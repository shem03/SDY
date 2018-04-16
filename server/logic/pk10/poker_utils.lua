local db_mgr = require("db_mgr")

local cmd = {}

--获取时间格式 
--time "H:M:S" 
local function converCurrentTime(time)
    local split = string.split(time, ":")
    if #split < 3 then return 0 end
    local tab = os.date("*t", os.time())
    tab.hour = split[1]
    tab.min = split[2]
    tab.sec = split[3]
    local result = os.time{year=tab.year, month=tab.month, day=tab.day, hour=tab.hour, min=tab.min, sec=tab.sec} -- 今天0点
    return result
end

-- 获取开奖时间
local function getTypeFtime(type)
    return 30
end

-- 获取时间
local function getGameNo(type, time)
    local time   = os.time()
    local kjTime = getTypeFtime(type)
    local atTime = os.date("%H:%M:%S", time) -- + kjTime
    local sql    = string.format("select actionNo, actionTime from t_ct_ssc_data_time where type=%d and actionTime>'%s' order by actionTime limit 1", type, atTime)
    local res = db_mgr.execute(sql)
    if table.empty(res) then
        sql = string.format("select actionNo, actionTime from t_ct_ssc_data_time where type=%d order by actionTime limit 1", type)
        res = db_mgr.execute(sql)
    end
    if table.empty(res) then
        return nil
    else
        local data = res[1]
        data.actionTime       = converCurrentTime(data.actionTime)
        data.actionTimeDate = os.date("%Y-%m-%d %H:%M:%S", data.actionTime)
        return data
    end
end

function cmd.getGameStep2()
    local game_step = Config.step_none
    local gametime  = 0
    g.count = (g.count or 0) + 1
    g.game_time = g.game_time + 1
    print("g.count=", g.count)
    if g.count == 1 then
        game_step = Config.pk_bet_start
        gametime  = 15
    elseif g.count == 2 then
        game_step = Config.pk_step_bet
        gametime  = 15 - g.game_time
    elseif g.count <= 15 then
        if g.game_time == 15 then
            game_step = Config.pk_bet_end
            gametime  = 0
            g.game_time = 0
        else
            game_step = Config.pk_bet_start
            gametime  = 15 - g.game_time
        end
    elseif g.count <= 25 then
        game_step = Config.pk_wait_kaijiang
        if g.game_time == 10 then
            gametime = 0
            g.game_time = 0
        else
            gametime = 10 - g.game_time
        end
    elseif g.count <= 35 then
        game_step = Config.pk_kaijiang
        if g.game_time == 10 then
            gametime = 0
            g.game_time = 0
        else
            gametime = 10 - g.game_time
        end
    elseif g.count <= 45 then
        game_step = Config.pk_bipai
        if g.game_time == 10 then
            gametime = 0
            g.game_time = 0
        else
            gametime = 10 - g.game_time
        end
    elseif g.game_time <= 55 then
        game_step = Config.pk_result
        if g.game_time == 10 then
            gametime = 0
            g.game_time = 0
            g.count = nil
        else
            gametime = 10 - g.game_time
        end
    end


    return game_step, gametime
end

-- 获取倒计时和步骤
function cmd.getGameStep()
    local test 		 = getGameNo(20)
    local kjTime     = getTypeFtime(type)
    local diffTime   = test.actionTime - os.time()

    local game_time = 0
    local game_step = Config.step_none
    if diffTime > 5* 60 then
        return Config.pk_result, diffTime
    end
    if 10 < diffTime and diffTime < 195 then  -- 下注 184s
        game_time =  diffTime - 10
        if game_time == 1 then
            game_step = Config.pk_bet_end
        elseif game_time == 184 then
            game_step = Config.pk_bet_start
        else
            game_step = Config.pk_step_bet
        end
        -- print("下注中", game_time)
    end


    if diffTime >=0 and diffTime <= 10 or (diffTime <= 300 and diffTime > 300-28) then --等待开奖 38s
        if diffTime >=0 and diffTime <= 10 then
            game_time = diffTime + 28 
        else
            game_time = 38 - (300 - diffTime) - 10
        end
        game_step = Config.pk_wait_kaijiang
        -- print("等待开奖", game_time)
    end

    if diffTime <= 300-28 and (diffTime >= 300 -28 - 30) then	-- 比车 30s
        game_time = diffTime - (300 -28 - 30) + 1
        game_step = Config.pk_kaijiang
        -- print("比车", game_time)
    end

    if diffTime < 300 -28 - 30 and diffTime >= 300 -28 - 30 - 25 then --比牌25s
        game_time = diffTime - (300 -28 - 30 - 25) + 1
        game_step = Config.pk_bipai
        -- print("比牌", game_time)
    end

    if diffTime < 300-28 -55 and diffTime >= 195 then --等待开始 38s
        game_time =  diffTime - 195
        game_step = Config.pk_result
        -- print("结算等待开始", game_time)
    end
    --print("game_time=", game_time, game_step)
    return game_step, game_time
end

-- 获取可下注类型数量
local function get_seat_count()
    -- if true then
    --     return 5;
    -- end
    local roomInfo = g.room_info.gameRoomInfo
    local seat_count = 5
    -- 72 牌九玩法  71 牛牛玩法
    if roomInfo.calculatedBits == "72" then
        seat_count = 2
    end

    return (10/seat_count)
end
cmd.get_seat_count = get_seat_count

-- 获取庄家座位
function cmd.get_banker_seat()
    local seat_count = get_seat_count()

    local saizi1 = math.random(1, 6)
    local saizi2 = math.random(1, 6)
    local saizi = {saizi1, saizi2}
    local num = (saizi1 + saizi2)%seat_count
    local seat_count = num == 0 and seat_count or num

    return seat_count, saizi 
end

-- 平均每门下注总金币
function cmd.get_average_bet_value_list(banker_seat, bankerCoin)
    
    local can_bet_count = get_seat_count()
    local average_bet_value_list = {}
    local average_bet = math.floor(bankerCoin/(can_bet_count-1))
    for i=1,can_bet_count do
        if i ~= banker_seat then
            average_bet_value_list[i] = average_bet
        end
    end

    return average_bet_value_list
end

-- 比牌数据分组
function cmd.get_bipai_list(data)
    if type(data) ~= "table" then
        return nil
    end

    local bipai_list = {}

    local seat_count = get_seat_count()
    local haos = 10/seat_count

    for i = 1, 10, haos do
        local bipai_data = {}
        for j = 1, haos do
            table.insert(bipai_data, data[i+j-1])
        end
        table.insert(bipai_list, bipai_data)
    end

    return bipai_list
end

-- 牛牛&牌九
local function niuniu2paijiu(haos, type)
    local total = 0
    for i=1, #haos do
        total = total + tonumber(haos[i])
    end

    if total == 0 then
        return 0
    end

    local point = total % 10
    if point == 0 then
        if type == 1 then
            point = 0
        else
            point = 10
        end
    end

    return point
end

-- 获取号码
local function get_haos(i, kjHaos, type)
    if type == 1 then
        local hao1     = kjHaos[(i-1)*2+1]
        local hao2     = kjHaos[(i-1)*2+2]
        return {hao1, hao2}
    elseif type == 2 then
        local hao1     = kjHaos[(i-1)*5+1]
        local hao2     = kjHaos[(i-1)*5+2]
        local hao3     = kjHaos[(i-1)*5+3]
        local hao4     = kjHaos[(i-1)*5+4]
        local hao5     = kjHaos[(i-1)*5+5]
        return {hao1, hao2, hao3, hao4, hao5}
    end
end

-- 获取哪个点比较大
local function comparePoint(a, b)
    if a.point > b.point then
        return true
    elseif a.point == b.point then
        return a.hao_max > b.hao_max
    end
    return false
end

local function sum_result_log(log)
    local result_log = {}
    for k,v in pairs(log) do
        local isNew = true
        for k1,v1 in pairs(result_log) do
            if v1.end_door == v.end_door and v1.start_door == v.start_door then
                isNew = false
                v1.change = v1.change + v.change
                break
            end
        end

        if isNew then
            table.insert(result_log, v)
        end
        
    end

    return result_log
end

-- 结算
function cmd.getResult( betData, totalBet, kj, banker_tag, banker_userinfo )
    print("==============>11111", betData, totalBet, kj)
    if not kj then
        return {}
    end
    local bet_data       = betData or {}
    local total_bet      = totalBet or{}
    local kjHaos         = string.split(kj, ",")
    local seat_count     = get_seat_count()
    local type           = seat_count == 5 and 1 or 2
    local bankerUserInfo = banker_userinfo or {}
    local banker         = bankerUserInfo.uid
    --  牛牛两门 or 牌九五门
    local user_infos  = {}
    local infos_arr   = {}
    local banker_info = nil
    for i=1, seat_count do --5
        local haos     = get_haos(i, kjHaos, type)
        local info     = {}
        info.num   	   = table.concat(haos, ",")
        info.point 	   = niuniu2paijiu(haos, type)
        info.bet  	   = bet_data[i]
        info.total_bet = total_bet[i]
        local haos     = haos
        table.sort(haos, function(a, b)
            return a > b
        end)
        info.hao_max   = haos[1]
        info.door      = i
        if i == banker_tag then
            info.is_banker = true
            banker_info = info
        else
            user_infos[i] = info
            table.insert(infos_arr, info)
        end
    end

    -- 下注最大值排序
    local tmp = table_copy_table(infos_arr)
    -- print(tmp)
    if table.size(tmp) > 1 then
        table.sort(tmp, comparePoint)
    end
    -- print(tmp)
    -- 设定每个点的大小级别, level越高点越大
    local tmp_idx = 0
    for i=#tmp, 1, -1 do
        tmp_idx = tmp_idx + 1
        tmp[tmp_idx].level = i
    end

    -- 庄家模式
    local result   = {}
    result.doors   = {}
    result.users   = {}
    result.details = {}
    -- 庄家
    if banker_info then
        local log = {}
        local banker_door = {}
        local banker_coin_change = 0
        for i=#tmp, 1, -1 do     --庄VS从小到大的闲家比  log更形象
            local info = tmp[i]
            if comparePoint(banker_info, info) == true then		-- 庄>闲
                info.coin_change   = -(info.total_bet or 0)
            else                                                -- 庄<闲
                info.coin_change = info.total_bet or 0
            end

            local peopes = bet_data[info.door] or {}
            for uid, bet in pairs(peopes) do
                result.details[uid] = result.details[uid] or {}

                local user_info = {}
                user_info.coin_change = 0
                if info.coin_change > 0 then
                    user_info.coin_change = bet.bet_value
                    -- 客户端操作log
                    table.insert(log, {change=bet.bet_value, start_door=banker_info.door, end_door=info.door})
                elseif info.coin_change < 0 then
                    user_info.coin_change = -bet.bet_value
                    -- 客户端操作log
                    table.insert(log, {change=bet.bet_value, start_door=info.door, end_door=banker_info.door})
                else
                    user_info.coin_change = 0
                end
                user_info.uid     = bet.uid
                user_info.name    = bet.name
                user_info.avatar  = bet.avatar
                if result.users[uid] then
                    result.users[uid].coin_change = result.users[uid].coin_change + user_info.coin_change
                else
                    result.users[uid] = user_info
                end
                
                -- 结算个人明细
                local detail       = {}
                detail.uid         = bet.uid
                detail.name        = bet.name
                detail.avatar      = bet.avatar
                result.details[uid].user_info       = detail
                result.details[uid].coin_change     = result.users[uid].coin_change
                result.details[uid].door            = result.details[uid].door or {}
                result.details[uid].door[info.door] = user_info.coin_change
                if result.details[uid].total_bet then
                    result.details[uid].total_bet = result.details[uid].total_bet + bet.bet_value
                else
                    result.details[uid].total_bet = bet.bet_value
                end
                if banker_door[info.door] then
                    banker_door[info.door] = banker_door[info.door] + (-user_info.coin_change)
                else
                    banker_door[info.door] = -user_info.coin_change
                end
            end
            banker_coin_change = banker_coin_change + info.coin_change
            result.doors[info.door] = info
        end

        -- door
        banker_info.coin_change  = -banker_coin_change
        result.doors[banker_tag] = banker_info
        -- user
        result.users[banker] 		   	 = {}
        result.users[banker].coin_change = banker_info.coin_change
        result.users[banker].uid         = banker
        result.users[banker].name        = bankerUserInfo.name
        result.users[banker].avatar      = bankerUserInfo.user_avatar
        result.users[banker].is_banker   = true
        table.insert(log, {change=0, start_door=0, end_door=0})		-- 全部返回玩家列表
        result.log = log

        -- detail
        local detail                           = {}
        detail.uid                             = banker
        detail.name                            = bankerUserInfo.name
        detail.avatar                          = bankerUserInfo.user_avatar
        result.details[banker]                 = result.details[banker] or {}
        result.details[banker].is_banker       = true
        result.details[banker].user_info       = detail
        result.details[banker].coin_change     = banker_info.coin_change
        result.details[banker].total_bet       = 0
        result.details[banker].door            = banker_door
        -- print(result)
    else
        -- 分配到门
        -- 排序查找最大点数
        -- print(tmp)
        local log = {}
        local user = {}
        local tmp_user_infos = {}
        local play_doors = table.size(betData or {})
        if play_doors > 1 then    --门数大于1 进行输赢计算
            tmp_user_infos = tmp
        else                      --门数小等于1 进行单计算
            tmp_user_infos = {}
            result.doors   = user_infos
            -- 门数等于1（组装流局局结算回去，其实也算正常结算）
            if play_doors == 1 then 
                -- 返回战绩
                for door, info in pairs(betData) do 
                    local peopes   = info
                    for uid, bet in pairs(peopes) do
                        local user_info = {}
                        user_info.coin_change = 0
                        user_info.uid     = bet.uid
                        user_info.name    = bet.name
                        user_info.avatar  = bet.avatar
                        result.users[uid] = user_info
                    end
                    break
                end
            end
            -- print("result.users", result.users)
        end
        -- 计算
        for i=1, #tmp_user_infos do
            local info 			    = tmp_user_infos[i]
            local total_bet_change  = info.total_bet or 0
            info.coin_change	    = 0
            print("=====================")
            print("门计算：", info.door)
            -- 9 7 5 3 1
            for j=#tmp, 1, -1 do
                local t_info = tmp[j]
                t_info.remain_total_bet = t_info.remain_total_bet or (t_info.total_bet or 0) 
                
                if total_bet_change > 0 and t_info.remain_total_bet > 0 and info.level > t_info.level  then
                    print(total_bet_change, t_info.remain_total_bet)
                    if total_bet_change > t_info.remain_total_bet then
                        print("下注大于", total_bet_change, t_info.remain_total_bet)
                        -- 金币差额
                        info.coin_change	    = info.coin_change + t_info.remain_total_bet

                        -- 客户端操作log
                        table.insert(log, {change=t_info.remain_total_bet, start_door=t_info.door, end_door=info.door})

                        -- 下一轮扣
                        total_bet_change   = total_bet_change - t_info.remain_total_bet
                        t_info.remain_total_bet = 0
                        print("下注大", total_bet_change, t_info.remain_total_bet)

                    elseif total_bet_change < t_info.remain_total_bet then
                        print("下注小于", total_bet_change, t_info.remain_total_bet)
                        info.coin_change 		= info.coin_change + total_bet_change

                        -- 客户端操作log
                        table.insert(log, {change=total_bet_change, start_door=t_info.door, end_door=info.door})

                        t_info.remain_total_bet = t_info.remain_total_bet - total_bet_change
                        total_bet_change   = 0
                        print("下注小", total_bet_change, t_info.remain_total_bet)
                        break
                    else
                        print("下注等于", total_bet_change, t_info.remain_total_bet)
                        info.coin_change 		= info.coin_change + t_info.remain_total_bet

                        -- 客户端操作log
                        table.insert(log, {change=total_bet_change, start_door=t_info.door, end_door=info.door})

                        t_info.remain_total_bet = 0
                        total_bet_change = 0 
                        print("下注等", total_bet_change, t_info.remain_total_bet)
                        break
                    end
                else
                    print("判断语句", t_info.remain_total_bet, info.point ,t_info.point)
                end
            end
            
            if info.coin_change == 0 then
                if (info.remain_total_bet or 0) == 0 then									-- 刚好扣光
                    info.coin_change = -total_bet_change
                else
                    print("info.coin_change ======>不够扣", info.coin_change)
                    info.coin_change = -(total_bet_change - info.remain_total_bet)          -- 不够扣
                end
            end
            info.remain_total_bet = info.remain_total_bet or info.total_bet
            result.doors[info.door] = info
            print(info)
            -- 分配到人
            local peopes         = bet_data[info.door] or {}
            local user_total_bet = total_bet[info.door]
            local index   = 0
            local bet_sum = 0
            for uid, bet in pairs(peopes) do
                result.details[uid] = result.details[uid] or {}

                index = index + 1
                local user_info = {}
                user_info.coin_change = 0
                if user_total_bet == math.abs(info.coin_change) then    -- 赢 输（收到的钱刚好）
                    print("赢 输（收到的钱刚好）")
                    if info.coin_change >= 0 then	 --赢
                        user_info.coin_change =  bet.bet_value
                    else							 --输
                        user_info.coin_change = -bet.bet_value
                    end
                elseif user_total_bet > math.abs(info.coin_change) then -- 赢 输（收到的钱少了）
                    print("赢 输（收到的钱少了）", info.coin_change)
                    if info.coin_change > 0 then	--赢
                        if index == table.size(peopes) then
                            user_info.coin_change = info.coin_change - bet_sum
                            bet_sum = info.coin_change
                        else
                            user_info.coin_change = math.floor(info.coin_change * (bet.bet_value/user_total_bet) * 100)/100
                            bet_sum = bet_sum + user_info.coin_change
                            --print(bet.name, user_info.coin_change, math.floor(info.coin_change * (bet.bet_value/user_total_bet) * 100)/100)
                        end
                    else							--输
                        if index == table.size(peopes) then
                            user_info.coin_change = info.coin_change - bet_sum
                            bet_sum = info.coin_change
                        else
                            user_info.coin_change = math.floor(info.coin_change * (bet.bet_value/user_total_bet) * 100)/100
                            bet_sum = bet_sum + user_info.coin_change
                            --print(bet.name, user_info.coin_change, math.floor(info.coin_change * (bet.bet_value/user_total_bet) * 100)/100)
                        end
                    end
                elseif user_total_bet < info.coin_change then
                    print("获得金币>总下注，不可能")
                    assert(type("a") == "number", "获得金币>总下注，不可能")
                end
               
                user_info.uid     = bet.uid
                user_info.name    = bet.name
                user_info.avatar  = bet.avatar
                if result.users[uid] then
                    result.users[uid].coin_change = result.users[uid].coin_change + user_info.coin_change
                else
                    result.users[uid] = user_info
                end
                -- print(user_info)
                -- 结算个人明细
                local detail       = {}
                detail.uid         = bet.uid
                detail.name        = bet.name
                detail.avatar      = bet.avatar
                result.details[uid].user_info       = detail
                result.details[uid].coin_change     = result.users[uid].coin_change
                result.details[uid].door            = result.details[uid].door or {}
                result.details[uid].door[info.door] = user_info.coin_change
                if result.details[uid].total_bet then
                    result.details[uid].total_bet = result.details[uid].total_bet + bet.bet_value
                else
                    result.details[uid].total_bet = bet.bet_value
                end
            end
        end
        table.insert(log, {change=0, start_door=0, end_door=0})		-- 全部返回玩家列表
        result.log = sum_result_log(log)
    end

    for uid, detail in pairs(result.details or {}) do
        for i=1, seat_count do
            detail.door[i] = detail.door[i] or 0
        end
    end
    -- print(result)
    return result
end

return cmd
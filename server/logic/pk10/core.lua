local _user = require "user.ctcore"
local db_mgr = require("db_mgr")
local json = require "cjson"
local cthttp = require "cthttp"
local cmd = {}

-- 多用户操作游戏结算
-- type 0 增加 1 返还 2 赢 3 输 4、房间扣钱  5、房间返还
function cmd.operatGameResultAcct(custNo, token, userAccts)
    return _user.operatGameResultAcct(custNo, token, userAccts)
end

-- 获取最新一期开奖数据
function cmd.get_ssc_data()
    local sql = "SELECT * FROM t_ct_ssc_data WHERE 1=1 order by number desc limit 1"

    local data = db_mgr.execute(sql)[1]

    -- if os.time() - data.time > 120 then
    --     return nil
    --     -- body
    -- end
    return data.data, data.number
end

-- 连胜奖励结算
local function WinningStreakResult(userInfo)
    print("连胜奖励结算")
    local room_id  = g.room_info.gameRoomInfo.gameGroupId or ""
    local winCount = userInfo.winning_steak_count
    -- local round_ids = str_split_intarray(userInfo.winning_steak_round_ids, ",") 
    if winCount >= 6 then
        local sql = string.format("SELECT * FROM t_ct_hb_result WHERE uid=%s and room_id=%s and round_id IN(%s)", userInfo.uid, room_id, userInfo.winning_steak_round_ids)
        print("连胜奖励结算", sql)
        local res = db_mgr.execute(sql)
        if table.empty(res) then
            return
        end
        local total = {S1={ju=0}, S2={ju=0}}    -- S1牛牛  S2大小单双 梭哈   
        local isS1  = true
        local coin = 0
        for index, data in pairs(res) do
            if data.bet_type == 1 then
                total.S1.ju = (total.S1.ju or 0) + 1
                total.S1.bet_type = data.bet_type
                total.S1.bet_value = (total.S1.bet_value or 0) + data.total_bet_value
            else
                isS1 = false   
                total.S2.ju = (total.S2.ju or 0) + 1
                total.S2.bet_type = data.bet_type
                total.S2.bet_value = (total.S1.bet_value or 0) + data.total_bet_value
            end
        end
        
        local M1 = total.S1.bet_value or 0
        local M2 = total.S2.bet_value or 0
        local average = (M1 + M2/10)/winCount
        if average < 50 then
            coin = 0
        elseif average < 100 then
            coin = Config.hb_winning_streak_config[winCount][1]
        else
            coin = Config.hb_winning_streak_config[winCount][2]
        end

        print("连胜奖励结算", coin, average)

        if coin > 0 then
            local game_owner = g.room_info.gameRoomInfo.gameOwner
            local is_success = return_task_coin(game_owner, userInfo.uid, coin, 1)

            local cur_time = time_string(skynet.time())
            local mailContent = string.format("您的%d连胜已终止，奖励金币%d", winCount, coin)
            _user.add_mail(userInfo.uid, mailContent, 2, coin, is_success)

            local player = g.users[userInfo.uid]
            if player then
                local data = {
                    msg_id = "task_is_success",
                    reward_type = 1,
                    is_success = is_success,
                    content = mailContent,
                    coin = coin,
                    winning_steak_count = winCount,
                    time = cur_time
                }
                send_msg(player.fd, data)
            end
            
        end
    
    end
end

--
-- 存连胜数据
local function handleUserWinningStreak(user)
    local round_id = g.round or ""
    local room_id  = g.room_info.gameRoomInfo.gameGroupId or ""
    local roomUser = get_room_userinfo(room_id, user.uid)
    print("roomUser===>", roomUser)

    local winning_steak_count = 0
    local winning_steak_round_ids = ""
    print(user.coinChange, tostring(user.bet_type), user.isBanker)
    if user.coinChange > 0 and user.isBanker == false then -- and tostring(user.bet_type) ~= "4" 
        winning_steak_count = roomUser.winning_steak_count + 1
        winning_steak_round_ids = roomUser.winning_steak_round_ids
        if winning_steak_round_ids == "" then
            winning_steak_round_ids = round_id
        else
            winning_steak_round_ids = winning_steak_round_ids .. "," .. round_id
        end

    else
        winning_steak_count = 0
        winning_steak_round_ids = ""

        -- 输结算连胜奖励
        WinningStreakResult(roomUser)
        -- if user.isBanker == false then
        --     WinningStreakResult(roomUser)
        -- end
    end

    local sql = string.format("UPDATE t_ct_hb_room_user SET winning_steak_count='%d', winning_steak_round_ids='%s', time='%s' WHERE room_id=%s and uid=%s", winning_steak_count, winning_steak_round_ids, os.time(), room_id, user.uid);
    db_mgr.execute(sql)
end

local function addWinningStreak(result)
    local result = result.data
    local room_id = g.room_info.gameRoomInfo.gameGroupId
    local bet_user_ids = ""

    if not next(result) then
        return
    end
    for uid, user in pairs(result) do
        handleUserWinningStreak(user)

        -- 下注用户ID
        if user.isBanker == false then
            if bet_user_ids == "" then
                bet_user_ids = user.uid
            else
                bet_user_ids = bet_user_ids .. "," .. user.uid
            end
        end
        
    end

    -- 未下注，终结连胜，发放奖励
    local userinfos = get_room_userinfos(room_id, bet_user_ids)
    for k, roomUser in pairs(userinfos) do
        WinningStreakResult(roomUser)
    end

    local sql = string.format("UPDATE t_ct_hb_room_user SET winning_steak_count=0, winning_steak_round_ids='', time='%s' WHERE room_id=%s and uid NOT IN(%s)", os.time(), room_id, bet_user_ids);
    db_mgr.execute(sql)
end

-- 获取每日返利
local function get_daily_rebate(room_id, uid)
    local sql = string.format("SELECT * FROM t_ct_hb_daily_rebate WHERE room_id = '%s' and uid = '%s' limit 1",room_id, uid)
    return db_mgr.execute(sql)[1]
end

local function get_is_can_add(room_id, uid, tablename)
    local tab = os.date("*t", os.time())
    tab.hour = 12
    tab.min = 0
	tab.sec = 0
	local now   = os.time()
    local endTime   = os.time(tab) -- 今天12点
	local startTime = endTime - 86400
	local weiTime   = endTime + 86400
	--print("startTime:", time_string(startTime)) 
	--print("endTime:", time_string(endTime))
	--print("weiTime:", time_string(weiTime))
    --print("now:",time_string(os.time()))
    
    if now <= endTime and now > startTime then 		--昨天12:00 ~ 今天12:00
		--print("昨天")
		local sql = string.format("SELECT * FROM %s WHERE %d<time and time<=%d and room_id=%s and uid=%s limit 1", tablename, startTime, endTime, room_id, uid)
        local res = db_mgr.execute(sql)
        return table.size(res) == 0, res[1], startTime, endTime
	elseif now > endTime and now <= weiTime then	--今天12:00 ~ 明天12：00
		--print("今天", endTime, weiTime)
		local sql = string.format("SELECT * FROM %s WHERE %d<time and time<=%d and room_id=%s and uid=%s limit 1", tablename, endTime, weiTime, room_id, uid)
		local res = db_mgr.execute(sql)
		return table.size(res) == 0, res[1], endTime, weiTime
	end
end

-- 存储每日返利
local function addDailyRebate(resultData)
    local result = resultData.data
    local room_id = g.room_info.gameRoomInfo.gameGroupId
    local game_owner = g.room_info.gameRoomInfo.gameOwner

    if not next(result) then
        return
    end

    for uid, user in pairs(result) do
        -- 判断是否存在
        local ret, sqlData, startTime, endTime  = get_is_can_add(room_id, uid, "t_ct_hb_daily_rebate")
        if not ret then
            local cur_time = os.time()
            local coinChange = sqlData.coin_change + user.coin_change
            local total_amount = sqlData.total_amount + math.abs(user.coin_change)
            local sql = string.format("UPDATE t_ct_hb_daily_rebate SET coin_change='%s', rebate_value=total_amount*rate_value, total_amount='%s', time='%s',time_string='%s', return_time='%s' WHERE %d<time and time<=%d and room_id=%s and uid=%s ", 
            coinChange, total_amount, cur_time, time_string(cur_time), cur_time+86400, startTime, endTime, room_id, uid);
            db_mgr.execute(sql)
        else
            local cur_time = os.time()
            local sqlData = {}
            sqlData.room_id = room_id
            sqlData.round_id = g.roundid
            sqlData.round_num = g.round
            sqlData.uid = uid
            sqlData.name = user.name or ""
            sqlData.avatar = user.avatar or ""
            sqlData.coin_change = user.coin_change
            sqlData.total_amount =  math.abs(user.coin_change)
            sqlData.rate_value =  Config.hongbao_rate or 0
            sqlData.time = cur_time
            sqlData.time_string = time_string(cur_time)
            sqlData.rebate_value = string.format("%0.2f", sqlData.total_amount * sqlData.rate_value)
            sqlData.return_time = cur_time + 86400

            db_mgr.add("t_ct_hb_daily_rebate", sqlData)
        end
    end
end

-- 存储结算表
local function addResultLog(resultData)
    local result = resultData.details
    for uid, user in pairs(result) do
        local sqlData = {}
        sqlData.game_type = g.room_info.gameRoomInfo.gameType
        sqlData.game_sub_type = g.room_info.gameRoomInfo.calculatedBits
        sqlData.room_id = g.room_info.gameRoomInfo.gameGroupId
        sqlData.round_id = g.roundid
        sqlData.number = g.round
        sqlData.kj_data = g.kj_hao
        sqlData.uid = uid
        sqlData.name = user.user_info.name or ""
        sqlData.avatar = user.user_info.avatar or ""
        sqlData.time = os.time()
        sqlData.banker_id = g.banker
        sqlData.is_banker =  g.banker == uid and 1 or 0
        sqlData.banker_seat = g.banker_seat or 0
        sqlData.banker_game_cion = g.bankerGameCoin or 0
        sqlData.coin_change = user.coin_change or 0
        sqlData.original_coin_change = user.original_coin_change or user.coin_change
        sqlData.total_bet = user.total_bet or 0
        -- sqlData.log = string.sub(json.encode(g.result.log or {}),0, 1024)
        sqlData.door_result = json.encode(user.door or {})
        sqlData.door_bet_detais = json.encode((g.user_bet_door_details or {})[uid] or {})

        db_mgr.add("t_ct_ssc_result", sqlData)
    end
end

cmd.addResultLog = addResultLog

-- 存储结算相关数据
function cmd.handleResult(result)
    -- --存储结算数据
    addResultLog(result)
    --存储每日返利
    -- addDailyRebate(result)
    --存储连胜
    -- addWinningStreak(result)
end

return cmd
local skynet = require("skynet")
local db_mgr = require("db_mgr")
local json = require "cjson"
local cthttp = require "cthttp"
local _user = require "user.ctcore"
local utils  = require("hongbao.poker_utils")
local cmd = {}

-- 冻结房间钻石
function cmd.freezeRoomGold(roomId, goldNum)
    return _user.freezeRoomGold(roomId, goldNum)
end

-- 返还房间钻石
function cmd.returnRoomGold(roomId, goldNum)
    return _user.returnRoomGold(roomId, goldNum)
end

-- 扣除房间钻石
function cmd.reduceRoomGold(roomId, goldNum)
    return _user.reduceRoomGold(roomId, goldNum)
end

-- 多用户操作游戏结算
-- type 0 增加 1 返还 2 赢 3 输 4、房间扣钱  5、房间返还
function cmd.operatGameResultAcct(custNo, token, userAccts)
    return _user.operatGameResultAcct(custNo, token, userAccts)
end

-- 新增某个用户游戏中的金币  (用户金币-->游戏中金币)
function cmd.addUserGameCoin(user, coin, operatCustNo)
    return _user.addUserGameCoin(user, coin, operatCustNo)
end

-- 冲返某个用户中的金币   (用户游戏中金币-->金币)
function cmd.reduceUserGameCoin(user, coin, operatCustNo)
    return _user.reduceUserGameCoin(user, coin, operatCustNo)
end

-- 存储游戏操作
function cmd.addStepData(iStep, params)
    local roomid = g.room_info.gameRoomInfo.gameGroupId

    -- 刷新房间信息
    cmd.updateRoomInfo(roomid, g.roundid, iStep)

    -- 刷新游戏操作
    -- print("======================>roundid", g.roundid)
    local sqlActionData = {}
    sqlActionData.room_id = roomid
    sqlActionData.round_id = g.roundid
	sqlActionData.round_num = g.round
    sqlActionData.time = os.time()
    sqlActionData.uid = params.user.id or 0
    sqlActionData.name = params.user.name or ""
    sqlActionData.avatar = params.user.avatar or ""
    sqlActionData.step = iStep
    sqlActionData.baner_id = g.banker or 0
    
    if iStep == Config.step_rob then
        sqlActionData.rob_value = params.coin
    elseif iStep == Config.step_bet then
        sqlActionData.bet_type = params.bet_type
        sqlActionData.bet_sub_types = params.bet_sub_types
        sqlActionData.bet_values = params.bet_value
    elseif iStep == Config.step_send then
        if type(params.packers) == "table" then
            sqlActionData.packers = json.encode(params.packers)
        else
            sqlActionData.packers = params.packers
        end
    elseif iStep == Config.step_qiang then
        sqlActionData.packet_value = params.packet_value
        sqlActionData.packet_open = params.packet_open
    end
    
    -- print(sqlActionData, "======addStepData=-=======")
    db_mgr.add("t_ct_hb_action", sqlActionData)
end

-- 获取房间信息
function cmd.getLocalRoomInfo(room_id)
    local sql = string.format("SELECT * FROM t_ct_hb_room WHERE room_id = '%s' limit 1",room_id)
    return db_mgr.execute(sql)[1]
end

local function return_task_coin(game_owner, uid, coin, task_type)
    local userAccts = {}
    -- 房主扣钱
    local userAcct = {}
    userAcct.type = 7
    userAcct.coin = coin
    userAcct.custNo = game_owner
    userAcct.waterMemo = "房主奖励玩家金币"
    userAcct.gameType = g.room_info.gameRoomInfo.gameType
    if task_type == 1 then
        userAcct.waterType = "73"
    elseif task_type == 3 then
        userAcct.waterType = "75"
    elseif task_type == 2 then
        userAcct.waterType = "77"
    else
        return false
    end
    table.insert(userAccts, userAcct)

    -- 奖励玩家金币
    local userAcct = {}
    userAcct.type = 6
    userAcct.coin = coin
    userAcct.custNo = uid
    userAcct.waterMemo = "任务达成奖励金币"
    userAcct.gameType = g.room_info.gameRoomInfo.gameType
    if task_type == 1 then
        userAcct.waterType = "74"
    elseif task_type == 3 then
        userAcct.waterType = "76"
    elseif task_type == 2 then
        userAcct.waterType = "78"
    else
        return false
    end
    table.insert(userAccts, userAcct)

	-- 金币输赢
    local msg, dec = cmd.operatGameResultAcct("admin", "", userAccts)
	if msg ~= "ok" then
		print(msg == "B002" and "任务奖励房主账户余额不足" or dec)
        return false
    end
    return true
end

function cmd.getRound(room_id)
    local roominfo = cmd.getLocalRoomInfo(room_id)
    local tab = os.date("*t", os.time())
    tab.hour = 0
    tab.min = 0
    tab.sec = 0
    local startTime = os.time(tab) -- 今天0点
    if not roominfo then
        return 1
    else
        if roominfo.time > startTime then
            return roominfo.round_num + 1
        else
            return 1
        end
    end
end

-- 结算相关
-- 存储结算表
local function addResultLog(resultData)
    local result = resultData.result
    for uid, user in pairs(result) do
        local sqlData = {}
        sqlData.room_id = g.room_info.gameRoomInfo.gameGroupId
        sqlData.round_id = g.roundid
        sqlData.round_num = g.round
        sqlData.time = os.time()
        sqlData.banker_id = g.banker
        sqlData.is_banker =  g.banker == uid and 1 or 0
        sqlData.uid = uid
        sqlData.name = user.name or ""
        sqlData.avatar = user.avatar or ""
        sqlData.coin_change = user.coinChange or 0
        sqlData.packet_value = user.packet_value or ""
        sqlData.bet_type = user.bet_type or 0
        sqlData.bet_type_name = user.bet_type_name or ""
        sqlData.sub_bet_type  = user.sub_bet_type or ""
        sqlData.sub_bet_type_name = user.sub_bet_type_name or ""
        sqlData.rate = user.rate or ""
        sqlData.total_bet_value = user.total_bet_value or 0
        sqlData.point_type = user.point_type or ""
        sqlData.origin_coin_change = user.originalCoinChange or 0
        sqlData.point_type_name = user.point_type_name or ""
        sqlData.d_point_type = user.d_point_type or ""
        sqlData.d_point_type_name = user.d_point_type_name or ""
        sqlData.same = user.same or 0
        sqlData.lose = user.lose or 0
        sqlData.win = user.win or 0
        sqlData.is_special = user.is_special == true and 1 or 0
        sqlData.special_value = user.spcial_value or 0
        sqlData.special_type = user.special_type or 0
        sqlData.log = json.encode(user.log)
        db_mgr.add("t_ct_hb_result", sqlData)
    end
end

cmd.addResultLog = addResultLog

-- 刷新房间信息
function cmd.updateRoomInfo(roomid, roundid, step)
    local sql = string.format("UPDATE t_ct_hb_room SET round_id='%s', time='%s', step='%d',room_freeze_golden=%f WHERE room_id='%s'", roundid, os.time(), step, Config.hb_room_water, roomid);
    db_mgr.execute(sql)
end

-- 存储期数
function cmd.updateGameRound()
    local room_id = g.room_info.gameRoomInfo.gameGroupId
    local roominfo = cmd.getLocalRoomInfo(room_id)
    local tab = os.date("*t", os.time())
    tab.hour = 0
    tab.min = 0
    tab.sec = 0
    local startTime = os.time(tab) -- 今天0点
    if not roominfo then
        g.round = 1
        local sqlData = {}
        sqlData.room_id = room_id
        sqlData.round_id = g.roundid
        sqlData.round_num = g.round
        sqlData.time = os.time()
        sqlData.banker_id = g.banker
        db_mgr.add("t_ct_hb_room", sqlData)
    else
        print("插入局数为:", g.round)
        g.round = g.round or 1
        local sql = string.format("UPDATE t_ct_hb_room SET round_num='%d', round_id='%s', time='%s', banker_id='%s' WHERE room_id=%s", g.round, g.roundid, os.time(), g.banker, room_id);
        db_mgr.execute(sql)
    end
    
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
    local result = resultData.result
    local room_id = g.room_info.gameRoomInfo.gameGroupId
    local game_owner = g.room_info.gameRoomInfo.gameOwner

    for uid, user in pairs(result) do
        -- 判断是否存在
        local ret, sqlData, startTime, endTime  = get_is_can_add(room_id, uid, "t_ct_hb_daily_rebate")
        if not ret then
            local cur_time = os.time()
            local coinChange = sqlData.coin_change + user.originalCoinChange
            local total_amount = sqlData.total_amount + math.abs(user.originalCoinChange)
            local sql = string.format("UPDATE t_ct_hb_daily_rebate SET coin_change='%s', rebate_value=total_amount*rate_value, total_amount='%s', time='%s',time_string='%s', return_time='%s' WHERE %d<time and time<=%d and room_id=%s and uid=%s ", 
            coinChange, total_amount, cur_time, time_string(cur_time), cur_time+86400, startTime, endTime, room_id, uid);
            db_mgr.execute(sql)
        else
            local sqlData = {}
            sqlData.room_id = room_id
            sqlData.round_id = g.roundid
            sqlData.round_num = g.round
            sqlData.uid = uid
            sqlData.name = user.name or ""
            sqlData.avatar = user.avatar or ""
            sqlData.coin_change = user.originalCoinChange
            sqlData.total_amount =  math.abs(user.originalCoinChange)
            sqlData.rate_value =  Config.hongbao_rate or 0
            sqlData.time = resultData.time
            sqlData.time_string = resultData.op_time
            sqlData.rebate_value = string.format("%0.2f", sqlData.total_amount * sqlData.rate_value)
            sqlData.return_time = resultData.time + 86400

            db_mgr.add("t_ct_hb_daily_rebate", sqlData)
        end
    end
end

-- 房间用户相关
-- 获取房间用户是否存在
local function get_room_userinfo(room_id, uid)
    local sql = string.format("SELECT * FROM t_ct_hb_room_user WHERE id = '%s' limit 1",room_id .. uid)
    return db_mgr.execute(sql)[1]
end

-- 获取房间未下注且有连胜的所有用户
local function get_room_userinfos(room_id, user_ids)
    local sql = string.format("SELECT * FROM t_ct_hb_room_user WHERE room_id = '%s' and winning_steak_count > 0 and uid NOT IN(%s)",room_id, user_ids)
    return db_mgr.execute(sql)
end

-- 操作房间用户
function cmd.handleRoomUser(user)
    local room_id = g.room_info.gameRoomInfo.gameGroupId
    local id = room_id .. user.uid
    local roomUser = get_room_userinfo(room_id, user.uid)
    if roomUser then
        local cur_time = os.time()
        local sql = string.format("UPDATE t_ct_hb_room_user SET name='%s', avatar='%s', time='%s' WHERE room_id=%s and uid=%s", user.name or "", user.avatar or "", cur_time, room_id, user.uid)
        local res = db_mgr.execute(sql)
    else
        local sqlData = {}
        sqlData.id = id
        sqlData.room_id = room_id
        sqlData.uid = user.id
        sqlData.name = user.name or ""
        sqlData.avatar = user.avatar or ""
        sqlData.time = os.time()
        sqlData.time_string = time_string(os.time())
        db_mgr.add("t_ct_hb_room_user", sqlData)
    end
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
    local round_id = g.roundid or ""
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
    local result = result.result
    local room_id = g.room_info.gameRoomInfo.gameGroupId
    local bet_user_ids = ""
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

--
--存储特殊点
local function handleUserSpecial(user)
    local round_id = g.roundid or ""
    local room_id  = g.room_info.gameRoomInfo.gameGroupId or ""
    local packet_value = user.packet_value

    -- 判断是否存在
    local ret, spcialSqlData, startTime, endTime  = get_is_can_add(room_id, user.uid, "t_ct_hb_special_point")
    --print("handleUserSpecial===>",spcialSqlData, ret)
    local special_points = ""
    local special_point_round_ids = ""
    local isMatch = utils.isMatchSpecialWinning(packet_value)
    --print("user.isBanker", user.isBanker, isMatch)    

    -- 平均下注小于50不计算
    local average = tostring(user.bet_type) == "1" and user.total_bet_value or user.total_bet_value/10

    if user.isBanker == false and isMatch and average >= 50 then
        --判断是否重复领取
        spcialSqlData = spcialSqlData or {}
        special_points = spcialSqlData.special_points or ""
        special_point_round_ids = spcialSqlData.special_point_round_ids or ""
        local points = str_split_intarray(special_points, ",") 
        print(points)
        for k, v in pairs(points) do
            if tonumber(v) == tonumber(packet_value) then
                return
            end
        end
       print("============", special_points, special_point_round_ids)
        -- 添加
        -- 特殊点牌局
        if special_point_round_ids == "" then
            special_point_round_ids = round_id
        else
            special_point_round_ids = special_point_round_ids .. "," .. round_id
        end
        
        -- 特殊点
        if special_points == "" then
            special_points = packet_value
        else
            special_points = special_points .. "," .. packet_value
        end

        if not ret then
            local cur_time = os.time()
            local sql = string.format("UPDATE t_ct_hb_special_point SET special_points='%s', special_point_round_ids='%s', time='%d' WHERE %d<time and time<=%d and room_id=%s and uid=%s", special_points, special_point_round_ids, cur_time, startTime, endTime, room_id, user.uid);
            db_mgr.execute(sql)
        else
            local sqlData = {}
            sqlData.room_id = room_id
            sqlData.round_id = g.roundid
            sqlData.round_num = g.round
            sqlData.uid = user.uid
            sqlData.name = user.name or ""
            sqlData.avatar = user.avatar or ""
            sqlData.time = os.time()
            sqlData.special_points = special_points
            sqlData.special_point_round_ids = special_point_round_ids

            db_mgr.add("t_ct_hb_special_point", sqlData)
        end


        print("============2", special_points, special_point_round_ids)
        local coin = 0
        local special_config = Config.hb_special_config[tostring(packet_value)] or {}
        -- 判断返利值
        -- if user.bet_type == 1 or user.bet_type == 4 then
        --     if user.total_bet_value < 50 then
        --         print("奖励数值*50%")
        --         coin = 0
        --     elseif user.total_bet_value < 100 then
        --         print("奖励数值*100%")
        --         coin = special_config[1] or 0
        --     else
        --         print("奖励数值*200%")
        --         coin = special_config[2] or 0
        --     end
        -- -- else
        -- --     if user.total_bet_value <=400 then
        -- --         print("奖励数值*50%")
        -- --         coin = 2000 * 0.5
        -- --     elseif user.total_bet_value <= 2000 then
        -- --         print("奖励数值*100%")
        -- --         coin = 2000 * 1
        -- --     else
        -- --         print("奖励数值*200%")
        -- --         coin = 2000 * 2
        -- --     end
        -- end
        
        if user.total_bet_value == nil then
            return
        end

        if user.total_bet_value < 50 then
            print("奖励数值*50%")
            coin = 0
        elseif user.total_bet_value < 100 then
            print("奖励数值*100%")
            coin = special_config[1] or 0
        else
            print("奖励数值*200%")
            coin = special_config[2] or 0
        end

        if coin > 0 then
            local game_owner = g.room_info.gameRoomInfo.gameOwner
            local is_success = return_task_coin(game_owner, user.uid, coin, 2)

            local cur_time = time_string(skynet.time())
            local mailContent = string.format("恭喜您在%s获得特殊点数%s，奖励金币%d", cur_time, packet_value, coin)
            _user.add_mail(user.uid, mailContent, 2, coin, is_success)

            local player = g.users[user.uid]
            if player then
                local data = {
                    msg_id = "task_is_success",
                    reward_type = 2,
                    is_success = is_success,
                    content = mailContent,
                    coin = coin,
                    special_point = packet_value,
                    time = cur_time
                }
                send_msg(player.fd, data)
            end
        end

    end
end

local function addSpecialPoint(result)
    local result = result.result
    for uid, user in pairs(result) do
        handleUserSpecial(user)
    end
end

--
-- 存储集齐点数
local function handleUserTidyTogether(user)
    local round_id = g.roundid or ""
    local room_id  = g.room_info.gameRoomInfo.gameGroupId or ""
    local packet_value = user.packet_value

    -- 判断是否存在
    local ret, sqlData, startTime, endTime  = get_is_can_add(room_id, user.uid, "t_ct_hb_tidy_together")
    --print("handleUserTidyTogether===>",sqlData, ret, user)
    -- 平均下注小于50不计算
    local average = tostring(user.bet_type) == "1" and user.total_bet_value or user.total_bet_value/10

    if user.isBanker == false and user.is_special == true and average >= 50 then
        --判断是否重复领取
        local points_str = "points_" .. user.special_type
        local round_ids_str = "round_ids_" .. user.special_type

        sqlData = sqlData or {}
        local points = sqlData[points_str] or ""
        local round_ids = sqlData[round_ids_str]  or ""
        if points == "" then
            points = user.spcial_value .. ""
        else
            local arrPoints = str_split_intarray(points, ",") 
            for k, v in pairs(arrPoints) do
                if tonumber(v) == tonumber(user.spcial_value) then
                    return
                end
            end
            points = points .. "," .. user.spcial_value
        end

        if round_ids == "" then
            round_ids = round_id .. ""
        else
            round_ids = round_ids .. "," .. round_id
        end

        -- 算出个数
        if not ret then
            local cur_time = os.time()
            local sql = string.format("UPDATE t_ct_hb_tidy_together SET points_%d='%s', round_ids_%d='%s', time='%d' WHERE %d<time and time<=%d and room_id=%s and uid=%s", user.special_type, points, user.special_type, round_ids, cur_time, startTime, endTime, room_id, user.uid);
            db_mgr.execute(sql)
        else
            local sqlData = {}
            sqlData.room_id = room_id
            sqlData.round_id = g.roundid
            sqlData.round_num = g.round
            sqlData.uid = user.uid
            sqlData.name = user.name or ""
            sqlData.avatar = user.avatar or ""
            sqlData.time = os.time()
            sqlData[points_str] = points
            sqlData[round_ids_str] = round_ids
            
            db_mgr.add("t_ct_hb_tidy_together", sqlData)
        end

        local arrPoints = str_split_intarray(points, ",") 
        local tidy_together_num = table.size(arrPoints)
        
        local tidy_together_config = Config.hb_tidy_together_config[user.special_type] or {}
        if tidy_together_config[tidy_together_num] then
            -- 计算总下注
            local sql = string.format("SELECT * FROM t_ct_hb_result WHERE uid=%s and room_id=%s and round_id IN(%s)", user.uid, room_id, round_ids)
            print(tidy_together_config[tidy_together_num], "=======")
            local res = db_mgr.execute(sql)
            if table.empty(res) then
                return
            end
            local total = {S1={ju=0}, S2={ju=0}}    -- S1牛牛  S2大小单双 梭哈   
            local coin = 0
            for index, data in pairs(res) do
                if data.bet_type == 1 then
                    total.S1.ju = (total.S1.ju or 0) + 1
                    total.S1.bet_type = data.bet_type
                    total.S1.bet_value = (total.S1.bet_value or 0) + data.total_bet_value
                else
                    total.S2.ju = (total.S2.ju or 0) + 1
                    total.S2.bet_type = data.bet_type
                    total.S2.bet_value = (total.S1.bet_value or 0) + data.total_bet_value
                end                
            end

            local M1 = total.S1.bet_value or 0
            local M2 = total.S2.bet_value or 0

            local average = (M1 + M2/10)/tidy_together_num

            if average < 50 then
                coin = 0
            elseif average < 100 then
                coin = tidy_together_config[tidy_together_num][1] or 0
            else
                coin = tidy_together_config[tidy_together_num][2] or 0
            end

            if coin > 0 then
                local game_owner = g.room_info.gameRoomInfo.gameOwner
                local is_success = return_task_coin(game_owner, user.uid, coin, 3)
    
                local cur_time = time_string(skynet.time())
                local mailContent = string.format("恭喜您在%s集齐%s%d个，奖励金币%d", cur_time, Config.hb_point_collect_type[user.special_type], tidy_together_num, coin)
                _user.add_mail(user.uid, mailContent, 2, coin, is_success)
    
                local player = g.users[user.uid]
                if player then
                    local data = {
                        msg_id = "task_is_success",
                        reward_type = 3,
                        is_success = is_success,
                        content = mailContent,
                        coin = coin,
                        collect_type = Config.hb_point_collect_type[user.special_type],
                        tidy_together_num = tidy_together_num,
                        time = cur_time
                    }
                    send_msg(player.fd, data)
                end
            end

        end
    end
end


local function addTidyTogether(result)
    local result = result.result
    for uid, user in pairs(result) do
        handleUserTidyTogether(user)
    end
end

-- 存储结算相关数据
function cmd.handleResult(result)
    -- --存储结算数据
    -- addResultLog(result)
    --存储每日返利
    addDailyRebate(result)
    --存储连胜
    addWinningStreak(result)
    --存储特殊点
    addSpecialPoint(result)
    -- 存储集齐
    addTidyTogether(result)
end

-- 获取庄闲
function cmd.getZhuangxian(roomid)
    local sql = string.format("SELECT banker_ct,user_ct  FROM t_ct_hb_room WHERE room_id=%s limit 1", roomid)
    local res = db_mgr.execute(sql)
    if table.empty(res) then
        return {}
    end
    return res[1] or {}
end

return cmd
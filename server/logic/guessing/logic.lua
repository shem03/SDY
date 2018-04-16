
local skynet = require("skynet")
local utils = require("guessing.poker_utils")
local core = require("guessing.core")
local json = require("cjson")
local cthttp = require ("cthttp")
local ctuser = require("user.ctcore") 

local logic = {}

-- 必须的函数
--------------------------------------------------------------------------------
-- 初始化
function logic.init_game(user)
    LOG("猜拳游戏：初始化")
end

-- 登录
function logic.login(user)
    LOG("猜拳游戏：玩家登录", json.encode(user))

    -- 发送进入消息
    local data = {
        msg_id = "someone_enter_room",
        uid = user.uid,
        info_data = user
    }
    room_logic.broadcast(data)

    -- 存储玩家登陆信息
    core.handleRoomUser(user)

    logic.game_start()
end

-- 玩家断线，离开房间。
function logic.post_leave(user)
    LOG(string.format("猜拳游戏：玩家离开房间, 玩家ID: %d, 游戏状态：%d", user.id, g.game_step))

    -- 清空连接
    if user.fd ~= nil then
        g.conns[user.fd] = nil
        user.fd = nil
    end

    if not user.is_robot then
        room_logic.leave_agent(user)
    else
        g.robot_user = g.robot_user - 1
    end

    user.offline = true 
    g.users[user.uid] = nil
end

-- 判断玩家是否可以离开房间
function logic.get_user_free(user)
    return true
end

-- 获取剩余时间同步
function logic.get_game_time()
    local timeLeft = 0
    if (g.game_step_limit_time and g.game_time) then 
        timeLeft = g.game_step_limit_time - g.game_time
    end 
    return timeLeft, g.game_step
end

-- 断线后重连
function logic.reconn(fd, id)
    LOG("猜拳游戏：断线重连")

    local res = {
        msg_id = "resume_game",
        step  = g.game_step,
        total_bet_value = g.total_bet_value or 0
    }
    res.time = logic.get_game_time()
    res.bet_list = utils.get_bet_data_list()
    res.punch_list = utils.get_punch_data_list()
    res.winner, res.outcome_status = utils.getGuessingResult(res.punch_list[1], res.punch_list[2])
    res.info = g.step_info

    send_msg(fd, res)
end

----------------------------------------------------------------------------------
function logic.game_start()
    -- 游戏未开始，人数达到猜拳人数，启动下注倒计时
    if (g.game_step == Config.step_none and g.room_info.member_count == 2) then
        LOG("猜拳游戏：游戏开始") 
        logic.bet_start()
    end
end

function logic.game_over(timeLeft)
    g.game_step_lua.game_over(timeLeft)
end

-- 通知玩家开始下注
function logic.bet_start()
    LOG("猜拳游戏：通知玩家开始下注")

    -- 进入下注阶段
    g.game_step_lua.bet_start()

    -- 开始下注
    local data = {
        msg_id = "bet_start",
        time = g.game_step_limit_time,  -- 下注时长
    }
    room_logic.broadcast(data)
end

-- 玩家下注
-- @param bet_type 下注类型
-- @param bet_value 下注值
function logic.betting(user, bet_type, bet_value)
    local bet_type = 0
    local bet_value = bet_value or 0
    
    g.bet_data = g.bet_data or {}

    -- 判断是否下过注
    if g.bet_data[user.id] then 
        return send_error(user.fd, -2, "您已经下过注了", "bet_fail")
    end

    -- 下注金币区间限制
    local minBetValue = 1
    local maxBetValue = 0
    local msg, dec, account = ctuser.get_game_user_account(user.custNo)
    if msg == "ok" then 
        maxBetValue = account.balAmt 
    else 
        send_error(user.fd, -1, dec)
    end
    if bet_value < minBetValue then
        local content = string.format("下注至少需要%d个金币", minBetValue)
        send_error(user.fd, -2, content, "bet_fail")
        return
    elseif bet_value > maxBetValue then
        send_error(user.fd, -2, "您没有足够的金币", "bet_fail")
        return        
    end

    -- 增加游戏中的金币
    local game_coin = bet_value
    local userAccts = {}
    table.insert(userAccts, {
        type = 0,       -- 增加操作
        coin = game_coin,
        custNo = user.custNo,
        waterMemo = "下注金币冻结",
        gameType = g.room_info.gameRoomInfo.gameType
    })
    local msg, dec = core.operatGameResultAcct("admin", "", userAccts)
    if msg ~= "ok" then return send_error(user.fd, -2,  dec, "bet_fail") end

    -- 保存用户下注数据
    g.bet_data[user.id] = g.bet_data[user.id] or {}
    table.insert(g.bet_data[user.id], {
        type = bet_type,
        value = bet_value
    })

    g.players = g.players or {}
    g.players[user.id] = user

    -- 下注总额
    g.total_bet_value = (g.total_bet_value or 0) + bet_value

    -- 发送下注消息
    local data = {
        msg_id = "someone_bet_success",
        uid = user.id,
        bet_value = bet_value,
        bet_type = bet_type,
        total_bet_value = g.total_bet_value
    }
    room_logic.broadcast(data)

    local step_info = string.format("玩家下注，玩家：%s，下注类型：%d，下注值：%d", user.id, bet_type, bet_value)
    LOG(step_info)

    -- 存储游戏操作
    local param = {}
    param.step = Config.step_guess_bet_start
    param.user = user
    param.bet_type = bet_type
    param.bet_value = bet_value
    param.step_info = step_info
    core.addStepData(param)

    -- 双方都主动下注，下注阶段提前结束
    if table.size(g.bet_data) == 2 then 
        g.game_step_lua.bet_end()
    end
end

-- 通知玩家下注结束
function logic.beter_end()
    -- 至少有一方还未下注，游戏提前结束
    local bet_peoples = table.size(g.bet_data or {})
    print("下注人数:", bet_peoples)
    if bet_peoples ~= 2 then
        LOG("===流局===")
        logic.game_flow_bureau()
        return
    end

    -- 下注明细
    local bet_data_list = utils.get_bet_data_list()

    local data = {
        msg_id = "bet_end",
        bet_list = bet_data_list
    }
    room_logic.broadcast(data)

    -- 进入出拳阶段
    logic.punch_start()
end


-- 通知玩家开始出拳
function logic.punch_start()
    LOG("猜拳游戏：通知玩家开始出拳")

    -- 游戏进入出拳阶段
    g.game_step_lua.punch_start()

    -- 开始出拳
    local data = {
        msg_id = "punch_start",
        time = g.game_step_limit_time   -- 出拳时长
    }
    room_logic.broadcast(data)
end

-- 玩家出拳
function logic.punch(user, fist)
    if fist ~= Config.fist_scissors and  
        fist ~= Config.fist_rock and 
        fist ~= Config.fist_paper then 
        send_error(user.fd, -2, "出拳错误", "punches_fail")
    end

    g.punches_data = g.punches_data or {}

    -- 判断是否出过拳
    if g.punches_data[user.id] then 
        return send_error(user.fd, -2, "您已经出过拳", "bet_fail")
    end

    -- 保存玩家出拳数据
    g.punches_data[user.id] = {
        fist = fist
    }

    -- 发送出拳消息
    local data = {
        msg_id = "someone_punches_success",
        uid = user.id,
        fist = fist
    }
    room_logic.broadcast(data)

    local info = string.format("玩家%s主动出拳:%d", user.id, fist)
    LOG(info)

    -- 存储出拳步骤的数据
    local param = {}
    param.step = Config.step_guess_punches_start
    param.user = user
    param.fist = fist
    param.step_info = info
    core.addStepData(param)

    -- 双方都主动出拳，出拳阶段提前结束
    if table.size(g.punches_data) == 2 then 
        g.game_step_lua.punch_end()
    end
end

-- 出拳结束
function logic.punch_end()
    -- 判断玩家是否出拳，如果一方未出拳，则系统代其随机出拳
    g.punches_data = g.punches_data or {} 
    for uid, user in pairs(g.players) do
        if not g.punches_data[uid] then 
            local size = 3  -- 剪刀，石头，布
            local fist = math.random(size)
            local value = {}
            g.punches_data[uid] = value
            value.fist = fist
            local info = string.format("系统为玩家%s随机出拳:%d", uid, fist)
            LOG(info)
            
            -- 存储出拳步骤的数据
            local param = {}
            param.step = Config.step_guess_punches_end
            param.user = user
            param.fist = fist
            param.step_info = info
            core.addStepData(param)
        end
    end 

    -- 推送胜负结果
    logic.push_guessing_result()
end

-- 推送胜负情况
function logic.push_guessing_result()
    -- 出拳明细
    local punch_data_list = utils.get_punch_data_list()

    -- 计算胜负状况(1平局、2一方胜出)
    local winner, outcome_status = utils.getGuessingResult(punch_data_list[1], punch_data_list[2])
    g.winner = winner
    g.outcome_status = outcome_status
    LOG("赢家:", winner)
    LOG("胜负情况:", outcome_status == Config.status_tie and "平局" or "一方胜出")

    -- 进入等待结算阶段
    g.game_step_lua.wait_result()

    -- 下发出拳数据
    local data = {
        msg_id = "push_guessing_result",
        punch_list = punch_data_list,
        time = g.game_step_limit_time,
        winner = g.winner,
        outcome_status = g.outcome_status
    }
    room_logic.broadcast(data)

    -- 有一方胜出，游戏直接进入结算阶段
    if outcome_status == Config.status_someone_win then 
        -- 执行结算逻辑
        logic.game_result()
    end
end

-- 通知玩家重新出拳
function logic.punches_again()
    -- 清空上一把出拳数据
    g.punches_data = nil

    -- 游戏进入出拳阶段
    g.game_step_lua.punch_start()

    local msg = "上一把平局，请重新出拳"
    local info = json.encode({msg})
    local data = {
        msg_id = "punches_again",
        info = info,
        time = g.game_step_limit_time
    }
    room_logic.broadcast(data)
end

-- 结算
function logic.game_result()
    LOG("猜拳游戏：结算")

    -- 进入结算阶段
    g.game_step_lua.game_result()

    -- 平局
    if g.outcome_status == Config.status_tie then
        LOG("===游戏平局，重新出拳===") 
        -- 重新出拳
        logic.punches_again()
        return
    end

    -- 客户账户操作
    local userAccts = {}

    -- 冲还金币，把游戏中的金币先退还到客户账户
    for uid, user in pairs(g.players) do
        local bet_info = g.bet_data[uid]
        local userAcct = {}
        userAcct.type = 1  -- 冲返操作
        userAcct.coin = bet_info[1].value  
        userAcct.custNo = uid
        userAcct.waterMemo = "游戏冲还"
        userAcct.gameType = g.room_info.gameRoomInfo.gameType
        table.insert(userAccts, userAcct)
    end

    -- 输赢结算
    local transfer_coin = 0 
    for uid, bet_info in pairs(g.bet_data) do
        -- 获取输家下注的金币
        if uid ~= g.winner then 
            transfer_coin = bet_info[1].value
            break
        end 
    end
    LOG("输赢结算金币:", transfer_coin)
    for uid, user in pairs(g.players) do
        local userAcct = {}
        table.insert(userAccts, userAcct)
        if g.winner == uid then
            userAcct.type = 2  -- 赢操作
            userAcct.coin = transfer_coin  
            userAcct.custNo = uid
            userAcct.waterMemo = "游戏赢"
            userAcct.gameType = g.room_info.gameRoomInfo.gameType
        else
            userAcct.type = 3  -- 输操作
            userAcct.coin = transfer_coin  
            userAcct.custNo = uid
            userAcct.waterMemo = "游戏输"
            userAcct.gameType = g.room_info.gameRoomInfo.gameType
        end
    end

    -- 结算金币
    local msg, dec = core.operatGameResultAcct("admin", "", userAccts)
    if msg ~= "ok" then
        LOG("结算不成功")
        return send_error(user.fd, -2, dec, "game_result_fail")
    end

    -- 发送游戏结束通知
    local msg = "结算成功，游戏结束"
    g.step_info = json.encode({msg})
    LOG(g.step_info)
    local data = {
        msg_id = "game_over",
        time = logic.get_game_time(),
        winner = g.winner,
        transfer_coin = transfer_coin,
        info = g.step_info,
        status = Config.game_normal_end
    }
    room_logic.broadcast(data)

    logic.game_over()
end

-- 流局
function logic.game_flow_bureau()
    -- 流局了
    g.game_step_lua.flow_bureau()

    local msg = "在规定时间内，一方未下注，游戏结束!"
    g.step_info = json.encode({msg})
    LOG(g.step_info)
    local data = {
        msg_id = "game_over",
        info = g.step_info,
        status = Config.game_flow_bureau,
        time = g.game_step_limit_time,
        bet_list = utils.get_bet_data_list()
    }
    room_logic.broadcast(data)

    -- 存储流局步骤数据
    local param = {}
    param.step = Config.step_guess_flow
    param.user = {}
    core.addStepData(param)

    -- 返还金币
    local userAccts = {}
    for uid, bet_info in pairs(g.bet_data or {}) do
        local userAcct = {} 
        userAcct.type = 1           -- 返还金币操作
        userAcct.coin = bet_info[1].value 
        userAcct.custNo = uid
        userAcct.gameType = g.room_info.gameRoomInfo.gameType
        table.insert(userAccts, userAcct)
    end
    if next(userAccts) then
        local msg, dec = core.operatGameResultAcct("admin", "", userAccts)
        if msg ~= "ok" then
            return send_error(user.fd, -2, dec, "game_flow_bureau_fail")
        end
    end

    logic.game_over()
end

-- 玩家主动退出游戏
function logic.quit_game(user)
    LOG(string.format("猜拳游戏：玩家主动退出游戏, 玩家ID: %d, 游戏状态：%d", user.id, g.game_step))

    -- 判断游戏是否开始，且不在结算阶段
    if (g.game_step > Config.step_none) and 
        (g.game_step ~= Config.step_guess_result) and 
        (g.game_step ~= Config.step_guess_game_over) then
        local userAccts = {}
        local transfer_coin = 0  
        local winner = nil

        -- 金币冲返
        for uid, _ in pairs(g.users) do
            local bet_info = g.bet_data and g.bet_data[uid]
            if bet_info then 
                table.insert(userAccts, {
                    type = 1,       
                    coin = bet_info[1].value,
                    custNo = uid,
                    waterMemo = "金币冲返",
                    gameType = g.room_info.gameRoomInfo.gameType
                })
            end
            if uid == user.id then 
                -- 记录离线玩家下注的金币
                if bet_info then transfer_coin = bet_info[1].value end
            else
                winner = uid 
            end
        end

        if transfer_coin > 0 and winner then 
            LOG("输赢结算金币:", transfer_coin)
            for uid, _ in pairs(g.users) do
                local userAcct = {}
                table.insert(userAccts, userAcct)
                if winner == uid then
                    LOG("游戏赢家:", uid)
                    userAcct.type = 2  -- 赢操作
                    userAcct.coin = transfer_coin  
                    userAcct.custNo = uid
                    userAcct.waterMemo = "游戏赢"
                    userAcct.gameType = g.room_info.gameRoomInfo.gameType
                else
                    LOG("游戏输家:", uid)
                    userAcct.type = 3  -- 输操作
                    userAcct.coin = transfer_coin  
                    userAcct.custNo = uid
                    userAcct.waterMemo = "游戏输"
                    userAcct.gameType = g.room_info.gameRoomInfo.gameType
                end
            end
        end

        if next(userAccts) then 
            local msg, dec = core.operatGameResultAcct("admin", "", userAccts)
            if msg ~= "ok" then
                LOG("结算不成功")
                return send_error(user.fd, -2, dec, "post_leave_fail")
            end
            LOG("结算成功")
        end

        -- 游戏结束
        local timeLeft = 5
        logic.game_over(timeLeft)

        -- 游戏结束
        local msg = "有玩家退出游戏，游戏结束"
        g.step_info = json.encode({msg})
        LOG(g.step_info)
        local data = {
            msg_id = "game_over",
            time = g.game_step_limit_time,
            winner = winner,
            transfer_coin = transfer_coin,
            info = g.step_info,
            status = Config.game_exit_end
        }
        room_logic.broadcast(data)
    else
        -- 游戏结束
        local timeLeft = 5
        logic.game_over(timeLeft)
    end
end

return logic
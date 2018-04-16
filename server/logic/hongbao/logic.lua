local skynet = require "skynet"
local db_mgr = require("db_mgr")
local core   = require("hongbao.core")
local user_core   = require("user.ctcore")
local room_core   = require("room.core")
local utils  = require("hongbao.poker_utils")
local cheat  = require("hongbao.cheat")
local json = require "cjson"
local logic = {}

-- 初始化
function logic.init_game(user)
    -- 获取round
    if g.round == 0 then
        g.round = core.getRound(g.room_info.gameRoomInfo.gameGroupId)
    end
    print("g.round:=================》", g.round)

    -- 下发下注倍率配置
    local data = {
        msg_id = "bet_rate_config",
        config = utils.getAllRates(),
        task_config = {
            [1] = Config.hb_winning_streak_config,
            [2] = Config.hb_special_config,
            [3] = Config.hb_tidy_together_config,
        },
        bet_range_config = Config.hb_bet_range_config[g.room_info.gameRoomInfo.gameGradeType] or Config.hb_bet_range_config["8B"],
        barrage_card = Config.barrage_card  -- 每一条弹幕需消耗的弹幕卡数
    }

    send_msg(user.fd, data)
end

-- 登录
function logic.login(user)
    -- 发送进入消息
    local data = {
        msg_id = "someone_enter_room",
        uid    = user.uid,
        infoData = user --room_logic.get_userinfo(user)
    }
    --print(user)
    room_logic.broadcast(data)
   
    -- 存储房间用户
    core.handleRoomUser(user)

end

-- 确实离开房间，不会再回来
function logic.post_leave(user)
    print("logic.post_leave========================》", user.id, g.game_step)

    if user.fd ~= nil then
        g.conns[user.fd] = nil
        user.fd = nil
    end

    -- 如果游戏中不清空数据
    if g.game_step ~= Config.step_none then
        user.offline = true
    else
        g.users[user.id] = nil
        logic.someone_quit(user.id)
    end

    if not user.is_robot then
        room_logic.leave_agent(user)
    else
        g.robot_user = g.robot_user - 1
    end

end

-- 获取剩余时间同步
function logic.get_game_time()
    local resumeTime = 0
    if g.game_step == Config.step_bet then
        resumeTime = Config.hb_bet_time - g.game_time
    elseif g.game_step == Config.step_send then 
        resumeTime = Config.hb_wait_send - g.game_time
    elseif g.game_step == Config.step_qiang then
        resumeTime   = Config.hb_qiang_time - g.game_time
    elseif g.game_step == Config.step_wait_result then
        resumeTime = Config.hb_wait_result_time - g.game_time
    elseif g.game_step == Config.step_result then
        resumeTime = Config.hb_reuslt_time - g.game_time
    end
    return resumeTime, g.game_step
end

--[[
    step_rob    = 1,		-- 抢庄
	step_bet    = 2,		-- 下注
	step_send   = 3,		-- 发包
	step_qiang  = 4,		-- 抢包
	step_result = 5,		-- 结算
	step_end	= 6,		-- 结束
	step_flow	= 7,		-- 流局
]]

-- 断线重连
function logic.reconn(fd, id)
    print("断线重连")

    -- 查询播报信息列表
    if next(g.report_info_list) == nil then
        local info_list = room_core.get_report_info_list(g.room_info.gameRoomInfo.gameGroupId, Config.hb_report_info_num)
        if info_list and next(info_list) then 
            for i = 1, #info_list do
                table.insert(g.report_info_list, 1, info_list[i])
            end
        end 
    end

    local res = {
        msg_id = "resume_game",
        state  = g.game_step,
        banker = g.banker,
        banker_name = g.banker_name,
        bankerCoin = g.bankerGameCoin,
        game_round_id = g.roundid,
        game_group_id = g.room_info.gameRoomInfo.gameGroupId,
        game_group_owner = g.room_info.gameRoomInfo.gameOwner,
        banker_surplus_coin =  g.bankerSurplusCoin,
        info_list = g.report_info_list,
        total_bet_value = g.total_bet_value or 0,
    }
    if g.banker and g.players[g.banker] then
        local banerData = g.players[g.banker] or {} 
        res.user_avatar = banerData.user_avatar
    end
    if g.game_step == Config.step_bet then
        res.resumeTime = Config.hb_bet_time - g.game_time
        res.bet_data   = g.bet_data
    elseif g.game_step == Config.step_send then 
        res.resumeTime = Config.hb_wait_send - g.game_time
        res.bet_data   = g.bet_data
    elseif g.game_step == Config.step_qiang then
        res.resumeTime   = Config.hb_qiang_time - g.game_time
        res.packets  = g.packets
    elseif g.game_step == Config.step_wait_result then
        res.resumeTime   = Config.hb_wait_result_time - g.game_time
        res.packets  = g.packets
    elseif g.game_step == Config.step_result then
        res.resumeTime = Config.hb_reuslt_time - g.game_time
        res.result = g.result
    elseif g.game_step == Config.step_biao then
        res.resumeTime = Config.hb_biao_time - g.game_time
    end

    send_msg(fd, res)
end

-- 有人退出房间
function logic.someone_quit(uid)

end

-- 判断玩家是否在游戏中，是否可离开
function logic.get_user_free(user)
    local bets = g.bet_data or {}
    print(user.id == g.banker , user.id, g.banker,  bets[user.id])
    if user.id == g.banker or bets[user.id] ~= nil or g.robot_user > 0 then
        return false  
    end
    return true
end

---------------------------------------------------------------------------------------------
-- 冻结房间钻石
function logic.freezeRoomGold()
    local msg, dec = core.freezeRoomGold(g.room_info.gameRoomInfo.gameGroupId, Config.hb_room_water)
    return msg, dec
end

-- 抢庄
function logic.rob_banker(user, coin)
    if coin > 10000000 then
        return send_error(user.fd, -2, "亲，你抢庄金额太高了~", "someone_rob_banker_fail")
    end

    local minLimit = tonumber(g.room_info.gameRoomInfo.gameBankerLimitAmt or 0)
    if coin < minLimit/100 then
        return send_error(user.fd, -2, g.room_info.gameRoomInfo.gameGradeTypeName or "", "someone_rob_banker_fail")
    end

    local maxLimit = tonumber(g.room_info.gameRoomInfo.gameBankerMaxLimitAmt or 0)
    if maxLimit > 0 and coin > maxLimit/100 then
        return send_error(user.fd, -2, g.room_info.gameRoomInfo.gameGradeTypeName or "", "someone_rob_banker_fail")
    end

    -- 房间钻石
    local msg, dec = core.freezeRoomGold(g.room_info.gameRoomInfo.gameGroupId, Config.hb_room_water)
    if msg ~= "ok" then
        return send_error(user.fd, -2, msg == "B002" and "房间钻石不足" or dec, "someone_rob_banker_fail")
    end

    -- 用户金币
    -- local msg, dec = core.addUserGameCoin(user, coin)
    local userAccts = {}
    table.insert(userAccts, {
        type = 0,
        coin = coin,
        custNo = user.custNo,
        waterMemo = "上庄金币冻结",
        gameType = g.room_info.gameRoomInfo.gameType
    })
    local msg, dec = core.operatGameResultAcct("admin", "", userAccts)
    if msg ~= "ok" then
        return send_error(user.fd, -2, dec, "someone_rob_banker_fail")
    end

    g.banker = user.id
    g.banker_name = user.name
    g.bankerCoin = coin
    g.bankerGameCoin = coin
    g.bankerSurplusCoin = coin -- 房间游戏中剩余金币
    g.players = g.players or {}
    g.players[user.id] = user
    print(g.players)

    local stepInfo = json.encode({"%s上庄成功！金币:%s！", user.name, coin})
    room_core.save_report_info(Config.msg_type_system, stepInfo, user.id)
    -- 上庄成功
    local data = {  
        msg_id = "someone_rob_banker_success",
        uid = user.id,
        name = user.name,
        coin = coin,
        banker_surplus_coin =  g.bankerSurplusCoin,
        info = stepInfo,
        msg_type = Config.msg_type_system
    }
    room_logic.broadcast(data)

    -- 游戏开始  抢庄驱动游戏开始
    local isBiao = true
    local query_result = room_core.query_room_info(g.room_info.gameRoomInfo.gameGroupId)
    if query_result.banker_type and tonumber(query_result.banker_type) == 2 then
        isBiao = false
    end
    g.game_step_lua.game_start(isBiao)

    -- 存储抢庄步骤数据
    local params = {}
    params.user = user
    params.coin = coin
    params.stepInfo = stepInfo
    core.addStepData(Config.step_rob, params)
end

-- 下庄
function logic.down_banker(user, message)
    -- 游戏中金币转到用户金币
    -- local msg, dec = core.reduceUserGameCoin(user, g.bankerGameCoin)
    local userAccts = {}
    table.insert(userAccts, {
        type = 1,
        coin = g.bankerGameCoin,
        custNo = user.custNo,
        waterMemo = "下庄金币返还",
        gameType = g.room_info.gameRoomInfo.gameType
    })
    local msg, dec = core.operatGameResultAcct("admin", "", userAccts)
    if msg ~= "ok" then
        LOG("下庄失败", g.bankerGameCoin)
        send_error(user.fd, -2, dec, "someone_rob_banker_fail")
        return
    end
    local stepInfo = message
    if message then
        stepInfo = json.encode({message})
    else
        stepInfo = json.encode({"%s已下庄！赶快去上庄吧！", user.name}) 
    end
    
    room_core.save_report_info(Config.msg_type_system, stepInfo, user.id)

    -- 下庄成功
    local data = {  
        msg_id = "someone_down_banker_success",
        uid = user.id,
        name = user.name,
        msg = message or "下庄成功",
        info = stepInfo,
        msg_type = Config.msg_type_system
    }
    room_logic.broadcast(data)

    --下庄清空数据
    g.bankerCoin = 0
    g.bankerGameCoin = 0
    g.bankerSurplusCoin = 0
    g.banker = nil
    g.banker_name = nil
    g.players = nil
    
    g.game_time = Config.hb_reuslt_time

end

-- 开始标庄
function logic.biao_start()
    -- 开始下注
    local data = {
        msg_id = "biao_start",
        time   = Config.hb_biao_time,
        banker_surplus_coin =  g.bankerSurplusCoin,
    }
    room_logic.broadcast(data)
end

-- 标庄
function logic.biao_banker(user, coin)

    if coin > 10000000 then
        return send_error(user.fd, -2, "亲，你标庄金额太高了~", "someone_biao_banker_fail")
    end

    local maxLimit = tonumber(g.room_info.gameRoomInfo.gameBankerMaxLimitAmt or 0)
    if maxLimit > 0 and coin > maxLimit/100 then
        return send_error(user.fd, -2, g.room_info.gameRoomInfo.gameGradeTypeName or "", "someone_rob_banker_fail")
    end

    if g.bankerGameCoin >= coin then
        return send_error(user.fd, -2, "抢庄失败，抢庄金币少于庄家金币~", "someone_biao_banker_fail")
    end

    -- 玩家不同直接先操作玩家，后再返还庄家（防止出现庄家游戏中为0，而玩家却标庄系统异常，导致卡住）
    if user.id ~= g.banker then
        -- 用户金币
        print("不同", coin)
        -- local msg, dec = core.addUserGameCoin(user, coin)
        local userAccts = {}
        table.insert(userAccts, {
            type = 0,
            coin = coin,
            custNo = user.custNo,
            waterMemo = "标庄金币冻结",
            gameType = g.room_info.gameRoomInfo.gameType
        })
        local msg, dec = core.operatGameResultAcct("admin", "", userAccts)
        if msg ~= "ok" then
            return send_error(user.fd, -2, dec, "someone_biao_banker_fail")
        end

        -- 返还上个庄家游戏中金币
        -- local msg, dec = core.reduceUserGameCoin(user, g.bankerGameCoin, g.banker)
        local userAccts = {}
        table.insert(userAccts, {
            type = 1,
            coin = g.bankerGameCoin,
            custNo = g.banker,
            waterMemo = "标庄返还庄家金币",
            gameType = g.room_info.gameRoomInfo.gameType
        })
        local msg, dec = core.operatGameResultAcct("admin", "", userAccts)
        if msg ~= "ok" then
            return send_error(user.fd, -2, dec, "someone_biao_banker_fail")
        end
    else
        local offsetCoin = coin - g.bankerGameCoin
        print("相同庄", offsetCoin)
        -- 用户金币
        -- local msg, dec = core.addUserGameCoin(user, offsetCoin)
        local userAccts = {}
        table.insert(userAccts, {
            type = 0,
            coin = offsetCoin,
            custNo = user.custNo,
            waterMemo = "庄家标庄金币冻结",
            gameType = g.room_info.gameRoomInfo.gameType
        })
        local msg, dec = core.operatGameResultAcct("admin", "", userAccts)
        if msg ~= "ok" then
            return send_error(user.fd, -2, dec, "someone_biao_banker_fail")
        end
    end

    g.banker = user.id
    g.banker_name = user.name
    g.bankerCoin = coin
    g.bankerGameCoin = coin
    g.bankerSurplusCoin = coin -- 房间游戏中剩余金币
    g.players = {}
    g.players[user.id] = user
    -- print(g.players)

    local stepInfo = json.encode({"%s抢庄成功！金币:%s", user.name, coin})
    room_core.save_report_info(Config.msg_type_system, stepInfo, user.id)
    -- 抢庄成功
    local data = {  
        msg_id = "someone_biao_banker_success",
        uid = user.id,
        name = user.name,
        coin = coin,
        banker_surplus_coin =  g.bankerSurplusCoin,
        info = stepInfo,
        msg_type = Config.msg_type_system
    }
    room_logic.broadcast(data)

    -- 存储抢庄步骤数据
    local params = {}
    params.user = user
    params.coin = coin
    params.stepInfo = stepInfo
    core.addStepData(Config.step_biao, params)
end

-- 标庄结束
function logic.stop_biao()
    local stepInfo = json.encode({"本局抢庄结束！"})
    room_core.save_report_info(Config.msg_type_system, stepInfo)

    -- 开始下注
    local data = {
        msg_id = "robBiaoBankerTimeout",
        info = stepInfo,
        msg_type = Config.msg_type_system,
        roundBankerCustNo = g.banker,
        roundBankerCustName = g.banker_name,
        -- time   = Config.hb_bet_time,
        banker_surplus_coin =  g.bankerSurplusCoin,
    }
    room_logic.broadcast(data)
end

-- 开始下注
function logic.beter_start()
    -- 开始下注
    local data = {
        msg_id = "bet_start",
        time   = Config.hb_bet_time,
        banker_surplus_coin =  g.bankerSurplusCoin,
    }
    room_logic.broadcast(data)

    -- 清空下注数据
    g.total_bet_value = 0
    g.total_bet_data  = nil
    g.bet_data        = nil
end

-- 下注
function logic.beter(user, bet_type, bet_sub_type, bet_value)
    g.bet_data     = g.bet_data or {}

    if g.bet_data[user.id] ~= nil then
        for index, value in pairs(g.bet_data[user.id]) do
            if value.type ~= bet_type then
                return  send_error(user.fd, -2, "只允许选中一种方式下注~", "bet_fail")
            else
                if value.type == Config.hb_bet_special_point then
                    if value.sub_type == bet_sub_type then
                        return send_error(user.fd, -2, "该点数只允许下注一次~", "bet_fail")
                    end
                else
                    return send_error(user.fd, -2, "该类型只允许下注一次~", "bet_fail")
                end
            end
        end
    else
        print("亲，你可以下注")
    end

    LOG("下注数据--如下")
    -- print(bet_type, bet_sub_type, bet_value, "=========")
    LOG(string.format("logic.beter() ---> bet_type:%d bet_sub_type:%d bet_value:%d", bet_type or 0, bet_sub_type or 0, bet_value or 0))

    -- 目前除了特码其他都只能选择一种类型下注
    LOG(string.format("logic.beter222() ---> bet_data:%s", json.encode(g.bet_data or {})))

    -- 判断下注区间
    local bet_range_config = Config.hb_bet_range_config[g.room_info.gameRoomInfo.gameGradeType] or Config.hb_bet_range_config["8B"]
    local minBetValue = bet_range_config[bet_type][1]
    local maxBetValue = bet_range_config[bet_type][2]
    if bet_value < minBetValue or bet_value > maxBetValue then
        local content = string.format("下注失败，下注区间为%d~%d", minBetValue, maxBetValue)
        print(content)
        send_error(user.fd, -2, content, "bet_fail")
        return
    end


    -- 庄家扣除游戏中金币
    local bankerReduceCoin = 0
    if bet_type == 1 or bet_type == 2 or bet_type == 4 then
        bankerReduceCoin = utils.getMaxRate(bet_type) * bet_value
    else
        bankerReduceCoin = utils.getRate(bet_type, bet_sub_type) * bet_value
    end

     -- 计算剩余下注
     local surplusCoin =  g.bankerSurplusCoin - bankerReduceCoin
     print("surplusCoin====>", surplusCoin)
     if surplusCoin < 0 then
         print("下注失败，超出上庄金币范围")
         return send_error(user.fd, -2, "下注失败，超出上庄金币范围", "bet_fail")
     end

    -- 用户游戏中金币
    local game_coin = 0
    if bet_type ~= 1 then
        game_coin = bet_value
    else
        game_coin = utils.getMaxRate(bet_type) * bet_value
    end
    print("1111=============>", utils.getMaxRate(bet_type), utils.getRate(bet_type, bet_sub_type))

    -- 操作游戏中的金币 + 增加游戏中的金币
    -- local msg, dec = core.addUserGameCoin(user, game_coin)
    local userAccts = {}
    table.insert(userAccts, {
        type = 0,
        coin = game_coin,
        custNo = user.custNo,
        waterMemo = "下注金币冻结",
        gameType = g.room_info.gameRoomInfo.gameType
    })
    local msg, dec = core.operatGameResultAcct("admin", "", userAccts)
    if msg ~= "ok" then
        print("下注失败，bet_fail")
        return send_error(user.fd, -2, dec, "bet_fail")
    end

    -- 下注数据
    g.bet_data[user.id] = g.bet_data[user.id] or {}    

    -- 下注总额
    g.total_bet_value = (g.total_bet_value or 0) + bet_value

    -- 保存用户操作
    table.insert(g.bet_data[user.id], {
        type     = bet_type,
        sub_type = bet_sub_type,
        value    = bet_value
    })

    -- 操作庄家游戏剩余金币
    g.bankerSurplusCoin = surplusCoin

    -- 统计下注金额
    g.total_bet_data = g.total_bet_data or {}
    g.total_bet_data[user.id] =   g.total_bet_data[user.id] or {}
    local total_bet_data =  g.total_bet_data[user.id]
    local canInsert      = true

    for k, v in pairs(total_bet_data) do    
        if bet_type == v.type and bet_sub_type == v.sub_type then
            v.value = v.value + bet_value
            v.game_coin = v.game_coin + game_coin
            canInsert = false
        end
    end

    if canInsert then
        table.insert(g.total_bet_data[user.id], {
            type     = bet_type,
            sub_type = bet_sub_type,
            value    = bet_value,
            game_coin= game_coin 
        })
    end
    
    g.players = g.players or {}
    g.players[user.id] = user

    local bet_list = g.bet_data[user.id]

    local typeName = utils.getBetTypeName(bet_type)
    if bet_sub_type then
        if bet_type == 3 then
            typeName = utils.getSubBetTypeName(bet_type, bet_sub_type)
        else
            typeName = typeName .. utils.getSubBetTypeName(bet_type, bet_sub_type)
        end
        
    end

    local stepInfo = json.encode({"%s下注%s%s金币", user.name, typeName, bet_value})
    room_core.save_report_info(Config.msg_type_system, stepInfo, user.id)

    -- 发送下注消息
    local data = {
        msg_id       = "someone_bet_success",
        uid          = user.id,
        bet_value    = bet_value,
        bet_type     = bet_type,
        bet_sub_type = bet_sub_type,
        bet_list     = bet_list,
        total_bet_value = g.total_bet_value,
        banker_surplus_coin =  g.bankerSurplusCoin,
        info         = stepInfo,
        msg_type = Config.msg_type_system
    }

    room_logic.broadcast(data)

    -- 存储下注步骤数据
    local params = {}
    params.user = user
    params.bet_type = bet_type
    params.bet_sub_type = bet_sub_type
    params.bet_value = bet_value
    params.stepInfo = stepInfo
    core.addStepData(Config.step_bet, params)
end

-- 下注结束
function logic.stop_beter()

    local stepInfo = json.encode({"本局下注结束！"})
    room_core.save_report_info(Config.msg_type_system, stepInfo)
    -- 开始下注
    local data = {
        msg_id = "beterTimeout",
        info         = stepInfo,
        msg_type = Config.msg_type_system,
        -- time   = Config.hb_bet_time,
        -- banker_surplus_coin =  g.bankerSurplusCoin,
    }
    room_logic.broadcast(data)
end

-- 等待发包
function logic.wait_send()
    -- 下注明细
    local bet_data_list = {}
    for k, v in pairs(g.bet_data) do
        local user = g.players[k] or {}
        local bet_data = {
            name = user.name or "",
            uid  = k,
            bet_type = 1,
            bet_type_name = "",
            total_bet_coin = 0,
            bet_sub_type_names = nil,
        }
        for k1, betData in pairs(v) do
            bet_data.total_bet_coin = bet_data.total_bet_coin + betData.value
            bet_data.bet_type = betData.type
            bet_data.bet_type_name = utils.getSubBetTypeName(betData.type)
            local bet_info = utils.getSubBetTypeName(betData.type, betData.sub_type)
            if betData.type == 4 then
                bet_info = bet_info  .. "(" .. betData.value .. ")"
            end
            if bet_data.bet_sub_type_names == nil then
                bet_data.bet_sub_type_names = bet_info
            else
                bet_data.bet_sub_type_names = bet_data.bet_sub_type_names .. " " .. bet_info 
            end
        end

        table.insert(bet_data_list, bet_data)
        
    end

    local data = {
        msg_id  = "wait_send_packet",
        time    = Config.hb_wait_send,
        banker  = g.banker,
        round_num = g.round,
        bet_list= bet_data_list,
    }
    
    room_logic.broadcast(data)
end

-- 发包
function logic.send_packet(user, packers)
    -- 生成分配红包
    local people = table.size(g.bet_data or {}) + 1
    local money  = 2 * people

    local roomData = core.getZhuangxian(g.room_info.gameRoomInfo.gameGroupId)
    local banker_ct = roomData.banker_ct
    local user_ct   = roomData.user_ct
    if banker_ct == 1 or user_ct == 1 then
        cheat.assign_red_packet(money, people, roomData)
    else
        utils.assign_red_packet(money, people)
    end

    local banerData = g.players[g.banker]

    -- local stepInfo = json.encode({"红包已到达，开始抢红包！"})
    -- room_core.save_report_info(Config.msg_type_system, stepInfo)
    -- 开始抢包
    local data = {
        msg_id  = "packet_arrivals",
        packets = g.packets,
        time    = Config.hb_qiang_time,
        banker  = g.banker,
        banker_name = banerData.name,
        banker_avatar = banerData.user_avatar,
        -- info = stepInfo
        -- msg_type = Config.msg_type_system
    }
    room_logic.broadcast(data)

    -- 存储发包步骤数据
    local params = {}
    params.user = {}
    params.packers = g.packets
    core.addStepData(Config.step_send, params)
end

-- 打开红包
function logic.open_red_packet(user)
    local packet        = g.packets[user.id] or {}
    packet.open         = true
    packet.open_time    = time_string(os.time())
    packet.uid          = user.id or ""
    packet.name         = user.name or ""
    packet.avatar       = user.user_avatar or ""
    packet.isBanker     = user.id == g.banker

    local opens    = {}
    local data = {
        msg_id       = "someone_open_red_packet",
        -- uid          = user.id,
        packet_value = packet.value,
        packets      = g.packets,
    }
    room_logic.broadcast(data)

    -- -- 红包全打开直接结算
    -- local isAllOpen = true
    -- for k, v in pairs(g.packets) do
    --     if v.open == false then
    --         isAllOpen = false
    --         break
    --     end
    -- end
    -- if isAllOpen then
    --     g.game_step_lua.game_reuslt()
    -- end

    -- 存储抢包步骤数据
    local params = {}
    params.user = user
    params.packet_value = packet.value
    params.packet_open = tonumber(packet.open)
    core.addStepData(Config.step_qiang, params)
end

-- 刮红包
function logic.gua_red_packet(user)
    local packet        = g.packets[user.id] or {}
    packet.isGua        = true
    packet.gua_time     = time_string(os.time())

    local info = utils.getCowData(packet.value)[1]

    local opens    = {}
    local data = {
        msg_id       = "someone_gua_red_packet",
        uid          = user.id,
        name         = user.name,
        packets      = g.packets,
        point_type      = info.point_type
    }
    room_logic.broadcast(data)
end

-- 等待结算，留时间用户查看抢包详情
function logic.wait_game_result()
    local outTime = time_string(os.time())
    for k, v in pairs(g.packets) do
        if not v.open then
            user = g.players[k]
            v.open         = true
            v.open_time    = outTime
            v.uid          = user.id or ""
            v.name         = user.name or ""
            v.avatar       = user.user_avatar or ""
            v.isBanker     = user.id == g.banker
            v.isGua        = true
            v.gua_time     = outTime
            v.is_out_time  = 1
        end
        
    end

    local data = {
        msg_id = "wait_game_result",
        time    = Config.hb_wait_result_time,
        packets      = g.packets,
    }
    room_logic.broadcast(data)
end

-- 生成结算
function logic.game_result()
    -- 生成结算
    print("result===>", g.banker, g.packets, g.total_bet_data)
    -- 打日志
    LOG(string.format("logic.game_result() ---> g.banker:%s packets:%s total_bet_data:%s", 
    g.banker or "", json.encode(g.packets or {}), json.encode(g.total_bet_data or {})))

    local result = utils.getResult(g.banker, g.packets, g.total_bet_data, g.players)
    LOG(json.encode(result), "============开始结算==============")

    -- 输赢金币处理2
    -- 返回游戏中
    local userAccts = {}
    for k, v in pairs(result) do
        local userTotalBet = g.total_bet_data[v.uid] or {}
        local userGameCoin = 0
        for j, h in pairs(userTotalBet) do
            userGameCoin = userGameCoin + h.game_coin
        end
        local userAcct = {}
        userAcct.type = 1
        userAcct.coin = v.isBanker and g.bankerGameCoin or userGameCoin
        userAcct.custNo = v.uid
        userAcct.gameType = g.room_info.gameRoomInfo.gameType
        table.insert(userAccts, userAcct)
    end

    -- 输赢
    local pumps = {}
    for k, v in pairs(result) do
        local userAcct = {}
        if v.coinChange > 0 then
            userAcct.type = 2
        elseif v.coinChange < 0 then
            userAcct.type = 3
        end

        local coin = math.abs(v.coinChange)
        if v.coinChange > 0 then
            if v.isBanker then
                local pump = coin*Config.hb_banker_win_pump_rate
                userAcct.coin = coin
                pumps[v.uid] = {isbanker = true, coin = pump}

                v.originalCoinChange = coin
                v.coinChange = tonumber(string.format("%.2f", coin - pump)) -- 庄家抽佣
                g.bankerGameCoin = g.bankerGameCoin + v.coinChange
            else
                local pump = coin*Config.hb_user_win_pump_rate
                userAcct.coin = coin
                pumps[v.uid] = {coin = pump}

                v.originalCoinChange = coin
                v.coinChange = tonumber(string.format("%.2f", coin - pump)) -- 闲家抽佣
            end
        else
            userAcct.coin = coin
            v.originalCoinChange = coin
            if v.isBanker then
                g.bankerGameCoin = tonumber(string.format("%.2f", g.bankerGameCoin - coin))
            end
        end

        userAcct.custNo = v.uid
        userAcct.gameType = g.room_info.gameRoomInfo.gameType
        table.insert(userAccts, userAcct)
    end

    -- 抽佣
    --庄赢抽佣 M=盈利金额*6%
    --闲赢抽佣 M=盈利金额*3%
    local game_owner = g.room_info.gameRoomInfo.gameOwner
    for uid, pump in pairs(pumps) do
        -- 抽出钱
        local userAcct = {}
        userAcct.type = 7
        userAcct.coin = pump.coin
        userAcct.custNo = uid
        userAcct.waterType = "97"
        userAcct.waterMemo = pump.isbanker == true and "庄家抽佣" or "闲家抽佣"
        userAcct.gameType = g.room_info.gameRoomInfo.gameType
        table.insert(userAccts, userAcct)

        -- 抽给房主
        local userAcct = {}
        userAcct.type = 6
        userAcct.coin = pump.coin
        userAcct.custNo = game_owner
        userAcct.waterType = "98"
        userAcct.waterMemo = pump.isbanker == true and "房主收到庄家抽佣" or "房主收到闲家抽佣"
        userAcct.gameType = g.room_info.gameRoomInfo.gameType
        table.insert(userAccts, userAcct)
    end

    --房主收益：房主收益组成=上庄抽佣+庄赢抽佣+闲赢抽佣
    --上庄抽佣 M=下注玩家数N*50
    --上庄金币不够了，扣光上庄金币
    local rob_banker_coin = table.size(g.bet_data or {})*Config.hb_rob_banker_pump_rate
    local rob_banker_pump = rob_banker_coin
    if g.bankerGameCoin < rob_banker_coin then
        rob_banker_pump = g.bankerGameCoin
    end

    -- 金币到上庄抽佣
    local userAcct = {}
    userAcct.type = 7
    userAcct.coin = rob_banker_pump
    userAcct.custNo = g.banker
    userAcct.waterType = "70"
    userAcct.waterMemo = "上庄抽佣"
    userAcct.gameType = g.room_info.gameRoomInfo.gameType
    table.insert(userAccts, userAcct)

    -- 抽给房主
    local userAcct = {}
    userAcct.type = 6
    userAcct.coin = rob_banker_pump
    userAcct.custNo = game_owner
    userAcct.waterType = "07"
    userAcct.waterMemo = "房主收到上庄抽佣"
    userAcct.gameType = g.room_info.gameRoomInfo.gameType
    table.insert(userAccts, userAcct)

    -- 扣除上庄抽佣那部分金额
    for k, v in pairs(result) do
        if v.isBanker then
            v.coinChange = tonumber(string.format("%.2f", v.coinChange - rob_banker_pump))
        end
    end 

    local bankerGameCoin = tonumber(string.format("%.2f", g.bankerGameCoin - rob_banker_pump))
     --上庄金币 庄家金币到游戏中
    local userAcct = {}
    userAcct.type = 0
    userAcct.coin = bankerGameCoin
    userAcct.custNo = g.banker
    userAcct.waterMemo = "上庄金额冻结款"
    userAcct.gameType = g.room_info.gameRoomInfo.gameType
    table.insert(userAccts, userAcct)

    LOG("")
    LOG("==================================》扣除金币 Start《==================================")
    -- LOG(json.encode(userAccts))
    LOG("==================================》 扣除金币 End 《==================================")
    LOG("")

    --存储结算数据
    LOG("房结算数据")
    core.addResultLog({result = result})
    LOG("房结算数据-over")
    local user = g.players[g.banker]
    -- 扣除房间钻石
    local msg, dec = core.reduceRoomGold(g.room_info.gameRoomInfo.gameGroupId, Config.hb_room_water)
    if msg ~= "ok" then
        LOG("房间钻石不足")
        return send_error(user.fd, -2, msg == "B002" and "房间钻石不足" or dec, "game_flow__fail")
    end

    -- 金币输赢
    print("开始结算扣钱")
    local msg, dec = core.operatGameResultAcct(user.custNo, user.token, userAccts)
    print("开始结算扣钱结果", msg, dec)
    if msg ~= "ok" then
        LOG("结算---》账号余额不足==结算", g.bankerGameCoin, g.bankerSurplusCoin )
        return send_error(user.fd, -2, msg == "B002" and "账户余额不足" or dec, "game_result_fail")
    end
    LOG("结算成功")
    -- 存储步骤
    local stepInfo = json.encode({"本局游戏结束，等待下局开始！"})
    room_core.save_report_info(Config.msg_type_system, stepInfo)

    -- 庄家金币
    g.bankerGameCoin =  bankerGameCoin

    -- 刷新剩余的游戏中金币
    g.bankerSurplusCoin = g.bankerGameCoin

    -- 结算
    g.result = result
    print("result:", g.result)
    local data = {
        msg_id    = "game_result",
        op_time   = time_string(os.time()),
        round_id  = g.roundid,
        round_num = g.round,
        result    = result,
        time    = Config.hb_reuslt_time,
        info    = stepInfo,
        msg_type = Config.msg_type_system,
        banker_game_coin = g.bankerGameCoin,  -- 庄家游戏中金币
        banker_surplus_coin =  g.bankerSurplusCoin,
    }
    room_logic.broadcast(data)

    -- 存储结算
    data.time = os.time()

    -- 存储结算步骤数据
    local params = {}
    params.user = user
    core.addStepData(Config.step_result, params)

    -- 存储处理结算操作
    core.handleResult(data)

    -- 更新局数局数
    g.game_logic.updateGameRound()

    -- 判断是否下庄
    print("==================>", "dsadsadsadsa", g.bankerGameCoin)
    -- 1 抢庄模式  2 连庄模式
    local query_result = room_core.query_room_info(g.room_info.gameRoomInfo.gameGroupId)
    if g.banker and tonumber(query_result.banker_type) == 2 then
        if user.offline == true then
            g.game_logic.down_banker(user, "庄家离线已自动下庄！")
        elseif g.bankerGameCoin < g.room_info.gameRoomInfo.gameBankerLimitAmt/100 then
            g.game_logic.down_banker(user, "庄家金额不足已自动下庄！")
        end
    else
        g.game_logic.down_banker(user)
    end
end

-- 局流局
function logic.game_flow_bureau()
    -- 返还房间钻石
    local user = g.players[g.banker]
    local msg, dec = core.returnRoomGold(g.room_info.gameRoomInfo.gameGroupId, Config.hb_room_water)
    print("msg, dec2===>", msg, dec)
    if msg ~= "ok" then
        print("msg, dec===>", msg, dec)
        return send_error(user.fd, -2, msg == "B002" and "房间钻石不足" or dec, "game_flow__fail")
    end
    
    -- 流局了
    local msg = string.format("流局，人数不足%d人！", Config.hb_minimum_bet)
    local stepInfo = json.encode({msg})
    room_core.save_report_info(Config.msg_type_system, stepInfo)
    local data = {
        msg_id = "game_flow_bureau",
        msg    = msg,
        time   = Config.hb_reuslt_time,
        info   = stepInfo,
        msg_type = Config.msg_type_system
    }
    room_logic.broadcast(data)

    -- 存储流局步骤数据
    local params = {}
    params.user = user
    core.addStepData(Config.step_flow, params)

    -- 刷新剩余的游戏中金币（流局重置剩余金币）
    g.bankerSurplusCoin = g.bankerGameCoin

    -- 返还金币
    local userAccts = {}
    for uid, bet in pairs(g.total_bet_data or {}) do
        local userTotalBet = bet or {}
        local userGameCoin = 0
        for j, h in pairs(userTotalBet) do
            userGameCoin = userGameCoin + h.game_coin
        end
        local userAcct = {}
        userAcct.type = 1
        userAcct.coin = userGameCoin
        userAcct.custNo = uid
        userAcct.gameType = g.room_info.gameRoomInfo.gameType
        table.insert(userAccts, userAcct)
    end
    if table.size(userAccts) == 0 then
        return
    end
    local msg, dec = core.operatGameResultAcct(user.custNo, user.token, userAccts)
    if msg ~= "ok" then
        print("账号余额不足==流局")
        return send_error(user.fd, -2, msg == "B002" and "账户余额不足" or dec, "game_flow_bureau_fail")
    end

    -- 1 抢庄模式  2 连庄模式
    local query_result = room_core.query_room_info(g.room_info.gameRoomInfo.gameGroupId)
    if tonumber(query_result.banker_type) == 1 then
        g.game_logic.down_banker(user)
    end
end

-- 局结算
function logic.game_round_over()
    -- 一局结束 GAME_OVER
    local end_data = {
        msg_id = "game_round_over",
    }
    room_logic.broadcast(end_data)
end

-- 游戏结束
function logic.updateGameRound()
    -- 局数
    core.updateGameRound()

    -- 下一局缓存+1
    g.round = g.round + 1
end

function logic.get_room_online_user(user)
    local end_data = {
        msg_id = "get_room_online_user",
        uid = user.uid,
        user_list = g.conns or {}
    }
    -- print(g.conns)
    room_logic.broadcast(end_data)
end

function logic.get_room_members(user)
    local msg, dec, datas = room_core.get_room_members(user.custNo, user.token, g.room_info.gameRoomInfo.gameGroupId)
    if msg ~= "ok" then
        return send_error(user.fd, -2, dec, "get_room_members_fail")
    end

    local members = {}
    for key, data in pairs(datas or {}) do
        local is_online = false
        for k,v in pairs(g.conns or {}) do
            if v.custNo == data.custNo then
                is_online = true
                break
            end
        end

        data.is_online = is_online
        if is_online then
            table.insert( members, 1, data )
        else
            table.insert( members, data )
        end
    end

    local end_data = {
        msg_id = "get_room_members_success",
        uid = user.uid,
        members = members
    }
    send_msg(user.fd, end_data)
end



return logic
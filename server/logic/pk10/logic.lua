local skynet = require("skynet")
local utils  = require("pk10.poker_utils")
local core   = require("pk10.core")
local logic = {}

-- 初始化
function logic.init_game(user)
    -- g.banker_list = g.banker_list or {}
    if g.round == nil then
        g.is_kj = false   -- 是否开奖，默认不开奖
    end
    
end

-- 登录
function logic.login(user)
    -- 发送进入消息
    local data = {
        msg_id = "someone_enter_room",
        uid    = user.uid,
        infoData = user,
        state = g.game_step,
        time = g.step_time
    }
    room_logic.broadcast(data)
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

-- 判断玩家是否在游戏中，是否可离开
function logic.get_user_free(user)
    local bets = g.bet_data or {}
    print(user.id == g.banker , user.id, g.banker,  bets[user.id])
    if user.id == g.banker or bets[user.id] ~= nil or g.robot_user > 0 then
        return false  
    end
    return true
end

-- 断线重连
function logic.reconn(fd, id)
    print("pk10断线重连")
    g.game_step, g.step_time =  utils.getGameStep()
    -- 获取开奖数据
    local cj_data = skynet.call("cachepool", "lua", "get_ssc_kj_data")

    g.round = cj_data.number or 0

    local res = {
        msg_id = "resume_game",
        state  = g.game_step, -- == 0 and g.game_step or g.game_step-1,
        banker = g.banker,
        banker_name = g.banker_name,
        banker_seat = g.banker_seat,
        bankerCoin = g.bankerGameCoin,
        game_round_id = g.roundid,
        game_group_id = g.room_info.gameRoomInfo.gameGroupId,
        game_group_owner = g.room_info.gameRoomInfo.gameOwner,
        total_bet_value_list = g.total_bet_value_list or {},
        banker_surplus_coin_list =  g.bankerSurplusCoinList or {},
        round_num = g.round,
        kaijiang_data = str_split_intarray(cj_data.data or "", ","),
        resumeTime = g.step_time,
        user_bet_door_details = g.user_bet_door_details or {},
    }
    if g.game_step == Config.pk_step_bet or g.game_step == Config.pk_bet_start then
        res.resumeTime = g.step_time
        res.bet_data   = g.bet_data
    elseif g.game_step == Config.pk_wait_kaijiang then 
        res.resumeTime = g.step_time
        res.bet_data   = g.bet_data
    elseif g.game_step == Config.pk_kaijiang then
        res.resumeTime   = g.step_time
        res.packets  = g.packets or {}
        res.bet_data   = g.bet_data
    elseif g.game_step == Config.pk_bipai then
        res.resumeTime   = g.step_time
        res.packets  = g.packets or {}
        res.bet_data   = g.bet_data
        if g.result then
            res.log = g.result.log
        end
    elseif g.game_step == Config.pk_result then
        res.resumeTime   = g.step_time
        res.packets  = g.packets or {} 
        res.result_data = g.result and g.result.users or {}
        res.result_details = g.result and g.result.details or {}
    end

    send_msg(fd, res)
end

-- 有人退出房间
function logic.someone_quit(uid)
end

---------------------------------------------------------------------------------------------
-- 上庄
function logic.rob_banker(user, coin)
    -- -- 已经上过庄
    -- for i=1,table.nums(g.banker_list or {}) do
    --     local userTmp = g.banker_list[i] or {}
    --     if userTmp.id == user.id then
    --         return send_error(user.fd, -2, "不能重复上庄", "someone_rob_banker_fail")
    --     end
    -- end

    -- -- 保存上庄列表
    -- user.bankerCoin = coin
    -- table.insert(g.banker_list, user)

    -- 用户金币
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

    g.banker_info = user
    g.banker = user.id
    g.banker_name = user.name
    g.bankerCoin = coin
    g.bankerGameCoin = coin
    -- g.bankerSurplusCoin = coin -- 房间游戏中剩余金币
    g.players = g.players or {}
    g.players[user.id] = user

    -- 随机庄家座位
    local saizi = {}
    g.banker_seat, saizi = utils.get_banker_seat()

    -- 每门总下注金额
    -- g.bankerSurplusCoinList = utils.get_average_bet_value_list(g.banker_seat, coin)

    -- 上庄成功
    local data = {  
        msg_id = "someone_rob_banker_success",
        uid = user.id,
        name = user.name,
        banker_seat = g.banker_seat,
        saizi = saizi,
        coin = coin,
        -- banker_list = g.banker_list,
    }
    room_logic.broadcast(data)

end

-- 下庄
function logic.down_banker(user, message)
    -- local is_rob_banker = false
    -- for i=1,table.nums(g.banker_list) do
    --     local userTmp = g.banker_list[i] or {}
    --     if userTmp.id == user.id then
    --         is_rob_banker = true
    --         -- 从上庄列表中移除
    --         table.remove( g.banker_list, i )
    --     end
    -- end

    -- if not banker_info then
    --     return send_error(user.fd, -2, "您没有上庄！", "down_banker_fail")
    -- end

    -- 游戏中金币转到用户金币
    local userAccts = {}
    table.insert(userAccts, {
        type = 1,
        coin = g.bankerGameCoin,
        custNo = user.custNo,
        waterMemo = "下庄冻结金币返还",
        gameType = g.room_info.gameRoomInfo.gameType
    })
    local msg, dec = core.operatGameResultAcct("admin", "", userAccts)
    if msg ~= "ok" then
        LOG("下庄失败", g.bankerGameCoin)
        send_error(user.fd, -2, dec, "down_banker_fail")
        return
    end

    -- 下庄成功
    local data = {  
        msg_id = "someone_down_banker_success",
        uid = user.id,
        name = user.name,
        -- info = stepInfo,
        msg = message or "下庄成功",
        -- banker_list = g.banker_list,
    }
    room_logic.broadcast(data)

    --下庄清空数据
    g.bankerGameCoin = 0
    g.bankerSurplusCoinList = {}
    g.banker      = nil
    g.banker_name = nil
    g.banker_seat = nil
    g.banker_info = nil
    g.players     = nil
    
end

-- 开始下注
function logic.beter_start()
    -- local banker_info = g.banker_list[1]
    -- -- 从上庄列表中移除
    -- table.remove( g.banker_list, 1 )

    if g.banker then
        -- 每门总下注金额
        g.bankerSurplusCoinList = utils.get_average_bet_value_list(g.banker_seat, g.bankerGameCoin)
    end

    -- 开始下注
    local data = {
        msg_id = "bet_start",
        time = g.step_time,
        -- banker_info = banker_info,
        -- banker_list = g.banker_list,
        banker_surplus_coin_list =  g.bankerSurplusCoinList,
    }
    room_logic.broadcast(data)

    -- 清空下注数据
    g.total_bet_value_list = nil
    g.bet_door_data   = nil 
    g.total_bet_data  = nil
    g.bet_data        = nil
    g.user_bet_door_details = nil

end

-- 下注结束
function logic.beter_end()

    local data = {
        msg_id = "bet_end",
        time = g.step_time,
        banker_surplus_coin_list =  g.bankerSurplusCoinList,
        user_bet_door_details = g.user_bet_door_details,
    }
    room_logic.broadcast(data)
end

-- 下注
function logic.beter(user, bet_type, bet_value)
    g.bet_data = g.bet_data or {}

    LOG(string.format("pk10 logic.beter() ---> bet_type:%d bet_value:%d", bet_type or 0, bet_value or 0))

    -- 有人上庄，每门总下注金额为上庄金币平均值
    if g.banker then
        if bet_type == g.banker_seat then
            return send_error(user.fd, -2, "庄家区域无法下注！", "bet_fail")
        end
        local surplus_bet_value = g.bankerSurplusCoinList[bet_type]
        if surplus_bet_value - bet_value < 0 then
            return send_error(user.fd, -2, "该区域下注总额已上限", "bet_fail")
        end
    end

    -- 操作游戏中的金币 + 增加游戏中的金币
    print(user, "user")
    -- local msg, dec = core.addUserGameCoin(user, bet_value, user.custNo, g.room_info.gameRoomInfo.gameType)
    local userAccts = {}
    table.insert(userAccts, {
        type = 0,
        coin = bet_value,
        custNo = user.custNo,
        waterMemo = "下注金额冻结款",
        gameType = g.room_info.gameRoomInfo.gameType
    })
    local msg, dec = core.operatGameResultAcct("admin", "", userAccts)
    if msg ~= "ok" then
        return send_error(user.fd, -2, dec, "bet_fail")
    end

    -- 下注数据
    g.bet_data[user.id]      = g.bet_data[user.id] or {} 

    -- 计算每门剩余的金币
    if g.banker then
        g.bankerSurplusCoinList[bet_type] = g.bankerSurplusCoinList[bet_type] - bet_value
    end

    -- 每门下注总额
    g.total_bet_value_list = (g.total_bet_value_list or {})
    if g.total_bet_value_list[bet_type] then
        g.total_bet_value_list[bet_type] = g.total_bet_value_list[bet_type] + bet_value
    else
        g.total_bet_value_list[bet_type] = bet_value
    end

    -- 每门下注明细
    g.bet_door_data =  g.bet_door_data or {}
    g.bet_door_data[bet_type] = g.bet_door_data[bet_type] or {}
    if  g.bet_door_data[bet_type][user.id] then
        g.bet_door_data[bet_type][user.id].bet_value = g.bet_door_data[bet_type][user.id].bet_value + bet_value
        -- g.bet_door_data[bet_type][user.id].bet_per = string.format("%.4f", g.bet_door_data[bet_type][user.id].bet_value/g.total_bet_value_list[bet_type])
    else
        g.bet_door_data[bet_type][user.id] = {
            uid  = user.uid,
            name = user.name,
            avatar = user.user_avatar,
            bet_value = bet_value,
        }
    end

    -- ========每个玩家每门下注总额，占比========
    g.user_bet_door_details =  g.user_bet_door_details or {}
    g.user_bet_door_details[user.id] = g.user_bet_door_details[user.id] or {}
    local other_user_per_list = {}
    -- 每个玩家总下注
    local door_total_bet_value = g.user_bet_door_details[user.id].door_total_bet_value or 0
    door_total_bet_value = door_total_bet_value + bet_value
    -- 每门下注金额
    local door_info_list = g.user_bet_door_details[user.id].door_info_list or {}
    if  door_info_list[bet_type] then
        door_info_list[bet_type].bet_value = door_info_list[bet_type].bet_value + bet_value
        door_info_list[bet_type].bet_per = string.format("%.3f", door_info_list[bet_type].bet_value/g.total_bet_value_list[bet_type])        
    else
        door_info_list[bet_type] = {
            bet_value = bet_value,
            bet_per = string.format("%.3f", bet_value/g.total_bet_value_list[bet_type]),
       }
    end

    -- 缓存玩家每门下注详情
    g.user_bet_door_details[user.id] = {
        user_name = user.name,
        door_total_bet_value = door_total_bet_value,
        door_info_list = door_info_list
    }

    -- 修改当前门其他玩家占比
    other_user_per_list[user.id] = {
        bet_value = door_info_list[bet_type].bet_value,
        bet_per = door_info_list[bet_type].bet_per
    }
    for k,v in pairs(g.user_bet_door_details) do
        if k ~= user.id and v.door_info_list[bet_type] then
            v.door_info_list[bet_type].bet_per = string.format("%.3f", v.door_info_list[bet_type].bet_value/g.total_bet_value_list[bet_type])
            other_user_per_list[k] = {
                bet_value = v.door_info_list[bet_type].bet_value,
                bet_per = v.door_info_list[bet_type].bet_per
            }
        end
    end

    -- 保存用户操作
    table.insert(g.bet_data[user.id], {
        type  = bet_type,
        value = bet_value
    })

    -- 发送下注消息
    local data = {
        msg_id       = "someone_bet_success",
        uid          = user.id,
        bet_value    = bet_value,
        bet_type     = bet_type,
        total_bet_value = g.total_bet_value_list[bet_type],
        banker_surplus_coin_list =  g.bankerSurplusCoinList,
        me_total_bet_value = door_info_list[bet_type].bet_value,
        bet_per = door_info_list[bet_type].bet_per,
        other_user_per = other_user_per_list,
    }

    room_logic.broadcast(data)
end

-- 获取下注详情
function logic.get_betting_data(user, bet_type)
    -- 发送下注消息
    g.bet_door_data = g.bet_door_data or {}
    for i=1,5 do
        if g.bet_door_data[i] then
            for k,v in pairs(g.bet_door_data[i]) do
                g.bet_door_data[i][v.uid].bet_per = string.format("%.3f", v.bet_value/g.total_bet_value_list[i])
            end
        end
    end

    local data = {
        msg_id       = "get_betting_data_success",
        uid          = user.id,
        bet_type     = bet_type,
        bet_door_data = g.bet_door_data[bet_type] or {},
    }

    room_logic.broadcast(data)
end

-- 封盘/等待开奖
function logic.wait_kaijiang()
    local data = {
        msg_id = "wait_kaijiang",
        time = g.step_time,
        banker_surplus_coin_list =  g.bankerSurplusCoinList,
    }
    room_logic.broadcast(data)
end

-- 开奖
function logic.kaijiang()
    local kaijiang_data = {}
    -- 未开奖，先发送假数据开始跑马动画
    if not g.is_kj then
        local test = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
        for i=1,10 do
            local index = math.random(1, #test)    
            kaijiang_data[i] = test[index]        
            table.remove( test, index )
        end
    end

    -- =============测试===============
    -- g.kj_hao = table.concat(kaijiang_data, ",")
    -- g.kaijiang_data = kaijiang_data
    -- g.round = (g.round or 665087) +1
    -- =============测试===============
    
    
    local data = {
        msg_id = "kaijiang",
        time = g.step_time,
        round_num = g.round+1,
        kaijiang_data = kaijiang_data
    }
    print(kaijiang_data, "假数据")
    room_logic.broadcast(data)
end

-- 比牌
function logic.bipai()
    -- 计算结算数据
    g.result = utils.getResult( g.bet_door_data, g.total_bet_value_list, g.kj_hao, g.banker_seat, g.banker_info)

    local bipai_list = utils.get_bipai_list(g.kaijiang_data)

    local data = {
        msg_id = "bipai",
        time = g.step_time,
        round_num = g.round,
        kaijiang_data = g.kaijiang_data,
        list = bipai_list,
        log = g.result.log
    }
    room_logic.broadcast(data)
end

-- 结算
function logic.result()

    -- 金币游戏中金币
    -- 冲返庄家上庄金额
    local userAccts = {}
    if g.banker then
        local userAcct = {}
        userAcct.type = 1
        userAcct.coin = g.bankerGameCoin
        userAcct.custNo = g.banker
        userAcct.gameType = g.room_info.gameRoomInfo.gameType
        table.insert(userAccts, userAcct)
    end

    -- 冲返下注金币
    for uid, bets in pairs(g.bet_data or {}) do
        local userGameCoin = 0
        for index, bet in pairs(bets) do
            userGameCoin = userGameCoin + bet.value
        end
        local userAcct  = {}
        userAcct.type   = 1
        userAcct.coin   = userGameCoin
        userAcct.custNo = uid
        userAcct.gameType = g.room_info.gameRoomInfo.gameType
        table.insert(userAccts, userAcct)
    end

    -- 投注的门数>1，进行输赢结算
    local pumps = {}
    if g.result and table.size(g.bet_door_data or {}) > 1 then
        local users = g.result.users or {}
        for uid, user in pairs(users) do
            local coin     = math.abs(user.coin_change)
            if coin > 0 then
                local userAcct = {}
                if user.coin_change > 0 then
                    userAcct.type = 2
                elseif user.coin_change < 0 then
                    userAcct.type = 3
                end
                userAcct.coin   = coin
                userAcct.custNo = user.uid
                userAcct.gameType = g.room_info.gameRoomInfo.gameType
                table.insert(userAccts, userAcct)

                -- 计算抽佣值
                if user.is_banker then
                    if user.coin_change > 0 then
                        local pump = coin*Config.pk_banker_win_pump_rate
                        pumps[uid] = {isbanker = true, coin = pump}

                        user.original_coin_change = coin
                        user.coin_change = tonumber(string.format("%.2f", coin - pump)) -- 庄家抽佣
                    end
                    g.bankerGameCoin = g.bankerGameCoin + user.coin_change
                    g.bankerGameCoin = tonumber(string.format("%.2f", g.bankerGameCoin))
                else
                    if user.coin_change > 0 then
                        local pump = coin*Config.pk_user_win_pump_rate
                        pumps[uid] = {coin = pump}
                        user.original_coin_change = coin
                        user.coin_change = tonumber(string.format("%.2f", coin - pump)) -- 闲家抽佣
                    end
                end
            end
        end
    end

    -- 抽佣
    --庄赢抽佣 M=盈利金额*5%
    --闲赢抽佣 M=盈利金额*5%
    local game_owner = g.room_info.gameRoomInfo.gameOwner
    for uid, pump in pairs(pumps) do
        -- 抽出钱
        local userAcct = {}
        userAcct.type = 7
        userAcct.coin = pump.coin
        userAcct.custNo = uid
        userAcct.waterType = "97"
        userAcct.waterMemo = pump.isbanker == true and "pk10庄家抽佣" or "pk10闲家抽佣"
        userAcct.gameType = g.room_info.gameRoomInfo.gameType
        table.insert(userAccts, userAcct)

        -- 抽给房主
        local userAcct = {}
        userAcct.type = 6
        userAcct.coin = pump.coin
        userAcct.custNo = game_owner
        userAcct.waterType = "98"
        userAcct.waterMemo = pump.isbanker == true and "pk10房主收到庄家抽佣" or "pk10房主收到闲家抽佣"
        userAcct.gameType = g.room_info.gameRoomInfo.gameType
        table.insert(userAccts, userAcct)
    end

    --上庄金币 庄家金币到游戏中
    if g.banker then
        local userAcct = {}
        userAcct.type = 0
        userAcct.coin = g.bankerGameCoin
        userAcct.custNo = g.banker
        userAcct.waterMemo = "pk10上庄金额冻结款"
        userAcct.gameType = g.room_info.gameRoomInfo.gameType
        table.insert(userAccts, userAcct)
    end

    -- 刷新details
    if g.result and g.result.details and g.result.users then
        for uid, user in pairs(g.result.users) do
            if g.result.details[uid] then
                g.result.details[uid].original_coin_change = user.original_coin_change
                g.result.details[uid].coin_change = user.coin_change
            end
        end
    end
    
    -- 金币输赢
    print(userAccts, "==============结算=============")
    if next(userAccts) then
        local msg, dec = core.operatGameResultAcct("admin", "", userAccts)
        if msg ~= "ok" then
            LOG("结算---》失败==结算",dec, g.bankerGameCoin, g.bankerSurplusCoin )
            return 
        end
    end
    print(g.result)
    LOG("结算成功")
    print("结算成功")
    local data = {
        msg_id = "game_result",
        -- data = g.result and g.result.users or {},
        details = g.result and g.result.details or {},
        time = g.step_time,
        banker = g.banker,
        banker_name = g.banker_name,
        banker_seat = g.banker_seat,
        bankerCoin = g.bankerGameCoin,
    }
    room_logic.broadcast(data)

    -- 存储处理结算操作
    core.handleResult(data)

    -- 判断是否下庄
    if g.banker then
        local user = g.players[g.banker]
        if user.offline == true then
            g.game_logic.down_banker(user, "庄家离线已自动下庄！")
        elseif g.bankerGameCoin < 10000 then -- g.room_info.gameRoomInfo.gameBankerLimitAmt/100
            g.game_logic.down_banker(user, "庄家金额不足已自动下庄！")
        end
    end

end

-- 局结算
function logic.game_round_over()
    -- 一局结束 GAME_OVER
    local end_data = {
        msg_id = "game_round_over",
        time   = g.step_time,
    }
    room_logic.broadcast(end_data)

    -- g.game_step = Config.step_none
    -- 清空下注数据
    g.total_bet_value_list = nil
    g.bet_door_data   = nil
    g.total_bet_data  = nil
    g.bet_data        = nil
    g.user_bet_door_details = nil

    g.kaijiang_data = {}
    g.kj_hao = {}
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

-- 刷新采集数据
function logic.update_cj_data(data)
    if g.game_step == Config.pk_kaijiang then
        local cj_data = skynet.call("cachepool", "lua", "get_ssc_kj_data")
        if not cj_data.data then
            return
        end
        -- 通知奖到了
        if cj_data.number ~= g.round and not g.is_kj then
            print("发送开奖", cj_data)
            g.is_kj = true

            g.kj_hao = cj_data.data
            g.kaijiang_data = str_split_intarray(g.kj_hao, ",")
            g.round = cj_data.number
            LOG("g.kj_hao, g.kaijiang_data, g.round", g.kj_hao, g.kaijiang_data, g.round)
            -- 开奖了
            local data = {
                msg_id = "kj_notice",
                time = cj_data.time,
                round_num = g.round,
                kaijiang_data = g.kaijiang_data
            }
            room_logic.broadcast(data)
        end
    else
        g.is_kj = false
    end
end


return logic
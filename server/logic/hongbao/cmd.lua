local skynet = require "skynet"
local queue = require "skynet.queue"
local cs = queue() 
local cmd = {}

-- 玩家抢庄
function cmd.rob_banker(user, data)
    if g.banker ~= nil then
        send_error(user.fd, -2, "上庄失败，已经有人捷足先登了~", "someone_rob_banker_fail")
        return
    end
    local coin = data.bankerLimit
    g.game_logic.rob_banker(user, coin)
end

-- 玩家标庄
function cmd.biao_banker(user, data)
    if g.game_step ~= Config.step_biao then
        send_error(user.fd, -2, "标庄已结束", "bet_fail")
        return
    end

    local coin = tonumber(data.bankerLimit)
    g.game_logic.biao_banker(user, coin)
end

-- 玩家下庄
function cmd.down_banker(user, data)
    if g.banker ~= user.id then
        send_error(user.fd, -2, "下庄失败，您不是庄家！", "down_banker_fail")
        return
    end

    if g.game_step ~= Config.step_none and g.game_step ~= Config.step_result then
        send_error(user.fd, -2, "游戏中不能下庄！", "down_banker_fail")
        return
    end

    g.game_logic.down_banker(user)
end

-- 玩家下注
function cmd.betting(user, data)
    if g.game_step ~= Config.step_bet then
        send_error(user.fd, -2, "下注已结束", "bet_fail")
        return
    end

    if user.id == g.banker then
        send_error(user.fd, -2, "庄家不允许下注", "bet_fail")
        return
    end 

    local bet_type     = data.bet_type          -- 下注类型
    local bet_sub_type = data.bet_sub_type      -- 下注子类型
    local bet_value    = data.bet_value         -- 下注值

    if not bet_type then
        send_error(user.fd, -2, "下注失败，请选择下注类型", "bet_fail")
        return
    end

    if not bet_value then
        send_error(user.fd, -2, "下注失败，请选择下注子类型", "bet_fail")
        return
    end

    if  bet_type <=0 or bet_type>4 then
        send_error(user.fd, -2, "非法的下注类型", "bet_fail")
        return
    end

    if bet_type == Config.hb_bet_size_dan_shuang_he or bet_type == Config.hb_bet_special_point then
        if not bet_sub_type then
            send_error(user.fd, -2, "下注失败，请选择下注子类型", "bet_fail")
            return
        end
    end

    cs(function()
        g.game_logic.beter(user, bet_type, bet_sub_type, bet_value)
    end)
end

-- 拆红包
function cmd.open_red_packet(user, data)
    if g.game_step ~= Config.step_qiang then
        send_error(user.fd, -2, "抢包已结束", "bet_fail")
        return
    end

    if user.id == g.banker then
        local isOpen = false
        --print("==>", g.packets)
        for uid, packet in pairs(g.packets) do
            if packet.open == true then
                isOpen = true
                break
            end
        end

        if isOpen == false then
            send_error(user.fd, -2, "庄家不能抢头包", "open_red_packet_fail")
            return
        end
    end
    g.game_logic.open_red_packet(user)
end

-- 刮红包
function cmd.gua_red_packet(user, data)
    g.game_logic.gua_red_packet(user)
end

-- 获取在线用户
function cmd.get_room_online_user(user, data)
    
    g.game_logic.get_room_online_user(user)
end

-- 获取房间成员
function cmd.get_room_members(user, data)
    
    g.game_logic.get_room_members(user)
end

return cmd
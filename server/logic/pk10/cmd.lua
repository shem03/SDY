local queue = require "skynet.queue"
local cs = queue() 

local cmd = {}

-- 玩家上庄
function cmd.rob_banker(user, data)
    if g.game_step ~= Config.step_none and g.game_step ~= Config.pk_result then
        send_error(user.fd, -2, "游戏中不能上庄！", "rob_banker_fail")
        return
    end

    cs(function()
        if g.banker ~= nil then
            send_error(user.fd, -2, "上庄失败，已经有人捷足先登了~", "rob_banker_fail")
            return
        end
        local coin = data.bankerLimit
        g.game_logic.rob_banker(user, coin)
    end)
    
end

-- 玩家下庄
function cmd.down_banker(user, data)
    if g.banker ~= user.id then
        send_error(user.fd, -2, "下庄失败，您不是庄家！", "down_banker_fail")
        return
    end

    if g.game_step ~= Config.step_none and g.game_step ~= Config.pk_result then
        send_error(user.fd, -2, "游戏中不能下庄！", "down_banker_fail")
        return
    end

    g.game_logic.down_banker(user)
end

-- 玩家下注
function cmd.betting(user, data)
    if g.game_step ~= Config.pk_step_bet and g.game_step ~= Config.pk_bet_start then
        send_error(user.fd, -2, "下注已结束", "bet_fail")
        return
    end

    if user.id == g.banker then
        send_error(user.fd, -2, "庄家不允许下注", "bet_fail")
        return
    end 

    local bet_type     = data.bet_type          -- 下注类型
    local bet_value    = data.bet_value         -- 下注值

    if not bet_value then
        send_error(user.fd, -2, "下注失败，没有下注金额", "bet_fail")
        return
    end

    cs(function()
        if g.game_step ~= Config.pk_step_bet and g.game_step ~= Config.pk_bet_start then
            return
        end
        g.game_logic.beter(user, bet_type, bet_value)
    end)
end

-- 玩家下注详情
function cmd.get_betting_data(user, data)

    local bet_type     = data.bet_type          -- 下注类型

    g.game_logic.get_betting_data(user, bet_type)
end

-- 获取在线用户
function cmd.get_room_online_user(user, data)
    
    g.game_logic.get_room_online_user(user)
end

return cmd
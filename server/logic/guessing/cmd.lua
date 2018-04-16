
local queue = require "skynet.queue"
local cs = queue() 

local cmd = {}

-- 玩家下注
function cmd.betting(user, data)
    -- 下注还未开始，拦截
    if g.game_step < Config.step_guess_bet_start then 
        send_error(user.fd, -2, "游戏未开始，不能下注", "bet_fail")
        return
	-- 下注结束，不能进行下注
	elseif g.game_step > Config.step_guess_bet_start then
        send_error(user.fd, -2, "下注已经结束", "bet_fail")
        return
    end

    local bet_type = data.bet_type          -- 下注类型
    local bet_value = data.bet_value         -- 下注值

    g.game_logic.betting(user, bet_type, bet_value)
end

-- 玩家出拳
function cmd.punch(user, data)
	-- 出拳阶段结束，不能进行出拳
	if g.game_step < Config.step_guess_bet_end then
        send_error(user.fd, -2, "请先下注！", "punch_fail")
        return
    elseif g.game_step > Config.step_guess_punches_start then
        send_error(user.fd, -2, "出拳阶段已经结束！", "punch_fail")
        return
    end

    local fist = data.fist

    g.game_logic.punch(user, fist)
end

-- 退出游戏
function cmd.quit_game(user)
    g.game_logic.quit_game(user)
end

return cmd
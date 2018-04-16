
local utils  = require("guessing.poker_utils")
local cmd = {}

-- 房间逻辑定时器，外部调用
function cmd.run()
    -- 获取游戏状态
    g.game_time = g.game_time + 1
    if (g.game_step ~= Config.step_none) and (g.game_time ~= Config.step_guess_game_over) then
        local cur_step_fun = cmd[g.game_step]
        assert(cur_step_fun ~= nil, "g.game_step"..g.game_step)
        cur_step_fun()
    end
end

-- 打印，内部函数
local interval_time = 5
local function step_print(step_str, print_time)
    if (g.game_time % interval_time) == 0 then 
        print("--->>"..(step_str or '').." 房间ID:"..g.room_info.gameRoomInfo.gameGroupId)
        if print_time then 
            print("操作限制时长：", g.game_step_limit_time)
            print("游戏已经进行：", g.game_time)
        end
    end
end

-- 设置游戏进行状态，内部函数
local function set_game_step(step, limit_time)
    -- 切换游戏状态
    g.game_step = step
    -- 重置游戏时间
    g.game_time = 0
    -- 设置游戏操作时长
    g.game_step_limit_time = limit_time or 0
end
---------------------------------------------------------------------------------------

-- 开始下注
local function bet_start()
    -- 切换游戏状态-->下注开始
    set_game_step(Config.step_guess_bet_start, Config.time_guessing_bet)
end
cmd.bet_start = bet_start

-- 下注结束
local function bet_end()
    -- 切换游戏状态-->下注结束
    set_game_step(Config.step_guess_bet_end)
end
cmd.bet_end = bet_end

-- 开始出拳
local function punch_start()
    -- 切换游戏状态-->出拳开始
    set_game_step(Config.step_guess_punches_start, Config.time_guessing_punches)
end
cmd.punch_start = punch_start

-- 出拳结束
local function punch_end()
    -- 切换游戏状态-->出拳结束
    set_game_step(Config.step_guess_punches_end)
end
cmd.punch_end = punch_end

-- 进入等待结算阶段
local function wait_result()
    -- 切换游戏状态-->等待结算
    set_game_step(Config.step_guess_wait_result, Config.time_guessing_wait_result)
end
cmd.wait_result = wait_result

-- 一方未下注，导致游戏流局
local function flow_bureau()
    -- 切换游戏状态-->流局
    set_game_step(Config.step_guess_flow, Config.time_guessing_wait_result)
end
cmd.flow_bureau = flow_bureau

-- 游戏结算
local function game_result()
    -- 切换游戏状态-->游戏结算
    g.game_step = Config.step_guess_result
end
cmd.game_result = game_result

-- 游戏结束
local function game_over(limit_time)
    -- 切换游戏状态-->游戏结束
    if limit_time then 
        set_game_step(Config.step_guess_game_over, limit_time)
    else
        g.game_step = Config.step_guess_game_over
    end
end
cmd.game_over = game_over

------------------------------------------------------------------------------------
----------- 游戏每个阶段处理函数
--[[
    -- 猜拳游戏状态
    step_guess_bet_start      -- 开始下注
    step_guess_bet_end        -- 下注结束
    step_guess_punches_start  -- 出拳开始
    step_guess_punches_end    -- 出拳结束
    step_guess_wait_result    -- 等待结算
    step_guess_result         -- 游戏结束
    step_guess_flow           -- 流局
    step_guess_game_over      -- 游戏结束

    -- 猜拳游戏每个阶段持续时间
    time_guessing_bet         -- 下注时间
    time_guessing_punches     -- 出拳时间
    time_guessing_wait_result -- 结算等待时间
]]
-- 下注开始 
cmd[Config.step_guess_bet_start] = function()
    step_print("猜拳游戏下注倒计时", true)
    if g.game_time < g.game_step_limit_time then
       return
    end

    bet_end()
end

-- 下注结束
cmd[Config.step_guess_bet_end] = function()
    if g.game_time < 1 then
       return
    end

    step_print("猜拳游戏下注结束，等待玩家出拳")

    -- 通知下注结束，进入出拳阶段
    g.game_logic.beter_end()
end

-- 出拳开始
cmd[Config.step_guess_punches_start] = function()
    step_print("猜拳游戏出拳倒计时", true)
    if g.game_time < g.game_step_limit_time then
       return
    end

    punch_end()
end

-- 出拳结束
cmd[Config.step_guess_punches_end] = function()
    if g.game_time < 1 then
       return
    end

    step_print("猜拳游戏玩家出拳结束")
    -- 出拳结束
    g.game_logic.punch_end()
end

-- 等待结算，留给玩家时间查看胜负情况
cmd[Config.step_guess_wait_result] = function()
    step_print("等待结算...", true)
    if g.game_time < g.game_step_limit_time then
       return
    end

    -- 执行结算逻辑
    g.game_logic.game_result()
end

-- 结算
cmd[Config.step_guess_result] = function()
end

-- 游戏结束
cmd[Config.step_guess_game_over] = function()
end

-- 流局，解散房间
cmd[Config.step_guess_flow] = function()
end

return cmd
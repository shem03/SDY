local utils  = require("pk10.poker_utils")
local robot  = require("pk10.robot")
local cmd = {}

-- 游戏结束
local function game_over()
end

local function robot_run(game_step)
    if Config.robot then
        robot.run(game_step)
    end
end

-- 房间逻辑定时器
function cmd.run()
    -- 获取游戏状态
    local game_status
    game_status, g.step_time =  utils.getGameStep()   

    -- 更新游戏采集分数
    g.game_logic.update_cj_data()

    -- 机器人
    pcall(robot_run, game_status)

    -- 相同状态调用一次
    if g.game_step == game_status then
        return
    end
    g.game_step = game_status

    -- print(g.game_step)
    -- 轮询调用方法
    if g.game_step > Config.step_none then    -- 游戏已经开始
        local cur_step_fun = cmd[g.game_step]
        assert(cur_step_fun~=nil, "g.game_step" .. g.game_step)
        cur_step_fun()
    end
end

--[[
    pk_bet_start       	= 1,		-- 开始下注
	pk_step_bet		    = 2,		-- 下注中
	pk_bet_end	   		= 3,		-- 下注结束
	pk_wait_kaijiang  	= 4,		-- 等待开奖，封盘
	pk_kaijiang      	= 5,		-- 比车
	pk_bipai            = 6,		-- 比牌
	pk_result   		= 7,        -- 结算
]]

-- 下注开始 185s
cmd[Config.pk_bet_start] = function()
    -- 通知下注结束
    g.game_logic.beter_start()
end

-- 下注中
cmd[Config.pk_step_bet] = function()
    
end

-- 下注结束
cmd[Config.pk_bet_end] = function()
    g.game_logic.beter_end()
end

-- 等待开奖，封盘
cmd[Config.pk_wait_kaijiang] = function()
    g.game_logic.wait_kaijiang()
end

-- 比车
cmd[Config.pk_kaijiang] = function()
    g.game_logic.kaijiang()
end

-- 比牌
cmd[Config.pk_bipai] = function()
    g.game_logic.bipai()
end

-- 结算并等待开始
cmd[Config.pk_result] = function()
    g.game_logic.result()
    g.game_logic.game_round_over()
end


-- ================================================
-- 房间逻辑定时器
-- function cmd.run()
--     -- print("pk10定时器")
--     g.step_time = g.step_time or 5
--     g.game_step = g.game_step or 0

--     g.step_time = g.step_time - 1
--     local cur_step_fun = cmd[g.game_step]
--     assert(cur_step_fun~=nil, "g.game_step" .. g.game_step)
--     cur_step_fun()
-- end

-- -- 下注开始 185s
-- cmd[Config.pk_bet_start] = function()
--     if g.step_time > 0 then
--         return
--     end

--     g.step_time = 10
--     g.game_step = Config.pk_step_bet

--     -- 通知下注结束
--     g.game_logic.beter_start()
-- end

-- -- 下注中
-- cmd[Config.pk_step_bet] = function()
--     if g.step_time > 0 then
--         return
--     end

--     g.step_time = 1
--     g.game_step = Config.pk_bet_end
-- end

-- -- 下注结束
-- cmd[Config.pk_bet_end] = function()
--     if g.step_time > 0 then
--         return
--     end
--     g.step_time = 1
--     g.game_step = Config.pk_wait_kaijiang

--     g.game_logic.beter_end()
-- end

-- -- 等待开奖，封盘
-- cmd[Config.pk_wait_kaijiang] = function()
--     if g.step_time > 0 then
--         return
--     end
--     g.step_time = 10
--     g.game_step = Config.pk_kaijiang

--     g.game_logic.wait_kaijiang()
-- end

-- -- 比车
-- cmd[Config.pk_kaijiang] = function()
--     if g.step_time > 0 then
--         return
--     end
--     g.step_time = 30
--     g.game_step = Config.pk_bipai

--     g.game_logic.kaijiang()
-- end

-- -- 比牌
-- cmd[Config.pk_bipai] = function()
--     if g.step_time > 0 then
--         return
--     end
--     g.step_time = 30
--     g.game_step = Config.pk_result

--     g.game_logic.bipai()
-- end

-- -- 结算并等待开始
-- cmd[Config.pk_result] = function()
--     if g.step_time > 0 then
--         return
--     end
--     g.step_time = 20
--     g.game_step = Config.step_none

--     g.game_logic.result()
--     g.game_logic.game_round_over()
-- end

-- -- 等待下局开始
-- cmd[Config.step_none] = function()
--     if g.step_time > 0 then
--        return
--     end

--     g.step_time = 1
--     g.game_step = Config.pk_bet_start
-- end

return cmd
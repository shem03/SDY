local skynet = require "skynet"
local utils  = require("hongbao.poker_utils")
local robot  = require("hongbao.robot")
local cmd = {}

-- 游戏结束
local function game_over()
    -- 清空上局数据
    g.packets = nil
    g.bet_data = nil
    g.result = nil
    g.roundid = nil
    g.total_bet_data = nil
    g.total_bet_value = nil

    if g.banker then
        local user = g.players[g.banker]
        if user.offline == true then
            LOG("庄家离线已自动下庄")
            g.game_logic.down_banker(user, "庄家离线已自动下庄！")
        else
            LOG("连庄")
            g.players = {}
            g.players[g.banker] = user
            g.game_step_lua.game_start(false)
        end
        return
    end
    
    g.players = nil

    -- 更新状态
    g.game_step = Config.step_none
    g.game_time = 0
    print("gameover")

    -- ！！重要,所有游戏回合都需要调用
    room_logic.game_over()
end


-- 游戏开始 flag==false 表示连庄
local function game_start(flag)
    if not flag then
        local msg,dec = g.game_logic.freezeRoomGold()
        if msg ~= "ok" then
            local banker = g.players[g.banker]
            print("游戏开始", "钻石不足", dec,msg)
            if msg == "B002" then
                g.game_logic.down_banker(banker, "房间钻石不足，自动下庄！")
                g.game_time = 0
                g.game_step = Config.step_none
                return
            end
            return send_error(banker.fd, -2, dec or "", "game_start_fail")
        end
    end

    g.game_time = 0
    -- g.game_step = Config.step_biao
    g.roundid   = math.floor(skynet.time())

    if flag then
        g.game_step = Config.step_biao
        -- 通知开始标庄
        g.game_logic.biao_start()
    else
        g.game_step = Config.step_bet
        -- 通知开始下注
        g.game_logic.beter_start()
    end

end
cmd.game_start = game_start

-- 游戏结算
local function goto_result()
    g.game_time = 0
    g.game_step = Config.step_result

    g.game_logic.game_result()
end
cmd.game_reuslt = goto_result

-- 房间逻辑定时器
function cmd.run()
    g.game_time = g.game_time + 1
    if g.game_step > Config.step_none then    -- 游戏已经开始
        local cur_step_fun = cmd[g.game_step]
        assert(cur_step_fun~=nil, "g.game_step" .. g.game_step)
        cur_step_fun()
    end

    if Config.robot then
        robot.run()
    end

    -- 定时查询是否清除当前agent
end

-- 抢庄
cmd[Config.step_rob] = function()
end

-- 标庄开始
cmd[Config.step_biao] = function()
    print("标庄开始", g.game_time, Config.hb_biao_time)
    if g.game_time < Config.hb_biao_time then
       return
    end

    -- 开始下注
    g.game_time = 0
    g.game_step = Config.step_biao_end

    -- 通知标庄结束
    g.game_logic.stop_biao()
end

-- 标庄结束
cmd[Config.step_biao_end] = function()
    if g.game_time < 1 then
       return
    end

    -- 开始下注
    g.game_time = 0
    g.game_step = Config.step_bet

    -- 通知开始下注
    g.game_logic.beter_start()
end

-- 下注开始
cmd[Config.step_bet] = function()
    --print("下注", g.game_time, Config.hb_bet_time)
    if g.game_time < Config.hb_bet_time then
       return
    end

    -- 下注结束
    g.game_time = 0
    g.game_step = Config.step_bet_end
    g.game_logic.stop_beter()
end

-- 下注结束
cmd[Config.step_bet_end] = function()
    if g.game_time < 1 then
       return
    end

    -- 判断是否流局
    local bet_peoples = table.size(g.bet_data or {})
    if bet_peoples < Config.hb_minimum_bet then
        g.game_time = 0
        g.game_step = Config.step_flow      -- 小于最低下注人数 流局
        return
    end

    -- 等待发包
    g.game_time = 0
    g.game_step = Config.step_send
    g.game_logic.wait_send()
end

-- 发包
cmd[Config.step_send] = function()
    if g.game_time < Config.hb_wait_send then
        return
    end

    print("发包")
    g.game_logic.send_packet()

    g.game_time = 0
    g.game_step = Config.step_qiang
end

-- 抢包
cmd[Config.step_qiang] = function()
    if g.game_time < Config.hb_qiang_time then
       return
    end
    -- goto_result()
    print("推送等待结算")
    g.game_logic.wait_game_result()

    g.game_time = 0
    g.game_step = Config.step_wait_result
end

-- 等待结算
cmd[Config.step_wait_result] = function()
    if g.game_time < Config.hb_wait_result_time then
       return
    end
    goto_result()
end

-- 结束并结算
cmd[Config.step_result] = function()
    -- print("结算", g.game_time, Config.hb_reuslt_time)
    if g.game_time <= Config.hb_reuslt_time then
        return
    end
    g.game_time = 0
    g.game_logic.game_round_over()

    -- 结算
    game_over()
end

-- 流局
cmd[Config.step_flow] = function()
    g.game_step = Config.step_result
    g.game_time = 0

    print("流局")

    g.game_logic.game_flow_bureau()
end
    
return cmd
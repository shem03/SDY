local skynet    = require "skynet"
local db_mgr    = require("db_mgr")
local user_core = require("user.ctcore")
local room_core   = require("room.core")

-- 机器人
local cmd             = {}
local room_robots     = {}
local bet_data        = {}
local max_delay_bet   = 3
local delay_bet_count = 0

-- 添加机器人
local function handle_robot()
    -- 有庄就进房间
    if g.banker then
        -- 机器人
        --if g.real_user + g.robot_user < g.room_info.min_count then
        --    cmd.login()
        --end
        if g.robot_user < g.room_info.robot_count then
            cmd.login()
        elseif g.robot_user == g.room_info.robot_count then
            return
        else
            for uid, robot in pairs(room_robots) do
                if not g.bet_data then
                    cmd.post_leave()
                    break
                elseif not g.bet_data[i] then
                    cmd.post_leave()
                    break
                end
            end
        end

    else
        cmd.post_leave()
    end
end

-- 清除游戏过程中的缓存


-- 设置机器人状态
local function set_robot_run(account, isRun)
	return skynet.call("cachepool", "lua", "set_robot_run", account, isRun)
end

-- 获取机器人
local function get_free_robots()
	return skynet.call("cachepool", "lua", "get_free_robots")
end

-- 登录
function cmd.login()
    local robots = get_free_robots()
    if table.size(robots) == 0 then
        return
    end
    local keys   = table.indices(robots)
    local key    = keys[math.random(1, #keys)]
    local robot  = robots[key]
    local status, msg, user = user_core.login(robot.account, robot.password)
    if status ~= "ok" then
        return
    end

    -- 未加入房间的自动先加入 
	local code, dec, result = room_core.get_into_game_room(1, user.custNo, user.token, g.room_info.gameRoomInfo.gameGroupId, g.room_info.gameRoomInfo.gameOwner, user.custNo)

    -- 机器人开始运作
    set_robot_run(robot.account, true)
    user.is_robot = true
    user.fd       = -user.id
    user.is_run   = true
    user.account  = robot.account
    user.max_bet_count= math.random(1,2)
    user.bet_count= 0
    room_robots[user.id] = user

    -- 机器人
    g.robot_user  = g.robot_user + 1

    -- 存储
    g.conns[user.fd] = user
    g.users[user.id] = user
    g.game_logic.login(user)
     -- 更新存储人数
     room_core.update_room_people(g.room_info.gameRoomInfo.gameGroupId, table.size(g.conns or {}))
end

-- 登出
function cmd.post_leave()
    local robot_ids = table.indices(room_robots)
    if #robot_ids == 0 then
        return 
    end
    local rate = math.random(1, 100)
    if rate > 50 then
        return
    end
    local select_robot = nil
    for id, user in pairs(room_robots) do
        if user.is_run == true then
            select_robot = user
            user.is_run  = false
            break
        end
    end
    if not select_robot then
        return
    end
    g.game_logic.post_leave(select_robot)
    set_robot_run(select_robot.account, false)
     -- 更新存储人数
    room_core.update_room_people(g.room_info.gameRoomInfo.gameGroupId, table.size(g.conns or {}))
    room_robots[select_robot.id] = nil
end

-- 游戏步骤轮询
function cmd.run()
    -- 用户自主上庄 == 青青草原||
    if g.room_info.gameRoomInfo.gameGroupId == "3755581327787008" then
        return
    end
    
    handle_robot()

    if g.game_step > Config.step_none then    -- 游戏已经开始
        local cur_step_fun = cmd[g.game_step]
        assert(cur_step_fun~=nil, "g.game_step" .. g.game_step)
        cur_step_fun()
    end
end

-- 抢庄
cmd[Config.step_rob] = function()
end

-- 标庄开始
cmd[Config.step_biao] = function()
end

-- 标庄结束
cmd[Config.step_biao_end] = function()
end

-- 下注开始
cmd[Config.step_bet] = function()
    -- print("机器人 下注开始")
    if table.size(room_robots) == 0 then
        return
    end

    -- 一定时间下注
    delay_bet_count = delay_bet_count + 1
    if delay_bet_count < max_delay_bet then
        return
    end

    local bat_rate = math.random(1, 100)
    -- print(bat_rate)
    if bat_rate < 5 then
        return
    end

    local bet_peoples = {}
    for uid, user in pairs(room_robots) do
        if g.bet_data and g.bet_data[user.id] ~= nil then
            if user.bet_count < user.max_bet_count then
                local value = g.bet_data[user.id][1]
                if value.type == Config.hb_bet_special_point then
                    table.insert(bet_peoples, {user = user, type = Config.hb_bet_special_point})
                end
            end
        else
            table.insert(bet_peoples, {user = user})
        end
    end

    if #bet_peoples == 0 then
        return
    end

    -- 取出没下注的
    local bet_people_data = bet_peoples[math.random(1, #bet_peoples)]
    local bet_people      = bet_people_data.user
    local bet_type        = bet_people_data.type or 0
    
    -- 进行下注
    local room_robot = room_robots[bet_people.id]
    -- print("room_robot.bet_count , room_robot.max_bet_count", room_robot.bet_count, room_robot.max_bet_count)
    if bet_type == Config.hb_bet_special_point then
        local bet_value = math.random(10, 200)
        local bet_sub_type = math.random(1, 9)
        g.game_cmd.betting(bet_people, {bet_type = bet_type, bet_sub_type = bet_sub_type, bet_value = bet_value})
        bet_data[bet_people.id] = {user = bet_people, isgua = false}
        
        room_robot.bet_count = room_robot.bet_count + 1
    else
        local bet_type = math.random(1, 4)
        if bet_type == 1 then
            local bet_value = math.random(10, 200)
            g.game_cmd.betting(bet_people, {bet_type = bet_type, bet_value = bet_value})
            room_robot.bet_count = room_robot.bet_count + 1
        elseif bet_type == 2 then
            local bet_value = math.random(6, 2000)
            g.game_cmd.betting(bet_people, {bet_type = bet_type, bet_value = bet_value})
            room_robot.bet_count = room_robot.bet_count + 1
        elseif bet_type == 3 then
            local bet_value = math.random(100, 2000)
            local bet_sub_type = math.random(1, 9)
            g.game_cmd.betting(bet_people, {bet_type = bet_type, bet_sub_type = bet_sub_type, bet_value = bet_value})
            room_robot.bet_count = room_robot.bet_count + 1
        elseif bet_type == 4 then
            local bet_value = math.random(100, 1000)
            local bet_sub_type = math.random(1, 9)
            g.game_cmd.betting(bet_people, {bet_type = bet_type, bet_sub_type = bet_sub_type, bet_value = bet_value})
            room_robot.bet_count = room_robot.bet_count + 1
        end
        if bet_type > 0 and bet_type <= 4 then
            bet_data[bet_people.id] = {user = bet_people, isgua = false}
        end
    end
end

-- 下注结束
cmd[Config.step_bet_end] = function()
    for uid, user in pairs(room_robots) do
        user.max_bet_count= math.random(1,2)
        user.bet_count= 0
    end

    delay_bet_count = 0
end

-- 发包
cmd[Config.step_send] = function()

end

-- 抢包
cmd[Config.step_qiang] = function()
    print("机器人 刮包开始")
    -- 找出没刮的
    local no_guas = {}
    for k, v in pairs(bet_data) do
        if not v.isgua then
            table.insert(no_guas, v) 
        end
    end
    if table.size(no_guas) == 0 then return end

    -- 找出下注成功的
    local bet_oks = {}
    for k, v in pairs(no_guas) do
        if g.bet_data[v.user.id] then
            table.insert(bet_oks, v) 
        end
    end
    if table.size(bet_oks) == 0 then return end

    -- 刮
    local bet_rate = math.random(1, 100)
    if bet_rate < 10 then
        return
    end
    local gua_people = bet_oks[math.random(1, #bet_oks)]
    bet_data[gua_people.user.id].isgua = true
    g.game_cmd.open_red_packet(gua_people.user)
end

-- 等待结算
cmd[Config.step_wait_result] = function()

end

-- 结束并结算
cmd[Config.step_result] = function()
    bet_data = {}
end

-- 流局
cmd[Config.step_flow] = function()
    bet_data = {}
end

return cmd
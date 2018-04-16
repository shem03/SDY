local skynet    = require "skynet"
local db_mgr    = require("db_mgr")
local user_core = require("user.ctcore")
local room_core   = require("room.core")
local utils  = require("pk10.poker_utils")

-- 机器人
local cmd             = {}
local room_robots     = {}
local bet_data        = {}
local max_delay_bet   = 5
local delay_bet_count = 0
local robot_bets      = {10, 50, 100, 500, 1000}

-- 添加机器人
local function handle_robot()
    --print(g.room_info.robot_count, g.robot_user)
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
end

-- 清除游戏过程中的缓存

-- 退出机器人


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
function cmd.post_leave(uid)
    local robot_ids = table.indices(room_robots)
    if #robot_ids == 0 then
        return 
    end
    local rate = math.random(1, 100)
    if rate > 50 then
        return
    end
    local select_robot = nil
    if uid then
        select_robot = room_robots[uid]
        select_robot.is_run  = false
    else
        for id, user in pairs(room_robots) do
            if user.is_run == true then
                select_robot = user
                user.is_run  = false
                break
            end
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
function cmd.run(game_step)
    handle_robot()

    if game_step > Config.step_none then    -- 游戏已经开始
        local cur_step_fun = cmd[game_step]
        assert(cur_step_fun~=nil, "pk 10 game_step" .. game_step)
        cur_step_fun()
    end
end

-- 下注开始 185s
cmd[Config.pk_bet_start] = function()

end

-- 下注中
cmd[Config.pk_step_bet] = function()
    print("机器人 下注开始")
    if table.size(room_robots) == 0 then
        return
    end

    -- 一定时间下注
    delay_bet_count = delay_bet_count + 1
    if delay_bet_count < max_delay_bet then
        return
    end

    local bat_rate = math.random(1, 100)
    print("bat_rate", bat_rate)
    if bat_rate > 30 then
        return
    end

    local bet_peoples = {}
    for uid, user in pairs(room_robots) do
        table.insert(bet_peoples, {user = user})
    end

    if #bet_peoples == 0 then
        return
    end

    -- 取出没下注的
    local bet_people_data = bet_peoples[math.random(1, #bet_peoples)]
    local bet_people      = bet_people_data.user

    local room_robot = room_robots[bet_people.id]
    print("bet_people.bet_count , bet_people.max_bet_count", room_robot.bet_count ,room_robot.max_bet_count)
    if room_robot.bet_count > room_robot.max_bet_count then
        return
    end

    local bet_type = math.random(1, utils.get_seat_count())
    if bet_type == g.banker_seat then
        return
    end

    print("pk10 机器人下注")
    local bet_value = 0
    local bet_change = math.random(1, 100)
    if bet_change > 99 then
        bet_value = 1000
    elseif bet_change > 95 then
        bet_value = 500
    elseif bet_change > 68 then
        bet_value = 100
    else
        bet_value = robot_bets[math.random(1, 2)]
    end

    g.game_cmd.betting(bet_people, {bet_type = bet_type, bet_value = bet_value})
    room_robot.bet_count = room_robot.bet_count + 1
end

-- 下注结束
cmd[Config.pk_bet_end] = function()
    for uid, user in pairs(room_robots) do
        user.max_bet_count= math.random(1,2)
        user.bet_count= 0
    end

    delay_bet_count = 0
end

-- 等待开奖，封盘
cmd[Config.pk_wait_kaijiang] = function()
end

-- 比车
cmd[Config.pk_kaijiang] = function()
end

-- 比牌
cmd[Config.pk_bipai] = function()
end

-- 结算并等待开始
cmd[Config.pk_result] = function()
end

return cmd
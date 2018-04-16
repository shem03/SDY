local skynet = require "skynet"
local db_mgr = require("db_mgr")
require "skynet.manager"

local CMD    = {}

-----------------------------------------------------------------------------------------
--------------------------------------- 用户房间模块 --------------------------------------
-----------------------------------------------------------------------------------------
local all_rooms = {}
local all_conns = {}

-- 更新房间缓存
function CMD.update_rooms(rooms)
    all_rooms = rooms or {}
    --print("房间：", rooms)
end

-- 更新大厅在线用户
function CMD.update_conns(users)
    all_conns = users or {}
    -- print("刷新大厅用户")
end

-- 获取房间缓存
function CMD.get_rooms()
    return all_rooms
end

-- 获取大厅在线用户
function CMD.get_conns()
    return all_conns
end


-----------------------------------------------------------------------------------------
--------------------------------------- 用户好友模块 --------------------------------------
-----------------------------------------------------------------------------------------



-----------------------------------------------------------------------------------------
------------------------------------- 时时彩开奖模块 --------------------------------------
-----------------------------------------------------------------------------------------
local kj_data = {}

-- 获取最近一条开奖数据
local function getLastCj()
    local sql = "SELECT data, number, time FROM t_ct_ssc_data WHERE 1=1 order by number desc limit 1"    
    local data = db_mgr.execute(sql)[1]
    return data
end

-- 初始化
function CMD.start()
    kj_data = getLastCj()
end

-- 设置开奖数据
function CMD.set_ssc_kj_data(data)
    print("cach_pool ssc log:", data)
    kj_data = data
end

-- 获取开奖数据
function CMD.get_ssc_kj_data()
    -- 需添加逻辑判断开奖 是否是新期开奖
    return kj_data or {}
end

-- 获取最近一条开奖数据
function CMD.get_ssc_kj_data_list(data)
    local limit = data.limit or 20
    local sql = "SELECT data, number, time FROM t_ct_ssc_data WHERE 1=1 order by number desc limit " .. limit    
    local data = db_mgr.execute(sql)
    return data
end

-----------------------------------------------------------------------------------------
--------------------------------------- 机器人模块 ----------------------------------------
-----------------------------------------------------------------------------------------
local robots = {}

-- 设置机器人是否在跑
function CMD.set_robot_run(account, isRun)
    local robot = robots[account]
    if robot then
        robot.is_run = isRun
    end
end

-- 刷新机器人缓存
function CMD.update_local_cache()
    print(robots)
    local localRobots = db_mgr.get_robots()
    for account, robot in pairs(localRobots) do
        if robots[account] then
            localRobots[account] = robots[account]
        end
    end
    robots = localRobots
    print(robots)
    return true, "刷新成功"
end

-- 获取空闲机器人
function CMD.get_free_robots()
    -- 初始化机器人
	if table.size(robots) == 0 then
		robots = db_mgr.get_robots()
    end
    local freeRobots = {}
    for account, robot in pairs(robots) do
        if not robot.is_run then
            table.insert(freeRobots, robot)
        end
    end
	return freeRobots
end
-- end


-- 服务启动
skynet.start(function()
	skynet.dispatch("lua", function(session, source, cmd, ...)
		local f = assert(CMD[cmd], cmd .. "not found")
		skynet.retpack(f(...))
	end)

	skynet.register(SERVICE_NAME)
end)

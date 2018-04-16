local skynet = require "skynet"
local db_mgr = require("db_mgr")
local friend_cmd = require("friend.cmd")
require "skynet.manager"

-- 好友服数据（自行按需配置）
g = {}

local CMD    = {}

-- 出错了
local function call_error()
	LOG_ERROR(string.format("friend_center error:%s", debug.traceback()))
end


-- 启动
function CMD.start()
end

-- 数据接收
function CMD.data(msg_id, user, msg)
    local fun = friend_cmd[msg_id]
	if fun then
		local ok = xpcall(fun, call_error, user, msg)
		if ok == false then
			return send_error(user.fd, -1, "服务器出错")
		end
        return
    end
end

local function timer_call()
    skynet.timeout(100, timer_call) -- 1秒    
    -- print("好友服务")
end


skynet.start(function()
    math.randomseed(skynet.time())
	--skynet.timeout(100, timer_call)
	skynet.dispatch("lua", function(session, source, cmd, ...)
		local f = assert(CMD[cmd], cmd .. "not found")
		skynet.retpack(f(...))
	end)

	skynet.register(SERVICE_NAME)
end)

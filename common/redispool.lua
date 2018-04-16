local skynet = require "skynet"
require "skynet.manager"
local redis = require "skynet.db.redis"

local CMD = {}
local pool = {}

local maxconn
local function getconn(uid)
	local db
	if not uid or uid==-1 or maxconn == 1 then
		db = pool[1]
	else
		db = pool[uid % (maxconn - 1) + 2]
	end

	return db
end

function CMD.start()
	maxconn = tonumber(skynet.getenv("redis_maxinst")) or 2
	for i = 1, maxconn do
		local db = redis.connect{
			host = skynet.getenv("redis_host"),
			port = skynet.getenv("redis_port"),
			db = 0,
			auth = skynet.getenv("redis_auth"),
		}

		if db then
			--db:flushdb() --测试期，清理redis数据
			table.insert(pool, db)
		else
			skynet.error("redis connect error")
		end
	end
end

function CMD.docmd( uid, cmd, ... )
	local db = getconn(uid)
	return db[cmd](db, ...)
end

skynet.start(function()
	skynet.dispatch("lua", function(session, source, cmd, ...)
		local f = assert(CMD[cmd], cmd .. " not found")
		skynet.retpack(f(...))
	end)

	skynet.register(SERVICE_NAME)
end)

local skynet = require "skynet"
require "skynet.manager"
local mysql = require "skynet.db.mysql"

local CMD = {}
local pool = {}

local maxconn
local index = 2
local function getconn(sync)
	local db
	if sync then
		db = pool[1]
	else
		db = pool[index]
		assert(db)
		index = index + 1
		if index > maxconn then
			index = 2
		end
	end
	return db
end

function CMD.start()
	CMD.stop()
	maxconn = tonumber(skynet.getenv("mysql_maxconn")) or 10
	assert(maxconn >= 2)
	local host = skynet.getenv("mysql_host")
	local port = tonumber(skynet.getenv("mysql_port"))
	LOG("mysql conn:", host, port)
	for i = 1, maxconn do
		local db = mysql.connect{
			host = host,
			port = port,
			database = skynet.getenv("mysql_db"),
			user = skynet.getenv("mysql_user"),
			password = skynet.getenv("mysql_pwd"),
			max_packet_size = 1024 * 1024
		}
		if db then
			table.insert(pool, db)
			db:query("set names utf8mb4")
		else
			skynet.error("mysql connect error")
		end
	end
end

-- sync为false或者nil，sql为读操作，如果sync为true用于数据变动时同步数据到mysql，sql为写操作
-- 写操作取连接池中的第一个连接进行操作
function CMD.execute(sql, no_re_execute)
	local db = getconn()
	if db == nil then
		CMD.start()
		assert(false, "connect mysql error")
	end

	-- print("mysql:", sql)
	local status, rs = pcall(db.query,db,sql)
	if status == false then
		LOG_ERROR(string.format("SQL:%s \n err:%s \n", sql, rs))
		-- 可能是超时，则断线重连
		CMD.stop()
		CMD.start()
		if no_re_execute == nil then
			return CMD.execute(sql, true)
		end
		return
	end
	if rs.badresult == true then
		LOG_ERROR(string.format("SQL:%s \nsqlstate:%s \nerrno:%d \nerr:%s \n", sql, rs.sqlstate, rs.errno, rs.err))
	else
		return rs
	end
end

function CMD.stop()
	for _, db in pairs(pool) do
		db:disconnect()
	end
	pool = {}
end

skynet.start(function()
	skynet.dispatch("lua", function(session, source, cmd, ...)
		local f = assert(CMD[cmd], cmd .. "not found")
		skynet.retpack(f(...))
	end)

	skynet.register(SERVICE_NAME)
end)

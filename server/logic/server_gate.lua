local skynet = require "skynet"
local gateserver = require "snax.gateserver" --处理网络事件
local netpack = require "skynet.netpack"

local watchdog
local connection = {}       -- fd -> connection : {fd, client, agent, ip, mode }
local forwarding = {}       -- agent -> connection
local base_timeout = tonumber(skynet.getenv "socket_timeout")
local socket_timeout = base_timeout * 100   -- socket 超时时间

skynet.register_protocol {
    name = "client",
    id = skynet.PTYPE_CLIENT,
}

-- 
-- handler处理事件
local handler = {}

function handler.open(source, conf)
	watchdog = conf.watchdog or source
end

-- 处理消息
function handler.message(fd, msg, sz)
    -- recv  a package, forward it
    local c = connection[fd]
    c.last_time = skynet.time()

    local agent = c.agent
    if agent then
        skynet.send(agent, "lua", "data", { msg = netpack.tostring(msg, sz), sz = sz, fd = fd, ip = c.ip })
    else
        skynet.send(watchdog, "lua", "socket", "data", fd, netpack.tostring(msg, sz))
    end
end

-- 连接
function handler.connect(fd, addr)
    local c = {
        fd = fd,
        ip = addr,
        last_time = skynet.time()
    }
    connection[fd] = c
    skynet.send(watchdog, "lua", "socket", "open", fd, addr)
end

-- 不发消息
local function unforward(c)
    if c.agent then
        forwarding[c.agent] = nil
        c.agent = nil
        c.client = nil
    end
end

-- 删除连接
local function close_fd(fd)
    local c = connection[fd]
    if c then
        unforward(c)
        connection[fd] = nil
    end
end

-- 关闭连接
function handler.disconnect(fd)
    close_fd(fd)
    skynet.send(watchdog, "lua", "socket", "close", fd)
end

-- 处理错误
function handler.error(fd, msg)
    close_fd(fd)
    skynet.send(watchdog, "lua", "socket", "error", fd, msg)
end

-- 处理警告
function handler.warning(fd, size)
    skynet.send(watchdog, "lua", "socket", "warning", fd, size)
end

--
-- CMD
local CMD = {}

function CMD.forward(source, fd, client, address)
	local c = assert(connection[fd])
	unforward(c)
	c.client = client or 0
	c.agent = address or source
	forwarding[c.agent] = c
	gateserver.openclient(fd)
end

function CMD.accept(source, fd)
	local c = assert(connection[fd])
	unforward(c)
	gateserver.openclient(fd)
end

function CMD.kick(source, fd)
	gateserver.closeclient(fd)
end

-- 分发
function handler.command(cmd, source, ...)
	local f = assert(CMD[cmd])
	return f(source, ...)
end

-- 自定义handle来向gateserver注册事件处理(玩家登录，断开，数据到达等)
gateserver.start(handler)

-- 定时器
function timer_call()
    skynet.timeout(socket_timeout, timer_call) -- 5秒超时
    local cur_time = skynet.time()
    for k, v in pairs(connection) do
        if v.last_time < cur_time - base_timeout then
            skynet.error(string.format("timeout then closeclient:%d timeout:%d", v.fd, socket_timeout))
            gateserver.closeclient(v.fd)
        end
    end
end

-- 开始检测用户心跳超时
skynet.timeout(socket_timeout, timer_call)
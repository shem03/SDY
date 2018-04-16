local skynet = require "skynet"
local snax = require "skynet.snax"
require "skynet.manager"

math.randomseed(tostring(os.time()):reverse():sub(1, 7))

skynet.start(function()
    LOG("Server start")

    -- 读取端口ip
    local port = tonumber(skynet.getenv "port")
    local host = skynet.getenv "host"

    -- 启动mysql
    local mysqlpool = skynet.uniqueservice("mysqlpool")
    skynet.call(mysqlpool, "lua", "start")

    -- 启动redis
    --local redispool = skynet.uniqueservice("redispool")
    --skynet.call(redispool, "lua", "start")

    -- 启动调试
    local console_port = tonumber(skynet.getenv "console_port")
    skynet.newservice("webdebug", console_port)

    -- 创建web服务器服务
    local webserver = skynet.uniqueservice("webserver")
    
    -- 启动socket服务
	local watchdog = skynet.uniqueservice("watchdog")
	skynet.call(watchdog, "lua", "start", {
		port = port,
		address = host,
		maxclient = 9999,
		nodelay = true,
	})
    LOG("Server listen on", port)
    
    -- 启动webclient
    skynet.uniqueservice("webclient") 

    -- 启动缓存池
    local cachepool = skynet.uniqueservice("cachepool")
    skynet.call(cachepool, "lua", "start")

    -- 好友中心
    local friend_center = skynet.uniqueservice("friend_center")
    skynet.call(friend_center, "lua", "start")

    -- 业务重置服务
    -- skynet.newservice("lanucher")

    -- 测试文件
    --skynet.newservice("test")

    skynet.exit()
end)

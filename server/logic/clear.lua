local skynet = require "skynet"
local snax = require "skynet.snax"
require "skynet.manager"

math.randomseed(tostring(os.time()):reverse():sub(1, 7))

skynet.start(function()
    LOG("Server start")

    -- 启动mysql
    local mysqlpool = skynet.uniqueservice("mysqlpool")
    skynet.call(mysqlpool, "lua", "start")

    -- 启动webclient
    skynet.uniqueservice("webclient") 

    -- 业务重置服务
    skynet.newservice("lanucher")

    -- 测试文件
    --skynet.newservice("test")

    skynet.exit()
end)

skynetroot = "./skynet/"
thread = 8
logger = "server_log"
logservice = "snlua"
logpath = "."
harbor = 0
start = "main"	-- main script
bootstrap = "snlua bootstrap"	-- The service for bootstrap

-- 集群名称配置文件
nodename = "chaotoo"

log_dirname = "log"

logicservice = "./server/logic/?.lua;" ..
			   "./bin/server/logic/?.lua;" ..
			   "./common/?.lua;"..
			   "./skynet/test/?.lua;"

-- LUA服务所在位置
luaservice = skynetroot .. "service/?.lua;" .. logicservice
snax = logicservice

-- 用于加载LUA服务的LUA代码
lualoader = skynetroot .. "lualib/loader.lua"
preload = "./common/preload.lua"	-- run preload.lua before every lua service run

-- C编写的服务模块路径
cpath = skynetroot .. "cservice/?.so"

-- 将添加到 package.path 中的路径，供 require 调用。
lua_path = skynetroot .. "lualib/?.lua;" ..
		   "./common/?.lua;" ..
		   "./server/logic/?.lua"

-- 将添加到 package.cpath 中的路径，供 require 调用。
lua_cpath = skynetroot .. "luaclib/?.so;" .. "./luaclib/?.so"

-- 后台模式
--daemon = nodename..".pid"

host = "0.0.0.0"
port = 8793 --8793				                -- 监听端口
console_port = 8792 --8792                     -- 监听控制台端口
web_host = "0.0.0.0"
web_port = 8791 --8791


mysql_maxconn = 3			            -- mysql数据库最大连接数

mysql_host = "192.168.103.22" --"127.0.0.1"                -- mysql数据库主机
mysql_port = 3306 --3306			            -- mysql数据库端口
mysql_db = "v2game"	          		    -- mysql数据库库名
mysql_user = "root"                     -- mysql数据库帐号
mysql_pwd = "root"                    -- mysql数据库密码


-- redis

redis_host = "127.0.0.1"
redis_port = 6379
redis_auth = "redis123123"


socket_timeout = 120                    -- socket 超时时间2分钟
local skynet = require "skynet"
local snax = require "skynet.snax"

function do_redis(args, uid)
	return skynet.call("redispool", "lua", "docmd", uid or -1, table.unpack(args))
end

function do_http_get( url, uri)
	return skynet.call("webclient", "lua", "get", url,uri, header)
end

-- header可为空，默认json的header，header不为空情况为自定义header
function do_http_post( url, uri, data, header)
	return skynet.call("webclient", "lua", "post", url, uri, data, header)
end

function do_mysql_req( sql, sync, db_type )
	return skynet.call("mysqlpool", "lua", "execute", sql, sync, db_type)
end

function do_https_get( url )
	local https = snax.uniqueservice("httpsclient")
	return https.req.get(url)
end

function do_https_post( url, data )
	local https = snax.uniqueservice("httpsclient")
	return https.req.post(url, data)
end

function LOG_DEBUG(...)
	local info = debug.getinfo(2)
	skynet.error("debug", info.short_src, info.currentline, ...)
end

function LOG_INFO(...)
	local info = debug.getinfo(2)
	skynet.error("info_", info.short_src, info.currentline, ...)
end

function LOG_WARN(...)
	local info = debug.getinfo(2)
	skynet.error("warn_", info.short_src, info.currentline, ...)
end

function LOG_ERROR(...)
	local info = debug.getinfo(2)
	skynet.error("error", info.short_src, info.currentline, ...)
end

function LOG_FATAL(...)
	local info = debug.getinfo(2)
	skynet.error("fatal", info.short_src, info.currentline, ...)
end

function LOG( ... )
	local info = debug.getinfo(2)
	skynet.error(info.short_src, info.currentline, ...)
end

----------------------------------------------------------------------------------------------
--[[
    Author: WangYiZhao
    Date: 2018-03-29
    功能描述:字符串常见操作
--]]

-- 根据分隔符拆分字符串成列表
function String_Split(target, sep)
	if target == nil then return {} end
	local sep, list = sep or ":", {}
	local pattern = "([^"..sep.."]+)"
	target:gsub(pattern, function(c) table.insert(list, c) end)
	return list
end

-- 把列表以分隔符合并成字符串
function String_Join(list, sep)
	return table.concat(list, sep)
end

-- 生成ID
math.randomseed(os.time())
local __string_last_time = 0
local __string_last_index = 0
function String_generateID(pre)
    local cur_time = os.time()
    if cur_time ~= __string_last_time then
        __string_last_time = cur_time
        __string_last_index = 0
    else
        __string_last_index = __string_last_index + 1
    end
    local result = ""
    if pre then result = pre.."_" end
    result = result..__string_last_time.."_"..__string_last_index.."_"..math.random(0, 10000).."_"..math.random(0, 10000)
    return result
end

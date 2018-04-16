local skynet = require "skynet"
local httpc = require "http.httpc"
local dns = require "skynet.dns"
require "skynet.manager"

httpc.timeout = 300	-- set timeout 3 second

local CMD = {}

local function post_data( host, url, data, custom_header)
	local header  = nil
	-- 如果有自定义header则使用自定义header
	if custom_header then
		header = custom_header
	else
		header = { ["content-type"] = "application/json" }
	end
	local respheader = {}
	return httpc.request("POST", host, url, recvheader, header, data)
end

function CMD.post(url, uri, args, header)
	local respheader = {}
	local status, body = post_data(url, uri, args, header)
	return status, body
end

function CMD.get(url, uri)
	local respheader = {}
	local status, body = httpc.get(url, uri, respheader)
	return status, body
end

skynet.start(function()
	skynet.dispatch("lua", function(session, source, cmd, ...)
		--print(session, source, cmd, ...)
		local f = assert(CMD[cmd], cmd .. " not found")
		skynet.retpack(f(...))
	end)

	skynet.register(SERVICE_NAME)
end)

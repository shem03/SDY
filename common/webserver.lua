local skynet = require "skynet"
local socket = require "skynet.socket"
local httpd = require "http.httpd"
local sockethelper = require "http.sockethelper"
local urllib = require "http.url"
local cthttp = require "cthttp"
local json = require "cjson"
local table = table
local string = string

local mode = ...

if mode == "agent" then
local web_logic = require("web_logic")
local agent_cmd = {}

local res_header = {}

local function response(id, ...)
	local ok, err = httpd.write_response(sockethelper.writefunc(id), ...)
	if not ok then
		-- if err == sockethelper.socket_error , that means socket closed.
		LOG_ERROR(string.format("fd = %d, %s", id, err))
	end
end

local function call_error()
	LOG_ERROR(string.format("web_server error:%s", debug.traceback()))
end

local function logic_call(path, method, header, query_data, addr)
	local data = nil
	if path == "/chaotu" then
		local fun = query_data.msg_id and web_logic[query_data.msg_id]
		local ok, rec, rec_header, code
		-- print("===>", query_data.msg_id)
		if fun ~= nil then
			ok, rec, rec_header = xpcall(fun, call_error, query_data, header, addr)
			if ok == false then
				data = '{"code":-1,"error":"服务器出错"}'
			else
				data = rec
			end
		else
			data = '{"code":-1,"error":"错误的API"}'
		end
	elseif string.sub(path,1, string.len("/hgame-api/api2.0/")) == "/hgame-api/api2.0/" then
		local status, body = cthttp.client_post(path, query_data)
		data = body or "{}"

	elseif string.sub(path,1, string.len("/hgame-pay/api2.0/")) == "/hgame-pay/api2.0/" then
		local status, body = cthttp.client_pay_post(path, query_data)
		data = body or "{}"

	else
		data = '{"code":-1,"error":"错误的路径"}'
	end
	
	if query_data.msg_id ~= "ping" then
		--print("http rec:", data, query_data.msg_id)
	end
	return data, rec_header
end

function agent_cmd.request( id, addr )
	socket.start(id)
	-- limit request body size to 8192 (you can pass nil to unlimit)
	local code, url, method, header, body = httpd.read_request(sockethelper.readfunc(id), 8192)
	if code then
		if code ~= 200 then
			response(id, code)
		else
			-- if header.cookie then
			-- 	header.cookie = cookie.parse(header.cookie)
			-- end
			local tmp = {}
			local path, query = urllib.parse(url)
			
			-- skynet.error("web server url:", path, method, body)
			local query_data = nil
			if query then
				query_data = urllib.parse_query(query)
			end
			if method == "POST" then
				--print("body==>", body)
				local json_ok, json_t = pcall(json.decode, body)
				if json_ok == false then
					local res_str = '{"result":-1,"error":"格式解析错误"}'
					response(id, code, res_str, res_header)
					socket.close(id)
					return
				end
				if query_data then
					for k,v in pairs(query_data) do
						json_t[k] = v
					end
				end
				query_data = json_t
			end
			local response_data, rec_header = logic_call(path, method, header, query_data, addr)
			
			response(id, code, response_data, rec_header or res_header)
		end
	else
		if url == sockethelper.socket_error then
			skynet.error("socket closed")
		else
			skynet.error(url)
		end
	end
	socket.close(id)
end

skynet.start(function()
	skynet.dispatch("lua", function (session, source, command, ...)
		local f = assert(agent_cmd[command] or web_logic[command])
		if session == 0 then
			f(...)
		else
			skynet.retpack(f(...))
		end
	end)
end)

else

local max_agent = 10
local cmd = {}
local agent = {}

function cmd.register_url( url, opt )
	for i=1,max_agent do
		skynet.call(agent[i], "lua", "register_url", url, opt)
	end
end

skynet.start(function()
	for i= 1, max_agent do
		agent[i] = skynet.newservice(SERVICE_NAME, "agent")
		skynet.send(agent[i], "lua", "init")
	end
	local balance = 1
	local host = skynet.getenv("web_host") or "0.0.0.0"
	local port = tonumber(skynet.getenv("web_port")) or 8080
	local id = socket.listen(host, port)
	skynet.error("Listen web host "..host..":"..port)
	socket.start(id , function(id, addr)
		local ip, port = addr:match"([^:]+):?(%d*)$"
		-- skynet.error(string.format("%s connected, pass it to agent :%08x", addr, agent[balance]))
		skynet.send(agent[balance], "lua", "request", id, ip)
		balance = balance + 1
		if balance > #agent then
			balance = 1
		end
	end)

	skynet.dispatch("lua", function(session, source, command, ...)
		local f = assert(cmd[command])
		skynet.retpack(f(...))
	end)
end)

end
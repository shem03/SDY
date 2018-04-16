-- local protocol = require "protocol"
fd = nil
local last = ""
function disconn_callback()
	--ui.clear()
	if fd then
		socket.close(fd)
	end
	fd = nil
	ui.status("等待连接")
	ui.stop_timer()
	last = ""
end


local function unpack_package(text)
	if text == nil then
		return last
	end
	local size = #text
	if size < 2 then
		return nil, text
	end
	local s = text:byte(1) * 256 + text:byte(2)
	if size < s then
		return nil, text
	end
	print("unpack_package:", s)
	return text:sub(3,2+s), text:sub(3+s)
end

local function unpack_f(f, condition)
	local function try_recv(last)
		if fd == nil then
			return true, last
		end
		local result
		result, last = f(last)
		if result then
			return result, last
		end
		local r = socket.recv(fd)
		if not r then
			return nil, last
		end
		if r == "" then
			ui.msg "Server closed"
			disconn_callback()
			return '', ''
		end
		if r == true then
			return r, last
		end
		return f(last .. r)
	end

	return function()
		while true do
			local result
			result, last = try_recv(last)
			if result ~= true then
				if result then
					return result
				end
				socket.usleep(100)
			else
				if condition == false then
					return result
				end
			end
		end
	end
end

read_package = unpack_f(unpack_package, true)
read_package_asny = unpack_f(unpack_package, false)

local function short2Data(short)
	if not short then return end
	return string.char(math.floor(short/256), short%256)
end


function send_request(msg)
	local res = short2Data(#msg)..msg
	print("send res:", fd, #res, msg)
	local ok,err = pcall(socket.send, fd, res)
	if ok == false then
		disconn_callback()
		print("disconn", fd)
	end
end

function recv_response(v)
	print("result:", v)
	-- local msg_id, msg = protocol.unpack_msg(v, true)
	-- return msg_id, msg
end
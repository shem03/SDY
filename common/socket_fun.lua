local json = require "cjson"
json.encode_sparse_array(true,1)
local socket = require "skynet.socket"
local skynet = require "skynet"

local function short2Data(short)
	if not short then return end
	return string.char(math.floor(short/256), short%256)
end


function send_msg(fd, msg)
	if msg.msg_id ~= "ping" and fd and fd > 0 then
		--print(os.date('%Y-%m-%d %H:%M:%S')..'  send_msg---------:', fd, msg)
	end
	if fd and fd >0 then
		msg.code = 0
		msg.__time = skynet.time()
		local res = json.encode(msg)
		socket.write(fd, short2Data(#res)..res)
	end
end

function send_error( fd, code, error_msg, msg_id)
	if fd and fd > 0 then
		print(os.date('%Y-%m-%d %H:%M:%S').."  send_error----------:", fd, error_msg)
		local data = {
			code = code,
			error_msg = error_msg,
			msg_id = msg_id,
			__time = skynet.time()
		}
		local res = json.encode(data)
		socket.write(fd, short2Data(#res)..res)
	end
end
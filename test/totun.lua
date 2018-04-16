-- timeout tunnel
local c = require "skynet.core"
local dest, timeout = ...
dest = tonumber(dest)
timeout = tonumber(timeout or 1) * 10

local req = {}
local expired = {}
for i=1,timeout do
	expired[i] = {}
end
local current = 1
local current_time = c.intcommand("NOW")

local send = c.send

local function exit()
	for _, pack_session in pairs(req) do
		send(pack_session & 0xffffffff, 7, pack_session >> 32, "")
	end
	c.command("EXIT")
end

local function forward(type, msg, sz, session, source)
	if type == 1 then
		if source == dest then
			local pack_session = req[session]
			if pack_session then
				-- response
				req[session] = nil
				send(pack_session & 0xffffffff, 1, pack_session >> 32, msg, sz)
			else
				c.trash(msg,sz)
				c.error(string.format("Timeout message from :%08x", source))
			end
		elseif source == 0 then
			-- timer, ignore the session
			local t = c.intcommand("NOW")
			c.intcommand("TIMEOUT", current_time + 10 - t)	-- next tick (0.1s)
			current_time = current_time + 10
			current = current + 1
			if current > timeout then
				current = 1
			end
			local e = expired[current]
			-- clear timeout session
			for idx, session in ipairs(e) do
				local pack_session = req[session]
				if pack_session then
					req[session] = nil
					source = pack_session & 0xffffffff
					-- the session is timeout, raise an error (7 is skynet.PTYPE_ERROR)
					c.error(string.format(":%08x timeout: session = %x", source, session))
					if not send(source , 7, pack_session >> 32, "") then
						exit()
						return
					end
				end
				req[session] = nil
				e[idx] = nil
			end
		else
			c.trash(msg,sz)
			c.error("Trash message")
		end
	else
		local s = session == 0 and 0 or nil
		local session_id =	send(dest, type, s, msg, sz)
		if not session_id then
			c.trash(msg,sz)
			send(source, 7, session, "")
			c.error(string.format(":%08x dead",dest))
			exit()
			return
		end
		if not s then
			req[session_id] = session << 32 | source
			local e = expired[current]
			e[#e+1] = session_id
		end
	end
end

c.callback(forward, true)
c.intcommand("TIMEOUT",10)	-- 10 ticks / second
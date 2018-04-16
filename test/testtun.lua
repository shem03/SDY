local skynet = require "skynet"
require "skynet.manager"

local mode = ...

if mode == "slave" then

skynet.start(function()
	skynet.dispatch("lua", function(session, address, ti, ...)
		if session == 0 then
			print("==>", ti, ...)
			return
		end
		skynet.sleep(ti)
		skynet.ret(skynet.pack(...))
	end)
end)

else

skynet.start(function()
	local slave = skynet.newservice(SERVICE_NAME , "slave")
	-- default time is 1 second
	local tun = skynet.launch("snlua", "totun", slave, 1)
	skynet.send(tun, "lua", "send")
	print(skynet.call(tun, "lua", 50, "ping", 50))
	print(skynet.call(tun, "lua", 99, "ping", 99))
	print(skynet.call(tun, "lua", 200, "ping", 200))
end)

end
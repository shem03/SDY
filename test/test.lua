local skynet = require "skynet"

skynet.start(function()
	-- for i=1,10 do
	-- 	local url = "https://api.weixin.qq.com/cgi-bin/token?grant_type=client_credential&appid=wx22dd5a70662d6a29&secret=311c4c43d4beb747fb36faf638bb77fb"
	-- 	local code, err = https.get(function( str )
	-- 		print('callback:', str)
	-- 	end, url, '{}')
	-- end

	-- local url = "https://api.weixin.qq.com/cgi-bin/token?grant_type=client_credential&appid=wx22dd5a70662d6a29&secret=311c4c43d4beb747fb36faf638bb77fb"
	-- print(do_https_get(url))
	
	skynet.newservice("webdebug", 8888)

	local a = 0
	skynet.fork(function( ... )
		while true do
			local x = 1
			a = a + x
			print("fork ", a)
			skynet.sleep(2000)
		end
	end)
end)
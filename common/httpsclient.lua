local https = require("https")

local skynet = require "skynet"
local snax = require "snax"

function response.get(url)
	local result
	local code, err = https.get(function( str )
			result = str
	end, url)
	if code == 0 then
		return true, result
	else
		return false, code, err
	end
end

function response.post(url, data)
	local result
	local code, err = https.post(function( str )
			result = str
	end, url, data)
	if code == 0 then
		return true, result
	else
		return false, code, err
	end
end

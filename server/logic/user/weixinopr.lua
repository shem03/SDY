
local WeixinOpr = {} 

local Json=require "cjson"
local https = require("https")

--
local wxappid = "wx710480d915b1df60"
local appsecret = "45160ee379121156aa19f98024c826dc"

local tTokenInfo = {}


function getHttsToWinXinSvr(url)
	-- body

    local code, body = do_https_get(url)    
    
    if(code) then
      return Json.decode(body)
    else
      skynet.error("winxin srv happen error=",body) 
      return body
    end
 
end

function getWeixinAccessToken(iCode)
	-- body
	local url = string.format("https://api.weixin.qq.com/sns/oauth2/access_token?appid=%s&secret=%s&code=%s&grant_type=authorization_code",wxappid,appsecret,iCode)
	return getHttsToWinXinSvr(url)

end

function refreshAccessToken()
	-- body
	local url = string.format("https://api.weixin.qq.com/sns/oauth2/refresh_token?appid=%s&grant_type=refresh_token&refresh_token=%s",wxappid,tTokenInfo.refresh_token)
    tTokenInfo=getHttsToWinXinSvr(rul)
end

function checkToken()
	-- body
	local url = string.format("https://api.weixin.qq.com/sns/auth?access_token=%s&openid=%s",tTokenInfo.access_token,tTokenInfo.openid)
    local tCheckInfo = getHttsToWinXinSvr(rul)
    return tCheckInfo
end

function getWeixinHttp()
	-- body
    
	local url = string.format("https://api.weixin.qq.com/sns/userinfo?access_token=%s&openid=%s",tTokenInfo.access_token,tTokenInfo.openid)
    return getHttsToWinXinSvr(url)
end


function WeixinOpr.getWeiXinUserInfo(iCode)
	-- body
	print("getWeiXinUserInfo")
    tTokenInfo=getWeixinAccessToken(iCode)
    if(tTokenInfo.errcode ~= nil) then
    	return tTokenInfo
    end

    local tUser =getWeixinHttp()
    if(tUser.errcode ~= nil) then
    	return tUser
    end    
    return tUser
end

return WeixinOpr


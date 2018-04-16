local skynet = require("skynet")
local core = require("user.core")
local weixinopr = require("user.weixinopr")
local RoomLogic = require("room.logic")

-- OnCSQuickReg_
cmd[100] = function (fd, rMsg, ip_str)
    local ip, port = ip_str:match"([^:]+):?(%d*)$"

    local user
    if rMsg.data.code then
        return cmd[107](fd, rMsg, ip)
    end
    if rMsg.header.uid and rMsg.header.uid>0 then
        user = core.get(rMsg.header.uid, true)
        if user == nil then
            return MsgError(fd, -100, "can not find user")
        end
    else
        local uid = core.update()
        user = core.get(uid)
        if user == nil then
            return MsgError(fd, -100, "create user fail")
        end
    end
    user.ip = ip
    core.cache(user.uid, 'fd', fd)
    core.cache(user.uid, 'status', 'online')
    user.roominfo = GetUserRoom(user.uid)
    rMsg.data = user
    rMsg.data.user_id = user.uid
    rMsg.header.msg_id = 100
    MsgResponse(fd,rMsg)

    RoomLogic.ReConn(user)
    return true
end

cmd[107] = function (fd, rMsg, ip)
   local sMsg = {}
   local wxUser = weixinopr.getWeiXinUserInfo(rMsg.data.code)

   print("code=",rMsg.data.code, wxUser)
   if(wxUser.errcode ~= nil) then
        LOG_ERROR("getWeiXinUserInfo error:",wxUser.errcode, wxUser.errmsg)
        return MsgError(fd, wxUser.errcode, wxUser.errmsg)
   end
   local user = core.get_openid(wxUser.openid)
   if user == nil then
       local uid = core.update(nil, {
            nick_name = wxUser.nickname,
            union_id = wxUser.unionid,
            open_id = wxUser.openid,
            head_img_url = wxUser.headimgurl,
            sex = wxUser.sex,
            province = wxUser.province,
            city = wxUser.city
        })
        user = core.get(uid)
    else
        -- 更新微信信息
        user.nick_name = wxUser.nickname
        user.head_img_url = wxUser.headimgurl
        core.save_fields_todb(user.uid, {nick_name = wxUser.nickname, head_img_url = wxUser.headimgurl})
    end
    user.ip = ip
    core.cache(user.uid, 'fd', fd)
    core.cache(user.uid, 'status', 'online')
    user.roominfo = GetUserRoom(user.uid)
    rMsg.data = user
    rMsg.data.user_id = user.uid
    rMsg.header.msg_id = 100
    MsgResponse(fd, rMsg)

    RoomLogic.ReConn(user)
    return true
end

cmd[108] = function( user, rMsg )
    local uid = rMsg.data.uid
    local res_user = core.get(uid)
    res_user.status = res_user.cache.status
    res_user.roominfo = GetUserRoom(res_user.uid)

    rMsg.data = res_user
    MsgResponse(user.cache.fd, rMsg)
end
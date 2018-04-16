local skynet = require "skynet"
local queue = require "skynet.queue"
local notice = require("notice_utils")
local _ctuser  = require("user.ctcore")
local relation = require("friend.relation")
local message = require("friend.message")
require("util")

require "config"
local cs = queue() 
local cmd = {}

-- 判断好友是否在线
function cmd.is_online(uid)
    local all_conns = skynet.call("cachepool", "lua", "get_conns")
	local all_rooms = skynet.call("cachepool", "lua", "get_rooms")
    
    --print("all_conns===============", all_conns)
	-- 搜索大厅
    for k, v in pairs(all_conns) do
		if uid and v.user and (uid == v.user.uid) then
			return true
		end
	end

	-- 搜索房间
    for groupid, room in pairs(all_rooms) do
        local agent = room.agent
		if agent then
			if skynet.call(agent, "lua", "is_online", uid) then
				return true
			end
        end
    end

	return false
end

-- 判断好友是否在进行某游戏
function cmd.is_online_game_type(uid, game_type)
	local all_rooms = skynet.call("cachepool", "lua", "get_rooms")

	-- 搜索房间
    for groupid, room in pairs(all_rooms) do
        local agent = room.agent
		if agent then
			if skynet.call(agent, "lua", "is_online_game_type", uid, game_type) then
				return true
			end
        end
    end

	return false
end


--添加好友申请
function cmd.add_friend_apply( user, data )  --data: friend_uid, uid
    --判断自己好友数量是否已满
	if relation.get_friend_num(user.uid) > Config_friend.friend_num_limit  then
        send_error(user.fd, -2, "您的好友数量已满!")
        return
	end
	--判断对方好友数量是否已满
	if relation.get_friend_num(data.friend_uid) > Config_friend.friend_num_limit then
        send_error(user.fd, -2, "对方好友数量已满!")
        return
	end
    
    --判断是否已为好友
	if relation.is_friend( user.uid, data.friend_uid ) then
        send_error(user.fd, -2, "你们已经成为好友")
        return
    end

	--判断好友请求是否已发送
	local friend_message = {
		from_id = user.uid,
		uid = data.friend_uid,
        m_type = 2001,
        is_readed = 0
	}
	local ret = message.get_all_message( friend_message )
	if (ret[1] ~= nil) then
        send_error(user.fd, -2, "好友请求已发送,无需重复申请")
        return
    end

    --保存系统消息记录
    user.user_avatar = user.user_avatar or "http://test-37.img-cn-shanghai.aliyuncs.com/13" --头像默认值
    --禁止加自己为好友
    if data.friend_uid == user.uid then
        send_error(user.fd, -2, "禁止加自己为好友")
        return
    end
    
    message.save_message( data.friend_uid, user.uid, user.name, user.user_avatar, 2001, "申请将您加为好友" )
    
    --返回成功消息(给好友申请发起方)
    send_msg(user.fd, {
        msg_id = "add_friend_apply_success",
        msg = "添加好友请求发送成功"
    })

    --发送好友申请(若在线)(给好友申请接收方)
    local b_online = cmd.is_online(data.friend_uid)
    if b_online then
        notice.broadcast({
            msg_id = "apply_add_friend",
            from_id = user.uid,
            from_name = user.name,
            from_avatar = user.user_avatar
        }, data.friend_uid
        )
    end
end

--接受好友添加申请
function cmd.add_friend_accept(user, data)  --data: id, uid,friend_uid,friend_name
	--判断自己与对方是否已是好友
	if relation.is_friend(user.uid, data.friend_uid) then
        send_error(user.fd, -2, "您已经与对方成为好友!")
        return
	end
	--判断自己好友数量是否已满
	if relation.get_friend_num(user.uid) > Config_friend.friend_num_limit  then
        send_error(user.fd, -2, "您的好友数量已满!")
        return
	end
	--判断对方好友数量是否已满
	if relation.get_friend_num(data.friend_uid) > Config_friend.friend_num_limit  then
        send_error(user.fd, -2, "对方好友数量已满!")
        return
	end
	
    --获取本地用户信息
    local res = _ctuser.get_all_ctuser( data.friend_uid )
	local friend_avatar = res.head_img_url or "http://test-37.img-cn-shanghai.aliyuncs.com/13" --暂时写默认值
    
	--保存好友关系记录
	relation.save_friend_record(user.uid, data.friend_uid, user.name, data.friend_name, user.user_avatar, friend_avatar)

	--消息已读标记
    message.mark_isreaded_message( data.id , nil, nil)
    
    --返回成功消息(给好友申请接受方)
    send_msg(user.fd, {
        msg_id = "add_friend_accept_success",
        msg = "好友添加成功!"
    })

    --提醒好友申请已接受(给好友申请发起方)(若在线)
    local b_online = cmd.is_online(data.friend_uid)
    if b_online then
        notice.broadcast({
            msg_id = "add_friend_success",
            from_id = user.uid,
            from_name = user.name,
            from_avatar = user.user_avatar
        }, data.friend_uid
        )
    end

end

--拒绝好友添加申请
function cmd.add_friend_refuse(user, data)  --data: id, uid,friend_uid,friend_name
	--消息已读标记
    message.mark_isreaded_message( data.id , nil, nil)
    
    --返回成功消息(给好友申请接受方)
    send_msg(user.fd, {
        msg_id = "add_friend_refuse_success",
        msg = "已拒绝添加好友!"
    })
    
    --提醒好友申请已拒绝(给好友申请发起方)(若在线)
    local b_online = cmd.is_online(data.friend_uid)
    if b_online then
        notice.broadcast({
            msg_id = "add_friend_apply_refuse",
            from_id = user.uid,
            from_name = user.name,
            from_avatar = user.user_avatar
        }, data.friend_uid
        )
    end

end


--发送猜拳邀请
function cmd.invite_friend_guess( user, data )  --data: friend_uid, uid
    --获取账户消息
    local msg, dec, account = _ctuser.get_game_user_account(user.uid)
    --print("账户信息=======================",msg, dec, account)
    if(msg == "ok") then
        user.user_coin = account.balAmt or 0 
    else
        send_error(user.fd, -1, dec)
        return
    end

    --判断自己金币是否足够
	if user.user_coin <= 0  then
        send_error(user.fd, -2, "您的金币不足!")
        return
	end

    --禁止邀请自己
    if data.friend_uid == user.uid then
        send_error(user.fd, -2, "禁止邀请自己")
        return
    end
    --判断自己是否在进行猜拳游戏
    local b_guess = cmd.is_online_game_type(user.uid, "guessing")
    local b_hongbao = cmd.is_online_game_type(user.uid, "hongbao") or cmd.is_online_game_type(user.uid, "pk10")  --暂时阻止自己在红包游戏中的邀请
    if b_guess  then
        send_error(user.fd, -2, "您正在猜拳游戏中，无法发起邀请!")
        return
    end
    if b_hongbao  then
        send_error(user.fd, -2, "您正在红包游戏中，无法发起邀请!")
        return
    end
    --判断对方是否在进行猜拳或已离线
    b_guess = cmd.is_online_game_type(data.friend_uid, "guessing")
    b_hongbao = cmd.is_online_game_type(data.friend_uid, "hongbao") or cmd.is_online_game_type(data.friend_uid, "pk10")  --暂时阻止对方在红包游戏中的邀请
    local b_online = cmd.is_online(data.friend_uid)
    if b_guess then
        send_error(user.fd, -2, "对方正在猜拳游戏中，无法发起邀请!")
        return
    end
    if b_hongbao then
        send_error(user.fd, -2, "对方正在红包游戏中，无法发起邀请!")
        return
    end
    if not b_online then
        send_error(user.fd, -2, "对方已离线，无法发起邀请!")
        return
    end

    --保存系统消息记录
    user.user_avatar = user.user_avatar or "http://test-37.img-cn-shanghai.aliyuncs.com/13" --头像默认值
    message.save_message( data.friend_uid, user.uid, user.name, user.user_avatar, 2002, "邀请你进行猜拳游戏" )
    
    --返回成功消息(给好友申请发起方)
    send_msg(user.fd, {
        msg_id = "invite_friend_guess_success",
        msg = "猜拳邀请发送成功"
    })

    if cmd.is_online(data.friend_uid) then 
        --发送猜拳邀请
        notice.broadcast({
            msg_id = "apply_friend_guess",
            from_id = user.uid,
            from_name = user.name,
            from_avatar = user.user_avatar
        }, data.friend_uid
        )
    else
        send_error(user.fd, -2, "对方不在线，无法发送猜拳邀请")
    end
end

--接受好友猜拳邀请
function cmd.friend_guess_accept(user, data)  --data: uid,friend_uid,friend_name
    --获取账户消息
    local msg, dec, account = _ctuser.get_game_user_account(user.uid)
    if(msg == "ok") then
        user.user_coin = account.balAmt or 0 
    else
        send_error(user.fd, -1, dec)
        return
    end

	--判断自己金币是否足够
	if user.user_coin <= 0  then
        send_error(user.fd, -2, "您的金币不足!")
        return
	end
    
    --判断自己是否在进行猜拳游戏
    local b_guess = cmd.is_online_game_type(user.uid, "guessing")
    if b_guess then
        send_error(user.fd, -2, "您正在猜拳游戏中，无法接受邀请!")
        return
    end
    --判断对方是否在进行猜拳或已离线
    b_guess = cmd.is_online_game_type(data.friend_uid, "guessing")
    local b_online = cmd.is_online(data.friend_uid)
    if b_guess then
        send_error(user.fd, -2, "对方正在猜拳游戏中，无法接受邀请!")
        return
    end
    if not b_online then
        send_error(user.fd, -2, "对方已离线，无法接受邀请!")
        return
    end

    --约定房间ID
    -- local room_id = "A" .. tostring(math.floor(skynet.time()*1000))
    local room_id = String_generateID()

    --获取本地用户信息
    local res = _ctuser.get_all_ctuser( data.friend_uid )
	local friend_avatar = res.head_img_url or "http://test-37.img-cn-shanghai.aliyuncs.com/13" --暂时写默认值

    --返回成功消息
    send_msg(user.fd, {
        msg_id = "friend_guess_accept_success",
        msg = "接受好友猜拳邀请成功!",
        from_id = data.friend_uid,
        from_name = data.friend_name,
        from_avatar = friend_avatar,
        room_id = room_id
    })
    --提示猜拳邀请成功(给猜拳邀请发起方)
    notice.broadcast({
        msg_id = "apply_friend_guess_success",
        from_id = user.uid,
        from_name = user.name,
        from_avatar = user.user_avatar,
        room_id = room_id
    }, data.friend_uid
    )

end

--拒绝好友猜拳邀请
function cmd.friend_guess_refuse(user, data)  --data: uid,friend_uid,friend_name
    --返回成功消息(给猜拳邀请接收方)
    send_msg(user.fd, {
        msg_id = "friend_guess_refuse_success",
        msg = "已拒绝猜拳邀请!"
    })

    local b_online = cmd.is_online(data.friend_uid)
    if b_online then 
        --提示猜拳邀请被拒绝(给猜拳邀请发起方)
        notice.broadcast({
            msg_id = "apply_friend_guess_refuse",
            from_id = user.uid,
            from_name = user.name,
            from_avatar = user.user_avatar
        }, data.friend_uid
        )
    end

end

-- 判断是否为好友(搜索好友)
function cmd.is_friend(user, data)   --data: uid, friend_uid
    --获取本地用户信息
    local res_user = _ctuser.get_all_ctuser( data.friend_uid )
    if res_user ~= nil  then
        local res_friend = relation.get_all_friend( data )
        if res_friend[1] ~= nil  then
            send_msg(user.fd, {
                msg_id = "is_friend_yes",
                friend_uid = res_friend[1].friend_id,
                friend_name = res_friend[1].friend_name,
                friend_avatar = res_friend[1].friend_avatar
            })
        else
            send_msg(user.fd, {
                msg_id = "is_friend_no",
                friend_uid = res_user.id,
                friend_name = res_user.name,
                friend_avatar = res_user.head_img_url
            })
        end
    else
        send_error(user.fd, -1, "该用户不存在!")
    end

end

--发送私聊消息
function cmd.send_private_message(user, data) --data: uid, friend_uid, content
    --禁止发消息给自己
    if data.friend_uid == user.uid then
        send_error(user.fd, -2, "禁止发消息给自己")
        return
    end
    --校验与对方是否为好友
	if not relation.is_friend( user.uid, data.friend_uid ) then
        send_error(user.fd, -2, "你们不是好友!")
        return
    end

    --保存消息记录
    --单引号转义
    local content = data.content
    content = string.gsub(content, "'", "''")
	message.save_message( data.friend_uid, user.uid, user.name, user.user_avatar, 1, content )
	
	--返回消息发送成功
	send_msg(user.fd, {
		msg_id = "send_private_message_success",
        msg = "消息发送成功",
        friend_uid = data.friend_uid
	})
    
    local b_online = cmd.is_online(data.friend_uid)
    if b_online then
        --发送私聊消息(发给私信接收方)
        notice.broadcast({
            msg_id = "private_message",
            from_name = user.name,
            from_id = user.uid,
            from_avatar = user.user_avatar,
            add_time = os.date("%Y-%m-%d,%H:%M:%S"),
            content = data.content
        }, data.friend_uid
        )
    end
    
end


-- 获取消息列表
function cmd.get_message_list(user, data)   --data: uid
    local res = message.get_all_message( data )

    --返回消息记录
	send_msg(user.fd, {
        msg_id = "get_message_list_success",
        data = res
    })
end

-- 获取好友私信消息记录
function cmd.get_private_records(user, data)   --data: uid , from_id
    local res = message.get_private_records( data )

    --消息已读标记
    message.mark_isreaded_message( nil , user.uid, data.from_id)

    --返回消息记录
	send_msg(user.fd, {
        msg_id = "get_private_records_success",
        data = res
    })
end

--[[
-- 消息已读标记
function cmd.mark_isreaded_message(user, data)   --data: m_id, from_id
	local res = message.mark_isreaded_message( data.m_id, user.uid, data.from_id )
    
    --返回
	send_msg(user.fd, {
        msg_id = "mark_isreaded_message_success",
        data = res
    })
    
end]]

-- 获取所有好友
function cmd.get_all_friend(user, data)   --data: uid
	local res = relation.get_all_friend( data )
	--返回
	send_msg(user.fd, {
        msg_id = "get_all_friend_success",
        data = res
    })
    
end

-- 删除好友
function cmd.unfriend(user, data)   --data: uid, friend_uid
    --删除好友关系
    relation.unfriend( data.uid, data.friend_uid )
    --删除好友聊天记录
    message.delete_private_records( data.uid, data.friend_uid )

	--返回
	send_msg(user.fd, {
        msg_id = "unfriend_success",
        --data = res
    })
end

-- 更新好友头像
function cmd.update_friend_avatar(user, data)   --data: friend_uid, friend_avatar
	relation.update_friend_avatar( data.friend_uid, data.friend_avatar )

end


-- 通知对方目前在房间列表   暂时 猜拳用
function cmd.notice_game_room_list(user, data)   --data: uid, friend_uid
    
    --返回消息发送成功
	send_msg(user.fd, {
		msg_id = "notice_game_room_list_success",
        msg = "通知发送成功",
        friend_uid = data.friend_uid
	})
    
    local b_online = cmd.is_online(data.friend_uid)
    if b_online then
        --通知对方
        notice.broadcast({
            msg_id = "in_gameroomlist",
            from_name = user.name,
            from_id = user.uid,
            from_avatar = user.user_avatar
        }, data.friend_uid
        )
    end

end












return cmd
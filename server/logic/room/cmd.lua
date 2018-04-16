local cmd = {}
local skynet = require "skynet"
local db_mgr = require("db_mgr")
local _user = require("user.ctcore")
local _room = require("room.core")
local _ctuser = require("user.ctcore")
local notice = require("notice_utils")
local json = require("cjson")

local function _login( user )
    assert(user ~= nil)
    user.offline = false

    g.conns[user.fd] = user
    g.users[user.id] = user
    g.game_logic.login(user)
end

function cmd.disconnect( fd, force )
    local user = g.conns[fd]
    g.conns[fd] = nil
    g.real_user = g.real_user - 1
    print("======>disconnect_real_user", g.real_user)
    if g.real_user < 0 then
        g.real_user = 0
    end
    g.room_info.gameRoomInfo = g.room_info.gameRoomInfo or {}
    _room.update_room_people(g.room_info.gameRoomInfo.gameGroupId, table.size(g.conns or {}))
    LOG("cmd.disconnect:", fd, user and user.id, g.game_step, g.real_user)
    if user == nil then return end

    local data = {
        msg_id = "offline",
        uid = user.id
    }
    room_logic.broadcast(data, user.id)
    print("g.room_info.private", g.room_info.private, user.seat, g.game_step, Config.step_none)
    if (g.room_info.private and user.seat) or (g.game_step > Config.step_none and user.seat) then -- 游戏中
        user.offline = true
        g.all_offline = true
        for k,v in pairs(g.conns) do
            if not v.offline then
                g.all_offline = false
                break
            end
        end
    elseif g.game_logic.get_user_free then
         local isFree = g.game_logic.get_user_free(user)
         if isFree then
            g.game_logic.post_leave(user)
        else
            user.offline = true
            g.all_offline = true
            for k,v in pairs(g.conns) do
                if not v.offline then
                    g.all_offline = false
                    break
                end
            end
        end
    -- else
    --     g.game_logic.post_leave(user)
    -- end
    -- elseif g.room_info.game_type == "pk10" then
    --     g.game_logic.post_leave(user)
        
    -- elseif g.room_info.game_type == "hongbao" then  -- 红包/...
    --     if g.robot_user == 0 then
    --         print("机器人0个")
    --         g.game_logic.post_leave(user)
    --     else
    --         user.offline = true
    --         g.all_offline = true
    --         for k,v in pairs(g.conns) do
    --             if not v.offline then
    --                 g.all_offline = false
    --                 break
    --             end
    --         end
    --     end
    else
        g.game_logic.post_leave(user)
    end
end

-- 登录，广播
function cmd.login( fd, id, ip, user)
    local user = g.users[id] or user
    assert(user~=nil and user.custNo~=nil, "login:"..id)
    user.fd = fd
    user.ip = ip
    
    _login(user)

    g.real_user = g.real_user + 1
    print("======>login_real_user", g.real_user)
    -- 更新存储人数
    g.room_info.gameRoomInfo = g.room_info.gameRoomInfo or {}
    _room.update_room_people(g.room_info.gameRoomInfo.gameGroupId, table.size(g.conns or {}))
    -- 如果已经开局，则走断线重连
   g.game_logic.reconn(fd, id)
end

-- 强制退出房间
function cmd.quit_room( user, data )
    -- 开始未出牌
    if g.room_info.private then
        if g.ask_quit_time and g.ask_quit_time > 0 then
            return send_error(user.fd, -2, "已经有退出房间的请求")
        end
        if (g.game_step > Config.step_none or g.round > 0) and user.seat then
            local robot_users = {}
            g.ask_quit_time = Config.ask_quit_time
            for k,v in pairs(g.users) do
                if v.is_robot or user.id == v.id then
                    table.insert(robot_users, k)
                    -- 发起人、机器人默认 同意退房
                    cmd.agree_quit(v, {status = true})
                end
            end
            -- 广播通知其它人，是否允许
            user.agree_quit = true
            local data = {
                msg_id = "ask_quit",
                uid = user.id
            }
            return room_logic.broadcast(data, robot_users)
        end
    else
        if g.game_logic.try_quit and g.game_logic.try_quit(user) then
            return send_error(user.fd, -2, "已经开局，退出失败")
        end
    end

    local data = {
        msg_id = "someone_quit",
        uid = user.id,
    }
    room_logic.broadcast(data)

    -- 通知退出房间
    g.game_logic.post_leave(user)
    skynet.call(g.gate, "lua", "kick", user.fd)
end

function cmd.agree_quit( user, data )
    LOG("agree_quit:", g.ask_quit_time, user.id, data.status)
    if g.ask_quit_time == 0 then
        return
    end
    local send_data = {
        msg_id = "agree_quit",
        uid = user.id,
        status = data.status
    }
    room_logic.broadcast(send_data)
    if data.status == true then
        user.agree_quit = true
        
        local count = 0
        local cur_count = 0
        for i,v in ipairs(g.seat) do
            local user = g.users[v]
            cur_count = cur_count + 1 
            if user.agree_quit == true then
                count = count + 1
            end
        end
        -- 所有人同意退出，解散房间
        LOG("agree_quit:", count, cur_count)
        if count >= cur_count then
            g.ask_quit_time = 0
            room_logic.game_over(true)
        end
    else
        g.ask_quit_time = 0
        for i,v in ipairs(g.seat) do
            local user = g.users[v]
            user.agree_quit = nil
        end
    end
end

-- 表情
function cmd.face( user, data )
    data.code = 0
    data.uid = user.id
    room_logic.broadcast(data)
end

-- 准备
function cmd.ready( user, data )
    user.ready = true
    data.uid = user.id
    
    room_logic.broadcast(data)
end

-- ping
function cmd.ping(user, data)
    data.msg_id = "ping"
    if g.game_logic.get_game_time then
        data.game_time, data.step = g.game_logic.get_game_time()
    end
    send_msg(user.fd, data)
end

-- 进入房间
function cmd.enter_room(user, data)
end

-- 解散房间
function cmd.dissolve_room(user, data)
    print("解散房间", g.room_info)
    local gameRoomInfo = g.room_info.gameRoomInfo
    if user.uid ~= gameRoomInfo.gameOwner then
        return send_error(user.fd, -2, "您不是房主，无法进行此操作")
    end 

    -- 通知大厅玩家房间解散
    notice.broadcast({
        msg_id = "notice_dissolve_room",
        gameGroupId = gameRoomInfo.gameGroupId
    })

    -- 通知房间内玩家退出房间
    room_logic.game_over(true)
end

-- 踢人
function cmd.kick_member(user, data)
    local friendCustNo = data.friendCustNo
    local custNo = user.uid

    if not friendCustNo then
        return send_error(user.fd, -2, "被T人不能为空", "kick_member_fail")
    end

    -- 踢人成功
    send_msg(user.fd, {
        msg_id = "kick_member_success"
    })

    -- 广播
    room_logic.broadcast({
        msg_id = "some_kick_member",
        kick_uid = friendCustNo
    })

    -- 通知退出房间
    local firend = g.users[friendCustNo]
    if firend then
        g.game_logic.post_leave(firend)
        skynet.call(g.gate, "lua", "kick", firend.fd)
    end
end

-- 获取申请列表
function cmd.get_apply_list(user, data)
	-- local enter_room_apply = enter_room_apply[user.uid]
	local enter_room_apply = _room.get_apply_list(user.custNo)
	send_msg(user.fd, {
		msg_id = "get_apply_list_success",
		result = enter_room_apply
	})
end


-- 是否同意进入房间
function cmd.approve_room(user, data)
	local apply_id = data.apply_id
	local status = data.status
	if status ~= 1 and status ~= 2 then
		send_error(user.fd, -2, "status参数错误,1通过2不通过", "approve_room_fail")
        return
	end
	if apply_id == nil then
		send_error(user.fd, -2, "apply_id参数不能为空", "approve_room_fail")
		return
	end
	-----new----
	local apply_info = _room.query_apply_list(apply_id)
	if not next(apply_info) then
		return send_error(user.fd, -2, "申请已失效", "approve_room_fail")
	end

	 --把审核人拉入房间
	if status == 1 then
		local code, dec, result = _room.get_into_game_room(1, user.custNo, user.token, apply_info.room_id, user.custNo, apply_info.uid)
		if code ~= "ok" then
			return send_error(user.fd, -2, dec or "拉入房间失败", "approve_room_fail")
		end
	end


	-- 返回结果给审核人
	send_msg(user.fd, {
        msg_id = "approve_room_success",
        apply_id = apply_id,
    })

   

    -- 删除数据
    _room.delect_apply_list(apply_id)

    -- 判断申请人是否在线
    local apply_user = g.users[apply_info.uid]
	if not apply_user then
		return
	end

	-- 通知申请人
	local msg_data = {
		msg_id = "apply_approved",	
		status = status,
		enter_code = "",
		gameGroupId = apply_info.room_id,
        searchCode = apply_info.room_code,
        room_name = apply_info.room_name or "",
	}

	send_msg(apply_user.fd, msg_data)

end

-- 房间设置
function cmd.set_room_info(user, params)
    if not params.gameGroupId then
        return send_error(user.fd, -2, "房间ID不能为空", "set_room_info_fail")
    end
    if not params.beter_type or params.beter_type == "" then
        return send_error(user.fd, -2, "下注类型不能为空", "set_room_info_fail")
    end
    local code, dec, info = _room.game_room_info_modify(params)
    if code ~= "ok" then
        send_error(user.fd, -2, dec, "set_room_info_fail") 
        return
    end

    --返回成功
    send_msg(user.fd, {
        msg_id = "set_room_info_success",
        data = info
    })

    -- 广播房间信息改变
    local code, dec, gameRoomInfo = _room.get_game_room_detail(params.gameGroupId)
    if code ~= "ok" then
        return
    end
    g.room_info.gameRoomInfo = gameRoomInfo

    -- room_logic.broadcast({
    --     msg_id = "someone_set_room_info",
    --     gameRoomInfo = gameRoomInfo
    -- })
    notice.broadcast({
        msg_id = "someone_set_room_info",
        gameRoomInfo = gameRoomInfo
    })

end

-- 转让房主
function cmd.change_room_owner(user, data)
    if not data.gameGroupId then
        return send_error(user.fd, -2, "房间ID不能为空", "change_room_info_fail")
    end
    local code, dec, gameRoomInfo = _room.get_game_room_detail(data.gameGroupId)
    if code ~= "ok" then
        send_error(user.fd, -2, dec, "change_room_info_fail") 
        return
    end
    g.room_info.gameRoomInfo = gameRoomInfo

    -- 广播房间信息改变
    room_logic.broadcast({
        msg_id = "room_info_change",
        gameRoomInfo = gameRoomInfo
    })

    --返回成功
    send_msg(user.fd, {
        msg_id = "change_room_owner_success"
    })
end

-- 是否被禁言
local function is_chat_message(uid)
    local roomid = g.room_info.gameRoomInfo.gameGroupId
    local result = _room.get_room_user_info(roomid, uid)

    if result.allow_speak == 0 then
        return false
    end
    
    return true
end

-- 聊天
function cmd.chat_message(user, data)
    local msg_type = data['content'].msg_type -- 消息类型
    if msg_type ~= Config.msg_type_normal and 
       msg_type ~= Config.msg_type_barrage then  
       return send_error(user.fd, -2, "未知的消息类型", "chat_message_fail")
    end
    local sender_name = data['content'].name -- 发送者名称

    data.code = 0
    data.msg_id = "chat_message"
    data.uid = user.id

    -- 判断是否禁言
    if not is_chat_message(user.id) then
        send_msg(user.fd, {
            msg_id = "chat_message_fail",
            error_msg = "您已被禁言",
        })
        return
    end

    -- 存储消息
    local content = json.encode({data['content'].info})
    data['content'].info = content
    _room.save_report_info(msg_type, content, user.id, sender_name)

    -- 消息转发
    room_logic.broadcast(data)
end

-- 群/个人禁言
-- allow       0不允许    1允许
-- object      1成员      2群
-- is_manager  0不是管理员 1是管理员 
function cmd.allow_speak(user, data)
    local allow     = data.allow
    local object    = data.object
    local isManager = data.is_manager
    local playerId = data.uid
    local gameRoomOwner = g.room_info.gameRoomInfo.gameOwner
    local roomid = g.room_info.gameRoomInfo.gameGroupId
    if isManager == 1 or playerId == gameRoomOwner then
        if object == 1 then
            local res = _room.update_user_allow_speak(roomid, playerId, allow)
        elseif object == 2 and user.id == gameRoomOwner then
            local res = _room.update_group_allow_speak(roomid, allow)
        end

        local list = _room.get_allow_list(roomid)
        room_logic.broadcast({
            msg_id = "allow_speak_success",
            allow_speak = allow,
            data = list,
        })
    else
        send_error(user.fd, -2, "您无权限进行此操作", "allow_user_speak_fail")
    end
end

-- 获取禁言列表
function cmd.get_allow_list(user, data)
    local roomid = g.room_info.gameRoomInfo.gameGroupId
    local list = _room.get_allow_list(roomid)
    send_msg(user.fd, {
        msg_id = "get_allow_list_success",
        data   = list
    })
end

return cmd
local skynet = require "skynet"
require "skynet.manager"
local json = require "cjson"
json.encode_sparse_array(true,1)
local db_mgr = require("db_mgr")
require "socket_fun"
require "config"

local CMD = CMD or {}
local SOCKET = SOCKET or {}

-- 全局表
g = g or {
    gate = nil,
    agent = {},
    conns = {},
    users = {},
    passwords = {},
    online_num = 0,
    rebot_num = 0,
	run_room = {},
	
}

room_mgr = require "room.mgr"
rooms = rooms or {}
local function init()
    -- 随机种子
    math.randomseed(skynet.time())

    -- 机器人个数
    g.rebot_num = db_mgr.count("c_robot")
    LOG("g.rebot_num:", g.rebot_num)

    -- 初始化用户表递增ID
    db_mgr.execute("alter table d_user AUTO_INCREMENT=100000;")

    -- 初始化
    Config_init()
end

-- 连接服务端
function SOCKET.open(fd, addr)
    LOG("New client from : " .. addr, fd)

    local ip, port = addr:match"([^:]+):?(%d*)$"
	skynet.call(g.gate, "lua", "accept", fd)
	g.conns[fd] = {ip = ip, uid = nil, fd=fd}
	g.online_num = g.online_num + 1
end

-- 断开服务端
function SOCKET.close(fd)
    LOG("socket close", fd, g.online_num)
    g.close_conn(fd)
end

-- 错误处理
function SOCKET.error(fd, msg)
    LOG("socket error", fd, msg)
    g.close_conn(fd)
end

-- 警告
function SOCKET.warning(fd, size)
    -- size K bytes havn't send out in fd
    LOG("socket warning", fd, size)
end

-- SOCKET接口 入口函数
function SOCKET.data(fd, msg)
    local msg = json.decode(msg)
	if msg.msg_id ~= "ping" then
		print("SOCKET.data:", fd, msg)
	end
	if msg == nil or msg == false then
		send_error(fd, -1, "消息格式错误")
		return
	end
	if msg.msg_id == nil then
		send_error(fd, -1, "没有消息ID")
		return
	end

	room_mgr.cmd(fd, msg)
end

-- CMD
function CMD.start(conf)
    room_mgr.init()
    --print("start==>", g.gate, conf)
    skynet.call(g.gate, "lua", "open" , conf)
end

-- data = {roomid, fd, id, round}
function CMD.leave_agent( data )
    assert(data.roomid ~= nil, "roomid is nil")
    return room_mgr.exit_member(data)
end

-- 清空玩家房间信息，异常卡在房间里出不来了
function CMD.clear_user_roominfo( uid )
    return room_mgr.clear_user_roominfo(uid)
end

-- 强制销毁房间，清空房间人员
function CMD.force_quit_room( roomid, agent )
    return room_mgr.force_quit_room(roomid, agent)
end

-- 设置房间最低机器人数 
function CMD.set_room_robot_count(roomid, count)
	return room_mgr.set_room_robot_count(roomid, count)
end

-- 换房
function CMD.change_room( roomid, fd, id )
    local user = g.users[id]
	if user then
		user.roomid = nil
		user.r_password = nil
	end
	room_mgr.exit_member(roomid, fd, id)
	local room = room_mgr.random_room(roomid)
	assert(room~=nil, "room is nil")
	room_mgr.enter_room(user, room)
end

-- 查询房间
function CMD.query_user_room( uid )
    local user = g.users[uid]
	if user == nil then
		return
	end
	local room = room_mgr.get_room(user.roomid)
	return user.roomid, room and room.password
end

-- 查询在线
function CMD.query_online_num()
    return g.online_num
end

--获取俱乐部房间列表信息(JSON)
function CMD.get_run_club_roomsinfo(clubid)
	local result = {}
	if g.run_club_rooms ~= nil then
		result = g.run_club_rooms[clubid]
	end
	return json.encode(result)
end

--获取俱乐部房间信息
function CMD.get_club_roominfo(clubid,roomid)
	local result = nil
	if g.run_club_rooms ~= nil then
		local club_rooms = g.run_club_rooms[clubid]
		if club_rooms ~= nil then
			result = club_rooms[roomid]
		end
	end
	return result
end

function CMD.get_run_roominfo()
	return json.encode(g.run_room)
end

function CMD.set_cheat_uid(roomid, uid)
	local room = room_mgr.get_room(roomid)
	LOG("set_cheat_uid:", roomid, uid)
	room.cheat_uid = uid
end

skynet.start(function()
    -- skynet.timeout(1, timer_call)
	init()
	skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
		if cmd == "socket" then
			local f = SOCKET[subcmd]
			f(...)
			-- socket api don't need return
		else
			local f = assert(CMD[cmd])
			if source == 0 then
				f(subcmd, ...)
			else
				skynet.ret(skynet.pack(f(subcmd, ...)))
			end
		end
	end)

	g.gate = skynet.newservice("server_gate")
	skynet.register(SERVICE_NAME)
end)
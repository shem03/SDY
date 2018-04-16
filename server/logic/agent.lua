local skynet = require "skynet"
local netpack = require "skynet.netpack"
local socket = require "skynet.socket"
local json = require "cjson"
local friend_cmd = require("friend.cmd")
require "socket_fun"
require "config"

require("room.room_logic")

g = {
	room_info = 0,
	game_logic = nil,
	game_cmd = nil,
	game_step_lua = nil,
	roundid = nil, -- 局ID

	report_info_list = {},  -- 房间内的播报消息列表

	conns = {},
	users = {},
	seat = {},

	round_score = {}, -- 每局分数

	watchdog = nil,
	gate = nil,
	real_user = 0,
	robot_user = 0,

	round = 0,            -- 当前局数
	pre_round_data = nil, -- 上一局数据
	banker = nil,         -- 当前局的庄家
	
	-- 当前局状态
	game_step = Config.step_none, -- 当前游戏步骤
	game_time = 0,                -- 当前步骤进行的时间
	game_leave_time = 0,

	ask_quit_time = 0,
	
	cur_game_id = 0,

	cheat = nil,         -- 作弊的玩家ID

	new_gamer = {},   --新玩家

	cmd = require "room.cmd",
}

local CMD = {}

function CMD.start(room_info, fd, id, watchdog, gate, rebot_num, ip, user)
	if id then
		LOG("agent start:", room_info.game_type, id, "min:", room_info.min_count, "fd:", fd)
	else
		LOG("agent empty start:", room_info.game_type, "min:", room_info.min_count, "fd:", fd)
	end
	print("房间服务开始==============(room.agent)", room_info.agent)
	g.room_info = room_info

	-- print("room_info===================", room_info)
	assert(room_info.game_type ~= nil)
	if room_info.game_type == "daboluo" then
		user.id = tonumber(user.id)
		--print(user)
	end
	if g.game_logic == nil then
		g.game_logic = require(room_info.game_type..".logic")
		Config_init()
		-- 初始化当前房间ID
		g.roundid = room_info.roundid
		-- 初始化逻辑变量
		if g.game_logic.loader then
			g.game_logic.loader()
		end
	end
	assert(g.game_logic ~= nil)
	if g.game_step_lua == nil then
		g.game_step_lua = require(room_info.game_type..".step")
	end
	assert(g.game_step_lua ~= nil)
	if g.game_cmd == nil then
		g.game_cmd = require(room_info.game_type..".cmd")
	end
	assert(g.game_cmd ~= nil)

	g.watchdog = watchdog
	g.gate = gate
	g.rebot_num = rebot_num
	if fd then
		skynet.call(g.gate, "lua", "forward", fd)
	end

	if Config.chanel ~= "xzj" and g.room_info.variety then
		LOG_ERROR("房间初始化失败")
		return
	end

	g.room_type = room_info.room_type

	if g.game_logic.init_game then
		g.game_logic.init_game(user)
	end
	if fd then
		g.cmd.login(fd, id, ip, user)
	end
end

function CMD.reconn(fd, id)
	skynet.call(g.gate, "lua", "forward", fd)
	g.cmd.reconn(fd, id)
end

function CMD.disconnect( fd )
	g.cmd.disconnect(fd)
end

local function call_error()
	LOG_ERROR(string.format("agent error:%s", debug.traceback()))
end

function CMD.data( data )
	-- 数据回调
	local ok, msg = xpcall(json.decode, debug.traceback, data.msg)
	if ok == false then
		LOG_ERROR("logic protocol error:", data.sz, data.fd, data.msg)
		send_error(data.fd, -1, "can't protocol packet")
		return
	end
	if msg.msg_id == nil then
		print(data)
		send_error(data.fd, -1, "msg_id can't nil")
		return
	end
	if msg.msg_id ~= "ping" then
		print("agent cmd:", msg)
	end
	local user = g.conns[data.fd]
	-- print("=========", g.conns, data.fd, msg.msg_id)
	if user == nil then
		-- 没有找到用户
		send_error(data.fd, -1, "没有找到用户")
		return
	end
	local fun = g.cmd[msg.msg_id] or g.game_cmd[msg.msg_id]
	if fun then
		local ok = xpcall(fun, call_error, user, msg)
		if ok == false then
			return send_error(data.fd, -1, "服务器出错")
		end
		return
	elseif friend_cmd[msg.msg_id] then
		--print("好友接收")
		-- 好友相关数据接收
		skynet.call("friend_center", "lua", "data", msg.msg_id, user, msg)
		return
	end
		
	if msg.msg_id then
		send_error(data.fd, -1, "agent没有找到API:"..msg.msg_id)
	end
end

-- 设置作弊玩家
function CMD.set_cheat_uid(uid)
	if tonumber(uid) > 0 then
		local user = g.users[uid]
		if user == nil or user.seat == nil then
			return false
		end
		LOG("set_cheat_uid:", uid)
		g.cheat = uid
	else
		LOG("clear_cheat_uid:", uid)
		g.cheat = nil
	end
	return true
end

-- 通知消息
function CMD.notice_action(data, uid)
	local conns = g.conns or {}
	--print("===>", data, uid)
	if uid then
		for fd, conn in pairs(conns) do
			if conn.uid == uid then
				send_msg(fd, data)
				break
			end
		end
	else
		room_logic.broadcast(data)
	end
end

function CMD.get_online_num()
	local conns = g.conns or {}

	return table.size(conns)
end

-- 判断用户是否在线
function CMD.is_online(uid)
	local conns = g.conns or {}
	--print("online=======>", uid)
	for fd, conn in pairs(conns) do
		if  uid and uid == conn.uid  then
			return true
		end
	end

	return false
end

-- 判断用户是否在进行某游戏
function CMD.is_online_game_type(uid, game_type)
	local conns = g.conns or {}
	--print("g.room_info.game_type,game_type,  find:uid===================", g.room_info.game_type,game_type, uid)
	for fd, conn in pairs(conns) do
		if  uid and (uid == conn.uid) and (g.room_info.game_type == game_type) then
			return true
		end
	end

	return false
end



-- 设置机器人数量
function CMD.set_room_robot_count(count)
	g.room_info.robot_count = count
end

-- 游戏定时器
local function timer_call()
	skynet.timeout(100, timer_call) -- 1秒

	room_logic.run()

	--俱乐部开房后这个变量为nil
	if g.game_step_lua ~= nil then
		g.r_game_time = 0
		g.game_step_lua.run()
	end
end

skynet.start(function()
	math.randomseed(skynet.time())
	skynet.timeout(100, timer_call)
	skynet.dispatch("lua", function(source,address, command, ...)
		local f = CMD[command]
		-- print("command", command)
		if source == 0 then
			skynet.pack(f(...))
		else
			skynet.ret(skynet.pack(f(...)))
		end
	end)
end)

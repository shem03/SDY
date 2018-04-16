local skynet      = require "skynet"
local room_config = require("room.room_config")
local _user 	  = require("user.core")
local _ctuser 	  = require("user.ctcore")
local _room 	  = require("room.core")
local _room_cmd 	  = require("room.cmd")
local clublogic   = require("club.logic")
local friend_cmd  = require("friend.cmd")
local queue = require "skynet.queue"
local cs = queue() 
local mgr		   = {}
local enter_room_apply = {}
local allow_enter_room_apply = {}

-- 更新大厅连接
local function update_cache_conns(conns)
	skynet.call("cachepool", "lua", "update_conns", conns)
end

-- 更新所有房间agent
local function update_cache_rooms(rooms)
	skynet.call("cachepool", "lua", "update_rooms", rooms)
end

-- 获取房间
local function get_room( roomid )
	return rooms.all[roomid]
end
mgr.get_room = get_room

-- 获取房间
local function get_typeroom( roomid )
	local room_type = math.floor(roomid/100000)
	if rooms[room_type] == nil then
		return
	end
	return rooms[room_type]
end

-- 设置房间机器人数
function mgr.set_room_robot_count(roomid, count)
	local room = get_room(roomid)
	print(rooms.all, roomid)
	if not room  then
		return false, "房间未开启"
	end
	if room.agent then
		room.robot_count = count
		skynet.call(room.agent, "lua", "set_room_robot_count", count)
		return true, "设置成功"
	else
		return false, "房间未开启"
	end
end

-- 关闭用户连接
g.close_conn = function(fd)
	local a = g.conns[fd]
	print("close_conn:", fd)
	if a then
		skynet.call(g.gate, "lua", "kick", fd)
		if a.user and a.user.fd == fd then
			if a.user.roomid then
				local room = get_room(a.user.roomid)
				if room.agent then
					skynet.call(room.agent, "lua", "disconnect", fd)
				end
			else
				g.users[a.user.uid] = nil
			end
			a.user.fd = nil
		end
		g.online_num = g.online_num - 1
		g.conns[fd] = nil
		update_cache_conns(g.conns)
	end
end

-- 初始化
function mgr.init()
	rooms = room_config.init_room()
end

-- 出错了
local function call_error()
	LOG_ERROR(string.format("mgr error:%s", debug.traceback()))
end

--接口统一处理函数
function mgr.cmd( fd, msg )
	local fun = mgr[msg.msg_id]
	local friend_fun = friend_cmd[msg.msg_id]
	if fun then
		if msg.msg_id ~= "ping" and msg.msg_id ~= "login" then
			-- print(fd, msg)
			local user = g.conns[fd].user
			if user == nil then
				return send_error(fd, -1, "请先登录")
			end
			if user.fd == nil then
				return -- 用户已经断线
			end
			local ok = xpcall(fun, call_error, user, msg)
			if ok == false then
				return send_error(fd, -1, "服务器出错")
			end
		else
			local ok = xpcall(fun, call_error, fd, msg)
			if ok == false then
				return send_error(fd, -1, "服务器出错")
			end
		end
	elseif friend_fun then
		local user = g.conns[fd].user
		if user == nil then
			return send_error(fd, -1, "请先登录")
		end
		if user.fd == nil then
			return -- 用户已经断线
		end
		-- 好友相关数据接收
		skynet.call("friend_center", "lua", "data", msg.msg_id, user, msg)
	else
		send_error(fd, -1, "找不到API:"..msg.msg_id)
	end
	
end

-- 心跳包回包
function mgr.ping(fd, data)
	send_msg(fd, {time=skynet.time(),msg_id="ping"})
end

-- 登录
function mgr.login_bak( fd, data )	
	if data.deviceid == nil then
		return send_error(fd, -1, "参数deviceid不能为空", "login")
	end
	local uid = _user.get_uid(data.deviceid)
	if uid == nil then
		return send_error(fd, -1, "deviceid有误", "login")
	end
	local user = g.users[uid]
	if user == nil then
		user = {fd=fd, deviceid=data.deviceid, uid = uid}
	else
		-- 挤下线
		local old_fd = user.fd
		if old_fd == fd then
			return send_error(fd, Config.error_code_re_login, "不能重复登录", "login")
		end
		user.fd = fd
		send_error(old_fd, Config.error_code_re_login, "小子，你被T下线了", "login")
		g.close_conn(old_fd)
	end

	g.users[uid] = user
	g.conns[fd].user = user
	user.ip = g.conns[fd].ip
	send_msg(fd, {msg_id="login_success"})
end

-- 进入房间
local function _enter_room_bak( user, room, user_info, gameGroupId )
	assert(room~=nil)
	--print("room=================",room)
	-- 判断金币是否足够
	if room.min_coin > 0 and user then
		if user_info.user_coin < room.min_coin then
			send_error(user.fd, -5, "金币不够，进入房间失败", "enter_room")
			g.close_conn(user.fd)
			return
		end
	end
	-- 通知agent加入房间
	if room.agent == nil then
		local ok, rec = pcall(skynet.newservice, "agent")
		if ok then
			room.agent = rec
		elseif user then
			send_error(user.fd, -3, "服务出错，进入房间失败", "enter_room")
			g.close_conn(user.fd)
			return
		else
			return 'error'
		end
	end
	-- 发送消息加入房间成功
	-- print("e Config", Config)
	-- print("e room", room)
	if user then
		send_msg(user.fd, {
			msg_id="enter_room_success", 
			roomid=room.roomid,
			game_type = room.game_type,
			rtype=room.room_type, 
			seat_num = room.max_count,
			min_num = room.min_count or room.max_count,
			time = Config.auto_card_time, -- 理牌时间
			password = room.password,
			have_banker = room.have_banker,
			room_card = room.room_card,
			room_coin = room.room_coin,
			card_num = room.card_num,
			round_num = room.round_num,
			owner = room.owner,
			danse = room.danse,
			variety = room.variety,
		})
		room.members[user.uid] = user_info.user_name
		if user.roomid and user.roomid ~= room.roomid then
			LOG_ERROR("user.roomid ~= room.roomid", tostring(user), tostring(room))
		end
		if not user.roomid or user.roomid ~= room.roomid then
			-- 加入房间
			room.member_count = room.member_count + 1
			user.roomid = room.roomid
			user.r_password = room.password
			-- if room.member_count >= room.min_count then 
				-- 把该房间移到最后
			-- end
		end
	end
	local room_type = room.room_type
	local _rooms = rooms[room_type]
	local type_rooms
	if room.private then
		type_rooms = _rooms.private
	else
		type_rooms = _rooms.index
	end
	table.remove(type_rooms, 1)
	table.insert(type_rooms, room)
	-- 俱乐部里的游戏房间
	if room.clubid ~= nil then
		g.run_club_rooms = g.run_club_rooms or {}
		g.run_club_rooms[room.clubid] = g.run_club_rooms[room.clubid] or {}
		g.run_club_rooms[room.clubid][room.roomid] = room
	end
	if user then
		skynet.call(room.agent, "lua", "start", 
			room, 
			user.fd, user.uid, 
			skynet.self(), 
			g.gate, 
			g.rebot_num, 
			user.ip)
	else
		-- 俱乐部 开空房
		skynet.call(room.agent, "lua", "start", 
			room, 
			nil, nil, 
			skynet.self(), 
			g.gate, 
			g.rebot_num, 
			nil)
	end
	return true
end

function mgr.random_room( old_roomid )
	local old_room = get_room(old_roomid)
	local _rooms = get_typeroom( old_roomid )
	local type_rooms = _rooms[old_room.bet]
	local i = 0
	local target = nil
	while i < 10 do
		i = i + 1
		local room = type_rooms[i]
		if room and room.roomid ~= old_roomid then
			target = room
			break
		end
	end
	print("random_room:", old_roomid, target)
	if target == nil then
		return type_rooms[1]
	end
	return target
end

function mgr.enter_room_bak( user, data )
	if user.r_password and data.password then
		if tonumber(data.password)~=user.r_password then
			-- 判断房间是否存在，如果已经不存在，则去掉
			local room = g.passwords[user.password]
			if room ~= nil then
				send_error(user.fd, -2, "请先继续未结束的房间:"..user.r_password, "enter_room")
				g.close_conn(user.fd)
				return
			else
				user.r_password = nil
				user.roomid = nil
			end
		end
	end
	if data.password then
		data.password = tonumber(data.password)
		local room = g.passwords[data.password]
		if room == nil then
			-- room = get_room(data.password)
			-- if room == nil then
				send_error(user.fd, Config.error_code_no_room, "亲~房间已经解散~", "enter_room")
				g.close_conn(user.fd)
				return
			-- end
			-- if room.password then
			-- 	send_error(user.fd, -2, "密码不对", "enter_room")
			-- 	return	
			-- end
		end

		-- 如果是俱乐部游戏房间，判断请求是否合法
		if room.clubid ~= nil then
			local error_msg = clublogic.check(room.clubid,user.uid,0,room.roomid)
			if error_msg ~= nil then
				send_error(user.fd, -2, error_msg, "enter_room")
				g.close_conn(user.fd)
				return 
			end
		end
		local user_info = _user.get(user.uid)
		return _enter_room(user, room, user_info)
	end
	if data.model == "create_private" then
		return mgr.create_room(user, data)
	end
	local roomid = data.roomid
	if roomid == nil then
		return mgr.empty_seat(user, data)
	end
	local room = get_room(roomid)
	if room == nil then
		send_error(user.fd, -2, "找不到房间", "enter_room")
		g.close_conn(user.fd)
		return 
	end
	if room.password then
		send_error(user.fd, -2, "密码不对", "enter_room")
		g.close_conn(user.fd)
		return	
	end
	-- 大赢家要求，不能观战
	if room.member_count >= room.min_count then
		send_error(user.fd, -2, "已经满人", "enter_room")
		g.close_conn(user.fd)
		return 
	end 

	-- 如果是俱乐部游戏房间，判断请求是否合法
	if room.clubid ~= nil then
		local error_msg = clublogic.check(room.clubid,user.uid,0,room.roomid)
		if error_msg ~= nil then
			send_error(user.fd, -2, error_msg, "enter_room")
			g.close_conn(user.fd)
			return
		end
	end
	local user_info = _user.get(user.uid)
	_enter_room(user, room, user_info)
end

function mgr.create_room( user, data )
	if data.type == nil then
		send_error(user.fd, Config.error_code_no_room, "没有找到房间类型:正常十三水(1)", "enter_room")
		g.close_conn(user.fd)
		return 
	end
	local _rooms = rooms[data.type]
	local room = nil
	assert(_rooms~=nil)

	for k,v in pairs(_rooms.private) do
		-- 俱乐部管理员开房成功后不在房间内
		if v.member_count == 0 and v.agent == nil then
			room = v
			break
		end
	end
	if room == nil then
		send_error(user.fd, -2, "房间已满，请稍候~", "enter_room")
		g.close_conn(user.fd)
		return
	end

	-- 是否是俱乐部里的游戏房间
	room.clubid = data.clubid or nil
	LOG("create room:", user.uid, tostring(data))
	local user_info = _user.get(user.uid)
	-- 判断房卡是否充足，暂时扣除房卡作为抵押
	if room.private then
		local min_count = 4
		if data.seat_num then
			min_count = data.seat_num
		end
		if min_count == 2 then
			min_count = 4
		end

		-- 麻将房卡 只和局数有关
		if room.game_type == 'mahjong' then
			min_count = 4
			data.card_num = 13
		end
		local card_key = room.game_type.."_"..min_count.."_"..data.card_num.."_"..(data.round_num or Config.room_round[1])
		local card = Config.room_card[card_key]
		if card == nil then
			card = 80
			LOG_ERROR(user.fd, -4, "找不到该房卡配置:"..card_key, "enter_room")
		end
		room.room_card = tonumber(card)

		if room.clubid == nil then
			if user_info.user_money < card or _user.update_money(user_info, -card) == false then
				send_error(user.fd, -3, "房卡不足，请充值~", "enter_room")
				g.close_conn(user.fd)
				return
			end
			_user.add_consume_log(user.uid, "money", -card, room.game_type.."消费", user_info.user_money)
			send_msg(user.fd, {
				msg_id="update_bee", 
				cur_card=user_info.user_money
			})
		else
			-- 如果是俱乐部游戏房间，判断请求是否合法
			local error_msg,fund = clublogic.check(room.clubid,user.uid,card)
			if error_msg ~= nil then
				send_error(user.fd, -2, error_msg, "enter_room")
				g.close_conn(user.fd)
				return
			end

			send_msg(user.fd, {
				msg_id="update_club_fund", 
				clubid = room.clubid,
				cur_fund=fund
			})
		end
	end

	-- 局数、几人场、玩法、封顶
	room.round_num = data.round_num or 1
	room.max_count = data.seat_num or room.max_count
	-- 只需要到达的人数，即可开局
	room.min_count = data.min_num or room.max_count
	room.score_type = data.score_type or 2 --1：放胡单赔、2：放胡三家赔、3：放胡双倍单赔
	room.compare_gold_score = data.compare_gold_score or 0 	-- 赌金模式
	room.topscore = data.topscore or -1				-- 封顶模式
	room.have_banker = data.have_banker or room.have_banker
	room.owner = user.uid
	room.card_num = data.card_num or room.card_num
	room.danse = data.danse
	room.variety = data.variety
	room.roundid = math.floor(skynet.time())
	-- 俱乐部里游戏房间（名称、俱乐部ID）
	if room.clubid ~= nil then
		room.name = data.name or nil
		if room.name == nil or utfstrlen(room.name) == 0 then
			room.name = "俱乐部房间"
			-- send_error(user.fd, -2, "缺少房间名称", "enter_room")
		end
		room.times_num = data.times_num or nil
		if room.times_num == nil or room.times_num < 0 then
			send_error(user.fd, -2, "缺少房间倍率", "enter_room")
			g.close_conn(user.fd)
			return
		end
	end

	-- 赌金、封顶模式 只能二选一
	if room.compare_gold_score > 0 and room.topscore > 0 then
		send_error(user.fd, -2, "赌金、封顶模式 只能二选一~", "enter_room")
		g.close_conn(user.fd)
		return
	end

	-- 创建成功
	-- 设置密码
	local password
	for i=1,50 do
		local temp = math.floor(math.random(1000000) % 100000) + 100000
		if g.passwords[temp] == nil then
			password = temp
			break
		end
	end
	if password == nil then
		send_error(user.fd, -2, "房间创建失败，请稍候~", "enter_room")
		g.close_conn(user.fd)
		return
	end

	LOG("password:", room.roomid, password)
	room.password = password
	g.passwords[password] = room

	local result = nil
	--need_outroom 开房后是否退出房间，由客户端主动上传
	if room.clubid == nil or data.need_outroom == nil or data.need_outroom == 0 then
		result = _enter_room(user, room, user_info)
	else
		-- 俱乐部管理员开房成功后不在房间内
		result = _enter_room(nil, room, nil)
	end
	if result == true then
		g.run_room[room.roomid] = room
	else
		send_error(user.fd, -2, "房间创建失败，请稍候~", "enter_room")
		g.close_conn(user.fd)
	end
end

-- 随机快速进入
function mgr.empty_seat(user, data)
	-- data.type  0普通  2多三张 4百变 51百人牛牛
	-- data.bet  需要的金币
	-- 先查找有没空闲的房间
	if data.type == nil then
		send_error(user.fd, Config.error_code_no_room, "没有找到房间类型:正常十三水(1)", "enter_room")
		g.close_conn(user.fd)
		return 
	end
	local _rooms = rooms[data.type]
	local room = nil
	local type_rooms = nil
	assert(_rooms~=nil)
	for k,v in pairs(_rooms.index) do
		if v.member_count < v.min_count then
			room = v
			break
		end
	end
	if room == nil then
		send_error(user.fd, -2, "没有找到房间类型:正常十三水(1)", "enter_room")
		g.close_conn(user.fd)
		return
	end
	room.variety = data.variety
	room.danse = data.danse
	local user_info = _user.get(user.uid)
	local result = _enter_room(user, room, user_info)
	if result == true then
		g.run_room[room.roomid] = room
	end
end

-- data = {roomid, fd, id, round}
function mgr.exit_member( data )
	local result_fund = 0
	local room = get_room(data.roomid)
	local user = g.users[data.id]
	if user and room.members[data.id] then
		LOG("exit_member: (room.member_count, roomid, fd, uid, room.agent, room)",
			 room.member_count, data.roomid, data.fd, data.id, room.agent, user and user.roomid, room)
		user.roomid = nil
		user.r_password = nil
		room.members[user.uid] = nil
		room.member_count = room.member_count - 1
	end
	if room == nil then return "该房间已不存在" end
	if data.managersend ~= nil and data.managersend == 1 and room.clubid == nil then return "该房间不在该俱乐部" end
	-- if room.clubid == nil and user == nil then return end
	-- if room.clubid == nil and user.roomid ~= data.roomid then return end
	LOG("exit_member: (room.member_count, roomid, fd, uid, room.agent)",
			 room.member_count, data.roomid, data.fd, data.id, room.agent)
	-- 判断如果在线玩家为空，则把agent销毁
	if room.member_count == 0 and room.agent then
		--退出还未开局的俱乐部房间 不销毁；如果已开局，最后一个退出可以销毁。
		if data.round == 0 and room.clubid ~= nil and data.needkillroom == nil then
			return
		end
		-- 如果局数为0，且需要房卡，则把房卡还回去
		-- 俱乐部管理员主动要求关闭房间，判断房间成员数即可，不用判断回合数
		if (data.round == 0 or data.managersend == 1) and room.room_card > 0  then
			local card = room.room_card
			
			if room.clubid == nil then
				local content = {
					uid = room.owner,
					money = card,
					task_type = "add_money",
					msg = "收到未开局返回的房卡:【"..card.."】"
				}
				_user.add_task(room.owner, content)
			else
				-- 返回俱乐部基金
				result_fund = clublogic.update_fund(room.clubid, card)
				if user ~= nil then
					-- 发送俱乐部系统消息
					local msg = "【"..user.uid.."】退出【"..room.name.."】未开局返回基金:【"..card.."】"
					clublogic.send_club_msg(0, room.clubid, msg)
				end
			end
		end

		LOG("kill agent", room.agent)
		skynet.kill(room.agent)
		g.run_room[room.roomid] = nil
		-- 俱乐部房间
		if room.clubid ~= nil then
			g.run_club_rooms[room.clubid][room.roomid] = nil
		end
		room.agent = nil
		room.owner = nil
		room.roundid = nil
		room.member_count = 0
		room.clubid = nil
		room.guessing_id = nil
		if room.password then
			g.passwords[room.password] = nil
			room.password = nil
		end
		update_cache_rooms(rooms.all)
	elseif data.managersend == 1 then
		return '该房间还有人在，无法关闭'
	end
	
	return result_fund
end

-- 内部使用 清空玩家房间信息，异常卡在房间里出不来了
function mgr.clear_user_roominfo( uid )
	local user = g.users[uid]
	if user then
		local roomid = user.roomid
		if roomid ~= nil then
			local room = get_room(roomid) or g.passwords[roomid]
			if room ~= nil then
				if room.members[user.uid] ~= nil then
					room.member_count = room.member_count - 1
				end
				room.members[user.uid] = nil
			end
		end
		user.roomid = nil
		user.r_password = nil
		if user.fd then
			g.close_conn(user.fd)
			user.fd = nil
		end
		LOG("clear_user_roominfo uid,user.roomid,user.r_password:",uid, user.roomid, user.r_password)
		return true
	else
		return false, '找不到用户'
	end
end

-- 内部使用 强制销毁房间，清空房间人员
function mgr.force_quit_room(roomid, room_agent)
	local room = get_room(roomid) or g.passwords[roomid]
	if room == nil then
		return false, '找不到房间'
	end
	for k,v in pairs(room.members) do
		local user = g.users[k]
		if user then
			user.r_password = nil
			user.roomid = nil
		
			if user.fd then
				g.close_conn(user.fd)
				user.fd = nil
			end
		end
	end

	if room.agent then
		skynet.kill(room.agent)
	elseif room_agent then
		skynet.kill(room_agent)
	end
	-- 清空当前房间列表数据
	g.run_room[room.roomid] = nil
	-- 俱乐部房间
	if room.clubid ~= nil then
		g.run_club_rooms[room.clubid][room.roomid] = nil
	end
	room.members = {}
	room.agent = nil
	room.owner = nil
	room.roundid = nil
	room.clubid = nil
	room.member_count = 0
	if room.password then
		g.passwords[room.password] = nil
		room.password = nil
	end
	update_cache_rooms(rooms.all)
	return true
end



---------------------------------------------------------------------------------------------------
-- 晁图部分
-- 登录
function mgr.login( fd, data )	
	if data.token == nil or data.token == "" then
		send_error(fd, -1, "参数token不能为空")
		return
	end

	if data.custNo == nil or data.custNo == "" then
		send_error(fd, -1, "参数custNo不能为空")
		return
	end

	local msg, err, userinfo = _ctuser.get_user_info(data.custNo, data.token)
	if msg ~= "ok" then
		return send_error(fd, Config.error_code_re_login, err, "login_fail")
	end

	local uid = data.custNo
	local user = g.users[uid]
	if user == nil then
		user = userinfo
		user.fd = fd
		user.uid = userinfo.custNo
		user.custNo = userinfo.custNo
	else
		-- 挤下线
		local old_fd = user.fd
		if old_fd == fd then
			return send_error(fd, Config.error_code_re_login, "不能重复登录", "login_fail")
		end
		-- 刷最新用户登录缓存
		user = userinfo
		user.fd = fd
		user.uid = userinfo.custNo
		user.custNo = userinfo.custNo
		send_error(old_fd, Config.error_code_re_login, "小子，你被T下线", "login_fail")
		g.close_conn(old_fd)
	end
	g.users[uid] = user
	--print("g.conns", g.conns, fd)
	g.conns[fd].user = user
	user.ip = g.conns[fd].ip
	--print("g.conns", g.conns, fd)
	--print("login_success", uid, user.custName)
	
	--登录时记录玩家信息到本地  t_ct_user
	_ctuser.update_login_user(userinfo.custNo, "0", userinfo.name, "0", user.user_avatar)
	--登录时更新玩家头像  t_friend_relation
	local friend_info = {
		friend_uid = user.uid,
		friend_avatar = user.user_avatar
	}
	skynet.call("friend_center", "lua", "data", "update_friend_avatar", user, friend_info)

	update_cache_conns(g.conns)

	send_msg(fd, {msg_id="login_success", uid = uid, name = user.custName})
end


-- 进入房间 子方法
local function _enter_room( user, room, user_info, roominfo, gameGroupId, friend_user_info)
	assert(room~=nil)
	-- 通知agent加入房间
	if room.agent == nil then
		local ok, rec = pcall(skynet.newservice, "agent")
		if ok then
			room.agent = rec
		elseif user then
			send_error(user.fd, -3, "服务出错，进入房间失败", "enter_room")
			g.close_conn(user.fd)
		else
			return "error"
		end
	end
	-- 刷新房间
	update_cache_rooms(rooms.all)
	-- 发送消息加入房间成功
	if user then
		--room.game_type = "hongbao"
		send_msg(user.fd, {
			msg_id 		= "enter_room_success",
			roomid		=room.roomid,
			game_type   = room.game_type,
			gameGroupId = gameGroupId,
			roomStatue  = roominfo,
			friend_info = friend_user_info
		})
		room.members[user.uid] = user_info.user_name
		
		if user.roomid and user.roomid ~= room.roomid then
			LOG_ERROR("user.roomid ~= room.roomid", tostring(user), tostring(room))
		end
		if not user.roomid or user.roomid ~= room.roomid then
			-- 加入房间
			room.member_count = room.member_count + 1
			user.roomid = room.roomid
			user.r_password = room.password
		end
		print("room.member_count==>", room.member_count)
	end
	local room_type = room.room_type
	local _rooms = rooms[room_type]
	--local type_rooms
	--if room.private then
	--	type_rooms = _rooms.private
	--else
	--	type_rooms = _rooms.index
	--end
	--table.remove(type_rooms, 1)
	--table.insert(type_rooms, room)
	-- print("room:", room)
	if user then
		skynet.call(room.agent, "lua", "start", 
			room, 
			user.fd, 
			user.uid, 
			skynet.self(), 
			g.gate, 
			g.rebot_num, 
			user.ip,
			user)
	end
end


-- 进入房间 主方法 
function mgr.enter_room(user, data)
	cs(function()
		local gameGroupId = data.gameGroupId

		local gameType = data.gameType or '8'
		local getIntoRoomType = data.getIntoRoomType
		local cust_game_type = data.cust_game_type 

		local gameRoomInfo = {}
		local roominfo = {}
		if cust_game_type then			--1、 自定义游戏(猜拳，大菠萝， 即玩即销毁)
			gameRoomInfo.gameGroupId = gameGroupId
			gameRoomInfo.gameType = gameType
		else							--2、 红包赛马(后台固定房间，一直存在)
			if not gameGroupId then
				return send_error(user.fd, -2, "gameGroupId不能为空 ", "enter_room_fail")
			end
		
			local code, dec
			code, dec, gameRoomInfo = _room.get_game_room_detail(gameGroupId)
			if code ~= "ok" then
				return send_error(user.fd, -2, dec, "enter_room_fail")
			end
		
			-- 未加入房间的自动先加入 
			local inRoom = _room.get_is_in_room(gameGroupId, user.uid)
			if not inRoom then
				local query_result = _room.query_room_info(gameRoomInfo.gameGroupId)
				if tonumber(query_result.is_apply) == 1 then
					return send_error(user.fd, -2, "未申请加入该房间", "enter_room_fail")
				else
					local code, dec, result = _room.get_into_game_room(1, user.custNo, user.token, gameRoomInfo.gameGroupId, gameRoomInfo.gameOwner, user.custNo)
					if code ~= "ok" then
						return send_error(user.fd, -2, dec or "进入房间失败", "enter_room_fail")
					end
				end
			end

			-- 获取房间信息
			local msg, dec, _roominfo = _room.get_game_room_status(user.custNo, user.token, gameGroupId)
			roominfo = _roominfo
			if msg ~= "ok" then
				return send_error(user.fd, -2, dec, "enter_room_fail")
			end
		end
		
		local friend_user_info = {}

		-- 获取房间
		local room = get_room(gameGroupId)
		local game_type = nil
		if gameRoomInfo.gameType == "7" then
			game_type = "pk10"
		elseif gameRoomInfo.gameType == "8" then
			game_type = "hongbao"
		elseif cust_game_type == "104" then
			game_type = "guessing"

			local friendCustNos = data.friendCustNos  -- 参与猜拳的好友ID
			friend_user_info = _ctuser.get_all_ctuser(friendCustNos)
		elseif cust_game_type == "105" then
			game_type = "daboluo"
			mgr.enter_room_daboluo( user, data )
			return
		end
		
		if not game_type then
			return send_error(user.fd, -2, "未知的游戏类型", "enter_room_fail")
		end

		if not room then
			room = {
				gameGroupId = gameGroupId,
				roomid = gameGroupId,
				gameType = gameType,
				member_count = 0,
				max_count = 1000,
				min_count = 60,
				robot_count = 30,
				members = {},
				room_coin = 0,
				room_card =0,
				gameRoomInfo = gameRoomInfo,
				game_type = game_type,
				guessing_id = gameGroupId,
			}
		elseif room and game_type == "guessing" then  -- 猜拳游戏房间已经被解散
			if room.guessing_id == nil then 
				return send_error(user.fd, -2, "房间已经解散", "enter_room_fail")
			end
		end
		rooms.all[gameGroupId] = room

		-- 获取个人信息
		local msg, dec, user_info = _ctuser.get_user_info(user.custNo, user.token)
		if msg ~= "ok" then
			return send_error(user.fd, -2, dec, "enter_room_fail")
		end
		_enter_room(user, room, user_info, roominfo, gameGroupId, friend_user_info)
	end)
end

-- 请求创建房间
function mgr.create_room(user, params)
	if not params.banker_type or not params.beter_type or not params.is_apply then
        send_error(user.fd, -2, "参数错误", "create_room_fail")
	end
	
	if params.beter_type == "" then
        return send_error(user.fd, -2, "下注类型不能为空", "create_room_fail")
    end
	
    local code, dec, gameRoomInfo = _room.create_room(params)
    if code ~= "ok" then
        send_error(user.fd, -2, dec, "create_room_fail") 
    end

    --返回成功
    send_msg(user.fd, {
        msg_id = "create_room_success",
        gameRoomInfo = gameRoomInfo
    })

end

-- 请求房间列表
function mgr.get_game_room_list(user, params)
	if not params.custNo or not params.type or not params.gameType then
        send_error(user.fd, -2, "参数错误", "get_game_room_list_fail")
    end
	
    local code, dec, gameRoomList = _room.get_game_room_list(params)
    if code ~= "ok" then
        send_error(user.fd, -2, dec, "get_game_room_list_fail") 
	end

    --返回成功
    send_msg(user.fd, {
        msg_id = "get_game_room_list_success",
        gameRoomList = gameRoomList
    })

end

-- 申请进入房间
function mgr.apply_enter_room(user, data)
	local code = data.code
	if not code then
		send_error(user.fd, -2, "请输入房间号", "apply_enter_room_fail")
		return
	end
	
	-- 获取房间信息
	local custName = user.custName
	--print(data)
	local code, dec, gameRoomInfo= _room.get_game_room_detail(code)
	if code ~= "ok" then
		send_error(user.fd, -2, dec, "apply_enter_room_fail")
		return
	end

	-- 房间id
	local gameGroupId = gameRoomInfo.gameGroupId
	local gameType = gameRoomInfo.gameType
	local searchCode = gameRoomInfo.searchCode
	
	-- 是否在房间
	local inRoom = _room.get_is_in_room(gameGroupId, user.uid)
	if inRoom then
		send_msg(user.fd, {
			info = "您已经在这个房间了，无需重复加入",
			msg_id = "apply_enter_exist",
			gameGroupId = gameGroupId,
		})
		return
	end
	
	-- 房主
	local masterCustNo = gameRoomInfo.gameOwner

	-- 判断是否已经申请过了
	-- enter_room_apply[masterCustNo] = enter_room_apply[masterCustNo] or {}

	-- local msterData = enter_room_apply[masterCustNo]
	-- for k, v in pairs(msterData) do
	-- 	if v.custNo == user.uid and v.gameGroupId == gameGroupId then
	-- 		send_error(user.fd, -2, "您已经发起申请了,请等待房主审核", "apply_enter_room_repeat")
	-- 		return
	-- 	end
	-- end
	local apply_data = _room.query_apply_list(gameGroupId .. user.uid)
	if next(apply_data) then
		send_error(user.fd, -2, "您已经发起申请了,请等待房主审核", "apply_enter_room_fail")
		return
	end

	-- 保存申请列表
	-- local apply_id = user.custNo .. skynet.time() * 10000
	-- enter_room_apply[masterCustNo][apply_id] = {
	-- 	create_time = skynet.time(),
	-- 	name = user.custName,
	-- 	custNo = user.uid,
	-- 	gameGroupId = gameGroupId,
	-- 	apply_id = apply_id,
	-- 	gameType = gameType,
	-- 	searchCode = searchCode, -- 房间码
	-- }
	local apply_id = gameGroupId .. user.custNo
	local result = _room.save_apply_list(gameGroupId, gameRoomInfo.gameName, searchCode, masterCustNo, user.uid, user.custName, user.user_avatar, data.remark)

	-- 向房主发送通知
	print("masterCustNo", masterCustNo)
	print("g.users", g.users)
    print("g.conns", g.conns)
	local masterUser = g.users[masterCustNo]
	if not masterUser or not masterUser.fd then
		send_error(user.fd, -2, "申请成功，请等待房主审核~", "apply_enter_room_fail")
		return
	end

	-- 发送给房主
	send_msg(masterUser.fd, {
		msg_id = "apply_entry_room",
		name = user.custName,
		custNo = user.custNo,
		gameGroupId = gameGroupId,
		apply_id = apply_id
	})

	-- 发送给申请人
	send_msg(user.fd, {
		msg_id = "apply_enter_room_success",
		apply_id = apply_id,
	})

end

--进入房间 大菠萝
function mgr.enter_room_daboluo( user, data ) --data+:  min_coin(金币下限), room_coin（底注）
	--local room_type = data.getIntoRoomType  --9 大菠萝
	local room_type = 9  --9 大菠萝
	print("room_type====================", room_type)

	--根据段位选择入房保底金币与底注,暂时先写默认2000,20
	local min_coin = data.min_coin or 2000
	local room_coin = data.room_coin or 20

	--获取房间信息
	local _rooms = rooms[room_type]
	local room = nil
	assert(_rooms~=nil)
	--寻找空位
	for k,v in pairs(_rooms.index) do
		--if v.member_count < v.min_count then
		if v.member_count < 1 then   --test 先设定1人房
			room = v
			break
		end
	end
	if room == nil then
		send_error(user.fd, -2, "没有找到空位, 房间类型:大菠萝", "enter_room")
		g.close_conn(user.fd)
		return
	end

	--房间配置
	room.min_coin = min_coin
	room.room_coin = room_coin
	room.game_type = "daboluo"
	--room.private = true --test
	room.roundid = math.floor(skynet.time())  --test

	-- 判断金币是否足够
	local msg, dec, account = _ctuser.get_game_user_account(user.uid)
	if(msg == "ok") then
        user.user_coin = account.balAmt 
    else
        send_error(user.fd, -1, dec)
        return
	end
	
	user.user_coin = 20000--test 默认20000

	if user and (user.user_coin < room.min_coin) then
		send_error(user.fd, -5, "您的金币不足" .. tostring(min_coin) .. "，可前往商城购买", "coin_not_enough")
		g.close_conn(user.fd)
		return
	end

	-- 通知agent加入房间
	if room.agent == nil then
		local ok, rec = pcall(skynet.newservice, "agent")
		if ok then
			room.agent = rec
		elseif user then
			send_error(user.fd, -3, "服务出错，进入房间失败", "enter_room")
			g.close_conn(user.fd)
			return
		else
			return 'error'
		end
	end

	if user then
		send_msg(user.fd, {
			msg_id="enter_room_success", 
			roomid=room.roomid,
			game_type = room.game_type,
			rtype=room.room_type, 
			seat_num = room.max_count,
			min_num = room.min_count or room.max_count,
			time = Config_daboluo.auto_card_time, -- 理牌时间
			password = room.password,
			have_banker = room.have_banker,
			room_card = room.room_card,
			room_coin = room.room_coin,
			card_num = room.card_num,
			round_num = room.round_num,
			owner = room.owner,
			danse = room.danse,
			variety = room.variety,
		})

		room.members[user.uid] = user.name
		if user.roomid and (user.roomid ~= room.roomid) then
			LOG_ERROR("user.roomid ~= room.roomid", tostring(user), tostring(room))
		end
		if not user.roomid or (user.roomid ~= room.roomid) then
			-- 加入房间
			room.member_count = room.member_count + 1
			user.roomid = room.roomid
			--user.r_password = room.password
		end
	end

	if user then
		skynet.call(room.agent, "lua", "start", 
			room, 
			user.fd, user.uid, 
			skynet.self(), 
			g.gate, 
			g.rebot_num, 
			user.ip,
			user)
	end
end


-- 获取申请列表
function mgr.get_apply_list(user, data)
	_room_cmd.get_apply_list(user, data)
end


-- 是否同意进入房间
function mgr.approve_room(user, data)
	_room_cmd.approve_room(user, data)

end

return mgr
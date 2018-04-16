local service_path = "./?.lua;".."../common/?.lua;" .. "../server/logic/?.lua" 
package.path = "../skynet/lualib/?.lua;../skynet/service/?.lua;" .. service_path
package.cpath = "./?.dll;skynet/luaclib/?.dll;luaclib/?.dll"

require "wx"
require "base"
socket = require "clientsocket"
ui = require "ui"
require "json"

-- Json.Encode(test)
-- Json.Decode(test_en)

local LOGIN_HOST = "120.77.147.73"
local LOGIN_PORT = 9017

choices = {
	{"心跳", "ping", '{"msg_id":"ping"}'},
	{"登录", "login", '{"msg_id":"login", "deviceid":"test", "uid":100000}'},
	{"进入房间(随机)", "enter_room", '{"msg_id":"enter_room", "type":1}'},
	{"进入房间(房间号)", "enter_room", '{"msg_id":"enter_room", "password":100001}'},
	{"创建房间", "enter_room", '{"msg_id":"enter_room", "type":1, "model":"create_private"}'},
	{"创建房间_麻将", "enter_room", '{"msg_id":"enter_room", "type":3, "model":"create_private", "seat_num":4}'},
	{"准备", "ready", '{"msg_id":"ready"}'},
	{"出牌", "out_card", '{"msg_id":"out_card","card":39}'},
	{"胡牌", "hu_card", '{"msg_id":"hu_card"}'},
	{"设置测试以否", "set_mj_test", '{"msg_id":"set_mj_test","istest":1,"type":3,"testrobot":1,"testrobot_can_cpg":1,"testneed_lave_card_num":20}'},
	{"清空等待时间", "clear_game_time", '{"msg_id":"clear_game_time"}'},
	{"过", "guo", '{"msg_id":"guo"}'},
	{"吃", "chi_card", '{"msg_id":"chi_card","card_list":"19,20"}'},
	{"提交牌型", "choice_poker_type", 
		'{"msg_id":"choice_poker_type", "ctype":[1,2,3], "arr":[18,66,26,58,74,21,54,71,56,25,19,27,75]}'},
	{"退出房间", "quit_room", '{"msg_id":"quit_room"}'},
	{"同意退出", "agree_quit", '{"msg_id":"agree_quit", "status": true}'}
}


local argu = ...

local CMD = {}

local function conn_callback( host, port, uid )
	if fd ~= nil then
		ui.msg("已经连接")
		return
	end
	ui.clear()
	ui.msg(string.format("conn: %s %d %s", host, port, uid))
	LOGIN_HOST = host
	LOGIN_PORT = port
	fd = socket.connect(LOGIN_HOST, LOGIN_PORT)

	if fd then
		ui.status("连接成功:"..fd)
		ui.start_timer()
	end
end
local session = 0
local function cmd_callbakc( param, data )
	if fd == nil then
		ui.msg("先确认连接")
		return
	end
	session = session + 1
	send_request(data)
end

local function timer_callback()
	if fd~=nil then
		local result = read_package_asny()
		if result == true or #result == 0 then
			return
		end
		print("recv:", #result, result)
		-- local msg_id, msg = recv_response(result)
		-- ui.msg('接收到消息:'..msg_id..'\n')
		ui.msg(result)
	end
end

ui.init(timer_callback)

ui.create_ui(LOGIN_HOST, LOGIN_PORT, conn_callback, disconn_callback, cmd_callbakc)
ui.msg("start loop")
wx.wxGetApp():MainLoop()


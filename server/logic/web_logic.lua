-- Web逻辑
local skynet = require("skynet")
local snax = require("skynet.snax")
local json = require("cjson")
json.encode_sparse_array(true,1)
local crypt = require "skynet.crypt"
local _user = require("user.ctcore")
local _room = require("room.core")
local _hongbao = require("hongbao.core")
local room_config = require("room.room_config")
local clublogic = require("club.logic")
local db_mgr = require("db_mgr")
local md5 =	require	"md5"
require("config")
local cmd = {}

local watchdog = nil
local error_arguments = '{"code":-1,"error":"参数错误"}'
local error_server = '{"code":-1,"error":"服务器出错"}'
local error_sendself = '{"code":-1,"error":"error send to self"}'
local no_error = '{"code":0}'

local function send_error( msg )
	if msg == nil then
		msg = "参数错误"
	end
	local res = {
		code = -1,
		error = msg
	}
	return json.encode(res)
end

local function sha1(text)
	local c = crypt.sha1(text)
	return crypt.hexencode(c)
end

local function get_watchdog()
	if watchdog == nil then
		watchdog = skynet.uniqueservice("watchdog")
	end
	return watchdog
end

function cmd.init()
	-- print("init")
	-- 初始化
	Config_init()
end

function cmd.dot(data)
	return no_error
end

-- 检查deviceid是否有效
function cmd.check_deviceid(data)
	local res = {
		code = 0,
		data = {
			deviceid = data.deviceid
		}
	}
	return json.encode(res)
end

local function query_user_room(uid)
	local roomid, password = skynet.call(get_watchdog(), "lua", "query_user_room", uid)
	return roomid, password
end

-- 获取在线人数
function cmd.getonlinenum(data)
    local res = {
        time = skynet.time(),
        code = 0,
        data = skynet.call(get_watchdog(), "lua", "query_online_num")
    }
    return json.encode(res)
end

-- 计算特殊点数集齐奖 下注平均值
local function tidy_together_average(uid, room_id, round_ids)
	if round_ids == nil or round_ids == "" then
		return 0
	end

	local res = _room.get_result_list(uid, room_id, round_ids)
	if table.empty(res) then
		return 0
	end
	local total = {S1={ju=0}, S2={ju=0}}    -- S1牛牛  S2大小单双 梭哈   

	for index, data in pairs(res) do
		if data.bet_type == 1 then
			total.S1.ju = (total.S1.ju or 0) + 1
			total.S1.bet_type = data.bet_type
			total.S1.bet_value = (total.S1.bet_value or 0) + data.total_bet_value
		else
			total.S2.ju = (total.S2.ju or 0) + 1
			total.S2.bet_type = data.bet_type
			total.S2.bet_value = (total.S1.bet_value or 0) + data.total_bet_value
		end                
	end

	local M1 = total.S1.bet_value or 0
	local M2 = total.S2.bet_value or 0
	local sum = total.S1.ju + total.S2.ju

	local average = math.floor((M1 + M2/10)/sum)
	return average
end

-- 计算特殊点数下注平均值列表
local function special_point_averages(uid, room_id, round_ids)
	if round_ids == nil or round_ids == "" then
		return {}
	end

	local res = _room.get_result_list(uid, room_id, round_ids)
	if table.empty(res) then
		return 0
	end
	 
	local average_list = {}
	for index, data in pairs(res) do
		if data.bet_type == 1 then -- 牛牛
			table.insert(average_list, data.total_bet_value)
		else -- 大小单双 梭哈
			table.insert(average_list, data.total_bet_value/10)
		end                
	end

	return average_list
end

-- 计算特殊点数下注平均值列表
local function winning_steak_averages(uid, room_id, round_ids)
	if round_ids == nil or round_ids == "" then
		return {}
	end

	local res = _room.get_result_list(uid, room_id, round_ids)
	if table.empty(res) then
		return {}
	end
	 
	local average_list = {}

	local total = {S1={ju=0}, S2={ju=0}}    -- S1牛牛  S2大小单双 梭哈  
	for index, data in pairs(res) do
		if data.bet_type == 1 then
			total.S1.ju = (total.S1.ju or 0) + 1
			total.S1.bet_type = data.bet_type
			total.S1.bet_value = (total.S1.bet_value or 0) + data.total_bet_value
		else
			total.S2.ju = (total.S2.ju or 0) + 1
			total.S2.bet_type = data.bet_type
			total.S2.bet_value = (total.S1.bet_value or 0) + data.total_bet_value
		end 
		
		local M1 = total.S1.bet_value or 0
		local M2 = total.S2.bet_value or 0
		local sum = total.S1.ju + total.S2.ju
	
		local average = math.floor((M1 + M2/10)/sum)

		table.insert(average_list, average)

	end

	return average_list
end

-- 获取任务奖励列表
function cmd.get_daily_task_list(data)
	local arrRewardData = {}

	local limit = data.limit or 30
	local room_id = data.room_id
	local user_id = data.uid
	local reward_type = data.reward_type
	if room_id == nil or user_id == nil or reward_type == nil then
		return error_arguments
	end

	if reward_type > 3 or reward_type < 1 then
		return error_arguments
	end

	local reward_list = {}
	reward_list = _room.get_daily_task_list(reward_type, room_id, user_id, limit)

	if reward_type == 1 then
		arrRewardData.winning_count = reward_list.winning_steak_count or 0
		local average_list = winning_steak_averages(reward_list["uid"], reward_list["room_id"], reward_list["winning_steak_round_ids"])
		arrRewardData.average_list = average_list
	elseif reward_type == 2 then
		arrRewardData.special_points = str_split_intarray(reward_list.special_points, ",")
		local average_list = special_point_averages(reward_list["uid"], reward_list["room_id"], reward_list["special_point_round_ids"])
		arrRewardData.average_list = average_list
	elseif reward_type == 3 then
		local data = {}
		for i=11, 16 do
			if reward_list["points_" .. i] ~= "" then
				data = {}
				local arrPoint = str_split_intarray(reward_list["points_" .. i], ",")
				data["collect_type"] = i
				data["collect_type_name"] = Config.hb_point_collect_type[i] or ""
				data["points"] = arrPoint
				data["points_num"] = #arrPoint
				data["average"] = tidy_together_average(reward_list["uid"], reward_list["room_id"], reward_list["round_ids_" .. i])
				-- data["round_ids"] = reward_list["round_ids_" .. i]

				table.insert(arrRewardData, data)
			end
		end
	end

	local res = {
		code = 0,
		data = arrRewardData
	}
	return json.encode(res)
end

-- 获取返利列表
function cmd.get_daily_rebate_list(data)
	local limit = data.limit or 30
	local room_id = data.room_id
	local user_id = data.uid
	if room_id == nil or user_id == nil then
		return error_arguments
	end

	local rebate_list = _room.get_daily_rebate_list(room_id, user_id, limit)

	local arrRebateData = {}

	for k, v in pairs(rebate_list) do
		local info = {}
		info.rebate_value = v.rebate_value
		info.total_amount = v.total_amount
		info.rate_value = v.rate_value
		info.time = v.return_time

		table.insert(arrRebateData, info)	
	end

	local res = {
		code = 0,
		data = arrRebateData
	}
	return json.encode(res)
end

-- 获取房间庄家点数列表
function cmd.get_banker_point_list(data)
	local limit = data.limit or 30
	local room_id = data.room_id
	if room_id == nil then
		return error_arguments
	end
	local points =_room.get_banker_point_list(room_id, limit)
	local res = {
		code = 0,
		data = points,
	}
	-- print(res)
	return json.encode(res)
end

-- 获取单局结算
function cmd.get_round_result(data)
	local room_id = data.room_id
	local round_id = data.round_id
	if room_id == nil or round_id == nil then
		return error_arguments
	end
	local result = _room.get_banker_result(room_id, round_id)
	local round_num = 0
	local time = 0
	for k, v in pairs(result) do
		v.log = nil
		v.id  = nil
		round_num = v.round_num
		time = v.time
	end
	
	local data  = {}
	data.result = result
	data.op_time = time_string(time)
	data.round_id  = round_id
	data.round_num = round_num
	local res = {
		code = 0,
		data = data
	}

	--print(res)
	return json.encode(result)
end

-- 获取在线人数
function cmd.get_room_online()
	local onlineNum = _room.query_room_people()
	-- print(onlineNum)
	local cj_data = skynet.call("cachepool", "lua", "get_ssc_kj_data") or {}
	local time = tonumber(cj_data.time or 0)+285 - os.time()
	local res = {
		code = 0,
		data = {
			online_data = onlineNum,
			custom_data = {
				data = str_split_intarray(cj_data.data, ","),
				number = cj_data.number,
				time = time < 0 and 0 or time,
			}
		}
	}
	return json.encode(res)
end

-- 上报充值记录
function cmd.report_charge_info(data)
	if not data.uid or not data.price then		
		return
	end

	_user.add_report_charge(data.uid, data.userName or "", data.price)
end

-- 登录记录玩家
function cmd.login(data)
	if not data.open_id or not data.uid then
		return
	end
	_user.update_login_user(data.uid, data.open_id, data.name or "", data.sex or 0, data.remark1 or "")
end

-- 获取邮件
function cmd.get_mails(data)
	local uid = data.uid
	if uid == nil then
		return error_arguments
	end
	local result = _user.get_mails(uid)

	local list = {}
	for k, v in pairs(result) do
		local data  = {}
		data.content = v.content
		data.msg_time = v.msg_time
		data.coin  = v.coin
		data.is_send = v.is_send

		table.insert(list, data)
	end

	local res = {
		code = 0,
		data = list
	}

	--print(res)
	return json.encode(res)
end

-- 返还金币奖励(房主金币不够，补发奖励)
function cmd.request_return_coin(data)
	local result = _user.get_mails()
	if table.empty(result) then
		return
	end	
end

-- 定时器请求（返还每日返利）
function cmd.request_return_daily_rebate(data)
	local rebate_list = _room.request_return_daily_rebate_list()
	if table.empty(rebate_list) then
		return
	end
	local arrRoomInfo = {}
	-- print(rebate_list, "====asd=====")
	for k, v in pairs(rebate_list) do
		local roomInfoTmp = arrRoomInfo[v.room_id]
		if not roomInfoTmp then
			local msg, dec, roominfo = _room.get_game_room_status("admin", "", v.room_id)
			
			if msg == "ok" then
				arrRoomInfo[v.room_id] = roominfo.gameRoomInfo
				roomInfoTmp = roominfo.gameRoomInfo
			end
			
		end

		local userAccts = {}
		if roomInfoTmp then
			local rebate_value = string.format("%0.2f", v.total_amount * v.rate_value)
			-- 房主扣钱
			local userAcct = {}
			userAcct.type = 7
			userAcct.coin = rebate_value
			userAcct.custNo = roomInfoTmp.gameOwner
			userAcct.waterMemo = "玩家每日返利扣除"
			userAcct.waterType = "71"
			userAcct.gameType = "8"
			table.insert(userAccts, userAcct)
		
			-- 玩家返利金币
			local userAcct = {}
			userAcct.type = 6
			userAcct.coin = rebate_value
			userAcct.custNo = v.uid
			userAcct.waterMemo = "每日返利"
			userAcct.waterType = "72"
			userAcct.gameType = "8"
			table.insert(userAccts, userAcct)

			print(userAccts)
			local msg, dec = _user.operatGameResultAcct("admin", "", userAccts)
			print(msg, dec)
			if msg == "ok" then
				_room.update_daily_rebate(v.room_id, v.uid, rebate_value, 1)
			end
		end
	end
	
	-- if roominfo.gameRoomInfo.gameOwner
end

-- 充值接口
function cmd.charge(data)

end

function cmd.update_version(data)
	local version = data.version
	if version == nil then
		return '{"code":-1, "data":"version nil"}'
	end
	local sql = string.format("UPDATE d_version SET version='%d'", version);
	local res = db_mgr.execute(sql)

	return string.format('%s', json.encode(res))
end


------------------------------------------对内------------------------------------------------

function cmd.get_run_roominfo( data )
	local result = skynet.call(get_watchdog(), "lua", "get_run_roominfo")
	local rec = string.format('{"code":0, "data":%s}', result)
	return rec
end

function cmd.set_cheat_event(data)
	print("weblogic set_cheat_uid")
	local roomid = data.room_id
	local banker = data.banker
	local user   = data.user
	if roomid == nil or (banker == nil and user == nil) then
		return error_arguments
	end
	roomid = tostring(roomid)
	local sql = string.format("SELECT * FROM t_ct_hb_room WHERE room_id = '%s' limit 1", roomid)
	local res = db_mgr.execute(sql)
	local code = 0
    if table.size(res) == 0 then
        local sqlData = {}
        sqlData.room_id = roomid
		sqlData.time = os.time()
		sqlData.banker_ct = banker or 0
		sqlData.user_ct = user or 0
		local status, rs = pcall(db_mgr.add, "t_ct_hb_room", sqlData)
		print("set_cheat_event-c = res", status)
		if status == false then
			code = -1
		end
	else
		print("banker:", banker, user)
		if banker ~= nil and user ~= nil then
			local sql = string.format("UPDATE t_ct_hb_room SET banker_ct='%d',user_ct='%d',time='%d' WHERE room_id=%s", banker, user, os.time(), roomid);
			local res = db_mgr.execute(sql)
			code = (res==nil and -1 or 0)
		elseif banker ~= nil then
			local sql = string.format("UPDATE t_ct_hb_room SET banker_ct='%d',time='%d' WHERE room_id=%s", banker, os.time(), roomid);
			local res = db_mgr.execute(sql)
			code = (res==nil and -1 or 0)
			print("code", code, res)
		elseif user ~= nil then
			local sql = string.format("UPDATE t_ct_hb_room SET user_ct='%d',time='%d' WHERE room_id=%s", user, os.time(), roomid);
			local res = db_mgr.execute(sql)
			code = (res==nil and -1 or 0)
		end
    end

	print("code", code)
	local res = {
		code = code
	}
	return json.encode(res)
end

function cmd.get_cheat(data)
	local roomid = data.room_id
	if roomid == nil then
		return error_arguments
	end

	--local sql = string.format("SELECT * FROM t_ct_hb_room WHERE room_id = '%s' limit 1",roomid)
	local sql = string.format("SELECT banker_ct,user_ct,room_id FROM t_ct_hb_room WHERE room_id IN(%s)", roomid)
	local res = db_mgr.execute(sql)
	--print("res", res)
	-- local call = {}
	-- if table.size(res) > 0 then
	-- 	local room = res[1]
	-- 	call.banker = room.banker_ct
	-- 	call.user = room.user_ct
	-- end

	local res = {
		code = 0,
		data = res
	}
	return json.encode(res)
end

-- 获取签到信息
function cmd.get_sign_in_data(data)
	local uid = data.uid
	if uid == nil then
		return error_arguments
	end
	local result = _user.get_user_qiandao(uid)
	
	local res = {
		code = 0,
		data = {
			is_sign_in = result.is_sign_in,
			day = result.qiandao_num,
		}
	}
	return json.encode(res)
end

-- 签到
function cmd.set_user_sign_in(data)
	local uid = data.uid
	if uid == nil then
		return error_arguments
	end
	local get_data = _user.get_user_qiandao(uid)
	if get_data == nil then
		return error_server
	end
	if get_data.is_sign_in == 1 then
		return '{"code":-1,"error":"已签到过了"}'
	end

	-- 更新数据
	local result = _user.set_user_qiandao(uid, data.name or "")
	if not result or result ~= 1 then
		return '{"code":-1,"error":"签到失败，稍后重试！"}'
	end

	local bouns_type = nil
	local qiandao_num = get_data.qiandao_num + 1
	if qiandao_num == 7 then
		bouns_type = math.random(1, 7)
	end

	-- 玩家返利金币
	local userAccts = {}
	local userAcct = {}
	userAcct.type = 6
	userAcct.coin = 6
	userAcct.custNo = uid
	userAcct.waterMemo = "每日签到奖励"
	userAcct.waterType = "79"
	userAcct.gameType = "8"
	table.insert(userAccts, userAcct)

	if bouns_type then
		local userAcct = {}
		userAcct.type = 6
		userAcct.coin = Config.sign_in_config[bouns_type] or 0
		userAcct.custNo = uid
		userAcct.waterMemo = "第七日签到额外奖励"
		userAcct.waterType = "79"
		userAcct.gameType = "8"
		table.insert(userAccts, userAcct)
	end

	local msg, dec = _user.operatGameResultAcct("admin", "", userAccts)
	print(msg, dec)
	if msg ~= "ok" then
		
	end
	
	local res = {
		code = 0,
		data = {
			is_sign_in = 1,
			coin = 6,
			day = qiandao_num <= 7 and qiandao_num or 1,
			bouns_type = bouns_type,
		}
	}
	return json.encode(res)
end

function cmd.ping( data )
	local uid = data.uid
	if uid == nil then
		return error_arguments
	end
	local res = {
		code = 0,
	}
	return json.encode(res)
end

-- 开奖
function cmd.ssc_kj(data)
	if data.time == nil or data.number == nil or data.data == nil then
		return error_arguments
	end
	local res = {
		code = 0,
	}

	-- 缓存开奖数据
	skynet.call("cachepool", "lua", "set_ssc_kj_data", data)

	return json.encode(res)
end

-- 获取开奖历史记录
function cmd.get_kj_history(data)

    local limit     = data.limit or 20 -- 获取历史数据数量

	local cj_history_list = skynet.call("cachepool", "lua", "get_ssc_kj_data_list", {limit=limit})
	for k,v in pairs(cj_history_list) do
		if type(v.data) == "string" then
			v.data = str_split_intarray(v.data, ",")
		end
	end

    local res = {
		code = 0,
		data = cj_history_list
	}
	
	return json.encode(res)
end

-- 获取ssc单局结算记录
function cmd.get_ssc_result(data)
	local room_id = data.room_id
	local number = data.number
	if room_id == nil or number == nil then
		return error_arguments
	end
	local result = _room.get_ssc_result(room_id, number)
	local round_num = 0
	local result_time = 0
	local users = {}
	local result_details = {}
	local banker_id = nil
	local banker_seat = nil
	local banker_name = nil
	local banker_coin = nil
	for k, v in pairs(result) do
		result_time = v.time

		local user_info = {
			uid = v.uid,
			coin_change = v.coin_change,
			name = v.name,
			avatar = v.avatar,
			-- is_banker = v.is_banker == 1 and true or false
		}
		if v.is_banker == 1 then
			banker_id = v.ranker_id
			banker_seat = v.banker_seat
			banker_name = v.banker_name
			banker_coin = v.banker_game_coin
		end
		users[v.uid] = user_info

		result_details[v.uid] = {
			total_bet = v.total_bet,
			coin_change = v.coin_change,
			is_banker = v.is_banker == 1 and true or false,
			user_info = user_info,
			door = json.decode(v.door_result)
		}
	end	
	
	local res = {
		code = 0,
		data = {
			users = users,
			details = result_details,
			time = result_time,
			banker = banker_id,
			banker_name = banker_name,
			banker_seat = banker_seat,
			bankerCoin = banker_coin,
		}
	}

	--print(res)
	return json.encode(res)

end

-- 设置群机器人数量
function cmd.set_group_robot_count(data)
	if data.count == nil or data.room_id == nil then
		return error_arguments
	end
	local success, msg = skynet.call(get_watchdog(), "lua", "set_room_robot_count", data.room_id, data.count)
	local res = {
		code = success == true and 0 or -1,
		msg  = msg
	}
	
	return json.encode(res)
end

-- 刷新机器人缓存
function cmd.update_local_cache(data)
	local success, msg = skynet.call("cachepool", "lua", "update_local_cache")
	local res = {
		code = success == true and 0 or -1,
		msg  = msg
	}
	
	return json.encode(res)
end

-- 上报每分钟实时在线人数
function cmd.report_online_people()

	local success, msg, tableData = _room.report_online_people()

	print(success, msg, tableData)
	
end

return cmd
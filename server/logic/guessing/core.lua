
local _user = require "user.ctcore"
local db_mgr = require("db_mgr")
local json = require "cjson"
local cthttp = require "cthttp"

local cmd = {}

--[[ 
	多用户操作游戏结算
   	userAccts[1].type: 
   		0 增加 
		1 返还 
		2 赢 
		3 输 
		4 房间扣钱  
		5 房间返还
--]]
function cmd.operatGameResultAcct(custNo, token, userAccts)
    return _user.operatGameResultAcct(custNo, token, userAccts)
end

-- 存储登陆玩家的信息
function cmd.handleRoomUser(user)
 	local room_id = g.room_info.gameRoomInfo.gameGroupId
    local id = room_id.."_"..user.uid
    local sql = [[REPLACE INTO t_guessing_room_user (c_id, c_room_id, c_uid, c_name, c_avatar, c_time, c_time_string) VALUES ('%s', '%s', '%s', '%s', '%s', '%s', '%s');]]
    sql = string.format(sql, 
				    	id, 
				    	room_id, 
				    	user.uid, 
				    	user.name or "", 
				    	user.avatar or "", 
				    	os.time(), 
				    	time_string(os.time()))
    db_mgr.execute(sql)
end

-- 存储游戏操作
function cmd.addStepData(params)
	local step = params.step
	if not step then return end

	local room_id = g.room_info.gameRoomInfo.gameGroupId

    -- 刷新房间信息
    local update_field = {}
    update_field["c_time"] = os.time()
    update_field["c_step"] = step
    local update_where = {}
    update_where["c_room_id"] = room_id
    db_mgr.update("t_guessing_room", update_field, update_where)

    -- 添加游戏操作记录
    local data = {}
    data["c_room_id"] = room_id
    data["c_time"] = os.time()
    data["c_uid"] = params.user.id or 0
    data["c_name"] = params.user.name or ""
    data["c_avatar"] = params.user.avatar or ""
    data["c_step_info"] = params.step_info or ""
    data["c_step"] = step
    -- 下注阶段
    if step == Config.step_guess_bet_start then 
    	data["c_bet_type"] = params.bet_type
    	data["c_bet_value"] = params.bet_value
    -- 出拳阶段
    elseif step == Config.step_guess_guessing_start
        or step == Config.step_guess_guessing_end then
    	data["c_fist"] = params.fist
    end
    db_mgr.add("t_guessing_action", data)
end

return cmd
local skynet = require("skynet")
local db_mgr = require("db_mgr")
local json = require "cjson"
local cthttp = require "cthttp"
local notice = require("notice_utils")
local cmd = {}

-- 获取房间明细
function cmd.get_game_room_detail(queryGameGroupId)
    local status, body = cthttp.post("hgame-api/api2.0/games/getGameRoomDetail", {
		custNo = 1,
        queryGameGroupId = queryGameGroupId,
    })
    
    local ret, dataTable = pcall(json.decode, body)

    if status ~= 200 or not ret then
        return "error", "请求房间信息出错".. dataTable.respCode, {}
    end

    if dataTable.respCode ~= "00" then
        return "error", "获取房间信息失败" .. dataTable.respCode, {}
    end

    local respData = dataTable.respData or {}
    local gameRoomInfo = respData.gameRoomInfo
    if not gameRoomInfo then
        return "error", "房间码错误"
    end

    -- 增加房间设置信息
    local query_result = cmd.query_room_info(gameRoomInfo.gameGroupId)
    gameRoomInfo.bankerType = tonumber(query_result.banker_type)
    gameRoomInfo.beterType = query_result.beter_type
    gameRoomInfo.isApply = tonumber(query_result.is_apply)

    return "ok", "获取房间信息成功", gameRoomInfo
end

-- 创建房间
function cmd.create_room(params)
    local status, body = cthttp.post("hgame-api/api2.0/games/createGame", {
        custNo = params.custNo,
        token = params.token,
        gameType = params.gameType,
        gameGradeType = params.gameGradeType,
        gameName = params.gameName,
        isAuth = tostring(params.isAuth),
        calculatedBits = params.calculatedBits,
        custRoomKey = params.custRoomKey or "170105",
    })
    
    local ret, dataTable = pcall(json.decode, body)

    if status ~= 200 or not ret then
        return "error", "创建房间出错".. dataTable.respCode, {}
    end

    if dataTable.respCode ~= "00" then
        return "error", "创建房间失败" .. dataTable.respCode, {}
    end

    local respData = dataTable.respData or {}
    local gameRoomInfo = respData.gameRoomInfo
    if not gameRoomInfo then
        return "error", "房间码错误"
    end

    -- 保存房间信息
    local sqlData = {}
    sqlData.room_id = gameRoomInfo.gameGroupId
    sqlData.round_id = gameRoomInfo.gameRounds
    sqlData.round_num = 1
    sqlData.time = os.time()

    if params.banker_type then
        sqlData.banker_type = tonumber(params.banker_type)
        gameRoomInfo.bankerType = tonumber(params.banker_type)
    end
    if params.beter_type then
        sqlData.beter_type = tostring(params.beter_type)
        gameRoomInfo.beterType = tostring(params.beter_type)
    end
    if params.is_apply then
        sqlData.is_apply = tonumber(params.is_apply)
        gameRoomInfo.isApply = tonumber(params.is_apply)
    end
    -- 插入数据库
    db_mgr.add("t_ct_hb_room", sqlData)

    return "ok", "创建房间成功", gameRoomInfo
end

-- 获取房间列表
function cmd.get_game_room_list(params)
    local rownum = nil
    if tostring(params.type) == "null" then
        rownum = "10"
    end
    if params.limit then
        rownum = tostring(params.limit)
    end
    local status, body = cthttp.post("hgame-api/api2.0/games/getGameRoomList", {
        custNo = params.custNo,
        token = params.token,
        type = tostring(params.type),
        gameType = tostring(params.gameType),
        rownum = rownum,
    })

    local ret, dataTable = pcall(json.decode, body)
    if status ~= 200 or not ret then
        return "error", "获取房间列表失败".. code, {}
    end

    if dataTable.respCode ~= "00" then
        return "error", "获取房间列表失败" .. dataTable.respCode, {}
    end

    local room_list = dataTable.respData or {}

    for k, room_info in pairs(room_list) do
        if room_info.isJoinRoom and room_info.isJoinRoom == '1' then
            room_info.myState = 1
        else
            room_info.myState = 0
            local apply_data = cmd.query_apply_list(room_info.gameGroupId .. params.custNo)
            if next(apply_data) then
                room_info.myState = 2
            end
        end
        -- 增加房间设置信息
        local query_result = cmd.query_room_info(room_info.gameGroupId)
        room_info.bankerType = tonumber(query_result.banker_type)
        room_info.beterType = tostring(query_result.beter_type)
        room_info.isApply = tonumber(query_result.is_apply)
    end

    return "ok", "获取房间列表成功", room_list
end

-- 房间设置
function cmd.game_room_info_modify(params)
    local status, body = cthttp.post("hgame-api/api2.0/games/gameRoomInfoModify", {
        custNo = params.custNo,
        token = params.token,
        gameGroupId = params.gameGroupId,
        gameGradeType = params.gameGradeType,
        gameName = params.gameName,
        calculatedBits = params.calculatedBits,
        custRoomKey = params.custRoomKey,
    })
    
    local ret, dataTable = pcall(json.decode, body)

    if status ~= 200 or not ret then
        return "error", "房间设置出错".. dataTable.respCode, {}
    end

    if dataTable.respCode ~= "00" then
        return "error", dataTable.respMsg or "房间设置失败", {}
    end

    -- 更新数据库
    local sql = string.format("UPDATE t_ct_hb_room SET banker_type='%d', beter_type='%s', is_apply='%d' WHERE room_id='%s'", params.banker_type, params.beter_type, params.is_apply, params.gameGroupId);
    db_mgr.execute(sql)
    

    return "ok", "房间设置成功", dataTable
end

-- 获取申请人是否在房间
function cmd.get_is_in_room(gameGroupId, queryCustNo)
    local status, body = cthttp.post("hgame-api/api2.0/games/checkGroupMember", {
        custNo = 1,
        token = "",
        gameGroupId = gameGroupId,
        queryCustNo = queryCustNo
    })

    local ret, dataTable = pcall(json.decode, body)
    --print(dataTable, ret)
    if status ~= 200 or not ret then
        return  false
    end
    if dataTable.respCode ~= "00" then
        return false
    end
    --print(dataTable.respData)
    local respData = dataTable.respData or {}
    local custInfo = respData.custInfo
    if custInfo then
        return true
    end
    return false
end

-- 获取房间成员
function cmd.get_room_members(custNo, token, gameGroupId)
    local status, body = cthttp.post("hgame-api/api2.0/games/getGroupMember", {
        custNo = custNo,
        token = token,
        gameGroupId = gameGroupId,
    })

    local ret, dataTable = pcall(json.decode, body)
    --print(dataTable, ret)
    if status ~= 200 or not ret then
        return "error", "获取房间成员失败".. dataTable.respCode, {}
    end

    if dataTable.respCode ~= "00" then
        return "error", "获取房间成员失败" .. dataTable.respCode, {}
    end

    local respData = dataTable.respData
    if not respData then
        return "error", "获取房间成员失败"
    end

    return "ok", "获取房间成员成功", respData

end

-- 获取把审核人拉进房间
-- getIntoRoomType 1 房内玩家主动拉好友进入
-- custNo 当前登录用户客户号
-- token 当前登录用户token
-- gameGroupId 游戏房间id
-- inviteCustNo 用户客户号（邀请者）
-- friendCustNos 用户客户号(被拉者)，多用户用竖线分割
function cmd.get_into_game_room(getIntoRoomType, custNo, token, gameGroupId, inviteCustNo, friendCustNos)
    local status, body = cthttp.post("hgame-api/api2.0/games/getIntoGameRoom", {
        getIntoRoomType = getIntoRoomType, 
        custNo = custNo,
        token = token,
        gameGroupId = gameGroupId, 
        inviteCustNo = inviteCustNo, 
        friendCustNos = friendCustNos, 
    })

    local ret, dataTable = pcall(json.decode, body)
    -- print("==================>拉房间", dataTable)
    if status ~= 200 or not ret then
        return "error", "拉进房间失败".. code, {}
    end

    if dataTable.respCode ~= "00" then
        return "error", "拉进房间失败" .. dataTable.respCode, {}
    end

    return "ok"
end

-- 获取房间状态和详情
function cmd.get_game_room_status(custNo, token, gameGroupId)
    local status, body = cthttp.post("hgame-api/api2.0/games/getGameRoomStatus", {
        custNo = custNo,
        token = token,
        gameGroupId = gameGroupId
    })

    local ret, dataTable = pcall(json.decode, body)

    if status ~= 200 or not ret then
        return "error", "获取房间详情失败".. code, {}
    end

    if dataTable.respCode ~= "00" then
        return "error", "获取房间详情失败" .. dataTable.respCode, {}
    end

    local respData = dataTable.respData or {}
    if not respData then
        return "error", "获取房间详情失败"
    end

    local room_info = respData.gameRoomInfo
    -- 增加房间设置信息
    local query_result = cmd.query_room_info(room_info.gameGroupId)
    room_info.bankerType = tonumber(query_result.banker_type)
    room_info.beterType = query_result.beter_type
    room_info.isApply = tonumber(query_result.is_apply)
    
    respData.gameRoomInfo = room_info

    return "ok", "获取房间信息成功", respData
end

function cmd.report_online_people()
    local online_num_data = notice.get_online_num_info()
    print(json.encode(online_num_data), "===")
    local status, body = cthttp.post("hgame-api/api2.0/user/saveRealTimeOnline", {
        jsonStr = json.encode(online_num_data)
    })

    local ret, dataTable = pcall(json.decode, body)

    if status ~= 200 or not ret then
        LOG("上报在线人数请求失败")
        return
    end

    return "ok", "上报数据成功", dataTable.respData

end


-- 数据库操作 -------------------------------------------------
-----------------------

-- 存储房间播报信息
function cmd.save_report_info(type, content, uid, name)
    if table.size(g.report_info_list) > Config.hb_report_info_num then
        table.remove(g.report_info_list, 1)
    end

    local msg = {}
    table.insert(g.report_info_list, msg)
    msg.msg_type = type 
    msg.info = content
    msg.uid = uid or ''
    msg.name = name or ''

    local data = {}
    data.room_id = g.room_info.gameRoomInfo.gameGroupId or ''
    data.round_id = tostring(g.roundid or '')
    data.uid = uid or ''
    data.time = tostring(os.time())
    data.info = content
    data.msg_type = type
    data.name = name or ''

    db_mgr.add("t_ct_hb_report_info", data)
end

-- 获取房间消息列表
function cmd.get_report_info_list(room_id, limit)
    if room_id == nil then return end
    local limit = tonumber(limit) or 20

    local sql = [[SELECT info,msg_type,uid,name FROM t_ct_hb_report_info WHERE 1 = 1 and room_id = '%s' ORDER BY time DESC limit %d]]
    sql = string.format(sql, room_id, limit)
    local res = db_mgr.execute(sql)
    return res
end

-- 获取每日返利数据列表
function cmd.get_daily_rebate_list(room_id, user_id, limit)
    local sql =  " SELECT * FROM t_ct_hb_daily_rebate WHERE 1 = 1 "
    if room_id then
        sql = sql .. " and room_id = " .. room_id
    end
    if user_id then
        sql = sql .. " and uid = " .. user_id
    end
    
    -- sql = sql .. " and rebate_value >= 0 "
    sql = sql .. " ORDER BY time DESC limit " .. (limit or 20)

    local res = db_mgr.execute(sql)
    return res
end

-- 获取每日未返利数据列表
function cmd.request_return_daily_rebate_list()
    local tab = os.date("*t", os.time())
    tab.hour = 12
    tab.min = 0
	tab.sec = 0
    local now   = os.time()
    local endTime   = os.time(tab) -- 今天12点
    local startTime = endTime - 86400

    -- 今天12点前的多减一天
    if endTime > now then
        now   = os.time() - 86400
        endTime   = os.time(tab) - 86400
        startTime = endTime - 86400
    end

    
    local sql =  " SELECT * FROM t_ct_hb_daily_rebate WHERE 1 = 1 and is_return = 0 and %d < time and time <= %d ORDER BY time ASC limit 10"
    sql = string.format(sql, startTime, endTime)

    local res = db_mgr.execute(sql)
    return res
end

function cmd.update_daily_rebate(room_id, uid, rebate_value, is_return)
    print(rebate_value, is_return, room_id, uid)
    local sql = string.format("UPDATE t_ct_hb_daily_rebate SET rebate_value='%f', is_return='%d', return_time = '%d' WHERE room_id = %s and uid = %s", rebate_value, is_return, os.time(), room_id, uid)
    db_mgr.execute(sql)

end

-- 读取特殊点表，集齐奖表
local function get_daily_task_info(room_id, uid, tablename)
    local tab = os.date("*t", os.time())
    tab.hour = 12
    tab.min = 0
	tab.sec = 0
	local now   = os.time()
    local endTime   = os.time(tab) -- 今天12点
	local startTime = endTime - 86400
	local weiTime   = endTime + 86400
    
    local sql = ""
    if now <= endTime and now > startTime then 		--昨天12:00 ~ 今天12:00
		sql = string.format("SELECT * FROM %s WHERE %d<time and time<=%d and room_id=%s and uid=%s limit 1", tablename, startTime, endTime, room_id, uid)
	elseif now > endTime and now <= weiTime then	--今天12:00 ~ 明天12：00
		sql = string.format("SELECT * FROM %s WHERE %d<time and time<=%d and room_id=%s and uid=%s limit 1", tablename, endTime, weiTime, room_id, uid)
		
    end

    local res = db_mgr.execute(sql)
    return res[1] or {}
end

-- 读取用户信息
function cmd.get_room_user_info(room_id, user_id)
    local sql = string.format("SELECT * FROM t_ct_hb_room_user WHERE id = '%s' limit 1",room_id .. user_id)
    local result = db_mgr.execute(sql)
    return result[1] or {}
end

-- 获取任务奖励列表 type 1 连胜  2 特殊点  3 集齐奖
function cmd.get_daily_task_list(type, room_id, user_id, limit)
    local sql = ""

    local tab = os.date("*t", os.time())
    tab.hour = 12
    tab.min = 0
    tab.sec = 0
    local now   = os.time()
    local endTime   = os.time(tab) -- 今天12点
    local startTime = endTime - 86400
    local weiTime   = endTime + 86400

    local result = {}
    if type == 1 then
        result = cmd.get_room_user_info(room_id, user_id)
    elseif type == 2 then
        result = get_daily_task_info(room_id, user_id, "t_ct_hb_special_point")
    elseif type == 3 then
        result = get_daily_task_info(room_id, user_id, "t_ct_hb_tidy_together")
    end

    return result
end

-- 庄家点数列表
function cmd.get_banker_point_list(room_id, limit)
    local sql = string.format("SELECT point_type_name,round_id,room_id,round_num FROM t_ct_hb_result WHERE room_id=%s and is_banker=1 ORDER BY time DESC limit %d", room_id, limit)
    --print("sql", sql)
    local res = db_mgr.execute(sql)
    return res
end

-- 获取单局结算
function cmd.get_banker_result(room_id, round_id)
    local sql = string.format("SELECT * FROM t_ct_hb_result WHERE room_id=%s and round_id=%s", room_id, round_id)
    local res = db_mgr.execute(sql)
    return res
end

function cmd.get_result_list(uid, room_id, round_ids)
	local sql = string.format("SELECT * FROM t_ct_hb_result WHERE uid=%s and room_id=%s and round_id IN(%s)", uid, room_id, round_ids)
    local res = db_mgr.execute(sql)
    
    return res
end

-- 获取ssc单局结算
function cmd.get_ssc_result(room_id, number)
    local sql = string.format("SELECT * FROM t_ct_ssc_result WHERE room_id=%s and number=%s", room_id, number)
    local res = db_mgr.execute(sql)
    return res
end

-- 更新房间人数
function cmd.update_room_people(roomid, people)
    if not roomid or not people then
        return
    end
    local res = cmd.query_room_info(roomid)
    if table.size(res) == 0 then
        local sqlData = {}
        sqlData.room_id = roomid
        sqlData.time = os.time()
        sqlData.online_num = people
        db_mgr.add("t_ct_hb_room", sqlData)
    else
        local sql = string.format("UPDATE t_ct_hb_room SET online_num='%d', time='%s' WHERE room_id='%s'", people, os.time(), roomid);
        db_mgr.execute(sql)
    end
end

-- 保存房间申请列表-----------------------
function cmd.save_apply_list(roomid,roomName, roomCode, masterid, uid, name, avatar, remark)
    local time = os.time()
    local sql = string.format("INSERT t_ct_apply_list(apply_id, room_id, room_name, room_code, master_id, uid, name, avatar, remark, apply_time) values('%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', %d)",
        roomid .. uid, roomid, roomName, roomCode, masterid, uid, name, avatar or '', remark or '', time)
    local res = db_mgr.execute(sql)
    return res.affected_rows
end

-- 查询是否已申请过
function cmd.query_apply_list(applyid)
    local sql = string.format("SELECT * FROM t_ct_apply_list where apply_id = '%s'", applyid)
    local res = db_mgr.execute(sql)
    return res[1] or {}
end

-- 获取申请列表
function cmd.get_apply_list(masterId)
    local sql = string.format("SELECT * FROM t_ct_apply_list where master_id = '%s'", masterId)
    local res = db_mgr.execute(sql)
    return res
end

-- 删除审核过的数据
function cmd.delect_apply_list(applyid)
    local sql = string.format("DELETE FROM t_ct_apply_list where apply_id = '%s'", applyid)
    local res = db_mgr.execute(sql)
    return res.affected_rows
end
----------------------------------------------

-- 获取所有房间人数
function cmd.query_room_people()
    local sql = "SELECT room_id,online_num FROM t_ct_hb_room"
    local res = db_mgr.execute(sql)
    return res
end

--获取房间信息
function cmd.query_room_info(gameGroupId)
    local sql = string.format("SELECT * FROM t_ct_hb_room WHERE room_id = '%s'",gameGroupId)
    local res = db_mgr.execute(sql)[1] or {}
    return res
end

-- 更新个人禁言
function cmd.update_user_allow_speak(roomid, uid, allow)
    local sql = string.format("UPDATE t_ct_hb_room_user SET allow_speak='%d' WHERE room_id=%s and uid=%s", allow, roomid, uid);
    local res = db_mgr.execute(sql)
    return res
end

-- 更新群禁言
function cmd.update_group_allow_speak(roomid, allow)
    --更新群禁言
    local sql = string.format("UPDATE t_ct_hb_room SET allow_speak='%d' WHERE room_id='%s'", allow, roomid);
    db_mgr.execute(sql)

    -- 更新个人禁言
    local sql = string.format("UPDATE t_ct_hb_room_user SET allow_speak='%d' WHERE room_id=%s", allow, roomid);
    db_mgr.execute(sql)
end

-- 获取禁言列表
function cmd.get_allow_list(roomid)
    local sql = string.format("SELECT allow_speak FROM t_ct_hb_room WHERE room_id=%s limit 1", roomid)
    local room = db_mgr.execute(sql)
    
    local sql = string.format("SELECT uid,allow_speak FROM t_ct_hb_room_user WHERE room_id=%s limit 30", roomid)
    local user = db_mgr.execute(sql)

    local data = {
        room = room,
        user = user
    }
    return data
end

return cmd
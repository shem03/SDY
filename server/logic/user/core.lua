local skynet = require("skynet")
local db_mgr = require("db_mgr")
local json = require "cjson"
local cmd = {}

function cmd.get_uid(deviceid)
    if deviceid == nil then return end
    local datas = G._uid_deviceid_tab
    if datas == nil then
        datas = {}
        G._uid_deviceid_tab = datas
    end

    local uid = datas[deviceid]
    if uid == nil then
        local res = db_mgr.get_userinfo_device(deviceid)
        if res then
            uid = res.id
            datas[deviceid] = uid
        end
    end
    return uid
end

function cmd.getbguser(id)
    local res = db_mgr.get_bguserinfo(id)
    return res
end

function cmd.get(uid)
    local res = db_mgr.get_userinfo(uid)
    return res
end

function cmd.get_device(deviceid)
    local res = db_mgr.get_userinfo_device(deviceid)
    return res
end

local function random_robot()
    local rebot_num = rebot_num or db_mgr.count("c_robot")
    local id = math.random(rebot_num)
    local rebot = db_mgr.get("c_robot", "id", id)
    return rebot
end

function cmd.register( deviceid, devicename, from_platform, nickname, user_avatar, sex  )
    local cur_time = skynet.time()
    if nickname then
        nickname = string.gsub(nickname, "'", "''")
    end
    if devicename then
        devicename = string.gsub(devicename, "'", "''")
    end
    if user_avatar == nil then -- 从机器库随机一个头像
        user_avatar = random_robot().userAvatar
    end
    local user_id = db_mgr.add("d_user", {deviceid = deviceid,from_platform=from_platform,user_coin=10000,
        user_avatar = user_avatar, user_sex = sex, user_money=300,
    	user_name=nickname or devicename, device_name=devicename,last_logintime=cur_time, register_time=cur_time})

    cmd.add_consume_log(user_id, "coin", 10000, "注册")
    cmd.add_consume_log(user_id, "money", 300, "注册")

    return user_id
end

--更新最后登录时间
function cmd.update_logintime( uid )
    local cur_time = skynet.time()
    local rec = db_mgr.update("d_user", {last_logintime = cur_time}, {id = uid})
    return rec
end

function cmd.ranklist(des_type)
    local sql = string.format("SELECT id,user_name,user_coin,user_avatar,user_sex,user_point FROM d_user where user_status=0 order by user_%s desc limit 50", des_type)
	return db_mgr.execute(sql)
end

-- user = {coin=coin, money=money}  where = {id=uid, __version=__version}
-- 这是一个安全的接口，会重试5次，尽量不要进行竞争
local function _update_safe( data, where )
    assert(where.id~=nil)
    assert(where.__version~=nil)
    local rec = db_mgr.update("d_user", data, where)
    if rec >= 1 then
        return where.__version + 1
    end
    LOG_ERROR("UPDATE d_user fail", where.id, where.__version)
end

function cmd.update( data, where)
    return db_mgr.update("d_user", data, where)
end

function cmd.update_coin( user, coin )
    for i=1,5 do
        local rec = _update_safe( {user_coin=user.user_coin+coin, __version=user.__version+1}, {id=user.id, __version=user.__version} )
        if rec and rec >= 1 then
            user.__version = user.__version + 1
            user.user_coin = user.user_coin+coin
            return true
        else
            local user_info = db_mgr.get_userinfo(user.id)
            user.user_coin = user_info.user_coin
            user.user_money = user_info.user_money
            user.user_point = user_info.user_point
            user.__version = user_info.__version
        end
    end
    return false
end

function cmd.update_money( user, money )
    for i=1,5 do
        local rec = _update_safe( {user_money=user.user_money+money, __version=user.__version+1}, {id=user.id, __version=user.__version} )
        if rec and rec >= 1 then
            user.user_money = user.user_money+money
            user.__version = user.__version + 1
            return true
        else
            local user_info = db_mgr.get_userinfo(user.id)
            user.user_coin = user_info.user_coin
            user.user_money = user_info.user_money
            user.user_point = user_info.user_point
            user.__version = user_info.__version
        end
    end
    return false
end

function cmd.update_point( user, point )
    for i=1,5 do
        local rec = _update_safe( {user_point=user.user_point+point, __version=user.__version+1}, {id=user.id, __version=user.__version} )
        if rec and rec >= 1 then
            user.user_point = user.user_point+point
            user.__version = user.__version + 1
            return true
        else
            local user_info = db_mgr.get_userinfo(user.id)
            user.user_coin = user_info.user_coin
            user.user_money = user_info.user_money
            user.user_point = user_info.user_point
            user.__version = user_info.__version
        end
    end
    return false
end

function cmd.get_feedback( uid )
    local sql = string.format("SELECT * from d_feedback where user_id=%d limit 10", uid)
    return db_mgr.execute(sql)
end

function cmd.add_feedback( uid, content )
    local cur_time = time_string(skynet.time())
    local sql = string.format("INSERT d_feedback(content, user_id, feedback_time) values('%s', %d,'%s')", content, uid, cur_time)
    return db_mgr.execute(sql).affected_rows
end

function cmd.getmsg( uid )
    local sql = string.format("SELECT * from d_msg where uid=%d and msg_status<3 order by msg_time desc limit 10", uid)
    return db_mgr.execute(sql)
end

function cmd.update_msg( ids, status )
    local sql = string.format("UPDATE d_msg SET msg_status=%d WHERE id in(%s)", status, table.concat(ids, ','))
    return db_mgr.execute(sql).affected_rows
end

function cmd.update_all_unread(uid)
    local sql = string.format("UPDATE d_msg SET msg_status=1 WHERE uid=%d", uid)
    return db_mgr.execute(sql).affected_rows
end

-- 0未知1未读2已读3删除
function cmd.add_msg( uid, content, msg_type )
    if content == nil or #content == 0 then return end
    local cur_time = time_string(skynet.time())
    local sql = string.format("INSERT d_msg(content, uid, msg_time, msg_type) values('%s', %d,'%s', %d)",
     content, uid, cur_time, msg_type)
    return db_mgr.execute(sql).affected_rows
end

function cmd.get_unread_count( uid )
    local sql = string.format("SELECT count(id) as count from d_msg where uid=%d and msg_status=0", uid)
    return db_mgr.execute(sql)[1]["count"]
end

function cmd.get_shop( platform )
    local sql = string.format("SELECT * from c_shop limit 50")
    return db_mgr.execute(sql)
end

function cmd.get_menuinfo( channel )
    local sql = string.format("SELECT * from c_game_menu where channel=%d order by parent_id", channel)
    return db_mgr.execute(sql)
end

function cmd.get_shop_id( id )
    local sql = string.format("SELECT * from c_shop where id=%d limit 1", id)
    return db_mgr.execute(sql)[1]
end

function cmd.add_task( uid, content )
    if content == nil then
        content = "{}"
    else
        content = json.encode(content)
    end
    local cur_time = time_string(skynet.time())
    local sql = string.format("INSERT d_task(content, uid, task_time, status) values('%s', %d,'%s', 0)",
     content, uid, cur_time, msg_type)
    return db_mgr.execute(sql).insert_id
end

function cmd.gettask( uid )
    local sql = string.format("SELECT * from d_task where uid=%d and status = 0 limit 10", uid)
    return db_mgr.execute(sql)
end

function cmd.update_task( id )
    local sql = string.format("UPDATE d_task SET status=1 WHERE id=%d", id)
    return db_mgr.execute(sql).affected_rows
end

function cmd.getnotice()
    local cur_time = time_string(skynet.time())
    local sql = string.format("SELECT * from c_notice where status=1 and start_time < '%s' and end_time > '%s' limit 10",
     cur_time, cur_time)
    return db_mgr.execute(sql)
end

function cmd.get_trade()
    local sql = string.format("SELECT * from c_trade limit 50")
    return db_mgr.execute(sql)
end

function cmd.add_trade( uid, trade_id, mobile, address, name )
    local cur_time = time_string(skynet.time())
    local sql = string.format("INSERT d_trade(userid, mobile, address, name,  trade_id, trade_time) values(%d, '%s','%s','%s', %d, '%s')",
     uid, mobile, address, name, trade_id, cur_time)
    return db_mgr.execute(sql).affected_rows
end

function cmd.get_config(key)
    return db_mgr.get_config(key)
end

-- 添加麻将日志
function cmd.add_game_mj_log( data, tbl_info )
    local info = "{}"
    if tbl_info ~= nil then
        info = json.encode(tbl_info)
    end
    local addtime = time_string(skynet.time())
    local sql = string.format("INSERT d_game_mj_log(gameid, round, step, uid, operate, substep, `describe`, info, addtime) values(%d, %d, %d, %d, %d, %d, '%s', '%s', '%s')", data.gameid, data.round, data.step, data.uid, data.operate, data.substep, data.describe, info, addtime)
    -- print("sql:",sql)
    return db_mgr.execute(sql).affected_rows
end

function cmd.add_score_data( userid, roomid, score_data, clubid, roundid )
    if clubid == nil then
        clubid = 0
    end
    local cur_time = time_string(skynet.time())
    local sql = string.format("INSERT d_score(userid, roomid, score_data, room_datetime, clubid, roundid) values(%d, %d,'%s','%s', %d, %d)",
     userid, roomid, score_data, cur_time, clubid, roundid)
    return db_mgr.execute(sql).affected_rows
end

function cmd.update_score_data( userid, roomid, score_data, clubid, roundid)
    if clubid == nil then
        clubid = 0
    end
    local sql = string.format("UPDATE d_score set score_data = '%s' where userid=%d and roomid = %d and clubid = %d and roundid = %d",
     score_data, userid, roomid, clubid, roundid)
    return db_mgr.execute(sql).affected_rows
end

-- 添加房间开始记录
function cmd.add_room_data( roomid, roundid, clubid, roominfo )
    if clubid == nil then
        clubid = 0
    end
    if cmd.update_room_data(roomid,roundid) > 0 then
        return
    end
    local cur_time = time_string(skynet.time())
    local sql = string.format("INSERT d_room(roomid, roundid, clubid, roominfo, starttime) values(%d, %d, %d,'%s','%s')",
     roomid, roundid, clubid, roominfo, cur_time)
    return db_mgr.execute(sql).affected_rows
end

--更新房间结算记录
function cmd.update_room_data( roomid, roundid, scoreinfo)
    local cur_time = time_string(skynet.time())
    local sql = "";
    if scoreinfo == nil then
        sql = string.format("UPDATE d_room set starttime = '%s' where roundid=%d and roomid=%d",
            cur_time, roundid, roomid)
    else
        sql = string.format("UPDATE d_room set scoreinfo = '%s', endtime = '%s' where roundid=%d and roomid=%d",
            scoreinfo, cur_time, roundid, roomid)
    end
    return db_mgr.execute(sql).affected_rows
end

function cmd.add_score_log( uid, score, action, roomid, roundid, round )
    local cur_time = time_string(skynet.time())
    local sql = string.format("INSERT d_score_log(uid, score, update_time, action, roomid, roundid, round) values(%d, %d,'%s','%s', %d, %d, %d)",
     uid, score, cur_time, action, roomid, roundid, round)
    return db_mgr.execute(sql).affected_rows
end

function cmd.get_score_data( uid )
    local sql = string.format("SELECT * from d_score where userid=%d order by id desc limit 10", uid)
    return db_mgr.execute(sql)
end

function cmd.get_one_score( uid, roundid, roomid )
    local sql = string.format("SELECT * from d_score where userid=%d and roundid=%d and roomid=%d limit 1",
     uid, roundid, roomid)
    return db_mgr.execute(sql)
end

-- 消费日志
function cmd.add_consume_log( uid, type, value, action, end_value, start_value, remark)
    if start_value == nil and end_value == nil then
        start_value = 0
        end_value = value
    elseif start_value == nil then
        start_value = end_value - (value)
    elseif end_value == nil then
        end_value = start_value + (value)
    end
    if remark == nil then
        remark = ""
    end
    local cur_time = time_string(skynet.time())
    local sql = string.format("INSERT d_consume_log(uid, type, update_time, value, action, start_value, end_value, remark) values(%d, '%s','%s', %d, '%s', %d, %d, '%s')",
     uid, type, cur_time, value, action, start_value, end_value, remark)
    return db_mgr.execute(sql).affected_rows
end

-- 后台用户名密码获取用户信息
function cmd.get_userinfo_by_bgnamepwd( bg_username,bg_pwd )
    local sql = string.format("select a.id uid,a.user_name,a.user_avatar,a.user_money,b.username bg_username from d_user a join d_bguser b on a.bg_userid=b.id where b.username='%s' and b.pwd='%s' limit 1;",
        bg_username,bg_pwd)
    return db_mgr.execute(sql)[1]
end

-- 外部接口调用时使用，获取真正的钻石数，有可能有任务没执行
function cmd.get_real_user_money( uid, user_money)
    local like_str = '%add_money%'
    local sql = string.format("select * from d_task where uid=%d and STATUS=0 and content like '%s';", uid, like_str)
    local task_list = db_mgr.execute(sql)
    for k,v in pairs(task_list) do
        local content = json.decode(v.content)
        user_money = user_money + (tonumber(content.money))
    end
    return user_money
end

-- 根据订单id获取网页充值记录数
function cmd.get_webordernum(orderid)
    local sql = string.format("SELECT count(*) num from d_web_order where orderid='%s'", orderid)
    return db_mgr.execute(sql)
end

function cmd.add_weborder( uid, orderid, money, taskid, price)
    local cur_time = time_string(skynet.time())
    local sql = string.format("INSERT INTO d_web_order(uid, orderid, money, price, taskid, addtime) values(%d, '%s', %d, %d, %d, '%s')",
     uid, orderid, money, price, taskid, cur_time)
    return db_mgr.execute(sql).affected_rows
end

return cmd


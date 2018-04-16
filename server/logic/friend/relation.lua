local skynet = require("skynet")
local db_mgr = require("db_mgr")

local relation = {}

--获取所有好友
function relation.get_all_friend( data )   --data: uid, friend_uid
    local sql = string.format("SELECT * from t_friend_relation where user_id=%d and relation=1 ", data.uid)
    if(data.friend_uid ~= nil) then
        sql = string.format("%s and friend_id=%d", sql, data.friend_uid)
    end
    sql = string.format("%s order by friend_name desc", sql)

    --print("all_friend=======",sql)
    return db_mgr.execute(sql)
end

--获取好友个数
function relation.get_friend_num( uid )
    local sql = string.format("SELECT count(0) CNT from t_friend_relation where user_id=%d and relation=1 ", uid)
    return db_mgr.execute(sql)[1]["CNT"]
end

--保存好友关系记录   --一对关系保存2条记录
function relation.save_friend_record( uid, friend_id, user_name, friend_name, user_avatar, friend_avatar)
    local sql = string.format("INSERT t_friend_relation(user_id, friend_id, friend_name, friend_avatar, relation, add_time) \
                values(%d, %d, '%s', '%s', %d, now()); \n", uid, friend_id, friend_name, friend_avatar, 1)
    sql = string.format("%s INSERT t_friend_relation(user_id, friend_id, friend_name, friend_avatar, relation, add_time) \
                values(%d, %d, '%s',  '%s', %d, now())", sql, friend_id, uid, user_name, user_avatar, 1)
    return db_mgr.execute(sql).affected_rows
end

--更新好友头像
function relation.update_friend_avatar( friend_id, friend_avatar )
    local sql = string.format("UPDATE  t_friend_relation set friend_avatar='%s'  where  friend_id=%d ", friend_avatar, friend_id)

    return db_mgr.execute(sql).affected_rows
end

--删除好友
function relation.unfriend( uid, friend_id )
    local sql = string.format("delete from  t_friend_relation where user_id=%d and friend_id=%d; \n", uid, friend_id)
	sql = string.format("%s delete from  t_friend_relation where user_id=%d and friend_id=%d ", sql, friend_id, uid)
    return db_mgr.execute(sql).affected_rows
end

--判断是否好友
function relation.is_friend( uid, friend_id )
	local sql = string.format("SELECT count(0) CNT from t_friend_relation where user_id=%d and friend_id=%d and relation=1 ", uid, friend_id)
	local ret = db_mgr.execute(sql)
	if ( ret[1]["CNT"] == 1) then 
	    return true
    else 
	    return  false
	end
end

return relation
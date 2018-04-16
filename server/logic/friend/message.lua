local skynet = require("skynet")
local db_mgr = require("db_mgr")

local message = {}



--保存消息记录
function message.save_message( uid, from_id, from_name, from_avatar, m_type, content )
	local sql = string.format("INSERT t_friend_message(user_id, from_id, from_name, from_avatar, m_type, is_readed, add_time, content) \
				values(%d, %d, '%s', '%s', %d, 0, now(), '%s') ", uid, from_id, from_name, from_avatar, m_type, content)
    return db_mgr.execute(sql).affected_rows
end

--获取消息记录  --m_type : 1好友消息,2001好友申请,不送则搜索全部类型; from_id, is_readed(0未读1已读)
function message.get_all_message( data )
	local sql = string.format("SELECT * from t_friend_message where user_id=%d  ", data.uid)
	if(data.from_id ~= nil) then
		sql = sql .. string.format(" and from_id=%d ", data.from_id)
	end
	if(data.is_readed ~= nil) then
		sql = sql .. string.format(" and is_readed=%d ",  data.is_readed)
	end
	if(data.m_type ~= nil) then
		sql = sql .. string.format(" and m_type=%d ",  data.m_type)
	end
	--sql = sql .. " order by from_name"
	--print("get_all_message..sql=====",sql)
    return db_mgr.execute(sql)
end


--消息已读标记
function message.mark_isreaded_message( m_id , user_id, from_id)
	assert(m_id ~= nil or user_id ~= nil, "消息已读标记失败：参数错误")
	local sql = string.format("UPDATE  t_friend_message set is_readed = 1 where  1=1  " )
	if(m_id ~= nil) then
		sql = sql .. string.format(" and id = %d ", m_id)
	end
	if(user_id ~= nil) then
		sql = sql .. string.format(" and user_id=%d ", user_id)
	end
	if(from_id ~= nil) then
		sql = sql .. string.format(" and from_id=%d ", from_id)
	end
	--print("mark_sql===========",sql)
    return db_mgr.execute(sql).affected_rows
end

--获取好友双方私信记录  --uid, from_id
function message.get_private_records( data )
	local sql = string.format("SELECT * from t_friend_message where (user_id=%d and from_id=%d) \
				or (user_id=%d and from_id=%d) order by add_time  ", data.uid, data.from_id, data.from_id, data.uid)

	--print("get_private_records..sql=============",sql)
    return db_mgr.execute(sql)
end

--删除好友聊天记录
function message.delete_private_records( uid, from_id )
    local sql = string.format("delete from  t_friend_message where user_id=%d and from_id=%d; \n", uid, from_id)
	sql = sql .. string.format(" delete from  t_friend_message where user_id=%d and from_id=%d ", from_id, uid)
    return db_mgr.execute(sql).affected_rows
end




return message
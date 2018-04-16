
local skynet = require "skynet"
local _user = require("user.core")
local db_mgr = require("db_mgr")
local _user = require("user.core")
local json = require "cjson"
local logic = {}

-- 获取当前俱乐部消息ID最大值
function get_maxmsgid( clubid )
	-- 获取俱乐部最后一条消息的前10条，新成员可以看到最后10条消息
	local sql = string.format("select * from d_club_msg where clubid=%d order by id desc limit 10", clubid)
	local res = db_mgr.execute(sql)
	if #res == 10 then
		return res[10]["id"]
	elseif #res == 0 then
		return 0
	else
		return res[#res]["id"]
	end
end

-- 获取成员未读的验证消息条数
function get_unread_apply_num( clubid, uid )
	if not check_authority(uid,clubid,Club_Config.Club_Buttons_Auth.Apply_Msg) then
		return 0
	end
	local sql = string.format("select * from d_club_member where status<>-1 and uid=%d and clubid=%d limit 1", uid,clubid)
	local res = db_mgr.execute(sql)
	if #res > 0 then
		maxapplymsgid = res[1]["maxapplymsgid"]
		local where = string.format("where status=0 and clubid=%d and id>%d", clubid, maxapplymsgid)
		local count = db_mgr.count("d_club_apply", where)
		return count
	end
	return 0
end

-- 检查按钮权限
function check_authority( uid,clubid,btn )
	local sql = string.format("select * from d_club_member where status<>-1 and uid=%d and clubid=%d limit 1", uid,clubid)
	local res = db_mgr.execute(sql)
	if #res > 0 then
		local roletype = tonumber(res[1]["roletype"])
		if roletype == Club_Config.Club_RoleType.Creater then
			return true
		elseif roletype == Club_Config.Club_RoleType.Manager then
			local btns = {Club_Config.Club_Buttons_Auth.Get_Member,Club_Config.Club_Buttons_Auth.Dissolve,Club_Config.Club_Buttons_Auth.Fund_Manager,Club_Config.Club_Buttons_Auth.Setting,Club_Config.Club_Buttons_Auth.Apply_Msg,Club_Config.Club_Buttons_Auth.Modify_Auth}
			if is_in_table(btns, btn) then
				return true
			else
				return false
			end 
		elseif roletype == Club_Config.Club_RoleType.Senior then
			local btns = {Club_Config.Club_Buttons_Auth.Get_Member}
			if is_in_table(btns, btn) then
				return true
			else
				return false
			end 
		elseif roletype == Club_Config.Club_RoleType.Ordinary then
			local btns = {Club_Config.Club_Buttons_Auth.Get_Member}
			if is_in_table(btns, btn) then
				return true
			else
				return false
			end 
		else
			return false
		end
	else
		return false
	end
end

-- data = {fund=fund}  where = {id=clubid, __version=__version}
-- 这是一个安全的接口，会重试5次，尽量不要进行竞争
local function _update_safe( data, where )
    assert(where.id~=nil)
    assert(where.__version~=nil)
    local rec = db_mgr.update("d_club", data, where)
    if rec >= 1 then
        return where.__version + 1
    end
    LOG_ERROR("UPDATE d_club fail", where.id, where.__version)
end

-- 获取俱乐部信息
function logic.get( clubid )
	local sql = string.format("SELECT * FROM d_club WHERE status=0 and id=%d LIMIT 1",clubid)
	local ret = do_mysql_req(sql)
	if ret == nil or #ret == 0 then
		return nil
	end
	return ret[1]
end

-- 获取俱乐部成员信息信息
function logic.getmember( clubid, uid )
	local sql = string.format("SELECT * FROM d_club_member WHERE clubid=%d and uid=%d and status<>-1 LIMIT 1",clubid,uid)
	local ret = do_mysql_req(sql)
	if ret == nil or #ret == 0 then
		return nil
	end
	return ret[1]
end

-- 检测是否可以创建/加入俱乐部房间
function logic.check( clubid, uid, card, roomid )
	local club = logic.get(clubid)
	if club == nil then
		return "俱乐部不存在"
	end
	local club_member = logic.getmember(clubid,uid)
	--print("club_member:",club_member)
	if club_member == nil then
		return "你不是该俱乐部成员"
	elseif tonumber(club_member.status) == Club_Config.Club_MemberStatus.Suspend then
		return "你已被管理员禁赛"
	end
	-- 判断能否创建房间
	if card > 0 then
		if club.fund < card or logic.update_fund(club, -card) == false then
			return "俱乐部基金不足，请补充~"
		end
		if Club_Config.Club_RoleType.Manager > club_member.roletype then
			return "只有创建人或管理员才能创建房间"
		end
	-- 判断能否进入房间
	elseif roomid ~= nil and roomid > 0 then
		if Config.channel == 'xzj' then
			--普通会员 需审核
			if club_member.roletype < Club_Config.Club_RoleType.Senior then
				local status = logic.get_apply_in_club_room_status(uid, roomid)
				--申请状态（0：申请提交，1：申请通过 ，-1：驳回,-2：请求已过期，-10：驳回并不接收申请）
				if status ~= 1 then
					return "暂无权进入房间，需审核"
				end
			end
		elseif Config.channel == 'dyj' or Config.channel == 'dd' or Config.channel == 'zm' then
			
		else
			return "暂无权进入房间，需审核"
		end
	else
		return "未知请求"
	end
	club = logic.get(clubid)
	return nil,club.fund
end

-- 俱乐部更新基金
function logic.update_fund( clubidorclub, fund )
	local club = nil
	if (type(clubidorclub) == "table") then
        club = clubidorclub
    else
    	club = logic.get(clubidorclub)
    end
	if club == nil then
		return false
	end
	for i=1,5 do
        local rec = _update_safe( {fund=club.fund+fund, __version=club.__version+1}, {id=club.id, __version=club.__version} )
        if rec and rec >= 1 then
            club.fund = club.fund+fund
            club.__version = club.__version + 1
            return club.fund
        else
            return false
        end
    end
    return false
end

-- 检查俱乐部ID是否合法
function logic.check_clubid( clubid, uid )
	local clubid = tonumber(clubid)
	if clubid == nil or clubid <= 0 then
		return "俱乐部ID不能为空"
	end

	local where = "where status=0 and id="..clubid
	local count = db_mgr.count("d_club", where)
	if count == 0 then
		return "俱乐部不存在"
	end
	if uid ~= nil then
		local sql = "select * from d_club_member where status<>-1 and clubid="..clubid.." and uid="..uid
		local res = db_mgr.execute(sql)
		if res ~= nil and #res > 0 then
			local roletype = res[1]["roletype"]
			return nil,roletype
		else
			return "亲，你不是该俱乐部成员"
		end
	end
end

-- 检查俱乐部名称合法性
function logic.check_clubname( name, clubid )
	if name == nil or #name == 0 then
		return "名称不能为空"
	end
	name = trim(name)
	local temp_name = "1"..name
	temp_name = tonumber(temp_name)
	if temp_name ~= nil then
		return "名称不能为纯数字"
	end
	local name_len = utfstrlen(name)
	if name_len < 3 or name_len > 16 then
		return "名称需3-16个字符，实际"..name_len
	end
	local res = db_mgr.query("d_club", {name = name, status = 0})
	if res ~= nil and #res > 0 then
		if #res > 1 then
			return "已存在该名称的俱乐部"
		elseif clubid ~= nil and res[1].id ~= clubid then 
			return "已存在该名称的俱乐部"
		end
	end
	return nil,name
end

-- 获取我的俱乐部列表
function logic.get_own_clubs( uid )
	local sql = string.format("select c.id,c.imgid,c.name,c.member_count,c.max_member_count,c.areaid,c.fund,a.province,cm.roletype from d_club c left join c_area a on c.areaid=a.id left join d_club_member cm on cm.clubid=c.id where cm.uid=%d and c.status=0 and cm.status<>-1 order by cm.roletype desc", uid)
	return db_mgr.execute(sql)
end

-- 创建俱乐部
function logic.create_club( uid, name, areaid )
	local where = "where status=0 and creater="..uid
	local count = db_mgr.count("d_club", where)
	where = "where status=0 and name='"..name.."'"
	local count_name = db_mgr.count("d_club", where)
	if count > 0 then
		return 0,"亲，你只能创建一个俱乐部哦"
	elseif count_name > 0 then
		return 0,"亲，该名称已被占用哦"
	else
		where = "where id="..areaid
		count = db_mgr.count("c_area", where)
		if count == 0 then
			return 0,"地区ID不存在"
		end

		local club = {}
		club.creater = uid
		club.name = name
		club.areaid = areaid
		club.member_count = 1
		club.max_member_count = 500
		club.fund = 0
		club.intro = ""
		club.addtime = time_string(skynet.time())
		--俱乐部状态（0：正常，-1：解散）
		club.status = 0
		local clubid = db_mgr.add("d_club", club)

		local club_member = {}
		club_member.clubid = clubid
		club_member.uid = uid
		club_member.maxmsgid = 0
		club_member.roletype = Club_Config.Club_RoleType.Creater
		club_member.addtime = time_string(skynet.time())
		--成员状态（0：正常，-1：开除）
		club_member.status = 0 
		db_mgr.add("d_club_member", club_member)

		return clubid
	end
end

-- 获取所在地配置信息
function logic.get_areas(  )
	local sql = "select id as areaid,province,isspecial from c_area order by sort"
	return db_mgr.execute(sql)
end

-- 申请加入俱乐部
function logic.apply_in_club( uid, clubid, msg )
	local where = "where status<>-1 and clubid="..clubid.." and uid="..uid
	local count = db_mgr.count("d_club_member", where)
	if count > 0 then
		return "亲，你已是该俱乐部成员"
	else
		where = "where status = 0 and clubid="..clubid.." and uid="..uid
		other = "order by id desc limit 1"
		res = db_mgr.query("d_club_apply", where)
		if #res > 0 then
			local status = res[1]["status"]
			if status == Club_Config.Club_Apply_Status.Apply then
				return "已申请，待管理员审核"
			elseif status == Club_Config.Club_Apply_Status.DenyApply then
				return "该俱乐部管理员已屏蔽了您的申请"
			end
		end

		--添加申请记录
		local club_apply = {}
		club_apply.clubid = clubid
		club_apply.uid = uid
		club_apply.msg = msg
		club_apply.status = Club_Config.Club_Apply_Status.Apply
		club_apply.addtime = time_string(skynet.time())
		db_mgr.add("d_club_apply", club_apply)
	end
end

-- 搜索俱乐部信息
function logic.search_club( clubidorname )
	local sql = string.format("select c.id,c.imgid,c.name,c.member_count,c.max_member_count,c.areaid,c.intro,a.province from d_club c left join c_area a on c.areaid=a.id where c.status=0 and (c.id='%s' or c.name='%s') order by c.member_count desc,c.id", clubidorname, clubidorname)
	return db_mgr.execute(sql)
end

--获取俱乐部申请列表
function logic.get_club_applys( uid, clubid, start, limit )
	if not check_authority(uid,clubid,Club_Config.Club_Buttons_Auth.Apply_Msg) then
		return nil,"无权查看验证消息"
	end
	local sql = string.format("select a.id,a.uid,a.clubid,a.msg,a.addtime applytime,u.user_avatar avatar,u.user_name nickname,c.name clubname from d_club_apply a left join d_user u on a.uid=u.id left join d_club c on a.clubid=c.id where a.status=0 and c.status=0 and clubid=%d and clubid in (select clubid from d_club_member where uid=%d and roletype>=%d and status<>-1) order by applytime desc limit %d,%d"
		, clubid, uid, Club_Config.Club_RoleType.Manager, start, limit)
	-- print("club_applys sql:",sql)

	local res = db_mgr.execute(sql)
	if #res > 0 then
		--更新该用户看到的验证消息的最大ID
		local maxapplymsgid = res[1]["id"]
		db_mgr.update("d_club_member", {maxapplymsgid = maxapplymsgid}, {uid = uid, clubid = clubid})
	end
	return res
end

-- 审核加入俱乐部、房间申请
function logic.verify_in_club( uid, applyid, verify_status, msg )
	local where = "where status=0 and id="..applyid
	local res = db_mgr.query("d_club_apply", where)
	if #res == 0 then
		return "没有该申请ID"
	else
		local apply_status = res[1]["status"]
		if apply_status ~= Club_Config.Club_Apply_Status.Apply then
			return "该申请已审核过"
		end

		local clubid = res[1]["clubid"]
		where = string.format("where status<>-1 and clubid=%d and uid=%d and roletype>=%d"
			,clubid, uid, Club_Config.Club_RoleType.Manager)
		local count = db_mgr.count("d_club_member", where)
		if count == 0 then
			return "无权审核该俱乐部申请"
		end

		------------------------审核加入房间--------------------
		local roomid = tonumber(res[1]["roomid"])
		if roomid ~= nil and roomid > 0 then
			return logic.verify_in_club_room(res, verify_status, msg)
		end

		------------------------审核加入俱乐部------------------

		local apply_uid = res[1]["uid"]
		where = "where status<>-1 and clubid="..clubid.." and uid="..apply_uid
		local set_res = db_mgr.query("d_club_member", where)
		if #set_res > 0 then
			return "该俱乐部已存在该成员"
		end

		where = "where status=0 and id="..clubid
		res = db_mgr.query("d_club", where)
		if #res == 0 then
			return "俱乐部已不存在"
		elseif tonumber(res[1]["member_count"]) >= tonumber(res[1]["max_member_count"]) then
			return "俱乐部已满员"
		end

		if verify_status == Club_Config.Club_Apply_Status.Pass then
			local club_member = {}
			club_member.clubid = clubid
			club_member.uid = apply_uid
			club_member.maxmsgid = get_maxmsgid(clubid)
			club_member.roletype = Club_Config.Club_RoleType.Ordinary
			club_member.addtime = time_string(skynet.time())
			db_mgr.add("d_club_member", club_member)

			-- 更新成员数量
			local sql = "update d_club set member_count=member_count+1 where id="..clubid
			db_mgr.execute(sql)
		end

		--添加审核记录
		local club_verify = {}
		club_verify.applyid = applyid
		club_verify.uid = uid
		club_verify.msg = msg
		club_verify.status = verify_status
		club_verify.addtime = time_string(skynet.time())
		db_mgr.add("d_club_verify", club_verify)

		--更新申请记录
		db_mgr.update("d_club_apply", {status = verify_status}, {id = applyid})
	end
end

-- 获取俱乐部详情
function logic.get_club_detail( uid,clubid )
	local sql = string.format("select c.id,c.imgid,c.name,c.fund,c.member_count,c.max_member_count,c.areaid,c.intro,c.creater,u.user_name creater_name,u.user_avatar creater_avatar,a.province from d_club c left join c_area a on c.areaid=a.id left join d_user u on u.id=c.creater where c.status=0 and c.id=%d limit 1", clubid)
	local res = db_mgr.execute(sql)
	if #res > 0 then
		res[1]["roletype"] = -1
		sql = string.format("select * from d_club_member where status<>-1 and uid=%d and clubid=%d limit 1", uid,clubid)
		local res2 = db_mgr.execute(sql)
		if #res2 > 0 then
			res[1]["roletype"] = res2[1]["roletype"]
		end
		res[1]["unread_apply_num"] = get_unread_apply_num( clubid, uid)
	end
	return res
end

-- 获取俱乐部成员列表
function logic.get_club_members( uid,clubid )
	if not check_authority(uid,clubid,Club_Config.Club_Buttons_Auth.Get_Member) then
		return nil,"权限不足"
	end
	local sql = string.format("select m.uid,m.clubid,m.roletype,m.status,u.user_name nickname,u.user_avatar,u.last_logintime from d_club_member m left join d_user u on m.uid=u.id where m.status<>-1 and m.clubid=%d order by m.roletype desc,u.last_logintime desc", clubid)
	return db_mgr.execute(sql)
end

-- 修改俱乐部成员角色（开除成员）
function logic.set_member_roletype( uid, clubid, set_uid, roletype, status )
	local where = "where status<>-1 and clubid="..clubid.." and uid="..uid
	local res = db_mgr.query("d_club_member", where)
	if #res == 0 then
		return nil,"亲，你不是该俱乐部成员"
	elseif not check_authority(uid,clubid,Club_Config.Club_Buttons_Auth.Modify_Auth) then
		return nil,"权限不足"
	else
		where = "where status<>-1 and clubid="..clubid.." and uid="..set_uid
		local set_res = db_mgr.query("d_club_member", where)
		if #set_res == 0 then
			return nil,"亲，设置人员不是该俱乐部成员"
		elseif tonumber(set_res[1]["roletype"]) >= tonumber(res[1]["roletype"]) then
			return nil,"亲，你无权设置该成员"
		end

		if status then
			db_mgr.update("d_club_member", {status = status}, {id = set_res[1]["id"]})
			if status == Club_Config.Club_MemberStatus.Del then
				-- 开除 需要更新成员数量
				local sql = "update d_club set member_count=member_count-1 where id="..clubid
				db_mgr.execute(sql)
			end
		elseif roletype then
			db_mgr.update("d_club_member", {roletype = roletype}, {id = set_res[1]["id"]})
		end
		return roletype
	end
end

-- 退出/解散俱乐部
function logic.quit_club( uid, clubid )
	local where = "where status<>-1 and clubid="..clubid.." and uid="..uid
	local res = db_mgr.query("d_club_member", where)
	if #res == 0 then
		return nil,"亲，你不是该俱乐部成员"
	elseif tonumber(res[1]["roletype"]) == Club_Config.Club_RoleType.Creater then
		-- 解散俱乐部
		db_mgr.update("d_club", {status = Club_Config.Club_MemberStatus.Del}, {id = clubid})
		return "解散俱乐部成功"
	else
		-- 退出俱乐部
		db_mgr.update("d_club_member", {status = Club_Config.Club_MemberStatus.Del}, {id = res[1]["id"]})
		-- 退出 需要更新成员数量
		local sql = "update d_club set member_count=member_count-1 where id="..clubid
		db_mgr.execute(sql)
		return "退出俱乐部成功"
	end
end

-- 发送俱乐部聊天信息
function logic.send_club_msg( uid, clubid, msg )
	local club_msg = {}
	club_msg.clubid = clubid
	club_msg.uid = uid
	club_msg.content = msg
	club_msg.addtime = time_string(skynet.time())
	local msg_id = db_mgr.add("d_club_msg", club_msg)
	
	if uid > 0 then
		-- 更新查看过的最大聊天消息ID
		db_mgr.update("d_club_member", {maxmsgid = msg_id}, {uid = uid, clubid = clubid})
	end
	return msg_id
end

-- 获取俱乐部聊天信息
function logic.get_club_msgs( uid, clubid, start, limit , start_id)
	-- 信息只保留两天内信息，超过自动清空。
	local earliest_time = time_string(skynet.time() - 2*24*3600)

	local sql = string.format("select m.id,m.uid,m.content msg,m.addtime addtime,u.user_avatar avatar,u.user_name nickname from d_club_msg m left join d_user u on m.uid=u.id where clubid=%d and m.id>%d and m.uid<>0 and m.addtime>'%s' order by m.addtime desc limit %d,%d"
		,clubid, start_id, earliest_time, start, limit)
	local res = db_mgr.execute(sql)

	if start == 0 and #res > 0 then
		-- 更新查看过的最大聊天消息ID
		db_mgr.update("d_club_member", {maxmsgid = tonumber(res[1]["id"])}, {uid = uid, clubid = clubid})
	end
	--未读验证消息条数
	local apply_num = get_unread_apply_num( clubid, uid )
	local result = {}
	result.list = res
	result.apply_num = apply_num
	return result
end

-- 设置俱乐部信息
function logic.set_club_info( uid, clubid, imgid, name, intro )
	if not check_authority(uid,clubid,Club_Config.Club_Buttons_Auth.Setting) then
		return nil,"权限不足"
	end
	db_mgr.update("d_club", {imgid = imgid, name = name, intro = intro}, {id = clubid})
	return "设置成功"
end

-- 俱乐部基金充值列表
function logic.get_fund_records( uid, clubid, start, limit )
	if not check_authority(uid,clubid,Club_Config.Club_Buttons_Auth.Fund_Manager) then
		return nil,"权限不足"
	end
	local sql = string.format("select f.id,f.fund,f.addtime,u.user_name nickname from d_club_fundrecord f left join d_user u on f.uid=u.id where f.clubid=%d order by addtime desc limit %d,%d"
		,clubid, start, limit)
	local res = db_mgr.execute(sql)
	return res
end


-- 俱乐部补充基金
function logic.add_club_fund( uid, clubid, fund)
	local user_info = _user.get(uid)
	if user_info == nil then
		return nil,"用户不存在"
	end
	if user_info.user_money < fund then
		return nil,"用户钻石不足"
	end

	--更新玩家钻石
	local content = {
		uid = uid,
		money = -fund,
		task_type = "add_money",
		msg = "您已成功补充俱乐部【"..clubid.."】基金:【"..fund.."】"
	}
	_user.add_task(uid, content)

	-- 更新俱乐部基金
	local f_result = logic.update_fund(clubid,fund)
	if f_result == false then
		return nil,"更新俱乐部基金不足"
	end

	-- 添加记录
	local club_fundrecord = {}
	club_fundrecord.clubid = clubid
	club_fundrecord.uid = uid
	club_fundrecord.fund = fund
	club_fundrecord.addtime = time_string(skynet.time())
	local msg_id = db_mgr.add("d_club_fundrecord", club_fundrecord)

	local new_fund = db_mgr.get_value("d_club", "fund", {id = clubid})
	if new_fund ~= nil then
		return new_fund
	end
	return fund
end

-- 俱乐部对局记录
function logic.get_room_records( uid, clubid, start, limit )
	if not check_authority(uid,clubid,Club_Config.Club_Buttons_Auth.Records) then
		return nil,"权限不足"
	end
	-- 对局纪录显示改为保留3天内纪录
	local earliest_time = time_string(skynet.time() - 3*24*3600)

	local sql = string.format("select * from d_room where endtime is not null and starttime > '%s' and clubid=%d order by starttime desc limit %d,%d"
		, earliest_time, clubid, start, limit)
	local tmp_res = db_mgr.execute(sql)
	local res = {}
	for i,v in ipairs(tmp_res) do
		local item = {}
		item.addtime = v.starttime
		local roominfo = json.decode(v.roominfo)
		local scoreinfo = json.decode(v.scoreinfo)
		item.room_type = roominfo.room_type
		item.times_num = roominfo.times_num or 1
		item.members = {}
		for k1,v1 in pairs(scoreinfo) do
			local m_item = {}
			m_item.score = v1
			for k,v in pairs(roominfo.members) do
				if k1 == k then
					m_item.uid = k
					m_item.nickname = v
				end
			end
			table.insert(item.members, m_item)
		end
		table.insert(res, item)
	end

	return res
end


-- 申请加入俱乐部房间
function logic.apply_in_club_room( uid, clubid, roomid, msg )
	-- 最短间隔30s才能再次请求
	local compare_time = time_string(skynet.time() - 30)
	local where = "where clubid="..clubid.." and uid="..uid.." and roomid="..roomid.." and addtime>'"..compare_time.."'"
	local res = db_mgr.query("d_club_apply", where)
	if res ~= nil and #res > 0 then
		return "请求过于频繁"
	end

	--添加申请进入房间记录
	local club_apply = {}
	club_apply.clubid = clubid
	club_apply.uid = uid
	club_apply.roomid = roomid
	club_apply.msg = msg
	club_apply.status = Club_Config.Club_Apply_Status.Apply
	club_apply.addtime = time_string(skynet.time())
	db_mgr.add("d_club_apply", club_apply)
end

--获取加入俱乐部房间审核状态
function logic.get_apply_in_club_room_status( uid, roomid )
	-- 30s等待审核是否通过，超时失效
	local compare_time = time_string(skynet.time() - 30)
	local where = "where roomid>0 and uid="..uid.." and addtime>'"..compare_time.."'"
	if roomid ~= nil and roomid > 0 then
		-- 请求加入具体房号时调用 可以宽限到5分钟之内的审核通过都有效
		compare_time = time_string(skynet.time() - 5*60)
		where = "where uid="..uid.." and addtime>'"..compare_time.."'".." and roomid="..roomid
	end
	--print("where:",where)
	local other = " order by status desc limit 1"
	local res = db_mgr.query("d_club_apply", where, nil , other)
	if res ~= nil and #res > 0 then
		local status = res[1]["status"]
		--申请状态（0：申请提交，1：申请通过 ，-1：驳回，-10：驳回并不接收申请）
		return status
	else
		return -100
	end
end

-- 审核加入俱乐部房间申请
function logic.verify_in_club_room( applyinfo, verify_status, msg )
	local applyid = applyinfo[1]["id"]
	local addtime = applyinfo[1]["addtime"]
	local last_time = time_string(skynet.time() - 30)

	--添加审核记录
	local club_verify = {}
	club_verify.applyid = applyid
	club_verify.uid = uid
	club_verify.msg = msg
	club_verify.status = verify_status
	club_verify.addtime = time_string(skynet.time())
	db_mgr.add("d_club_verify", club_verify)
	if last_time > addtime then
		db_mgr.update("d_club_apply", {status = -2}, {id = applyid})
		return "请求已过期"
	end

	--更新申请记录
	db_mgr.update("d_club_apply", {status = verify_status}, {id = applyid})
end

return logic
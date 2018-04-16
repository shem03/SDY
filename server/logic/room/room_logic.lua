local skynet = require "skynet"
local _user = require("user.core")
local notice = require("notice_utils")
room_logic = {}
local json = require("cjson")
json.encode_sparse_array(true,1)

function room_logic.run()
    -- print("开始---》启动房间逻辑操作")
    if g.ask_quit_time > 0 then
        g.ask_quit_time = g.ask_quit_time - 1
        if g.ask_quit_time == 0 then
            -- 清空请求的状态
            for i,v in ipairs(g.seat) do
                local user = g.users[v]
                user.agree_quit = nil
            end
            LOG("time out agree_quit")
            room_logic.game_over(true)
        end
    end

    if g.room_info and (g.room_info.game_type == "hongbao" or g.room_info.game_type == "pk10") then
        return
    end

    -- 超过一定时间没有动作，则解散
    local expire_time = Config.auto_del_room
    if expire_time and (g.game_time > expire_time and g.start_time == nil) then
        -- 俱乐部房间增加 10分钟没有人进入房间 或者 10分钟未开始自动关闭
        room_logic.game_over(true)
        return
    end
end

function room_logic.broadcast(data, skipusers)
    for k,v in pairs(g.users) do
        -- 不需要通知 房间所有人 有时候需要去除自己
        if (type(skipusers) == "table") and not is_in_table(skipusers, k) then
            send_msg(v.fd, data)
        elseif k ~= skipusers then 
            send_msg(v.fd, data)
        end
    end
end

function room_logic.user_update_coin(user, coin)
    LOG("user_update_coin:", user.id, user.user_coin, coin)
    --cxz
    user.user_coin = user.user_coin or 0
    local temp_coin = user.user_coin + coin
    if temp_coin < 0 then
        coin = -user.user_coin
    end
    return _user.update_coin(user, coin)
end

function room_logic.get_userinfo( user )
	--cxz
    return {
        uid = user.id,
        name = user.user_name or user.name,
        coin = user.user_coin or 10000,
        sex = user.user_sex or 1,
        avatar = user.user_avatar,
        ip = user.ip,
    }
end

function room_logic.leave_agent(user)
	-- 通知watchdog
    if user then
        print("room_logic.leave_agent===========g.room_info.roomid", g.room_info.roomid, user.fd, user.id, g.round)
        skynet.call(g.watchdog, "lua", "leave_agent", {roomid=g.room_info.roomid, 
            fd=user.fd, id=user.id, round=g.round})
    else
        -- 空房超时 销毁房间
        skynet.call(g.watchdog, "lua", "leave_agent", {roomid=g.room_info.roomid, 
            fd=0, id=0, needkillroom=1, round=g.round})
    end
end

function room_logic.game_start()
    if g.start_time == nil then
        g.start_time = time_string(skynet.time())

        if g.room_info.average then
            local card = math.floor(g.room_info.room_card/g.room_info.min_count)
            for k,v in pairs(g.seat) do
                local user = g.users[v]
                _user.update_money(user_info, -card)
                _user.add_consume_log(user.uid, "money", -card, room.game_type.."消费", user_info.user_money)
                send_msg(user.fd, {
                    msg_id="update_bee", 
                    cur_card=user_info.user_money
                })
            end
        end
    end
end

function room_logic.game_over(all_over)
    -- 所有玩家清空准备状态
    for k,v in pairs(g.seat) do
        local user = g.users[v]
        user.ready = nil
    end
    local data = {
        msg_id = "game_over",
        all_over = false,
        start_time = g.start_time,
        over_time = time_string(skynet.time())
    }

    -- 统计积分
    if g.room_info.private and g.round_score and g.room_info.game_type ~= "daboluo" then
        room_logic.add_score_data()
        if Config.channel == 'dyj' then
            data.points = room_logic.add_point()
        end

        --保证完成了第一局 才添加房间记录 线上跑99%开房后退房的数据了
        if tonumber(g.round) == 1 then
            room_logic.add_room_data()
        end
    end

    if all_over or (g.room_info.round_num and tonumber(g.round) >= tonumber(g.room_info.round_num)) then
        --更新房间结算记录
        room_logic.add_room_data(1)

        LOG("all_over:", all_over, g.room_info.round_num, g.round, g.roundid)
        g.game_step = Config.step_none
        g.game_time = 0

        -- 所有局数完成
        data.all_over = true
        room_logic.broadcast(data)
        -- 断开所有玩家
        local count = 0
        for k,v in pairs(g.users) do
            g.game_logic.post_leave(v)
            count = count + 1
        end
        if count == 0 then
            room_logic.leave_agent(nil)
        end
        return
    elseif all_over then   --红包解散房间
        print("红包解散房间===>")
        g.game_step = Config.step_none
        g.game_time = 0

        -- 所有局数完成
        data.all_over = true
        room_logic.broadcast(data)
        -- 断开所有玩家
        local count = 0
        for k,v in pairs(g.users) do
            g.game_logic.post_leave(v)
            count = count + 1
        end
        if count == 0 then
            room_logic.leave_agent(nil)
        end
        return
    else
        room_logic.broadcast(data)
    end
    
	-- 检查所有在座的是否金币充足
    if g.room_info.room_coin > 0 then
        if #g.seat > 0 then
            for k,v in pairs(g.seat) do
                local user = g.users[v]
                -- cxz 金币不足先注释
                if false or  user.user_coin < g.room_info.min_coin then
                    -- 强制站起
                    send_error(user.fd, -5, "金币不足，强制站起。")
                    
                    g.game_logic.post_leave(user)
                end
            end
        else
            room_logic.leave_agent(nil)
        end
    end

end

function room_logic.check_ready()
    local rec = true
    local count = 0
    for k,v in pairs(g.seat) do
        local user = g.users[v]
        if user.ready ~= true then
            if user.is_robot then
                user.ready = true
                room_logic.broadcast({msg_id="ready", uid=user.id})
            else
                rec =  false
            end
        else
            count = count + 1
        end
    end
    if g.room_info.private and count < g.room_info.min_count then
        rec =  false
    end
    --大菠萝2人即可开始游戏
    if g.room_info.private and count < g.room_info.min_count and g.room_info.game_type == "daboluo" then
        rec =  true
    end
    -- 如果开局，同时是私人房，则记录数据
    -- if rec and g.room_info.private and g.round == 0 then
        
    -- end
    return rec
end

function room_logic.get_ready()
    local readys = {}
    for k,v in pairs(g.seat) do
        local user = g.users[v]
        readys[user.id] = user.ready
    end
    return readys
end

-- 全局下来总分排行
function room_logic.add_point()
    -- 统计所有分数
    local points = {}
    for k,v in pairs(g.round_score) do
        for kk,vv in pairs(v) do
            points[kk] = (points[kk] or 0) + vv
        end
    end
    local end_points = {}
    for k,v in pairs(points) do
        table.insert(end_points, {uid=k, score=v})
    end
    -- 当两个数相等的时候，比较函数一定要返回false
    -- 从大小到排序
    table.sort(end_points, function( x, y )
        return x.score > y.score
    end)
    local adds = {}
    for k,v in pairs(end_points) do
        local config_point = Config.add_point[#end_points]
        if config_point == nil then
            return adds
        end
        local point = config_point[k]
        local user = g.users[v.uid]
        if user and point > 0 and not user.is_robot then
            _user.update_point(user, point)
            adds[user.id] = point
        end
    end
    return adds
end

function room_logic.add_score_data()
    -- 记录每个玩家每局的分数
    local names = {}
    if g.round_score[g.round] then
        for kk,vv in pairs(g.round_score[g.round]) do
            local user = g.users[kk]
            if user then
                names[kk] = string.gsub(user.name, "'", "''")
            end
            print("kk, vv, g.room_info.game_type, g.room_info.roomid, g.roundid, g.round",kk, vv, g.room_info.game_type, g.room_info.roomid, g.roundid, g.round)
            _user.add_score_log(kk, vv, g.room_info.game_type, g.room_info.roomid, g.roundid, g.round)
        end

        -- local room_info = table_copy_table(g.room_info)
        -- room_info.members = nil
        --, room_info = room_info
        local data = {scores = g.round_score, users = names}
        local score_data = json.encode(data)
        for k,v in pairs(names) do
            -- 如果是第一局，创建新数据
            if g.round == 1 then
                _user.add_score_data( k, g.room_info.roomid, score_data, g.room_info.clubid, g.roundid )
            else
                _user.update_score_data( k, g.room_info.roomid, score_data, g.room_info.clubid, g.roundid )
            end
        end
    end
end

-- 添加房间/更新房间积分记录
function room_logic.add_room_data(game_over)
    -- 大厅对局不记录
    if not g.room_info.private then
        return
    end
    -- 刚开始开局，创建新数据
    -- 兼容打一局 就结束的牌局 没有存储scoreinfo
    if g.round == 1 and (game_over == nil or game_over == 0) then
        local roominfo = table_copy_table(g.room_info)
        if #roominfo.members > #g.seat then
            local members = table_copy_table(roominfo.members)

            --过滤不在房间里玩的玩家
            local del_keys = {}
            local isseat = false
            for k,v in pairs(members) do
                isseat = false
                for ii,vv in ipairs(g.seat) do
                    if tonumber(vv) == tonumber(k) then
                        isseat = true
                        break
                    end
                end
                if not isseat then
                    table.insert(del_keys, k)
                end
            end
            for k,v in pairs(del_keys) do
                members[v] = nil
            end

            roominfo.members = nil
            roominfo.members = members
        end
        local roominfo = json.encode(roominfo)
        _user.add_room_data(g.room_info.roomid, g.roundid, g.room_info.clubid , roominfo)
    else
        local scoreinfo = {}
        if g.round > 0 then
            for i=g.round,1,-1 do
                if g.round_score[i] then
                    for kk,vv in pairs(g.round_score[i]) do
                        scoreinfo[kk] = scoreinfo[kk] or 0
                        scoreinfo[kk] = scoreinfo[kk] + (vv)
                    end
                end
            end
        end
        LOG(string.format("g.round_score：%s",g.round_score))
        local scoreinfo = json.encode(scoreinfo)
        _user.update_room_data(g.room_info.roomid, g.roundid, scoreinfo)
    end
end

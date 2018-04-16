local skynet = require "skynet"
require "skynet.manager"
require "socket_fun"

local CMD = {}

-- 初始化
function CMD.start()
end

-- 广播
-- 数据 data
-- 单发 传uid即可
-- 群发 传uid = uids即可（暂时没实现）
-- 全服 传uid = nil 即可
function CMD.broadcast(data, uid)
    local all_conns = skynet.call("cachepool", "lua", "get_conns")
    local all_rooms = skynet.call("cachepool", "lua", "get_rooms")
    --print("all_conns_cac:", all_conns)
    --print("all_rooms_cac:", all_rooms)
    -- 大厅玩家
    if uid then                                 --单发
        if type(uid) ~= "string" then
            uid = tostring(uid)
        end
        -- 大厅玩家
        for k, v in pairs(all_conns) do
            --print("uid and v.user.uid============",uid, v.user.uid)
            if uid and v.user and (uid == v.user.uid) then
                --print("find uid===============", uid)
                send_msg(v.fd, data)
                break
            end
        end
    else                                        --群发
        -- 大厅玩家
        for k, v in pairs(all_conns) do
            send_msg(v.fd, data)
        end
    end

    -- 房间内玩家
    for groupid, room in pairs(all_rooms) do
        local agent = room.agent
        if agent then
            skynet.call(agent, "lua", "notice_action", data, uid)
        end
    end
end

function CMD.get_online_num_info()
    local all_conns = skynet.call("cachepool", "lua", "get_conns")
	local all_rooms = skynet.call("cachepool", "lua", "get_rooms")
    
    local online_num_data = {}
    -- 总在线人数
    table.insert(online_num_data, {
        gameType = '0',
        onlineNum = table.size(all_conns)
    })

    -- 每个房间在线人数
	for groupid, room in pairs(all_rooms) do
        local agent = room.agent
        if agent then
            local gameType = room.gameRoomInfo.gameType
            local online_num = skynet.call(agent, "lua", "get_online_num")
           
            if online_num_data[gameType] then
                online_num_data[gameType].onlineNum = online_num_data[gameType].onlineNum + online_num
            else
                table.insert(online_num_data, {
                    gameType = gameType,
                    onlineNum = online_num
                })
            end
        end
    end

    return online_num_data
end

return CMD

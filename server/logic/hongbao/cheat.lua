local utils  = require("hongbao.poker_utils")

local cmd = {}

local dxds_cfg = {
    [1] = {1, 2, 3, 4, 5},
    [2] = {6, 7, 8, 9, 10},
    [3] = {1, 3, 5, 7, 9},
    [4] = {2, 4, 6, 8, 10},
    [5] = {1, 3, 5},
    [6] = {7, 9},
    [7] = {2, 4},
    [8] = {6, 8, 10},
    [9] = {11, 12, 13, 14, 15, 16},
}

-- 获取第二位小数
local function getDot2(point, ge, dot1, n)
    local dot2 = 0
    if point <  ge + dot1 then
        local n = 1
        dot2 = math.abs(ge + dot1 - n * 10 - point)
    else
        dot2 = point - ge - dot1
    end
    return dot2
end

-- 获取点数索引
local function getPointIndex(rates)
    local rate = math.random(1, 100)
    local point = 0
    for i=1, #rates do
        local r1 = rates[i]
        if i == 1 and rate < r1 then
            point = i
            break
        end 
        if r1 == rate then
            point = i
            break
        end
        for j = 2, #rates do
            local r2 = rates[j]
            if rate < r2 and rate > r1 then
                point = j
                break
            end
        end
    end
    return point
end

-- 生成普通牛牛点数
local function get_normal_cow(point, ge)
    local random = math.random(1, 100)
    local start = 1
    if random < 15 then
        start = 0
    end
    local ge   = math.random(start, ge or 3) 
    local dot1 = math.random(0, 9) 
    -- point = 10
    -- ge = 0
    -- dot1 = 0
    if point == 10 and ge == 0 and dot1 == 0 then
        local ran = math.random(0,1)
        if ran == 1 then
            ge = math.random(1, 3) 
        else
            dot1 =  math.random(1, 3) 
        end
    end
    local dot2 = getDot2(point, ge, dot1, 1)
   return ge .. "." .. dot1 .. dot2
end

-- 生成特殊点
local function get_spcial_point(point, limit)
    if point == 11 then         --金牛
        local cfg = utils.get_jinniu_cfg()
        local index = math.random(1, #cfg)
        return cfg[index]
    elseif point == 12 then     --对子
        local cfg = utils.get_duizi_cfg()
        local index = math.random(1, #cfg)
        return cfg[index]
    elseif point == 13 then     --正顺
        local cfg = utils.get_zhengshun_cfg()
        local index = math.random(1, 3)
        return cfg[index]
    elseif point == 14 then     --倒顺
        local cfg = utils.get_daoshun_cfg()
        local index = math.random(6, 7)
        return cfg[index]
    elseif point == 15 then     --满牛
        local cfg = utils.get_manniu_cfg()
        local index = math.random(1, 3)
        return cfg[index]
    elseif point == 16 then     --豹子
        local cfg = utils.get_baozi_cfg()
        local index = math.random(1, 3)
        return cfg[index]
    end
end

-- 大小单双 生成除自己以外的点数
local function getIgnoreDxdsTag(bets)
    local userPoints = {}
    for index, unit_bet in pairs(bets) do
        local user_dxds = dxds_cfg[unit_bet.sub_type]
        for k, v in pairs(user_dxds) do 
            table.insert(userPoints, v)
        end
    end
    print(userPoints)

    -- 去重
    userPoints = tb_remove_repeat(userPoints)
    print("去重后的结果", userPoints)

    -- 搞出点数
    local tags = {}
    for i=1, 9 do
        local cfg_dxds = dxds_cfg[i]
        local isMath = true
        for cfg_index, cfg_dxds in pairs(cfg_dxds) do 
            for user_index, user_dxds in pairs(userPoints) do
                if cfg_dxds == user_dxds then
                    isMath = false
                    break
                end
            end
            if not isMath then
                break
            end
        end

        if isMath then
            table.insert(tags, i)
        end
    end

    -- 去重
    print(tags)
    if table.size(tags) == 0 then
        return 0
    end

    return tags[math.random(1, #tags)]
end

-- 生成大小单双点数
local function getDxdsValue(tag, ge)
    print("tag", tag)
    if tag == 9 then
        local points = dxds_cfg[tag]
        local point = points[math.random(1, #points)]
        local packet_value = get_spcial_point(point, ge or 1)
        print("合：", packet_value)
        return packet_value
    elseif tag == 8 then    -- 大双
        local points = dxds_cfg[tag]
        local point = points[math.random(1, #points)]
        local packet_value = get_normal_cow(point, ge or 1)
        print("大双：", packet_value)
        return packet_value
    elseif tag == 7 then    -- 小双
        local points = dxds_cfg[tag]
        local point = points[math.random(1, #points)]
        local packet_value = get_normal_cow(point, ge or 1)
        print("小双：", packet_value)
        return packet_value
    elseif tag == 6 then    -- 大单
        local points = dxds_cfg[tag]
        local point = points[math.random(1, #points)]
        local packet_value = get_normal_cow(point, ge or 1)
        print("大单：", packet_value)
        return packet_value
    elseif tag == 5 then    -- 小单
        local points = dxds_cfg[tag]
        local point = points[math.random(1, #points)]
        local packet_value = get_normal_cow(point, ge or 1)
        print("小单：", packet_value)
        return packet_value
    elseif tag == 4 then    -- 双
        local points = dxds_cfg[tag]
        local point = points[math.random(1, #points)]
        local packet_value = get_normal_cow(point, ge or 1)
        print("双：", packet_value)
        return packet_value
    elseif tag == 3 then   -- 单
        local points = dxds_cfg[tag]
        local point = points[math.random(1, #points)]
        local packet_value = get_normal_cow(point, ge or 1)
        print("单：", packet_value)
        return packet_value
    elseif tag == 2 then   -- 大
        local points = dxds_cfg[tag]
        local point = points[math.random(1, #points)]
        local packet_value = get_normal_cow(point, ge or 1)
        print("大：", packet_value)
        return packet_value
    elseif tag == 1 then   -- 小
        local points = dxds_cfg[tag]
        local point = points[math.random(1, #points)]
        local packet_value = get_normal_cow(point, ge or 1)
        print("小：", packet_value)
        return packet_value
    end
end

--- 庄家
function cmd.baner_event(ge)
    print("庄家事件")
    local packet_value = "0.01"

    local rate = math.random(1, 100)
    rate = 100
    local  N = {15, 15, 17, 17, 18, 18}                 --牛一，牛二，牛三，牛四，牛五，牛六
    local  M = {14, 14, 12, 12, 10, 10, 8, 8, 6, 6}     --牛七，牛八，牛九，牛牛，金牛，对子，正顺，倒顺，满牛，豹子
    local n_rate = {}
    local m_rate = {}

    -- 大
    local last = 0
    for k, v in pairs(N) do
        last = last + v
        n_rate[k] = last
    end

    -- 小
    last = 0
    for k, v in pairs(M) do
        last = last + v
        m_rate[k] = last
    end

    if rate >= 45 then
        -- 计算权重
        --local  m_rate = {14, 28, 40, 52, 62, 72, 80, 88, 94, 100}
        local point = getPointIndex(m_rate) + #N
        if point > 10 then                  -- 特殊点
            packet_value = get_spcial_point(point)
            print("大等45生成特殊点：", packet_value, point)
        else                                -- 正常牛
            packet_value = get_normal_cow(point, ge)
            print("大等45：", packet_value, point)
        end
    else
        --计算权重
        --local n_rate = {15, 30, 47, 64, 82, 100}
        local point = getPointIndex(n_rate)
        packet_value = get_normal_cow(point, ge)
        print("小于45：", packet_value, point)
    end
    return packet_value
end

-- 闲家
function cmd.use_event(bet_data, ge)
    print("闲家事件")
    --判断玩家1、2、4
    local rate = math.random(1, 100)
    
    -- 开始
    rate = 39
    if rate >= 40 then
        return {}, 0
    end

    local otherBets = {}
    local packet = {}
    local cash = 0
    for uid, bets in pairs(bet_data) do
        if table.size(bets) > 0 then
            local bet = bets[1]
            local type = bet.type
            if type == 3 then
                local tag = getIgnoreDxdsTag(bets)
                --print("===>", tag)
                if tag > 0 then
                    packet[uid] = {value = getDxdsValue(tag, ge), open = false, isGua = false}
                    cash = cash + tonumber(packet[uid].value)
                end
            else
                print("无")
            end
        end
    end

    return packet, cash
end

-- 分配红包
function cmd.assign_red_packet(money, people, roomData)
    -- test 
    local banker_id = g.banker
    local bet_data  = g.bet_data
    local players   = g.players
    --[[
    money = 8
    people = 4
    local banker_id = "11111"
    local bet_data = 
    {
        ["10111"] = {
            { 
            type     = 1,
            sub_type = nil,
            value    = 100
            }
        },
        ["10112"] = {
            { 
            type     = 1,
            sub_type = nil,
            value    = 100
            }
        }, 
        ["10113"] = {
            { 
                type     = 3,
                sub_type = 2,
                value    = 100
            },
            { 
                type     = 3,
                sub_type = 5,
                value    = 100
            }
        },
    }

    local players = {["11111"] = true, ["10111"] = true, ["10112"] = true, ["10113"] = true}
    ]]

    -- 开始逻辑
    local ct_banker = roomData.banker_ct ~= 0 
    local ct_user   = roomData.user_ct ~= 0 
    local packets   = {} 
    print("=====1111", roomData, ct_banker, ct_user, bet_data)
    if ct_banker == true and ct_user == true then       -- 庄闲
        local bet_count = table.size(bet_data)
        local count = 0
        for uid, bets in pairs(bet_data) do
            if table.size(bets) > 0 then
                local bet = bets[1]
                local type= bet.type
                if type == 3 then
                    count = count + 1
                end
            end
        end
        print("bet_count, count", bet_count, count, bet_data)
        if bet_count == count then
            local user_packets, cash = cmd.use_event(bet_data, 2)
            local off = money - (cash or 0)
            if off <= 0 then
                user_packets, cash = cmd.use_event(bet_data)
                off = money - (cash or 0)
            end
            print("user_packets", user_packets)
            local banker_value = string.format("%0.2f", off)

            packets[banker_id] =  {value = banker_value, open = false, isGua = false}
            for uid, v in pairs(user_packets) do
                packets[uid] = v
            end
        else
            local banker_value = cmd.baner_event(2)
            local user_packets, cash = cmd.use_event(bet_data, 2)
            local off = money - banker_value - (cash or 0)
            if off <= 0 then
                banker_value = cmd.baner_event(1)
                user_packets, cash = cmd.use_event(bet_data)
                off = money - banker_value - (cash or 0)
            end

            local redpackets = utils.randomRedPacket(off, people - table.size(user_packets) - 1)
            packets[banker_id] =  {value = banker_value, open = false, isGua = false}
            for uid, v in pairs(user_packets) do
                packets[uid] = v
            end

            local index = 1
            for uid, player in pairs(players) do
                local isMath = true
                for id, packet in pairs(packets) do
                    if uid == id then
                        isMath = false
                        break
                    end
                end
                if isMath then
                    packets[uid] = {value = redpackets[index], open = false, isGua = false}
                    index = index + 1
                end
            end
        end
        print("ok", packets)
        g.packets = packets
    elseif ct_banker == true then                       -- 庄
        local banker_value = cmd.baner_event()
        local redpackets   = utils.randomRedPacket(money - banker_value, people - 1)
        packets[banker_id] =  {value = banker_value, open = false, isGua = false}
        local index = 1
        for uid, player in pairs(players) do
            local isMath = true
            for id, packet in pairs(packets) do
                if uid == id then
                    isMath = false
                    break
                end
            end
            if isMath then
                packets[uid] = {value = redpackets[index], open = false, isGua = false}
                index = index + 1
            end
        end
        print("ok2", packets)
        g.packets = packets
    elseif ct_user == true then                         -- 闲
        local packet, cash = cmd.use_event(bet_data)
        local size         = table.size(packet)
        local redpackets   = utils.randomRedPacket(money - cash, people - size)
        packets = packet
        local index = 1
        for uid, player in pairs(players) do
            local isMath = true
            for id, packet in pairs(packets) do
                if uid == id then
                    isMath = false
                    break
                end
            end
            if isMath then
                packets[uid] = {value = redpackets[index], open = false, isGua = false}
                index = index + 1
            end
        end
        print("ok3", packets)
        g.packets = packets
    end
end

return cmd
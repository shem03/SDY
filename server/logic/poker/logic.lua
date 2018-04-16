local skynet = require "skynet"
local _user = require("user.core")
local poker_utils = require("poker.poker_utils")
local db_mgr = require("db_mgr")

local logic = {}

-- 必须的函数
-----------------------------------------------------------------------
local function random_robot()
    local id = math.random(g.rebot_num)
    local rebot = db_mgr.get("c_robot", "id", id)
    print("random_robot:", rebot)
    return rebot
end

function logic.add_robot()
    local num = 1--math.random(1,3)
    print("add_robot:", num)
    for i=1, num do
        local user = random_robot()
        user.user_coin = math.random(10000, 100000)
        user.is_robot = true
        g.robot_user = g.robot_user + 1
        user.fd = -user.id
        g.conns[user.fd] = user
        g.users[user.id] = user

        logic.login(user)
    end
end

local function get_seat( uid )
    for i=1,g.room_info.min_count do -- 玩家座位1-min_count
        if g.seat[i] == uid then
            return i
        end
    end
end

function logic.login(user)
    local seat_num = g.room_info.min_count
     -- 没有空位，则发进入的消息
    local data = {
        msg_id = "someone_enter_room",
        uid = user.id,
        seat_num = seat_num,
        round = g.round,
        owner = g.room_info.owner,
        infoData = room_logic.get_userinfo(user),
        ready = user.ready,
        have_card = g.cards and g.cards[user.id] and true or false,
        show_card =  g.cur_cards and g.cur_cards[user.id] and true or false,
        roundid = g.roundid,
    }
    room_logic.broadcast(data)

    -- 计算座位
    local seatid = get_seat(user.id)
    if seatid == nil then -- 如果没有座位则进行排座
        for i=1,seat_num do -- 玩家座位1-seat_num
            if g.seat[i] == nil then
                logic.someone_sit(i, user)
                break
            end
        end
    end
    LOG("some sit:", g.room_info.roomid, user.id, seatid)
    if user.seat == nil and not user.is_reboot then
        print("remove_one_reboot:", g.seat, seatid, user.is_reboot)
        g.game_logic.remove_one_reboot() -- 移除机器人
    end

    -- 发送房间内的其它人资料
    for k,v in pairs(g.seat) do -- 玩家座位1-seat_num
        local temp_user = g.users[v]
        assert(temp_user.seat ~= nil, v)
        local data = {
            msg_id = "someone_sit",
            uid = temp_user.id,
            seatid = temp_user.seat,
            infoData = room_logic.get_userinfo(temp_user),
            offline = temp_user.offline
        }
        send_msg(user.fd, data)
    end
end

-- 确实离开房间，不会再回来
function logic.post_leave(user)
    print("logic.post_leave", user.id, g.game_step)
    if user.fd ~= nil then
        g.conns[user.fd] = nil
        user.fd = nil
    end
    -- 如果游戏中，则不清空用户数据
    if g.game_step ~= Config.step_none and user.seat then
        user.offline = true
    else
        g.users[user.id] = nil
        logic.someone_stand(user)
        logic.someone_quit(user.id)
        local seat = user.seat
        user.seat = nil
        if seat then
            g.seat[seat] = nil
        end
    end
    if not user.is_robot then
        room_logic.leave_agent(user)
    else
        g.robot_user = g.robot_user - 1
    end
end

function logic.reconn(fd, id)
    -- 发送断线重连
    local self_cards = g.cards and g.cards[id]
    local res = {
        msg_id = "resume_game",
        state = g.game_step, -- 状态
        people = {},
        seat = g.seat,
        isGame = self_cards and 1 or 0,
        spType = self_cards and self_cards.spType or 0, -- 玩家自己是否特殊牌型
        cArr = self_cards and poker_utils.cardsEncode(self_cards.user_card) or nil,  -- 玩家自己的牌
        resumeTime = g.client_time or Config.auto_card_time-g.game_time,  -- 剩余时间
        ask_quit_time = g.ask_quit_time,
        banker = g.banker,

        round_score = g.round_score,

        -- state==5的时候才需要
        shootLen = {},
        swat = -1, -- 是否全垒打 
        cur_game_id = g.cur_game_id,

        more_card = g.more_card
    }
    if g.game_step == Config.step_compare and g.scores then
        res.swat = g.scores.all_swat
        res.shootLen = g.scores.shootLen
    elseif g.game_step == Config.step_none or g.game_step == Config.step_over then-- 上一把的牌数据
        res.pre_round_data = g.pre_round_data
        res.readys = room_logic.get_ready()
    end
    if g.cards then
        for k,v in pairs(g.cards) do
            local uid = k
            local user = g.users[uid]
            local optPoker = g.cur_cards and g.cur_cards[uid] and 1 or 0
            local item = {
                seatid = user.seat,
                optPoker = optPoker, -- 是否已经出牌
                isnotin = 1          -- 是否在打牌
            }
            if g.game_step == Config.step_compare then
                local cur_cards = g.cur_cards[uid]
                local t1,t2,t3,user_card
                if cur_cards.spType == nil then
                    t1 = cur_cards.cType[3]  -- 前面三张
                    t2 = cur_cards.cType[2]  -- 中间五张
                    t3 = cur_cards.cType[1]  -- 最后五张
                    user_card = cur_cards.cards
                else
                    user_card = v.user_card
                end
                item.spType = cur_cards.spType or 0
                item.t1 = t1
                item.t2 = t2
                item.t3 = t3
                item.arr = poker_utils.cardsEncode(user_card)
                item.scoreArr = g.scores and g.scores.datas[uid]
                item.left_card = cur_cards.left_card
            end
            table.insert(res.people, item)
        end
    end
    if g.ask_quit_time and g.ask_quit_time > 0 then
        res.agree_quit = {}
        for k,v in pairs(g.seat) do
            local user = g.users[v]
            res.agree_quit[v] = user.agree_quit
        end
    end
    send_msg(fd, res)
end

-----------------------------------------------------------------------


function logic.shuffle_card(card_num, max_count)
    local tempCard = {}
    -- type 1方块 2草花 3红心 4黑桃 
    -- value 1:2  13:A
    local add_heart = false
    local add_black = false
    if max_count >= 5 then
        add_black = true
    end
    if max_count == 6 then
        add_heart = true -- 红桃
    end
    if g.room_info.danse then
        for i=1,max_count do
            for j=1,13 do
                table.insert(tempCard, {type=4, value=j})
            end
        end
    else
        for i=1,4 do
            for j=1,13 do
                table.insert(tempCard, {type=i, value=j})
            end
            if add_black and i == 4 then
                for j=1,13 do
                    table.insert(tempCard, {type=i, value=j})
                end
            end
            if add_heart and i == 3 then
                for j=1,13 do
                    table.insert(tempCard, {type=i, value=j})
                end
            end
        end
        if g.room_info.variety then
            print("variety:", g.room_info.variety)
            table.insert(tempCard, {type=5, value=15})
            table.insert(tempCard, {type=5, value=16})
        end
    end
    local all_cards = {}
    -- 洗牌
    while #tempCard > 0 do
        local key = math.random(1,#tempCard)
        table.insert(all_cards, tempCard[key])
        tempCard[key],tempCard[#tempCard] = tempCard[#tempCard],tempCard[key]
        tempCard[#tempCard] = nil
    end

    return all_cards
end

--获取一张牌
function logic.getOneCard(cards)
	local obj = cards[#cards]
	cards[#cards] = nil
	return obj, #cards
end

function logic.room_deal_card()
    local max_card_num = g.room_info.card_num
    local room_type = g.room_type

    g.cards = {}
    local cards = logic.shuffle_card(max_card_num, g.room_info.max_count)
    print("room_deal_card:", room_type, g.room_info.variety)
    local cards_str = {}
    for k,v in pairs(g.seat) do
        if v > 0 then
            table.insert(cards_str, " user[")
            table.insert(cards_str, v)
            table.insert(cards_str, ",")
            table.insert(cards_str, k)
            table.insert(cards_str, "]={")
        	local user_card = {}
            for num = 1, max_card_num do
    			local obj = logic.getOneCard(cards)
    			table.insert(user_card, obj)

                table.insert(cards_str, "{type=")
                table.insert(cards_str, obj.type)
                table.insert(cards_str, ", value=")
                table.insert(cards_str, obj.value)
                table.insert(cards_str, "},")

                -- 开庄黑桃a
                if g.room_info.have_banker == 1 and obj.type == 4 and obj.value == 13 then
                    g.banker = v
                end
    		end
    	    table.insert(cards_str, "}")
      

            local spType, spCards = nil
            if max_card_num == 13 then
                -- if g.room_info.min_count == 2 then
                --     if Config.channel == "dyj" then -- 大赢家二人场可以报道
                --         spType, spCards = poker_utils.checkSpecial(user_card, g.room_info.danse, g.room_info.variety)
                --     end
                -- else
    	           spType, spCards = poker_utils.checkSpecial(user_card, g.room_info.danse, g.room_info.variety)
                -- end
            end
    	    table.insert(cards_str, " spType:")
            table.insert(cards_str, spType)
            if max_card_num == 17 or g.room_info.variety then
                g.more_card = cards
            end
            -- g.varietyC = varietyC
    		g.cards[v] = {
                user_card = user_card,
                spType = spType,
                spCards = spCards,
                seat = k
            }
        end
    end
    LOG(string.format("deal card ---> roomid:%d game_type:%d cur_game_id:%d card: %s", 
        g.room_info.roomid, g.room_type, 
        g.cur_game_id, table.concat( cards_str )))
end

function logic.someone_sit( seat, user )
    if seat then
        print("someone_sit:", seat, user.id)
        g.seat[seat] = user.id
        user.seat = seat
        local data = {
            msg_id = "someone_sit",
            uid = user.id,
            seatid = seat,
            infoData = room_logic.get_userinfo(user)
        }
        room_logic.broadcast(data)

        -- 如果游戏还没开始，则步骤时间清零
        if g.game_step == Config.step_none then
            g.game_time = 0
        end
    end
end

-- 有人退出房间
function logic.someone_quit(uid)
    local data = {
        msg_id = "someone_quit",
        uid = uid
    }
    room_logic.broadcast(data)
end

function logic.someone_stand(user)
    print("logic.someone_stand", user.id)
    -- 变成游客
    local seat = user.seat
    if seat then
        local data = {
            msg_id = "someone_stand",
            seat = seat,
            uid = user.id
        }

        g.seat[seat] = nil
        user.seat = nil
        room_logic.broadcast(data)
    end
end

function logic.remove_one_reboot()
    for k,v in pairs(g.users) do
        if v.is_robot then
            v.offline = true
            break
        end
    end
end

function logic.try_quit(user)
    print("try_quit", g.room_info.private, (g.game_step == Config.step_fee or g.game_step == step_deal_card))
    if not g.room_info.private then
        if (g.game_step == Config.step_fee or g.game_step == step_deal_card) and user.seat then -- 游戏中
            return true
        end
    else
        assert(false,"不应该走这个逻辑")
    end
    return false
end

return logic
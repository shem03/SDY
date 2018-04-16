
local skynet = require "skynet"
local poker_utils = require("poker.poker_utils")

local cmd = {}

-- 尝试站起(如果游戏已经开始，则不能站起)
function cmd.try_stand( user, data )
    print("g.game_step:", g.game_step)
    if g.game_step > Config.step_none and g.game_step ~= Config.step_over and g.cards[user.id] then
        data.msg_id = "stand_failed"
        send_msg(user.fd, data)
    else
        g.game_logic.someone_stand(user)
    end
end

-- 强制站起，如果游戏未开始，则走尝试站起，如果已经开始，则改为自动结算，还是会站起
function cmd.stand( user, data)
    g.game_logic.someone_stand(user)
end

function cmd.sit( user, data )
    local seatid = data.seatid
    if seatid<=0 or seatid>g.room_info.min_count then
        send_error(user.fd, -1, "坐位无效!")
        return
    end

    if g.seat[seatid] then
        send_error(user.fd, -1, "该位置已经有人!")
        return
    end

    -- if g.game_logic.check_coin(user.id) == false then
    --     send_error(user.fd, -1, "金币不足，不能坐下!")
    --     return
    -- end

    g.game_logic.someone_sit(seatid, user)
end

-- 换房
function cmd.change_room( user, data )
     if g.game_step > Config.step_none and user.seat then -- 游戏中
        g.game_logic.force_quit(user)
    end

    local data = {
        msg_id = "someone_quit",
        uid = user.id,
    }
    room_logic.broadcast(data)

    skynet.send(g.watchdog, "lua", "change_room", g.room_info.roomid, fd, user.id)
    g.game_logic.post_leave(user)
end
-- 提交牌型
function cmd.choice_poker_type( user, data )
    local cType = data.ctype
    local cArr = data.arr
    local sptype = data.sptype
    local variety_pos = data.variety_pos
    if sptype == nil and (cType == nil or #cType~=3 or cArr == nil) then
        send_error(user.fd, -1, "参数有错!")
        return
    end
    if sptype == 0 then
        sptype = nil
    end
    local user_cards = g.cards[user.id]
    if user_cards == nil then
        send_error(user.fd, -1, "玩家没有手牌!")
        return
    end

    if sptype~=nil and sptype ~= user_cards.spType then
        LOG_ERROR("检测到牌型异常玩家：", user.user_name, user.id)
        -- for k,v in pairs(g.users) do
            send_error(user.fd, -99, "检测到牌型异常玩家："..user.user_name)
        -- end
        -- for k,v in pairs(g.users) do
        --     send_error(v.fd, -99, "检测到牌型异常玩家："..user.user_name)
        -- end
        return
    end

    local cards = cArr and poker_utils.cardsDecode(cArr)
    if cards then -- 如果牌形是从大到小排，则转换一下
        local card1 = {cards[1], cards[2], cards[3], cards[4], cards[5]}
        local card2 = {cards[6], cards[7], cards[8], cards[9], cards[10]}
        local card3 = {cards[11], cards[12], cards[13]}
        table.sort(card1,poker_utils.sortDescent)
        table.sort(card2,poker_utils.sortDescent)
        table.sort(card3,poker_utils.sortDescent)
        cards = {}
        for k,v in pairs(card1) do
            table.insert(cards, v)
        end
        for k,v in pairs(card2) do
            table.insert(cards, v)
        end
        for k,v in pairs(card3) do
            table.insert(cards, v)
        end
        LOG("user_cards:", poker_utils.get_cardlog(cards))
    end
    
    -- 校验牌
    if not g.room_info.variety then
        local old_cards = user_cards.user_card
        local res_cards = poker_utils.delCards(cards, old_cards)
        if data.left_card then
            local left_card = poker_utils.cardsDecode(data.left_card)
            res_cards = poker_utils.delCards(res_cards, left_card)
        end
        if #res_cards > 0 then
            LOG_ERROR("检测到牌型异常玩家：", user.user_name, user.id)
            -- for k,v in pairs(g.users) do
                send_error(user.fd, -99, "检测到牌型异常玩家："..user.user_name)
            -- end
            -- for k,v in pairs(g.users) do
            --     send_error(v.fd, -99, "检测到牌型异常玩家："..user.user_name)
            -- end
            return
        end
    end

    -- 校验牌型
    if sptype == nil and poker_utils.check_pai_type(cards, cType) ~= true then
        LOG_ERROR("检测到牌型异常玩家：", user.user_name, user.id)
        -- for k,v in pairs(g.users) do
            send_error(user.fd, -99, "检测到牌型异常玩家："..user.user_name)
        -- end
        -- for k,v in pairs(g.users) do
            -- send_error(v.fd, -99, "检测到牌型异常玩家："..user.user_name)
        -- end
        return
    end

    g.cur_cards[user.id] = g.cur_cards[user.id] or {}
    g.cur_cards[user.id].spType = sptype
    g.cur_cards[user.id].cType = cType
    g.cur_cards[user.id].cards = cards
    g.cur_cards[user.id].left_card = data.left_card
    g.cur_cards[user.id].variety_pos = data.variety_pos

    local res = {
        msg_id = "is_right_poker_type",
        seatid = user.seat,
        state = 1
    }

    room_logic.broadcast(res)
end

-- 百变 点数位置
function cmd.happydogggy_sequence(user , data)
    local hparr = data.hpArr
    g.cur_cards[user.id] = g.cur_cards[user.id] or {}
    g.cur_cards[user.id].hparr = hparr
end

return cmd
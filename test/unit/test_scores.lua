local PokerUtils = require("server/logic/poker/poker_utils")


local function compare_score( from_card, to_card, from_uid, to_uid)
    local score_arr = {0,0,0,0,0,0,0}
    local total_score = 0
    local swat = true   -- 全赢
    local swated = true -- 全输
    for i=1,3 do
        local score_index = (4-i)*2 - 1
        local function add_score(com, jj) -- com 牌型
            score_arr[score_index] = score_arr[score_index] + 1*jj
            total_score = total_score + 1*jj
            local value = nil
            -- [乌龙1，对子2，两对3，三条4，顺子5，同花6，葫芦7，铁支8，同花顺9, 五同10 中墩葫芦13]
            if i == 3 and (com == 4 or com == 11 ) then -- 冲三
                value = 2
            elseif i == 2 and (com == 7 or com == 13) then -- 中墩葫芦
                value = 1
            elseif com == 8 and i == 2 then
                value = 7  -- 铁支中道
            elseif com == 8 and i == 1 then
                value = 3  -- 铁支尾道
            elseif com == 9 and i == 2 then
                value = 9  -- 同花顺中道
            elseif com == 9 and i == 1 then
                value = 4  -- 同花顺尾道
            elseif com == 10 and i == 2 then
                value = 19 -- 五同中道
            elseif com == 10 and i == 1 then
                value = 9  -- 五同尾道
            end
            if value then
                -- print("add value:", i, score_index, com)
                total_score = total_score + value*jj
                score_arr[score_index+1] = score_arr[score_index+1] + value*jj
            end
        end
        
        if from_card.cType[i] > to_card.cType[i] then
            add_score(from_card.cType[i], 1)
            swated = false
        elseif from_card.cType[i] < to_card.cType[i] then
            add_score(to_card.cType[i], -1)
            swat = false
        else -- 相等比牌的大小
            local card_type = from_card.cType[i]
            if card_type == 11 then -- 冲三需要改变
                card_type = 4
            end
            local fun = poker_utils.compare[card_type]
            if fun == nil then
                local cards = {}
                for k,v in pairs(from_card.cards) do
                    table.insert(cards, string.format("(type: %d value: %d)", v.type, v.value))
                end
                LOG_ERROR("poker_utils.compare no function:"..card_type, table.concat( cards, ", "))
            end
            LOG("compare fun:", i, card_type, from_uid, to_uid)
            local res = nil
            if i == 1 and fun then
                res = fun(1, from_card.cards, to_card.cards)
                -- from_cards_num = from_card.cards[1].value + from_card.cards[2].value + from_card.cards[3].value + from_card.cards[4].value + from_card.cards[5].value
                -- to_cards_num = to_card.cards[1].value + to_card.cards[2].value + to_card.cards[3].value + to_card.cards[4].value + to_card.cards[5].value
            elseif i == 2 and fun then
                res = fun(6, from_card.cards, to_card.cards)
                -- from_cards_num = from_card.cards[6].value + from_card.cards[7].value + from_card.cards[8].value + from_card.cards[9].value + from_card.cards[10].value
                -- to_cards_num = to_card.cards[6].value + to_card.cards[7].value + to_card.cards[8].value + to_card.cards[9].value + to_card.cards[10].value
            elseif i == 3 and fun then
                res = fun(11, from_card.cards, to_card.cards)
                -- from_cards_num = from_card.cards[11].value + from_card.cards[12].value + from_card.cards[13].value
                -- to_cards_num = to_card.cards[11].value + to_card.cards[12].value + to_card.cards[13].value
            end
        
            if res == true then
                add_score(from_card.cType[i], 1)
                swated = false
            elseif res == false then
                add_score(to_card.cType[i], -1)
                swat = false
            else
                swat = false
                swated = false
            end
        end
    end

    return score_arr,total_score,swat,swated
end

local function calculate_score(log)
    local datas = {}
    local total_scores = {}
    local shootLen = {}
    local totals = {}
    local all_swat = -1
    table.insert(log, "score[")
    for k,v in pairs(g.cur_cards) do
        local from_user = g.users[k]
        local user_scores = {}
        local total_score = 0
        local normalAdd = 0
        local specialAdd = 0
        local cur_swat = 1
        local temp_score = {} -- 记录和所有对家的分数
        if v.spType == nil then
            -- 计算分数,比较每一道
            local people_num = 0
            for kk,vv in pairs(g.cur_cards) do
                people_num = people_num + 1
                if kk ~= k and (not g.banker or (kk == g.banker or k == g.banker)) then
                    if vv.spType == nil then
                        local to_user_cards = g.cards[kk]
                        assert(to_user_cards ~= nil, kk)
                        local score_arr, cur_score, swat, swated  = compare_score(v, vv, k, kk)
                        if swat then
                            g.client_time = g.client_time + 2
                            table.insert(shootLen, {shooter=from_user.seat, shooted=to_user_cards.seat})
                            cur_score = cur_score * 2
                        else
                            cur_swat = -1
                        end
                        if swated then
                            cur_score = cur_score * 2
                        end
                        score_arr[7] = cur_score
                        total_score = total_score + cur_score
                        normalAdd = normalAdd + cur_score
                        user_scores[to_user_cards.seat] = score_arr
                        temp_score[to_user_cards.seat] = cur_score
                    else
                        local to_user_cards = g.cards[kk]
                        local cur_score = poker_utils.getSpecialScore(vv.spType)
                        total_score = total_score - cur_score
                        specialAdd = specialAdd - cur_score
                        local score_arr = {0,0,0,0,0,0,-cur_score}
                        user_scores[to_user_cards.seat] = score_arr
                    end
                end 
            end
            LOG("cur_swat:", k, cur_swat, g.room_info.min_count, people_num)
            if cur_swat == 1 and people_num == g.room_info.min_count and people_num >=3 and not g.banker then -- 全垒打,需要全赢了另外三人
                all_swat = from_user.seat
                total_score = total_score * 2
                for k,v in pairs(temp_score) do
                    user_scores[k][7] = user_scores[k][7]*2
                end
            end
        else
            g.client_time = g.client_time + 5
            -- 特殊牌型计算分数,只需要比较一次，下发总分
            for kk,vv in pairs(g.cur_cards) do
                if kk ~= k and (not g.banker or (kk == g.banker or k == g.banker)) then
                    local to_user_cards = g.cards[kk]
                    assert(to_user_cards ~= nil, kk)
                    local cur_score = 0
                    if not vv.spType then
                        cur_score = poker_utils.getSpecialScore(v.spType)
                        user_scores[to_user_cards.seat] = {0,0,0,0,0,0,cur_score}
                    else
                        if v.spType > vv.spType then
                            cur_score = poker_utils.getSpecialScore(v.spType)
                            user_scores[to_user_cards.seat] = {0,0,0,0,0,0,cur_score}
                        elseif v.spType < vv.spType then
                            cur_score = -poker_utils.getSpecialScore(v.spType)
                            user_scores[to_user_cards.seat] = {0,0,0,0,0,0,cur_score}
                        else
                            cur_score = 0
                            user_scores[to_user_cards.seat] = {0,0,0,0,0,0,cur_score}
                        end
                    end
                    total_score = total_score + cur_score
                    specialAdd = specialAdd + cur_score
                end
            end
        end
        table.insert(log, " user:")
        table.insert(log, k)
        table.insert(log, " seat:")
        for k,v in pairs(user_scores) do
            table.insert(log, k)
            table.insert(log, "(")
            table.insert(log, table.concat( v, ", "))
            table.insert(log, ")")
        end
        datas[k] = user_scores
        totals[k] = {
            total_score = total_score,
            specialAdd = specialAdd,
            normalAdd = normalAdd
        }
    end
    table.insert(log, "]")
    table.insert(log, " all_swat: ")
    table.insert(log, all_swat)
    g.scores = {
        datas = datas,
        shootLen = shootLen,
        all_swat = all_swat,
        totals = totals
    }
end
cmd.__calculate_score = calculate_score
-- 比牌
cmd[Config.step_compare] = function()
    if g.client_time == nil then
        -- 下发玩家的出牌数据
        local res = {
            msg_id = "compare_result",
            people = {},
            swat = -1,-- 全垒打
            shootLen = nil,
            people_num = 0,
            more_card = g.more_card,
        }
        g.client_time = 0
        local log_compare = {}
        for k,v in pairs(g.cards) do
            g.client_time = g.client_time + 2
            local cards = v
            local cur_cards = g.cur_cards[k]
            assert(cur_cards~=nil, "cur_cards == nil:"..k)
            local t1,t2,t3,user_card
            if cur_cards.spType == nil then
                t1 = cur_cards.cType[3]  -- 前面三张
                t2 = cur_cards.cType[2]  -- 中间五张
                t3 = cur_cards.cType[1]  -- 最后五张
                user_card = cur_cards.cards
            else
                user_card = cards.spCards or cards.user_card
            end
            local user_data = {
                seatid=v.seat,
                spType = cur_cards.spType or 0,
                t1 = t1,
                t2 = t2,
                t3 = t3,
                arr = poker_utils.cardsEncode(user_card),
                unpack_arr = user_card,
                left_card = cur_cards.left_card
            }

            table.insert(res.people, user_data)
            res.people_num = res.people_num + 1

            table.insert(log_compare, " user cardtype:[")
            table.insert(log_compare, k)
            table.insert(log_compare, ",")
            table.insert(log_compare, v.seat)
            table.insert(log_compare, "]={")
            table.insert(log_compare, t1)
            table.insert(log_compare, poker_utils.GroupName[t1])
            table.insert(log_compare, ",")
            table.insert(log_compare, t2)
            table.insert(log_compare, poker_utils.GroupName[t2])
            table.insert(log_compare, ",")
            table.insert(log_compare, t3)
            table.insert(log_compare, poker_utils.GroupName[t3])
            table.insert(log_compare, "}spType:")
            table.insert(log_compare, cur_cards.spType)
        end

        -- 计算分数
        calculate_score(log_compare)

        res.shootLen = g.scores.shootLen
        res.swat = g.scores.all_swat
        local swat_user_id = g.seat[res.swat]
        if res.swat ~= -1 then
            g.client_time = g.client_time + 2
            -- 全垒打，其它家的分数翻倍
            for k,v in pairs(g.scores.datas) do
                if swat_user_id ~= k then
                    local score = v[res.swat][7]
                    v[res.swat][7] = score * 2
                    local totals = g.scores.totals[k]
                    totals.total_score = totals.total_score + score
                    totals.normalAdd = totals.normalAdd + score
                end
            end
        end
        for k,v in pairs(g.users) do
            res.score_arr = g.scores.datas
            send_msg(v.fd, res)
        end

        g.pre_round_data = res

        -- 打日志
        LOG(string.format("compare card ---> roomid:%d game_type:%d game_id:%d card: %s", 
        g.room_info.roomid, g.room_type, 
        g.cur_game_id, table.concat( log_compare )))
    else
        if g.game_time < g.client_time then return end
        g.client_time = nil
        g.game_step = Config.step_over
        g.game_time = 0
    end
end






-------------------------------------------------------------------------------------------
function print_r ( t )  
    local print_r_cache={}
    local function sub_print_r(t,indent)
        if (print_r_cache[tostring(t)]) then
            print(indent.."*"..tostring(t))
        else
            print_r_cache[tostring(t)]=true
            if (type(t)=="table") then
                for pos,val in pairs(t) do
                    if (type(val)=="table") then
                        print(indent.."["..pos.."] => "..tostring(t).." {")
                        sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
                        print(indent..string.rep(" ",string.len(pos)+6).."}")
                    elseif (type(val)=="string") then
                        print(indent.."["..pos..'] => "'..val..'"')
                    else
                        print(indent.."["..pos.."] => "..tostring(val))
                    end
                end
            else
                print(indent..tostring(t))
            end
        end
    end
    if (type(t)=="table") then
        print(tostring(t).." {")
        sub_print_r(t,"  ")
        print("}")
    else
        sub_print_r(t,"  ")
    end
end
LOG_ERROR = print
LOG = print


-- card1 = PokerUtils.cardsDecode(ecode_card)
-- print_r(card1)

-- card2 = PokerUtils.cardsDecode(ecode_card)
-- print_r(card2)

-- card3 = PokerUtils.cardsDecode(ecode_card)
-- print_r(card3)

-- card4 = PokerUtils.cardsDecode(ecode_card)
-- print_r(card4)

g = {
    client_time = 0,
    room_info = {bet = 100},
    users = {
        [101] = {seat = 1, is_reboot = true},
        [102] = {seat = 2, is_reboot = true},
        -- [103] = {seat = 3, is_reboot = true},
        -- [104] = {seat = 4, is_reboot = true},
    },

    cards = {
        [101] = {seat = 1},
        [102] = {seat = 2},
        -- [103] = {seat = 3},
        -- [104] = {seat = 4},
    },
    -- 牌和类型反过来
    -- [乌龙1，对子2，两对3，三条4，顺子5，同花6，葫芦7，铁支8，同花顺9, 五同10 中墩葫芦13]

    cur_cards = {
        [101] = {cType={2, 2, 1}, cards={{type=4, value=5},{type=2, value=7},{type=2, value=3},{type=4, value=13},{type=1, value=13},{type=4, value=8},{type=2, value=13},{type=3, value=1},{type=4, value=10},{type=3, value=6},{type=1, value=11},{type=3, value=13},{type=1, value=5}}
                },

        [102] = {cType={6, 3, 1}, cards= {{type=2, value=4},{type=1, value=1},{type=4, value=6},{type=2, value=8},{type=4, value=9},{type=2, value=6},{type=2, value=10},{type=4, value=11},{type=4, value=2},{type=2, value=5},{type=2, value=9},{type=3, value=10},{type=3, value=11}}

                },

        -- [103] = {cType={7, 3, 1}, cards= {{type=2, value=12},{type=1, value=3},{type=3, value=5},{type=2, value=2},{type=4, value=3},{type=3, value=3},{type=1, value=12},{type=3, value=9},{type=4, value=7},{type=1, value=10},{type=1, value=2},{type=3, value=4},{type=3, value=2}}

        --         },

        -- [104] = {cType={7, 6, 1}, cards= {{type=1, value=4},{type=4, value=4},{type=1, value=6},{type=4, value=12},{type=4, value=1},{type=1, value=8},{type=1, value=9},{type=2, value=11},{type=3, value=12},{type=2, value=1},{type=3, value=7},{type=1, value=7},{type=3, value=8}}

        --         },
    }
}

g.cur_cards[101].cards = card1
g.cur_cards[102].cards = card2
-- g.cur_cards[103].cards = card3
-- g.cur_cards[104].cards = card4
calculate_score()
print_r(g.scores)
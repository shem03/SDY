local poker_utils = require("server/logic/poker/poker_utils")

local card1 = {{type= 4 , value= 6 }, {type= 4 , value= 7 }, {type= 4 , value= 8 }, {type= 4 , value= 9 }, {type= 4 , value= 10 }, {type= 4 , value= 2 }, {type= 4 , value= 2 }, {type= 4 , value= 4 }, {type= 4 , value= 5 }, {type= 4 , value= 5 }, {type= 4 , value= 6 }, {type= 4 , value= 12 }, {type= 4 , value= 12 }} 

local card2 = {{type= 4 , value= 1 }, {type= 4 , value= 3 }, {type= 4 , value= 3 }, {type= 4 , value= 3 }, {type= 4 , value= 3 }, {type= 4 , value= 4 }, {type= 4 , value= 5 }, {type= 4 , value= 6 }, {type= 4 , value= 7 }, {type= 4 , value= 8 }, {type= 4 , value= 9 }, {type= 4 , value= 11 }, {type= 4 , value= 12 }}

Config = {channel='xzj'}
g = {
    client_time = 0,
    room_info = {bet = 100, danse=true},
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
        [101] = {cType={9, 6, 2}, cards=card1},

        [102] = {cType={8, 9, 1}, cards=card2},

        -- [103] = {cType={7, 3, 1}, cards= {{type=2, value=12},{type=1, value=3},{type=3, value=5},{type=2, value=2},{type=4, value=3},{type=3, value=3},{type=1, value=12},{type=3, value=9},{type=4, value=7},{type=1, value=10},{type=1, value=2},{type=3, value=4},{type=3, value=2}}

        --         },

        -- [104] = {cType={7, 6, 1}, cards= {{type=1, value=4},{type=4, value=4},{type=1, value=6},{type=4, value=12},{type=4, value=1},{type=1, value=8},{type=1, value=9},{type=2, value=11},{type=3, value=12},{type=2, value=1},{type=3, value=7},{type=1, value=7},{type=3, value=8}}

        --         },
    }
}

g.cur_cards[101].cards = card1
g.cur_cards[102].cards = card2


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
            local value = poker_utils.getNomalScore(i, com, g.room_info.danse)
            
            if value then
                -- print("add value:", i, score_index, com)
                total_score = total_score + value*jj
                score_arr[score_index+1] = score_arr[score_index+1] + value*jj
            end
        end
        print("cType", from_card.cType[i], to_card.cType[i])
        if from_card.cType[i] ~= to_card.cType[i] then
            if g.room_info.danse then -- 清一色，铁支比同花顺大
                local type1 = from_card.cType[i]
                local type2 = to_card.cType[i]
                print("type1:", type1, type2)
                if type1 == 8 then
                    type1 = 9
                elseif type1 == 9 then
                    type1 = 8
                end
                if type2 == 8 then
                    type2 = 9
                elseif type2 == 9 then
                    type2 = 8
                end
                print("type2:", type1, type2)
                if type1 > type2 then
                    add_score(from_card.cType[i], 1)
                    swated = false
                elseif type1 < type2 then
                    add_score(to_card.cType[i], -1)
                    swat = false
                end
            else
                if from_card.cType[i] > to_card.cType[i] then
                    add_score(from_card.cType[i], 1)
                    swated = false
                elseif from_card.cType[i] < to_card.cType[i] then
                    add_score(to_card.cType[i], -1)
                    swat = false
                end 
            end
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
LOG = print
LOG_ERROR = print

local score_arr,total_score,swat,swated = compare_score(g.cur_cards[101], g.cur_cards[102])
for k,v in pairs(score_arr) do
	print("score_arr", k,v)
end
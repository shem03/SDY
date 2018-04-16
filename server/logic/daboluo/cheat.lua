-- 作弊使用
local poker_utils = require("daboluo.poker_utils")

local cmd = {}

local function check_best(cards)
	-- 优先判断是否有特殊牌形
	if #cards == 13 then
        local spType, spCards = nil
        -- if g.room_info.min_count == 2 then
        --     if Config.channel == "dyj" then -- 大赢家二人场可以报道
        --         spType, spCards = poker_utils.checkSpecial(cards, g.room_info.danse, g.room_info.variety)
        --     end
        -- else
           spType, spCards = poker_utils.checkSpecial(cards, g.room_info.danse, g.room_info.variety)
        -- end
        if spType then
       		return -spType, spCards
        end
    end
	local run_result, name_list = poker_utils.happydoggyGroupCards(cards, g.varietyC, g.room_info.danse)
    if #name_list == 0 then
        LOG_ERROR("name_list len is nil in cheat", g.cheat, poker_utils.get_cardlog( cards ))
    end
	-- 取前三个进行择优
	local quanzhong = 10
    local one = name_list[1][1]*quanzhong*1.1 + name_list[1][2]*quanzhong + name_list[1][3]*quanzhong*0.8
    	+ (14-run_result[1][5].value) + (14-run_result[1][10].value) + (14-run_result[1][13].value)
    local two = 999999
    local three = 999999
    if name_list[2] then
        two = name_list[2][1]*quanzhong*1.1 + name_list[2][2]*quanzhong + name_list[2][3]*quanzhong*0.8
        + (14-run_result[2][5].value) + (14-run_result[2][10].value) + (14-run_result[2][13].value)
    end
    if name_list[3] then
        three = name_list[3][1]*quanzhong*1.1 + name_list[3][2]*quanzhong + name_list[3][3]*quanzhong*0.8
        + (14-run_result[3][5].value) + (14-run_result[3][10].value) + (14-run_result[3][13].value)
    end
    LOG("check_best:", one, two, three, 
    	poker_utils.GroupName[11-name_list[1][1]], poker_utils.GroupName[11-name_list[1][2]], 
    	poker_utils.GroupName[name_list[1][3]==1 and 4 or name_list[1][3]==3 and 1 or 2])
    if two <= one and two <= three then
        name_list[1] = name_list[2]
        run_result[1] = run_result[2]
        return two
    elseif three <= one and three <= two then
        name_list[1] = name_list[3]
        run_result[1] = run_result[3]
        return three
    end

    return one
end

function cmd.room_deal_cheat()
    local max_card_num = g.room_info.card_num
    local room_type = g.room_type

    g.cards = {}
    local cards = g.game_logic.shuffle_card(max_card_num, g.room_info.max_count)

    -- 生成牌形
    local s_cards = {}
    for k,v in pairs(g.seat) do
    	local user_card = {}
        for num = 1, max_card_num do
			local obj = g.game_logic.getOneCard(cards)
			table.insert(user_card, obj)
		end
		local value, cards = check_best(user_card)
		local data = {
			cards = cards or user_card,
			value = value
		}
		table.insert(s_cards, data)
    end
    -- 从小到大排序
    table.sort(s_cards,function(x,y) return x.value < y.value end)

    local cards_str = {}
    for k,v in pairs(g.seat) do
        if v > 0 then
            table.insert(cards_str, " user[")
            table.insert(cards_str, v)
            table.insert(cards_str, ",")
            table.insert(cards_str, k)
            table.insert(cards_str, "]={")
            
            local card_data = nil
            if v == g.cheat then
            	card_data = table.remove(s_cards, 1)
        	else
        		card_data = table.remove(s_cards, #s_cards)
        	end
        	LOG("user cheat:", v, card_data.value)
        	local user_card = card_data.cards
            for num = 1, max_card_num do
    			local obj = user_card[num]

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
            if card_data.value < 0 then
    	       spType, spCards = -card_data.value, card_data.cards
            end
    	    table.insert(cards_str, " spType:")
            table.insert(cards_str, spType)
            if max_card_num == 17 then
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
    LOG(string.format("deal cheat card ---> roomid:%d game_type:%d cur_game_id:%d card: %s", 
        g.room_info.roomid, g.room_type, 
        g.cur_game_id, table.concat( cards_str )))
end

return cmd
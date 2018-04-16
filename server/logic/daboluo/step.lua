local skynet = require "skynet"
local _user = require("user.core")

local poker_utils = require("daboluo.poker_utils")
local cheat = require("daboluo.cheat")
local test_card = require("daboluo.test_card")
local cmd = {}

local function game_over()
    -- 清空上局数据
    g.varietyC = nil
    g.cards = nil
    g.cur_cards = nil
    g.scores = nil

    -- 更新状态
    g.game_step = Config_daboluo.step_none
    g.game_time = 0
    g.cur_game_id = 0
    print("----------->game over")

    --print("---------------g.users===========",g.users)
    -- 清空已经断线的玩家, 私人房不清退
    local all_robot = false
    if g.room_info.private == false then
        all_robot = true
        for k,v in pairs(g.users) do
            -- print("v:", v.offline, v.id)
            if v.offline then
                g.game_logic.post_leave(v)
            end
            if not v.is_robot then
                all_robot = false
            end
        end
    end

    -- ！！重要,所有游戏回合都需要调用
    room_logic.game_over()
    if all_robot then
        LOG_ERROR("all_robot room:", g.room_info.roomid, g.room_info.owner)
        skynet.send(g.watchdog, "lua", "force_quit_room", g.room_info.roomid, skynet.self())
    end
    --[[
    --判断是否有新玩家进入房间
    if g.new_gamer[1] ~= nil then
        local seatid = g.game_logic.remove_one_robot() -- 移除机器人
        g.game_logic.someone_sit(seatid, g.new_gamer[1])
        g.new_gamer[1] = nil
    end
    ]]
end

local function game_start()
    if room_logic.game_start then
        room_logic.game_start()
    end
    --[[
    if g.room_info.room_coin > 0 then
        for i,v in ipairs(g.seat) do
            local user = g.users[v]
            if not user.is_robot then
                -- 收取金币10作为手续费
                -- cxz 扣钱屏蔽
                --if room_logic.user_update_coin(user, -Config_daboluo.table_fee) == false then
             --   assert(false, "手续费金币不足:"..user.id)
               -- end

                send_msg(user.fd, {
                    msg_id="update_bee", 
                    cur_coin=user.user_coin or 0
                })
            end
        end
    end ]]
   
    g.game_time = 0
    g.game_step = Config_daboluo.step_skip  --99
    g.cur_game_id = math.floor(skynet.time())
    g.round = g.round + 1

    --房间理牌并分牌
    if g.cheat then
        cheat.room_deal_cheat()
    else
        g.game_logic.room_deal_card()
        -- test_card.room_deal_test()
    end

    -- 开局
    local data = {
        msg_id = "take_table_start",
        banker = g.banker
    }
    room_logic.broadcast(data)

end

function cmd.run()
    --print("------------g.real_user, g.robot_user,g.game_step============",g.real_user, g.robot_user,g.game_step)
    if Config_daboluo.robot and g.room_info.private == false then -- 如果私人场，则不添加机器人
        if g.real_user + g.robot_user < g.room_info.min_count and g.game_logic.add_robot and g.game_step == Config_daboluo.step_none then
            g.game_logic.add_robot()
        end
    end

	g.game_time = g.game_time + 1
    if g.game_step > Config_daboluo.step_none then -- 游戏已经开始
        -- -- 如果玩家都离线了，则通知解散房间
        -- if g.all_offline then
        --     game_over()
        --     for k,v in pairs(g.users) do
        --         g.game_logic.post_leave(v)
        --     end
        --     return
        -- end
        local cur_step_fun = cmd[g.game_step]
        assert(cur_step_fun ~= nil, "daboluo:runerr=====g.game_step:"..g.game_step)
        cur_step_fun()
    else
    	if g.game_time > 1 and room_logic.check_ready() then -- 1秒后开局
	        -- 如果玩家大于两个且至少一个为真实玩家，则开始发牌
	        local count = 0
	        for k,v in pairs(g.seat) do
	            count = count + 1
	        end
	        if (count > 1) and (g.real_user>0) then
	            game_start()
	        end
	    end
    end
end

-- 开局跳过扣费
cmd[Config_daboluo.step_skip] = function()
    if g.game_time < 2 then
        return
    end
    
    g.game_step = Config_daboluo.step_deal_card
    g.cur_cards = {}
    g.game_time = 0
    local data = {
        msg_id = "round_start",
        spType = 0,
        cards = nil,
        cur_game_id = g.cur_game_id,
    }
    for k,v in pairs(g.cards) do
        local user = g.users[k]
        data.spType = v.spType
        data.cards = poker_utils.cardsEncode(v.user_card)
        -- data.real_cards = v.user_card
        send_msg(user.fd, data)
    end

    --将分到的牌发给客户端
    data = {
        msg_id = "choice_poker_types"
    }
    room_logic.broadcast(data)
end

-- 自动出牌
local function choice_poker_auto(user)
	local cards = g.cards[user.id]
    if cards.spType then
        g.cur_cards[user.id] = {spType=cards.spType}
    else
        assert(cards.user_card ~= nil)
        -- [乌龙1，对子2，两对3，三条4，顺子5，同花6，葫芦7，铁支8，同花顺9, 五同10 中墩葫芦13]
        local run_result, name_list = poker_utils.happydoggyGroupCards(cards.user_card, g.varietyC, g.room_info.danse)
        if #name_list == 0 then
            LOG_ERROR("name_list len is nil:", user.id, user.seat)
        end
        -- 取前三个进行择优
        local one = name_list[1][1] + name_list[1][2] + name_list[1][3]
        local two = 99
        local three = 99
        if name_list[2] then
            two = name_list[2][1] + name_list[2][2] + name_list[2][3]
        end
        if name_list[3] then
            three = name_list[3][1] + name_list[3][2] + name_list[3][3]
        end
        if two < one and two < three then
            name_list[1] = name_list[2]
            run_result[1] = run_result[2]
        elseif three < one and three < two then
            name_list[1] = name_list[3]
            run_result[1] = run_result[3]
        end
        
	    name_list[1][1] = 11 - name_list[1][1]
	    name_list[1][2] = 11 - name_list[1][2]
	    name_list[1][3] = name_list[1][3] == 1 and 4 or name_list[1][3] == 3 and 1 or 2

        local temp = run_result[1]
        
        local temp_arr = nil
        if g.room_info.variety then
            temp_arr = poker_utils.getVarietyPos(temp)
            if #temp_arr > 0 then
                print("temp_arr:", user.id, temp_arr)
            end
        end
        if name_list[1][3] == 11 then -- 冲三转换
            name_list[1][3] = 4
        end
        if name_list[1][2] == 13 then -- 中墩葫芦
            name_list[1][2] = 7
        end
        
        -- 清一色，顺子和铁支需要换回来
        if g.room_info.danse then
            if name_list[1][2] == 9 then
                name_list[1][2] = 8
            elseif name_list[1][2] == 8 then
                name_list[1][2] = 9
            end
            if name_list[1][1] == 9 then
                name_list[1][1] = 8
            elseif name_list[1][1] == 8 then
                name_list[1][1] = 9
            end
        end

        local left_card = nil
        if g.room_info.card_num > 13 then
            left_card = poker_utils.delCards(cards.user_card, temp)
        end
	    g.cur_cards[user.id] = {
	    	cType = name_list[1],
	    	cards = temp,
            variety_pos = temp_arr,
            left_card = left_card and poker_utils.cardsEncode(left_card)
		}

		-- print("name_list[1]:", name_list)
		-- print("run_result[1]:", run_result)
	end
    local res = {
        msg_id = "is_right_poker_type",
        seatid = user.seat,
        state = 1
    }
    room_logic.broadcast(res)
end

-- 出牌阶段
cmd[Config_daboluo.step_deal_card] = function ()
	-- 判断如果其它全是机器人，则机器人进行牌的计算并下发
	local has_nil = false   --是否全部出牌完毕
    for k,v in pairs(g.cards) do
        local user = g.users[k]
            assert(user.id~=nil, "error: user.id is nil")
        --if not g.room_info.private then -- 私人房不自动出牌  -- 大赢家私人自动出牌
            if user.is_robot and g.cur_cards[user.id] == nil then
                local r = math.random(1, 3)
                if r == 1 then
                    choice_poker_auto(user)
                    return
                end
            end
            if g.cur_cards[k] == nil and g.game_time > Config_daboluo.auto_card_time then
                -- 玩家超过auto_card_time秒没出牌，则自动出牌
                choice_poker_auto(user)
                return
            end
        --end

        if g.cur_cards[k] == nil then
        	has_nil = true
        end
    end

    if has_nil == false then
	    -- 如果全部出牌完毕，则进行比牌
	    g.game_step = Config_daboluo.step_compare
	    g.game_time = 0
	end
end

--比较两人牌型积分
local function compare_score( from_card, to_card, from_uid, to_uid)
    local score_arr = {0,0,0,0,0,0,0}
    local total_score = 0
    local swat = true   -- 全赢
    local swated = true -- 全输
    for i=1,3 do    --1底道 2中道 3头道
        local score_index = (4-i)*2 - 1
        local function add_score(cards, com, jj) -- com 牌型, cards 具体牌
            score_arr[score_index] = score_arr[score_index] + 1*jj   --填index=5,3,1
            total_score = total_score + 1*jj
            local value = poker_utils.getNomalScore(i, com, g.room_info.danse, cards)
            
            if value then
                -- print("add value:", i, score_index, com)
                total_score = total_score + value*jj
                score_arr[score_index+1] = score_arr[score_index+1] + value*jj --填index=6,4,2
            end
        end
        
        if from_card.cType[i] ~= to_card.cType[i] then   -- 不同牌型比牌的大小
            if g.room_info.danse then -- 清一色，铁支比同花顺大
                local type1 = from_card.cType[i]
                local type2 = to_card.cType[i]
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
                if type1 > type2 then
                    add_score(from_card.cType[i], 1)
                    swated = false
                elseif type1 < type2 then
                    add_score(to_card.cType[i], -1)
                    swat = false
                end
            else
                if from_card.cType[i] > to_card.cType[i] then
                    add_score(from_card.cards,from_card.cType[i], 1)
                    swated = false
                elseif from_card.cType[i] < to_card.cType[i] then
                    add_score(to_card.cards,to_card.cType[i], -1)
                    swat = false
                end 
            end
        else -- 相等牌型比牌的大小
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
            if i == 1 and fun then   --底道 1-5
                res = fun(1, from_card.cards, to_card.cards)
                -- from_cards_num = from_card.cards[1].value + from_card.cards[2].value + from_card.cards[3].value + from_card.cards[4].value + from_card.cards[5].value
                -- to_cards_num = to_card.cards[1].value + to_card.cards[2].value + to_card.cards[3].value + to_card.cards[4].value + to_card.cards[5].value
            elseif i == 2 and fun then  --中道 6-10
                res = fun(6, from_card.cards, to_card.cards)
                -- from_cards_num = from_card.cards[6].value + from_card.cards[7].value + from_card.cards[8].value + from_card.cards[9].value + from_card.cards[10].value
                -- to_cards_num = to_card.cards[6].value + to_card.cards[7].value + to_card.cards[8].value + to_card.cards[9].value + to_card.cards[10].value
            elseif i == 3 and fun then  --头道 11-13
                res = fun(11, from_card.cards, to_card.cards)
                -- from_cards_num = from_card.cards[11].value + from_card.cards[12].value + from_card.cards[13].value
                -- to_cards_num = to_card.cards[11].value + to_card.cards[12].value + to_card.cards[13].value
            end
        
            if res == true then    --from_card大
                add_score(from_card.cards,from_card.cType[i], 1)
                swated = false
            elseif res == false then   --to_card大
                add_score(to_card.cards,to_card.cType[i], -1)
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
    --local total_scores = {}
    local shootLen = {}
    local totals = {}
    local all_swat = -1   --全垒打桌号（全垒打，即全赢了其余所有人）
    table.insert(log, "score[")
    for k,v in pairs(g.cur_cards) do
        local from_user = g.users[k]
		local user_scores = {}
        local total_score = 0
        local normalAdd = 0
        local specialAdd = 0
        local cur_swat = 1    --全胜其余人
        local single_swat = 0   --全胜其他人数  1:全胜1个，2：全胜2个
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
                        local score_arr, cur_score, swat, swated  = compare_score(v, vv, k, kk)    --比较两人牌型，计算三道总得分
                        if swat then
                            g.client_time = g.client_time + 2
                            table.insert(shootLen, {shooter=from_user.seat, shooted=to_user_cards.seat})
                            --cur_score = cur_score * 2
                            cur_score = cur_score + 3   --全胜+3
                            single_swat = single_swat + 1
                            LOG("**********single_swat:k,kk,single_swat=============================", k, kk, single_swat)
                        else
                            cur_swat = -1
                        end
                        if swated then
                            --cur_score = cur_score * 2
                            cur_score = cur_score - 3   --被全胜-3
                        end
                        score_arr[7] = cur_score
                        total_score = total_score + cur_score
                        normalAdd = normalAdd + cur_score
                        user_scores[to_user_cards.seat] = score_arr
                        temp_score[to_user_cards.seat] = cur_score
                    else
                        cur_swat = -1 -- 有特殊牌不能全垒打
                        local to_user_cards = g.cards[kk]
                        local cur_score = poker_utils.getSpecialScore_small(vv.spType)
                        total_score = total_score - cur_score
                        specialAdd = specialAdd - cur_score
                        local score_arr = {0,0,0,0,0,0,-cur_score}
                        user_scores[to_user_cards.seat] = score_arr
                    end
                end
            end
            --LOG("cur_swat:k,cur_swat,min_count,people_num===========================", k, cur_swat, g.room_info.min_count, people_num)

            --全垒打
            if cur_swat == 1 and people_num == g.room_info.min_count and people_num >=3 and not g.banker then
                all_swat = from_user.seat
                --[[
                total_score = total_score * 2
                for k,v in pairs(temp_score) do
                    user_scores[k][7] = user_scores[k][7]*2
                end]]
            end

        else   -- 特殊牌型计分
            g.client_time = g.client_time + 5
            -- 特殊牌型计算分数,只需要比较一次，下发总分
            for kk,vv in pairs(g.cur_cards) do
                if kk ~= k and (not g.banker or (kk == g.banker or k == g.banker)) then
                    local to_user_cards = g.cards[kk]
                    assert(to_user_cards ~= nil, kk)
                    local cur_score = 0
                    if not vv.spType then
                        cur_score = poker_utils.getSpecialScore_small(v.spType)
                        user_scores[to_user_cards.seat] = {0,0,0,0,0,0,cur_score}
                    else
                        -- 大赢家要求，只比一条龙和清龙
                        if v.spType == vv.spType then
                            if v.spType < 0 then
                                -- 判断六同的大小
                                local rec = 1
                                local v_1 = PokerUtils.get_liutong_value(v.user_card)
                                local v_2 = PokerUtils.get_liutong_value(to_user_cards.user_card)
                                if v_1 and v_2 and v_1 < v_2 then
                                    rec = -1
                                end

                                cur_score = rec*poker_utils.getSpecialScore_small(v.spType)
                                user_scores[to_user_cards.seat] = {0,0,0,0,0,0,cur_score}
                            else
                                cur_score = 0
                                user_scores[to_user_cards.seat] = {0,0,0,0,0,0,cur_score}
                            end
                        else
                            if v.spType>=12 and v.spType > vv.spType then -- 13 清一色 12 一条龙
                                cur_score = poker_utils.getSpecialScore_small(v.spType)
                                user_scores[to_user_cards.seat] = {0,0,0,0,0,0,cur_score}
                            elseif v.spType>0 and vv.spType<0 then
                                cur_score = 0 - poker_utils.getSpecialScore_small(vv.spType)
                                user_scores[to_user_cards.seat] = {0,0,0,0,0,0,cur_score}
                            elseif v.spType<0 and v.spType<vv.spType then
                                cur_score = poker_utils.getSpecialScore_small(v.spType)
                                user_scores[to_user_cards.seat] = {0,0,0,0,0,0,cur_score}
                            elseif vv.spType >=12 and vv.spType > v.spType then
                                cur_score = 0 - poker_utils.getSpecialScore_small(vv.spType)
                                user_scores[to_user_cards.seat] = {0,0,0,0,0,0,cur_score}
                            elseif vv.spType>0 and v.spType<0 then
                                cur_score = poker_utils.getSpecialScore_small(v.spType)
                                user_scores[to_user_cards.seat] = {0,0,0,0,0,0,cur_score}
                            elseif vv.spType<0 and vv.spType<v.spType then
                                cur_score = 0 - poker_utils.getSpecialScore_small(vv.spType)
                                user_scores[to_user_cards.seat] = {0,0,0,0,0,0,cur_score}
                            else
                                cur_score = 0
                                user_scores[to_user_cards.seat] = {0,0,0,0,0,0,cur_score}
                            end
                        end
                    end
                    total_score = total_score + cur_score
                    specialAdd = specialAdd + cur_score
                end
            end
        end
        --写日志
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
    --print("g.scores==================", g.scores)
end
cmd.__calculate_score = calculate_score

-- 比牌
cmd[Config_daboluo.step_compare] = function()
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
        local log_compare = {}  --记录所有人的选牌
        for k,v in pairs(g.cards) do
            g.client_time = g.client_time + 1
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
                -- unpack_arr = user_card,
                left_card = cur_cards.left_card,
                variety_pos = cur_cards.variety_pos
        	}
            local pos_str = ""
            if cur_cards.variety_pos then
                for k,v in pairs(cur_cards.variety_pos) do
                    pos_str = "(pos:"..v[1]..", v:"..v[2]..")"
                end
            end
        	table.insert(res.people, user_data)
        	res.people_num = res.people_num + 1
            table.insert(log_compare, "  cards:")
            table.insert(log_compare, poker_utils.get_cardlog(user_card))
            table.insert(log_compare, pos_str)
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

            if cur_cards.left_card then
                local left_card = poker_utils.cardsDecode(cur_cards.left_card)
                table.insert(log_compare, " left_card:")
                table.insert(log_compare, poker_utils.get_cardlog(left_card))
            end
        end

        -- 计算分数
        calculate_score(log_compare)

        res.shootLen = g.scores.shootLen
        res.swat = g.scores.all_swat
        --[[
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
        end]]
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
        g.game_step = Config_daboluo.step_over
        g.game_time = 0
    end

    -- cxz 更新金币先注释
    --[[
    for k,v in pairs(g.cards) do
        local score_totals = g.scores.totals[k]
        local coin = 0
        if g.room_info.room_coin > 0 then
            local user = g.users[k]
            coin = score_totals.total_score * g.room_info.room_coin -- 根据分数计算money
            -- 用户更新金币
            
            if user and not user.is_robot and not user.force_quit then
                --room_logic.user_update_coin(user, coin)
            end
        end
    end]]
end

-- 结束并结算
cmd[Config_daboluo.step_over] = function()
    if g.game_time == 1 then
        local res = {
            msg_id = "the_last_result",
            people = {}
        }

        local cur_scores = {}
        g.round_score[g.round] = cur_scores
        -- 结算金币,暂时不考虑数据一致性
        for k,v in pairs(g.cards) do
    	    local score_totals = g.scores.totals[k]
    	    local coin = 0
    	    if g.room_info.room_coin > 0 then
                coin = score_totals.total_score * g.room_info.room_coin -- 根据分数计算money
            end

            local cards = v
            local cur_cards = g.cur_cards[k]
            local user_card
            if cur_cards.spType == nil then
                user_card = cur_cards.cards
            else
                user_card = cards.spCards or cards.user_card
            end

            if g.room_info.private then
                cur_scores[k] = score_totals.total_score
            end

            local item = {
                uid = k,
                normalAdd = score_totals.normalAdd,
                specialAdd = score_totals.specialAdd,
                totalScore = score_totals.total_score,
                coin = coin,
                arr = poker_utils.cardsEncode(user_card),
            }
            table.insert(res.people, item)
        end

        room_logic.broadcast(res)
        return
    end
    if g.room_info.private then
        game_over()
    end
    if g.game_time > 6 and not g.room_info.private then
        game_over()
    end
end

return cmd
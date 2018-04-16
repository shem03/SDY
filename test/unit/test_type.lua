local PokerUtils = require("server/logic/poker/poker_utils")
-- local card = {{type=1, value=13},{type=4, value=13},{type=2, value=12},{type=4, value=12},{type=1, value=7},
-- 				{type=2, value=7},{type=1, value=6},{type=1, value=6},{type=3, value=6},
-- 				{type=1, value=6},{type=4, value=3},{type=2, value=3},{type=3, value=1}}
-- 三同花
--local card = {{type=4, value=10},{type=4, value=12},{type=2, value=12},{type=4, value=2},{type=2, value=8},{type=4, value=11},{type=4, value=8},{type=4, value=9},{type=4, value=1},{type=4, value=1},{type=2, value=9},{type=4, value=6},{type=4, value=10},}

--[7fc][INFO_ 2017-08-26 20:37:34]: ./server/logic/poker/logic.lua 289 deal card ---> roomid:101139 game_type:1 cur_game_id:1503751054 card:  
--user[101843,1]={{type=4, value=3},{type=3, value=9},{type=3, value=11},{type=4, value=6},{type=4, value=10},{type=3, value=11},{type=4, value=5},{type=2, value=6},{type=3, value=7},{type=3, value=1},{type=4, value=9},{type=3, value=9},{type=4, value=8},} spType: 
local card = {{type=4, value=13},{type=4, value=4},{type=4, value=1},{type=2, value=11},{type=4, value=4},{type=3, value=4},{type=3, value=7},{type=4, value=11},{type=3, value=4},{type=4, value=1},{type=2, value=13},{type=1, value=7},{type=1, value=4},}
--user[101837,3]={{type=4, value=12},{type=3, value=13},{type=2, value=5},{type=2, value=12},{type=1, value=12},{type=4, value=10},{type=3, value=8},{type=3, value=5},{type=3, value=12},{type=4, value=7},{type=4, value=9},{type=1, value=2},{type=3, value=2},} spType: 
--user[101782,4]={{type=2, value=7},{type=3, value=12},{type=2, value=2},{type=1, value=5},{type=2, value=9},{type=4, value=2},{type=2, value=4},{type=1, value=11},{type=4, value=2},{type=4, value=5},{type=1, value=6},{type=2, value=1},{type=4, value=8},} spType: 
--user[101780,5]={{type=3, value=13},{type=3, value=8},{type=4, value=7},{type=1, value=13},{type=3, value=5},{type=3, value=10},{type=3, value=1},{type=4, value=12},{type=1, value=10},{type=3, value=6},{type=2, value=3},{type=3, value=10},{type=1, value=8},} spType: 
--user[102213,6]={{type=2, value=10},{type=4, value=11},{type=1, value=3},{type=4, value=13},{type=3, value=3},{type=3, value=2},{type=3, value=6},{type=1, value=1},{type=4, value=3},{type=2, value=8},{type=3, value=3},{type=4, value=6},{type=1, value=9},} spType:


-- [乌龙1，对子2，两对3，三条4，顺子5，同花6，葫芦7，铁支8，同花顺9, 五同10 中墩葫芦13]
-- local run_result, name_list = PokerUtils.happydoggyGroupCards(card)

-- for k,v in pairs(name_list) do
-- 	print("type:", 11-v[1], 11-v[2], v[3] == 1 and 11 or v[3] == 3 and 1 or 2)
-- end

-- for k,v in pairs(run_result[2]) do
-- 	print("run_result:", v.type, v.value)
-- end
print(PokerUtils.checkSpecial_small(card))
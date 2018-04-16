local PokerUtils = require("server/logic/poker/poker_utils")
local card1 = {{type=3, value=3},{type=4, value=4},{type=1, value=12},{type=2, value=2},{type=4, value=6},{type=1, value=2},{type=2, value=1},{type=3, value=11},{type=4, value=11},{type=1, value=7},{type=3, value=3},{type=3, value=11},{type=2, value=7},}

local card2 = {{type=2, value=8},{type=3, value=12},{type=4, value=6},{type=4, value=13},{type=3, value=11},{type=3, value=9},{type=4, value=9},{type=4, value=1},{type=1, value=11},{type=3, value=4},{type=3, value=3},{type=1, value=2},{type=3, value=13},}

local card3 = {{type= 3 , value= 2 }, {type= 1 , value= 3 }, {type= 1 , value= 4 }, {type= 1 , value= 5 }, {type= 3 , value= 6 }, {type= 2 , value= 5 }, {type= 1 , value= 8 }, {type= 4 , value= 9 }, {type= 1 , value= 13 }, {type= 3 , value= 13 }, {type= 2 , value= 10 }, {type= 3 , value= 10 }, {type= 2 , value= 11 }}

local types = {"方块", "草花", "红心", "黑桃"}
function print_card( cards )
	print("牌型：")
	table.sort(cards,PokerUtils.sortDescent)
	for k,v in pairs(cards) do
		print(types[v.type], v.value+1)
	end
	print("----------------")
end

print_card(card1)
print_card(card2)
print_card(card3)
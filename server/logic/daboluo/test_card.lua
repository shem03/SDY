local logic = {}
function logic.room_deal_test()
    g.cards = {}
    
    -- 测试六同和同花
    local user_card_1={{type= 4 , value= 1 }, {type= 4 , value= 5 }, {type= 4 , value= 8 }, {type= 4 , value= 9 }, {type= 4 , value= 13 }, {type= 1 , value= 3 }, {type= 2 , value= 6 }, {type= 4 , value= 6 }, {type= 2 , value= 11 }, {type= 3 , value= 11 }, {type= 1 , value= 4 }, {type= 3 , value= 12 }, {type= 1 , value= 13 }} --spType:1 
    local user_card_2={{type= 4 , value= 2 }, {type= 4 , value= 5 }, {type= 4 , value= 8 }, {type= 4 , value= 10 }, {type= 4 , value= 12 }, {type= 3 , value= 2 }, {type= 2 , value= 3 }, {type= 3 , value= 6 }, {type= 2 , value= 13 }, {type= 3 , value= 13 }, {type= 1 , value= 1 }, {type= 2 , value= 1 }, {type= 1 , value= 7 }} --spType: 
    local user_card_3={{type=3, value=2},{type=4, value=11},{type=4, value=7},{type=4, value=5},{type=3, value=4},{type=3, value=5},{type=3, value=3},{type=2, value=6},{type=2, value=4},{type=3, value=2},{type=1, value=9},{type=4, value=8},{type=3, value=6},} --spType: 
    local user_card_4={{type=3, value=3},{type=1, value=6},{type=2, value=8},{type=2, value=10},{type=1, value=10},{type=4, value=8},{type=1, value=13},{type=4, value=10},{type=4, value=10},{type=2, value=5},{type=3, value=10},{type=3, value=10},{type=3, value=9},} --spType:-1 
    local user_card_5={{type=4, value=2},{type=1, value=4},{type=1, value=1},{type=4, value=7},{type=4, value=13},{type=3, value=7},{type=4, value=4},{type=4, value=6},{type=3, value=8},{type=2, value=12},{type=4, value=1},{type=1, value=8},{type=4, value=9},} --spType: 
    local user_card_6={{type=2, value=1},{type=4, value=12},{type=3, value=11},{type=1, value=11},{type=2, value=11},{type=4, value=5},{type=4, value=2},{type=4, value=11},{type=2, value=7},{type=3, value=13},{type=4, value=4},{type=4, value=6},{type=3, value=4},} --spType:

    -- 测试一条龙和同花
    -- local user_card_1={{type=3, value=4},{type=3, value=6},{type=2, value=12},{type=4, value=7},{type=1, value=9},{type=1, value=8},{type=4, value=2},{type=3, value=8},{type=1, value=5},{type=3, value=9},{type=1, value=10},{type=4, value=4},{type=3, value=10},}  
    -- local user_card_2={{type=4, value=1},{type=1, value=3},{type=2, value=6},{type=4, value=13},{type=1, value=13},{type=1, value=4},{type=2, value=11},{type=4, value=5},{type=3, value=12},{type=4, value=9},{type=4, value=8},{type=3, value=11},{type=4, value=6},}
    -- local user_card_3={{type=3, value=11},{type=3, value=5},{type=2, value=10},{type=3, value=1},{type=4, value=11},{type=3, value=12},{type=2, value=7},{type=4, value=9},{type=3, value=9},{type=4, value=13},{type=2, value=5},{type=4, value=3},{type=4, value=12},} --spType:1 
    -- local user_card_4={{type=4, value=12},{type=1, value=7},{type=3, value=13},{type=2, value=3},{type=4, value=2},{type=2, value=13},{type=4, value=8},{type=1, value=1},{type=4, value=5},{type=3, value=6},{type=4, value=10},{type=2, value=1},{type=3, value=2},}  
    -- local user_card_5={{type=3, value=3},{type=3, value=13},{type=2, value=9},{type=1, value=11},{type=2, value=4},{type=3, value=10},{type=1, value=12},{type=4, value=7},{type=3, value=1},{type=1, value=6},{type=1, value=2},{type=3, value=8},{type=3, value=5},} --spType:12 
    -- local user_card_6={{type=4, value=4},{type=4, value=6},{type=3, value=7},{type=3, value=2},{type=2, value=2},{type=3, value=7},{type=4, value=11},{type=3, value=4},{type=4, value=3},{type=4, value=1},{type=2, value=8},{type=3, value=3},{type=4, value=10},}


    local v = g.seat[1]
    g.cards[v] = {
        user_card = user_card_1,
        seat = 1,
        spType = 1
    }

    local v = g.seat[2]
    g.cards[v] = {
        user_card = user_card_2,
        seat = 2
    }

    local v = g.seat[3]
    g.cards[v] = {
        user_card = user_card_3,
        seat = 3,
        
    }

    local v = g.seat[4]
    g.cards[v] = {
        user_card = user_card_4,
        seat = 4,
        spType = -1
    }

    local v = g.seat[5]
    g.cards[v] = {
        user_card = user_card_5,
        seat = 5,
        
    }

    local v = g.seat[6]
    g.cards[v] = {
        user_card = user_card_6,
        seat = 6,
    }
end

return logic
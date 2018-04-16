
local db_mgr = require("db_mgr")

local cmd = {}

-- 获取猜拳赢家
-- @param luser 玩家1 
-- @param ruser 玩家2 
-- @return winner 赢家id
-- @return status 胜负情况
function cmd.getGuessingResult(luser, ruser)
	if luser == nil or ruser == nil then return end

	local winner, status
	if (luser.fist == Config.fist_scissors and ruser.fist == Config.fist_rock) or   
		(luser.fist == Config.fist_rock and ruser.fist == Config.fist_paper) or   
		(luser.fist == Config.fist_paper and ruser.fist == Config.fist_scissors) then   
		winner = ruser.uid
		status = Config.status_someone_win
    elseif luser.fist == ruser.fist then  -- 双方打平
    	status = Config.status_tie
    else
    	winner = luser.uid
    	status = Config.status_someone_win
    end
    return winner, status
end

-- 获取下注明细
function cmd.get_bet_data_list()
    local bet_data_list = {}
    for uid, bet_info in pairs(g.bet_data or {}) do
        local user = g.players[uid]
        local bet_data = {
            name = user.name or "",
            uid = uid,
            bet_type = bet_info[1].type,
            bet_value = bet_info[1].value
        }
        table.insert(bet_data_list, bet_data)
    end
    return bet_data_list
end

-- 获取出拳明细
function cmd.get_punch_data_list()
    local punch_data_list = {}
    for uid, value in pairs(g.punches_data or {}) do
        local user = g.players[uid]
        local punch_data = {
            name = user.name or "",
            uid = uid,
            fist = value.fist
        }
        table.insert(punch_data_list, punch_data)
    end
    return punch_data_list
end

return cmd
local skynet = require "skynet"
local db     = require("db_mgr")
local _user  = require("user.ctcore")

-- 重启步骤：返还游戏中金币
local function step_return_game_coin()
	print("------------>重启返还用户金币<------------")
	local sql = "select uid from t_ct_hb_room_user group by uid;"
	local res = db.execute(sql) or {}
	local userAccts = {}
	local userAcct  = {}
	for k, v in pairs(res) do
		local msg, dec, account = _user.get_game_user_account(v.uid)
		-- print(msg, dec, account)
		if account.balGameAmt and tonumber(account.balGameAmt) > 0 then
			userAcct = {}
			userAcct.type = 1
			userAcct.coin =  tonumber(account.balGameAmt)
			userAcct.custNo = v.uid
			table.insert(userAccts, userAcct)
		end
		--print(account)
	end
	--print(userAccts)
	if table.size(userAccts) > 0 then
		--print(userAccts)
		local isSuccess, dec = _user.operatGameResultAcct("1", "", userAccts)
		print("返还结果", isSuccess, dec)
	end
end

-- 重启步骤：返还房间钻石
local function step_return_game_golden()
	print("------------>重启返还房间钻石<------------")
	local sql = "select step,room_id,room_freeze_golden from t_ct_hb_room;"
	local res = db.execute(sql) or {}
	for k, v in pairs(res) do
		if v.step > 0 and v.step < 5 and v.room_freeze_golden >0 then
			print("=======>room:", v.room_id, v.room_freeze_golden)
			local msg, dec = _user.returnRoomGold(v.room_id, v.room_freeze_golden)
			if msg == "ok" then
				local returnSql = string.format("update t_ct_hb_room set room_freeze_golden=0 where room_id=%s", v.room_id)
				db.execute(returnSql)
			end
		end
	end
end

-- 重启步骤：重置在线人数
local function step_reset_online_num()
	print("------------>重启重置在线人数<------------")
	local sql = "UPDATE t_ct_hb_room SET online_num=0;";
	db.execute(sql)
end


local function lanucher()
	-- 重置游戏中金币
	step_return_game_coin()
	-- 重置房间钻石
	step_return_game_golden()
	-- 重置在线人数
	step_reset_online_num()

	-- local userAccts = {}
	-- local userAcct = {}
	-- userAcct.type = 2
	-- userAcct.coin = 200000
	-- userAcct.custNo = 10671
	-- table.insert(userAccts, userAcct)
	-- _hongbao.operatGameResultAcct("1", "", userAccts)

end

skynet.start(function()
	lanucher()
	skynet.exit()
end)

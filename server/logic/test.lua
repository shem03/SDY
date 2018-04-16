
local skynet = require "skynet"
local db_mgr = require("db_mgr")
require("config")
local cthttp = require("cthttp")
local json = require("cjson")
local utils = require("hongbao.poker_utils")
--local mysql = require "mysql"
local _user = require("user.core")
local _hongbao = require("hongbao.core")
local _room = require("room.core")
local cmd = require("room.cmd")
local cheat = require("hongbao.cheat")
local pk10  = require("pk10.poker_utils")

local function test()
	-- local function on_connect(db)
	-- 	db:query("set charset utf8");
	-- end
	-- local db=mysql.connect({
	-- 	host="120.24.76.227",
	-- 	port=44449,
	-- 	database="test",
	-- 	user="cobub1",
	-- 	password="www.moneycome201688.com",
	-- 	max_packet_size = 1024 * 1024,
	-- 	on_connect = on_connect
	-- })
	-- if not db then
	-- 	print("failed to connect")
	-- end
	-- print("testmysql success to connect to mysql server")

	-- local res = db:query("select * from d_user")
	-- print("query", res)
	--[[
	local res = db.add("d_user", {platformUserId="111111", userName="test", userAvatar="http://test.png", userSex=0, lastLoginTime=11114545})
	print("add", res)

	local res = db.update("d_user", {userName="test11"}, {id=1})
	print("update", res)

	local res = db.query("d_user", {id=1})
	print("query", res)

	print(db.get_userinfo(1))

	print(db.query_key("d_user", "id", 1))

	print(db.del("d_user", {id=10}))
	]]

	--local httpc = require "http.httpc"
	--local status, body = httpc.get("www.zccode.com", "/plugin.php?id=rjyfk_url:url")
	--print(status, body)

	--local status, body = do_http_get( "www.zccode.com", "/plugin.php?id=rjyfk_url:url" )
	--print(status, body)
	--[[
	local status, body = cthttp.post("hgame-api/api2.0/user/userInfo", {
		custNo = "10383",
        token = "151055731733506dewqT36cUfhf9uSAhGAmkdJ6Yr",
	})

	if status == 200 then
		local ret, dataTable = pcall(json.decode, body)
		if ret then
			print(dataTable)
		end	
	end
	]]

	--print(os.date("*t", os.time()),"--->")

	--local now_time = os.date("*t", os.time())
	--local min = now_time.min
	--local off = min%10
	--print("off==>", off)	

	--print("===================>test func")
	-- local sqlWhere = {}
	-- sqlWhere.room_id = 1
	-- sqlWhere.round_id = 100012
	-- sqlWhere.round_num = 1
	-- sqlWhere.time = os.time()
	-- sqlWhere.baner_id = os.time()
	-- db.add("t_ct_action", sqlWhere)
	
	--[[
	function test(total, num, min)
		local money = 0
		for i=1, num -1 do
			--随机安全上限 
			local safe_total = math.floor((total-(num-i)*min)/(num-i))
			print(math.floor(safe_total))
			money = math.random(min*100, safe_total*100)/100
			total=total-money
			print( '第'.. i ..'个红包：'  .. money .. ' 元，余额：' .. total ..' 元')
		end
		print( '第'.. num ..'个红包：'  .. total .. ' 元，余额：' .. 0 ..' 元')
	end
	
	-- print(test(10, 8, 0.01))

	for i=1, 100 do 
		--print(utils.randomRedPacket(20, 10))
	end
	--print(os.time({day=22, month=12, year=2017, hour=00, minute=52, second=11}))
	--print(utils.getCowData("10.00"))

	local packet = {"0.12", "1.27", "1.16", "0.97", "1.71", "1.60", "0.84", "2.30", "3.04", "6.25", "2.74"}
	local total = 0
	for k, v in pairs(packet) do
		total = total + tonumber(v)
		--print(v, utils.getCowData(v))
	end
	]]
	--print("total", total)
	-- -- 冻结房间钻石
	-- print(cmd.freezeRoomGold(3587311524627456, "1"))

	-- -- 返还房间钻石
	-- print(cmd.returnRoomGold(3587311524627456, "1"))

	-- -- 扣除房间钻石
	-- print(cmd.reduceRoomGold(3587311524627456, "1"))
	
	--[[
	local testt = {
		["transferAcctType"] = "ACCT_TYPE_BAL_GAME_AMT",
		["transferCustNo"] = "10382",
		["updAcctType"] = "ACCT_TYPE_BAL_AMT",
		["updAmt"] = "160",
		["updCustNo"] = "10382",
		["waterMemo"] = "2.0游戏冻结款",
		["waterType"] = "11"
	}

	local status, body = cthttp.post("hgame-api/api2.0/gamesOperactions/operAcct", {
		custNo = "10382",
		token = "1511415310843Vxa1bcBVe7GJaWYK0YG9TFCHXq2g",
		operAcct = json.encode(testt),
	})
	]]
	--[[
	local status, body = cthttp.post("hgame-api/api2.0/games/getGameRoomDetail", {
		custNo = 1,
        queryGameGroupId = queryGameGroupId,
    })
    
    local ret, dataTable = pcall(json.decode, body)
	]]
	--local ret, dataTable = pcall(json.decode, body)

	--print(dataTable)

	--[[
	local value = "1.22"
	for i=1, #value do
		print(value[i])
	end]]
	
	--print(utils.getAllRates())
	-- print(utils.getResult("10374", hongbao, bet_data))
	--查询账号信息
	--_user.get_game_user_account("operatCustNo")
	--print("重启返还金币")
	-- 获取房间用户 select * from msg group by terminal_id;
	-- 重启返还游戏中金币
	--[[
	local sql = "select uid from t_ct_hb_room_user group by uid;"
	local res = db.execute(sql) or {}
	local userAccts = {}
	local userAcct  = {}
	for k, v in pairs(res) do
		local msg, dec, account = _user.get_game_user_account(v.uid)
		if account.balGameAmt > 0 then
			userAcct = {}
			userAcct.type = 1
			userAcct.coin =  tonumber(account.balGameAmt)
			userAcct.custNo = v.uid
			table.insert(userAccts, userAcct)
		end
		-- print(account)
	end
	--print(userAccts)
	if table.size(userAccts) > 0 then
		print(userAccts)
		local isSuccess, dec = _hongbao.operatGameResultAcct("1", "", userAccts)
		print("返还结果", isSuccess, dec)
	end

	-- 重启返还房间钻石
	local sql = "select step,room_id,room_freeze_golden from t_ct_hb_room;"
	local res = db.execute(sql) or {}
	for k, v in pairs(res) do
		if v.step > 0 and v.step < 5 then
			-- print("=======>room:", v.room_id, v.room_freeze_golden)
			_hongbao.returnRoomGold(v.room_id, v.room_freeze_golden)
		end
	end
	]]
	-- 重置在线人数
	-- local sql = "UPDATE t_ct_hb_room SET online_num=0;";
	-- db.execute(sql)
	
	--[[
	local msg = "m=1000dsadas"
    local pos = string.find(msg, "=")
    if pos ~= 2 then
        return
    end
    local msgTable = str_split_intarray(msg, "=")
    if table.size(msgTable) ~= 2 then
        return
	end

	local num = tonumber(msgTable[2])

	-- 加金币
	if num and (msgTable[1] == "m" or msgTable[1] == "M") then

	-- 加钻石
	elseif num and (msgTable[1]  == "g" or msgTable[1] == "G") then

	end


    print(msgTable, tonumber(msgTable[2]))
	]]

	--cheat.assign_red_packet()
	--print(_hongbao.getZhuangxian("3594506767926272"))
	--[[
	function testh(totalMoey, size)
		-- 计算单位分
		local redPackes = {}
    
		-- 剩余金额
		local remainMoney = totalMoey * 100
		-- 剩余数量
		local remainSize  = size

		while(remainSize > 0) do
			if remainSize == 1 then
				remainSize = remainSize - 1
				table.insert(redPackes, string.format("%0.2f", remainMoney/100)) 
				if remainMoney == 0 then
					print("出现0了", remainMoney)
					print(redPackes)
					return redPackes
				end
				return redPackes
			end

			local min   = 1
			local max   = remainMoney / remainSize * 2 
			local money = math.floor(math.random(1, 100)/100 * max)
			money = money <= min and 1 or money
			table.insert(redPackes, string.format("%0.2f", money/100))

			remainSize = remainSize - 1
			remainMoney = remainMoney - money
			if remainMoney == 0 then
				for k, v in pairs(redPackes) do
					if tonumber(v)*100 > 300 then
						remainMoney = math.random(100, 200)
						redPackes[k] = string.format("%0.2f", (tonumber(v)*100 - remainMoney)/100)
						--print("v==>", tonumber(v)*100, remainMoney, v, (tonumber(v)*100 - remainMoney)/100)
						print(remainMoney/100, v)
						break
					elseif tonumber(v)*100 > 200 then
						remainMoney = math.random(50, 100)
						redPackes[k] = string.format("%0.2f", (tonumber(v)*100 - remainMoney)/100)
						print(remainMoney/100, v)
						break
					elseif tonumber(v)*100 > 100 then
						remainMoney = math.random(1, 100)
						redPackes[k] = string.format("%0.2f", (tonumber(v)*100 - remainMoney)/100)
						print(remainMoney/100, v)
					end
				end
			end	
		end
	end

	for i=1, 1 do 
		local result,p = testh(20, 10)
		print(result)
	end
	]]

	--获取时间格式 
	--time "H:M:S" 
	function converCurrentTime(time)
		local split = string.split(time, ":")
		if #split < 3 then return 0 end
		local tab = os.date("*t", os.time())
   		tab.hour = split[1]
    	tab.min = split[2]
		tab.sec = split[3]
   		local result = os.time{year=tab.year, month=tab.month, day=tab.day, hour=tab.hour, min=tab.min, sec=tab.sec} -- 今天0点
		return result
	end

	-- 获取开奖时间
	function getTypeFtime(type)
		return 30
	end

	-- 获取时间
	function getGameNo(type, time)
		local time   = os.time()
		local kjTime = getTypeFtime(type)
		local atTime = os.date("%H:%M:%S", time) -- + kjTime
		local sql    = string.format("select actionNo, actionTime from t_ct_ssc_data_time where type=%d and actionTime>'%s' order by actionTime limit 1", type, atTime)
		local res = db_mgr.execute(sql)
		if table.empty(res) then
			sql = string.format("select actionNo, actionTime from t_ct_ssc_data_time where type=%d order by actionTime limit 1", type)
			res = db_mgr.execute(sql)
		end
		if table.empty(res) then
			return nil
		else
			local data = res[1]
			data.actionTime       = converCurrentTime(data.actionTime)
			data.actionTimeDate = os.date("%Y-%m-%d %H:%M:%S", data.actionTime)
			return data
		end
	end


	--print(getGameNo(20))
	function test()
		local test 		 = getGameNo(20)
		local kjTime     = getTypeFtime(type)
		local diffTime   = test.actionTime - os.time()

		print(diffTime)
		--print(diffTime - 10)
		local game_time = 0
		if 10 < diffTime and diffTime < 195 then  -- 下注 184s
			print("下注中")
			game_time =  diffTime - 10
		end


		if diffTime >=0 and diffTime <= 10 or (diffTime <= 300 and diffTime >= 300-28) then --等待开奖 38s
			print("等待开奖")
			if diffTime >=0 and diffTime <= 10 then
				game_time = diffTime + 28 
			else
				game_time = 38 - (300 - diffTime) - 10
			end
		end

		if diffTime < 300-28 and (diffTime >= 300 -28 - 30) then	-- 比车 30s
			print("比车")
			game_time = diffTime - (300 -28 - 30) + 1
		end

		if diffTime < 300 -28 - 30 and diffTime >= 300 -28 - 30 - 25 then --比牌25s
			print("比牌")
			game_time = diffTime - (300 -28 - 30 - 25) + 1
		end

		if diffTime < 300-28 -55 and diffTime >= 195 then --等待开始 38s
			print("结算等待开始")
			game_time =  diffTime - 195
		end
		print("game_time=", game_time)
		return step, game_time
	end

	local function timer_call()
		skynet.timeout(100, timer_call) -- 1秒
		pk10.getGameStep()
	end
	--timer_call()
	--[[
	print(0.66 + 0.22 + 0.33 + 0.66 + 0.55 + 0.66)
	print(6660.11 - 6660+6660.11 - 6660+6660.11 - 6660)  

	local sum = 0
	for i=1, 100 do
		sum = 6660.11 - 6660 + sum
	end
	print(math.floor(0.675*100)/100)
]]
	-- 步骤 
	--3分15下注       -- 剩余195s是下注的开始
	--下注184  	   -- 剩余10s是下注的结束   离开奖10秒
	--封盘等待开奖38  -- 最后10s开奖+占用下局28s
	--比车 结算 	       -- 105s - 28s  倒计时此时是3:15     30s 25s
	--等待开始		  --27s

	-- 结算操作
	function niuniu2paijiu(haos)
		local total = 0
		for i=1, #haos do
			total = total + tonumber(haos[i])
		end
	
		if total == 0 then
			return 0
		end
	
		local point = total % 10
		if point == 0 then
			point = 10
		end
	
		return point
	end

	function getResult( bet_data, total_bet, kj, banker, banker_tag )
		local kjHaos     = string.split(kj, ",")
		-- 牛牛  五门
		local user_infos  = {}
		local total_infos = {}
		local banker_info = nil
		for i=1, 2 do --5
			local info     = {}
			info.num   	   = kjHaos[i] .. "," .. kjHaos[i+1]
			info.point 	   = niuniu2paijiu({kjHaos[i], kjHaos[i+1]})
			info.bet  	   = bet_data[i]
			info.total_bet = total_bet[i]
			local haos     = {kjHaos[i], kjHaos[i+1]}
			table.sort(haos, function(a, b)
				return a > b
			end)
			info.hao_max   = haos[1]
			info.door      = i
			if i == banker_tag then
				info.is_banker = true
				banker_info = info
			else
				user_infos[i] = info
			end
		end

		local as = table.sort({1, 2}, function(a, b)
			return tonumber(a) > tonumber(b)
		end)
		print(as)

		-- 庄家模式
		local result = {}
		result.doors = {}
		result.users = {}
		-- 庄家
		if banker_info then
			local log = {}
			local banker_coin_change = 0
			for door, info in pairs(user_infos) do
				if banker_info.point > info.point then		-- 庄>闲
					info.coin_change   = -info.total_bet
				elseif banker_info.point < info.point then  -- 庄<闲
					info.coin_change = info.total_bet
				else -- 打和
					info.coin_change = 0
				end

				local peopes = bet_data[info.door]
				for uid, bet in pairs(peopes) do
					local user_info = {}
					user_info.coin_change = 0
					if info.coin_change > 0 then
						user_info.coin_change = bet
						-- 客户端操作log
						table.insert(log, {change=bet, start_door=info.door, end_door=banker_info.door})
					elseif info.coin_change < 0 then
						user_info.coin_change = -bet
						-- 客户端操作log
						table.insert(log, {change=bet, start_door=banker_info.door, end_door=info.door})
					else
						user_info.coin_change = 0
					end
					user_info.uid     = uid
					user_info.name    = "测试名字"
					user_info.avatar  = "http://www.baidu.net"
					user_info.door    = info.door
					result.users[uid] = user_info
				end
				banker_coin_change = banker_coin_change + info.coin_change
				result.doors[door] = info
			end

			-- door
			banker_info.coin_change  = -banker_coin_change
			result.doors[banker_tag] = banker_info
			-- user
			result.users[banker] 		   	 = {}
			result.users[banker].coin_change = banker_info.coin_change
			result.users[banker].name        =  "测试名字"
			result.users[banker].avatar      = "http://www.baidu.net"
			result.users[banker].is_banker   = true
			table.insert(log, {change=0, start_door=0, end_door=0})		-- 全部返回玩家列表
			result.log = log
			print(result)
		else
			local points = {}
			local tmp = table_copy_table(user_infos)
			table.sort(tmp, function(a, b)
				if a.point > b.point then
					return true
				elseif a.point == b.point then
					return a.hao_max > b.hao_max
				end
				return false
			end)

			-- 分配到门
			-- 排序查找最大点数
			local log = {}
			local user = {}
			for i=1, #tmp do
				local info 			    = tmp[i]
				local total_bet_change  = info.total_bet
				info.coin_change	    = 0
				for j=#tmp, 1, -1 do
					local t_info = tmp[j]
					t_info.remain_total_bet = t_info.remain_total_bet or t_info.total_bet 
					
					if t_info.remain_total_bet > 0 and info.point > t_info.point  then
						if total_bet_change > t_info.remain_total_bet then
							print("下注大于", total_bet_change, t_info.remain_total_bet)
							-- 金币差额
							info.coin_change	    = info.coin_change + t_info.remain_total_bet

							-- 客户端操作log
							table.insert(log, {change=t_info.remain_total_bet, start_door=t_info.door, end_door=info.door})

							-- 下一轮扣
							total_bet_change   = total_bet_change - t_info.remain_total_bet
							t_info.remain_total_bet = 0
							print("下注大", total_bet_change, t_info.remain_total_bet)
	
						elseif total_bet_change < t_info.remain_total_bet then
							print("下注小于", total_bet_change, t_info.remain_total_bet)
							info.coin_change 		= info.coin_change + total_bet_change

							-- 客户端操作log
							table.insert(log, {change=total_bet_change, start_door=t_info.door, end_door=info.door})

							t_info.remain_total_bet = t_info.remain_total_bet - total_bet_change
							total_bet_change   = 0
							print("下注小", total_bet_change, t_info.remain_total_bet)
							break
						else
							print("下注等于", total_bet_change, t_info.remain_total_bet)
							info.coin_change 		= info.coin_change + t_info.remain_total_bet

							-- 客户端操作log
							table.insert(log, {change=total_bet_change, start_door=t_info.door, end_door=info.door})

							t_info.remain_total_bet = 0
							total_bet_change = 0 
							print("下注等", total_bet_change, t_info.remain_total_bet)
							break
						end
					else
						print("判断语句", t_info.remain_total_bet, info.point ,t_info.point)
					end
				end
				
				if info.coin_change == 0 then
					if (info.remain_total_bet or 0) == 0 then									-- 刚好扣光
						info.coin_change = -total_bet_change
					else
						info.coin_change = -(total_bet_change - info.remain_total_bet)   -- 不够扣
					end
				end
				info.remain_total_bet = info.remain_total_bet or info.total_bet
				result.doors[info.door] = info
				print(info)
				-- 分配到人
				local peopes         = bet_data[info.door]
				local user_total_bet = total_bet[info.door]
				for uid, bet in pairs(peopes) do
					local user_info = {}
					user_info.coin_change = 0
					if user_total_bet == math.abs(info.coin_change) then    -- 赢 输（收到的钱刚好）
						if info.coin_change >= 0 then	 --赢
							user_info.coin_change =  bet
						else							 --输
							user_info.coin_change = -bet
						end
					elseif user_total_bet > math.abs(info.coin_change) then -- 赢 输（收到的钱少了）
						if info.coin_change > 0 then	--赢
							user_info.coin_change = info.coin_change * (math.floor(bet/user_total_bet))
						else							--输
							user_info.coin_change = info.coin_change * (math.floor(bet/user_total_bet))
						end
					elseif user_total_bet < info.coin_change then
						print("获得金币>总下注，不可能")
					end

					user_info.uid     = uid
					user_info.name    = "测试名字"
					user_info.avatar  = "http://www.baidu.net"
					user_info.door    = info.door
					result.users[uid] = user_info
				end
			end
			table.insert(log, {change=0, start_door=0, end_door=0})		-- 全部返回玩家列表
			result.log = log
			print(result)
		end
	end



	
	-- 不够赔 按百分比赔
	-- 够赔   多余的按原路比例返回
	local banker_tag = 2
	local banker 	 = "10392"
	local kj         = "01,03,04,05,07,09,06,02,08,10"
	local bet_data   = {
		[1] = {
			["10391"] = 700,
			["10392"] = 500,
			["10393"] = 500,
		},
		-- [2] = {
		-- 	["10392"] = 200,
		-- },
		-- [3] = {
		-- 	["10395"] = 700,
		-- },
		-- [4] = {
		-- 	["10393"] = 800,
		-- },
		-- [5] = {
		-- 	["10394"] = 600,
		-- }
	}
	local total_bet = {
		[1] = 500, --[2] = 200, --[3] = 700, [4] = 800, [5]=600
	}
	-- getResult( bet_data, total_bet, kj, banker, banker_tag )
end

skynet.start(function()
	test()
	skynet.exit()
end)

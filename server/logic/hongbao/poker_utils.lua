
local stringCowCfg = {
    [1] = "牛一",
    [2] = "牛二",
    [3] = "牛三",
    [4] = "牛四",
    [5] = "牛五",  
    [6] = "牛六",  
    [7] = "牛七",  
    [8] = "牛八",  
    [9] = "牛九",  
    [10] = "牛牛",
    
    [11] = "金牛", -- 0.10 - 0.90
    [12] = "对子", -- 0.11 - 0.99
    [13] = "正顺", -- 1.23 - 7.89
    [14] = "倒顺", -- 9.87 - 3.21
    [15] = "满牛", -- 1.00 - 9.00 可四位后三位
    [16] = "豹子", -- 1.11 - 9.99 可四位后三位
}

local stringSDSCfg = {
    [1] = "小",
    [2] = "大",
    [3] = "单",
    [4] = "双",
    [5] = "小单",
    [6] = "大单",
    [7] = "小双",
    [8] = "大双",
    [9] = "合",
}


local cmd = {}

-- 红包算法 
-- 比较简单 单位分 存入的时候记得转化为元
function cmd.randomRedPacket2(totalMoey, size)
    -- 计算单位分
    local redPackes = {}
    
    -- 剩余金额
    local remainMoney = totalMoey * 100
    -- 剩余数量
    local remainSize  = size

    while(remainSize > 0) do
        -- 最后一个红包
        if remainSize == 1 then
            remainSize = remainSize - 1
            table.insert(redPackes, string.format("%0.2f", remainMoney/100))
            return redPackes
        end

        -- 其他红包
        local min     = 1 -- 最低1分钱
        local average = math.floor(remainMoney / remainSize)
        --print(average)
        local money   = math.random(1, average)
        
        if money > min then
            money = money
        else
            money = min
        end

        table.insert(redPackes, string.format("%0.2f", money/100))
        
        remainSize = remainSize - 1
        remainMoney = remainMoney - money
    end

    return redPackes
end

function cmd.randomRedPacket(totalMoey, size)
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
            print(redPackes)
            return redPackes
        end

        local min   = 1
        local max   = remainMoney / remainSize * math.random(100, 200)/100 --2 
        -- print("max", max)
        local money = math.floor(math.random(50, 100)/100 * max)
        money = money <= min and 1 or money
        table.insert(redPackes, string.format("%0.2f", money/100))

        remainSize = remainSize - 1
        remainMoney = remainMoney - money
        if remainMoney == 0 then
            for k, v in pairs(redPackes) do
                if tonumber(v)*100 > 300 then
                    remainMoney = math.random(100, 200)
                    redPackes[k] = string.format("%0.2f", (tonumber(v)*100 - remainMoney)/100)
                    -- print(remainMoney/100, v)
                    break
                elseif tonumber(v)*100 > 200 then
                    remainMoney = math.random(50, 100)
                    redPackes[k] = string.format("%0.2f", (tonumber(v)*100 - remainMoney)/100)
                    --print(remainMoney/100, v)
                    break
                elseif tonumber(v)*100 > 100 then
                    remainMoney = math.random(1, 100)
                    redPackes[k] = string.format("%0.2f", (tonumber(v)*100 - remainMoney)/100)
                    --print("===>ttt", remainMoney/100, redPackes)
                    break
                end
            end
        end
        --print(redPackes)	
    end
end

local function generalNormalRedPacket(money, people)
    -- 开始计算每人红包 按顺序计算
    local redpackets = cmd.randomRedPacket(money, people)  -- {5.55, 7.77} -- 
    -- 洗牌
    local tempCard   = table_copy_table(redpackets)
    local allPackets = {} 
    while #tempCard > 0 do
        local key = math.random(1,#tempCard)
        table.insert(allPackets, tempCard[key])
        tempCard[key],tempCard[#tempCard] = tempCard[#tempCard],tempCard[key]
        tempCard[#tempCard] = nil
    end
    
   print("生成红包如下未洗：", redpackets)
   print("生成红包如下已洗：", allPackets)
   -- print(g.players)
    --完美洗人数
    local tmpPlayers = {}
    local allPlayers = {} 
    for k, v in pairs(g.players) do
        table.insert(tmpPlayers, v)
    end

    while #tmpPlayers > 0 do
        local key = math.random(1,#tmpPlayers)
        table.insert(allPlayers, tmpPlayers[key])
        tmpPlayers[key],tmpPlayers[#tmpPlayers] = tmpPlayers[#tmpPlayers],tmpPlayers[key]
        tmpPlayers[#tmpPlayers] = nil
    end

    print("生成人如下未洗：", g.players)
    print("生成人如下已洗：", allPlayers)

    -- 自动分配
    g.packets = {}
    for index, player in pairs(allPlayers) do
        g.packets[player.id] = {value = allPackets[index], open = false, isGua = false}
    end
end

-- 分配生成红包(正常)
function cmd.assign_red_packet(money, people)
    generalNormalRedPacket(money, people)
end

-- 特殊点配置
-- 豹子
function cmd.get_baozi_cfg()
    return {"1.11", "2.22", "3.33", "4.44", "5.55", "6.66", "7.77", "8.88", "9.99"}
end

-- 满牛
function cmd.get_manniu_cfg()
    return {"1.00", "2.00", "3.00", "4.00", "5.00", "6.00", "7.00", "8.00", "9.00"}
end

-- 倒顺
function cmd.get_daoshun_cfg()
    return {"9.87", "8.76", "7.65", "6.54", "5.43", "4.32","3.21"}
end

-- 正顺
function cmd.get_zhengshun_cfg()
    return {"1.23", "2.34", "3.45", "4.56", "5.67", "6.78", "7.89"}
end

-- 对子
function cmd.get_duizi_cfg()
    return {"0.11", "0.22", "0.33", "0.44", "0.55", "0.66", "0.77", "0.88", "0.99"}
end

-- 金牛
function cmd.get_jinniu_cfg()
    return {"0.10", "0.20", "0.30", "0.40", "0.50", "0.60", "0.70", "0.80", "0.90"}
end

-- 计算特殊点
-- 豹子
function cmd.baozi(value)
    local len = string.len(value)
    local str 
    if len > 4 then
        str = string.sub(value, len - 3, len)
    else
        str = value
    end
    -- 可以后三位
    local config = cmd.get_baozi_cfg()
    for k, v in pairs(config) do
        if str == v then
            return true, str, 16
        end
    end
    return false
end

-- 满牛
function cmd.manniu(value)
    local len = string.len(value)
    local str 
    if len > 4 then
        str = string.sub(value, len - 3, len)
    else
        str = value
    end

    -- 可以后三位
    local config = cmd.get_manniu_cfg()
    for k, v in pairs(config) do
        if str == v then
            return true, str, 15
        end
    end
    return false
end

-- 倒顺
function cmd.daoshun(value)
    local len = string.len(value)
    local str 
    if len > 4 then
        str = string.sub(value, len - 3, len)
    else
        str = value
    end
    -- 可以后三位
    local config = cmd.get_daoshun_cfg()
    for k, v in pairs(config) do
        if str == v then
            return true, str, 14
        end
    end
    return false
end

-- 正顺
function cmd.zhengshun(value)
    local len = string.len(value)
    local str 
    if len > 4 then
        str = string.sub(value, len - 3, len)
    else
        str = value
    end
    -- 可以后三位
    local config = cmd.get_zhengshun_cfg()
    for k, v in pairs(config) do
        if str == v then
            return true, str, 13
        end
    end
    return false
end

-- 对子
function cmd.duizi(value)
    local len = string.len(value)
    local str 
    if len > 4 then
        str = string.sub(value, len - 3, len)
    else
        str = value
    end
    -- 可以后三位
    local config = cmd.get_duizi_cfg()
    for k, v in pairs(config) do
        if str == v then
            return true, str, 12
        end
    end
    return false
end

-- 金牛
function cmd.jinniu(value)
    local len = string.len(value)
    local str 
    if len > 4 then
        str = string.sub(value, len - 3, len)
    else
        str = value
    end
    -- 可以后三位
    local config = cmd.get_jinniu_cfg()
    for k, v in pairs(config) do
        if str == v then
            return true, str, 11
        end
    end
    return false
end

-- 牛牛
function cmd.niuniu (value)
    --print("value==>", value)
    local str = string.gsub(value, "%p", "");
    --print("牛一==>", str)
    local len = string.len(str)
    if len > 3 then
        str = string.sub(str, len - 2, len)
    end
    --print("牛--==1>", str)
    local total = 0
    for i=1, #str do
        total = total + tonumber(str[i])
    end

    if total == 0 then
        return false, value, 0
    end

    local result = total % 10
    if result == 0 then
        result = 10
    end

    return true, value, result
end

-- 特殊点奖
function cmd.isMatchSpecialWinning(value)
    local value_str = tostring(value)
    local ignores = {
        ["1.00"] = true,
        ["2.00"] = true,
        ["3.00"] = true,
        ["4.00"] = true,

        ["1.11"] = true,
        ["2.22"] = true,
        ["3.33"] = true,
        ["4.44"] = true,
    }

    if ignores[value_str] == true then
        return false
    end

    -- 判断10.00 ~ n.nn
    local pos = string.find(value_str, ".00") or 0
    if pos > 0 then
        return true
    end

    -- 11.11 ~ n.nn
    local str = string.gsub(value_str, "%p", "");
    local temple = str[1]
    for i=1, #str do
		if str[i] ~= temple then
			return false
        end
    end
    return true
end

---------------------------------
-- 获取类型名称
function cmd.getBetTypeName(bet_type)
    local config = {"牛牛翻倍", "牛牛不翻倍", "大小单双", "特殊点数"}
    return config[bet_type]
end

-- 获取子类型名称
function cmd.getSubBetTypeName(bet_type, sub_bet_type)
    local config = {"牛牛翻倍", "牛牛不翻倍", "大小单双", "特殊点数"}
    if sub_bet_type == nil then
        return config[bet_type]
    else
        if bet_type == 3 then
            return stringSDSCfg[sub_bet_type]
        elseif bet_type == 4 then
            return stringCowCfg[sub_bet_type]
        end
    end
    return config[bet_type]
end

---------------------------------
-- 获取倍数
local function getCategoryRate(bet_type)
    if bet_type == 1 then        -- 牛牛翻倍
        return {5, 5, 5, 5, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16}
    elseif bet_type == 2 then    -- 牛牛不翻倍
        return {1}
    elseif bet_type == 3 then    -- 大小单双
        return {1, 1, 1, 1, 2, 4, 4, 2, 5}
    elseif bet_type == 4 then    -- 点数下注
        return {8.5}
    end
end

function cmd.getRate(bet_type, point_type)
    local config = getCategoryRate(bet_type)
    if #config == 1 then
        return config[1]
    end
    return config[(point_type or 1)]
end

-- 全部类型倍数
function cmd.getAllRates()
    -- 1、牛牛翻倍  2、牛牛不翻倍  3、大小单双  4、点数下注
    local category = {1, 2, 3, 4}
    local result = {}
    for k, v in pairs(category) do
        result[v] = getCategoryRate(v)
    end
    return result
end

-- 获取最大倍数
function cmd.getMaxRate(bet_type)
    if bet_type == 1 then	   -- 牛牛翻倍
        return 16
    elseif bet_type == 2 then  -- 牛牛不翻倍
        return 1
    elseif bet_type == 3 then  -- 大小单双
        return 5
    elseif bet_type == 4 then  -- 点数下注
        return 8.5
    end
end

-- 是否特殊点数
function cmd.getIsSpecial(tag)
    return tag >= 11
end

---------------------------------
local tCowGroup = {
    [1] = cmd.baozi,
    [2] = cmd.manniu,
    [3] = cmd.daoshun,
    [4] = cmd.zhengshun,
    [5] = cmd.duizi,
    [6] = cmd.jinniu,
    [7] = cmd.niuniu,
}

-- 牛牛玩法数据
function cmd.getCowData(value)
    local str    = tostring(value)
    local result = {}
    for i = 1, #tCowGroup do
        local func = tCowGroup[i]
        local ok, tvalue, tag = func(str)
        if ok then
            table.insert(result, {point_type = tag, value = tvalue, packet_value = value})
        end
    end
    return result
end

-- 获取大小单双
function cmd.getSizeDanShuangData(value)
    local dataTable = cmd.getCowData(value)
    if #dataTable <= 0 then
        return {}
    end

    local result = {}
    for index, data in pairs(dataTable) do
        local tag = data.point_type
        -- 合
        if tag <= 16 and tag >= 11 then
            table.insert(result, {point_type = 9, value = value, packet_value = value})
        end

        -- 大双
        if tag == 6 or tag == 8 or tag == 10 then
            table.insert(result, {point_type = 8, value = value, packet_value = value})
        end

        -- 小双
        if tag == 2 or tag == 4 then
            table.insert(result, {point_type = 7, value = value, packet_value = value})
        end

        -- 大单
        if tag == 7 or tag == 9 then
            table.insert(result, {point_type = 6, value = value, packet_value = value})
        end

        -- 小单
        if tag == 1 or tag == 3 or tag == 5 then
            table.insert(result, {point_type = 5, value = value, packet_value = value})
        end

        -- 双
        if tag == 2 or tag == 4 or tag == 6 or tag == 8 or tag == 10 then
            table.insert(result, {point_type = 4, value = value, packet_value = value})
        end

        -- 单
        if tag == 1 or tag == 3 or tag == 5 or tag == 7 or tag == 9 then
            table.insert(result, {point_type = 3, value = value, packet_value = value})
        end

        -- 大
        if tag == 6 or tag == 7 or tag == 8 or tag == 9 or tag == 10 then
            table.insert(result, {point_type = 2, value = value, packet_value = value})
        end

        -- 小
        if tag == 1 or tag == 2 or tag == 3 or tag == 4 or tag == 5 then
            table.insert(result, {point_type = 1, value = value, packet_value = value})
        end
    end

    return result, dataTable
end

-- 获取结算数据
function cmd.getResult(banker_id, hongbao, bet_data, playes)
	-- 算出庄家数据
	local result                = {}
    local banker_id             = banker_id
    local banker_packet_value   = hongbao[banker_id].value
	local bankerDxds, bankerCow = cmd.getSizeDanShuangData(banker_packet_value)
	local banker                = bankerCow[1]
    -- 庄
    local bankRate = cmd.getRate(1, banker.point_type)
	bankerResult = {}
    bankerResult.isBanker        = true
    bankerResult.point_type      = banker.point_type
    bankerResult.point_type_name = stringCowCfg[banker.point_type]
    bankerResult.packet_value    = banker_packet_value
    bankerResult.rate            = bankRate
	bankerResult.log             = {}
    bankerResult.win             = 0
    bankerResult.lose            = 0
    bankerResult.same            = 0

	local tBankerData = {}
	tBankerData.point_type   = banker.point_type
	tBankerData.point_name   = stringCowCfg[banker.point_type]

    local bankerCoinChange = 0
    local bankerTotalBet  = 0
    local winCount  = 0
    local loseCount = 0
    local sameCount = 0
    --
    -- 下注的
    local people = nil
	for uid, bet in pairs(bet_data) do
		-- 红包钱
		local packet_value = hongbao[uid].value or "0"
		local bet_type     = bet[1].type
		-- 结算结构
		people		         = {}
		people.bet_type      = bet_type
		people.bet_type_name = cmd.getBetTypeName(bet_type)
		people.isBanker	     = uid == banker

        -- 用户金币变化值
        local userCoinChange = 0   
        -- 用户下注总额
        local userToalBet    = 0
        -- log
        local tResult        = {}
        -- 生成大小单双&牛牛点数数据
		local userDxds, userCow = cmd.getSizeDanShuangData(packet_value)
		if bet_type == 1 or bet_type == 2 then -- 跟庄家比
			local tBet   = bet[1]           -- 翻倍与不翻倍取唯一的结果
			local banker = bankerCow[1]     -- 取最大点数比较
            local user   = userCow[1]       -- 取最大点数比较

            -- 下注点数
            local rate               = cmd.getRate(bet_type, user.point_type)
            people.point_type        = user.point_type
            people.point_type_name   = stringCowCfg[user.point_type]
            people.rate              = rate
            people.sub_bet_type_name = people.bet_type_name
            -- 下注总金额
            userToalBet = tBet.value

			if banker.point_type > user.point_type then
				print("庄家赢", uid)
                local bankerRate = cmd.getRate(bet_type, banker.point_type)
				local tData = {}
				tData.point_type   = user.point_type
				tData.point_name   = stringCowCfg[user.point_type]
				tData.rate         = rate
				tData.coin		   = bet_type == 1 and -bankerRate * tBet.value or -rate * tBet.value
				tData.bet_value    = tBet.value
				table.insert(tResult, tData)
                userCoinChange  = userCoinChange  + tData.coin

            elseif banker.point_type < user.point_type then
                -- 闲家牛一牛二 庄家牛一 赢
                if user.point_type == 1 or user.point_type == 2 then	-- 
                    print("庄赢")
                    local bankerRate = cmd.getRate(bet_type, banker.point_type)
					local tData = {}
					tData.point_type   = user.point_type
					tData.point_name   = stringCowCfg[user.point_type]
					tData.rate         = rate
					tData.coin		   = bet_type == 1 and -bankerRate * tBet.value or -rate * tBet.value
					tData.bet_value    = tBet.value
					table.insert(tResult, tData)
                    userCoinChange  = userCoinChange  + tData.coin
                else
                    print("闲赢", uid)
                    local tData = {}
                    tData.point_type   = user.point_type
                    tData.point_name   = stringCowCfg[user.point_type]
                    tData.rate         = rate
                    tData.coin		   = rate * tBet.value
                    tData.bet_value    = tBet.value
                    table.insert(tResult, tData)
                    userCoinChange  = userCoinChange  + tData.coin
                end
			else
				if user.point_type == 1 or user.point_type == 2 then	-- 点数一样庄胜
                    print("庄赢")
                    local bankerRate = cmd.getRate(bet_type, banker.point_type)
					local tData = {}
					tData.point_type   = user.point_type
					tData.point_name   = stringCowCfg[user.point_type]
					tData.rate         = rate
					tData.coin		   = bet_type == 1 and -bankerRate * tBet.value or -rate * tBet.value
					tData.bet_value    = tBet.value
					table.insert(tResult, tData)
                    userCoinChange  = userCoinChange  + tData.coin

				else
					--print(banker_packet_value, user.packet_value)
					if tonumber(banker_packet_value) > tonumber(user.packet_value) then
						print("庄赢")
                        local bankerRate = cmd.getRate(bet_type, banker.point_type)
						local tData = {}
						tData.point_type   = user.point_type
						tData.point_name   = stringCowCfg[user.point_type]
						tData.rate         = rate
						tData.coin		   = bet_type == 1 and -bankerRate * tBet.value or -rate * tBet.value
						tData.bet_value    = tBet.value
						table.insert(tResult, tData)
                        userCoinChange  = userCoinChange  + tData.coin

					elseif tonumber(banker_packet_value) < tonumber(user.packet_value) then
						print("闲赢")
						local tData = {}
						tData.point_type   = user.point_type
						tData.point_name   = stringCowCfg[user.point_type]
						tData.rate         = rate
						tData.coin		   = rate * tBet.value
						tData.bet_value    = tBet.value
						table.insert(tResult, tData)
                        userCoinChange  = userCoinChange  + tData.coin

					else
						print("打平")
						local rate = cmd.getRate(bet_type, user.point_type)
						local tData = {}
						tData.point_type   = user.point_type
						tData.point_name   = stringCowCfg[user.point_type]
						tData.rate         = rate
						tData.coin		   = 0
						tData.bet_value    = tBet.value
						table.insert(tResult, tData)
                        userCoinChange  = userCoinChange  + tData.coin

					end
				end
			end

		elseif bet_type == 4 then	-- 压点数
            local rate = cmd.getRate(bet_type)
            people.point_type        = ""
            people.point_type_name   = ""
            people.rate              = rate
            people.sub_bet_type_name = ""
            people.sub_bet_type      = ""
            
            -- 取最大点数
            local maxUserCow = userCow[1]

			for k, v in pairs(bet) do
                local isWin = false 
                userToalBet = userToalBet + v.value
                
                -- 特殊点全赔
                if maxUserCow.point_type > 10 then
                    people.point_type      = maxUserCow.point_type
                    people.point_type_name = stringCowCfg[maxUserCow.point_type]
                    isWin = false
                else
                    for j, h in pairs(userCow) do
                        if j == 1 then
                            people.point_type      = h.point_type
                            people.point_type_name = stringCowCfg[h.point_type]
                        else
                            people.point_type      = people.point_type .. "," .. h.point_type
                            people.point_type_name = people.point_type_name .. "," .. stringCowCfg[h.point_type]
                        end
                        if v.sub_type == h.point_type then
                            --print("压点", uid)
                            local tData = {}
                            tData.point_type   = h.point_type
                            tData.point_name   = stringCowCfg[h.point_type]
                            tData.rate         = rate
                            tData.coin		   = rate * v.value
                            tData.bet_value    = v.value
                            table.insert(tResult, tData)
                            
                            userCoinChange          = userCoinChange + tData.coin
                            isWin = true
                        end
                    end
                end

				if not isWin then
					local rate = cmd.getRate(bet_type, v.sub_type)
					local tData = {}
					tData.point_type   = v.sub_type
					tData.point_name   = stringCowCfg[v.sub_type]
					tData.rate         = rate
					tData.coin		   = - v.value
					tData.bet_value    = v.value
                    table.insert(tResult, tData)
                    
                    userCoinChange          = userCoinChange + tData.coin
                end
                
                -- 下注子类型 & 子类型名字
                local stringBetInfo = stringCowCfg[v.sub_type]
                if not isWin then
                    stringBetInfo = stringBetInfo .. "(-" .. v.value .. ")"
                else
                    stringBetInfo = stringBetInfo .. "(中奖" .. v.value .. ")"
                end

                if k == 1 then
                    people.sub_bet_type      = tostring(v.sub_type)
                    people.sub_bet_type_name = stringBetInfo
                else
                    people.sub_bet_type      = people.sub_bet_type .. "," .. v.sub_type
                    people.sub_bet_type_name = people.sub_bet_type_name .. " " .. stringBetInfo
                end

            end	
        elseif bet_type == 3 then   -- 压大小单双
            
            people.point_type        = ""   -- 点数
            people.point_type_name   = ""   -- 点数中文
            people.d_point_type      = ""   -- 大小单双
            people.d_point_type_name = ""  -- 大小单双
            people.rate              = ""   -- 倍数
            people.sub_bet_type_name = "" -- 子下注名字

            -- 点数处理
            for index, data in pairs(userCow) do
                if index == 1 then
                    people.point_type      = tostring(data.point_type)
                    people.point_type_name = stringCowCfg[data.point_type]
                else
                    people.point_type      = people.point_type .. "," .. data.point_type
                    people.point_type_name = people.point_type_name .. "," .. stringCowCfg[data.point_type]
                end
            end

            -- 取最大点数
            local maxUserCow = userCow[1]
            -- 取最大点数对应的大小单双
            local maxDxds = userDxds[1]

            -- 大小单双处理
			for k, v in pairs(bet) do
                local isWin = false 
                local rate  = cmd.getRate(bet_type, v.sub_type)
                userToalBet = userToalBet + v.value
                -- 记录下注子类型&下注子类型倍数
                if k == 1 then
                    people.sub_bet_type      = tostring(v.sub_type)
                    people.sub_bet_type_name = stringSDSCfg[v.sub_type]
                    people.rate              = tostring(rate)
                else
                    people.sub_bet_type      = people.sub_bet_type .. "," .. v.sub_type
                    people.sub_bet_type_name = people.sub_bet_type_name .. "," .. stringSDSCfg[v.sub_type]
                    people.rate              = people.rate .. "," .. rate
                end

                -- 抓合
                if maxDxds.point_type == 9 then
                    if v.sub_type == maxDxds.point_type then
                        people.d_point_type = tostring(maxDxds.point_type)
                        people.d_point_type_name = stringSDSCfg[maxDxds.point_type]

                        local tData = {}
                        tData.point_type   = maxDxds.point_type
                        tData.point_name   = stringSDSCfg[maxDxds.point_type]
                        tData.rate         = rate
                        tData.coin		   = rate * v.value
                        tData.bet_value    = v.value
                        table.insert(tResult, tData)

                        userCoinChange          = userCoinChange + tData.coin
                        isWin = true 
                    end
                else
                    for j, h in pairs(userDxds) do
                        -- 当前点数对的大小单双类型
                        if j == 1 then
                            people.d_point_type = tostring(h.point_type)
                            people.d_point_type_name = stringSDSCfg[h.point_type]
                        else
                            people.d_point_type = people.d_point_type .. "," .. h.point_type
                            people.d_point_type_name =  people.d_point_type_name .. "," ..  stringSDSCfg[h.point_type]
                        end
                         -- 大小单双中奖
                        if v.sub_type == h.point_type then
                            local tData = {}
                            tData.point_type   = h.point_type
                            tData.point_name   = stringSDSCfg[h.point_type]
                            tData.rate         = rate
                            tData.coin		   = rate * v.value
                            tData.bet_value    = v.value
                            table.insert(tResult, tData)
    
                            userCoinChange          = userCoinChange + tData.coin
                            isWin = true     
                        end
                    end
                end

				if not isWin then
					local tData = {}
					tData.point_type   = v.sub_type
					tData.point_name   = stringSDSCfg[v.sub_type]
					tData.rate         = rate
					tData.coin		   = - v.value
					tData.bet_value    = v.value
                    table.insert(tResult, tData)
                    
                    if maxDxds.point_type == 9 then -- 输且抓合输一半
                        tData.coin = - v.value * 0.5
                    end

                    userCoinChange     = userCoinChange + tData.coin
				end
			end
        end
            
        -- 红包金额
        people.packet_value = packet_value
        -- 操作记录
        people.log = tResult
        -- 用户金币
        people.coinChange = userCoinChange
        -- 下注总金额
        people.total_bet_value = userToalBet
        --统计庄家的钱
        bankerCoinChange = bankerCoinChange + people.coinChange
        -- 统计庄家的下注总金额
        bankerTotalBet   = bankerTotalBet + people.total_bet_value
        -- 名字
        people.name = playes[uid].name or ""
        -- 头像
        people.avatar = playes[uid].avatar or ""
        -- uid
        people.uid = uid
        -- 判断是否特殊牌
        local maxUser = userCow[1]  
        if cmd.getIsSpecial(maxUser.point_type) then
            people.is_special   = true
            people.spcial_value = maxUser.value
            people.special_type  = maxUser.point_type
        end
        -- 赋值
        result[uid] = people

        -- 判断
        if people.coinChange > 0 then
            loseCount = loseCount + 1
        elseif people.coinChange < 0 then
            winCount = winCount + 1
        else
            sameCount = sameCount + 1
        end
	end

    -- 庄
    tBankerData.coin             = - bankerCoinChange
    bankerResult.coinChange      = tBankerData.coin
    bankerResult.total_bet_value = bankerTotalBet
    bankerResult.win             = winCount
    bankerResult.lose            = loseCount
    bankerResult.same            = sameCount
    bankerResult.name            = playes[banker_id].name or ""
    bankerResult.avatar          = playes[banker_id].avatar or ""
    bankerResult.uid             = banker_id
    -- 判断是否特殊牌
    if cmd.getIsSpecial(banker.point_type) then
        bankerResult.is_special    = true
        bankerResult.spcial_value  = banker.value
        bankerResult.special_type  = banker.point_type
    end
    table.insert(bankerResult.log, tBankerData)
    result[banker_id] = bankerResult
    return result
end

return cmd 
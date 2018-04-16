
local PokerUtils = {}

--百变牌型（ 先用着有空在优化 ）
function PokerUtils.happydoggyGroupCards(cardsArr, varietyC, danse)
	local tGroup = PokerUtils.tGroup
	local t3Group = {PokerUtils.santiao,PokerUtils.yiduiThree,PokerUtils.wulongThree}
	local cArr,existArr,cNameArr = {},{},{}
	if danse then
		tGroup = PokerUtils.tGroupDanse
	end
	for i=1,#tGroup-1 do
		--print("第三墩：",i)
		local ccArr = PokerUtils.copy(cardsArr)
			local cards_1 = tGroup[i](ccArr)
			-- print("---------------------------------")
			for l=1,#cards_1 do
				local breakFor 	=	false
				for n=1,#tGroup do
					local sArr = PokerUtils.delCards(ccArr, cards_1[l], l, n, nil)
						local cards_2 = tGroup[n](sArr, varietyC, 2)
						-- print("第二墩：", n, PokerUtils.tGroupName[n], #cards_2)
						if #cards_2 > 0 then
							-- 清一色玩法，铁支比顺子大
							if n < i then
								breakFor 	=	true
								break
							end
							for j=1,#cards_2 do
								local cflag = true -- 是否相公
								if i == n then
									cflag = PokerUtils.isMessireFive(11-i,cards_1[l],cards_2[j])
									-- print("cflag:",cflag)
									cflag 	=	cflag == false
								end
								if cflag then
									if i == 1 and n == 3 and cards_1[l][1].value == 8 then
										break
									end
									local sArr = PokerUtils.delCards(sArr, cards_2[j], i, n, 3)
									--local sArr3 = PokerUtils.copy(sArr)
									for k=n < 8 and 1 or n < 10 and 2 or 3,3 do -- n==8
										local cards_3 = t3Group[k](sArr)
										-- print("---------------------------------", k, #cards_3, #sArr)
										-- print("sArr:", sArr[1].value, sArr[2].value, sArr[3].value, sArr[4].value, sArr[5].value, sArr[6].value)
										local cflag = false
										if #cards_3 > 0 then
											cards_3 = cards_3[1]
											cflag = true
											if n == 7 and k == 1 or n == 9 and k == 2 or n == 10 and k == 3 then
												cflag = PokerUtils.isMessireThree(n,cards_2,cards_3,j)
											end
										end
										-- print("所有墩：",i,PokerUtils.tGroupName[i], n,PokerUtils.tGroupName[n], k,PokerUtils.t3GroupName[k], "#sArr:", #sArr, cflag, #cards_3, existArr['a'..i..'b'..n.."c"..k])
										-- for i,v in ipairs(sArr) do
										-- 	print(i,v.value, v.type)
										-- end
										if cflag then -- 不是相公
											if not existArr['a'..i..'b'..n.."c"..k]  then
												local sArr = PokerUtils.delCards(sArr,cards_3, nil, nil, nil)
												local group3 = {cards_1[l][1],cards_1[l][2],cards_1[l][3],cards_1[l][4],cards_1[l][5]}
												local group2 = {cards_2[j][1],cards_2[j][2],cards_2[j][3],cards_2[j][4],cards_2[j][5]}
												local group1 = {cards_3[1],cards_3[2],cards_3[3]}


												-- local arr = {cards_1[l][1],cards_1[l][2],cards_1[l][3],cards_1[l][4],cards_1[l][5],
												-- 			cards_2[j][1],cards_2[j][2],cards_2[j][3],cards_2[j][4],cards_2[j][5],
												-- 			cards_3[1],cards_3[2],cards_3[3]}
												table.sort(group3, PokerUtils.sortDescent)
												table.sort(group2, PokerUtils.sortDescent)
												table.sort(group1, PokerUtils.sortDescent)

												local arr = {
																group3[1], group3[2], group3[3], group3[4], group3[5],
																group2[1], group2[2], group2[3], group2[4], group2[5],
																group1[1], group1[2], group1[3]
															}


												if #sArr == 3 then
													for i=14,16 do
														table.insert(arr, sArr[i-13])
													end
												end
												table.insert(cArr,arr)
												table.insert(cNameArr,{i,n,k})
												existArr['a'..i..'b'..n.."c"..k] = true
												if #cArr > 5 then
													return cArr,cNameArr
												end
											end
											break
										end
									end
								end
							end
						end
				end
				if breakFor then
					break
				end

			end
	end
	return cArr,cNameArr
end



--第二墩 与 第一墩 是否相公
function PokerUtils.isMessireThree(i,a,b,j)
	if i == 7 then
		if a[j][3].value < b[3].value then
			return false
		end
	elseif i > 8 then
		if i == 9 then
			if a[j][1].value == b[1].value then
				if a[j][3].value < b[3].value then
					return false
				end
			elseif a[j][1].value < b[1].value then
				return false
			end
		else
			if a[j][1].value == b[1].value then
				if a[j][2].value == b[2].value then
					if a[j][3].value < b[3].value then
						return false
					end
				elseif a[j][2].value < b[2].value then
					return false
				end
			elseif a[j][1].value < b[1].value then
				return false
			end
		end
	end
	return true
end

--第三墩 与 第二墩 是否相公
function PokerUtils.isMessireFive(i,a,b)
	local v,s = {},{}
	for n=1,5 do
		table.insert(v,a[n])
		table.insert(s,b[n])
	end
	if i == 6 then
		table.sort(v,function(x,y) return x.value < y.value end)
			table.sort(s,function(x,y) return x.value < y.value end)
	else
		table.sort(v,function(x,y) return x.value > y.value end)
			table.sort(s,function(x,y) return x.value > y.value end)
		end
		if i == 10 or i == 8 then
		return v[3].value < s[3].value
	elseif i == 7 then
		if v[3].value == s[3].value then
        	if v[1].value == v[3].value and s[1].value == s[3].value then
            	return v[4].value < s[4].value
          	elseif v[1].value == v[3].value and s[3].value == s[5].value then
            	return v[4].value < s[1].value
          	elseif v[3].value == v[5].value and s[1].value == s[3].value then
            	return v[1].value < s[4].value
          	elseif v[3].value == v[5].value and s[3].value == s[5].value then
            	return v[1].value < s[1].value
          	end
        end
        return v[3].value < s[3].value
    elseif i == 6 then
    	return not PokerUtils.compare_tonghua(1, v, s)
    elseif i == 9 or i == 5 or i == 1 then
    	if v[1].value == s[1].value then
        	if v[2].value == s[2].value then
            	if v[3].value == s[3].value then
              		if v[4].value == s[4].value then
              			if v[5].value == s[5].value then
              				return
              			else
                			return v[5].value < s[5].value
                		end
              		end
              		return v[4].value < s[4].value
            	end
          		return v[3].value < s[3].value
          	end
          	return v[2].value < s[2].value
        end
        return v[1].value < s[1].value
    elseif i > 1 and i < 5 then
    	local dz_1,dz_2,wl_1,wl_2 = {},{},{},{}
    	for i=1,5 do
    		if i < 5 and v[i].value == v[i+1].value or #dz_1 > 0 and v[i].value == dz_1[#dz_1] then
            	table.insert(dz_1,v[i].value)
          	else
            	table.insert(wl_1,v[i].value)
          	end
    		if i < 5 and s[i].value == s[i+1].value or #dz_2 > 0 and s[i].value == dz_2[#dz_2] then
            	table.insert(dz_2,s[i].value)
          	else
            	table.insert(wl_2,s[i].value)
          	end
        end
        if dz_1[1] == dz_2[1] then
          	if i == 4 then
            	if wl_1[1] == wl_2[1] then
              		return wl_1[2] < wl_2[2]
            	end
            	return wl_1[1] < wl_2[1]
          	elseif i == 3 then
            	if dz_1[3] == dz_2[3] then
              		return wl_1[1] < wl_2[1]
            	end
            	return dz_1[3] < dz_2[3]
          	elseif i == 2 then
            	if wl_1[1] == wl_2[1] then
              		if wl_1[2] == wl_2[2] then
                		return wl_1[3] < wl_2[3]
              		end
              		return wl_1[2] < wl_2[2]
            	end
            	return wl_1[1] < wl_2[1]
          	end
          	if #dz_1 == 0 or #dz_2 == 0 then
          		-- dump(dz_1)
          		-- dump(dz_2)
          		-- dump(wl_1)
          		-- dump(wl_2)
          	end 
        elseif #dz_1 > 0 and #dz_2 > 0 then
        	return dz_1[1] < dz_2[1]
        end
	end
    return true
end

--单张扑克解码
function PokerUtils.singleCardsDecode(c)
	local suit = math.floor(c/16)
	local point = c-suit*16-1
	return {type=suit,value=point}
end
--单张扑克编码
function PokerUtils.singleCardsEncode(o)
	return o.type*16+o.value+1
end
--扑克解码
function PokerUtils.cardsDecode(cArr)
	local arr = {}
	for i=1,#cArr do
		local c = cArr[i]
		if c == 97 then
			table.insert(arr,{type=5,value=16})
		elseif c == 96 then
			table.insert(arr,{type=5,value=15})
		else
			local suit = math.floor(c/16)
			local point = c-suit*16-1
			table.insert(arr,{type=suit,value=point})
		end
	end
	return arr
end
--扑克编码
function PokerUtils.cardsEncode(cArr)
	local arr,hArr = {},{}
	for i=1,#cArr do
		local c = cArr[i]
		local suit = c.type == 5 and c.suit or c.type
		table.insert(arr,suit*16+c.value+1)
		if c.type == 5 then
			local pos = 14-i
			if i < 6 then
				pos = i + 8
			elseif i >=6 and i < 11 then
				pos = i - 2
			end
			-- print("cardsEncode:", i, pos)
			table.insert(hArr,pos)
		end
	end
	return arr,hArr
end

--扑克比牌 排序 第一墩
function PokerUtils.cSort_1(a,b)
	if a[2] == b[2] then
		local v,s = {},{}
		for i=11,13 do
			table.insert(v,a[1][i].value)
			table.insert(s,b[1][i].value)
		end
		table.sort(v,function(x,y) return x > y end)
    	table.sort(s,function(x,y) return x > y end)
    	if a[2] == 1 then
			if v[1] == s[1] then
				if v[2] == s[2] then
					return v[3] < s[3]
				end
				return v[2] < s[2]
			end
			return v[1] < s[1]
		elseif a[2] == 2 then
			if v[2] == s[2] then
				if v[1] == v[2] and s[1] == s[2] then
		          	return v[3] < s[3]
		        elseif v[1] == v[2] and s[2] == s[3] then
		          	return v[3] < s[1]
		        elseif v[2] == v[3] and s[1] == s[2] then
		          	return v[1] < s[3]
		        elseif v[2] == v[3] and s[2] == s[3] then
		          	return v[1] < s[1]
		        end
			end
			return v[2] < s[2]
		elseif a[2] == 4 then
			return v[2] < s[2]
		end
	end
	return a[2] < b[2]
end
--扑克比牌 排序 第二墩 与 第三墩
function PokerUtils.cSort_2(i)
	return function(a,b)
		local t1,t2 = a[i],b[i]
		if t1 == t2 then
			local vArr,sArr,c 	=	{},{},1
			if i == 3 then
				c = 6
			end
			for i=c,c+4 do
				table.insert(vArr,a[1][i])
				table.insert(sArr,b[1][i])
			end
			return PokerUtils.isMessireFive(t1,vArr,sArr)
		end
		return t1 < t2
	end
end


--获取普通组合牌型
function PokerUtils.getGroupCards(cArr)
	local wlArr,dzArr,stArr,tzArr,sArr,wtArr,sz_n = {},{},{},{},{},{},1
	local cardsArr,vArr = PokerUtils.getVariety(cArr)
	-- print("getGroupCards varietyC vArr:", #vArr, varietyC)
	local i,szArr = #cardsArr,{}
	while i > 0 do
		local cards = cardsArr[i]
		--顺子组合判断
		if sz_n > 1 then
			if sArr[sz_n-1].value == cards.value then
				sz_n = sz_n-1
			elseif sArr[sz_n-1].value+1 ~= cards.value then
				if #sArr > 4 then table.insert(szArr,sArr) end
				sz_n = 1
				sArr = {}
			end
		end

		if i < #cardsArr and cards.value == cardsArr[i+1].value then

		elseif i > 1 and cards.value == cardsArr[i-1].value then
			--三条组合判断
			if i > 2 and cards.value == cardsArr[i-2].value then
				--五同组合判断
				if i > 4 and cards.value == cardsArr[i-4].value then
					table.insert(wtArr,{cards,cardsArr[i-1],cardsArr[i-2],cardsArr[i-3],cardsArr[i-4]})
				--四条组合判断
				elseif i > 3 and cards.value == cardsArr[i-3].value then
					table.insert(tzArr,{cards,cardsArr[i-1],cardsArr[i-2],cardsArr[i-3]})
				else
					--三条组合保存
					table.insert(stArr,{cards,cardsArr[i-1],cardsArr[i-2]})
				end
			else
				--对子组合保存
				table.insert(dzArr,{cards,cardsArr[i-1]})	
			end
		else
			table.insert(wlArr,cards)
		end
		--顺子组合保存
		sArr[sz_n] = cards
		sz_n = sz_n+1
		i = i - 1
	end
	if #sArr > 4 then table.insert(szArr,sArr) end
	return {wlArr,dzArr,stArr,tzArr,szArr,vArr,cardsArr,wtArr}
end

--扑克copy
function PokerUtils.copy(cArr)
	if not cArr then return {} end
	local arr = {}
	for i=1,#cArr do
		arr[i] = cArr[i]
	end
	return arr
end
--扑克删除
function PokerUtils.delCards(a1, b1, e, f, n)
	--[[
	local arr,cardsArr = {},{}
	for i=1,#b do
		arr[b[i].value] = true
	end
	for i=1,#a do
		if not arr[a[i].value] then
			table.insert(cardsArr,a[i])
		end
	end]]--
	local a = PokerUtils.copy(a1)
	local b = PokerUtils.copy(b1)
	if  n == 3 then
		--print(#a,#b)
		--dump(a)
		--dump(b)
	end
	for i=#a,1,-1 do
		if #b == 0 then break end
		for l=1,#b  do
			if b[l].type < 5 and a[i].value == b[l].value and a[i].type == b[l].type  then

				if e == 1 and f == 3 and n == 3 then
					--dump(b)
					--dump(a[i])
				end
				table.remove(b,l)
				table.remove(a,i)
				break
			end
		end
	end
	if #b > 0 then -- 需要移除赖子牌
		for i=#a,1,-1 do
			if #b == 0 then break end
			if a[i].type == 5 then
				for l=1,#b do
					if b[l].type == 5 then
						table.remove(b,l)
						table.remove(a,i)
						break
					end
				end
			end
		end
		--print(".................",#a,#b)
	elseif n == 3 then
		--print("=======================",#a,#b)
	end
	--print(#a,#b)
	return a
end

function PokerUtils.getVarietyPos(cards)
	local cArr = {}
	for i=1,#cards do
		if cards[i].type == 5 then
			table.insert(cArr,{i, cards[i].old})
		end
	end
	return cArr
end 


--获取百变扑克
function PokerUtils.getVariety(cards)
	table.sort(cards,PokerUtils.sortRise)
	local cArr,vArr = {},{}
	for i=1,#cards do
		if cards[i].type == 5 then
			table.insert(vArr,cards[i])
		else
			table.insert(cArr,cards[i])
		end
	end
	return cArr,vArr
end  
-- 乌龙 （三张）
function PokerUtils.wulongThree(cards, varietyC)
	if #cards < 3 then return {} end
	local cArr = PokerUtils.getGroupCards(cards, varietyC)
	local wlArr,cardsArr = cArr[1],{}
	for i=#wlArr,3,-1 do
		table.insert(cardsArr,{wlArr[i],wlArr[i-1],wlArr[i-2]})
	end
	return cardsArr
end
-- 一对 （三张）
function PokerUtils.yiduiThree(cards, varietyC)
	-- if #cards < 3 then return {} end
	-- local cArr = PokerUtils.getGroupCards(cards, varietyC)
	-- local wlArr,dzArr,vArr,cardsArr = cArr[1],cArr[2],cArr[6],{}
	-- if #dzArr > 0 and #wlArr > 0 then
	-- 	local i = #dzArr
	-- 	while i > 0 do
	-- 		table.insert(cardsArr,{dzArr[i][1],dzArr[i][2],wlArr[1]})
	-- 		i = i - 1
	-- 	end
	-- elseif #vArr > 0 and #wlArr > 1 then
	-- 	local i = #wlArr
	-- 	while i > 1 do
	-- 		table.insert(cardsArr,{wlArr[i],{type=5,value=wlArr[i].value,suit=wlArr[i].type == 4 and 3 or 4},wlArr[1]})
	-- 		i = i - 1
	-- 	end
	-- end
	if #cards < 3 then return {} end
	local resArr = {}
	local cardsArr,vArr = PokerUtils.getVariety(cards,0)
	local changeLen = #vArr
	local pokerLen = #cardsArr
	for i=1,pokerLen -1 do
		if  cardsArr[i].value == cardsArr[i+1].value then
			if i < pokerLen - 1 then
				table.insert(resArr,{cardsArr[i],cardsArr[i+1],cardsArr[i+2]})
			else
				table.insert(resArr,{cardsArr[i],cardsArr[i+1],cardsArr[1]})
			end
		end
	end
	if changeLen > 0 then
		local index = changeLen
		while index > 0 do
			for j=1,pokerLen-1 do
				local cards = cardsArr[j]
				table.insert(resArr,{cards,{type=5,value=cards.value,suit=cards.type == 4 and 3 or 4, old=vArr[index].value},cardsArr[j+1]})
			end
			index = index - 1
		end
	end
	-- print("yiduiThree:", #resArr)
	return resArr
end
--三条
function PokerUtils.santiao(cards, varietyC)
	-- if #cards < 3 then return {} end
	-- local cArr = PokerUtils.getGroupCards(cards, varietyC)
	-- local wlArr,stArr,vArr,cardsArr = cArr[1],cArr[3],cArr[6],{}
	-- if #stArr > 0 then
	-- 	local i = #stArr
	-- 	while i > 0 do
	-- 		table.insert(cardsArr,stArr[i])
	-- 		i = i - 1
	-- 	end
	-- elseif #vArr > 0 then
	-- 	local dzArr = cArr[2]
	-- 	if #dzArr > 0 then
	-- 		local i = #dzArr
	-- 		while i > 0 do
	-- 			table.insert(cardsArr,{dzArr[i][1],dzArr[i][2],{type=5,value=dzArr[i][1].value,suit=dzArr[i][1].value == 4 and 3 or 4}})
	-- 			i = i -1
	-- 		end
	-- 	elseif #vArr > 1 and #wlArr > 0 then
	-- 		local i = #wlArr
	-- 		while i > 0 do
	-- 			table.insert(cardsArr,{wlArr[i],{type=5,value=wlArr[i].value,suit=4},{type=5,value=wlArr[i].value,suit=3}})
	-- 			i = i - 1
	-- 		end
	-- 	elseif #vArr >= 3 then
	-- 		local cArr,hpArr 	=	PokerUtils.getVariety(cards,varietyC)
	-- 		if #hpArr > 2 then
	-- 			table.insert(cardsArr,{hpArr[1],hpArr[2],hpArr[3]})
	-- 		end
	-- 	end
	-- end
	-- return cardsArr

	if #cards < 3 then return {} end
	local resArr = {}
	local cardsArr,vArr = PokerUtils.getVariety(cards,varietyC)
	local changeLen = #vArr
	local pokerLen = #cardsArr
	for i=1,#cardsArr - 2 do
		if  cardsArr[i].value == cardsArr[i+2].value then
			table.insert(resArr,{cardsArr[i],cardsArr[i+1],cardsArr[i+2]})
		end
	end
	local index = changeLen
	if changeLen > 1 then
		local index = changeLen
		while index > 0 do
			for j=1,pokerLen do
				local cards = cardsArr[j]
				table.insert(resArr,{cards,{type=5,value=cards.value,suit=4, old=vArr[1].value},{type=5,value=cards.value,suit=3, old=vArr[2].value}})
			end
			index = index - 1
		end
	elseif changeLen > 0 then
		index = changeLen
		while index > 0 do
			for j=1,pokerLen -1 do
				if  cardsArr[j].value == cardsArr[j+1].value then
					table.insert(resArr,{cardsArr[j],cardsArr[j+1],{type=5,value=cardsArr[j].value,suit=cardsArr[j].suit == 4 and 3 or 4, old=vArr[index].value}})
				end
			end
			index = index - 1
		end
	end
	return resArr
end

-- 乌龙（五张）
function PokerUtils.wulongFive(cards, varietyC)
	if #cards < 5 then return {} end
	local cArr = PokerUtils.getGroupCards(cards, varietyC)
	local wlArr,cardsArr = cArr[1],{}
	if #wlArr > 4 then
		for i=#wlArr,5,-1 do
			local arr,cflag = {wlArr[i],wlArr[4],wlArr[3],wlArr[2],wlArr[1]},false
			for l=2,#arr do
				if arr[l].type ~= arr[l-1].type then
					cflag = true
					break
				end
			end
			if cflag then
				cflag 	=	false
				for l=2,#arr do
					if arr[l].value ~= arr[l-1].value+1 then
						cflag = true
						break
					end
				end
				if cflag and arr[1].value == 13 and arr[2].value == 4 and arr[3].value == 3 and arr[4].value == 2 and arr[5].value == 1 then
					cflag 	=	false
				end 
				if cflag then
					table.insert(cardsArr,arr)
				end
			end
		end
	end
	return cardsArr
end


-- 一对（五张）
function PokerUtils.yiduiFive(cards, varietyC)
	if #cards < 5 then return {} end
	local cArr = PokerUtils.getGroupCards(cards, varietyC)
	local wlArr,dzArr,vArr,cardsArr = cArr[1],cArr[2],cArr[6],{}
	if #dzArr > 0 then
		if #wlArr > 2 then
			for i=#dzArr,1,-1 do
				table.insert(cardsArr,{dzArr[i][1],dzArr[i][2],wlArr[3],wlArr[2],wlArr[1]})
			end
		elseif #dzArr > 3 then
			for i=#dzArr,4,-1 do
				table.insert(cardsArr,{dzArr[i][1],dzArr[i][2],dzArr[3][1],dzArr[2][1],dzArr[1][1]})
			end
		end
	elseif #vArr > 0 and #wlArr > 3 then
		local i = #wlArr
		while i > 3 do
			table.insert(cardsArr,{wlArr[i],{type=5,value=wlArr[i].value,suit=4, old=vArr[1].value},wlArr[i-1],wlArr[i-2],wlArr[i-3]})
			i = i - 1
		end
	end
	return cardsArr
end
--两对(返回最大的两对)
function PokerUtils.liangdui(cards, varietyC)
	if #cards < 5 then return {} end
	local cArr = PokerUtils.getGroupCards(cards, varietyC)
	local wlArr,dzArr,vArr,cardsArr = cArr[1],cArr[2],cArr[6],{}
	if #dzArr > 1 and #wlArr > 0 or #dzArr > 2 then
		local i = #dzArr
		for l=#dzArr,#wlArr == 0 and 3 or 2,-1 do
			table.insert(cardsArr,{dzArr[l][1],dzArr[l][2],dzArr[1][1],dzArr[1][2],#wlArr > 0 and wlArr[1] or dzArr[2][1]})

			--[[
			if i == l or i < 2 then
				break
			else
				table.insert(cardsArr,{dzArr[i][1],dzArr[i][2],dzArr[i-1][1],dzArr[i-1][2],wlArr[1]})
				i = i - 1
			end]]--
		end
		--dump(cardsArr)
	end
	return cardsArr
end


-- 三条（五张）
function PokerUtils.santiaoFive(cards, varietyC)
	if #cards < 5 then return {} end
	local cArr = PokerUtils.getGroupCards(cards, varietyC)
	local wlArr,dzArr,stArr,vArr,cardsArr = cArr[1],cArr[2],cArr[3],cArr[6],{}
	if #stArr > 0 then
		if #wlArr > 1 then
			for i=#stArr,1,-1 do
				table.insert(cardsArr,{stArr[i][1],stArr[i][2],stArr[i][3],wlArr[2],wlArr[1]})
			end
		elseif #dzArr > 1 then
			for i=#stArr,1,-1 do
				table.insert(cardsArr,{stArr[i][1],stArr[i][2],stArr[i][3],dzArr[2][1],dzArr[1][1]})
			end
		elseif #stArr > 2 then
			for i=#stArr,3,-1 do
				table.insert(cardsArr,{stArr[i][1],stArr[i][2],stArr[i][3],stArr[2][1],stArr[1][1]})
			end
		end
	elseif #vArr > 0 and #dzArr > 0 and #wlArr > 1 then
		local i = #dzArr
		while i > 0 do
			table.insert(cardsArr,{dzArr[i][1],dzArr[i][2],{type=5,value=dzArr[i][1].value,suit=dzArr[i][1].value == 4 and 3 or 4, old=vArr[1].value},wlArr[2],wlArr[1]})
			i = i - 1
		end
	elseif #vArr > 1 and #wlArr > 2 then
		local i = #wlArr
		while i > 2 do
			table.insert(cardsArr,{wlArr[i],{type=5,value=wlArr[i].value,suit=4, old=vArr[1].value},{type=5,value=wlArr[i].value,suit=3, old=vArr[2].value},wlArr[i-1],wlArr[i-2]})
			i = i - 1
		end
	end
	return cardsArr
end

--获取百变顺子
function PokerUtils.getHappydoggyShunzi(cardsArr,c)
	if #cardsArr+c < 5 then return {} end
	local cArr = {}
	for i=1,#cardsArr do
		cArr[i] = cardsArr[i].value
	end
	table.sort(cArr,function(a,b) return a > b end)
	local a,b,o,maxC,minC = {},{},{},cArr[1],cArr[#cArr]
  	for i=1,#cArr do o[cArr[i]] = true end
  	if maxC == 13 and #cArr > 1 and cArr[2] < 5 then
    	maxC = (cArr[2] == 4) and cArr[2] or 4
    	minC = minC == 1 and minC or 1
    	a = {cArr[1]}
    else
    	if maxC - minC > 4 then return {} end
    	local maxStep = 4 - (maxC - minC)
    	if maxStep > c then return {} end
    	while maxStep > 0 do
    		if maxC + 1 < 14 then
    			maxC = maxC + 1
    		elseif minC - 1 > 0 then
    			minC = minC - 1
    		else
    			return {}
    		end
    		maxStep = maxStep - 1
    		if maxC == 5 and minC - maxStep == 1 then
    			maxC = 4
    			a 	=	{13}
    			c 	=	c - 1
    			b[13] = true
    			for l = minC - 1, 1, -1 do
    				c 	=	c - 1
    				b[l] = true
    				minC = minC - 1
    			end
    			break
    		end
    	end
	end
	for i = maxC, minC, -1 do
		if o[i] or b[i] then
			table.insert(a, i)
		elseif c > 0 then
			table.insert(a, i)
			b[i] = true
		    c = c - 1
		    o[i] = true
		else
			break
		end
	end
	if #a < 5 then return {} end
	if a[1] == 13 and a[2] == 4 and a[3] == 3 and a[4] == 2 and a[5] == 1 or 
	   a[1] == a[2]+1 and a[2] == a[3]+1 and a[3] == a[4]+1 and a[4] == a[5]+1 then
		return a,b
	else
		return {},{}
	end
end
--获取最少花色
function PokerUtils.getMinSuit(cards)
	local suitArr = {{type=1,value=0},{type=2,value=0},{type=3,value=0},{type=4,value=0}}
	for i=1,#cards do
		local suit = cards[i].type
		if suit ~= 5 then
			suitArr[suit].value = suitArr[suit].value + 1
		end
	end
 	table.sort(suitArr,PokerUtils.sortRise)
 	local arr,n = {},1
 	for i=1,8 do
 		if n > 4 then n = 1 end
 		if suitArr[n].value ~= 2 then
 			suitArr[n].value = suitArr[n].value + 1
 			table.insert(arr,suitArr[n].type)
 		end
 		n = n + 1
 	end
 	return arr
end


--顺子
function PokerUtils.shunzi(cards, varietyC)
	if #cards < 5 then return {} end
	local cArr = PokerUtils.getGroupCards(cards, varietyC)
	local wlArr,dzArr,szArr,vArr,cardsArr = cArr[1],cArr[2],cArr[5],cArr[6],{}
	local szCards,vCards 	=	{},{}
	for i=#cArr[7],1,-1 do
		local o 	=	cArr[7][i]
		if i > 1 and o.value == cArr[7][i-1].value or 
			#szCards > 0 and szCards[#szCards].value == cArr[7][i].value then
		else
			table.insert(szCards,o)
			vCards[o.value] 	=	i
		end
	end
	if vCards[13] and vCards[4] and vCards[3] and vCards[2] and vCards[1] then
		table.insert(szArr,{cArr[7][vCards[1]],cArr[7][vCards[2]],cArr[7][vCards[3]],cArr[7][vCards[4]],cArr[7][vCards[13]]})
	end
	if #szArr > 0 then
		local i = #szArr
		while i > 0 do
			-- print('sz:', PokerUtils.get_cardlog(szArr[i]))
			local l = #szArr[i]
			while l > 4 do
				local sArr,cflag = {szArr[i][l],szArr[i][l-1],szArr[i][l-2],szArr[i][l-3],szArr[i][l-4]},false
				-- print('sz111:', PokerUtils.get_cardlog(sArr))
				-- for n=2,#sArr do
				-- 	if sArr[n].type ~= sArr[n-1].type then
				-- 		cflag = true
				-- 		break
				-- 	end
				-- end
				-- if cflag then
					table.insert(cardsArr,{szArr[i][l],szArr[i][l-1],szArr[i][l-2],szArr[i][l-3],szArr[i][l-4]})
				-- end
				l = l - 1
			end
			i = i - 1
		end
	elseif #vArr > 0 then
		local szArr = {}
		for i=#cArr[7],1,-1 do
			if i > 1 and cArr[7][i].value == cArr[7][i-1].value or 
				#szArr > 0 and szArr[#szArr].value == cArr[7][i].value then

			else
				table.insert(szArr,cArr[7][i])
			end
		end
		for i=4,1,-1 do
			if i+#vArr < 5 then break end
			for l=1,#szCards-i+1 do
				local arr,suitArr = {},{}
				for n=l,l+i-1 do
					suitArr[szCards[n].value] = szCards[n].type
					table.insert(arr,szCards[n])
				end
				local a,b =	PokerUtils.getHappydoggyShunzi(arr,#vArr)
				if #a == 5 then
					local minSuitArr = PokerUtils.getMinSuit(arr)
					local arr,c = {},1
					for n=1,5 do
                        if b[a[n]] then
                        	local suit = minSuitArr[c] and minSuitArr[c] or 4
                            table.insert(arr,{type=5,suit=suit,value=a[n], old=vArr[1].value})
                            c = c + 1
                        else
                            table.insert(arr,{type=suitArr[a[n]],value=a[n]})
                        end
                    end
                    table.insert(cardsArr,arr)
				end
			end
		end
	end
	return cardsArr
end



--获取花色
function PokerUtils.getSuit(cards)
	local arr = {{},{},{},{},{}}
	for i=1,#cards do
		local suit = cards[i].type
		if suit ~= 5 then
			table.insert(arr[suit],cards[i])
		end
	end
	return arr
end



--同花
function PokerUtils.tonghua(cards, varietyC, index)
	if #cards < 5 then return {} end
	local cArr = PokerUtils.getGroupCards(cards, varietyC)
	local suitArr = PokerUtils.getSuit(cArr[7])
	local cardsArr = {}
	for i=4,1,-1 do
		local sArr = suitArr[i]
		if #sArr > 4 then
			for l=1,#sArr-4 do
				local arr = {sArr[l],sArr[l+1],sArr[l+2],sArr[l+3],sArr[l+4]}
				local a,b = PokerUtils.getHappydoggyShunzi(arr,0) -- 判断是否是顺子
				if #a ~= 5 then
					-- print("cardsArr:", sArr[l].value)
					table.insert(cardsArr,{sArr[l],sArr[l+1],sArr[l+2],sArr[l+3],sArr[l+4]})
				end
			end
			if #sArr > 5 then
				-- 乱序随机5组
				local arr = {sArr[1],sArr[3],sArr[4],sArr[5],sArr[6]}
				local a,b = PokerUtils.getHappydoggyShunzi(arr,0) -- 判断是否是顺子
				if #a ~= 5 then
					table.insert(cardsArr,{sArr[1],sArr[3],sArr[4],sArr[5],sArr[6]})
				end
				-- 乱序随机5组
				local arr = {sArr[1],sArr[2],sArr[4],sArr[5],sArr[6]}
				local a,b = PokerUtils.getHappydoggyShunzi(arr,0) -- 判断是否是顺子
				if #a ~= 5 then
					table.insert(cardsArr,{sArr[1],sArr[2],sArr[4],sArr[5],sArr[6]})
				end
				-- 乱序随机5组
				local arr = {sArr[1],sArr[2],sArr[3],sArr[5],sArr[6]}
				local a,b = PokerUtils.getHappydoggyShunzi(arr,0) -- 判断是否是顺子
				if #a ~= 5 then
					table.insert(cardsArr,{sArr[1],sArr[2],sArr[3],sArr[5],sArr[6]})
				end
				-- 乱序随机5组
				local arr = {sArr[1],sArr[2],sArr[3],sArr[4],sArr[6]}
				local a,b = PokerUtils.getHappydoggyShunzi(arr,0) -- 判断是否是顺子
				if #a ~= 5 then
					table.insert(cardsArr,{sArr[1],sArr[2],sArr[3],sArr[4],sArr[6]})
				end
			end
		end
	end
	local vArr = cArr[6] -- 如果有百变牌
	if #vArr > 0 and #vArr < 3 then
		for i=4,1,-1 do
			local sArr = suitArr[i]
			if #sArr < 5 and #sArr+#vArr > 4 then
				local suit = sArr[1].type
				for l=1,#vArr do
					for n=1,#sArr-(4-l) do
						if l == 1 then
							table.insert(cardsArr,{sArr[n],{type=5,value=sArr[n].value,suit=suit, old=sArr[1].value},sArr[n+1],sArr[n+2],sArr[n+3]})
						elseif l == 2 then
							table.insert(cardsArr,{sArr[n],{type=5,value=sArr[n].value,suit=suit, old=sArr[1].value},sArr[n+1],{type=5,value=sArr[n+1].value,suit=suit, old=sArr[2].value},sArr[n+2]})
						end
					end
				end
			end
		end
	end
	-- for i,v in ipairs(cardsArr) do
	-- 	print("tonghua:", #cards)
	-- 	for ii,vv in ipairs(v) do
	-- 		print(vv.type,vv.value)
	-- 	end
	-- end
	return cardsArr
end

--葫芦
function PokerUtils.hulu(cards, varietyC)
	if #cards < 5 then return {} end
	local cArr = PokerUtils.getGroupCards(cards, varietyC)
	local dzArr,stArr,vArr = cArr[2],cArr[3],cArr[6]
	local cardsArr = {}
	if #stArr > 0 then
		if #dzArr > 0 then
			for i=#stArr,1,-1 do
				table.insert(cardsArr,{stArr[i][1],stArr[i][2],stArr[i][3],dzArr[1][1],dzArr[1][2]})
			end
		else
			for i=#stArr,1,-1 do
				for l=1,#stArr do
					if l >= i then break end
					table.insert(cardsArr,{stArr[i][1],stArr[i][2],stArr[i][3],stArr[l][1],stArr[l][2]})
				end
			end
		end
	end
	if #vArr > 0 and #dzArr > 1 then
		for i=#dzArr,2,-1 do
			table.insert(cardsArr,{dzArr[i][1],dzArr[i][2],{type=5,value=dzArr[i][1].value,suit=dzArr[i][1].type == 4 and 3 or 4, old=vArr[1].value},dzArr[1][1],dzArr[1][2]})
		end
	end
	return cardsArr
end
--铁支
function PokerUtils.tiezhi(cards, varietyC)
	if #cards < 5 then return {} end
	local cArr = PokerUtils.getGroupCards(cards, varietyC)
	local wlArr,tzArr,vArr = cArr[1],cArr[4],cArr[6]
	local cardsArr = {}
	if #tzArr then
		if #wlArr > 0 then
			for i=#tzArr,1,-1 do
				table.insert(cardsArr,{tzArr[i][1],tzArr[i][2],tzArr[i][3],tzArr[i][4],wlArr[1]})
			end
		elseif #cArr[2] > 0 then
			for i=#tzArr,1,-1 do
				table.insert(cardsArr,{tzArr[i][1],tzArr[i][2],tzArr[i][3],tzArr[i][4],cArr[2][1][1]})
			end
		elseif #cArr[3] > 0 then
			for i=#tzArr,1,-1 do
				table.insert(cardsArr,{tzArr[i][1],tzArr[i][2],tzArr[i][3],tzArr[i][4],cArr[3][1][1]})
			end
		elseif #tzArr > 1 then
			for i=#tzArr,2,-1 do
				table.insert(cardsArr,{tzArr[i][1],tzArr[i][2],tzArr[i][3],tzArr[i][4],tzArr[1][1]})
			end
		end
	end
	if #vArr > 0 then
		for i=3,2,-1 do
			if i+#vArr < 4 then break end
			local arr,tzArr = cArr[i],{}
			if #arr > 0 then
				for l=#arr,1,-1 do
					local suitArr = PokerUtils.getMinSuit(arr[l])
					if i == 3 then
						table.insert(tzArr,{arr[l][1],arr[l][2],arr[l][3],{type=5,value=arr[l][1].value,suit=suitArr[1], old=vArr[1].value}})
					else
						table.insert(tzArr,{arr[l][1],arr[l][2],{type=5,value=arr[l][1].value,suit=suitArr[1], old=vArr[1].value},{type=5,value=arr[l][1].value,suit=suitArr[2], old=vArr[2].value}})
					end
				end
			end
			for l=1,#tzArr-(#wlArr > 0 and 0 or 1) do
				table.insert(cardsArr,{tzArr[l][1],tzArr[l][2],tzArr[l][3],tzArr[l][4],#wlArr > 0 and wlArr[1] or tzArr[#tzArr][1]})
			end
		end
		-- if #cardsArr < 1 and #wlArr > 1 and #vArr > 2 then
		-- 	for l=#wlArr,2,-1 do
		-- 		table.insert(cardsArr,{wlArr[l],{type=5,value=wlArr[l].value,suit=4},{type=5,value=wlArr[l].value,suit=3},{type=5,value=wlArr[l].value,suit=2},wlArr[1]})
		-- 	end
		-- end
	end
	return cardsArr
end


--删除相同点数
function PokerUtils.delCountSame(cArr)
	local arr,cardsArr = {},{}
	for i=1,#cArr do
		if not arr[cArr[i].value] then
			arr[cArr[i].value] = true
			table.insert(cardsArr,cArr[i])
		end
	end
	table.sort(cardsArr,PokerUtils.sortDescent)
	return cardsArr
end

--同花顺
function PokerUtils.tonghuashun(cards, varietyC)
	if #cards < 5 then return {} end
	local cArr = PokerUtils.getGroupCards(cards, varietyC)
	local suitArr = PokerUtils.getSuit(cArr[7]) -- 获取花色
	local cardsArr,thsArr,vArr = {},{},cArr[6]
	for i=4,1,-1 do
		local sArr = PokerUtils.delCountSame(suitArr[i])
		if #sArr > 4 then
			table.sort(sArr,PokerUtils.sortRise)
			if sArr[1].value == 13 and sArr[1].value == 12 and sArr[1].value == 11 and sArr[1].value == 10 and sArr[1].value == 9 then
				table.insert(cardsArr,{sArr[1],sArr[2],sArr[3],sArr[4],sArr[5]})
			end
			if sArr[1].value == 13 and sArr[#sArr-3].value == 4 and sArr[#sArr-2].value == 3 and sArr[#sArr-1].value == 2 and sArr[#sArr].value == 1 then
				table.insert(cardsArr,{sArr[1],sArr[#sArr-3],sArr[#sArr-2],sArr[#sArr-1],sArr[#sArr]})
			end
			for l=1,#sArr-4 do
				if sArr[l].value == sArr[l+1].value+1 and sArr[l+1].value == sArr[l+2].value+1 and sArr[l+2].value == sArr[l+3].value+1 and
					sArr[l+3].value == sArr[l+4].value+1 then
					table.insert(cardsArr,{sArr[l],sArr[l+1],sArr[l+2],sArr[l+3],sArr[l+4]})
				end
			end
			table.insert(thsArr,sArr)
		else
			table.insert(thsArr,sArr)
		end
	end
	if #vArr > 0 then
		for i=4,2,-1 do
			for l=1,#thsArr do
				local sArr = thsArr[l]
				if #sArr+#vArr > 4 then
					for n=1,#sArr-i+1 do
						local arr = {}
						for k=n,n+i-1 do
							table.insert(arr,sArr[k])
						end
						local suit = arr[1].type
						local a,b = PokerUtils.getHappydoggyShunzi(arr,#vArr)
						if #a == 5 then
							local arr,c = {},1
							for j=1,5 do
		                        if b[a[j]] then
		                            table.insert(arr,{type=5,value=a[j],suit=suit, old=vArr[c].value})
		                            c = c + 1
		                        else
		                            table.insert(arr,{type=suit,value=a[j]})
		                        end
		                    end
		                    table.insert(cardsArr,arr)
						end
					end
				end
			end
		end
	end
	-- for i,v in ipairs(cardsArr) do
	-- 	print("cardsArr:", i, #v)
	-- 	for ii,vv in ipairs(v) do
	-- 		print("value:",vv.value, vv.type)
	-- 	end
	-- end
	return cardsArr -- 返回所有的同花顺
end


--五同
function PokerUtils.wutong(cards)
	if #cards < 5 then return {} end
	local cArr = PokerUtils.getGroupCards(cards)
	local wlArr,dzArr,stArr,tzArr,wtArr,vArr = cArr[1],cArr[2],cArr[3],cArr[4],cArr[8],cArr[6]
	local cardsArr = {}
	if #wtArr > 0 then
		for i=#wtArr,1,-1 do
			table.insert(cardsArr,wtArr[i])
		end
	end
	if #vArr > 0 then
		if #vArr > 1 then
			for i=#stArr,1,-1 do
				local suitArr = PokerUtils.getMinSuit(stArr[i])
				table.insert(cardsArr,{stArr[i][1],stArr[i][2],stArr[i][3],{type=5,value=stArr[i][1].value,suit=suitArr[1], old=vArr[1].value},{type=5,value=stArr[i][1].value,suit=suitArr[2], old=vArr[2].value}})
			end
		end
		-- if #vArr > 2 then
		-- 	for i=#dzArr,1,-1 do
		-- 		local suitArr = PokerUtils.getMinSuit(dzArr[i])
		-- 		local arr = {dzArr[i][1],dzArr[i][2]}
		-- 		for l=1,3 do
		-- 			table.insert(arr,{type=5,value=dzArr[i][1].value,suit=suitArr[l]})
		-- 		end
		-- 		table.insert(cardsArr,arr)
		-- 	end
		-- end
		-- if #vArr > 3 then
		-- 	for i=#wlArr,1,-1 do
		-- 		local suitArr = PokerUtils.getMinSuit({wlArr[i]})
		-- 		local arr = {wlArr[i]}
		-- 		for l=1,4 do
		-- 			table.insert(arr,{type=5,value=wlArr[i].value,suit=suitArr[l]})
		-- 		end
		-- 		table.insert(cardsArr,arr)
		-- 	end
		-- end
		for i=#tzArr,1,-1 do
			local suitArr = PokerUtils.getMinSuit(tzArr[i])
			table.insert(cardsArr,{tzArr[i][1],tzArr[i][2],tzArr[i][3],tzArr[i][4],{type=5,value=tzArr[i][1].value,suit=suitArr[1], old=vArr[1].value}})
		end
		if #vArr >= 5 then
			local cArr,hpArr 	=	PokerUtils.getVariety(cards,varietyC)
			if #hpArr > 4 then
				table.insert(cardsArr,{hpArr[1],hpArr[2],hpArr[3],hpArr[4],hpArr[5]})
			end
		end
	end
	-- print("wutong cardsArr:", #cardsArr)
	return cardsArr
end

PokerUtils.tGroupName = {
	[1] = "wutong",
	[2] = "tonghuashun",
	[3] = "tiezhi",
	[4] = "hulu",
	[5] = "tonghua",
	[6] = "shunzi",
	[7] = "santiaoFive",
	[8] = "liangdui",
	[9] = "yiduiFive",
	[10] = "wulongFive"
}

PokerUtils.GroupName = {
	"乌龙","对子","两对","三条","顺子","同花","葫芦","铁支", "同花顺", "五同"
}

PokerUtils.t3GroupName = 
	{"PokerUtils.santiao","PokerUtils.yiduiThree","PokerUtils.wulongThree"}

PokerUtils.tGroup = {
	[1] = PokerUtils.wutong,
	[2] = PokerUtils.tonghuashun,
	[3] = PokerUtils.tiezhi,
	[4] = PokerUtils.hulu,
	[5] = PokerUtils.tonghua,
	[6] = PokerUtils.shunzi,
	[7] = PokerUtils.santiaoFive,
	[8] = PokerUtils.liangdui,
	[9] = PokerUtils.yiduiFive,
	[10] = PokerUtils.wulongFive
}

PokerUtils.tGroupDanse = {
	[1] = PokerUtils.wutong,
	[2] = PokerUtils.tiezhi,
	[3] = PokerUtils.tonghuashun,
	[4] = PokerUtils.hulu,
	[5] = PokerUtils.tonghua,
	[6] = PokerUtils.shunzi,
	[7] = PokerUtils.santiaoFive,
	[8] = PokerUtils.liangdui,
	[9] = PokerUtils.yiduiFive,
	[10] = PokerUtils.wulongFive
}


--牌型从小到到
function PokerUtils.sortRise(a,b)
	if a.value == b.value then
		return a.type < b.type
	end
	return a.value > b.value
end

--牌型花色排序从小到大
function PokerUtils.sortSuitRise(a,b)
	if a.type == b.type then
		return a.value > b.value
	end
	return a.type < b.type
end

--牌型从大到小
function PokerUtils.sortDescent(a,b)
	if a.value == b.value then
		return a.type < b.type
	end
	return a.value < b.value
end

-- 三同花 三顺子 六对半 四套三条 一条龙 清龙 六同-1
function PokerUtils.checkSpecial_small(cards, danse)
	table.sort(cards,PokerUtils.sortDescent) -- 从小到大排序
	local qys = true  -- 13 清一色
	local ytl = true  -- 12 一条龙
	local stst = true -- 5 四套三条
	local ldb = true  -- 3 六对半
	local ssz = true  -- 2 三顺子
	local sth = true  -- 1 三同花
	if danse then
		sth = false
	end
	local liutong = false -- -1 六同
	local suang_liutong = false
	local sType = cards[1].type    -- 第一张的类型
	local sYType = cards[1].type%2 -- 第一张的模
	local sPrevValue = nil           -- 上一张的值
	local sPrevType = nil            -- 上一张的类型
	local sSameTypes = {}            -- 同类型的牌
	local sSameValues = {}           -- 同值的牌
	local type_count = 0
	local value_count = 0
	for k,v in ipairs(cards) do
		if sPrevValue ~= nil then
			if v.value ~= sPrevValue+1 then
				ytl = false-- 一条龙
			end
		end
		if v.value < 10 then
			sehz = false-- 十二皇族
		end

        if v.type ~= sType then
			qys = false-- 清一色
        end

        local cur_types = sSameTypes[v.type]
        if cur_types == nil then
        	cur_types = {}
        	sSameTypes[v.type] = cur_types
        	type_count = type_count + 1
        end
        table.insert(cur_types, v)
        local cur_values = sSameValues[v.value]
        if cur_values == nil then
        	cur_values = {}
        	sSameValues[v.value] = cur_values
        	value_count = value_count + 1
        end
        table.insert(cur_values, v.type)

        sPrevValue = v.value
        sPrevType = v.type
    end

    if qys and ytl then
    	return 13,cards
    end
    if ytl then
    	return 12,cards
    end

    if sth then
	    if type_count == 2 or type_count == 3 then -- 三同花不能是两个颜色或者4个颜色
	    	for k,v in pairs(sSameTypes) do
	    		if #v ~= 3 and #v ~= 5 and #v ~= 8 and #v~= 10 then
	    			sth = false
	    			break
	    		end
	    	end
	    else
	    	sth = false
	    end
	end

    -- 找出三条的数量和对子的数量
    local san_num = 0
    local dui_num = 0
   
    -- 判断三顺子和六对半
    for k,v in pairs(sSameValues) do
		if #v == 2 then
			dui_num = dui_num + 1
		elseif #v == 3 then
			san_num = san_num + 1
			dui_num = dui_num + 1
		elseif #v == 4 or #v == 5 then
			san_num = san_num + 1
			dui_num = dui_num + 2
		elseif #v == 6 then
			if liutong then
				suang_liutong = true
			else
				liutong = true
			end	
		end

		if #v > 3 then
			ssz = false
		end
	end
	if suang_liutong then
		return -2, cards
	end

	if liutong then
		return -1, cards
	end

    -- 四个三条和一张
    if san_num < 4 then
    	stst = false
    end
    -- 六对半，六个对子加一张
    if dui_num < 6 then
    	ldb = false
    end

    if stst then
    	return 5,cards 
    end
    if ldb then return 3,cards end

    -- 找出所有的顺子[355,535,553]
    if ssz then
	    local array = PokerUtils.shunzi(cards)
        -- print("ssz:", #array)
		for k,v in pairs(array) do
			-- print("get_cardlog:", PokerUtils.get_cardlog(v))
			local sArr1 = PokerUtils.copy(cards)
			local arr1 = PokerUtils.delCards(sArr1, v)
			local array1 = PokerUtils.shunzi(arr1)
			for kk,vv in pairs(array1) do
				local sArr2 = PokerUtils.copy(arr1)
				local arr = PokerUtils.delCards(sArr2, vv)
				-- print("get_cardlog 2:", PokerUtils.get_cardlog(arr), #arr, arr[1].value == 13 and arr[2].value == 2 and arr[3].value == 1)
				if #arr == 3 and ((arr[1].value == arr[2].value+1 and  arr[2].value == arr[3].value+1) or
					arr[1].value == 13 and arr[2].value == 2 and arr[3].value == 1) then
					cards = {}
					for kkk,vvv in pairs(v) do
						table.insert(cards, vvv)
					end
					for kkk,vvv in pairs(vv) do
						table.insert(cards, vvv)
					end
					for kkk,vvv in pairs(arr) do
						table.insert(cards, vvv)
					end
					return 2,cards -- 2 三顺子
				end
			end
		end
	end

	if sth then -- 三同花
		local temp_cards = {}
		local temp_three = nil
		for k,v in pairs(sSameTypes) do
			if #v == 3 then
				temp_three = v
			else
				for kk,vv in pairs(v) do
					table.insert(temp_cards, vv)
				end
			end
		end
		if temp_three then
			for kk,vv in pairs(temp_three) do
				table.insert(temp_cards, vv)
			end
		end
		return 1,temp_cards 
	end  -- 1 三同花
end

-- 三同花 三顺子 六对半 四套三条 一条龙 清龙
function PokerUtils.checkSpecial_variety(cards)
	table.sort(cards,PokerUtils.sortDescent) -- 从小到大排序
	local qys = true  -- 13 清一色
	local ytl = true  -- 12 一条龙
	local stst = true -- 5 四套三条
	local ldb = true  -- 3 六对半
	local ssz = true  -- 2 三顺子
	local sth = true  -- 1 三同花
	local liutong = false -- -1 六同
	local suang_liutong = false -- -2 双六同
	local sType = cards[1].type    -- 第一张的类型
	local sYType = cards[1].type%2 -- 第一张的模
	local sPrevValue = nil           -- 上一张的值
	local sPrevType = nil            -- 上一张的类型
	local sSameTypes = {}            -- 同类型的牌
	local sSameValues = {}           -- 同值的牌
	local type_count = 0
	local value_count = 0

	local sp_num = 0  -- 赖子数量

	local ql = {}
	local ql_need = {13,13,13,13}
	for i=1,4 do
		local temp = {}
		for j=1,13 do
			table.insert(temp, {type=i, value=j, check=false})
		end
		table.insert(ql, temp)
	end

	local no_variety_cards = {}
	local variety_cards = {}

	for k,v in ipairs(cards) do
		if v.value > 13 then
			sp_num = sp_num + 1
			table.insert(variety_cards, v)
		else
			local cur_types = sSameTypes[v.type]
	        if cur_types == nil then
	        	cur_types = {}
	        	sSameTypes[v.type] = cur_types
	        	type_count = type_count + 1
	        end
	        table.insert(cur_types, v)
	        local cur_values = sSameValues[v.value]
	        if cur_values == nil then
	        	cur_values = {}
	        	sSameValues[v.value] = cur_values
	        	value_count = value_count + 1
	        end
	        table.insert(cur_values, v.type)
	        table.insert(no_variety_cards, v)

	        local item = ql[v.type][v.value]
	        if item.check == false then
	        	ql_need[v.type] = ql_need[v.type] - 1
	        	item.check = true
	        end
		end

        sPrevValue = v.value
        sPrevType = v.type
    end
    -- 没有大小鬼
    if sp_num == 0 then
    	return PokerUtils.checkSpecial_small(cards)
    end
    for i=1,4 do
    	if sp_num - ql_need[i] >= 0 then
	    	return 13, ql[i] -- 清龙
	    end
    end
    -- 判断一条龙
    if sp_num + value_count == 13 then
    	return 12,cards
    end

    if sth then
	    if type_count == 2 or type_count == 3 then -- 三同花不能是两个颜色或者4个颜色
	    	local use_sp_num = sp_num
	    	for k,v in pairs(sSameTypes) do
	    		if #v == 1 and use_sp_num > 1 then
	    			use_sp_num = use_sp_num - 2
	    		elseif #v == 2 and use_sp_num > 0 then
	    			use_sp_num = use_sp_num - 1
	    		elseif #v == 4 and use_sp_num > 0 then
	    			use_sp_num = use_sp_num - 1
	    		elseif #v == 6 and use_sp_num > 1 then
	    			use_sp_num = use_sp_num - 2
	    		elseif #v == 7 and use_sp_num > 0 then
	    			use_sp_num = use_sp_num - 1
	    		elseif #v == 9 and  use_sp_num > 0 then
	    			use_sp_num = use_sp_num - 1
	    		else
	    			sth = false
	    			break
	    		end
	    	end
	    elseif type_count == 1 then
	    else
	    	sth = false
	    end
	end

    -- 找出三条的数量和对子的数量
    local san_num = 0
    local dui_num = 0
   	local si_num = 0
   	local real_dui_num = 0
   	local dan_num = 0 -- 散牌数量

    -- 判断三顺子和六对半
    local use_sp_num = sp_num
    for k,v in pairs(sSameValues) do
    	if #v == 1 then
    		dan_num = dan_num + 1
		elseif #v == 2 then
			dui_num = dui_num + 1
			real_dui_num = real_dui_num + 1
		elseif #v == 3 then
			san_num = san_num + 1
			dui_num = dui_num + 1
		elseif #v == 4 or #v == 5 then
			san_num = san_num + 1
			dui_num = dui_num + 2
			si_num = si_num + 1
			if #v + use_sp_num == 6 then
				if liutong then
					suang_liutong = true
				else
					liutong = true
				end
				use_sp_num = use_sp_num - (6 - #v)
			end
		end

		if #v > 3 then
			ssz = false
		end
	end
	if suang_liutong then
		return -2, cards
	end

	if liutong then
		return -1, cards
	end

    -- 四个三条和一张
    if san_num < 4 then
    	if san_num == 2 and sp_num > 1 then
    		if real_dui_num == 2 then
    		else
    			stst = false
    		end
    	elseif san_num == 3 then
    		if (sp_num > 0 and real_dui_num == 1) or sp_num > 1 then
    		else
    			stst = false
    		end
    	else
    		stst = false
    	end
    end
    -- 六对半，六个对子加一张
    if dan_num - sp_num > 1 then
    	ldb = false
    end

    if stst then
    	return 5,cards 
    end
    if ldb then return 3,cards end

    -- 找出所有的顺子[355,535,553]
    if ssz then
	    local array = PokerUtils.shunzi(cards)
        -- print("ssz:", #array)
		for k,v in pairs(array) do
			-- print("get_cardlog:", PokerUtils.get_cardlog(v))
			local sArr1 = PokerUtils.copy(cards)
			local arr1 = PokerUtils.delCards(sArr1, v)
			local array1 = PokerUtils.shunzi(arr1)
			for kk,vv in pairs(array1) do
				local sArr2 = PokerUtils.copy(arr1)
				local arr = PokerUtils.delCards(sArr2, vv)
				-- print("get_cardlog 2:", PokerUtils.get_cardlog(arr), #arr, arr[1].value == 13 and arr[2].value == 2 and arr[3].value == 1)
				if #arr == 3 and ((arr[1].value == arr[2].value+1 and  arr[2].value == arr[3].value+1) or
					arr[1].value == 13 and arr[2].value == 2 and arr[3].value == 1) then
					cards = {}
					for kkk,vvv in pairs(v) do
						table.insert(cards, vvv)
					end
					for kkk,vvv in pairs(vv) do
						table.insert(cards, vvv)
					end
					for kkk,vvv in pairs(arr) do
						table.insert(cards, vvv)
					end
					return 2,cards -- 2 三顺子
				end
			end
		end
	end

	if sth then -- 三同花
		local temp_cards = {}
		local temp_three = nil
		for k,v in pairs(sSameTypes) do
			for kk,vv in pairs(v) do
				table.insert(temp_cards, vv)
			end
			for kk,vv in pairs(variety_cards) do
				table.insert(temp_cards, vv)
			end
		end
		return 1,temp_cards 
	end  -- 1 三同花
end

function PokerUtils.checkSpecial(cards, danse, variety)
	if variety then
		return PokerUtils.checkSpecial_variety(cards)
	else
		return PokerUtils.checkSpecial_small(cards, danse)
	end
end

function PokerUtils.getSpecialScore(t)
--	{'三同花','三顺子','六对半','五对三条','四套三条','凑一色','全小',
--	'全大','三分天下','三同花顺','十二皇族','一条龙','清龙'}
	local data = {6, 6, 6, 8, 10, 15, 10, 20, 26, 32, 24, 52, 108}
	return data[t]
end

function PokerUtils.getSpecialScore_small(t)
--	{'三同花','三顺子','六对半','五对三条','四套三条','凑一色','全小',
--	'全大','三分天下','三同花顺','十二皇族','一条龙','清龙'}
	local data = {6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 52, 108}
	data[-1] = 20
	data[-2] = 100
	return data[t]
end

function PokerUtils.getNomalScore(pos, com, danse)
	local value = nil
	if danse then
		if Config.channel == 'dyj' then
			if pos == 3 and (com == 4 or com == 11 ) then -- 冲三
	            value = 2
	        elseif pos == 2 and (com == 7 or com == 13) then -- 中墩葫芦
	            value = 1
	        elseif com == 8 and pos == 2 then
	            value = 9  -- 铁支中道
	        elseif com == 8 and pos == 1 then
	            value = 7  -- 铁支尾道
	        elseif com == 9 and pos == 2 then
	            value = 9  -- 同花顺中道
	        elseif com == 9 and pos == 1 then
	            value = 4  -- 同花顺尾道
	        elseif com == 10 and pos == 2 then
	            value = 31 -- 五同中道
	        elseif com == 10 and pos == 1 then
	            value = 15  -- 五同尾道
	        end
	    else
	    	-- [乌龙1，对子2，两对3，三条4，顺子5，同花6，葫芦7，铁支8，同花顺9, 五同10 中墩葫芦13]
	        if pos == 3 and (com == 4 or com == 11 ) then -- 冲三
	            value = 2
	        elseif pos == 2 and (com == 7 or com == 13) then -- 中墩葫芦
	            value = 1
	        elseif com == 8 and pos == 2 then
	            value = 19  -- 铁支中道
	        elseif com == 8 and pos == 1 then
	            value = 9  -- 铁支尾道
	        elseif com == 9 and pos == 2 then
	            value = 9  -- 同花顺中道
	        elseif com == 9 and pos == 1 then
	            value = 4  -- 同花顺尾道
	        elseif com == 10 and pos == 2 then
	            value = 39 -- 五同中道
	        elseif com == 10 and pos == 1 then
	            value = 19  -- 五同尾道
	        end
	    end
	else
		-- [乌龙1，对子2，两对3，三条4，顺子5，同花6，葫芦7，铁支8，同花顺9, 五同10 中墩葫芦13]
        if pos == 3 and (com == 4 or com == 11 ) then -- 冲三
            value = 2
        elseif pos == 2 and (com == 7 or com == 13) then -- 中墩葫芦
            value = 1
        elseif com == 8 and pos == 2 then
            value = 7  -- 铁支中道
        elseif com == 8 and pos == 1 then
            value = 3  -- 铁支尾道
        elseif com == 9 and pos == 2 then
            value = 9  -- 同花顺中道
        elseif com == 9 and pos == 1 then
            value = 4  -- 同花顺尾道
        elseif com == 10 and pos == 2 then
            value = 19 -- 五同中道
        elseif com == 10 and pos == 1 then
            value = 9  -- 五同尾道
        end
	end
	-- print("getNomalScore:", pos, com, value)
	return value
end

-- 一定要从小到大
local function find_big( index, a, b )
	-- print("find_big:", index, a[1].value, a[2].value)
	assert(a[1].value <= a[2].value)
	assert(b[1].value <= b[2].value)
	-- 比较单张
	local size = 5
	if index == 11 then
		size = 3
	end
	for i=index+size-1,index,-1 do
		if a[i].value > b[i].value then
			return true
		elseif a[i].value < b[i].value then
			return false
		end
	end
end

function PokerUtils.compare_wutong( index, a, b )
	if a[index+2].value == b[index+2].value then
		return nil 
	else
		return a[index+2].value > b[index+2].value
	end
end
function PokerUtils.compare_tonghuashun( index, a, b )
	-- 比较A2345 和 (9 10 11 12 A) 以及其它
	local temp_a = {}
	local temp_b = {}
	for i=0,4 do
		table.insert(temp_a, a[index+i])
		table.insert(temp_b, b[index+i])
	end

	local rec = PokerUtils.isMessireFive(9,temp_a,temp_b)
	if rec == nil then
		return nil
	else
		return not rec
	end
end
function PokerUtils.compare_tiezhi( index, a, b )
	return PokerUtils.compare_wutong( index, a, b )
end
function PokerUtils.compare_hulu( index, a, b )
	if a[index+2].value == b[index+2].value then
		if a[index].value == b[index].value and a[index+3].value == b[index+3].value then
			return nil 
		else
			if a[index].value ~= b[index].value then
				return a[index].value > b[index].value
			else
				return a[index+3].value > b[index+3].value
			end
		end
	else
		return a[index+2].value > b[index+2].value
	end
end
function PokerUtils.compare_tonghua( index, a, b )
	-- if Config.channel == 'dyj' then
	-- 	return find_big(index , a, b)
	-- end
	-- -- 判断是否有一对，两对或者三根 -- 大赢家要求，特殊处理，同花不判断对子和三根
	-- -- 检查a牌组的牌型
	-- local tab_a = {}
	-- local tab_b = {}
	-- local size_a = 0
	-- local size_b = 0
	-- for i=index,index+4 do
	-- 	local v = a[i].value
	-- 	if tab_a[v] then
	-- 		tab_a[v] = tab_a[v] + 1
	-- 	else
	-- 		tab_a[v] = 1
	-- 		size_a = size_a + 1
	-- 	end
	-- 	v = b[i].value
	-- 	if tab_b[v] then
	-- 		tab_b[v] = tab_b[v] + 1
	-- 	else
	-- 		tab_b[v] = 1
	-- 		size_b = size_b + 1
	-- 	end
	-- end

	-- if size_a <3 or size_b<3 then
	-- 	local strs = {}
	-- 	table.insert(strs, ' a:')
	-- 	for k,v in pairs(a) do
	-- 		table.insert(strs, v.value)
	-- 	end
	-- 	table.insert(strs, ' b:')
	-- 	for k,v in pairs(b) do
	-- 		table.insert(strs, v.value)
	-- 	end
	-- 	LOG_ERROR("error compare_tonghua:", index, #tab_a, #tab_b, table.concat( strs, ", "))
	-- 	return
	-- end

	-- if size_a ~= size_b then
	-- 	return size_a < size_b
	-- else
	-- 	if size_a == 4 then -- 对子
	-- 		-- 找出对子，优先比较
	-- 		local dui_a = nil
	-- 		local dui_b = nil
	-- 		for k,v in pairs(tab_a) do
	-- 			if v == 2 then
	-- 				dui_a = k
	-- 				break
	-- 			end
	-- 		end
	-- 		for k,v in pairs(tab_b) do
	-- 			if v == 2 then
	-- 				dui_b = k
	-- 				break
	-- 			end
	-- 		end
	-- 		if dui_a ~= dui_b then
	-- 			return dui_a > dui_b
	-- 		end
	-- 	elseif size_a == 3 then -- 三条
	-- 		local san_a = nil
	-- 		local san_b = nil
	-- 		for k,v in pairs(tab_a) do
	-- 			if v == 3 then
	-- 				san_a = k
	-- 				break
	-- 			end
	-- 		end
	-- 		for k,v in pairs(tab_b) do
	-- 			if v == 3 then
	-- 				san_b = k
	-- 				break
	-- 			end
	-- 		end
	-- 		if san_a ~= san_b then
	-- 			return san_a > san_b
	-- 		end
	-- 	end
	-- end
	return find_big(index , a, b)
end
function PokerUtils.compare_shunzi( index, a, b )
	local temp_a = {}
	local temp_b = {}
	for i=0,4 do
		table.insert(temp_a, a[index+i])
		table.insert(temp_b, b[index+i])
	end

	local rec = PokerUtils.isMessireFive(5,temp_a,temp_b)
	if rec == nil then
		return nil
	else
		return not rec
	end
end
function PokerUtils.compare_santiao( index, a, b )
	if a[index+2].value == b[index+2].value then
		return find_big(index, a, b)
	else
		return a[index+2].value > b[index+2].value
	end
end
function PokerUtils.compare_liangdui( index, a, b )
	local a_s = nil -- 单牌
	local b_s = nil
	local a_dui1 = nil
	local a_dui2 = nil
	local b_dui1 = nil
	local b_dui2 = nil
	index = index - 1
	
	if a[index+2].value == a[index+3].value and a[index+4].value == a[index+5].value then ---1
		a_dui1 = a[index+2].value
		a_dui2 = a[index+4].value
		a_s = a[index+1].value
	elseif a[index+1].value == a[index+2].value and a[index+4].value == a[index+5].value  then -- 3
		a_dui1 = a[index+1].value
		a_dui2 = a[index+4].value
		a_s = a[index+3].value
	elseif a[index+1].value == a[index+2].value and a[index+3].value == a[index+4].value then -- 5
		a_dui1 = a[index+1].value
		a_dui2 = a[index+3].value
		a_s = a[index+5].value
	end
	
	if b[index+2].value == b[index+3].value and b[index+4].value == b[index+5].value then ---1
		b_dui1 = b[index+2].value
		b_dui2 = b[index+4].value
		b_s = b[index+1].value
	elseif b[index+1].value == b[index+2].value and b[index+4].value == b[index+5].value  then -- 3
		b_dui1 = b[index+1].value
		b_dui2 = b[index+4].value
		b_s = b[index+3].value
	elseif b[index+1].value == b[index+2].value and b[index+3].value == b[index+4].value then -- 5
		b_dui1 = b[index+1].value
		b_dui2 = b[index+3].value
		b_s = b[index+5].value
	end

	if a_dui1 == nil or b_dui1 == nil or a_dui2 == nil or b_dui2 == nil then
		local strs = {}
		table.insert(strs, ' a:')
		for k,v in pairs(a) do
			table.insert(strs, v.value)
		end
		table.insert(strs, ' b:')
		for k,v in pairs(b) do
			table.insert(strs, v.value)
		end
		LOG_ERROR("error compare_liangdui:", index, table.concat( strs, ", "))
		return
	end
	-- print(a_dui1, b_dui1, a_dui2, b_dui2, 'a_s, b_s',a_s, b_s)
	if a_dui1 == b_dui1 and a_dui2 == b_dui2 and a_s == b_s then
		return
	elseif a_dui2 == b_dui2 and a_dui1 == b_dui1  then
		return a_s > b_s
	elseif a_dui2 == b_dui2 then
		return a_dui1 > b_dui1
	else
		return a_dui2 > b_dui2
	end

end
function PokerUtils.compare_yidui( index, a, b )
	local a_d = nil -- 对子
	local pre = nil
	local b_d = nil
	local size = 4+index
	if index == 11 then
		size = 2+index
	end
	for i=index,size do
		if pre == a[i].value then
			a_d = pre
			break
		end
		pre = a[i].value
	end
	pre = nil
	for i=index,size do
		if pre == b[i].value then
			b_d = pre
			break
		end
		pre = b[i].value
	end
	if a_d == b_d then
		return find_big(index, a, b)
	else
		return a_d>b_d
	end
end
function PokerUtils.compare_wulong( index, a, b )
	return find_big(index, a, b)
end

PokerUtils.compare = {
	[1] = PokerUtils.compare_wulong,
	[2] = PokerUtils.compare_yidui,
	[3] = PokerUtils.compare_liangdui,
	[4] = PokerUtils.compare_santiao,
	[5] = PokerUtils.compare_shunzi,
	[6] = PokerUtils.compare_tonghua,
	[7] = PokerUtils.compare_hulu,
	[8] = PokerUtils.compare_tiezhi,
	[9] = PokerUtils.compare_tonghuashun,
	[10] = PokerUtils.compare_wutong,	
}

function PokerUtils.get_cardlog( cards )
	local cards_str = {}
	for k,v in pairs(cards) do
		table.insert(cards_str, "{type=")
        table.insert(cards_str, v.type)
        table.insert(cards_str, ", value=")
        table.insert(cards_str, v.value)
        table.insert(cards_str, "},")
	end
	return table.concat( cards_str, "")
end

function PokerUtils.get_liutong_value( cards )
	local sSameValues = {}
	for k,v in pairs(cards) do
		local cur_values = sSameValues[v.value]
		if cur_values == nil then
        	cur_values = {}
        	sSameValues[v.value] = cur_values
        	value_count = value_count + 1
        end
        table.insert(cur_values, v.type)
        if #cur_values == 6 then
        	return v.value
        end
	end
end

function PokerUtils.check_pai_type( cards, types )
	-- 检查前面三张牌
	local cur_type = types[3]
	local cur_card = {cards[11],cards[12],cards[13]}
	if cur_type == 11 or cur_type == 4 then
		cur_type = 3
	end
	local group = {PokerUtils.wulongThree, PokerUtils.yiduiThree, PokerUtils.santiao}
	if cur_type~=1 and #group[cur_type](cur_card) == 0 then
		return
	end

	-- 中间5张
	cur_type = 11-types[2]
	cur_card = {cards[6],cards[7],cards[8],cards[9],cards[10]}
	if cur_type~=10 and #PokerUtils.tGroup[cur_type](cur_card) == 0 then
		print("cur_type:", cur_type)
		return
	end

	-- 尾道5张
	cur_type = 11-types[1]
	cur_card = {cards[1],cards[2],cards[3],cards[4],cards[5]}
	if cur_type~=10 and #PokerUtils.tGroup[cur_type](cur_card) == 0 then
		print("cur_type:", cur_type)
		return
	end

	return true
end

return PokerUtils
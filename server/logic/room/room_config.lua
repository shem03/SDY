local cmd = {}

function cmd.init_room()
	local rooms = {
		[1] = { -- 普通场
			index = {},
			private = {},
		},
		[2] = { -- 多三张
			index = {},
			private = {},
		},
		[3] = { -- 麻将
			index = {},
			private = {},
		},
		[4] = { -- 斗牛
			index = {},
			private = {},
		},
		[5] = { -- 牌九
			index = {},
			private = {},
		},
		[6] = {	-- 牛牛
			index = {},
			private = {},
		},
		[7] = {	-- 红包
			index = {},
			private = {},
		},
		[8] = {	-- 红包2.0
			index = {},
			private = {},
		},
		[9] = {	-- 大菠萝
			index = {},
			private = {},
		}

	}
	local all = {}

	for k,v in pairs(rooms) do
		local game_type = "poker"
		local have_banker = 0
		local card_num = 13
		local variety = nil -- 带鬼
		local max_count = 4
		local min_count = 4
		if k == 3 then
			game_type = "mahjong"
			have_banker = 1
			card_num = 16
		elseif k == 4 then
			game_type = "bullfight"
			have_banker = 1
			card_num = 5
		elseif k == 5 then
			game_type = "paigow"
			have_banker = 1
			card_num = 2
		elseif k == 6 then
			game_type = "cow"
			have_banker = 1
			card_num = 5
		elseif k== 7 then
			game_type = "hongbao"
			have_banker = 1
			card_num = 3
		elseif k== 9 then
			game_type = "daboluo"
			card_num = 17
			max_count = 3
			min_count = 3
		end
		for i=1,1000 do
			local roomid = k*100000+i
			local room = {
				roomid = roomid,
				room_type = k,
				game_type = game_type,
				member_count = 0,
				max_count = max_count,			--最多人数（十三水）、几人场（福州麻将）
				min_count = min_count,
				have_banker = have_banker,
				room_card = 0,          --需要的房卡
				room_coin = Config.table_fee,        --需要的金币
				min_coin = 10*Config.table_fee,      --需要最少多少金币进入房间 
				card_num = card_num,          -- 牌数
				private = false,
				cheat_uid = nil,
				variety = nil,
				members = {},
			}
			table.insert(v["index"], room)
			all[roomid] = room

			local roomid = k*100000+i+1000
			local room = {
				roomid = roomid,
				room_type = k,
				game_type = game_type,
				member_count = 0,
				max_count = max_count,	
				min_count = min_count,
				have_banker = have_banker,
				room_card = 0,        --需要的房卡
				room_coin = 0,         --需要的金币
				min_coin = 0, 
				card_num = card_num,
				private = true,
				cheat_uid = nil,
				members = {},
			}
			table.insert(v["private"], room)
			all[roomid] = room
		end	
	end
	
	rooms.all = all
	return rooms
end

return cmd


local function init()
	local json = require("cjson")
	local db_mgr = require("db_mgr")
	-- 初始化房卡和局数配置
	Config.room_round = json.decode(db_mgr.get_config("room_round"))
	-- LOG("Config.room_round:", Config.room_round[1], Config.room_round[2], Config.room_round[3])
	Config.room_card = json.decode(db_mgr.get_config("room_card"))

	Config.channel = db_mgr.get_config("channel")

	--Config.share_money = tonumber(db_mgr.get_config("share_money"))
	--Config.server_status = tonumber(db_mgr.get_config("server_status"))
end
Config_init = init
-- 十三水 步骤配置
Config = {
	robot = true,
	table_fee = 200, -- 桌费
	-- 大赢家
	room_card = 98,  -- 10局房卡
	-- 丁丁
	-- room_card = 20,  -- 10局房卡

	-- 红包每日返利利率
	hongbao_rate = 0.003,

	step_none = 0,
	step_fee = 1,       -- 扣钱
	step_deal_card = 2, -- 发牌
	step_compare = 3,   -- 比牌
	step_over = 4,      -- 游戏结束

	auto_card_time = 100, -- 超时出牌时间
	auto_del_room = 600,  -- 10分钟解散房间

	ask_quit_time = 60,   -- 请求退出房间的初始时间

	-- 错误消息ID 
	error_code_no_room = -101,  -- 房间不存在
	error_code_re_login = -102, -- 重复登录

	add_point = {
		[2] = {1, 0},
		[3] = {2, 1, 0},
		[4] = {3, 2, 1, 0},
		[5] = {4, 2, 1, 0, 0},
		[6] = {5, 3, 2, 1, 0, 0}
	},

	-- 牛牛配置
	bf_bet = {10, 50, 100},
	bf_bet_time = 20, -- 下注时间
	bf_auto_card_time = 99, -- 出牌时间

	-- 转盘配置
	lottery_config = {
		{type="money", value=1},
		{type="money", value=2},
		{type="money", value=3},
		{type="money", value=5},
		{type="money", value=10},
		{type="money", value=15},
		{type="money", value=20},
		{type="money", value=50},
		{type="money", value=80},
		{type="money", value=100},
		{type="money", value=120},
		{type="money", value=250},
	},

	-- 红包
	-- 红包状态
	step_rob       = 1,		-- 抢庄
	step_biao	   = 8,		-- 标庄
	step_biao_end  = 9,		-- 标庄结束
	step_bet       = 2,		-- 下注开始
	step_bet_end   = 10,	-- 下注结束
	step_send      = 3,		-- 发包
	step_qiang     = 4,		-- 抢包
	step_wait_result= 7,	-- 等待结算
	step_result    = 5,		-- 结算
	step_flow	   = 6,		-- 流局

	hb_bet_time    = 60, --60,       -- 下注时间
	hb_biao_time   = 10, --10,       -- 标庄时间
	hb_wait_send   = 15, --15,       -- 等待发包
	hb_qiang_time  = 21, --21,	     -- 抢包时间
	hb_wait_result_time  = 20, --20  -- 等待结算时间
	hb_reuslt_time = 20, -- 20	     -- 结算时间 等待下局开始

	hb_room_water = 5,				 -- 房间钻石消耗
	hb_rob_banker_pump_rate = 50,    -- 上庄抽佣
	hb_banker_win_pump_rate = 0.06,  -- 庄赢抽佣
	hb_user_win_pump_rate   = 0.03,  -- 闲赢抽佣

	hb_report_info_num = 20,	         -- 播报缓存信息数量

	-- 红包下注类型
	hb_bet_cow_double         = 1,
	hb_bet_cow_no_doubel      = 2,
	hb_bet_size_dan_shuang_he = 3,
	hb_bet_special_point	  = 4,

	-- 下注区间配置(根据房间段位来区分)
	hb_bet_range_config = {
		["8A"] = {
			[1] = {10, 5000},   -- 牛牛翻倍
			[2] = {6, 50000},   -- 牛牛不翻倍
			[3] = {100, 50000}, -- 大小单双合
			[4] = {100, 10000}, -- 特殊点数
		},
		["8B"] = {
			[1] = {2, 5000},   -- 牛牛翻倍
			[2] = {5, 50000},   -- 牛牛不翻倍
			[3] = {5, 50000}, -- 大小单双合
			[4] = {5, 10000}, -- 特殊点数
		}
	},

	-- 红包签到转盘奖励配置
	sign_in_config = {18,28,38,58,68,78,88},

	-- 红包倍数
	-- 牛牛翻倍
	hb_rate_cow_double = {
		[1] = 5,	-- 牛一
		[2] = 5,	-- 牛二
		[3] = 5,	-- 牛三
		[4] = 5,	-- 牛四
		[5] = 5,	-- 牛五
		[6] = 6,	-- 牛六
		[7] = 7,	-- 牛七
		[8] = 8,	-- 牛八
		[9] = 9,	-- 牛九
		[10] = 10,  -- 牛十
	},

	-- 大小单双
	hb_rate_size_dan_shuang_he = {
		[1] = 1,	-- 大
		[2] = 1,	-- 小
		[3] = 1,    -- 单
		[4] = 1,    -- 双
		[5] = 4,	-- 大单
		[6] = 2,	-- 小单
		[7] = 2,    -- 大双
		[8] = 4,    -- 小双
		[9] = 5,    -- 和
	},

	hb_point_collect_type = {
		[11] = "金牛奖",
		[12] = "对子奖",
		[13] = "正顺奖",
		[14] = "倒顺奖",
		[15] = "满牛奖",
		[16] = "豹子奖",
	},

	-- 连胜奖励配置
	hb_winning_streak_config = {
		[6] = {666, 1111},
		[7] = {1333, 2222},
		[8] = {1999, 3333},
		[9] = {2666, 4444},
		[10] = {3333, 5555},
		[11] = {3999, 6666},
		[12] = {4666, 7777},
		[13] = {5333, 8888},
		[14] = {5999, 9999},
		[15] = {6666, 11111},
		[16] = {7333, 12222},
		[17] = {7999, 13333},
		[18] = {8666, 14444},
		[19] = {9333, 15555},
		[20] = {9999, 16666},
	},

	-- 特殊点奖励配置
	hb_special_config = {
		["5.00"] = {555, 1088},
		["6.00"] = {666, 1388},
		["7.00"] = {777, 1688},
		["8.00"] = {888, 1999},
		["9.00"] = {999, 2388},
		["5.55"] = {555, 1088},
		["6.66"] = {666, 1388},
		["7.77"] = {777, 1688},
		["8.88"] = {888, 1999},
		["9.99"] = {999, 2388},
	},

	-- 特殊点奖励配置
	hb_tidy_together_config = {
		[11] = {
			[5] = {1388, 2888},
			[6] = {1888, 3888},
			[7] = {2388, 4888},
			[8] = {2888, 5888},
			[9] = {3388, 6888},
		},
		[12] = {
			[5] = {1388, 2888},
			[6] = {1888, 3888},
			[7] = {2388, 4888},
			[8] = {2888, 5888},
			[9] = {3388, 6888},
		},
		[13] = {
			[3] = {1388, 2888},
			[4] = {1888, 3888},
			[5] = {2388, 4888},
			[6] = {2888, 5888},
			[7] = {3388, 6888},
		},
		[14] = {
			[3] = {1388, 2888},
			[4] = {1888, 3888},
			[5] = {2388, 4888},
			[6] = {2888, 5888},
			[7] = {3388, 6888},
		},
		[15] = {
			[3] = {1388, 2888},
			[4] = {1888, 3888},
			[5] = {2388, 4888},
			[6] = {2888, 5888},
			[7] = {3388, 6888},
			[8] = {3888, 7888},
			[9] = {4388, 8888},
		},
		[16] = {
			[3] = {1388, 2888},
			[4] = {1888, 3888},
			[5] = {2388, 4888},
			[6] = {2888, 5888},
			[7] = {3388, 6888},
			[8] = {3888, 7888},
			[9] = {4388, 8888},
		},
	},

	-- 最少多少下注 不足算流局
	hb_minimum_bet = 5,

	-- open golden
	hb_open_add_cash = true,

	-- 赛车
	-- 赛车状态
	pk_bet_start       	= 1,		-- 开始下注
	pk_step_bet		    = 2,		-- 下注中
	pk_bet_end	   		= 3,		-- 下注结束
	pk_wait_kaijiang  	= 4,		-- 等待开奖，封盘
	pk_kaijiang      	= 5,		-- 比车
	pk_bipai            = 6,		-- 比牌
	pk_result   		= 7,		-- 结算

	pk_banker_win_pump_rate = 0.05,  -- 庄赢抽佣
	pk_user_win_pump_rate   = 0.05,  -- 闲赢抽佣

	--------------------------------------------------------------------------------
	-- 猜拳游戏
	-- 猜拳游戏状态
    step_guess_bet_start = 1,     -- 开始下注
    step_guess_bet_end = 2,       -- 下注结束
    step_guess_punches_start = 3, -- 出拳开始
    step_guess_punches_end = 4,   -- 出拳结束
    step_guess_wait_result = 5,   -- 等待结算
    step_guess_result = 6,        -- 游戏结算
    step_guess_flow = 7,          -- 流局
    step_guess_game_over = 8, 	  -- 游戏结束

	-- 猜拳游戏每个阶段持续时间
    time_guessing_bet = 60,       	  -- 下注时间
    time_guessing_punches = 30,   	  -- 出拳时间
    time_guessing_wait_result = 5, 	  -- 结算等待时间

	fist_scissors = 1, 			-- 剪刀 
	fist_rock = 2,				-- 石头
	fist_paper = 3, 		    -- 布

	-- 猜拳胜负情况
	status_tie = 1, 			-- 双方打平
	status_someone_win = 2, 	-- 一方胜出

	-- 猜拳邀请状态
	invite_guessing_wait_reply = 0, -- 等待答复
	invite_guessing_refuse = 1, 	-- 拒绝邀请
	invite_guessing_accept = 2, 	-- 接受邀请
	invite_guessing_timeout = 3, 	-- 超时邀请

	-- 猜拳游戏结束方式 
	game_normal_end = 1,  		-- 正常结束
	game_exit_end = 2, 			-- 玩家退出游戏 
	game_flow_bureau = 3, 		-- 流局

	--------------------------------------------------------------------------------
	-- 消息类型
	msg_type_system = 1, 		-- 系统消息
	msg_type_normal = 2,		-- 普通消息
	msg_type_barrage = 3,		-- 弹幕消息

	barrage_card = 2, 			-- 发送一条弹幕消息所需要的弹幕卡数量
}

-- 福州麻将 配置
Mj_Config = {
	is_need_log = true,			-- 游戏步骤是否需要记录到mysql中存档
	need_lave_card_num = 20,	-- 需要留底牌20张
	robot = true,
	isowntest = true,			-- 服务端测试使用
	istest = false,				-- 测试使用
	room_card = 6.25,  			-- 10局房卡

	wait_time = 15,				-- 操作等待时间（秒）

	step_one = 0,				-- 刚创建/一局结束
	step_banker = 1,       		-- 定庄家
	step_start = 2, 			-- 开局发牌
	step_flower = 3, 			-- 开局补花
	step_gold = 4, 				-- 开金
	step_rob_gold = 5, 			-- 抢金
	step_cur_operate = 6,   	-- 当前玩家操作（天胡、自摸、暗杠、明杠、出牌）
	step_other_operate = 7, 	-- 非当前玩家操作（吃、碰、明杠、胡牌）
	step_roundover = 8,      	-- 本局结束（结算下发、清理数据）
	step_fee = 10,       		-- 扣钱（房卡）（第一局结束后扣）
	step_over = 20,      		-- 房间游戏结束

	-- 测试起牌
	Cheat_Config = 				{17,17,17,18,19,20,21,22,23,33,34,35,36,37,38,39},
	Cheat_Peng_Config = 		{17,40,40,18,18,33,33,20,20,37,37,22,22,56,56,55},
	Cheat_Gang_Config = 		{17,18,18,18,34,34,34,49,49,49,55,55,55,56,56,56},
	Cheat_Dark_Gang_Config = 	{17,18,18,18,18,21,21,21,21,22,22,22,22,37,38,39},
	Cheat_Bright_Gang_Config = 	{55,40,40,18,18,18,20,20,20,37,37,22,22,22,40,55},

	-- 福州麻将 胡配置
	Hu_Config = {
		NO_HU = 0,						-- 不能胡
		COMMON = 1,						-- 平胡	
		TIANHU = 2,						-- 天胡
		ROB_GOLD = 3,					-- 抢金
		PING_HU_NO_FLOWER = 4,			-- 平胡（无花无杠）
		PING_HU_ONE_FLOWER = 5,			-- 平胡（一张花）
		GOLD_THREE = 6,					-- 三金倒
		GOLD_SPARROW = 7,				-- 金雀
		GOLD_DRAGON = 8,				-- 金龙
	},

	-- 福州麻将 胡牌分数配置 与 胡配置 一一对应
	Hu_Score_Config = {1,30,30,30,15,40,60,120},

	-- 福州麻将 操作配置
	Operate_Config = {
		CUR_OPERATE_WAIT = 0,			-- 等待玩家操作
		CUR_OPERATE_OUTCARD = 1,		-- 出牌
		CUR_OPERATE_CHI = 2,			-- 吃	
		CUR_OPERATE_PENG = 3,			-- 碰
		CUR_OPERATE_DARK_GANG = 4,		-- 暗杠
		CUR_OPERATE_BRIGHT_GANG = 5,	-- 明杠（自己出牌与碰牌杠）
		CUR_OPERATE_HU = 6,				-- 胡
		CUR_OPERATE_GUO = 7,			-- 过
		CUR_OPERATE_GANG = 8,			-- 杠（与出牌杠）
		CUR_OPERATE_FLOW = 9,			-- 流局
	},

	-- 操作排序 从小到大 依次操作
	Operate_Sort_Config = {
		OPERATE_SORT_HU = 1,			-- 胡牌
		OPERATE_SORT_GANG = 2,			-- 明杠（杠的优先级要大于碰，但实际情况两者不可能同时发生在两个不同玩家身上）
		OPERATE_SORT_PENG = 3,			-- 碰
		OPERATE_SORT_CHI = 4,			-- 吃
	},

	-- 作弊各个事件概率值，可调整！！！
	Cheat_Change_Config = {50,30,30,30,20,30,30},

	-- 作弊人各个事件类型
	Cheat_Change_Type = {
		EXIST = 0,						-- 是否有设置作弊，判断概率100%
		OPEN_GOLD = 1,					-- 判断是否有机会开手牌金
		GET_GOOD_CARD = 2,				-- 判断自己/别家摸牌是否有机会摸好牌（对于作弊玩家来说）
		GET_TWO_SAME = 3,				-- 判断初始化牌时是否有机会获得一个对子
		GET_ONE_THREE_ORDER = 4,		-- 判断初始化牌时是否有机会获得第一个三张连牌
		GET_SECOND_THREE_ORDER = 5,		-- 判断初始化牌时是否有机会获得第二个三张连牌
		GET_ONE_TWO_ORDER = 6,			-- 判断初始化牌时是否有机会获得第一个两张连牌/两张间隔一的牌
		GET_SECOND_TWO_ORDER = 7,		-- 判断初始化牌时是否有机会获得第二个两张连牌/两张间隔一的牌
	},
}


-- 福州麻将 步骤配置
Club_Config = {
	-- 俱乐部角色类型
	Club_RoleType = {
		Creater = 100,					--创建者
		Manager = 10,					--管理员
		Senior = 1,						--高级会员
		Ordinary = 0					--普通会员
	},

	-- 俱乐部成员状态
	Club_MemberStatus = {
		Normal = 0,						--普通正常
		Del = -1,						--被开除
		Suspend = -10					--禁赛
	},

	-- 俱乐部申请状态类型
	Club_Apply_Status = {
		Apply = 0,						--申请
		Pass = 1,						--同意
		Deny = -1,						--驳回
		DenyApply = -10,				--驳回并不接收申请了
	},

	-- 俱乐部按钮权限
	Club_Buttons_Auth = {
		Get_Member = 1,					--获取成员列表
		Dissolve = 2,					--解散俱乐部
		Fund_Manager = 3,				--基金管理
		Setting = 4,					--俱乐部设置
		Apply_Msg = 5,					--验证消息
		Records = 6,					--对战记录
		Modify_Auth = 7,				--修改成员权限
	},
}


-- 菠菜牛牛
Cow_config = {
	step_none      = 0,
	step_start     = 1,       -- 开始
	step_bet       = 2, 	  -- 下注
	step_rotary    = 3,  	  -- 封盘
	step_compare   = 4,       -- 比车
	step_result    = 5,       -- 结算
	step_over      = 6,       -- 结束
}

--好友关系配置
Config_friend = {
	friend_num_limit   = 50   --好友数量上限
}

--大菠萝配置
Config_daboluo = {
	robot = true,

	step_none = 0,
	step_deal_card = 1, -- 发牌
	step_compare = 2,   -- 比牌
	step_over = 3,      -- 游戏结束

	step_skip = 99,    --跳过

	auto_card_time = 60, -- 出牌时间
	auto_del_room = 600,  -- 10分钟解散房间

	ask_quit_time = 60,   -- 请求退出房间的初始时间
}
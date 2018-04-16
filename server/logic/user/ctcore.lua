-- 晁图用户组
local skynet = require("skynet")
local json = require "cjson"
local cthttp = require "cthttp"
local db_mgr = require("db_mgr")
local md5 = require "md5"

local cmd = {}

-- 登录
function cmd.login(account, password)
    local status, body = cthttp.post("hgame-api/api2.0/user/login", {
		loginName = account,
        loginPwd  = string.upper(md5.sumhexa(password)),
        loginType = "1",
    })

    local ret, dataTable = pcall(json.decode, body)

    if status ~= 200 or not ret then
        return "error", "请求用户信息出错".. code, {}
    end

    if dataTable.respCode ~= "00" then
        return "error", "获取用户信息失败" .. dataTable.respCode, {}
    end

    local respData = dataTable.respData or {}
    local user = respData.user
    if not user then
        return "error", "用户信息错误", {}
    end

    dataTable.respData.user.id = dataTable.respData.user.custNo
    dataTable.respData.user.uid = dataTable.respData.user.custNo
    dataTable.respData.user.name = dataTable.respData.user.custName
    dataTable.respData.user.user_avatar = dataTable.respData.user.remark1 or ""
    dataTable.respData.user.remark1 = nil

    return "ok", "获取用户信息成功", user
end

-- 获取个人信息
function cmd.get_user_info(custNo, token)
    local status, body = cthttp.post("hgame-api/api2.0/user/userInfo", {
		custNo = custNo,
        token = token,
    })
    
    local ret, dataTable = pcall(json.decode, body)
    dataTable = dataTable or {}

    if status ~= 200 or not ret then
        return "err", "CT服务器异常 http:".. status, {}
    end

    if dataTable.respCode ~= "00" then
        return "token_err", dataTable.respMsg, {}
    end

    -- 存储redis
    local key="ct:user_info:"..custNo
    dataTable.respData.user.id = custNo
    dataTable.respData.user.name = dataTable.respData.user.custName
    dataTable.respData.user.user_avatar = dataTable.respData.user.remark1 or ""
    dataTable.respData.user.remark1 = nil
    --do_redis({ "set", key , json.encode(dataTable.respData.user)})

    return "ok", "获取用户信息成功", dataTable.respData.user

end


-- 根据id获取个人信息
function cmd.get(custNo)
    local key="ct:user_info:"..custNo
    local ret = do_redis({ "get", key })
    if ret == nil or ret == "" then
        return {}
    end
    return json.decode(ret)
end

-- 获取用户账户信息
function cmd.get_game_user_account(operatCustNo)
    local status, body = cthttp.post("hgame-api/api2.0/user/queryCustAccount", {
		custNo = 1,
        -- token = "",
        queryCustNo = operatCustNo,
    })
    
    local ret, dataTable = pcall(json.decode, body)

    if status ~= 200 or not ret then
        return "error", "请求账户信息出错", {}
    end

    if dataTable.respCode ~= "00" then
        return "error", "获取账户信息失败" .. dataTable.respCode, {}
    end

    local respData = dataTable.respData or {}
    local custAcctInfo = respData.custAcctInfo
    if not custAcctInfo then
        return "error", "账户信息错误", {}
    end

    custAcctInfo.balAmt = tonumber(custAcctInfo.balAmt or 0)/100
    custAcctInfo.balGameAmt = tonumber(custAcctInfo.balGameAmt or 0)/100


    return "ok", "获取账户信息成功", custAcctInfo
end

--[[
    waterType = 15 冻结款
    waterType = 99 游戏冲还
    06-游戏-赢60-游戏-输
    -- 游戏中的金币返回用户金币
    local operAcct = {
		["transferAcctType"] = "ACCT_TYPE_BAL_AMT",
		["transferCustNo"] = user.custNo,
		["updAcctType"] = "ACCT_TYPE_BAL_GAME_AMT",
		["updAmt"] = "100",
		["updCustNo"] = user.custNo,
		["waterMemo"] = "游戏冻结款",
		["waterType"] = "15"
    }
    local operAcct = {
		["transferAcctType"] = "ACCT_TYPE_BAL_GAME_AMT",
		["transferCustNo"] = user.custNo,
		["updAcctType"] = "ACCT_TYPE_BAL_AMT",
		["updAmt"] = coin,
		["updCustNo"] = user.custNo,
		["waterMemo"] = "游戏冲还",
		["waterType"] = "99"
    }
]]
-- 游戏金币操作请求
local function operAcct(custNo, token, operAcct)
    if true then 
        --print("custNo, token, operAcct", custNo, token, operAcct)
        --return "ok"
    end
    local operAcctJson = ""
    for index, account in pairs(operAcct) do
        if index == 1 then
            operAcctJson = json.encode(account)
        else
            operAcctJson = operAcctJson .. "|" .. json.encode(account)
        end
    end
    
    local status, body, requst_body = cthttp.post("hgame-api/api2.0/gamesOperactions/operAcct", {
		custNo = custNo,
        token = token,
        operAcct = operAcctJson,
    })
    
    local ret, dataTable = pcall(json.decode, body)
    --print("金币操作结果", dataTable)
    --LOG("金币操作结果", json.encode(dataTable))
    -- print("回调==============================>",operAcct)
    if status ~= 200 or not ret then
        return "error", "操作服务器异常", {}
    end

    if dataTable.respCode ~= "00" then
        return dataTable.respCode, dataTable.respMsg, {}
    end

    local respData = dataTable.respData
    if not respData then
        return "error", "操作服务器异常"
    end
    return "ok", respData.respMsg, respData, requst_body, dataTable
end

-- 冻结房间钻石
function cmd.freezeRoomGold(roomId, goldNum)
    goldNum = tonumber(string.format("%.2f", goldNum)) 
    local acct = {
        ["transferAcctType"] = "ACCT_TYPE_GOLD_BAL_GAME_AMT",
        ["transferCustNo"] = tostring(roomId),
        ["updAcctType"] = "ACCT_TYPE_GOLD_BAL_AMT",
        ["updAmt"] = goldNum * 100,
        ["updCustNo"] = tostring(roomId),
        ["waterMemo"] = "房间钻石冻结款", 
        ["waterType"] = "15"   
    }
    return operAcct("admin", nil, {acct})
end

-- 返还房间钻石
function cmd.returnRoomGold(roomId, goldNum)
    goldNum = tonumber(string.format("%.2f", goldNum)) 
    local acct = {
        ["transferAcctType"] = "ACCT_TYPE_GOLD_BAL_AMT",
        ["transferCustNo"] = tostring(roomId),
        ["updAcctType"] = "ACCT_TYPE_GOLD_BAL_GAME_AMT",
        ["updAmt"] = goldNum * 100,
        ["updCustNo"] = tostring(roomId),
        ["waterMemo"] = "房间钻石冲还",
        ["waterType"] = "99"
    }
    return operAcct("admin", nil, {acct})
end

-- 扣除房间钻石
function cmd.reduceRoomGold(roomId, goldNum)
    goldNum = tonumber(string.format("%.2f", goldNum))
    local acct = {
        ["updAcctType"] = "ACCT_TYPE_GOLD_BAL_GAME_AMT",
        ["updAmt"] = goldNum * 100,
        ["updCustNo"] = tostring(roomId),
        ["waterMemo"] = "扣除房间钻石", 
        ["waterType"] = "60"   
    }
    return operAcct("admin", nil, {acct})
end

-- 游戏赢
local function getWinUserParams(coin, operatCustNo, waterMemo, game_type)
    coin = tonumber(string.format("%.2f", coin))
    --print("游戏赢", coin)
    local acct = {
        ["transferAcctType"] = "ACCT_TYPE_BAL_AMT",
        ["transferCustNo"]   = operatCustNo,
        ["updAmt"]           = coin*100,
        ["waterMemo"]        = waterMemo or "游戏赢",
        ["waterType"]        = "06",
        ["gameType"] = game_type
    }
    return acct
end

-- 游戏输
local function getLoseUserParams(coin, operatCustNo, waterMemo, game_type)
    coin = tonumber(string.format("%.2f", coin))
    --print("游戏输", coin)
    local acct = {
        ["updAcctType"]      = "ACCT_TYPE_BAL_AMT",
        ["updCustNo"]        = operatCustNo,
        ["updAmt"]           = coin*100,
        ["waterMemo"]        = waterMemo or "游戏输",
        ["waterType"]        = "60",
        ["gameType"] = game_type
    }
    return acct
end

-- 游戏收益
local function getUserProfitParams(coin, operatCustNo, waterType, waterMemo, game_type)
    coin = tonumber(string.format("%.2f", coin))
    --print(waterMemo, coin)
    local acct = {
        ["transferAcctType"] = "ACCT_TYPE_BAL_AMT",
        ["transferCustNo"]   = operatCustNo,
        ["updAmt"]           = coin*100,
        ["waterMemo"]        = waterMemo,
        ["waterType"]        = waterType,
        ["gameType"] = game_type
    }
    return acct
end

-- 游戏支出
local function getUserDefrayParams(coin, operatCustNo, waterType, waterMemo, game_type)
    coin = tonumber(string.format("%.2f", coin))
    -- print(waterMemo, coin)
    local acct = {
        ["updAcctType"]      = "ACCT_TYPE_BAL_AMT",
        ["updCustNo"]        = operatCustNo,
        ["updAmt"]           = coin*100,
        ["waterMemo"]        = waterMemo,
        ["waterType"]        = waterType,
        ["gameType"] = game_type
    }
    return acct
end

-- 冲返某个用户中的金币   (用户游戏中金币-->金币)
local function getReduceUserParams(coin, operatCustNo, transferCustNo, waterMemo, game_type)
    coin = tonumber(string.format("%.2f", coin))
    -- print("冲返某个用户中的金币", coin)
    local acct = {
		["transferAcctType"] = "ACCT_TYPE_BAL_AMT",
		["transferCustNo"] = transferCustNo or operatCustNo,
		["updAcctType"] = "ACCT_TYPE_BAL_GAME_AMT",
		["updAmt"] = coin*100,
		["updCustNo"] = operatCustNo,
		["waterMemo"] = waterMemo or "游戏冲还",
        ["waterType"] = "99",
        ["gameType"] = game_type
    }
    return acct
end

-- 新增某个用户游戏中的金币  (用户金币-->游戏中金币)
local function getAddUserParams(coin, operatCustNo, transferCustNo, waterMemo, game_type)
    coin = tonumber(string.format("%.2f", coin))
    local acct = {
		["transferAcctType"] = "ACCT_TYPE_BAL_GAME_AMT",
		["transferCustNo"] = transferCustNo or operatCustNo,
		["updAcctType"] = "ACCT_TYPE_BAL_AMT",
		["updAmt"] = coin*100,
		["updCustNo"] = operatCustNo,
		["waterMemo"] = waterMemo or "游戏冻结款",
		["waterType"] = "15",
        ["gameType"] = game_type
    }
    return acct
end

-- 多用户操作游戏结算
-- type 0 增加 1 返还 2 赢 3 输 4、房间扣钱  5、房间返还 6、游戏收益 7、游戏支出
function cmd.operatGameResultAcct(custNo, token, userAccts)
    local accounts = {}
    for index, userAcct in pairs(userAccts) do
        -- userAcct.gameType = nil
        if userAcct.type == 0 then
            table.insert(accounts, getAddUserParams(userAcct.coin, userAcct.custNo, userAcct.custNo, userAcct.waterMemo or "游戏冻结款", userAcct.gameType))
        elseif userAcct.type == 1 then 
            table.insert(accounts, getReduceUserParams(userAcct.coin, userAcct.custNo,userAcct.custNo, userAcct.waterMemo, userAcct.gameType))
        elseif userAcct.type == 2 then
            table.insert(accounts, getWinUserParams(userAcct.coin, userAcct.custNo, userAcct.waterMemo, userAcct.gameType))
        elseif userAcct.type == 3 then
            table.insert(accounts, getLoseUserParams(userAcct.coin, userAcct.custNo, userAcct.waterMemo, userAcct.gameType))
        elseif userAcct.type == 6 then
            table.insert(accounts, getUserProfitParams(userAcct.coin, userAcct.custNo, userAcct.waterType, userAcct.waterMemo, userAcct.gameType))
        elseif userAcct.type == 7 then
            table.insert(accounts, getUserDefrayParams(userAcct.coin, userAcct.custNo, userAcct.waterType, userAcct.waterMemo, userAcct.gameType))
        end
        --[[
        if userAcct.type == 0 then
            -- 金币转到游戏中金币
            table.insert(accounts, getAddUserParams(userAcct.coin, userAcct.custNo, userAcct.custNo, "红包-游戏冻结款"))
        elseif userAcct.type == 1 then 
            -- 返还闲家 冻结的金币
            table.insert(accounts, getReduceUserParams(userAcct.coin, userAcct.custNo))
        elseif userAcct.type == 2 then
            -- 闲家赢 从庄家游戏中金币转给玩家
            table.insert(accounts, getReduceUserParams(userAcct.coin, g.banker, userAcct.custNo, "红包-游戏赢"))
        elseif userAcct.type == 3 then
            -- 闲家输 转入金币到庄家游戏中金币
            table.insert(accounts, getAddUserParams(userAcct.coin, userAcct.custNo, g.banker, "红包-游戏输"))
        end
        ]]
    end

    --print("============operatGameResultAcct==============")
    --print(accounts)
    return operAcct("admin", nil, accounts)
end

-- -- 新增某个用户游戏中的金币  (用户金币-->游戏中金币)
-- function cmd.addUserGameCoin(user, coin, operatCustNo, game_type)
--     coin = tonumber(string.format("%.2f", coin))
--     local acct = getAddUserParams(coin, operatCustNo or user.custNo,user.custNo, game_type)

--     return operAcct(user.custNo, user.token, {acct})
-- end

-- -- 冲返某个用户中的金币   (用户游戏中金币-->金币)
-- function cmd.reduceUserGameCoin(user, coin, operatCustNo, game_type)
--     coin = tonumber(string.format("%.2f", coin))
--     local acct = getReduceUserParams(coin, operatCustNo or user.custNo, game_type)
    
--     return operAcct(user.custNo, user.token, {acct})
-- end

-- 充值某人金币
function cmd.addUserMoney(custNo, coin)
    coin = tonumber(string.format("%.2f", coin))
    local acct = {
        ["transferAcctType"] = "ACCT_TYPE_BAL_AMT",
        ["transferCustNo"]   = custNo,
        ["updAmt"]           = coin*100,
        ["waterMemo"]        = "测试服充金币",
        ["waterType"]        = "06"
    }
    local accounts = {acct}
    return operAcct("admin", nil, accounts)
end

function cmd.addUserGloden(custNo, golden)
    golden = tonumber(string.format("%.2f", golden))
    local acct = {
        ["transferAcctType"] = "ACCT_TYPE_GOLD_BAL_AMT",
        ["transferCustNo"]   = custNo,
        ["updAmt"]           = golden*100,
        ["waterMemo"]        = "测试服充钻",
        ["waterType"]        = "06"
    }
    local accounts = {acct}
    return operAcct("admin", nil, accounts)
end

-- 减某人金币
function cmd.reduceUserMoney(custNo, coin)
    coin = tonumber(string.format("%.2f", coin))
    local acct = {
        ["updAcctType"]      = "ACCT_TYPE_BAL_AMT",
        ["updCustNo"]        = custNo,
        ["updAmt"]           = coin*100,
        ["waterMemo"]        = "测试服减金币",
        ["waterType"]        = "60"
    }
    local accounts = {acct}
    return operAcct("admin", nil, accounts)
end

function cmd.reduceUserGloden(custNo, golden)
    golden = tonumber(string.format("%.2f", golden))
    local acct = {
        ["updAcctType"]      = "ACCT_TYPE_GOLD_BAL_AMT",
        ["updCustNo"]        = custNo,
        ["updAmt"]           = coin*100,
        ["waterMemo"]        = "测试服减钻石",
        ["waterType"]        = "60"
    }
    local accounts = {acct}
    return operAcct("admin", nil, accounts)
end

-- 刷新登录用户信息
function cmd.update_login_user(uid, openId, custName, sex, remark1)
    local sql = string.format("SELECT * FROM t_ct_user WHERE id='%s' limit 1", uid)
    local res = db_mgr.execute(sql)
    if table.size(res) == 0 then
        local sqlData = {}
        sqlData.id = uid
        sqlData.open_id = openId
        sqlData.name = custName
        sqlData.sex  = sex
        sqlData.head_img_url = remark1
        sqlData.time = os.time()
        sqlData.time_string = time_string(os.time())
        db_mgr.add("t_ct_user", sqlData)
    else
        local cur_time = os.time()
        local sql = string.format("UPDATE t_ct_user SET name='%s', sex='%s', time='%d', \
                    head_img_url='%s',time_string='%s' WHERE id='%s' ", custName, sex, os.time(),remark1, time_string(os.time()), uid);
        db_mgr.execute(sql)
    end
end

function cmd.add_report_charge( uid, userName, price)
    local cur_time = os.time()
    local sql = string.format("INSERT t_ct_report_charge(uid, user_name, price, charge_time, time_string) values('%s', '%s', %d, %d, '%s')", uid, userName, price, cur_time, time_string(cur_time))
    db_mgr.execute(sql)
end

function cmd.update_mails( ids )
    local sql = string.format("UPDATE d_msg SET is_send = 1 WHERE id in(%s)", table.concat(ids, ','))
    return db_mgr.execute(sql).affected_rows
end

function cmd.get_mails(uid)
    -- uid = tonumber(uid)
    local sql = ""

    if uid == nil then
        sql = "SELECT * from d_msg where msg_type = 2 and is_send = 0 and coin > 0 order by msg_time DESC limit 2"
    else
        sql = string.format("SELECT * from d_msg where uid = %d and msg_status < 3 order by msg_time DESC limit 20", uid)
    end
    return db_mgr.execute(sql)
end

-- 0未知1未读2已读3删除
function cmd.add_mail( uid, content, msg_type, coin, is_success )
    uid = tonumber(uid)
    if content == nil or #content == 0 then return end
    local cur_time = time_string(skynet.time())
    local sql = string.format("INSERT d_msg(content, uid, msg_time, msg_type, coin, is_send) values('%s', %d,'%s', %d, %d, %d)",
     content, uid, cur_time, msg_type, coin, is_success and 1 or 0)
    return db_mgr.execute(sql).affected_rows
end

-- 获取签到信息
function cmd.get_user_qiandao(uid)
    local sql = "SELECT * from t_ct_user_qiandao where uid = " .. uid or 0
    local data = db_mgr.execute(sql)
    if data == nil then
        return data
    end
    data = data[1] or {}

    local tab = os.date("*t", os.time())
    tab.hour = 0
    tab.min = 0
    tab.sec = 0
	local time1 = os.time(tab) -- 今天0点
    local time2 = time1 + 86400 -- 今天24点
    local time3 = time1 - 86400 -- 昨天0点

	local is_sign_in = 0
    data.qiandao_num = data.qiandao_num or 0
	if data.last_time and data.last_time >= time1 and data.last_time < time2 then -- 判断是否已签到
        is_sign_in = 1
    elseif data.qiandao_num >= 7 then -- 未签到，7天都签到过，从头开始
        data.qiandao_num = 0
    end
    data.is_sign_in = is_sign_in

    if data.last_time and data.last_time < time3 then
        data.qiandao_num = 0
    end
    
    return data
end

-- 设置签到
function cmd.set_user_qiandao(uid, name)
    local data = cmd.get_user_qiandao(uid)

    local time = os.time()
    local time_string = time_string(os.time())

    local sql = ""
    if data == nil or not data.uid then
        sql = string.format("INSERT t_ct_user_qiandao(uid, name, qiandao_num, time, last_time, time_string) values('%s','%s', %d, %d, %d, '%s')",
        uid, name, 1, time, time, time_string)
    else        
        local qiandao_num = data.qiandao_num
        if data.is_sign_in == 0 then
            qiandao_num = qiandao_num + 1
            if qiandao_num > 7 then
                qiandao_num = qiandao_num - 7
            end
        end
        
        sql = string.format("UPDATE t_ct_user_qiandao SET name='%s', qiandao_num=%d, time=%d, last_time=%d, time_string='%s' WHERE uid = '%s'", 
        name, qiandao_num, time, time, time_string, uid)
    end
    return db_mgr.execute(sql).affected_rows
end

--获取本地用户信息
function cmd.get_all_ctuser( uid )
    local sql = string.format("SELECT * FROM t_ct_user WHERE id='%s' limit 1", uid)
    return db_mgr.execute(sql)[1]
end

return cmd


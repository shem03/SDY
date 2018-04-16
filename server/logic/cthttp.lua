-- 晁图http工具
-- 请求方式如下
-- local cthttp = require("cthttp")
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
 
local md5 = require "md5"
local json = require "cjson"
local cmd  = {}
--local CT_HTTP_URL = "192.168.103.7:8090"       -- "127.0.0.1:38092"
local CT_HTTP_URL = "211.152.37.242:12021"       -- test
local CT_HTTP_URL_PAY = "211.152.37.242:12023"   -- "127.0.0.1:38091"

-- urlencode
local function urlEncode(s)
    s = string.gsub(s, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)
    return string.gsub(s, " ", "+")
end 

-- urldecode
local function urlDecode(s)
    s = string.gsub(s, '%%(%x%x)', function(h) return string.char(tonumber(h, 16)) end)
    return s
end

-- 排序参数从小到大
local function get_sort_keys(dataTable)
    local keys = {}
    for k, v in pairs(dataTable) do
        table.insert(keys, k)
    end
    table.sort(keys)
    return keys
end

-- 计算签名
local function cal_sign(dataTable)
    local secret = "11111111111111111111111111111111"
    local keys = get_sort_keys(dataTable)
    local link_str_tab = {}
    for _,k in pairs(keys) do
        table.insert(link_str_tab, k .. dataTable[k])
    end
    local to_sign_str = secret .. table.concat(link_str_tab) ..secret
    local sign = string.upper(md5.sumhexa(to_sign_str))
    return sign
end

-- 数据排序重组
local function encode_body(post_data)
    local request_body_tab = {}
    local flag = 1
    for k, v in pairs(post_data) do
        if flag == 1 then
            table.insert(request_body_tab, k)
            table.insert(request_body_tab, "=")
            table.insert(request_body_tab, v)
        else
            table.insert(request_body_tab, "&")
            table.insert(request_body_tab, k)
            table.insert(request_body_tab, "=")
            table.insert(request_body_tab, v)
        end
        flag = flag + 1
    end
    return table.concat(request_body_tab, "")
end

-- post请求
function cmd.post(uri, post_data)
    post_data.platformOrgCode = "1"
    post_data.clientType = "UI"
    post_data.timestamp = os.time()
    post_data.sign = cal_sign(post_data)

    local requst_body = encode_body(post_data)
    local status, code, body = pcall(do_http_post, CT_HTTP_URL, '/' .. uri, requst_body, {["Content-Type"] = "application/x-www-form-urlencoded"})--do_http_post( CT_HTTP_URL, '/' .. uri, requst_body, {["Content-Type"] = "application/x-www-form-urlencoded"})
    --print(status, code)
    if not status then
        print("cmd.post ===> status, code, body", uri,status, code, requst_body)
        return 408, '{"respCode":"S999","respMsg":"服务器请求失败"}'
    end
    return code, body, requst_body
end

-- post请求
function cmd.client_post(uri, post_data)

    local requst_body = post_data["key"]
    if requst_body == nil then
        return -1, ""
    end
    local time = os.time()
    local status, code, body = pcall(do_http_post,  CT_HTTP_URL, uri, requst_body, {["Content-Type"] = "application/x-www-form-urlencoded"}) -- do_http_post( CT_HTTP_URL, uri, requst_body, {["Content-Type"] = "application/x-www-form-urlencoded"})
    if not status then
        print("cmd.client_post ===> status, code, body", uri, status, code, requst_body, os.time()-time)
        return 408, '{"respCode":"S999","respMsg":"服务器请求失败"}'
    end
    return code, body
end

-- post请求
function cmd.client_pay_post(uri, post_data)

    local requst_body = post_data["key"] 
    if requst_body == nil then
        return -1, ""
    end
    -- print(requst_body)
    local status, code, body = pcall(do_http_post, CT_HTTP_URL_PAY, uri, requst_body, {["Content-Type"] = "application/x-www-form-urlencoded"})
    if not status then
        print("cmd.client_pay_post ===> status, code, body", uri, status, code)
        return 408, '{"respCode":"S999","respMsg":"服务器请求失败"}'
    end
    return code, body
end

return cmd
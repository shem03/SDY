require "os"
local MsgParser = require("MsgParser")


function gmt_time_string( t )
	return os.date("%a, %d %b %Y %X GMT", t or os.time())
end

function time_string( timestamp )
    timestamp = math.floor(timestamp) or os.time()
	return os.date("%Y-%m-%d %H:%M:%S", timestamp)
end

-- 判断value是否在table中
function is_in_table(tbl_list, value)
	for k,v in ipairs(tbl_list) do
	  if v == value then
	  	return true;
	  end
	end
	return false;
end


-- 复制table 深拷贝
function table_copy_table(ori_tbl)
    if (type(ori_tbl) ~= "table") then
        return nil
    end
    local new_tab = {}
    for i,v in pairs(ori_tbl) do
        local vtyp = type(v)
        if (vtyp == "table") then
            new_tab[i] = table_copy_table(v)
        elseif (vtyp == "thread") then
            new_tab[i] = v
        elseif (vtyp == "userdata") then
            new_tab[i] = v
        else
            new_tab[i] = v
        end
    end
    return new_tab
end

-- 字符串转为数组
function str_split_intarray(input, delimiter)  
    if input == nil then
        return {}
    end

    input = tostring(input)  
    delimiter = tostring(delimiter)  
    if (delimiter=='') then return false end  
    local pos,arr = 0, {}  
    -- for each divider found  
    for st,sp in function() return string.find(input, delimiter, pos, true) end do  
        table.insert(arr, string.sub(input, pos, st - 1))  
        pos = sp + 1  
    end  
    table.insert(arr, string.sub(input, pos))  
    return arr 
end

-- 数组去重
function tb_remove_repeat(t)
    local tt = table_copy_table(t)
    local temp_t={}
    for key,val in pairs(tt) do
       temp_t[val] = true
    end
    local result = {}
    for i,v in pairs(temp_t) do
        table.insert(result, i)
    end
    return result
end

--[[
-- tab = os.date("*t", time)
通过os.date函数的第二个参数指定一个时间数值。
例如:
local tab = os.date("*t", 1131286710);
--返回值 tab 的数据 {year=2005, month=11, day=6, hour=22,min=18,sec=30}
--year表示年,month表示月,day表示日期,hour表示小时,min表示分钟,sec表示秒,isdst表示是否夏令时
--tab成包括一些其他的成员 tab.yday 表示一年中的第几天 tab.wday 表示星期几(星期天为1)
time = os.time(tab) -->返回值为1131286710]]
--获取当天的开始时间戳
function now_daytime_start(now_time)
    --获取此时的时间戳
    local now_time = now_time or os.time()
    local tab = os.date("*t", now_time)
    tab.hour = 0
    tab.min = 0
    tab.sec = 0
   local result = os.time(tab)
   return result
end

--获取当天的结束时间戳
function now_daytime_end(now_time)
    --获取此时的时间戳
    local now_time = now_time or os.time()
    local tab = os.date("*t", now_time)    
    tab.hour = 0    
    tab.min = 0    
    tab.sec = 0
    local result = tonumber(os.time(tab) + 86400)
    return result
end

-- 去除字符串前后空格
function trim (s) 
    if s == nil then
        return s
    end
    return (string.gsub(s, "^%s*(.-)%s*$", "%1")) 
end

--- 获取utf8编码字符串正确长度的方法
-- @param str
-- @return number
function utfstrlen(str)
    str = trim(str)
    local len = #str;
    local left = len;
    local cnt = 0;
    local arr={0,0xc0,0xe0,0xf0,0xf8,0xfc};
    while left ~= 0 do
    local tmp=string.byte(str,-left);
    local i=#arr;
    while arr[i] do
    if tmp>=arr[i] then left=left-i;break;end
    i=i-1;
    end
    cnt=cnt+1;
    end
    return cnt;
end

-- 获取加密串 最长有效期5分钟
function gettimekey(re_time)
    local now = tonumber(os.time())
    local z,f = 0,0
    local num = 0
    if re_time == 1 then
        -- 生成
        z,f = math.modf(now/300)
        num = f > 0.5 and 1 or 0
        print("1:",z,f)
        LOG("gettimekey 1 z:"..z..",f:"..f)
    elseif re_time <= (now + 5) and re_time > (now - 300) then
        -- 验证
        z,f = math.modf(re_time/300)
        print("2:",z,f)
        LOG("gettimekey 2 z:"..z..",f:"..f)
        if f > 0.5 then
            local z1,f1 = math.modf(now/300)
            print("3:",z1,f1)
            LOG("gettimekey 3 z1:"..z1..",f1:"..f1)
            num = f1 > 0.5 and 1 or 0
        end
    end
    print("num:",num)
    local next_time = (math.ceil(now/300)+num+1)*300
    print("next_time:",next_time)
    LOG("gettimekey num:"..num..",next_time:"..next_time..",now:"..now)
    local source_key = 'asldfsdhfl'..tostring(next_time)..'24sddf!@23'
    -- local source_key = tostring((math.ceil(now/300)+1)*300)
    return source_key,now
end

-- 检查是否有敏感字符存在
function has_filter_str(str)
    local s = MsgParser:hasFilterStr(str)
    return s
end

-- 获取已经过滤好的字符串 敏感字符用*代替
function get_filtered_str(str)
    local s = MsgParser:getString(str)
    return s
end

--检查渠道
-- channel (当前渠道)
-- type (1:俱乐部功能,2:关闭俱乐部房间)
function check_channel(channel, mtype)
    local canchannels = nil
    if mtype == 1 then
        canchannels = {'xzj','dyj','zm','dd'}
    elseif mtype == 2 then
        canchannels = {'xzj'}
    end
    if channel == nil or canchannels == nil or not is_in_table(canchannels, channel) then
        return false
    end
    return true
end
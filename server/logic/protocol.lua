--[[
--消息数据按4字节对齐
--组合消息数据:   CDataCombine
--解析消息数据:   CDataParser
--]]

local factor8=72057594037927936		--256*256*256*256*256*256*256
local factor7=281474976710656		--256*256*256*256*256*256
local factor6=1099511627776			--256*256*256*256*256
local factor5=4294967296	 		--256*256*256*256
local factor4=16777216 	 			--256*256*256
local factor3=65536		 			--256*256
local factor2=256                   --256

local TYPE_BYTE = 1                --1字节
local TYPE_SHORT = 2                --2字节
local TYPE_INT = 4                  --4字节
local TYPE_LONG = 8                 --8字节
local TYPE_STRING = 9               --字符串
local TYPE_BUFDATA = 10              --字符串

local msgData = {}

--无符号转换成有符号(暂时没必要)
function msgData.unsigned2signed( value, bytes)
    local  ret = value
    bytes = bytes or 4
    if(ret >= 2^(bytes*8 - 1))then
        ret = ret - 2^(bytes*8)
    end
    return ret
end

------------网络消息数据转换
function msgData.data2Int64(data)
	if not data then return end

	return factor8*string.byte(data,1)+factor7*string.byte(data,2)+factor6*string.byte(data,3)+factor5*string.byte(data,4)+
	factor4*string.byte(data,5)+factor3*string.byte(data,6)+factor2*string.byte(data,7)+string.byte(data,8)
end

function msgData.data2Int(data)
	if not data then return end

	return factor4*string.byte(data,1)+factor3*string.byte(data,2)+factor2*string.byte(data,3)+string.byte(data,4)
end

function msgData.data2Short(data)
	if not data then return end

	return factor2*string.byte(data,1)+string.byte(data,2)
end

function msgData.data2Byte(data)
	if not data then return end

	return string.byte(data,1)
end

function msgData.int2Data(int)
	if not int then return end
    int = math.floor(int)
	local byte1,byte2,byte3,byte4;
	byte4 = math.floor(int/factor4);
	byte3 = int%factor4; 
	byte2 = byte3%factor3; 
	byte3 = math.floor(byte3/factor3); 
	byte1 = byte2%factor2; 
	byte2 = math.floor(byte2/factor2); 
	return string.char(byte4,byte3,byte2,byte1);
end

function msgData.int642Data(int64)
	if not int64 then return end
	int = math.floor(int64)
	local byte1,byte2,byte3,byte4,byte5,byte6,byte7,byte8
	byte8 = math.floor(int64/factor8);
	byte7 = int64%factor8;
	byte6 = byte7%factor7;
	byte7 = math.floor(byte7/factor7);
	byte5 = byte6%factor6;
	byte6 = math.floor(byte6/factor6);
	byte4 = byte5%factor5;
	byte5 = math.floor(byte5/factor5);

	byte3 = byte4%factor4;
	byte4 = math.floor(byte4/factor4);
	byte2 = byte3%factor3;
	byte3 = math.floor(byte3/factor3);
	byte1 = byte2%factor2;
	byte2 = math.floor(byte2/factor2);
	return string.char(byte8,byte7,byte6,byte5,byte4,byte3,byte2,byte1);
end

function msgData.short2Data(short)
	if not short then return end
	int = math.floor(short)
	return string.char(math.floor(short/factor2), short%factor2)
end

function msgData.byte2Data(byte)
	if not byte then return end
	
	return string.char(byte)
end


-------------------------------------------
-- CDataParse
-------------------------------------------

local CDataParse={}

function CDataParse:init(data)
	self.m_idx = 1
	self.m_data = data .. "\0\0\0\0\0\0\0\0"--防止消息过短低于8个字节
	
end


function CDataParse:GetMsgByte() --获得一个字节的数据
    local data = msgData.data2Byte(string.sub(self.m_data, self.m_idx, self.m_idx))
    self.m_idx = self.m_idx + 1

    return data
end

function CDataParse:GetMsgShort() --获得二个字节的数据
    local data = msgData.data2Short(string.sub(self.m_data, self.m_idx, self.m_idx + 1))
    self.m_idx = self.m_idx + 2

    return data
end

function CDataParse:GetMsgInt() --获得四个字节的数据
    local data = msgData.data2Int(string.sub(self.m_data, self.m_idx, self.m_idx + 3))
    self.m_idx = self.m_idx + 4

    return data
end

function CDataParse:GetMsgLong() --获得八个字节的数据
    local data = msgData.data2Int64(string.sub(self.m_data, self.m_idx, self.m_idx + 7))
    self.m_idx = self.m_idx + 8

    return data
end

function CDataParse:GetMsgString() --获得字符串的数据
    local len = msgData.data2Short(string.sub(self.m_data, self.m_idx, self.m_idx + 1))
    self.m_idx = self.m_idx + 2
    local data = string.sub(self.m_data, self.m_idx, self.m_idx+len-1)
    self.m_idx = self.m_idx + len

    return data
end


-------------------------------------------
-- CDataCombine 发送消息时用到
--[[
--字符连接技巧: .. 连接符效率较低
--用table.concat 来解决效率问题
--]]
-------------------------------------------

local CDataCombine={}

function CDataCombine:init(type)
	self.m_size = 2
	self.m_type=type
	--self.m_idx = 1
	self.m_data = {}
end

function CDataCombine:appendByte(byte)
	if not byte then return end
	if (byte < 0 or byte >= factor2) then --如何大于1字节
        print("CDataCombine:appendByte() error exceed the limit !")
		return
	end

   -- table.insert(self.m_data, msgData.byte2Data(TYPE_BYTE))
    table.insert(self.m_data, msgData.byte2Data(byte))
    --local data=""
    --data = data .. msgData.byte2Data(TYPE_BYTE) --添加数据类型标记
    --data = data .. msgData.byte2Data(byte)      --添加数据
	--self.m_data[self.m_idx] = data
	--self.m_idx = self.m_idx+1
end

function CDataCombine:appendShort(h)
	if not h then return end
	if (h < 0 or h >= factor3) then --如何大于2字节
        print("CDataCombine:appendShort() error exceed the limit !")
		return
	end

    --table.insert(self.m_data, msgData.byte2Data(TYPE_SHORT))
    table.insert(self.m_data, msgData.short2Data(h))
	--[[
	local data=""
    data = data .. msgData.byte2Data(TYPE_SHORT)
	data = data .. msgData.short2Data(h)
	self.m_data[self.m_idx] = data
	self.m_idx = self.m_idx+1
	--]]
end

function CDataCombine:appendInt(i)
	if not i then return end
	--4294967296==256*256*256*256
    if(i<0 or i>=factor5)then
        print("CDataCombine:appendInt() error exceed the limit !")
        return
	end

    --table.insert(self.m_data, msgData.byte2Data(TYPE_INT))
    table.insert(self.m_data, msgData.int2Data(i))
	--[[local data=""
    data = data .. msgData.byte2Data(TYPE_INT)
    data = data .. msgData.int2Data(i)
	self.m_data[self.m_idx] = data
	self.m_idx = self.m_idx+1
	--]]
end

function CDataCombine:appendInt64(i)
	if not i then return end
    if(i<0)then
        print("CDataCombine:appendInt64() error exceed the limit !")
        return
    end
    
    --table.insert(self.m_data, msgData.byte2Data(TYPE_INT64))
    table.insert(self.m_data, msgData.int642Data(i))
	--[[
	local data=""
    data = data .. msgData.byte2Data(TYPE_INT64)
    data = data .. msgData.int642Data(i)
	self.m_data[self.m_idx] = data
	self.m_idx = self.m_idx+1
	--]]
end

function CDataCombine:appendString(s)
	if not s then return end

	local len = string.len(s)
    --table.insert(self.m_data, msgData.byte2Data(TYPE_STRING))
    table.insert(self.m_data, msgData.short2Data(len))
    table.insert(self.m_data, s)
	--[[
	local data=""
    data = data .. msgData.byte2Data(TYPE_STRING)
	data = data .. msgData.short2Data(len)
	data = data .. s
	self.m_data[self.m_idx] = data
	self.m_idx = self.m_idx+1
	--]]
end

function CDataCombine:getData()
	--[[
	for _,v in ipairs(self.m_data) do
		self.m_size = self.m_size + string.len(v)
	end

	local data=""
	data = data .. msgData.short2Data(self.m_size)
	data = data .. msgData.short2Data(self.m_type)
	for _,v in ipairs(self.m_data) do
		data = data .. v
	end
	--]]
    local data1 = table.concat(self.m_data)
    self.m_size = self.m_size + string.len(data1)
	local data = msgData.short2Data(self.m_size)..msgData.short2Data(self.m_type)..data1
	
    return data
end

function writer( msg,tpl )
	-- body
	for i,v in ipairs(tpl) do
		local key = v[1]
		if v[3] > 1 then
			local len = (msg[key] and #(msg[key])) or 0
            CDataCombine:appendShort(len)

			if len and len > 0 then
				assert(type(msg[key])  == "table",key.." the type should be table! ")
				for i = 1,len do
					if type(v[2]) == "table" then
						writer(msg[key][i],v[2])
					elseif v[2] == "string" then
						CDataCombine:appendString(msg[key][i])
					elseif v[2] == "int" then
						CDataCombine:appendInt(msg[key][i])
					elseif v[2] == "short" then
						CDataCombine:appendShort(msg[key][i])
			        elseif v[2] == "long" then
				        CDataCombine:appendInt64(msg[key][i])							
			        elseif v[2] == "byte" then
				        CDataCombine:appendByte(msg[key][i])								
					else 
						assert(nil,"not table string int short" .. v[2])
					end
				end
			end
		else
 
			if type(v[2])  == "table" then
				writer(msg[key],v[2])
			elseif v[2] == "string" then
				CDataCombine:appendString(msg[key])
			elseif v[2] == "int" then
				CDataCombine:appendInt(msg[key])
			elseif v[2] == "short" then
				CDataCombine:appendShort(msg[key])
			elseif v[2] == "long" then
				CDataCombine:appendInt64(msg[key])				
			elseif v[2] == "byte" then
				CDataCombine:appendByte(msg[key])				
			else 
				assert(nil,"not table string int short byte" .. v[2])
			end
		end
	end
end

local function pack_msg(msg_id, msg, isclient)
    if (not msg) then return end

    CDataCombine:init(msg_id)
    local tpl
    if isclient then
    	tpl = template.request[msg_id]
    else
    	tpl = template.respone[msg_id]
    end
    writer(msg,tpl)
    local data = CDataCombine:getData()
    if(not data) then 
        print("----------------CDataCombine:getData() error!")
        return 
    end

    return data
end

local function reader( msg, tpl )
	-- body
	for i,v in ipairs(tpl) do
		local key = v[1]
		if v[3] > 1 then
			msg[key] = {}
			local len = CDataParse:GetMsgShort()
			if len and len > 0 then
				for i = 1,len do
					if type(v[2]) == "table" then
						msg[key][i] = {}
						reader(msg[key][i],v[2])
					elseif v[2] == "string" then
						msg[key][i] = CDataParse:GetMsgString()
					elseif v[2] == "int" then
						msg[key][i] = CDataParse:GetMsgInt()
					elseif v[2] == "short" then
						msg[key][i] = CDataParse:GetMsgShort()
					elseif v[2] == "ulong" or v[2] == "long" then
						msg[key][i] = CDataParse:GetMsgLong()
					elseif v[2] == "byte" then
						msg[key][i] = CDataParse:GetMsgByte()
					else
						assert(nil,"not table string int short" .. v[2])
					end
				end
			end
		else
			if type(v[2]) == "table" then
				msg[key] = {}
				reader(msg[key],v[2])
			elseif v[2] == "string" then
				msg[key] = CDataParse:GetMsgString()
			elseif v[2] == "int" then
				msg[key] = CDataParse:GetMsgInt()
			elseif v[2] == "short" then
				msg[key] = CDataParse:GetMsgShort()
			elseif v[2] == "ulong" or v[2] == "long" then
				msg[key] = CDataParse:GetMsgLong()
			elseif v[2] == "byte" then
				msg[key] = CDataParse:GetMsgByte()
			else 
				assert(nil,"not table string int short" .. v[2])
			end
		end
		-- print("reader: ", key, msg[key])
	end
end

local function unpack_msg(data, isclient)
    if (not data) then return end
    CDataParse:init(data)
    local msg_id = CDataParse:GetMsgShort()
    local tpl
    if isclient then
    	tpl = template.respone[msg_id]
    else
    	tpl = template.request[msg_id]
    end
    if tpl == nil then
    	error("can't find template by msg_id:"..msg_id)
    	return
    end
    -- print("unpack_msg:", msg_id, #data)
    local msg = {}

    reader(msg, tpl)

    return msg_id, msg
end

return {
	pack_msg = pack_msg,
	unpack_msg = unpack_msg,
}

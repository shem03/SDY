local cmd = {}

function cmd.version()
	local temp = do_mysql_req("select version()")
	print(temp)
end

function cmd.get_last_id()
    local sql = "SELECT LAST_INSERT_ID() AS ID "
    local ret = do_mysql_req(sql)
    if ret == nil or ret[1] == nil then
    	return nil
    end
    local last_id =tonumber(ret[1]["ID"])
    return last_id
end

--获取后台登陆用户
function cmd.get_bguserinfo(id)
    local sql = string.format("SELECT * FROM d_bguser WHERE id = %d limit 1",id)
    local ret = do_mysql_req(sql)
    return ret[1]
end

function cmd.get_userinfo(user_id)
	local sql = string.format("SELECT * FROM d_user WHERE id = %d limit 1",user_id)
	local ret = do_mysql_req(sql)
	return ret[1]
end

function cmd.get_userinfo_device(deviceid)
    local sql = string.format("SELECT * FROM d_user WHERE deviceid = '%s' limit 1",deviceid)
    local ret = do_mysql_req(sql)
    return ret[1]
end

function cmd.get_uid_device(deviceid)
    local sql = string.format("SELECT id FROM d_user WHERE deviceid = '%s' limit 1",deviceid)
    local ret = do_mysql_req(sql)
    return ret[1]
end

function cmd.get_config(key)
    local sql = string.format("SELECT pvalue from d_config where pkey='%s' limit 1", key)
    return cmd.execute(sql)[1]["pvalue"]
end

function cmd.get_robots()
    local robots = {}
    local sql = "SELECT account,password FROM t_ct_robot"
    local res = cmd.execute( sql )
    for index, robot in pairs(res) do
        robots[robot.account] = robot
    end
    return robots
end

function cmd.execute( sql )
	return do_mysql_req(sql)
end

-- 根据值读取 例子 query_key("d_user", "id", 1)
function cmd.query_key( tablename, key, value )
    local data
    local sql
    if key == nil then
        sql = string.format("SELECT * FROM %s limit 1000", tablename)
    else
        if type(value) == "number" then
            sql = string.format("SELECT * FROM %s WHERE %s = %d limit 1000", tablename, key, value)
        else
            sql = string.format("SELECT * FROM %s WHERE %s = '%s' limit 1000", tablename, key, value)
        end
    end
    local res = do_mysql_req(sql)
    return res
end

-- 根据值读取 例子 get("d_user", "id", 1)
function cmd.get( tablename, key, value )
    return cmd.query_key(tablename, key, value)[1]
end

function cmd.get_value( tablename, key, where )
    local res = cmd.query(tablename, where)
    if #res > 0 then
        return res[1][key]
    end
end

function cmd.count( tablename, where )
    local array = {}
    local sql = nil
    if where then
        if type(where) == "table" then
            for k, v in pairs(where) do
                if #array>1 then 
                    table.insert(array, " and ") 
                else 
                    table.insert(array, 'WHERE ') 
                end
                
                if type(v) == "number" then
                    table.insert(array, string.format("%s=%d", k, v))
                else
                    table.insert(array, string.format("%s='%s'", k, v))
                end
            end
            sql = table.concat(array)
        else
            sql = where
        end
    else
        sql = ""
    end
    sql = string.format("SELECT count(*) FROM %s %s", tablename, sql)
    local res = do_mysql_req(sql)
    return res[1]["count(*)"]
end

-- 根据参数读取table,返回多条记录 fields, other其它参数，直接加在后面
-- 例子 query("d_user", {id=1}, "id, name", "order by dec")
-- 如果没有fields, other，可以不传
function cmd.query( tablename, where, fields, other )
    local array = {}
    local sql = nil
    if where then
        if type(where) == "table" then
            for k, v in pairs(where) do
                if #array>1 then table.insert(array, " and ") else 
                    table.insert(array, 'WHERE ') end
                if type(v) == "number" then
                    table.insert(array, string.format("%s=%d", k, v))
                else
                    table.insert(array, string.format("%s='%s'", k, v))
                end
            end
            sql = table.concat(array)
        else
            sql = where
        end
    else
        sql = ""
    end

    if fields then
        if other then
            sql = string.format("SELECT %s FROM %s %s %s", fields, tablename, sql, other)
        else
            sql = string.format("SELECT %s FROM %s %s limit 1000", fields, tablename, sql)
        end
    else
        if other then
            sql = string.format("SELECT * FROM %s %s %s", tablename, sql, other)
        else
            sql = string.format("SELECT * FROM %s %s limit 1000", tablename, sql)
        end
    end
    local res = do_mysql_req(sql)
    return res 
end

-- 添加数据
function cmd.add( tablename, param )
    local array_sql = {}
    local array_values = {}
    for k,v in pairs(param) do
        if #array_values ~= 0 then table.insert(array_values, ',') end
        if #array_sql ~= 0 then table.insert(array_sql, ',') end
        table.insert(array_sql, '`'..k..'`')
        if type(v) == "number" then
            if k == 'id' and v == 0 then
                table.insert(array_values, "NULL")
            else
                table.insert(array_values, v)
            end
        else
            -- 处理在sql中调用函数的情况
            local pos = string.find(v, "func:")
            if pos == 1 then
                v = string.gsub(v, "\"", "")
                v = string.gsub(v, "func:", "")
                table.insert(array_values, v)
            else
                table.insert(array_values, "'"..v.."'")
            end 
        end
    end
    local sql = string.format("insert into %s(%s) values(%s)", tablename, table.concat(array_sql), table.concat(array_values))
    --print("add:", sql)
    local res = do_mysql_req(sql)
    --print("add:", res)
    return res.insert_id
end

-- 更新 例子update("d_user", {name="test"}, {id=1})
function cmd.update( tablename, field, where )
    local array_where = {}
    local array_fields = {}

    if field then
        for k, v in pairs(field) do
            if #array_fields~=0 then table.insert(array_fields, ',') end
            if type(v) == "number" then
            	table.insert(array_fields, k)
            	table.insert(array_fields, "=")
                table.insert(array_fields, v)
            else
            	table.insert(array_fields, k)
            	table.insert(array_fields, "='")
            	table.insert(array_fields, v)
                table.insert(array_fields, "'")
            end
        end
    else
        return
    end
    if where then
        for k, v in pairs(where) do
            if #array_where>1 then table.insert(array_where, ' and ') else
            table.insert(array_where, 'WHERE ') end
            if type(v) == "number" then
            	table.insert(array_where, k)
            	table.insert(array_where, "=")
            	table.insert(array_where, v)
            else
            	table.insert(array_where, k)
            	table.insert(array_where, "='")
            	table.insert(array_where, v)
            	table.insert(array_where, "'")
            end
        end
    end
    
    local sql = string.format("UPDATE %s SET %s %s", tablename, table.concat(array_fields), table.concat(array_where))
    print("sql:", sql)
    local res = do_mysql_req(sql)
    return res.affected_rows
end

-- 删除数据
function cmd.del( tablename, where )
    local array_where = {}
    if where then
        for k, v in pairs(where) do
            if #array_where>1 then table.insert(array_where, ' and ') 
                else table.insert(array_where, 'WHERE ') end
            if type(v) == "number" then
            	table.insert(array_where, k)
            	table.insert(array_where, "=")
            	table.insert(array_where, v)
            else
            	table.insert(array_where, k)
            	table.insert(array_where, "='")
            	table.insert(array_where, v)
            	table.insert(array_where, "'")
            end
        end
    end
    local sql = string.format("DELETE from %s %s", tablename, table.concat(array_where))
    local res = do_mysql_req(sql)
    return res.affected_rows
end

return cmd
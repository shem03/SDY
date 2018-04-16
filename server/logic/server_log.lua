local skynet = require "skynet"
require "skynet.manager"

local log = {}

log.usecolor = true
log.out_file = "./log/server_"..skynet.getenv("nodename")
log.level = "trace"

local modes = {
  { name = "trace", color = "\27[34m", },
  { name = "debug", color = "\27[36m", },
  { name = "info_",  color = "\27[32m", },
  { name = "warn_",  color = "\27[33m", },
  { name = "error", color = "\27[31m", },
  { name = "fatal", color = "\27[35m", },
}


local levels = {}
for i, v in ipairs(modes) do
  levels[v.name] = i
end


local round = function(x, increment)
  increment = increment or 1
  x = x / increment
  return (x > 0 and math.floor(x + .5) or math.ceil(x - .5)) * increment
end


local _tostring = tostring

local tostring = function(...)
  local t = {}
  for i = 1, select('#', ...) do
    local x = select(i, ...)
    if type(x) == "number" then
      x = round(x, .01)
    end
    t[#t + 1] = _tostring(x)
  end
  return table.concat(t, " ")
end


-- 新的一天，滚动日志
local function rollfile()
  local cur_date = os.date("*t")
  if log.roll_day == cur_date.day then
  	return
  end
  log.roll_day = cur_date.day
  log.real_file = string.format("%s.%d%02d%02d.log", log.out_file, cur_date.year, cur_date.month, cur_date.day)
end

for i, x in ipairs(modes) do
  local nameupper = x.name:upper()
  log[x.name] = function(address, ...)
    
    -- Return early if we're below the log level
    if i < levels[log.level] then
      return
    end

    local msg = tostring(...)

    -- Output to console
    print(string.format("[%x] %s[%-6s%s]%s: %s",
                        address, 
                        log.usecolor and x.color or "",
                        nameupper,
                        os.date("%H:%M:%S"),
                        log.usecolor and "\27[0m" or "",
                        msg))
    -- 新的一天，滚动日志
	  rollfile()

    -- Output to log file
    if log.real_file then
      local fp = io.open(log.real_file, "a")
      local str = string.format("[%x][%-6s%s]: %s\n",
                                address, nameupper, os.date("%Y-%m-%d %H:%M:%S"),  
                                msg)
      fp:write(str)
      fp:close()
    end
  end
end

skynet.register_protocol {
	name = "text",
	id = skynet.PTYPE_TEXT,
	unpack = skynet.tostring,
	dispatch = function(_, address, msg)
		-- local log_str = string.format("%x %s %s", address, os.date("%Y-%m-%d %H:%M:%S"), msg)
    local log_type = string.sub(msg, 1, 5)
    if log_type and log[log_type] then
      log[log_type](address, string.sub(msg, 6))
    else
      log.info_(address, msg)
    end
	end
}

skynet.start(function()
	skynet.register ".logger"
  os.execute('#!/bin/bash\ndire="log"\nif [ ! -d "$dire" ]; then\nmkdir "$dire"\nfi')
end)
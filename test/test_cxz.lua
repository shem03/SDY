local cjson = require "cjson"

local arrData = {}
arrData[1] = "1"
arrData[2] = "2"

local jsonStr = cjson.encode(arrData)

print(jsonStr)

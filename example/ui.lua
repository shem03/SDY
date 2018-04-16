
local cmd = {}
local frame
local statusBar

local editor_ip
local editor_user
local editor_paw
local editor_cmd
local editor_msg

local cur_select = 1


function cmd.init(cb)
	frame = wx.wxFrame(wx.NULL, wx.wxID_ANY,"client", wx.wxDefaultPosition, wx.wxSize(470, 600), wx.wxDEFAULT_FRAME_STYLE )
	frame:Show(true)

	statusBar = frame:CreateStatusBar(1)
	frame:SetStatusText("等待连接")

	timer = wx.wxTimer(frame)

	frame:Connect(wx.wxEVT_TIMER,
	function (event)
		if cb then
			cb()
		end
	end )

	frame:Connect(wx.wxEVT_CLOSE_WINDOW,
    function (event)
        if timer then
            timer:Stop() -- always stop before exiting or deleting it
            timer:delete()
            timer = nil
        end
        -- ensure the event is skipped to allow the frame to close
        event:Skip()
    end )
    
end

function cmd.create_ui(LOGIN_HOST, LOGIN_PORT,conn_cb, diconn_cb, cmd_cb)
	assert(conn_cb)
	assert(diconn_cb)
	assert(cmd_cb)
	wx.wxStaticText( frame, wx.wxID_ANY, "服务端地址:", wx.wxPoint(10, 10))
	wx.wxStaticText( frame, wx.wxID_ANY, "UID:", wx.wxPoint(10, 40))

	editor_ip = wx.wxTextCtrl(frame, wx.wxID_ANY,LOGIN_HOST..":"..LOGIN_PORT,
	                          wx.wxPoint(80, 10), wx.wxSize(180, 18),
	                          wx.wxNO_BORDER)

	editor_uid = wx.wxTextCtrl(frame, wx.wxID_ANY,'1',
	                          wx.wxPoint(80, 40), wx.wxSize(180, 18),
	                          wx.wxNO_BORDER)

	local connid = 1
	local conn_btn = wx.wxButton(frame, connid, "连接", wx.wxPoint(300, 8))

	-- 连接
	frame:Connect(connid,  wx.wxEVT_COMMAND_BUTTON_CLICKED, 
		function(event)
			local host, port = string.match(editor_ip:GetValue(), "([^:]+):(.*)$")
			if host == nil or port ==nil then
				frame:SetStatusText("连接格式不对")
				return
			end

			conn_cb(host, tonumber(port), editor_uid:GetValue())
		end
	)

	local btnid_disconn = 2
	local discon_btn = wx.wxButton(frame, btnid_disconn, "断开", wx.wxPoint(300, 38))
	-- 断开连接
	frame:Connect(btnid_disconn,  wx.wxEVT_COMMAND_BUTTON_CLICKED, 
		function(event)
			diconn_cb()
		end
	)
	wx.wxStaticText( frame, wx.wxID_ANY, "命令:", wx.wxPoint(10, 95))

	local set_choices = {}
	for k,v in pairs(choices) do
		table.insert(set_choices, v[1].."-"..v[2])
	end

	local comboBox = wx.wxComboBox(frame, wx.wxID_ANY, set_choices[1],
                                   wx.wxPoint(80, 95), wx.wxSize(180, 18),
                                   set_choices)

	-- 命令
	editor_cmd = wx.wxTextCtrl(frame, wx.wxID_ANY, choices[cur_select][3],
	                                wx.wxPoint(10, 125), wx.wxSize(400, 55),
	                                wx.wxNO_BORDER + wx.wxTE_MULTILINE)

	frame:Connect(wx.wxID_ANY, wx.wxEVT_COMMAND_COMBOBOX_SELECTED, function( event )
		cur_select = event:GetSelection() + 1
		editor_cmd:SetValue(choices[cur_select][3])
	end)

	local btnid_cmd = 3
	local cmd_btn = wx.wxButton(frame, btnid_cmd, "执行", wx.wxPoint(300, 185))
	frame:Connect(btnid_cmd,  wx.wxEVT_COMMAND_BUTTON_CLICKED, 
		function(event)
			-- local funstr = " return "..editor_cmd:GetValue()
			-- local data = loadstring(funstr)()
			-- if data==nil or type(data)~="table" then
			-- 	cmd.status("数据输入格式不对")
			-- 	return
			-- end
			local data = editor_cmd:GetValue()
			cmd_cb(choices[cur_select], data)
		end
	)

	local btnid_clear = 4
	local clear_btn = wx.wxButton(frame, btnid_clear, "清空", wx.wxPoint(220, 185))
	frame:Connect(btnid_clear,  wx.wxEVT_COMMAND_BUTTON_CLICKED, 
		function(event)
			cmd.clear()
		end
	)

	-- 消息打印
	editor_msg = wx.wxTextCtrl( frame, wx.wxID_ANY, "", wx.wxPoint(10, 225), wx.wxSize(400, 280),
									wx.wxNO_BORDER + wx.wxTE_MULTILINE + wx.wxTE_READONLY)
end

function cmd.start_timer()
	timer:Start(300)
end

function cmd.stop_timer()
	timer:Stop()
end

function cmd.clear()
	editor_msg:SetValue("")
end

local function pr (t, name, indent)
    local tableList = {}
    function table_r (t, name, indent, full)
        local id = not full and name or type(name)~="number" and tostring(name) or '['..name..']'
        local tag = indent .. id .. ' = '
        local out = {}  -- result
        if type(t) == "table" then
            if tableList[t] ~= nil then
                table.insert(out, tag .. '{} -- ' .. tableList[t] .. ' (self reference)')
            else
                tableList[t]= full and (full .. '.' .. id) or id
                if next(t) then -- Table not empty
                    table.insert(out, tag .. '{')
                    for key,value in pairs(t) do
                        table.insert(out,table_r(value,key,indent .. '|  ',tableList[t]))
                    end
                    table.insert(out,indent .. '}')
                else table.insert(out,tag .. '{}')
                end
            end
        else
            local val = type(t)~="number" and type(t)~="boolean" and string.format("\"%s\"", t) or tostring(t)
            table.insert(out, tag .. val)
        end
        return table.concat(out, '\n')
    end
    return table_r(t,name or '服务器返回的字符串',indent or '')
end

function cmd.msg( str )
	local text = ""
    if type(str) == "table" then
        text = pr(str)
    else
        text = tostring(str)
    end
    editor_msg:AppendText(text..'\n')
end

function cmd.status( str )
	frame:SetStatusText(str)
end

return cmd
function widget:GetInfo()
	return {
		name		    = "BAR's Chat Console",
		desc		    = "v0.1 of simple tooltip",
		author		  = "Funkencool",
		date		    = "2013",
		license     = "GNU GPL, v2 or later",
		layer		    = math.huge,
		enabled   	= true
	}
end
local Chili,window0,stackpanel1,editbox0,whosListening
local messages = {}
local box
local numShowMsg = 1
local windowHeight = 1


local function updateMsgWindow()
	window0:ClearChildren()
	local text = ''
	for i=1, numShowMsg do
		local msg = messages[#messages-numShowMsg+i]
		if msg then 
			-- if msg.source then text = text..msg.source..", " end
			-- if msg.msgtype then text = text..msg.msgtype..", " end
			-- if msg.player then text = text..msg.player..", " end
			if string.find(msg.text, "Local") then text=text.."\255\255\127\0" end
			text = text..msg.text..'\n'
			if string.find(msg.text, "Local") then text=text.."\b" end
		end
	end
	box = Chili.TextBox:New{name='console',width=300,text=text}
	local wText = box.font:WrapText(text, 300, 500)
	_,_,box.lines = box.font:GetTextHeight(wText)
	window0:Resize(300,(box.lines-1)*15)
	window0:AddChild(box)
end

function widget:Initialize()
	Chili = WG.Chili
	local screen = Chili.Screen0
	editbox0 = Chili.EditBox:New{parent=screen,right=300,y=20,height=30,width=300}
	window0 = Chili.Window:New{parent=screen,padding = {5,0,5,0},minHeight = 15,right = 250,y = 50,width = 300}
	
	local buffer = Spring.GetConsoleBuffer(200)
	for i=1,#buffer do
	  widget:AddConsoleMessage(buffer[i])
	end
	
	Spring.SendCommands("console 0")
	Spring.SendCommands("inputtextgeo "..(editbox0.x/Chili.Screen0.width+0.004)..' '
		..(1 - (editbox0.y + editbox0.height) / Chili.Screen0.height + 0.003)..' 0.02 '..(editbox0.width / Chili.Screen0.width))
end

function widget:GameFrame(n)
	if n%120<1 and numShowMsg > 1 then 
		numShowMsg = numShowMsg-1 
		updateMsgWindow()
	end
end

function widget:AddConsoleMessage(msg)
	messages[#messages+1] = {}
	messages[#messages]=msg
	updateMsgWindow()
	if numShowMsg < 6 then numShowMsg = numShowMsg+1 end
end
function widget:KeyPress(key)
	if key==13 and editbox0.state.focused then
		Spring.SendCommands('Say '..editbox0.text)
		editbox0.text = ''
	return true
	end
end
function widget:Shutdown()
	Spring.SendCommands({"console 1", "inputtextgeo default"}) 
	Spring.SetConfigString("InputTextGeo", "0.26 0.73 0.02 0.028")
end
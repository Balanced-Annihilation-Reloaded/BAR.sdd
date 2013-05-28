function widget:GetInfo()
	return {
		name		    = "BAR's Chat Console",
		desc		    = "v0.1 of simple tooltip",
		author		  = "Funkencool",
		date		    = "2013",
		license     = "public domain",
		layer		    = math.huge,
		enabled   	= true
	}
end
local Chili,window0,stackpanel1,editbox0
local messages = {}
local box
local numShowMsg = 1
local windowHeight = 1


local function updateMsgWindow()
	window0:ClearChildren()
	local text = ''
	for i=1, numShowMsg do
		if messages[#messages-numShowMsg+i] then text = text..messages[#messages-numShowMsg+i].text..'\n' end
	end
	box = Chili.TextBox:New{name='console',width=300,text=text}
	local wText = box.font:WrapText(text, 300, 500)
	_,_,box.lines = box.font:GetTextHeight(wText)
	window0:Resize(300,(box.lines-1)*15)
	window0:AddChild(box)
end

function widget:Initialize()
	Chili = WG.Chili
	editbox0 = Chili.EditBox:New{parent=Chili.Screen0,right=250,y=20,height=30,width=350}
	window0 = Chili.Window:New{parent = Chili.Screen0,padding = {5,0,5,0},minHeight = 15,right = 250,y = 50,width = 300}
	
	local buffer = Spring.GetConsoleBuffer(200)
	for i=1,#buffer do
	  widget:AddConsoleMessage(buffer[i])
	end
	
	Spring.SendCommands("console 0")
	Spring.SendCommands("inputtextgeo "..(editbox0.x/Chili.Screen0.width+0.004)..' '..(1 - (editbox0.y + editbox0.height) / Chili.Screen0.height + 0.003)..' 0.02 '..(editbox0.width / Chili.Screen0.width))
end

function widget:GameFrame(n)
	if n%120<1 and numShowMsg > 1 then 
		numShowMsg = numShowMsg-1 
		updateMsgWindow()
	end
end

function widget:AddConsoleMessage(msg)
	messages[#messages+1]=msg
	updateMsgWindow()
	if numShowMsg < 6 then numShowMsg = numShowMsg+1 end
end

function widget:Shutdown()
	Spring.SendCommands({"console 1", "inputtextgeo default"}) -- not saved to spring's config file on exit
	Spring.SetConfigString("InputTextGeo", "0.26 0.73 0.02 0.028") -- spring default values
end
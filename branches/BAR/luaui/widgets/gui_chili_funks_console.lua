-- WIP
function widget:GetInfo()
	return {
		name    = 'Funks Chat Console',
		desc    = 'A simple chili chat console',
		author  = 'Funkencool',
		date    = '2013',
		license = 'GNU GPL v2',
		layer   = 0,
		enabled = true
	}
end

local Chili,conOut,editbox0,whosListening,control0,window0
local messages = {}
local box
local numShowMsg = 1
local windowHeight = 1

local function updateMsgWindow()
	conOut:ClearChildren()
	local text = ''
	for i=1, numShowMsg do
		local msg = messages[#messages-numShowMsg+i]
		if msg then
			-- if msg.source then text = text..msg.source..', ' end
			-- if msg.msgtype then text = text..msg.msgtype..', ' end
			-- if msg.player then text = text..msg.player..', ' end
			if string.find(msg.text, 'Local') then text=text..'\255\255\127\0' end
			text = text..msg.text..'\n'
			if string.find(msg.text, 'Local') then text=text..'\b' end
		end
	end
	box = Chili.TextBox:New{name='console',width=300,text=text}  --inefficient to make a new one of these every time TODO: don't clear child and update text
	local wText = box.font:WrapText(text, 300, 500)
	_,_,box.lines = box.font:GetTextHeight(wText) 
	conOut:Resize(300,math.max(0,(box.lines-1))*15)
	conOut:AddChild(box)
end

function widget:Initialize()
	Chili = WG.Chili
	local screen = Chili.Screen0
	--control0 = Chili.Control:New{parent=screen,right=500,y=20,height=30,width=300,padding={0,0,0,0}}
	window0 = Chili.Window:New{parent=screen,right=500,y=20,minHeight=20,height=30,width=300,padding={0,0,0,0}}
	editbox0 = Chili.EditBox:New{parent=window0,right=0,x=0,y=0,right=0,bottom=0,text='  --Takes over Enter/Return when entering text--',
	OnMouseDown = {function(obj) obj.text = '' end}}
	conOut = Chili.Window:New{parent=screen,padding = {5,0,2,0},minHeight = 15,right = 450,y = 50,width = 300}
	
	local buffer = Spring.GetConsoleBuffer(200)
	for i=1,#buffer do
		widget:AddConsoleLine(buffer[i].text,buffer[i].priority)
	end
	
	Spring.SendCommands('console 0')
	Spring.SendCommands('inputtextgeo '..(window0.x/Chili.Screen0.width-0.035)..' '
	..(1 - (window0.y + window0.height) / Chili.Screen0.height + 0.003)..' 0.02 '..(window0.width / Chili.Screen0.width))
end


function widget:GameFrame(n)
	local numClearMsg=0
	for i=1, numShowMsg do
		local msg = messages[#messages-numShowMsg+i]
		if msg.t + 300 < n then
			numClearMsg = numClearMsg+1
		end
	end
	numShowMsg= math.max(0,numShowMsg-numClearMsg)
	if numClearMsg>0 or numShowMsg>0 then
		updateMsgWindow()
	end
end

function widget:AddConsoleLine(text,priority)
	local msgtime=Spring.GetGameFrame()
	messages[#messages+1] = {}
	messages[#messages] = {text=text, priority=priority, t=msgtime}
	updateMsgWindow()
	if numShowMsg < 6 then numShowMsg = numShowMsg+1 end
end

function widget:KeyPress(key)
	if key==13 then
		if editbox0.state.focused then
			if string.find(editbox0.text,'/')==1 then
				Spring.SendCommands(string.sub(editbox0.text,2))
			else
				Spring.SendCommands('Say '..editbox0.text)
			end
			-- else
			-- editbox0.state.focused = true
			-- editbox0.text=''
			-- editbox0:Update()
			return true
		end
		editbox0.text = ''
		editbox0:Invalidate()
	end
end

function widget:Shutdown()
	Spring.SendCommands({'console 1', 'inputtextgeo default'})
	Spring.SetConfigString('InputTextGeo', '0.26 0.73 0.02 0.028')
end
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

-- Spring Functions --
local getTimer         = Spring.GetTimer
local diffTimers       = Spring.DiffTimers
local sendCommands     = Spring.SendCommands
local setConfigString  = Spring.SetConfigString
local getConsoleBuffer = Spring.GetConsoleBuffer
----------------------


-- Config --
local maxMsgNum = 6
local msgTime   = 4 -- time to display message in seconds
local msgWidth  = 300
------------

-- Chili elements --
local Chili
local msgWindow
local editbox0
local whosListening
local control0
local window0
local textBox
--------------------

-- Local Variables --
local messages = {}
local curMsgNum = 1
local timer = getTimer()
local oldTimer = timer
---------------------

local function updateMsgWindow()
	local text = ''
	
	for i=1, curMsgNum do
		local msg = messages[#messages-curMsgNum+i]
		if msg then text = text..msg.text..'\n' end
	end
	
	local font = textBox.font
	local wText, lines = font:WrapText(text, msgWidth, 500)	
	msgWindow:Resize(msgWidth, font.size * (lines-1) + 10) 
	
	textBox:SetText(text)
end

function widget:Initialize()
	
	Chili = WG.Chili
	
	local screen = Chili.Screen0
	
	window0 = Chili.Window:New{
		parent   = screen,
		right    = 500,
		y        = 20,
		minHeight= 20,
		height   = 30,
		width    = 300,
		padding  = {0,0,0,0}
	}
	
	editbox0 = Chili.EditBox:New{
		parent      = window0,
		right       = 0,
		x           = 0,
		y           = 0,
		right       = 0,
		bottom      = 0,
		text        = '  --Takes over Enter/Return when entering text--',
		OnMouseDown =  {function(obj) obj.text = '' end}
	}
	
	msgWindow = Chili.Window:New{
		parent    = screen,
		padding   = {5,5,2,5},
		minHeight = 15,
		right     = 450,
		y         = 50,
		width     = msgWidth
	}
	
	textBox = Chili.TextBox:New{
		parent = msgWindow,
		width  = msgWidth,
		text   = ''
	}
	local buffer = getConsoleBuffer(200)
	
	for i=1,#buffer do
		widget:AddConsoleLine(buffer[i].text,buffer[i].priority)
	end
	
	-- Disable engine console
	sendCommands('console 0')
	
	-- Move input to line up with new console
	sendCommands('inputtextgeo '
		-- ..(window0.x/Chili.Screen0.width-0.035)..' '
		..(window0.x/Chili.Screen0.width)..' '
		-- ..(1 - (window0.y + window0.height) / Chili.Screen0.height + 0.003)
		..(1 - (window0.y + window0.height) / Chili.Screen0.height)
		..' 0.1 '
		..(window0.width / Chili.Screen0.width) )
		
end

-- Adds dissappearing text
function widget:DrawScreen()
	timer = getTimer()
	if diffTimers(timer, oldTimer) > msgTime and curMsgNum > 0 then
		curMsgNum = curMsgNum - 1
		oldTimer = timer
		updateMsgWindow()
	end
end

function widget:AddConsoleLine(text,priority)
	messages[#messages+1] = {}
	messages[#messages] = {text=text, priority=priority}
	if curMsgNum < maxMsgNum then curMsgNum = curMsgNum+1 end
	oldTimer = getTimer()
	updateMsgWindow()
end

function widget:KeyPress(key)
	if key==13 then
		if editbox0.state.focused then
			if string.find(editbox0.text,'/')==1 then
				sendCommands(string.sub(editbox0.text,2))
			else
				sendCommands('Say '..editbox0.text)
			end
			return true
		end
		editbox0.text = ''
		editbox0:Invalidate()
	end
end

function widget:Shutdown()
	sendCommands({'console 1', 'inputtextgeo default'})
	setConfigString('InputTextGeo', '0.26 0.73 0.02 0.028')
end
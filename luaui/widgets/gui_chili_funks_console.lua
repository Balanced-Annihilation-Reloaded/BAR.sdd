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
local spGetTeamColor   = Spring.GetTeamColor
local spGetPlayerRoster= Spring.GetPlayerRoster
local sfind 		   = string.find 
local ssub			   = string.sub
local schar			   = string.char
local slen			   = string.len
----------------------


-- Config --
local maxMsgNum = 6
local msgTime   = 4 -- time to display message in seconds
local msgWidth  = 450
local msgRight  = 400
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
local myAllyTeamID = Spring.GetMyAllyTeamID()
---------------------

-- Text Colour Config --
cfg = {
	cothertext = {1,1,1,1}, --normal chat color
	callytext = {0,1,0,1}, --ally chat
	cspectext = {1,1,0,1}, --spectator chat
	
	cotherallytext = {1,0.5,0.5,1}, --enemy ally messages (seen only when spectating)
	cmisctext = {0.78,0.78,0.78,1}, --everything else
	cgametext = {0.4,1,1,1}, --server (autohost) chat
}

local function ConvertColor(r,g,b)
	return schar(255, (r*255), (g*255), (b*255))
end
---------------------

local function updateMsgWindow()
	local text = ''
	
	for i=1, curMsgNum do
		local msg = messages[#messages-curMsgNum+i]
		if msg then text = text..msg.text..'\n' end
	end
	
	local font = textBox.font
	local wText, lines = font:WrapText(text, msgWidth, 500)

	textBox:SetText(text)
	msgWindow:Resize(msgWidth, font.size * (lines-1) + 10) 
end

function widget:Initialize()
	
	Chili = WG.Chili
	
	local screen = Chili.Screen0
	
	window0 = Chili.Window:New{
		parent   = screen,
		right    = msgRight,
		y        = 30,
		minHeight= 20,
		height   = 30,
		width    = msgWidth,
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
		right     = msgRight,
		y         = 60,
		width     = msgWidth
	}
	
	textBox = Chili.TextBox:New{
		parent = msgWindow,
		width  = msgWidth,
		text   = ''
	}
	
	local buffer = getConsoleBuffer(maxMsgNum)
	for i=1,#buffer do
		local line = buffer[i]
		widget:AddConsoleLine(line.text,line.priority)
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

-- Adds disappearing text
function widget:Update()
	timer = getTimer()
	if diffTimers(timer, oldTimer) > msgTime and curMsgNum > 0 then
		curMsgNum = curMsgNum - 1
		oldTimer = timer
		updateMsgWindow()
	end
end

function widget:AddConsoleLine(text,priority)
	local messageText, ignoreThisMessage = processLine(text)
	if not ignoreThisMessage then 
		messages[#messages+1] = {}
		messages[#messages] = {text=messageText, priority=priority}
		if curMsgNum < maxMsgNum then curMsgNum = curMsgNum+1 end
		oldTimer = getTimer()
		updateMsgWindow()
	end
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

function processLine(line)

	local ignoreThisMessage = false
	local lineType = 0
	
	-- get data from player roster
	local roster = spGetPlayerRoster()
	local names = {}
	for i=1,#roster do
		names[roster[i][1]] = {roster[i][4],roster[i][5],roster[i][3]} --{allyTeamID, spectator, teamID}
	end
	
	-- assess line type
	if (names[ssub(line,2,(sfind(line,"> ") or 1)-1)] ~= nil) then
		lineType = 1 --player talking
		name = ssub(line,2,sfind(line,"> ")-1)
		text = ssub(line,slen(name)+4)
	elseif (names[ssub(line,2,(sfind(line,"] ") or 1)-1)] ~= nil) then
		lineType = 2 --spectator talking
		name = ssub(line,2,sfind(line,"] ")-1)
		text = ssub(line,slen(name)+4)
	elseif (names[ssub(line,2,(sfind(line,"(replay)") or 3)-3)] ~= nil) then
		lineType = 2 --spectator talking (replay)
		name = ssub(line,2,sfind(line,"(replay)")-3)
		text = ssub(line,slen(name)+13)
	elseif (names[ssub(line,1,(sfind(line," added point: ") or 1)-1)] ~= nil) then
		lineType = 3 --player point
		name = ssub(line,1,sfind(line," added point: ")-1)
		text = ssub(line,slen(name.." added point: ")+1)
	elseif (ssub(line,1,1) == ">") then
		lineType = 4 --game message
		text = ssub(line,3)
	end	

	-- filter out some engine messages; 
	if lineType==0 then 		
		-- 2 lines (instead of 4) appears when player connects
		if sfind(line,'-> Version') or sfind(line,'ClientReadNet') or sfind(line,'Address') then
			ignoreThisMessage = true
		end
		
		-- 'left the game' messages after game is over
		if gameOver then
			if sfind(line,'left the game') then
				ignoreThisMessage = true
			end
		end
	end	

	-- add colour
	local textColor = ""
	
	if (lineType==1) then --player message
		local c = cfg.cothertext
		local miscColor = ConvertColor(c[1],c[2],c[3])
		if (sfind(text,"Allies: ") == 1) then
			text = ssub(text,9)
			if (names[name][1] == MyAllyTeamID) then
				c = cfg.callytext
			else
				c = cfg.cotherallytext
			end
		elseif (sfind(text,"Spectators: ") == 1) then
			text = ssub(text,13)
			c = cfg.cspectext
		end
		
		textColor = ConvertColor(c[1],c[2],c[3])
		local r,g,b,a = spGetTeamColor(names[name][3])
		local nameColor = ConvertColor(r,g,b)
		
		line = nameColor..name..miscColor..": "..textColor..text
        
        playSound = true
		
	elseif (lineType==2) then --spectator message
		local c = cfg.cothertext
		local miscColor = ConvertColor(c[1],c[2],c[3])
		if (sfind(text,"Allies: ") == 1) then
			text = ssub(text,9)
			c = cfg.cspectext
		elseif (sfind(text,"Spectators: ") == 1) then
			text = ssub(text,13)
			c = cfg.cspectext
		end
		textcolor = ConvertColor(c[1],c[2],c[3])
		c = cfg.cspectext
		local nameColor = ConvertColor(c[1],c[2],c[3])
		
		line = nameColor.."(s) "..name..miscColor..": "..textColor..text
		
        playSound = true
        
	elseif (lineType==3) then --player point
		local c = cfg.cspectext
		local nameColor = ConvertColor(c[1],c[2],c[3])
		
		local spectator = true
		if (names[name] ~= nil) then
			spectator = names[name][2]
		end
		if (spectator) then
            name = "(s) "..name
		else
            local r,g,b,a = sGetTeamColor(names[name][3])
            nameColor =  ConvertColor(r,g,b)
		end
		
		c = cfg.cotherallytext
		if (spectator) then
			c = cfg.cspectext
		elseif (names[name][1] == MyAllyTeamID) then
			c = cfg.callytext
		end
		textColor = ConvertColor(c[1],c[2],c[3])
		c = cfg.cothertext
		local miscColor = ConvertColor(c[1],c[2],c[3])
		
		line = nameColor..name..miscColor.." * "..textColor..text
		
	elseif (lineType==4) then --game message
		local c = cfg.cgametext
		textColor = ConvertColor(c[1],c[2],c[3])
		
		line = textColor.."> "..text
	else --every other message
		local c = cfg.cmisctext
		textColor = ConvertColor(c[1],c[2],c[3])
		
		line = textColor..line
	end
	
	return line,ignoreThisMessage

end
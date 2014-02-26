-- WIP
-- TODO add color to text
function widget:GetInfo()
	return {
		name    = 'Funks Chat Console',
		desc    = 'A simple chili chat console',
		author  = 'Funkencool',
		date    = '2013',
		license = 'GNU GPL v2',
		layer   = 50,
		enabled = true
	}
end

-- Spring Functions --
include("keysym.h.lua")
local getTimer         = Spring.GetTimer
local diffTimers       = Spring.DiffTimers
local sendCommands     = Spring.SendCommands
local setConfigString  = Spring.SetConfigString
local getConsoleBuffer = Spring.GetConsoleBuffer
local getPlayerRoster  = Spring.GetPlayerRoster
local getTeamColor     = Spring.GetTeamColor
local sfind 		   = string.find 
local ssub			   = string.sub
local schar			   = string.char
local slen			   = string.len
----------------------


-- Config --
local maxMsgNum = 6
local msgTime   = 6 -- time to display messages in seconds
local msgWidth  = 420
local settings = {
	autohide = true,
	}
------------

-- Chili elements --
local Chili
local screen
local window
local msgWindow
local log
--------------------

-- Local Variables --
local messages = {}
local curMsgNum = 1
local enteringText = false
local timer = getTimer()
local oldTimer = timer
local myID = Spring.GetMyPlayerID()
local players = {}
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

local function loadWindow()
		
	window = Chili.Window:New{
		parent  = screen,
		width   = msgWidth,
		color   = {0,0,0,0},
		height  = 100,
		padding = {0,0,0,0},
		right   = 450,
		y       = 0,
	}
	
	Chili.Window:New{
		parent = window,
		minHeight = 10,
		width  = msgWidth,
		height = 30,
		y      = 0,
		x      = 0,
	}
	
	msgWindow = Chili.ScrollPanel:New{
		parent      = window,
		x           = 0,
		y           = 30,
		right       = 0,
		bottom      = 0,
		padding     = {0,0,0,0},
		borderColor = {0,0,0,0},
		verticalSmartScroll = true,
	}

	log = Chili.StackPanel:New{
		parent      = msgWindow,
		x           = 0,
		y           = 0,
		height      = 0,
		width       = '100%',
		autosize    = true,
		resizeItems = false,
		padding     = {0,0,0,0},
		itemPadding = {1,1,1,1},
		itemMargin  = {1,1,1,1},
		preserveChildrenOrder = true,
	}

end

local function loadOptions()
	for setting,_ in pairs(settings) do
		settings[setting] = Menu.Load(setting) or settings[setting]
	end
	
	local function toggle(obj)
		local setting = obj.setting
		settings[setting] = not settings[setting]
		Menu.Save(setting, settings[setting])
	end
	
	local options = Chili.Control:New{
		x        = 0,
		width    = '100%',
		height   = 70,
		padding  = {0,0,0,0},
		children = {
			Chili.Label:New{caption='Chat',x=0,y=0},
			Chili.Checkbox:New{caption='Auto-Hide Chat',width=200,y=15,right=0,checked=false,
				setting='autohide',OnChange = {toggle}},
			Chili.Line:New{y=30,width='100%'}
		}
	}
	
	
	Menu.AddToStack('Interface', options)
end

local function getInline(color)
	return schar(255, (color[1]*255), (color[2]*255), (color[3]*255))
end

local function getPlayers()
	local IDs = getPlayerRoster()
	Spring.Echo("Number of players = "..#IDs)
	for i = 1, #IDs do
		local player = IDs[i]
		local name = player[1]
		Spring.Echo(player)
		local r,g,b = getTeamColor(player[3])
		players[name] = {}
		players[name].id    = player[2]
		players[name].team  = player[3]
		players[name].ally  = player[4]
		players[name].spec  = player[5]
		players[name].color = {r,g,b,0.7}
	end
end

function widget:Initialize()
	
	Chili  = WG.Chili
	screen = Chili.Screen0
	Menu   = WG.MainMenu
	if Menu then 
		loadOptions() 
	end
	loadWindow()
	
	--~ getPlayers()
	local buffer = getConsoleBuffer(40)
	for i=1,#buffer do
		line = buffer[i]
		widget:AddConsoleLine(line.text,line.priority)
	end
	
	-- Disable engine console
	sendCommands('console 0')
	
	-- Move input to line up with new console
	sendCommands('inputtextgeo '
		..(window.x/screen.width)..' '
		..(1 - (window.y + 30) / screen.height)
		..' 0.1 '
		..(window.width / screen.width) )
		
end

-- Adds dissappearing text
function widget:Update()
	timer = getTimer()
	if diffTimers(timer, oldTimer) > msgTime
	 and not enteringText
	 and settings.autohide then
		oldTimer = timer
		if msgWindow.visible then msgWindow:Hide() end
	end
end

local function processLine(line)

	local ignoreThisMessage = false
	local lineType = 0
	
	-- get data from player roster
	local roster = getPlayerRoster()
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
		local r,g,b,a = getTeamColor(names[name][3])
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
            local r,g,b,a = spGetTeamColor(names[name][3])
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

function widget:AddConsoleLine(msg)
	local text, ignore = processLine(msg)
	if ignore then return end
	Chili.TextBox:New{
		parent      = log,
		text        = text,
		width       = '100%',
		align       = "left",
		valign      = "ascender",
		padding     = {0,0,0,0},
		duplicates  = 0,
		lineSpacing = 0,
	}
	if msgWindow.hidden then msgWindow:Show() end
	oldTimer = getTimer()
end

function widget:KeyPress(key, modifier, isRepeat)
	if (key == KEYSYMS.RETURN) then
		if msgWindow.hidden then msgWindow:Show() end
		enteringText = true
	end 
end

function widget:Shutdown()
	sendCommands({'console 1', 'inputtextgeo default'})
	setConfigString('InputTextGeo', '0.26 0.73 0.02 0.028')
end

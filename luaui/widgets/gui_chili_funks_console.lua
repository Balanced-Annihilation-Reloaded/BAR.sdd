-- WIP
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
local getMouseState    = Spring.GetMouseState
----------------------


-- Config --
local msgTime   = 6 -- time to display messages in seconds
local msgWidth  = 420 --width of the console
local settings = {
	autohide = true,
	}
------------

-- Chili elements --
local Chili
local screen
local window
local input
local msgWindow
local log
--------------------

-- Local Variables --
local messages = {}
local endTime = getTimer() 
local startTime = endTime --time of last message (or last time at which we checked to hide the console and then didn't)
local myID = Spring.GetMyPlayerID()
local myAllyID = Spring.GetMyAllyTeamID()
local gameOver = false --is the game over?
---------------------

-- Text Colour Config --
local color = {
	oAlly = '\255\255\128\128', --enemy ally messages (seen only when spectating)
	misc  = '\255\200\200\200', --everything else
	game  = '\255\102\255\255', --server (autohost) chat
	other = '\255\255\255\255', --normal chat color
	ally  = '\255\001\255\001', --ally chat
	spec  = '\255\255\255\001', --spectator chat
}

local function loadWindow()
	
	-- parent
	window = Chili.Window:New{
		parent  = screen,
		width   = msgWidth,
		color   = {0,0,0,0},
		height  = 100,
		padding = {0,0,0,0},
		right   = 450,
		y       = 0,
	}
	
	-- input text box
	input = Chili.Window:New{
		parent    = window,
		minHeight = 10,
		width     = msgWidth,
		height    = 30,
		y         = 0,
		x         = 0,
	}
	
	-- chat box
	msgWindow = Chili.ScrollPanel:New{
		verticalSmartScroll = true,
		parent      = window,
		x           = 0,
		y           = 30,
		right       = 0,
		bottom      = 0,
		padding     = {0,0,0,0},
		borderColor = {0,0,0,0},
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
			Chili.Checkbox:New{caption='Auto-Hide Chat',width=200,y=15,right=0,
				checked=settings.autohide,setting='autohide',OnChange={toggle}},
			Chili.Line:New{y=30,width='100%'}
		}
	}
	
	Menu.AddToStack('Interface', options)
end

local function getInline(r,g,b)
	if type(r) == 'table' then
		return string.char(255, (r[1]*255), (r[2]*255), (r[3]*255))
	else
		return string.char(255, (r*255), (g*255), (b*255))
	end
end

local function mouseIsOverChat()
	local x,y = Spring.GetMouseState()
	y = screen.height - y -- chili has y axis with 0 at top!	
	if x > window.x and x < window.x + window.width and y > 0 and ((msgWindow.visible and y < window.height) or (msgWindow.hidden and y < input.height)) then
		return true
	else
		return false
	end
end

local function showChat()
	-- show chat
	startTime = getTimer()
	if msgWindow.hidden then
		msgWindow:Show()
	end
end

local function hideChat()
	-- hide the chat, unless the mouse is hovering over the chat window
	if msgWindow.visible and settings.autohide and not mouseIsOverChat() then
		msgWindow:Hide()
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
	
	-- load from console buffer
	local buffer = getConsoleBuffer(40)
	for i=1,#buffer do
		line = buffer[i]
		widget:AddConsoleLine(line.text,line.priority)
	end
	
	-- disable engine console
	sendCommands('console 0')
	
	-- move input to line up with new console
	sendCommands('inputtextgeo '
		..(window.x/screen.width)..' '
		..(1 - (window.y + 30) / screen.height)
		..' 0.1 '
		..(window.width / screen.width) )
	
end

function widget:Update()
	-- if console has been visible for longer than msgTime since last event, see if its not needed anymore
	endTime = getTimer()
	if diffTimers(endTime, startTime) > msgTime then
		startTime = endTime
		hideChat()
	end
end

function widget:GameOver()
	gameOver = true
end

local function processLine(line)

	-- get data from player roster 
	local roster = getPlayerRoster()
	local players = {}
	
	for i=1,#roster do
		players[roster[i][1]] = {
			ID     = roster[i][2],
			allyID = roster[i][4],
			spec   = roster[i][5],
			teamID = roster[i][3],
			color  = getInline(getTeamColor(roster[i][3])),
		}
	end
	-------------------------------
	
	local name = ''
	
	-- Player Message
	if line:find('<.->') then
		name = line:match('<(.-)>')
		text = line:gsub('<.->', '')
		
	-- Spec Message
	elseif line:find('%[.-%]') then
		name = line:match('%[(.-)%]')
		text = line:gsub('%[.-%]', '')
		
	-- Point added
	elseif line:find('added point:') then
		name = line:match('(.-)%sadded point: ')
		text = line:gsub('.-%sadded point: ', '')
		
	-- Game Message
	elseif line:sub(1,1) == ">" then
		return color.game .. line
		
	-- Filter messages
	elseif line:find('-> Version') or line:find('ClientReadNet') or line:find('Address') then --surplus info when user connects
		return _, true --ignore
	elseif gameOver and line:find('left the game') then --'user left' messages after game is over
		return _, true --ignore
		
	-- Everything else
	else
		return color.misc .. line
	end
	
	-- Get rid of any (now) unneeded info in the name
	name = name:gsub('%s%(replay%)','')
	name = name:gsub('%s%(spec%)','')

	if players[name] then
		local player = players[name]
		local textColor = color.other
		local nameColor = color.other
		
		if player.spec then
			name = '(S)'.. name
			textColor = color.spec
		else
			nameColor = player.color
			if text:find('Allies: ') then
				if player.allyID == myAllyID then
					textColor = color.ally
				else
					textColor = color.oAlly
				end
			elseif text:find('Spectators: ') then
				textColor = color.spec
			end
		end
		-- Get rid of any (now) unneeded info in the text
		text = text:gsub('Allies: ','')
		text = text:gsub('Spectators: ','')
		line = nameColor .. name .. ': ' .. textColor .. text
	end

	return color.misc .. line
end

function widget:AddConsoleLine(msg)
	-- update chat with new line
	local text, ignore = processLine(msg)
	if ignore then return end
	
	local prevMsg = log.children[#log.children]
	if prevMsg and (text == prevMsg.text or text == prevMsg.origText) then
		prevMsg.duplicates = prevMsg.duplicates + 1
		prevMsg.origText = text
		prevMsg:SetText(getInline{1,0,0}..(prevMsg.duplicates + 1)..'x \b'..text)
		return
	end
	
	Chili.TextBox:New{
		parent      = log,
		text        = text,
		width       = '100%',
		duplicates  = 0,
		align       = "left",
		valign      = "ascender",
		padding     = {0,0,0,0},
		duplicates  = 0,
		lineSpacing = 0,
		font        = {
			outline          = true,
			outlineColor     = {0,0,0,1},
			autoOutlineColor = false,
			outlineWidth     = 4,
			outlineWeight    = 3,
		},
	}
	showChat()
end

function widget:KeyPress(key, mods, isRepeat)

	-- show the chat window when we send a message
	if (key == KEYSYMS.RETURN) then
		showChat()
	end 

	-- if control is pressed and the mouse is hovering over the text input box, show the console 
	if mods.ctrl and mouseIsOverChat() then
		showChat()
	end

end

function widget:Shutdown()
	sendCommands({'console 1', 'inputtextgeo default'})
	setConfigString('InputTextGeo', '0.26 0.73 0.02 0.028') 
end

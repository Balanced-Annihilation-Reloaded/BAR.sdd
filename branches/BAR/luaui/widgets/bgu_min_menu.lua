-- WIP
function widget:GetInfo()
	return {
		name    = 'Min Menu',
		desc    = 'Small panel for main menu access and to show time and FPS',
		author  = 'Funkencool, Bluestone',
		date    = '2013',
		license = 'GNU GPL v2',
		layer   = 10,
		handler = true,
		enabled = true
	}
end

local spGetFPS = Spring.GetFPS
local Chili, Menu
local clockType = "ingame" -- or "system", meaning ingame time or system time
local oTime,rTime

local function dbl(s)
	if s<9 then return "0" .. s else return s end
end

local function setGameTime(n)
	-- Possibly add option to include time paused?
	-- local gameSeconds = Spring.GetGameSeconds()
	local gameSeconds = math.floor(n / 30)
	local seconds = gameSeconds % 60
	local minutes = (gameSeconds - seconds) / 60
	timeLbl:SetCaption('\255\255\127\0 '.. dbl(minutes) .. ":" .. dbl(seconds))
end

local function setRealTime(rTime)
	oTime = rTime
	if string.find(rTime,'0')==1 then rTime = string.sub(rTime,2) end
	timeLbl:SetCaption('\255\255\127\0'..string.lower(rTime))
end

local function loadOptions()
	clockType = Menu.Load('clockType') or clockType

	Menu.AddOption{
		tab      = 'Interface',
		children = {
			Chili.Label:New{caption='Clock',x='0%',fontsize=18},
			Chili.ComboBox:New{
				x        = '10%',
				width    = '80%',
				items    = {"Ingame time", "System clock"},
				selected = (clockType=="ingame" and 1) or 2,
				OnSelect = {
					function(_,sel)
						if sel == 1 then
							setGameTime(Spring.GetGameFrame())
							clockType = 'ingame'
						else
							setRealTime(os.date('%I:%M %p'))
							clockType = 'system'
						end
						Menu.Save{["clockType"]=clockType}
					end
				}
			},
			Chili.Line:New{width='100%'},
		}
	}
	
	if clockType=='ingame' then
		timeLbl:SetCaption('\255\255\127\0 00:00')
	end

end

local function loadMinMenu()
	
	timeLbl = Chili.Label:New{
		caption = os.date('%I:%M %p'),
		x       = 0
	}
	
	fpsLbl = Chili.Label:New{
		caption = 'FPS: 65',
		x       = 65
	}
	
	menuBtn = Chili.Button:New{
		caption = 'Menu', 
		right   = 0,
		height  = '100%', 
		width   = 50,
		Onclick = {
			function() 
				WG.MainMenu.ShowHide() 
			end
		},
	}
	
	minMenu = Chili.Panel:New{
		parent    = Chili.Screen0,
		right     = 210, 
		y         = 60, 
		width     = 180,
		minheight = 20, 
		height    = 20,
		padding   = {5,0,0,0},
		children  = {timeLbl,fpsLbl,menuBtn}
	}
end

function widget:Initialize()
	Chili = WG.Chili	
	Menu = WG.MainMenu
	loadMinMenu()
	if Menu then
		loadOptions()
	end
end

function widget:Update()

	local fps = 'FPS: '..'\255\255\127\0'..spGetFPS()
	fpsLbl:SetCaption(fps)
	
	if clockType=="system" then
		local rTime = os.date('%I:%M %p')
		if oTime ~= rTime then setRealTime(rTime) end
	end

end

function widget:GameFrame(n)
	if n%30~=0 then return end
	if clockType=="ingame" then setGameTime(n) end
end

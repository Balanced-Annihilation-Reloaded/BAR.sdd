-- WIP
function widget:GetInfo()
	return {
		name    = 'Funks Min Menu',
		desc    = 'Small Window to access Main Menu, as well as show time and FPS',
		author  = 'Funkencool',
		date    = '2013',
		license = 'GNU GPL v2',
		layer   = -99,
		handler = true,
		enabled = true
	}
end
local spGetFPS = Spring.GetFPS
local Chili
---------------------------- 
-- The always visible window beneath resbars
--  for access to menu, as well as time and FPS
local function loadMinMenu()
	
	timeLbl = Chili.Label:New{
		caption = '10:30pm',
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
	
	minMenu = Chili.Window:New{
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


-------------------------- 
--
function widget:Initialize()
	Chili = WG.Chili
	loadMinMenu()
end

function widget:DrawScreen()
	local fps = 'FPS: '..'\255\255\127\0'..spGetFPS()
	fpsLbl:SetCaption(fps)
	local rTime = os.date('%I:%M %p')
	if oTime ~= rTime then
		oTime = rTime
		if string.find(rTime,'0')==1 then rTime = string.sub(rTime,2) end
		timeLbl:SetCaption('\255\255\127\0'..string.lower(rTime))
	end
end

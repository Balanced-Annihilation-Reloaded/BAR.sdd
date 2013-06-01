function widget:GetInfo()
	return {
		name		    = "BAR's funken tooltip",
		desc		    = "v0.1 of simple tooltip",
		author		  = "Funkencool",
		date		    = "2013",
		license     = "public domain",
		layer		    = math.huge,
		enabled   	= true
	}
end

--Chili elements
local Chili, cursortip, screen0
local varVar = 0
local mousePosX, mousePosY
local spGetCurrentTooltip = Spring.GetCurrentTooltip
local spTraceScreenRay 		= Spring.TraceScreenRay
local spGetMouseState			= Spring.GetMouseState
local spGetUnitTooltip = Spring.GetUnitTooltip
local tooltip = ""
local screenWidth, screenHeight = Spring.GetWindowGeometry()


local function initWindow()
	control0	= Chili.Window:New{parent = screen0, width = 300, height = 75, padding = {5,0,0,0},minHeight=1}
	tip				= Chili.TextBox:New{parent = control0, x = 0, y = 0, right = 0, bottom = 0,margin = {0,0,0,0}}
end

local function MakeToolTip(tooltip,x,y)
	if tooltip ~= '' then 
		local textwidth = tip.font:GetTextWidth(tooltip)
		local textheight,_,numLines = tip.font:GetTextHeight(tooltip)
		control0:SetPos(x + 20, screenHeight - y + 20,textwidth+10,14*numLines+2)
		if control0.hidden then control0:Show() end
		control0:BringToFront()
	elseif control0.visible then control0:Hide() end
	tip:SetText(tooltip)
end

function widget:DrawScreen()
	local mousePosX, mousePosY = spGetMouseState()
	local typeOver, ID = spTraceScreenRay(mousePosX, mousePosY)
	if screen0.currentTooltip then tooltip = screen0.currentTooltip
	elseif typeOver == "unit" then tooltip = spGetUnitTooltip(ID)
	else tooltip = '' end
	if tip.text ~= tooltip then
		MakeToolTip(tooltip,mousePosX, mousePosY)
	end
end


function widget:Initialize()
	if not WG.Chili then return end
	Chili = WG.Chili
	screen0 = Chili.Screen0
	initWindow()
end
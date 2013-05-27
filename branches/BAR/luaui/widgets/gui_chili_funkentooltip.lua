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
local tooltip = ""
local screenWidth, screenHeight = Spring.GetWindowGeometry()


local function initWindow()
	control0	= Chili.Window:New{parent = screen0, width = 300, height = 75, padding = {5,0,0,0}}
	tip				= Chili.TextBox:New{parent = control0, x = 0, y = 0, right = 0, bottom = 0}
end

local function MakeToolTip(tooltip)
	if tooltip then 
		if not control0:IsDescendantOf(screen0) then screen0:AddChild(control0) end
		if mousePosX < 0.5*screen0.width then control0:SetPos(mousePosX + 20, screenHeight - mousePosY)
		else control0:SetPos(mousePosX - 300, screenHeight - mousePosY) end
		control0:BringToFront()
	elseif control0:IsDescendantOf(screen0) then screen0:RemoveChild(control0) end
	tip:SetText(tooltip)
end

function widget:DrawScreen()
	mousePosX, mousePosY = spGetMouseState()
	local typeOver, ID = spTraceScreenRay(mousePosX, mousePosY)
	if screen0.currentTooltip then tooltip = screen0.currentTooltip
	elseif typeOver == "unit" then tooltip = Spring.GetUnitTooltip(ID)
	else tooltip = nil end
	MakeToolTip(tooltip)
end


function widget:Initialize()
	if not WG.Chili then return end
	Chili = WG.Chili
	screen0 = Chili.Screen0
	initWindow()
end
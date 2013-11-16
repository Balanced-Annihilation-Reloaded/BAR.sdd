-- WIP
function widget:GetInfo()
	return {
		name    = 'Funks cursor tooltip',
		desc    = 'A simple tooltip to appear when hovering mouse',
		author  = 'Funkencool',
		date    = '2013',
		license = 'GNU GPL v2',
		layer   = 0,
		enabled = true,
	}
end

local Chili, screen0, tipWindow, tip
local mousePosX, mousePosY
local showFrame
local tooltip = ''

local spTraceScreenRay          = Spring.TraceScreenRay
local spGetMouseState           = Spring.GetMouseState
local spGetUnitTooltip          = Spring.GetUnitTooltip
local spGetUnitResources        = Spring.GetUnitResources
local spGetFeatureResources     = Spring.GetFeatureResources
local screenWidth, screenHeight = Spring.GetWindowGeometry()
-----------------------------------
local function initWindow()
	tipWindow = Chili.Window:New{
		parent    = screen0, 
		skin      = 'Flat', 
		width     = 75,
		height    = 75,
		minHeight = 1,
		padding   = {5,2,2,2},
	}
	tip = Chili.TextBox:New{
		parent = tipWindow, 
		x      = 0,
		y      = 0,
		right  = 0, 
		bottom = 0,
		margin = {0,0,0,0},
	}
	
	tipWindow:Hide()
end

-----------------------------------
local function formatresource(description, res)
	color = ""
	if res < 0 then color = '\255\255\127\0' end
	if res > 0 then color = '\255\127\255\0' end
	
	if math.abs(res) > 20 then -- no decimals for small numbers
		res = string.format("%d", res)
		else
		res = string.format("%.1f",res)
	end
	return color .. description .. res
end
-----------------------------------
local function getUnitTooltip(ID)
	local tooltip = spGetUnitTooltip(ID)
	if tooltip==nil then
		tooltip=""
	end
	local metalMake, metalUse, energyMake, energyUse = spGetUnitResources(ID)
	
	local metal = ((metalMake or 0) - (MetalUse or 0))
	local energy = ((energyMake or 0) - (energyUse or 0))
	
	tooltip = tooltip..'\n'..formatresource("Metal: ", metal)..'/s\b\n' .. formatresource("Energy: ", energy)..'/s'
	return tooltip
end
-----------------------------------
local function getFeatureTooltip(ID)
	local rMetal, mMetal, rEnergy, mEnergy, reclaimLeft = spGetFeatureResources(ID)
	local tooltip = "Metal: "..rMetal..'\n'.."Energy: "..rEnergy
	return tooltip
end
-----------------------------------
local function getTooltip()
	mousePosX, mousePosY   = spGetMouseState()
	local typeOver, ID     = spTraceScreenRay(mousePosX, mousePosY)
	if screen0.currentTooltip    then tooltip = screen0.currentTooltip
	elseif typeOver == 'unit'    then tooltip = getUnitTooltip(ID)
	elseif typeOver == 'feature' then tooltip = getFeatureTooltip(ID)
	else                              tooltip = ''
	end
end
-----------------------------------

local function MakeToolTip()
	   
	local tooltip               = tooltip
	local x,y                   = mousePosX,mousePosY
	local textwidth             = tip.font:GetTextWidth(tooltip)
	local textheight,_,numLines = tip.font:GetTextHeight(tooltip)

	-- Making sure the tooltip is within the boundaries of the screen
	if (x + 20 + textwidth + 10) > screenWidth then
		x = screenWidth - 20 - textwidth - 10
	end
	if (y - 20 - (14 * numLines + 2)) < 0 then
		y = 14 * numLines + 2 + 20
	end

	tipWindow:SetPos(x + 20, screenHeight - y + 20, textwidth + 10, 14 * numLines + 2)
   
	if tipWindow.hidden then tipWindow:Show() end
	tipWindow:BringToFront()
end
-----------------------------------
function widget:GameFrame(frame)
	getTooltip()
	if tip.text ~= tooltip then
		showFrame = frame + 20
		tip:SetText(tooltip)
		if tipWindow.visible then tipWindow:Hide() end
	elseif showFrame < frame and tooltip ~= '' then
		MakeToolTip()
	end
end
-----------------------------------
function widget:Initialize()
	if not WG.Chili then return end
	Chili = WG.Chili
	screen0 = Chili.Screen0
	initWindow()
end

function widget:Shutdown()
	tipWindow:Dispose()
end


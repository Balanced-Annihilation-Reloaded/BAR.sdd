-- WIP
function widget:GetInfo()
	return {
		name    = 'Cursor tooltip',
		desc    = 'Provides a tooltip whilst hovering the mouse',
		author  = 'Funkencool',
		date    = '2013',
		license = 'GNU GPL v2',
		layer   = 0,
		enabled = true,
	}
end

local Chili, screen, tipWindow, tip
local mousePosX, mousePosY
local oldTime
local tipType = 'none'
local tooltip = ''
local ID

local spGetTimer                = Spring.GetTimer
local spDiffTimers              = Spring.DiffTimers
local spTraceScreenRay          = Spring.TraceScreenRay
local spGetMouseState           = Spring.GetMouseState
local spGetUnitTooltip          = Spring.GetUnitTooltip
local spGetUnitResources        = Spring.GetUnitResources
local spGetFeatureResources     = Spring.GetFeatureResources
local spGetFeatureDefID         = Spring.GetFeatureDefID
local screenWidth, screenHeight = Spring.GetWindowGeometry()
-----------------------------------
function firstToUpper(str)
    -- make the first char of a string into upperCase
    return (str:gsub("^%l", string.upper))
end
-----------------------------------
local function initWindow()
	tipWindow = Chili.Panel:New{
		parent    = screen, 
		skin      = 'Flat', 
		width     = 75,
		height    = 75,
		minHeight = 1,
		padding   = {5,4,4,4},
	}
	tip = Chili.TextBox:New{
		parent = tipWindow, 
		x      = 0,
		y      = 0,
		right  = 0, 
		bottom = 0,
		margin = {0,0,0,0},
        font = {            
            outline          = true,
            autoOutlineColor = true,
            outlineWidth     = 3,
            outlineWeight    = 4,
        }
	}
	
	oldTime = spGetTimer()
	tipWindow:Hide()
end

function widget:ViewResize(vsx, vsy)
	screenWidth = vsx
	screenHeight = vsy
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
local function getUnitTooltip(uID)
	local tooltip = spGetUnitTooltip(uID)
	if tooltip==nil then
		tooltip=""
	end
	local metalMake, metalUse, energyMake, energyUse = spGetUnitResources(uID)
	
	local metal = ((metalMake or 0) - (MetalUse or 0))
	local energy = ((energyMake or 0) - (energyUse or 0))
	
	tooltip = tooltip..'\n'..formatresource("Metal: ", metal)..'/s\b\n' .. formatresource("Energy: ", energy)..'/s'
	return tooltip
end
-----------------------------------
local function getFeatureTooltip(fID)
	local rMetal, mMetal, rEnergy, mEnergy, reclaimLeft = spGetFeatureResources(fID)
    local fDID = spGetFeatureDefID(fID)
    local fName = FeatureDefs[fDID].tooltip
	local tooltip = "Metal: "..rMetal..'\n'.."Energy: "..rEnergy
    if fName then tooltip = firstToUpper(fName) .. '\n' .. tooltip end
	return tooltip
end
-----------------------------------
local prevTipType, prevID
local function getTooltip()
	mousePosX, mousePosY   = spGetMouseState()
	tipType, ID     = spTraceScreenRay(mousePosX, mousePosY)
    
    if tipType==prevTipType and ID==prevID then return end
    prevTipType = tipType
    prevID = ID
    
	if screen.currentTooltip    then tooltip = screen.currentTooltip
	elseif tipType == 'unit'    then tooltip = getUnitTooltip(ID)
	elseif tipType == 'feature' then tooltip = getFeatureTooltip(ID)
	else                             tooltip = ''
	end
end
-----------------------------------

local function setTooltip()
	   
	local tooltip               = tooltip
	local x,y                   = mousePosX,mousePosY
	local textwidth             = tip.font:GetTextWidth(tooltip)
	local textheight,_,numLines = tip.font:GetTextHeight(tooltip)

	-- Making sure the tooltip is within the boundaries of the screen
	if (x + 20 + textwidth + 10) > screenWidth then
		x = screenWidth - 20 - textwidth - 10
	end
	if (y - 20 - (14 * numLines + 5)) < 0 then
		y = 14 * numLines + 5 + 20 
	end

	tipWindow:SetPos(x + 20, screenHeight - y + 20, textwidth + 10, 14 * numLines + 8)
   
	if tipWindow.hidden then tipWindow:Show() end
	tipWindow:BringToFront()
end
-----------------------------------
function widget:Update()
	local showTip = tipType ~= 'unit' and tipType ~= 'feature' and tooltip ~= ''
	local curTime = spGetTimer()
	getTooltip()
	if tip.text ~= tooltip then
		tip:SetText(tooltip)
		oldTime = spGetTimer()
		if tipWindow.visible then 
			tipWindow:Hide()
		end
	elseif (spDiffTimers(curTime, oldTime) > 1 and tooltip ~= '') or showTip then
		setTooltip()
	end
end
-----------------------------------
function widget:Initialize()
	if not WG.Chili then return end
	Chili = WG.Chili
	screen = Chili.Screen0
	initWindow()
end

function widget:Shutdown()
	tipWindow:Dispose()
end


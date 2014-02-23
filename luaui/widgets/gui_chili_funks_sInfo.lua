-- WIP
function widget:GetInfo()
	return {
		name      = 'Funks current selection info',
		desc      = 'Shows information about current selection',
		author    = 'Funkencool',
		date      = '2013',
		license   = 'GNU GPL v2',
		layer     = math.huge,
		enabled   = true,
		handler   = true,
	}
end

local imageDir = 'luaui/images/buildIcons/'

local Chili ,infoWindow, unitInfo, unitName, unitIcon, selectionGrid, unitHealth, groundInfo 
local healthBars = {}
local updateNow  = false

local green = {0,0.8,0,1}


local curTip --[[ current tooltip type: 
                  -3 for ground info
                  -2 for so many unitDefIDs that we just give text info 
                  -1 for multiple unitDefIDs that fit with pics (<=9)
                  >=0 for a single unit & is the unitID  ]]

local spGetTimer                = Spring.GetTimer
local spDiffTimers              = Spring.DiffTimers
local spGetUnitDefID            = Spring.GetUnitDefID
local spGetUnitTooltip          = Spring.GetUnitTooltip
local spGetSelectedUnits        = Spring.GetSelectedUnits
local spGetUnitHealth           = Spring.GetUnitHealth
local spGetSelectedUnitsSorted  = Spring.GetSelectedUnitsSorted
local spGetMouseState           = Spring.GetMouseState
local spTraceScreenRay          = Spring.TraceScreenRay
local spGetGroundHeight         = Spring.GetGroundHeight
local spSelectUnitArray         = Spring.SelectUnitArray

local r,g,b     = Spring.GetTeamColor(Spring.GetMyTeamID())
local teamColor = {r,g,b}

local timer = spGetTimer()
local healthTimer = timer
local groundTimer = timer


local function selectGroup(obj)
	-- TODO:
	--  add key functionality
	--  for example if shift is pressed, group is removed
	spSelectUnitArray(obj.unitIDs)
end
----------------------------------
-- add unitDefID (curTip = -1)
local function addUnitGroup(name,texture,overlay,unitIDs)
	local count = #unitIDs
	if count == 1 then count = '' end
	
	local unitCount = Chili.Label:New{
		caption = count,
		y       = 0,
		right   = 0,
	}
	
	healthBars[#healthBars + 1] = Chili.Progressbar:New{
		unitIDs = unitIDs,
		value   = 0,
		bottom  = 1,
		x       = 0,
		width   = '100%',
		height  = 6,
		color   = green,
	}
	
	local unitIcon = Chili.Image:New{
		file     = texture,
		height   = '100%',
		width    = '100%',
		children = {
			Chili.Image:New{
				color    = teamColor,
				height   = '100%',
				width    = '100%',
				file     = overlay,
				children = {unitCount}
			},
		},
	}
	
	local button = Chili.Button:New{
		unitIDs  = unitIDs,
		caption  = '',
		margin   = {1,1,1,1},
		padding  = {0,0,0,0},
		children = {unitIcon, healthBars[#healthBars]},
		OnClick  = {selectGroup},
	}
	
	selectionGrid:AddChild(button)
end

----------------------------------
-- unit info (curTip >= 0)
local function showUnitInfo(texture, overlay, description, humanName, health, maxHealth)
	
	unitName = Chili.TextBox:New{
		x      = 0,
		y      = 5,
		right  = 0,
		bottom = 0,
		text   = " " .. humanName..'\n'.. " " .. description,
	}

	unitHealth = Chili.Progressbar:New{
		caption = math.floor(health) ..' / '.. math.floor(maxHealth),
		value   = 0,
		bottom  = 5,
		x       = 0,
		width   = '100%',
		height  = 25,
		color   = green,
	}
	
	unitIcon = Chili.Image:New{
		file     = texture,
		y        = 0,
		height   = '100%',
		width    = '100%',
		children = {
			Chili.Image:New{
				color    = teamColor,
				height   = '100%',
				width    = '100%',
				file     = overlay,
				children = {unitName, unitHealth},
			}
		}
	}
	
	
	unitInfo:AddChild(unitIcon)
	
end
----------------------------------
-- text unit info only (curTip = -2)
local function showBasicSelectionInfo(num, numTypes)
	
	basicUnitInfo = Chili.TextBox:New{
		x      = 0,
		y      = 5,
		right  = 0,
		bottom = 0,
		text   = " Units selected: " .. num .. "\n Unit types: " .. numTypes,
	}
	
	unitInfo:AddChild(basicUnitInfo)
end

----------------------------------
local function getInfo()
	
	units = spGetSelectedUnits()
	
	if #units == 0 then
		--info about point on map corresponding to cursor (updated every other gameframe)
		curTip = -3
	elseif #units == 1 then
		--detailed info about a single unit
		local unitID      = units[1]
		curTip = unitID
		local defID       = spGetUnitDefID(unitID)
		local description = UnitDefs[defID].tooltip or ''
		local name        = UnitDefs[defID].name
		local texture     = imageDir..'Units/' .. name .. '.png'
		local overlay     = imageDir..'Overlays/' .. name .. '.png'
		local humanName   = UnitDefs[defID].humanName
		local curHealth, maxHealth = spGetUnitHealth(unitID)

		showUnitInfo(texture, overlay, description, humanName, curHealth, maxHealth)
		
	else
		--broad info about lots of units
		curTip = -1
		local sortedUnits = spGetSelectedUnitsSorted()
		local unitDefIDCount = 0
		local unitCount = 0
			--see if sortedUnits has too many elements
			if sortedUnits["n"] <= 9 then 
				--pics & healthbars, grouped by UnitDefID, if it fits
				for unitDefID, unitIDs in pairs(sortedUnits) do
					if unitDefID ~= 'n' then 
						local name    = UnitDefs[unitDefID].name
						local texture = imageDir..'Units/' .. name .. '.png'
						local overlay = imageDir..'Overlays/' .. name .. '.png'
						addUnitGroup(name,texture,overlay,unitIDs)
					end
				end
			else
				showBasicSelectionInfo(#units, sortedUnits["n"])
			end
	end
end

----------------------------------
-- ground info (curTip = -3)
local function updateGroundInfo()
	
	local mx, my    = spGetMouseState()
	local focus,map = spTraceScreenRay(mx,my)
	if focus == "ground" and map[1] then
		local px,pz = math.floor(map[1]),math.floor(map[3])
		local py = math.floor(spGetGroundHeight(px,pz))
		groundText:SetText(" Position: " .. px ..  ", " .. pz .. "\n" .. " Height: " .. py)
		groundText:Invalidate()
	end
end

----------------------------------
local function updateHealthBars()
	
	--single unit	
	if curTip >= 0 then 
		local health, maxHealth = spGetUnitHealth(curTip)
		unitHealth:SetCaption(math.floor(health) ..' / '.. math.floor(maxHealth))
		unitHealth.max = maxHealth
		unitHealth:SetValue(health)
		
	--multiple units, but not so many we cant fit pics
	elseif curTip == -1 then 
		for unitGroup = 1, #healthBars do
			local value, max = 0, 0
			for id = 1, #healthBars[unitGroup].unitIDs do
				local health, maxhealth = spGetUnitHealth(healthBars[unitGroup].unitIDs[id])
				max   = max + maxhealth
				value = value + health
			end
			healthBars[unitGroup].max = max
			healthBars[unitGroup]:SetValue(value)
		end

	end
	
	updateNow = false
end

----------------------------------
function widget:Initialize()
	

	
	if (not WG.Chili) then
		widgetHandler:RemoveWidget()
		return
	end
	
	Chili   = WG.Chili
	screen0 = Chili.Screen0
	winSize = screen0.height * 0.2
	
	--Main window, ancestor of everything
	infoWindow = Chili.Window:New{
		padding = {5,5,5,5},
		parent  = Chili.Screen0,
		x       = 0,
		y       = 1,
		width   = winSize,
		height  = winSize,
	}
	
	selectionGrid = Chili.Grid:New{
		parent  = infoWindow,
		x       = 0,
		y       = 0,
		height  = '100%',
		width   = '100%',
		rows    = 3,
		columns = 3,
		padding = {0,0,0,0},
		margin  = {0,0,0,0},
	}
	
	unitInfo = Chili.Control:New{
		parent  = infoWindow,
		x       = 0,
		y       = 0,
		height  = '100%',
		width   = '100%',
		padding = {0,0,0,0},
		margin  = {0,0,0,0},
	}
	
	groundText = Chili.TextBox:New{
		parent = infoWindow,
		x      = 0,
		y      = 5,
		right  = 0,
		bottom = 0,
		text   = 'test',
	}
	
	Spring.SetDrawSelectionInfo(false)
	widget:CommandsChanged()
end

----------------------------------
function widget:CommandsChanged()
	curTip = nil
	healthBars = {}
	groundText:SetText('')
	selectionGrid:ClearChildren()
	unitInfo:ClearChildren()
	getInfo()
	updateNow = true
end

-- Updates health bars or ground info depending on curtip
--   -3 for ground info
--   -2 for so many unitDefIDs that we just give text info (doesn't require updating)
--   -1 for multiple unitDefIDs that fit with pics (<=9)
--   >=0 for a single unit & is the unitID
function widget:Update()
	
	if curTip == nil then return end
	
	local timer = spGetTimer()
	local updateGround = curTip == -3 and spDiffTimers(timer, groundTimer) > 0.1 
	local updateHealth = curTip >= -1 and (spDiffTimers(timer, healthTimer) > 1 or updateNow)
	
	if updateGround then
		updateGroundInfo()
		groundTimer = timer
	elseif updateHealth then
		updateHealthBars()
		healthTimer = timer
	end
end

----------------------------------
function widget:Shutdown()
	infoWindow:Dispose()
	Spring.SetDrawSelectionInfo(true)
end


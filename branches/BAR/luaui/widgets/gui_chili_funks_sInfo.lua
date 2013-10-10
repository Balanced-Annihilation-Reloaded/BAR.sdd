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

local Chili ,infoWindow, unitInfo, unitName, unitIcon, selectionGrid, unitHealth, unitProg
local healthBars = {}
local updateNow

local spGetUnitDefID            = Spring.GetUnitDefID
local spGetUnitTooltip          = Spring.GetUnitTooltip
local spGetSelectedUnits        = Spring.GetSelectedUnits
local spGetUnitHealth           = Spring.GetUnitHealth
local spGetSelectedUnitsSorted  = Spring.GetSelectedUnitsSorted

local r,g,b     = Spring.GetTeamColor(Spring.GetMyTeamID())
local teamColor = {r,g,b}

----------------------------------
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
		color   = {0.5,1,0,1},
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
		caption  = '',
		margin   = {1,1,1,1},
		padding  = {0,0,0,0},
		children = {unitIcon, healthBars[#healthBars]},
	}
	
	selectionGrid:AddChild(button)
end

----------------------------------
local function showUnitInfo(texture, overlay, description, humanName)
	
	unitName = Chili.TextBox:New{
		x      = 0,
		y      = 0,
		right  = 0,
		bottom = 0,
		text   = humanName..'\n'..description,
	}
	
	unitHealth = Chili.Progressbar:New{
		value   = 0,
		bottom  = 5,
		x       = 0,
		width   = '50%',
		height  = 10,
		color   = {0.5,1,0,1},
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
local function getInfo()
	
	local sortedUnits = spGetSelectedUnitsSorted()
	local units = spGetSelectedUnits()
	
	if #units == 1 then
		
		local unitID      = units[1]
		local defID       = spGetUnitDefID(unitID)
		local description = UnitDefs[defID].tooltip or ''
		local name        = UnitDefs[defID].name
		local texture     = imageDir..'Units/' .. name .. '.png'
		local overlay     = imageDir..'Overlays/' .. name .. '.png'
		local humanName   = UnitDefs[defID].humanName
		
		unitProg = unitID
		showUnitInfo(texture, overlay, description, humanName)
		
		else
		
		for defID, unitIDs in pairs(sortedUnits) do
			if defID == 'n' then break end
			
			local name    = UnitDefs[defID].name
			local texture = imageDir..'Units/' .. name .. '.png'
			local overlay = imageDir..'Overlays/' .. name .. '.png'
			
			addUnitGroup(name,texture,overlay,unitIDs)
			
		end
		
	end
	
end

----------------------------------
----------------------------------
function widget:Initialize()
	

	
	if (not WG.Chili) then
		widgetHandler:RemoveWidget()
		return
	end
	
	Chili   = WG.Chili
	screen0 = Chili.Screen0
	winSize = screen0.height * 0.2
	
	--Main window, parent of everything
	infoWindow = Chili.Window:New{
		padding = {0,0,0,0},
		parent  = Chili.Screen0,
		x       = 0,
		y  = 1,
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
	
	Spring.SetDrawSelectionInfo(false)
end

----------------------------------
function widget:CommandsChanged()
	unitProg = nil
	healthBars = {}
	selectionGrid:ClearChildren()
	unitInfo:ClearChildren()
	getInfo()
	updateNow = true
end

----------------------------------
function widget:Shutdown()
	infoWindow:Dispose()
	Spring.SetDrawSelectionInfo(true)
end

function widget:GameFrame(n)
	if (n % 30 < 1) or updateNow then
		if unitProg then
			
			local health, maxhealth = spGetUnitHealth(unitProg)
			unitHealth:SetMinMax(0,maxhealth)
			unitHealth:SetValue(health)
			
			elseif #healthBars > 0 then
			for a=1, #healthBars do
				local value, max = 0, 0
				for b=1, #healthBars[a].unitIDs do
					local health, maxhealth = spGetUnitHealth(healthBars[a].unitIDs[b])
					max   = max + maxhealth
					value = value + health
				end
				healthBars[a].max = max
				healthBars[a]:SetValue(value)
			end
		end
		
		updateNow = false
	end
end







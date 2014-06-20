--------------------------------------------------------------------------------
function widget:GetInfo()
    return {
        name      = "Antinuke range",
        desc      = "Draws circle to show anti defence ranges (options: /antiranges_glow, antiranges_fade)",
        author    = "[teh]decay, Floris",
        date      = "20 june 2014",
        license   = "GNU GPL, v2 or later",
        version   = 3,
        layer     = 5,
        enabled   = true  --  loaded by default?
    }
end

-- project page on github: https://github.com/jamerlan/gui_mobile_anti_defence_range

--Changelog
-- v2 [teh]decay:  Add water antinukes
-- v3 Floris:  added normal anti, changed widget name, optional glow, optional fadeout on closeup, changed line thickness and opacity, empty anti uses different color


--------------------------------------------------------------------------------
-- Console commands
--------------------------------------------------------------------------------

--/antiranges_glow		-- toggles a faint glow on the line
--/antiranges_fade		-- toggles hiding of ranges when zoomed in

--------------------------------------------------------------------------------
-- Options
--------------------------------------------------------------------------------

local filledStockpileColor		= {1,1,0}
local emptyStockpileColor		= {1,0.45,0}
local showLineGlow				= true
local fadeOnCloseup        		= true
local fadeStartDistance			= 2900

--------------------------------------------------------------------------------
-- Speedups
--------------------------------------------------------------------------------

local arm_anti					= UnitDefNames.armamd.id
local arm_mobile_anti			= UnitDefNames.armscab.id
local arm_mobile_anti_water		= UnitDefNames.armcarry.id
local core_anti					= UnitDefNames.corfmd.id
local core_mobile_anti			= UnitDefNames.cormabm.id
local core_mobile_anti_water	= UnitDefNames.corcarry.id

local spGetActiveCommand		= Spring.GetActiveCommand
local spGetMouseState			= Spring.GetMouseState
local spTraceScreenRay			= Spring.TraceScreenRay
local spPos2BuildPos			= Spring.Pos2BuildPos

local glColor					= gl.Color
local glDepthTest				= gl.DepthTest
local glLineWidth				= gl.LineWidth
local glDrawGroundCircle		= gl.DrawGroundCircle


local spGetMyPlayerID			= Spring.GetMyPlayerID
local spGetPlayerInfo			= Spring.GetPlayerInfo
local spGetMyAllyTeamID			= Spring.GetMyAllyTeamID
local spGetUnitDefID			= Spring.GetUnitDefID
local spGetUnitPosition			= Spring.GetUnitPosition
local spGetUnitVelocity			= Spring.GetUnitVelocity
local spMarkerAddPoint			= Spring.MarkerAddPoint
local spGetTeamUnits			= Spring.GetTeamUnits
local spGetPositionLosState 	= Spring.GetPositionLosState
local spGetCameraPosition		= Spring.GetCameraPosition
local spGetUnitStockpile		= Spring.GetUnitStockpile

local mobileAntiInLos			= {}
local mobileAntiOutOfLos		= {}


local coverageRangeArmStatic	= WeaponDefs[UnitDefNames.armamd.weapons[1].weaponDef].coverageRange
local coverageRangeCoreStatic	= WeaponDefs[UnitDefNames.corfmd.weapons[1].weaponDef].coverageRange
local coverageRangeArm			= WeaponDefs[UnitDefNames.armscab.weapons[1].weaponDef].coverageRange
local coverageRangeCore			= WeaponDefs[UnitDefNames.cormabm.weapons[1].weaponDef].coverageRange
local coverageRangeArmWater		= WeaponDefs[UnitDefNames.armcarry.weapons[1].weaponDef].coverageRange
local coverageRangeCoreWater	= WeaponDefs[UnitDefNames.corcarry.weapons[1].weaponDef].coverageRange

--------------------------------------------------------------------------------
-- Callins
--------------------------------------------------------------------------------



function widget:DrawWorld()
    if Spring.IsGUIHidden() then return end
	local camX, camY, camZ = spGetCameraPosition()
    for uID, pos in pairs(mobileAntiInLos) do
        local x, y, z = spGetUnitPosition(uID)
        
        if x ~= nil and y ~= nil and z ~= nil then
			drawCircle(uID, pos.coverageRange, x, y, z, camX, camY, camZ)
        end
    end

    for uID, pos in pairs(mobileAntiOutOfLos) do
        local a, b, c = spGetPositionLosState(pos.x, pos.y, pos.z)
        if b then
            mobileAntiOutOfLos[uID] = nil
        end
    end

    for uID, pos in pairs(mobileAntiOutOfLos) do
        if pos.x ~= nil and pos.y ~= nil and pos.z ~= nil then
			drawCircle(uID, pos.coverageRange, pos.x, pos.y, pos.z, camX, camY, camZ)
        end
    end
end


function drawCircle(uID, coverageRange, x, y, z, camX, camY, camZ)
	local xDifference = camX - x
	local yDifference = camY - y
	local zDifference = camZ - z
	local camDistance = math.sqrt(xDifference*xDifference + yDifference*yDifference + zDifference*zDifference)
	
	local lineWidthMinus = (camDistance/2000)
	if lineWidthMinus > 2 then
		lineWidthMinus = 2
	end
	local lineOpacityMultiplier = 1
	if fadeOnCloseup then
		lineOpacityMultiplier = (camDistance - fadeStartDistance) / 1800
		if lineOpacityMultiplier > 1 then
			lineOpacityMultiplier = 1
		end
	end
	
	local numStockpiled,numStockpileQued,stockpileBuild = spGetUnitStockpile(uID)
	local circleColor = emptyStockpileColor
	if numStockpiled >= 1 then
		circleColor = filledStockpileColor
	end
	
	glDepthTest(true)
	if showLineGlow then
		glLineWidth(10)
		glColor(circleColor[1],circleColor[2],circleColor[3], .015*lineOpacityMultiplier)
		glDrawGroundCircle(x, y, z, coverageRange, 256)
	end
	glColor(circleColor[1],circleColor[2],circleColor[3], .3*lineOpacityMultiplier)
	glLineWidth(3-lineWidthMinus)
	glDrawGroundCircle(x, y, z, coverageRange, 256)
end


function widget:UnitEnteredLos(unitID)
    processVisibleUnit(unitID)
end

function processVisibleUnit(unitID)
    local unitDefId = spGetUnitDefID(unitID);
    if unitDefId == arm_anti or unitDefId == core_anti or unitDefId == arm_mobile_anti or unitDefId == core_mobile_anti or unitDefId == arm_mobile_anti_water or unitDefId == core_mobile_anti_water then
        local x, y, z = spGetUnitPosition(unitID)
        local pos = {}
        pos["x"] = x
        pos["y"] = y
        pos["z"] = z

        if unitDefId == arm_mobile_anti then
            pos.coverageRange = coverageRangeArm
        elseif unitDefId == arm_anti then
            pos.coverageRange = coverageRangeArmStatic
        elseif unitDefId == core_anti then
            pos.coverageRange = coverageRangeCoreStatic
        elseif unitDefId == arm_mobile_anti_water then
            pos.coverageRange = coverageRangeArmWater
        elseif unitDefId == core_mobile_anti then
            pos.coverageRange = coverageRangeCore
        else
            pos.coverageRange = coverageRangeCoreWater
        end

        mobileAntiInLos[unitID] = pos
        mobileAntiOutOfLos[unitID] = nil
    end
end

function widget:UnitLeftLos(unitID)
    local unitDefId = spGetUnitDefID(unitID);
    if unitDefId == arm_anti or unitDefId == core_anti or unitDefId == arm_mobile_anti or unitDefId == core_mobile_anti or unitDefId == arm_mobile_anti_water or unitDefId == core_mobile_anti_water then
        local x, y, z = spGetUnitPosition(unitID)
        local pos = {}
        pos["x"] = x or mobileAntiInLos[unitID].x
        pos["y"] = y or mobileAntiInLos[unitID].y
        pos["z"] = z or mobileAntiInLos[unitID].z

        if unitDefId == arm_mobile_anti then
            pos.coverageRange = coverageRangeArm
        elseif unitDefId == arm_mobile_anti_water then
            pos.coverageRange = coverageRangeArmWater
        elseif unitDefId == core_mobile_anti then
            pos.coverageRange = coverageRangeCore
        else
            pos.coverageRange = coverageRangeCoreWater
        end

        mobileAntiOutOfLos[unitID] = pos
        mobileAntiInLos[unitID] = nil
    end
end

function widget:UnitCreated(unitID, unitDefID, teamID, builderID)
    processVisibleUnit(unitID)
end

function widget:UnitTaken(unitID, unitDefID, unitTeam, newTeam)
    processVisibleUnit(unitID)
end

function widget:UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
    processVisibleUnit(unitID)
end

function widget:GameFrame(n)
    for uID, _ in pairs(mobileAntiInLos) do
        if not Spring.GetUnitDefID(uID) then
            mobileAntiInLos[uID] = nil -- has died
        end
    end
end

function widget:PlayerChanged(playerID)
    local _, _, spec, teamId = Spring.GetPlayerInfo(Spring.GetMyPlayerID())

    for _, unitID in ipairs(spGetTeamUnits(teamId)) do
        processVisibleUnit(unitID)
    end

    return true
end

function widget:Initialize()
    local _, _, spec, teamId = Spring.GetPlayerInfo(Spring.GetMyPlayerID())

    for _, unitID in ipairs(spGetTeamUnits(teamId)) do
        processVisibleUnit(unitID)
    end

    return true
end

--------------------------------------------------------------------------------

function widget:GetConfigData(data)
    savedTable = {}
    savedTable.showLineGlow			= showLineGlow
    savedTable.fadeOnCloseup		= fadeOnCloseup
    return savedTable
end

function widget:SetConfigData(data)
    if data.showLineGlow ~= nil 		then  showLineGlow			= data.showLineGlow end
    if data.fadeOnCloseup ~= nil 		then  fadeOnCloseup			= data.fadeOnCloseup end
end

function widget:TextCommand(command)
    if (string.find(command, "antiranges_glow") == 1  and  string.len(command) == 15) then 
		showLineGlow = not showLineGlow
		if showLineGlow then
			Spring.Echo("Antinuke Ranges:  Glow enabled")
		else
			Spring.Echo("Antinuke Ranges:  Glow disabled")
		end
	end
    if (string.find(command, "antiranges_fade") == 1  and  string.len(command) == 15) then 
		fadeOnCloseup = not fadeOnCloseup
		if fadeOnCloseup then
			Spring.Echo("Antinuke Ranges:  Fade-out on closeup enabled")
		else
			Spring.Echo("Antinuke Ranges:  Fade-out on closeup disabled")
		end
	end
end

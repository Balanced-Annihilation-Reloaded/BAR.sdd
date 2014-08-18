function widget:GetInfo()
   return {
      name      = "Resurrection Halos",
      desc      = "Draws halos on ressurected units",
      author    = "Floris",
      date      = "24.04.2014",
      license   = "GNU GPL, v2 or later",
      layer     = 5,
      enabled   = true
   }
end

--------------------------------------------------------------------------------
-- Console commands
--------------------------------------------------------------------------------

-- /resurrectionhalos_buildings			-- toggles halos for buildings (and non-movable units/factories)
-- /resurrectionhalos_comsonly			-- toggles halos for coms only
-- /resurrectionhalos_dontfade			-- toggles halos to stay visible forever, or to slowly fade away eventually (coms will stay visible forever if defined in config)

--------------------------------------------------------------------------------
-- Config
--------------------------------------------------------------------------------

OPTIONS = {
	haloSize				= 0.5,
	haloDistance			= 4,
	skipBuildings			= true,
	timeoutTime				= 90,
	timeoutFadeTime			= 40,
	dontTimeout				= true,
	dontTimeoutComs			= true,
	onlyForComs				= false,
	sizeVariation			= 0.11,
	sizeSpeed				= 0.7,
	opacityVariation		= 0.09,
	--opacitySpeed			= 0.35,
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local myTeamID                = Spring.GetLocalTeamID()

-- preferred to keep these values the same as fancy unit selections widget
local rectangleFactor		= 3.3
local scalefaktor			= 2.9
local unitConf				= {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local haloUnits = {}
local haloUnitsCount = 0
local glDrawListAtUnit			= gl.DrawListAtUnit
local glDrawFuncAtUnit			= gl.DrawFuncAtUnit

local spIsGUIHidden				= Spring.IsGUIHidden
local spGetSelectedUnitsCount	= Spring.GetSelectedUnitsCount
local spGetSelectedUnits		= Spring.GetSelectedUnits
local spGetUnitDefID			= Spring.GetUnitDefID
local spIsUnitInView 			= Spring.IsUnitInView

local prevGameSecs				= Spring.GetGameSeconds()
	
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function SetUnitConf()
	for udid, unitDef in pairs(UnitDefs) do
		local xsize, zsize = unitDef.xsize, unitDef.zsize
		local scale = scalefaktor*( xsize^2 + zsize^2 )^0.5
		local shape, xscale, zscale
		
		if (unitDef.isBuilding or unitDef.isFactory or unitDef.speed==0) then
			shape = 'square'
			xscale, zscale = rectangleFactor * xsize, rectangleFactor * zsize
		elseif (unitDef.isAirUnit) then
			shape = 'triangle'
			xscale, zscale = scale, scale
		else
			shape = 'circle'
			xscale, zscale = scale, scale
		end
		unitConf[udid] = {shape=shape, xscale=xscale, zscale=zscale}
	end
end


function DrawIcon(posY, posX, haloSize)
	gl.Translate(0,posY,-(haloSize/2))
	gl.Rotate(90,1,0,0)
	gl.TexRect(-(haloSize/2), 0, (haloSize/2), haloSize)
end


-- add unit-icon to unit
function AddHaloUnit(unitID)
	local unitUnitDefs = UnitDefs[spGetUnitDefID(unitID)]
	if not OPTIONS.skipBuildings or (OPTIONS.skipBuildings and not (unitUnitDefs.isBuilding or unitUnitDefs.isFactory or unitUnitDefs.speed==0)) then
		if not OPTIONS.onlyForComs or (OPTIONS.onlyForComs and (unitUnitDefs.name == 'corcom' or unitUnitDefs.name == 'armcom')) then
			local ud = UnitDefs[spGetUnitDefID(unitID)]
			
			haloUnits[unitID] = {}
			haloUnits[unitID].unitHeight		= ud.height
			haloUnits[unitID].endSecs			= Spring.GetGameSeconds() + OPTIONS.timeoutTime
			haloUnits[unitID].sizeAddition		= 0
			haloUnits[unitID].sizeUp			= true
			haloUnits[unitID].opacityAddition	= 0
			haloUnits[unitID].opacityUp			= true
			haloUnits[unitID].name				= unitUnitDefs.name
			
			haloUnitsCount = haloUnitsCount + 1
		end
	end
end

--------------------------------------------------------------------------------
-- Engine Calls
--------------------------------------------------------------------------------

function widget:Initialize()
	
	SetUnitConf()
end


-- draw halos
function widget:DrawWorld()
	if spIsGUIHidden() then return end
	local gameSecs = Spring.GetGameSeconds()
	local diffGameSecs = gameSecs - prevGameSecs
	prevGameSecs = gameSecs
	
	if haloUnitsCount > 0 then
		gl.DepthMask(true)
		gl.DepthTest(true)
		gl.Texture('LuaUI/Images/halo.png')
		for unitID, unit in pairs(haloUnits) do
			if spIsUnitInView(unitID) then
				
				-- calc addition size
				if OPTIONS.sizeVariation > 0 then
					if unit.sizeUp and unit.sizeAddition >= OPTIONS.sizeVariation / 2 then
						unit.sizeUp = false
					end
					if not unit.sizeUp and unit.sizeAddition <= -(OPTIONS.sizeVariation / 2) then
						unit.sizeUp = true
					end
					if unit.sizeUp then
						unit.sizeAddition = unit.sizeAddition + ((OPTIONS.sizeVariation / 2) * (diffGameSecs / OPTIONS.sizeSpeed))
						if unit.sizeAddition > (OPTIONS.sizeVariation / 2) then
							unit.sizeAddition = (OPTIONS.sizeVariation / 2)
						end
					else
						unit.sizeAddition = unit.sizeAddition - ((OPTIONS.sizeVariation / 2) * (diffGameSecs / OPTIONS.sizeSpeed))
						if unit.sizeAddition < -(OPTIONS.sizeVariation / 2) then
							unit.sizeAddition = -(OPTIONS.sizeVariation / 2)
						end
					end
				end
				local alpha = 1
				if not OPTIONS.dontTimeout and (not OPTIONS.dontTimeoutComs or (OPTIONS.dontTimeoutComs and unit.name ~= 'corcom' and unit.name ~= 'armcom')) then
					alpha = ((((unit.endSecs+OPTIONS.timeoutFadeTime) - gameSecs) / OPTIONS.timeoutTime))
				end
				if alpha > 1 then alpha = 1 end
				if OPTIONS.opacityVariation > 0 then alpha = alpha - (OPTIONS.opacityVariation/2) end
				local alpha1 = alpha
				alpha = alpha + (alpha * (unit.sizeAddition))
				if alpha1 <= 0 then 
					haloUnits[unitID] = nil
					haloUnitsCount = haloUnitsCount - 1
				else
					gl.Color(1,1,1,alpha)
					local unitDefs = unitConf[spGetUnitDefID(unitID)]
					local unitScale = unitDefs.xscale
					if alpha < 1 then 
						alpha = 1
					end
					local iconsize = (unitScale * OPTIONS.haloSize) + ((unitScale * OPTIONS.haloSize) * unit.sizeAddition)
					glDrawFuncAtUnit(unitID, false, DrawIcon, unit.unitHeight+(unitScale/2), 0, iconsize)
				end
			end
		end
		gl.Color(1,1,1,1)
		gl.Texture(false)
		gl.DepthTest(false)
		gl.DepthMask(false)
	end
end

						

-- detect resurrected units here
function widget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
	if builderID  and  UnitDefs[spGetUnitDefID(builderID)].canResurrect then
		AddHaloUnit(unitID)
	end
end


-- for testing: draw halos on selected units
--[[
function widget:CommandsChanged()
	
	if spGetSelectedUnitsCount() > 0 then
		local units = Spring.GetSelectedUnitsSorted()
		for uDID,_ in pairs(units) do
			if uDID ~= 'n' then --'n' returns table size
				for i=1,#units[uDID] do
					local unitID = units[uDID][i]
					if not haloUnits[unitID] then
						AddHaloUnit(unitID)
					end
				end
			end
		end
	end
end
]]--

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetConfigData(data)
    savedTable = {}
    savedTable.skipBuildings	= OPTIONS.skipBuildings
    savedTable.onlyForComs		= OPTIONS.onlyForComs
    savedTable.dontTimeout		= OPTIONS.dontTimeout
    return savedTable
end

function widget:SetConfigData(data)
    if data.skipBuildings ~= nil 	then  OPTIONS.skipBuildings	= data.skipBuildings end
    if data.onlyForComs ~= nil	 	then  OPTIONS.onlyForComs	= data.onlyForComs end
    if data.dontTimeout ~= nil	 	then  OPTIONS.dontTimeout	= data.dontTimeout end
end

function widget:TextCommand(command)
    if (string.find(command, "resurrectionhalos_buildings") == 1  and  string.len(command) == 27) then 
		OPTIONS.skipBuildings = not OPTIONS.skipBuildings
	end
    if (string.find(command, "resurrectionhalos_comsonly") == 1  and  string.len(command) == 26) then 
		OPTIONS.onlyForComs = not OPTIONS.onlyForComs
	end
    if (string.find(command, "resurrectionhalos_dontfade") == 1  and  string.len(command) == 26) then 
		OPTIONS.dontTimeout = not OPTIONS.dontTimeout
	end
end

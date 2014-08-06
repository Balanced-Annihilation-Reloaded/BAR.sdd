function widget:GetInfo()
   return {
      name      = "Self-D Icons",
      desc      = "",
      author    = "Floris",
      date      = "06.05.2014",
      license   = "GNU GPL, v2 or later",
      layer     = 5,
      enabled   = true
   }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local myTeamID                = Spring.GetLocalTeamID()

-- preferred to keep these values the same as fancy unit selections widget
local rectangleFactor		= 3.3
local scalefaktor			= 2.9
local unitConf				= {}
local skipSelectedUnits		= true

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local selfdUnits = {}
local glDrawFuncAtUnit			= gl.DrawFuncAtUnit

local spIsGUIHidden				= Spring.IsGUIHidden
local spGetUnitDefID			= Spring.GetUnitDefID
local spIsUnitInView 			= Spring.IsUnitInView
local spIsUnitSelected			= Spring.IsUnitSelected

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


function DrawIcon(posY, posX, iconSize, text)
	gl.Texture('LuaUI/Images/skull.png')
	gl.Color(0.9,0.9,0.9,1)
	gl.Translate(posX*0.9,posY,posX*1.5)
	gl.Billboard()
	gl.TexRect(-(iconSize/2), 0, (iconSize/2), iconSize)
	gl.Text(text, -16, 1, 12, 'c')
end


-- add unit-icon to unit
function AddSelfDUnit(unitID)
	local ud = UnitDefs[spGetUnitDefID(unitID)]
	
	givenUnits[unitID] = {}
	givenUnits[unitID].osClock			= os.clock()
	givenUnits[unitID].lastInViewClock	= os.clock()
	givenUnits[unitID].unitHeight		= ud.height
end

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

--------------------------------------------------------------------------------
-- Engine Calls
--------------------------------------------------------------------------------

function widget:Initialize()
	SetUnitConf()
end


-- draw icons
function widget:DrawWorld()
	if spIsGUIHidden() then return end
	local gameSecs = Spring.GetGameSeconds()
	
	gl.DepthMask(true)
	gl.DepthTest(true)
	
	for unitID, unitEndSecs in pairs(selfdUnits) do
		if spIsUnitInView(unitID) then
			if (skipSelectedUnits == false or (skipSelectedUnits and spIsUnitSelected(unitID) == false)) then
				local unitDefs = unitConf[spGetUnitDefID(unitID)]
				local unitScale = unitDefs.xscale*1.22 - (unitDefs.xscale/6.6)
				glDrawFuncAtUnit(unitID, false, DrawIcon, 10.1, unitScale, 18, math.floor((unitEndSecs - gameSecs)+1))
			end
		end
	end
	
	gl.Color(1,1,1,1)
	gl.Texture(false)
	gl.DepthTest(false)
	gl.DepthMask(false)
end


function widget:UnitCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)

	if cmdID == CMD.SELFD then
		if selfdUnits[unitID] then  
			selfdUnits[unitID] = nil
		else
			selfdUnits[unitID] = Spring.GetGameSeconds() + UnitDefs[spGetUnitDefID(unitID)].selfDCountdown
		end
	end
end


function widget:UnitDestroyed(unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam)
	
	if selfdUnits[unitID] then  
		selfdUnits[unitID] = nil
	end
end

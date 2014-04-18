--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    gui_enemy_spotter.lua
--  brief:   Draws transparant smoothed donuts under enemy units
--  author:  Dave Rodgers (orig. TeamPlatter edited by TradeMark)
--
--  Copyright (C) 2007.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
   return {
      name      = "EnemySpotter",
      desc      = "Draws transparant smoothed donuts under enemy units (with teamcolors or predefined colors, depending on situation)",
      author    = "TradeMark  (Floris: added multiple ally color support)",
      date      = "17.03.2013",
      license   = "GNU GPL, v2 or later",
      layer     = 5,
      enabled   = false  --  loaded by default?
   }
end



--------------------------------------------------------------------------------
-- Config
--------------------------------------------------------------------------------

local drawWithHiddenGUI                 = true    -- keep widget enabled when graphical user interface is hidden (when pressing F5)
local skipOwnAllyTeam                   = true    -- keep this 'true' if you dont want circles rendered under your own units

local circleSize                        = 1
local circleDivs                        = 12      -- how precise circle?
local circleOpacity                     = 0.18
local innerSize                         = 1.35    -- circle scale compared to unit radius
local outerSize                         = 1.30    -- outer fade size compared to circle scale (1 = no outer fade)
                                        
local defaultColorsForAllyTeams         = 0       -- (number of teams)   if number <= of total numebr of allyTeams then dont use teamcoloring but default colors
local keepTeamColorsForSmallAllyTeam    = 3       -- (number of teams)   use teamcolors if number or teams (inside allyTeam)  <=  this value
local spotterColor = {                            -- default color values
   {0,0,1} , {1,0,1} , {0,1,1} , {0,1,0} , {1,0.5,0} , {0,1,1} , {1,1,0} , {1,1,1} , {0.5,0.5,0.5} , {0,0,0} , {0.5,0,0} , {0,0.5,0} , {0,0,0.5} , {0.5,0.5,0} , {0.5,0,0.5} , {0,0.5,0.5} , {1,0.5,0.5} , {0.5,0.5,0.1} , {0.5,0.1,0.5},
}
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local glDrawListAtUnit        = gl.DrawListAtUnit

local spGetTeamColor          = Spring.GetTeamColor
local spGetUnitDefDimensions  = Spring.GetUnitDefDimensions
local spGetUnitDefID          = Spring.GetUnitDefID
local spIsUnitSelected        = Spring.IsUnitSelected
local spGetAllyTeamList       = Spring.GetAllyTeamList 
local spGetTeamList           = Spring.GetTeamList
local spGetVisibleUnits       = Spring.GetVisibleUnits
local spIsGUIHidden           = Spring.IsGUIHidden
local spGetUnitAllyTeam       = Spring.GetUnitAllyTeam
                              
local myTeamID                = Spring.GetLocalTeamID()
local myAllyID                = Spring.GetMyAllyTeamID()

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local realRadii               = {}
local circlePolys             = {}
local allyToSpotterColor      = {}
local unitConf                = {}
local allyToSpotterColorCount = 0
local pickTeamColor           = false

-- preferred to keep these values the same as fancy unit selections widget
local rectangleFactor		= 3.3
local scalefaktor			= 2.9

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


-- Creating polygons:
function widget:Initialize()

	setUnitConf()
	
   local allyTeamList = spGetAllyTeamList()
   local numberOfAllyTeams = #allyTeamList
   for allyTeamListIndex = 1, numberOfAllyTeams do
      local allyID                = allyTeamList[allyTeamListIndex]
      if not skipOwnAllyTeam  or  (skipOwnAllyTeam  and  not (allyID == myAllyID))  then
         allyToSpotterColorCount     = allyToSpotterColorCount+1
         allyToSpotterColor[allyID]  = allyToSpotterColorCount
         local usedSpotterColor      = spotterColor[allyToSpotterColorCount]
         if defaultColorsForAllyTeams < numberOfAllyTeams-1 then
            local teamList              = spGetTeamList(allyID)
            for teamListIndex = 1, #teamList do
               local teamID = teamList[teamListIndex]
               if (teamListIndex == 1  and  #teamList <= keepTeamColorsForSmallAllyTeam) then     -- only check for the first allyTeam  (to be consistent with picking a teamcolor or default color, inconsistency could happen with different teamsizes)
                  pickTeamColor = true
               end
               if pickTeamColor then
                  -- pick the first team in the allyTeam and take the color from that one
                  if (teamListIndex == 1) then
                     local r,g,b,a       = spGetTeamColor(teamID)
                     usedSpotterColor[1] = r
                     usedSpotterColor[2] = g
                     usedSpotterColor[3] = b
                  end
               end
            end
         end
         
         
         circlePolys[allyID] = gl.CreateList(function()
         
            gl.Blending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)      -- disable layer blending
            
            -- colored inner circle:
            gl.BeginEnd(GL.TRIANGLES, function()
               local radstep = (2.0 * math.pi) / circleDivs
               for i = 1, circleDivs do
                  local a1 = (i * radstep)
                  local a2 = ((i+1) * radstep)
                  --(fadefrom)
                  gl.Color(usedSpotterColor[1], usedSpotterColor[2], usedSpotterColor[3], 0)
                  gl.Vertex(0, 0, 0)
                  --(colorSet)
                  gl.Color(usedSpotterColor[1], usedSpotterColor[2], usedSpotterColor[3], circleOpacity)
                  gl.Vertex(math.sin(a1), 0, math.cos(a1))
                  gl.Vertex(math.sin(a2), 0, math.cos(a2))
               end
            end)
            
            if (outerSize ~= 1) then
               -- colored outer circle:
               gl.BeginEnd(GL.QUADS, function()
                  local radstep = (2.0 * math.pi) / circleDivs
                  for i = 1, circleDivs do
                     local a1 = (i * radstep)
                     local a2 = ((i+1) * radstep)
                     --(colorSet)
                     gl.Color(usedSpotterColor[1], usedSpotterColor[2], usedSpotterColor[3], circleOpacity)
                     gl.Vertex(math.sin(a1), 0, math.cos(a1))
                     gl.Vertex(math.sin(a2), 0, math.cos(a2))
                     --(fadeto)
                     gl.Color(usedSpotterColor[1], usedSpotterColor[2], usedSpotterColor[3], 0)
                     gl.Vertex(math.sin(a2)*outerSize, 0, math.cos(a2)*outerSize)
                     gl.Vertex(math.sin(a1)*outerSize, 0, math.cos(a1)*outerSize)
                  end
               end)
            end
         end)
      end
   end
end


function widget:Shutdown()
	local allyTeamList = spGetAllyTeamList()
	for i=1, #allyTeamList do
		local allyID = allyTeamList[i]
		if circlePolys[allyID] then
			gl.DeleteList(circlePolys[allyID])
		end
	end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function setUnitConf()
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
--------------------------------------------------------------------------------


-- Drawing:
function widget:DrawWorldPreUnit()
   if not drawWithHiddenGUI then
      if spIsGUIHidden() then return end
   end
   gl.DepthTest(true)
   gl.PolygonOffset(-100, -2)
   local visibleUnits = spGetVisibleUnits()
   if #visibleUnits then
      for i=1, #visibleUnits do
         local unitID = visibleUnits[i]
         local allyID = spGetUnitAllyTeam(unitID)
         if circlePolys[allyID] ~= nil then
            if not skipOwnAllyTeam  or  (skipOwnAllyTeam  and  not (allyID == myAllyID))  then
               local unitDefIDValue = spGetUnitDefID(unitID)
               if (unitDefIDValue) then
                  
					local unit = unitConf[unitDefIDValue]
					glDrawListAtUnit(unitID, circlePolys[allyID], false, unit.xscale*2, 1.0, unit.zscale*2)
					
               end
            end
         end
      end
   end
end
             

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

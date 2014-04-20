function widget:GetInfo()
   return {
      name      = "EnemySpotter",
      desc      = "Draws transparant smoothed donuts under enemy units (with teamcolors or predefined colors, depending on situation)",
      author    = "Floris (original enemyspotter by TradeMark, who edited 'TeamPlatter' by Dave Rodgers)",
      date      = "20.04.2014",
      license   = "GNU GPL, v2 or later",
      layer     = 5,
      enabled   = true
   }
end

--------------------------------------------------------------------------------
-- Console commands
--------------------------------------------------------------------------------

-- /enemyspotter_self
-- /enemyspotter_all
-- /+enemyspotter_opacity
-- /-enemyspotter_opacity

--------------------------------------------------------------------------------
-- Config
--------------------------------------------------------------------------------

local drawWithHiddenGUI                 = true		-- keep widget enabled when graphical user interface is hidden (when pressing F5)
local useVariableSpotterDetail          = true		-- use variable number of parts the spotter circle consists of
local renderAllTeamsAsSpec				= true		-- renders for all teams when spectator
local renderAllTeamsAsPlayer			= false		-- keep this 'false' if you dont want circles rendered under your own units as player

local circleParts						= 12      	-- number of parts for a cirlce, when not using useVariableSpotterDetail
local circlePartsMin					= 9      	-- minimal number of parts for a cirlce, when zoomed out
local circlePartsMax					= 18      	-- maximum number of parts for a cirlce, when zoomed in

local spotterOpacity					= 0.25
local innerSize							= 1.30		-- circle scale compared to unit radius
local outerSize							= 1.30		-- outer fade size compared to circle scale (1 = not rendered)
                                        
local defaultColorsForAllyTeams			= 0 		-- (number of teams)   if number <= of total numebr of allyTeams then dont use teamcoloring but default colors
local keepTeamColorsForSmallAllyTeam	= 3			-- (number of teams)   use teamcolors if number or teams (inside allyTeam)  <=  this value
local spotterColor = {								-- default color values
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
local spGetCameraPosition	  = Spring.GetCameraPosition
local spGetUnitPosition       = Spring.GetUnitPosition
          
local myTeamID                = Spring.GetLocalTeamID()
local myAllyID                = Spring.GetMyAllyTeamID()
local gaiaTeamID			  = Spring.GetGaiaTeamID()

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local circlePolys             = {}
local allyToSpotterColor      = {}
local unitConf                = {}
local skipOwnAllyTeam         = true

-- preferred to keep these values the same as fancy unit selections widget
local rectangleFactor		= 3.3
local scalefaktor			= 2.9

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


function Round(num, idp)
    local mult = 10^(idp or 0)
    return math.floor(num * mult + 0.5) / mult
end


function CreateSpotterList(r,g,b,a, parts)
	if spotterOpacity < 0.08 then spotterOpacity = 0.08
	elseif spotterOpacity > 0.5 then spotterOpacity = 0.5 end

	return gl.CreateList(function()

		gl.Blending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)      -- disable layer blending

		-- colored inner circle:
		gl.BeginEnd(GL.TRIANGLE_FAN, function()
			gl.Color(r, g, b, 0)
			gl.Vertex(0, 0, 0)
			local radstep = (2.0 * math.pi) / parts
			for i = 1, parts do
				local a1 = (i * radstep)
				local a2 = ((i+1) * radstep)
				
				gl.Color(r, g, b, a)
				gl.Vertex(math.sin(a1), 0, math.cos(a1))
				gl.Vertex(math.sin(a2), 0, math.cos(a2))
			end
		end)

		if (outerSize ~= 1) then
			-- colored outer circle:
			gl.BeginEnd(GL.QUADS, function()
				local radstep = (2.0 * math.pi) / parts
				for i = 1, parts do
					local a1 = (i * radstep)
					local a2 = ((i+1) * radstep)
					
					gl.Color(r, g, b, a)
					gl.Vertex(math.sin(a1), 0, math.cos(a1))
					gl.Vertex(math.sin(a2), 0, math.cos(a2))
					
					gl.Color(r, g, b, 0)
					gl.Vertex(math.sin(a2)*outerSize, 0, math.cos(a2)*outerSize)
					gl.Vertex(math.sin(a1)*outerSize, 0, math.cos(a1)*outerSize)
				end
			end)
		end
	end)
end


function DeleteSpotterLists()
	for allyID, lists in pairs(circlePolys) do
		for parts in pairs(lists) do
			gl.DeleteList(circlePolys[allyID][parts])
		end
		circlePolys[allyID] = nil
	end
end


function CreateSpotterLists()

	DeleteSpotterLists()

    if Spring.GetSpectatingState()  and  renderAllTeamsAsSpec then
        skipOwnAllyTeam = false
    elseif not Spring.GetSpectatingState() and renderAllTeamsAsPlayer then
        skipOwnAllyTeam = false
    end
    
	local allyToSpotterColorCount = 0
	local allyTeamList = spGetAllyTeamList()
	local numberOfAllyTeams = #allyTeamList
	for allyTeamListIndex = 1, numberOfAllyTeams do
		local allyID = allyTeamList[allyTeamListIndex]
		
		if not skipOwnAllyTeam  or  (skipOwnAllyTeam  and  not (allyID == myAllyID))  then
		
			allyToSpotterColorCount     = allyToSpotterColorCount+1
			allyToSpotterColor[allyID]  = allyToSpotterColorCount
			local usedSpotterColor      = spotterColor[allyToSpotterColorCount]
			if defaultColorsForAllyTeams < numberOfAllyTeams-1 then
				local teamList = Spring.GetTeamList(allyID)
				for teamListIndex = 1, #teamList do
					local teamID = teamList[teamListIndex]
					if teamID ~= gaiaTeamID then
						local pickTeamColor = false
						if (teamListIndex == 1  and  #teamList <= keepTeamColorsForSmallAllyTeam) then     -- only check for the first allyTeam, (to be consistent with picking a teamcolor or default color, inconsistency could happen with different teamsizes)
							pickTeamColor = true
						end
						if pickTeamColor then
						-- pick the first team in the allyTeam and take the color from that one
							if (teamListIndex == 1) then
								usedSpotterColor[1],usedSpotterColor[2],usedSpotterColor[3],_       = Spring.GetTeamColor(teamID)
							end
						end
					end
				end
			end
			teamList = Spring.GetTeamList(allyID)
			for teamListIndex = 1, #teamList do
				teamID = teamList[teamListIndex]
				if teamID ~= gaiaTeamID then
					 circlePolys[allyID] = {}
					for i=circlePartsMin, circlePartsMax do
						circlePolys[allyID][i] = CreateSpotterList(usedSpotterColor[1],usedSpotterColor[2],usedSpotterColor[3],spotterOpacity, i)
					end
				end
			end
		end
	end
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
	CreateSpotterLists()
end


function widget:Shutdown()
	
	DeleteSpotterLists()
end


function widget:DrawWorldPreUnit()
	if not drawWithHiddenGUI then
		if spIsGUIHidden() then return end
	end
	--local totalVariableParts,totalFixedParts = 0,0
	
	local camX, camY, camZ = spGetCameraPosition()
	local unitZ = false
	local parts = circleParts
	
	--gl.DepthTest(true)
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
						local unitScale = unit.xscale*2
						
						if not useVariableSpotterDetail then
							parts = circleParts
						else
							-- only process camera distance calculation for the first unit, to improve performance. It doesnt seem to hurt acuracy much.
							if not unitZ then
								local unitX,unitY,unitZ = spGetUnitPosition(unitID, true)
								local xDifference = camX - unitX
								local yDifference = camY - unitY
								local zDifference = camZ - unitZ
								local camDistance = math.sqrt(xDifference*xDifference + yDifference*yDifference + zDifference*zDifference)
								
								parts = Round(circlePartsMax - (camDistance / 800))
								
								if parts < circlePartsMin then
									parts = circlePartsMin
								elseif parts > circlePartsMax then
									parts = circlePartsMax
								end
								--totalFixedParts = totalFixedParts + circleParts
								--totalVariableParts = totalVariableParts + parts
							end
						end
						
						glDrawListAtUnit(unitID, circlePolys[allyID][parts], false, unitScale, 1.0, unitScale)
						
					end
				end
			end
		end
	end
	--Spring.Echo('Variable Parts:  '..totalVariableParts..'      Fixed Parts per unit:  '..totalFixedParts)
end


function widget:PlayerChanged()
    if Spring.GetSpectatingState()  and  renderAllTeamsAsSpec then
        skipOwnAllyTeam = false
        CreateSpotterLists()
    elseif not Spring.GetSpectatingState() and renderAllTeamsAsPlayer then
        skipOwnAllyTeam = false
        CreateSpotterLists()
    end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetConfigData(data)
    savedTable = {}
    savedTable.renderAllTeamsAsSpec		= renderAllTeamsAsSpec
    savedTable.renderAllTeamsAsPlayer	= renderAllTeamsAsPlayer
    savedTable.spotterOpacity			= spotterOpacity
    return savedTable
end

function widget:SetConfigData(data)
    if data.renderAllTeamsAsSpec ~= nil     then  renderAllTeamsAsSpec   = data.renderAllTeamsAsSpec end
    if data.renderAllTeamsAsPlayer ~= nil   then  renderAllTeamsAsPlayer   = data.renderAllTeamsAsPlayer end
    spotterOpacity        = data.spotterOpacity       or spotterOpacity
end

function widget:TextCommand(command)
    if (string.find(command, "enemyspotter_self") == 1  and  string.len(command) == 17) then 
		renderAllTeamsAsPlayer = not renderAllTeamsAsPlayer
		if not Spring.GetSpectatingState() then 
			skipOwnAllyTeam = not renderAllTeamsAsPlayer
			CreateSpotterLists()
		end
	end

    if (string.find(command, "enemyspotter_all") == 1  and  string.len(command) == 16) then 
		renderAllTeamsAsSpec = not renderAllTeamsAsSpec
		if Spring.GetSpectatingState() then 
			skipOwnAllyTeam = not renderAllTeamsAsSpec
			CreateSpotterLists()
		end
	end

    --if (string.find(command, "enemyspotter_self") == 1  and  string.len(command) == 17) then renderAllTeamsAsPlayer = not renderAllTeamsAsPlayer ; CreateSpotterLists() end

    --if (string.find(command, "enemyspotter_all") == 1  and  string.len(command) == 16) then renderAllTeamsAsSpec = not renderAllTeamsAsSpec ; CreateSpotterLists() end

    if (string.find(command, "+enemyspotter_opacity") == 1) then spotterOpacity = spotterOpacity + 0.02 ; callfunction = CreateSpotterLists() end
    if (string.find(command, "-enemyspotter_opacity") == 1) then spotterOpacity = spotterOpacity - 0.02 ; callfunction = CreateSpotterLists() end
end

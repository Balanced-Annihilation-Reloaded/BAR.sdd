function widget:GetInfo()
    return {
        name      = "Comblast & Dgun Range",
        desc      = "Shows the range of commander death explosion and dgun ranges",
        author    = "Bluestone, based on similar widgets by vbs, tfc, decay",
        date      = "11/2013",
        license   = "GPL v3 or later",
        layer     = 0,
        enabled   = false  -- loaded by default
    }
end

--------------------------------------------------------------------------------
-- Console commands
--------------------------------------------------------------------------------

--/comranges_glow			-- toggles a faint glow on the line

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local pairs					= pairs

local spGetUnitPosition     = Spring.GetUnitPosition
local spGetUnitDefID 		= Spring.GetUnitDefID
local spGetAllUnits			= Spring.GetAllUnits
local spGetSpectatingState 	= Spring.GetSpectatingState
local spGetMyPlayerID		= Spring.GetMyPlayerID
local spGetPlayerInfo		= Spring.GetPlayerInfo
local spGetGroundHeight		= Spring.GetGroundHeight
local spIsSphereInView		= Spring.IsSphereInView
local spValidUnitID			= Spring.ValidUnitID
local spGetCameraPosition	= Spring.GetCameraPosition
local glDepthTest 			= gl.DepthTest
local glDrawGroundCircle 	= gl.DrawGroundCircle
local glLineWidth 			= gl.LineWidth
local glColor				= gl.Color
local glTranslate			= gl.Translate
local glRotate				= gl.Rotate
local glText				= gl.Text
local GL_ALWAYS				= GL.ALWAYS

local comCenters = {}
local drawList
local amSpec = false
local inSpecFullView = false

--------------------------------------------------------------------------------
-- OPTIONS
--------------------------------------------------------------------------------

local circleDivs			= 64		-- circle detail, when fading out it will lower this aswell (so dont go too low)
local blastRadius			= 360		-- com explosion
local dgunRange				= WeaponDefNames["armcom_arm_disintegrator"].range + 2*WeaponDefNames["armcom_arm_disintegrator"].damageAreaOfEffect
local showTitles			= true		-- shows title text around the circle-line
local showTitleDistance		= 750
local showLineGlow 			= true		-- a ticker but faint 2nd line will be drawn underneath		
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------



-- track coms --

function widget:Initialize()
    checkComs()
	checkSpecView()
    return true
end

function addCom(unitID)
	if not spValidUnitID(unitID) then return end --because units can be created AND destroyed on the same frame, in which case luaui thinks they are destroyed before they are created
	local x,y,z = Spring.GetUnitPosition(unitID)
	comCenters[unitID] = {x,y,z}
end

function removeCom(unitID)
	comCenters[unitID] = nil
end

function widget:UnitFinished(unitID, unitDefID, unitTeam)
    if UnitDefs[unitDefID].customParams.iscommander == "1" then
        addCom(unitID)
    end
end

function widget:UnitCreated(unitID, unitDefID, teamID, builderID)
    if UnitDefs[unitDefID].customParams.iscommander == "1" then
        addCom(unitID)
    end
end

function widget:UnitTaken(unitID, unitDefID, unitTeam, newTeam)
    if UnitDefs[unitDefID].customParams.iscommander == "1" then
        addCom(unitID)
    end
end


function widget:UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
    if UnitDefs[unitDefID].customParams.iscommander == "1" then
        addCom(unitID)
    end
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
    if comCenters[unitID] then
        removeCom(unitID)
    end
end

function widget:UnitEnteredLos(unitID, unitTeam)
    if not amSpec then
        local unitDefID = spGetUnitDefID(unitID)
        if UnitDefs[unitDefID].customParams.iscommander == "1" then
            addCom(unitID)
        end
    end
end

function widget:UnitLeftLos(unitID, unitDefID, unitTeam)
    if not amSpec then
        if comCenters[unitID] then
            removeCom(unitID)
        end
    end
end

function widget:PlayerChanged(playerID)
    checkSpecView()
    return true
end

function widget:GameOver()
	widgetHandler:RemoveWidget()
end

function checkSpecView()
	--check if we became a spec
    local _,_,spec,_ = spGetPlayerInfo(spGetMyPlayerID())
    if spec ~= amSpec then
        amSpec = spec 
		checkComs()
    end
end

function checkComs()
	--remake list of coms
	for k,_ in pairs(comCenters) do
		comCenters[k] = nil
	end
	
    local visibleUnits = spGetAllUnits()
    if visibleUnits ~= nil then
        for _, unitID in ipairs(visibleUnits) do
            local unitDefID = spGetUnitDefID(unitID)
            if unitDefID and UnitDefs[unitDefID].customParams.iscommander == "1" then
                addCom(unitID)
            end
        end
    end
end


-- draw -- 
 
-- map out what to draw
function widget:GameFrame(n)
	-- check if we are in spec full view
	local _, specFullView, _ = spGetSpectatingState()
    if specFullView ~= inSpecFullView then
		checkComs()
		inSpecFullView = specFullView
    end

	-- check com movement
	for unitID in pairs(comCenters) do
		local x,y,z = spGetUnitPosition(unitID)
		if x then
			local yg = spGetGroundHeight(x,z) 
			local draw = true
			-- check if com is off the ground
			if y-yg>10 then 
				draw = false
			-- check if is in view
			elseif not spIsSphereInView(x,y,z,blastRadius) then
				draw = false
			end
			comCenters[unitID] = {x,y,z,draw}
		else
			--couldn't get position, check if its still a unit 
			if not spValidUnitID(unitID) then
				removeCom(unitID)
			end
		end
	end	
end

-- draw circles
function widget:DrawWorldPreUnit()
	local camX, camY, camZ = spGetCameraPosition()
	glDepthTest(GL_ALWAYS)
	for _,center in pairs(comCenters) do
		if center[4] then
		
			local xDifference = camX - center[1]
			local yDifference = camY - center[2]
			local zDifference = camZ - center[3]
			local camDistance = math.sqrt(xDifference*xDifference + yDifference*yDifference + zDifference*zDifference)
			
			local lineWidthMinus = (camDistance/2000)
			if lineWidthMinus > 2 then
				lineWidthMinus = 2
			end
			local lineOpacityMultiplier = (1200/camDistance)
			if lineOpacityMultiplier > 1 then
				lineOpacityMultiplier = 1
			end
			if lineOpacityMultiplier > 0.18 then
				if showTitles and camDistance < showTitleDistance then
					-- DGUN titles
					local lineDistance	= 5
					local fontSize		= 10
					local radius		= dgunRange
					local text = "DGUN"
					
					glColor(1, 0.8, 0, .3*lineOpacityMultiplier)
					glTranslate(center[1], 0, center[3])
					
					local mapHeight = spGetGroundHeight(center[1],center[3]-radius)
					glTranslate(0,mapHeight,-radius)
					glRotate(90,-1,0,0)
					glText(text, 0, lineDistance, fontSize, "cn")
					glRotate(90,1,0,0)
					glTranslate(0,-mapHeight,radius)
					
					mapHeight = spGetGroundHeight(center[1],center[3]+radius)
					glTranslate(0,mapHeight,radius)
					glRotate(90,-1,0,0)
					glRotate(180,0,0,1)
					glText(text, 0, lineDistance, fontSize, "cn")
					glRotate(180,0,0,-1)
					glRotate(90,1,0,0)
					glTranslate(0,-mapHeight,-radius)
					
					mapHeight = spGetGroundHeight(center[1]-radius,center[3])
					glTranslate(-radius,mapHeight,0)
					glRotate(90,-1,0,0)
					glRotate(90,0,0,1)
					glText(text, 0, lineDistance, fontSize, "cn")
					glRotate(90,0,0,-1)
					glRotate(90,1,0,0)
					glTranslate(radius,-mapHeight,0)
					
					mapHeight = spGetGroundHeight(center[1]+radius,center[3])
					glTranslate(radius,mapHeight,0)
					glRotate(90,-1,0,0)
					glRotate(270,0,0,1)
					glText(text, 0, lineDistance, fontSize, "cn")
					glRotate(270,0,0,-1)
					glRotate(90,1,0,0)
					glTranslate(-radius,-mapHeight,0)
					
					glTranslate(-center[1], 0, -center[3])
					
					
					-- Com explosion range titles
					lineDistance	= 5
					fontSize		= 10
					radius			= blastRadius
					text			= "BLAST"
					
					glColor(1, 0, 0, .37*lineOpacityMultiplier)
					glTranslate(center[1], 0, center[3])
					
					local mapHeight = spGetGroundHeight(center[1],center[3]-radius)
					glTranslate(0,mapHeight,-radius)
					glRotate(90,-1,0,0)
					glText(text, 0, lineDistance, fontSize, "cn")
					glRotate(90,1,0,0)
					glTranslate(0,-mapHeight,radius)
					
					mapHeight = spGetGroundHeight(center[1],center[3]+radius)
					glTranslate(0,mapHeight,radius)
					glRotate(90,-1,0,0)
					glRotate(180,0,0,1)
					glText(text, 0, lineDistance, fontSize, "cn")
					glRotate(180,0,0,-1)
					glRotate(90,1,0,0)
					glTranslate(0,-mapHeight,-radius)
					
					mapHeight = spGetGroundHeight(center[1]-radius,center[3])
					glTranslate(-radius,mapHeight,0)
					glRotate(90,-1,0,0)
					glRotate(90,0,0,1)
					glText(text, 0, lineDistance, fontSize, "cn")
					glRotate(90,0,0,-1)
					glRotate(90,1,0,0)
					glTranslate(radius,-mapHeight,0)
					
					mapHeight = spGetGroundHeight(center[1]+radius,center[3])
					glTranslate(radius,mapHeight,0)
					glRotate(90,-1,0,0)
					glRotate(270,0,0,1)
					glText(text, 0, lineDistance, fontSize, "cn")
					glRotate(270,0,0,-1)
					glRotate(90,1,0,0)
					glTranslate(-radius,-mapHeight,0)
					
					glTranslate(-center[1], 0, -center[3])
				end
				
				-- draw lines
				if showLineGlow then
					glLineWidth(10-lineWidthMinus)
					glColor(1, 0.8, 0, .04*lineOpacityMultiplier)
					glDrawGroundCircle(center[1], center[2], center[3], dgunRange, circleDivs*lineOpacityMultiplier)
					
					glLineWidth(10-lineWidthMinus)
					glColor(1, 0, 0, .055*lineOpacityMultiplier)
					glDrawGroundCircle(center[1], center[2], center[3], blastRadius, (circleDivs*1.2)*lineOpacityMultiplier)
				end
				glLineWidth(3-lineWidthMinus)
				glColor(1, 0.8, 0, .36*lineOpacityMultiplier)
				glDrawGroundCircle(center[1], center[2], center[3], dgunRange, circleDivs*lineOpacityMultiplier)
				
				glLineWidth(3.3-lineWidthMinus)
				glColor(1, 0, 0, .48*lineOpacityMultiplier)
				glDrawGroundCircle(center[1], center[2], center[3], blastRadius, (circleDivs*1.2)*lineOpacityMultiplier)
			end
		end
	end
	glLineWidth(1)
	glDepthTest(false)
end

function widget:GetConfigData(data)
    savedTable = {}
    savedTable.showLineGlow = showLineGlow
    return savedTable
end

function widget:SetConfigData(data)
    if data.showLineGlow ~= nil 	then  autoFade	= data.showLineGlow end
end

function widget:TextCommand(command)
    if (string.find(command, "comranges_glow") == 1  and  string.len(command) == 14) then 
		showLineGlow = not showLineGlow
		if autoFade then
			Spring.Echo("Pause screen:  Glow on")
		else
			Spring.Echo("Pause screen:  Glow off")
		end
	end
end

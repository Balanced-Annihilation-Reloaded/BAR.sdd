function widget:GetInfo()
  return {
    name      = "Commander Name Tags",
    desc      = "Displays a name tag above each commander.",
    author    = "Bluestone, Floris",
    date      = "January 2015",
    license   = "GNU GPL, v2 or later",
    layer     = -10,
    enabled   = false,  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
-- config
--------------------------------------------------------------------------------

local heightOffset			= 28
local fontSize				= 13
local scaleFontAmount		= 130

local font = gl.LoadFont("Fonts/FreeSansBold.otf",50, 8, 8)

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local GetUnitTeam        		= Spring.GetUnitTeam
local GetTeamInfo        		= Spring.GetTeamInfo
local GetPlayerInfo      		= Spring.GetPlayerInfo
local GetTeamColor       		= Spring.GetTeamColor
local GetVisibleUnits    		= Spring.GetVisibleUnits
local GetUnitDefID       		= Spring.GetUnitDefID
local GetAllUnits        		= Spring.GetAllUnits
local IsUnitInView	 	 		= Spring.IsUnitInView
local GetCameraPosition  		= Spring.GetCameraPosition
local GetUnitPosition    		= Spring.GetUnitPosition

local glDepthTest        		= gl.DepthTest
local glAlphaTest        		= gl.AlphaTest
local glColor            		= gl.Color
local glText             		= gl.Text
local glTranslate        		= gl.Translate
local glBillboard        		= gl.Billboard
local glDrawFuncAtUnit   		= gl.DrawFuncAtUnit
local GL_GREATER     	 		= GL.GREATER
local GL_SRC_ALPHA				= GL.SRC_ALPHA	
local GL_ONE_MINUS_SRC_ALPHA	= GL.ONE_MINUS_SRC_ALPHA
local glBlending          		= gl.Blending

--------------------------------------------------------------------------------

local comms = {}

--------------------------------------------------------------------------------

--gets the name, color, and height of the commander
local function GetCommAttributes(unitID, unitDefID)
  local team = GetUnitTeam(unitID)
  if team == nil then
    return nil
  end
  local _, player = GetTeamInfo(team)
  local name,_,_,_,_,_,_,country,rank = GetPlayerInfo(player)
  local r, g, b, a = GetTeamColor(team)
  local height = UnitDefs[unitDefID].height + heightOffset
  return {name or 'Commander', {r, g, b, a}, height, country, rank}
end


local function DrawName(unitID, attributes)
  
  local iconHeight = (12.5+usedFontSize/1.6)
  
  glTranslate(0, attributes[3], 0 )
  glBillboard()
   
  font:Begin()
  font:SetTextColor(attributes[2])
  
  -- not acurate (enough)   but...   font:SetAutoOutlineColor(true)   doesnt seem to work
  if (attributes[2][1] + attributes[2][2]*1.35 + attributes[2][3]*0.5) < 0.75 then
    font:SetOutlineColor({1,1,1,1})
  else
    font:SetOutlineColor({0,0,0,1})
  end
  font:Print(attributes[1], -0.3, 0, usedFontSize, "con")
  
  font:End()
end


local vsx, vsy = Spring.GetViewGeometry()
function widget:ViewResize()
  vsx,vsy = Spring.GetViewGeometry()
end


function widget:DrawWorld()
  --if Spring.IsGUIHidden() then return end

  glDepthTest(true)
  glAlphaTest(GL_GREATER, 0)
  glBlending(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
   
  local camX, camY, camZ = GetCameraPosition()
  
  for unitID, attributes in pairs(comms) do
    
    -- calc opacity
	if IsUnitInView(unitID) then
		local x,y,z = GetUnitPosition(unitID)
		local xDifference = camX - x
		local yDifference = camY - y
		local zDifference = camZ - z
		camDistance = math.sqrt(xDifference*xDifference + yDifference*yDifference + zDifference*zDifference) 
		
	    usedFontSize = (fontSize*0.5) + (camDistance/scaleFontAmount)
	    
		glDrawFuncAtUnit(unitID, false, DrawName, unitID, attributes)
	end
  end
  
  glAlphaTest(false)
  glColor(1,1,1,1)
  glDepthTest(false)
end

--------------------------------------------------------------------------------

local function CreateName(unitID, unitDefID)
  local team = GetUnitTeam(unitID)
  if team == nil then
    return {name="",colour={0,0,0,0},height=0}
  end
  local _, player = GetTeamInfo(team)
  local name = GetPlayerInfo(player) or 'Robert Paulson'
  local r, g, b = GetTeamColor(team)
  local a = 1
  local height = UnitDefs[unitDefID].height + 22
  return {name=name, colour={r,g,b,a}, height=height}
end

function CheckCom(unitID, unitDefID, unitTeam)
  if (unitDefID and UnitDefs[unitDefID] and UnitDefs[unitDefID].customParams.iscommander) then
    comms[unitID] = CreateName(unitID, unitDefID)
  end
end

function CheckAllComs()
  local units = GetAllUnits()
  for _, unitID in ipairs(units) do
    local unitDefID = GetUnitDefID(unitID)
    if (unitDefID and UnitDefs[unitDefID].customParams.iscommander) then
      comms[unitID] = GetCommAttributes(unitID, unitDefID)
    end
  end
end

function widget:Initialize()
  CheckAllComs()
end

function PlayerChanged()
  CheckAllComs()
end
    
function widget:UnitCreated(unitID, unitDefID, unitTeam)
  CheckCom(unitID, unitDefID, unitTeam)
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
  comms[unitID] = nil
end

function widget:UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
  CheckCom(unitID, unitDefID, unitTeam)
end

function widget:UnitTaken(unitID, unitDefID, unitTeam, newTeam)
  CheckCom(unitID, unitDefID, unitTeam)
end

function widget:UnitEnteredLos(unitID, unitDefID, unitTeam)
  CheckCom(unitID, unitDefID, unitTeam)
end

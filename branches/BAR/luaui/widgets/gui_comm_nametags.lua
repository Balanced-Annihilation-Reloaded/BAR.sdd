function widget:GetInfo()
  return {
    name      = "Commander Name Tags",
    desc      = "Displays a name tag above each commander.",
    author    = "Bluestone",
    date      = "July 2014",
    license   = "GNU GPL, v2 or later",
    layer     = -10,
    enabled   = false,  --  loaded by default?
  }
end

--------------------------------------------------------------------------------

local GetUnitTeam         = Spring.GetUnitTeam
local GetTeamInfo         = Spring.GetTeamInfo
local GetPlayerInfo       = Spring.GetPlayerInfo
local GetTeamColor        = Spring.GetTeamColor
local GetVisibleUnits     = Spring.GetVisibleUnits
local GetUnitDefID        = Spring.GetUnitDefID
local GetAllUnits         = Spring.GetAllUnits

local glDepthTest         = gl.DepthTest
local glAlphaTest         = gl.AlphaTest
local glColor             = gl.Color
local glText              = gl.Text
local glTranslate         = gl.Translate
local glBillboard         = gl.Billboard
local glDrawFuncAtUnit    = gl.DrawFuncAtUnit
local GL_GREATER          = GL.GREATER

--------------------------------------------------------------------------------

local comms = {}

--------------------------------------------------------------------------------

local function DrawName(name,colour,height)
  glTranslate(0, height, 0 )
  glBillboard()  
  glColor(colour)
  if (colour[1]+colour[2]+colour[3]>0.5) then
    glText(name, 0, 0, 13, "co")
  end
  glText(name, 0, 0, 13, "c")
  glColor(1,1,1,1)
end

local vsx, vsy = Spring.GetViewGeometry()
function widget:ViewResize()
  vsx,vsy = Spring.GetViewGeometry()
end

function widget:DrawWorld()
  glDepthTest(true)
  glAlphaTest(GL_GREATER, 0)

  for unitID, _ in pairs(comms) do
    glDrawFuncAtUnit(unitID, false, DrawName, comms[unitID].name, comms[unitID].colour, comms[unitID].height)
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
      comms[unitID] = CreateName(unitID, unitDefID)
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

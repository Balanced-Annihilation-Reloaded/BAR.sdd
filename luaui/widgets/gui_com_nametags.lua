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

local font = gl.LoadFont("Fonts/freesansbold.otf",14, 3, 6)

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local GetUnitTeam                = Spring.GetUnitTeam
local GetTeamInfo                = Spring.GetTeamInfo
local GetPlayerInfo              = Spring.GetPlayerInfo
local GetTeamColor               = Spring.GetTeamColor
local GetVisibleUnits            = Spring.GetVisibleUnits
local GetUnitDefID               = Spring.GetUnitDefID
local GetAllUnits                = Spring.GetAllUnits
local IsUnitInView                  = Spring.IsUnitInView
local GetCameraPosition          = Spring.GetCameraPosition
local GetUnitPosition            = Spring.GetUnitPosition

local glDepthTest                = gl.DepthTest
local glAlphaTest                = gl.AlphaTest
local glColor                    = gl.Color
local glText                     = gl.Text
local glTranslate                = gl.Translate
local glBillboard                = gl.Billboard
local glDrawFuncAtUnit           = gl.DrawFuncAtUnit
local GL_GREATER                  = GL.GREATER
local GL_SRC_ALPHA                = GL.SRC_ALPHA    
local GL_ONE_MINUS_SRC_ALPHA    = GL.ONE_MINUS_SRC_ALPHA
local glBlending                  = gl.Blending

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
  local bgColor = {0,0,0,1}
  if (r + g*1.35 + b*0.5) < 0.75 then  -- font:SetAutoOutlineColor(true) is broken (same for gl)
    bgColor = {1,1,1,1}
  end
  local height = UnitDefs[unitDefID].height + 36
  return {name = name or 'Commander', colour = {r, g, b, a}, height = height, bgColour = bgColor}
end


local function DrawName(unitID, attributes)
  glTranslate(0, attributes.height, 0 )
  glBillboard()
   
  font:Begin()
  font:SetTextColor(attributes.colour)
  font:SetOutlineColor(attributes.bgColour)
  font:Print(attributes.name, 0, 0, fontSize, "vcon")
  font:End()
end


local vsx, vsy = Spring.GetViewGeometry()
function widget:ViewResize()
  vsx,vsy = Spring.GetViewGeometry()
end


function widget:DrawWorld()
  if Spring.IsGUIHidden() then return end

  glDepthTest(true)
  glAlphaTest(GL_GREATER, 0)
  glBlending(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
   
  for unitID, attributes in pairs(comms) do
    glDrawFuncAtUnit(unitID, false, DrawName, unitID, attributes)
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
      comms[unitID] = GetCommAttributes(unitID, unitDefID)
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

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
local IsUnitInView               = Spring.IsUnitInView
local GetCameraPosition          = Spring.GetCameraPosition
local GetUnitPosition            = Spring.GetUnitPosition
local IsUnitIcon                 = Spring.IsUnitIcon
local IsGUIHidden                = Spring.IsGUIHidden


local glDepthTest                = gl.DepthTest
local glAlphaTest                = gl.AlphaTest
local glColor                    = gl.Color
local glText                     = gl.Text
local glPushMatrix               = gl.PushMatrix
local glPopMatrix                = gl.PopMatrix
local glTranslate                = gl.Translate
local glBillboard                = gl.Billboard
local glDrawFuncAtUnit           = gl.DrawFuncAtUnit
local GL_GREATER                  = GL.GREATER
local GL_SRC_ALPHA                = GL.SRC_ALPHA    
local GL_ONE_MINUS_SRC_ALPHA    = GL.ONE_MINUS_SRC_ALPHA
local glBlending                  = gl.Blending

--------------------------------------------------------------------------------

local comms = {}

function CheckCommInfo(unitID, unitDefID)
  local teamID = GetUnitTeam(unitID)
  if teamID == nil then
    return nil
  end
  local _, player = GetTeamInfo(teamID)
  local name,_,_,_,_,_,_,country,rank = GetPlayerInfo(player)
  name = name or 'Commander'
  local r, g, b, a = GetTeamColor(teamID)
  local bgColor = {0,0,0,1}
  if (r + g*1.35 + b*0.5) < 0.75 then  
    bgColor = {1,1,1,1}
  end
  local height = UnitDefs[unitDefID].height + 36
  local x,y,z = GetUnitPosition(unitID)
  return {unitID=unitID, name=name, colour={r,g,b,a}, height=height, bgColour=bgColor, x=x,y=y,z=z}
end

function CheckCom(unitID)
  local unitDefID = Spring.GetUnitDefID(unitID)
  if not (unitDefID and UnitDefs[unitDefID].customParams.iscommander) then
    return 
  end
  
  for i=1,#comms do
    if unitID==comms[i].unitID then
      -- existing com
      comms[i] = CheckCommInfo(unitID, unitDefID)
      return
    end
  end
  -- new com  
  local info = CheckCommInfo(unitID, unitDefID)
  table.insert(comms, info)    
end

function RemoveCom(unitID)
  for i=1,#comms do
    if unitID==comms[i].unitID then
      table.remove(comms,i)
      break
    end
  end
end

function CheckAll()
  comms = {}
  local units = GetAllUnits()
  for _, unitID in ipairs(units) do
    CheckCom(unitID)
  end
end

function widget:Initialize()
  CheckAll()
end

function PlayerChanged()
  CheckAll()
end
    
function widget:UnitCreated(unitID, unitDefID, unitTeam)
  CheckCom(unitID)
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
  RemoveCom(unitID)
end

function widget:UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
  CheckCom(unitID)
end

function widget:UnitTaken(unitID, unitDefID, unitTeam, newTeam)
  CheckCom(unitID)
end

function widget:UnitEnteredLos(unitID, unitTeam, allyTeam, unitDefID)
  CheckCom(unitID)
end

function widget:UnitLeftLos(unitID, unitTeam, allyTeam, unitDefID)
  RemoveCom(unitID)
end

--------------------------------------------------------------------------------

function UpdateComPositions()
    for i=1,#comms do
        local info = comms[i]
        info.x,info.y,info.z = GetUnitPosition(info.unitID)
    end
end

function widget:GameFrame()
    UpdateComPositions()
end

function DrawName(info)   
  glBillboard()

  font:Begin()
  font:SetTextColor(info.colour)
  font:SetOutlineColor(info.bgColour)
  font:Print(info.name, 0, 0, fontSize, "vcon")
  font:End()
end

function widget:DrawWorld()
  if IsGUIHidden() then return end

  glDepthTest(true)

  local info
  for i=1,#comms do
    info = comms[i]
    if info.x and not IsUnitIcon(info.unitID) then
        glPushMatrix()
        glTranslate(info.x, info.height+info.y, info.z)
        DrawName(info)
        glPopMatrix()
    end
  end
  
  glDepthTest(false)
end

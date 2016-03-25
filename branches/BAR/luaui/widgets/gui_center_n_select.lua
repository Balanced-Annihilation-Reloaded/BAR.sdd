--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


function widget:GetInfo()
  return {
    name      = "Center n Select",
    desc      = "Selects and centers the Commander at the start of the game",
    author    = "quantum, Evil4Zerggin, zwzsg",
    date      = "19 April 2008",
    license   = "GNU GPL, v2 or later",
    layer     = 5,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local myPlayerID = Spring.GetMyPlayerID()
local myTeamID = Spring.GetMyTeamID()

function widget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
  local t = Spring.GetGameSeconds()
  local spec,_= Spring.GetSpectatingState()
  if spec or t<=0 or t>1 then return end
  
  if Game.gameVersion == "$VERSION" then
    widgetHandler:RemoveWidget() -- its annoying...
    return
  end
  
  local x, y, z = Spring.GetTeamStartPosition(myTeamID)
  local unitArray = Spring.GetTeamUnits(myTeamID)
  if (unitArray and #unitArray==1) then
    Spring.SelectUnitArray{unitArray[1]}
    x, y, z = Spring.GetUnitPosition(unitArray[1])
    if x and y and z then
      Spring.SetCameraTarget(x, y, z)
    end
  end
  
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

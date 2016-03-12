function gadget:GetInfo()
  return {
    name      = "Comgate",
    desc      = "Commander gate effect.",
    author    = "quantum, TheFatController",
    date      = "June 22, 2007",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

-------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------

local enabled = tonumber(Spring.GetModOptions().mo_comgate) or 0

if (enabled == 0) then 
  return false
end

--synced
if (gadgetHandler:IsSyncedCode()) then

local hiddenUnits = {}
local teleportUnits = {}
local initdone = false
local gameStart = false
local gaiaTeamID = Spring.GetGaiaTeamID()
local armcomDefID = UnitDefNames.armcom.id
local corcomDefID = UnitDefNames.corcom.id
local teleportDefID = UnitDefNames.teleport.id

function gadget:UnitCreated(unitID, unitDefID, teamID)
  if (not gameStart) then
    local x,y,z = Spring.GetUnitPosition(unitID)
    hiddenUnits[unitID] = {x,y,z,teamID}
    Spring.SetUnitNoDraw(unitID,true) 
  else
    if unitDefID == teleportDefID then
      Spring.SetUnitNoDraw(unitID,true)
      Spring.SetUnitNoSelect(unitID,true)
      teleportUnits[unitID] = true
    end
  end
end

function gadget:GameFrame(n)
  if (not gameStart) and (n > 5) then
    gameStart = true
    Spring.Echo("Initializing Commander Gate")   
  end
  if (n == 6) then
    for unitID,data in pairs(hiddenUnits) do
      Spring.CreateUnit(teleportDefID,data[1],data[2],data[3],90,data[4],nil)
    end
  end
  if (n == 140) then
    for unitID,_ in pairs(hiddenUnits) do
    Spring.SetUnitNoDraw(unitID,false)
    end
    for unitID,_ in pairs(teleportUnits) do
      Spring.DestroyUnit(unitID,false,true)
    end
  end
  if (n == 170) then
    Spring.Echo("Commander Gate Complete")
    gadgetHandler:RemoveGadget(self)
  end
end

function gadget:AllowCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions, cmdTag, synced)
    local n = Spring.GetGameFrame()
    if n < 140 then return false end
    return true
end

--unsynced
else

--Todo Match comgate sound effect to new effect duration (for now it uses weapon effect sounds)
--[[
function gadget:Initialize()
  gadgetHandler:AddSyncAction("gatesound", GateSound)
end

function GateSound(_,unitTeam,x,y,z)
  if (unitTeam == Spring.GetMyTeamID()) then
    Spring.PlaySoundFile("sounds/zap_zap.wav", 100, x,y,z)
  end
end
--]]
end
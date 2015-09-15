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
local initdone = false
local gameStart = false
local gaiaTeamID = Spring.GetGaiaTeamID()
local armcomDefID = UnitDefNames.armcom.id

function gadget:UnitCreated(unitID, unitDefID, teamID)
    if (not gameStart) then
        local x,y,z = Spring.GetUnitPosition(unitID)
        hiddenUnits[unitID] = {x,y,z,teamID,unitDefID}
        Spring.SetUnitNoDraw(unitID,true) 
    end
end

function gadget:GameFrame(n)
  if (not gameStart) and (n > 5) then
    gameStart = true
    Spring.Echo("Initializing Commander Gate")   
  end
  if (n == 6) then
    for unitID,data in pairs(hiddenUnits) do
      if data[5] == armcomDefID then
        local env = Spring.UnitScript.GetScriptEnv(unitID)
        Spring.UnitScript.CallAsUnit(unitID,env.Teleport)
      else
        Spring.CallCOBScript(unitID, "TeleportControl", 0)
      end
      --SendToUnsynced("gatesound", data[4], data[1], data[2]+90, data[3])
    end
  end
  if (n == 140) then
    for unitID,_ in pairs(hiddenUnits) do
    Spring.SetUnitNoDraw(unitID,false)
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
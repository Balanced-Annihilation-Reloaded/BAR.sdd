function gadget:GetInfo()
  return {
    name      = "SetNeutral",
    desc      = "Sets Armoured Units to Neutral when closed",
    author    = "TheFatController",
    date      = "25 Nov 2008",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local enabled = tonumber(Spring.GetModOptions().mo_chickengame) or 0

if (enabled == 0) then 
  return false
end

if (not gadgetHandler:IsSyncedCode()) then
  return
end

local GetUnitCOBValue = Spring.GetUnitCOBValue
local SetUnitNeutral = Spring.SetUnitNeutral
local GetUnitStates = Spring.GetUnitStates
local neutralUnits = {}
local armourTurrets = {}
armourTurrets[UnitDefNames["cormaw"].id] = true
armourTurrets[UnitDefNames["armclaw"].id] = true
armourTurrets[UnitDefNames["corvipe"].id] = true
armourTurrets[UnitDefNames["armpb"].id] = true
armourTurrets[UnitDefNames["cortoast"].id] = true
armourTurrets[UnitDefNames["armamb"].id] = true
armourTurrets[UnitDefNames["cordoom"].id] = true
armourTurrets[UnitDefNames["packo"].id] = true
local UPDATE = 30
local timeCounter = 15

function gadget:GameFrame(n)
  if (n >= timeCounter) then
    timeCounter = (n + UPDATE)
    for unitID,neutral in pairs(neutralUnits) do
      local armoured = (GetUnitCOBValue(unitID, 20) > 0)
      if neutral and (not armoured) then
        SetUnitNeutral(unitID, false)
        neutralUnits[unitID] = false  
      elseif (not neutral) and armoured then
        SetUnitNeutral(unitID, true)
        neutralUnits[unitID] = true  
      end      
    end    
  end
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
  neutralUnits[unitID] = nil
end

function gadget:UnitFinished(unitID, unitDefID, unitTeam)
  if armourTurrets[unitDefID] then
    if (GetUnitCOBValue(unitID, 20) == 1) then
      SetUnitNeutral(unitID, true)
      neutralUnits[unitID] = true
    else
      neutralUnits[unitID] = false
    end
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

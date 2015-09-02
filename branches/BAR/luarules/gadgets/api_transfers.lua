function gadget:GetInfo()
  return {
    name      = "Transfers API",
    desc      = "Tells LuaUI when a unit or resource transfer takes place",
    author    = "Bluestone",
    date      = "August 2014",
    license   = "GPL v2 or later",
    layer     = math.huge,
    enabled   = true  --  loaded by default?
  }
end

if (gadgetHandler:IsSyncedCode()) then

-- this part is a synced gadget because AllowResourceTransfer is the only way to detect when a resource transfer takes place
-- otherwise, it should be an unsynced gadget and the SendToUnsycned step should be removed

local hadTransfer = false
local transfers = {}

------------------
-- record transfer

function gadget:UnitGiven(unitID, unitDefID, newTeamID, teamID)
    hadTransfer = true
    
    transfers[teamID] = transfers[teamID] or {}
    transfers[teamID][newTeamID] = transfers[teamID][newTeamID] or {}
    transfers[teamID][newTeamID].unit = transfers[teamID][newTeamID].unit or 0
    
    transfers[teamID][newTeamID].unit = transfers[teamID][newTeamID].unit + 1
end

function gadget:AllowResourceTransfer(teamID,newTeamID,resType,amount)
    hadTransfer = true
    
    local res
    if resType=="m" then res = "metal" 
    elseif resType=="e" then res = "energy" end
    if not res then return end
    
    transfers[teamID] = transfers[teamID] or {}
    transfers[teamID][newTeamID] = transfers[teamID][newTeamID] or {}
    transfers[teamID][newTeamID][res] = transfers[teamID][newTeamID][res] or 0
    
    transfers[teamID][newTeamID][res] = transfers[teamID][newTeamID][res] + amount
    
    return true
end

------------------
-- announce transfers to unsynced

function format(num, idp)
  return string.format("%." .. (idp or 0) .. "f", num)
end

function Pluralize(object, amount)
    return (amount==1) and object or object.."s"
end

function AnnounceTransfer(teamID, newTeamID, object, amount)
    if object=="unit" then
        object = Pluralize(object,amount)
    end
    amount = format(amount,0)
    
    SendToUnsynced("ObjectTransfered", teamID, newTeamID, object, amount)
end

function gadget:GameFrame(n)
    if not hadTransfer then return end
    if n%10~=0 then return end --avoid transfer spam using cpu
    

    for teamID,v in pairs(transfers) do
        for newTeamID,v2 in pairs(v) do
            for object,amount in pairs(v2) do
                AnnounceTransfer(teamID, newTeamID, object, amount)
            end        
        end    
    end

    transfers = {}    
    hadTransfer = false
end


------------------
else -- unsynced
------------------

function gadget:Initialize()
    gadgetHandler:AddSyncAction("ObjectTransfered", ObjectTransfered)
end

function gadget:ShutDown()
    gadgetHandler:RemoveSyncAction("ObjectTransfered")
end

function ObjectTransfered(_,teamID, newTeamID, object, amount)
    if not Script.LuaUI("ObjectTransfered") then return end
    local spec = Spring.GetSpectatingState()
    if not (spec or Spring.AreTeamsAllied(teamID,Spring.GetMyTeamID())) then return end
    Script.LuaUI.ObjectTransfered(teamID, newTeamID, object, amount)
end



end

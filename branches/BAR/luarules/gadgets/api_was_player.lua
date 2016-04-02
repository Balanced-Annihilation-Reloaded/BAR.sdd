function gadget:GetInfo()
    return {
        name      = "Was Player",
        desc      = "Sets gamerulesparams to record if a playerID was ever a player",
        author    = "Bluestone", 
        date      = "July 2014",
        license   = "GNU GPL, v3 or later",
        layer     = 0,
        enabled   = true,  
    }
end

--------------------------------------
if gadgetHandler:IsSyncedCode() then 
--------------------------------------

local players = {}

function Broadcast()
    local playerList = Spring.GetPlayerList()
    for _,pID in ipairs(playerList) do
        local _,_,spec,tID = Spring.GetPlayerInfo(pID)  

        if (not players[pID] and not spec) or (players[pID] and players[pID]~=tID) then
            players[pID] = tID
            Spring.SetGameRulesParam("player_" .. tostring(pID) .. "_wasPlayer", tID)
        end
    end    
end

function gadget:Initialize()
    Broadcast()
end

function gadget:GameFrame() -- no better way to do this in synced and unsynced can't set rules params :(
    Broadcast()
end

--------------------------------------
end
--------------------------------------

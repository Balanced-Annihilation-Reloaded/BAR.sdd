function gadget:GetInfo()
	return {
		name      = "Was Player",
		desc      = "Sets gamerulesparams to record if a playerID was ever actually a player",
		author    = "Bluestone", 
		date      = "July 2014",
		license   = "GNU GPL, v3 or later",
		layer     = 0,
		enabled   = true,  
	}
end

if not gadgetHandler:IsSyncedCode() then return false end

local players = {}

function Broadcast()
    local playerList = Spring.GetPlayerList()
    for _,pID in ipairs(playerList) do
        local _,_,spec,_ = Spring.GetPlayerInfo(pID)  

        if not spec then
            players[pID] = true
        end
    end

    for pID,_ in pairs(players) do
        Spring.SetGameRulesParam("player_" .. tostring(pID) .. "_wasPlayer", 1)
    end    
end

function gadget:Initialize()
    Broadcast()
end

function gadget:PlayerChanged()
    Broadcast()
end
function widget:GetInfo()
  return {
    name      = "Transfer Announce", 
    desc      = "Tells you when unit/resource transfers take place",
    author    = "Bluestone", 
    date      = "",
    license   = "GPL v2 or later",
    layer     = 0, 
    enabled   = true
  }
end

local white = "\255\255\255\255"

function InlineColour(R,G,B)
    local r,g,b
    if type(R) == 'table' then
        r,g,b = math.max(1,R[1]*255),math.max(1,R[2]*255),math.max(1,R[3]*255)
    else
        r,g,b = math.max(1,R*255),math.max(1,G*255),math.max(1,B*255)
    end
    return string.char(255,r,g,b)
end

function GetTeamPlayerName(teamID)
    local r,g,b = Spring.GetTeamColor(teamID)
    local colourString = InlineColour(r,g,b)
    
    local skirmishAIID, name, hostPlayerID, shortName, version = Spring.GetAIInfo(teamID)
    local playerList = Spring.GetPlayerList(teamID)
    local teamLeader = playerList[1] and select(1,Spring.GetPlayerInfo(playerList[1])) or ""
    local name = shortName or teamLeader or ""
    
    if #playerList<=1 then return colourString .. name
    else return colourString .. name .. " (coop)"
    end    
end

function ObjectTransfered(teamID, newTeamID, object, amount)
    Spring.Echo(GetTeamPlayerName(teamID) .. white .. " sent " .. amount .. " " .. object .. " to " .. GetTeamPlayerName(newTeamID))
end

function widget:Initialize()
    widgetHandler:RegisterGlobal("ObjectTransfered", ObjectTransfered)
end

function widget:ShutDown()
    widgetHandler:DeregisterGlobal("ObjectTransfered")
end

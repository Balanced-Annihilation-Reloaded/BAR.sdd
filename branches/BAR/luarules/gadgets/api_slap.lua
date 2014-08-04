function gadget:GetInfo()
  return {
    name      = "Slap",
    desc      = "Slaps Players",
    author    = "Bluestone",
    date      = "August 2014",
    license   = "Horses",
    layer     = -math.huge,
    enabled   = true  --  loaded by default?
  }
end

if (gadgetHandler:IsSyncedCode()) then
	return
end

local slappingObjects = {
    [1] = "wet fish",
    [2] = "small inflatable willy",
    [3] = "goat",
    [4] = "severed hand",
    [5] = "raw beefsteak",
}

local myPlayerID = Spring.GetMyPlayerID()
local myName,_ = Spring.GetPlayerInfo(myPlayerID)

local lastSlap = Spring.GetTimer()
local firstSlap = true

function Slap(cmd,line,words,playerID)
    local theirPlayerID = tonumber(words[1])    
    if playerID~=myPlayerID then return end
    if theirPlayerID==myPlayerID then 
        Spring.Echo("You slapped yourself")
        return
    end

    local thisSlap = Spring.GetTimer()
    if not firstSlap and Spring.DiffTimers(thisSlap,lastSlap)<30 then
        Spring.Echo("Slap limit reached, please wait!")
        return
    end
    firstSlap = false
    
    local theirName,_ = Spring.GetPlayerInfo(theirPlayerID)
    if not theirName then return end

    
    lastSlap = thisSlap    
    local slapText = myName .. " slaps " .. theirName .. " around with a "
    
    if math.random() < 0.95 then
        slapText = slapText .. "large peewee"
    else
        local n = math.random(1,#slappingObjects)
        slapText = slapText .. slappingObjects[n]
    end

    Spring.SendMessage(slapText)
end


function gadget:Initialize()
	gadgetHandler:AddChatAction('slap', Slap, "")
end


function gadget:Shutdown()
	gadgetHandler:RemoveChatAction('slap')
end




--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

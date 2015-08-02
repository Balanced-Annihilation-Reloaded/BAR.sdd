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

local slappingObjects_uncommon = {
    [1] = "a wet fish",
    [2] = "a leather glove",
    [3] = "a goat",
    [4] = "a severed hand",
    [5] = "a raw beefsteak",
}

local slappingObjects_rare = {
    [1] = "a long-eared bunny rabbit",
    [2] = "a paddle",
    [4] = "a sack of dead kittens",
    [3] = "a pair of inflatable breasts",
    [5] = "the interminable torment of mankind",
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
    local slapText = myName .. " slaps " .. theirName .. " around with "
    
    if math.random() < 0.95 then
        slapText = slapText .. "large peewee"
    else
        if math.random() < 0.80 then
            local n = math.random(1,#slappingObjects_uncommon)
            slapText = slapText .. slappingObjects_uncommon[n]
        else
            local n = math.random(1,#slappingObjects_rare)
            slapText = slapText .. slappingObjects_rare[n]        
        end
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

function gadget:GetInfo()
  return {
    name      = "Substitution",
    desc      = "Allows players absent at gamestart to be replaced by specs",
    author    = "Bluestone",
    date      = "June 2014",
    license   = "GNU GPL, v3 or later",
    layer     = 1, --run after game_intial_spawn 
    enabled   = true  
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-----------------------------
if gadgetHandler:IsSyncedCode() then 
-----------------------------

-- TS difference required for substitutions 
-- idealDiff is used if possible, validDiff as fall-back, otherwise no
local validDiff = 4 
local idealDiff = 2

local substitutes = {}
local players = {}
local absent = {}
local replaced = false
local gameStarted = false

local gaiaTeamID = Spring.GetGaiaTeamID()

function gadget:RecvLuaMsg(msg, playerID)
	if msg=='\145' then
        substitutes[playerID] = nil
        --Spring.Echo("received removal", playerID)
    end
    if msg=='\144' then
        -- do the same eligibility check as in unsynced
        local customtable = select(10,Spring.GetPlayerInfo(playerID))
        local tsMu = customtable.skill 
        local tsSigma = customtable.skilluncertainty
        ts = tsMu and tonumber(tsMu:match("%d+%.?%d*"))
        tsSigma = tonumber(tsSigma)
        local eligible = tsMu and tsSigma and (tsSigma<=2) and (not string.find(tsMu, ")")) and (not players[playerID]) 
        if eligible then
            substitutes[playerID] = ts
        end
        --Spring.Echo("received", playerID, eligible, ts)
    end

    FindSubs(false)    
end

function gadget:PlayerChanged()
    if not gameStarted then
        FindSubs(false)
    end
end

function gadget:Initialize()
    if (tonumber(Spring.GetModOptions().mo_noowner) or 0) == 1 then
        gadgetHandler:RemoveGadget() -- don't run in FFA mode
        return 
    end

    -- record a list of which playersIDs are players on which teamID
    local teamList = Spring.GetTeamList()
    for _,teamID in pairs(teamList) do
    if teamID~=gaiaTeamID then
        local playerList = Spring.GetPlayerList(teamID)
        for _,playerID in pairs(playerList) do
            local _,_,spec = Spring.GetPlayerInfo(playerID)
            if not spec then
                players[playerID] = teamID
            end
        end
    end
    end
end

function FindSubs(real)
    -- make a copy of the substitutes table
    local substitutesLocal = {}
    local i = 0
    for k,v in pairs(substitutes) do
        substitutesLocal[k] = v
        i = i + 1
    end
    absent = {}
    --Spring.Echo("subs: " .. i)
    
    -- make a list of absent players (only ones with valid ts)
    for playerID,_ in pairs(players) do
        local _,active,spec = Spring.GetPlayerInfo(playerID)
        local present = active and not spec
        if not present then
            local customtable = select(10,Spring.GetPlayerInfo(playerID)) -- player custom table
            local tsMu = customtable.skill
            ts = tsMu and tonumber(tsMu:match("%d+%.?%d*")) 
            if ts then
                absent[playerID] = ts
                --Spring.Echo("absent:", playerID, ts)
            end
        end
    end
    --Spring.Echo("absent: " .. #absent)
    
    -- for each one, try and find a suitable replacement & substitute if so
    for playerID,ts in pairs(absent) do
        -- construct a table of who is ideal/valid 
        local idealSubs = {}
        local validSubs = {}
        for subID,subts in pairs(substitutesLocal) do
            local _,active,spec = Spring.GetPlayerInfo(subID)
            if active and spec then
                if  math.abs(ts-subts)<=validDiff then 
                    validSubs[#validSubs+1] = subID
                end
				if math.abs(ts-subts)<=idealDiff then
                    idealSubs[#idealSubs+1] = subID 
                end
            end
        end
        --Spring.Echo("ideal: " .. #idealSubs .. " for pID " .. playerID)
        --Spring.Echo("valid: " .. #validSubs .. " for pID " .. playerID)

        local willSub = false
        if #validSubs>0 then
            -- choose who
            local sID
            if #idealSubs>0 then
                sID = (#idealSubs>1) and idealSubs[math.random(1,#idealSubs)] or idealSubs[1]
            else
                sID = (#validSubs>1) and validSubs[math.random(1,#validSubs)] or validSubs[1]
            end
            
            if real then
                -- do the replacement 
                local teamID = players[playerID]
                Spring.AssignPlayerToTeam(sID, teamID)
                replaced = true
                
                local incoming,_ = Spring.GetPlayerInfo(sID)
                local outgoing,_ = Spring.GetPlayerInfo(playerID)            
                Spring.Echo("Player " .. incoming .. " was substituted in for " .. outgoing)
            end
            substitutesLocal[sID] = nil
            willSub = true
        end
        --Spring.Echo("willSub: " .. (sID or "-1") .. " for pID " .. playerID)
        
        if not real then
            -- tell luaui who we would substitute if the game started now
            Spring.SetGameRulesParam("Player" .. playerID .. "willSub", willSub and 1 or 0)
        end
    end

end

function gadget:GameStart()
    gameStarted = true
    FindSubs(true)
end

function gadget:GameFrame(n)
    if n~=1 then return end

    if replaced then
        -- if at least one player was replaced, reveal startpoints to all
        Spring.Echo("Revealing start points to all")
       
        local coopStartPoints = GG.coopStartPoints or {} 
        local revealed = {}
        for pID,p in pairs(coopStartPoints) do --first do the coop starts
            local name,_,tID = Spring.GetPlayerInfo(pID)
            SendToUnsynced("MarkStartPoint", p[1], p[2], p[3], name, tID)
            revealed[pID] = true
        end
            
        local teamStartPoints = GG.teamStartPoints or {}
        for tID,p in pairs(teamStartPoints) do
            p = teamStartPoints[tID]
            local playerList = Spring.GetPlayerList(tID)
            local name = ""
            for _,pID in pairs(playerList) do --now do all pIDs for this team which were not coop starts
                if not revealed[pID] then
                    local pName,active,spec = Spring.GetPlayerInfo(pID) 
                    if pName and absent[pID]==nil and active and not spec then --AIs might not have a name, don't write the name of the dropped player
                        name = name .. pName .. ", "
                        revealed[pID] = true
                    end
                end
            end
            if name ~= "" then
                name = string.sub(name, 1, math.max(string.len(name)-2,1)) --remove final ", "
            end
            SendToUnsynced("MarkStartPoint", p[1], p[2], p[3], name, tID)
        end
    end
    
    gadgetHandler:RemoveGadget()
    return
end

-----------------------------
else -- begin unsynced section
-----------------------------
return false
-----------------------------
end -- end unsynced section
-----------------------------

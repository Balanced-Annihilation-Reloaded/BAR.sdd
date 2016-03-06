function gadget:GetInfo()
  return {
    name      = "Awards",
    desc      = "AwardsAwards",
    author    = "Bluestone",
    date      = "2013-07-06",
    license   = "GPLv2",
    layer     = -1, 
    enabled   = false -- disabled until there is a GUI end of it
  }
end

if (gadgetHandler:IsSyncedCode()) then 

local SpAreTeamsAllied = Spring.AreTeamsAllied

local teamInfo = {}
local coopInfo = {}
local present = {}

local econUnitDefIDs = { --better to hardcode these since its complicated to pick them out with UnitDef properties
    --land t1
    UnitDefNames.armsolar.id,
    UnitDefNames.corsolar.id,
    UnitDefNames.armadvsol.id,
    UnitDefNames.coradvsol.id,
    UnitDefNames.armwin.id,
    UnitDefNames.corwin.id,
    UnitDefNames.armmakr.id,
    UnitDefNames.cormakr.id,
    --sea t1
    UnitDefNames.armtide.id,
    UnitDefNames.cortide.id,
    UnitDefNames.armfmkr.id,
    UnitDefNames.corfmkr.id,
    --land t2
    UnitDefNames.armmmkr.id,
    UnitDefNames.cormmkr.id,
    UnitDefNames.corfus.id,
    UnitDefNames.armfus.id,
    UnitDefNames.aafus.id,
    UnitDefNames.cafus.id,
    --sea t2
    UnitDefNames.armuwfus.id,
    UnitDefNames.coruwfus.id,
    UnitDefNames.armfmmm.id,
    UnitDefNames.corfmmm.id,
}


function gadget:GameStart()
    --make table of teams eligible for awards
    local allyTeamIDs = Spring.GetAllyTeamList()
    local gaiaTeamID = Spring.GetGaiaTeamID()
    for i=1,#allyTeamIDs do
        local teamIDs = Spring.GetTeamList(allyTeamIDs[i])
        for j=1,#teamIDs do
            local _,_,_,isAiTeam = Spring.GetTeamInfo(teamIDs[j])
            local isLuaAI = (Spring.GetTeamLuaAI(teamIDs[j]) ~= "")
            local isGaiaTeam = (teamIDs[j] == gaiaTeamID)
            if ((not isAiTeam) and (not isLuaAi) and (not isGaiaTeam)) then
                local playerIDs = Spring.GetPlayerList(teamIDs[j])
                local numPlayers = 0
                for _,playerID in pairs(playerIDs) do
                    local _,_,isSpec = Spring.GetPlayerInfo(playerID) 
                    if not isSpec then 
                        numPlayers = numPlayers + 1
                    end
                end
                
                if numPlayers > 0 then
                    present[teamIDs[j]] = true
                    teamInfo[teamIDs[j]] = {ecoDmg=0, fightDmg=0, otherDmg=0, dmgDealt=0, ecoUsed=0, dmgRatio=0, ecoProd=0, lastKill=0, dmgRec=0, sleepTime=0, unitsCost=0, present=true,}
                    coopInfo[teamIDs[j]] = {players=numPlayers,}
                else
                    present[teamIDs[j]] = false
                end
            else
                present[teamIDs[j]] = false
            end
        end
    end
end

function isEcon(unitDefID) 
    --return true if unitDefID is an eco producer, false otherwise
    for _,id in pairs(econUnitDefIDs) do
        if unitDefID == id then
            return true
        end
    end
    return false
end

function gadget:UnitDestroyed(unitID, unitDefID, teamID, attackerID, attackerDefID, attackerTeamID)
    -- add destroyed unitID cost to stats for attackerTeamID
    if not attackerTeamID then return end
    if attackerTeamID == gaiaTeamID then return end
    if not present[attackerTeamID] then return end
    if (not unitDefID) or (not teamID) then return end
    if SpAreTeamsAllied(teamID, attackerTeamID) then return end
    
    --keep track of who didn't kill for longest (sleeptimes)
    local curTime = Spring.GetGameSeconds()
    if (curTime - teamInfo[attackerTeamID].lastKill > teamInfo[attackerTeamID].sleepTime) then
        teamInfo[attackerTeamID].sleepTime = curTime - teamInfo[attackerTeamID].lastKill
    end
    teamInfo[attackerTeamID].lastKill = curTime
    
    local ud = UnitDefs[unitDefID]
    local cost = ud.energyCost + 60 * ud.metalCost
    
    --keep track of killing 
    if #(ud.weapons) > 0 then
        teamInfo[attackerTeamID].fightDmg = teamInfo[attackerTeamID].fightDmg + cost
    elseif isEcon(unitDefID) then
        teamInfo[attackerTeamID].ecoDmg = teamInfo[attackerTeamID].ecoDmg + cost
    else
        teamInfo[attackerTeamID].otherDmg = teamInfo[attackerTeamID].otherDmg + cost --currently not using this but recording it for interest
    end        
    --Spring.Echo(teamInfo[attackerTeamID].fightDmg, teamInfo[attackerTeamID].ecoDmg, teamInfo[attackerTeamID].otherDmg)
end

function gadget:UnitCreated(unitID, unitDefID, teamID, builderID)
    if not teamID then return end
    if teamID==gaiaTeamID then return end
    if not present[teamID] then return end
    if not unitDefID then return end
    
    local ud = UnitDefs[unitDefID]
    local cost = ud.energyCost + 60 * ud.metalCost
    
    if #(ud.weapons) > 0 and not ud.customParams.iscommander then
        teamInfo[teamID].unitsCost = teamInfo[teamID].unitsCost + cost   
    end
    --Spring.Echo(teamID, teamInfo[teamID].unitsCost)
end

function gadget:UnitTaken(unitID, unitDefID, teamID, newTeam)
    if not newTeam then return end 
    if newTeam==gaiaTeamID then return end
    if not present[newTeam] then return end
    if not present[teamID] then return end
    if not unitDefID then return end --should never happen
    if not teamID then return end
    
    local ud = UnitDefs[unitDefID]
    local cost = ud.energyCost + 60 * ud.metalCost

    teamInfo[newTeam].ecoUsed = teamInfo[newTeam].ecoUsed + cost 
    if #(ud.weapons) > 0 then
        teamInfo[newTeam].unitsCost = teamInfo[newTeam].unitsCost + cost   
    end
end

function GameOverTeamInfo()
    -- calculate average damage dealt
    local avgTeamDmg = 0 
    local numTeams = 0
    for teamID,_ in pairs(teamInfo) do
        local cur_max = Spring.GetTeamStatsHistory(teamID)
        local stats = Spring.GetTeamStatsHistory(teamID, 0, cur_max)
        avgTeamDmg = avgTeamDmg + stats[cur_max].damageDealt / coopInfo[teamID].players
        numTeams = numTeams + 1
    end
    avgTeamDmg = avgTeamDmg / (math.max(1,numTeams))
    
    -- get other stuff from engine stats
    for teamID,_ in pairs(teamInfo) do
        local cur_max = Spring.GetTeamStatsHistory(teamID)
        local stats = Spring.GetTeamStatsHistory(teamID, 0, cur_max)
        teamInfo[teamID].dmgDealt = teamInfo[teamID].dmgDealt + stats[cur_max].damageDealt    
        teamInfo[teamID].ecoUsed = teamInfo[teamID].ecoUsed + stats[cur_max].energyUsed + 60 * stats[cur_max].metalUsed
        teamInfo[teamID].dmgRec = stats[cur_max].damageReceived
        teamInfo[teamID].ecoProd = stats[cur_max].energyProduced + 60 * stats[cur_max].metalProduced
    end

    -- take account of coop
    for teamID,_ in pairs(teamInfo) do
        teamInfo[teamID].ecoDmg = teamInfo[teamID].ecoDmg / coopInfo[teamID].players
        teamInfo[teamID].fightDmg = teamInfo[teamID].fightDmg / coopInfo[teamID].players
        teamInfo[teamID].otherDmg = teamInfo[teamID].otherDmg / coopInfo[teamID].players
        teamInfo[teamID].dmgRec = teamInfo[teamID].dmgRec / coopInfo[teamID].players 
    end

    -- sleep times
    local curTime = Spring.GetGameSeconds()
    for teamID,_ in pairs(teamInfo) do
        if (curTime - teamInfo[teamID].lastKill > teamInfo[teamID].sleepTime) then
            teamInfo[teamID].sleepTime = curTime - teamInfo[teamID].lastKill
        end
    end
end

function RankedTeams(Score)
    local t = {}
    for teamID,_ in pairs(teamInfo) do
        t[#t+1] = {tID=teamID, score=Score(teamID)}
    end
    local function IS_IT_SO_BLOODY_DIFFICULT_TO_HAVE_STD_SET(i,j)
        return t[i].score>t[j].score
    end
    table.sort(t, IS_IT_SO_BLOODY_DIFFICULT_TO_HAVE_STD_SET)
    return t
end

function AwardAward(name, action, t)
    for i=1,3 do
        t[i] = t[i] or {}
    end
    SendToUnsynced("AwardAward", name, action, t[1].tID, t[1].score, t[2].tID, t[2].score, t[3].tID, t[3].score)
end

function gadget:GameOver(winningAllyTeams)
    -- Finalize your info table, then award the awards
    GameOverTeamInfo()
    
    -- ecoDmg, teamInfo[teamID].ecoDmg
    local function ecoDmg(teamID)
        return teamInfo[teamID].ecoDmg
    end
    local ecoDmgRanked = RankedTeams(ecoDmg)
    AwardAward("ecoDmg", "Killing enemy economy", ecoDmgRanked)
    
    -- fightKill, teamInfo[teamID].fightDmg
    local function fightDmg(teamID)
        return teamInfo[teamID].fightDmg
    end
    local fightDmgRanked = RankedTeams(fightDmg)
    AwardAward("fightDmg", "Killing enemy units and defences", fightDmgRanked)
    
    
    -- teamInfo[teamID].ecoProd
    local function ecoProd(teamID)
        return teamInfo[teamID].ecoProd
    end
    local ecoProdRanked = RankedTeams(fightDmg)
    AwardAward("ecoProd", "produced the most eco", ecoProdRanked)
    
    
    -- teamInfo[teamID].dmgRec
    local function dmgRec(teamID)
        return teamInfo[teamID].dmgRec
    end
    local dmgRecRanked = RankedTeams(dmgRec)
    AwardAward("ecoProd", "produced the most eco", dmgRecRanked)


    -- teamInfo[teamID].sleepTime
    local function sleepTime(teamID)
        return teamInfo[teamID].sleepTime
    end
    local sleepTimeRanked = RankedTeams(sleepTime)
    AwardAward("sleepTime", "slept longest", sleepTimeRanked)
end




-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
else  -- UNSYNCED
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function gadget:Initialize()
    gadgetHandler:AddSyncAction("AwardAward", AwardAward)    
end

function AwardAward (_, name, action, first, first_score, second, second_score, third, third_score)
    --Spring.Echo(name, action, first, first_score, second, second_score, third, third_score)

                        
    --record who won which awards in chat message (for demo parsing by replays.springrts.com)
    --make all values positive, as unsigned ints are easier to parse
    --[[
    local ecoKillLine    = '\161' .. tostring(1+ecoKillAward) .. ':' .. tostring(ecoKillScore) .. '\161' .. tostring(1+ecoKillAwardSec) .. ':' .. tostring(ecoKillScoreSec) .. '\161' .. tostring(1+ecoKillAwardThi) .. ':' .. tostring(ecoKillScoreThi)  
    local fightKillLine  = '\162' .. tostring(1+fightKillAward) .. ':' .. tostring(fightKillScore) .. '\162' .. tostring(1+fightKillAwardSec) .. ':' .. tostring(fightKillScoreSec) .. '\162' .. tostring(1+fightKillAwardThi) .. ':' .. tostring(fightKillScoreThi)
    local awardsMsg = ecoKillLine .. fightKillLine
    Spring.SendLuaRulesMsg(awardsMsg)
    ]]
    
    ---tell widgetland
    if Script.LuaUI("AwardAward") then
        Script.LuaUI.AwardAward(name, action, first, first_score, second, second_score, third, third_score)
    end
end


function gadget:Shutdown()
    gadgetHandler:RemoveSyncAction("AwardAward")    
end

end

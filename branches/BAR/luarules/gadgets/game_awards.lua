function gadget:GetInfo()
  return {
    name      = "Awards",
    desc      = "AwardsAwards",
    author    = "Bluestone",
    date      = "2013-07-06",
    license   = "GPLv2",
    layer     = -1, 
    enabled   = true -- loaded by default?
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
	if not unitDefID then return end --should never happen
    if not teamID then return end
    
	local ud = UnitDefs[unitDefID]
	local cost = ud.energyCost + 60 * ud.metalCost

	teamInfo[newTeam].ecoUsed = teamInfo[newTeam].ecoUsed + cost 
    if #(ud.weapons) > 0 then
        teamInfo[teamID].unitsCost = teamInfo[teamID].unitsCost + cost   
    end
end


function gadget:GameOver(winningAllyTeams)
	--calculate average damage dealt
	local avgTeamDmg = 0 
	local numTeams = 0
	for teamID,_ in pairs(teamInfo) do
		local cur_max = Spring.GetTeamStatsHistory(teamID)
		local stats = Spring.GetTeamStatsHistory(teamID, 0, cur_max)
		avgTeamDmg = avgTeamDmg + stats[cur_max].damageDealt / coopInfo[teamID].players
		numTeams = numTeams + 1
	end
	avgTeamDmg = avgTeamDmg / (math.max(1,numTeams))
	
	--get other stuff from engine stats
	for teamID,_ in pairs(teamInfo) do
		local cur_max = Spring.GetTeamStatsHistory(teamID)
		local stats = Spring.GetTeamStatsHistory(teamID, 0, cur_max)
		teamInfo[teamID].dmgDealt = teamInfo[teamID].dmgDealt + stats[cur_max].damageDealt	
		teamInfo[teamID].ecoUsed = teamInfo[teamID].ecoUsed + stats[cur_max].energyUsed + 60 * stats[cur_max].metalUsed
		if teamInfo[teamID].unitsCost > 175000 then 
			teamInfo[teamID].dmgRatio = teamInfo[teamID].dmgDealt / teamInfo[teamID].unitsCost * 100
		else
			teamInfo[teamID].dmgRatio = 0
		end
		teamInfo[teamID].dmgRec = stats[cur_max].damageReceived
		teamInfo[teamID].ecoProd = stats[cur_max].energyProduced + 60 * stats[cur_max].metalProduced
	end

	--take account of coop
	for teamID,_ in pairs(teamInfo) do
		teamInfo[teamID].ecoDmg = teamInfo[teamID].ecoDmg / coopInfo[teamID].players
		teamInfo[teamID].fightDmg = teamInfo[teamID].fightDmg / coopInfo[teamID].players
		teamInfo[teamID].otherDmg = teamInfo[teamID].otherDmg / coopInfo[teamID].players
		teamInfo[teamID].dmgRec = teamInfo[teamID].dmgRec / coopInfo[teamID].players 
		teamInfo[teamID].dmgRatio = teamInfo[teamID].dmgRatio / coopInfo[teamID].players
	end
	
	
	--award awards
	local ecoKillAward, ecoKillAwardSec, ecoKillAwardThi, ecoKillScore, ecoKillScoreSec, ecoKillScoreThi = -1,-1,-1,0,0,0
	local fightKillAward, fightKillAwardSec, fightKillAwardThi, fightKillScore, fightKillScoreSec, fightKillScoreThi = -1,-1,-1,0,0,0
	local effKillAward, effKillAwardSec, effKillAwardThi, effKillScore, effKillScoreSec, effKillScoreThi = -1,-1,-1,0,0,0
	local ecoAward, ecoScore = -1,0
	local dmgRecAward, dmgRecScore = -1,0
	local sleepAward, sleepScore = -1,0
	for teamID,_ in pairs(teamInfo) do	
		--deal with sleep times
		local curTime = Spring.GetGameSeconds()
		if (curTime - teamInfo[teamID].lastKill > teamInfo[teamID].sleepTime) then
			teamInfo[teamID].sleepTime = curTime - teamInfo[teamID].lastKill
		end
		--eco killing award
		if ecoKillScore < teamInfo[teamID].ecoDmg then
			ecoKillScoreThi = ecoKillScoreSec
			ecoKillAwardThi = ecoKillAwardSec
			ecoKillScoreSec = ecoKillScore
			ecoKillAwardSec = ecoKillAward
			ecoKillScore = teamInfo[teamID].ecoDmg
			ecoKillAward = teamID
		elseif ecoKillScoreSec < teamInfo[teamID].ecoDmg then
			ecoKillScoreThi = ecoKillScoreSec
			ecoKillAwardThi = ecoKillAwardSec
			ecoKillScoreSec = teamInfo[teamID].ecoDmg
			ecoKillAwardSec = teamID
		elseif ecoKillScoreThi < teamInfo[teamID].ecoDmg then
			ecoKillScoreThi = teamInfo[teamID].ecoDmg
			ecoKillAwardThi = teamID		
		end
		--fight killing award
		if fightKillScore < teamInfo[teamID].fightDmg then
			fightKillScoreThi = fightKillScoreSec
			fightKillAwardThi = fightKillAwardSec
			fightKillScoreSec = fightKillScore
			fightKillAwardSec = fightKillAward
			fightKillScore = teamInfo[teamID].fightDmg
			fightKillAward = teamID
		elseif fightKillScoreSec < teamInfo[teamID].fightDmg then
			fightKillScoreThi = fightKillScoreSec
			fightKillAwardThi = fightKillAwardSec
			fightKillScoreSec = teamInfo[teamID].fightDmg
			fightKillAwardSec = teamID
		elseif fightKillScoreThi < teamInfo[teamID].fightDmg then
			fightKillScoreThi = teamInfo[teamID].fightDmg
			fightKillAwardThi = teamID		
		end
		--efficiency ratio award
		if effKillScore < teamInfo[teamID].dmgRatio then
			effKillScoreThi = effKillScoreSec
			effKillAwardThi = effKillAwardSec
			effKillScoreSec = effKillScore
			effKillAwardSec = effKillAward
			effKillScore = teamInfo[teamID].dmgRatio 
			effKillAward = teamID
		elseif effKillScoreSec < teamInfo[teamID].dmgRatio then
			effKillScoreThi = effKillScoreSec
			effKillAwardThi = effKillAwardSec
			effKillScoreSec = teamInfo[teamID].dmgRatio 
			effKillAwardSec = teamID
		elseif effKillScoreThi < teamInfo[teamID].dmgRatio then
			effKillScoreThi = teamInfo[teamID].dmgRatio 
			effKillAwardThi = teamID		
		end
		
		--eco prod award
		if ecoScore < teamInfo[teamID].ecoProd then
			ecoScore = teamInfo[teamID].ecoProd
			ecoAward = teamID		
		end
		--most damage rec award
		if dmgRecScore < teamInfo[teamID].dmgRec then
			dmgRecScore = teamInfo[teamID].dmgRec
			dmgRecAward = teamID		
		end
		--longest sleeper award
		if sleepScore < teamInfo[teamID].sleepTime and teamInfo[teamID].sleepTime > 12*60 then
			sleepScore = teamInfo[teamID].sleepTime
			sleepAward = teamID		
		end
	end	
	
	--is the cow awarded?
	local cowAward = -1
	if ecoKillAward ~= -1 and (ecoKillAward == fightKillAward) and (fightKillAward == effKillAward) and ecoKillAward ~= -1 then --check if some team got all the awards
		if winningAllyTeams and winningAllyTeams[1] then
			local won = false
			local _,_,_,_,_,cowAllyTeamID = Spring.GetTeamInfo(ecoKillAward)
			for _,allyTeamID in pairs(winningAllyTeams) do
				if cowAllyTeamID == allyTeamID then --check if this team won the game
					cowAward = ecoKillAward 
					break
				end
			end
		end
	end

	
	--tell unsynced
	SendToUnsynced("ReceiveAwards", ecoKillAward, ecoKillAwardSec, ecoKillAwardThi, ecoKillScore, ecoKillScoreSec, ecoKillScoreThi, 
									fightKillAward, fightKillAwardSec, fightKillAwardThi, fightKillScore, fightKillScoreSec, fightKillScoreThi, 
									effKillAward, effKillAwardSec, effKillAwardThi, effKillScore, effKillScoreSec, effKillScoreThi, 
									ecoAward, ecoScore, 
									dmgRecAward, dmgRecScore, 
									sleepAward, sleepScore,
									cowAward)
                                    	
end




-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
else  -- UNSYNCED
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function gadget:Initialize()
	gadgetHandler:AddSyncAction("ReceiveAwards", ReceiveAwards)	
end

function ReceiveAwards (_,ecoKillAward, ecoKillAwardSec, ecoKillAwardThi, ecoKillScore, ecoKillScoreSec, ecoKillScoreThi, 
						fightKillAward, fightKillAwardSec, fightKillAwardThi, fightKillScore, fightKillScoreSec, fightKillScoreThi, 
						effKillAward, effKillAwardSec, effKillAwardThi, effKillScore, effKillScoreSec, effKillScoreThi, 
						ecoAward, ecoScore, 
						dmgRecAward, dmgRecScore, 
						sleepAward, sleepScore,
						cowAward)
                        

                        
    --record who won which awards in chat message (for demo parsing by replays.springrts.com)
	--make all values positive, as unsigned ints are easier to parse
	local ecoKillLine    = '\161' .. tostring(1+ecoKillAward) .. ':' .. tostring(ecoKillScore) .. '\161' .. tostring(1+ecoKillAwardSec) .. ':' .. tostring(ecoKillScoreSec) .. '\161' .. tostring(1+ecoKillAwardThi) .. ':' .. tostring(ecoKillScoreThi)  
	local fightKillLine  = '\162' .. tostring(1+fightKillAward) .. ':' .. tostring(fightKillScore) .. '\162' .. tostring(1+fightKillAwardSec) .. ':' .. tostring(fightKillScoreSec) .. '\162' .. tostring(1+fightKillAwardThi) .. ':' .. tostring(fightKillScoreThi)
	local effKillLine    = '\163' .. tostring(1+effKillAward) ..  ':' .. tostring(effKillScore) .. '\163' .. tostring(1+effKillAwardSec) .. ':' .. tostring(effKillScoreSec) .. '\163' .. tostring(1+effKillAwardThi) .. ':' .. tostring(effKillScoreThi)
	local otherLine      = '\164' .. tostring(1+cowAward) .. '\165' ..  tostring(1+ecoAward) .. ':' .. tostring(ecoScore).. '\166' .. tostring(1+dmgRecAward) .. ':' .. tostring(dmgRecScore) ..'\167' .. tostring(1+sleepAward) .. ':' .. tostring(sleepScore)
	local awardsMsg = ecoKillLine .. fightKillLine .. effKillLine .. otherLine
	Spring.SendLuaRulesMsg(awardsMsg)
    
    ---tell widgetland
    if Script.LuaUI("ReceiveAwards") then
        Script.LuaUI.ReceiveAwards( ecoKillAward, ecoKillAwardSec, ecoKillAwardThi, ecoKillScore, ecoKillScoreSec, ecoKillScoreThi, 
									fightKillAward, fightKillAwardSec, fightKillAwardThi, fightKillScore, fightKillScoreSec, fightKillScoreThi, 
									effKillAward, effKillAwardSec, effKillAwardThi, effKillScore, effKillScoreSec, effKillScoreThi, 
									ecoAward, ecoScore, 
									dmgRecAward, dmgRecScore, 
									sleepAward, sleepScore,
									cowAward)
    end
end


function gadget:ShutDown()
	gadgetHandler:RemoveSyncAction("ReceiveAwards")	
end

end

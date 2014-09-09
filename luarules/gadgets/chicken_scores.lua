function gadget:GetInfo()
  return {
    name      = "BA Chicken Scores",
    desc      = "Shows Scores at the end of the game",
    author    = "TheFatController/quantum/abma",
    date      = "26. Feb. 2012",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true --  loaded by default?
  }
end

if (gadgetHandler:IsSyncedCode()) then

local enabled = tonumber(Spring.GetModOptions().mo_chickengame) or 0
if (enabled == 0) then 
  return false
end
  
local function dump(o)
	if type(o) == 'table' then
		local s = '{ '
		for k,v in pairs(o) do
			if type(k) ~= 'number' then k = '"'..k..'"' end
			s = s .. '['..k..'] = ' .. dump(v) .. ',\n'
		end
			return s .. '} '
		else
			return tostring(o)
	end
end

local function getTeams()
	local teams = {}
	local teamlist = Spring.GetTeamList()
	for _, teamID in ipairs(teamlist) do
		local name = Spring.GetPlayerInfo(teamID)
		if not name then
			info = Spring.GetAIInfo(teamID)
			if info then
--				Spring.Echo(dump(info))
				name = "AI"
			end
		end
		teams[teamID] =  name 

	end
	--Spring.Echo(dump(teams))
	return teams
end

local teamInfo = getTeams()

--local bonusPoints = 1
--local burrowDef = UnitDefNames["roost"] --unitdef for burrow, used for bonus points
--function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
--	if (unitDefID == burrowDef) then
--		bonusPoints = (bonusPoints + 2500)    
--	end
--end

local function CalculateScores(humanTeams)
	local totalDamage = 0
	local teamScores = {}
	local totalScore = 0
	for teamID in pairs(humanTeams) do
		Spring.Echo("Getting Score: " ..tostring(teamID))
		local max = Spring.GetTeamStatsHistory(teamID)
		stats = Spring.GetTeamStatsHistory(teamID, 0, max)
--		Spring.Echo(dump(stats))
		teamScores[teamID] = stats[max].damageDealt
		totalDamage = totalDamage + teamScores[teamID]
--		Spring.Echo("TotalDamage: "..tostring(totalDamage))
		local teamUnits = Spring.GetTeamUnits(teamID)
		for _, unitID in pairs(teamUnits) do
			local defID = Spring.GetUnitDefID(unitID)
			if defID then
				totalScore = totalScore + UnitDefs[defID].metalCost
				totalScore = totalScore + (UnitDefs[defID].energyCost / 50)
			end
		end
	end
	for teamID in pairs(humanTeams) do
		teamScores[teamID] = math.ceil(teamScores[teamID])
	end
--	Spring.Echo(dump(teamScores))
	return teamScores
end

local function comma_value(amount)
	local formatted = amount
	while true do  
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
		if (k==0) then
			break
		end
	end
	return formatted
end


local function DisplayScores(scoreList)
	Spring.Echo("           ")
	Spring.Echo("Team Scores")
	Spring.Echo("-----------")
--	Spring.Echo(dump(scoreList))
	
	for teamID, teamScore in pairs(scoreList) do
		local name = "Unknown"
--		Spring.Echo(dump(teamInfo))
		name = teamInfo[teamID]
		Spring.Echo("Team" .. teamID .. ": " ..name .. " : " .. comma_value(teamScore) .. " Points")
	end
end
local function showScore()
	local endScores = CalculateScores(teamInfo)
	DisplayScores(endScores)
	for i,v in pairs(endScores) do
		SendToUnsynced("ChickenEvent", "score"..i, v)
	end
end

--function gadget:GameFrame(n)
--	if n % 100 == 0 then
--		showScore()
--	end
--end

function gadget:GameOver()
	if not showScoresOnce then
		showScore()
		showScoresOnce = true
	end
end

end

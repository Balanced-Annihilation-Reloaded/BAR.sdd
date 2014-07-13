function widget:GetInfo()
	return {
		name    = 'Awards',
		desc    = 'Awards awards!',
		author  = 'Funkencool, Bluestone',
		date    = 'July 2014',
		license = 'GNU GPL v2',
		layer   = 0,
		enabled = true
	}
end

--[[                HOW AWARDS WORK
    
 >> Normal Awards

These ones get a 1st, 2nd and 3rd place which are included in that order in the LuaMsg.

ecoKillAward is for killing the most enemy econ production. fightKillAward is for killing 
the most enemy fighting stuff. effKillAward is for the best damage 
done <-> resources used ratio. The gadget has a mechanism that tries to account for 
taking/sharing.

 >> Special Awards

These awards are won by a single team; there is no first/second/third.

The CowAward ("Memorial WarCow") is given to a team that wins (first place in) all three normal 
awards. It's quite hard to win a WarCow.

There are three other special awards: ecoAward  (most eco produced), dmgRecAward (most damage taken) 
and sleepAward (not doing damage for longest). The sleepAward counts time not doing damage even 
after a teams death; it is often won by someone who did something stupid and died very early.

 >> Pictures

The three KillAwards and the CowAward have pictures associated to them which you can find 
in /luaui/images/awards. The other awards are in some sense less important and don't have pictures.
 
 >> TeamIDs, playerIDs, playerNames

For all awards, they are only awarded when particular criteria are met so there is always the 
chance that the award is not given to anyone. The awards gadget assigns awards to teams, so the numbers you 
receive are the teamIDs of team(s) who won that award and (if appropriate) the corresponding score.

Of course, what then appears on screen are the names of players who won. The correspondance is: 
for each teamID the gadget looks for a playerID of a player who was not a spectator at GameStart 
(recall specs are put in team 0, which also contains some genuine players). The first such playerID 
found is used to name the player who gets the award. If more than one such playerID is found 
then .. " (coop)" is added to the players name.    

Please put this documentation somewhere sensible when you are done with the example widget! 
    
]]

local playerListByTeam = {}

function colourNames(teamID)
		if teamID < 0 then return "" end
    	nameColourR,nameColourG,nameColourB,nameColourA = Spring.GetTeamColor(teamID)
		R255 = math.floor(nameColourR*255)  --the first \255 is just a tag (not colour setting) no part can end with a zero due to engine limitation (C)
        G255 = math.floor(nameColourG*255)
        B255 = math.floor(nameColourB*255)
        if ( R255%10 == 0) then
                R255 = R255+1
        end
        if( G255%10 == 0) then
                G255 = G255+1
        end
        if ( B255%10 == 0) then
                B255 = B255+1
        end
	return "\255"..string.char(R255)..string.char(G255)..string.char(B255) --works thanks to zwzsg
end 

function FindPlayerName(teamID)
	local plList = playerListByTeam[teamID]
	local name 
	if plList[1] then
		name = plList[1]
		if #plList > 1 then
			name = name .. " (coop)"
		end
	else
		name = "(unknown)"
	end

	return colourNames(teamID) .. name .. "\255\255\255\255"
end

function round(num, idp)
  return string.format("%." .. (idp or 0) .. "f", num)
end

function widget:Initialize()
    widgetHandler:RegisterGlobal('ReceiveAwards', ReceiveAwards)
    
    --load a list of players for each team into playerListByTeam
	local teamList = Spring.GetTeamList()
	for _,teamID in pairs(teamList) do
		local playerList = Spring.GetPlayerList(teamID)
		local list = {} --without specs
		for _,playerID in pairs(playerList) do
			local name, _, isSpec = Spring.GetPlayerInfo(playerID)
			if not isSpec then
				table.insert(list, name)
			end
		end
		playerListByTeam[teamID] = list
	end
end

function widget:ShutDown()
    widgetHandler:DeregisterGlobal('ReceiveAwards')
end

function widget:GameOver()
	Spring.SendCommands('endgraph 0')	
end

-- this function will be magically called just after gameover
-- you need at least two teams in a game to test awards (otherwise the game does not ever end)
-- simplest way is to make a short replay with $VERSION and use that for testing
function ReceiveAwards( ecoKillAward, ecoKillAwardSec, ecoKillAwardThi, ecoKillScore, ecoKillScoreSec, ecoKillScoreThi, 
						fightKillAward, fightKillAwardSec, fightKillAwardThi, fightKillScore, fightKillScoreSec, fightKillScoreThi, 
						effKillAward, effKillAwardSec, effKillAwardThi, effKillScore, effKillScoreSec, effKillScoreThi, 
						ecoAward, ecoScore, 
						dmgRecAward, dmgRecScore, 
						sleepAward, sleepScore,
						cowAward)
    --

    Spring.Echo("Recieved awards")
    -- normal award example
    -- do likewise for second/third place (not all places may be awarded)
    if ecoKillAward > 0 then
        Spring.Echo("ecoKillAward was won by " .. FindPlayerName(ecoKillAward) .. " with a score of " .. round(ecoKillScore))
    else
        Spring.Echo("ecoKillAward was not awarded")
    end
    -- special award example
    if ecoAward > 0 then
        Spring.Echo("ecoAward was won by " .. FindPlayerName(ecoAward) .. " with a score of " .. round(ecoScore))
    else
        -- nothing
    end
    -- cow award example
    if cowAward > 0 then
        Spring.Echo("A memorial WarCow was won by " .. FindPlayerName(cowAward))
    else
        -- nothing
    end
end

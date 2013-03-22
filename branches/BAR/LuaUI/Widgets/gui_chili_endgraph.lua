--[[
	TO DO:
		Add amount label when mouseover line on graph (e.g to see exact metal produced at a certain time),
		Implement camera control to pan in the background while viewing graph,
		Add minimize option
		Come up with better way of handling specs, active players and players who died (currently doesn't show players who have died
	
	Graph Ideas:
		Total metal in units and/or buildings
		Total metal in units/# of units, (Average cost of units)
		Metal spent - damage recieved = total metal in units?
		
]]
function widget:GetInfo()
	return {
		name		    = "EndGame Stats",
		desc		    = "v0.7 Chili replacement for default end game statistics",
		author		  = "Funkencool",
		date		    = "2013",
		license     = "public domain",
		layer		    = math.huge,
		enabled   	= true
	}
end

local testing = false
-- INCLUDES

--comment out any stats you don't want included, order also directly effects button layout.. [1] = engineName, [2] = Custom Widget Name (can change)
local engineStats = {
	--{"time"            , "time"},
	-- {"frame"           , ""},
	{"metalUsed"       , "Metal Used"},
	{"metalProduced"   , "Metal Produced"},
	--{"metalExcess"     , "Metal Excess"},
	-- {"metalReceived"   , ""},
	-- {"metalSent"       , ""},
	{"energyUsed"      , "Energy Used"},
	{"energyProduced"  , "Energy Produced"},
	--{"energyExcess"    , "Energy Excess"},
	-- {"energyReceived"  , ""},
	-- {"energySent"      , ""},
	{"damageDealt"     , "Damage Dealt"},
	--{"damageReceived"  , "Damage Received"},
	{"unitsProduced"   , "Units Built"},
	{"unitsKilled"     , "Units Killed"},
	--{"unitsDied"       , "Units Lost"},
	-- {"unitsReceived"   , ""},
	-- {"unitsSent"       , ""},
	-- {"unitsCaptured"   , ""},
	-- {"unitsOutCaptured", ""},
}

local customStats = {
-- {external_dataArray, "button label"},
[[Not Implemented yet:
	I organize the engine stats in this widget but custom will have to be handled by themselves
  Probably in a dataArray = {player1_array = {data}, player2_array = {data}} ]]
}

-- CONSTANTS
local chiliConst = {
--	borderColor = {0,0,0,0}
	}
-- CHILI CONTROLS
local Chili
local window0 	
local graphPanel 
local graphSelect
local graphLabel
local wasActive = {}
local playerNames = {}

--formats final stat to fit in label 
local function numFormat(label)
	local string
	if label/1000000 > 1 then
		label =  math.floor(label/1000000)
		string = label .. "M"
	elseif label/1000 > 1 then
		label = math.floor(label/1000)
		string = label .. "k"
	else
	string = math.floor(label) .. ""
	end
	return string
end

--Total package of graph: Draws graph and labels for each nonSpec player
local function drawGraph(graphArray, graph_m, teamID)
	--get's all the needed info about players and teams
	local _,teamLeader,_,isAI = Spring.GetTeamInfo(teamID)
	local playerName, isActive, isSpec = Spring.GetPlayerInfo(teamLeader)
	local r,g,b,a = Spring.GetTeamColor(teamID)
	local teamColor = {r,g,b,a}
	local lineLabel = numFormat(graphArray[#graphArray])
	local shortName
	

	
	--Sets AI name to reflect AI used and player hosting it
	if isAI then
		local _,botID,_,shortName = Spring.GetAIInfo(teamID)
		playerName = shortName .."-" .. botID .. ""
	end
	
	--Make so once on graph always on graph
	if isActive then wasActive[teamID] = isActive end
	if not playerNames[teamID] then playerNames[teamID] = playerName else playerName = playerNames[teamID] end
	
	if isActive or wasActive[teamID] then --should be if NOT isSpec, but works? Prevents specs from being included in Graph
		for i=1, #graphArray do
			if (graph_m < graphArray[i]) then graph_m = graphArray[i] end
		end	
		
		--gets vertex's from array and plots them
		local drawLine = function()		
			for i=1, #graphArray do
				local ordinate = graphArray[i]
				gl.Vertex((i - 1)/(#graphArray - 1), 1 - ordinate/graph_m)
			end
		end
		
		--adds value to end of graph
		local label1 = Chili.Label:New{parent = lineLabels, y = (1 - graphArray[#graphArray]/graph_m) * 88 - 1 .. "%", width = "100%", caption = lineLabel, font = {color = teamColor}}
		
		--adds player to Legend
		local label2 = Chili.Label:New{parent = graphPanel, x = 10, y = (teamID)*20 + 5, width = "100%", height  = 20, caption = playerName, font = {color = teamColor}}
		
		--creates graph element
		local graph = Chili.Control:New{
			parent	= graphPanel,
			x       = 0,
			y       = 0,
			height  = "100%",
			width   = "100%",
			padding = {0,0,0,0},
			DrawControl = function (obj)
				local x = obj.x
				local y = obj.y
				local w = obj.width
				local h = obj.height
				
				gl.Color(teamColor)
				gl.PushMatrix()
				gl.Translate(x, y, 0)
				gl.Scale(w, h, 1)
				gl.LineWidth(3)
				gl.BeginEnd(GL.LINE_STRIP, drawLine)
				gl.PopMatrix()
			end
			}
	end
end

local function getEngineArrays(statistic, labelCaption)
	local teamScores = {}
	local teams	= Spring.GetTeamList()
	local teams = (#teams - 1)
	local max = Spring.GetTeamStatsHistory(0) - 1
	Spring.Echo(labelCaption)
	
	--Applies label of the selected graph at bottom of window
	graphLabel:SetCaption(labelCaption)

	--finds highest stat out all the player stats, i.e. the highest point of the graph
	local graphMax = 0
	for a=0, teams do
		local stats = Spring.GetTeamStatsHistory(a, 0, max)
		for b=1, max do
			if (graphMax < stats[b][statistic]) then graphMax = stats[b][statistic] end
		end
	end
	
	--Applys each player to graph accordingly
	for a=0, teams do
		local stats = Spring.GetTeamStatsHistory(a, 0, max)
		local teamScores = {}
		for b=1, max do
			teamScores[b] = stats[b][statistic]
		end
		drawGraph(teamScores, graphMax, a)
	end
end

-- Starting point: Draws all the main elements which are later tailored
function loadpanel()

	Chili = WG.Chili
	local screen0 = Chili.Screen0
	local selW  = 150
	window0 		= Chili.Window:New{parent = screen0, x = "20%", y = "20%", width = "60%", height = "60%", padding = {5,5,5,5}}
	
	lineLabels 	= Chili.Control:New{parent = window0, right = 0, y = 0, width = 37, height = "100%", padding = {0,0,0,0},}
	graphSelect	= Chili.StackPanel:New{minHeight = 70, parent = window0, x =  0, y = 0, width = selW, height = "100%",}
	graphPanel 	= Chili.Panel:New{parent = window0, x = selW, right = 30, y = 0, height = "90%", padding = {10,10,10,10}}
	graphLabel  = Chili.Label:New{autosize = true, parent = window0, bottom = 0,caption = "", align = "center", width = "70%", x = "20%", height = "10%", font = {size = 30,},}
	
	for a=1, #engineStats do
		local engineButton =	Chili.Button:New{name = engineStats[a][1], caption = engineStats[a][2], maxHeight = 30, parent = graphSelect, OnClick = {function(obj) graphPanel:ClearChildren();lineLabels:ClearChildren();getEngineArrays(obj.name,obj.caption);end},}
	end
	
	local exitButton = Chili.Button:New{name = "exit", caption = "Exit", bottom = 0, right = 0, height = 30, width = 40 , parent = window0, OnClick = {function() Spring.SendCommands("quit");end},}

end

--to do: possible to run from start when playing as spec
function widget:Initialize()
	if testing then
	Spring.SendCommands("endgraph 0")
	loadpanel()
	end
end


function widget:GameOver()
	if not testing then
	Spring.SendCommands("endgraph 0")
	loadpanel()
	end
end

--[[
	TO DO:
		Add amount label when mouseover line on graph (e.g to see exact metal produced at a certain time),
		Implement camera control to pan in the background while viewing graph,
		Add minimize option
		Come up with better way of handling specs, active players and players who died
		Write gadget to collect statistics
	
	Graph Ideas:
		Total metal in units and/or buildings
		Total metal in units/# of units, (Average cost of units)
		Metal spent - damage recieved = total metal in units?
	
]]
function widget:GetInfo()
	return {
		name    = 'Funks EndGame Stats',
		desc    = 'Chili replacement for default end game statistics',
		author  = 'Funkencool',
		date    = '2013',
		license = 'GNU GPL v2',
		layer   = 0,
		enabled = true
	}
end

--comment out any stats you don't want included, order also directly effects button layout.. { [1] = engineName, [2] = CustomCaption } 
local engineStats = {
	--{'time'            , 'time'},
	--{'frame'           , ''},
	{'metalUsed'       , 'Metal Used'},
	{'metalProduced'   , 'Metal Produced'},
	--{'metalExcess'     , 'Metal Excess'},
	--{'metalReceived'   , ''},
	--{'metalSent'       , ''},
	{'energyUsed'      , 'Energy Used'},
	{'energyProduced'  , 'Energy Produced'},
	--{'energyExcess'    , 'Energy Excess'},
	--{'energyReceived'  , ''},
	--{'energySent'      , ''},
	{'damageDealt'     , 'Damage Dealt'},
	--{'damageReceived'  , 'Damage Received'},
	{'unitsProduced'   , 'Units Built'},
	{'unitsKilled'     , 'Units Killed'},
	--{'unitsDied'       , 'Units Lost'},
	--{'unitsReceived'   , ''},
	--{'unitsSent'       , ''},
	--{'unitsCaptured'   , ''},
	--{'unitsOutCaptured', ''},
}

local gameOver = Spring.IsGameOver() or Spring.GetSpectatingState()
local isDelta  = false
local curGraph = {}
local button = {}

-- Chili vars
local Chili, control0, graphPanel, graphSelect, graphLabel, graphTime
-------------

------------------------------------
--formats final stat to fit in label
local function numFormat(label)
	local number = math.floor(label)
	local string = ''
	if number/1000000000 >= 1 then
		string = string.sub(number/1000000000 .. '', 0, 4) .. 'B'
	elseif number/1000000 >= 1 then
		string = string.sub(number/1000000 .. '', 0, 4) .. 'M'
	elseif number/10000 >= 1 then
		string = string.sub(number/1000 .. '', 0, 4) .. 'k'
	else
		string = math.floor(number) .. ''
	end
	return string
end

local function formatTime(seconds)
	local minutes = math.floor(seconds/60)
	local seconds = seconds % 60
	return '\255\255\127\0'..minutes..'\bmin, '..'\255\255\127\0'..seconds..'\bsec'
end

local function drawIntervals(graphMax)
	for i=1, 4 do
		local line = Chili.Line:New{
			parent = graphPanel,
			x      = 0,
			bottom = (i)/5*100 .. '%', 
			width  = '100%',
		}
		local label = Chili.Label:New{
			parent  = graphPanel,
			x       = 0, 
			bottom  = (i)/5*100+2 .. '%', 
			width   = '100%',
			caption = numFormat(graphMax*i/5),
		}
	end
end

local function fixLabelAlignment()
	local doAgain
	for a=1, #lineLabels.children do
		for b=a+1, #lineLabels.children do
			if lineLabels.children[a].y >= lineLabels.children[b].y and lineLabels.children[a].y < lineLabels.children[b].y+20 then
				lineLabels.children[a]:SetPos(0, lineLabels.children[b].y+20)
				doAgain = false
			end end end
			if doAgain then fixLabelAlignment() end
end

------------------------------------------------------------------------
--Total package of graph: Draws graph and labels for each nonSpec player
local function drawGraphPanel(teamStatArray, graphMax, teamID)
	
	-- All the needed info about players and numTeams
	local _,teamLeader,isDead,isAI     = Spring.GetTeamInfo(teamID)
	local playerName, isActive, isSpec = Spring.GetPlayerInfo(teamLeader)
	local playerRoster                 = Spring.GetPlayerRoster()
	local r,g,b,a                      = Spring.GetTeamColor(teamID)
	local teamColor                    = {r,g,b,a}
	local lineLabel                    = numFormat(teamStatArray[#teamStatArray])
	local graphMax                     = graphMax
	local shortName
	
	-- Prevents specs from being included in Graph
	if not ( isActive or isDead ) then return end
	
	-- Sets AI name to reflect AI used and player hosting it
	if isAI then
		local _,botID,_,shortName = Spring.GetAIInfo(teamID)
		playerName = shortName ..'-' .. botID .. ''
	end
	
	-- Gets vertex's from array and plots them
	local drawLine = function()
		for i=1, #teamStatArray do
			local ordinate = teamStatArray[i]
			gl.Vertex((i - 1)/(#teamStatArray - 1), 1 - ordinate/graphMax)
		end
	end
	
	-- Adds value to end of graph
	Chili.Button:New{
		parent  = lineLabels,
		bottom  = teamStatArray[#teamStatArray]/graphMax * 90 .. '%',
		width   = '100%',
		caption = lineLabel,
		font    = {
			color        = teamColor, 
			outlineColor = {0,0,0,1},
		},
	}
	
	-- Adds player to Legend
	Chili.Label:New{
		parent  = graphPanel,
		x       = 55,
		y       = (teamID)*20 + 5,
		width   = '100%',
		height  = 20,
		caption = playerName,
		font    = {
			color        = teamColor, 
			outlineColor = {1,1,1,0.1},
		},
	}
	
	-- Creates graph element with custom drawcontrol for the lines in the graph
	local graph = Chili.Control:New{
		parent        = graphPanel,
		x             = 0,
		y             = 0,
		height        = '100%',
		width         = '100%',
		padding       = {0,0,0,0},
		drawcontrolv2 = true,
		DrawControl   = function (obj)
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


----------------------------------------------------------------
----------------------------------------------------------------
local function getEngineArrays(statName, graphLength)
	local numTeams    = #Spring.GetTeamList() - 1

	
	-- Finds highest stat out all the player stats, i.e. the highest point of the graph
	local statArrays = {}
	local graphMax   = 0
	
	for TeamID = 0, numTeams do
		local teamStatArray = {}
		
		-- GetTeamStatsHistory() is synced so  being a spec or gameOver is required to work
		local stats = Spring.GetTeamStatsHistory(TeamID, 0, graphLength)
		
    -- subtract one from graphlength for delta (should do it a better way)
		for i=1, graphLength - 1 do
			-- 
			teamStatArray[i] = stats[i][statName]
			
			if isDelta then
				teamStatArray[i] = ( stats[i+1][statName] - teamStatArray[i] )
			end
			
			if ( teamStatArray[i] > graphMax ) then 
				graphMax = teamStatArray[i] 
			end 
			
		end
		statArrays[TeamID] = teamStatArray
	end
	
	if graphMax > 5 then drawIntervals(graphMax) end
	
	for TeamID=0, numTeams do
		drawGraphPanel(statArrays[TeamID], graphMax, TeamID) --Applies per player elements
	end
	
-- TODO: check to see if team has any stats. If not, don't show	
end

------------------------
local function replaceGraph(obj)
	
	local obj = obj or curGraph
	graphPanel:ClearChildren()
	lineLabels:ClearChildren()
	
	local graphLength = Spring.GetTeamStatsHistory(0) - 1
	local gameTime    = Spring.GetTeamStatsHistory(0, 0, graphLength)
	local gameTime    = gameTime[graphLength]['time']
	
	-- Applies label of the selected graph at bottom of window
	graphLabel:SetCaption(obj.caption)
	graphTime:SetCaption('Total Time: ' .. formatTime(gameTime))
	curGraph.caption = obj.caption
	curGraph.name    = obj.name
	
	getEngineArrays(curGraph.name, graphLength)
	
	fixLabelAlignment()
end

-----------------------------------------------------------------------
-- Starting point: Draws all the main elements which are later tailored
function loadWindow()
	
	Chili = WG.Chili
	local screen0 = Chili.Screen0
	local selW  = 150
	
	control0 = Chili.Control:New{
		x       = 0,
		y       = 0, 
		right   = 0, 
		bottom  = 0,
		padding = {5,5,5,5},
	}

	graphSelect = Chili.StackPanel:New{
		parent    = control0,
		width     = selW,
		minHeight = 70,
		x         = 0,
		y         = '10%',
		bottom    = 0,
	}
	
	graphPanel = Chili.Control:New{
		parent  = control0,
		x       = selW,
		height  = '90%',
		right   = 40,
		bottom  = 0,
	}	
	
	lineLabels = Chili.Control:New{
		parent  = control0,
		right   = 0,
		width   = 40,
		y       = 0,
		bottom  = 0,
		padding = {0,0,0,0},
	}
	
	graphLabel = Chili.Label:New{
		parent   = control0,
		x        = 0,
		y        = 0,
		caption  = '',
		font     = {size = 30,},
	}
	
	graphTime = Chili.Button:New{
		parent  = control0,
		caption = '',
		y       = 0,
		right   = 0,
		height  = 20,
		width   = 200,
	}
	
	for a=1, #engineStats do
		button[a] = Chili.Button:New{
			parent    = graphSelect,
			name      = engineStats[a][1],
			caption   = engineStats[a][2],
			maxHeight = 30,
			OnClick   = {replaceGraph},
		}
	end
	
	Chili.Checkbox:New{
		caption  = 'Delta',
		y        = 10, 
		x        = 250,
		height   = 30, 
		width    = 50,
		parent   = control0,
		checked  = false,
		OnChange = {
			function()
				isDelta = not isDelta
				if curGraph.name then
					replaceGraph()
				end
			end
		},
	}
	
	replaceGraph(button[1])
	WG.BarMenu.AddControl('Graph', control0)
	WG.BarMenu.ShowHide('Graph')
end

--to do: possible to run from start when playing as spec
function widget:Initialize()
	local testing = false
	Spring.SendCommands('endgraph 0')
	if gameOver or testing then loadWindow() end
end

function widget:Shutdown()
	Spring.SendCommands('endgraph 1')
end

function widget:GameOver()
	loadWindow()
	gameOver = true
end

function widget:GetInfo()
    return {
        name    = 'Skirmish Setup',
        desc    = 'Allows selection of skirmish AI and map',
        author  = 'Funkencool',
        date    = '2016',
        license = 'GNU GPL v2',
        layer   = 0,
        enabled = true
    }
end

local Chili, Menu, options
local Settings = {}
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
-- Intialize --
----------------------------------------------------------------------------------------

function ScriptTXT(script)
  local string = '[Game]\n{\n\n'

  -- First write Tables
  for key, value in pairs(script) do
    if type(value) == 'table' then
      string = string..'\t['..key..']\n\t{\n'
      for key, value in pairs(value) do
        string = string..'\t\t'..key..' = '..value..';\n'
      end
      string = string..'\t}\n\n'
    end
  end

  -- Then the rest (purely for aesthetics)
  for key, value in pairs(script) do
    if type(value) ~= 'table' then
      string = string..'\t'..key..' = '..value..';\n'
    end
  end
  string = string..'}'

  local txt = io.open('script.txt', 'w+')
  txt:write(string)
	txt:close()
  return string
end
    
local sideImage = function(side, color)
	local image = Chili.Image:New{
		x = 0, y = 0, right = 0, bottom = 0,
		file = 'LuaUI/Images/buildIcons/'..side..'.dds',
		children = {
			Chili.Image:New{
				color = color,
				x = 0, y = 0, right = 0, bottom = 0,
				file = 'LuaUI/Images/buildIcons/'..side..'_Overlay.dds',
			}
		}
	}
	return image
end
    
local getLayout = function(AI)
	local layout = Chili.Control:New{
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		padding = {0,0,0,0},
		children = {
			Chili.Label:New{
				caption = 'Name',
				fontsize = 20,
				x = 5,
				y = 10,
				width = '100%',
			},
			Chili.EditBox:New{
				x = 20,
				right = 20,
				y = 30,
				height = 30,
				text = AI.name,
				OnFocusUpdate = {
					function(self)
						AI.name = self.text
					end
				}
			},
			Chili.Label:New{
				y = 64,
				x = 5,
				width = '100%',
				caption = 'Side',
				fontsize = 20,
			},
			Chili.Button:New{
				y = 90,
				x = 5,
				width = 65,
				height = 65,
				caption = '',
				padding = {0,0,0,0},
				children = {sideImage('ARM', AI.color)},
				OnClick = {
					function()
						AI.side = 'ARM'
						AI:ClearChildren()
						AI:AddChild(sideImage('ARM', AI.color))
					end
				}
			},
			Chili.Button:New{
				y = 90,
				x = 75,
				width = 65,
				height = 65,
				caption = '',
				padding = {0,0,0,0},
				children = {sideImage('CORE', AI.color)},
				OnClick = {
					function()
						AI.side = 'CORE'
						AI:ClearChildren()
						AI:AddChild(sideImage('CORE', AI.color))
					end
				}
			},
			Chili.Colorbars:New{
				x = 5,
				right = 5,
				bottom = 10,
				height = 50,
				color = AI.color,
			},
		}
	}
	return layout
end

local function createUI()
    local Match = Chili.Control:New{
    	name = 'Set Up a Skirmish',
    	x = 0, y = 0, bottom = 0, right = 0,
    	padding = {5,5,5,5},
    	bots = {},
    	botNames = {'Jim','Joe','Fred','Fred Jr.','Steve','John','Greg'},
    	allyTeams = 0,
    	Script = {
    		player0  =  {
    			isfromdemo = 0,
    			name = 'Local',
    			rank = 0,
    			spectator = 1,
    			team = 0,
    		},

    		gametype = 'Balanced Annihilation Reloaded $VERSION',
    		hostip = '127.0.0.1',
    		hostport = 8452,
    		ishost = 1,
    		mapname = Settings['map'] or 'Some Map',
    		myplayername = 'Local',
    		nohelperais = 0,
    		numplayers = 1,
    		numusers = 2,
    		startpostype = 2,
    	}
    }
    -- Adds bots to script table, then starts the game with a generated script
    local function StartScript()
    	if #Match.bots < 1 then AddPlayer() end
    
    	-- it's easier to store and modify objects than table
    	--  so I wait until the end to put bots in the Script (no more changing)
    	for team = 1, #Match.bots do
    		local bot = Match.bots[team]
    		Match.Script['ai' .. team - 1] = {
    			host = 0,
    			isfromdemo = 0,
    			name = bot.name or 'AI',
    			shortname = bot.shortname or 'KAIK',
    			spectator = 0,
    			team = team,
    		}
    
    		Match.Script['team'.. team]  =  {
    			allyteam = bot.allyTeam,
    			rgbcolor = ''..bot.color[1]..' '..bot.color[2]..' '..bot.color[3],
    			side = bot.side,
    			teamleader = 0,
    		}
    
    		if not Match.Script['allyteam' .. bot.allyTeam] then
    			Match.Script['allyteam' .. bot.allyTeam]  =  {
    				numallies = 0,
    			}
    		end
    	end
    
    	Spring.Reload(ScriptTXT(Match.Script))
    end

    
    
    -- Attaches random profile and config layout to Button obj
    -- Essentially turns Button obj into AI obj
    local attachProfile = function(self)
    
    	self.name = Match.botNames[math.random(5)]
    	self.team = #Match.bots + 1
    	self.color = {math.random(),math.random(),math.random(),1}
    	self.side = math.random(10) > 5 and 'CORE' or 'ARM'
      self.shortname  = 'KAIK'
    	self.caption = self.name
    	-- self:AddChild(sideImage(self.side, self.color))
    	self.width = 50
    	self.height = 50
      
      self.layout  = getLayout(self)
    	-- create a replacement 'Add AI' button
    	self.parent:AddChild(Chili.Button:New{
    		x = self.x + 55,
    		y = 0,
    		height = 40,
    		width = 40,
    		padding = {0,0,0,0},
    		allyTeam = self.allyTeam,
    		caption = 'Add\n AI',
    		OnClick = self.OnClick,
    	})
    
    	AddTeam(self.allyTeam + 1)
    	self.OnClick = {
        function(self)
  		      Match:GetChildByName('AI Config'):ClearChildren()
			      Match:GetChildByName('AI Config'):AddChild(self.layout)
		    end
      }
      
    	Match.bots[self.team] = self
    end

    Match:AddChild(Chili.Button:New{
    	caption  = 'Start',
    	bottom   = 10,
    	right    = 210,
    	height   = 50,
    	width    = 65,
    	padding  = {0,0,0,0},
    	allyTeam = 1,
    	OnClick  = {StartScript},
    })
    
    ---------------------------
    -- Teams and Bot UI
    -- TODO add allyTeams:
    --  YOU vs (bot)(add AI) vs (add AI)
    function AddPlayer(self)
    	if self then self.caption = 'YOU' end
    	AddTeam(1)
    	Match.Script.player0.spectator = 0
    
    	Match.Script.team0  =  {
    		allyteam = 0,
    		rgbcolor = '0.99609375 0.546875 0',
    		side = 'CORE',
    		teamleader = 0,
    	}
    
    	Match.Script.allyteam0  =  {
    		numallies = 0,
    	}
    end
    
    function AddTeam(team)
    	if Match.allyTeams > team then return end
    	local teamPlayers = Chili.Control:New{
    		height = 60,
    		width = 300,
    		x = 20,
    		y = team * 70,
    		children = {
    			Chili.Button:New{
    				caption  = 'Add\n AI',
    				x        = team == 0 and 55 or 40,
    				bottom   = 0,
    				height   = 40,
    				width    = 40,
    				padding  = {0,0,0,0},
    				allyTeam = team,
    				OnClick  = {attachProfile},
    			}
    		}
    	}
    	if team > 0 then
    		teamPlayers:AddChild(Chili.Label:New{
    			caption  = 'vs',
    			fontSize = 24,
    			x        = 0,
    			y        = 0,
    		})
    	else
    		teamPlayers:AddChild(Chili.Button:New{
    			caption  = 'Join',
    			x        = 0,
    			bottom   = 0,
    			height   = 50,
    			width    = 50,
    			padding  = {0,0,0,0},
    			allyTeam = team,
    			OnClick  = {AddPlayer},
    		})
    	end
    	Match:AddChild(teamPlayers)
    	Match.allyTeams = team + 1
    end
    AddTeam(0)
    
    Match:AddChild(Chili.Panel:New{
	    name     = 'AI Config',
	    right    = 0,
	    y        = 150,
	    bottom   = 6,
	    width    = '25%',
	    padding  = {0,0,0,0},
	    children = {
		  Chili.Label:New{caption = 'Add AI', y = 6, fontSize = 18,  x = '0%', width = '100%', align = 'center'},
		  Chili.Label:New{caption = 'and/or', y = 26, fontSize = 18, x = '0%', width = '100%', align = 'center'},
		  Chili.Label:New{caption = 'Select AI', y = 46, fontSize = 18, x = '0%', width = '100%', align = 'center'},
		  Chili.Label:New{caption = 'To edit', y = 66, fontSize = 18, x = '0%', width = '100%', align = 'center'},
	}
})

    ---------------------------
    -- Map Selection UI
    
    Match:AddChild(Chili.Label:New{
    	caption  = 'On',
    	fontSize = 24,
    	height   = 24,
    	x        = 30,
    	bottom   = 25,
    })
    
    Match:AddChild(Chili.Label:New{
    	name     = 'MapName',
    	caption  = Match.Script.mapname,
    	fontSize = 40,
    	height   = 40,
    	x        = 70,
    	bottom   = 5,
    })
    
    -- TODO get minimaps somehow
    --  small translucent info overlay over minimap (wind, size, teams, etc..)
    --  get and show team start boxes, or at least start positions
    --  add tabpanel to include: Minimap, Metalmap, infomap

    local MapList = Chili.ScrollPanel:New{
    	parent = match,
    	name   = 'Map Selection',
      y = 0,
    	right  = 0,
    	width  = 200,
    	height = 150,
    	children = {Chili.Label:New{caption = '-- Select Map --', y = 6, fontSize = 18,  x = '0%', width = '100%', align = 'center'}}
    }
    
    -- fill list of maps
    local function AddMap(info)
    	MapList:AddChild(Chili.Button:New{
    		caption  = info.name,
    		x        = 0,
    		y        = #MapList.children * 30,
    		width    = '100%',
    		height   = 26,
    		OnClick = {
    			function(self)
    				Settings['map'] = info.name
    				Match.Script.mapname = info.name
    				Match:GetChildByName('MapName'):SetCaption(info.name)
    			end
    		}
    	})
    end
    
    for _, archive in pairs(VFS.GetAllArchives()) do
    	local info = VFS.GetArchiveInfo(archive)
    	if info.modtype == 3 then AddMap(info) end
    end
    ----------------------
    
    Match:AddChild(MapList)
    
    -- Control will essentially attached to a Menu button
    return Match
end 

----------------------------------------------------
-- Callins
----------------------------------------------------

function widget:Initialize()
    Chili = WG.Chili
    Menu = WG.MainMenu
    if not Menu or not Chili then
        return
    end
    
    Menu.AddTab('Skirmish',createUI()) 
end

function widget:Shutdown()
                                     
end

function widget:GetConfigData()
    return options
end

function widget:SetConfigData(data)
    if data then
        options = data
    end
end


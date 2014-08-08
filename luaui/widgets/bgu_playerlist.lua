function widget:GetInfo()
	return {
		name      = "Player List",
		desc      = "Player list with shortcuts",
		author    = "Bluestone", --based on Marmoth's Advanced Player List
		date      = "July 2014",
		license   = "GNU GPL, v3 or later",
		layer     = 0,
		enabled   = true,  
        handler   = true,
	}
end


--------------------------------------------------------------------------------
-- Pics & Options & Stuff
--------------------------------------------------------------------------------

--rank pics
local rankPics = {
    [0] = "LuaUI/Images/Ranks/rank0.png",
    [1] = "LuaUI/Images/Ranks/rank1.png",
    [2] = "LuaUI/Images/Ranks/rank2.png",
    [3] = "LuaUI/Images/Ranks/rank3.png",
    [4] = "LuaUI/Images/Ranks/rank4.png",
    [5] = "LuaUI/Images/Ranks/rank5.png",
    [6] = "LuaUI/Images/Ranks/rank6.png",
    [7] = "LuaUI/Images/Ranks/rank7.png",
    ['unknown'] = "LuaUI/Images/Ranks/rank_unknown.png",
}

local pingPic         = "LuaUI/Images/playerlist/ping.png"
local cpuPic          = "LuaUI/Images/playerlist/cpu.png"
local readyPic        = "LuaUI/Images/playerlist/blob_small.png"

local needUpdate = true

-- local player info
local myPlayerID = Spring.GetMyPlayerID()

--General players/spectator count and tables
local deadPlayerName = " --- "
local players = {} -- list of all players
local myAllyTeam = {}
local allyTeams = {}
local deadPlayers = {}
local specs = {}

-- permanent panels
local alliesPanel, enemiesPanel, specsPanel, deadplayersPanel
local iPanel, shareE, shareM, watchres, watchcamera, ignore, slap
local enemyAllyTeamPanels = {}

--To determine faction at start
local armcomDefID = UnitDefNames.armcom.id
local corcomDefID = UnitDefNames.corcom.id

--Name for absent/resigned players
local absentName = " --- "

--Did the game start yet?
local gameStarted = false

-- Options
local options = {
    ranks = true,
    flags = true,
    ts = true,
}
local width = {
    flag = 15,
    rank = 15,
    faction = 15,
    name = 165,
    ts = 22,
    cpu = 15,
    ping = 10,
}
local offset = {}

-- Colours
local mColour = '\255\153\153\204'
local eColour = '\255\255\255\76'


--------------------------------------------------------------------------------
-- Random helper functions
--------------------------------------------------------------------------------

function round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

function InlineColour(r,g,b)
	if type(r) == 'table' then
		return string.char(255, (r[1]*255), (r[2]*255), (r[3]*255))
	else
		return string.char(255, (r*255), (g*255), (b*255))
	end
end

function CountTable(t)
    local i = 0
    for _,_ in pairs(t) do
        i = i + 1
    end
    return i
end

function IsDark(red,green,blue)                  	
	-- Determines if the player color is dark (i.e. if a white outline for the sidePic is needed)
	if red*1.2 + green*1.1 + blue*0.8 < 0.9 then return true end
	return false
end

--------------------------------------------------------------------------------
-- interaction panel
--------------------------------------------------------------------------------

local iPanelWidth = 125
local iPanelItemHeight = 25
local iPanelpID -- pID with which iPanel was most recently invoked

function WatchCamera()
    if WG.LockCamera then
        WG.LockCamera(iPanelpID)
    else
        Spring.Echo("Lock Camera widget is not enabled!")
    end

    iPanel:Hide()
end

function WatchRes()
    local teamToSpec = 0 --TODO
    Spring.SendCommands("specteam "..teamToSpec)

    iPanel:Hide()
end

function Ignore()
    if WG.ignoredPlayers[players[iPanelpID].plainName] then
        Spring.SendCommands("unignoreplayer "..players[pID].plainName)    
    else    
        Spring.SendCommands("ignoreplayer "..players[pID].plainName)
    end
    
    iPanel:Hide()
end

function Slap()
    Spring.SendCommands('luarules slap '..iPanelpID)
    
    iPanel:Hide()
end

function ShareUnits()
    local tID = players[iPanelpID].tID
    local n = Spring.GetSelectedUnitsCount()
    Spring.ShareResources(tID,'units')
    
    if n>0 then
        Spring.SendCommands("say a: I gave "..n.." units to "..players[iPanelpID].plainName) 
    end
    
    iPanel:Hide()
end

function ShareRes()
    local e = shareE_slider.value
    local m = shareM_slider.value
    local tID = players[iPanelpID].tID
    Spring.ShareResources(tID,'energy',e)
    Spring.ShareResources(tID,'metal',m)
    
    if e > 0 then
		Spring.SendCommands("say a: I sent "..e.." energy to "..players[iPanelpID].plainName) 
	end
    if m > 0 then
		Spring.SendCommands("say a: I sent "..m.." metal to "..players[iPanelpID].plainName)
	end
    
    iPanel:Hide()
end

function iPanel()
    -- setup iPanel
    iPanel = Chili.Window:New{
        parent    = Chili.Screen0,
        right     = 0,
        bottom    = 0,
        width     = iPanelWidth,
        height    = 1,
        minHeight = 25,
        autosize  = false,
        children  = {},
        padding     = {0,0,0,0},
		itemPadding = {0,0,0,0},
		itemMargin  = {0,0,0,0},
    }
    
    iPanelLayout = Chili.LayoutPanel:New{
        parent      = iPanel,
		name        = 'stack',
		width       = iPanelWidth,
		resizeItems = false,
		autosize    = true,
		padding     = {0,0,0,0},
		itemPadding = {0,0,0,0},
		itemMargin  = {0,0,0,0},
		children    = {},
		preserveChildrenOrder = true,
    }
    
    -- setup children
    
    shareunits = Chili.Button:New{
        minheight = iPanelItemHeight,
        width = '100%',
        caption = 'share units',
        right = 0,
        onclick = {ShareUnits},
    }
    shareres_button = Chili.Button:New{
        minheight = iPanelItemHeight,
        width = '100%',
        caption = 'share res',
        right = 0,
        onclick = {ShareRes},
    }
    
    shareE_text = Chili.TextBox:New{
        height = '100%',
        x = 6,
        text = eColour .. "E",   
        font = {
            outline          = true,
            outlineColor     = {1,1,1,1},
            autoOutlineColor = false,
            outlineWidth     = 2,
            outlineWeight    = 5,
            size             = 15,
        }
    }
    
    shareE_slider = Chili.Trackbar:New{
        height = '100%',
        width = 93,
        x = 37,
        min = 0,
        max = 5000,
        step = 500,
        value = 1000,
    }

    shareE_slider_panel = Chili.LayoutPanel:New{
		height = 25,
        width = '100%',
        right = 0,
		padding     = {0,0,0,0},
		itemPadding = {0,0,0,0},
		itemMargin  = {0,0,0,0},
        orientation = 'horizontal',
        children = {
            shareE_text,
            shareE_slider,
        }
    }
    
    shareM_text = Chili.TextBox:New{
        height = '100%',
        x = 4,
        text = mColour .. "M",    
        font = {
            outline          = true,
            outlineColor     = {0.6,0.6,0.8,1},
            autoOutlineColor = false,
            outlineWidth     = 2,
            outlineWeight    = 3,
            size             = 15,
        }
    }
    
    shareM_slider = Chili.Trackbar:New{
        height = '100%',
        width = 93,
        x = 37,
        min = 0,
        max = 2500,
        step = 250,
        value = 1000,
    }

    shareM_slider_panel = Chili.LayoutPanel:New{
		height = 25,
        width = '100%',
        right = 0,
		padding     = {0,0,0,0},
		itemPadding = {0,0,0,0},
		itemMargin  = {0,0,0,0},
        orientation = 'horizontal',
        children = {
            shareM_text,
            shareM_slider,
        }
    }
        
    shareres_sliders = Chili.LayoutPanel:New{
		height = 63,
        width = '100%',
        right = 0,
		padding     = {8,10,8,3},
		itemPadding = {0,0,0,0},
		itemMargin  = {0,0,0,0},
		children    = {
            shareE_slider_panel,
            shareM_slider_panel,
        },    
    }

    shareres_panel = Chili.LayoutPanel:New{
		autosize    = true,
        width = '100%',
        right = 0,
		padding     = {0,0,0,0},
		itemPadding = {0,0,0,0},
		itemMargin  = {0,0,0,0},
		children    = {
            shareres_sliders,
            shareres_button,
            shareunits,
        },    
    }
    

    watchcamera = Chili.Button:New{
        minheight = iPanelItemHeight,
        width = '100%',
        caption = 'watch camera',
        right = 0,
        onclick ={WatchCamera},
    }

    watchres = Chili.Button:New{
        minheight = iPanelItemHeight,
        width = '100%',
        caption = 'watch res',
        onclick ={WatchRes},
    }

    ignore = Chili.Button:New{
        minheight = iPanelItemHeight,
        width = '100%',
        caption = 'ignore',
        onclick ={Ignore},
    }

    slap = Chili.Button:New{
        minheight = iPanelItemHeight,
        width = '100%',
        caption = 'slap',
        onclick ={Slap},
    }
        
end



function iPanelPress(obj,value)   
    if not iPanel.hidden then 
        iPanel:ToggleVisibility()
        return 
    end
    
    iPanelpID = obj.pID
        
    iPanelLayout:ClearChildren()

    -- add children, calc height
    local h = 0
    
    -- share stuff 
    if not players[myPlayerID].spec and not players[iPanelpID].spec and iPanelpID~=myPlayerID and Spring.GetGameFrame()>0 and Spring.AreTeamsAllied(players[myPlayerID].tID, players[iPanelpID].tID) then
        iPanelLayout:AddChild(shareres_panel)
        h = h + 2*iPanelItemHeight + 63
    end

    -- watch cam
    if (players[myPlayerID].spec or Spring.ArePlayersAllied(myPlayerID, iPanelpID)) and not players[iPanelpID].isAI then
        iPanelLayout:AddChild(watchcamera)
        h = h + iPanelItemHeight
    end
    
    -- watch res
    if not players[iPanelpID].spec and players[myPlayerID].spec then
        iPanelLayout:AddChild(watchres)
        h = h + iPanelItemHeight
    end
    
    -- ignore
    if obj.pID~=myPlayerID and not players[iPanelpID].isAI then
        if WG.ignoredPlayers[players[obj.pID].plainName] then
            ignore:SetCaption('un-ignore')
        else    
            ignore:SetCaption('ignore')
        end
        iPanelLayout:AddChild(ignore)
        h = h + iPanelItemHeight
    end
    
    -- slap
    if Spring.GetGameFrame()>2 and not players[iPanelpID].isAI then --because its a luarules action
        iPanelLayout:AddChild(slap)
        h = h + iPanelItemHeight
    end
    
    if h==0 then --nothing to show
        if not iPanel.hidden then 
            iPanel:Hide()        
        end 
        return 
    end

    iPanel:ToggleVisibility()        
    
    -- move panel to mouse pos & resize
    local x,y = Spring.GetMouseState()
    local vsx,vsy = Spring.GetViewGeometry()
    iPanel:Resize(iPanelWidth,h)
    iPanelLayout:Resize(iPanelWidth,h)
    iPanel:SetPos(x,vsy-y-h) --TODO: don't go off edge of screen
        
    -- draw iPanel in front of stack
    iPanel:SetLayer(1)
    stack:SetLayer(2)
    iPanel:Invalidate()
end

--------------------------------------------------------------------------------
-- player/spec panels
--------------------------------------------------------------------------------

local colourConv = {
    -- green -> yellow -> red, in 6 steps
    -- for cpu/ping icons
    [1] = {0.0, 1.0, 0.0, 1.0},
    [2] = {0.5, 1.0, 0.5, 1.0},
    [3] = {1.0, 0.0, 1.0, 1.0},
    [4] = {1.0, 0.0, 0.5, 1.0},
    [5] = {1.0, 0.0, 0.0, 1.0},
    [6] = {0.7, 0.0, 0.0, 1.0},
}

function PlayerPanel(pID)

    local panel = Chili.Button:New{
		width       = '100%',
        minHeight   = 17,
		resizeItems = false,
		autosize    = true,
		padding     = {5,0,0,0},
		itemPadding = {0,0,0,0},
        itemMargin  = {0,0,0,0},
        caption     = "",
        onclick     = {iPanelPress},
		children    = {},
        pID         = pID,
	}
   
    --children in order from R to L
    
    local ping = Chili.Image:New{
        parent = panel,
        name = "ping",
        height = 17,
        width = width.ping,
        right = offset.ping,
        file = pingPic, 
    }

    local cpu = Chili.Image:New{
        parent = panel,
        name = "cpu",
        height = 17,
        width = width.cpu,
        right = offset.cpu,
        file = cpuPic, 
    }
    
    if options.ts then
        local ts = Chili.TextBox:New{
            parent      = panel,
            name        = "ts",
            text        = players[pID].skill,
            right       = offset.ts,
            width       = width.ts,
            autoHeight  = false,
            height      = '100%',
            padding     = {0,4,0,0},
            lineSpacing = 0,
            font        = {
                outline          = true,
                autoOutlineColor = true,
                outlineWidth     = 4,
                outlineWeight    = 4,
                size             = 12,
            },
        }
    end

    local name = Chili.TextBox:New{
        parent      = panel,
        name        = "name",
        text        = players[pID].name,
        right       = offset.name,
        width       = width.name,
        autoHeight  = false,
        height      = '100%',
        padding     = {0,2,0,0},
        lineSpacing = 0,
        font        = {
            outline          = true,
            autoOutlineColor = true,
            outlineWidth     = 4,
            outlineWeight    = 4,
            size             = 14,
        },
    }
    
    local readystate = Chili.Image:New{
        parent = panel,
        name = "readystate",
        height = 17,
        width = width.faction,
        right = offset.faction,
        file = readyPic, 
        color = ReadyColour(players[pID].readyState)
    }
    -- faction image is created when game starts, readystate image is then hidden
    
    if options.ranks then
        local rank = Chili.Image:New{
            parent = panel,
            name = "rank",
            height = 17,
            width = width.rank,
            right = offset.rank,
            file = players[pID].rankPic,
        }
    end
    
    if options.flags then
        local flag = Chili.Image:New{
            parent = panel,
            name = "flag",
            height = 17,
            width = width.flag,
            right = offset.flag,
            file = players[pID].flagPic,
        }
    end

    return panel
end

function DeadPanel(pID)
    local panel = Chili.Panel:New{
		width       = '100%',
        minHeight   = 17,
		resizeItems = false,
		autosize    = true,
		padding     = {0,0,0,0},
		itemPadding = {0,0,0,0},
		itemMargin  = {0,0,0,0},
		children    = {},
	}
    
    local name = Chili.TextBox:New{
        parent      = panel,
        name        = "name",
        text        = players[pID].deadname,
        width       = width.name,
        right       = offset.name,
        autoHeight  = false,
        height      = 17,
        padding     = {0,2,0,0},
        lineSpacing = 0,
        font        = {
            outline          = true,
            autoOutlineColor = true,
            outlineWidth     = 4,
            outlineWeight    = 4,
            size             = 14,
        },
    }
    return panel
end


function SpecPanel(pID)
    local panel = Chili.LayoutPanel:New{
		width       = '100%',
        minHeight   = 12,
		resizeItems = false,
		autosize    = true,
		padding     = {0,0,0,0},
		itemPadding = {0,0,0,0},
		itemMargin  = {0,0,0,0},
		children    = {},
	}

    local button = Chili.Button:New{
        name        = "button",
        parent      = panel,
		width       = width.name,
        right       = offset.name,
        minHeight   = 12,
		padding     = {0,0,0,0},
		itemPadding = {0,0,0,0},
		itemMargin  = {0,0,0,0},
		children    = {},
        pID         = pID,
        caption     = "",
        onclick     = {iPanelPress},
	}
    
    local name = Chili.TextBox:New{
        parent      = button,
        name        = "name",
        text        = players[pID].name,
        width       = '100%',
        minHeight   = 12,
        autoHeight  = false,
        height      = 12,
        padding     = {8,5,0,0},
        lineSpacing = 0,
        font        = {
            outline          = true,
            autoOutlineColor = true,
            outlineWidth     = 2,
            outlineWeight    = 10,
            size             = 12,
        },
    }
    
    return panel
end

--------------------------------------------------------------------------------
-- Player info helper functions
--------------------------------------------------------------------------------

function SetFaction(pID) 
	--set faction, from TeamRulesParam when possible and from initial info if not    
    local startUDID = Spring.GetTeamRulesParam(players[pID].tID, 'startUnit')
	if startUDID then
		if startUDID == armcomDefID then 
			faction = "arm"
		elseif startUDID == corcomDefID then
			faction = "core"
		else
            _,_,_,_,faction = Spring_GetTeamInfo(team)
        end
	else
		_,_,_,_,faction = Spring_GetTeamInfo(team)
	end
       
	if faction then
        players[pID].faction = faction
        if players[pID].dark then
            players[pID].factionPic = "LuaUI/Images/playerlist/"..faction.."WO_default.png"
		else
            players[pID].factionPic = "LuaUI/Images/playerlist/"..faction.."_default.png"
        end
    else
        if players[pID].dark then
            players[pID].factionPic = "LuaUI/Images/playerlist/defaultWO.png"
        else
            players[pID].factionPic = "LuaUI/Images/playerlist/default.png"
        end
    end
end

function GetSkill(playerID)
    if players[playerID].isAI then return "" end 
    
	local customtable = select(10,Spring.GetPlayerInfo(playerID)) -- player custom table
	local tsMu = customtable.skill
	local tsSigma = customtable.skilluncertainty
	local tskill = ""
	if tsMu then
		tskill = tsMu and tonumber(tsMu:match("%d+%.?%d*")) or 0
		tskill = round(tskill,0)
		if string.find(tsMu, ")") then
			tskill = "\255"..string.char(190)..string.char(140)..string.char(140) .. tskill -- ')' means inferred from lobby rank
		else
		
			-- show privacy mode
			local priv = ""
			if string.find(tsMu, "~") then -- '~' means privacy mode is on
				priv = "\255"..string.char(200)..string.char(200)..string.char(200) .. "*" 		
			end
			
			--show sigma
			if tsSigma then -- 0 is low sigma, 3 is high sigma
				tsSigma=tonumber(tsSigma)
				local tsRed, tsGreen, tsBlue 
				if tsSigma > 2 then
					tsRed, tsGreen, tsBlue = 190, 130, 130
				elseif tsSigma == 2 then
					tsRed, tsGreen, tsBlue = 140, 140, 140
				elseif tsSigma == 1 then
					tsRed, tsGreen, tsBlue = 195, 195, 195
				elseif tsSigma < 1 then
						tsRed, tsGreen, tsBlue = 250, 250, 250
				end
				tskill = priv .. "\255"..string.char(tsRed)..string.char(tsGreen)..string.char(tsBlue) .. tskill
			else
				tskill = priv .. "\255"..string.char(195)..string.char(195)..string.char(195) .. tskill --should never happen
			end
		end
	else
		tskill = "" --"\255"..string.char(160)..string.char(160)..string.char(160) .. "?"
	end
	return tskill, tsMu
end

function ReadyColour(readyState, isAI)
	local ready = (readyState==1) or (readyState==2) or (readyState==-1)
	local hasStartPoint = (readyState==4)
	local readyColour
    if ready then
		readyColour = {0.1,0.95,0.2,1}
	else
		if hasStartPoint then
			readyColour = {1,0.65,0.1,1}
		else
			readyColour = {0.8,0.1,0.1,1}	
		end
	end
    return readyColour
end

function GetRankPic(rank)
    return rank and rankPics[rank] or rankPics['unknown'] 
end

function GetFlag(country)
    local path = "LuaUI/Images/flags/"..string.upper(country)..".png"
    -- TODO: check if exists, return _unknown.pgn o/w
    return path
end

function cpuLevel(cpu)
    local n_cpu
    if cpu < 0.3 then
        n_cpu = 1
    elseif cpu < 0.45 then
        n_cpu = 2
    elseif cpu < 0.6 then
        n_cpu = 3
    elseif cpu < 0.75 then
        n_cpu = 4
    elseif cpu < 0.9 then
        n_cpu = 5
    else
        n_cpu = 6
    end
    return n_cpu
end

--------------------------------------------------------------------------------
-- Player info 
--------------------------------------------------------------------------------

function NewPlayer(pID)
    players[pID] = {}
    local name, active, spec, tID, aID, ping, cpu, country, rank = Spring.GetPlayerInfo(pID)  
    
    players[pID].pID = pID
    players[pID].tID = tID
    players[pID].aID = aID
    players[pID].isAI = false

    local r,g,b = Spring.GetTeamColor(tID)
    players[pID].colour = {r,g,b}
    players[pID].dark = IsDark(r,g,b)
    
    players[pID].plainName = name
    players[pID].name = ((not spec) and InlineColour(players[pID].colour) or "") .. name --TODO use 'original' colours?
    players[pID].deadname = ((not spec) and InlineColour(players[pID].colour) or "") .. deadPlayerName    
    
    players[pID].rank = rank 
    players[pID].rankPic = GetRankPic(rank)
    players[pID].country = country
    players[pID].flagPic = GetFlag(country)
    
    local tskill,tsMu = GetSkill(pID, isAI)
    players[pID].skill = tskill --string
    players[pID].tsMu = tsMu --number
        
    players[pID].active = active
    players[pID].spec = spec
    players[pID].ping = ping
    players[pID].cpu = cpu
    
    players[pID].readyState = Spring.GetGameRulesParam("player_" .. tostring(pID) .. "_readyState") or 0   
    players[pID].readyColour = ReadyColour(players[pID].readyState)
    players[pID].wasPlayer = (Spring.GetGameRulesParam("player_" .. tostring(pID) .. "_wasPlayer")==1)      

    -- set at gamestart
    players[pID].faction = nil
    players[pID].factionPic = nil 
    
    -- panels
    players[pID].playerPanel = PlayerPanel(pID)
    players[pID].deadPanel = DeadPanel(pID)
    players[pID].specPanel = SpecPanel(pID)

    needUpdate = true
end

local AIID = 1000 --dummy pID for AI "players", starts counting at 1000

function NewAIPlayer(tID)    
    local skirmishAIID, name, hostPlayerID, shortName, version = Spring.GetAIInfo(tID)

    local pID = AIID
    players[pID] = {}
    
    local _, _, isDead, isAITeam, _, aID = Spring.GetTeamInfo(tID)
    local _, active, _, _, _, ping, cpu, _, _ = Spring.GetPlayerInfo(hostPlayerID)  
    
    players[pID].pID = AIID 
    players[pID].hostID = hostPlayerID
    players[pID].tID = tID
    players[pID].aID = aID
    players[pID].isAI = true

    local r,g,b = Spring.GetTeamColor(tID)
    players[pID].colour = {r,g,b}
    players[pID].dark = IsDark(r,g,b)

    players[pID].plainName = shortName 
    players[pID].name = (InlineColour(players[pID].colour) or "") .. shortName --TODO use 'original' colours?
    players[pID].deadname = (InlineColour(players[pID].colour) or "") .. deadPlayerName    

    -- rank, country and skill are nil
    players[pID].skill = ""
    players[pID].tsMu = -100

    players[pID].active = active
    players[pID].spec = false or isDead
    players[pID].ping = ping
    players[pID].cpu = cpu
    
    players[pID].readyState = 0
    players[pID].readyColour = {0.1,0.1,0.97,1}
    players[pID].wasPlayer = true      
    
    -- set at gamestart
    players[pID].faction = nil
    players[pID].factionPic = nil 

    -- panels
    players[pID].playerPanel = PlayerPanel(pID)
    players[pID].deadPanel = DeadPanel(pID)
    players[pID].specPanel = SpecPanel(pID) 

    AIID = AIID + 1
end

function CheckChange(oldValue, value, update)
    if value~=oldValue then
        return true, value
    else
        return false or update, oldValue
    end
end

function UpdatePingCPU(pID, ping, cpu)
    -- update ping/cpu
    players[pID].ping = ping -- in ms
    players[pID].cpu = cpu -- in [0,1]

    local n_cpu = cpuLevel(cpu)
    local n_ping = math.min(6, 1 + math.floor(ping*1000/300))
    
    players[pID].playerPanel:GetChildByName('cpu').color = colourConv[n_cpu]
    players[pID].playerPanel:GetChildByName('ping').color = colourConv[n_ping]
    players[pID].playerPanel:GetChildByName('cpu'):Invalidate()
    players[pID].playerPanel:GetChildByName('ping'):Invalidate()
end

function UpdateAIPlayer(pID)
    -- we assume that AIs do not change teamID and that they stay alive until their team dies or host player leaves
    local _, _, isDead, isAITeam, _, aID = Spring.GetTeamInfo(players[pID].tID)
    local _, active, _, _, _, ping, cpu, _, _ = Spring.GetPlayerInfo(players[pID].hostID)  
    local update = false

    -- check if its team died
    update, players[pID].active = CheckChange(players[pID].active, active, update)
    update, players[pID].spec = CheckChange(players[pID].spec, isDead, update)    
    
    -- update ping/cpu to match its hosts
    UpdatePingCPU(pID,ping,cpu)

    needUpdate = needUpdate or update
end

function UpdatePlayer(pID)
    if players[pID].isAI then
        UpdateAIPlayer(pID) 
        return
    end

    local name, active, spec, tID, aID, ping, cpu, country, rank = Spring.GetPlayerInfo(pID)  
    local update = false --does the player mean we need a global update?

    -- check change of tID
    update, players[pID].tID = CheckChange(players[pID].tID, tID, update)
    update, players[pID].aID = CheckChange(players[pID].aID, aID, update)
    if update then
        -- if the tID/aID changed, we need to update the name colour
        if not spec then
            local r,g,b = Spring.GetTeamColor(tID)
            players[pID].colour = {r,g,b}
        end
        
        players[pID].name = ((not spec) and InlineColour(players[pID].colour) or "") .. name --TODO use original colours
        players[pID].deadname = ((not spec) and InlineColour(players[pID].colour) or "") .. deadPlayerName    
        
        players[pID].playerPanel:GetChildByName('name'):SetText(players[pID].name)
        players[pID].deadPanel:GetChildByName('name'):SetText(players[pID].deadname)
        players[pID].specPanel:GetChildByName('button'):GetChildByName('name'):SetText(players[pID].name)
    end
    
    -- check if a player leaves/resigns/appears
    update, players[pID].wasPlayer = CheckChange(players[pID].wasPlayer, (Spring.GetGameRulesParam("player_" .. tostring(pID) .. "_wasPlayer")==1), update)   
    update, players[pID].active = CheckChange(players[pID].active, active, update)
    update, players[pID].spec = CheckChange(players[pID].spec, spec, update)
    
    if not gameStarted then
        -- poll ready state
        local updateReadyState = false
        updateReadyState, players[pID].readyState = CheckChange(players[pID].readyState, Spring.GetGameRulesParam("player_" .. tostring(pID) .. "_readyState") or 0, updateReadyState)    
        if updateReadyState then
            players[pID].playerPanel:GetChildByName('readystate').color = ReadyColour(players[pID].readyState)
            players[pID].playerPanel:GetChildByName('readystate'):Invalidate()
        end
    end
    
    UpdatePingCPU(pID, ping, cpu)
    
    --TODO: is takeable?
    --TODO: made marker?

    -- record globally if we need an update
    needUpdate = needUpdate or update    
end

function ScheduledUpdate()
    -- update each player 
    for pID,_ in pairs(players) do
        UpdatePlayer(pID)
    end
    -- check for new players
    local playerList = Spring.GetPlayerList()
    for _,pID in ipairs(playerList) do
        if not players[pID] then
            NewPlayer(pID)
        end
    end
end

--------------------------------------------------------------------------------
-- Callins
--------------------------------------------------------------------------------

function widget:Initialize()
    Spring.SendCommands('unbind Any+h sharedialog')

    Chili = WG.Chili
    
    CalculateOffsets()

    -- add players
    local playerList = Spring.GetPlayerList()
    for _,pID in ipairs(playerList) do
        NewPlayer(pID)
    end

    -- add AIs
    local teamList = Spring.GetTeamList()
    for _,tID in ipairs(teamList) do
        local _,_,_,isAITeam,_,_ = Spring.GetTeamInfo(tID)
        if isAITeam then
            NewAIPlayer(tID)
        end
    end

    SetupStack()

    iPanel()
    iPanel:Hide()
    
    -- TODO: add option for flags and ranks into optionMenu, just need to change options.XXX and call OptionChange()
end

function widget:ShutDown()
    Spring.SendCommands('bind Any+h sharedialog')
end

function widget:PlayerChanged(pID)
    ScheduledUpdate()
end

function widget:GameFrame(n)
    -- show factions just after game starts
    if not gameStarted and n>1 then
        gameStarted = true
        ScheduledUpdate()
        
        for pID,_ in pairs(players) do
            SetFaction(pID)
        
            players[pID].playerPanel:GetChildByName('readystate'):Hide()
        
            Chili.Image:New{
                parent = players[pID].playerPanel,
                name = 'faction',
                height = 17,
                width = width.faction,
                right = offset.faction,
                file = players[pID].factionPic,
                color = players[pID].colour,
            }
        end
            
        needUpdate = true
    end
end

local prevTimer = Spring.GetTimer()
function widget:Update()
    local timer = Spring.GetTimer()
    if Spring.DiffTimers(timer,prevTimer)>0.2 then
        ScheduledUpdate()
    end
    
    if needUpdate then
        UpdateStack()
        if not iPanel.hidden then iPanel:Hide() end
        needUpdate = false
    end
end

function widget:KeyPress()
    if not iPanel.hidden then 
        iPanel:Hide()
    end
    return false
end


--------------------------------------------------------------------------------
-- Team/AllyTeam tables
--------------------------------------------------------------------------------

function SetupAllyTeams()
    -- create allyteams tables
    local myAllyTeamID = Spring.GetMyAllyTeamID()
    
    myAllyTeam = {}
    allyTeams = {}
    
    allyTeamList = Spring.GetAllyTeamList()
    local gaiaTeamID = Spring.GetGaiaTeamID()
    
    for _,aID in ipairs(allyTeamList) do
        local teamList = Spring.GetTeamList(aID)
        for _,tID in ipairs(teamList) do
            if tID~=gaiaTeamID then
                if aID~=myAllyTeamID then
                    if not allyTeams[aID] then
                        allyTeams[aID] = {}
                    end
                    table.insert(allyTeams[aID],tID)
                else
                    table.insert(myAllyTeam,tID)
                end
            end
        end
    end    
end

function AssignPlayersToTeams()
    -- add pIDs to appropriate tables
    deadPlayers = {}
    specs = {}
    teams = {}
    local teamList = Spring.GetTeamList()
    for _,tID in ipairs(teamList) do
        teams[tID] = {}
    end
   
    for pID,_ in pairs(players) do
        local active = players[pID].active 
        local spec = players[pID].spec
        local tID = players[pID].tID
        local wasPlayer = players[pID].wasPlayer
        local isAI = players[pID].isAI
        
        if wasPlayer then 
            -- live or dead player (panel creator will act appropriately)
            table.insert(teams[tID],pID) 
            if active and spec and not isAI then
                -- dead player, now a spec                    
                table.insert(deadPlayers,pID)
            end
        else
            if active then
                -- spectator, never a player
                table.insert(specs,pID)
            end
        end        
    end
end

function pID_compare(pID_1,pID_2)
    if players[pID_1].tsMu and players[pID_2].tsMu then return (players[pID_1].tsMu > players[pID_2].tsMu) end
    return (pID_1<pID_2)
end    

function GetMaxTS(tID)
    local playerList = Spring.GetPlayerList(tID)
    local maxTS = -100
    for _,pID in pairs(playerList) do
        if players[pID].tsMu then
            maxTS = math.max(maxTS, players[pID].tsMu)
        end
    end
    return maxTS
end

function tID_compare(tID_1,t_ID2)
    local ts_1 = GetMaxTS(tID_1)
    local ts_2 = GetMaxTS(tID_2)
    if ts_1 and ts_2 then return (ts_1>ts_2) end
    return (tID_1<tID_2)
end
    
function SortTeams()
    -- sort players within each team
    -- TODO: coops, AIs
    for tID,_ in pairs(teams) do
        table.sort(teams[tID],pID_compare)
    end

    -- sort deadPlayers and specs    
    table.sort(deadPlayers,pID_compare)
    table.sort(specs,pID_compare)    
end

function SortAllyTeams()
    -- sort teams within my allyTeam
    table.sort(myAllyTeam,tID_compare)

    -- sort teams with other allyTeams
    for aID,_ in pairs(allyTeams) do
        table.sort(allyTeams[aID],tID_compare)
    end    
end    


--------------------------------------------------------------------------------
-- GUI helper controls
--------------------------------------------------------------------------------

function Header(text)
    local panel = Chili.LayoutPanel:New{
		width       = '100%',
        minHeight   = 18,
		resizeItems = false,
		autosize    = true,
		padding     = {0,0,0,0},
		itemPadding = {0,0,0,0},
		itemMargin  = {0,0,0,0},
		children    = {},
	}
    
    local name = Chili.TextBox:New{
        parent      = panel,
        text        = " " .. text,
        right       = offset.name,
        width       = width.name,
        autoHeight  = false,
        height      = '100%',
        padding     = {0,2,0,0},
        lineSpacing = 0,
        font        = {
            outline          = true,
            outlineColor     = {0,0,0,1},
            autoOutlineColor = false,
            outlineWidth     = 4,
            outlineWeight    = 5,
            size             = 14,
        },
    }
    return panel
end

function Separator() 
    local separator = Chili.Line:New{
        width = '100%',
    }
    return separator
end

function HalfSeparator()
    local separator = Chili.Line:New{
        width = 100,
        x = offset.max - offset.name - width.name + 100,
    }
    return separator
end

--------------------------------------------------------------------------------
-- GUI construction
--------------------------------------------------------------------------------

function CalculateOffsets()
    local o = 0 --offset from RHS of stack
    o = o + 22 -- right margin
    offset = {}
    
    offset.ping = o
    o = o + width.ping
    
    offset.cpu = o
    o = o + width.cpu
    
    if options.ts then
        offset.ts = o
        o = o + width.ts
    end
            
    offset.name = o
    o = o + width.name
    
    o = o + 2
    
    offset.faction = o
    o = o + width.faction
    
    if options.ranks then
        offset.rank = o
        o = o + width.rank 
    else
        offset.rank = 50 --out of the way, it will be hidden anyway
    end
    
    o = o + 1
    
    if options.flags then
        offset.flag = o
        o = o + width.flag
    else
        offset.flag = 50 --out of the way, it will be hidden anyway
    end
    
    o = o + 16 --left margin
    offset.max = o
end

function SetupStack()

    SetupAllyTeams()

    window = Chili.Window:New{
        parent    = Chili.Screen0,
        right     = 0,
        bottom    = 0,
        width     = offset.max,
        minHeight = 50,
        minWidth  = 1,
        autosize  = true,
        children  = {},
    }

    stack = Chili.LayoutPanel:New{
        parent      = window,
		name        = 'stack',
		width       = '100%',
        minHeight   = 50,
		resizeItems = false,
		autosize    = true,
		padding     = {0,0,0,0},
		itemPadding = {0,0,0,0},
		itemMargin  = {0,0,0,0},
		children    = {},
		preserveChildrenOrder = true,
	}
    
    alliesPanel = Chili.LayoutPanel:New{
        parent      = stack,
		name        = 'allies',
		width       = '100%',
        minHeight   = 0,
		resizeItems = false,
		autosize    = true,
		padding     = {0,0,0,0},
		itemPadding = {0,0,0,0},
		itemMargin  = {0,0,0,0},
		children    = {},
		preserveChildrenOrder = true,
	}
        
    enemiesPanel = Chili.LayoutPanel:New{
        parent      = stack,
		name        = 'enemies',
		width       = '100%',
        minHeight   = 0,
		resizeItems = false,
		autosize    = true,
		padding     = {0,0,0,0},
		itemPadding = {0,0,0,0},
		itemMargin  = {0,0,0,0},
		children    = {},
		preserveChildrenOrder = true,
	}
    
    specsPanel = Chili.LayoutPanel:New{
        parent      = stack,
		name        = 'specs',
		width       = '100%',
        minHeight   = 0,
		resizeItems = false,
		autosize    = true,
		padding     = {0,0,0,0},
		itemPadding = {0,0,0,0},
		itemMargin  = {0,0,0,0},
		children    = {},
		preserveChildrenOrder = true,
	}
    
    UpdateStack()
end

function UpdateStack()
    -- disassociate all children
    alliesPanel:ClearChildren()
    enemiesPanel:ClearChildren()
    specsPanel:ClearChildren()
    specsPanel:ClearChildren()
    for i,_ in ipairs(enemyAllyTeamPanels) do
        enemyAllyTeamPanels[i]:ClearChildren()
    end

    -- re-sort players into teams/allyteams
    AssignPlayersToTeams()
    SortTeams()
    SortAllyTeams()
    
    -- now re-associate children
    alliesPanel:AddChild(Header("ALLIES"))
    for _,tID in ipairs(myAllyTeam) do
        for _,pID in ipairs(teams[tID]) do
            if players[pID].spec then
                alliesPanel:AddChild(players[pID].deadPanel)
            else
                alliesPanel:AddChild(players[pID].playerPanel)            
            end
        end
    end
    alliesPanel:AddChild(Separator())

    enemiesPanel:AddChild(Header("ENEMIES"))    
    enemyAllyTeamPanels = {}
    local n_allies = CountTable(allyTeams)
    local n = 0
    for aID,_ in pairs(allyTeams) do       
        enemyAllyTeamPanels[aID] = Chili.LayoutPanel:New{
            parent      = enemiesPanel,
            name        = 'allyteam ' .. aID, 
            width       = '100%',
            minHeight   = 0,
            resizeItems = false,
            autosize    = true,
            padding     = {0,0,0,0},
            itemPadding = {0,0,0,0},
            itemMargin  = {0,0,0,0},
            children    = {},
            preserveChildrenOrder = true,
        }
        
        for _,tID in ipairs(allyTeams[aID]) do
            for _,pID in ipairs(teams[tID]) do
                if players[pID].spec then
                    enemyAllyTeamPanels[aID]:AddChild(players[pID].deadPanel)
                else
                    enemyAllyTeamPanels[aID]:AddChild(players[pID].playerPanel)            
                end
            end
        end
        
        n = n + 1
        if n < n_allies then
            enemiesPanel:AddChild(HalfSeparator())
        end
    end
    enemiesPanel:AddChild(Separator())

    specsPanel:AddChild(Header("SPECTATORS"))   
    for _,pID in ipairs(deadPlayers) do
        specsPanel:AddChild(players[pID].specPanel)
    end
    for _,pID in ipairs(specs) do
        specsPanel:AddChild(players[pID].specPanel)
    end 

    stack:Invalidate() -- without this the spectator panel doesn't resize, chili bug?
end

function OptionChange()
    -- change the width of stack
    CalculateOffsets()
    window:Resize(offset.max,0)
    
    -- set flag and rank visibility to match options
    for pID,_ in pairs(players) do
        if options.flags then
            if players[pID].playerPanel:GetChildByName('flag').hidden then
                players[pID].playerPanel:GetChildByName('flag'):Show()
            end
        else
            if not players[pID].playerPanel:GetChildByName('flag').hidden then
                players[pID].playerPanel:GetChildByName('flag'):Hide()
            end
        end
        if options.ranks then
            if players[pID].playerPanel:GetChildByName('rank').hidden then
                players[pID].playerPanel:GetChildByName('rank'):Show()
            end
        else
            if not players[pID].playerPanel:GetChildByName('rank').hidden then
                players[pID].playerPanel:GetChildByName('rank'):Hide()
            end
        end    
    end
end


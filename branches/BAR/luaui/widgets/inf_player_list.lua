function widget:GetInfo()
    return {
        name      = "Player List",
        desc      = "Displays a player list with many shortcuts",
        author    = "Bluestone", --based on Marmoth's Advanced Player List
        date      = "July 2014",
        license   = "GNU GPL, v3 or later",
        layer     = -1,
        enabled   = true,
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

local buttonColour, panelColour, sliderColour 

local needUpdate = true

-- local player info
local myPlayerID = Spring.GetMyPlayerID()
local myTeamID = Spring.GetMyTeamID()
local myAllyTeamID = Spring.GetMyAllyTeamID()
local amISpec, notFullView, _= Spring.GetSpectatingState()
local amIFullView = not notFullView

--General players/spectator count and tables
local deadPlayerName = " --- "
local players = {} -- list of all players
local myAllyTeam = {}
local allyTeams = {}
local allyTeamOrder = {}
local deadPlayers = {}
local specs = {}
local headers = {}

-- permanent panels
local window, stack
local iPanel, shareE, shareM, watchres, watchcamera, ignore, slap

--To determine faction at start
local armcomDefID = UnitDefNames.armcom.id
local corcomDefID = UnitDefNames.corcom.id

--Name for absent/resigned players
local absentName = " --- "

--Did the game start yet?
local gameStarted = false

-- Colours
local mColor = '\255\153\153\204'
local eColor = '\255\255\255\76'

-- res panels
local resources = { 
    [1] = {name="metal", color={0.6, 0.6, 0.8, 0.8}, textColor=mColor},
    [2] = {name="energy", color={1.0, 1.0, 0.3, 0.6}, textColor=eColor},
}    

-- Options
local options = {
    ready_faction = true,
    ranks = true,
    flags = true,
    ts = true,
    resBars = true,
    resText = true,
    headerRes = true,
}
local width = {
    flag = 15,
    rank = 15,
    faction = 15,
    name = 130,
    resText = 94,
    resBars = 75,
    ts = 22,
    cpu = 15,
    ping = 10,
}
local offset = {}



--------------------------------------------------------------------------------
-- Random helper functions
--------------------------------------------------------------------------------

function round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

function InlineColor(R,G,B)
    local r,g,b
    if type(R) == 'table' then
        r,g,b = math.max(1,R[1]*255),math.max(1,R[2]*255),math.max(1,R[3]*255)
    else
        r,g,b = math.max(1,R*255),math.max(1,G*255),math.max(1,B*255)
    end
    return string.char(255,r,g,b)
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

function UpdateMyStates()
    teamID = Spring.GetMyTeamID()
    if teamID~= myTeamID then
        myTeamID = teamID
        myAllyTeamID = Spring.GetMyAllyTeamID
        local _,_,_,_,_,allyTeamID = Spring.GetTeamInfo(teamID)
        myAllyTeamID = allyTeamID
        needUpdate = true -- if we are spectator changing team, this is where it gets noticed
    end

    local spec, notFullView, fullSelect = Spring.GetSpectatingState()
    if spec~=amISpec or (not notFullView)~=amIFullView then
        needUpdate = true
        amIFullView = not notFullView 
        amISpec = spec
    end
end

--------------------------------------------------------------------------------
-- interaction panel
--------------------------------------------------------------------------------

local iPanelWidth = 125
local iPanelItemHeight = 25
local iPanelpID, iPaneltID, iPanelName, iPanelDeadPlayer -- info from button with which iPanel was most recently invoked

function WatchCamera()
    if WG.LockCamera then
        WG.LockCamera(iPanelpID)
    else
        Spring.Echo("Warning: Lock Camera API not found!")
    end

    iPanel:Hide()
end

function WatchRes()
    local _,notFullView,fullSelect = Spring.GetSpectatingState()
    Spring.SendCommands("specteam "..iPaneltID)

    iPanel:Hide()
end

function WatchLos()
    local _,notFullView,fullSelect = Spring.GetSpectatingState()
    if notFullView then
        Spring.SendCommands("specteam "..iPaneltID)
        Spring.SendCommands("specfullview")
    else
        Spring.SendCommands("specfullview")
    end

    iPanel:Hide()
end

function Ignore()
    if WG.ignoredPlayers[players[iPanelpID].plainName] then
        Spring.SendCommands("unignoreplayer "..players[iPanelpID].plainName)    
    else    
        Spring.SendCommands("ignoreplayer "..players[iPanelpID].plainName)
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
    
    iPanel:Hide()
end

function ShareRes()
    local e = shareE_slider.value
    local m = shareM_slider.value
    local tID = players[iPanelpID].tID
    Spring.ShareResources(tID,'energy',e)
    Spring.ShareResources(tID,'metal',m)
       
    iPanel:Hide()
end

function SetShareResTooltip()
    -- when hovering the share res button
    local e = shareE_slider.value
    local m = shareM_slider.value
    shareres_button.tooltip = "Share " .. e .. "E, " .. m .. "M"
end

local takeInfo
function TakeTeam()
    -- record info about the take
    -- effects of take can't be fully determined until after it happens, so we process this in widget:GameFrame
    Spring.SendCommands("luarules take2 " .. iPaneltID)
    takeInfo = {team=iPaneltID, name=iPanelName, byPlayer=myPlayerID, onFrame=Spring.GetGameFrame()}
    
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
        color = buttonColour,
        padding     = {1,0,1,0},
        borderColor = {0,0,0,1},
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
        borderColor = buttonColour,
        backgroundColor = buttonColour,
    }
    shareres_button = Chili.Button:New{
        minheight = iPanelItemHeight,
        width = '100%',
        caption = 'share res',
        right = 0,
        borderColor = buttonColour,
        backgroundColor = buttonColour,
        onmouseover = {SetShareResTooltip},
        onclick = {ShareRes},
    }
    
    shareE_text = Chili.TextBox:New{
        height = '100%',
        x = 6,
        text = eColor .. "E",   
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
        text = mColor .. "M",    
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
        value = 500,
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
        borderColor = buttonColour,
        backgroundColor = buttonColour,
    }

    watchres = Chili.Button:New{
        minheight = iPanelItemHeight,
        width = '100%',
        caption = 'watch res',
        onclick ={WatchRes},
        borderColor = buttonColour,
        backgroundColor = buttonColour,
    }

    watchlos = Chili.Button:New{
        minheight = iPanelItemHeight,
        width = '100%',
        caption = 'watch los',
        onclick ={WatchLos},
        borderColor = buttonColour,
        backgroundColor = buttonColour,
    }

    ignore = Chili.Button:New{
        minheight = iPanelItemHeight,
        width = '100%',
        caption = 'ignore',
        onclick ={Ignore},
        borderColor = buttonColour,
        backgroundColor = buttonColour,
    }

    slap = Chili.Button:New{
        minheight = iPanelItemHeight,
        width = '100%',
        caption = 'slap',
        onclick ={Slap},
        borderColor = buttonColour,
        backgroundColor = buttonColour,
    }

    take = Chili.Button:New{
        minheight = iPanelItemHeight,
        width = '100%',
        caption = 'take',
        onclick ={TakeTeam},
        borderColor = buttonColour,
        backgroundColor = buttonColour,
    }
    
end

function iPanelPress(obj,value)  
    -- show the iPanel & configure all the buttons to say the right stuff
    if not iPanel.hidden then 
        iPanel:ToggleVisibility()
        return 
    end
    
    iPanelpID = obj.pID
    iPaneltID = obj.tID --nil for specs
    iPanelName = obj.pName
    iPanelDeadPlayer = obj.deadPlayer --true iff this is the iPanel of a dead player panel
        
    iPanelLayout:ClearChildren()

    -- add children, calc height
    local h = 0
    
    -- share stuff 
    if not iPanelDeadPlayer and not IsTakeable(iPaneltID) and not players[myPlayerID].spec and not players[iPanelpID].spec and iPanelpID~=myPlayerID and Spring.GetGameFrame()>0 and (Spring.IsCheatingEnabled() or Spring.AreTeamsAllied(players[myPlayerID].tID, players[iPanelpID].tID)) then
        iPanelLayout:AddChild(shareres_panel)
        h = h + 2*iPanelItemHeight + 63
    end

    -- take stuff
    if IsTakeable(iPaneltID) and not players[myPlayerID].spec then 
        iPanelLayout:AddChild(take)
        h = h + iPanelItemHeight    
    end

    -- watch cam
    if not iPanelDeadPlayer and (players[myPlayerID].spec or Spring.ArePlayersAllied(myPlayerID, iPanelpID)) and not players[iPanelpID].isAI then
        iPanelLayout:AddChild(watchcamera)
        h = h + iPanelItemHeight
    end
    
    -- watch res
    if iPaneltID and players[myPlayerID].spec and not iPanelDeadPlayer then 
        iPanelLayout:AddChild(watchres)
        h = h + iPanelItemHeight
    end
    
    -- watch los (specfullview)
    if not players[iPanelpID].spec and players[myPlayerID].spec then
        iPanelLayout:AddChild(watchlos)
        local a,notFullView,c = Spring.GetSpectatingState()
        if notFullView then
            watchlos:SetCaption("watch los")
        else
            watchlos:SetCaption("un-watch los")
        end
        h = h + iPanelItemHeight
    end

    -- ignore
    if obj.pID~=myPlayerID and not players[iPanelpID].isAI and not iPanelDeadPlayer then
        if WG.ignoredPlayers[players[obj.pID].plainName] then
            ignore:SetCaption('un-ignore')
        else    
            ignore:SetCaption('ignore')
        end
        iPanelLayout:AddChild(ignore)
        h = h + iPanelItemHeight
    end
    
    -- slap
    if Spring.GetGameFrame()>2 and not players[iPanelpID].isAI and not iPanelDeadPlayer then --because its a luarules action
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
    local sw, sh = Spring.GetWindowGeometry()
    iPanel:SetPos(math.min(x,sw-iPanelWidth),vsy-y-h) 
        
    -- draw iPanel in front of stack
    iPanel:SetLayer(1)
    stack:SetLayer(2)
    iPanel:Invalidate()
end

function HideIPanel()
    if not iPanel.hidden then
        iPanel:Hide()
    end
end


--------------------------------------------------------------------------------
-- player/spec panels
--------------------------------------------------------------------------------

local colorConv = {
    -- green -> yellow -> red, in 6 steps
    -- for cpu/ping icons
    [1] = {0.0, 1.0, 0.0, 1.0},
    [2] = {0.5, 1.0, 0.5, 1.0},
    [3] = {1.0, 0.0, 1.0, 1.0},
    [4] = {1.0, 0.0, 0.5, 1.0},
    [5] = {1.0, 0.0, 0.0, 1.0},
    [6] = {0.7, 0.0, 0.0, 1.0},
}

function ResBarPanel(pID)
    local tID = players[pID].tID
    local panelWidth = width.resBars
    local panelHeight = 20
    local panel = Chili.Control:New{
        name      = 'resBarPanel',
        right     = offset.resBars,
        height    = panelHeight, 
        width     = width.resBars,
        bordercolor = {0,0,0,0},
        padding   = {0,1,0,0},
        margin    = {0,0,0,0},
    }

    local hPadding = 1

    local hPos = hPadding/2
    for _,res in pairs(resources) do
        Chili.Progressbar:New{
            name   = res.name,
            parent = panel,
            x      = 0, 
            y      = hPos, 
            width  = '100%',        
            height = 8,
            color  = res.color,
            padding   = {0,0,0,0},
            margin    = {0,0,0,0},
            max = 1,
        }    
        hPos = hPos + (panelHeight-hPadding)/2
    end
    
    return panel
end

function ResTextPanel(pID)
    local tID = players[pID].tID
    local panelWidth = width.resText
    local panelHeight = 20
    local panel = Chili.Control:New{
        name      = 'resTextPanel',
        right     = offset.resText,
        height    = panelHeight, 
        width     = width.resText,
        bordercolor = {0,0,0,0},
        padding   = {0,1,0,0},
        margin    = {0,0,0,0},
    }
    
    local x = 1
    for _,res in ipairs(resources) do
        Chili.TextBox:New{
            parent = panel,
            name = res.name,
            text = '',
            x = x,
            y = 4,
            width = width.resText/2,
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
                size             = 13,
            },
        }
        x = x + width.resText/2
    end

    return panel
end

function PlayerPanel(pID)

    local panel = Chili.Button:New{
        name        = "player_panel_" .. tostring(pID),
        width       = '100%',
        minHeight   = 17,
        resizeItems = false,
        autosize    = true,
        padding     = {5,0,0,0},
        itemPadding = {0,0,0,0},
        itemMargin  = {0,0,0,0},
        borderColor = {0,0,0,0},
        backgroundColor = buttonColour,
        caption     = "",
        onclick     = {iPanelPress},
        children    = {},
        pID         = pID,
        tID         = players[pID].tID,
        pName       = players[pID].name,
        deadPlayer  = false,
    }
   
    --children in order from R to L

    local ping = Chili.Image:New{
        parent = panel,
        name = "ping",
        height = 17,
        y = 3,
        width = width.ping,
        right = offset.ping,
        file = pingPic, 
    }

    local cpu = Chili.Image:New{
        parent = panel,
        name = "cpu",
        height = 17,
        y = 3,
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

    if options.resBars then
        local resBars = ResBarPanel(pID)
        panel:AddChild(resBars)
        if not players[pID].canShowResInfo then
            resBars:Hide()
        end
    end
    
    if options.resText then
        local resText = ResTextPanel(pID)
        panel:AddChild(resText)
        if not players[pID].canShowResInfo then
            resText:Hide()
        end
    end

    local name = Chili.TextBox:New{
        parent      = panel,
        name        = "name",
        text        = players[pID].name,
        right       = offset.name,
        width       = width.name,
        autoHeight  = false,
        height      = 20,
        y           = 4,
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
    
    if options.ready_faction then
        local readystate = Chili.Image:New{
            parent = panel,
            name = "readystate",
            height = 17,
            y      = 3,
            width = width.faction,
            right = offset.faction,
            file  = readyPic, 
            color = ReadyColour(players[pID].readyState)
        }
        -- faction image is created when game starts, readystate image is then hidden
    end
    
    if options.ranks then
        local rank = Chili.Image:New{
            parent = panel,
            name = "rank",
            height = 17,
            y = 3,
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
            y = 3,
            width = width.flag,
            right = offset.flag,
            file = players[pID].flagPic,
        }
    end

    return panel
end

function DeadPanel(pID)
    local panel = Chili.Button:New{
        name        = "dead_panel_" .. tostring(pID),
        parent      = panel,
        width       = '100%',
        minHeight   = 17,
        padding     = {0,0,0,0},
        itemPadding = {0,0,0,0},
        itemMargin  = {0,0,0,0},
        borderColor = {0,0,0,0},
        backgroundColor = buttonColour,
        children    = {},
        caption     = "",
        onclick     = {iPanelPress},
        pID         = pID,
        tID         = players[pID].tID, 
        pName       = players[pID].deadname,
        deadPlayer  = true,
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
    local panel = Chili.Button:New{
        name        = "spec_panel_" .. tostring(pID),
        parent      = panel,
        width       = width.name,
        right       = offset.name,
        minHeight   = 12,
        padding     = {0,0,0,0},
        itemPadding = {0,0,0,0},
        itemMargin  = {0,0,0,0},
        borderColor = {0,0,0,0},
        backgroundColor = buttonColour,
        children    = {},
        caption     = "",
        onclick     = {iPanelPress},
        pID         = pID,
        tID         = nil,
        pName       = players[pID].name,
        deadPlayer  = false,
    }
    
    local name = Chili.TextBox:New{
        parent      = panel,
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

function format(num, idp)
  return string.format("%." .. (idp or 0) .. "f", num)
end
local function readable(num)
    local s = ""
    if num < 0 then
        s = '-'
    else
        s = '+'
    end
    num = math.abs(num)
    if num < 1000 then
        s = s .. format(num,1)
    elseif num >= 10000 then
        s = s .. format(num/1000,0)..'k'
    elseif num >= 1000 then
        s = s .. format(num/1000,1)..'k'
    else
        s = s .. format(num,0)
    end
    return s
end

function SetFaction(pID) 
    --set faction, from TeamRulesParam when possible and from initial info if not    
    local startUDID = Spring.GetTeamRulesParam(players[pID].tID, 'startUnit')
    local faction
    if startUDID == armcomDefID then 
        faction = "arm"
    elseif startUDID == corcomDefID then
        faction = "core"
    else
        _,_,_,_,faction = Spring.GetTeamInfo(players[pID].tID)
    end
       
    if faction then
        players[pID].faction = faction
        if players[pID].dark then
            players[pID].factionPic = "LuaUI/Images/playerlist/"..faction.."WO_default.png"
        else
            players[pID].factionPic = "LuaUI/Images/playerlist/"..faction.."_default.png"
        end
    else
        players[pID].factionPic = "LuaUI/Images/playerlist/default.png"
    end
end

function IsTakeable(tID) 
    if not tID then return false end
    local _,_,_,_,_,aID,_,_ = Spring.GetTeamInfo(tID)
    if aID ~= Spring.GetMyAllyTeamID() then return false end
    if tID == Spring.GetMyTeamID() then return false end
    local spec,_ = Spring.GetSpectatingState()
    if spec then return false end
    
    if Spring.GetTeamRulesParam(tID, "numActivePlayers") == 0 then
        local units = Spring.GetTeamUnitCount(tID)
        local energy = Spring.GetTeamResources(tID,"energy")
        local metal = Spring.GetTeamResources(tID,"metal")
        if units and energy and metal then
            if (units > 0) or (energy > 1000) or (metal > 100) then            
                return true
            end
        end
    end
    return false                    
end

function GetSkill(playerID)
    if players[playerID].isAI then return "" end 
    
    local customtable = select(10,Spring.GetPlayerInfo(playerID)) -- player custom table
    local tsMu = customtable.skill
    local tsMuNumber = tsMu and tonumber(tsMu:match("%d+%.?%d*"))
    local tsSigma = customtable.skilluncertainty
    local tskill = ""
    if tsMu then
        tskill = tsMuNumber or 0
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
    return tskill, tsMuNumber
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
    if country and country ~= "" then 
        return "LuaUI/Images/flags/"..string.upper(country)..".png"
    else
        return "LuaUI/Images/flags/_unknown.png"
    end
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

function CanShowResInfo(pID)
    local aID = players[pID].aID
    return (aID==myAllyTeamID) or (amISpec and not amIFullView) or (amISpec and amIFullView and aID==myAllyTeamID)
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

    players[pID].wasPlayer = Spring.GetGameRulesParam("player_" .. tostring(pID) .. "_wasPlayer") -- teamID of the most recent team for which this pID was a player

    local r,g,b = Spring.GetTeamColor(players[pID].wasPlayer or tID)
    players[pID].color = {r,g,b}
    players[pID].dark = IsDark(r,g,b)
    
    players[pID].plainName = name
    players[pID].name = ((not spec) and InlineColor(players[pID].color) or "") .. name --TODO use 'original' colors?
    players[pID].deadname = ((not spec) and InlineColor(players[pID].color) or "") .. deadPlayerName    
    
    players[pID].rank = rank 
    players[pID].rankPic = GetRankPic(rank)
    players[pID].country = country
    players[pID].flagPic = GetFlag(country)
    
    local tskill,tsMu = GetSkill(pID, isAI)
    players[pID].skill = tskill --string
    players[pID].tsMu = tonumber(tsMu) --number
        
    players[pID].active = active
    players[pID].spec = spec
    players[pID].ping = ping
    players[pID].cpu = cpu
    
    players[pID].readyState = Spring.GetGameRulesParam("player_" .. tostring(pID) .. "_readyState") or 0   
    players[pID].readyColour = ReadyColour(players[pID].readyState)
    

    -- set at gamestart
    players[pID].faction = nil
    players[pID].factionPic = nil 
    
    -- decide if we show res bars
    players[pID].canShowResInfo = CanShowResInfo(pID)

    -- panels
    players[pID].playerPanel = PlayerPanel(pID)
    players[pID].deadPanel = DeadPanel(pID)
    players[pID].specPanel = SpecPanel(pID)

    needUpdate = true
end

local AIID = 1000 -- dummy pID for AI "players", starts counting at 1000

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

    players[pID].wasPlayer = true      

    local r,g,b = Spring.GetTeamColor(tID)
    players[pID].color = {r,g,b}
    players[pID].dark = IsDark(r,g,b)

    players[pID].plainName = name 
    players[pID].name = (InlineColor(players[pID].color) or "") .. name --TODO use 'original' colors?
    players[pID].deadname = (InlineColor(players[pID].color) or "") .. deadPlayerName    

    -- rank, country and skill are nil
    players[pID].skill = ""
    players[pID].tsMu = -1

    players[pID].active = active
    players[pID].spec = false or isDead
    players[pID].ping = ping
    players[pID].cpu = cpu
    
    players[pID].readyState = 0
    players[pID].readyColour = {0.1,0.1,0.97,1}
    
    -- set at gamestart
    players[pID].faction = nil
    players[pID].factionPic = nil 

    -- decide if we show res bars
    players[pID].canShowResInfo = CanShowResInfo(pID)

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

function UpdateResText(pID)
    if not options.resText then return end
    local panel = players[pID].playerPanel:GetChildByName('resTextPanel')
    
    -- should we show the res text?
    local canShowResInfo = players[pID].canShowResInfo 
    if canShowResInfo and panel.hidden then
        panel:Show()
    elseif not canShowResInfo and panel.visible then
        panel:Hide()
    end

    if not players[pID].canShowResInfo then return end
    local tID = players[pID].tID

    -- update values
    for _,res in ipairs(resources) do
        local currentLevel, storage, pull, income, expense, share, sent, received = Spring.GetTeamResources(tID, res.name)
        panel:GetChildByName(res.name):SetText(res.textColor .. readable(income))
    end    
end

function UpdateResBars(pID)
    if not options.resBars then return end
    local panel = players[pID].playerPanel:GetChildByName('resBarPanel')
    
    -- should  we show these resbars?
    local canShowResInfo = players[pID].canShowResInfo
    if canShowResInfo and panel.hidden then
        panel:Show()
    elseif not canShowResInfo and panel.visible then
        panel:Hide()
    end
    
    if not players[pID].canShowResInfo then return end
    local tID = players[pID].tID
    
    -- update values
    for _,res in ipairs(resources) do
        local currentLevel, storage, pull, income, expense, share, sent, received = Spring.GetTeamResources(tID, res.name)
        panel:GetChildByName(res.name):SetValue(currentLevel/storage)
    end
end

function UpdatePingCPU(pID, ping, cpu)
    -- update ping/cpu
    players[pID].ping = ping -- in ms
    players[pID].cpu = cpu -- in [0,1]

    local n_cpu = cpuLevel(cpu)
    local n_ping = math.min(6, 1 + math.floor(ping*1000/300))
    
    players[pID].playerPanel:GetChildByName('cpu').color = colorConv[n_cpu]
    players[pID].playerPanel:GetChildByName('ping').color = colorConv[n_ping]
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
    update, players[pID].wasPlayer = CheckChange(players[pID].wasPlayer, Spring.GetGameRulesParam("player_" .. tostring(pID) .. "_wasPlayer"), update)
    if update then
        -- if the tID/aID changed, we need to update the name color & the team associated to the players DeadPanel
        if not spec then
            local r,g,b = Spring.GetTeamColor(players[pID].wasPlayer or tID)
            players[pID].color = {r,g,b}
        end
        
        players[pID].name = ((not spec) and InlineColor(players[pID].color) or "") .. name 
        players[pID].deadname = ((not spec) and InlineColor(players[pID].color) or "") .. deadPlayerName    
        
        players[pID].playerPanel:GetChildByName('name'):SetText(players[pID].name)
        players[pID].deadPanel:GetChildByName('name'):SetText(players[pID].deadname)
        players[pID].deadPanel.tID = players[pID].tID
        players[pID].deadPanel.name = players[pID].deadname
        players[pID].specPanel:GetChildByName('name'):SetText(players[pID].name)        

        if players[pID].playerPanel:GetChildByName('faction') then
            players[pID].playerPanel:GetChildByName('faction').color = players[pID].color
        end
    end
    
    -- check if a player leaves/resigns/appears
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
-- Take
--------------------------------------------------------------------------------

function ProcessTake()
    local afterE = Spring.GetTeamResources(takeInfo.team,"energy")
    local afterM = Spring.GetTeamResources(takeInfo.team, "metal")
    local afterU = Spring.GetTeamUnitCount(takeInfo.team)
    local toSay = "say a: I took " .. takeInfo.name .. "."

    if afterE and afterM and afterU then
        if afterE > 1.0 or afterM > 1.0 or  afterU > 0 then
            toSay = toSay .. "\255\1\255\1" .. " Left  " .. math.floor(afterU) .. " units, " .. math.floor(afterE) .. " energy and " .. math.floor(afterM) .. " metal."
        end
    end

    Spring.SendCommands(toSay)
    takeInfo = nil
end


--------------------------------------------------------------------------------
-- Callins
--------------------------------------------------------------------------------

function widget:Initialize()
    Spring.SendCommands('unbind Any+h sharedialog')
    WG.PlayerList = {}

    Chili = WG.Chili
    buttonColour = WG.buttonColour
    panelColour = WG.panelColour
    sliderColour = WG.sliderColour
    
    -- add player list options to main menu
    SetupOptions()  

    CalculateOffsets()

    -- disable engine player info 
    if (Spring.GetConfigInt("ShowPlayerInfo")==1) then
        Spring.SendCommands("info 0")
    end

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
end

function widget:GamePreload()
    if WG.isMission then
    
    end
end

function widget:Shutdown()
    WG.PlayerList = nil

    window:Dispose()
    iPanel:Dispose()
    for pID,_ in pairs(players) do
        players[pID].playerPanel:Dispose()
        players[pID].deadPanel:Dispose()
        players[pID].specPanel:Dispose()
    end
    
    Spring.SendCommands('bind Any+h sharedialog')

    -- re-enable engine player info 
    if (Spring.GetConfigInt("ShowPlayerInfo")==0) then
        Spring.SendCommands("info 1")
    end
end

function widget:PlayerChanged(pID)
    UpdateMyStates()
    ScheduledUpdate()
end

function widget:GameFrame(n)
    -- show factions just after game starts
    if not gameStarted and n>1 then
        gameStarted = true
        ScheduledUpdate()
        
        if options.ready_faction then
            for pID,_ in pairs(players) do
                SetFaction(pID)
            
                players[pID].playerPanel:GetChildByName('readystate'):Hide()
            
                Chili.Image:New{
                    parent = players[pID].playerPanel,
                    name = 'faction',
                    height = 17,
                    y = 3,
                    width = width.faction,
                    right = offset.faction,
                    file = players[pID].factionPic,
                    color = players[pID].color,
                }
            end
        end
        
        needUpdate = true
    end
    
    -- make buttons for takeable players flash
    if n%20==0 and not players[myPlayerID].spec then
        local color
        if n%40==0 then
            color = {1,1,1,1}
        else
            color = {1,0.8,0,1}
        end
        for pID,_ in pairs(players) do
            if IsTakeable(players[pID].tID) then
                players[pID].playerPanel.backgroundColor = color
            end
        end
    
    end
    
    -- handle take
    if takeInfo and n >= takeInfo.onFrame+32 then --taking can take a while, not sure why
        ProcessTake()
    end
    
    -- update res text in header
    if n%15==1 then
        UpdateHeaders()
    end
    
    -- update resbars and restext in player panels
    -- this has to be done every frame, and we also need to check every frame that we have access to the relevent info & show/hide as appropriate
    UpdateMyStates()
    for pID,_ in pairs(players) do
        local canShowResInfo = CanShowResInfo(pID)
        local forceUpdate = (canShowResInfo~=players[pID].canShowResInfo)
        if forceUpdate then
            players[pID].canShowResInfo = canShowResInfo
        end
        
        UpdateResBars(pID)
        if n%15==1 or forceUpdate then
            UpdateResText(pID)
        end
    end
end

local prevTimer = Spring.GetTimer()
function widget:Update()
    UpdateMyStates()

    if needUpdate then
        UpdateStack()
        HideIPanel()
        needUpdate = false
    end

    local timer = Spring.GetTimer()
    if Spring.DiffTimers(timer,prevTimer)>0.33 then
        ScheduledUpdate()
        prevTimer = timer
    end    
end

function widget:KeyPress()
    HideIPanel()
    return false
end

function IsInRectPanel(mx,my,panel)
    return (panel.x<mx and mx<panel.x+panel.width and panel.y<my and my<panel.y+panel.height)
end

function widget:MousePress(mx,my)
    -- hide the iPanel if we click outside of the playerlist
    if (not IsInRectPanel(mx,Chili.Screen0.height-my, window)) and (not IsInRectPanel(mx, Chili.Screen0.height-my, iPanel)) then
        HideIPanel()
    end
    return false
end


--------------------------------------------------------------------------------
-- Team/AllyTeam tables & sorting
--------------------------------------------------------------------------------

function SetupAllyTeams()
    -- create allyteams tables
    myAllyTeam = {}
    allyTeams = {}
    allyTeamOrder = {} -- because ally team idxs start at 0 and lua idxs starts at 1
    
    allyTeamList = Spring.GetAllyTeamList()
    local gaiaTeamID = Spring.GetGaiaTeamID()
    
    for _,aID in ipairs(allyTeamList) do
        local teamList = Spring.GetTeamList(aID)
        for _,tID in ipairs(teamList) do
            if tID~=gaiaTeamID then
                if aID~=myAllyTeamID then
                    if not allyTeams[aID] then
                        allyTeams[aID] = {}
                        table.insert(allyTeamOrder, aID)
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
            -- live or dead player (panel assignment will act appropriately)
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

function tID_compare(tID_1, t_ID2)
    local ts_1 = GetMaxTS(tID_1)
    local ts_2 = GetMaxTS(tID_2)
    if ts_1 and ts_2 then return (ts_1>ts_2) end
    return (tID_1<tID_2)
end

function aID_compare(aID_1, aID_2)
    return aID_1<aID_2
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
    table.sort(allyTeamOrder,aID_compare)

    -- sort teams with other allyTeams
    for aID,_ in pairs(allyTeams) do
        table.sort(allyTeams[aID],tID_compare)
    end    
end    


--------------------------------------------------------------------------------
-- Stack helper controls
--------------------------------------------------------------------------------

function Header(text)
    local panel = Chili.Control:New{
        width       = '100%',
        minHeight   = 18,
        resizeItems = false,
        autosize    = true,
        padding     = {0,0,0,0},
        itemPadding = {0,0,0,0},
        itemMargin  = {0,0,0,0},
        children    = {},
    }

    local resWidth = 50
    
    local name = Chili.TextBox:New{
        parent      = panel,
        text        = text,
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
    
    local r = (offset.ts or offset.ping) + resWidth 
    for _,res in ipairs(resources) do
        Chili.TextBox:New{
            parent = panel,
            name = res.name,
            text = '',
            right = r,
            width = resWidth,
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
        r = r - resWidth
    end

    return panel
end

function Separator() 
    local separator = Chili.Line:New{
        width   = '100%',
    }
    return separator
end

function HalfSeparatorThin()
    local separator = Chili.Line:New{
        width   = 250,
        x       = offset.max - offset.name - width.name + 100,
        maxheight = 4,
    }
    return separator
end

function HalfSeparatorThick()
    local separator = Chili.Line:New{
        width   = 250,
        x       = offset.max - offset.name - width.name + 100,
    }
    return separator
end

--------------------------------------------------------------------------------
-- Stack construction
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

    if options.resBars then
        offset.resBars = o
        o = o + width.resBars
    end
    
    if options.resText then
        offset.resText = o
        o = o + width.resText
    end

    offset.name = o
    o = o + width.name
    
    o = o + 2
    
    if options.ready_faction or WG.isMission then -- if it's a mission, this will be hidden, but we want the space there to make a margin
        offset.faction = o 
        o = o + width.faction
    else
        offset.faction = 500 --out of the way, it will be hidden anyway
    end
    
    if options.ranks then
        offset.rank = o
        o = o + width.rank 
    else
        offset.rank = 500 
    end
    
    o = o + 1
    
    if options.flags then
        offset.flag = o
        o = o + width.flag
    else
        offset.flag = 500 
    end
    
    o = o + 16 --left margin
    offset.max = o
    
    WG.PlayerList.width = offset.max
end

function SetupStack()

    window = Chili.Window:New{
        parent    = Chili.Screen0,
        right     = 0,
        bottom    = 0,
        width     = offset.max,
        minHeight = 50,
        minWidth  = 1,
        autosize  = true,
        color = buttonColour,
        caption = "",
        children  = {},
    }

    stack = Chili.LayoutPanel:New{
        parent      = window,
        name        = 'stack',
        width       = '100%',
        minHeight   = 50,
        resizeItems = false,
        autosize    = true,
        padding     = {0,5,0,0},
        itemPadding = {0,0,0,0},
        itemMargin  = {0,0,0,0},
        children    = {},
        preserveChildrenOrder = true,
    }
    
    UpdateStack()
end

function UpdateStack()
    stack:ClearChildren()

    -- re-sort players into teams/allyteams
    SetupAllyTeams()
    AssignPlayersToTeams()
    SortTeams()
    SortAllyTeams()
    
    -- choose if we'll show a header for enemy each ally team or just one for them all
    local nAllyTeams = #Spring.GetAllyTeamList() - 1 -- -1 for gaia
    headerMode = (nAllyTeams<=8) and "individual" or "compound"
    
    -- re-make stack
    -- allies first
    local allyHeader = Header(" ALLIES")
    headers[myAllyTeamID] = allyHeader
    stack:AddChild(allyHeader)
    for _,tID in ipairs(myAllyTeam) do
        for _,pID in ipairs(teams[tID]) do
            if players[pID].spec or not players[pID].active then
                stack:AddChild(players[pID].deadPanel)
            else
                stack:AddChild(players[pID].playerPanel)            
            end
        end
    end
    stack:AddChild(Separator())

    -- enemies seconds
    if headerMode=="compound" then
        local enemyHeader = Header(" ENEMIES")
        headers[-1] = enemyHeader
        stack:AddChild(enemyHeader)
    end    
    local n_allies = CountTable(allyTeams)
    local n = 0
    for i,aID in pairs(allyTeamOrder) do        
        if headerMode=="individual" then
            local enemyHeader = Header(" ENEMIES " .. (#allyTeamOrder>1 and tostring(i) or "")) --aIDs start at 0 :(
            headers[aID] = enemyHeader
            stack:AddChild(enemyHeader)        
        end
    
        for _,tID in ipairs(allyTeams[aID]) do
            for _,pID in ipairs(teams[tID]) do
                if players[pID].spec or not players[pID].active then
                    stack:AddChild(players[pID].deadPanel)
                else
                    stack:AddChild(players[pID].playerPanel)            
                end
            end
        end
        
        n = n + 1
        if n < n_allies then
            if headMode=="compound" then
                stack:AddChild(HalfSeparatorThin())
            else
                stack:AddChild(HalfSeparatorThick())            
            end
        end
    end

    -- specs third
    if #deadPlayers + #specs >= 1 then
        stack:AddChild(Separator())
        stack:AddChild(Header("SPECTATORS")) --already filtered for being active
        for _,pID in ipairs(deadPlayers) do 
            stack:AddChild(players[pID].specPanel)
        end
        for _,pID in ipairs(specs) do
            stack:AddChild(players[pID].specPanel)
        end 
    end    
    
    UpdateHeaders()
end

function UpdateHeaders()
    -- update the m/e res text shown in headers
    if not options.headerRes then return end
    UpdateMyStates() 

    local allyTeamList = Spring.GetAllyTeamList()

    -- prepare tables
    local allyRes = {}
    local enemyRes = {}
    for _,res in ipairs(resources) do
        local resName = res.name
        for _,aID in pairs(allyTeamList) do
            allyRes[aID] = allyRes[aID] or {}
            allyRes[aID][resName] = {}
            allyRes[aID][resName].lev      = 0
            allyRes[aID][resName].storage  = 0
            allyRes[aID][resName].income   = 0
            allyRes[aID][resName].expense  = 0
        end
        enemyRes[resName] = {}
        enemyRes[resName].lev      = 0
        enemyRes[resName].storage  = 0
        enemyRes[resName].income   = 0
        enemyRes[resName].expense  = 0
    end
    
    -- count up the income etc of ally teams
    for _,aID in ipairs(allyTeamList) do
        local teamList = Spring.GetTeamList(aID)
        for _,tID in ipairs(teamList) do
            for _,res in ipairs(resources) do
                local resName = res.name
                local currentLevel, storage, pull, income, expense, share, sent, received = Spring.GetTeamResources(tID, resName)   
                if currentLevel then
                    allyRes[aID][resName].lev      = allyRes[aID][resName].lev + currentLevel
                    allyRes[aID][resName].storage  = allyRes[aID][resName].storage + storage
                    allyRes[aID][resName].income   = allyRes[aID][resName].income + income
                    allyRes[aID][resName].expense  = allyRes[aID][resName].expense + expense                 
                    if aID~=myAllyTeamID and amISpec and not amIFullView then
                        enemyRes[resName].lev     = enemyRes[resName].lev + currentLevel
                        enemyRes[resName].storage = enemyRes[resName].storage + storage
                        enemyRes[resName].income  = enemyRes[resName].income + income
                        enemyRes[resName].expense = enemyRes[resName].expense + expense            
                    end
                end
            end
        end    
    end    
    
    -- write headers
    for _,res in ipairs(resources) do
        local resName = res.name        
        local allyResText = res.textColor .. readable(allyRes[myAllyTeamID][resName].income)        
        headers[myAllyTeamID]:GetChildByName(resName):SetText(allyResText)        

        if amISpec and not amIFullView then
            if headerMode=="compound" then 
                local enemyResText = res.textColor .. readable(enemyRes[resName].income)             
                headers[-1]:GetChildByName(resName):SetText(enemyResText)
            else -- "individual"
                for _,aID in pairs(allyTeamList) do
                    if headers[aID] then 
                        local enemyResText = res.textColor .. readable(allyRes[aID][resName].income)
                        headers[aID]:GetChildByName(resName):SetText(enemyResText)
                    end
                end
            end        
        end
    end
end


--------------------------------------------------------------------------------
-- Options
--------------------------------------------------------------------------------

function SetupOptions()
    if not WG.MainMenu then return end

    -- add options into main menu, to show/hide flags, ranks and ts values (and not ready/faction)
    local function FlagState(_,show)
        options.flags = show
        OptionChange()
    end
    local function RankState(_,show)
        options.ranks = show
        OptionChange()
    end
    local function TSState(_,show)
        options.ts = show
        OptionChange()
    end
    local function ResBarState(_,show)
        options.resBars = show
        OptionChange()
    end
    local function ResTextState(_,show)
        options.resText = show --fixme: implement
        OptionChange()
    end
    local function HeaderResState(_,show)
        options.headerRes = show --fixme: implement
        OptionChange()
    end
    
    WG.MainMenu.AddWidgetOption{
        name = widget:GetInfo().name,
        children = {
            Chili.Checkbox:New{caption='Show Flags',x='10%',width='80%',
                    checked=options.flags,OnChange={FlagState}}, --toggle doesn't work
            Chili.Checkbox:New{caption='Show Ranks',x='10%',width='80%',
                    checked=options.ranks,OnChange={RankState}},
            Chili.Checkbox:New{caption='Show TrueSkill',x='10%',width='80%',
                    checked=options.ts,OnChange={TSState}},
            Chili.Checkbox:New{caption='Show Resource Bars',x='10%',width='80%',
                    checked=options.resBars,OnChange={ResBarState}},
            Chili.Checkbox:New{caption='Show Incomes',x='10%',width='80%',
                    checked=options.resText,OnChange={ResTextState}},
            Chili.Checkbox:New{caption='Show Summed Incomes',x='10%',width='80%',
                    checked=options.headerRes,OnChange={HeaderResState}},
        }
    }   
end

function OptionChange()
    -- recalc the offsets 
    CalculateOffsets()
    window:Resize(offset.max,0)
    
    -- redraw all the player panels (with new offsets)
    for pID,_ in pairs(players) do
        players[pID].playerPanel:Dispose()
        players[pID].playerPanel = PlayerPanel(pID)
        players[pID].specPanel:Dispose()
        players[pID].specPanel = SpecPanel(pID)
        players[pID].deadPanel:Dispose()
        players[pID].deadPanel = DeadPanel(pID)
    end
    ScheduledUpdate()
    
    UpdateStack()
end

function widget:GetConfigData()
    return options
end

function widget:SetConfigData(data)
    if data then
        options = data
    end
end
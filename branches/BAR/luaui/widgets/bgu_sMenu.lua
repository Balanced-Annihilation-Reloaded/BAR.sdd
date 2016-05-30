--  TODO add build progress bar?
function widget:GetInfo()
    return {
        name      = 'Selection Menu',
        desc      = 'Interface for issuing build orders and unit commands',
        author    = 'Funkencool, Bluestone',
        date      = '2013+',
        license   = 'GNU GPL v2',
        layer     = 0,
        enabled   = true,
        handler   = true,
    }
end
--------------

local imageDir = 'luaui/images/buildIcons/'

-- menu categories & dimensions --
local catNames = {'ECONOMY', 'BATTLE', 'FACTORY', 'LOADED'} -- order matters
local loadedMenuCat = 4
local selectedTab

local wantedBuildCols --min
local wantedBuildRows
local maxBuildCols
local maxBuildRows
local wantedPaddingCols  -- determines how the shape of the unit buttons vary as their number/grid changes, see resizeUI
local wantedPaddingRows

local orderRows
local orderCols

local hideFacBarOnBuild
local hideFacBarOnOrder

local relMenuFont = 14
local menuFont

local relFontSize = 16
local fontSize

local options = {
    showOrderTooltips = true,
    showStateTooltips = true,
    showBuildTooltips = true,
}

-- custom command IDs for LuaUIs CMD table
local CMD_UNIT_SET_TARGET = 34923
CMD.UNIT_SET_TARGET = CMD_UNIT_SET_TARGET
CMD[CMD_UNIT_SET_TARGET] = 'UNIT_SET_TARGET'

local CMD_UNIT_CANCEL_TARGET = 34924
CMD.UNIT_CANCEL_TARGET = CMD_UNIT_CANCEL_TARGET
CMD[CMD_UNIT_CANCEL_TARGET] = 'UNIT_CANCEL_TARGET'

local CMD_UNIT_SET_TARGET_RECTANGLE = 34925
CMD.UNIT_SET_TARGET_RECTANGLE = CMD_UNIT_SET_TARGET_RECTANGLE
CMD[CMD_UNIT_SET_TARGET_RECTANGLE] = 'UNIT_SET_TARGET_RECTANGLE'

local CMD_LAND_AT_AIRBASE = 35430
CMD.LAND_AT_AIRBASE = CMD_LAND_AT_AIRBASE
CMD[CMD_LAND_AT_AIRBASE] = "LAND_AT_AIRBASE"

local CMD_LAND_AT_SPECIFIC_AIRBASE = 35431
CMD.LAND_AT_SPECIFIC_AIRBASE = CMD_LAND_AT_SPECIFIC_AIRBASE
CMD[CMD_LAND_AT_SPECIFIC_AIRBASE] = "LAND_AT_SPECIFIC_AIRBASE"

local CMD_PASSIVE = 34571
CMD.PASSIVE = CMD_PASSIVE
CMD[CMD_PASSIVE] = 'PASSIVE'

local CMD_UPGRADEMEX = 31244
CMD.UPGRADEMEX = CMD_UPGRADEMEX
CMD[CMD_UPGRADEMEX] = 'UPGRADEMEX'

local CMD_AUTOMEX = 31143
CMD.AUTOMEX = CMD_AUTOMEX
CMD[CMD_AUTOMEX] = 'AUTOMEX'

-- expose order colours (matching cursors) to WG
local orderColours = {
    -- standard
    [CMD.MOVE]         = {0.20, 1.00, 0.00, 1.0},
    [CMD.FIGHT]        = {1.00, 0.30, 0.00, 1.0},
    [CMD.ATTACK]       = {1.00, 0.00, 0.00, 1.0},
    [CMD.PATROL]       = {0.10, 0.25, 0.95, 1.0},
    [CMD.STOP]         = {0.40, 0.00, 0.00, 1.0},
    [CMD.REPAIR]       = {0.50, 1.00, 1.00, 1.0},
    [CMD.GUARD]        = {0.07, 0.15, 0.65, 1.0},
    [CMD.WAIT]         = {0.80, 0.80, 0.80 ,1.0},
    [CMD.CAPTURE]      = {0.80, 0.00, 0.90, 1.0},
    [CMD.RECLAIM]      = {0.00, 0.60, 0.00, 1.0},
    [CMD.MANUALFIRE]   = {0.90, 0.90, 0.00, 1.0},
    [CMD.LOAD_UNITS]   = {0.50, 0.90, 0.90, 1.0},
    [CMD.LOAD_ONTO]    = {0.50, 0.90, 0.90, 1.0},
    [CMD.UNLOAD_UNITS] = {1.00, 0.95, 0.15, 1.0},
    [CMD.UNLOAD_UNIT]  = {1.00, 0.95, 0.15, 1.0},
    [CMD.STOCKPILE]    = {1.00, 1.00, 1.00, 1.0},
    [CMD.RESURRECT]    = {1.00, 0.20, 0.95, 1.0},
    [CMD.RESTORE]      = {0.50, 1.00, 0.20, 1.0},
    [CMD.AREA_ATTACK]  = {0.80, 0.00, 0.00, 1.0},
    -- etc
    [CMD.TIMEWAIT]     = {0.80, 0.80, 0.80 ,1.0},
    [CMD.DEATHWAIT]    = {0.80, 0.80, 0.80 ,1.0},
    [CMD.SQUADWAIT]    = {0.80, 0.80, 0.80 ,1.0},
    [CMD.GATHERWAIT]   = {0.80, 0.80, 0.80 ,1.0},
    [CMD.SELFD]        = {1.00, 1.00, 0.00, 1.0},
    -- custom
    [CMD.UNIT_SET_TARGET]    = {1.00, 0.65, 0.10, 1.0},
    [CMD.UNIT_CANCEL_TARGET] = {0.40, 0.00, 0.00, 1.0},
    [CMD.UPGRADEMEX]         = {0.60, 0.60, 0.60, 1.0},
    [CMD.AUTOMEX]            = {0.60, 0.60, 0.60, 1.0},
    [CMD.LAND_AT_AIRBASE]    = {0.50, 1.00, 1.00, 1.0},
    [CMD.LAND_AT_SPECIFIC_AIRBASE]= {0.50, 1.00, 1.00, 1.0},
}
WG.OrderColours = orderColours

-- commands we don't care about (wtf do some of these even do)
local ignoreCMDs = {
    selfd          = '',
    loadonto        = '',
    timewait        = '',
    deathwait    = '',
    squadwait       = '',
    gatherwait     = '',
}

-- orders menu layout, left->right with top line first
local defaultOrderMenuLayout = {
    [1] = {
    },
    [2] = {
        [1] = "repair",
        [2] = "reclaim",
        [3] = "upgrademex",
        [4] = "restore",
        [5] = "loadunits",
        [6] = "unloadunits",
        [7] = "settarget",
        [8] = "canceltarget",
    },
    [3] = {
        [1] = "move",
        [2] = "fight",
        [3] = "attack",
        [4] = "patrol",
        [5] = "guard",
        [6] = "areaattack",
        [7] = "wait",
        [8] = "stop",
    },
}
local orderMenuLayout = {}

-- states that are always displayed
local topStates = {
    [1] = "movestate",
    [2] = "firestate",
    [3] = "repeat",
}

local buttonColour, panelColour, sliderColour

-- state colours
local white = {1,1,1,1}
local grey = {0.2,0.2,0.2,1}
local black = {0,0,0,1}
local green = {0,1,0,1}
local darkgreen = {0,0.8,0,1}
local yellow = {1,1,0,1}
local orange = {1,0.5,0,1}
local red = {1,0,0,1}

local paramColours = {
    ['Hold fire']    = red,
    ['Return fire']  = orange,
    ['Fire at will'] = green,
    ['Hold pos']     = red,
    ['Maneuver']     = orange,
    ['Roam']         = green,
    ['Repeat off']   = red,
    ['Repeat on']    = green,
    ['Active']       = green,
    ['Passive']      = red,
    [' Fly ']        = green,
    ['Land']         = red,
    [' Off ']        = red,
    [' On ']         = green,
    ['UnCloaked']    = red,
    ['Cloaked']      = green,
    ['LandAt 0']     = red,
    ['LandAt 30']    = orange,
    ['LandAt 50']    = yellow,
    ['LandAt 80']    = green,
    ['UpgMex off']   = red,
    ['UpgMex on']    = green,
    ['Low traj']     = red,
    ['High traj']    = green,
}

-- order hotkeys
local Hotkey = {
    ["attack"] = "A",
    ["guard"] = "G",
    ["fight"] = "F",
    ["patrol"] = "P",
    ["reclaim"] = "E",
    ["loadonto"] = "L",
    ["loadunits"] = "L",
    ["unloadunit"] = "U",
    ["unloadunits"] = "U",
    ["stop"] = "S",
    ["wait"] = "W",
    ["repair"] = "R",
    ["manualfire"] = "D",
    ["cloak"] = "K",
    ["move"] = "M",
    ["resurrect"] = "O",
    ["settarget"] = "Y", --set target
    ["canceltarget"] = "J", --cancel target
}
------------



-- Chili vars --
local Chili
local panH, panW, winW, winH, winX, winB, tabH, minMapH, minMapW
local screen0, buildMenu, stateMenu, orderMenu, menuTabs
local menuTab = {}
local grid = {}
local orderGrid = {}

local buttonColour

local unitButtons = {} -- all cached
local orderButtons = {} -- all cached
local stateButtons = {} -- all cached

local darkenedMenuTabColor = {1.0, 0.7, 0.1, 0.8}
local menuTabColor = {1,1,1,1}

----------------

-- Spring Functions --
local spGetTimer              = Spring.GetTimer
local spDiffTimers            = Spring.DiffTimers
local spGetActiveCmdDesc      = Spring.GetActiveCmdDesc
local spGetActiveCmdDescs     = Spring.GetActiveCmdDescs
local spGetActiveCommand      = Spring.GetActiveCommand
local spGetCmdDescIndex       = Spring.GetCmdDescIndex
local spGetFullBuildQueue     = Spring.GetFullBuildQueue
local spGetSelectedUnits      = Spring.GetSelectedUnits
local spSendCommands          = Spring.SendCommands
local spSetActiveCommand      = Spring.SetActiveCommand
local spGetSpectatingState    = Spring.GetSpectatingState
local spGetUnitDefID          = Spring.GetUnitDefID
local spGetUnitIsTransporting = Spring.GetUnitIsTransporting
local max = math.max

-- Local vars --
local gameStarted = (Spring.GetGameFrame()>0)
local updateRequired = ''
local oldTimer = spGetTimer()
local sUnits = {}
local onlyTransportSelected
local activeSelUDID, activeSelCmdID

local r,g,b = Spring.GetTeamColor(Spring.GetMyTeamID())
local teamColor = {r,g,b,0.8}
local selectedColor = {1,1,1,1} -- colour overlay of unit icons for unit of selected build command

----------------
local function getInline(r,g,b)
    if type(r) == 'table' then
        return string.char(255, (r[1]*255), (r[2]*255), (r[3]*255))
    else
        return string.char(255, (r*255), (g*255), (b*255))
    end
end

local function CountTable(t)
    local n = 0
    for _,_ in pairs(t) do
        n = n + 1
    end
    return n
end

---------------------------------------------------------------
-- ui positions etc

local function FinalizeOrderGrid()
    -- use more order rows if the order buttons won't fit into the screen width
    -- we allow for up to 24 order buttons in up to 3 rows, with all non-fixed buttons going into the top row
    -- the (max) number of buttons per row is always a multiple of 8
    local vsx,_ = Spring.GetViewGeometry()
    local availableWidth 
    if WG.PlayerList and WG.PlayerList.width then
        availableWidth = vsx - WG.PlayerList.width - WG.UIcoords.orderMenu.x -- player list is in BR corner
	else
        availableWidth = vsx - WG.UIcoords.orderMenu.x 
    end

    local availableButtonsPerRow = math.floor(availableWidth / WG.UIcoords.orderMenuButton.w)
    availableButtonsPerRow = math.floor(availableButtonsPerRow/8)*8 -- round down to the nearest 8
    availableButtonsPerRow = math.max(availableButtonsPerRow, 1) -- in case user has the worlds smallest screen
    local neededRows = math.ceil(24 / availableButtonsPerRow)

    orderRows = math.max(orderRows, neededRows)
    orderCols = availableButtonsPerRow

    -- now set the order menu layout to match the number of rows we actually use
    -- merge downwards, collect in bottom row
    orderMenuLayout = {}
    local rowOffset = #defaultOrderMenuLayout - orderRows
    for i=1,#defaultOrderMenuLayout do
        orderMenuLayout[i] = {}
    end
    for i=1,#defaultOrderMenuLayout do
        for j=1,#defaultOrderMenuLayout[i] do
            local row = math.min(#orderMenuLayout, i+rowOffset)
            table.insert(orderMenuLayout[row], defaultOrderMenuLayout[i][j])
        end
    end
end


local function resizeUI()
    local vsx,vsy = Spring.GetViewGeometry()

    -- fontSize
    fontSize = WG.RelativeFontSize(relFontSize) -- labels on buttons
    menuFont = WG.RelativeFontSize(relMenuFont)

    -- build grid dimensions
    wantedBuildRows = WG.UIcoords.buildGrid.wantedRows
    wantedBuildCols = WG.UIcoords.buildGrid.wantedCols
    maxBuildRows    = WG.UIcoords.buildGrid.maxRows
    maxBuildCols    = WG.UIcoords.buildGrid.maxCols
    maxBuildGUICols = WG.UIcoords.buildGrid.maxGUICols

    -- when to show/hide the facBar 
    hideFacBarOnBuild = WG.UIcoords.buildMenu.hideFacBar
    hideFacBarOnOrder = WG.UIcoords.orderMenu.hideFacBar

    local buildMenuOrientation = WG.UIcoords.buildGrid.orientation
    for i=1,#catNames do
        grid[i].orientation = buildMenuOrientation
    end

    local i = selectedTab
    local buildGUICols = (i) and math.min(maxBuildGUICols, grid[i].columns) or 1

	-- build grid position
	local internalTabOffset = (WG.UIcoords.buildMenu.menuTabs=="internal" and menuFont*3 or 0)
    local bx = WG.UIcoords.buildMenu.x
    local by = WG.UIcoords.buildMenu.y + internalTabOffset
    local bh = WG.UIcoords.buildMenu.h - internalTabOffset
    local bw = WG.UIcoords.buildMenu.w * (buildGUICols / wantedBuildCols) -- better to keep consistent layout & not use small buttons when possible
	if WG.PlayerList.width and bx+bw>vsx-WG.PlayerList.width then 
		bw = vsx - bx - WG.PlayerList.width 
    end
    buildMenu:SetPos(bx,by,bw,bh)

    -- menu tabs (pinned to build menu)
	local tw = 0.07*vsx
	local th = menuFont*3
	if WG.UIcoords.buildMenu.menuTabs=="right" then
		menuTabs:SetPos(bx+bw, by, tw, bh)
	elseif WG.UIcoords.buildMenu.menuTabs=="top" then
		menuTabs:SetPos(bx, by-th, 3*tw, th)
	elseif WG.UIcoords.buildMenu.menuTabs=="internal" then
		menuTabs:SetPos(bx, WG.UIcoords.buildMenu.y, WG.UIcoords.buildMenu.w, internalTabOffset)
	end	
    makeMenuTabs() 

    -- build menu buttons
    for _,button in pairs(unitButtons) do
        local q = button.children[1].children[1]
        q.font.size = fontSize
        q:Invalidate()
        local hotkey = button.children[1].children[2]
        hotkey.font.size = fontSize
        hotkey:Invalidate()
    end

    -- state grid dimension
    stateMenu.rows = WG.UIcoords.stateGrid.rows
    stateMenu.columns = WG.UIcoords.stateGrid.cols

    -- state menu text
    for _,button in pairs(stateButtons) do
        button.font.size = fontSize
        button:Invalidate()
    end

    -- state menu position
    local sx = WG.UIcoords.stateMenu.x
    local sy = WG.UIcoords.stateMenu.y
    local sw = WG.UIcoords.stateMenu.w
    local sh = WG.UIcoords.stateMenu.h
    stateMenu:SetPos(sx,sy,sw,sh)

    -- order grid dimensions
    orderRows = WG.UIcoords.orderGrid.rows
    orderCols = WG.UIcoords.orderGrid.cols
    FinalizeOrderGrid()
    if orderRows>#orderMenuLayout then
        Spring.Echo("ERROR: max order rows is " .. #orderMenuLayout)
    end

    local align = WG.UIcoords.orderMenu.align
    local verticalOrderGrids = align == "left" or align == "right"
    local flipOrderGrids = align == "left" or align == "top"

    -- order menu position
    local ox = WG.UIcoords.orderMenu.x
    local oy = WG.UIcoords.orderMenu.y
    local ow = verticalOrderGrids and WG.UIcoords.orderMenuButton.w * #orderMenuLayout or WG.UIcoords.orderMenuButton.w * orderCols
    local oh = verticalOrderGrids and WG.UIcoords.orderMenuButton.h * orderCols or WG.UIcoords.orderMenuButton.h * #orderMenuLayout
    orderMenu:SetPos(ox,oy,ow,oh)

    if verticalOrderGrids then
        orderMenu:SetOrientation("horizontal")
    else
        orderMenu:SetOrientation("vertical")
    end

    orderMenu:ClearChildren()
    local start, finish, step = flipOrderGrids and #orderMenuLayout or 1, flipOrderGrids and 1 or #orderMenuLayout, flipOrderGrids and -1 or 1
    for i=start, finish, step do
        orderGrid[i].columns = verticalOrderGrids and 1 or orderCols
        orderGrid[i].rows = verticalOrderGrids and orderCols or 1
        orderMenu:AddChild(orderGrid[i])
    end

    -- order buttons
    for _,button in pairs(orderButtons) do
        local hotkey = button.children[1].children[1]
        if hotkey then
            hotkey.font.size = fontSize
            hotkey:Invalidate()
        end
    end
end

local function showGrid(num)
    for i=1,#catNames do
        if  i == num and grid[i].hidden then
            grid[i]:Show()
        elseif i ~= num and grid[i].visible then
            grid[i]:Hide()
        end
    end
end

local function selectTab(self)
    if not self then return end

    local choice = self.tabNum
    showGrid(choice)
    selectedTab = choice
    resizeUI()

    local old = menuTab[menuTabs.prevChoice]
    if old then
        old.font.color = menuTabColor
        old:Invalidate()
    end

    local highLight = menuTab[choice]
    if highLight then
        highLight.font.color = darkenedMenuTabColor
        highLight:Invalidate()
    end

    menuTabs.choice = choice
	menuTabs.prevChoice = choice
end

local function scrollMenus(_,_,_,_,value)
    local choice = menuTabs.choice
    local maxMenuTab = 0
    for k,_ in pairs(menuTab) do
        maxMenuTab = math.max(maxMenuTab, k)
    end
    while (true) do
        choice = choice - value
        if choice<=0 then choice = maxMenuTab end
        if choice==maxMenuTab+1 then choice=0 end
        if menuTab[choice]~= nil then break end
    end -- Prevents zooming
    selectTab(menuTab[choice])
    return true -- prevents zooming
end

---------------------------------------------------------------
-- context hotkeys

local function ForceUpdateHotkeys()
    local hotkeys = WG.buildingHotkeys
    for uDID,key in pairs(hotkeys) do
        local button = unitButtons[uDID]
        local image = button.children[1]
        local hotkey = image.children[2]
        hotkey:SetCaption(key)
    end
end


---------------------------------------------------------------
-- give an order

local function cmdAction(obj, x, y, button, mods)
    if obj.disabled then return end
    if button~=1 and button~=3 then return false end

    -- if we are called from the LOADED tab, select the unload command
    -- TODO: implement new transporters and per unitDef unloading
    if obj.parent.name=="grid_LOADED" then
        local index = spGetCmdDescIndex(CMD.UNLOAD_UNITS)
        if (index) then
            local alt, ctrl, meta, shift = mods.alt, mods.ctrl, mods.meta, mods.shift
            local left, right = (button == 1), (button == 3)
            spSetActiveCommand(index, button, left, right, alt, ctrl, meta, shift)
        end
        return
    end

    -- if we are called from any other tab
    -- tell initial queue / set active command that we want to build this unit
    if not gameStarted then
        if  WG.InitialQueue then
            WG.InitialQueue.SetSelDefID(-obj.cmdId)
        end
    else
        local index = spGetCmdDescIndex(obj.cmdId)
        if (index) then
            local left, right = (button == 1), (button == 3)
            local alt, ctrl, meta, shift = mods.alt, mods.ctrl, mods.meta, mods.shift
            spSetActiveCommand(index, button, left, right, alt, ctrl, meta, shift)
        end
    end
    return true
end


---------------------------------------------------------------
-- active cmds

-- Loads the build queue
local function parseBuildQueue()
    local queue = {}
    local unitIDs = Spring.GetSelectedUnits()
    for i=1, #unitIDs do
        local list = Spring.GetRealBuildQueue(unitIDs[i]) or {}
        for i=1, #list do
            for defID, count in pairs(list[i]) do
                queue[defID] = queue[defID] and (queue[defID] + count) or count
            end
        end
    end
    return queue
end
local function parseInitialBuildQueue()
    local queue = {}
    local buildQueue = WG.InitialQueue and WG.InitialQueue.buildQueue or {}
    for i=1, #buildQueue do
        local defID = buildQueue[i][1]
        queue[defID] = queue[defID] and (queue[defID] + 1) or 1
    end
    return queue
end

-- Adds icons/commands to the menu panels accordingly
local function addBuild(item)
    -- unpack item
    local uDID = item.uDID
    local name = item.name
    local category = item.category
    local disabled = item.disabled

    -- prepare the button
    local button = unitButtons[uDID]
    local image = button.children[1]

    local queue = image.children[1]
    local hotkey = image.children[2]
    local overlay = image.children[3]

    local caption = item.count or ''
    queue:SetCaption(caption)
    local key = WG.buildingHotkeys[uDID] or ''
    hotkey:SetCaption(key)

    if disabled then
        -- building this unit is disabled
        button.focusColor[4] = 0
        overlay.color = {0.4,0.4,0.4,0.7} -- grey
        image.color = {0.4,0.4,0.4,0.7}
    else
        button.focusColor[4] = 0.5
		if uDID==activeSelUDID then
            button.borderColor = button.focusColor
            selectTab(menuTab[category])
        else
            overlay.color = teamColor
            image.color = {1,1,1,1}
            button.borderColor = {1,1,1,0.1}
        end
    end
    button.disabled = disabled

    -- avoid adding too many buttons
    if #grid[category].children>maxBuildCols*maxBuildRows-1 then return end
    if #grid[category].children==maxBuildCols*maxBuildRows-1 then
        Chili.bguButton:New{
            x = 5,
            parent = grid[category],
            caption = "(full)",
            padding   = {0,0,0,0},
            margin    = {0,0,0,0},
            borderColor = {1,1,1,0.1},
            backgroundColor = buttonColour,
            font = {
                size = 16
            }
        }
        return
    end

    -- add this button, no duplicates
	-- note: build buttons are only orphaned when the unit selection changes
    if not grid[category]:GetChildByName(button.name) then
        grid[category]:AddChild(button)
    end
end

local function addState(cmd)
    local caption = cmd.params[cmd.params[1] + 2]
    local name = cmd.action .. " " .. caption

    -- avoid adding too many
    if #stateMenu.children==stateMenu.rows*stateMenu.columns then
        local lastChild = stateMenu.children[#stateMenu.children]
        if lastChild.name == "full_state" then
            return
        end

        stateMenu:RemoveChild(lastChild)
        button = Chili.bguButton:New{
            name   = "full_state",
            parent = stateMenu,
            caption   = "(full)",
            padding   = {0,0,0,0},
            margin    = {0,0,0,0},
            OnMouseUp = {},
            borderColor = {1,1,1,0.1},
            backgroundColor = buttonColour,
            font      = {
                size  = fontSize,
            },
        }
        return
    end


    -- create the button if it does not already exist
    local button
    if stateButtons[name]==nil then
        button = Chili.bguButton:New{
            name      = name,
            caption   = caption,
            cmdName   = cmd.name,
            _tooltip   = cmd.tooltip,
            tooltip = options.showStateTooltips and cmd.tooltip,
            cmdId     = cmd.id,
            cmdAName  = cmd.action,
            padding   = {0,0,0,0},
            margin    = {0,0,0,0},
            OnMouseUp = {cmdAction},
            borderColor = {1,1,1,0.1},
            backgroundColor = buttonColour,
            font      = {
                color = paramColours[caption] or white,
                size  = fontSize,
            },
        }
        stateButtons[name] = button
    else
        -- use existing button
        button = stateButtons[name]
    end

    stateMenu:AddChild(button)
end

local function addDummyState(cmd)
    local name = cmd.action .. "_dummy"
    -- create the button if it does not already exists
    local button
    if not stateButtons[name] then
        button = Chili.bguButton:New{
            caption   = cmd.action,
            padding   = {0,0,0,0},
            margin    = {0,0,0,0},
            OnMouseUp = {},
            borderColor = {1,1,1,0.1},
            backgroundColor = buttonColour,
            font      = {
                color = grey,
                size  = fontSize,
            },
        }
        stateButtons[name] = button
    else
        button = stateButtons[name]
    end

    stateMenu:AddChild(button)
end

local function paddingState()
    return Chili.Control:New{
        padding   = {0,0,0,0},
        margin    = {0,0,0,0},
        OnMouseUp = {},
    }
end

local function addOrderButton(item)
    -- create the button if it does not already exist
    local button
    local cmd = item.cmd
    local cat = item.category
    local name = cmd.action
    if orderButtons[name] == nil then
        button = Chili.bguButton:New{
            name      = cmd.action,
            caption   = '',
            cmdName   = cmd.name,
            _tooltip   = cmd.tooltip,
            tooltip = options.showOrderTooltips and cmd.tooltip,
            cmdId     = cmd.id,
            cmdAName  = cmd.action,
            padding   = {0,0,0,0},
            margin    = {0,0,0,0},
            OnMouseUp = {cmdAction},
            borderColor = {1,1,1,0.1},
            backgroundColor = buttonColour,
            children  = {
                Chili.Image:New{
                    parent  = button,
                    x       = '15%',
                    bottom  = '15%',
                    y       = '15%',
                    right   = '15%',
                    color   = orderColours[cmd.id] or {1,1,1,1},
                    file    = imageDir..'Commands/'..cmd.action..'.png',
                    children = {
                        Chili.Label:New{
                            caption = Hotkey[name] or "",
                            right  = 0,
                            y = 0,
                            font = {
                                size = fontSize,
                                outline          = true,
                                autoOutlineColor = true,
                                outlineWidth     = 5,
                                outlineWeight    = 3,
                            }
                        },
                    }
                }
            }
        }
        if cmd.id==CMD.STOCKPILE then
            local stockpile_q = Chili.Label:New{name="stockpile_label",right=0,bottom=0,caption="", font={size=14,shadow=false,outline=true,autooutlinecolor=true,outlineWidth=4,outlineWeight=6}}
            button.children[1]:AddChild(stockpile_q)
        end
        orderButtons[name] = button
    else
        -- use existing button
        button = orderButtons[name]
    end

    -- prepare the button for display
    if cmd.id==CMD.STOCKPILE then
        local units = Spring.GetSelectedUnits()
        local num, queued = 0, 0
        for _,unitID in ipairs(units) do
            local n,q = Spring.GetUnitStockpile(unitID)
            num = num + (n or 0)
            queued = queued + (q or 0)
        end
        local stockPileLbl = button.children[1]:GetChildByName("stockpile_label")
        stockPileLbl:SetCaption(num.."/"..queued)
        stockPileLbl.font.size = fontSize
        stockPileLbl:Invalidate()
    end
    button.borderColor = (cmd.id==activeSelCmdID) and button.focusColor or {1,1,1,0.1}

    orderGrid[cat]:AddChild(button)
end

local function getOrderCat(action)
    for i=1,#orderMenuLayout do
        for j=1,#orderMenuLayout[i] do
            if orderMenuLayout[i][j]==action then
                return i
            end
        end
    end
    return 1 + #orderMenuLayout - orderRows -- top non-empty row
end

local function addDummyOrder(item)
    local button
    local action = item.action
    local cat = getOrderCat(action)
    local name = action .. "_dummy"
    if orderButtons[name] == nil then
        button = Chili.bguButton:New{
            name      = name,
            caption   = '',
            --tooltip   = cmd.tooltip .. getInline(orderColours[cmd.action]) .. HotkeyString(cmd.action),
            padding   = {0,0,0,0},
            margin    = {0,0,0,0},
            OnMouseUp = {},
            backgroundColor = buttonColour,
            Children  = {
                Chili.Image:New{
                    parent  = button,
                    x       = '15%',
                    bottom  = '15%',
                    y       = '15%',
                    right   = '15%',
                    color   = grey,
                    file    = imageDir..'Commands/'..action..'.png',
                }
            }
        }
        orderButtons[name] = button
    else
        button = orderButtons[name]
    end

    orderGrid[cat]:AddChild(button)
end

local function getBuildCat(ud)
    local menuCat
	if ud.isFactory or (ud.isBuilder and ud.speed==0) then
        -- Factories & Nanos
		menuCat = 3
    elseif (ud.speed > 0 and ud.canMove) then
        -- Units
        menuCat = 3
    elseif ud.isBuilding and (ud.energyMake>=20
                           or ud.isExtractor
                           or ud.tidalGenerator>0
                           or ud.windGenerator>0
                           or Spring.GetGameRulesParam(ud.name .. "_mm_capacity")
                           or ud.energyStorage>=3000
                           or ud.metalStorage>=1000)then
        -- Economy
        menuCat = 1
    else
        -- Battle
        menuCat = 2
    end

    return menuCat
end

local function AddInSequence(items, t, Add, dummyAdd)
    -- add any items in the array table t, in order, first
    -- if we can't find something from t, add a dummy instead
    for _,k in ipairs(t) do
        if items[k] then
            -- add top cmd
            Add(items[k])
            items[k] = nil
        else
            -- add dummy top cmd
            dummy_item = {action=k}
            dummyAdd(dummy_item)
        end
    end

    -- add the rest
    for _,item in pairs(items) do
        Add(item)
    end
end

local function AddInSortedOrder(items, Add, Comparator)
    -- add items in order of comparator
    table.sort(items, Comparator)
    for _,item in ipairs(items) do
        Add(item)
    end
end


local function parseCmds()
    local queue = parseBuildQueue()
    local cmdList = spGetActiveCmdDescs()

    local units = {}
    local orders = {}
    local states = {}

    -- Parses through each cmd and gives it its own button
    for i = 1, #cmdList do
        local cmd = cmdList[i]
        if cmd.name ~= '' and not (ignoreCMDs[cmd.name] or ignoreCMDs[cmd.action]) then
            -- Is it a unit and if so what kind?
            local menuCat
            if UnitDefNames[cmd.name] then
                local ud = UnitDefNames[cmd.name]
                menuCat = getBuildCat(ud)
            end

            if menuCat and #grid[menuCat].children<=maxBuildRows*maxBuildCols then
                buildMenu.active     = true
                grid[menuCat].active = true
                units[#units+1] = {name=cmd.name, uDID=-cmd.id, disabled=cmd.disabled, category=menuCat, count=(queue[-cmd.id] or cmd.params[1])} -- cmd.params[1] helps only in godmode
            elseif #cmd.params > 1 then
                states[cmd.action] = cmd
            elseif cmd.id > 0 then
                local cat = getOrderCat(cmd.action)
                orderMenu.active = true
                orderGrid[cat].active = true
                orders[cat] = orders[cat] or {}
                orders[cat][cmd.action] = {action=cmd.action, cmd=cmd, category=cat}
            end
        end
    end

    -- Include stop command
    if orderMenu.active then
        local cmd = {action='stop', id=CMD.STOP, tooltip="Stop: Clears the command queue"}
        local cat = getOrderCat("stop")
        orders[cat] = orders[cat] or {}
        orders[cat][cmd.action] = {action=cmd.action, cmd=cmd, category=cat}
    end

    if orderGrid[1].active or orderGrid[2].active or orderGrid[3].active then
        orderGrid[1].active = true
        orderGrid[2].active = true
        orderGrid[3].active = true
    end

    -- Add the states in the wanted order
    if #cmdList>0 then
        if WG.UIcoords.stateGrid.align=="bottom" then
            -- pad out to make it as though we added bottom-up
            local nPadding = 6
            for action,smd in pairs(states) do
                local alwaysPresent = false
                for _,a in ipairs(topStates) do
                    if a==action then
                        alwaysPresent = true
                        break
                    end
                end
                if not alwaysPresent then nPadding = nPadding - 1 end
            end
            for i=1,nPadding do
                stateMenu:AddChild(paddingState())
            end
        end

        AddInSequence(states, topStates, addState, addDummyState)
    end

    -- Add the orders, for each order category
    for i=1,#orderMenuLayout do
        if orderGrid[i].active then
            if not orders[i] then orders[i] = {} end
            AddInSequence(orders[i], orderMenuLayout[i], addOrderButton, addDummyOrder)
        end
    end

    -- Add the units, in order of lowest cost
    if #units>0 then
        AddInSortedOrder(units, addBuild, WG.BuildOrderComparator)
    end
end

local function parseTransported()
    -- work out how many of each unitDefID we are transporting
    local tUnitDefIDs = {}
    for i=1,#sUnits do
        local unitID = sUnits[i] --is a transporter
        local transported = spGetUnitIsTransporting(unitID)
        for j=1,#transported do
            local tID = transported[j]
            local tDID = spGetUnitDefID(tID)
            tUnitDefIDs[tDID] = (tUnitDefIDs[tDID] or 0) +1
        end
    end

    -- add to grid
    local units = {}
    for uDID,count in pairs(tUnitDefIDs) do
        local name = UnitDefs[uDID].name
        units[#units+1] = {name=name, uDID=uDID, disabled=false, category=loadedMenuCat, count=count}
        grid[loadedMenuCat].active = true
        buildMenu.active = true
    end

    if #units>0 then
        AddInSortedOrder(units, addBuild, WG.BuildOrderComparator)
    end
end

local function parseUnitDefCmds(uDID)
    -- load the build menu for the given unitDefID
    -- don't load the state/cmd menus
    local queue = parseInitialBuildQueue()

    local units = {}
    buildMenu.active = true
    orderMenu.active = false

    local buildDefIDs = UnitDefs[uDID].buildOptions

    for _,bDID in pairs(buildDefIDs) do
        local ud = UnitDefs[bDID]
        local menuCat = getBuildCat(ud)
        grid[menuCat].active = true
        units[#units+1] = {name=ud.name, uDID=bDID, disabled=false, category=menuCat, count=queue[bDID]}
    end

    if #units>0 then
        AddInSortedOrder(units, addBuild, WG.BuildOrderComparator)
    end
end

local function SetGridDimensions()
    for i=1,#catNames do
        -- work out what size grid to use for build menu
        -- start from wanted; then add a new row, then new col, in turn, if needed
        local n = #grid[i].children
        local buildCols = wantedBuildCols
        local buildRows = wantedBuildRows
        local included = buildRows * buildCols
        if (n>maxBuildRows*maxBuildCols) then
            Spring.Echo("sMenu error: can't fit icons into build menu") -- should never happen; addBuild prevents it
        end
        while (included < n) do
            buildCols = math.min(buildCols + 1, maxBuildCols)
            included = buildRows * buildCols
            if included >= n then break end
			
            buildRows =  math.min(buildRows + 1, maxBuildRows)
            included = buildRows * buildCols
            if included >= n then break end
        end
        grid[i].columns = buildCols
        grid[i].rows = buildRows
    end
end

local function ChooseTab()
    -- use the most recent tab that wasn't the factory tab, if possible
    for i=1,#catNames do
        if #grid[i].children>0 and menuTabs.prevChoice==i then return i end
    end
    for i=1,#catNames do
        if #grid[i].children>0 then return i end
    end
    return nil
end

--------------------------------------------------------------
-- menu tabs

function makeMenuTabs()
    -- create a tab for each menu Panel with a command
    menuTabs:ClearChildren()
	local vsx,vsy = Spring.GetViewGeometry()
    local tabCount = 0
    for i = 1, #catNames do
        if grid[i].active then
			tabCount = tabCount + 1
		end
	end
	local tw,th
	if WG.UIcoords.buildMenu.menuTabs=="right" then
		tw = menuTabs.width 
		th = menuFont*3
	elseif WG.UIcoords.buildMenu.menuTabs=="top" then
		tw = vsx*0.07
		th = menuFont*3
	elseif WG.UIcoords.buildMenu.menuTabs=="internal" then
		tw = menuTabs.width / tabCount
		th = menuTabs.height
	end
	local tx,ty = 0,0
	
	
	menuTab = {}
    local tab = 0
    for i = 1, #catNames do
        if grid[i].active then
            menuTab[i] = Chili.bguButton:New{
                tabNum  = i,
                tooltip = 'You can scroll through the different categories with your mouse wheel!',
                parent  = menuTabs,
                x       = tx,
                y       = ty,
                width   = tw,
                height  = th,
                caption = catNames[i],
                OnClick = {selectTab},
                backgroundColor = buttonColour,
                OnMouseWheel = {scrollMenus},
                font    = {
                    size             = menuFont,
                    color            = menuTabColor,
                    outline          = true,
                    autoOutlineColor = true,
                    outlineWidth     = 4,
                    outlineWeight    = 5,
                },
            }
            tab = tab + 1
			if WG.UIcoords.buildMenu.menuTabs=="right" then
				ty = ty + th
			elseif WG.UIcoords.buildMenu.menuTabs=="top" then
				tx = tx + tw
			elseif WG.UIcoords.buildMenu.menuTabs=="internal" then
				tx = tx + tw
			end
        end
    end
end

---------------------------
local function loadPanels()
    -- loads/reloads the build/order/state menus

    -- check for change in selected units
    local newUnit = false
    local units = spGetSelectedUnits()
    if #units == #sUnits then
        for i = 1, #units do
            if units[i] ~= sUnits[i] then
                newUnit = true
                break
            end
        end
    else
        newUnit = true
    end

    -- check if we have only transports selected
    if newUnit then
        local notTransport = false
        for i = 1, #units do
            local unitDefID = spGetUnitDefID(units[i])
            if not UnitDefs[unitDefID].isTransport then
                notTransport = true
                break
            end
        end
        onlyTransportSelected = not notTransport
    end

    -- states and order buttons are removed and re-added on each refresh
    -- this is needed for state buttons (e.g. changing cloak state also changes fire state, because of a widget), and a different button is used for *each* possible fire state
    -- it isn't needed for order buttons but wth
    for i=1,#orderMenuLayout do
        orderGrid[i]:ClearChildren()
        orderGrid[i].active = false
    end
    stateMenu:ClearChildren()

    -- unit buttons are only removed and re-added if the unit selection changes
    -- or if transports are enabled, in case we loaded/unloaded
    if newUnit or onlyTransportSelected then
        sUnits = units
        for i=1,#catNames do
            grid[i]:ClearChildren()
            grid[i].active = false
        end
    end

    -- set up the new menus
    parseCmds()
    if onlyTransportSelected then
        parseTransported()
    end
    SetGridDimensions()

    -- choose active menu cat
    makeMenuTabs()
    menuTabs.choice = ChooseTab()
    if menuTabs.choice and buildMenu.active and menuTab[menuTabs.choice] then
        selectTab(menuTab[menuTabs.choice])
    end
end

local function loadDummyPanels(unitDefID)
    -- load the build menu panels as though this unitDefID were selected, even though it is not

    for i=1,#orderMenuLayout do
        orderGrid[i]:ClearChildren()
        orderGrid[i].active = false
    end

    stateMenu:ClearChildren()

    menuTabs.choice = 1
    for i=1,#catNames do
        grid[i]:ClearChildren()
        grid[i].active = false
    end

    parseUnitDefCmds(unitDefID)
    SetGridDimensions()
    makeMenuTabs()
    menuTabs.choice = ChooseTab()
    if menuTabs.choice and buildMenu.active then
        selectTab(menuTab[menuTabs.choice])
    end
end

---------------------------
-- cache of unit buttons

local airFacs = { --unitDefs can't tell us this
    [UnitDefNames.armap.id] = true,
    [UnitDefNames.armaap.id] = true,
    [UnitDefNames.corap.id] = true,
    [UnitDefNames.coraap.id] = true,
    [UnitDefNames.armplat.id] = true,
    [UnitDefNames.corplat.id] = true,
}

function IsWater(unitDef)
    local water = (unitDef.maxWaterDepth and unitDef.maxWaterDepth>25)
            or (unitDef.minWaterDepth and unitDef.minWaterDepth>0)
            or string.find(unitDef.moveDef and unitDef.moveDef.name or "", "hover")
    return water
end

function IsAir(unitDef)
    local air = unitDef.isAirUnit or unitDef.isAirBase or airFacs[unitDef.id]
            or (unitDef.weapons[1] and unitDef.weapons[1].onlyTargets.vtol and not unitDef.weapons[1].onlyTargets.all)
    return air
end

local function CreateUnitButton(name, unitDef)
    -- make the button for this unit
    local unitDefID = unitDef.id
    local description = unitDef.tooltip~="" and "\n"..unitDef.tooltip or ""
    local tooltip = unitDef.humanName .. description
    
    unitButtons[unitDefID] = Chili.bguButton:New{
        name      = "button_" .. name,
        cmdId     = -unitDefID,
        unitDefID = unitDefID,
        _tooltip   = tooltip,
        tooltip = options.showBuildTooltips and tooltip,
        caption   = '',
        disabled  = false,
        padding   = {0,0,0,0},
        margin    = {0,0,0,0},
        OnMouseUp = {cmdAction},
        OnMouseOver = {function(self) WG.sMenu.mouseOverUnitDefID = self.unitDefID end},
        OnMouseOut   = {function() WG.sMenu.mouseOverUnitDefID = nil end},
        OnMouseWheel = {scrollMenus},
        backgroundColor = buttonColour,
        children  = {
            Chili.Image:New{
                name   = "image_" .. name,
                height = '100%', width = '100%',
                file   = '#'..unitDef.id,
                flip   = false,
                children = {
                    Chili.Label:New{ -- # in build queue
                        caption = 'queue_' .. name,
                        right   = '7%',
                        y       = '7%',
                        font = {
                            size             = fontSize,
                            outline          = true,
                            autoOutlineColor = true,
                            outlineWidth     = 5,
                            outlineWeight    = 3,
                        }
                    },
                    Chili.Label:New{
                        name = 'hotkey_' .. name,
                        caption = '',
                        right   = '7%',
                        bottom = '5%',
                        font = {
                            size             = fontSize,
                            outline          = true,
                            autoOutlineColor = true,
                            outlineWidth     = 5,
                            outlineWeight    = 3,
                        }
                    },
                    Chili.Image:New{
                        name = 'overlay_' .. name,
                        color  = teamColor,
                        height = '100%', width = '100%',
                        file   = imageDir..'Overlays/'..name..'.dds',
                    },
                }
            }
        }
    }

    local extraIcons = {
        [1] = {image="constr.png",   used = unitDef.isBuilder},
        [2] = {image="raindrop.png", used = IsWater(unitDef)},
        [3] = {image="plane.png",    used = IsAir(unitDef)},
    }

    local y = 7 -- %
    for _,icon in ipairs(extraIcons) do
        if icon.used then
            Chili.Image:New{
                parent = unitButtons[unitDefID].children[1].children[3],
                x = '10%', bottom = y .. '%',
                height = '15%', width = '15%', keepAspect = true,
                file   = imageDir..icon.image,
            }
            y = y + 16
        end
    end
end

---------------------------
local function LayoutHandler(xIcons, yIcons, cmdCount, commands)
    -- interaction with widgetHandler
    widgetHandler.commands   = commands
    widgetHandler.commands.n = cmdCount
    widgetHandler:CommandsChanged()

    return "", xIcons, yIcons, {}, {}, {}, {}, {}, {}, {}, {[1337]=9001}
end
---------------------------
local function ForceSelect(uDID)
    -- act as though the build button for this uDID was pushed
    updateRequired = "ForceSelect"
    activeSelUDID = uDID
    WG.sMenu.mouseOverDefID = uDID
    activeSelCmdID = nil
    if WG.InitialQueue then
        WG.InitialQueue.SetSelDefID(uDID)
    end
end
---------------------------
function widget:Initialize()
    widgetHandler:ConfigLayoutHandler(LayoutHandler)
    Spring.ForceLayoutUpdate()
    spSendCommands({'tooltip 0'})

    if Spring.GetGameFrame()>0 then gameStarted = true end

    WG.sMenu = {}
    WG.sMenu.ForceUpdate = function() updateRequired='ForceUpdate' end
    WG.sMenu.ForceUpdateHotkeys = ForceUpdateHotkeys

    Chili = WG.Chili
    buttonColour = WG.buttonColour
    screen0 = Chili.Screen0

    buildMenu = Chili.Control:New{
        parent       = screen0,
        name         = 'build menu',
        active       = false,
        padding      = {0,0,0,0},
    }

    menuTabs = Chili.Control:New{
        parent  = screen0,
        choice  = 1,
        prevChoice = 1,
        padding = {0,0,0,0},
        margin  = {0,0,0,0},
    }

    orderMenu = Chili.StackPanel:New{
        name = "order menu",
        parent = screen0,
        padding = {0,0,0,0},
        margin  = {0,0,0,0},
    }

    for i=1,#defaultOrderMenuLayout do
        orderGrid[i]  = Chili.Grid:New{
            name    = "order grid " .. i,
            parent  = orderMenu,
            active  = false,
            columns = 1,
            rows    = 1,
            padding = {0,0,0,0},
            margin  = {0,0,0,0},
        }
    end

    stateMenu = Chili.Grid:New{
        name    = "state grid",
        parent  = screen0,
        columns = 1,
        rows    = 1,
        orientation = 'vertical',
        padding = {0,0,0,0},
    }

    -- Creates a container for each category of build commands.
    for i=1,#catNames do
        grid[i] = Chili.Grid:New{
            name     = "grid_" .. catNames[i],
            parent   = buildMenu,
            x        = 0,
            y        = 0,
            right    = 0,
            bottom   = 0,
            padding  = {0,0,0,0},
            margin   = {0,0,0,0},
        }
    end

    resizeUI()
    
    -- options
    AddMenuOptions()

    -- Create a cache of buttons stored in the unit array
    for name, unitDef in pairs(UnitDefNames) do
        CreateUnitButton(name,unitDef)
    end

    -- offer the option to force select build menu buttons
    WG.sMenu.ForceSelect = ForceSelect
end

---------------------------
function widget:ViewResize()
    resizeUI()
    updateRequired = 'ViewResize'
end
---------------------------
local selectedUnits = {}
function widget:CommandsChanged()
    -- see if selected units changed, cause an update if so
    local newUnits = Spring.GetSelectedUnits()
    if not newUnits then return end
    if #selectedUnits ~= #newUnits then
        updateRequired = 'CommandsChanged'
        selectedUnits = newUnits
    else
        for i,_ in ipairs(newUnits) do
            if selectedUnits[i]~=newUnits[i] then
                updateRequired = 'CommandsChanged'
                selectedUnits = newUnits
                break
            end
        end
    end
end
local skipUnitCommands = {
    -- in general we need to refresh when the unit we have selected receives a command
    -- but some commands can be spammed easily, and we don't need to refresh for most of those
    [CMD.ATTACK] = true,
    [CMD.MOVE] = true,
    [CMD.PATROL] = true,
    [CMD.SET_WANTED_MAX_SPEED] = true,
    [CMD.FIGHT] = true,
}
function widget:UnitCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
    if Spring.IsUnitSelected(unitID) and not skipUnitCommands[cmdID] then
        updateRequired = 'UnitCommand'
    end
end
function widget:UnitCmdDone(unitID, unitDefID, unitTeam, cmdID, cmdTag, cmdParams, cmdOpts)
    if Spring.IsUnitSelected(unitID) then
        updateRequired = 'UnitCmdDone'
    end
end
function widget:UnitLoaded(unitID, unitDefID, unitTeam, transportID, transportTeam)
    if Spring.IsUnitSelected(transportID) or Spring.IsUnitSelected(unitID) then
        updateRequired = 'UnitLoaded'
    end
end
function widget:UnitUnloaded(unitID, unitDefID, unitTeam, transportID, transportTeam)
    if Spring.IsUnitSelected(transportID) or Spring.IsUnitSelected(unitID) then
        updateRequired = 'UnitUnloaded'
    end
end
function widget:GameFrame()
    -- track the current active command
    -- has to be GameFrame because CommandsChanged isn't called when an active build command changes
    local _,cmdID,_ = Spring.GetActiveCommand()
    if cmdID and cmdID<0 then
        local uDID = -cmdID -- looking to build a unit of this uDID
        if activeSelCmdID or activeSelUDID~=uDID then
            updateRequired = 'GameFrame: looking to build a unit of this uDID'
            activeSelUDID = uDID
            activeSelCmdID = nil
            selectTab(menuTab[getBuildCat(UnitDefs[uDID])])
        end
    elseif cmdID then
        -- looking to give this cmdID
        if activeSelUDID or activeSelCmdID~=cmdID then
            updateRequired = 'GameFrame: looking to give this cmdID'
            activeSelUDID = nil
            activeSelCmdID = cmdID
        end
    else
        -- no active commands
        if activeSelUDID or activeSelCmdID then
            updateRequired = 'GameFrame: no active commands'
            activeSelUDID = nil
            activeSelCmdID = nil
        end
    end
end
---------------------------
-- handle InitialQueue, if enabled
local startUnitDefID
local function InitialQueue()
    if gameStarted or not WG.InitialQueue or spGetSpectatingState() then
        return false
    end

    -- check if we just changed faction
    local uDID = WG.startUnit or Spring.GetTeamRulesParam(Spring.GetMyTeamID(), 'startUnit')
    if uDID==startUnitDefID and ( updateRequired == '' )then return true end
    if not uDID then return false end

    -- now act as though unitDefID is selected for building
    startUnitDefID = uDID
    sUnits[1] = uDID
    local r,g,b = Spring.GetTeamColor(Spring.GetMyTeamID())
    teamColor = {r,g,b,0.8}

    if WG.FacBar then WG.FacBar.Hide() end
    buildMenu.active = false
    orderMenu.active = false

    loadDummyPanels(startUnitDefID)
    updateRequired = ''
    return true
end
---------------------------
-- If update is required this Loads the panel and queue for the new unit or hides them if none exists
--  There is an offset to prevent the panel disappearing right after a command has changed (for fast clicking)
function widget:Update()
    if InitialQueue() then return end

    if updateRequired then
        --Spring.Echo("sMenu updateRequired reason:", updateRequired)
        local r,g,b = Spring.GetTeamColor(Spring.GetMyTeamID())
        teamColor = {r,g,b,0.9}
        updateRequired = nil

        orderMenu.active = false -- if order cmd is found during parse this will become true
        buildMenu.active = false -- if build cmd is found during parse this will become true
        -- every unit has states

        loadPanels()

        if not buildMenu.active and buildMenu.visible then
            buildMenu:Hide()
        elseif buildMenu.active and buildMenu.hidden then
            buildMenu:Show()
        end
        if (hideFacBarOnBuild and buildMenu.active) or (hideFacBarOnOrder and orderMenu.active) then
            WG.FacBar.Hide()
        else
            WG.FacBar.Show()
        end
    end
end

function widget:GameStart()
    -- Reverts initial queue behaviour
    for i=1,#catNames do
        grid[i].active = false
    end
    WG.sMenu.mouseOverUnitDefID = nil
    gameStarted = true
    updateRequired = 'GameStart'
end

---------------------------
-- options

function AddMenuOptions()
    local Menu = WG.MainMenu

    Menu.AddWidgetOption{
        title = "Selection Menu",
        name = widget:GetInfo().name,
        children = {
            Chili.Checkbox:New{caption='Show build menu tooltips',x='5%',width='95%',
                    checked=options.showBuildTooltips, OnChange={function() options.showBuildTooltips = not options.showBuildTooltips; SetTooltips(); end}},
            Chili.Checkbox:New{caption='Show state menu tooltips',x='5%',width='95%',
                    checked=options.showStateTooltips, OnChange={function() options.showStateTooltips = not options.showStateTooltips; SetTooltips(); end}},
            Chili.Checkbox:New{caption='Show order menu tooltips',x='5%',width='95%',
                    checked=options.showOrderTooltips, OnChange={function() options.showOrderTooltips = not options.showOrderTooltips; SetTooltips(); end}},
        }
    }
end

function SetTooltips()
    for _,button in pairs(unitButtons) do        
        button.tooltip = options.showBuildTooltips and button._tooltip
    end
    for _,button in pairs(stateButtons) do        
        button.tooltip = options.showBuildTooltips and button._tooltip
    end
    for _,button in pairs(orderButtons) do        
        button.tooltip = options.showBuildTooltips and button._tooltip
    end
    
end
    
---------------------------
--


function widget:GetConfigData()
    return options
end

function widget:SetConfigData(data)
    if data then
        options = data
    end
end

function widget:Shutdown()
    -- Let Chili know we're done with these
    buildMenu:Dispose()
    menuTabs:Dispose()

    WG.sMenu = nil

    -- Bring back stock Order Menu
    widgetHandler:ConfigLayoutHandler(nil)
    Spring.ForceLayoutUpdate()

    spSendCommands({'tooltip 1'})
end
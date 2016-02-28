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

-- menu categories --
local catNames = {'ECONOMY', 'BATTLE', 'UNITS', 'FACTORY', 'LOADED'} -- order matters
local loadedMenuCat = 5
local buildMenuCat = 4

local wantedCols = 3 --min
local wantedRows = 4
local maxCols = 5
local maxRows = 6
local wantedPaddingCols = 1 -- determines how the shape of the unit buttons vary as their number/grid changes, see resizeUI
local wantedPaddingRows = 3

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
    [CMD.UNLOAD_UNIT] = {1.00, 0.95, 0.15, 1.0},
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

-- orders that are always displayed
local topOrders = {
    [1] = "move",
    [2] = "fight",
    [3] = "attack",
    [4] = "patrol",
    [5] = "stop",
    [6] = "settarget",
    [7] = "canceltarget",
    [8] = "repair",
    [9] = "guard",
    [10] = "wait",
}

-- states that are always displayed
local topStates = {
    [1] = "movestate",
    [2] = "firestate",
    [3] = "repeat",
}

-- state colours
local white = {1,1,1,1}
local black = {0,0,0,1}
local green = {0,1,0,1}
local darkgreen = {0,0.8,0,1}
local yellow = {1,1,0,1}
local orange = {1,0.5,0,1}
local red = {1,0,0,1}
local grey = {0.2,0.2,0.2,1}

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

local unitButtons = {} -- all cached
local orderButtons = {} -- created on demand
local stateButtons = {} -- created on demand

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
local selectedBorderColor = {1,0,0,1} -- colour of outline of selected commands icon

----------------
local function getInline(r,g,b)
    if type(r) == 'table' then
        return string.char(255, (r[1]*255), (r[2]*255), (r[3]*255))
    else
        return string.char(255, (r*255), (g*255), (b*255))
    end
end

---------------------------------------------------------------
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

local function showGrid(num)
    for i=1,#catNames do
        if  i == num and grid[i].hidden then
            grid[i]:Show()
        elseif i ~= num and grid[i].visible then
            grid[i]:Hide()
        end
    end
end

local function resizeUI(scrH,i)
    local nCols = (i) and math.max(wantedCols+wantedPaddingCols, math.min(maxCols, grid[i].columns)) or wantedCols
    local nRows = (i) and math.max(wantedRows+wantedPaddingRows, math.min(maxRows, grid[i].rows)) or wantedRows
    
    local ordH = scrH * 0.05
    local ordY = scrH - ordH
    local winY = scrH * 0.2
    local winH = scrH * 0.5
    local winW = winH * nCols / nRows
    local aspect = Game.mapX/Game.mapY
    
    -- find out where minimap is
    local minMapH = WG.MiniMap and WG.MiniMap.height or scrH * 0.3
    local minMapW = WG.MiniMap and WG.MiniMap.width or minMapH * aspect
    
    buildMenu:SetPos(0, winY, winW, winH) -- better to keep consistent layout & not use small buttons when possible
    menuTabs:SetPos(winW,winY+20)
    orderMenu:SetPos(minMapW,ordY,ordH*21,ordH)
    -- orderBG:SetPos(minMapW,ordY,ordH*#orderMenu.children,ordH) --background for order menu, if it had one!
    stateMenu:SetPos(winY*1.05,0,200,winY)    
end

local function selectTab(self)
    if not self then return end 
    local choice = self.tabNum
    showGrid(choice)
    
    local highLight = menuTab[menuTabs.choice] 
    if highLight then
        highLight.font.color = {.5,.5,.5,1}
        highLight.font.size  = 14
        highLight.width = 100
        highLight:Invalidate()
    end
    
    local old = menuTab[choice] 
    if old then
        old.font.color = {1,1,1,1}
        old.width = 120
        old.font.size  = 18
        old:Invalidate()
    end

    menuTabs.choice = choice
    if choice ~= buildMenuCat or (choice==buildMenuCat and (#grid[1].children>0 or #grid[1].children>0)) then
        menuTabs.prevChoice = choice 
    end

    resizeUI(Chili.Screen0.height, choice)    
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
---------------------------------------------------------------

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
    
    -- avoid adding too many
    if #grid[category].children>maxCols*maxRows-1 then return end
    if #grid[category].children==maxCols*maxRows-1 then
        Chili.Button:New{
            x = 5,
            parent = grid[category],
            caption = "(full)",
            padding   = {0,0,0,0},
            margin    = {0,0,0,0},
            font = {
                size = 16
            }
        }
        return
    end
    
    -- prepare the button
    local button = unitButtons[name]
    local label = button.children[1].children[1]
    local overlay = button.children[1].children[3]
    local caption = item.count or ''
    
    if disabled then
        -- building this unit is disabled
        button.focusColor[4] = 0
        -- Grey out Unit pic
        overlay.color = {0.4,0.4,0.4}
    else
        button.focusColor[4] = 0.5
        if uDID==activeSelUDID then
            overlay.color = selectedColor
            button.borderColor = selectedBorderColor
            selectTab(menuTab[category])
        else
            overlay.color = teamColor
            button.borderColor = {1,1,1,0.1}        
        end
    end
    button.disabled = disabled
        
    -- add this button
    label:SetCaption(caption)
    if not grid[category]:GetChildByName(button.name) then
        -- No duplicates
        grid[category]:AddChild(button)
    end
end

local function addState(cmd)
    local caption = cmd.params[cmd.params[1] + 2]
    local name = cmd.action .. " " .. caption
    -- create the button if it does not already exist
	local button
	if stateButtons[name]==nil then 
		button = Chili.Button:New{
            name      = name,
			caption   = caption,
			cmdName   = cmd.name,
			tooltip   = cmd.tooltip,
			cmdId     = cmd.id,
			cmdAName  = cmd.action,
			padding   = {0,0,0,0},
			margin    = {0,0,0,0},
            minheight = 25,
			OnMouseUp = {cmdAction},
			backgroundColor = black,
			font      = {
				color = paramColours[caption] or white,
				size  = 16,
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
        button = Chili.Button:New{
            caption   = cmd.action,
            --tooltip   = cmd.tooltip, 
            padding   = {0,0,0,0},
            margin    = {0,0,0,0},
            minheight = 25,
            OnMouseUp = {},
			backgroundColor = black,
            font      = {
                color = grey,
                size  = 16,
            },
        }
        stateButtons[name] = button
    else
        button = stateButtons[name]
    end
    
    stateMenu:AddChild(button)
end

local function addOrderButton(cmd)  
    -- create the button if it does not already exist
	local button 
    local name = cmd.action
	if orderButtons[name] == nil then 
		button = Chili.Button:New{
			name      = cmd.action,
            caption   = '',
			cmdName   = cmd.name,
			tooltip   = cmd.tooltip,
			cmdId     = cmd.id,
			cmdAName  = cmd.action,
			padding   = {0,0,0,0},
			margin    = {0,0,0,0},
			OnMouseUp = {cmdAction},
			borderColor = {1,1,1,0.1},
			backgroundColor = black,
			Children  = {
				Chili.Image:New{
					parent  = button,
					x       = 5,
					bottom  = 5,
					y       = 5,
					right   = 5,
					color   = orderColours[cmd.id] or {1,1,1,1},
					file    = imageDir..'Commands/'..cmd.action..'.png',
					children = {
						Chili.Label:New{
							caption = Hotkey[name] or "",
							right  = 2,
							y = 1,
                            font = {
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
        button.children[1]:GetChildByName("stockpile_label"):SetCaption(num.."/"..queued)
    end
	button.borderColor = (cmd.id==activeSelCmdID) and selectedBorderColor or {1,1,1,0.1}
    
	orderMenu:AddChild(button)
end

local function addDummyOrder(cmd)
    local button 
    local name = cmd.action .. "_dummy"
    if orderButtons[name] == nil then
        button = Chili.Button:New{
            name      = name,
            caption   = '',
            --tooltip   = cmd.tooltip .. getInline(orderColours[cmd.action]) .. HotkeyString(cmd.action),
            padding   = {0,0,0,0},
            margin    = {0,0,0,0},
            OnMouseUp = {},
			backgroundColor = black,
            Children  = {
                Chili.Image:New{
                    parent  = button,
                    x       = 5,
                    bottom  = 5,
                    y       = 5,
                    right   = 5,
                    color   = grey,
                    file    = imageDir..'Commands/'..cmd.action..'.png',
                }
            }
        }
        orderButtons[name] = button
    else
        button = orderButtons[name]
    end
    
    orderMenu:AddChild(button) 
end

local function getMenuCat(ud)
    if ud.isFactory or (ud.isBuilder and ud.speed==0) then
        menuCat = 4
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

local function AddInSortedOrder(items, Add, Score)
    -- add items in order of score, from lowest to highest
    local t = {}
    for _,v in pairs(items) do
        t[#t+1] = {item=v, score=Score(v)}
    end
    local function Comparator(i,j)
        return i.score<j.score
    end
    table.sort(t,Comparator)
    for _,v in ipairs(t) do
        Add(v.item)
    end
end

function Cost(item)
    local uDID = item.uDID
    return 60*UnitDefs[uDID].metalCost + UnitDefs[uDID].energyCost
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
                menuCat = getMenuCat(ud)    
            end

            if menuCat and #grid[menuCat].children<=maxRows*maxCols then
                buildMenu.active     = true
                grid[menuCat].active = true
                units[#units+1] = {name=cmd.name, uDID=-cmd.id, disabled=cmd.disabled, category=menuCat, count=(queue[-cmd.id] or cmd.params[1])} -- cmd.params[1] helps only in godmode
            elseif #cmd.params > 1 then
                states[cmd.action] = cmd
            elseif cmd.id > 0 and not WG.OpenHostsList then -- hide the order menu if the open host list is showing (it shows to specs who have it enabled)
                orderMenu.active = true
                orders[cmd.action] = cmd
            end
        end
    end
    
    -- Include stop command, if needed
    if orderMenu.active then
        local stop_cmd = {name="Stop", action='stop', id=CMD.STOP, tooltip="Stop: Clears the command queue"}
        orders[stop_cmd.action] = stop_cmd
    end
    
    -- Add the orders/states in the wanted order, from L->R
    if #cmdList>0 then
        AddInSequence(orders, topOrders, addOrderButton, addDummyOrder)
        AddInSequence(states, topStates, addState, addDummyState)
    end
    
    -- Add the units, in order of lowest cost
    if #units>0 then
        AddInSortedOrder(units, addBuild, Cost)
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
        AddInSortedOrder(units, addBuild, Cost)
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
        local menuCat = getMenuCat(ud)
        grid[menuCat].active = true
        units[#units+1] = {name=ud.name, uDID=bDID, disabled=false, category=menuCat, count=queue[bDID]} 
    end

    if #units>0 then
        AddInSortedOrder(units, addBuild, Cost)
    end
end

function SetGridDimensions()
    for i=1,#catNames do
        -- work out if we have too many buttons in a grid, request more columns if so
        local n = #grid[i].children 
        local neededColumns = math.floor((n-1)/maxRows)+1
        local neededRows = math.floor((n-1)/maxCols)+1
        local nCols = math.max(wantedCols, math.min(maxCols, neededColumns))
        local nRows = math.max(wantedRows, math.min(maxRows, neededRows))
        grid[i].columns = nCols
        grid[i].rows = nRows
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
--------------------------------------------------------------

-- Creates a tab for each menu Panel with a command
local function makeMenuTabs()
    menuTabs:ClearChildren()
    menuTab = {}
    local tabCount = 0
    for i = 1, #catNames do
        if grid[i].active then
            tabCount = tabCount + 1
            menuTab[i] = Chili.Button:New{
                tabNum  = i,
                tooltip = 'You can scroll through the different categories with your mouse wheel!',
                parent  = menuTabs,
                width   = 100,
                y       = (tabCount - 1) * 200 / max(3,#catNames) + 1, -- panel to fit into is 200 high
                height  = 200/max(3,#catNames)-1,
                caption = catNames[i],
                OnClick = {selectTab},
                backgroundColor = black,
                OnMouseWheel = {scrollMenus},
                font    = {
                    color = {.5, .5, .5, 1}
                },
            }
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
    -- this is needed for state buttons (e.g. changing cloak state also changes fire state, because of a widget), and a different is used for *each* possible fire state
    -- it isn't needed for order buttons but wth
    orderMenu:ClearChildren()
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
    if menuTabs.choice and buildMenu.active and menuTab[menuTabs.choice] then selectTab(menuTab[menuTabs.choice]) end
end

local function loadDummyPanels(unitDefID)
    -- load the build menu panels as though this unitDefID were selected, even though it is not

    orderMenu:ClearChildren()
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
    if menuTabs.choice and buildMenu.active then selectTab(menuTab[menuTabs.choice]) end
end

---------------------------
--
local airFacs = { --unitDefs can't tell us this
    [UnitDefNames.armap.id] = true,
    [UnitDefNames.armaap.id] = true,
    [UnitDefNames.corap.id] = true,
    [UnitDefNames.coraap.id] = true,
    [UnitDefNames.armplat.id] = true,
    [UnitDefNames.corplat.id] = true,
}

local function creatUnitButton(name, unitDef)  
    -- make the button for this unit
    local hotkey = WG.buildingHotkeys and WG.buildingHotkeys[unitDef.id] or ''
    unitButtons[name] = Chili.Button:New{
        name      = name,
        cmdId     = -unitDef.id,
        tooltip   = nil,
        caption   = '',
        disabled  = false,
        padding   = {0,0,0,0},
        margin    = {0,0,0,0},
        OnMouseUp = {cmdAction},
        OnMouseOver = {function() WG.sMenu.mouseOverDefID = unitDef.id end},
        OnMouseOut   = {function() WG.sMenu.mouseOverDefID = nil end}, 
        backgroundColor = black,
        children  = {
            Chili.Image:New{
                height = '100%', width = '100%',
                file   = '#'..unitDef.id,
                flip   = false,
                children = {
                    Chili.Label:New{ -- # in build queue
                        caption = '',
                        right   = 10,
                        y       = 10,
                        font = {
                            outline          = true,
                            autoOutlineColor = true,
                            outlineWidth     = 5,
                            outlineWeight    = 3,
                        }
                    },
                    Chili.Label:New{
                        caption = hotkey,
                        right   = 10,
                        bottom = 10,
                        font = {
                            outline          = true,
                            autoOutlineColor = true,
                            outlineWidth     = 5,
                            outlineWeight    = 3,
                        }
                    },
                    Chili.Image:New{
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
        [2] = {image="raindrop.png", used = (unitDef.maxWaterDepth and unitDef.maxWaterDepth>25) 
                                             or (unitDef.minWaterDepth and unitDef.minWaterDepth>0) 
                                             or string.find(unitDef.moveDef and unitDef.moveDef.name or "", "hover")},
        [3] = {image="plane.png",    used = (unitDef.isAirUnit or unitDef.isAirBase or airFacs[unitDef.id] or (unitDef.weapons[1] and unitDef.weapons[1].onlyTargets.vtol or false))},
    }
    local y = 10
    for _,icon in ipairs(extraIcons) do
        if icon.used then
            Chili.Image:New{
                parent = unitButtons[name].children[1].children[3],
                x = 10, bottom = y,
                height = 15, width = 15,
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
    
    if (not WG.Chili) then
        widgetHandler:RemoveWidget()
        return
    end

    Chili = WG.Chili
    screen0 = Chili.Screen0
    
    buildMenu = Chili.Control:New{
        parent       = screen0,
        name         = 'buildMenu',
        active       = false,
        padding      = {0,0,0,0},
        OnMouseWheel = {scrollMenus},
    }

    menuTabs = Chili.Control:New{
        parent  = screen0,
        choice  = 1,
        prevChoice = 1,
        height  = 200,
        width   = 120,
        padding = {0,0,0,0},
        margin  = {0,0,0,0},
    }
    
    orderMenu = Chili.Grid:New{
        name    = "order grid",
        parent  = screen0,
        active  = false,
        columns = 21,
        rows    = 1,
        padding = {0,0,0,0},
    }


    stateMenu = Chili.Grid:New{
        name    = "state grid",
        parent  = screen0,
        columns = 2,
        rows    = 8,
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

    resizeUI(Chili.Screen0.height)


    -- Create a cache of buttons stored in the unit array
    for name, unitDef in pairs(UnitDefNames) do
        creatUnitButton(name,unitDef)
    end

    -- offer the option to force select build menu buttons
    WG.sMenu.ForceSelect = ForceSelect
end

--------------------------- 
function widget:ViewResize(_,scrH)
    resizeUI(scrH)
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
function GameFrame()
    -- track the current active command
    -- has to be GameFrame because CommandsChanged isn't called when an active build command changes
    local _,cmdID,_ = Spring.GetActiveCommand()
    if cmdID and cmdID<0 then
        local uDID = -cmdID -- looking to build a unit of this uDID
        if activeSelCmdID or activeSelUDID~=uDID then 
            updateRequired = 'GameFrame: looking to build a unit of this uDID'
            activeSelUDID = uDID
            activeSelCmdID = nil
            selectTab(menuTab[getMenuCat(UnitDefs[uDID])])
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
    
    if WG.HideFacBar then WG.HideFacBar() end
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
        teamColor = {r,g,b,0.8}
        updateRequired = nil
        
        orderMenu.active = false -- if order cmd is found during parse this will become true
        buildMenu.active = false -- if build cmd is found during parse this will become true
        -- every unit has states 

        loadPanels()
        
        if not buildMenu.active and buildMenu.visible then
            buildMenu:Hide()
            if WG.FacBar then WG.FacBar.Show() end
        elseif buildMenu.active and buildMenu.hidden then
            buildMenu:Show()
            if WG.FacBar then WG.FacBar.Hide() end
        end
    end
end

function widget:GameStart()
    -- Reverts initial queue behaviour
    for i=1,#catNames do
        grid[i].active = false
    end
    WG.sMenu.mouseOverDefID = nil
    gameStarted = true
    updateRequired = 'GameStart'
end

---------------------------
--
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
-- WIP (excuse the mess)
--  TODO add build progress bar.
function widget:GetInfo()
	return {
		name      = 'Selection Menu',
		desc      = 'Interface for issuing build orders and unit commands',
		author    = 'Funkencool',
		date      = 'Sep 2013',
		license   = 'GNU GPL v2',
		layer     = 0,
		enabled   = true,
		handler   = true,
	}
end
--------------

-- Config --
local catNames = {'ECONOMY', 'BATTLE', 'FACTORY'} -- order matters
local imageDir = 'luaui/images/buildIcons/'

--  Will probably ignore redundant units here (e.g. floating AA, umex, etc. which are interchangeable)
local ignoreCMDs = {
	selfd 	     = '',
	loadonto 	   = '',
	timewait 	   = '',
	deathwait    = '',
	squadwait	   = '',
	gatherwait	 = '',
	--coruwms      = '',
	--coruwes      = '',
	--coruwadves   = '',
	--coruwadvms   = '',
	--coruwfus     = '',
	--coruwmex     = '',
	--coruwmme     = '',
	--coruwmmm     = '',
}

local orderColors = {
	wait        = {0.8, 0.8, 0.8 ,1.0},
	attack      = {1.0, 0.0, 0.0, 1.0},
    settarget   = {1.0, 0.5, 0.0, 0.7},
	fight       = {1.0, 0.3, 0.0, 1.0},
	areaattack  = {0.8, 0.0, 0.0, 1.0},
	manualfire  = {0.8, 0.2, 0.0, 1.0},
	move        = {0.2, 1.0, 0.0, 1.0},
	reclaim     = {0.2, 0.6, 0.0, 1.0},
	patrol      = {0.4, 0.4, 1.0, 1.0},
	guard       = {0.0, 0.0, 1.0, 1.0},
	repair      = {0.2, 0.2, 0.8, 1.0},
	loadunits   = {1.0, 1.0, 1.0, 1.0},
	unloadunits = {1.0, 1.0, 1.0, 1.0},
	stockpile   = {1.0, 1.0, 1.0, 1.0},
	upgrademex  = {0.6, 0.6, 0.6, 1.0},
	capture     = {0.6, 0.0, 0.8, 1.0},
	resurrect   = {0.0, 0.0, 1.0, 1.0},
    restore     = {0.5, 1.0, 0.2, 1.0},
    stop        = {0.4, 0.0, 0.0, 1.0},
    canceltarget= {0.4, 0.0, 0.0, 1.0},
}

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

local topStates = {
    [1] = "movestate",
    [2] = "firestate",
    [3] = "repeat",
}

local white = {1,1,1,1}
local black = {0,0,0,1}
local green = {0,1,0,1}
local yellow = {0.5,0.5,0,1}
local orange = {1,0.5,0,1}
local red = {1,0,0,1}
local grey = {0.2,0.2,0.2,1}

local paramColors = {
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

-- set target custom command IDs
local CMD_UNIT_SET_TARGET = 34923
local CMD_UNIT_CANCEL_TARGET = 34924
local CMD_UNIT_SET_TARGET_RECTANGLE = 34925

--export to CMD table
CMD.UNIT_SET_TARGET = CMD_UNIT_SET_TARGET
CMD[CMD_UNIT_SET_TARGET] = 'UNIT_SET_TARGET'
CMD.UNIT_CANCEL_TARGET = CMD_UNIT_SET_TARGET
CMD[CMD_UNIT_CANCEL_TARGET] = 'UNIT_CANCEL_TARGET'
CMD.UNIT_SET_TARGET_RECTANGLE = CMD_UNIT_SET_TARGET_RECTANGLE
CMD[CMD_UNIT_SET_TARGET_RECTANGLE] = 'UNIT_SET_TARGET_RECTANGLE'


-- Chili vars --
local Chili
local panH, panW, winW, winH, winX, winB, tabH, minMapH, minMapW
local screen0, buildMenu, stateMenu, orderMenu, orderBG, menuTabs 
local orderArray = {}
local stateArray = {}
local menuTab = {}
local queue = {}
local grid = {}
local unit = {}
----------------

-- Spring Functions --
local spGetTimer          = Spring.GetTimer
local spDiffTimers        = Spring.DiffTimers
local spGetActiveCmdDesc  = Spring.GetActiveCmdDesc
local spGetActiveCmdDescs = Spring.GetActiveCmdDescs
local spGetActiveCommand  = Spring.GetActiveCommand
local spGetCmdDescIndex   = Spring.GetCmdDescIndex
local spGetFullBuildQueue = Spring.GetFullBuildQueue
local spGetSelectedUnits  = Spring.GetSelectedUnits
local spSendCommands      = Spring.SendCommands
local spSetActiveCommand  = Spring.SetActiveCommand

-- Local vars --
local gameStarted = (Spring.GetGameFrame()>0)
local updateRequired = true
local oldTimer = spGetTimer()
local sUnits = {}
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
	if not gameStarted then
        WG.SetSelDefID(-obj.cmdId)
	else
		local index = spGetCmdDescIndex(obj.cmdId)
		if (index) then
			local left, right = (button == 1), (button == 3)
			local alt, ctrl, meta, shift = mods.alt, mods.ctrl, mods.meta, mods.shift
			spSetActiveCommand(index, button, left, right, alt, ctrl, meta, shift)
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

local maxCols = 6
local maxRows = 8

local function resizeUI(scrH,i)
    -- ideally, our grid wants =3 columns, in which case we give it space for 4 & use wider buttons-
    -- if our grid wants >3 cols, we use smaller buttons & possibly widen
    -- we always display space for the maximum number of rows
    local nCols = (i) and math.max(4, math.min(maxCols, grid[i].columns)) or 4 
    
	local ordH = scrH * 0.05
	local ordY = scrH - ordH
	local winY = scrH * 0.2
	local winH = scrH * 0.5
	local winW = winH * nCols / maxRows 
	local aspect = Game.mapX/Game.mapY
	local minMapH = scrH * 0.3
	local minMapW = minMapH * aspect
	if aspect > 1 then
		minMapW = minMapH * aspect^0.5
		minMapH = minMapW / aspect
	end
	
	buildMenu:SetPos(0, winY, winW, winH) -- better to keep consistent layout & not use small buttons when possible
	menuTabs:SetPos(winW,winY+20)
	orderMenu:SetPos(minMapW,ordY,ordH*21,ordH)
	orderBG:SetPos(minMapW,ordY,ordH*#orderMenu.children,ordH)
	stateMenu:SetPos(winY*1.05,0,200,winY)
end

local function selectTab(self)
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
    if choice ~= 3 or (choice==3 and (#grid[1].children>0 or #grid[1].children>0)) then
        menuTabs.prevChoice = choice 
    end

    resizeUI(Chili.Screen0.height, choice)    
end

local function scrollMenus(_,_,_,_,value)
	local choice = menuTabs.choice
	choice = (choice - value - 1) % #menuTab + 1
    selectTab(menuTab[choice])
	return true -- Prevents zooming
end

---------------------------------------------------------------
---------------------------------------------------------------

-- Adds icons/commands to the menu panels accordingly
local function addBuild(cmd, category)
	local button = unit[cmd.name]
	local label = button.children[1].children[1]
	local overlay = button.children[1].children[2]
	local caption = queue[-cmd.id] or ''
	
	-- Build command is disabled (note that this can change dependent on the number of this type of unit currently alive)
	if cmd.disabled then
		-- No Highlight on mouse over
		button.focusColor[4] = 0
		-- Grey out Unit pic
		overlay.color = {0.4,0.4,0.4}
	else
		button.focusColor[4] = 0.5
        if -cmd.id==activeSelUDID then
            overlay.color = selectedColor
            button.borderColor = selectedBorderColor
            selectTab(menuTab[category])
        else
            overlay.color = teamColor
            button.borderColor = {1,1,1,0.1}        
        end
	end
	button.disabled = cmd.disabled
	
	label:SetCaption(caption)
	if not grid[category]:GetChildByName(button.name) then
		-- No duplicates
		grid[category]:AddChild(button)
	end
end

local function HotkeyString(action)
    if Hotkey[action] then
        return " " .. "[" .. Hotkey[action] .. "]"
    else
        return ""
    end
end

local function addState(cmd)
	local param = cmd.params[cmd.params[1] + 2]
	stateMenu:AddChild(Chili.Button:New{
		caption   = param,
		cmdName   = cmd.name,
		tooltip   = cmd.tooltip,
		cmdId     = cmd.id,
		cmdAName  = cmd.action,
		padding   = {0,0,0,0},
		margin    = {0,0,0,0},
		OnMouseUp = {cmdAction},
		font      = {
			color = paramColors[param] or white,
			size  = 16,
		},
		backgroundColor = black,
	})
end

local function addDummyState(cmd)
	stateMenu:AddChild(Chili.Button:New{
		caption   = cmd.action,
		--tooltip   = cmd.tooltip, 
		padding   = {0,0,0,0},
		margin    = {0,0,0,0},
		OnMouseUp = {},
		font      = {
			color = grey,
			size  = 16,
		},
		backgroundColor = black,
	})
end

local function addOrder(cmd)
    local borderColor = (cmd.id==activeSelCmdID) and selectedBorderColor or {1,1,1,0.1}

	local button = Chili.Button:New{
		caption   = '',
		cmdName   = cmd.name,
		tooltip   = cmd.tooltip .. getInline(orderColors[cmd.action]) .. HotkeyString(cmd.action),
		cmdId     = cmd.id,
		cmdAName  = cmd.action,
		padding   = {0,0,0,0},
		margin    = {0,0,0,0},
		OnMouseUp = {cmdAction},
        borderColor = borderColor,
		Children  = {
			Chili.Image:New{
				parent  = button,
				x       = 5,
				bottom  = 5,
				y       = 5,
				right   = 5,
				color   = orderColors[cmd.action] or {1,1,1,1},
				file    = imageDir..'Commands/'..cmd.action..'.png',
			}
		}
	}

    if cmd.id==CMD.STOCKPILE then
        for _,uID in ipairs(sUnits) do -- we just pick the first unit that can stockpile
            local n,q = Spring.GetUnitStockpile(uID)
            if n and q then
                local stockpile_q = Chili.Label:New{right=0,bottom=0,caption=n.."/"..q, font={size=14,shadow=false,outline=true,autooutlinecolor=true,outlineWidth=4,outlineWeight=6}}
                button.children[1]:AddChild(stockpile_q)
                break
            end
        end
    end
    
	orderMenu:AddChild(button)
	orderBG:Resize(orderMenu.height*#orderMenu.children,orderMenu.height)
end

local function addDummyOrder(cmd)
	local button = Chili.Button:New{
		caption   = '',
		--tooltip   = cmd.tooltip .. getInline(orderColors[cmd.action]) .. HotkeyString(cmd.action),
		padding   = {0,0,0,0},
		margin    = {0,0,0,0},
		OnMouseUp = {},
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

	orderMenu:AddChild(button)
	orderBG:Resize(orderMenu.height*#orderMenu.children,orderMenu.height)
end

local function getMenuCat(ud)
	if (ud.speed > 0 and ud.canMove) or ud.isFactory then
        -- factories, and the units they can build
        menuCat = 3
	elseif (ud.radarRadius > 1 or ud.sonarRadius > 1 or 
        ud.jammerRadius > 1 or ud.sonarJamRadius > 1 or
        ud.seismicRadius > 1 or ud.name=='coreyes') and #ud.weapons<=0 then
        -- Intel
		menuCat = 2
    elseif #ud.weapons > 0 or ud.shieldWeaponDef or ud.isFeature then
		-- Defence
		menuCat = 2
	else
		-- Economy
		menuCat = 1
	end

    return menuCat
end

local function AddInSequence(cmds, t, func, dummyFunc)
    for _,k in ipairs(t) do
        if cmds[k] then
            -- add top cmd
            func(cmds[k])
            cmds[k] = nil
        else
            -- add dummy top cmd
            dummy_cmd = {action=k}
            dummyFunc(dummy_cmd)
        end
    end
    
    -- add the rest
    for _,cmd in pairs(cmds) do
        func(cmd)
    end    
end 

local function SetGridDimensions()
	for i=1,#catNames do
        -- work out if we have too many buttons in a grid, request more columns if so
        local n = #grid[i].children 
        local neededColumns = math.floor((n-1)/maxRows)+1
        local nCols = math.max(3, math.min(maxCols, neededColumns))
		local nRows = math.floor((n-1)/nCols)+1
		grid[i].columns = nCols
        grid[i].rows = math.max(4, nRows)
    end
end

local function ChooseTab()
    -- use the most recent tab that wasn't the factory tab, if possible
    for i=1,3 do
        if #grid[i].children>0 and menuTabs.prevChoice==i then return i end
    end
    for i=1,3 do
        if #grid[i].children>0 then return i end
    end
    return nil
end

local function parseCmds()
	local cmdList = spGetActiveCmdDescs()
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
				addBuild(cmd,menuCat)
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
        local stop_cmd = {name="Stop", action='stop', id=CMD.STOP, tooltip="Clears the command queue"}
        orders[stop_cmd.action] = stop_cmd
    end
    
    -- Add the orders/states in the wanted order, from L->R
    if #cmdList>0 then
        AddInSequence(orders, topOrders, addOrder, addDummyOrder)
        AddInSequence(states, topStates, addState, addDummyState)
    end    
end

local function parseUnitDef(uDID)
  -- load the build menu for the given unitDefID
  -- don't load the state/cmd menus

	buildMenu.active = true
	orderMenu.active = false
	
	local buildDefIDs = UnitDefs[uDID].buildOptions
	
	for _,bDID in pairs(buildDefIDs) do
		local ud = UnitDefs[bDID]
		local menuCat = getMenuCat(ud)
		grid[menuCat].active = true
		local cmd = {name=ud.name, id=bDID, disabled=false} --fake cmd desc muahahah
		addBuild(cmd,menuCat)    
	end
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
				y       = (tabCount - 1) * 150 / #catNames + 1,
				height  = 150/#catNames-1,
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
-- Loads/reloads the icon panels for commands
local function loadPanels()

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

	orderMenu:ClearChildren()
	stateMenu:ClearChildren()

	orderArray = {}
	stateArray = {}

	if newUnit then
		sUnits = units
		for i=1,#catNames do
			grid[i]:ClearChildren()
			grid[i].active = false
		end
	end

	parseCmds()
    SetGridDimensions()
	makeMenuTabs()
    menuTabs.choice = ChooseTab()
    if menuTabs.choice and buildMenu.active and menuTab[menuTabs.choice] then selectTab(menuTab[menuTabs.choice]) end
end

local function loadDummyPanels(unitDefID)
	-- load the build menu panels as though this unitDefID were selected, even though it is not
	orderMenu:ClearChildren()
	stateMenu:ClearChildren()

	orderArray = {}
	stateArray = {}

	menuTabs.choice = 1
	for i=1,#catNames do
		grid[i]:ClearChildren()
		grid[i].active = false
	end

	parseUnitDef(unitDefID)
    SetGridDimensions()   
	makeMenuTabs()
    menuTabs.choice = ChooseTab()
    if menuTabs.choice and buildMenu.active then selectTab(menuTab[menuTabs.choice]) end
end

---------------------------
--
local function createButton(name, unitDef)
	-- if it can attack and it's not a plane, get max range of weapons of unit
	local range = 0
	local rangeText = ""
	for _,weapon in pairs(unitDef.weapons) do
		local weaponDefID = weapon.weaponDef
		range = math.max(range, WeaponDefs[weaponDefID].range)
	end
	if range > 0 and not unitDef.canFly then
		rangeText = '\nRange: ' .. range
	end
	
	-- make the tooltip for this unit
	local tooltip = unitDef.humanName..' - '..unitDef.tooltip..
		            '\nCost: '..getInline{0.6,0.6,0.8}..unitDef.metalCost..'\b Metal, '..getInline{1,1,0.3}..unitDef.energyCost..'\b Energy'..
		            '\nBuild Time: '..unitDef.buildTime..
	              rangeText

	-- make the button for this unit
	unit[name] = Chili.Button:New{
		name      = name,
		cmdId     = -unitDef.id,
		tooltip   = tooltip,
		caption   = '',
		disabled  = false,
		padding   = {0,0,0,0},
		margin    = {0,0,0,0},
		OnMouseUp = {cmdAction},
		children  = {
			Chili.Image:New{
				height = '100%', width = '100%',
				file   = imageDir..'Units/'..name..'.dds',
				children = {
					Chili.Label:New{
						caption = '',
						right   = 10,
						y       = 10,
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
 
	local isWater = (unitDef.maxWaterDepth and unitDef.maxWaterDepth>25) or (unitDef.minWaterDepth and unitDef.minWaterDepth>0)
	if isWater then
		-- Add raindrop to unit icon
		Chili.Image:New{
			parent = unit[name].children[1],
			x = 1, bottom = 1,
			height = 15, width = 15,
			file   = imageDir..'raindrop.png',
		}
    end    
end

---------------------------
--	This should now take into account multiple queues
local function queueHandler()
	local unitIDs = Spring.GetSelectedUnits()
	for i=1, #unitIDs do
		local list = Spring.GetRealBuildQueue(unitIDs[i]) or {}
		for i=1, #list do
			for defID, count in pairs(list[i]) do 
				queue[defID] = queue[defID] and (queue[defID] + count) or count
			end
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
function widget:Initialize()
	widgetHandler:ConfigLayoutHandler(LayoutHandler)
	Spring.ForceLayoutUpdate()
	spSendCommands({'tooltip 0'})
    
    if Spring.GetGameFrame()>0 then gameStarted = true end

	if (not WG.Chili) then
		widgetHandler:RemoveWidget()
		return
	end

	Chili = WG.Chili
	screen0 = Chili.Screen0
	
	buildMenu = Chili.Panel:New{
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
		height  = 150,
		width   = 120,
		padding = {0,0,0,0},
		margin  = {0,0,0,0}
	}
	
	orderMenu = Chili.Grid:New{
		parent  = screen0,
		active  = false,
		columns = 21,
		rows    = 1,
		padding = {0,0,0,0},
	}
	
	orderBG = Chili.Panel:New{
		parent = screen0,
	}


	stateMenu = Chili.Grid:New{
		parent  = screen0,
		columns = 2,
		rows    = 8,
        orientation = 'vertical',
		padding = {0,0,0,0},
	}

	-- Creates a container for each category of build commands.
	for i=1,#catNames do
		grid[i] = Chili.Grid:New{
			name     = catNames[i],
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
        createButton(name,unitDef)
	end

end

--------------------------- 
-- 
function widget:ViewResize(_,scrH)
	resizeUI(scrH)
end
--------------------------- 
local selectedUnits = {}
function widget:CommandsChanged()
    -- see if selected units changed, cause an update if so
    local newUnits = Spring.GetSelectedUnits()
    if not newUnits then return end
    if #selectedUnits ~= #newUnits then
        updateRequired = true
        selectedUnits = newUnits
    else
        for i,_ in ipairs(newUnits) do
            if selectedUnits[i]~=newUnits[i] then
                updateRequired = true
                selectedUnits = newUnits
                break
            end
        end
    end
end
function widget:UnitCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
    if cmdID and cmdID<0 and teamID==Spring.GetMyTeamID() then --build command
        updateRequired = true
    end
end
function GameFrame()
    -- track the current active command
    -- has to be GameFrame because CommandsChanged isn't called when an active build command changes
    local _,cmdID,_ = Spring.GetActiveCommand()
    if cmdID and cmdID<0 then
        local uDID = -cmdID -- looking to build a unit of this uDID
        if activeSelCmdID or activeSelUDID~=uDID then 
            updateRequired = true
            activeSelUDID = uDID
            activeSelCmdID = nil
        end
    elseif cmdID then
        -- looking to give this cmdID
        if activeSelUDID or activeSelCmdID~=cmdID then 
            updateRequired = true
            activeSelUDID = nil
            activeSelCmdID = cmdID
            selectTab(menuTab[getMenuCat(uDID)])
        end
    else
        -- no active commands
        if activeSelUDID or activeSelCmdID then 
            updateRequired = true
            activeSelUDID = nil
            activeSelCmdID = nil
        end
    end
end
--------------------------- 
-- Checks status of game and InitialQueue, handles InitialQueue if enabled
local startUnitDefID
local function InitialQueue()
	if not WG.SetSelDefID or gameStarted or Spring.GetSpectatingState() then 
		return false 
	end

	-- check if we just changed faction
	local uDID = WG.startUnit or Spring.GetTeamRulesParam(myTeamID, 'startUnit')
	if uDID==startUnitDefID then return true end 

	-- now act as though unitDefID is selected for building
	startUnitDefID = uDID
    sUnits[1] = uDID
	local r,g,b = Spring.GetTeamColor(Spring.GetMyTeamID())
	teamColor = {r,g,b,0.8}
    
    if WG.HideFacBar then WG.HideFacBar() end
	buildMenu.active = false
	orderMenu.active = false
	if orderBG.visible then
		orderBG:Hide()
	end
	
	loadDummyPanels(startUnitDefID)
	return true
end
--------------------------- 
-- If update is required this Loads the panel and queue for the new unit or hides them if none exists
--  There is an offset to prevent the panel disappearing right after a command has changed (for fast clicking)
function widget:Update()
	if InitialQueue() then return end
	
	if updateRequired then
		local r,g,b = Spring.GetTeamColor(Spring.GetMyTeamID())
		teamColor = {r,g,b,0.8}
		updateRequired = false
		orderMenu.active = false -- if order cmd is found during parse this will become true
		buildMenu.active = false -- if build cmd is found during parse this will become true

		queue = {}
		queueHandler()
		loadPanels()

		if not orderMenu.active and orderBG.visible then
			orderBG:Hide()
		elseif orderMenu.active and orderBG.hidden then
			orderBG:Show()
		end
		
		if not buildMenu.active and buildMenu.visible then
			buildMenu:Hide()
            if WG.ShowFacBar then WG.ShowFacBar() end
		elseif buildMenu.active and buildMenu.hidden then
			buildMenu:Show()
            if WG.HideFacBar then WG.HideFacBar() end
        end
	end
end

function widget:GameStart()
	-- Reverts initial queue behaviour
	for i=1,#catNames do
		grid[i].active = false
	end
	gameStarted = true
	updateRequired = true
end
---------------------------
--
function widget:Shutdown()
	-- Let Chili know we're done with these
	buildMenu:Dispose()
	menuTabs:Dispose()
	
	-- Bring back stock Order Menu
	widgetHandler:ConfigLayoutHandler(nil)
	Spring.ForceLayoutUpdate()
	
	spSendCommands({'tooltip 1'})
end
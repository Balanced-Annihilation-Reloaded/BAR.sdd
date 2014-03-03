-- WIP (excuse the mess)
function widget:GetInfo()
	return {
		name      = 'Funks Selection Menu',
		desc      = 'Shows current selections build, order, and state options',
		author    = 'Funkencool',
		date      = 'Sep 2013',
		license   = 'GNU GPL v2',
		layer     = 0,
		enabled   = true,
		handler   = true,
	}
end
-- Includes --
local cat, ignoreCMDs, orderColors = include('Configs/buildMenu.lua') --categories
local catNames = {'ECONOMY', 'DEFENSE', 'INTEL', 'FACTORIES', 'BUILD'} -- Must be the same as cat indexes
local imageDir = 'luaui/images/buildIcons/'
--------------

-- Config --
local nCol, nRow = 8, 3

------------


-- Chili vars --
local Chili
local panH, panW, winW, winH, winX, winB, tabH, minMapH, minMapW
local screen0, buildMenu, stateMenu, orderMenu, menuTabs 
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
----------------------


-- Local vars --
local updateRequired = true
local sUnits = {}
local oldTimer = spGetTimer()
local r,g,b = Spring.GetTeamColor(Spring.GetMyTeamID())
local teamColor = {r,g,b}
----------------



---------------------------------------------------------------
local function cmdAction(obj, x, y, button, mods)
	local index = spGetCmdDescIndex(obj.cmdId)
	Spring.Echo(obj.name)
	if (index) then
		local left, right = (button == 1), (button == 3)
		local alt, ctrl, meta, shift = mods.alt, mods.ctrl, mods.meta, mods.shift
		spSetActiveCommand(index, button, left, right, alt, ctrl, meta, shift)
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
	local choice = self.tabNum
	showGrid(choice)

	if menuTab[menuTabs.choice] then
		menuTab[menuTabs.choice].font.color = {.5,.5,.5,1}
		menuTab[menuTabs.choice]:Invalidate()
	end

	if menuTab[choice] then
		menuTab[choice].font.color = {1,1,1,1}
		menuTab[choice]:Invalidate()
	end

	menuTabs.choice = choice
end

local function scrollMenus(self,x,y,up,value)
	local choice = menuTabs.choice
	choice = choice - value
	if choice > #menuTab then
		choice = 1
	elseif choice < 1 then
		choice = #menuTab
	end
	selectTab(menuTab[choice])
	return true -- Prevents zooming
end
---------------------------------------------------------------
---------------------------------------------------------------

-- Adds icons/commands to the menu panels accordingly
local function addBuild(cmd, category)
	local button = unit[cmd.name]
	local label = button.children[1].children[1]
	local caption = queue[-cmd.id] or ''
	label:SetCaption(caption)
	if not grid[category]:GetChildByName(button.name) then
		grid[category]:AddChild(button)
	end
end

local function addState(cmd)
	local button = Chili.Button:New{
		caption = cmd.params[cmd.params[1] + 2],
		cmdName   = cmd.name,
		tooltip   = cmd.tooltip,
		cmdId     = cmd.id,
		cmdAName  = cmd.action,
		padding   = {0,0,0,0},
		margin    = {0,0,0,0},
		OnMouseUp = {cmdAction},
	}
	stateMenu:AddChild(button)
end

local function addOrder(cmd)
	local button = Chili.Button:New{
		caption   = '',
		cmdName   = cmd.name,
		tooltip   = cmd.tooltip,
		cmdId     = cmd.id,
		cmdAName  = cmd.action,
		padding   = {0,0,0,0},
		margin    = {0,0,0,0},
		OnMouseUp = {cmdAction},
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
	orderMenu:AddChild(button)
end

local function parseCmds()
	local menuCat
	local cmdList = spGetActiveCmdDescs()

	-- Parses through each active cmd and gives it its own button
	for i = 1, #cmdList do
		local cmd = cmdList[i]
		if cmd.name ~= '' and not (ignoreCMDs[cmd.name] or ignoreCMDs[cmd.action]) then
			
			-- Is it a unit and if so what kind?
			if UnitDefNames[cmd.name] then
				local ud = UnitDefNames[cmd.name]
				
				if ud.speed > 0 and ud.canMove then
					-- Mobile Units
					menuCat = 5
				elseif ud.isFactory then
					-- Factories
					menuCat = 4
				elseif (ud.radarRadius > 1 or ud.sonarRadius > 1 or 
				        ud.jammerRadius > 1 or ud.sonarJamRadius > 1 or
				        ud.seismicRadius > 1 or ud.name=='coreyes') and #ud.weapons<=0 then
					-- Intel
					menuCat = 3
				elseif #ud.weapons > 0 or ud.shieldWeaponDef or ud.isFeature then
					-- Defense
					menuCat = 2
				else
					-- Economy
					menuCat = 1
				end
			end

			if menuCat and #grid[menuCat].children < (nRow*nCol) then
				buildMenu.active     = true
				grid[menuCat].active = true
				addBuild(cmd,menuCat)
			elseif #cmd.params > 1 then
				addState(cmd)
			elseif cmd.id > 0 then
				addOrder(cmd)
			end

		end
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
			menuTab[tabCount] = Chili.Button:New{
				tabNum  = i,
				parent  = menuTabs,
				width   = '100%',
				y       = (tabCount - 1) * tabH / #catNames + 1,
				height  = tabH/#catNames-1,
				caption = catNames[i],
				OnClick = {selectTab},
				font    = {
					color = {.5, .5, .5, 1}
				},
			}
		end
	end

	if tabCount == 1 then
		menuTab[1]:Hide()
	elseif tabCount > 1 then
		menuTab[menuTabs.choice].font.color = {1,1,1,1}
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
		menuTabs.choice = 1
		for i=1,#catNames do
			grid[i]:ClearChildren()
			grid[i].active = false
		end
	end

	parseCmds()
	makeMenuTabs()
	if menuTab[menuTabs.choice] then selectTab(menuTab[menuTabs.choice]) end
end

---------------------------
--
local function queueHandler()
	local unitID = Spring.GetSelectedUnits()
	if unitID[1] then
		local list = Spring.GetRealBuildQueue(unitID[1]) or {}
		for i=1, #list do
			for defID, count in pairs(list[i]) do queue[defID] = count end
		end
	end
end

---------------------------
-- Iniatilizes main/permanent chili controls
--  These are then shown/hidden when needed
function widget:Initialize()
	widgetHandler:ConfigLayoutHandler(false)
	Spring.ForceLayoutUpdate()
	spSendCommands({'tooltip 0'})

	if (not WG.Chili) then
		widgetHandler:RemoveWidget()
		return
	end

	Chili = WG.Chili
	screen0 = Chili.Screen0

	-- WIP to customize layout
	-- config --
	local vertical = true
	local minMapBottom = true
	------------

	-- these numbers are used by numerous chili widgets
	--  TODO should be an include or global object
	local scrH = screen0.height
	local tabB = 0
	local ordH = scrH * 0.07
	local selH = scrH * 0.2
	local selW = selH
	minMapH = scrH * 0.3
	minMapW = minMapH * Game.mapX/Game.mapY

	if (Game.mapX/Game.mapY > 1) then
		minMapW = minMapH*(Game.mapX/Game.mapY)^0.5
		minMapH = minMapW * Game.mapY/Game.mapX
	end

	if minMapBottom then
		selW = minMapW
		selH = minMapH
	end

	if vertical then
		local tempRow = nRow
		nRow = nCol
		nCol = tempRow
		winH = scrH * 0.5
		winW = winH * nCol / nRow
		tabH = winH/3
		winX = 0
		winB = selH
		tabB = winB + selH
	else
		winH = scrH * 0.15
		winW = winH * nCol / nRow
		tabH = winH
		winX = selW
		winB = 0
	end



	buildMenu = Chili.Window:New{
		parent       = screen0,
		name         = 'buildMenu',
		active       = false,
		x            = winX,
		bottom       = winB,
		width        = winW,
		height       = winH,
		padding      = {0,0,0,0},
		OnMouseWheel = {scrollMenus},
	}

	menuTabs = Chili.Control:New{
		parent  = screen0,
		choice  = 1,
		x       = winX + winW,
		bottom  = tabB,
		width   = 100,
		height  = tabH,
		padding = {0,0,0,0},
		margin  = {0,0,0,0}
	}

	orderMenu = Chili.Grid:New{
		parent      = screen0,
		columns     = 21,
		rows        = 1,
		bottom      = 0,
		x           = selW,
		height      = ordH,
		width       = ordH*21,
		padding     = {0,0,0,0},
	}

	stateMenu = Chili.Grid:New{
		parent  = screen0,
		columns = 1,
		rows    = 8,
		y       = 1,
		x       = scrH * 0.2,
		height  = scrH * 0.2,
		width   = scrH * 0.1,
		padding = {0,0,0,0},
	}



	-- Creates a container for each category.
	for i=1,#catNames do
		grid[i] = Chili.Grid:New{
			name     = catNames[i],
			parent   = buildMenu,
			x        = 0,
			y        = 0,
			right    = 0,
			bottom   = 0,
			rows     = nRow,
			columns  = nCol,
			padding  = {0,0,0,0},
			margin   = {0,0,0,0},
		}
	end

	-- Creates a cache of buttons.
	for name, data in pairs(UnitDefNames) do
		unit[name] = Chili.Button:New{
			name      = name,
			cmdId     = -data.id,
			tooltip   = data.tooltip,
			caption   = '',
			padding   = {0,0,0,0},
			margin    = {0,0,0,0},
			OnMouseUp = {cmdAction},
			children  = {
				Chili.Image:New{
					height = '100%', width = '100%',
					file   = imageDir..'Units/'..name..'.png',
					children = {
						Chili.Label:New{
							caption = '',
							right   = 2,
							y       = 2,
						},
						Chili.Image:New{
							color  = teamColor,
							height = '100%', width = '100%',
							file   = imageDir..'Overlays/'..name..'.png',
						},
					}
				}
			}
		}
	end


end
--------------------------- 
-- When Available Commands change this is called
--  sets Updaterequired to true
function widget:CommandsChanged()
	updateRequired = true
end
--------------------------- 
-- If update is required this Loads the panel and queue for the new unit or hides them if none exists
--  There is an offset to prevent the panel dissappearing right after a command has changed (for fast clicking)
function widget:Update()
	if updateRequired then
		updateRequired = false
		buildMenu.active = false
		queue = {}
		queueHandler()
		loadPanels()

		if not buildMenu.active and buildMenu.visible then
			buildMenu:Hide()
		elseif buildMenu.active and buildMenu.hidden then
			buildMenu:Show()
		end
	end
end
---------------------------
--
function widget:Shutdown()
	buildMenu:Dispose()
	menuTabs:Dispose()
	widgetHandler:ConfigLayoutHandler(nil)
	Spring.ForceLayoutUpdate()
	spSendCommands({'tooltip 1'})
end

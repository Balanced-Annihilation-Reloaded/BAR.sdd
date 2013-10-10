-- Version 0.7 WIP
function widget:GetInfo()
	return {
		name      = 'Funks current selection Menu',
		desc      = 'Shows current selections build, order, and state options',
		author    = 'Funkencool',
		date      = 'Sep 2013',
		license   = 'GNU GPL v2',
		layer     = 0,
		enabled   = true,
		handler   = true,
	}
end
-- Includes
local cat, ignoreCMDs = include('Configs/buildMenu.lua') --categories
local catNames = {'ECONOMY', 'DEFENSE', 'INTEL', 'FACTORIES', 'BUILD'} -- Must be the same as cat indexes
local imageDir = 'luaui/images/buildIcons/'
-- Chili vars
local Chili
local nCol, nRow = 7,2
local panH, panW, winW, winH, winX, winB, tabH, minMapH, minMapW
local buildMenu, menuTabs, panel0, stateWindow, scroll0, idx
local menuTab, buildQueue, screen0, buildMenu, stateMenu, orderMenu
local buildGrids = {}
local buildArray = {}
local orderArray = {}
local stateArray = {}
local queue = {}
----------------
local updateRequired = true
local updateTab = true
local selectedUnits = {}

local spGetActiveCmdDesc  = Spring.GetActiveCmdDesc
local spGetActiveCmdDescs = Spring.GetActiveCmdDescs
local spGetActiveCommand  = Spring.GetActiveCommand
local spGetCmdDescIndex   = Spring.GetCmdDescIndex
local spGetFullBuildQueue = Spring.GetFullBuildQueue
local spGetSelectedUnits  = Spring.GetSelectedUnits
local spSendCommands      = Spring.SendCommands
local spSetActiveCommand  = Spring.SetActiveCommand

local r,g,b = Spring.GetTeamColor(Spring.GetMyTeamID())
local teamColor = {r,g,b}

---------------------------
--
function LayoutHandler(xIcons, yIcons, cmdCount, commands)
	widgetHandler.commands   = commands
	widgetHandler.commands.n = cmdCount
	widgetHandler:CommandsChanged()
	local reParamsCmds = {}
	local customCmds = {}
	
	return '', xIcons, yIcons, {}, customCmds, {}, {}, {}, {}, reParamsCmds, {[1337]=9001}
end
---------------------------
--
local function cmdAction(chiliButton, x, y, button, mods)
	local index = spGetCmdDescIndex(chiliButton.cmdID)
	-- Spring.Echo(chiliButton.cmdName,chiliButton.cmdAName)
	if (index) then
		local left, right = (button == 1), (button == 3)
		local alt, ctrl, meta, shift = mods.alt, mods.ctrl, mods.meta, mods.shift
		spSetActiveCommand(index, button, left, right, alt, ctrl, meta, shift)
	end
end
--------------------------- Selects tab when tab is clicked or scrolled
--
local function selectTab(self,x,y,up,value,mods)
	menuTab[buildMenu.choice]:SetCaption('\255\127\127\127'.. catNames[buildMenu.choice])
	if buildGrids[buildMenu.choice] then
		buildGrids[buildMenu.choice]:ToggleVisibility()
	end
	
	if self.name == 'buildMenu' then --mouse scrolled over 'buildMenu'? else tab was pressed
		buildMenu.choice = buildMenu.choice - value
		for i=1,#catNames do
			
			if buildArray[buildMenu.choice] and (#buildArray[buildMenu.choice] < 1) then
				buildMenu.choice = buildMenu.choice - value
			end
			
			if buildMenu.choice > #catNames then
				buildMenu.choice = 1
			elseif buildMenu.choice < 1 then
				buildMenu.choice = #catNames
			end
			
		end
		
	else
		buildMenu.choice = self.tabNum
	end
	
	menuTab[buildMenu.choice]:SetCaption('\255\255\255\255'.. catNames[buildMenu.choice])
	buildGrids[buildMenu.choice]:ToggleVisibility()
	return true --prevents zoom function when mouse scrolled over menu
end
--------------------------- Adds icons/commands to the menu panels accordingly
--
local function createMenus()
	
	local menuCat
	local cmdList = spGetActiveCmdDescs()
	
	
	for i = 1, #cmdList do
		local cmd = cmdList[i]
		if cmd.name ~= '' and not (ignoreCMDs[cmd.name] or ignoreCMDs[cmd.action]) then
			
			--decides which category a unit is in
			for i=1, #catNames do
				if cat[catNames[i]][cmd.name] then
					menuCat = i
					buildMenu.active = true
					break
				end
			end
			
			local button = Chili.Button:New{
				caption = '',
				cmdName   = cmd.name,
				tooltip   = cmd.tooltip,
				cmdID     = cmd.id,
				cmdAName  = cmd.action,
				padding   = {0,0,0,0},
				margin    = {0,0,0,0},
				OnMouseUp = {cmdAction},
			}
			
			-- for units
			if menuCat then
				local caption = queue[-cmd.id] or ''
				
				local image = Chili.Image:New{
					parent = button,
					height = '100%', width = '100%',
					file   = imageDir..'Units/'..cmd.name..'.png',
					children = {
						Chili.Label:New{
							right   = 2,
							y       = 2,
							caption = caption
						},
						Chili.Image:New{
							color  = teamColor,
							height = '100%', width = '100%',
							file   = imageDir..'Overlays/'..cmd.name..'.png',
						},
					},
				}
				buildArray[menuCat][#buildArray[menuCat] + 1] = button
				
			-- For states
			elseif #cmd.params > 1 then
				button.caption = cmd.params[cmd.params[1] + 2]
				stateMenu:AddChild(button)
				
			-- For commands
			else
				local oNum = #orderMenu.children
				
				local image = Chili.Image:New{
					parent  = button,
					x       = 5, 
					bottom  = 5,
					y       = 5, 
					right   = 5,
					file    = imageDir..'Commands/Bold/'..cmd.name..'.png',
				}
				orderMenu:AddChild(button)
			end
			
		end
	end
	
	
	
	--Creates a container for each category and adds equivelant array as child.
	for i=1,#catNames do
		buildGrids[i] = Chili.Grid:New{
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
			children = buildArray[i],
		}
		if updateTab and (#buildArray[i] > 0) then buildMenu.choice = i; updateTab = false end
		if buildMenu.choice ~= i then buildGrids[i]:Hide() end
	end
	
end
--------------------------- Creates a tab for each menu Panel with a command
--
local function makeMenuTabs()
	menuTabs:ClearChildren()
	menuTab = {}
	local tabCount = 0
	for i=1, #catNames do
		if #buildArray[i] > 0 then
			
			menuTab[i] = Chili.Button:New{
				tabNum  = i,
				parent  = menuTabs,
				right   = 12,
				width   = 100,
				y       = (tabCount) * tabH/#catNames+1,
				height  = tabH/#catNames-1,
				caption = '\255\127\127\127'..catNames[i],
				OnClick = {selectTab}
			}
			tabCount = tabCount + 1
		end
		
	end
	
	if tabCount < 2 then 
		menuTabs:ClearChildren()
	else 
		menuTab[buildMenu.choice]:SetCaption('\255\255\255\255'.. catNames[buildMenu.choice])
	end
end

--------------------------- Loads/reloads the icon panels for commands
--
local function loadPanels()
	
	buildMenu:ClearChildren()
	orderMenu:ClearChildren()
	stateMenu:ClearChildren()
	for i=1,#catNames do buildArray[i] = {} end
	orderArray = {}
	stateArray = {}
	
	local units = spGetSelectedUnits()
	if units[1] and (selectedUnits[1] ~= units[1]) then
		selectedUnits = units
		updateTab = true
	end
	createMenus()
	makeMenuTabs()
end
--------------------------- Adds icons to queue panel depending on build commands in queue
--  or hides it if there are none
local function queueHandler()
	local unitID = Spring.GetSelectedUnits()
	if unitID[1] then
		local list = Spring.GetRealBuildQueue(unitID[1])
		for i=1, #list do
			for defID, count in pairs(list[i]) do queue[defID] = count end
		end
	end
end
--------------------------- Iniatilizes main/permanent chili controls
--  These are then shown/hidden when needed
function widget:Initialize()
	widgetHandler:ConfigLayoutHandler(LayoutHandler)
	Spring.ForceLayoutUpdate()
	spSendCommands({'tooltip 0'})
	
	if (not WG.Chili) then
		widgetHandler:RemoveWidget()
		return
	end
	
	Chili = WG.Chili
	screen0 = Chili.Screen0
	local vertical = true --config
	local minMapBottom = true --config
	
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
		nCol, nRow = 2, 7
		winH       = scrH * 0.5
		winW       = winH * nCol / nRow
		tabH       = winW
		winX       = 0
		winB       = selH
		tabB       = winB + selH
	else
		winH      = scrH * 0.15
		winW      = winH * nCol / nRow
		tabH      = winH
		winX      = selW
		winB      = 0
	end
	
	
	
	buildMenu = Chili.Window:New{
		parent       = screen0,
		name         = 'buildMenu',
		-- skinName     = 'Flat',
		choice       = 1,
		active       = false,
		x            = winX,
		bottom       = winB,
		width        = winW,
		height       = winH,
		padding      = {0,0,0,0},
		OnMouseWheel = {selectTab},
	}
	
	menuTabs = Chili.Control:New{
		parent  = screen0,
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
	
	
	-- Blur option to menu ( may be resource intensive )
	-- if WG['blur_api'] then
	-- WG['blur_api'].UseNoise(true)
	-- idx = WG['blur_api'].InsertBlurRect(5,screen0.height * 0.7+5,winW-5,5)
	-- end
end
--------------------------- When Available Commands change this is called
--  sets Updaterequired to true
function widget:CommandsChanged()
	buildMenu.active = false
	updateRequired = true
end
--------------------------- If update is required this Loads the panel and queue for the new unit or hides them if none exists
--  There is an offset to prevent the panel dissappearing right after a command has changed (for fast clicking)
function widget:GameFrame(n)
	if updateRequired == true and ((n % 4) < 1) then
		updateRequired = false
		queue = {}
		queueHandler()
		loadPanels()
		if not buildMenu.active and buildMenu.visible then buildMenu:Hide()
		elseif buildMenu.active and buildMenu.hidden then buildMenu:Show() end
	end
end
---------------------------
--
function widget:Shutdown()
	buildMenu:Dispose()
	menuTabs:Dispose()
	--buildQueue:Dispose()
	widgetHandler:ConfigLayoutHandler(nil)
	Spring.ForceLayoutUpdate()
	if idx then WG['blur_api'].RemoveBlurRect(idx) end
	spSendCommands({'tooltip 1'})
end			
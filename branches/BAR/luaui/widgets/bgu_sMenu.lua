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
local nRow, nCol, mCol = 8, 4, 4
local catNames = {'ECONOMY', 'BATTLE', 'FACTORY'} -- order matters
local imageDir = 'luaui/images/buildIcons/'

-- Not sure if these are wanted? plus they need icons
--  Will probably ignore redundant units here (e.g. floating AA, umex, etc. which are interchangeable)
local ignoreCMDs = {
	settarget 	 = '',
	canceltarget = '',
	selfd 	     = '',
	loadonto 	   = '',
	timewait 	   = '',
	deathwait    = '',
	squadwait	   = '',
	gatherwait	 = '',
	restore      = '',
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
	fight       = {1.0, 0.3, 0.0, 1.0},
	areaattack  = {0.8, 0.0, 0.0, 1.0},
	manualfire  = {0.8, 0.4, 0.0, 1.0},
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
}
------------


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
----------------------


-- Local vars --
local updateRequired = true
local sUnits = {}
local oldTimer = spGetTimer()
local r,g,b = Spring.GetTeamColor(Spring.GetMyTeamID())
local teamColor = {r,g,b}
local gameStarted = (Spring.GetGameFrame()>0)
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
        return true
    end
    local index = spGetCmdDescIndex(obj.cmdId)
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

local function resizeUI(scrH)
	local ordH = scrH * 0.05
	local ordY = scrH - ordH
	local winY = scrH * 0.2
	local winH = scrH * 0.5
	local winW = winH * nCol / nRow
	local aspect = Game.mapX/Game.mapY
	local minMapH = scrH * 0.3
	local minMapW = minMapH * aspect
	if aspect > 1 then
		minMapW = minMapH * aspect^0.5
		minMapH = minMapW / aspect
	end
	
	buildMenu:SetPos(0, winY, winW, winH)
	menuTabs:SetPos(winW,winY+20)
	orderMenu:SetPos(minMapW,ordY,ordH*21,ordH)
	orderBG:SetPos(minMapW,ordY,ordH*#orderMenu.children,ordH)
	stateMenu:SetPos(winY,0,100,winY)
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
		overlay.color = teamColor
	end
	button.disabled = cmd.disabled
	
	label:SetCaption(caption)
	if not grid[category]:GetChildByName(button.name) then
		-- No duplicates
		grid[category]:AddChild(button)
	end
end

local function addState(cmd)
	local button = Chili.Button:New{
		caption   = cmd.params[cmd.params[1] + 2],
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
    
    if cmd.id==CMD.STOCKPILE then
        local units = Spring.GetSelectedUnits()
        for _,uID in ipairs(units) do -- we just pick the first unit that can stockpile
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
	orderMenu:SetLayer(2)
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

local function parseCmds()
	local cmdList = spGetActiveCmdDescs()
    
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

			if menuCat and #grid[menuCat].children < (nRow*mCol) then
				buildMenu.active     = true
				grid[menuCat].active = true
				addBuild(cmd,menuCat)
			elseif #cmd.params > 1 then
				addState(cmd)
			elseif cmd.id > 0 and not WG.OpenHostsList then -- hide the order menu if the open host list is showing (it shows to specs who have it enabled)
				orderMenu.active = true
				addOrder(cmd)
			end

		end
	end
    
	-- work out if we have too many buttons, widen the menu if so
	local n = 0
	for i=1,#catNames do
		n = math.max(n,#grid[i].children)
	end
	
	if n <=3*8 then 
		nCol = 3 
	else 
		nCol = 4 --max 32 buttons displayed per cat
	end

	for i=1,#catNames do
		grid[i].columns = nCol
	end
	
	resizeUI(Chili.Screen0.height)
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
	
	for i=1,#catNames do
		grid[i].columns = 3
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
				tooltip = 'You can scroll through the different categories with your mouse wheel!',
				parent  = menuTabs,
				width   = '100%',
				y       = (tabCount - 1) * 150 / #catNames + 1,
				height  = 150/#catNames-1,
				caption = catNames[i],
				OnClick = {selectTab},
				OnMouseWheel = {scrollMenus},
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
	makeMenuTabs()
	if menuTab[menuTabs.choice] then selectTab(menuTab[menuTabs.choice]) end
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

	local raindrop = Chili.Image:New{
		x = 1, bottom = 1,
		height = 15, width = 15,
		file   = imageDir..'raindrop.png',
	}

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
						right   = 2,
						y       = 2,
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
 
	local isWater = (unitDef.maxWaterDepth and unitDef.maxWaterDepth>20) or (unitDef.minWaterDepth and unitDef.minWaterDepth>0)
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
-- Including LayoutHandler causes CommandsChanged to be called twice? 
local function LayoutHandler(xIcons, yIcons, cmdCount, commands)
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
	
	local scrH = screen0.height
	local ordH = scrH * 0.05
	local winY = scrH * 0.2
	local winH = scrH * 0.5
	local winW = winH * nCol / nRow
	local aspect = Game.mapX/Game.mapY
	local minMapH = scrH * 0.3
	local minMapW = minMapH * aspect
	if aspect > 1 then
		minMapW = minMapH * aspect^0.5
		minMapH = minMapW / aspect
	end
	
	buildMenu = Chili.Window:New{
		parent       = screen0,
		name         = 'buildMenu',
		active       = false,
		x            = 0,
		y            = winY,
		width        = winW,
		height       = winH,
		padding      = {0,0,0,0},
		OnMouseWheel = {scrollMenus},
	}

	menuTabs = Chili.Control:New{
		parent  = screen0,
		choice  = 1,
		x       = winW,
		y       = winY+20,
		height  = 150,
		width   = 100,
		padding = {0,0,0,0},
		margin  = {0,0,0,0}
	}
	
	orderMenu = Chili.Grid:New{
		parent  = screen0,
		active  = false,
		columns = 21,
		rows    = 1,
		y       = scrH - ordH,
		x       = minMapW,
		height  = ordH,
		width   = ordH*21,
		padding = {0,0,0,0},
	}
	
	orderBG = Chili.Window:New{
		parent = screen0,
		y      = scrH - ordH,
		x      = minMapW,
		height = ordH,
		width  = ordH*21,
	}


	stateMenu = Chili.Grid:New{
		parent  = screen0,
		columns = 2,
		rows    = 8,
		y       = 1,
		x       = scrH * 0.2 * 1.05, --x and height match sInfo
		height  = scrH * 0.2,
		width   = 200,
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
			rows     = nRow,
			columns  = nCol,
			padding  = {0,0,0,0},
			margin   = {0,0,0,0},
		}
	end
    

	-- Create a cache of buttons stored in the unit array
	for name, unitDef in pairs(UnitDefNames) do
		-- Skip BA units ( uses much less lua memory )
		if not name:find('_ba') then
			createButton(name,unitDef)
		end      
	end

end

--------------------------- 
-- quick and dirty fix for resizing (needs clean up, has copy/paste code etc..)
function widget:ViewResize(_,scrH)
	resizeUI(scrH)
	updateRequired = true
end
--------------------------- 
-- When Available Commands change this is called
--  sets Updaterequired to true (checked in widget:Update)
function widget:CommandsChanged()
	updateRequired = true
end
--------------------------- 
-- If update is required this Loads the panel and queue for the new unit or hides them if none exists
--  There is an offset to prevent the panel disappearing right after a command has changed (for fast clicking)
local startUnitDefID

function widget:Update()

	if not gameStarted and not Spring.GetSpectatingState() then        
		-- game hasn't started, so we are dealing only with initial_queue at this point
		-- check that initial_queue is present
		if not WG.SetSelDefID then return end
		
		-- check if we just changed faction
		local uDID = WG.startUnit or Spring.GetTeamRulesParam(myTeamID, 'startUnit')
		if uDID==startUnitDefID then return end 
		
		-- now act as though unitDefID is selected for building
		startUnitDefID = uDID
		local r,g,b = Spring.GetTeamColor(Spring.GetMyTeamID())
		teamColor = {r,g,b}
	
		WG.HideFacBar()
		buildMenu.active = false
		orderMenu.active = false
		if not orderBG.hidden then
			orderBG:Hide()
		end
		
		loadDummyPanels(startUnitDefID)
		return
	end

	if updateRequired then
		local r,g,b = Spring.GetTeamColor(Spring.GetMyTeamID())
		teamColor = {r,g,b}
		
		updateRequired = false
		buildMenu.active = false
		orderMenu.active = false
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
			WG.ShowFacBar()	
		elseif buildMenu.active and buildMenu.hidden then
			buildMenu:Show()
			WG.HideFacBar()		
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

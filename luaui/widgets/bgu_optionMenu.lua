-- WIP
-- Look at the globalize function for an explanation on the 'API' to add options to menu from other widgets
--  as of writing this it is around line 700

-- TODO add popup window/API
-- TODO Handle spring settings better in general
-- TODO possibly seperate engine options and handling to seperate widget
--   same with widget/interface tab
function widget:GetInfo()
	return {
		name    = 'Main Menu',
		desc    = 'The main menu; for information, settings, widgets, etc',
		author  = 'Funkencool',
		date    = '2013',
		license = 'GNU GPL v2',
		layer   = -100,
		handler = true,
		enabled = true
	}
end


local spSendCommands = Spring.SendCommands
local spgetFPS       = Spring.GetFPS
local spGetTimer     = Spring.GetTimer

local Chili, mainMenu, menuTabs, menuBtn
local Settings = {}
local DefaultSettings = {}

local white = '\255\255\255\255'

-- Defaults ---  
-- DefaultSettings can only contain things from springsettings
-- not all settings appear here, only ones for which we actually want to overwrite the defaults when "reset to defaults" is clicked
DefaultSettings['Water']            = 'Reflective'
DefaultSettings['Shadows']          = 'Medium'

DefaultSettings['AdvMapShading']    = true
DefaultSettings['AdvModelShading']  = true
DefaultSettings['AllowDeferredMapRendering']   = true
DefaultSettings['AllowDeferredModelRendering'] = true

DefaultSettings['DistIcon']         = 200
DefaultSettings['DistDraw']         = 200
DefaultSettings['MaxParticles']     = 1000
DefaultSettings['MaxNanoParticles'] = 1000
DefaultSettings['MapBorder']        = true
DefaultSettings['DrawTrees']        = true
DefaultSettings['ShowHealthBars']   = true
DefaultSettings['MapMarks']         = true
DefaultSettings['DynamicSky']       = false
DefaultSettings['DynamicSun']       = false

-- Load relevant things from springsettings 
Settings['DistIcon']                    = Spring.GetConfigInt('DistIcon', 200) -- number is used if no config is set
Settings['DistDraw']                    = Spring.GetConfigInt('DistDraw', 200)
Settings['MaxNanoParticles']            = Spring.GetConfigInt('MaxNanoParticles', 1000)
Settings['MaxParticles']                = Spring.GetConfigInt('MaxParticles', 1000)
Settings['MapBorder']                   = Spring.GetConfigInt('MapBorder') == 1 -- turn 0/1 to bool
Settings['AdvMapShading']               = Spring.GetConfigInt('AdvMapShading', 1) == 1
Settings['AdvModelShading']             = Spring.GetConfigInt('AdvModelShading', 1) == 1
Settings['AllowDeferredMapRendering']   = Spring.GetConfigInt('AllowDeferredMapRendering') == 1
Settings['AllowDeferredModelRendering'] = Spring.GetConfigInt('AllowDeferredModelRendering') == 1
Settings['DrawTrees']                   = Spring.GetConfigInt('DrawTrees') == 1
Settings['MapMarks']                    = Spring.GetConfigInt('MapMarks') == 1
Settings['DynamicSky']                  = Spring.GetConfigInt('DynamicSky') == 1
Settings['DynamicSun']                  = Spring.GetConfigInt('DynamicSun') == 1

Settings['Water']   = 'Reflective'
Settings['Shadows'] = 'Medium'
-- I don't know how to check if luaui healthbars is set to 1 or not!

Settings['searchWidgetDesc'] = true
Settings['searchWidgetAuth'] = true
Settings['searchWidgetName'] = true
Settings['widget']           = {}
Settings['UIwidget']         = {}
Settings['Skin']             = 'Robofunk'
Settings['Cursor']           = 'Default'
Settings['CursorName']       = 'ba'

------------------------------------
local wFilterString = ""
local widgetList = {}
local tabs = {}
local credits = VFS.LoadFile('credits_game.txt')
local changelog = VFS.LoadFile('changelog.txt')
local NewbieInfo = include('configs/NewbieInfo.lua')
local HotkeyInfo = include('configs/HotkeyInfo.lua')

local amNewbie = (Spring.GetTeamRulesParam(Spring.GetMyTeamID(), 'isNewbie') == 1)


local wCategories = {
	['unit']      = {label = 'Units',       list = {}, pos = 1,},
	['cmd']       = {label = 'Commands',    list = {}, pos = 2,},
	['gui']       = {label = 'GUI',         list = {}, pos = 3,},
	['snd']       = {label = 'Sound',       list = {}, pos = 4,},
	['camera']    = {label = 'Camera',      list = {}, pos = 5,},
	['map']       = {label = 'Map',         list = {}, pos = 6,},
	['bgu']       = {label = 'BAR GUI',     list = {}, pos = 7,},
	['gfx']       = {label = 'GFX',         list = {}, pos = 8,},
	['api']       = {label = 'API',         list = {}, pos = 9,},
	['dbg']       = {label = 'Debugging',   list = {}, pos = 10,},
	['test']      = {label = 'Test Widgets',list = {}, pos = 11,},
	['ungrouped'] = {label = 'Ungrouped',   list = {}, pos = 12,},
}
---------------------------- 
--
local function setCursor(cursorSet)
	local cursorNames = {
		'cursornormal','cursorareaattack','cursorattack','cursorattack',
		'cursorbuildbad','cursorbuildgood','cursorcapture','cursorcentroid',
		'cursorwait','cursortime','cursorwait','cursorunload','cursorwait',
		'cursordwatch','cursorwait','cursordgun','cursorattack','cursorfight',
		'cursorattack','cursorgather','cursorwait','cursordefend','cursorpickup',
		'cursorrepair','cursorrevive','cursorrepair','cursorrestore','cursorrepair',
		'cursormove','cursorpatrol','cursorreclamate','cursorselfd','cursornumber',
	}
	
	for i=1, #cursorNames do
		local topLeft = (cursorNames[i] == 'cursornormal' and cursorSet ~= 'k_haos_girl')
		if cursorSet == 'ba' then Spring.ReplaceMouseCursor(cursorNames[i], cursorNames[i], topLeft)
		else Spring.ReplaceMouseCursor(cursorNames[i], cursorSet..'/'..cursorNames[i], topLeft) end
	end
end

----------------------------
-- Toggles widgets, enabled/disabled when clicked
--  does not account for failed initialization of widgets yet
local function toggleWidget(self)
	widgetHandler:ToggleWidget(self.name)
	if self.checked then
		self.font.color        = {1,0,0,1}
		self.font.outlineColor = {1,0,0,0.2}
	else
		self.font.color        = {0.5,1,0,1}
		self.font.outlineColor = {0.5,1,0,0.2}
	end
	self:Invalidate()
end

---------------------------- 
-- Adds widget to the appropriate groups list of widgets
local function groupWidget(name,wData)

	local _, _, category = string.find(wData.basename, '([^_]*)')
	if (not category) or (not wCategories[category]) then category = 'ungrouped' end

	for cat_name,cat in pairs(wCategories) do
		if category == cat_name then
			cat.list[#cat.list+1] = {name = name, wData = wData} 
		end
	end

end

---------------------------- 
-- Decides which group each widget goes into
local function sortWidgetList()
	local wFilterString = string.lower(wFilterString or '')
	for name,wData in pairs(widgetHandler.knownWidgets) do
	
		-- Only adds widget to group if it matches an enabled filter
		if (Settings.searchWidgetName and string.lower(name or ''):find(wFilterString))
		or (Settings.searchWidgetDesc and string.lower(wData.desc or ''):find(wFilterString))
		or (Settings.searchWidgetAuth and string.lower(wData.author or ''):find(wFilterString)) then
			groupWidget(name,wData)
		end
		
		-- Alphabetizes widgets by name in ascending order
		for _,cat in pairs(wCategories) do
			local ascendingName = function(a,b) return a.name<b.name end
			table.sort(cat.list,ascendingName)
		end
		
	end
end

---------------------------- 
-- Creates widget list for interface tab
--  TODO create cache of chili objects on initialize 
--    (doesn't need to recreate everything unless /luaui reload is called)
--  TODO detect widget failure, set color accordingly
local function makeWidgetList()
	sortWidgetList()
	local stack = tabs['Interface']:GetObjectByName('widgetList')
	stack:ClearChildren()

	-- Get order of categories
	local inv_pos = {}
	local num_cats = 0
	for cat_name,cat in pairs(wCategories) do
		if cat.pos then
			inv_pos[cat.pos] = cat_name
			num_cats = num_cats + 1
		end
	end
	
	-- First loop adds group label
	for i=1, num_cats do
		-- Get group of pos i
		local cat = wCategories[inv_pos[i]]
		local list = cat.list
		if #list>0 then
			stack:AddChild(Chili.Label:New{caption  = cat.label,x='0%',fontsize=18})
			-- Second loop adds each widget
			for b=1,#list do	
				local green  = {color = {0.5,1,0,1}, outlineColor = {0.5,1,0,0.2}}
				local orange = {color = {1,0.5,0,1}, outlineColor = {1,0.5,0,0.2}}
				local red    = {color = {1,0,0,1}, outlineColor = {1,0,0,0.2}}
				
				local enabled = (widgetHandler.orderList[list[b].name] or 0)>0
				local active  = list[b].wData.active
				local author = list[b].wData.author or "Unkown"
				local desc = list[b].wData.desc or "No Description"
				local fromZip = list[b].wData.fromZip and "" or "*"
				stack:AddChild(Chili.Checkbox:New{
					name      = list[b].name,
					caption   = list[b].name .. fromZip,
					tooltip   = 'Author: '..author.. '\n'.. desc,
					width     = '80%',
					x         = '10%',
					font      = (active and green) or (enabled and orange) or red,
					checked   = enabled,
					OnChange  = {toggleWidget},
				
				})
			end
		end
		cat.list = {}
	end
end

---------------------------- 
local function CheckSpec()
    -- hide the resign button if we are a spec
    if Spring.GetSpectatingState() and not tabs.Info:GetChildByName('ResignButton').hidden then
        tabs.Info:GetChildByName('ResignButton'):Hide()
    else
        if tabs.Info:GetChildByName('ResignButton').hidden then
            tabs.Info:GetChildByName('ResignButton'):Show()        
        end
    end
end

-- Toggles the menu visibility
--  also handles tab selection (e.g. f11 was pressed and menu opens to 'Interface')
local function showHide(tab)
	local oTab = Settings.tabSelected
	
    
	if tab then 
		menuTabs:Select(tab)
        CheckSpec()
    else
		mainMenu:ToggleVisibility()
        CheckSpec()
		return
	end
	
	if mainMenu.visible and oTab == tab then
		mainMenu:Hide()
	elseif mainMenu.hidden then
		mainMenu:Show()
        CheckSpec()	
    end
end

---------------------------- 
-- Handles the selection of the tabs
local function sTab(_,tabName)
  if Settings.tabSelected then mainMenu:RemoveChild(tabs[Settings.tabSelected]) end
  mainMenu:AddChild(tabs[tabName])
  Settings.tabSelected = tabName
end

---------------------------- 
-- Rebuilds widget list with new filter
local function addFilter()
	local editbox = tabs['Interface']:GetObjectByName('widgetFilter')
	wFilterString = editbox.text or ""
	makeWidgetList()
	editbox:SetText('')
end

---------------------------- 
-- Saves a variable in the settings array
local function Save(index, data)

	-- New behavior, Save{ key = value, key2 = value2 } 
	if type(index)=='table' then
		for key, value in pairs(index) do
			Settings[key] = value
		end
		
	-- Old behavior, Save('key', value)
	else
		Spring.Echo("Use Save{key=value,key2=value2,etc..} instead of Save('key', value)")
		local old = Settings[index]
		Settings[index] = data
		return old
	end
end

---------------------------- 
-- Loads a variable from the settings array
local function Load(index)
	if Settings[index] ~= nil then
		return Settings[index]
	else
		Spring.Echo('[Main Menu]Could not find '..index)
	end
end

---------------------------- 
--
local function addOption(obj)
	local stack = tabs[obj.tab]:GetObjectByName(obj.stack or 'Stack')
	
	if obj.title then
		-- Stays if widget fails, needs to be created in widget to work
		stack:AddChild(Chili.Label:New{caption=obj.title,x='0%',fontsize=18})
	end
	
	for i = 1, #obj.children do
		stack:AddChild(obj.children[i])
	end	
	
	if obj.bLine then
		-- Stays if widget fails, needs to be created in widget to work
		stack:AddChild(Chili.Line:New{width='100%'})
	end

end

---------------------------- 
--
local function addToStack()
	Spring.Echo('AddToStack() is depreciated, instead use AddOption{}')
end

---------------------------- 
-- Creates a stack panel which can then be used as a parent to options
local function addStack(obj)
	local stack
	if obj.scroll then
		stack = Chili.ScrollPanel:New{
			x        = obj.x or 0,
			y        = obj.y or 0,
			width    = obj.width or '50%',
			bottom   = obj.bottom or 0,
			children = {
				Chili.StackPanel:New{
					name        = obj.name or 'Stack',
					x           = 0,
					y           = 0,
					width       = '100%',
					resizeItems = false,
					autosize    = true,
					padding     = {0,0,0,0},
					itemPadding = {0,0,0,0},
					itemMargin  = {0,0,0,0},
					children    = obj.children or {},
					preserverChildrenOrder = true
				}
			}
		}
	else
		stack = Chili.StackPanel:New{
			name        = obj.name or 'Stack',
			x           = obj.x or 0,
			y           = obj.y or 0,
			width       = obj.width or '50%',
			resizeItems = false,
			autosize    = true,
			padding     = {0,0,0,0},
			itemPadding = {0,0,0,0},
			itemMargin  = {0,0,0,0},
			children    = obj.children or {},
			preserverChildrenOrder = true
		}
	end
	return stack
end


---------------------------- 
-- Creates the original window in which all else is contained
local function loadMainMenu()
	local sizeData = Load('mainMenuSize') or {x=400,y=200,width=585,height=400}
	
	-- Detects and fixes menu being off-screen
	local vsx,vsy = Spring.GetViewGeometry()
	if vsx < sizeData.x+sizeData.width-100 or sizeData.x < 100 then sizeData.x = 400 end
	if vsy < sizeData.y+sizeData.height-100 or sizeData.y < 100 then sizeData.height = 500 end
	
	mainMenu = Chili.Window:New{
		parent    = Chili.Screen0,
		x         = sizeData.x, 
		y         = sizeData.y,
		width     = sizeData.width,
		height    = sizeData.height,
		padding   = {5,8,5,5}, 
		draggable = true,
		resizable = true,
		OnResize  = {
			function(self) 
				Save{mainMenuSize = {x=self.x,y=self.y,width=self.width,height=self.height}} 
			end
		},
		children  = {
			Chili.Line:New{parent = mainMenu,y = 15,width = '100%'},
			Chili.Line:New{parent = mainMenu,bottom = 15,width = '100%'},
		}
	}
		
	menuTabs = Chili.TabBar:New{
		parent       = mainMenu,
		x            = 0, 
		y            = 0, 
		width        = '100%', 
		height       = 20, 
		minItemWidth = 70,
		selected     = Settings.tabSelected or 'Info',
		tabs         = {'Info','Interface', 'Graphics','Credits'},
		itemPadding  = {1,0,1,0},
		OnChange     = {sTab}
	}
	
    if amNewbie then
   		menuTabs:Select('Info')  
    else
        showHide()
    end
end

---------------------------- 
-- TODO: Create different general defaults such as high, low, etc.. 
--   and possibly custom (maybe even make custom settings savable/loadable)

local waterConvert_ID = {['Basic']=1,['Reflective']=2,['Dynamic']=3,['Refractive']=4,['Bump-Mapped']=5} -- name -> listID
local shadowConvert_ID = {['Off']=1,['Very Low']=2,['Low']=3,['Medium']=4,['High']=5,['Very High']=6}

local function applyDefaultSettings()
	for setting,value in pairs(DefaultSettings) do
		Settings[setting] = value
		engineStack = tabs['Graphics']:GetObjectByName('EngineSettings')
		
		if type(value)=='boolean' then
			local checkbox = engineStack:GetObjectByName(setting)
			if checkbox.checked ~= value then checkbox:Toggle() end
			spSendCommands(setting..' '..(value and 1 or 0))
		elseif setting=='Water' then 
			-- comboBox 
			engineStack:GetObjectByName(setting):Select(waterConvert_ID[value])
		elseif setting=='Shadows' then
			-- comboBox
			engineStack:GetObjectByName(setting):Select(shadowConvert_ID[value])          
		else 
			--slider
			engineStack:GetObjectByName(setting):SetValue(value)         
		end
	end
end
	
---------------------------- 
-- Creates a combobox style control
local comboBox = function(obj)
	local obj = obj
	local options = obj.options or obj.labels
	
	local comboBox = Chili.Control:New{
		y       = obj.y,
		width   = obj.width or '100%',
		height  = 40,
		x       = 0,
		padding = {0,0,0,0}
	}
	
	local selected
	for i = 1, #obj.labels do
		if obj.labels[i] == Settings[obj.name] then selected = i end
	end
	
	
	local function applySetting(obj, listID)
		local value   = obj.options[listID] or '' 
		local setting = obj.name or ''
		
		if setting == 'Skin' then
			Chili.theme.skin.general.skinName = value
			Spring.Echo('To see skin changes; \'/luaui reload\'')
		elseif setting == 'Cursor' then 
			setCursor(value)
			Settings['CursorName'] = value
		elseif setting == 'ShowHealthBars' then
			spSendCommands('luaui showhealthbars '..value)
		else 
			spSendCommands(setting..' '..value)
		end
		
		-- Spring.Echo(setting.." set to "..value) --TODO: this is misleading, some settings require a restart to be applied
		Settings[setting] =  obj.items[obj.selected]
	end
	
	comboBox:AddChild(
		Chili.Label:New{
			x=0,
			y=0,
			caption=obj.title or obj.name,
		})
	
	comboBox:AddChild(
		Chili.ComboBox:New{
			name     = obj.name,
			height   = 25,
			x        = '10%',
			width    = '80%',
			y        = 15,
			selected = selected,
			text     = label,
			options  = options,
			items    = obj.labels,
			OnSelect = {applySetting},
		})
	
	return comboBox
end

---------------------------- 
-- 
local checkBox = function(obj)
	local obj = obj
	
	local toggle = obj.OnChange or function(self)
		Settings[obj.name] = obj.checked
		spSendCommands(obj.name)
	end
	
	local checkBox = Chili.Checkbox:New{
		name      = obj.name,
		caption   = obj.title or obj.name,
		checked   = Settings[obj.name] or false,
		tooltip   = obj.tooltip or '',
		y         = obj.y,
		width     = obj.width or '80%',
		height    = 20,
		x         = '10%',
		textalign = 'left',
		boxalign  = 'right',
		OnChange  = {toggle}
	}
	return checkBox
end

---------------------------- 
-- 
local slider = function(obj)
	local obj = obj
	
	local trackbar = Chili.Control:New{
		y       = obj.y or 0,
		width   = obj.width or '100%',
		height  = 40,
		x       = 0,
		padding = {0,0,0,0}
	}
	
	
	local function applySetting(obj, value)
		Settings[obj.name] = value
		spSendCommands(obj.name..' '..value)
	end
	
	trackbar:AddChild(
		Chili.Label:New{
			x       = 0,
			y       = 0,
			caption = obj.title or obj.name,
		})
	
	trackbar:AddChild(
		Chili.Trackbar:New{
			name     = obj.name,
			height   = 25,
			x        = '10%',
			width    = '80%',
			y        = 15,
			min      = obj.min or 0,
			max      = obj.max or 1000,
			step     = obj.step or 100,
			value    = Settings[obj.name] or 500,
			OnChange = {applySetting},
		})
	
	return trackbar
end

-----INFO PANEL HELPERS------
-----------------------------
local function InfoTextBox(y, text1, text2, size) --hack because something to do with padding is broken here, likely Chili bug
    if not size then size = 20 end
    return Chili.LayoutPanel:New{width = 300, y = y*25, x = '10%', height = size+5, autosize = false, autoresizeitems = false, padding = {0,0,0,0}, itemPadding = {0,0,0,0}, itemMargin  = {0,0,0,0}, children = {
            Chili.TextBox:New{right='95%',text=" "..text1,font={size=size,color={0.8,0.8,1,1}},padding = {0,0,0,0}},
            Chili.TextBox:New{right='20%',text=text2,font={size=size,color={0.7,0.7,1,1}},padding = {0,0,0,0}},   
        }        
    }
end

local function InfoLineBox(y, text1, size)
    if not size then size = 20 end
    return Chili.LayoutPanel:New{width = 300, y = y*25, x = '10%', height = size+5, autosize = false, autoresizeitems = false, padding = {0,0,0,0}, itemPadding = {0,0,0,0}, itemMargin  = {0,0,0,0}, children = {
            Chili.TextBox:New{right='95%',text=" "..text1,font={size=size,color={0.8,0.8,1,1}},padding = {0,0,0,0}},
        }        
    }
end

local armageddonTime = 60 * (tonumber((Spring.GetModOptions() or {}).mo_armageddontime) or 0)

local gameEndMode    
if Spring.GetModOptions().deathmode=="com" then
    gameEndMode = "Kill all enemy Commanders"
elseif Spring.GetModOptions().deathmode=="killall" then
    gameEndMode = "Kill all enemy units"
elseif Spring.GetModOptions().deathmode=="neverend" then
    gameEndMode = "Never end"
end

local changeLog, gameInfo, introText

local function ParseChangelog(changelog)
    -- parse the changelog and add a small amount of colour
    -- TODO once we have a changelog!

    return changelog
end
    
-----OPTIONS-----------------
-----------------------------
local function Options()
	-- Each tab has its own control, which is shown when selected {Info,Interface,Graphics,etc..}
	-- mainMenu = Chili.Window:New{parent=Chili.Screen0,x = 400, y = 200, width = 500, height = 400,padding = {5,8,5,5}, draggable = true,
	--  Each graphical element is defined as a child of these controls and given a function to fullfill, when a certain event happens(i.e. OnClick)
	
	-- Graphics --
	tabs.Graphics = Chili.ScrollPanel:New{x = 0, y = 20, bottom = 20, width = '100%', borderColor = {0,0,0,0},backgroundColor = {0,0,0,0},
		children = {
			addStack{x='50%'},
			addStack{x = 0, name = 'EngineSettings',
				children = {
					comboBox{y=0,name='Water',
						labels={'Basic','Reflective','Dynamic','Refractive','Bump-Mapped'},
						options={0,1,2,3,4},},
					comboBox{y=40,name='Shadows',
						labels={'Off','Very Low','Low','Medium','High','Very High'},
						options={'0','2 1024','1 1024','2 2048','1 2048','1 4096'},},
					slider{name='DistDraw',title='Unit Draw Distance', max = 600, step = 1},
					slider{name='DistIcon',title='Unit Icon Distance', max = 600, step = 1},
					slider{name='MaxParticles',title='Max Particles', max = 5000},
					slider{name='MaxNanoParticles',title='Max Nano Particles', max = 5000},
					checkBox{title = 'Advanced Map Shading', name = 'AdvMapShading', tooltip = "Toggle advanced map shading mode"},
					checkBox{title = 'Advanced Model Shading', name = 'AdvModelShading', tooltip = "Toggle advanced model shading mode"},
					checkBox{title = 'Deferred Map Shading', name = 'AllowDeferredMapRendering', tooltip = "Toggle deferred model shading mode (requires advanced map shading)"},
					checkBox{title = 'Deferred Model Shading', name = 'AllowDeferredModelRendering', tooltip = "Toggle deferred model shading mode (requires advanced model shading)"},
					checkBox{title = 'Draw Engine Trees', name = 'DrawTrees', tooltip = "Enable/Disable rendering of engine trees"},
					checkBox{title = 'Dynamic Sky', name = 'DynamicSky', tooltip = "Enable/Disable dynamic-sky rendering"},
					checkBox{title = 'Dynamic Sun', name = 'DynamicSun', tooltip = "Enable/Disable dynamic-sun rendering"},
					checkBox{title = 'Show Health Bars', name = 'ShowHealthBars', tooltip = "Enable/Disable rendering of health-bars for units"},
					checkBox{title = 'Show Map Marks', name = 'MapMarks', tooltip = "Enables/Disables rendering of map drawings/marks"},
					checkBox{title = 'Show Map Border', name = 'MapBorder', tooltip = "Set or toggle map border rendering"},
					checkBox{title = 'Hardware Cursor', name = 'HardwareCursor', tooltip = "Enables/Disables hardware mouse-cursor support"},
					checkBox{title = 'Vertical Sync', name = 'VSync', tooltip = "Enables/Disables V-sync"},
					checkBox{title = 'OpenGL safe-mode', name = 'SafeGL', tooltip = "Enables/Disables OpenGL safe-mode"}, --does this actually do anything?!
					Chili.Button:New{name="ResetDefaults",height=20,width='100%',caption='Reset Defaults',OnMouseUp={applyDefaultSettings}},
				}
			}
		}
	}

	-- Interface --
	tabs.Interface = Chili.Control:New{x = 0, y = 20, bottom = 20, width = '100%', --Control attached to tab
		children = {
			addStack{name='widgetList',x='50%',scroll=true},
			Chili.EditBox:New{name='widgetFilter',x=0,y=0,width = '35%',text=' Enter filter -> Hit Return,  or -->',OnMouseDown = {function(obj) obj.text = '' end}},
			Chili.Button:New{right='50%',y=0,height=20,width='15%',caption='Search',OnMouseUp={addFilter}},
			Chili.Checkbox:New{caption='Search Widget Name',x=0,y=40,width='35%',textalign='left',boxalign='right',checked=Settings.searchWidgetName,
				OnChange = {function() Settings.searchWidgetName = not Settings.searchWidgetName end}},
			Chili.Checkbox:New{caption='Search Description',x=0,y=20,width='35%',textalign='left',boxalign='right',checked=Settings.searchWidgetDesc,
				OnChange = {function() Settings.searchWidgetDesc = not Settings.searchWidgetDesc end}},
			Chili.Checkbox:New{caption='Search Author',x=0,y=60,width='35%',textalign='left',boxalign='right',checked=Settings.searchWidgetAuth,
				OnChange = {function() Settings.searchWidgetAuth = not Settings.searchWidgetAuth end}},

			Chili.Line:New{width='50%',y=80},
			
			comboBox{name='Skin',y=90, width='45%',
				labels=Chili.SkinHandler.GetAvailableSkins()},
			comboBox{name='Cursor',y=125, width='45%',
				labels={'Chili Default','Chili Static','Spring Default','CA Classic','CA Static','Erom','Masse','Lathan','K_haos_girl'},
				options={'zk','zk_static','ba','ca','ca_static','erom','masse','Lathan','k_haos_girl'}},
			
			Chili.Label:New{caption='-- Widget Settings --',x='2%',width='46%',align = 'center',y=175},
			addStack{y=190,x='2%',width='46%',scroll=true},
		}
	}

	-- Credits --
	tabs.Credits = Chili.Control:New{x = 0, y = 20, bottom = 20, width = '100%',
		children = {
			Chili.Label:New{caption='-- Credits --',x='0%',width='70%',align = 'center'},
			Chili.ScrollPanel:New{width = '70%', x=0, y=20, bottom=0, children =
                {Chili.TextBox:New{width='100%',text=credits}}}
            -- TODO: insert logo on right hand side of this panel!
		}
	}

    local function ResignMe()
        spSendCommands{'Spectator'}
        showHide('Graph') 
        if not tabs.Info:GetChildByName('ResignButton').hidden then
            tabs.Info:GetChildByName('ResignButton'):Hide() 
        end
    end
    
    local hotkeyInfoBox = Chili.TextBox:New{width='100%',text=HotkeyInfo.General,padding={0,5,0,0}} 

    local function SetHotkeyTab(_, tabName)
        if tabName=='General' then hotkeyInfoBox:SetText(HotkeyInfo.General) 
        elseif tabName=="Units I" then hotkeyInfoBox:SetText(HotkeyInfo.Units_I)
        elseif tabName=="Units II" then hotkeyInfoBox:SetText(HotkeyInfo.Units_II)
        elseif tabName=="Units III" then hotkeyInfoBox:SetText(HotkeyInfo.Units_III)
        end
    end

    hotkeyInfo = Chili.Control:New{x = 0, y = 20, bottom = 0, width = '100%', children = {
            Chili.TabBar:New{x = 0, y = 0,	width = '100%', height = 20, minItemWidth = 70, selected = 'General', itemPadding = {1,0,1,0}, OnChange = {SetHotkeyTab},
                tabs = {'General', 'Units I', 'Units II', 'Units III'},
            },
            Chili.ScrollPanel:New{y = 20, width = '100%', bottom = 0, children = {
                    hotkeyInfoBox 
                }
            }
        }
    }



    changeLog = Chili.ScrollPanel:New{width = '100%', height='100%', children = {
            Chili.TextBox:New{width='100%',text=ParseChangelog(changelog),padding={0,5,0,0}} 
        }
    }
    
    introText = Chili.ScrollPanel:New{width = '100%', height='100%', children = {
            Chili.TextBox:New{width='100%',text=NewbieInfo,padding={0,5,0,0}} 
        }
    }
    
    gameInfo = Chili.Panel:New{width = '100%', height = '100%', autosize = true, autoresizeitems = false, padding = {0,0,0,0}, itemPadding = {0,0,0,0}, itemMargin  = {0,0,0,0}, children = {
                    InfoTextBox(1, "Map:",      Game.mapName),    
                    InfoTextBox(2, "",          "(" .. Game.mapX .. " x " .. Game.mapY .. ")", 15),    
                    InfoTextBox(3, "Wind:",     Game.windMin .. " - " .. Game.windMax),    
                    InfoTextBox(4, "Tidal:",    Game.tidal),    
                    InfoTextBox(5, "Acidity:",  Game.waterDamage),    
                    InfoTextBox(6, "Gravity:",  math.floor(Game.gravity)),    
                    Chili.Line:New{width='100%',y=7*25+5},
                    InfoTextBox(8, "Game End:", gameEndMode, 15),
                    InfoLineBox(9.5, (armageddonTime>0) and "Armageddon at " .. "1" .. " minutes" or ""),
        }
    }
    
    local function SetInfoChild(_, listID)
        local child
        if listID==1 then child=gameInfo elseif listID==2 then child = hotkeyInfo elseif listID==3 then child=changeLog elseif listID==4 then child=introText end
        if not child or not tabs.Info then return end --avoids a nil error when this function is called on setup of the comboBox
        tabs.Info:GetChildByName('info_layoutpanel'):ClearChildren()
        tabs.Info:GetChildByName('info_layoutpanel'):AddChild(child)
    end
    
    resignButton = 	Chili.Button:New{caption = 'Resign and Spectate', name = "ResignButton", height = '8%', width = '28%', right = '1%', y = '40%', OnMouseUp = {ResignMe}}

	-- Info --
	tabs.Info = Chili.Control:New{x = 0, y = 20, bottom = 20, width = '100%',
		children = {
			Chili.LayoutPanel:New{name = 'info_layoutpanel', width = '70%', x=0, y=0, bottom=0},
            
			Chili.ComboBox:New{
                name     = 'text_select',
                height   = '8%',
                y        = '8%',
                width    = '28%',
                right    = '1%',
                text     = "",
                selected = amNewbie and 3 or 1,
                items  = {"game info", "hotkeys", "changelog", "intro"},
                OnSelect = {SetInfoChild},
            },
         
            resignButton,
            Chili.Button:New{caption = 'Exit To Desktop',height = '8%',width = '28%',right = '1%', y = '52%',
				OnMouseUp = {function() spSendCommands{'quit'} end }},
		}
	}

    if amNewbie then
        SetInfoChild(_,3)
    else
        SetInfoChild(_,1)
    end
    
end

-----------------------------
-- Creates a tab, mostly as an auxillary function for addControl()
local function createTab(tab)
	tabs[tab] = Chili.Control:New{x = 0, y = 20, bottom = 20, width = '100%'}
	menuTabs:AddChild(Chili.TabBarItem:New{caption = tab})
end

-----------------------------
-- Adds a chili control to a tab
--  usage is Menu.AddControl('nameOfTab', controlToBeAdded)
--  if tab doesn't exist, one is created
--  this is useful if you want a widget to get it's own tab (endgraph is a good example)
--  this function probably won't change
local function addControl(tab,control)
	if not tabs[tab] then createTab(tab) end
	tabs[tab]:AddChild(control)
	tabs[tab]:Invalidate()
end

-----------------------------
-- Makes certain functions global, extending their usage to other widgets
--  most manipulate and/or create chili objects in some way to extend options
--  look at relevant functions above for more info
local function globalize()
	local Menu = {}
	
	Menu.UpdateList = makeWidgetList
	Menu.Save       = Save
	Menu.Load       = Load
	Menu.AddControl = addControl
	Menu.ShowHide   = showHide
	
	-- This will be primary function for adding options to the menu
	--  the name may change but the general usage should stay the same
	Menu.AddOption  = addOption
	-- Example Usage
	-- Menu.AddOption{
	--   tab      = 'Interface',
	--   children = {
	--     Chili.Label:New{caption='Example',x='0%',fontsize=18},
	--     Chili.ComboBox:New{
	--        x        = '10%',
	--        width    = '80%',
	--        items    = {"Option 1", "Option 2", "Option 3"},
	--        selected = 1,
	--        OnSelect = {
	--          function(_,sel)
	--            Spring.Echo("Option "..sel.." Selected")
	--          end
	-- 			  }
	-- 		},
	-- 		Chili.Line:New{width='100%'},
	-- 	}
	-- }
	
	
	
	-- This will likely be replaced ( but will remain for now as is)
	Menu.AddToStack = addToStack
	
	-- These will more than likely be removed
	Menu.AddChoice  = addChoice
	Menu.Checkbox   = checkbox
	Menu.Slider     = slider
	------------------------
	
	WG.MainMenu = Menu
end
-----------------------------

function widget:GetConfigData()
	return Settings
end

function widget:SetConfigData(data)
	if (data and type(data) == 'table') then
		Settings = data
	end
end

function widget:KeyPress(key,mod)
	local editbox = tabs['Interface']:GetObjectByName('widgetFilter')
	if key==13 and editbox.state.focused then
		addFilter()
		return true
	end
end

-------------------------- 
-- Initial function called by widget handler
function widget:Initialize()
	Chili = WG.Chili
	Chili.theme.skin.general.skinName = Settings['Skin'] or 'Robocracy'
	setCursor(Settings['CursorName'] or 'ba')
	Options()
	globalize()
	makeWidgetList()
	loadMainMenu()
	
	-----------------------
	---     Hotkeys     ---
	local openMenu    = function() showHide('Info') end
	local openWidgets = function() if mainMenu.visible then mainMenu:Hide() return end; showHide('Interface') end
	local hideMenu    = function() if mainMenu.visible then mainMenu:Hide() end end
    
	spSendCommands('unbindkeyset f11')
	spSendCommands('unbindkeyset Any+i gameinfo')
	spSendCommands('unbind S+esc quitmenu','unbind esc quitmessage')
	widgetHandler.actionHandler:AddAction(widget,'openMenu', openMenu, nil, 't')
	widgetHandler.actionHandler:AddAction(widget,'openWidgets', openWidgets, nil, 't')
	widgetHandler.actionHandler:AddAction(widget,'hideMenu', hideMenu, nil, 't')
	spSendCommands('bind i openMenu')
	spSendCommands('bind S+esc openMenu')
	spSendCommands('bind f11 openWidgets')
	spSendCommands('bind esc hideMenu')
end

-------------------------- 
--
function widget:Update()
	if widgetHandler.knownChanged then
		widgetHandler.knownChanged = false
		-- Seems to update to quickly ( before widget is 'inactive' )
		makeWidgetList()
	end
end
-- Called by widget handler when this widget either crashes or is disabled
function widget:Shutdown()
	spSendCommands('unbind S+esc openMenu')
	spSendCommands('unbind f11 openWidgets')
	spSendCommands('unbind esc hideMenu')
	spSendCommands('bind f11 luaui selector') -- if the default one is removed or crashes, then have the backup one take over.
	spSendCommands('bind Any+i gameinfo')
end


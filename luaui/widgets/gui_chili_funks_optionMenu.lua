-- WIP
--  TODO Reapply original spring settings on shutdown
function widget:GetInfo()
	return {
		name    = 'Funks Main Menu',
		desc    = 'Graphics, Interface, and Sound Options Menu (WIP)',
		author  = 'Funkencool',
		date    = '2013',
		license = 'GNU GPL v2',
		layer   = -100,
		handler = true,
		enabled = true
	}
end


local spSendCommands = Spring.SendCommands
local spSetConfigInt = Spring.SetConfigInt
local spGetConfigInt = Spring.GetConfigInt
local spgetFPS       = Spring.GetFPS
local spGetTimer     = Spring.GetTimer

local Chili, mainMenu, menuTabs, menuBtn
local Settings = {}
-- Defaults --- ignored unless fresh install
-- TODO Get defaults from Spring.GetConfig
Settings['Skin']             = 'Flat'
Settings['Cursor']           = 'Default'
Settings['CursorName']       = 'ba'
Settings['Water']            = 'Reflective'
Settings['Shadows']          = 'Medium'
Settings['DistIcon']         = 'Medium'
Settings['MaxNanoParticles'] = 'Medium'
Settings['MaxParticles']     = 'High'
Settings['DistDraw']         = 'Very High'
Settings['MapBorder']        = true
Settings['AdvMapShading']    = true
Settings['AdvModelShading']  = true
Settings['DrawTrees']        = true
Settings['ShowHealthBars']   = true
Settings['ShowRezBars']      = true
Settings['MapMarks']         = true
Settings['searchWidgetDesc'] = true
Settings['searchWidgetAuth'] = true
Settings['searchWidgetName'] = true
Settings['widget']           = {}
Settings['UIwidget']         = {}
------------------------------------
local widgetList = {}
local tabs = {}
local credits = VFS.LoadFile('credits.txt')
if credits == '' then credits = 'credits is blank, normally this would read the credits.txt in the games base directory' end


local wCategories = {
	{cat = 'gfx'      , label = 'Effects'       , list = {}, },
	{cat = 'gui'      , label = 'GUI'           , list = {}, },
	{cat = 'camera'   , label = 'Camera'        , list = {}, },
	{cat = 'map'      , label = 'Map'           , list = {}, },
	{cat = 'cmd'      , label = 'Commands'      , list = {}, },
	{cat = 'unit'     , label = 'Units'         , list = {}, },
	{cat = 'minimap'  , label = 'Minimap'       , list = {}, },
	{cat = 'mission'  , label = 'Mission'       , list = {}, },
	{cat = 'api'      , label = 'API'           , list = {}, },
	{cat = 'dbg'      , label = 'Debugging'     , list = {}, },
	{cat = 'hook'     , label = 'Commands'      , list = {}, },
	{cat = 'ico'      , label = 'GUI'           , list = {}, },
	{cat = 'init'     , label = 'Initialization', list = {}, },
	{cat = 'snd'      , label = 'Sound'         , list = {}, },
	{cat = 'test'     , label = 'Test Widgets'  , list = {}, },
	{cat = 'ungrouped', label = 'Ungrouped'     , list = {}, }
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
-- Toggles widgets enabled/disabled when clicked
--  does not account for failed initialization of widgets yet
local function toggleWidget(self)
	widgetHandler:ToggleWidget(self.name)
	if self.checked then
		self.font.color        = {1,0.5,0,1}
		self.font.outlineColor = {1,0.5,0,0.2}
		else
		self.font.color        = {0.5,1,0,1}
		self.font.outlineColor = {0.5,1,0,0.2}
	end
	self:Invalidate()
end

---------------------------- 
-- 
local function groupWidget(name,wData)
	local _, _, category = string.find(wData.basename, '([^_]*)')
	if not category then category = 'ungrouped' end
	
	for i=1,#wCategories do
		if category == wCategories[i].cat then
			wCategories[i].list[#wCategories[i].list+1] = {name = name,wData = wData} 
		end
	end

end

---------------------------- 
--
local function sortWidgetList(filter)
	local filter = string.lower(filter or '')
	for name,wData in pairs(widgetHandler.knownWidgets) do
		if (Settings.searchWidgetName and string.lower(name or ''):find(filter))
		or (Settings.searchWidgetDesc and string.lower(wData.desc or ''):find(filter))
		or (Settings.searchWidgetAuth and string.lower(wData.author or ''):find(filter)) then
			groupWidget(name,wData)
		end
		for i=1,#wCategories do
			local ascending = function(a,b) return a.name<b.name end
			table.sort(wCategories[i].list,ascending)
		end
	end
end

---------------------------- 
-- Creates widget list for interface tab
--  TODO create cache of chili objects on initialize
--  TODO detect widget failure, set color
local function makeWidgetList(filter)
	sortWidgetList(filter)
	local widgetNum = 0
	local scrollpanel = tabs['Interface']:GetObjectByName('widgetList')
	scrollpanel:ClearChildren()
	-- First loop adds group label
	for a=1,#wCategories do
		local list = wCategories[a].list
		if #list>0 then
			widgetNum = widgetNum + 1
			Chili.Label:New{
				parent   = scrollpanel,
				x        = 0,  
				y        = widgetNum * 20 - 10,
				caption  = '- '..wCategories[a].label..' -',
				align    = 'center',
				width    = '100%',
				autosize = false,
			}
			widgetNum = widgetNum + 1
			
			-- Second loop adds each widget
			for b=1,#list do
				local enabled = (widgetHandler.orderList[list[b].name] or 0)>0
				local fontColor
				if enabled then fontColor = {color = {0.5,1,0,1}, outlineColor = {0.5,1,0,0.2}}
				else fontColor = {color = {1,0.5,0,1}, outlineColor = {1,0.5,0,0.2}} end
				local author = list[b].wData.author or ""
				local desc = list[b].wData.desc or ""
				Chili.Checkbox:New{
					name      = list[b].name,
					caption   = list[b].name,
					parent    = scrollpanel,
					tooltip   = 'Author: '..author.. '\n'.. desc,
					x         = 0,
					right     = 0,
					y         = widgetNum*20,
					height    = 19,
					font      = fontColor,
					checked   = enabled,
					OnChange  = {toggleWidget},
				}
				widgetNum = widgetNum + 1
			end
		end
		wCategories[a].list = {}
	end
end

---------------------------- 
--
local function showHide(tab)
	local oTab = Settings.tabSelected
	
	if tab then 
		menuTabs:Select(tab)
	else
		mainMenu:ToggleVisibility()
		return
	end
	
	if mainMenu.visible and oTab == tab then
		mainMenu:Hide()
	elseif mainMenu.hidden then
		mainMenu:Show()
	end
end

---------------------------- 
--
local function sTab(_,tabName)
  if Settings.tabSelected then mainMenu:RemoveChild(tabs[Settings.tabSelected]) end
  mainMenu:AddChild(tabs[tabName])
  Settings.tabSelected = tabName
end

---------------------------- 
--
local function addFilter()
	local editbox = tabs['Interface']:GetObjectByName('widgetFilter')
	makeWidgetList(editbox.text)
	editbox:SetText('')
end

---------------------------- 
--
local function save(index, data)
	local old = Settings[index] or 'empty'
	Settings[index] = data or nil
	return old
end

---------------------------- 
--
local function load(index)
	local value = Settings[index] or nil
	return value
end

---------------------------- 
--
local function addToStack(tab, control)
	local stack = tabs[tab]:GetObjectByName('Stack')
	if not stack then
		Spring.Echo('No Stack in '..tab)
		return
	end
	stack:AddChild(control)
	-- stack:AddChild(Chili.Line:New{width='100%',x=0})
end

---------------------------- 
--
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
					name        = 'Stack',
					x           = 0,
					y           = 0,
					width       = '100%',
					resizeItems = false,
					autosize    = true,
					padding     = {0,0,0,0},
					itemPadding = {0,0,0,0},
					itemMargin  = {0,0,0,0},
					preserverChildrenOrder = true
				}
			}
		}
	else
		stack = Chili.StackPanel:New{
			name        = 'Stack',
			x           = obj.x or 0,
			y           = obj.y or 0,
			width       = obj.width or '50%',
			resizeItems = false,
			autosize    = true,
			padding     = {0,0,0,0},
			itemPadding = {0,0,0,0},
			itemMargin  = {0,0,0,0},
			preserverChildrenOrder = true
		}
	end
	return stack
end


---------------------------- 
--
local function loadMainMenu()
	local sizeData = load('mainMenuSize') or {}
	mainMenu = Chili.Window:New{
		parent    = Chili.Screen0,
		x         = sizeData[1] or 400, 
		y         = sizeData[2] or 200,
		width     = sizeData[3] or 500,
		height    = sizeData[4] or 400,
		padding   = {5,8,5,5}, 
		draggable = true,
		resizable = true,
		OnResize  = {function(self) save('mainMenuSize', {self.x,self.y,self.width,self.height} ) end},
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
			tabs         = {'Info','Interface', 'Graphics'},
			itemPadding  = {1,0,1,0},
			OnChange     = {sTab}
		}
		
		showHide()
end

---------------------------- 
-- 
local function applySetting(obj)
	local value   = obj.options[obj.selected] or ''
	local setting = obj.name or ''
	
	if setting == 'Skin' then
		Chili.theme.skin.general.skinName = value; Spring.Echo('To see skin changes; \'/luaui reload\'')
	elseif setting == 'Cursor' then 
		setCursor(value)
		Settings['CursorName'] = value
	else 
		spSendCommands(setting..' '..value)
	end

	Settings[setting] =  obj.items[obj.selected]
end

---------------------------- 
-- Creates a combobox style control
--  TODO Use chili default combobox(gajops)
local comboBox = function(obj)
	local obj = obj
	local options = obj.options or obj.labels
	
	local comboBox = Chili.Control:New{
		y       = obj.y,
		width   = '45%',
		height  = 40,
		x       = 0,
		padding = {0,0,0,0}
	}
	
	
	local selected
	for i = 1, #obj.labels do
		if obj.labels[i] == Settings[obj.name] then selected = i end
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
			x        = 60,
			y        = 15,
			right    = 0,
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
--
local checkBox = function(obj)
	local obj = obj
	
	local function toggle(self)
		Settings[obj.name] = self.checked
		spSendCommands(self.name)
	end
	
	local checkBox = Chili.Checkbox:New{
		name      = obj.name,
		caption   = obj.title or obj.name,
		checked   = Settings[obj.name] or false,
		tooltip   = obj.tooltip or '',
		y         = obj.y,
		width     = '45%',
		height    = 20,
		x         = 0,
		textalign ='left',
		boxalign  ='right',
		OnChange  = {toggle}
	}
	return checkBox
end

---------------------------- 
-- Temporary control to work exclusively for default bloom options
--  The same interface could be added to other widgets 
--  although it would probably be easier to come up with a better sytem and add that to the bloom widget.
local incDec = function(obj)
	local incDec = Chili.Control:New{name=obj.name,parent=tabs[obj.parent],y=obj.y,width='50%',height=30,right=0,padding={0,0,0,0}}
	local decOption = function(self)
		spSendCommands('luaui -'..self.parent.name)
	end
	local incOption = function(self)
		spSendCommands('luaui +'..self.parent.name)
	end
	incDec:AddChild(Chili.Label:New{right=45,y=0,caption=obj.label})
	incDec:AddChild(Chili.Button:New{right=0,y=0,width=20,height=16,font={size=20},caption='+',OnMouseUp={incOption}})
	incDec:AddChild(Chili.Button:New{right=21,y=0,width=20,height=16,font={size=20},caption='-',OnMouseUp={decOption}})
end

-----OPTIONS-----------------
-----------------------------
local function Options()
	-- Each tab has its own control, which is shown when selected {Info,Interface,Graphics, and Sound}
	-- mainMenu = Chili.Window:New{parent=Chili.Screen0,x = 400, y = 200, width = 500, height = 400,padding = {5,8,5,5}, draggable = true,
	--  Each graphical element is defined as a child of these controls and given a function to fullfill, when a certain event happens(i.e. OnClick)
	
	-- Graphics --
	tabs.Graphics = Chili.ScrollPanel:New{x = 0, y = 20, bottom = 20, width = '100%', borderColor = {0,0,0,0},backgroundColor = {0,0,0,0},
		children = {
			addStack{x='50%'},
			comboBox{y=0,name='Water',
				labels={'Basic','Reflective','Dynamic','Refractive','Bump-Mapped'},
				options={0,1,2,3,4},},
			comboBox{y=40,name='Shadows',
				labels={'Off','Very Low','Low','Medium','High','Very High'},
				options={'0','2 1024','1 1024','2 2048','1 2048','1 4096'},},
			comboBox{y=80,name='DistDraw',title='Unit Draw Distance',
				labels={'Low','Medium','High','Very High'},
				options={100,300,500,1000},},
			comboBox{y=120,name='DistIcon',title='Unit Icon Distance',
				labels={'Off','Low','Medium','High','Very High'},
				options={10000,100,200,300,400},},
			comboBox{y=160,name='MaxParticles',title='Particles',
				labels={'Very Low','Low','Medium','High','Very High'},
				options={500,1000,2000,3000,5000},},
			comboBox{y=200,name='MaxNanoParticles',title='Nano Particles',
				labels={'Very Low','Low','Medium','High','Very High'},
				options={500,1000,2000,3000,5000},},
			checkBox{y = 250, title = 'Vertical Sync', name = 'VSync', tooltip = "Enables/Disables vertical-sync (Graphics setting)"},
			checkBox{y = 270, title = 'Advanced Map Shading', name = 'AdvMapShading', tooltip = "Set or toggle advanced map shading mode"},
			checkBox{y = 290, title = 'Advanced Model Shading', name = 'AdvModelShading', tooltip = "Set or toggle advanced model shading mode"},
			checkBox{y = 310, title = 'OpenGL safe-mode', name = 'SafeGL', tooltip = "Enables/Disables OpenGL safe-mode"},
			checkBox{y = 330, title = 'Draw Engine Trees', name = 'DrawTrees', tooltip = "Enable/Disable rendering of engine trees"},
			checkBox{y = 350, title = 'Dynamic Sky', name = 'DynamicSky', tooltip = "Enable/Disable dynamic-sky rendering"},
			checkBox{y = 370, title = 'Dynamic Sun', name = 'DynamicSun', tooltip = "Enable/Disable dynamic-sun rendering"},
			checkBox{y = 390, title = 'Hardware Cursor', name = 'HardwareCursor', tooltip = "Enables/Disables hardware mouse-cursor support"},
			checkBox{y = 410, title = 'Show Health Bars', name = 'ShowHealthBars', tooltip = "Enable/Disable rendering of health-bars for units"},
			checkBox{y = 430, title = 'Show Rez Bars', name = 'ShowRezBars', tooltip = "Enable/Disable rendering of resource-bars for features"},
			checkBox{y = 470, title = 'Show Map marks', name = 'MapMarks', tooltip = "Enables/Disables map marks rendering"},
			checkBox{y = 490, title = 'Show Engine Map Border', name = 'MapBorder', tooltip = "Set or toggle map border rendering"},
		}
	}
	
	
	-- Interface --
	tabs.Interface = Chili.Control:New{x = 0, y = 20, bottom = 20, width = '100%', --Control attached to tab
		children = {
			Chili.ScrollPanel:New{name='widgetList',x = '50%',y = 0,right = 0,bottom = 0},
			Chili.EditBox:New{name='widgetFilter',x=0,y=0,width = '35%',text=' Enter filter -> Hit Return,  or -->',OnMouseDown = {function(obj) obj.text = '' end}},
			Chili.Button:New{right='50%',y=0,height=20,width='15%',caption='Search',OnMouseUp={addFilter}},
			Chili.Checkbox:New{caption='Search Widget Name',x=0,y=40,width='35%',textalign='left',boxalign='right',checked=Settings.searchWidgetName,
				OnChange = {function() Settings.searchWidgetName = not Settings.searchWidgetName end}},
			Chili.Checkbox:New{caption='Search Description',x=0,y=20,width='35%',textalign='left',boxalign='right',checked=Settings.searchWidgetDesc,
				OnChange = {function() Settings.searchWidgetDesc = not Settings.searchWidgetDesc end}},
			Chili.Checkbox:New{caption='Search Author',x=0,y=60,width='35%',textalign='left',boxalign='right',checked=Settings.searchWidgetAuth,
				OnChange = {function() Settings.searchWidgetAuth = not Settings.searchWidgetAuth end}},

			Chili.Line:New{width='50%',y=80},
			
			comboBox{name='Skin',y=90,
				labels=Chili.SkinHandler.GetAvailableSkins()},
			comboBox{name='Cursor',y=125,
				labels={'Default','ZK Animated','ZK Static','CA Classic','CA Static','Erom','Masse','Lathan','K_haos_girl'},
				options={'ba','zk','zk_static','ca','ca_static','erom','masse','Lathan','k_haos_girl'}},
			
			Chili.Label:New{caption='-- Widget Settings --',x='2%',width='46%',align = 'center',y=175},
			addStack{y=190,x='2%',width='46%',scroll=true},
		}
	}

	-- Info --
	tabs.Info = Chili.Control:New{x = 0, y = 20, bottom = 20, width = '100%',
		children = {
			Chili.Label:New{caption='-- Credits --',x='0%',width='70%',align = 'center'},
			Chili.ScrollPanel:New{width = '70%', x=0, y=20, bottom=0, children ={Chili.TextBox:New{width='100%',text=credits}}},
			Chili.Button:New{caption = 'Resign and Spectate',height = '8%',width = '28%',right = '1%', y = '40%',
				OnMouseUp = {function() spSendCommands{'Spectator'};showHide('Graph') end }},
			Chili.Button:New{caption = 'Exit To Desktop',height = '8%',width = '28%',right = '1%', y = '52%',
				OnMouseUp = {function() spSendCommands{'quit'} end }},
		}
	}

	
end

local function createTab(tab)
	tabs[tab] = Chili.Control:New{x = 0, y = 20, bottom = 20, width = '100%'}
	menuTabs:AddChild(Chili.TabBarItem:New{caption = tab})
end

local function addControl(tab,control)
	if not tabs[tab] then createTab(tab) end
	tabs[tab]:AddChild(control)
end

local function addChoice(tab,control,obj)
	if not tabs[tab] then createTab(tab) end
	if obj.name and tabs[tab].childrenByName[obj.name] then 
		return 
	end
	
	local child
	if control == 'combobox' then 
		child = comboBox(obj)
	elseif control == 'checkbox' then 
		child = checkBox(obj)
	end
	
	tabs[tab]:AddChild(child)
	return child
end
-----------------------------
-- Global
-----------------------------
local function globalize()
	local Menu = {}
	Menu.Save       = save
	Menu.Load       = load
	Menu.ShowHide   = showHide
	Menu.AddChoice  = addChoice
	Menu.AddControl = addControl
	Menu.AddToStack = addToStack
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
		makeWidgetList(editbox.text)
		editbox:SetText('')
		return true
	end
end

-------------------------- 
--
function widget:Initialize()
	Chili = WG.Chili
	Chili.theme.skin.general.skinName = Settings['Skin'] or 'Flat'
	setCursor(Settings['CursorName'] or 'ba')
	Options()
	globalize()
	makeWidgetList()
	loadMainMenu()
	
	-------------------------- 
	-----     Hotkeys       --
	local openMenu    = function() showHide('Info') end
	local openWidgets = function() showHide('Interface') end
	local hideMenu    = function() if mainMenu.visible then mainMenu:Hide() end end
	
	spSendCommands('unbindkeyset f11')
	spSendCommands('unbind S+esc quitmenu','unbind esc quitmessage')
	widgetHandler.actionHandler:AddAction(widget,'openMenu', openMenu, nil, 't')
	widgetHandler.actionHandler:AddAction(widget,'openWidgets', openWidgets, nil, 't')
	widgetHandler.actionHandler:AddAction(widget,'hideMenu', hideMenu, nil, 't')
	spSendCommands('bind S+esc openMenu')
	spSendCommands('bind f11 openWidgets')
	spSendCommands('bind esc hideMenu')
end
-------------------------- 
--
function widget:Shutdown()
	spSendCommands('unbind S+esc openMenu')
	spSendCommands('unbind f11 openWidgets')
	spSendCommands('unbind esc hideMenu')
	spSendCommands('bind f11 luaui selector') -- if the default one is removed or crashes, then have the backup one take over.
end


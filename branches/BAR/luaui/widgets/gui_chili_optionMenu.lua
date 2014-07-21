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
local spgetFPS       = Spring.GetFPS
local spGetTimer     = Spring.GetTimer

local Chili, mainMenu, menuTabs, menuBtn
local Settings = {}
local DefaultSettings = {}

-- Defaults ---  
-- DefaultSettings can only contain things from springsettings
-- not all setttings appear here, only ones for which we actually want to overwrite the defaults when "reset to defaults" is clicked
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

-- load relevant things from springsettings 
Settings['DistIcon'] = Spring.GetConfigInt('DistIcon')
Settings['DistDraw'] = Spring.GetConfigInt('DistDraw')
Settings['MaxNanoParticles'] = Spring.GetConfigInt('MaxNanoParticles')
Settings['MaxParticles'] = Spring.GetConfigInt('MaxParticles')
Settings['MapBorder'] = Spring.GetConfigInt('MapBorder')
Settings['AdvMapShading'] = Spring.GetConfigInt('AdvMapShading')
Settings['AdvModelShading'] = Spring.GetConfigInt('AdvModelShading')
Settings['AllowDeferredMapRendering'] = Spring.GetConfigInt('AllowDeferredMapRendering')
Settings['AllowDeferredModelRendering'] = Spring.GetConfigInt('AllowDeferredModelRendering')
Settings['DrawTrees'] = Spring.GetConfigInt('DrawTrees')
Settings['MapMarks'] = Spring.GetConfigInt('MapMarks')   
Settings['DynamicSky'] = Spring.GetConfigInt('DynamicSky')
Settings['DynamicSky'] = Spring.GetConfigInt('DynamicSun')
Settings['Water'] = Spring.GetConfigInt('Water')
Settings['Shadows'] = Spring.GetConfigInt('Shadows')
-- I don't know how to check if luaui healthbars is set to 1 or not!

Settings['searchWidgetDesc'] = true
Settings['searchWidgetAuth'] = true
Settings['searchWidgetName'] = true
Settings['widget']           = {}
Settings['UIwidget']         = {}
Settings['Skin']             = 'Robocracy'
Settings['Cursor']           = 'Default'
Settings['CursorName']       = 'ba'

------------------------------------
local wFilterString = ""
local widgetList = {}
local tabs = {}
local credits = VFS.LoadFile('credits.txt')
if credits == '' then credits = 'credits is blank, normally this would read the credits.txt in the games base directory' end


local wCategories = {
	['unit']      = {label = 'Units',       list = {}, pos = 1,},
	['cmd']       = {label = 'Commands',    list = {}, pos = 2,},
	['gui']       = {label = 'GUI',         list = {}, pos = 3,},
	['gfx']       = {label = 'GFX',         list = {}, pos = 4,},
	['snd']       = {label = 'Sound',       list = {}, pos = 5,},
	['camera']    = {label = 'Camera',      list = {}, pos = 6,},
	['map']       = {label = 'Map',         list = {}, pos = 7,},
	['minimap']   = {label = 'Minimap',     list = {}, pos = 8,},
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
-- Toggles widgets enabled/disabled when clicked
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
-- Adds widget to pertaining groups list of widgets
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
local function sortWidgetList(wFilterString)
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
	local yStep = 0
	local scrollpanel = tabs['Interface']:GetObjectByName('widgetList')
	scrollpanel:ClearChildren()
	
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
			yStep = yStep + 1
			Chili.Label:New{
				parent   = scrollpanel,
				x        = 0,  
				y        = yStep * 20 - 10,
				caption  = '- '..cat.label..' -',
				align    = 'center',
				width    = '100%',
				autosize = false,
			}
			yStep = yStep + 1
			
			-- Second loop adds each widget
			for b=1,#list do
				local enabled = (widgetHandler.orderList[list[b].name] or 0)>0
				local active  = list[b].wData.active
				local fontColor
				
				-- Enabled and Active (only enabled widgets can be active)
				if active then fontColor = {color = {0.5,1,0,1}, outlineColor = {0.5,1,0,0.2}}
				-- Enabled but not Active
				elseif enabled then fontColor = {color = {1,0.5,0,1}, outlineColor = {1,0.5,0,0.2}}
				-- Disabled
				else fontColor = {color = {1,0,0,1}, outlineColor = {1,0,0,0.2}} end
				
				local author = list[b].wData.author or "Unkown"
				local desc = list[b].wData.desc or "No Description"
                local fromZip = list[b].wData.fromZip and "" or "*"
				Chili.Checkbox:New{
					name      = list[b].name,
					caption   = list[b].name .. fromZip,
					parent    = scrollpanel,
					tooltip   = 'Author: '..author.. '\n'.. desc,
					x         = 0,
					right     = 0,
					y         = yStep*20,
					height    = 19,
					font      = fontColor,
					checked   = enabled,
					OnChange  = {toggleWidget},
				}
				yStep = yStep + 1
			end
		end
		cat.list = {}
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
	wFilterString = editbox.text or ""
	makeWidgetList()
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
    local vsx,vsy = Spring.GetViewGeometry()
    if vsx < sizeData[1]+sizeData[3]-100 or sizeData[1] < 100 then sizeData[1] = 400 end
    if vsy < sizeData[2]+sizeData[4]-100 or sizeData[2] < 100 then sizeData[3] = 500 end
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

--local waterConvert = {['Basic']=0,['Reflective']=1,['Dynamic']=2,['Refractive']=3,['Bump-Mapped']=4} -- name -> setting value
local waterConvert_ID = {['Basic']=1,['Reflective']=2,['Dynamic']=3,['Refractive']=4,['Bump-Mapped']=5} -- name -> listID
--local shadowConvert = {['Off']='0',['Very Low']='2 2014',['Low']='1 2014',['Medium']='2 2048',['High']='1 2048',['Very High']='1 4096'}
local shadowConvert_ID = {['Off']=1,['Very Low']=2,['Low']=3,['Medium']=4,['High']=5,['Very High']=6}
local function boolConvert (arg)
    if (arg==true) then return 1 else return 0 end
end

local function applyDefaultSettings()
    for setting,value in pairs(DefaultSettings) do
        Settings[setting] = value
        
        -- hacky code, sorry!
        if type(value)=='boolean' then 
            --checkbox
            for i=1,#tabs.Graphics.children do
                if (tabs.Graphics.children[i].name==setting) then
                    if value~=tabs.Graphics.children[i].checked then
                        tabs.Graphics.children[i]:Toggle()
                    end
                end
            end
            spSendCommands(setting..' '..boolConvert(value)) -- i couldn't figure out how to use the custom OnChange for checkboxes
        elseif setting=='Water' then 
            --combobox
            for i=1,#tabs.Graphics.children do
                if (tabs.Graphics.children[i].name==setting) then
                    tabs.Graphics.children[i].children[2]:Select(waterConvert_ID[value]) -- children[2] seems to always work, but is needed because the comboBox is not a child but a grandchild of tabs.Graphics

                end
            end
        elseif setting=='Shadows' then 
            --combobox
            for i=1,#tabs.Graphics.children do
                if (tabs.Graphics.children[i].name==setting) then
                    tabs.Graphics.children[i].children[2]:Select(shadowConvert_ID[value])
                end
            end                
        else 
            --slider
            for i=1,#tabs.Graphics.children do
                if (tabs.Graphics.children[i].name==setting) then
                    tabs.Graphics.children[i].children[2]:SetValue(value) 
                end
            end                
        end
    end
end
    
---------------------------- 
-- Creates a combobox style control
local comboBox = function(obj)
	local obj = obj
	local options = obj.options or obj.labels
	
	local comboBox = Chili.Control:New{
        name    = obj.name,
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

        Spring.Echo(setting.." set to "..value) --TODO: this is misleading, some settings require a restart to be applied
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
-- 
local slider = function(obj)
	local obj = obj
	
	local trackbar = Chili.Control:New{
        name    = obj.name,
		y       = obj.y or 0,
		width   = '45%',
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
			x        = 60,
			y        = 15,
			right    = 0,
			min      = obj.min or 0,
			max      = obj.max or 1000,
			step     = obj.step or 100,
			value    = Settings[obj.name] or 500,
			OnChange = {applySetting},
		})
	
	return trackbar
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
			comboBox{y=0,name='Water',
				labels={'Basic','Reflective','Dynamic','Refractive','Bump-Mapped'},
				options={0,1,2,3,4},},
			comboBox{y=40,name='Shadows',
				labels={'Off','Very Low','Low','Medium','High','Very High'},
				options={'0','2 1024','1 1024','2 2048','1 2048','1 4096'},},
			slider{y=80,name='DistDraw',title='Unit Draw Distance', max = 600, step = 25},
			slider{y=120,name='DistIcon',title='Unit Icon Distance', max = 600, step = 25},
			slider{y=160,name='MaxParticles',title='Max Particles', max = 5000},
			slider{y=200,name='MaxNanoParticles',title='Max Nano Particles', max = 5000},
			checkBox{y = 250, title = 'Advanced Map Shading', name = 'AdvMapShading', tooltip = "Toggle advanced map shading mode"},
			checkBox{y = 270, title = 'Advanced Model Shading', name = 'AdvModelShading', tooltip = "Toggle advanced model shading mode"},
			checkBox{y = 290, title = 'Deferred Map Shading', name = 'AllowDeferredMapRendering', tooltip = "Toggle deferred model shading mode (requires advanced map shading)"},
			checkBox{y = 310, title = 'Deferred Model Shading', name = 'AllowDeferredModelRendering', tooltip = "Toggle deferred model shading mode (requires advanced model shading)"},
			checkBox{y = 350, title = 'Draw Engine Trees', name = 'DrawTrees', tooltip = "Enable/Disable rendering of engine trees"},
			checkBox{y = 370, title = 'Dynamic Sky', name = 'DynamicSky', tooltip = "Enable/Disable dynamic-sky rendering"},
			checkBox{y = 390, title = 'Dynamic Sun', name = 'DynamicSun', tooltip = "Enable/Disable dynamic-sun rendering"},
			checkBox{y = 410, title = 'Show Health Bars', name = 'ShowHealthBars', tooltip = "Enable/Disable rendering of health-bars for units"},
			checkBox{y = 430, title = 'Show Map Marks', name = 'MapMarks', tooltip = "Enables/Disables rendering of map drawings/marks"},
			checkBox{y = 450, title = 'Show Map Border', name = 'MapBorder', tooltip = "Set or toggle map border rendering"},
			checkBox{y = 490, title = 'Hardware Cursor', name = 'HardwareCursor', tooltip = "Enables/Disables hardware mouse-cursor support"},
			checkBox{y = 510, title = 'Vertical Sync', name = 'VSync', tooltip = "Enables/Disables V-sync"},
			checkBox{y = 530, title = 'OpenGL safe-mode', name = 'SafeGL', tooltip = "Enables/Disables OpenGL safe-mode"}, --does this actually do anything?!
            Chili.Button:New{y=560,name="ResetDefaults",height=20,width='70%',caption='Reset Defaults',OnMouseUp={applyDefaultSettings}},
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
	elseif control == 'slider' then
		child = slider(obj)
	end
	
	addToStack(tab, child)
	return child
end

-----------------------------
-- Makes certain functions global, extending their usage to other widgets
--  most manipulate and/or create chili objects in some way to extend options
--  look at relevant functions above for more info
local function globalize()
	local Menu = {}
	
	Menu.Save       = save
	Menu.Load       = load
	Menu.ShowHide   = showHide
	Menu.AddChoice  = addChoice
	Menu.AddControl = addControl
	Menu.AddToStack = addToStack
	Menu.Checkbox   = checkbox
	Menu.Slider     = slider
	
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
	Chili.theme.skin.general.skinName = Settings['Skin'] or 'Robocracy'
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
function widget:Update()
	if widgetHandler.knownChanged then
		widgetHandler.knownChanged = false
		makeWidgetList()
	end
end
-------------------------- 
--
function widget:Shutdown()
	spSendCommands('unbind S+esc openMenu')
	spSendCommands('unbind f11 openWidgets')
	spSendCommands('unbind esc hideMenu')
	spSendCommands('bind f11 luaui selector') -- if the default one is removed or crashes, then have the backup one take over.
end



-- Look at the globalize function for an explanation on the 'API' to add options to menu from other widgets

function widget:GetInfo()
    return {
        name    = 'Main Menu',
        desc    = 'The main menu; for information, settings, widgets, etc',
        author  = 'Funkencool, Bluestone',
        date    = '2013',
        license = 'GNU GPL v2',
        layer   = -100, -- load after chili API stuff
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

local fullyLoaded = false -- set to true at the end of widget:Initialize 

local white = '\255\255\255\255'

function LoadSpringSettings()
    -- Load relevant things from springsettings (overwrite our 'local' copy of these settings)
    -- Listed out because lua and Spring treat bool<->int conversion differently
    
    Settings['Water']                       = Spring.GetConfigInt('ReflectiveWater') 
    --Settings['ShadowMapSize']               = Spring.GetConfigInt('ShadowMapSize')
    Settings['Shadows']                     = Spring.GetConfigInt('Shadows')

    Settings['AdvMapShading']               = Spring.GetConfigInt('AdvMapShading', 1) == 1
    Settings['AdvModelShading']             = Spring.GetConfigInt('AdvModelShading', 1) == 1
    Settings['AllowDeferredMapRendering']   = Spring.GetConfigInt('AllowDeferredMapRendering') == 1
    Settings['AllowDeferredModelRendering'] = Spring.GetConfigInt('AllowDeferredModelRendering') == 1

    Settings['UnitIconDist']                = Spring.GetConfigInt('UnitIconDist', 280) -- number is used if no config is set  
    Settings['UnitLodDist']                 = Spring.GetConfigInt('UnitLodDist', 280)
    Settings['MaxNanoParticles']            = Spring.GetConfigInt('MaxNanoParticles', 1000)
    Settings['MaxParticles']                = Spring.GetConfigInt('MaxParticles', 1000)
    Settings['MapBorder']                   = Spring.GetConfigInt('MapBorder') == 1 -- turn 0/1 to bool
    Settings['3DTrees']                     = Spring.GetConfigInt('3DTrees') == 1
    Settings['luarules normalmapping']      = (Spring.GetConfigInt("NormalMapping", 1) > 0) -- api_custom_unit_shaders.lua
    Settings['GroundDecals']                = Spring.GetConfigInt('GroundDecals') == 1    
    Settings['MapMarks']                    = Spring.GetConfigInt('MapMarks') == 1
    Settings['DynamicSky']                  = Spring.GetConfigInt('DynamicSky') == 1
    Settings['DynamicSun']                  = Spring.GetConfigInt('DynamicSun') == 1
end

Settings['searchWidgetDesc'] = true
Settings['searchWidgetAuth'] = true
Settings['searchWidgetName'] = true
Settings['widget']           = {}
Settings['Cursor']           = 'Dynamic'
Settings['CursorName']       = 'bar'
Settings['widgetScrollPos']  = 0

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
    ['unit']      = {label = 'Units',       list = {}, pos = 1,}, -- relates to individual units or unit types
    ['cmd']       = {label = 'Commands',    list = {}, pos = 2,}, -- relates to (more general cases of) giving commands to units
    ['gui']       = {label = 'GUI',         list = {}, pos = 3,}, -- relates to providing information interactively
    ['inf']       = {label = 'Information', list = {}, pos = 4,}, -- relates to providing information passively
    ['snd']       = {label = 'Sound',       list = {}, pos = 5,}, 
    ['camera']    = {label = 'Camera',      list = {}, pos = 6,},
    ['map']       = {label = 'Map',         list = {}, pos = 7,},
    ['bgu']       = {label = 'BAR GUI',     list = {}, pos = 8,},
    ['gfx']       = {label = 'GFX',         list = {}, pos = 9,},
    ['dbg']       = {label = 'Debugging',   list = {}, pos = 10,},
    ['api']       = {label = 'API \255\255\200\200(Here be dragons!)', list = {}, pos = 11,},
    ['test']      = {label = 'Test Widgets',list = {}, pos = 12,},
    ['ungrouped'] = {label = 'Ungrouped',   list = {}, pos = 13,},
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
        'cursorsettarget','cursorupgmex',
    }

    for i=1, #cursorNames do
        local topLeft = (cursorNames[i] == 'cursornormal' and cursorSet ~= 'k_haos_girl')
        if cursorSet == 'bar' then Spring.ReplaceMouseCursor(cursorNames[i], cursorNames[i], topLeft)
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
    local widgetList = tabs['Interface']:GetChildByName('widgetList') --scrollPanel 
    local stack = widgetList.children[1] --stackPanel
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
            stack:AddChild(Chili.Label:New{caption =cat.label, x=0, fontsize=18})
            -- Second loop adds each widget
            for b=1,#list do
                local green  = {color = {0.5,1,0,1}, outlineColor = {0.5,1,0,0.2}}
                local orange = {color = {1,0.5,0,1}, outlineColor = {1,0.5,0,0.2}}
                local red    = {color = {1,0,0,1}, outlineColor = {1,0,0,0.2}}

                local enabled = (widgetHandler.orderList[list[b].name] or 0)>0
                local active  = list[b].wData.active
                local author = list[b].wData.author or "Unknown"
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

local function AddWidgetOption(obj)
    if not obj.title or not obj.name then return end

    local widgetOptions = tabs.Interface:GetChildByName('widgetOptions') --scrollPanel
    local stack = widgetOptions.children[1] -- stackPanel

    local oldOptions = stack:GetChildByName(obj.name)
    local panel --contains this widgets options
    if oldOptions then
        panel = oldOptions
        panel:ClearChildren()
    else
        panel = Chili.StackPanel:New{
            name        = obj.name,
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
    end
        
    panel:AddChild(Chili.Label:New{caption=obj.title,x='0%',fontsize=18})
    for i = 1, #obj.children do
        panel:AddChild(obj.children[i]) -- chili controls created by widget
        -- if the widget is unloaded, these will disappear, but the title will still remain (and no options showing)
    end
    panel:AddChild(Chili.Line:New{width='100%'})
    panel:AddChild(Chili.Line:New{width='100%'})
    stack:AddChild(panel)
end

----------------------------
local function CheckSpec()
    -- hide the resign button if we are a spec
    local button = tabs.General:GetChildByName('ResignButton')
    local isSpec = Spring.GetSpectatingState()
    if isSpec and button.visible then
        button:Hide()
    elseif not isSpec and button.hidden then
        button:Show()
    end
end

-- Toggles the menu visibility
--  also handles tab selection (e.g. f11 was pressed and menu opens to 'Interface')
local function ShowHide(tab)
    local oTab = Settings.tabSelected

    Chili.Screen0.currentTooltip = nil
    
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
    
    CheckSpec()
end

----------------------------
-- Handles the selection of the tabs
local function sTab(_,tabName)
    if not tabs[tabName] then return end
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
        Spring.Echo("Use Save{key=value,key2=value2,etc..} instead of Save('key', value) [" .. (key or "") .. "]")
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
        return nil
    end
end
----------------------------
-- Creates a stack panel 
local function addStack(obj)
    local stack
        stack = Chili.StackPanel:New{
            name        = obj.name or 'Stack',
            x           = obj.x or 0,
            y           = obj.y or 0,
            width       = obj.width or '50%',
            --height      = '70%',
            resizeItems = false,
            autosize    = true,
            padding     = {0,0,0,0},
            itemPadding = {5,0,5,0},
            itemMargin  = {0,0,0,0},
            children    = obj.children or {},
            preserverChildrenOrder = true
        }
    return stack
end
-- Creates a stack panel inside a scroll panel
local function addScrollStack(obj)
    local stack = Chili.ScrollPanel:New{
        name     = obj.name or 'ScrollStack',
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
                children    = obj.children or {},
                preserverChildrenOrder = true
            }
        }
    }
    return stack
end

----------------------------
-- Creates the original window in which all else is contained
local function loadMainMenu()
    local sizeData = Load('mainMenuSize') or {x=400,y=200,width=750,height=550}

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
        OnChange = {function() Chili.Screen0.currentTooltip=nil end},
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
        selected     = Settings.tabSelected or 'General',
        tabs         = {'General','Interface', 'Graphics'},
        itemPadding  = {1,0,1,0},
        OnChange     = {sTab}
    }
    
    mainMenu:Hide()

end

----------------------------
local waterConvert_ID = {[0]=1,[1]=2,[2]=3,[3]=4,[4]=5} -- value -> listID (ugh)
local shadowConvert_ID = {[0]=1,[1]=2,[2]=3}
--local shadowMapSizeConvert_ID = {[32]=1,[1024]=2,[2048]=3,[4096]=4} 
----------------------------

local function applyDefaultSettings()
    local comboboxes = {
        ['Water']            = 1,
        ['Shadows']          = 2,
    }
    
    local sliders = {
        ['UnitIconDist']      = 280,
        ['UnitLodDist']       = 280,
        ['MaxParticles']      = 1000,
        ['MaxNanoParticles']  = 1000,
    }
    
    local checkboxes = {
        ['AdvMapShading']    = 1,
        ['AdvModelShading']  = 1,
        ['luarules normalmapping']    = 1,
        ['AllowDeferredMapRendering']   = 1,
        ['AllowDeferredModelRendering'] = 1,
        ['MapBorder']        = 1,
        ['3DTrees']          = 1,
        ['GroundDecals']     = 0,
        ['MapMarks']         = 1,
        ['DynamicSky']       = 0,
        ['DynamicSun']       = 0,
    }

    local EngineSettingsMulti = tabs['Graphics']:GetChildByName('Settings'):GetChildByName('EngineSettingsMulti')
    local EngineSettingsCheckBoxes = tabs['Graphics']:GetChildByName('Settings'):GetObjectByName('EngineSettingsCheckBoxes')
    
    for setting,value in pairs(comboboxes) do
        Settings[setting] = value
        if setting=='Water' then
            EngineSettingsMulti:GetObjectByName(setting):Select(waterConvert_ID[value])
        elseif setting=='Shadows' then
            EngineSettingsMulti:GetObjectByName(setting):Select(shadowConvert_ID[value])
        --elseif setting=='ShadowMapSize' then
            --engineStack:GetObjectByName(setting):Select(shadowMapSizeConvert_ID[value] or 2)
        end
    end
    
    for setting,value in pairs(sliders) do
        Settings[setting] = value
        EngineSettingsMulti:GetObjectByName(setting):SetValue(value)
    end
    
    for setting,value in pairs(checkboxes) do
        Settings[setting] = value
        local checkbox = EngineSettingsCheckBoxes:GetObjectByName(setting)
        if checkbox.checked ~= (value==1) then checkbox:Toggle() end
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
    if obj.name=='Shadows' then
        selected = shadowConvert_ID[Settings['Shadows']] -- for shadows and water we store the value to match springsettings
    elseif obj.name=='Water' then
        selected = waterConvert_ID[Settings['Water']]
    else
        for i = 1, #obj.labels do
            if obj.labels[i] == Settings[obj.name] then selected = i end
        end
    end

    Spring.Echo(obj.name, Settings[obj.name])    

    local function applySetting(obj, listID)
        local value   = obj.options[listID] or ''
        local setting = obj.name or ''

        if setting == 'Skin' then
            --fixme, colourmode & alphamode
        elseif setting == 'Cursor' then
            setCursor(value)
            Settings['CursorName'] = value
        else 
            spSendCommands(setting..' '..value)
        end

        -- Spring.Echo(setting.." set to "..value) --TODO: this is misleading
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

    local toggle = function(self)
        Settings[self.name] = not self.checked --self.checked hasn't changed yet!
        spSendCommands(self.name)
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

    Spring.Echo(obj.name, Settings[obj.name])

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


-----------------------------
-- Creates a tab, mostly as an auxillary function for AddControl()
local function createTab(tab)
    tabs[tab.name] = Chili.Control:New{x = 0, y = 20, bottom = 20, width = '100%', children = tab.children or {} }
    menuTabs:AddChild(Chili.TabBarItem:New{caption = tab.name, width = tab.tabWidth})
end

-----OPTIONS-----------------
-----------------------------

function SetInfoChild(obj)
    if not tabs.General then return end
    tabs.General:GetChildByName('info caption'):SetCaption(obj.caption)
    tabs.General:GetChildByName('info_layoutpanel'):ClearChildren()
    tabs.General:GetChildByName('info_layoutpanel'):AddChild(obj.iPanel)
end

local function createInfoTab()
    local armageddonTime = 60 * (tonumber((Spring.GetModOptions() or {}).mo_armageddontime) or 0)

    local endModes = { com = "Kill all enemy Commanders", killall = "Kill all enemy units", neverend = "Never end"}
    local gameEndMode = endModes[Spring.GetModOptions().deathmode]
    
    local changeLog, introText, hotkeyInfo
    
    local function ParseChangelog(changelog)
        -- parse the changelog and add a small amount of colour
        -- TODO once we have a changelog!
        
        return changelog
    end
    
    local function InfoTextBox(obj)
        obj.size = obj.size or 20
        local Box = Chili.Control:New{width = '100%', y = obj.y*25, x = 0, height = obj.size +5, padding = {0,0,0,0},
            children = {
                Chili.Label:New{right='70%', caption=obj.name or '',font={size=obj.size,color={0.8,0.8,1,1}}},
                Chili.Label:New{x='35%', caption=obj.value,font={size=obj.size,color={0.7,0.7,1,1}}},
            }
        }
        return Box
    end
    
    local function InfoLineBox(y, text1, size)
        if not size then size = 20 end
        return Chili.LayoutPanel:New{width = 300, y = y*25, x = '10%', height = size+5, autosize = false, autoresizeitems = false, padding = {0,0,0,0}, itemPadding = {0,0,0,0}, itemMargin  = {0,0,0,0}, children = {
                Chili.TextBox:New{right='95%',text=" "..text1,font={size=size,color={0.8,0.8,1,1}},padding = {0,0,0,0}},
            }        
        }
    end
    
    local function ResignMe(self)
        spSendCommands{'Spectator'}
        if self.visible then self:Hide() end
    end

    local hotkeyInfoBox = Chili.TextBox:New{width='100%',text=HotkeyInfo.General,padding={0,5,0,0}} 

    local function SetHotkeyTab(_, tabName)
        hotkeyInfoBox:SetText(HotkeyInfo[tabName])
    end
    
    local hotkeyInfo = Chili.Control:New{x = 0, y = 20, bottom = 0, width = '100%', 
        children = {
            Chili.TabBar:New{x = 0, y = 0,    width = '100%', height = 20, minItemWidth = 70, selected = 'General', itemPadding = {1,0,1,0}, OnChange = {SetHotkeyTab},
                tabs = {'General', 'Units I', 'Units II', 'Units III'},
            },
            Chili.ScrollPanel:New{y = 20, width = '100%', bottom = 0, children = {hotkeyInfoBox}}
        }
    }

    local changeLog = Chili.ScrollPanel:New{width = '100%', height='100%',
        children = {
            Chili.TextBox:New{width='100%',text=ParseChangelog(changelog),padding={0,5,0,0}}
        }
    }

    local introText = Chili.ScrollPanel:New{width = '100%', height='100%',
        children = {
            Chili.TextBox:New{width='100%',text=NewbieInfo,padding={0,5,0,0}}
        }
    }

    -- Info --
    tabs.General = Chili.Control:New{x = 0, y = 20, bottom = 20, width = '100%',
        children = {
            Chili.Label:New{name = 'info caption', caption = '', x = 0, y = 2, width = '70%', fontsize = 20},
            Chili.LayoutPanel:New{name  = 'info_layoutpanel', width = '70%', x=0, y=20, bottom=0},

            Chili.Button:New{caption = 'Introduction', iPanel = introText, height = '7%', width = '28%', right = '1%', y = '7%', OnMouseUp = {SetInfoChild}, name="Introduction Button"},
            Chili.Button:New{caption = 'Hotkey Info', iPanel = hotkeyInfo, height = '7%', width = '28%', right = '1%', y = '16%', OnMouseUp = {SetInfoChild}},

            Chili.Button:New{caption = 'Changelog', iPanel = changeLog, height = '7%', width = '28%', right = '1%', y = '37%', OnMouseUp = {SetInfoChild}},
            
            Chili.Button:New{caption = 'Resign and Spectate', name = "ResignButton", height = '9%', width = '28%', right = '1%', y = '72%', OnMouseUp = {ResignMe}},
            Chili.Button:New{caption = 'Exit To Desktop',height = '9%',width = '28%',right = '1%', y = '82%',
                OnMouseUp = {function() spSendCommands{'quitforce'} end }},
        }
    }

    SetInfoChild{iPanel = introText, caption = 'Introduction'}
end

local function createInterfaceTab()
    -- Interface --
    tabs.Interface = Chili.Control:New{x = 0, y = 20, bottom = 20, width = '100%', --Control attached to tab
        children = {
            addScrollStack{name='widgetList',x='50%'},
            Chili.EditBox:New{name='widgetFilter',x=0,y=0,width = '35%',text=' Enter filter -> Hit Return,  or -->',OnMouseDown = {function(obj) obj:SetText('') end}},
            Chili.Button:New{right='50%',y=0,height=20,width='15%',caption='Search',OnMouseUp={addFilter}},
            Chili.Checkbox:New{caption='Search Widget Name',x=0,y=40,width='35%',textalign='left',boxalign='right',checked=Settings.searchWidgetName,
                OnChange = {function() Settings.searchWidgetName = not Settings.searchWidgetName end}
            },
            Chili.Checkbox:New{caption='Search Description',x=0,y=20,width='35%',textalign='left',boxalign='right',checked=Settings.searchWidgetDesc,
                OnChange = {function() Settings.searchWidgetDesc = not Settings.searchWidgetDesc end}
            },
            Chili.Checkbox:New{caption='Search Author',x=0,y=60,width='35%',textalign='left',boxalign='right',checked=Settings.searchWidgetAuth,
                OnChange = {function() Settings.searchWidgetAuth = not Settings.searchWidgetAuth end}
            },

            Chili.Line:New{width='50%',y=80},

            Chili.TextBox:New{text='Skin',y=90, width='45%',},
            Chili.Control:New{x='2%', y=100, width='40%',autoSize=true,padding={0,4,0,0},
                children = {
                    Chili.TextBox:New{x='0%',width='35%',text="Colour mode:"},
                    Chili.ComboBox:New{x='35%',width='65%',
                        items    = {"black", "white", "team"},
                        selected = (WG.GetSkinColourMode()=="black" and 1) or (WG.GetSkinColourMode()=="white" and 2) or (WG.GetSkinColourMode()=="team" and 3),
                        OnSelect = {
                            function(self,sel)
                                local mode = self.items[sel]
                                WG.SetSkinColourMode(mode)
                                Spring.Echo("Setting skin colour to " .. WG.GetSkinColourMode())
                                if fullyLoaded then
                                    WG.ExposeNewSkinColours() -- causes luaui reload -> don't do this in initialise
                                end
                            end
                            }
                        },
                    Chili.TextBox:New{y=17, x='0%',width='35%',text="Alpha:"},
                    Chili.ComboBox:New{y=17, x='35%',width='65%',
                        items    = {"low", "med", "high", "max"},
                        selected = (WG.GetSkinAlphaMode()=="low" and 1) or (WG.GetSkinAlphaMode()=="med" and 2) or (WG.GetSkinAlphaMode()=="high" and 3) or (WG.GetSkinAlphaMode()=="max" and 4),
                        OnSelect = {
                            function(self,sel)
                                local alpha = self.items[sel]
                                WG.SetSkinAlphaMode(self.items[sel])  
                                Spring.Echo("Setting skin alpha to " .. WG.GetSkinAlphaMode(), sel)
                                if fullyLoaded then
                                    WG.ExposeNewSkinColours() -- causes luaui reload -> don't do this in initialise
                                end
                            end
                            }
                        },
                    },                
            },
            comboBox{name='Cursor',y=135, width='45%',
                labels={'Dynamic','Static'},
                options={'bar','static'}
            },
            Chili.Label:New{caption='-- Widget Settings --',x='2%',width='46%',align = 'center',y=175},
            addScrollStack{y=190,x='2%',width='46%',name='widgetOptions'},
        }
    }
    
    tabs.Interface:GetChildByName("widgetList"):SetScrollPos(x, Settings.widgetScrollPos or 0)
end

local function createGraphicsTab()
    -- Graphics --
    tabs.Graphics = Chili.Window:New{x = 0, y = 20, bottom = 20, width = '100%', borderColor = {0,0,0,0}, backgroundColor = {0,0,0,0},
        children = {
            Chili.ScrollPanel:New{name='Settings', x=0, y=0, width='100%', height='80%', children = {
                    addStack{x = 0, y = '3%', name = 'EngineSettingsMulti', children = {
                            comboBox{y=0,title='Water',name='Water', --not 'ReflectiveWater' because we use SendCommands instead of SetConfigInt to apply settings (some settings seem to only take effect immediately this way)
                                labels={'Basic','Reflective','Dynamic','Refractive','Bump-Mapped'},
                                options={0,1,2,3,4},},
                            comboBox{y=40,title='Shadows',name='Shadows',
                                labels={'Off','On','Units Only'},
                                options={'0','1','2'},},
                            --[[comboBox{y=40,title='Shadow Resolution',name='ShadowMapSize', --disabled because it seems this can't be changed ingame
                                labels={'Very Low','Low','Medium','High'},
                                options={'32','1024','2048','4096'},},]]
                            slider{name='UnitLodDist',title='Unit Draw Distance', max = 600, step = 1},
                            slider{name='UnitIconDist',title='Unit Icon Distance', max = 600, step = 1},
                            slider{name='MaxParticles',title='Max Particles', max = 5000},
                            slider{name='MaxNanoParticles',title='Max Nano Particles', max = 5000},
                        }
                    },
                    addStack{x = '50%', y = '3%', name = 'EngineSettingsCheckBoxes', children = {
                            checkBox{title = 'Advanced Map Shading', name = 'AdvMapShading', tooltip = "Toggle advanced map shading mode"},                    
                            checkBox{title = 'Advanced Model Shading', name = 'AdvModelShading', tooltip = "Toggle advanced model shading mode"},
                            checkBox{title = 'Extra Model Shading', name = 'luarules normalmapping', tooltip = "Toggle BARs extra model shaders"}, 
                            checkBox{title = 'Deferred Map Shading', name = 'AllowDeferredMapRendering', tooltip = "Toggle deferred model shading mode (requires advanced map shading)"},
                            checkBox{title = 'Deferred Model Shading', name = 'AllowDeferredModelRendering', tooltip = "Toggle deferred model shading mode (requires advanced model shading)"},
                            checkBox{title = 'Draw Engine Trees', name = '3DTrees', tooltip = "Enable/Disable rendering of engine trees"},
                            checkBox{title = 'Ground Decals', name = 'GroundDecals', tooltip = "Enable/Disable rendering of ground decals"},
                            checkBox{title = 'Dynamic Sky', name = 'DynamicSky', tooltip = "Enable/Disable dynamic-sky rendering"},
                            checkBox{title = 'Dynamic Sun', name = 'DynamicSun', tooltip = "Enable/Disable dynamic-sun rendering"},
                            checkBox{title = 'Show Map Marks', name = 'MapMarks', tooltip = "Enables/Disables rendering of map drawings/marks"},
                            checkBox{title = 'Hide Map Border', name = 'MapBorder', tooltip = "Set or toggle map border rendering"}, --something is weird with parity here
                            checkBox{title = 'Vertical Sync', name = 'VSync', tooltip = "Enables/Disables V-sync"},      
                        }                    
                    }
                },
            },
            Chili.Button:New{name="ResetDefaults",x='25%',y='85%',height='10%',width='50%',caption='Reset Defaults',OnMouseUp={applyDefaultSettings}},
        }
    }
    
    --TODO: OnSelect for this tab that reloads options from the springsettings values (in case they have been changed elswhere by e.g. other widgets whilst ingame)
end


local function createCreditsTab()
    createTab{name = 'Credits',
        children = {
            Chili.ScrollPanel:New{width = '70%', x=0, y=0, bottom=0,
                children = {Chili.TextBox:New{width='100%',text=credits}}
            }
        }-- TODO: find a logo and a place for it!
    }
end
-----------------------------
--
local function AddChildren(control, children)
    for i=1, #children do control:AddChild(children[i]) end
end


-----------------------------
-- Adds a chili control to a tab
--  usage is Menu.AddControl('nameOfTab', controlToBeAdded)
--  if tab doesn't exist, one is created
--  this is useful if you want a widget to get it's own tab (endgraph is a good example)
--  this function probably won't change
local function AddControl(tab,control,tabWidth)
    if not tabs[tab] then createTab{name = tab, tabWidth = tabWidth} end
    tabs[tab]:AddChild(control)
    tabs[tab]:Invalidate()
end


-----------------------------
-- Makes certain functions global, extending their usage to other widgets
--  most manipulate and/or create chili objects in some way to extend options
--  look at relevant functions above for more info
local function globalize()
    local Menu = {}
   
    Menu.AddControl = AddControl -- for adding new tabs e.g. the end-graph widget
    Menu.ShowHide   = ShowHide -- show/hide menu tabs

    
    Menu.AddWidgetOption  = AddWidgetOption -- for registering options of widgets (note: ideally, widgets are responsible for save/load of their own options)
    --[[
        -- Example usage for AddWidgetOption(obj)
        obj = {
            title = 'My Title',
            name = widget:GetInfo().name, -- required!
            children = {
                Chili.Checkbox:New{caption='An Option', x='10%', width='80%', checked=<initial value from widget>, OnChange={function() <effect of changing option in widget>; end}},
            }
        }                
    ]]
    
    -- allow access to our own Settings table (todo: remove this)
    Menu.Load = Load
    Menu.Save = Save

    WG.MainMenu = Menu
end
-----------------------------

function widget:GetConfigData()
    local widgetList = tabs['Interface']:GetChildByName('widgetList')
    Settings.widgetScrollPos = widgetList and widgetList.scrollPosY or 0 --guard against removing ourself
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
    setCursor(Settings['CursorName'] or 'bar')

    loadMainMenu()
    
    LoadSpringSettings()
    
    createInfoTab()
    createInterfaceTab()
    createGraphicsTab()
    createCreditsTab()
        
    if amNewbie then ShowHide('General') else menuTabs:Select('General') end
    globalize()
    makeWidgetList()

    -----------------------
    ---     Hotkeys     ---
    local toggleMenu      = function() ShowHide('General') end
    local hideMenu        = function() if mainMenu.visible then mainMenu:Hide() end end
    local toggleInterface = function() ShowHide('Interface') end
    local showHelp        = function() ShowHide('General'); SetInfoChild(tabs.General:GetChildByName("Introduction Button")) end --small hack

    spSendCommands('unbindkeyset f11')
    spSendCommands('unbindkeyset Any+i gameinfo')
    spSendCommands('unbind S+esc quitmenu','unbind esc quitmessage')
    widgetHandler.actionHandler:AddAction(widget,'toggleInterface', toggleInterface, nil, 't')
    widgetHandler.actionHandler:AddAction(widget,'hideMenu', hideMenu, nil, 't')
    widgetHandler.actionHandler:AddAction(widget,'toggleMenu', toggleMenu, nil, 't')
    widgetHandler.actionHandler:AddAction(widget,'showHelp', showHelp, nil, 't')
    spSendCommands('bind i toggleMenu')
    spSendCommands('bind S+esc toggleMenu')
    spSendCommands('bind f11 toggleInterface')
    spSendCommands('bind esc hideMenu')
    spSendCommands('bind h showHelp')
    
    fullyLoaded = true
end

function widget:Update()
    -- check if any widgets changed enabled/active state
    if widgetHandler.knownChanged then
        widgetHandler.knownChanged = false -- important note: widgetHandler.knownChanged=true was added by us to the widgetHandler, when a widget crashes (selector.lua polls each Drawframe)
        makeWidgetList()
    end
end

function widget:Shutdown()
    spSendCommands('unbind i toggleMenu')
    spSendCommands('unbind S+esc toggleMenu')
    spSendCommands('unbind f11 toggleInterface')
    spSendCommands('unbind esc hideMenu')
    spSendCommands('bind f11 luaui selector') -- if the default one is removed or crashes, then have the backup one take over.
    spSendCommands('bind Any+i gameinfo')
end


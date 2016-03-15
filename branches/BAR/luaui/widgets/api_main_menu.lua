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
        enabled = true,
        api     = true,
    }
end


local spSendCommands = Spring.SendCommands
local spgetFPS       = Spring.GetFPS
local spGetTimer     = Spring.GetTimer
local spGetDrawFrame = Spring.GetDrawFrame

local Chili, mainMenu, menuTabs, menuBtn

local tabs = {}
local credits = VFS.LoadFile('credits_game.txt')
local changelog = VFS.LoadFile('changelog.txt')
local NewbieInfo = include('configs/NewbieInfo.lua')
local HotkeyInfo = include('configs/HotkeyInfo.lua')
local amNewbie = (Spring.GetTeamRulesParam(Spring.GetMyTeamID(), 'isNewbie') == 1)

local Settings = {}
local DefaultSettings = {}

 local fullyLoaded = false -- set to true at the end of widget:Initialize 

local whiteStr = '\255\255\255\255'
local greenStr = '\255\1\255\1'
local blueStr = '\255\1\1\255'
local turqoiseStr = "\255\48\213\200"
local lilacStr = "\255\200\162\200"
local greyStr = '\255\150\150\150'


------------------------------------
-- Settings

local MinimalGraphicsSettings = { 
    -- springsettings, graphics tab
    comboboxes = {
        ['Water']            = 0,
        ['Shadows']          = 0,
        ['ShadowMapSize']    = 2048,
    },
    sliders = {
        ['UnitIconDist']      = 150,
        ['UnitLodDist']       = 150,
        ['MaxParticles']      = 1000,
        ['MaxNanoParticles']  = 750,
    },
    checkboxes = {
        ['AdvMapShading']    = false,
        ['AdvModelShading']  = false,
        ['luarules normalmapping'] = false,
        ['AllowDeferredMapRendering']   = false,
        ['AllowDeferredModelRendering'] = false,
        ['3DTrees']          = false,
        ['GroundDecals']     = false,
        ['DynamicSky']       = false,
        ['DynamicSun']       = false,
        ['MapMarks']         = true,
        ['MapBorder']        = false,
        ['VSync']            = true,
    },
}

local DefaultSettings = { 
    -- springsettings, graphics tab
    comboboxes = {
        ['Water']            = 1,
        ['Shadows']          = 2,
        ['ShadowMapSize']    = 4096,
    },
    sliders = {
        ['UnitIconDist']      = 260,
        ['UnitLodDist']       = 260,
        ['MaxParticles']      = 3000,
        ['MaxNanoParticles']  = 2000,
    },
    checkboxes = {
        ['AdvMapShading']    = true,
        ['AdvModelShading']  = true,
        ['luarules normalmapping'] = true,
        ['AllowDeferredMapRendering']   = true,
        ['AllowDeferredModelRendering'] = true,
        ['3DTrees']          = true,
        ['GroundDecals']     = true,
        ['DynamicSky']       = false,
        ['DynamicSun']       = false,
        ['MapMarks']         = true,
        ['MapBorder']        = false,
        ['VSync']            = true,
    },
    
    -- non-springsettings, interface tab
    interface = {
        ['cursorName']         = 'bar',
        ['searchWidgetDesc']   = true,
        ['searchWidgetAuth']   = true,
        ['searchWidgetName']   = true,
        ['showWidgetDescs'] = true,
        ['showWidgetAuthors'] =  false,
        ['widgetSelectorMode'] = "normal",
        ['expandedWidgetOptions'] = {},
        ['mainMenuSize'] = {x=400,y=200,width=750,height=550},
    },
}

local MaximalGraphicsSettings = {
    -- springsettings, graphics tab
    comboboxes = {
        ['Water']            = 4,
        ['Shadows']          = 1,
        ['ShadowMapSize']    = 8192,
    },
    sliders = {
        ['UnitIconDist']      = 700, -- never show icons
        ['UnitLodDist']       = 600,
        ['MaxParticles']      = 5000,
        ['MaxNanoParticles']  = 5000,
    },
    checkboxes = {
        ['AdvMapShading']    = true,
        ['AdvModelShading']  = true,
        ['luarules normalmapping'] = true,
        ['AllowDeferredMapRendering']   = true,
        ['AllowDeferredModelRendering'] = true,
        ['3DTrees']          = true,
        ['GroundDecals']     = true,
        ['DynamicSky']       = true,
        ['DynamicSun']       = true,
        ['MapMarks']         = true,
        ['MapBorder']        = true,
        ['VSync']            = true,
    },
}

function FetchDefaultSetting(name)
    for cat, settingsTable in pairs(DefaultSettings) do
        if settingsTable[name] then return 
            settingsTable[name], cat 
        end 
    end
end

function FetchSpringSetting(name, settingName)
    -- prefer our local copy of settings to Springs one because Spring doesn't save many of the settings if they are changed ingame
    -- todo: if this is even fixed in the engine, switch to preferring the engines copy!
    local settingName = settingName or name -- toggle name differs from springsettings.cfg name
    local default,cat = FetchDefaultSetting(name)
    if cat=='checkboxes' then
        if Settings[name]==nil then 
            -- bool, but springsettings contains an int
            Settings[name] = (Spring.GetConfigInt(name, default and 1 or 0) > 0)
        end
    else
        if Settings[name]==nil then
            -- number
            Settings[name] = Spring.GetConfigInt(name, default)
        end
    end    
end

function FetchSetting(name)
    local default = FetchDefaultSetting(name)
    if Settings[name]== nil then 
        Settings[name] = default 
    end
end

function InitSettings()
    -- set to default if nil
    for cat,settingsTable in pairs(DefaultSettings) do
        for name,_ in pairs(settingsTable) do
            if cat~="interface" then
                -- fetch relevant things from springsettings
                FetchSpringSetting(name)
            else
                -- our interface settings
                FetchSetting(name)
            end
        end
    end
end


local waterConvert_ID = {[0]=1,[1]=2,[2]=3,[3]=4,[4]=5} -- setting value -> listID (ugh)
local shadowConvert_ID = {[0]=1,[1]=2,[2]=3}
local shadowMapSizeConvert_ID = {[2048]=1,[4096]=2,[8192]=3} 
        
function ApplyGraphicsSettings(WantedSettings)
    -- apply our default springsettings (==graphics) and *only* those, via selecting them in our chili controls
    local EngineSettingsMulti = tabs['Graphics']:GetChildByName('Settings'):GetChildByName('EngineSettingsMulti')
    local EngineSettingsCheckBoxes = tabs['Graphics']:GetChildByName('Settings'):GetObjectByName('EngineSettingsCheckBoxes')
    
    for setting,value in pairs(WantedSettings.comboboxes) do
        Settings[setting] = value
        if setting=='Water' then
            EngineSettingsMulti:GetObjectByName(setting):Select(waterConvert_ID[value])
        elseif setting=='Shadows' then
            EngineSettingsMulti:GetObjectByName(setting):Select(shadowConvert_ID[value])
        elseif setting=='ShadowMapSize' then
            EngineSettingsMulti:GetObjectByName(setting):Select(shadowMapSizeConvert_ID[value])
        end
    end
    
    for setting,value in pairs(WantedSettings.sliders) do
        Settings[setting] = value
        EngineSettingsMulti:GetObjectByName(setting):SetValue(value)
    end
    
    for setting,value in pairs(WantedSettings.checkboxes) do
        Settings[setting] = value
        local checkbox = EngineSettingsCheckBoxes:GetObjectByName(setting)
        if checkbox.checked ~= value then checkbox:Toggle() end
    end
end

function ApplyMinimalGraphicsSettings()
    ApplyGraphicsSettings(MinimalGraphicsSettings)
end
function ApplyDefaultGraphicsSettings()
    ApplyGraphicsSettings(DefaultSettings)
end
function ApplyMaximalGraphicsSettings()
    ApplyGraphicsSettings(MaximalGraphicsSettings)
end

----------------------------
-- load cursors 
function SetCursor(cursorSet)
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
        local topLeft = (cursorNames[i] == 'cursornormal')
        if cursorSet == 'bar' then 
            Spring.ReplaceMouseCursor(cursorNames[i], cursorNames[i], topLeft)
        else 
            Spring.ReplaceMouseCursor(cursorNames[i], cursorSet..'/'..cursorNames[i], topLeft) 
        end
    end
end

------------------------------------
-- widget list vars

local wFilterString = ""
local widgetList = {}
local updateWidgetListPos = false -- we track the widget selector posn by the name of the first visible control -> if we want to position after a redraw, chili needs a frame to sort out its y coords 
local widgetOptions = {} -- hold the chili controls for widgets custom options

local wCategories = {
    ['unit']      = {label = 'Units',       list = {}, pos = 1,}, -- relates to individual units or unit types
    ['cmd']       = {label = 'Commands',    list = {}, pos = 2,}, -- relates to (more general cases of) giving commands to units
    ['gui']       = {label = 'GUI',         list = {}, pos = 3,}, -- relates to providing information interactively
    ['inf']       = {label = 'Information', list = {}, pos = 4,}, -- relates to providing information passively
    ['snd']       = {label = 'Sound',       list = {}, pos = 5,}, 
    ['camera']    = {label = 'Camera',      list = {}, pos = 6,},
    ['map']       = {label = 'Map',         list = {}, pos = 7,},
    ['bgu']       = {label = 'BAR GUI',     list = {}, pos = 8, adv = true},
    ['gfx']       = {label = 'GFX',         list = {}, pos = 9, adv = true},
    ['dbg']       = {label = 'Debugging',   list = {}, pos = 10, adv = true},
    ['api']       = {label = 'API \255\255\200\200(Here be dragons!)', list = {}, pos = 11, adv = true},
    ['test']      = {label = 'Test Widgets',list = {}, pos = 12, adv = true},
    ['ungrouped'] = {label = 'Ungrouped',   list = {}, pos = 13, adv = true},
}
local inv_widgetCat_pos = {}
local num_widgetCat

----------------------------
-- sort & group the widgets
local function groupWidget(name,wData)

    local _, _, category = string.find(wData.basename, '([^_]*)')
    if (not category) or (not wCategories[category]) then category = 'ungrouped' end

    for cat_name,cat in pairs(wCategories) do
        if category == cat_name then
            cat.list[#cat.list+1] = {name = name, wData = wData}
        end
    end

end

local sortedWidgetList
local function sortWidgetList()
    if not fullyLoaded then return end -- we have to wait until after initialize, because the widgetHandler hasn't loaded all the widgets at that point!
    if sortedWidgetList then return end
    sortedWidgetList = true

    -- give each widget a cat, and put into its cat.list
    for name,wData in pairs(widgetHandler.knownWidgets) do
        groupWidget(name,wData)
    end 
    
    -- sort each cat.list
    local ascendingName = function(a,b) return a.name<b.name end
    for _,cat in pairs(wCategories) do
        table.sort(cat.list, ascendingName)
    end
    
    -- get order of categories
    inv_widgetCat_pos = {}
    num_widgetCat = 0
    for cat_name,cat in pairs(wCategories) do
        if cat.pos then
            inv_widgetCat_pos[cat.pos] = cat_name
            num_widgetCat = num_widgetCat + 1
        end
    end
end

----------------------------
-- widget list vertical alignment on re-draws 

function GetTopVisibleControlOfWidgetList()    
    -- get the name of the control which is topmost within the visible part of the widget selector scrollstack *and* is a widget checkbox
    -- BUT we need to alignNames instead of names, to forget about the font colour part of control name (there is one cached widgetControl for each font colour!)
    local widgetList = tabs['Interface']:GetChildByName('widgetList')
    if not widgetList then return nil end --guard against when we use the main menu to remove itself
    local stack = widgetList.children[1]
    local scrollY = widgetList.scrollPosY
    local name
    for _,child in ipairs(stack.children) do
        if child.y>=scrollY and child.alignName then 
            name = child.alignName
            break
        end
    end
    --Spring.Echo(name, scrollY)
    return name
end

function SetTopVisibleControlOfWidgetList(name)
    -- set the topmost control of the visible part of the widget selector scrollstack to be equal to the named control
    -- we have to avoid the case where all ys are zero; chili doesn't update the ys immediately
    local widgetList = tabs['Interface']:GetChildByName('widgetList')
    local stack = widgetList.children[1]
    local scrollPosY, alignName 
    local success
    for _,child in ipairs(stack.children) do
        success = success or (child.y>0)
        if name==child.alignName then 
            scrollPosY = child.y
            alignName = child.alignName
            break
        end
    end
    widgetList:SetScrollPos(0, scrollPosY or 0)
    --Spring.Echo(success, scrollPosY, name, alignName)
    return success
end

function ToggleExpandWidgetOptions(name)
    Settings['expandedWidgetOptions'][name] = not Settings['expandedWidgetOptions'][name]
    makeWidgetList()
end

----------------------------
-- widget filter (search) 
local function SetWidgetFilter()
    local editbox = tabs['Interface']:GetObjectByName('widgetFilter')
    wFilterString = editbox.text or ""
    makeWidgetList()
end

local function ClearWidgetFilter()
    local editbox = tabs['Interface']:GetObjectByName('widgetFilter')
    wFilterString = ""
    editbox:SetText("")
    makeWidgetList()
end

----------------------------
-- widget list drawing

local widgetControls = {}
local widgetAuthorControls = {}
local widgetDescsControls = {}

local function toggleWidget(self)
    -- Toggles widgets, enabled/disabled when clicked
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

local function WidgetFilter(name,desc,author)
    -- implement searching for widgets
    if wFilterString == "" then return true end

    local wFilterString = string.lower(wFilterString or '')
    if (Settings.searchWidgetName and string.lower(name or ''):find(wFilterString))
    or (Settings.searchWidgetDesc and string.lower(desc or ''):find(wFilterString))
    or (Settings.searchWidgetAuth and string.lower(author or ''):find(wFilterString)) then
        return true
    end
    return false
end

function GetWidgetControl(name, fontColour, enabled, active, fromZip, showDescs, desc)   
    local controlName = name  .. "_control" .. "_" .. fontColour
    local alignName = name  .. "_control"
    if not widgetControls[controlName] then
        -- create if not in our cache
        local greenFont  = {color = {0.5,1,0,1}, outlineColor = {0.5,1,0,0.2}}
        local orangeFont = {color = {1,0.5,0,1}, outlineColor = {1,0.5,0,0.2}}
        local redFont    = {color = {1,0,0,1}, outlineColor = {1,0,0,0.2}}
        local widgetControl = Chili.Control:New{
            name      = controlName,
            alignName = alignName, -- used for preserving v pos (from users point of view) on redraws 
            useForVAlign = true,
            width = '100%',
            x = '0%',
            autoSize = true,
            padding = {0,0,0,0},
            children = {
                Chili.Checkbox:New{
                    name      = name,
                    caption   = name .. fromZip,
                    tooltip   = (not showDescs) and desc,
                    width     = '87%',
                    x         = '7%',
                    font      = (fontColour=="green" and greenFont) or (fontColour=="orange" and orangeFont) or redFont,
                    checked   = enabled,
                    padding   = {1,1,1,0},
                    OnChange  = {toggleWidget},
                },
            }
        }
        if widgetOptions[name] then
            widgetControl:AddChild(Chili.Button:New{
                name    = name .. "_button",
                x       = '1%',
                y       = 3,
                width   = '5%',
                height  = 12,
                caption = '',
                OnClick = {function() ToggleExpandWidgetOptions(name) end}
            })
        end
        widgetControls[controlName] = widgetControl
    end
    
    local widgetOptions = widgetControls[controlName].children[2]
    if widgetOptions then
        widgetOptions:SetCaption(Settings['expandedWidgetOptions'][name] and "-" or "+")    
    end
    
    widgetControls[controlName].y = 0 -- we need to forget the *cached* y coord because the system for preserving v align needs the proper y coord and chili won't update immediately
    
    return widgetControls[controlName]
end

function GetWidgetAuthorControl(name, author)
    local controlName = name .. "_author"
    if not widgetAuthorControls[controlName] then
        -- create if its not in our cache
        local widgetAuthorControl = Chili.TextBox:New{
            name      = controlName,
            width     = '85%',
            x         = '9%',                
            text      = lilacStr .. "Author: " .. author,
            tooltip   = nil,
            padding   = {0,0,0,3},
        }
        widgetAuthorControls[controlName] = widgetAuthorControl
    end
    return widgetAuthorControls[controlName]
end

function GetWidgetDescsControl(name, desc)
    local controlName = name .. "_desc"
    if not widgetDescsControls[controlName] then
            -- create if its not in our cache        
        local widgetDescsControl = Chili.TextBox:New{
            name      = controlName,
            width     = '85%',
            x         = '9%',                
            text      = desc,
            tooltip   = nil,
            padding   = {0,0,0,3},
        }
        widgetAuthorControls[controlName] = widgetDescsControl
    end
    return widgetAuthorControls[controlName]
end


function makeWidgetList(layoutChange)
    -- remake the widget list
    -- layoutChange should be set to true if the callee has changed something (e.g. show/hide descs) that will change the heights of the controls
    local showDescs = Settings.showWidgetDescs
    local showAuthors = Settings.showWidgetAuthors
    local showAdv = (Settings.widgetSelectorMode=="advanced")
    
    -- construct and sort the widget list, if needed
    sortWidgetList()
    if not sortedWidgetList then return end

    -- remove previous children
    local widgetList = tabs['Interface']:GetChildByName('widgetList') --scrollPanel 
    local stack = widgetList.children[1] --stackPanel
    if layoutChange and #stack.children>0 then
        Settings["widgetScroll"] = GetTopVisibleControlOfWidgetList()
    end
    stack:ClearChildren()
        
    -- add new children
    -- Outer loop adds cat labels
    for i=1, num_widgetCat do
        -- Get group of pos i
        local cat = wCategories[inv_widgetCat_pos[i]]
        local list = cat.list
        if #list>0 and (showAdv or not cat.adv) then
            stack:AddChild(Chili.Control:New{width="100%",height=1}) -- dummy to make sure none of the "real" controls have y=0
            stack:AddChild(Chili.Line:New{width="50%",name=cat.label.."_line1", alignName = cat.label.."_line1"})
            stack:AddChild(Chili.Label:New{caption = turqoiseStr..cat.label, x=0, font={shadow=false,size=18}, alignName = cat.label .. "_label"})
            stack:AddChild(Chili.Line:New{width="50%",name=cat.label.."_line2", alignName = cat.label.."_line2"})
            -- Inner loop adds widgets in cat
            for b=1,#list do
                local enabled = (widgetHandler.orderList[list[b].name] or 0)>0
                local name = list[b].name
                local active  = list[b].wData.active
                local author = list[b].wData.author or "Unknown"
                local desc = list[b].wData.desc or "No Description"
                local fromZip = list[b].wData.fromZip and "" or greyStr .. " (user)"
                
                if WidgetFilter(name, desc, author) then 
                    local widgetFontColour = (active and "green") or (enabled and "orange") or "red"
                    local widgetControl = GetWidgetControl(name, widgetFontColour, enabled, active, fromZip, showDescs, desc)           
                    stack:AddChild(widgetControl)

                    if showAuthors then
                        local widgetAuthorControl = GetWidgetAuthorControl(name, author)
                        stack:AddChild(widgetAuthorControl)
                    end
                    if showDescs then
                        local widgetDescsControl = GetWidgetDescsControl(name, desc)
                        stack:AddChild(widgetDescsControl)
                    end
                    
                    if Settings['expandedWidgetOptions'][name] and widgetOptions[name] then
                        stack:AddChild(widgetOptions[name])
                    end
                end
            end
        end
    end    
    stack:AddChild(Chili.Line:New{width="50%",name="cat_bottomline"})
    
    if layoutChange then 
        updateWidgetListPos = true
    end    
end

local function AddWidgetOption(obj)
    if not obj.title or not obj.name or not obj.children then 
        return
    end
    
    widgetOptions[obj.name] = nil
    local panel = Chili.StackPanel:New{ -- will hold the widgets options
        name        = obj.name,
        x           = '9%',
        y           = 0,
        width       = '60%',
        resizeItems = false,
        autosize    = true,
        padding     = {0,0,0,0},
        itemPadding = {0,0,0,0},
        itemMargin  = {0,0,0,0},
        preserverChildrenOrder = true    
    }     
        
    for i = 1, #obj.children do
        panel:AddChild(obj.children[i]) -- chili controls created by widget
        -- if the widget is unloaded, these will disappear, but the title will still remain (and no options showing)
    end
    widgetOptions[obj.name] = panel
end

----------------------------
-- general visibility
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

local function ShowHide(tab)
    -- toggles the menu visibility and handles tab selection (e.g. f11 was pressed and menu opens to 'Interface')
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

local function sTab(_,tabName)
    -- handles selection of tabs
    if not tabs[tabName] then return end
    if Settings.tabSelected then mainMenu:RemoveChild(tabs[Settings.tabSelected]) end
    
    mainMenu:AddChild(tabs[tabName])
    Settings.tabSelected = tabName
end

----------------------------
-- control templates
local function addStack(obj)
    -- Creates a stack panel 
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

local function addScrollStack(obj)
    -- Creates a stack panel inside a scroll panel
    local stack = Chili.ScrollPanel:New{
        name     = obj.name or 'ScrollStack',
        x        = obj.x or 0,
        y        = obj.y or 0,
        width    = obj.width or '50%',
        bottom   = obj.bottom or 0,
        smoothScrollTime = obj.smoothScrollTime,
        verticalSmartScroll = obj.verticalSmartScroll,
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
-- Settings controls

local checkBox = function(obj)
    local obj = obj

    local OnChange = function(self)
        Settings[self.name] = not self.checked --self.checked hasn't changed yet!
        local value = Settings[self.name] and 1 or 0
        spSendCommands(self.name .. " " .. value)
        Spring.SetConfigInt(self.name, value)
    end
    
    local checkBox = Chili.Checkbox:New{
        name      = obj.name,
        caption   = obj.title or obj.name,
        checked   = Settings[obj.name],
        tooltip   = obj.tooltip or '',
        y         = obj.y,
        width     = obj.width or '80%',
        height    = 20,
        x         = '10%',
        textalign = 'left',
        boxalign  = 'right',
        OnChange  = {OnChange}
    }
    return checkBox
end

local slider = function(obj)
    local obj = obj

    local trackbar = Chili.Control:New{
        y       = obj.y or 0,
        width   = obj.width or '100%',
        height  = 40,
        x       = 0,
        padding = {0,0,0,0}
    }

    local function OnChange(self, value)
        local name = self.name        
        Settings[name] = value
        if name=="UnitLodDist" then
            spSendCommands('distdraw ' .. value)
        elseif name=="UnitIconDist" then
            spSendCommands('disticon ' .. value)            
        else
            spSendCommands(name..' '..value)
        end
        Spring.SetConfigInt(name, value)
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
            OnChange = {OnChange},
        })

    return trackbar
end

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
    elseif obj.name=='ShadowMapSize' then
        selected = shadowConvert_ID[Settings['ShadowMapSize']]
    else
        for i = 1, #obj.labels do
            if obj.labels[i] == Settings[obj.name] then selected = i end
        end
    end

    local function OnSelect(self, listID)
        local value   = self.options[listID]
        local name = self.name
        Settings[name] = value
        
        if name=="ShadowMapSize" then
            spSendCommands('shadows ' .. Settings['Shadows'] .. ' ' .. value) -- special case :(
        else
            spSendCommands(name..' '..value)
        end
        
        Spring.SetConfigInt(name, value)
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
            OnSelect = {OnSelect},
        })

    return comboBox
end

----------------------------
-- main load
local function loadMainMenu()
    local sizeData = Settings['mainMenuSize']

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
                Settings['mainMenuSize'] = {x=self.x,y=self.y,width=self.width,height=self.height}
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
        tabs         = {'General','Graphics','Interface'},
        itemPadding  = {1,0,1,0},
        OnChange     = {sTab}
    }
    
    mainMenu:Hide()

end

-----------------------------
-- Creates a tab, mostly as an auxillary function for AddControl()
local function createTab(tab)
    tabs[tab.name] = Chili.Control:New{x = 0, y = 20, bottom = 20, width = '100%', children = tab.children or {} }
    menuTabs:AddChild(Chili.TabBarItem:New{caption = tab.name, width = tab.tabWidth})
end

function SetInfoChild(obj)
    if not tabs.General then return end
    tabs.General:GetChildByName('info caption'):SetCaption(obj.caption)
    tabs.General:GetChildByName('info_layoutpanel'):ClearChildren()
    tabs.General:GetChildByName('info_layoutpanel'):AddChild(obj.iPanel)
end

-----------------------------
-- native TABS

local function CreateGeneralTab()    
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
                children = {
                    Chili.TabBarItem:New{caption='General'},
                    Chili.TabBarItem:New{caption='Selecting Units', width=120,},
                    Chili.TabBarItem:New{caption='Giving Orders', width=110,},
                    Chili.TabBarItem:New{caption='Build Orders', width=100,},                
                }
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
            Chili.Button:New{caption = 'Controls & Hotkeys', iPanel = hotkeyInfo, height = '7%', width = '28%', right = '1%', y = '16%', OnMouseUp = {SetInfoChild}},

            Chili.Button:New{caption = 'Changelog', iPanel = changeLog, height = '7%', width = '28%', right = '1%', y = '37%', OnMouseUp = {SetInfoChild}},
            
            Chili.Button:New{caption = 'Resign and Spectate', name = "ResignButton", height = '9%', width = '28%', right = '1%', y = '72%', OnMouseUp = {ResignMe}},
            Chili.Button:New{caption = 'Exit To Desktop',height = '9%',width = '28%',right = '1%', y = '82%',
                OnMouseUp = {function() spSendCommands{'quitforce'} end }},
        }
    }

    SetInfoChild{iPanel = introText, caption = 'Introduction'}
end

local function CreateInterfaceTab()
    -- Interface --
    tabs.Interface = Chili.Control:New{x = 0, y = 20, bottom = 20, width = '100%',
        children = {
            addScrollStack{name='widgetList',x='40%',width='60%',smoothScrollTime=0.25,verticalSmartScroll=true},
            
            Chili.Label:New{caption='-- Widget Filter --',x='2%',width='35%',align = 'center',y=0},
            Chili.EditBox:New{name='widgetFilter',x=0,y=23,width = '27%',text=' Enter search term...',OnMouseDown = {function(obj) obj:SetText('') end}},
            Chili.Button:New{x='27%',y=22,height=22,width='13%',caption='Search',OnMouseUp={SetWidgetFilter}},
            Chili.Control:New{x='2%', y=46, width='35%',autoSize=true,padding={0,0,0,0},
                children = {
                    Chili.Checkbox:New{caption='Search Name',x=0,y=0,width='100%',textalign='left',boxalign='right',checked=Settings.searchWidgetName,
                        OnChange = {function() Settings.searchWidgetName = not Settings.searchWidgetName end}
                    },
                    Chili.Checkbox:New{caption='Search Description',x=0,y=17,width='100%',textalign='left',boxalign='right',checked=Settings.searchWidgetDesc,
                        OnChange = {function() Settings.searchWidgetDesc = not Settings.searchWidgetDesc end}
                    },
                    Chili.Checkbox:New{caption='Search Author',x=0,y=34,width='100%',textalign='left',boxalign='right',checked=Settings.searchWidgetAuth,
                        OnChange = {function() Settings.searchWidgetAuth = not Settings.searchWidgetAuth end}
                    },
                    Chili.Button:New{x='6%',y=52,height=22,width='90%',caption='Clear Search',OnMouseUp={ClearWidgetFilter}},
                },
            },
            
            Chili.Line:New{width='40%',y=123},

            Chili.Label:New{caption='-- Widget Display --',x='2%',width='35%',align = 'center',y=136},
            Chili.Control:New{x='2%', y=160, width='35%',autoSize=true,padding={0,0,0,0},
                children = {
                    Chili.Checkbox:New{caption='Show Descriptions',x=0,y=0,width='100%',textalign='left',boxalign='right',checked=Settings.showWidgetDescs ,
                        OnChange = {
                            function() 
                                Settings.showWidgetDescs = not Settings.showWidgetDescs
                                makeWidgetList(true) 
                            end} 
                    },
                    Chili.Checkbox:New{caption='Show Authors',x=0,y=17,width='100%',textalign='left',boxalign='right',checked=Settings.showWidgetAuthors,--todo
                        OnChange = {
                            function() 
                                Settings.showWidgetAuthors = not Settings.showWidgetAuthors
                                makeWidgetList(true) 
                            end} --todo
                    },
                    Chili.Checkbox:New{caption='Allow User Widgets',x=0,y=34,width='100%',textalign='left',boxalign='right',checked=widgetHandler.allowUserWidgets,
                        OnChange = {function() Spring.SendCommands("luaui toggle_user_widgets") end}
                    },
                    Chili.TextBox:New{x='0%',y=51,width='40%',text="Selector mode:",padding={0,3,0,0}},
                    Chili.ComboBox:New{x='40%',y=51,width='60%',
                        items    = {"normal", "advanced"},
                        selected = (Settings.widgetSelectorMode=="advanced" and 2) or 1, 
                        OnSelect = {
                            function(self,sel)
                                Settings.widgetSelectorMode = self.items[sel]
                                if fullyLoaded then 
                                    makeWidgetList(true) 
                                 end 
                            end
                            }
                        },
                }            
            },
            --fixme: shortcuts to cats?
            
            Chili.Line:New{width='40%',y=233},

            Chili.Label:New{caption='-- Skin Settings --',x='2%',width='35%',align = 'center',y=247},
            Chili.Control:New{x='2%', y=272, width='35%',autoSize=true,padding={0,0,0,0},
                children = {
                    Chili.TextBox:New{x='0%',width='40%',text="Colour mode:"},
                    Chili.ComboBox:New{x='40%',width='60%',
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
                    Chili.TextBox:New{y=17, x='0%',width='40%',text="Alpha:"},
                    Chili.ComboBox:New{y=17, x='40%',width='60%',
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
                    Chili.TextBox:New{y=34, x='0%',width='40%',text="Cursor:"},
                    Chili.ComboBox:New{y=34, x='40%',width='60%',
                        items    = {"dynamic", "static"},
                        selected = (Settings["Cursor"]=="dynamic" and 1) or (Settings["Cursor"]=="static" and 2),
                        OnSelect = {
                            function(self,sel)
                                if sel==1 then SetCursor("bar") 
                                elseif sel==2 then SetCursor("static")
                                end
                            end
                            }
                        },
                    }, 
                            
            },    

            Chili.Button:New{x='5%',bottom='5%',width='30%',height=30,caption="Reset Settings",
                OnClick ={function() Spring.SendCommands("luaui reset") end},            
            }
        }
    }
    
    updateWidgetListPos = true
end

local function CreateGraphicsTab()
    -- Graphics --
    tabs.Graphics = Chili.Control:New{x = 0, y = 20, bottom = 20, width = '100%', borderColor = {0,0,0,0}, backgroundColor = {0,0,0,0},
        children = {
            Chili.ScrollPanel:New{name='Settings', x=0, y=0, width='100%', height='80%', children = {
                    addStack{x = 0, y = '3%', name = 'EngineSettingsMulti', children = {
                            comboBox{y=0,title='Water',name='Water', 
                                labels={'Basic','Reflective','Dynamic','Refractive','Bump-Mapped'},
                                options={0,1,2,3,4},},
                            comboBox{y=40,title='Shadows',name='Shadows',
                                labels={'Off','On','Units Only'},
                                options={'0','1','2'},},
                            comboBox{y=40,title='Shadow Resolution',name='ShadowMapSize', 
                                labels={'Low','Medium','High'},
                                options={'2048','4096','8192'},},
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
                            checkBox{title = 'Show Map Border', name = 'MapBorder', tooltip = "Set or toggle map border rendering"}, 
                            checkBox{title = 'Vertical Sync', name = 'VSync', tooltip = "Enables/Disables V-sync"},      
                        }                    
                    }
                },
            },
            Chili.Button:New{name="Minimal",x='2.5%',width='30%',y='85%',height='10%',caption='Minimal Settings',OnMouseUp={ApplyMinimalGraphicsSettings}},
            Chili.Button:New{name="Defaults",x='35%',width='30%',y='85%',height='10%',caption='Default Settings',OnMouseUp={ApplyDefaultGraphicsSettings}},
            Chili.Button:New{name="Maximal",x='68.5%',width='30%',y='85%',height='10%',caption='Maximal Settings',OnMouseUp={ApplyMaximalGraphicsSettings}},
        }
    }
    
    --TODO: OnSelect for this tab that reloads options from the springsettings values (in case they have been changed elsewhere by e.g. other widgets whilst ingame)
end


local function CreateCreditsTab()
    createTab{name = 'Credits',
        children = {
            Chili.ScrollPanel:New{width = '70%', x=0, y=0, bottom=0,
                children = {Chili.TextBox:New{width='100%',text=credits}}
            }
        }-- TODO: find a logo and a place for it!
    }
end

local function AddTab(tab,control,tabWidth)
    -- Adds a chili control as a menu tab
    --  if tab doesn't exist, it is created
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
    Menu.ShowHide = ShowHide -- show/hide menu tabs

    Menu.AddTab = AddTab -- for adding new tabs e.g. the end-graph widget
    --  usage is Menu.AddControl('nameOfTab', controlToBeAdded)
    
    Menu.AddWidgetOption  = AddWidgetOption -- for registering options of widgets (note: ideally, widgets are responsible for save/load of their own options)
    --[[
        -- Example usage for AddWidgetOption(obj)
        obj = {
            name = widget:GetInfo().name, -- **required**
            children = {
                Chili.Checkbox:New{caption='An Option', x='0%', width='100%', checked=<initial value from widget>, OnChange={function() <effect of changing option in widget>; end}},
                Chili.Checkbox:New{caption='Another Option', x='0%', width='100%', checked=<initial value from widget>, OnChange={function() <effect of changing option in widget>; end}},
            }
        }                
    ]]
    
    WG.MainMenu = Menu
end



--------------------------
-- main

function widget:Initialize()
    Chili = WG.Chili
    
    InitSettings()
    SetCursor(Settings['cursorName'])

    loadMainMenu()
    CreateGeneralTab()
    CreateGraphicsTab()
    CreateInterfaceTab()
    CreateCreditsTab()
        
        
    if amNewbie then ShowHide('General') else menuTabs:Select(Settings.tabSelected or 'General') end
    globalize()
    
    makeWidgetList(true)
    
    -- our hotkeys
    local toggleMenu      = function() if mainMenu.visible then ShowHide() else ShowHide('General') end end
    local toggleInterface = function() ShowHide('Interface') end
    local toggleGraphics  = function() ShowHide('Graphics') end
    local toggleIntro     = function() ShowHide('General'); SetInfoChild(tabs.General:GetChildByName("Introduction Button")) end --small hack

    spSendCommands('unbindkeyset f11')
    spSendCommands('unbindkeyset Any+i gameinfo')
    spSendCommands('unbind S+esc quitmenu','unbind esc quitmessage')
    widgetHandler.actionHandler:AddAction(widget,'toggleGraphics', toggleGraphics, nil, 't')
    widgetHandler.actionHandler:AddAction(widget,'toggleInterface', toggleInterface, nil, 't')
    widgetHandler.actionHandler:AddAction(widget,'hideMenu', hideMenu, nil, 't')
    widgetHandler.actionHandler:AddAction(widget,'toggleMenu', toggleMenu, nil, 't')
    widgetHandler.actionHandler:AddAction(widget,'toggleIntro', toggleIntro, nil, 't')
    spSendCommands('bind Any+esc toggleMenu')
    spSendCommands('bind f10 toggleGraphics')
    spSendCommands('bind f11 toggleInterface')
    spSendCommands('bind i toggleIntro')
    
    fullyLoaded = true
end

function widget:Update()
    -- check if any widgets changed enabled/active state
    if widgetHandler.knownChanged then
        widgetHandler.knownChanged = false -- important note: widgetHandler.knownChanged=true was added by us to the widgetHandler, when a widget crashes (selector.lua polls each Drawframe)
        makeWidgetList()
    end
    
    if Settings.visibleAtShutdown then
        ShowHide()
        Settings.visibleAtShutdown = false
    end

    
    if updateWidgetListPos then
        if Settings["widgetScroll"] then 
            local success = SetTopVisibleControlOfWidgetList(Settings["widgetScroll"])
            if success then -- we have to wait for chili to actually set up the y coords and it sometimes waits...
                updateWidgetListPos = nil
            end
        else
            updateWidgetListPos = nil        
        end    
    end
end

function widget:Shutdown()
    spSendCommands('unbind i toggleIntro')
    spSendCommands('unbind Any+esc toggleMenu')
    spSendCommands('unbind f10 toggleGraphics')
    spSendCommands('unbind f11 toggleInterface')
    spSendCommands('bind f11 luaui selector') -- if the default one is removed or crashes, then have the backup one take over
    spSendCommands('bind Any+i gameinfo')
end

-----------------------------
-- config data 

function widget:GetConfigData()
    if fullyLoaded then
        Settings.widgetScroll = GetTopVisibleControlOfWidgetList()
        Settings.visibleAtShutdown = mainMenu.visible
        if Settings.tabSelected == 'Beta Release' then -- hack
            Settings.visibleAtShutdown = nil
        end
    end
    
    return Settings
end

function widget:SetConfigData(data)
    if (data and type(data) == 'table') then
        Settings = data
    end
end


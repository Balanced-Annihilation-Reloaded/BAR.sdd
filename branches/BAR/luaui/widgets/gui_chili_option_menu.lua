function widget:GetInfo()
 return {
  name    = "BAR's Main Menu",
  desc    = "v0.1 of Graphics, Interface, and Sound Options Menu (WIP)",
  author  = "Funkencool",
  date    = "2013",
  license   = "GNU GPL, v2 or later",
  layer    = -1000000,
  handler  = true,
  enabled   = true
 }
end

local spSendCommands = Spring.SendCommands
local spSetConfigInt = Spring.SetConfigInt
local spGetConfigInt = Spring.GetConfigInt
local spgetFPS       = Spring.GetFPS
local spGetTimer     = Spring.GetTimer

local Chili, mainMenu, menuTabs,timeLbl,fpsLbl ,menuBtn,minMenu,oTime
local barSettings = {}
-- Defaults ---
 barSettings.searchWidgetDesc=true
 barSettings.searchWidgetAuth=true
 barSettings.searchWidgetName=true
 barSettings.widget = {}
 barSettings.UIwidget = {}
------------------------------------
local menuVisible = false
local widgetList = {}
local tabs = {}
local changelog = 
[[ (for future when it matters) 
 Example ChangeLog:
 7.61 -> 7.62
11/29/11:

-Better handling for most units with turninplace
-Fix t1 destroyer bad handling (by reverting to old behaivour, a combo of …
-Torpedoes no longer hit hovers
-Fix the Dominator hack
-Added ability for maps to override engine start positions. Thanks zwzsg
-Add Updated air release gadget and new airlab fix gadget , and cmd_lstpos …
-Fix problem with armbrtha hitsphere
-Updated Dynamic Collision Volume gadget to support dynamic per piece …
-Update mex snap Widget
-Viper and Pitbull script fix (thanks KingRaptor and Juzza)]]

local wCategories = {
 {cat = "api"      , label = "For Developers", list = {}, },
 {cat = "camera"   , label = "Camera"        , list = {}, },
 {cat = "cmd"      , label = "Commands"      , list = {}, },
 {cat = "dbg"      , label = "For Developers", list = {}, },
 {cat = "gfx"      , label = "Effects"       , list = {}, }, 
 {cat = "gui"      , label = "GUI"           , list = {}, },
 {cat = "hook"     , label = "Commands"      , list = {}, },
 {cat = "ico"      , label = "GUI"           , list = {}, },
 {cat = "init"     , label = "Initialization", list = {}, },
 {cat = "map"      , label = "Map"           , list = {}, },
 {cat = "minimap"  , label = "Minimap"       , list = {}, },
 {cat = "mission"  , label = "Mission"       , list = {}, },
 {cat = "snd"      , label = "Sound"         , list = {}, },
 {cat = "test"     , label = "For Developers", list = {}, },
 {cat = "unit"     , label = "Units"         , list = {}, },
 {cat = "ungrouped", label = "Ungrouped"     , list = {}, }
 }

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

local function groupWidget(name,wData)
 local _, _, category = string.find(wData.basename, "([^_]*)")
 if category then
  for i=1,#wCategories do
   if category and category == wCategories[i].cat then wCategories[i].list[#wCategories[i].list+1] = {name = name,wData = wData} end
  end
 else
  local list = wCategories[#wCategories].list
  list[#list+1] = {name = name,wData = wData}
  wCategories[#wCategories].list = list
 end
end

local function sortWidgetList(filter)
 local filter = filter or ""
 for name,wData in pairs(widgetHandler.knownWidgets) do
  if ((barSettings.searchWidgetName and string.find(string.lower(name), string.lower(filter)))
  or (barSettings.searchWidgetDesc and string.find(string.lower(wData.desc), string.lower(filter)))
  or (barSettings.searchWidgetAuth and string.find(string.lower(wData.author), string.lower(filter)))) then
   groupWidget(name,wData)
  end
 end
end

local function makeWidgetList(filter)
 sortWidgetList(filter)
 local widgetNum = 0
 local control = tabs["Interface"]
 local scrollpanel = control:GetObjectByName("widgetList")
 scrollpanel:ClearChildren()
 for a=1,#wCategories do
  local list = wCategories[a].list
  if #list>0 then 
   widgetNum = widgetNum + 1
   Chili.Label:New{parent = scrollpanel,caption = '- '..wCategories[a].label..' -', y = widgetNum*20-10, align = 'center',x=0,width = '100%',autosize=false}
   widgetNum = widgetNum + 1
   for b=1,#list do
    local enabled = (widgetHandler.orderList[list[b].name] or 0)>0
    local fontColor
    if enabled then fontColor = {color = {0.5,1,0,1}, outlineColor = {0.5,1,0,0.2}}
    else fontColor = {color = {1,0.5,0,1}, outlineColor = {1,0.5,0,0.2}} end
    Chili.Checkbox:New{
     name      = list[b].name,
     caption   = list[b].name,
     parent    = scrollpanel,
     tooltip   = 'By '..list[b].wData.author.. ")\n"..list[b].wData.desc or '',
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

local function showHide()
 if mainMenu then mainMenu:ToggleVisibility() end
end

local function sTab(_,tabName)
  if barSettings.tabSelected then mainMenu:RemoveChild(tabs[barSettings.tabSelected]) end
  mainMenu:AddChild(tabs[tabName])
  barSettings.tabSelected = tabName
end

local function addFilter() 
 local control = tabs["Interface"]
 local editbox = control:GetObjectByName("widgetFilter")
 makeWidgetList(editbox.text)
 editbox:SetText("")
end

local function chngSkin()
 local control = tabs["Interface"]
 local editbox = control:GetObjectByName("skin")
 Chili.theme.skin.general.skinName = editbox.text
 barSettings.chiliSkin = editbox.text
 spSendCommands("luaui reload")
end

local function loadMainMenu()
 mainMenu = Chili.Window:New{parent=Chili.Screen0,x = 400, y = 200, width = 500, height = 400,padding = {5,8,5,5}, draggable = true,
  children = {
   Chili.Line:New{parent = mainMenu,y = 15,width = "100%"},
   Chili.Line:New{parent = mainMenu,bottom = 20,width = "100%"},
   Chili.Button:New{caption = "Resign and Spectate",height = 20,width = '25%',x = 20,bottom=0,
    OnMouseUp = {function() spSendCommands{"Spectator"};showHide() end }},
   Chili.Button:New{caption = "Exit To Desktop",height = 20,width = '25%',right = 20,bottom=0,
     OnMouseUp = {function() spSendCommands{"quit","quitforce"} end }},
  }}
 
 menuTabs = Chili.TabBar:New{parent = mainMenu, x = 0, width = '100%', y = 0, height = 20, minItemWidth = 70,selected=barSettings.tabSelected or 'Info',
  tabs = {"Info","Interface", "Graphics", "Sound"}, OnChange = {sTab}}
   
 showHide()
end

local function loadMinMenu()
 timeLbl = Chili.Label:New{caption = "10:30pm", x = 0}
 fpsLbl = Chili.Label:New{caption = "FPS: 65",x = 70}
 menuBtn = Chili.Button:New{caption = 'Menu', right = 0, height = '100%', width = 50, Onclick = {showHide}}
 minMenu = Chili.Window:New{parent=Chili.Screen0,right = 210, y = 20, width = 180,minheight = 20, height = 20,padding = {5,0,0,0},children = {timeLbl,fpsLbl,menuBtn}}
end

local function addComBox(tab,vert,caption,name,items,rItems,showLine)
 local control = tabs[tab]
 local selected = barSettings[name]
 if showLine then control:AddChild(Chili.Line:New{y=vert-4,width='50%'}) end
 control:AddChild(Chili.Label:New{caption = caption,y = vert,height=20,right=378})
 control:AddChild(Chili.ComboBox:New{name = name,y = vert,right = 250,width = 125,height=26,items = items,rItems = rItems, selected = selected,
  OnSelect = {function(_,boxNum) spSetConfigInt(name,rItems[boxNum]);barSettings[name] = boxNum end}})
  -- OnSelect = {function(_,boxNum) spSendCommands(name.." "..rItems[boxNum]);barSettings[name] = boxNum end}})
end

local function addPlayerList()
 -- local list = Spring.GetPlayerRoster()
 -- for i=1,#list do
  -- for name,data in pairs(list[i]) do Spring.Echo(name,data) end
  -- local r,g,b = Spring.GetTeamColor(list[i][3])
  -- local label = Chili.Label:New{parent=tabs.Info,x='70%',y=20*i+20,font={color = {r,g,b,1}}, caption = list[i][1]}
 -- end
end
-----OPTIONS-----------------
-----------------------------
local function Options()
-- Each tab has its own control {Info,Interface,Graphics, and Sound}
--  Each graphical element is defined as a child of these controls and given a function to fullfill, when a certain even happens(i.e. OnClick)
 
-- Graphics --
 tabs.Graphics = Chili.Control:New{x = 0, y = 20, bottom = 20, width = '100%', 
 children = {}}
 -- addComBox('Graphics', 0  , "Water    ", "ReflectiveWater", {"Basic","Reflective","Dynamic","Refractive","Bump-Mapped"}, {0,1,2,3,4})
 -- addComBox('Graphics', 30 , "-Reflection", "BumpWaterReflection", {"Off","Performance","Full"}, {0,1,2})
 -- addComBox('Graphics', 60 , "-Refraction", "BumpWaterRefraction", {"Off","Performance","Full"}, {0,1,2})
 -- addComBox('Graphics', 90 , "Shadows   ", "Shadows", {"Off","Fast","Full"}, {0,2,1},true)
 -- addComBox('Graphics', 120, "-Resolution", "ShadowMapSize", {"Low","Medium","High"}, {1024,2048,4096})
 -- addComBox('Graphics', 150, "-SmoothLines-", "SmoothLines", {"Safe","Performance","Balanced","Power"}, {0,1,2,3},true)
 -- addComBox('Graphics', 180, "-SmoothPoints-", "SmoothPoints", {"Safe","Performance","Balanced","Power"}, {0,1,2,3})
 -- addComBox('Graphics', 210, "-FSAA", "FSAALevel", {"Safe","Performance","Balanced","Power"}, {0,2,4,8})
 -- addComBox('Graphics', 30, "-Shadows-", "Shadows", {"Low","Medium","High"}, {"3 1024","3 2048","3 4096"},true)
 
-- Interface --
 tabs.Interface = Chili.Control:New{x = 0, y = 20, bottom = 20, width = '100%', --Control attached to tab
 children = {
  Chili.ScrollPanel:New{name="widgetList",x = '50%',y = 0,right = 0,bottom = 0},
  Chili.EditBox:New{name="widgetFilter",x=0,y=0,width = '50%',text=''},
  Chili.Button:New{right='50%',y=20,height=24,width='15%',caption='Filter',OnMouseUp={addFilter}},
  Chili.Checkbox:New{caption="Search Widget Name",x=0,y=40,width='35%',textalign="left",boxalign="right",checked=barSettings.searchWidgetName,
   OnChange = {function() barSettings.searchWidgetName = not barSettings.searchWidgetName end}}, 
  Chili.Checkbox:New{caption="Search Description",x=0,y=20,width='35%',textalign="left",boxalign="right",checked=barSettings.searchWidgetDesc,
   OnChange = {function() barSettings.searchWidgetDesc = not barSettings.searchWidgetDesc end}},
  Chili.Checkbox:New{caption="Search Author",x=0,y=60,width='35%',textalign="left",boxalign="right",checked=barSettings.searchWidgetAuth,
   OnChange = {function() barSettings.searchWidgetAuth = not barSettings.searchWidgetAuth end}},
  Chili.Line:New{width='50%',y=80},
  Chili.EditBox:New{name='skin',x=0,y=90,width='50%',text=''},
  Chili.Button:New{right='50%',y=110,height=24,width='20%',caption='Change Skin',OnMouseUp={chngSkin}},
--  Chili.Button:New{right='75%',y=150,height=24,width='25%',caption='Chili Globals',OnMouseUp={getGlobals}},
 }}
 
-- Info --
 tabs.Info = Chili.Control:New{x = 0, y = 20, bottom = 20, width = '100%', 
 children = {
  Chili.Label:New{caption="-- Recent Changes --",x='0%',width="70%",align = 'center'},
  Chili.ScrollPanel:New{width = '70%', x=0, y=20, bottom=0, children ={Chili.TextBox:New{width='100%',text=changelog}}},
 }}  

-- Sound --
 tabs.Sound = Chili.Control:New{x = 0, y = 20, bottom = 20, width = '100%', children = {
  Chili.Label:New{caption = "Master Volume:",},
  Chili.Trackbar:New{x = 120,height = 15,right = '50%',value = spGetConfigInt("snd_volmaster"),
   OnChange = { function(self) spSendCommands{"set snd_volmaster " .. self.value} end },},
  Chili.Label:New{caption = "General Volume:",y = 20},
  Chili.Trackbar:New{x = 120,y = 20,height = 15,right = '50%',value = spGetConfigInt("snd_volgeneral"),
   OnChange = { function(self) spSendCommands{"set snd_volgeneral " .. self.value} end },},
  Chili.Label:New{caption = "Music Volume:",y = 40},
  Chili.Trackbar:New{x = 120,y = 40,height = 15,right = '50%',value = spGetConfigInt("snd_volmusic"),
   OnChange = { function(self) spSendCommands{"set snd_volmusic " .. self.value} end },},
 }}

end
-----------------------------
-----------------------------
-- function widget:GetConfigData()
 -- if barSettings ~= WG.barSettings then 
 -- for name,data in pairs(barsettings) do
  -- WG.barSettings[name] = data
 -- end
 -- end
 -- return barSettings
-- end

-- function widget:SetConfigData(data)
 -- if (data and type(data) == 'table') then 
 -- WG.barSettings = data 
-- -- Localize global 
 -- barSettings = WG.barSettings
-- -- Defaults ---
 -- barSettings.searchWidgetDesc=true
 -- barSettings.searchWidgetAuth=true
 -- barSettings.searchWidgetName=true
 -- barSettings.widget = {}
 -- barSettings.UIwidget = {}
-- --------------------------------
 -- end
-- end
function widget:DrawScreen()
 local fps = 'FPS: '..'\255\255\127\0'..spgetFPS()
 fpsLbl:SetCaption(fps)
 local rTime = os.date("%I:%M %p")
 if oTime ~= rTime then
  oTime = rTime
  if string.find(rTime,'0')==1 then rTime = string.sub(rTime,2) end
  timeLbl:SetCaption('\255\255\127\0'..string.lower(rTime))
 end
end

function widget:KeyPress(key,mod)
 local control = tabs["Interface"]
 local editbox = control:GetObjectByName("widgetFilter")
 if key==13 and editbox.state.focused then
  makeWidgetList(editbox.text)
  editbox:SetText("")
  return true
 elseif key==292 then
  showHide()
  menuTabs:Select('Interface')
  return true
 elseif key==27 then
  showHide()
  menuTabs:Select('Info')
  return true
 -- elseif key==
 end
end

function widget:Initialize()
 Chili = WG.Chili
 Chili.theme.skin.general.skinName = barSettings.chiliSkin or 'Flat'
 Options()
 makeWidgetList()
 loadMainMenu()
 loadMinMenu()
 addPlayerList()
end
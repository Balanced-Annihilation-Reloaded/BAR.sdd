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
local changelog = VFS.LoadFile('changelog.txt')
if changelog == '' then changelog = "changelog is blank, normally this would read the changelog.txt in the games base directory" end

local cursorNames = {
  'cursornormal','cursorareaattack','cursorattack','cursorattack','cursorbuildbad',
  'cursorbuildgood','cursorcapture','cursorcentroid','cursordwatch','cursorwait',
  'cursordgun','cursorattack','cursorfight','cursorattack','cursorgather','cursorwait',
  'cursordefend','cursorpickup','cursormove','cursorpatrol','cursorreclamate',
  'cursorrepair','cursorrevive','cursorrepair','cursorrestore','cursorrepair',
  'cursorselfd','cursornumber','cursorwait','cursortime','cursorwait','cursorunload','cursorwait',
}

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
----------------------------
local function setCursor(cursorSet)
 for i=1, #cursorNames do
  local topLeft = (cursorNames[i] == 'cursornormal' and cursorSet ~= 'k_haos_girl')
  if cursorSet == 'ba' then Spring.ReplaceMouseCursor(cursorNames[i], cursorNames[i], topLeft)
  else Spring.ReplaceMouseCursor(cursorNames[i], cursorSet.."/"..cursorNames[i], topLeft) end
 end
end
----------------------------
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
----------------------------
local function sortWidgetList(filter)
 local filter = filter or ""
 for name,wData in pairs(widgetHandler.knownWidgets) do
  if ((barSettings.searchWidgetName and string.find(string.lower(name), string.lower(filter)))
  or (barSettings.searchWidgetDesc and string.find(string.lower(wData.desc), string.lower(filter)))
  or (barSettings.searchWidgetAuth and string.find(string.lower(wData.author), string.lower(filter)))) then
   groupWidget(name,wData)
  end
  for i=1,#wCategories do
   local ascending = function(a,b) return a.name<b.name end
   table.sort(wCategories[i].list,ascending)
  end
 end
end
----------------------------
local function makeWidgetList(filter)
 sortWidgetList(filter)
 local widgetNum = 0
 local scrollpanel = tabs["Interface"]:GetObjectByName("widgetList")
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
     tooltip   = 'Author: '..list[b].wData.author.. "\n"..list[b].wData.desc or '',
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
local function showHide(tab)
 if mainMenu then mainMenu:ToggleVisibility() end
 if tab then menuTabs:Select(tab) end
end
----------------------------
local function sTab(_,tabName)
  if barSettings.tabSelected then mainMenu:RemoveChild(tabs[barSettings.tabSelected]) end
  mainMenu:AddChild(tabs[tabName])
  barSettings.tabSelected = tabName
end
----------------------------
local function addFilter()
 local editbox = tabs["Interface"]:GetObjectByName("widgetFilter")
 makeWidgetList(editbox.text)
 editbox:SetText("")
end
----------------------------
local function loadMainMenu()
 mainMenu = Chili.Window:New{parent=Chili.Screen0,x = 400, y = 200, width = 500, height = 400,padding = {5,8,5,5}, draggable = true,
  children = {
   Chili.Line:New{parent = mainMenu,y = 15,width = "100%"},
   Chili.Line:New{parent = mainMenu,bottom = 20,width = "100%"},
   Chili.Button:New{caption = "Resign and Spectate",height = 20,width = '25%',x = '15%',bottom=0,
    OnMouseUp = {function() spSendCommands{"Spectator"};showHide() end }},
   Chili.Button:New{caption = "Exit To Desktop",height = 20,width = '25%',right = '15%',bottom=0,
     OnMouseUp = {function() spSendCommands{"quit","quitforce"} end }},
  }}

 menuTabs = Chili.TabBar:New{parent = mainMenu, x = 0, width = '100%', y = 0, height = 20, minItemWidth = 70,selected=barSettings.tabSelected or 'Info',
  tabs = {"Info","Interface", "Graphics", "Sound", "Log"}, itemPadding = {1,0,1,0},OnChange = {sTab}}

 showHide()
end
----------------------------
local function loadMinMenu()
 timeLbl = Chili.Label:New{caption = "10:30pm", x = 0}
 fpsLbl = Chili.Label:New{caption = "FPS: 65",x = 70}
 menuBtn = Chili.Button:New{caption = 'Menu', right = 0, height = '100%', width = 50, Onclick = {showHide}}
 minMenu = Chili.Window:New{parent=Chili.Screen0,right = 210, y = 20, width = 180,minheight = 20, height = 20,padding = {5,0,0,0},children = {timeLbl,fpsLbl,menuBtn}}
end
----------------------------
local function applySetting(self)
 local editbox = self.parent.childrenByName['EditBox']
 if self.parent.name == 'Skin' then Chili.theme.skin.general.skinName = editbox.option; Spring.Echo("To see skin changes; \"/luaui reload\"")
 elseif self.parent.name == 'Cursor' then setCursor(editbox.option)
 else spSendCommands(self.parent.name.." "..editbox.option) end
 barSettings[self.parent.name] = editbox.option
 self.font.color = {0.5,0.5,0.5,1}
 self:Invalidate()
end
----------------------------
local comboBox = function(obj)
 local obj=obj
 local comboBox = Chili.Control:New{name=obj.name,parent=tabs[obj.parent],y=obj.y,width='50%',bottom=0,x=0}

 local OnSelect = function(self)
  local box = comboBox.childrenByName['EditBox']
  local button = comboBox.childrenByName['Button']
  button.font.color = {1,1,1,1}
  box.text = self.caption
  box.option = self.option
  box:Invalidate()
  button:Invalidate()
 end

 if not obj.options then obj.options=obj.labels end

 local dropdown = function(self)
  if not self.opened then
  
   -- local ddWindow = Chili.Window:New{name='ddWindow',padding={0,0,0,0},x='10%',y=35,height=#obj.labels*20+16,width = '70%',}
   local x,y = comboBox:ClientToScreen(25,35)
   comboBox.ddWindow = Chili.Window:New{name='ddWindow',padding={0,0,0,0},x=x,y=y,height=#obj.labels*21+16,width=150,}

   for i=1, #obj.labels do
    local checked = (barSettings[obj.name] == obj.labels[i])
    comboBox.ddWindow:AddChild(Chili.Checkbox:New{x='5%',width='90%',option=obj.options[i],caption=obj.labels[i],height=20,y=21*(i-1)+8,checked=checked,OnChange={OnSelect}})
   end

   Chili.Screen0:AddChild(comboBox.ddWindow)
   comboBox.ddWindow:BringToFront()
   -- combobox:AddChild(ddWindow)
   self.opened = true
  else
   comboBox.ddWindow:Dispose()
   self.opened = false
  end
  self:Invalidate()
  self.parent:Invalidate()
 end
 comboBox:AddChild(Chili.Label:New{x=10,y=0,caption=obj.name})
 comboBox:AddChild(Chili.EditBox:New{name='EditBox',x='10%',y=15,width='70%',text='',OnFocusUpdate={dropdown},})
 comboBox:AddChild(Chili.Button:New{name='Button',y=15,right=0,height=20,width='20%',caption='Apply',font={color={0.5,0.5,0.5,1}},OnMouseUp={applySetting}})
end

local incDec = function(obj)
 local incDec = Chili.Control:New{name=obj.name,parent=tabs[obj.parent],y=obj.y,width='50%',height=30,right=0,padding={0,0,0,0}}
 local decOption = function(self)
  spSendCommands('luaui -'..self.parent.name)
 end
 local incOption = function(self)
  spSendCommands('luaui +'..self.parent.name)
 end
 incDec:AddChild(Chili.Label:New{right=65,y=0,caption=obj.label})
 incDec:AddChild(Chili.Button:New{right=0,y=0,width=30,height=20,caption='Inc',OnMouseUp={incOption}})
 incDec:AddChild(Chili.Button:New{right=30,y=0,width=30,height=20,caption='Dec',OnMouseUp={decOption}})
end

-----OPTIONS-----------------
-----------------------------
local function Options()
-- Each tab has its own control {Info,Interface,Graphics, and Sound}
-- mainMenu = Chili.Window:New{parent=Chili.Screen0,x = 400, y = 200, width = 500, height = 400,padding = {5,8,5,5}, draggable = true,
--  Each graphical element is defined as a child of these controls and given a function to fullfill, when a certain event happens(i.e. OnClick)

-- Graphics --
 tabs.Graphics = Chili.Control:New{x = 0, y = 20, bottom = 20, width = '100%',
  children = {
   Chili.Line:New{right='40%',height='100%',style='vertical'},
   Chili.Line:New{x='50%',right=0,y=160},
   Chili.Label:New{x='55%',y=10,caption='Bloom Options'},
   Chili.Checkbox:New{caption="Dilate Pass",x='80%',y=20,right=0,textalign="left",boxalign="right",checked=false, 
    OnChange = {function(self) if not self.checked then spSendCommands('luaui +dilatepass') else spSendCommands('luaui -dilatepass') end  end}}, 
   Chili.Checkbox:New{caption="Debug Mode",x='80%',y=40,right=0,textalign="left",boxalign="right",checked=false, 
    OnChange = {function(self) if not self.checked then spSendCommands('luaui +bloomdebug') else spSendCommands('luaui -bloomdebug') end  end}}, 
   -- Chili.Checkbox:New{caption="Search Author",x='50%',y=120,width='35%',textalign="left",boxalign="right",OnChange={}},
   }}
   
   comboBox{parent='Graphics',name="Water",y=0,
    labels={"Basic","Reflective","Dynamic","Refractive","Bump-Mapped"},
    options={0,1,2,3,4},}
   comboBox{parent='Graphics',name="Shadows",y=40,
    labels={"Off","Very Low","Low","Medium","High","Very High"},
    options={"0","2 1024","2 2048","1 1024","1 2048","1 4096"},}
   incDec{parent='Graphics',name='illumthres',y=60,label='Illumination Threshold'}
   incDec{parent='Graphics',name='glowamplif',y=85,label='Glow Amplifier'}
   incDec{parent='Graphics',name='bluramplif',y=110,label='Blur Amplifier'}
   incDec{parent='Graphics',name='blurpasses',y=135,label='Blur Passes'}

-- Interface --
 tabs.Interface = Chili.Control:New{x = 0, y = 20, bottom = 20, width = '100%', --Control attached to tab
  children = {
   Chili.ScrollPanel:New{name="widgetList",x = '50%',y = 0,right = 0,bottom = 0},
   Chili.EditBox:New{name="widgetFilter",x=0,y=0,width = '35%',text=' Enter filter -> Hit Return,  or -->',OnMouseDown = {function(obj) obj.text = '' end}},
   Chili.Button:New{right='50%',y=0,height=20,width='15%',caption='Search',OnMouseUp={addFilter}},
   Chili.Checkbox:New{caption="Search Widget Name",x=0,y=40,width='35%',textalign="left",boxalign="right",checked=barSettings.searchWidgetName,
    OnChange = {function() barSettings.searchWidgetName = not barSettings.searchWidgetName end}},
   Chili.Checkbox:New{caption="Search Description",x=0,y=20,width='35%',textalign="left",boxalign="right",checked=barSettings.searchWidgetDesc,
    OnChange = {function() barSettings.searchWidgetDesc = not barSettings.searchWidgetDesc end}},
   Chili.Checkbox:New{caption="Search Author",x=0,y=60,width='35%',textalign="left",boxalign="right",checked=barSettings.searchWidgetAuth,
    OnChange = {function() barSettings.searchWidgetAuth = not barSettings.searchWidgetAuth end}},
   Chili.Line:New{width='50%',y=80},
  }}
   comboBox{parent='Interface',name='Skin',y=90,
    labels={'Flat','Robocracy','Carbon','DarkHive'}}
   comboBox{parent='Interface',name='Cursor',y=125,
    labels={'Default','ZK Animated','ZK Static','CA Classic','CA Static','Erom','Masse','Lathan','K_haos_girl'},
    options={'ba','zk','zk_static','ca','ca_static','erom','masse','Lathan','k_haos_girl'}}

-- Info --
 tabs.Info = Chili.Control:New{x = 0, y = 20, bottom = 20, width = '100%',
  children = {
   Chili.Label:New{caption="-- Recent Changes --",x='0%',width="70%",align = 'center'},
   Chili.ScrollPanel:New{width = '70%', x=0, y=20, bottom=0, children ={Chili.TextBox:New{width='100%',text=changelog}}},
  }}

-- Sound --
 tabs.Sound = Chili.Control:New{x = 0, y = 20, bottom = 20, width = '100%',
  children = {
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

-- Log --
 tabs.Log = Chili.Control:New{x = 0, y = 20, bottom = 20, width = '100%',
  children = {
   Chili.ScrollPanel:New{x=0,y=0,right=0,bottom=0,name="mLog",children = {Chili.TextBox:New{x=0,y=0,right=0,bottom=0,}}}
  }}

end
-----------------------------
-----------------------------
function widget:GetConfigData()
 return barSettings
end

function widget:SetConfigData(data)
 if (data and type(data) == 'table') then
  barSettings = data
 end
end

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
 local editbox = tabs["Interface"]:GetObjectByName("widgetFilter")
 if key==13 and editbox.state.focused then
  makeWidgetList(editbox.text)
  editbox:SetText("")
  return true
 end
end
--------------------------
function widget:Initialize()
 Chili = WG.Chili
 Chili.theme.skin.general.skinName = barSettings.Skin or 'Flat'
 setCursor(barSettings['Cursor'] or 'ba')
 Options()
 makeWidgetList()
 loadMainMenu()
 loadMinMenu()
 local buffer = Spring.GetConsoleBuffer()
 for i=1,#buffer do
  widget:AddConsoleMessage(buffer[i])
 end
 
--------------------------
----- Shortcuts
 local openMenu = function() showHide('Info') end
 local openWidgets = function() showHide('Interface') end
 local openLog = function() showHide('Log') end
 local hideMenu = function() if mainMenu.visible then mainMenu:Hide() end end
 
 spSendCommands("unbindkeyset f11")
 spSendCommands("unbind S+esc quitmenu","unbind esc quitmessage")
 widgetHandler.actionHandler:AddAction(widget,"openMenu", openMenu, nil, "t")
 widgetHandler.actionHandler:AddAction(widget,"openWidgets", openWidgets, nil, "t")
 widgetHandler.actionHandler:AddAction(widget,"hideMenu", hideMenu, nil, "t")
 spSendCommands("bind S+esc openMenu")
 spSendCommands("bind f11 openWidgets")
 spSendCommands("bind esc hideMenu")
 -- widgetHandler.actionHandler:AddAction("openLog", openLog, nil, "t")
 -- spSendCommands("bind hotkey openLog")
end
--------------------------
function widget:Shutdown()
 spSendCommands("unbind S+esc openMenu")
 spSendCommands("unbind f11 openWidgets")
 spSendCommands("unbind esc hideMenu")
end
--------------------------
local mLogText = ''
function widget:AddConsoleMessage(msg)
 if tabs.Log then
  mLogText = mLogText..msg.text..'\n'
  local scrollpanel = tabs["Log"]:GetObjectByName("mLog")
  scrollpanel.children[1].text = mLogText
  scrollpanel.children[1]:UpdateLayout()
 end
end

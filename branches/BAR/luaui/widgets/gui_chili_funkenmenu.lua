-- Version 0.6
function widget:GetInfo()
 return {
  name      = "BAR's funken build Menu",
  desc      = "Shiny new Command/Build Menu",
  author    = "Funkencool",
  date      = "2013",
  license     = "GNU GPL v2",
  layer      = math.huge,
  enabled    = true,
  handler    = true,
 }
end
-- Includes
local strategic_commands, econ_commands, ignore_commands = include("Configs/BuildMenu.lua")
-----------

local Chili
local panH, panW, winW
local menuBackground, menuTabs, panel0, stateWindow, scroll0, menuTab, buildQueue, idx, screen0,menuBackground
local menuPanel = {}
local menu = {}
local names = {"ORDER","BUILD"," TACT","  ECON"}
local activeWindows = {false,false,false,false}
----------------
local imageDir = 'LuaUI/Images/commands/'
local updateRequired = true
local menuChoice = 2
local selectedUnits = {}

local spGetActiveCommand  = Spring.GetActiveCommand
local spSetActiveCommand  = Spring.SetActiveCommand
local spGetActiveCmdDesc  = Spring.GetActiveCmdDesc
local spGetActiveCmdDescs = Spring.GetActiveCmdDescs
local spGetSelectedUnits  = Spring.GetSelectedUnits
local spSendCommands      = Spring.SendCommands
local spGetCmdDescIndex   = Spring.GetCmdDescIndex
local spGetFullBuildQueue = Spring.GetFullBuildQueue


---------------------------
                         --
function LayoutHandler(xIcons, yIcons, cmdCount, commands)
 widgetHandler.commands   = commands
 widgetHandler.commands.n = cmdCount
 widgetHandler:CommandsChanged()
 local reParamsCmds = {}
 local customCmds = {}

 return "", xIcons, yIcons, {}, customCmds, {}, {}, {}, {}, reParamsCmds, {[1337]=9001}
end
---------------------------
                         --
local function cmdAction(chiliButton, x, y, button, mods) 
 local index = spGetCmdDescIndex(chiliButton.cmdid)
 if (index) then
  local left, right = (button == 1), (button == 3)
  local alt, ctrl, meta, shift = mods.alt, mods.ctrl, mods.meta, mods.shift
  spSetActiveCommand(index, button, left, right, alt, ctrl, meta, shift)
 end
end
--------------------------- Selects tab when tab is clicked or scrolled
                         --  
local function selectTab(self,x,y,up,value,mods)
 menuPanel[menuChoice]:ToggleVisibility()
 --menuTab[menuChoice].hovered = false
 if self.name == 'menuBackground' then
  menuChoice = menuChoice - value
  for i=1,4 do
   if not activeWindows[menuChoice] then menuChoice = menuChoice - value end
   if menuChoice > 4 then menuChoice = 1
   elseif menuChoice < 1 then menuChoice = 4
   end
  end
 else
  menuChoice = self.tabNum
 end
 menuPanel[menuChoice]:ToggleVisibility()
 menuTab[menuChoice].hovered = true
 return true
end
--------------------------- Adds icons/commands to the menu panels accordingly
                         -- 
local function createMenus()
 menuBackground:ClearChildren()
 local button
 local menuNum
 local cmds = spGetActiveCmdDescs()
 
 for i=1,4 do menu[i] = {} end
 
 for i = 1, #cmds do
  local cmd = cmds[i]
  
  if cmd.id >= 0 then                      menuNum = 1
  elseif strategic_commands[cmd.name] then menuNum = 3
  elseif econ_commands[cmd.name] then      menuNum = 4
  else                                     menuNum = 2
  end
  
  if cmd.name ~= "" and not ignore_commands[cmd.action] then
   if menuNum == 1 then
    button = Chili.Button:New{
     cmdname   = cmd.name,
     caption   = string.gsub(cmd.name,"%s+", "\n"),
     tooltip   = cmd.tooltip,
     cmdid     = cmd.id,
     padding   = {0,0,0,0},
     margin    = {0,0,0,0},
     OnMouseUp = {cmdAction},
     font      = {size = 12},
    }
   else    
    button = Chili.Image:New{
     cmdname   = cmd.name,
     tooltip   = cmd.tooltip,
     cmdid     = cmd.id,
     file      = '#'..-cmd.id,
     margin    = {1,1,1,1},
     OnClick = {cmdAction},
     OnMouseOver = {function(self) self.children[1].borderColor={1,1,1,0.5};self.children[1]:Invalidate() end},
     OnMouseOut = {function(self) self.children[1].borderColor={0,0,0,0};self.children[1]:Invalidate() end},
	   OnMouseDown = {function(self) self.color={1,1,1,0.5};self:Invalidate() end},
     OnMouseUp = {function(self) self.color={1,1,1,1};self:Invalidate() end},
     children  = {Chili.Button:New{x=0,y=winW/3-12,height=12,width=30,borderColor={0,0,0,0},caption = UnitDefNames[cmd.name]['metalCost']}}
    }
   end
   if #cmd.params > 1 then button.caption = string.gsub(cmd.params[cmd.params[1] + 2],"%s+", "\n") end
   menu[menuNum][#menu[menuNum]+1] = button
  end
 end

 

 for i=1,#menu do
  menuPanel[i] = Chili.Grid:New{
   name = names[i],
   parent = menuBackground,
   x = 0, right = 0, 
   y = 0, bottom = 0,
   rows = 10, columns= 3,
   padding = {0,0,0,0}, margin = {0,0,0,0},
   children = menu[i],
  }
  if menuChoice ~= i and #menu[i] > 1 then menuPanel[i]:Hide() end
 end
end
--------------------------- Creates a tab for each menu Panel with a command
                         --
local function makeMenuTabs()
 menuTabs:ClearChildren()
 menuTab = {}
 activeWindows = {}
 local tabCount = 0
 local tempMenu = {}
 for i=1, 4 do
  if #menu[i] > 0 then

   activeWindows[i] = true
   
   menuTab[i] = Chili.Button:New{
   tabNum  = i,
   parent  = menuTabs,
   right   = 20+6*i,
   width   = 80-6*i,
   y       = (tabCount) * 41,
   height  = 40,
   caption = names[i],
   OnClick = {selectTab}
   }
   tabCount = tabCount + 1
  end
 end
end
--------------------------- Chooses initial tab when a new unit is selected
                         --
local function chooseTab()
 local tab = {tabNum = 1}
 for i=1, 4 do
  if activeWindows[i] then tab.tabNum = i end
 end
 selectTab(tab)
end
--------------------------- Loads/reloads the icon panels for commands
                         --
local function loadPanels()
 createMenus()
 makeMenuTabs()
 
 local units = spGetSelectedUnits()
 if units[1] and selectedUnits[1] ~= units[1] then
  selectedUnits = units
  chooseTab()
 end
end
--------------------------- Adds icons to queue panel depending on build commands in queue
                         --  or hides it if there are none
local function queueHandler()
 buildQueue:ClearChildren()
 local unitID = Spring.GetSelectedUnits()
 local queueNum
 if unitID[1] then
  local cmd = Spring.GetFactoryCommands(unitID[1])
  if cmd then
   for i=1, #cmd do
    if cmd[i].id < 0 then
     if i == 1 or (i>1 and cmd[i-1].id ~= cmd[i].id) then 
      buildQueue.children[#buildQueue.children+1]=Chili.Image:New{parent=buildQueue, x=45*#buildQueue.children+5, y=5, width =40, height=40, file='#'..-cmd[i].id,cmdid=cmd[i].id, OnClick={cmdAction}}
      buildQueue.children[#buildQueue.children]:AddChild(Chili.Label:New{caption=""})
      queueNum = 1
     else 
      queueNum = queueNum + 1 
     end
     if queueNum > 1 then buildQueue.children[#buildQueue.children].children[1]:SetCaption(""..queueNum) end
    end
   end 
  buildQueue:Resize(45*#buildQueue.children+5)
  end
 end
 if #buildQueue.children < 1 and buildQueue.visible then buildQueue:Hide() 
 elseif #buildQueue.children > 0 and buildQueue.hidden then buildQueue:Show()
 end
end
--------------------------- Iniatilizes main/permanent chili controls 
                         --  These are then shown/hidden when needed
function widget:Initialize()
 widgetHandler:ConfigLayoutHandler(LayoutHandler)
 Spring.ForceLayoutUpdate()
 spSendCommands({"tooltip 0"})
 
 if (not WG.Chili) then
  widgetHandler:RemoveWidget()
  return
 end

 Chili = WG.Chili
 screen0 = Chili.Screen0
 winH = screen0.height * 0.7
 winW = winH * 0.3
 
 menuBackground = Chili.Window:New{
  name = 'menuBackground',
  parent = screen0,
  skinName = 'Flat',
  x = 0, width = winW,
  bottom = 0, height = winH,
  padding = {0,0,0,0},
  OnMouseWheel = {selectTab},
 } 
 menuTabs = Chili.Control:New{
  parent = screen0,
  x = winW, width = 90, 
  bottom = 0, height = winH, 
  padding = {0,0,0,0}, margin = {0,0,0,0}
 }
 buildQueue = Chili.Window:New{
  parent = screen0, 
  x = winW, bottom = 1, 
  width = 20, height = 40, 
  hidden = true,padding = {0,0,0,0}
 }

 
 if WG['blur_api'] then
  WG['blur_api'].UseNoise(true)
  idx = WG['blur_api'].InsertBlurRect(5,screen0.height * 0.7+5,winW-5,5)
 end
end
--------------------------- When Available Commands change this is called
                         --  sets Updaterequired to true
function widget:CommandsChanged()
 updateRequired = true
end
--------------------------- If update is required this Loads the panel and queue for the new unit or hides them if none exists
                         --  There is an offset to prevent the panel dissappearing right after a command has changed (for fast clicking)
function widget:GameFrame(n)
 if updateRequired == true and ((n % 4) < 1) then
    updateRequired = false
  loadPanels()
  queueHandler()
  if not activeWindows[1] and menuBackground.visible then menuBackground:Hide()
  elseif activeWindows[1] and menuBackground.hidden then menuBackground:Show() end
 end
end
---------------------------
                         --
function widget:Shutdown()
 menuBackground:Dispose()
 menuTabs:Dispose()
 buildQueue:Dispose()
 widgetHandler:ConfigLayoutHandler(nil)
 Spring.ForceLayoutUpdate()
 if idx then WG['blur_api'].RemoveBlurRect(idx) end
 spSendCommands({"tooltip 1"})
end
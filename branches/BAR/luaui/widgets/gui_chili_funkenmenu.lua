-- Version 0.6
function widget:GetInfo()
	return {
		name		    = "BAR's funken build Menu",
		desc		    = "Shiny new Command/Build Menu",
		author		  = "Funkencool",
		date		    = "2013",
		license     = "GNU GPL v2",
		layer		    = math.huge,
		enabled   	= true,
		handler		  = true,
	}
end
-- Includes
local strategic_commands, econ_commands, ignore_commands = include("Configs/BuildMenu.lua")
-----------

-- Chili objects
local Chili
local panH, panW, winW
local window0, menuTabs, panel0, stateWindow, scroll0, menu, menuTab, buildQueue, queueControl, idx
----------------


local imageDir = 'LuaUI/Images/commands/'
local updateRequired = true
local menuChoice = 1
local selectedUnits = {}


-- CONTROLS
local spGetActiveCommand 	= Spring.GetActiveCommand
local spSetActiveCommand 	= Spring.SetActiveCommand
local spGetActiveCmdDesc 	= Spring.GetActiveCmdDesc
local spGetActiveCmdDescs 	= Spring.GetActiveCmdDescs
local spGetSelectedUnits    = Spring.GetSelectedUnits
local spSendCommands        = Spring.SendCommands
local spGetCmdDescIndex = Spring.GetCmdDescIndex
local spGetFullBuildQueue = Spring.GetFullBuildQueue
local Echo = Spring.Echo


-- SCRIPT FUNCTIONS
function LayoutHandler(xIcons, yIcons, cmdCount, commands)
	widgetHandler.commands   = commands
	widgetHandler.commands.n = cmdCount
	widgetHandler:CommandsChanged()
	local reParamsCmds = {}
	local customCmds = {}

	return "", xIcons, yIcons, {}, customCmds, {}, {}, {}, {}, reParamsCmds, {[1337]=9001}
end

local function ClickFunc(chiliButton, x, y, button, mods) 
	local index = spGetCmdDescIndex(chiliButton.cmdid)
	if (index) then
		local left, right = (button == 1), (button == 3)
		local alt, ctrl, meta, shift = mods.alt, mods.ctrl, mods.meta, mods.shift
		spSetActiveCommand(index, button, left, right, alt, ctrl, meta, shift)
	end
end

local function createMyButton(container, texture, cmd,isState)
	if cmd.name ~= "" then
		local button = Chili.Button:New{
			cmdname = cmd.name,
			caption = string.gsub(cmd.name,"%s+", "\n"),
			tooltip = cmd.tooltip,
			cmdid       = cmd.id,
			minHeight = winW/3+5,
			minWidth  = winW/3+5,
			padding 	= {9,9,9,9},
			margin		= {0,0,0,0},
			OnClick = {ClickFunc},
		}
	if texture then 
		button.caption = '' 
		button.children = {Chili.Image:New{width = "100%", height = "100%", x = 0, y = 0, file = texture, parent = button}}
	elseif isState then
		button.caption = string.gsub(cmd.params[cmd.params[1] + 2],"%s+", "\n")
	end
	container:AddChild(button)
	end
end

local function findButtonData(cmd)
	local isState = (cmd.type == CMDTYPE.ICON_MODE and #cmd.params > 1)
	local isBuild = (cmd.id < 0)
	if ignore_commands[cmd.action]	then  return
	elseif not isBuild then 									createMyButton(menu[1], _, cmd,isState)
	elseif econ_commands[cmd.name] then 			createMyButton(menu[2], '#'..-cmd.id, cmd)
	elseif strategic_commands[cmd.name] then 	createMyButton(menu[3], '#'..-cmd.id, cmd)
	else 																			createMyButton(menu[4], '#'..-cmd.id, cmd)
	end
end

local function makeMenuTabs()	
	local tabCount = 0
	local tempMenu = {}
	tempMenu[1] = menu[1]
	menuTab[1] = Chili.Button:New{parent = menuTabs, right = 20, y = 5, width = 80, height = 45, caption = "ORDER", OnMouseOver = {
		function() window0:ClearChildren(); window0:AddChild(menu[1]); menuChoice = 1;end}}
	local caption = {"ORDER","ECON","TACT","UNIT"}
	for i=2, 4 do
		if #menu[i].children > 0 then
			local tab = tabCount + 2
			tempMenu[tab] = menu[i]
			menuTab[tab] = Chili.Button:New{parent = menuTabs, right = 30, y = 35 + tabCount * 25, width = 70, height = 40, caption = caption[i], OnMouseOver = {
				function() window0:ClearChildren(); window0:AddChild(menu[tab]); menuChoice = tab; end}}
			tabCount = tabCount + 1
		end
	end
	menu = tempMenu
	if not menu[menuChoice] then menuChoice = 1 end
	--if #menu > 1 then menuChoice = 2 end
	if #menu>0 then window0:AddChild(menu[menuChoice]) end
end

local function createMenus()
	menu = {}
	for i=0, 4 do
		menu[i] = Chili.Grid:New{height = "100%", width  = "95%", padding = {0,0,0,0}, color = {0,0,0,0}, columns = 3, rows = 10}
	end
end

local function resetWindow()
	window0:ClearChildren()
	stateWindow:ClearChildren()
	menuTabs:ClearChildren()
	for i=0, 4 do
		menu[i]:Dispose()
	end
end

local function loadPanel()

	createMenus()
	menuTab = {}
	resetWindow()
	
	local commands = spGetActiveCmdDescs()
	for cmdid = 1, #commands do
		findButtonData(commands[cmdid]) 
	end
	makeMenuTabs()
end

local function switchTabs(window,x,y,up,value,mods)
	menuTab[menuChoice].state.hovered = false
	menuTab[menuChoice]:Invalidate()
	menuChoice = menuChoice - value
	if menuChoice > #menu then menuChoice = 1 end
	if menuChoice == 0 then menuChoice = #menu end
	window0:ClearChildren()
	menuTab[menuChoice].state.hovered = true
	window0:AddChild(menu[menuChoice])
	menuTab[menuChoice]:Invalidate()
	return true
end

function queueHandler()
	buildQueue:ClearChildren()
	local unitID = Spring.GetSelectedUnits()
	local queueNum
	if unitID[1] then
		local cmd = Spring.GetFactoryCommands(unitID[1])
		if cmd then
			for i=1, #cmd do
				if cmd[i].id < 0 then
					if i == 1 or (i>1 and cmd[i-1].id ~= cmd[i].id) then 
						buildQueue.children[#buildQueue.children+1]=Chili.Image:New{parent=buildQueue, x=45*#buildQueue.children, y=0, width =40, height=40, file='#'..-cmd[i].id,cmdid=cmd[i].id, OnClick={ClickFunc}}
						buildQueue.children[#buildQueue.children]:AddChild(Chili.Label:New{caption=""})
						queueNum = 1
					else 
						queueNum = queueNum + 1	
					end
					if queueNum > 1 then buildQueue.children[#buildQueue.children].children[1]:SetCaption(""..queueNum) end
				end
			end 
		queueControl:Resize(45*#buildQueue.children+30)
		end
	end
	if #buildQueue.children < 1 and #queueControl.children == 1 then queueControl:RemoveChild(buildQueue) 
	elseif #buildQueue.children > 0 then queueControl:AddChild(buildQueue) 
	end
end

function widget:Initialize()
	widgetHandler:ConfigLayoutHandler(LayoutHandler)
	Spring.ForceLayoutUpdate()
	spSendCommands({"tooltip 0"})
	
	if (not WG.Chili) then
		widgetHandler:RemoveWidget()
		return
	end

	Chili = WG.Chili
	local screen0 = Chili.Screen0
	panH = screen0.height * 0.7
	panW = panH * 0.5
	winW = panW * 0.6
	
	window0         = Chili.Window:New{x = 0, y = 0, bottom = 0, width = winW, padding = {0,0,0,0}, margin = {0,0,0,0}, OnMouseWheel = {switchTabs}}
	menuTabs 				= Chili.Control:New{x = winW * 0.965, y = 0, bottom = 0, width = 90, padding = {0,0,0,0}, margin = {0,0,0,0}}
	stateWindow 		= Chili.Grid:New{y = 10, bottom = 0, x = winW + 15, width  = 30, padding = {0, 0, 0, 0}, columns = 1, rows = 16}
	queueControl		= Chili.Control:New{parent = screen0, x = winW - 10, bottom = 0, width = 300, height = 70, margin = {0,0,0,0}}
	buildQueue 			= Chili.Panel:New{parent = queueControl, y = 0, height = "100%", width = "100%", right = 10, padding = {15,10,10,10}}
	
	panel0 = Chili.Control:New{
		parent = screen0,
		x = 0,
		bottom = 0,
		width = panW,
		height = panH,
		padding = {0,0,0,0},
		margin = {0,0,0,0},
		color = {0,0,0,0},	
		children = {menuTabs, window0, stateWindow},
	}
	if WG['blur_api'] then
		WG['blur_api'].UseNoise(true)
		idx = WG['blur_api'].InsertBlurRect(5,screen0.height * 0.7+5,winW-5,5)
	end
end

function widget:CommandsChanged()
	updateRequired = true
end

function widget:DrawScreen(n)
	if updateRequired == true then
	if selectedUnits ~= spGetSelectedUnits() then
    updateRequired = false
		loadPanel()
		queueHandler()
		selectedUnits = spGetSelectedUnits()
	end
	end
end

function widget:Shutdown()
	panel0:Dispose()
  widgetHandler:ConfigLayoutHandler(nil)
  Spring.ForceLayoutUpdate()
	if idx then WG['blur_api'].RemoveBlurRect(idx) end
  spSendCommands({"tooltip 1"})
end
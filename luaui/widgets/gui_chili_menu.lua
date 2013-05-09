-- Version 0.6
function widget:GetInfo()
	return {
		name		    = "BAR UI Command Menu",
		desc		    = "Shiny new Command Menu (obsolete ver)",
		author		  = "Funkencool",
		date		    = "2013",
		license     = "GNU GPL v2",
		layer		    = math.huge,
		enabled   	= false,
		handler		  = true,
	}
end
-- INCLUDES
--VFS.Include("LuaRules/utilities.lua")
local strategic_commands, econ_commands = include("Configs/BuildMenu.lua")

-- CONSTANTS
local MAXBUTTONSONROW = 3
local COMMANDSTOEXCLUDE = {"timewait","deathwait","squadwait","gatherwait","loadonto","nextmenu","prevmenu"}
local Chili
local color = {}
color.borderColor     = {1.0, 1.0, 1.0, 0.6}
color.borderColor2    = {0.0, 0.0, 0.0, 0.8}
color.backgroundColor = {0.8, 0.8, 1.0, 0.4}
color.focusColor      = {0.2, 0.2, 1.0, 0.6}
local debug = false
local menuChoice

-- MEMBERS
local x, y
local imageDir = 'LuaUI/Images/commands/'
local updateRequired = true


-- Chili objects

local window0, menuTabs, panel0, stateWindow, scroll0, menu, menuTab

-- CONTROLS
local spGetActiveCommand 	= Spring.GetActiveCommand
local spGetActiveCmdDesc 	= Spring.GetActiveCmdDesc
local spGetSelectedUnits    = Spring.GetSelectedUnits
local spSendCommands        = Spring.SendCommands


-- SCRIPT FUNCTIONS
function LayoutHandler(xIcons, yIcons, cmdCount, commands)
	widgetHandler.commands   = commands
	widgetHandler.commands.n = cmdCount
	widgetHandler:CommandsChanged()
	local reParamsCmds = {}
	local customCmds = {}

	return "", xIcons, yIcons, {}, customCmds, {}, {}, {}, {}, reParamsCmds, {[1337]=9001}
end

function ClickFunc(chiliButton, x, y, button, mods) 
	local index = Spring.GetCmdDescIndex(chiliButton.cmdid)
	if (index) then
		local left, right = (button == 1), (button == 3)
		local alt, ctrl, meta, shift = mods.alt, mods.ctrl, mods.meta, mods.shift

		Spring.Echo("active command set to ", chiliButton.action)
		Spring.SetActiveCommand(index, button, left, right, alt, ctrl, meta, shift)
	end
end

function findButtonData(cmd)
	local isState = (cmd.type == CMDTYPE.ICON_MODE and #cmd.params > 1)
	local isBuild = (cmd.id < 0)
	if not isState and not isBuild then
		createMyButton(menu[1], 'luaUI/Images/commands/bold/' .. cmd.action .. '.png', cmd)
	elseif isState then
		createMyButton(stateWindow, 'luaUI/Images/commands/states/' .. cmd.action .. cmd.params[1] + 2 .. '.png', cmd)
	elseif strategic_commands[cmd.name] then
		createMyButton(menu[3], '#'..-cmd.id, cmd)
	elseif econ_commands[cmd.name] then
		createMyButton(menu[2], '#'..-cmd.id, cmd)
	else
		createMyButton(menu[4], '#'..-cmd.id, cmd)
	end
	
end

function createMyButton(container, texture, cmd)
	if cmd.name ~= "" then
		local button = Chili.Button:New{
			cmdname = cmd.name,
			action = cmd.action,
			caption = "",
			tooltip = cmd.tooltip,
			hidden = cmd.disabled,
			cmdid       = cmd.id,
			-- minHeight = 80,
			-- minWidth  = 80,
			padding 	= {8,8,8,8},
			margin		= {0,0,0,0},
			OnClick = {ClickFunc},
			children = {Chili.Image:New{width = "100%", height = "100%", x = 0, y = 0, file = texture, parent = button}},
		}	
	container:AddChild(button)
	end
end

local function makeMenuTabs()	
	local tabCount = 0
	menuChoice = 1
	local tempMenu = {}
	tempMenu[1] = menu[1]
	menuTab[1] = Chili.Button:New{parent = menuTabs, right = 0, y = 5, width = 40, height = 90, caption = "O\nR\nD\nE\nR", OnClick = {
		function() window0:ClearChildren(); window0:AddChild(menu[1]); menuChoice = 1;end}}
	
	if #menu[2].children > 0 then
		local tab = tabCount + 2
		tempMenu[tab] = menu[2]
		menuTab[tab] = Chili.Button:New{parent = menuTabs, right = 5, y = 85, width = 35, height = 70, caption = "E\nC\nO\nN", OnClick = {
		function() window0:ClearChildren(); window0:AddChild(menu[tab]); menuChoice = tab; end}}
		menuChoice = tabCount + 2
		tabCount = tabCount + 1
	end
	
	if #menu[3].children > 0 then
		local tab = tabCount + 2
		tempMenu[tab] = menu[3]
		menuTab[tab] = Chili.Button:New{parent = menuTabs, right = 5, y = 85 + tabCount * 60, width = 35, height = 70, caption = "T\nA\nC\nT", OnClick = {
		function() window0:ClearChildren(); window0:AddChild(menu[tab]); menuChoice = tab; end}}		
		tabCount = tabCount + 1
	end

	if #menu[4].children > 0 then
		local tab = tabCount + 2
		tempMenu[tab] = menu[4]
		menuTab[tab] = Chili.Button:New{parent = menuTabs, right = 5, y = 85 + tabCount * 60, width = 35, height = 70, caption = "U\nN\nI\nT", OnClick = {
			function() window0:ClearChildren(); window0:AddChild(menu[tab]); menuChoice = tab;end}}
		tabCount = tabCount + 1
	end
	menu = tempMenu
	window0:AddChild(menu[menuChoice])
end
function createMenus()
	menu = {}
	for i=0, 4 do
		menu[i] = Chili.Grid:New{height = "100%", width  = "100%", padding = {0,0,0,0}, color = {0,0,0,0}, columns = 3, rows = 10}
	end
end

function resetWindow()
	window0:ClearChildren()
	stateWindow:ClearChildren()
	menuTabs:ClearChildren()
	for i=0, 4 do
		menu[i]:Dispose()
	end
end

function loadPanel()

	createMenus()
	menuTab = {}
	resetWindow()
	
	local commands = Spring.GetActiveCmdDescs()
	for cmdid = 1, #commands do
		findButtonData(commands[cmdid]) 
	end
	makeMenuTabs()

end

function switchTabs(window,x,y,up,value,mods)
		menuTab[menuChoice].state.hovered = false
		menuTab[menuChoice]:Invalidate()
		menuChoice = menuChoice - value
		if menuChoice > #menu then menuChoice = 1 end
		if menuChoice == 0 then menuChoice = #menu end
		window0:ClearChildren()
		menuTab[menuChoice].state.hovered = true
		window0:AddChild(menu[menuChoice])
		menuTab[menuChoice]:Invalidate()
		
end

-- WIDGET CODE
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
	local panH		=	screen0.height * 0.7
	local panW		= panH * 0.5
	local winW		= panW * 0.6
	
	window0         = Chili.Window:New{x = 0, y = 0, bottom = 0, width = winW, padding = {0,0,0,0}, margin = {0,0,0,0}, OnMouseWheel = {switchTabs}}
	menuTabs 				= Chili.Control:New{x = winW * 0.965, y = 0, bottom = 0, width = 30, padding = {0,0,0,0}, margin = {0,0,0,0}}
	stateWindow 		= Chili.Grid:New{y = 10, bottom = 0, x = winW + 15, width  = 30, padding = {0, 0, 0, 0}, columns = 1, rows = 16}
	
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
	
end

function widget:CommandsChanged()
	updateRequired = true
end

function widget:DrawScreen()
    if updateRequired then
      updateRequired = false
			loadPanel()
    end
end

function widget:Shutdown()
	panel0:Dispose()
  widgetHandler:ConfigLayoutHandler(nil)
  Spring.ForceLayoutUpdate()
  spSendCommands({"tooltip 1"})
end
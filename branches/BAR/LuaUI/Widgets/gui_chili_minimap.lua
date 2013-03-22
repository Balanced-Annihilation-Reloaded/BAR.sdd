function widget:GetInfo()
  return {
    name      = "Chili Minimap",
    desc      = "v0.884 Chili Minimap",
    author    = "Licho, CarRepairer",
    date      = "@2010",
    license   = "GNU GPL, v2 or later",
    layer     = -100000,
    experimental = false,
    enabled   = true, --  loaded by default?
	detailsDefault = 1
  }
end


local window_minimap
local Chili
local glDrawMiniMap = gl.DrawMiniMap
local glResetState = gl.ResetState
local glResetMatrices = gl.ResetMatrices

local iconsize = 20

local tabbedMode = false

local function toggleTeamColors()
	if WG.LocalColor and WG.LocalColor.localTeamColorToggle then
		WG.LocalColor.localTeamColorToggle()
	else
		Spring.SendCommands("luaui enablewidget Local Team Colors")
	end
end 


local function AdjustToMapAspectRatio(w,h)
	if (Game.mapX > Game.mapY) then
		return w, w*Game.mapY/Game.mapX+iconsize
	end
	return h*Game.mapX/Game.mapY, h+iconsize
end

local function MakeMinimapWindow()
end

options_path = 'Settings/Interface/Minimap'
local radar_path = 'Settings/Graphics/Radar View Colors'
options_order = { 'use_map_ratio', 'hidebuttons', 'initialSensorState', 'alwaysDisplayMexes', 'lastmsgpos', 'lblViews', 'viewstandard', 'viewheightmap', 'viewblockmap', 'lblLos', 'viewfow', 'radar_color_label', 'radar_fog_color', 'radar_los_color', 'radar_radar_color', 'radar_jammer_color', 'radar_preset_blue_line', 'radar_preset_green', 'radar_preset_only_los'}
options = {
	use_map_ratio = {
		name = 'Minimap Keeps Aspect Ratio',
		type = 'bool',
		value = true,
		advanced = true,
		OnChange = function(self)
			if (self.value) then 
				local w,h = AdjustToMapAspectRatio(300, 200)
				window_minimap:Resize(w,h,false,false)
			end 
			window_minimap.fixedRatio = self.value;			
		end,
},
	--[[
	simpleMinimapColors = {
		name = 'Simplified Minimap Colors',
		type = 'bool',
		desc = 'Show minimap blips as green for you, teal for allies and red for enemies (only minimap will use this simple color scheme).', 
		springsetting = 'SimpleMiniMapColors',
		OnChange = function(self) Spring.SendCommands{"minimap simplecolors " .. (self.value and 1 or 0) } end,
	},
	--]]
	
	initialSensorState = {
		name = "Initial LOS state",
		desc = "Game starts with LOS enabled",
		type = 'bool',
		value = true,
	},
	
	alwaysDisplayMexes = {
		name = 'Show metal spots',
		hotkey = {key='f4', mod=''},
		type ='bool',
		value = false,
	},
	
	lblViews = { type = 'label', name = 'Views', },
	
	viewstandard = {
		name = 'Clear map drawings',
		type = 'button',
		action = 'clearmapmarks',
	},
	viewheightmap = {
		name = 'Toggle Height Map',
		type = 'button',
		action = 'showelevation',
	},
	viewblockmap = {
		name = 'Toggle Pathing Map',
		desc = 'Select unit then click this to see where it can go.',
		type = 'button',
		action = 'showpathtraversability',
	},
	
	lastmsgpos = {
		name = 'Last Message Position',
		type = 'button',
		action = 'lastmsgpos',
	},
	
	lblLos = { type = 'label', name = 'Line of Sight', },
	
	viewfow = {
		name = 'Toggle Fog of War View',
		type = 'button',
		action = 'togglelos',
	},
	
	radar_color_label = { type = 'label', name = 'Note: These colors are additive.', path = radar_path,},
	
	radar_fog_color = {
		name = "Fog Color",
		type = "colors",
		value = { 0.4, 0.4, 0.4, 1},
		OnChange =  function() updateRadarColors() end,
		path = radar_path,
	},
	radar_los_color = {
		name = "LOS Color",
		type = "colors",
		value = { 0.15, 0.15, 0.15, 1},
		OnChange =  function() updateRadarColors() end,
		path = radar_path,
	},
	radar_radar_color = {
		name = "Radar Color",
		type = "colors",
		value = { 0, 0, 1, 1},
		OnChange =  function() updateRadarColors() end,
		path = radar_path,
	},
	radar_jammer_color = {
		name = "Jammer Color",
		type = "colors",
		value = { 0.1, 0, 0, 1},
		OnChange = function() updateRadarColors() end,
		path = radar_path,
	},
	
	radar_preset_blue_line = {
		name = 'Blue Outline Radar (default)',
		type = 'button',
		OnChange = function()
			options.radar_fog_color.value = { 0.4, 0.4, 0.4, 1}
			options.radar_los_color.value = { 0.15, 0.15, 0.15, 1}
			options.radar_radar_color.value = { 0, 0, 1, 1}
			options.radar_jammer_color.value = { 0.1, 0, 0, 1}
			updateRadarColors()
		end,
		path = radar_path,
	},
	
	radar_preset_green = {
		name = 'Green Area Radar',
		type = 'button',
		OnChange = function()
			options.radar_fog_color.value = { 0.25, 0.2, 0.25, 0}
			options.radar_los_color.value = { 0.2, 0.13, 0.2, 0}
			options.radar_radar_color.value = { 0, 0.17, 0, 0}
			options.radar_jammer_color.value = { 0.18, 0, 0, 0}
			updateRadarColors()
		end,
		path = radar_path,
	},
	
	radar_preset_only_los = {
		name = 'Only LOS',
		type = 'button',
		OnChange = function()
			options.radar_fog_color.value = { 0.40, 0.40, 0.40, 0}
			options.radar_los_color.value = { 0.15, 0.15, 0.15, 0}
			options.radar_radar_color.value = { 0, 0, 0, 0}
			options.radar_jammer_color.value = { 0, 0, 0, 0}
			updateRadarColors()
		end,
		path = radar_path,
	},
	
	hidebuttons = {
		name = 'Hide Minimap Buttons',
		type = 'bool',
		advanced = true,
		OnChange= function(self) iconsize = self.value and 0 or 20; MakeMinimapWindow() end,
		value = false,
	},

}

function updateRadarColors()
	local fog = options.radar_fog_color.value
	local los = options.radar_los_color.value
	local radar = options.radar_radar_color.value
	local jam = options.radar_jammer_color.value
	Spring.SetLosViewColors(
		{ fog[1], los[1], radar[1], jam[1]},
		{ fog[2], los[2], radar[2], jam[2]}, 
		{ fog[3], los[3], radar[3], jam[3]} 
	)
end

function setSensorState(newState)
	local losEnabled = Spring.GetMapDrawMode() == "los"
	if losEnabled ~= newState then
		Spring.SendCommands('togglelos')
	end
end

function widget:Update() --Note: these run-once codes is put here (instead of in Initialize) because we are waiting for epicMenu to initialize the "options" value first.
	setSensorState(options.initialSensorState.value)
	updateRadarColors()
	widgetHandler:RemoveCallIn("Update") -- remove update call-in since it only need to run once. ref: gui_ally_cursors.lua by jK
end

local function MakeMinimapButton(file, pos, option)
	local desc = options[option].desc and (' (' .. options[option].desc .. ')') or ''
	local action = WG.crude.GetActionName(options_path, options[option])
	local hotkey = WG.crude.GetHotkey(action)
	
	if hotkey ~= '' then
		hotkey = ' (\255\0\255\0' .. hotkey:upper() .. '\008)'
	end
		
	return Chili.Button:New{ 
		height=iconsize, width=iconsize, 
		caption="",
		margin={0,0,0,0},
		padding={0,0,0,0},
		bottom=0, 
		x=iconsize*(pos-1), 
		
		tooltip = ( options[option].name .. desc .. hotkey ),
		OnClick={ function(self) Spring.SendCommands( action ); end },
		children={
			Chili.Image:New{
				file=file,
				width="100%";
				height="100%";
				x="0%";
				y="0%";
			}
		},
	}
end

MakeMinimapWindow = function()
	if (window_minimap) then
		window_minimap:Dispose()
	end

	local h = Chili.Screen0.height*0.30 + 8
	local w = (h - iconsize) * Game.mapX/Game.mapY
	if (Game.mapX/Game.mapY > 1) then
		w = h*(Game.mapX/Game.mapY)^0.5 - 10
		h = w * Game.mapY/Game.mapX + iconsize
	end
	
	window_minimap = Chili.Window:New{  
--		dockable = true,
		name = "Minimap",
		x = 0,  
		y = 0,
		padding = {5,5,5,5},
		margin = {0,0,0,0},
		width  = w,
		height = h,
		parent = Chili.Screen0,
		children = {
			MakeMinimapButton( 'LuaUI/images/map/standard.png', 3, 'viewstandard' ),
			MakeMinimapButton( 'LuaUI/images/map/heightmap.png', 4, 'viewheightmap' ),
			MakeMinimapButton( 'LuaUI/images/map/blockmap.png', 5, 'viewblockmap' ),
			MakeMinimapButton( 'LuaUI/images/map/metalmap.png', 6, 'alwaysDisplayMexes'),
			MakeMinimapButton( 'LuaUI/images/map/fow.png', 7, 'viewfow' ),
--			MakeMinimapButton( 'LuaUI/images/map/minimap_colors_simple.png', 1, 'toggleTeamColors' ),
			Chili.Button:New{ 
				height=iconsize, width=iconsize, 
				caption="",
				margin={0,0,0,0},
				padding={4,4,4,4},
				bottom=0, 
				x=0, 
				
				tooltip = "Toggle simplified teamcolours",
				
				--OnClick={ function(self) options[option].OnChange() end }, 
				OnClick = {toggleTeamColors},
				children={
					Chili.Image:New{
						file='LuaUI/images/map/minimap_colors_simple.png',
						width="100%";
						height="100%";
						x="0%";
						y="0%";
					}
				},
			},
		},
	}
end
function widget:MousePress(x, y, button)
	if not Spring.IsAboveMiniMap(x, y) then
		return false
	end
	local alt, ctrl, meta, shift = Spring.GetModKeyState()
	if not meta then  --//skip epicMenu when user didn't press the Spacebar
		return false 
	end
	if Spring.GetActiveCommand() == 0 then --//activate epicMenu when user didn't have active command & Spacebar+click on the minimap
		WG.crude.OpenPath(options_path) --click + space will shortcut to option-menu
		WG.crude.ShowMenu() --make epic Chili menu appear.
		return true
	else --//skip epicMenu when user have active command. User might be trying to queue/insert command using the minimap.
		return false
	end
end

--[[function widget:Update(dt) 
	local mode = Spring.GetCameraState()["mode"]
	if mode == 7 and not tabbedMode then
		tabbedMode = true
		Chili.Screen0:RemoveChild(window_minimap)
	end
	if mode ~= 7 and tabbedMode then
		Chili.Screen0:AddChild(window_minimap)
		tabbedMode = false
	end
end
--]]

 --// similar properties to "widget:Update(dt)" above but update less often.
function widget:KeyRelease(key, mods, label, unicode)
	if key == 0x009 then --// "0x009" is equal to "tab". Reference: uikeys.txt
		local mode = Spring.GetCameraState()["mode"]
		if mode == 7 and not tabbedMode then
			Chili.Screen0:RemoveChild(window_minimap)
			tabbedMode = true
		end
		if mode ~= 7 and tabbedMode then
			Chili.Screen0:AddChild(window_minimap)
			tabbedMode = false
		end
	end
end

function widget:Initialize()
	if (Spring.GetMiniMapDualScreen()) then
		Spring.Echo("ChiliMinimap: auto disabled (DualScreen is enabled).")
		widgetHandler:RemoveWidget()
		return
	end

	if (not WG.Chili) then
		widgetHandler:RemoveWidget()
		return
	end
	
	Chili = WG.Chili
	
	MakeMinimapWindow()
	
	gl.SlaveMiniMap(true)
end

function widget:Shutdown()
	--// reset engine default minimap rendering
	gl.SlaveMiniMap(false)
	Spring.SendCommands("minimap geo " .. Spring.GetConfigString("MiniMapGeometry"))

	--// free the chili window
	if (window_minimap) then
		window_minimap:Dispose()
	end
end 


local lx, ly, lw, lh

function widget:DrawScreen() 
	if (window_minimap.hidden) then 
		gl.ConfigMiniMap(0,0,0,0) --// a phantom map still clickable if this is not present.
		lx = 0
		ly = 0
		lh = 0
		lw = 0
		return 
	end
	if (lw ~= window_minimap.width or lh ~= window_minimap.height or lx ~= window_minimap.x or ly ~= window_minimap.y) then 
		local cx,cy,cw,ch = Chili.unpack4(window_minimap.clientArea)
		ch = ch	- iconsize
		cx = cx + 2
		cy = cy + 2
		cw = cw - 4
		ch = ch - 4
		--window_minimap.x, window_minimap.y, window_minimap.width, window_minimap.height
		--Chili.unpack4(window_minimap.clientArea)
		cx,cy = window_minimap:LocalToScreen(cx,cy)
		local vsx,vsy = gl.GetViewSizes()
		gl.ConfigMiniMap(cx,vsy-ch-cy,cw,ch)
		lx = window_minimap.x
		ly = window_minimap.y
		lh = window_minimap.height
		lw = window_minimap.width
	end

	gl.PushAttrib(GL.ALL_ATTRIB_BITS)
	gl.MatrixMode(GL.PROJECTION)
	gl.PushMatrix()
	gl.MatrixMode(GL.MODELVIEW)
	gl.PushMatrix()

	glDrawMiniMap()

	gl.MatrixMode(GL.PROJECTION)
	gl.PopMatrix()
	gl.MatrixMode(GL.MODELVIEW)
	gl.PopMatrix()
	gl.PopAttrib()
end 


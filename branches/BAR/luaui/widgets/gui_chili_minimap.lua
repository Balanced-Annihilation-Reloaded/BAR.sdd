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

local function MakeMinimapWindow()
	if (window_minimap) then
		window_minimap:Dispose()
	end

	local h = Chili.Screen0.height*0.30 + 8
	local w = (h - iconsize) * Game.mapX/Game.mapY
	if (Game.mapX/Game.mapY > 1) then
		w = h*(Game.mapX/Game.mapY)^0.5 - 10
		h = w * Game.mapY/Game.mapX
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


function widget:GetInfo()
  return {
    name      = "BAR's Minimap",
    desc      = "v0.884 Chili Minimap",
    author    = "Licho, CarRepairer",
    date      = "@2010",
    license   = "GNU GPL, v2 or later",
    layer     = -99,
    enabled   = true,
  }
end


local minimap
local Chili
local glDrawMiniMap = gl.DrawMiniMap
local glResetState = gl.ResetState
local glResetMatrices = gl.ResetMatrices


local tabbedMode = false

local function MakeMinimapWindow()
	
	if (minimap) then
		minimap:Dispose()
	end

	local aspect = Game.mapX/Game.mapY
	local h = Chili.Screen0.height * 0.3
	local w = h * aspect
	
	if (aspect > 1) then
		w = h * aspect^0.5
		h = w / aspect
	end
	
	minimap = Chili.Window:New{
		name    = "Minimap", 
		parent  = Chili.Screen0,
		width   = w, 
		height  = h, 
		x       = 0, 
		bottom  = 0,
		padding = {5,5,5,5},
		margin  = {0,0,0,0},
	}
end

function widget:KeyRelease(key, mods, label, unicode)
	if key == 0x009 then --// "0x009" is equal to "tab". Reference: uikeys.txt
		local mode = Spring.GetCameraState()["mode"]
		if mode == 7 and not tabbedMode then
			Chili.Screen0:RemoveChild(minimap)
			tabbedMode = true
		end
		if mode ~= 7 and tabbedMode then
			Chili.Screen0:AddChild(minimap)
			tabbedMode = false
		end
	end
end

function widget:ViewResize(vsx, vsy)
	MakeMinimapWindow()
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
	if (minimap) then
		minimap:Dispose()
	end
end 


local lx, ly, lw, lh

function widget:DrawScreen() 
	
	if (minimap.hidden) then 
		gl.ConfigMiniMap(0,0,0,0) --// a phantom map still clickable if this is not present.
		lx = 0
		ly = 0
		lh = 0
		lw = 0
		return 
	end
	
	if (lw ~= minimap.width or lh ~= minimap.height or lx ~= minimap.x or ly ~= minimap.y) then 
		local cx,cy,cw,ch = Chili.unpack4(minimap.clientArea)
		cx = cx + 2
		cy = cy + 2
		cw = cw - 4
		ch = ch - 4
		cx,cy = minimap:LocalToScreen(cx,cy)
		local vsx,vsy = gl.GetViewSizes()
		gl.ConfigMiniMap(cx,vsy-ch-cy,cw,ch)
		lx = minimap.x
		ly = minimap.y
		lh = minimap.height
		lw = minimap.width
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


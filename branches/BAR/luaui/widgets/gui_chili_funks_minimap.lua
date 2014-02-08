function widget:GetInfo()
  return {
    name      = "BAR's Minimap",
    desc      = "Chili Minimap",
    author    = "Licho, CarRepairer, Funkencool",
    date      = "@2010",
    license   = "GNU GPL, v2 or later",
    layer     = -99,
    enabled   = true,
  }
end


local Chili
local minimap

-- Localize
local glGetViewSizes  = gl.GetViewSizes
local glConfigMiniMap = gl.ConfigMiniMap
local glDrawMiniMap   = gl.DrawMiniMap
local glPushAttrib    = gl.PushAttrib
local glPopAttrib     = gl.PopAttrib
local glMatrixMode    = gl.MatrixMode
local glPushMatrix    = gl.PushMatrix
local glPopMatrix     = gl.PopMatrix
local GL_ALL_ATTRIB_BITS = GL.ALL_ATTRIB_BITS
local GL_PROJECTION      = GL.PROJECTION
local GL_MODELVIEW       = GL.MODELVIEW
--

local function MakeMinimapWindow()
	
	if (minimap) then
		minimap:Dispose()
	end

	local aspect = Game.mapX/Game.mapY
	local h = Chili.Screen0.height * 0.3
	local w = h * aspect
	
	if aspect > 1 then
		w = h * aspect^0.5
		h = w / aspect
	end
	
	minimap = Chili.Window:New{
		name      = "Minimap", 
		parent    = Chili.Screen0,
		draggable = false,
		width     = w, 
		height    = h,
		x         = 0,
		bottom    = 0,
		padding   = {6,6,5,6},
	}
	
end

function widget:KeyRelease(key, mods, label, unicode)
	-- "0x009" = "tab". Reference: uikeys.txt
	if key == 0x009 then
		local mode = Spring.GetCameraState()["mode"]
		if mode == 7 and minimap.visible then
			minimap:Hide()
		elseif mode ~= 7 and minimap.hidden then
			minimap:Show()
		end
	end
end

function widget:ViewResize(vsx, vsy)
	MakeMinimapWindow()
end

function widget:Initialize()
	
	if Spring.GetMiniMapDualScreen() then
		Spring.Echo("ChiliMinimap: auto disabled (DualScreen is enabled).")
		widgetHandler:RemoveWidget()
		return
	end

	if not WG.Chili then
		widgetHandler:RemoveWidget()
		return
	end
	
	Chili = WG.Chili
	
	MakeMinimapWindow()
	
	gl.SlaveMiniMap(true)
end

function widget:Shutdown()
	-- reset engine default minimap rendering
	gl.SlaveMiniMap(false)
	Spring.SendCommands("minimap geo " .. Spring.GetConfigString("MiniMapGeometry"))

	-- free the chili window
	if minimap then
		minimap:Dispose()
	end
end 

function widget:DrawScreen() 
	
	if minimap.hidden then
		-- a phantom map is still clickable if this is not present.
		glConfigMiniMap(0,0,0,0)
		return 
	else
		local vsx,vsy = glGetViewSizes()
		local cx,cy,cw,ch = Chili.unpack4(minimap.clientArea)
		cx,cy = minimap:LocalToScreen(cx,cy)
		glConfigMiniMap(cx,vsy-ch-cy,cw,ch)		
	end


	glPushAttrib(GL_ALL_ATTRIB_BITS)
	glMatrixMode(GL_PROJECTION)
	glPushMatrix()
	glMatrixMode(GL_MODELVIEW)
	glPushMatrix()
	
	glDrawMiniMap()
	
	glMatrixMode(GL_PROJECTION)
	glPopMatrix()
	glMatrixMode(GL_MODELVIEW)
	glPopMatrix()
	glPopAttrib()
end 


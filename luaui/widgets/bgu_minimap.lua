function widget:GetInfo()
  return {
    name      = "Minimap",
    desc      = "Minimap",
    author    = "Funkencool",
    date      = "2014",
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

local function MakeMinimapWindow(screenH)
	
	if (minimap) then
		minimap:Dispose()
	end

	local aspect = Game.mapX/Game.mapY
	local h = screenH * 0.3
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
		padding   = {6,6,6,6},
	}
	
end

function widget:ViewResize(_, vsy)
	MakeMinimapWindow(vsy)
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
	
	MakeMinimapWindow(Chili.Screen0.height)
	
	gl.SlaveMiniMap(true)
end

function widget:Shutdown()
	-- reset engine default minimap rendering
	gl.SlaveMiniMap(false)
	Spring.SendCommands("minimap geo " .. Spring.GetConfigString("MiniMapGeometry"))
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


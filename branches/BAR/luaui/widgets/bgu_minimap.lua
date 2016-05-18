function widget:GetInfo()
  return {
    name      = "Minimap",
    desc      = "Displays the minimap",
    author    = "Funkencool",
    date      = "2014",
    license   = "GNU GPL, v2 or later",
    layer     = -99,
    enabled   = true,
  }
end


local Chili
local minimap
local maxH = 0.3
local minH = 0.12
local maxW = 0.3
local minW = 0.12

local glConfigMiniMap = gl.ConfigMiniMap
local glDrawMiniMap   = gl.DrawMiniMap
local glGetViewSizes  = gl.GetViewSizes
local glPushMatrix    = gl.PushMatrix
local glPopMatrix     = gl.PopMatrix
local glRotate        = gl.Rotate
local glTranslate     = gl.Translate

local spGetCameratState = Spring.GetCameraState

local buttonColour, panelColour, sliderColour 

local function MakeMinimapWindow()
    
    if (minimap) then
        minimap:Dispose()
    end

    local x = WG.UIcoords.minimap.x
    local y = WG.UIcoords.minimap.y
    local w = WG.UIcoords.minimap.w
    local h = WG.UIcoords.minimap.h
    
    minimap = Chili.Panel:New{
        name      = "minimap", 
        parent    = Chili.Screen0,
        draggable = false,
        borderColor = {0,0,0,0},
        backgroundColor = panelColour,
        padding   = {6,6,6,6},
    }
    
    minimap:SetPos(x,y,w,h)    
end

function widget:Initialize()
    
    if Spring.GetMiniMapDualScreen() then
        Spring.Echo("ChiliMinimap: auto disabled (DualScreen is enabled).")
        widgetHandler:RemoveWidget()
        return
    end

    buttonColour = WG.buttonColour
    panelColour = WG.panelColour
    
    Chili = WG.Chili
    
    MakeMinimapWindow()    
    gl.SlaveMiniMap(true)
end

function widget:ViewResize()
    MakeMinimapWindow()
end

function widget:Shutdown()
    -- reset engine default minimap rendering
    gl.SlaveMiniMap(false)
    Spring.SendCommands("minimap geo " .. Spring.GetConfigString("MiniMapGeometry"))
    
    WG.MiniMap = nil
end 

function widget:Update()
    local camState = spGetCameratState()
    flipped = (camState.flipped==1)    
end

function widget:DrawScreen() 
    
    if minimap.hidden then
        -- a phantom map is still click-able if this is not present.
        glConfigMiniMap(0,0,0,0)
        return 
    end
    
    local vsx,vsy = glGetViewSizes()
    local cx,cy,cw,ch = Chili.unpack4(minimap.clientArea)
    cx,cy = minimap:LocalToScreen(cx,cy)
    
    local mx = cx
    local my = vsy - ch - cy
    local mw = cw + 1
    local mh = ch + 1

    if not flipped then
        glConfigMiniMap(mx,my,mw,mh) 
        glDrawMiniMap()    
    else 
        glPushMatrix()
        glTranslate(mx+mw,my+mh,0)
        glRotate(180, 0,0,1)
        glTranslate(1,1,0)
        glConfigMiniMap(0,0,mw,mh) -- negative x and y vals are silently ignored :/
        glDrawMiniMap()
        glPopMatrix()    
    end

end 


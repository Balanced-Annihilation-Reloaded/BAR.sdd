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

local buttonColour, panelColour, sliderColour 

local function MakeMinimapWindow(screenW, screenH)
    
    if (minimap) then
        minimap:Dispose()
    end

    local aspect = Game.mapX/Game.mapY
    local relAspect = (screenW*maxW)/(screenH*maxH)
    local h,w
    if aspect <= relAspect then
        -- height limited
        h = screenH * maxH
        w = math.min(math.max(h*aspect, screenW*minW), screenW*maxW)
    else
        -- width limited
        w = screenW * maxW
        h = math.min(math.max(w/aspect, screenH*minH), screenH*maxH)
        Spring.Echo(screenH*minH, w/aspect, screenH*maxH)
    end
    
    WG.MiniMap = {}
    WG.MiniMap.width = w
    WG.MiniMap.height = h
    
    minimap = Chili.Panel:New{
        name      = "minimap", 
        parent    = Chili.Screen0,
        draggable = false,
        width     = w, 
        height    = h,
        x         = 0,
        bottom    = 0,
        borderColor = {0,0,0,0},
        backgroundColor = panelColour,
        padding   = {6,6,6,6},
    }
    
end

function widget:ViewResize(vsx, vsy)
    MakeMinimapWindow(vsx, vsy)
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
    
    local vsx,vsy = Spring.GetViewGeometry()
    MakeMinimapWindow(vsx, vsy)
    
    gl.SlaveMiniMap(true)
end

function widget:Shutdown()
    -- reset engine default minimap rendering
    gl.SlaveMiniMap(false)
    Spring.SendCommands("minimap geo " .. Spring.GetConfigString("MiniMapGeometry"))
    
    WG.MiniMap = nil
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
    
    glConfigMiniMap(cx,vsy-ch-cy,cw+1,ch+1)        
    glDrawMiniMap()
end 


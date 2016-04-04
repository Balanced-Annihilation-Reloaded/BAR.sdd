
function widget:GetInfo()
	return {
		name      = "BGU layout", 
		desc      = "Controls the positioning of the main BGU elements",
		author    = "Bluestone",
		date      = "socks",
		license   = "GPLv2",
		layer     = -999, -- before all UI elements
		enabled   = true, 
        api       = true,
        handler   = true,
    }
end

-- todo: add font sizes that scale with screen?

local min = math.min
local max = math.max
local floor = math.floor
local vsx, vsy, screenAspect
local initialized 
local screenAspect

local layouts = {
    "classic",
    "classic2",
    "inverted",
    "inverted2",
	"new1",
	"new2"
    -- "bottom" 
}
local options = {
    layout = "inverted" -- default
}

-- ui element positions (& related menu button sizes)
local UIcoords = { 
    minimap = {},     
    sInfo = {}, 
    buildMenu = {}, 
    -- buildMenu controls its own width, according to how many buttons it displays
    -- build menu buttons?

    orderMenu = {}, 
    orderMenuButton = {},
    stateMenu = {}, 
    stateMenuButton = {}, 
    
    -- res bars 
    -- todo

    -- console/chonsole
    -- todo
    
    
    -- player list has to choose its own dimensions
}

-------------------------------------
-- helpers

function ApplyViewGeometry(t)
    local converted = {}
    for k,v in pairs(t) do
        converted[k] = {}
        for k2,v2 in pairs(v) do
            if k2=='x' or k2=='w' then
                converted[k][k2] = v2*vsx
            elseif k2=='y' or k2=='h' then
                converted[k][k2] = v2*vsy
            else
                converted[k][k2] = v2
            end         
        end    
    end
    return converted
end

function GetMinimapDimensions(minW, maxW, minH, maxH)
    local screenW,screenH = Spring.GetViewGeometry()
    local mapAspect = Game.mapX/Game.mapY
    local relAspect = (screenW*maxW)/(screenH*maxH)
    local h,w
    if mapAspect <= relAspect then
        -- height limited
        h = screenH * maxH
        w = min(max(h*mapAspect, screenW*minW), screenW*maxW)
    else
        -- width limited
        w = screenW * maxW
        h = min(max(w/mapAspect, screenH*minH), screenH*maxH)
    end
    return w/screenW, h/screenH
end


-------------------------------------
-- classic

function Classic()
    local minimapW,minimapH = GetMinimapDimensions(0.12, 0.27, 0.12, 0.27)
    local minimap = {x=0, y=0, w=minimapW, h=minimapH}
    
    local sInfoH = 0.23
    local sInfo = {x=0, y=1-sInfoH, w=sInfoH/screenAspect, h=sInfoH}
    
    local buildMenu = {x=0, y=max(minimapH,0.2), w=nil, h=1-max(minimapH,0.2)-sInfo.h} 
    local buildGrid = {wantedRows=4, wantedCols=3, paddingRows=3, paddingCols=1, maxRows=6, maxCols=5}
    
    local facBarButton = {h=0.06}
    
    local stateMenuButton = {w=min(0.1,70/vsy), h=0.02}
    local stateMenu = {x=sInfo.w, y=1-sInfo.h, w=stateMenuButton.w, h=sInfo.h}
    local stateGrid = {orientation="bottom"}
    
    local orderMenuButton = {w=0.055/screenAspect, h=0.055}    
    local orderMenu = {x=stateMenu.x+stateMenu.w, y=1-3*orderMenuButton.h, w=nil, h=nil}    
    local orderGrid = {rows=3, cols=8} -- it might override 
    
    local resBars = {x=1-0.3, y=0, w=0.3, h=0.09}
    
    local consoleLeft = minimapW+0.05
    local consoleRight = resBars.x
    local console = {x=consoleLeft, y=0, w=max(0,consoleRight-consoleLeft), h=0.15}
    local chonsole = {x=consoleLeft, y=console.h, w=console.w, h=nil}

    UIcoords = {
        minimap=minimap, sInfo=sInfo, 
        buildMenu=buildMenu, buildGrid=buildGrid,
        facBarButton=facBarButton,
        stateMenu=stateMenu, stateMenuButton=stateMenuButton, stateGrid=stateGrid,
        orderMenu=orderMenu, orderMenuButton=orderMenuButton, orderGrid=orderGrid,
        resBars=resBars,
        console=console, chonsole=chonsole,
    }
end

function Classic2()
    local minimapW,minimapH = GetMinimapDimensions(0.12, 0.27, 0.12, 0.27)
    local minimap = {x=0, y=0, w=minimapW, h=minimapH}
    local sInfoH = 0.23
    local sInfo = {x=0, y=max(minimapH,0.2), w=sInfoH/screenAspect, h=sInfoH}
    
    local buildMenu = {x=0, y=sInfo.y+sInfo.h, w=nil, h=1-max(minimapH,0.2)-sInfo.h} 
    local buildGrid = {wantedRows=4, wantedCols=3, paddingRows=3, paddingCols=1, maxRows=6, maxCols=5}
    
    local facBarButton = {h=0.06}

    local stateMenuButton = {w=min(0.1,70/vsy), h=0.02}
    local stateMenu = {x=sInfo.w, y=sInfo.y, w=stateMenuButton.w, h=sInfo.h}
    local stateGrid = {orientation="bottom"}
    
    local orderMenuButton = {w=0.055/screenAspect, h=0.055}    
    local orderMenu = {x=0.25, y=1-3*orderMenuButton.h, w=nil, h=nil}    
    local orderGrid = {rows=1, cols=21} -- it might override 
    
    local resBars = {x=1-0.3, y=0, w=0.3, h=0.09}
    
    local consoleLeft = minimapW+0.05
    local consoleRight = resBars.x
    local console = {x=consoleLeft, y=0, w=max(0,consoleRight-consoleLeft), h=0.15}
    local chonsole = {x=consoleLeft, y=console.h, w=console.w, h=nil}

    UIcoords = {
        minimap=minimap, sInfo=sInfo, 
        buildMenu=buildMenu, buildGrid=buildGrid,
        facBarButton=facBarButton,
        stateMenu=stateMenu, stateMenuButton=stateMenuButton, stateGrid=stateGrid,
        orderMenu=orderMenu, orderMenuButton=orderMenuButton, orderGrid=orderGrid,
        resBars=resBars,
        console=console, chonsole=chonsole,
    }

end

-------------------------------------
-- inverted

function Inverted()
    local minimapW,minimapH = GetMinimapDimensions(0.12, 0.28, 0.12, 0.28)
    local minimap = {x=0, y=1-minimapH, w=minimapW, h=minimapH}
    local sInfo = {x=0, y=0, w=0.2/screenAspect, h=0.2}
    
    local buildMenu = {x=0, y=0.2, w=nil, h=0.5} 
    local buildGrid = {wantedRows=4, wantedCols=3, paddingRows=3, paddingCols=1, maxRows=6, maxCols=5}
    
    local facBarButton = {h=0.06}

    local stateMenuButton = {w=min(0.1,70/vsy), h=0.02}
    local stateMenu = {x=sInfo.w, y=0, w=stateMenuButton.w, h=sInfo.h}
    local stateGrid = {orientation="top"}

    local orderMenuButton = {w=0.055/screenAspect, h=0.055}    
    local orderMenu = {x=minimapW, y=1-3*orderMenuButton.h, w=nil, h=nil} 
    local orderGrid = {rows=1, cols=21} -- it might override 
    
    local resBars = {x=1-0.3, y=0, w=0.3, h=0.09}

    local consoleLeft = stateMenu.x+stateMenu.w+0.05
    local consoleRight = resBars.x
    local console = {x=consoleLeft, y=0, w=max(0,consoleRight-consoleLeft), h=0.15}
    local chonsole = {x=consoleLeft, y=console.h, w=console.w, h=nil}
    
    UIcoords = {
        minimap=minimap, sInfo=sInfo, 
        buildMenu=buildMenu, buildGrid=buildGrid,
        facBarButton=facBarButton,
        stateMenu=stateMenu, stateMenuButton=stateMenuButton, stateGrid=stateGrid,
        orderMenu=orderMenu, orderMenuButton=orderMenuButton, orderGrid=orderGrid,
        resBars=resBars,
        console=console, chonsole=chonsole,
    }

end


-------------------------------------
-- inverted2 WIP -- needs (WIP) horizontal build menu
function Inverted2()
    local minimapW,minimapH = GetMinimapDimensions(0.12, 0.28, 0.12, 0.28)
    local minimap = {x=0, y=1-minimapH, w=minimapW, h=minimapH}
    local sInfo = {x=0, y=0, w=0.2/screenAspect, h=0.2}
    
    local buildMenu = {x=minimapW, y=1-minimapH, w=nil, h=minimapH} 
    local buildGrid = {wantedRows=4, wantedCols=4, paddingRows=0, paddingCols=0, maxRows=4, maxCols=6}
    
    local facBarButton = {h=0.06}

    local stateMenuButton = {w=min(0.1,70/vsy), h=0.02}
    local stateMenu = {x=sInfo.w, y=0, w=stateMenuButton.w, h=sInfo.h}
    local stateGrid = {orientation="top"}

    local orderMenuButton = {w=0.055/screenAspect, h=0.055}    
    local orderMenu = {x=0, y=minimap.y-3*orderMenuButton.h, w=nil, h=nil}
    local orderGrid = {rows=3, cols=8} -- it might override 
    
    local resBars = {x=1-0.3, y=0, w=0.3, h=0.09}

    local consoleLeft = stateMenu.x+stateMenu.w+0.05
    local consoleRight = resBars.x
    local console = {x=consoleLeft, y=0, w=max(0,consoleRight-consoleLeft), h=0.15}
    local chonsole = {x=consoleLeft, y=console.h, w=console.w, h=nil}
    
    UIcoords = {
        minimap=minimap, sInfo=sInfo, 
        buildMenu=buildMenu, buildGrid=buildGrid,
        facBarButton=facBarButton,
        stateMenu=stateMenu, stateMenuButton=stateMenuButton, stateGrid=stateGrid,
        orderMenu=orderMenu, orderMenuButton=orderMenuButton, orderGrid=orderGrid,
        resBars=resBars,
        console=console, chonsole=chonsole,
    }
end

-------------------------------------
-- new1 another WIP -- needs (WIP) horizontal build menu

function New1()    
    local minimapW,minimapH = GetMinimapDimensions(0.12, 0.27, 0.12, 0.27)
    local minimap = {x=0, y=0, w=minimapW, h=minimapH}
    local sInfo = {x=0, y=1-minimapH, w=minimapH/screenAspect, h=minimapH}
    
    local buildMenu = {x=sInfo.w, y=1-minimapH, w=nil, h=minimapH} 
    local buildGrid = {wantedRows=4, wantedCols=4, paddingRows=0, paddingCols=0, maxRows=4, maxCols=6}
    
    local facBarButton = {h=0.06}

    local stateMenuButton = {w=min(0.1,70/vsy), h=0.02}
    local stateMenu = {x=0, y=minimapH, w=stateMenuButton.w, h=minimapH}
    local stateGrid = {orientation="bottom"}

    local orderMenuButton = {w=0.055/screenAspect, h=0.055}    
    local orderMenu = {x=0, y=1-sInfo.h-3*orderMenuButton.h, w=nil, h=nil}
    local orderGrid = {rows=3, cols=8} -- it might override 
    
    local resBars = {x=1-0.3, y=0, w=0.3, h=0.09}

    local consoleLeft = minimapW+0.05
    local consoleRight = resBars.x
    local console = {x=consoleLeft, y=0, w=max(0,consoleRight-consoleLeft), h=0.15}
    local chonsole = {x=consoleLeft, y=console.h, w=console.w, h=nil}
    
    UIcoords = {
        minimap=minimap, sInfo=sInfo, 
        buildMenu=buildMenu, buildGrid=buildGrid,
        facBarButton=facBarButton,
        stateMenu=stateMenu, stateMenuButton=stateMenuButton, stateGrid=stateGrid,
        orderMenu=orderMenu, orderMenuButton=orderMenuButton, orderGrid=orderGrid,
        resBars=resBars,
        console=console, chonsole=chonsole,
    }
end
-------------------------------------
-- New2 another WIP -- needs (WIP) horizontal build menu

function New2()    
    local minimapW,minimapH = GetMinimapDimensions(0.12, 0.27, 0.12, 0.27)
    local minimap = {x=0, y=0, w=minimapW, h=minimapH}

    local sInfoH = 0.23
    local sInfo = {x=0, y=max(minimapH,0.2), w=sInfoH/screenAspect, h=sInfoH}

    local buildMenu = {x=0, y=1-minimapH, w=nil, h=minimapH} 
    local buildGrid = {wantedRows=4, wantedCols=4, paddingRows=0, paddingCols=0, maxRows=4, maxCols=6}
    
    local facBarButton = {h=0.06}

    local stateMenuButton = {w=min(0.1,70/vsy), h=0.02}
    local stateMenu = {x=sInfo.w, y=sInfo.y, w=stateMenuButton.w, h=sInfo.h}
    local stateGrid = {orientation="top"}
    
    local orderMenuButton = {w=0.055/screenAspect, h=0.055}        
    local orderMenu = {x=0, y=buildMenu.y-3*orderMenuButton.h, w=nil, h=nil}
    local orderGrid = {rows=3, cols=8} -- it might override 
    
    local resBars = {x=1-0.3, y=0, w=0.3, h=0.09}

    local consoleLeft = minimapW+0.05
    local consoleRight = resBars.x
    local console = {x=consoleLeft, y=0, w=max(0,consoleRight-consoleLeft), h=0.15}
    local chonsole = {x=consoleLeft, y=console.h, w=console.w, h=nil}
    
    UIcoords = {
        minimap=minimap, sInfo=sInfo, 
        buildMenu=buildMenu, buildGrid=buildGrid,
        facBarButton=facBarButton,
        stateMenu=stateMenu, stateMenuButton=stateMenuButton, stateGrid=stateGrid,
        orderMenu=orderMenu, orderMenuButton=orderMenuButton, orderGrid=orderGrid,
        resBars=resBars,
        console=console, chonsole=chonsole,
    }
end


-------------------------------------
-- callins etc

function SetLayout(layout)
    local oldLayout = options.layout
    layout = layout or options.layout
    options.layout = layout
    
    if layout=="classic" then Classic()
    elseif layout=="classic2" then Classic2()
    elseif layout=="inverted" then Inverted()
    elseif layout=="inverted2" then Inverted2()
    elseif layout=="new1" then New1()
    elseif layout=="new2" then New2()
    end
    
    WG.UIcoords = ApplyViewGeometry(UIcoords)
    WG.UIcoords.layout = layout
    WG.UIcoords.SetLayout = SetLayout
    
    if initialized and oldLayout~=layout then
        for name,wData in pairs(widgetHandler.knownWidgets) do
            local _, _, category = string.find(wData.basename, '([^_]*)')
            if category=='bgu' and wData.active then
                widgetHandler:ToggleWidget(name)
                widgetHandler:ToggleWidget(name)
            end        
        end 
    end
end

function widget:Initialize()
    vsx,vsy = Spring.GetViewGeometry()
    screenAspect = vsx/vsy

    WG.UIcoords = {}
    WG.UIcoords.SetLayout = SetLayout
    
    WG.RelativeFontSize = RelativeFontSize
    
    SetLayout()
    
    initialized = true
end

function RelativeFontSize(i)
    -- set font sizes relative to vsy=1000
    local size = i*vsy/1000
    size = floor(size+0.5)
    return size
end

function widget:ViewResize(x, y)
    vsx = x
    vsy = y
    screenAspect = vsx/vsy
    SetLayout()       
end

function widget:GetConfigData()
    return options
end

function widget:SetConfigData(data)
    if data then
        options = data
    end
end
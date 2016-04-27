
function widget:GetInfo()
	return {
		name      = "Chili Skin Colours",
		desc      = "Provides additional colours in WG for use in Chili",
		author    = "Bluestone",
		date      = "socks",
		license   = "GPLv2",
		layer     = -999,
		enabled   = true, 
        api       = true,
        handler   = true,
	}
end

local min = math.min
local max = math.max

local spec = Spring.GetSpectatingState()
if spec then tr=0.8;tg=0.8;tb=0.8; end

function GetTableIdx(t, val)
    for k,v in pairs(t) do
        if (v==val) then return k end
    end
    return nil
end

    
local initialized

local options = { --defaults
    mode = "black", 
    alpha = "high", 
    tint = "weak", 
}

local optionLists = {
    mode = {"black", "white"},
    alpha = {"low", "med", "high", "max"},
    tint = {"none", "weak", "strong"},
    selected = {},
}

local colourBank = {
    white = {1,1,1,1},
    grey = {0.5,0.5,0.5,1},
    darkgrey = {0.2,0.2,0.2,1},
    black = {0,0,0,1},
   
    green = {0,1,0,1},
    yellow = {1,1,0,1},
    red = {1,0,0,1},
    blue = {0,0,1,1},
   
    orange = {1,0.5,0,1},
    darkgreen = {0,0.8,0,1},
    lightblue = {0.8,0.8,1,1},
    darkblue = {0.4,0.4,1,1},
    lilac = {0.8,0.65,0.8,1},
    tomato = {1,0.4,0.3,1},
    turqoise = {0.2,0.84,0.8,1}, 
	
	focusOrange = {1.0, 0.7, 0.1, 0.8},
}

local modes = {
    black = {
        buttonColour = colourBank.black,
        panelColour = colourBank.black,
        sliderColour = colourBank.white,    
    },
    white = {
        buttonColour = colourBank.white,
        panelColour = colourBank.white,
        sliderColour = colourBank.white,
    },
}

local alphas = {
    low = {
        buttonColour = 0.15,
        panelColour = 0.25,
        sliderColour = 0.4,
    },
    med = {
        buttonColour = 0.4,
        panelColour = 0.5,
        sliderColour = 0.6,
    },
    high = {
        buttonColour = 0.8,
        panelColour = 0.8,
        sliderColour = 0.85,
    },
    max = {
        buttonColour = 1,
        panelColour = 1,
        sliderColour = 1,
    },
}

local tints = {
    none = {
        buttonColour = 0,
        panelColour = 0,
        sliderColour = 0,
    },
    weak = {
        buttonColour = 0.05,
        panelColour = 0.05,
        sliderColour = 0.05,
    },
    strong = {
        buttonColour = 0.12,
        panelColour = 0.12,
        sliderColour = 0.12,
    },
}

local colours = {
    buttonColour = {1,1,1,1}, -- for buttons
    panelColour = {1,1,1,1}, -- for panels & windows (= buttonColour with a bit more alpha)
    sliderColour = {1,1,1,1}, -- for sliders *and* buttons that are inside panels and windows
}

function SetSkinColours(mode, tint, alpha)
    if mode then 
        options.mode = mode
    end
    if tint then 
        options.tint = tint 
    end
    if alpha then 
        options.alpha = alpha
    end
    optionLists.selected.mode = GetTableIdx(optionLists.mode, options.mode)
    optionLists.selected.tint = GetTableIdx(optionLists.tint, options.tint)
    optionLists.selected.alpha = GetTableIdx(optionLists.alpha, options.alpha)
end

function BlendColours(material)
    -- blend in alpha and team colour
    local baseColour = modes[options.mode][material]
    local tr,tg,tb = Spring.GetTeamColor(Spring.GetMyTeamID())
    local tcol = {tr,tg,tb}
    local teamColourSaturation = tints[options.tint][material]
    local col = {} 
    for i=1,3 do
        col[i] = (1-teamColourSaturation)*baseColour[i] + teamColourSaturation*tcol[i]
    end
    col[4] = alphas[options.alpha][material]
    return col
end

function ExposeColours() --internal
    -- calculate the colours based on current options & expose to WG
    SetSkinColours()
    for material,_ in pairs(modes[options.mode]) do
        colours[material] = BlendColours(material) 
    end
    
    WG.buttonColour = colours.buttonColour
    WG.panelColour = colours.panelColour
    WG.sliderColour = colours.sliderColour
end

function ExposeNewSkinColours()
    -- expose colours & reload widgets that use them
    if initialized then
        ExposeColours()
        
        for name,wData in pairs(widgetHandler.knownWidgets) do
            local _, _, category = string.find(wData.basename, '([^_]*)')
            if category=='bgu' and wData.active then
                widgetHandler:ToggleWidget(name)
                widgetHandler:ToggleWidget(name)
            end        
        end 
    end
end

function GetSkinColours()
    return options.mode, options.tint, options.alpha
end

function GetSkinOptionLists()
    return optionLists
end


function widget:SetConfigData(data)
    if data then
        options = data
    end
end

function widget:Initialize()
    ExposeColours()
    
    WG.SetSkinColours = SetSkinColours 
    WG.GetSkinColours = GetSkinColours
    WG.GetSkinOptionLists = GetSkinOptionLists
    WG.ExposeNewSkinColours = ExposeNewSkinColours
    
    initialized = true
end

function widget:Shutdown()
    WG.SetSkinColours = nil 
    WG.GetSkinColours = nil  
    WG.GetSkinOptionLists = nil
    WG.ExposeNewSkinColours = nil
end

function widget:GetConfigData()
    return options
end


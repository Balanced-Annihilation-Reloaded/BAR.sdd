
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
	}
end

local tr,tg,tb = Spring.GetTeamColor(Spring.GetMyTeamID())
local teamColour = {tr,tg,tb,1}


local options = { --defaults
    mode = "black", --"white, ""black", "team"
    alpha = "high", --"low", "med", "high", "max"
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
        buttonColour = 0.7,
        panelColour = 0.8,
        sliderColour = 0.85,
    },
    max = {
        buttonColour = 1,
        panelColour = 1,
        sliderColour = 1,
    }
}

local modes = {
    white = {
        buttonColour = colourBank.white,
        panelColour = colourBank.white,
        sliderColour = colourBank.white,
    },
    black = {
        buttonColour = colourBank.black,
        panelColour = colourBank.black,
        sliderColour = colourBank.white,    
    },
    team = {
        buttonColour = teamColour,
        panelColour = teamColour,
        sliderColour = teamColour,        
    },
}


local colours = {
    buttonColour = {1,1,1,1}, -- for buttons
    panelColour = {1,1,1,1}, -- for panels & windows (= buttonColour with a bit more alpha)
    sliderColour = {1,1,1,1}, -- for sliders *and* buttons that are inside panels and windows
}

function SetSkinColourMode(mode)
    options.mode = mode
    for material,c in pairs(modes[options.mode]) do
        colours[material] = {c[1],c[2],c[3],1} 
    end
end

function SetSkinAlphaMode(alpha)
    options.alpha = alpha
    for material,a in pairs(alphas[options.alpha]) do
        colours[material][4] = a 
    end
end

function ExposeColours() --internal
    WG.buttonColour = colours.buttonColour
    WG.panelColour = colours.panelColour
    WG.sliderColour = colours.sliderColour
end

function ExposeNewSkinColours()
    Spring.SendCommands("luarules reloadluaui") -- force reload *all* widgets, which can then redraw their controls with the new colours, which will be saved, loaded and then exposed!
end

function GetSkinColourMode()
    return options.mode
end

function GetSkinAlphaMode()
    return options.alpha
end

function widget:SetConfigData(data)
    if data then
        options = data
    end
end

function widget:Initialize()
    SetSkinColourMode(options.mode)
    SetSkinAlphaMode(options.alpha)
    ExposeColours()
 
    WG.GetSkinColourMode = GetSkinColourMode 
    WG.GetSkinAlphaMode = GetSkinAlphaMode 
    WG.SetSkinColourMode = SetSkinColourMode
    WG.SetSkinAlphaMode = SetSkinAlphaMode 
    WG.ExposeNewSkinColours = ExposeNewSkinColours
end

function widget:GetConfigData()
    return options
end


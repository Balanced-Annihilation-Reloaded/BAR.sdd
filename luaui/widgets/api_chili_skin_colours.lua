
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
        buttonColour = 0.3,
        panelColour = 0.4,
        sliderColour = 0.6,
    },
    high = {
        buttonColour = 0.6,
        panelColour = 0.7,
        sliderColour = 0.8,
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


local cfg = {
    mode = "black", --"white, ""black", "team"
    alpha = "high", --"low", "med", "high", "max"
}

local colours = {
    buttonColour = {1,1,1,1},
    panelColour = {1,1,1,1},
    sliderColour = {1,1,1,1},

}

function widget:Initialize()
    local mode = cfg.mode
    local alpha = cfg.alpha  
    for material,c in pairs(modes[mode]) do
        colours[material] = {c[1],c[2],c[3],1} 
    end
    for material,a in pairs(alphas[alpha]) do
        colours[material][4] = a 
    end
    
    WG.buttonColour = colours.buttonColour
    WG.panelColour = colours.panelColour
    WG.sliderColour = colours.sliderColour
 
    local Chili = WG.Chili
    Spring.Echo(Chili, Chili.Skin)
end


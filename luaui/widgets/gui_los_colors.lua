function widget:GetInfo()
    return {
        name      = "LOS colors",
        desc      = "Controls colors shown for LOS and related stuff",
        author    = "Bluestone", --using colour profiles from BAs widget
        date      = "",
        license   = "GPL v2 or later",
        layer     = 0,
        enabled   = true  
    }
end

local options = {
    -- with default values
    showRadarAsSpec = true,
    extraSaturation = true,
}

local originalColors, colors
local spSetLosViewColors = Spring.SetLosViewColors
local spec,_ = Spring.GetSpectatingState()

local initialized = false
local Chili, Menu


local losColors = {
    always = {0.20, 0.20, 0.20},
    los =    {0.20, 0.20, 0.20},
    radar =  {0.17, 0.17, 0.17},
    jam =    {0.12, 0.00, 0.00},
    radar2 = {0.17, 0.17, 0.17},
}

local losColorsExtraSaturation = {
    always = {0.20, 0.20, 0.20},
    los =    {0.22, 0.14, 0.30},
    radar =  {0.08, 0.16, 0.00},
    jam =    {0.20, 0.00, 0.00},
    radar2 = {0.08, 0.16, 0.00},
}

local losColorsWithoutRadars = {
    always = {0.30, 0.30, 0.30},
    los =    {0.25, 0.25, 0.25},
    radar =  {0.00, 0.00, 0.00},
    jam =    {0.12, 0.00, 0.00},
    radar2 = {0.00, 0.00, 0.00},
}


function TurnOnLOS()
    if Spring.GetMapDrawMode()~="los" then
        Spring.SendCommands("togglelos")
    end
end

function TurnOffLOS()
    if Spring.GetMapDrawMode()=="los" then
        Spring.SendCommands("togglelos")
    end
end

function resetColorsLOS()
    if spec and not showRadarAsSpec then
        --Spring.Echo(1)
        colors = losColorsWithoutRadars
    elseif options.extraSaturation then
        --Spring.Echo(2)
        colors = losColorsExtraSaturation
    else
        --Spring.Echo(3)
        colors = losColors
    end
    
    spSetLosViewColors(colors.always, colors.los, colors.radar, colors.jam, colors.radar2)
end

function ToggleRadarAsSpec()
    options.showRadarAsSpec = not options.showRadarAsSpec
    resetColorsLOS()
end

function ToggleExtraSaturation()
    options.extraSaturation = not options.extraSaturation
    resetColorsLOS()
end



function widget:Initialize()
    local always, los, radar, jam, radar2 = Spring.GetLosViewColors()
    originalColors = {always=always,los=los,radar=radar,jam=jam,radar2=radar2}
    colors = {always=always,los=los,radar=radar,jam=jam,radar2=radar2}
    
    if Spring.GetGameFrame()>0 then
        TurnOnLOS()
    end

    Chili  = WG.Chili
    if not Chili then return end
    screen = Chili.Screen0
    Menu   = WG.MainMenu
    if not Menu then return end
    
    Menu.AddWidgetOption{
            title = 'LOS Colors',
            name = widget:GetInfo().name,
            children = {
                Chili.Checkbox:New{caption='Show radar as spec',x='10%',width='80%',
                        checked=options.showRadarAsSpec,OnChange={function() ToggleRadarAsSpec() end}}, 
                Chili.Checkbox:New{caption='Extra saturation',x='10%',width='80%',
                        checked=options.extraSaturation,OnChange={function() ToggleExtraSaturation() end}},
        }
    }
        
    resetColorsLOS()
    initialized = true
end

function widget:GameStart()
    TurnOnLOS()
end

function widget:SetConfigData(data)
    for k,v in pairs(options) do
        Spring.Echo(k, options[k], data[k])
        if data[k]~=nil then options[k] = data[k] end
    end
end

function widget:PlayerChanged()
    local prevSpec = spec
    spec,_ = Spring.GetSpectatingState()
    if prevSpec ~= spec then
        resetColorsLOS()
    end
end

function widget:Shutdown()
    spSetLosViewColors(originalColors.always, originalColors.los, originalColors.radar, originalColors.jam, originalColors.radar2)
    TurnOffLOS()
end

function widget:GetConfigData()
    return options
end



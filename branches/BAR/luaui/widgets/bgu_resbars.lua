-- WIP
function widget:GetInfo()
    return {
        name    = 'Resource Bars',
        desc    = 'Displays resource and resource sharing bars',
        author  = 'Funkencool',
        date    = '2013',
        license = 'GNU GPL v2',
        layer = 0,
        enabled = true,
    }
end
-------------------------------------------
-- Chili vars
-------------------------------------------
local Chili, resourceWindow
-------------------------------------------
-- Local vars
-------------------------------------------
local spGetTeamResources = Spring.GetTeamResources
local spGetMyTeamID      = Spring.GetMyTeamID

local image = {
    metal  = 'luaui/images/resourcebars/Ibeam.png',
    energy = 'luaui/images/resourcebars/lightning.png',
    }
local conversionPic  = "LuaUI/Images/EMconversion.png"

local meter        = {}
local incomeLabel  = {}
local expenseLabel = {}
local netLabel     = {}
local shareLevel   = {}
local myTeamID = spGetMyTeamID()
local settings = {}
-- Colors
local green        = {0.2, 1.0, 0.2, 1.0}
local red          = {1.0, 0.2, 0.2, 1.0}
--local greenOutline = {0.2, 1.0, 0.2, 0.2}
--local redOutline   = {1.0, 0.2, 0.2, 0.2}
local fullyLoaded = false -- to stop making "set X to Y" remarks when we are just reloading the config on init
--

local buttonColour, panelColour, sliderColour 

-------------------------------------------
-- Auxiliary functions
-------------------------------------------
function round(num, idp)
  return string.format("%." .. (idp or 0) .. "f", num)
end
local function readable(num)
    local s = ""
    if num < 0 then
        s = '-'
    elseif num < 0 then
        s = '+'
    end
    num = math.abs(num)
    if num <= 1000 then
        s = s .. round(num,1)
    elseif num >100000 then
        s = s .. round(num/1000,0)..'k'
    elseif num >1000 then
        s = s .. round(num/1000,1)..'k'
    else
        s = s .. round(num,0)
    end
    return s
end
-------------------------------------------
-- Main
-------------------------------------------
local function ToggleconversionWindow()
    if conversionWindow.hidden then
        conversionWindow:Show()
        resourceWindow:Hide()
    else
        conversionWindow:Hide()    
        resourceWindow:Show()
    end
    return true
end

local function initWindow()
    local screen0 = Chili.Screen0
    
    resourceWindow = Chili.Button:New{
        parent    = screen0,
        right     = 0, 
        y         = 0, 
        width     = 450, 
        height    = 80, 
        minHeight = 20, 
        padding   = {0,0,0,0},
        borderColor = buttonColour,
        backgroundColor = buttonColour,
        caption = "",
        OnClick = {ToggleconversionWindow},
    }

end

local function makeBar(res, barX, barY)
    
    local control = Chili.Control:New{
        parent    = resourceWindow,
        name      = res,
        x         = barX,
        y         = barY,
        height    = 32,
        minHeight = 20, 
        width     = 430,
        padding   = {0,0,0,0},
    }
    
    meter[res] = Chili.Progressbar:New{
        parent = control, 
        x      = 122, 
        height = 20, 
        bottom = 5, 
        right  = 3,
    }
    
    Chili.Image:New{
        file   = image[res],
        height = 24,
        width  = 24,
        right  = 308, 
        y      = 3, 
        parent = control
    }
    
    netLabel[res] = Chili.Label:New{
        caption = "",
        right   = 373,
        bottom  = 7,
        parent  = control,
        height  = 16,
        font    = {
            size = 15,
            outline          = true,
            autoOutlineColor = true,
            outlineWidth     = 5,
            outlineWeight    = 3,        
        }
    }
    
    incomeLabel[res] = Chili.Label:New{
        caption  = '+0.0',
        right    = 332, 
        y        = 0,
        parent   = control,
        align    = 'right',
        --height   = 13,
        font     = {
            size         = 14,
            color        = green,
            outline          = true,
            autoOutlineColor = true,
            outlineWidth     = 5,
            outlineWeight    = 3,
        },
    }

    expenseLabel[res] = Chili.Label:New{
        caption  = '-0.0',
        right    = 332,
        bottom   = 0,
        parent   = control,
        align    = 'right',
        --height   = 13,
        font     = {
            size         = 14,
            color        = red,
            outline          = true,
            autoOutlineColor = true,
            outlineWidth     = 5,
            outlineWeight    = 3,
        },
    }
    
end

local function makeconversionWindow()
    conversionWindow = Chili.Button:New{
        parent = Chili.Screen0,
        height = 80,
        width = 450,
        right = 0,
        y = 0,
        padding = {10,10,10,10},
        borderColor = buttonColour,
        backgroundColor = buttonColour,
        caption = "",
        OnClick = {ToggleconversionWindow},
    }    
    
    local function SetConversion(obj, value)
        local alterLevelFormat = string.char(137) .. '%i'
        Spring.SendLuaRulesMsg(string.format(alterLevelFormat, value))
        if fullyLoaded then
            Spring.Echo("Conversion of energy to metal will only occur when energy is above " .. round(value) .. "% full")
        end
    end
    
    local function SetEShare (obj, value)
        Spring.SetShareLevel('energy', value)
        if fullyLoaded then
            Spring.Echo("Energy will be shared to allies when over " .. round(value) .. "% full")
        end
    end

    local function SetMShare (obj, value)
        Spring.SetShareLevel('metal', value)        
        if fullyLoaded then
            Spring.Echo("Metal will be shared to allies when over " .. round(value) .. "% full")
        end
    end
    
    conversionText = Chili.TextBox:New{
        parent = conversionWindow,
        x = 10,
        y = 10,
        height = 18,
        width = 212,
        text = " E to M conversion above this %",
        font = {
            size = 12,
        }    
    }

    conversionSlider = Chili.Trackbar:New{
        parent = conversionWindow,
        height = 25,
        width = 207,
        x = 5,
        y = 27,
        min = 0,
        max = 100,
        step = 5,
        value = 90,
        onchange = {SetConversion},
    }
    
    shareText = Chili.TextBox:New{
        parent = conversionWindow,
        x = 228,
        y = 10,
        height = 18,
        width = 190,
        text = "share (E,M) to allies above this %",
        font = {
            size = 12,
        }    
    }

    EshareSlider = Chili.Trackbar:New{
        parent = conversionWindow,
        height = 25,
        width = 97,
        x = 222,
        y = 27,
        min = 0,
        max = 100,
        step = 5,
        value = 95,
        onchange = {SetEShare},
    }

    MshareSlider = Chili.Trackbar:New{
        parent = conversionWindow,
        height = 25,
        width = 97,
        x = 222+97+5,
        y = 27,
        min = 0,
        max = 100,
        step = 5,
        value = 95,
        onchange = {SetMShare},
    }

    conversionWindow:Hide()
end

-- Updates 
local function setBar(res)
    local currentLevel, storage, pull, income, expense, share = spGetTeamResources(myTeamID, res)
    
    -- set everything to 0 if nil (eg. we are a spec and not watching anyone)
    currentLevel = currentLevel or 0
    storage = storage or 0
    pull = pull or 0
    income = income or 0
    expense = expense or 0
    share = share or 0

    
    local net = income-expense
    
    if net > 0 then
        -- if there is a net gain
        netLabel[res].font.color = green
    else
        -- if there is a net loss
        netLabel[res].font.color = red
    end
    
    netLabel[res]:SetCaption(readable(net))
    incomeLabel[res]:SetCaption(readable(income))
    expenseLabel[res]:SetCaption(readable(-pull))
    
    meter[res]:SetValue(currentLevel/storage*100)
    meter[res]:SetCaption(math.floor(currentLevel)..'/'..storage)
end
function SetBarColors()
    meter['metal']:SetColor(0.6,0.6,0.8,.8)
    meter['energy']:SetColor(1,1,0.3,.6)
end
-------------------------------------------
-- Callins
-------------------------------------------
function widget:GameFrame(n)
    myTeamID = spGetMyTeamID()
    setBar('metal')
    setBar('energy')
end

function SetValues()
    if not settings[1] then return end
    EshareSlider:SetValue(settings[1])
    MshareSlider:SetValue(settings[2])
    conversionSlider:SetValue(settings[3])
end

function widget:Initialize()
    Spring.SendCommands('resbar 0')
    Chili = WG.Chili
    buttonColour = WG.buttonColour

    initWindow()
    makeBar('metal',10,9)
    makeBar('energy',10,39)
    makeconversionWindow()
    if Spring.GetGameFrame()>0 then
        SetBarColors()
    else
        meter['metal']:SetColor(0.0,0.6,0.9,.8)
        meter['energy']:SetColor(0.0,0.6,0.9,.8)        
    end
    SetValues()
    
    fullyLoaded = true
end

function widget:KeyPress()
    if resourceWindow.hidden then
        ToggleconversionWindow()
    end
end

function widget:GameStart()
    SetBarColors()
end

function widget:Shutdown()
    Spring.SendCommands('resbar 1')
end

function widget:GetConfigData()
    settings[1] = EshareSlider.value
    settings[2] = MshareSlider.value
    settings[3] = conversionSlider.value    
    return settings
end

function widget:SetConfigData(data)
    settings = data
end

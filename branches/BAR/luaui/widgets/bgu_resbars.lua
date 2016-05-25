function widget:GetInfo()
    return {
        name    = 'Resource Bars',
        desc    = 'Displays resource and resource sharing bars',
        author  = 'Funkencool, Bluestone',
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
local spGetSpectatingState = Spring.GetSpectatingState

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
local myTeamID -- don't set yet, it forces an update when changed
local spec = spGetSpectatingState()
local settings = {}
-- Colors
local green        = {0.2, 1.0, 0.2, 1.0}
local red          = {1.0, 0.2, 0.2, 1.0}
--local greenOutline = {0.2, 1.0, 0.2, 0.2}
--local redOutline   = {1.0, 0.2, 0.2, 0.2}
local fullyLoaded = false -- to stop making "set X to Y" remarks when we are just reloading the config on init
--

local buttonColour, panelColour, sliderColour, teamColourPic
local smallFontSize, largeFontSize
local smallRelFontSize, largeRelFontSize = 14, 16

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
    if resourceWindow.hidden then
        conversionWindow:Hide()    
        resourceWindow:Show()
    elseif not spec then
        conversionWindow:Show()
        resourceWindow:Hide()
    end
    return true
end

local resources = {"metal", "energy"}
local function ResizeUI()
    local x = WG.UIcoords.resBars.x
    local y = WG.UIcoords.resBars.y
    local w = WG.UIcoords.resBars.w
    local h = WG.UIcoords.resBars.h
    resourceWindow:SetPos(x,y,w,h)
    conversionWindow:SetPos(x,y,w,h)
    
    smallFontSize = WG.RelativeFontSize(smallRelFontSize)
    largeFontSize = WG.RelativeFontSize(largeRelFontSize)

    for _,resName in pairs(resources) do
        netLabel[resName].font.size = largeFontSize,
        netLabel[resName]:Invalidate()
    end
    
    for _,resName in pairs(resources) do
        incomeLabel[resName].font.size = smallFontSize,
        incomeLabel[resName]:Invalidate()
        expenseLabel[resName].font.size = smallFontSize,
        expenseLabel[resName]:Invalidate()
    end
end

local function initWindow()
    resourceWindow = Chili.bguButton:New{
        parent    = Chili.Screen0,
        padding   = {0,0,0,0},
        borderColor = buttonColour,
        backgroundColor = buttonColour,
        focusColor = spec and buttonColour or focusColor,
        caption = "",
        OnClick = {ToggleconversionWindow},
    }
end

local function makeBar(res, barY, top)
    
    local control = Chili.Control:New{
        parent    = resourceWindow,
        name      = res,
        x         = '0%',
        y         = barY,
        height    = '50%',
        width     = '100%',
        padding   = {0,0,0,0},
        margin    = {0,0,0,0},
    }
    
    meter[res] = Chili.Progressbar:New{
        parent = control, 
        x = '30%', 
        y = top and '40%' or '10%',
        height = '50%', 
        width = '68%'
    }
    
    Chili.Image:New{
        file   = image[res],
        x      = '24%',
        y      = top and '20%' or '0%',
        height = '80%',
        width  = '5%',
        parent = control
    }
    
    
    netLabel[res] = Chili.Label:New{
        caption = "",
        x = '4%',
        y = top and '40%' or '22%',
        width = '10%',
        parent  = control,
        align    = 'right',
        font    = {
            size = smallFontSize,
            outline          = true,
            autoOutlineColor = true,
            outlineWidth     = 5,
            outlineWeight    = 3,        
        }
    }
    
    incomeLabel[res] = Chili.Label:New{
        caption  = '+0.0',
        x = '14%',
        y = top and '60%' or '40%',
        width = '10%',
        parent   = control,
        align    = 'right',
        --height   = 13,
        font     = {
            size         = smallFontSize,
            color        = green,
            outline          = true,
            autoOutlineColor = true,
            outlineWidth     = 5,
            outlineWeight    = 3,
        },
    }

    expenseLabel[res] = Chili.Label:New{
        caption  = '-0.0',
        x = '14%',
        y = top and '20%' or '2%',
        width = '10%',
        parent   = control,
        align    = 'right',
        --height   = 13,
        font     = {
            size         = largeFontSize,
            color        = red,
            outline          = true,
            autoOutlineColor = true,
            outlineWidth     = 5,
            outlineWeight    = 3,
        },
    }
    
end

local function makeconversionWindow()
    conversionWindow = Chili.bguButton:New{
        parent = Chili.Screen0,
        padding = {0,0,0,0},
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
        x = '4%',
        y = '30%',
        width = '47%',
        text = " E to M conversion threshold",
        font = {
            size = 12,
        }    
    }

    conversionSlider = Chili.Trackbar:New{
        parent = conversionWindow,
        height = '30%',
        width = '46%',
        x = '4%',
        y = '42%',
        min = 0,
        max = 100,
        step = 5,
        value = 90,
        onchange = {SetConversion},
    }
    
    shareText = Chili.TextBox:New{
        parent = conversionWindow,
        x = '52%',
        y = '30%',
        width = '50%',
        text = "share (E,M) to allies thresholds",
        font = {
            size = 12,
        }    
    }

    EshareSlider = Chili.Trackbar:New{
        parent = conversionWindow,
        height = '30%',
        width = '21%',
        x = '75%',
        y = '42%',
        min = 0,
        max = 100,
        step = 5,
        value = 95,
        onchange = {SetEShare},
    }

    MshareSlider = Chili.Trackbar:New{
        parent = conversionWindow,
        height = '30%',
        width = '21%',
        x = '52%',
        y = '42%',
        min = 0,
        max = 100,
        step = 5,
        value = 95,
        onchange = {SetMShare},
    }

    conversionWindow:Hide()
end

-- Updates 
local function setBar(res, updateText)
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
    
    meter[res]:SetValue(currentLevel/storage*100)
    meter[res]:SetCaption(math.floor(currentLevel)..'/'..storage)

    if not updateText then return end -- we only need to update res text just after a slow update occurs

    local netText = readable(net)
    local incomeText = readable(income)
    local pullText = readable(-pull)     

    netLabel[res]:SetCaption(netText)
    incomeLabel[res]:SetCaption(incomeText)
    expenseLabel[res]:SetCaption(pullText)
end
function SetBarColors()
    meter['metal']:SetColor(0.6,0.6,0.8,.8)
    meter['energy']:SetColor(1,1,0.3,.6)
end
-------------------------------------------
-- Callins
-------------------------------------------
function widget:GameFrame(n)    
    local newTeamID = spGetMyTeamID()
    local updateText = (myTeamID ~= newTeamID) or (n%30==1) -- team change or slow update
    
    if myTeamID~= newTeamID then    
        if teamColourPic then
            resourceWindow:RemoveChild(teamColourPic)
        end
        local r,g,b = Spring.GetTeamColor(newTeamID)
        teamColourPic = Chili.Image:New{
            parent = resourceWindow,
            name = 'teamColourPic',
            height = 10,
            width = 10,
            x=10,
            y=10,
            file = "LuaUI/Images/playerlist/default.png", --TODO
            color = {r,g,b},
        }    
    end
    myTeamID = newTeamID
    
    setBar('metal',updateText)
    setBar('energy',updateText)
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
    smallFontSize = WG.RelativeFontSize(smallRelFontSize)
    largeFontSize = WG.RelativeFontSize(largeRelFontSize)

    initWindow()
    makeBar('metal','0%', true)
    makeBar('energy','50%', false)
    makeconversionWindow()
    
    ResizeUI()
    
    if Spring.GetGameFrame()>0 then
        SetBarColors()
    else
        meter['metal']:SetColor(0.0,0.6,0.9,.8)
        meter['energy']:SetColor(0.0,0.6,0.9,.8)        
    end
    SetValues()
    
    fullyLoaded = true
end

function widget:ViewResize()
    ResizeUI()
end

function widget:PlayerChanged()
    spec,_ = spGetSpectatingState()
    if spec then
        resourceWindow.focusColor = buttonColour
    else
        resourceWindow.focusColor = {1.0, 0.7, 0.1, 0.5} -- todo, get from skin
    end
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

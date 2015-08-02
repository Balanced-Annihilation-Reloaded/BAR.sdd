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
local Chili, window0
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
local greenOutline = {0.2, 1.0, 0.2, 0.2}
local redOutline   = {1.0, 0.2, 0.2, 0.2}
local fullyLoaded = false -- to stop making "set X to Y" remarks when we are just reloading the config on init
--

-------------------------------------------
-- Auxiliary functions
-------------------------------------------
function format(num, idp)
  return string.format("%." .. (idp or 0) .. "f", num)
end
local function readable(num)
	local s = ""
	if num < 0 then
		s = '-'
	else
		s = '+'
	end
	num = math.abs(num)
	if num < 10 then
		s = s .. format(num,1)
	elseif num >10000 then
		s = s .. format(num/1000,0)..'K'
	elseif num >1000 then
		s = s .. format(num/1000,1)..'K'
	else
		s = s .. format(num,0)
	end
	return s
end
-------------------------------------------
-- Main
-------------------------------------------
local function ToggleConversionPanel()
    if conversionPanel.hidden then
        conversionPanel:Show()
        conversionButton2:Show()
        window0:Hide()
    else
        conversionPanel:Hide()    
        conversionButton2:Hide()
        window0:Show()
    end
    return true
end

local function initWindow()
	local screen0 = Chili.Screen0
	
	window0 = Chili.Panel:New{
		parent    = screen0,
		right     = 0, 
		y         = 0, 
		width     = 450, 
		height    = 60, 
		minHeight = 20, 
		padding   = {0,0,0,0},
	}

end

local function makeBar(res, barX, barY)
	
	local control = Chili.Control:New{
		parent    = window0,
		name      = res,
		x         = barX,
		y         = barY,
		height    = 30,
		minHeight = 20, 
		width     = 420,
		padding   = {0,0,0,0},
	}
	
	meter[res] = Chili.Progressbar:New{
		parent = control, 
		x      = 110, 
		height = 20, 
		bottom = 5, 
		right  = 0,
	}
	
	Chili.Image:New{
		file   = image[res],
		height = 24,
		width  = 24,
		x      = 86, 
		y      = 3, 
		parent = control
	}
	
	netLabel[res] = Chili.Label:New{
		caption = "",
		right   = 380,
        bottom  = 7,
		parent  = control,
        height  = 16,
        font    = {size = 15}
	}
	
	incomeLabel[res] = Chili.Label:New{
		caption  = '+0.0',
		right    = 334, 
		y        = 0,
		parent   = control,
		align    = 'right',
        height   = 14,
		font     = {
			size         = 13,
			color        = green,
			outlineColor = greenOutline,
		},
	}

	expenseLabel[res] = Chili.Label:New{
		caption  = '-0.0',
		right    = 334,
		bottom   = 0,
		parent   = control,
		align    = 'right',
        height   = 14,
		font     = {
			size         = 13,
			color        = red,
			outlineColor = redOutline,
		},
	}
	
end

local function makeConversionPanel()
    conversionButton = Chili.Button:New{ --for when window0 is shown
        parent = window0,
        x = 1,
        bottom = 30-1,
        height = 30,
        width = 30,
        onclick = {ToggleConversionPanel},
        caption = "",
        padding = {6,6,6,6},
        children = {Chili.Image:New{width='100%',height='100%',file=conversionPic,keepAspect=false}},
    }
    
    conversionPanel = Chili.Window:New{
        parent = Chili.Screen0,
        height = 60,
        width = 450-30,
        right = 0,
        y = 0,
        padding = {10,10,10,10}
    }    
    
    conversionButton2 = Chili.Button:New{ --for when conversionPanel is shown
        parent = Chili.Screen0,
        right = 420-1, -- 450-
        y = 1,
        height = 30,
        width = 30,
        onclick = {ToggleConversionPanel},
        caption = "",
        padding = {6,6,6,6},
        children = {Chili.Image:New{width='100%',height='100%',file=conversionPic,keepAspect=false}},
    }

    conversionText = Chili.TextBox:New{
        parent = conversionPanel,
        x = 0,
        y = 0,
        height = 18,
        width = 197,
        text = " E to M conversion above this %",
        font = {
            size = 12,
        }    
    }
    
    local function SetConversion(obj, value)
        local alterLevelFormat = string.char(137) .. '%i'
        Spring.SendLuaRulesMsg(string.format(alterLevelFormat, value))
        if fullyLoaded then
            Spring.Echo("Conversion of energy to metal will only occur when energy is above " .. value .. "% full")
        end
    end
    
    local function SetEShare (obj, value)
        Spring.SetShareLevel('energy', value)
        if fullyLoaded then
            Spring.Echo("Energy will be shared to allies when over " .. value .. "% full")
        end
    end

    local function SetMShare (obj, value)
        Spring.SetShareLevel('metal', value)        
        if fullyLoaded then
            Spring.Echo("Metal will be shared to allies when over " .. value .. "% full")
        end
    end
    
    conversionSlider = Chili.Trackbar:New{
        parent = conversionPanel,
        height = 25,
        width = 190,
        x = 0,
        y = 18,
        min = 0,
        max = 100,
        step = 5,
        value = 90,
        onchange = {SetConversion},
    }
    
    shareText = Chili.TextBox:New{
        parent = conversionPanel,
        x = 197,
        y = 0,
        height = 18,
        width = 197,
        text = " share (E,M) to allies above this %",
        font = {
            size = 12,
        }    
    }

    EshareSlider = Chili.Trackbar:New{
        parent = conversionPanel,
        height = 25,
        width = 95,
        x = 197,
        y = 18,
        min = 0,
        max = 100,
        step = 5,
        value = 95,
        onchange = {SetEShare},
    }

    MshareSlider = Chili.Trackbar:New{
        parent = conversionPanel,
        height = 25,
        width = 95,
        x = 197+95+5,
        y = 18,
        min = 0,
        max = 100,
        step = 5,
        value = 95,
        onchange = {SetMShare},
    }

    conversionPanel:Hide()
    conversionButton2:Hide()
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
	
	-- if there is a net gain
	if net > 0 then
		netLabel[res].font.color = green
		netLabel[res].font.outlineColor = greenOutline
	-- if there is a net loss
	else
		netLabel[res].font.color = red
		netLabel[res].font.outlineColor = redOutline
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
    setBar('metal')
    setBar('energy')
end

function widget:CommandsChanged()
	myTeamID = spGetMyTeamID()
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
	initWindow()
	makeBar('metal',25,0)
	makeBar('energy',25,30)
    makeConversionPanel()
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
    if window0.hidden then
        ToggleConversionPanel()
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
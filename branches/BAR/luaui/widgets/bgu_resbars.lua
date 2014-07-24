-- WIP
function widget:GetInfo()
	return {
		name    = 'Resource Bars',
		desc    = 'Simple chili resource bars',
		author  = 'Funkencool',
		date    = '2013',
		license = 'GNU GPL v2',
		layer		= 0,
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
local meter        = {}
local incomeLabel  = {}
local expenseLabel = {}
local netLabel     = {}
local shareLevel   = {}
local myTeamID = spGetMyTeamID()
-- Colors
local green        = {0.2, 1.0, 0.2, 1.0}
local red          = {1.0, 0.2, 0.2, 1.0}
local greenOutline = {0.2, 1.0, 0.2, 0.2}
local redOutline   = {1.0, 0.2, 0.2, 0.2}
--

-------------------------------------------
-- Auxiliary functions
-------------------------------------------
local function readable(num)
	local s=''
	if num < 0 then
		s='-'
	else
		s='+'
	end
	num=math.abs(num)
	if num<10 then
		s= s .. math.floor(num) .. '.' .. math.floor((num*10)%10)
	elseif num <1000 then
		s= s .. math.floor(num)
	else 
		s=s .. math.floor(num%1000).. '.' .. math.floor((num%1000)/100)
	end
	return s
end
-------------------------------------------
-- Main
-------------------------------------------
local function initWindow()
	local screen0 = Chili.Screen0
	
	window0 = Chili.Window:New{
		parent    = screen0,
		right     = 0, 
		y         = 0, 
		width     = 450, 
		height    = 60, 
		minHeight = 20, 
		padding   = {0,0,0,0}
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
		caption = '',
		x       = 5,
		bottom  = 7,
		parent  = control,
	}
	
	incomeLabel[res] = Chili.Label:New{
		caption  = '+0.0',
		right    = 334, 
		y        = 0,
		parent   = control,
		align    = 'right',
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
		font     = {
			size         = 13,
			color        = red,
			outlineColor = redOutline,
		},
	}
	
end

-- Updates 
local function setBar(res)
	local currentLevel, storage, pull, income, expense, share = spGetTeamResources(myTeamID, res)
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
	if n%2 == 0 then
		setBar('metal')
		setBar('energy')
	end
end

function widget:CommandsChanged()
	myTeamID = spGetMyTeamID()
end

function widget:Initialize()
	Spring.SendCommands('resbar 0')
	Chili = WG.Chili
	initWindow()
	makeBar('metal',0,0)
	makeBar('energy',30,30)
    if Spring.GetGameFrame()>0 then
        SetBarColors()
    else
        meter['metal']:SetColor(0.0,0.6,0.9,.8)
        meter['energy']:SetColor(0.0,0.6,0.9,.8)        
    end
end

function widget:GameStart()
    SetBarColors()
end

function widget:Shutdown()
	Spring.SendCommands('resbar 1')
end

-- WIP
function widget:GetInfo()
	return {
		name    = 'Funks Resource Bar',
		desc    = 'Simple chili resource bars',
		author  = 'Funkencool',
		date    = '2013',
		license = 'GNU GPL v2',
		layer		= 0,
		enabled = true,
	}
end

local Chili, window0, control0, metalShare, energyMeter, energyShare
local meter = {}
local incomeLabel = {}
local shareLevel = {}
local spGetTeamResources = Spring.GetTeamResources
local myTeamID = Spring.GetMyTeamID()
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

local function initWindow()
	local screen0 = Chili.Screen0
	local _,_,_,_,_,mShare = spGetTeamResources(myTeamID, 'metal')
	local _,_,_,_,_,eShare = spGetTeamResources(myTeamID, 'energy')
	
	window0 = Chili.Window:New{parent = screen0, right = 0, y = 0, width = 840, height = 30, minHeight = 20, padding = {0,0,0,0}}
	
	meter['metal'] = Chili.Progressbar:New{parent = window0, x = 110, height = 20, bottom = 5, right = 415}
	meter['energy'] = Chili.Progressbar:New{parent = window0, x = 540, height = 20, bottom = 5, right = 0}
	-- shareLevel['metal'] = Chili.Trackbar:New{parent = window0, x = 90, height = 10, bottom = 5, width = 300, value = mShare*100}
	-- shareLevel['energy'] = Chili.Trackbar:New{parent = window0, x = 500, height = 10, bottom = 5, width = 300, value = eShare*100}
	incomeLabel['metal'] = Chili.Label:New{caption = '', right = 760, bottom = 7, parent = window0, align = 'right'}
	
	incomeLabel['metalin'] = Chili.Label:New{caption = '+0.0', right = 730, bottom = 11, parent = window0, align = 'right',fontSize=13}
	incomeLabel['metalin'].font.color={0.2,1,0.2,1}
	incomeLabel['metalout'] = Chili.Label:New{caption = '-0.0', right = 730, y=14, parent = window0, align = 'right',fontSize=13}
	incomeLabel['metalout'].font.color={1,0.2,0.2,1}
	
	incomeLabel['energy'] = Chili.Label:New{caption = '', right = 330, bottom = 7, parent = window0, align = 'right'}
	
	incomeLabel['energyin'] = Chili.Label:New{caption = '+0.0', right = 300, bottom = 11, parent = window0, align = 'right', fontSize=13}
	incomeLabel['energyin'].font.color={0.2,1,0.2,1}
	incomeLabel['energyout'] = Chili.Label:New{caption = '+0.0', right = 300, y=14 , parent = window0, align = 'right', fontSize=13}
	incomeLabel['energyout'].font.color={1,0.2,0.2,1}
	
	Chili.Label:New{caption = 'Metal:', x = 5, y = 6, parent = window0}
	Chili.Label:New{caption = 'Energy:', x = 435, y = 6, parent = window0}
end

local function setBar(res)
	local currentLevel, storage, pull, income, expense, share = spGetTeamResources(myTeamID, res)
	if res == 'metal' then 
		incomeLabel['metalin']:SetCaption(readable(income))
		incomeLabel['metalout']:SetCaption(readable(-pull))
	else
		incomeLabel['energyin']:SetCaption(readable(income))
		incomeLabel['energyout']:SetCaption(readable(-pull))
	end
	if income-expense > 0 then
		incomeLabel[res].font.color = {0.5,1,0.0,1}
		incomeLabel[res].font.outlineColor = {0.5,1,0.0,0.2}
		incomeLabel[res]:SetCaption(readable(income-expense))
		if res == 'metal' then 
			meter[res]:SetColor(0.6,0.6,0.8,.8)
		else
			meter[res]:SetColor(1,1,0.3,.6)
		end
	else
		incomeLabel[res].font.color = {1,0.5,0,1}
		incomeLabel[res].font.outlineColor = {1,0.5,0,0.2}
		incomeLabel[res]:SetCaption(readable(income-expense))
		if res == 'metal' then 
			meter[res]:SetColor(0.6,0.6,0.4,.6)
		else
			meter[res]:SetColor(1,0.3,0.3,.6)
		end
	end
--	Spring.SetShareLevel(res, shareLevel[res].value/100)
	meter[res]:SetValue(currentLevel/storage*100)
	meter[res]:SetCaption(math.floor(currentLevel)..'/'..storage)
end

function widget:GameFrame(n)
	if n%10 == 0 then
		setBar('metal')
		setBar('energy')
	end
end

function widget:Initialize()
	Spring.SendCommands('resbar 0')
	Chili = WG.Chili
	initWindow()
end
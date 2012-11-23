--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Chili Resource Bars",
    desc      = "",
    author    = "jK",
    date      = "2010",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    experimental = false,
    enabled   = true
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

include("colors.h.lua")

WG.energyWasted = 0
WG.energyForOverdrive = 0
--[[
WG.windEnergy = 0 
WG.highPriorityBP = 0
WG.lowPriorityBP = 0
--]]

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local abs = math.abs
local echo = Spring.Echo
local GetMyTeamID = Spring.GetMyTeamID
local GetTeamResources = Spring.GetTeamResources
local GetTimer = Spring.GetTimer
local DiffTimers = Spring.DiffTimers
local Chili

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local col_metal = {136/255,214/255,251/255,1}
local col_energy = {1,1,0,1}
local col_buildpower = {0.8, 0.8, 0.2, 1}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local window
local bar_metal
local bar_energy
local bar_buildpower
local lbl_metal
local lbl_energy
local lbl_m_expense
local lbl_e_expense
local lbl_m_income
local lbl_e_income

local blink = 0
local blink_periode = 1
local blink_alpha = 1
local blinkM_status = 0
local blinkE_status = 0
local time_old = 0

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local builderDefs = {}
for id,ud in pairs(UnitDefs) do
	if ud.isBuilder then
		builderDefs[#builderDefs+1] = id
	elseif (ud.buildSpeed > 0) then
		builderDefs[#builderDefs+1] = id
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

options_path = 'Settings/Interface/Resource Bars'

local function option_workerUsageUpdate()
	DestroyWindow()
	CreateWindow()
end

options = { 
  eexcessflashalways = {name='Always Flash On Energy Excess', type='bool', value=false},
  onlyShowExpense = {name='Only Show Expense', type='bool', value=true},
  workerUsage = {name = "Show Worker Usage", type = "bool", value=false, OnChange = option_workerUsageUpdate},
  energyFlash = {name = "Energy Stall Flash", type = "number", value=0.1, min=0,max=1,step=0.02},
  opacity = {
	name = "Opacity",
	type = "number",
	value = 0, min = 0, max = 1, step = 0.01,
	OnChange = function(self) window.color = {1,1,1,self.value}; window:Invalidate() end,
  }
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Update(s)

	if not window then return end

	local myTeamID = GetMyTeamID()

	local eCurr, eStor, ePull, eInco, eExpe, eShar, eSent, eReci = GetTeamResources(myTeamID, "energy")
	local mCurr, mStor, mPull, mInco, mExpe, mShar, mSent, mReci = GetTeamResources(myTeamID, "metal")
	
--	eStor = eStor - 10000 -- reduce by hidden storage
	if eCurr > eStor then eCurr = eStor end -- cap by storage
	if options.onlyShowExpense.value then
		eExpe = eExpe - WG.energyWasted -- if there is energy wastage, dont show it as used pull energy
	else
		ePull = ePull - WG.energyWasted
	end

	blink = (blink + s)%blink_periode
	blink_alpha = math.abs(blink_periode/2 - blink)

	--// BLINK WHEN EXCESSING OR ON LOW ENERGY
	local wastingM = mCurr >= mStor * 0.9
	if wastingM then
		blinkM_status = true
		bar_metal:SetColor( 136/255,214/255,251/255,0.65 + 0.35*blink_alpha )
		-- fade to green
		--bar_metal:SetColor( 136/255*blink_alpha,214/255,251/255*blink_alpha,1)
	elseif (blinkM_status) then
		blinkM_status = false
		bar_metal:SetColor( col_metal )
	end

	local wastingE = false
	if options.eexcessflashalways.value then
		wastingE = (WG.energyWasted > 0)
	else
		wastingE = (WG.energyWasted > eInco*0.05) and (WG.energyWasted > 15)
	end
	local stallingE = (eCurr <= eStor * options.energyFlash.value) and (eCurr < 1000) and (eCurr >= 0)
	if stallingE or wastingE then
		blinkE_status = true
		bar_energy:SetValue( 100 )
		if wastingE then
			bar_energy:SetColor(1,1,0,0.65 + 0.35 *blink_alpha)
			-- blink between energy color and green
			--bar_energy:SetColor(blink_alpha,1,0,1)
		else
			-- flash red if stalling
			bar_energy:SetColor(1,0,0,blink_alpha)
		end
	elseif (blinkE_status) then
		blinkE_status = false
		bar_energy:SetColor( col_energy )
	end


	local mPercent = 100 * mCurr / mStor
	local ePercent = 100 * eCurr / eStor

	bar_metal:SetValue( mPercent )
	if wastingM then
		bar_metal:SetCaption( (GreenStr.."%i/%i"):format(mCurr, mStor) )
	else
		bar_metal:SetCaption( ("%i/%i"):format(mCurr, mStor) )
	end

	if (not blinkE_status) then
		bar_energy:SetValue( ePercent )
	end
	if stallingE then
		bar_energy:SetCaption( (RedStr.."%i/%i"):format(eCurr, eStor) )
	elseif wastingE then
                bar_energy:SetCaption( (GreenStr.."%i/%i"):format(eCurr, eStor) )
	else
		bar_energy:SetCaption( ("%i/%i"):format(eCurr, eStor) )
	end


	--// UPDATE THE LABELS JUST ONCE PER SECOND!
  local time_now = GetTimer()
  local diff = DiffTimers(time_now, time_old)
  if (diff < 1) then return end
  time_old = time_now

	local mTotal = mInco - mExpe
	if options.onlyShowExpense.value then
		mTotal = mInco - mExpe
	else
		mTotal = mInco - mPull
	end

	if (mTotal >= 2) then
		lbl_metal.font:SetColor(0,1,0,1)
	elseif (mTotal > 0.1) then
		lbl_metal.font:SetColor(1,0.7,0,1)
	else
		lbl_metal.font:SetColor(1,0,0,1)
	end
	local abs_mTotal = abs(mTotal)
	if (abs_mTotal <0.1) then
		lbl_metal:SetCaption( "\1770" )
	elseif (abs_mTotal >=10)and((abs(mTotal%1)<0.1)or(abs_mTotal>99)) then
		lbl_metal:SetCaption( ("%+.0f"):format(mTotal) )
	else
		lbl_metal:SetCaption( ("%+.1f"):format(mTotal) )
	end

	local eTotal
	if options.onlyShowExpense.value then
		eTotal = eInco - eExpe
	else
		eTotal = eInco - ePull
	end
	
	if (eTotal >= 2) then
		lbl_energy.font:SetColor(0,1,0,1)
	elseif (eTotal > 0.1) then
		lbl_energy.font:SetColor(1,0.7,0,1)
	--elseif ((eStore - eCurr) < 50) then --// prevents blinking when overdrive is active
	--	lbl_energy.font:SetColor(0,1,0,1)
	else		
		lbl_energy.font:SetColor(1,0,0,1)
	end
	local abs_eTotal = abs(eTotal)
	if (abs_eTotal<0.1) then
		lbl_energy:SetCaption( "\1770" )
	elseif (abs_eTotal>=10)and((abs(eTotal%1)<0.1)or(abs_eTotal>99)) then
		lbl_energy:SetCaption( ("%+.0f"):format(eTotal) )
	else
		lbl_energy:SetCaption( ("%+.1f"):format(eTotal) )
	end

	if options.onlyShowExpense.value then
		lbl_m_expense:SetCaption( ("%.1f"):format(mExpe) )
		lbl_e_expense:SetCaption( ("%.1f"):format(eExpe) )
	else
		lbl_m_expense:SetCaption( ("%.1f"):format(mPull) )
		lbl_e_expense:SetCaption( ("%.1f"):format(ePull) )
	end
	lbl_m_income:SetCaption( ("%.1f"):format(mInco) )
	lbl_e_income:SetCaption( ("%.1f"):format(eInco) )


	if options.workerUsage.value then
		local bp_aval = 0
		local bp_use = 0
		local builderIDs = Spring.GetTeamUnitsByDefs(GetMyTeamID(), builderDefs)
		if (builderIDs) then
			for i=1,#builderIDs do
				local unit = builderIDs[i]
				local ud = UnitDefs[Spring.GetUnitDefID(unit)]

				local _, metalUse, _,energyUse = Spring.GetUnitResources(unit)
				bp_use = bp_use + math.max(abs(metalUse), abs(energyUse))
				bp_aval = bp_aval + ud.buildSpeed
			end
		end
		local buildpercent = bp_use/bp_aval * 100
		if bp_aval == 0 then
			bar_buildpower:SetValue(0)
			bar_buildpower:SetCaption("no workers")
		else
			bar_buildpower:SetValue(buildpercent)
			bar_buildpower:SetCaption(("%.1f%%"):format(buildpercent))
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()
	Chili = WG.Chili

	if (not Chili) then
		widgetHandler:RemoveWidget()
		return
	end

	widgetHandler:RegisterGlobal("MexEnergyEvent", MexEnergyEvent)
	--widgetHandler:RegisterGlobal("SendWindProduction", SendWindProduction)
	--widgetHandler:RegisterGlobal("PriorityStats", PriorityStats)

	time_old = GetTimer()

	Spring.SendCommands("resbar 0")

	CreateWindow()

end

function widget:Shutdown()
	window:Dispose()
	Spring.SendCommands("resbar 1")
end

function CreateWindow()

	local bars = 2
	if options.workerUsage.value then
		bars = 3
	end
	local function p(a)
		return tostring(a).."%"
	end
	--// WINDOW
	window = Chili.Window:New{
		color = {1,1,1,options.opacity.value},
		parent = Chili.Screen0,
		dockable = true,
		name="ResourceBars",
		right = 0,
		y = 0,
		clientWidth  = 300,
		clientHeight = 45,
		draggable = false,
		resizable = false,
		tweakDraggable = true,
		tweakResizable = true,
	}

	--// METAL
	Chili.Image:New{
		parent = window,
		height = p(100/bars),
		width  = 25,
                y      = p(100/bars),
		right  = 0,
		file   = 'LuaUI/Images/ibeam.png',
	}
	bar_metal = Chili.Progressbar:New{
		parent = window,
		color  = col_metal,
		height = p(100/bars),
		right  = 26,
                x      = 110,
                y      = p(100/bars),
		tooltip = "This shows your current metal reserves",
		font   = {color = {1,1,1,1}, outlineColor = {0,0,0,0.7}, },
	}
	lbl_metal = Chili.Label:New{
		parent = window,
		height = p(100/bars),
		width  = 60,
                x      = 10,
                y      = p(100/bars),
		valign = "center",
		align  = "right",
		caption = "0",
		autosize = false,
		font   = {size = 19, outline = true, outlineWidth = 4, outlineWeight = 3,},
		tooltip = "Your metal gain.",
	}
	lbl_m_income = Chili.Label:New{
		parent = window,
		height = p(50/bars),
		width  = 40,
                x      = 70,
                y      = p(100/bars),
		caption = "10.0",
		valign = "center",
 		align  = "center",
		autosize = false,
		font   = {size = 12, outline = true, color = {0,1,0,1}},
		tooltip = "Your metal income.",
	}
	lbl_m_expense = Chili.Label:New{
		parent = window,
		height = p(50/bars),
		width  = 40,
                x      = 70,
                y      = p(1.5*100/bars),
		caption = "10.0",
		valign = "center",
		align  = "center",
		autosize = false,
		font   = {size = 12, outline = true, color = {1,0,0,1}},
		tooltip = "Your metal expense.",
	}


	--// ENERGY
	Chili.Image:New{
		parent = window,
		height = p(100/bars),
		width  = 25,
                right  = 10,
                y      = 1,
		file   = 'LuaUI/Images/energy.png',
	}
	bar_energy = Chili.Progressbar:New{
		parent = window,
		color  = col_energy,
		height = p(100/bars),
		right  = 36,
                x      = 100,
                y      = 1,
		tooltip = "Shows your current energy reserves.\n Anything above 100% will be burned by 'mex overdrive'\n which increases production of your mines",
		font   = {color = {1,1,1,1}, outlineColor = {0,0,0,0.7}, },
	}
	lbl_energy = Chili.Label:New{
		parent = window,
		height = p(100/bars),
		width  = 60,
                x      = 0,
                y      = 1,
		valign = "center",
		align  = "right",
		caption = "0",
		autosize = false,
		font   = {size = 19, outline = true, outlineWidth = 4, outlineWeight = 3,},
		tooltip = "Your energy gain.",
	}
	lbl_e_income = Chili.Label:New{
		parent = window,
		height = p(50/bars),
		width  = 40,
                x      = 60,
                y      = 1,
		caption = "10.0",
		valign  = "center",
		align   = "center",
		autosize = false,
		font   = {size = 12, outline = true, color = {0,1,0,1}},
		tooltip = "Your energy income.",
	}
	lbl_e_expense = Chili.Label:New{
		parent = window,
		height = p(50/bars),
		width  = 40,
                x      = 60,
                y      = p(50/bars),
		caption = "10.0",
		valign = "center",
		align  = "center",
		autosize = false,
		font   = {size = 12, outline = true, color = {1,0,0,1}},
		tooltip = "Your energy expense.",
	}

	if not options.workerUsage.value then return end
	-- worker usage
	bar_buildpower = Chili.Progressbar:New{
		parent = window,
		color  = col_buildpower,
		height = "33%",
		right  = 6,
		x      = 120,
		y      = "66%",
		tooltip = "",
		font   = {color = {1,1,1,1}, outlineColor = {0,0,0,0.7}, },
	}
end

function DestroyWindow()
	window:Dispose()
	window = nil
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


function MexEnergyEvent(teamID, energyWasted, energyForOverdrive, totalIncome, metalFromOverdrive)
  if (Spring.GetLocalTeamID() == teamID) then 
  	WG.energyWasted = energyWasted
	--Spring.Echo("energyWasted " .. energyWasted)
	WG.energyForOverdrive = energyForOverdrive
  end
end

--[[
function SendWindProduction(teamID, value)
	WG.windEnergy = value
end


function PriorityStats(teamID, highPriorityBP, lowPriorityBP)
	WG.highPriorityBP = highPriorityBP
	WG.lowPriorityBP = lowPriorityBP
end
--]]

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

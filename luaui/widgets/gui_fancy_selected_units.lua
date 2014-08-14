function widget:GetInfo()
   return {
      name      = "Fancy Selected Units",
      desc      = "Shows which units are selected",
      author    = "Floris",
      date      = "04.04.2014",
      license   = "GNU GPL, v2 or later",
      layer     = 2,
      enabled   = false
   }
end

--(took 'UnitShapes' widget as a base for this one)


--------------------------------------------------------------------------------
-- Console commands
--------------------------------------------------------------------------------

-- /selectedunits_style				-- toggles different styles!

-- /+selectedunits_opacity
-- /-selectedunits_opacity
-- /+selectedunits_baseopacity
-- /-selectedunits_baseopacity

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- TODO
-- show the selections of teammates

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local clearquad
local shapes = {}

local rad_con						= 180 / math.pi

local UNITCONF						= {}

local currentRotationAngle			= 0
local currentRotationAngleOpposite	= 0
local previousOsClock				= os.clock()

local animationMultiplier			= 1
local animationMultiplierInner		= 1
local animationMultiplierAdd		= true

local selectedUnits					= {}
local perfSelectedUnits				= {}

local maxSelectTime					= 0				--time at which units "new selection" animation will end
local maxDeselectedTime				= -1			--time at which units deselection animation will end

local currentOption					= 2

local glCallList					= gl.CallList
local glDrawListAtUnit				= gl.DrawListAtUnit

local spIsUnitSelected				= Spring.IsUnitSelected
local spGetSelectedUnitsCount		= Spring.GetSelectedUnitsCount
local spGetSelectedUnitsSorted		= Spring.GetSelectedUnitsSorted
local spGetUnitTeam					= Spring.GetUnitTeam
local spLoadCmdColorsConfig			= Spring.LoadCmdColorsConfig
local spGetUnitDirection			= Spring.GetUnitDirection
local spGetCameraPosition			= Spring.GetCameraPosition
local spGetUnitViewPosition			= Spring.GetUnitViewPosition
local spGetUnitDefID				= Spring.GetUnitDefID
local spIsGUIHidden					= Spring.IsGUIHidden
local spGetTeamColor				= Spring.GetTeamColor
local spGetUnitHealth 				= Spring.GetUnitHealth
local spGetUnitIsCloaked			= Spring.GetUnitIsCloaked
local spUnitInView                  = Spring.IsUnitInView

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local OPTIONS = {}
OPTIONS.defaults = {	-- these will be loaded when switching style, but the style will overwrite the those values 
	name							= "Defaults",
	-- Quality settings
	showNoOverlap					= false,	-- set true for no line overlapping
	showBase						= true,
	showFirstLine					= true,
	showFirstLineDetails			= true,
	showSecondLine					= false,
	showExtraComLine				= true,		-- extra circle lines for the commander unit
	showExtraBuildingWeaponLine		= true,
	showUnitHighlight				= false,	-- default off, eats performance
	showUnitHighlightHealth			= false,	-- (overrides showUnitHighlight)
	
	-- opacity
	spotterOpacity					= 1,
	baseOpacity						= 0.8,		-- 0 is opaque
	unitHighlightOpacity			= 0.08,		-- 0 is invisible
	opacitySliderMultiplier			= 0.01,		-- the higher the value, the more transparant the slider can make it
	
	-- animation
	selectionStartAnimation			= true,
	selectionStartAnimationTime		= 0.15,
	selectionStartAnimationScale	= 0.8,
	-- selectionStartAnimationScale	= 1.17,
	selectionEndAnimation			= true,
	selectionEndAnimationTime		= 0.2,
	selectionEndAnimationScale		= 0.9,
	--selectionEndAnimationScale	= 1.17,
	
	-- animation
	rotationSpeed					= 0.8,
	animationSpeed					= 0.0006,	-- speed of scaling up/down inner and outer lines
	animateSpotterSize				= true,
	maxAnimationMultiplier			= 1.014,
	minAnimationMultiplier			= 0.99,
	
	-- prefer not to change because other widgets use these values too  (highlight_units, given_units, selfd_icons, ...)
	scaleFactor						= 2.9,			
	rectangleFactor					= 3.3,
	
	
	-- circle shape
	circlePieces					= 36,		-- (1 or higher)
	circlePieceDetail				= 1,		-- smoothness of each piece (1 or higher)
	circleSpaceUsage				= 0.7,		-- 1 = whole circle space gets filled
	circleInnerOffset				= 0.45,
	
	-- size
	scaleMultiplier					= 1.04,
	innersize						= 1.7,
	selectinner						= 1.66,
	outersize						= 1.79,
	
	-- line opacity
	firstLineOpacity				= 0.06,
	secondLineOpacity				= 0.18,
}
table.insert(OPTIONS, {
	name							= "Cheap Fill",
	showFirstLineDetails			= false,
	rotationSpeed					= 0,
	baseOpacity						= 0.65,
	opacitySliderMultiplier			= 0.07,
})
table.insert(OPTIONS, {
	name							= "Solid Lines",
	circlePieces					= 5,
	circlePieceDetail				= 7,
	circleSpaceUsage				= 1,
	circleInnerOffset				= 0,
	
	rotationSpeed					= 0,
})
table.insert(OPTIONS, {
	name							= "Tilted Blocky Dots",
	circlePieces					= 36,
	circlePieceDetail				= 1,
	circleSpaceUsage				= 0.7,
	circleInnerOffset				= 0.45,
})
table.insert(OPTIONS, {
	name							= "Blocky Dots",
	circlePieces					= 42,
	circlePieceDetail				= 1,
	circleSpaceUsage				= 0.55,
	circleInnerOffset				= 0,

	rotationSpeed					= 1,
})
table.insert(OPTIONS, {
	name							= "Stretched Blocky Dots",
	circlePieces					= 22,
	circlePieceDetail				= 4,
	circleSpaceUsage				= 0.28,
	circleInnerOffset				= 1,
})
table.insert(OPTIONS, {
	name							= "Curvy Lines",
	circlePieces					= 5,
	circlePieceDetail				= 7,
	circleSpaceUsage				= 0.75,
	circleInnerOffset				= 0,
	
	rotationSpeed					= 1.8,
})
table.insert(OPTIONS, {
	name							= "Teamcolor Highlight",
	showNoOverlap					= false,
	showBase						= false,
	showFirstLine					= false,
	showSecondLine					= false,
	showUnitHighlight				= true,
	showUnitHighlightHealth			= false,
	
	unitHighlightOpacity			= 0.4,
})
table.insert(OPTIONS, {
	name							= "Health Color Highlight",
	showNoOverlap					= false,
	showBase						= false,
	showFirstLine					= false,
	showSecondLine					= false,
	showUnitHighlight				= true,
	showUnitHighlightHealth			= true,
	
	unitHighlightOpacity			= 0.3,
})


function table.shallow_copy(t)
	local t2 = {}
	for k,v in pairs(t) do
		t2[k] = v
	end
	return t2
end
OPTIONS_original = table.shallow_copy(OPTIONS)
OPTIONS_original.defaults = nil

------------------------------------------------------------------------------------
------------------------------------------------------------------------------------


local function toggleOptions()
	currentOption = currentOption + 1
	if not OPTIONS[currentOption] then
		currentOption = 1
	end
	loadConfig()
end


local function updateSelectedUnitsData()
	
	-- remove deselected units 
	local clockDifference
	for teamID,_ in pairs(selectedUnits) do
		for unitID,_ in pairs(selectedUnits[teamID]) do
			if not spIsUnitSelected(unitID) and selectedUnits[teamID][unitID]['selected'] then
				clockDifference = OPTIONS[currentOption].selectionStartAnimationTime - (currentClock - selectedUnits[teamID][unitID]['new'])
				if clockDifference < 0 then
					clockDifference = 0
				end
				selectedUnits[teamID][unitID]['selected'] = false 
				selectedUnits[teamID][unitID]['new'] = false
				selectedUnits[teamID][unitID]['old'] = currentClock - clockDifference
			end
		end
	end
	
	-- add selected units
	if spGetSelectedUnitsCount() > 0 then
		local units = spGetSelectedUnitsSorted()
		local clockDifference, unit, unitID
		for uDID,_ in pairs(units) do
			if uDID ~= 'n' then --'n' returns table size
				for i=1,#units[uDID] do
					unitID = units[uDID][i]
					unit = UNITCONF[uDID]
					if (unit) then
						teamID = spGetUnitTeam(unitID)
						if not selectedUnits[teamID] then
							selectedUnits[teamID] = {}
						end
						if not selectedUnits[teamID][unitID] then
							selectedUnits[teamID][unitID]			= {}
							selectedUnits[teamID][unitID]['new']	= currentClock
						elseif selectedUnits[teamID][unitID]['old'] then
							clockDifference = OPTIONS[currentOption].selectionEndAnimationTime - (currentClock - selectedUnits[teamID][unitID]['old'])
							if clockDifference < 0 then
								clockDifference = 0
							end
							selectedUnits[teamID][unitID]['new']	= currentClock - clockDifference
							selectedUnits[teamID][unitID]['old']	= nil
						end
						selectedUnits[teamID][unitID]['selected']	= true
					end
				end
			end
		end
	end
	
	-- creates has blinking problem
	--[[ create new table that has iterative keys instead of unitID (to speedup after about 300 different units have ever been selected)
	perfSelectedUnits = {}
	for teamID,_ in pairs(selectedUnits) do
		perfSelectedUnits[teamID] = {}
		for unitID,_ in pairs(selectedUnits[teamID]) do
			table.insert(perfSelectedUnits[teamID], unitID)
		end
		perfSelectedUnits[teamID]['totalUnits'] = table.getn(perfSelectedUnits[teamID])
	end
	]]--
end


local function SetupCommandColors(state)
	local alpha = state and 1 or 0
	spLoadCmdColorsConfig('unitBox  0 1 0 ' .. alpha)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Creating polygons:
local function CreateDisplayLists(callback)
	local displayLists = {}
	
	displayLists.select = callback.fading(OPTIONS[currentOption].outersize, OPTIONS[currentOption].selectinner)
	displayLists.inner = callback.solid({0, 0, 0, 0}, OPTIONS[currentOption].innersize)
	displayLists.large = callback.solid(nil, OPTIONS[currentOption].selectinner)
	displayLists.shape = callback.fading(OPTIONS[currentOption].innersize, OPTIONS[currentOption].selectinner)
	
	return displayLists
end



local function DrawCircleLine(innersize, outersize)
	gl.BeginEnd(GL.QUADS, function()
		local detailPartWidth, a1,a2,a3,a4
		local width = OPTIONS[currentOption].circleSpaceUsage
		local detail = OPTIONS[currentOption].circlePieceDetail
		
		local radstep = (2.0 * math.pi) / OPTIONS[currentOption].circlePieces
		for i = 1, OPTIONS[currentOption].circlePieces do
			for d = 1, detail do
				
				detailPartWidth = ((width / detail) * d)
				a1 = ((i+detailPartWidth - (width / detail)) * radstep)
				a2 = ((i+detailPartWidth) * radstep)
				a3 = ((i+OPTIONS[currentOption].circleInnerOffset+detailPartWidth - (width / detail)) * radstep)
				a4 = ((i+OPTIONS[currentOption].circleInnerOffset+detailPartWidth) * radstep)
				
				--outer (fadein)
				gl.Vertex(math.sin(a4)*innersize, 0, math.cos(a4)*innersize)
				gl.Vertex(math.sin(a3)*innersize, 0, math.cos(a3)*innersize)
				--outer (fadeout)
				gl.Vertex(math.sin(a1)*outersize, 0, math.cos(a1)*outersize)
				gl.Vertex(math.sin(a2)*outersize, 0, math.cos(a2)*outersize)
			end
		end
	end)
end

local function DrawCircleSolid(size)
	gl.BeginEnd(GL.TRIANGLE_FAN, function()
		local pieces = (OPTIONS[currentOption].circlePieces * math.ceil(OPTIONS[currentOption].circlePieceDetail/ OPTIONS[currentOption].circleSpaceUsage))
		local radstep = (2.0 * math.pi) / pieces
		local a1
		if (color) then
			gl.Color(color)
		end
		gl.Vertex(0, 0, 0)
		for i = 0, pieces do
			a1 = (i * radstep)
			gl.Vertex(math.sin(a1)*size, 0, math.cos(a1)*size)
		end
	end)
end

local function CreateCircleLists()
	local callback = {}
	
	function callback.fading(innersize, outersize)
		return gl.CreateList(DrawCircleLine, innersize, outersize)
	end
	
	function callback.solid(color, size)
		return gl.CreateList(DrawCircleSolid, size)
	end
	
	shapes.circle = CreateDisplayLists(callback)
end



local function DrawSquareLine(innersize, outersize)
	
	gl.BeginEnd(GL.QUADS, function()
		local radstep = (2.0 * math.pi) / 4
		local width, a1,a2,a2_2
		for i = 1, 4 do
			-- straight piece
			width = 0.7
			i = i + 0.65
			a1 = (i * radstep)
			a2 = ((i+width) * radstep)
			
			gl.Vertex(math.sin(a2)*innersize, 0, math.cos(a2)*innersize)
			gl.Vertex(math.sin(a1)*innersize, 0, math.cos(a1)*innersize)
			
			gl.Vertex(math.sin(a1)*outersize, 0, math.cos(a1)*outersize)
			gl.Vertex(math.sin(a2)*outersize, 0, math.cos(a2)*outersize)
			
			-- corner piece
			width = 0.3
			i = i + 3
			a1 = (i * radstep)
			a2 = ((i+width) * radstep)
			i = i -0.6
			a2_2 = ((i+width) * radstep)
			
			gl.Vertex(math.sin(a2_2)*innersize, 0, math.cos(a2_2)*innersize)
			gl.Vertex(math.sin(a1)*innersize, 0, math.cos(a1)*innersize)
			
			gl.Vertex(math.sin(a1)*outersize, 0, math.cos(a1)*outersize)
			gl.Vertex(math.sin(a2_2)*outersize, 0, math.cos(a2_2)*outersize)
		end
	end)
end

local function DrawSquareSolid(size)
	gl.BeginEnd(GL.TRIANGLE_FAN, function()
		local width, a1,a2,a2_2
		local radstep = (2.0 * math.pi) / 4
		
		gl.Vertex(0, 0, 0)
		
		for i = 1, 4 do
			--straight piece
			width = 0.7
			i = i + 0.65
			a1 = (i * radstep)
			a2 = ((i+width) * radstep)
			
			gl.Vertex(math.sin(a2)*size, 0, math.cos(a2)*size)
			gl.Vertex(math.sin(a1)*size, 0, math.cos(a1)*size)
			
			--corner piece
			width = 0.3
			i = i + 3
			a1 = (i * radstep)
			a2 = ((i+width) * radstep)
			i = i -0.6
			a2_2 = ((i+width) * radstep)
			
			gl.Vertex(math.sin(a2_2)*size, 0, math.cos(a2_2)*size)
			gl.Vertex(math.sin(a1)*size, 0, math.cos(a1)*size)
		end
		
	end)
end

local function CreateSquareLists()
	
	local callback = {}
	
	function callback.fading(innersize, outersize)
		return gl.CreateList(DrawSquareLine, innersize, outersize)
	end
	
	function callback.solid(color, size)
		return gl.CreateList(DrawSquareSolid, size)
	end
	shapes.square = CreateDisplayLists(callback)
end



local function DrawTriangleLine(innersize, outersize)
	gl.BeginEnd(GL.QUADS, function()
		local width, a1,a2,a2_2
		local radstep = (2.0 * math.pi) / 3
		
		for i = 1, 3 do
			--straight piece
			width = 0.7
			i = i + 0.65
			a1 = (i * radstep)
			a2 = ((i+width) * radstep)
			
			gl.Vertex(math.sin(a2)*innersize, 0, math.cos(a2)*innersize)
			gl.Vertex(math.sin(a1)*innersize, 0, math.cos(a1)*innersize)
			
			gl.Vertex(math.sin(a1)*outersize, 0, math.cos(a1)*outersize)
			gl.Vertex(math.sin(a2)*outersize, 0, math.cos(a2)*outersize)
			
			-- corner piece
			width = 0.3
			i = i + 3
			a1 = (i * radstep)
			a2 = ((i+width) * radstep)
			i = i -0.6
			a2_2 = ((i+width) * radstep)
			
			gl.Vertex(math.sin(a2_2)*innersize, 0, math.cos(a2_2)*innersize)
			gl.Vertex(math.sin(a1)*innersize, 0, math.cos(a1)*innersize)
			
			gl.Vertex(math.sin(a1)*outersize, 0, math.cos(a1)*outersize)
			gl.Vertex(math.sin(a2_2)*outersize, 0, math.cos(a2_2)*outersize)
		end
		
	end)
end

local function DrawTriangleSolid(size)	
	
	gl.BeginEnd(GL.TRIANGLE_FAN, function()
		
		local width, a1,a2,a2_2
		local radstep = (2.0 * math.pi) / 3
		
		gl.Vertex(0, 0, 0)
		
		for i = 1, 3 do
			-- straight piece
			width = 0.7
			i = i + 0.65
			a1 = (i * radstep)
			a2 = ((i+width) * radstep)
			
			gl.Vertex(math.sin(a2)*size, 0, math.cos(a2)*size)
			gl.Vertex(math.sin(a1)*size, 0, math.cos(a1)*size)
			
			-- corner piece
			width = 0.3
			i = i + 3
			a1 = (i * radstep)
			a2 = ((i+width) * radstep)
			i = i -0.6
			a2_2 = ((i+width) * radstep)
			
			gl.Vertex(math.sin(a2_2)*size, 0, math.cos(a2_2)*size)
			gl.Vertex(math.sin(a1)*size, 0, math.cos(a1)*size)
		end
		
	end)
end

local function CreateTriangleLists()
	
	local callback = {}
	
	function callback.fading(innersize, outersize)
		return gl.CreateList(DrawTriangleLine, innersize, outersize)
	end
	
	function callback.solid(color, size)
		return gl.CreateList(DrawTriangleSolid, size)
	end
	shapes.triangle = CreateDisplayLists(callback)
end



local function highlightUnit(unitID, r,g,b,a)
  local health,maxHealth,paralyzeDamage,captureProgress,buildProgress = spGetUnitHealth(unitID)
  gl.Color(
    health>maxHealth/2 and 2-2*health/maxHealth or 1, -- red
    health>maxHealth/2 and 1 or 2*health/maxHealth, -- green
    0, -- blue
    0.4) -- alpha
    gl.Color(r,g,b,a)
    gl.Unit(unitID, true)
end



local function DestroyShape(shape)
	gl.DeleteList(shape.select)
	gl.DeleteList(shape.inner)
	gl.DeleteList(shape.large)
	gl.DeleteList(shape.shape)
end



function widget:Initialize()

	loadConfig()
	
	clearquad = gl.CreateList(function()
		local size = 1000
		gl.BeginEnd(GL.QUADS, function()
			gl.Vertex( -size,0,  			-size)
			gl.Vertex( Game.mapSizeX+size,0, -size)
			gl.Vertex( Game.mapSizeX+size,0, Game.mapSizeZ+size)
			gl.Vertex( -size,0, 			Game.mapSizeZ+size)
		end)
	end)
	SetupCommandColors(false)
	
	currentClock = os.clock()
	
	local Chili = WG.Chili
	local Menu = WG.MainMenu
	if not Menu then return end
	
	local items = {}
	for i = 1, table.getn(OPTIONS) do
		table.insert(items, OPTIONS[i].name)
	end
	
	Menu.AddOption{
		tab      = 'Interface',
		children = {
			Chili.Label:New{caption='Fancy Selected Units',x='0%',fontsize=18},
			Chili.ComboBox:New{
				x        = '10%',
				width    = '80%',
				items    = items,
				selected = currentOption,
				OnSelect = {
					function(_,sel)
						currentOption = sel
						loadConfig()
					end
				}
			},
			Chili.Checkbox:New{
				caption='Second line',x='10%',width='80%',
				checked=OPTIONS[currentOption].showSecondLine,
				setting=OPTIONS.defaults.showSecondLine,
				OnChange={function() OPTIONS.defaults.showSecondLine = not OPTIONS.defaults.showSecondLine; if OPTIONS_original[currentOption].showSecondLine == nil then OPTIONS[currentOption].showSecondLine = OPTIONS.defaults.showSecondLine; end end}
			},
			Chili.Checkbox:New{
				caption='Unit highlight',x='10%',width='80%',
				checked=OPTIONS.defaults.showUnitHighlight,
				setting=OPTIONS.defaults.showUnitHighlight,
				OnChange={function() OPTIONS.defaults.showUnitHighlight = not OPTIONS.defaults.showUnitHighlight; if OPTIONS_original[currentOption].showUnitHighlight == nil then OPTIONS[currentOption].showUnitHighlight = OPTIONS.defaults.showUnitHighlight; end end}
			},
			Chili.Label:New{caption='Opacity'},
			Chili.Trackbar:New{
				x        = '10%',
				width    = '80%',
				min      = 0,
				max      = 6,
				step     = 0.05,
				value    = OPTIONS[currentOption].spotterOpacity,
				OnChange = {function(_,value) OPTIONS[currentOption].spotterOpacity=value; OPTIONS.defaults.spotterOpacity=value; end}
			},
			Chili.Line:New{width='100%'},
		}
	}
end


function loadOption()
	local appliedOption = OPTIONS_original[currentOption]
	OPTIONS[currentOption] = table.shallow_copy(OPTIONS.defaults)
	
	for option, value in pairs(appliedOption) do
		OPTIONS[currentOption][option] = value
	end
end


function loadConfig()
	loadOption()
	
	CreateCircleLists()
	CreateSquareLists()
	CreateTriangleLists()
	
	SetUnitConf()
	
	Spring.Echo("Fancy Selected Units:  loaded style... '"..OPTIONS[currentOption].name.."'")
end


function SetUnitConf()
	local name, shape, xscale, zscale, scale, xsize, zsize, weaponcount
	for udid, unitDef in pairs(UnitDefs) do
		xsize, zsize = unitDef.xsize, unitDef.zsize
		scale = OPTIONS[currentOption].scaleFactor*( xsize^2 + zsize^2 )^0.5
		name = unitDef.name
		
		if (unitDef.isBuilding or unitDef.isFactory or unitDef.speed==0) then
			shapeName = 'square'
			shape = shapes.square
			xscale, zscale = OPTIONS[currentOption].rectangleFactor * xsize, OPTIONS[currentOption].rectangleFactor * zsize
		elseif (unitDef.isAirUnit) then
			shapeName = 'triangle'
			shape = shapes.triangle
			xscale, zscale = scale, scale
		else
			shapeName = 'circle'
			shape = shapes.circle
			xscale, zscale = scale, scale
		end
		
		weaponcount = table.getn(unitDef.weapons)
			
		
		UNITCONF[udid] = {name=name, shape=shape, shapeName=shapeName, xscale=xscale, zscale=zscale, weaponcount=weaponcount}
	end
end


function widget:Shutdown()
	SetupCommandColors(true)
	
	gl.DeleteList(clearquad)
	
	for _, shape in pairs(shapes) do
		DestroyShape(shape)
	end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


function widget:Update()
	currentClock = os.clock()
	maxSelectTime = currentClock - OPTIONS[currentOption].selectionStartAnimationTime
	maxDeselectedTime = currentClock - OPTIONS[currentOption].selectionEndAnimationTime
	
	updateSelectedUnitsData()		-- calling updateSelectedUnitsData() inside widget:CommandsChanged() will return in buggy behavior in combination with the 'smart-select' widget
end



local degrot = {}
function widget:GameFrame(frame)
	
	if frame%1~=0 then return end
	
	-- logs current unit direction	(needs regular updates for air units, and for buildings only once)	for teamID,_ in pairs(perfSelectedUnits) do
	--for teamID,_ in pairs(perfSelectedUnits) do
		--for unitKey=1, perfSelectedUnits[teamID]['totalUnits'] do
		--unitID = perfSelectedUnits[teamID][unitKey]
	for teamID,_ in pairs(selectedUnits) do
		for unitID,_ in pairs(selectedUnits[teamID]) do
			local dirx, _, dirz = spGetUnitDirection(unitID)
			if (dirz ~= nil) then
				degrot[unitID] = 180 - math.acos(dirz) * rad_con
				if dirx < 0 then
					degrot[unitID] = 180 - math.acos(dirz) * rad_con
				else
					degrot[unitID] = 180 + math.acos(dirz) * rad_con
				end
			end
		end
	end
end


function GetUsedRotationAngle(unitID, shapeName, opposite)
	if (shapeName == 'circle') then
		if opposite then 
			return currentRotationAngleOpposite
		else
			return currentRotationAngle
		end
	else
		return degrot[unitID]
	end
end



do
	local unitID, udid, unit, draw, unitPosX, unitPosY, unitPosZ, changedScale, usedAlpha, usedScale, usedXScale, usedZScale, usedRotationAngle
	local health,maxHealth,paralyzeDamage,captureProgress,buildProgress
	
	function DrawSelectionSpottersPart(teamID, type, r,g,b,a,scale, opposite, relativeScaleSchrinking, changeOpacity, drawUnitStyles)
		
		local OPTIONScurrentOption = OPTIONS[currentOption]
		
		--for unitKey=1, perfSelectedUnits[teamID]['totalUnits'] do
		--	unitID = perfSelectedUnits[teamID][unitKey]
		for unitID in pairs(selectedUnits[teamID]) do
			udid = spGetUnitDefID(unitID)
			unit = UNITCONF[udid]
			
			if (unit) and spUnitInView(unitID) then
				unitPosX, unitPosY, unitPosZ = spGetUnitViewPosition(unitID, true)
				
				changedScale = 1
				usedAlpha = a
				
				if not selectedUnits[teamID][unitID] then return end 
				
				
				if (OPTIONScurrentOption.selectionEndAnimation  or  OPTIONScurrentOption.selectionStartAnimation) then
					if changeOpacity then
						gl.Color(r,g,b,a)
					end
					-- check if the unit is deselected
					if (OPTIONScurrentOption.selectionEndAnimation and not selectedUnits[teamID][unitID]['selected']) then
						if (maxDeselectedTime < selectedUnits[teamID][unitID]['old']) then
							changedScale = OPTIONScurrentOption.selectionEndAnimationScale + (((selectedUnits[teamID][unitID]['old'] - maxDeselectedTime) / OPTIONScurrentOption.selectionEndAnimationTime)) * (1 - OPTIONScurrentOption.selectionEndAnimationScale)
							if (changeOpacity) then
								if type == 'unit highlight' then
									usedAlpha = (((selectedUnits[teamID][unitID]['old'] - maxDeselectedTime) / OPTIONScurrentOption.selectionEndAnimationTime) * a)
								else
									usedAlpha = 1 - (((selectedUnits[teamID][unitID]['old'] - maxDeselectedTime) / OPTIONScurrentOption.selectionEndAnimationTime) * (1-a))
								end
								gl.Color(r,g,b,usedAlpha)
							end
						else
							selectedUnits[teamID][unitID] = nil
						end
						
					-- check if the unit is newly selected
					elseif (OPTIONScurrentOption.selectionStartAnimation and selectedUnits[teamID][unitID]['new'] > maxSelectTime) then
						--spEcho(selectedUnits[teamID][unitID]['new'] - maxSelectTime)
						changedScale = OPTIONScurrentOption.selectionStartAnimationScale + (((currentClock - selectedUnits[teamID][unitID]['new']) / OPTIONScurrentOption.selectionStartAnimationTime)) * (1 - OPTIONScurrentOption.selectionStartAnimationScale)
						if (changeOpacity) then
							if type == 'unit highlight' then
								usedAlpha = (((currentClock - selectedUnits[teamID][unitID]['new']) / OPTIONScurrentOption.selectionStartAnimationTime) * a)
							else
								usedAlpha = 1 - (((currentClock - selectedUnits[teamID][unitID]['new']) / OPTIONScurrentOption.selectionStartAnimationTime) * (1-a))
							end
							gl.Color(r,g,b,usedAlpha)
						end
					end
				end
				
				
				if selectedUnits[teamID][unitID] then
				
					usedRotationAngle = GetUsedRotationAngle(unitID, unit.shapeName, opposite)
					if type == 'normal solid'  or  type == 'normal alpha' then
						
						-- special style for coms
						if drawUnitStyles and OPTIONScurrentOption.showExtraComLine and (unit.name == 'corcom'  or  unit.name == 'armcom') then
							usedRotationAngle = GetUsedRotationAngle(unitID, unit.shapeName)
							gl.Color(r,g,b,(usedAlpha*usedAlpha)+0.22)
							usedScale = scale * 1.25
							glDrawListAtUnit(unitID, unit.shape.inner, false, (unit.xscale*usedScale*changedScale)-((unit.xscale*changedScale-10)/10), 1.0, (unit.zscale*usedScale*changedScale)-((unit.zscale*changedScale-10)/10), currentRotationAngleOpposite, 0, degrot[unitID], 0)
							usedScale = scale * 1.23
							usedRotationAngle = GetUsedRotationAngle(unitID, unit.shapeName , true)
							gl.Color(r,g,b,(usedAlpha*usedAlpha)+0.08)
							glDrawListAtUnit(unitID, unit.shape.large, false, (unit.xscale*usedScale*changedScale)-((unit.xscale*changedScale-10)/10), 1.0, (unit.zscale*usedScale*changedScale)-((unit.zscale*changedScale-10)/10), 0, 0, degrot[unitID], 0)
						else
							-- adding style for buildings with weapons
							if drawUnitStyles and OPTIONScurrentOption.showExtraBuildingWeaponLine and unit.shapeName == 'square' then
								if (unit.weaponcount > 0) then
									usedRotationAngle = GetUsedRotationAngle(unitID, unit.shapeName)
									gl.Color(r,g,b,usedAlpha*(usedAlpha+0.2))
									usedScale = scale * 1.11
									glDrawListAtUnit(unitID, unit.shape.select, false, (unit.xscale*usedScale*changedScale)-((unit.xscale*changedScale-10)/7.5), 1.0, (unit.zscale*usedScale*changedScale)-((unit.zscale*changedScale-10)/7.5), usedRotationAngle, 0, degrot[unitID], 0)
								end
								gl.Color(r,g,b,usedAlpha)
							end
							
							if relativeScaleSchrinking then
								glDrawListAtUnit(unitID, unit.shape.select, false, (unit.xscale*scale*changedScale)-((unit.xscale*changedScale-5)/10), 1.0, (unit.zscale*scale*changedScale)-((unit.zscale*changedScale-5)/10), usedRotationAngle, 0, degrot[unitID], 0)
							else
								glDrawListAtUnit(unitID, unit.shape.select, false, unit.xscale*scale*changedScale, 1.0, unit.zscale*scale*changedScale, usedRotationAngle, 0, degrot[unitID], 0)
							end
						end
						
					elseif type == 'solid overlap' then
						
						if relativeScaleSchrinking then
							glDrawListAtUnit(unitID, unit.shape.large, false, (unit.xscale*scale*changedScale)-((unit.xscale*changedScale-5)/50), 1.0, (unit.zscale*scale*changedScale)-((unit.zscale*changedScale-5)/50), usedRotationAngle, 0, degrot[unitID], 0)
						else
							glDrawListAtUnit(unitID, unit.shape.large, false, (unit.xscale*scale*changedScale)+((unit.xscale-15)/15), 1.0, (unit.zscale*scale*changedScale)+((unit.zscale-15)/15), usedRotationAngle, 0, degrot[unitID], 0)
						end
						
					elseif type == 'base solid'  or  type == 'base alpha' then
						usedXScale = unit.xscale
						usedZScale = unit.zscale
						if OPTIONScurrentOption.showExtraComLine and (unit.name == 'corcom'  or  unit.name == 'armcom') then
							usedXScale = usedXScale * 1.23
							usedZScale = usedZScale * 1.23
						elseif OPTIONScurrentOption.showExtraBuildingWeaponLine and unit.shapeName == 'square' then
							if (unit.weaponcount > 0) then
								usedXScale = usedXScale * 1.14
								usedZScale = usedZScale * 1.14
							end
						end
						glDrawListAtUnit(unitID, unit.shape.large, false, (usedXScale*scale*changedScale)-((usedXScale*changedScale-10)/10), 1.0, (usedZScale*scale*changedScale)-((usedZScale*changedScale-10)/10), degrot[unitID], 0, degrot[unitID], 0)
						
					elseif type == 'unit highlight' then
					
						if OPTIONScurrentOption.showUnitHighlightHealth then
							health,maxHealth,paralyzeDamage,captureProgress,buildProgress = spGetUnitHealth(unitID)
							gl.Color(
								health>maxHealth/2 and 2-2*health/maxHealth or 1,
								health>maxHealth/2 and 1 or 2*health/maxHealth,
								paralyzeDamage/maxHealth,
								usedAlpha
							)
						end
						gl.Unit(unitID, true)
					end	
				end
			end
		end	
	end
end --// end do



--  Draw selection circle (only one layer)
function DrawSelectionSpotters(teamID, r,g,b,a,scale, opposite, relativeScaleSchrinking, drawUnitStyles)
	
	gl.ColorMask(false, false, false, true)
	gl.BlendFunc(GL.ONE_MINUS_SRC_ALPHA, GL.SRC_ALPHA)
	if OPTIONS[currentOption].showFirstLineDetails then
		if OPTIONS[currentOption].showNoOverlap then
			-- draw normal spotters solid
			gl.Color(r,g,b,0)
			DrawSelectionSpottersPart(teamID, 'normal solid', r,g,b,a,scale, opposite, relativeScaleSchrinking, false, drawUnitStyles)
			
			--  Here the spotters are given the alpha level (this step makes sure overlappings dont have different alpha level)
			gl.BlendFunc(GL.ONE, GL.ZERO)
			gl.Color(r,g,b,a)
			DrawSelectionSpottersPart(teamID, 'normal alpha', r,g,b,a,scale, opposite, relativeScaleSchrinking, true, drawUnitStyles)
		else
			gl.Color(r,g,b,a)
			DrawSelectionSpottersPart(teamID, 'normal alpha', r,g,b,a,scale, opposite, relativeScaleSchrinking, true, drawUnitStyles)
		end
	end
	
	--  Here the inner of the selected spotters are removed
	gl.BlendFunc(GL.ONE, GL.ZERO)
	gl.Color(r,g,b,1)
	DrawSelectionSpottersPart(teamID, 'solid overlap', r,g,b,a,scale, opposite, relativeScaleSchrinking, false, drawUnitStyles)
	
	--  Really draw the spotters now  (This could be optimised if we could say Draw as much as DST_ALPHA * SRC_ALPHA is)
	-- (without protecting form drawing them twice)
	gl.ColorMask(true, true, true, true)
	gl.BlendFunc(GL.ONE_MINUS_DST_ALPHA, GL.DST_ALPHA)
	
	-- Does not need to be drawn per Unit anymore
	glCallList(clearquad)
end


function widget:DrawWorldPreUnit()
	
	local clockDifference = (os.clock() - previousOsClock)
	previousOsClock = os.clock()
	
	--if spIsGUIHidden() then return end
	
	gl.PushAttrib(GL.COLOR_BUFFER_BIT)
	gl.DepthTest(false)
	
	-- animate rotation
	if OPTIONS[currentOption].rotationSpeed > 0 then
		local angleDifference = (OPTIONS[currentOption].rotationSpeed) * (clockDifference * 5)
		currentRotationAngle = currentRotationAngle + (angleDifference*0.66)
		if currentRotationAngle > 360 then
		   currentRotationAngle = currentRotationAngle - 360
		end
	
		currentRotationAngleOpposite = currentRotationAngleOpposite - angleDifference
		if currentRotationAngleOpposite < -360 then
		   currentRotationAngleOpposite = currentRotationAngleOpposite + 360
		end
	end
	
	-- animate scale 
	if OPTIONS[currentOption].animateSpotterSize then
		local addedMultiplierValue = OPTIONS[currentOption].animationSpeed * (clockDifference * 50)
		if (animationMultiplierAdd  and  animationMultiplier < OPTIONS[currentOption].maxAnimationMultiplier) then
			animationMultiplier = animationMultiplier + addedMultiplierValue
			animationMultiplierInner = animationMultiplierInner - addedMultiplierValue
			if (animationMultiplier > OPTIONS[currentOption].maxAnimationMultiplier) then
				animationMultiplier = OPTIONS[currentOption].maxAnimationMultiplier
				animationMultiplierInner = OPTIONS[currentOption].minAnimationMultiplier
				animationMultiplierAdd = false
			end
		else
			animationMultiplier = animationMultiplier - addedMultiplierValue
			animationMultiplierInner = animationMultiplierInner + addedMultiplierValue
			if (animationMultiplier < OPTIONS[currentOption].minAnimationMultiplier) then
				animationMultiplier = OPTIONS[currentOption].minAnimationMultiplier
				animationMultiplierInner = OPTIONS[currentOption].maxAnimationMultiplier
				animationMultiplierAdd = true
			end
		end
	end
	
	-- loop teams
	local baseR, baseG, baseB, r, g, b, a, scale, scaleBase, scaleOuter
	for teamID,_ in pairs(selectedUnits) do
		
		r,g,b = 1,1,1
		scale = 1 * OPTIONS[currentOption].scaleMultiplier * animationMultiplierInner
		scaleBase = scale * 1.133
		if OPTIONS[currentOption].showSecondLine then 
			scaleOuter = (1 * OPTIONS[currentOption].scaleMultiplier * animationMultiplier) * 1.18
			scaleBase = scaleOuter * 1.08
		end
		
		gl.ColorMask(false, false, false, true)
		gl.BlendFunc(GL.ONE, GL.ONE)
		gl.Color(r,g,b,1)
		glCallList(clearquad)
		
		-- draw base background layer
		if OPTIONS[currentOption].showBase then
			baseR, baseG, baseB = r,g,b
			baseR,baseG,baseB = spGetTeamColor(teamID)
			
			gl.Blending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)
			DrawSelectionSpottersPart(teamID, 'base solid', baseR,baseG,baseB,0,scaleBase, false, false, false, false)
			
			--  Here the inner of the selected spotters are removed
			gl.BlendFunc(GL.ONE, GL.ZERO)
			a = OPTIONS[currentOption].baseOpacity + (OPTIONS[currentOption].baseOpacity * (OPTIONS[currentOption].spotterOpacity*OPTIONS[currentOption].opacitySliderMultiplier))
			DrawSelectionSpottersPart(teamID, 'base alpha', baseR,baseG,baseB,a,scaleBase, false, false, true, false)
			
			--  Really draw the spotters now  (This could be optimised if we could say Draw as much as DST_ALPHA * SRC_ALPHA is)
			-- (without protecting form drawing them twice)
			gl.ColorMask(true,true,true,true)
			gl.BlendFunc(GL.ONE_MINUS_DST_ALPHA, GL.DST_ALPHA)
			glCallList(clearquad)
		end
		
		-- draw 1st line layer
		if OPTIONS[currentOption].showFirstLine then
			a = OPTIONS[currentOption].firstLineOpacity + (OPTIONS[currentOption].firstLineOpacity * (OPTIONS[currentOption].spotterOpacity*(OPTIONS[currentOption].opacitySliderMultiplier*100)))
			DrawSelectionSpotters(teamID, r,g,b,a,scale,false,false,false)
		end
		
		-- draw 2nd line layer
		if OPTIONS[currentOption].showSecondLine then
			--DrawSelectionSpotters(teamID, r,g,b,OPTIONS[currentOption].secondLineOpacity + (OPTIONS[currentOption].secondLineOpacity * OPTIONS[currentOption].spotterOpacity),scaleOuter, true, true, true)
			
			a = OPTIONS[currentOption].secondLineOpacity + (OPTIONS[currentOption].secondLineOpacity * (OPTIONS[currentOption].spotterOpacity*(OPTIONS[currentOption].opacitySliderMultiplier*100)))
			gl.ColorMask(false, false, false, true)
			gl.BlendFunc(GL.ONE_MINUS_SRC_ALPHA, GL.SRC_ALPHA)
			
			--  Here the inner of the selected spotters are removed
			gl.BlendFunc(GL.ONE, GL.ZERO)
			gl.Color(r,g,b,1)
			DrawSelectionSpottersPart(teamID, 'solid overlap', r,g,b,a,scaleOuter, true, true, false, true)
			
			--  Really draw the spotters now  (This could be optimised if we could say Draw as much as DST_ALPHA * SRC_ALPHA is)
			-- (without protecting form drawing them twice)
			gl.ColorMask(true, true, true, true)
			gl.BlendFunc(GL.ONE_MINUS_DST_ALPHA, GL.DST_ALPHA)
			
			-- Does not need to be drawn per Unit anymore
			glCallList(clearquad)
		end
	end
	
	gl.ColorMask(false,false,false,false)
		
	gl.Color(1,1,1,1)
	gl.PopAttrib()
end


function widget:DrawWorld()
	-- draw unit highlight
	if OPTIONS[currentOption].unitHighlightOpacity > 0  and (OPTIONS[currentOption].showUnitHighlight or OPTIONS[currentOption].showUnitHighlightHealth) then
		gl.DepthTest(true)
		gl.PolygonOffset(-2, -2)
		gl.Blending(GL.SRC_ALPHA, GL.ONE)
		local opacity = OPTIONS[currentOption].unitHighlightOpacity - (OPTIONS[currentOption].unitHighlightOpacity * (OPTIONS[currentOption].spotterOpacity/10))
		local r,g,b
		-- loop teams
		for teamID,_ in pairs(selectedUnits) do
			r,g,b = spGetTeamColor(teamID)
			DrawSelectionSpottersPart(teamID, 'unit highlight', r,g,b,opacity,0, false, false, true, false)
		end
		gl.Blending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)
		gl.PolygonOffset(false)
		gl.DepthTest(false)
	end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Config related

function widget:GetConfigData(data)
    savedTable = {}
    savedTable.currentOption					= currentOption
    savedTable.spotterOpacity					= OPTIONS[currentOption].spotterOpacity
    savedTable.showSecondLine					= OPTIONS.defaults.showSecondLine
    savedTable.showUnitHighlight				= OPTIONS.defaults.showUnitHighlight
    
    return savedTable
end

function widget:SetConfigData(data)
    currentOption								= data.currentOption		or currentOption
    OPTIONS[currentOption].spotterOpacity		= data.spotterOpacity		or OPTIONS[currentOption].spotterOpacity
    OPTIONS.defaults.showSecondLine				= data.showSecondLine		or OPTIONS.defaults.showSecondLine
    OPTIONS.defaults.showUnitHighlight			= data.showUnitHighlight	or OPTIONS.defaults.showUnitHighlight
end

function widget:TextCommand(command)
	
    if (string.find(command, "selectedunits_style") == 1  and  string.len(command) == 19) then 
		toggleOptions()
	end
	if (string.find(command, "+selectedunits_opacity") == 1) then OPTIONS[currentOption].spotterOpacity = OPTIONS[currentOption].spotterOpacity - 0.03 end
	if (string.find(command, "-selectedunits_opacity") == 1) then OPTIONS[currentOption].spotterOpacity = OPTIONS[currentOption].spotterOpacity + 0.03 end
end

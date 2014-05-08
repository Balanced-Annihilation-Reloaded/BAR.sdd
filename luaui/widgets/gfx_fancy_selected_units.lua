function widget:GetInfo()
   return {
      name      = "Fancy Selected Units",
      desc      = "Switch styles with /selectedunits_style",
      author    = "Floris",
      date      = "04.04.2014",
      license   = "GNU GPL, v2 or later",
      layer     = 2,
      enabled   = true
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

local maxSelectTime					= 0				--time at which units "new selection" animation will end
local maxDeselectedTime				= -1			--time at which units deselection animation will end

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

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local OPTIONS = {
	-- opacity
	spotterOpacity					= 1,			-- 0 is opaque
	baseOpacity						= 0.77,			-- 0 is opaque
	
	-- animation
	selectionStartAnimation			= true,
	selectionStartAnimationTime		= 0.25, --high so as visible while developing
	selectionStartAnimationScale	= 0.8,
	-- selectionStartAnimationScale	= 1.17,
	selectionStartAnimationOpacity	= 0,	-- starts with this addition opacity, over makes it overflow a bit at the end of the fadein
	selectionEndAnimation			= true,
	selectionEndAnimationTime		= 0.25, --high so as visible while developing
	selectionEndAnimationScale		= 0.9,
	selectionEndAnimationOpacity    = 0,
	-- selectionEndAnimationScale	= 1.17,
	animationSpeed					= 0.0006,
	
	-- prefer not to change because other widgets use these values too  (enemyspotter, given_units, selfd_icons)
	scaleFactor						= 2.9,			
	rectangleFactor					= 3.3,
}
OPTIONS[1] = {
	-- Quality settings
	showNoOverlap					= false,	-- set true for no line overlapping
	showBase						= true,
	showFirstLine					= true,
	showSecondLine					= true,
	showExtraComLine				= true,		-- extra circle lines for the commander unit
	showExtraBuildingWeaponLine		= true,
	
	circlePieces					= 36,		-- (1 or higher)
	circlePieceDetail				= 1,		-- smoothness of each piece (1 or higher)
	circleSpaceUsage				= 0.7,		-- 1 = whole circle space gets filled
	circleInnerOffset				= 0.45,
	
	-- size
	scaleMultiplier					= 1.04,
	innersize						= 1.7,
	selectinner						= 1.65,
	outersize						= 1.8,
	
	firstLineOpacity				= 0.06,
	secondLineOpacity				= 0.35,
	
	-- animation
	rotationSpeed					= 0.08,
	animateSpotterSize				= true,
	animateInnerSpotterSize			= true,
	maxAnimationMultiplier			= 1.014,
	minAnimationMultiplier			= 0.99
}
OPTIONS[2] = {
	-- Quality settings
	showNoOverlap					= false,	-- set true for no line overlapping
	showBase						= true,
	showFirstLine					= true,
	showSecondLine					= true,
	showExtraComLine				= true,		-- extra circle lines for the commander unit
	showExtraBuildingWeaponLine		= true,
	
	circlePieces					= 22,		-- (1 or higher)
	circlePieceDetail				= 4,		-- smoothness of each piece (1 or higher)
	circleSpaceUsage				= 0.28,		-- 1 = whole circle space gets filled
	circleInnerOffset				= 1,
	
	-- size
	scaleMultiplier					= 1.04,
	innersize						= 1.7,
	selectinner						= 1.65,
	outersize						= 1.8,
	
	-- opacity
	firstLineOpacity				= 0.06,
	secondLineOpacity				= 0.35,
	
	-- animation
	rotationSpeed					= 0.08,
	animateSpotterSize				= true,
	animateInnerSpotterSize			= true,
	maxAnimationMultiplier			= 1.014,
	minAnimationMultiplier			= 0.99
}
OPTIONS[3] = {
	-- Quality settings
	showNoOverlap					= false,	-- set true for no line overlapping
	showBase						= true,
	showFirstLine					= true,
	showSecondLine					= true,
	showExtraComLine				= true,		-- extra circle lines for the commander unit
	showExtraBuildingWeaponLine		= true,
	
	circlePieces					= 12,		-- (1 or higher)
	circlePieceDetail				= 4,		-- smoothness of each piece (1 or higher)
	circleSpaceUsage				= 0.75,		-- 1 = whole circle space gets filled
	circleInnerOffset				= 0,
	
	-- size
	scaleMultiplier					= 1.04,
	innersize						= 1.7,
	selectinner						= 1.65,
	outersize						= 1.8,
	
	-- opacity
	firstLineOpacity				= 0.06,
	secondLineOpacity				= 0.35,
	
	-- animation
	rotationSpeed					= 0.1,
	animateSpotterSize				= true,
	animateInnerSpotterSize			= true,
	maxAnimationMultiplier			= 1.014,
	minAnimationMultiplier			= 0.99
}
OPTIONS[4] = {
	-- Quality settings
	showNoOverlap					= false,	-- set true for no line overlapping
	showBase						= true,
	showFirstLine					= true,
	showSecondLine					= true,
	showExtraComLine				= true,		-- extra circle lines for the commander unit
	showExtraBuildingWeaponLine		= true,
	
	circlePieces					= 5,		-- (1 or higher)
	circlePieceDetail				= 7,		-- smoothness of each piece (1 or higher)
	circleSpaceUsage				= 0.75,		-- 1 = whole circle space gets filled
	circleInnerOffset				= 0,
	
	-- size
	scaleMultiplier					= 1.04,
	innersize						= 1.7,
	selectinner						= 1.65,
	outersize						= 1.8,
	
	-- opacity
	firstLineOpacity				= 0.06,
	secondLineOpacity				= 0.35,
	
	-- animation
	rotationSpeed					= 0.22,
	animateSpotterSize				= true,
	animateInnerSpotterSize			= true,
	maxAnimationMultiplier			= 1.014,
	minAnimationMultiplier			= 0.99
}
local currentOption		= 1
local totalOptions		= 4


------------------------------------------------------------------------------------
------------------------------------------------------------------------------------


local function toggleOptions()
	currentOption = currentOption + 1
	if currentOption > totalOptions then
		currentOption = 1
	end
	loadConfig()
end


local function updateSelectedUnitsData()
	
	-- remove deselected units 
	local os_clock = os.clock()
	for teamID,_ in pairs(selectedUnits) do
		for unitID,_ in pairs(selectedUnits[teamID]) do
			if not spIsUnitSelected(unitID) and selectedUnits[teamID][unitID]['selected'] then
				local clockDifference = OPTIONS.selectionStartAnimationTime - (os_clock - selectedUnits[teamID][unitID]['new'])
				if clockDifference < 0 then
					clockDifference = 0
				end
				selectedUnits[teamID][unitID]['selected'] = false 
				selectedUnits[teamID][unitID]['new'] = false
				selectedUnits[teamID][unitID]['old'] = os_clock - clockDifference
			end
		end
	end
	
	-- add selected units
	if spGetSelectedUnitsCount() > 0 then
		local units = spGetSelectedUnitsSorted()
		for uDID,_ in pairs(units) do
			if uDID ~= 'n' then --'n' returns table size
				for i=1,#units[uDID] do
					local unitID = units[uDID][i]
					local unit = UNITCONF[uDID]
					if (unit) then
						teamID = spGetUnitTeam(unitID)
						if not selectedUnits[teamID] then
							selectedUnits[teamID] = {}
						end
						if not selectedUnits[teamID][unitID] then
							selectedUnits[teamID][unitID]			= {}
							selectedUnits[teamID][unitID]['new']	= os_clock
						elseif selectedUnits[teamID][unitID]['old'] then
							local clockDifference = OPTIONS.selectionEndAnimationTime - (os_clock - selectedUnits[teamID][unitID]['old'])
							if clockDifference < 0 then
								clockDifference = 0
							end
							selectedUnits[teamID][unitID]['new']	= os_clock - clockDifference
							selectedUnits[teamID][unitID]['old']	= nil
						end
						selectedUnits[teamID][unitID]['selected']	= true
					end
				end
			end
		end
	end
end



function KeyExists(tbl, key)
	for k in pairs(tbl) do
		if key == k then
			return true
		end
	end
	return false
end

function Round(num, idp)
    local mult = 10^(idp or 0)
    return math.floor(num * mult + 0.5) / mult
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
	
	local zeroColor = {0, 0, 0, 0}
	
	displayLists.select = callback.fading(OPTIONS[currentOption].outersize, OPTIONS[currentOption].selectinner)
	displayLists.invertedSelect = callback.fading(OPTIONS[currentOption].outersize, OPTIONS[currentOption].selectinner)
	displayLists.inner = callback.solid(zeroColor, OPTIONS[currentOption].innersize)
	displayLists.large = callback.solid(nil, OPTIONS[currentOption].selectinner)
	displayLists.kill = callback.solid(nil, OPTIONS[currentOption].outersize)
	displayLists.shape = callback.fading(OPTIONS[currentOption].innersize, OPTIONS[currentOption].selectinner)
	
	return displayLists
end



local function DrawCircleLine(innersize, outersize)
	gl.BeginEnd(GL.QUADS, function()
		local width = OPTIONS[currentOption].circleSpaceUsage
		local detail = OPTIONS[currentOption].circlePieceDetail
		
		local radstep = (2.0 * math.pi) / OPTIONS[currentOption].circlePieces
		for i = 1, OPTIONS[currentOption].circlePieces do
			for d = 1, detail do
				
				local detailPartWidth = ((width / detail) * d)
				local a1 = ((i+detailPartWidth - (width / detail)) * radstep)
				local a2 = ((i+detailPartWidth) * radstep)
				local a3 = ((i+OPTIONS[currentOption].circleInnerOffset+detailPartWidth - (width / detail)) * radstep)
				local a4 = ((i+OPTIONS[currentOption].circleInnerOffset+detailPartWidth) * radstep)
				
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
		if (color) then
			gl.Color(color)
		end
		gl.Vertex(0, 0, 0)
		for i = 0, pieces do
			local a1 = (i * radstep)
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
		local parts = 4
		local radstep = (2.0 * math.pi) / parts
		
		for i = 1, parts do
			-- straight piece
			local width = 0.7
			i = i + 0.65
			local a1 = (i * radstep)
			local a2 = ((i+width) * radstep)
			
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
			local a2_2 = ((i+width) * radstep)
			
			gl.Vertex(math.sin(a2_2)*innersize, 0, math.cos(a2_2)*innersize)
			gl.Vertex(math.sin(a1)*innersize, 0, math.cos(a1)*innersize)
			
			gl.Vertex(math.sin(a1)*outersize, 0, math.cos(a1)*outersize)
			gl.Vertex(math.sin(a2_2)*outersize, 0, math.cos(a2_2)*outersize)
		end
	end)
end

local function DrawSquareSolid(size)
	gl.BeginEnd(GL.TRIANGLE_FAN, function()
		
		local parts = 4
		local radstep = (2.0 * math.pi) / parts
		
		gl.Vertex(0, 0, 0)
		
		for i = 1, parts do
			--straight piece
			local width = 0.7
			i = i + 0.65
			local a1 = (i * radstep)
			local a2 = ((i+width) * radstep)
			
			gl.Vertex(math.sin(a2)*size, 0, math.cos(a2)*size)
			gl.Vertex(math.sin(a1)*size, 0, math.cos(a1)*size)
			
			--corner piece
			width = 0.3
			i = i + 3
			a1 = (i * radstep)
			a2 = ((i+width) * radstep)
			i = i -0.6
			local a2_2 = ((i+width) * radstep)
			
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
		
		local parts = 3
		local radstep = (2.0 * math.pi) / parts
		
		for i = 1, parts do
			--straight piece
			local width = 0.7
			i = i + 0.65
			local a1 = (i * radstep)
			local a2 = ((i+width) * radstep)
			
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
			local a2_2 = ((i+width) * radstep)
			
			gl.Vertex(math.sin(a2_2)*innersize, 0, math.cos(a2_2)*innersize)
			gl.Vertex(math.sin(a1)*innersize, 0, math.cos(a1)*innersize)
			
			gl.Vertex(math.sin(a1)*outersize, 0, math.cos(a1)*outersize)
			gl.Vertex(math.sin(a2_2)*outersize, 0, math.cos(a2_2)*outersize)
		end
		
	end)
end

local function DrawTriangleSolid(size)	
	
	gl.BeginEnd(GL.TRIANGLE_FAN, function()
		
		local parts = 3
		local radstep = (2.0 * math.pi) / parts
		
		gl.Vertex(0, 0, 0)
		
		for i = 1, parts do
			-- straight piece
			local width = 0.7
			i = i + 0.65
			local a1 = (i * radstep)
			local a2 = ((i+width) * radstep)
			
			gl.Vertex(math.sin(a2)*size, 0, math.cos(a2)*size)
			gl.Vertex(math.sin(a1)*size, 0, math.cos(a1)*size)
			
			-- corner piece
			width = 0.3
			i = i + 3
			a1 = (i * radstep)
			a2 = ((i+width) * radstep)
			i = i -0.6
			local a2_2 = ((i+width) * radstep)
			
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



local function DestroyShape(shape)
	gl.DeleteList(shape.select)
	gl.DeleteList(shape.invertedSelect)
	gl.DeleteList(shape.inner)
	gl.DeleteList(shape.large)
	gl.DeleteList(shape.kill)
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
end


function loadConfig()
	CreateCircleLists()
	CreateSquareLists()
	CreateTriangleLists()
	
	SetUnitConf()
end


function SetUnitConf()
	for udid, unitDef in pairs(UnitDefs) do
		local xsize, zsize = unitDef.xsize, unitDef.zsize
		local scale = OPTIONS.scaleFactor*( xsize^2 + zsize^2 )^0.5
		local shape, xscale, zscale
		
		if (unitDef.isBuilding or unitDef.isFactory or unitDef.speed==0) then
			shape = shapes.square
			xscale, zscale = OPTIONS.rectangleFactor * xsize, OPTIONS.rectangleFactor * zsize
		elseif (unitDef.isAirUnit) then
			shape = shapes.triangle
			xscale, zscale = scale, scale
		else
			shape = shapes.circle
			xscale, zscale = scale, scale
		end
		
		UNITCONF[udid] = {shape=shape, xscale=xscale, zscale=zscale}
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
	maxSelectTime = currentClock - OPTIONS.selectionStartAnimationTime
	maxDeselectedTime = currentClock - OPTIONS.selectionEndAnimationTime
	
	updateSelectedUnitsData()		-- calling updateSelectedUnitsData() inside widget:CommandsChanged() will return in buggy behavior in combination with the 'smart-select' widget
end



local degrot = {}
function widget:GameFrame(frame)
	
	if frame%2~=0 then return end
	
	-- logs current unit direction	(needs regular updates for air units, and for buildings only once)
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



function GetUsedRotationAngle(unitID, unitUnitDefs, opposite)
	if (unitUnitDefs.isBuilding or unitUnitDefs.isFactory or unitUnitDefs.speed==0) then
		usedRotationAngle = degrot[unitID]
	elseif (unitUnitDefs.isAirUnit) then
		usedRotationAngle = degrot[unitID]
	else
		if opposite then 
			usedRotationAngle = currentRotationAngleOpposite
		else
			usedRotationAngle = currentRotationAngle
		end
	end
	return usedRotationAngle
end


function DrawSelectionSpottersPart(teamID, type, r,g,b,a,scale, opposite, relativeScaleSchrinking, changeOpacity, drawUnitStyles)
	
	local camX, camY, camZ = spGetCameraPosition()
	
	for unitID in pairs(selectedUnits[teamID]) do
		local udid = spGetUnitDefID(unitID)
		local unitUnitDefs = UnitDefs[udid]
		local unit = UNITCONF[udid]
		local draw = true
		
		if (unit) then
			local unitPosX, unitPosY, unitPosZ = spGetUnitViewPosition(unitID, true)
			local camHeightDifference = camY - unitPosY
			
			local changedScale = 1
			local usedAlpha = a
				
			if not selectedUnits[teamID][unitID] then return end 
			
			if (OPTIONS.selectionEndAnimation  or  OPTIONS.selectionStartAnimation) then
				if changeOpacity then
					gl.Color(r,g,b,a)
				end
				-- check if the unit is deselected
				if (OPTIONS.selectionEndAnimation and not selectedUnits[teamID][unitID]['selected']) then
					if (maxDeselectedTime < selectedUnits[teamID][unitID]['old']) then
						changedScale = OPTIONS.selectionEndAnimationScale + (((selectedUnits[teamID][unitID]['old'] - maxDeselectedTime) / OPTIONS.selectionEndAnimationTime)) * (1 - OPTIONS.selectionEndAnimationScale)
						if (changeOpacity) then
							usedAlpha = 1 - OPTIONS.selectionEndAnimationOpacity - (((selectedUnits[teamID][unitID]['old'] - maxDeselectedTime) / OPTIONS.selectionEndAnimationTime) * (1-a))
							gl.Color(r,g,b,usedAlpha)
						end
					else
						selectedUnits[teamID][unitID] = nil
					end
				-- check if the unit is newly selected
				elseif (OPTIONS.selectionStartAnimation and selectedUnits[teamID][unitID]['new'] > maxSelectTime) then
					--spEcho(selectedUnits[teamID][unitID]['new'] - maxSelectTime)
					changedScale = OPTIONS.selectionStartAnimationScale + (((currentClock - selectedUnits[teamID][unitID]['new']) / OPTIONS.selectionStartAnimationTime)) * (1 - OPTIONS.selectionStartAnimationScale)
					if (changeOpacity) then
						usedAlpha = 1 - OPTIONS.selectionStartAnimationOpacity - (((currentClock - selectedUnits[teamID][unitID]['new']) / OPTIONS.selectionStartAnimationTime) * (1-a))
						gl.Color(r,g,b,usedAlpha)
					end
				end
			end
			
			if selectedUnits[teamID][unitID] then
				local usedRotationAngle = GetUsedRotationAngle(unitID, unitUnitDefs ,opposite)
				if type == 'normal solid'  or  type == 'normal alpha' then
					
					-- special style for coms
					if drawUnitStyles and OPTIONS[currentOption].showExtraComLine and (unitUnitDefs.name == 'corcom'  or  unitUnitDefs.name == 'armcom') then
						usedRotationAngle = GetUsedRotationAngle(unitID, unitUnitDefs)
						gl.Color(r,g,b,(usedAlpha*usedAlpha)+0.22)
						local usedScale = scale * 1.25
						glDrawListAtUnit(unitID, unit.shape.inner, false, (unit.xscale*usedScale*changedScale)-((unit.xscale*changedScale-10)/10), 1.0, (unit.zscale*usedScale*changedScale)-((unit.zscale*changedScale-10)/10), currentRotationAngleOpposite, 0, degrot[unitID], 0)
						usedScale = scale * 1.23
						usedRotationAngle = GetUsedRotationAngle(unitID, unitUnitDefs , true)
						gl.Color(r,g,b,(usedAlpha*usedAlpha)+0.08)
						glDrawListAtUnit(unitID, unit.shape.large, false, (unit.xscale*usedScale*changedScale)-((unit.xscale*changedScale-10)/10), 1.0, (unit.zscale*usedScale*changedScale)-((unit.zscale*changedScale-10)/10), 0, 0, degrot[unitID], 0)
					else
						-- adding style for buildings with weapons
						if drawUnitStyles and OPTIONS[currentOption].showExtraBuildingWeaponLine and (unitUnitDefs.isBuilding or unitUnitDefs.isFactory or unitUnitDefs.speed==0) then
							if (#unitUnitDefs.weapons > 0) then
								usedRotationAngle = GetUsedRotationAngle(unitID, unitUnitDefs)
								gl.Color(r,g,b,usedAlpha*(usedAlpha+0.2))
								local usedScale = scale * 1.11
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
					
				elseif type == 'alphabuffer1' then
					
					glDrawListAtUnit(unitID, unit.shape.shape, false, unit.xscale*scale*changedScale, 1.0, unit.zscale*scale*changedScale, usedRotationAngle, 0, degrot[unitID], 0)
					glDrawListAtUnit(unitID, unit.shape.inner, false, unit.xscale*scale*changedScale, 1.0, unit.zscale*scale*changedScale, usedRotationAngle, 0, degrot[unitID], 0)
					
				elseif type == 'alphabuffer2' then
					
					glDrawListAtUnit(unitID, unit.shape.large, false, unit.xscale*scale*changedScale, 1.0, unit.zscale*scale*changedScale, usedRotationAngle, 0, degrot[unitID], 0)
					
				elseif type == 'base solid'  or  type == 'base alpha' then
					local usedXScale = unit.xscale
					local usedZScale = unit.zscale
					if OPTIONS[currentOption].showExtraComLine and (unitUnitDefs.name == 'corcom'  or  unitUnitDefs.name == 'armcom') then
						usedXScale = usedXScale * 1.23
						usedZScale = usedZScale * 1.23
					elseif OPTIONS[currentOption].showExtraBuildingWeaponLine and (unitUnitDefs.isBuilding or unitUnitDefs.isFactory or unitUnitDefs.speed==0) then
						if (#unitUnitDefs.weapons > 0) then
							usedXScale = usedXScale * 1.14
							usedZScale = usedZScale * 1.14
						end
					end
					glDrawListAtUnit(unitID, unit.shape.large, false, (usedXScale*scale*changedScale)-((usedXScale*changedScale-10)/10), 1.0, (usedZScale*scale*changedScale)-((usedZScale*changedScale-10)/10), degrot[unitID], 0, degrot[unitID], 0)
					
				end	
			end
		end
	end	
end



--  Draw selection circle (only one layer)
function DrawSelectionSpotters(teamID, r,g,b,a,scale, opposite, relativeScaleSchrinking, drawUnitStyles)
	
	gl.BlendFunc(GL.ONE_MINUS_SRC_ALPHA, GL.SRC_ALPHA)
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
	
	--  Here the inner of the selected spotters are removed
	gl.BlendFunc(GL.ONE, GL.ZERO)
	gl.Color(r,g,b,1)
	DrawSelectionSpottersPart(teamID, 'solid overlap', r,g,b,a,scale, opposite, relativeScaleSchrinking, false, drawUnitStyles)
	
	
	--  Really draw the spotters now  (This could be optimised if we could say Draw as much as DST_ALPHA * SRC_ALPHA is)
	-- (without protecting form drawing them twice)
	gl.ColorMask(true,true,true,true)
	gl.BlendFunc(GL.ONE_MINUS_DST_ALPHA, GL.DST_ALPHA)
	gl.Color(r,g,b,1)
	
	-- Does not need to be drawn per Unit anymore
	glCallList(clearquad)
	
	--  Draw spotters to AlphaBuffer
	gl.ColorMask(false, false, false, true)
	gl.BlendFunc(GL.DST_ALPHA, GL.ZERO)
	
	DrawSelectionSpottersPart(teamID, 'alphabuffer1', r,g,b,a,scale, opposite, relativeScaleSchrinking, false, drawUnitStyles)
	
	DrawSelectionSpottersPart(teamID, 'alphabuffer2', r,g,b,a,scale, opposite, relativeScaleSchrinking, false, drawUnitStyles)
end



function widget:DrawWorldPreUnit()
	
	local clockDifference = (os.clock() - previousOsClock)
	previousOsClock = os.clock()
	
	if spIsGUIHidden() then return end
	
	gl.PushAttrib(GL.COLOR_BUFFER_BIT)
	gl.DepthTest(false)
	
	
	if not paused then
		currentRotationAngle = currentRotationAngle + (OPTIONS[currentOption].rotationSpeed/2)
		if currentRotationAngle > 360 then
		   currentRotationAngle = currentRotationAngle - 360
		end
		local rotationSpeedMultiplier = (clockDifference * 50)
			
		currentRotationAngle = currentRotationAngle + ((OPTIONS[currentOption].rotationSpeed/2) * rotationSpeedMultiplier)
		
		
		currentRotationAngleOpposite = currentRotationAngleOpposite - OPTIONS[currentOption].rotationSpeed
		if currentRotationAngleOpposite < -360 then
		   currentRotationAngleOpposite = currentRotationAngleOpposite + 360
		end
		
		currentRotationAngleOpposite = currentRotationAngleOpposite - (OPTIONS[currentOption].rotationSpeed * rotationSpeedMultiplier)
	end
	
	
	-- animate spotter scale 
	if OPTIONS[currentOption].animateSpotterSize then
		local addedMultiplierValue = OPTIONS.animationSpeed * (clockDifference * 50)
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
	for teamID,_ in pairs(selectedUnits) do
		
		local r,g,b = 1,1,1
		local scale = 1 * OPTIONS[currentOption].scaleMultiplier * animationMultiplierInner
		local scaleBase = scale * 1.133
		if OPTIONS[currentOption].showSecondLine then 
			scaleOuter = (1 * OPTIONS[currentOption].scaleMultiplier * animationMultiplier) * 1.17
			scaleBase = scaleOuter * 1.07
		end
		
		gl.ColorMask(false,false,false,true)
		gl.BlendFunc(GL.ONE, GL.ONE)
		gl.Color(r,g,b,1)
		glCallList(clearquad)
		
		-- base layer
		if OPTIONS[currentOption].showBase then
			local baseR, baseG, baseB = r,g,b
			baseR,baseG,baseB = spGetTeamColor(teamID)
			
			gl.Blending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)
			DrawSelectionSpottersPart(teamID, 'base solid', baseR,baseG,baseB,0,scaleBase, false, false, false, false)
			
			--  Here the inner of the selected spotters are removed
			gl.BlendFunc(GL.ONE, GL.ZERO)
			DrawSelectionSpottersPart(teamID, 'base alpha', baseR,baseG,baseB,OPTIONS.baseOpacity * OPTIONS.spotterOpacity,scaleBase, false, false, true, false)
			
			--  Really draw the spotters now  (This could be optimised if we could say Draw as much as DST_ALPHA * SRC_ALPHA is)
			-- (without protecting form drawing them twice)
			gl.ColorMask(true,true,true,true)
			gl.BlendFunc(GL.ONE_MINUS_DST_ALPHA, GL.DST_ALPHA)
			glCallList(clearquad)
		end
		
		gl.ColorMask(false,false,false,true)
		
		-- 1st layer
		DrawSelectionSpotters(teamID, r,g,b,OPTIONS[currentOption].firstLineOpacity * OPTIONS.spotterOpacity,scale,false,false,false)
		
		-- 2nd layer
		if OPTIONS[currentOption].showSecondLine then
			DrawSelectionSpotters(teamID, r,g,b,OPTIONS[currentOption].secondLineOpacity * OPTIONS.spotterOpacity,scaleOuter, true, true, true)
		end
		
	end
	
	gl.BlendFunc(GL.ONE_MINUS_DST_ALPHA, GL.DST_ALPHA)
	glCallList(clearquad)
		
	gl.Color(1,1,1,1)
	gl.PopAttrib()
end



--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Config related

function widget:GetConfigData(data)
    savedTable = {}
    savedTable.currentOption		= currentOption
    savedTable.spotterOpacity		= OPTIONS.spotterOpacity
    savedTable.baseOpacity			= OPTIONS.baseOpacity
    return savedTable
end

function widget:SetConfigData(data)
    currentOption					= data.currentOption		or currentOption
    OPTIONS.spotterOpacity			= data.spotterOpacity		or OPTIONS.spotterOpacity
    OPTIONS.baseOpacity				= data.baseOpacity		or OPTIONS.baseOpacity
end

function widget:TextCommand(command)
	
    if (string.find(command, "selectedunits_style") == 1  and  string.len(command) == 19) then 
		toggleOptions()
	end
	if (string.find(command, "+selectedunits_opacity") == 1) then OPTIONS.spotterOpacity = OPTIONS.spotterOpacity - 0.02 end
	if (string.find(command, "-selectedunits_opacity") == 1) then OPTIONS.spotterOpacity = OPTIONS.spotterOpacity + 0.02 end
	
	if (string.find(command, "+selectedunits_baseopacity") == 1) then OPTIONS.baseOpacity = OPTIONS.baseOpacity - 0.02 end
	if (string.find(command, "-selectedunits_baseopacity") == 1) then OPTIONS.baseOpacity = OPTIONS.baseOpacity + 0.02 end
end

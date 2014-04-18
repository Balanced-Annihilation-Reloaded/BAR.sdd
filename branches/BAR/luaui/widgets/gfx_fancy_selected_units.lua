function widget:GetInfo()
   return {
      name      = "Fancy Selected Units",
      desc      = "(took 'UnitShapes' widget as a base)",
      author    = "Floris",
      date      = "04.04.2014",
      license   = "GNU GPL, v2 or later",
      layer     = 2,
      enabled   = true
   }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- NOTE:  STILL IN DEVELOPMENT!

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function SetupCommandColors(state)
	local alpha = state and 1 or 0
	--Spring.LoadCmdColorsConfig('move  0.5 1.0 0.5 ' .. alpha)
	Spring.LoadCmdColorsConfig('unitBox  0 1 0 ' .. alpha)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


local clearquad
local shapes = {}

local gaiaTeamID					= Spring.GetGaiaTeamID()

local rad_con						= 180 / math.pi

local glCallList					= gl.CallList
local glDrawListAtUnit				= gl.DrawListAtUnit

local UNITCONF						= {}

local currentRotationAngle			= 0
local currentRotationAngleOpposite	= 0
local previousOsClock				= os.clock()

local animationMultiplier			= 1
local animationMultiplierInner		= 1
local animationMultiplierAdd		= true

local selectedUnitsData				= {}
selectedUnitsData['unit']			= {}
selectedUnitsData['team']			= {}
selectedUnitsData['totalSelectedUnits']	= 0

local teamList = Spring.GetTeamList()
local numberOfTeams = #teamList

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local OPTIONS = {
	-- Quality settings
	showNoOverlap					= true,		-- set true for no line overlapping for solid lines
	showBase						= true,
	showFirstLine					= true,
	showSecondLine					= true,
	showExtraComLine				= true,		-- extra circle lines for the commander unit
	showExtraBuildingWeaponLine		= true,
	
	circlePieces					= 38,		-- (1 or higher)
	circlePieceDetail				= 1,		-- smoothness of each piece (1 or higher)
	circleSpaceUsage				= 0.75,		-- 1 = whole circle space gets filled
	circleInnerOffset				= 0.45,
	
	circleDivs						= 32,		-- how precise circle?  (the inner circle that cuts out overlapping spotters)
	
	
	-- size
	scaleMultiplier					= 1.04,
	innersize						= 1.7,
	selectinner						= 1.65,
	outersize						= 1.8,
	scalefaktor						= 2.9,
	rectangleFactor					= 3.3,
	
	-- opacity
	spotterOpacity					= 1,			-- 0 is opaque
	baseOpacity						= 0.8,		-- 0 is opaque
	firstLineOpacity				= 0.1,
	secondLineOpacity				= 0.5,
	
	-- color
	useDefaultColor					= true,
	defaultOwnColor					= {1,1,1},
	defaultOthersColor				= {0.5,1,0.5},
	useOriginalBaseColor			= true,			-- if using the default color, still useplayers color for the base-spotter?
	
	-- animation
	rotationSpeed					= 0.08,
	selectionStartAnimation			= true,
	selectionStartAnimationTime		= 0.025,
	selectionStartAnimationScale	= 0.8,
	-- selectionStartAnimationScale	= 1.17,
	selectionStartAnimationOpacity	= 0.11,	-- starts with this addition opacity, over makes it overflow a bit at the end of the fadein
	selectionEndAnimation			= true,
	selectionEndAnimationTime		= 0.05,
	selectionEndAnimationScale		= 0.9,
	-- selectionEndAnimationScale	= 1.17,
	animationSpeed					= 0.0007,
	animateSpotterSize				= true,
	animateInnerSpotterSize			= true,
	maxAnimationMultiplier			= 1.015,
	minAnimationMultiplier			= 0.99
}

------------------------------------------------------------------------------------
------------------------------------------------------------------------------------



local function updateSelectedUnitsData()

	-- remove old deselected units from the selectedUnitsData array
	currentClock = os.clock()
	local maxDeselectedTime = currentClock - OPTIONS.selectionEndAnimationTime
	local maxSelectTime = currentClock - OPTIONS.selectionStartAnimationTime
	for unitID in pairs(selectedUnitsData['unit']) do
		if not Spring.IsUnitSelected(unitID) then
			selectedUnitsData['unit'][unitID]['selected'] = false 
			selectedUnitsData['unit'][unitID]['new'] = false
			if selectedUnitsData['unit'][unitID]['clock'] < maxDeselectedTime then
				selectedUnitsData['unit'][unitID] = nil
			end
		end
	end
	
	-- add selected units
	selectedUnitsData['totalSelectedUnits'] = Spring.GetSelectedUnitsCount()
	if selectedUnitsData['totalSelectedUnits'] > 0 then
		local units = Spring.GetSelectedUnitsSorted()
		for uDID,_ in pairs(units) do
			if uDID ~= 'n' then --'n' returns table size
				for i=1,#units[uDID] do
					local unitID = units[uDID][i]
					local unit = UNITCONF[uDID]
					if (unit) then
						if not KeyExists(selectedUnitsData['unit'], unitID) then
							selectedUnitsData['unit'][unitID]				= {}
							selectedUnitsData['unit'][unitID]['new']		= currentClock
							selectedUnitsData['unit'][unitID]['selected']	= true
							--selectedUnitsData['unit'][unitID]['visible']	= Spring.IsUnitVisible(unitID, 30, true)
						end
						selectedUnitsData['unit'][unitID]['clock'] = currentClock
						if selectedUnitsData['unit'][unitID]['new']  and  selectedUnitsData['unit'][unitID]['new'] < maxSelectTime then
							selectedUnitsData['unit'][unitID]['new']		= false
						end
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


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


function Round(num, idp)
    local mult = 10^(idp or 0)
    return math.floor(num * mult + 0.5) / mult
end


-- Creating polygons:
local function CreateDisplayLists(callback)
	local displayLists = {}
	
	local zeroColor = {0, 0, 0, 0}
	
	displayLists.select = callback.fading(OPTIONS.outersize, OPTIONS.selectinner)
	displayLists.invertedSelect = callback.fading(OPTIONS.outersize, OPTIONS.selectinner)
	displayLists.inner = callback.solid(zeroColor, OPTIONS.innersize)
	displayLists.large = callback.solid(nil, OPTIONS.selectinner)
	displayLists.kill = callback.solid(nil, OPTIONS.outersize)
	displayLists.shape = callback.fading(OPTIONS.innersize, OPTIONS.selectinner)
	
	return displayLists
end



local function DrawCircleLine(innersize, outersize)
	gl.BeginEnd(GL.QUADS, function()
		local width = OPTIONS.circleSpaceUsage
		local detail = OPTIONS.circlePieceDetail
		
		local radstep = (2.0 * math.pi) / OPTIONS.circlePieces
		for i = 1, OPTIONS.circlePieces do
			for d = 1, detail do
				
				local detailPartWidth = ((width / detail) * d)
				local a1 = ((i+detailPartWidth - (width / detail)) * radstep)
				local a2 = ((i+detailPartWidth) * radstep)
				local a3 = ((i+OPTIONS.circleInnerOffset+detailPartWidth - (width / detail)) * radstep)
				local a4 = ((i+OPTIONS.circleInnerOffset+detailPartWidth) * radstep)
				
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
	if 1 == 2 then
	gl.BeginEnd(GL.TRIANGLE_FAN, function()
		local width = OPTIONS.circleSpaceUsage
		local detail = OPTIONS.circlePieceDetail
		local emptyDetail = Round( (1 - width) * detail)
		local emptyWidth = 1 - width
		if emptyDetail < 1 then emptyDetail = 1 end
		local radstep = (2.0 * math.pi) / OPTIONS.circlePieces
		gl.Vertex(0, 0, 0)
		for i = 1, OPTIONS.circlePieces do
			-- fill in middle parts of drawn lines
			for d = 1, detail do
				detailPartWidth = ((width / detail) * d)
				--a3 = ((i+OPTIONS.circleInnerOffset+detailPartWidth) * radstep)
				a3 = ((i+OPTIONS.circleInnerOffset+detailPartWidth - (width / detail)) * radstep)
				gl.Vertex(math.sin(a3)*size, 0, math.cos(a3)*size)
			end
			-- fill in the middle parts where there isnt a line drawn
			for ed = 1, emptyDetail do
				detailPartWidth = ((emptyWidth / emptyDetail) * ed)
				a3 = ((i+OPTIONS.circleInnerOffset - (emptyWidth / emptyDetail)) * radstep)
				gl.Vertex(math.sin(a3)*size, 0, math.cos(a3)*size)
			end
		end
	end)
	end
	gl.BeginEnd(GL.TRIANGLE_FAN, function()
		local radstep = (2.0 * math.pi) / OPTIONS.circleDivs
		if (color) then
			gl.Color(color)
		end
		gl.Vertex(0, 0, 0)
		for i = 0, OPTIONS.circleDivs do
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
	if not WG.allySelUnits then 
		WG.allySelUnits = {} 
	end
	
	CreateCircleLists()
	CreateSquareLists()
	CreateTriangleLists()
	
	SetUnitConf()
	
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
end


function SetUnitConf()
	for udid, unitDef in pairs(UnitDefs) do
		local xsize, zsize = unitDef.xsize, unitDef.zsize
		local scale = OPTIONS.scalefaktor*( xsize^2 + zsize^2 )^0.5
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

function widget:CommandsChanged()
end


local degrot = {}
function widget:GameFrame(frame)

	updateSelectedUnitsData()
	
	if frame%3~=0 then return end
	
	for unitID in pairs(selectedUnitsData['unit']) do
		local dirx, _, dirz = Spring.GetUnitDirection(unitID)
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



function DrawSelectionSpottersPart(type, r,g,b,a,scale, opposite, relativeScaleSchrinking, changeOpacity)

	local camX, camY, camZ = Spring.GetCameraPosition()
	
	for i=1, #teamVisibleSelected do
		local unitID = teamVisibleSelected[i]
		local udid = Spring.GetUnitDefID(unitID)
		local unitUnitDefs = UnitDefs[udid]
		local unit = UNITCONF[udid]
		
		if (unit) then
			local unitPosX, unitPosY, unitPosZ = Spring.GetUnitViewPosition(unitID, true)
			local camHeightDifference = camY - unitPosY
			
			local changedScale = 1
				
			-- check if the unit is deselected
			if OPTIONS.selectionEndAnimation  or  OPTIONS.selectionStartAnimation then
				if changeOpacity then
					gl.Color(r,g,b,a)
				end
				if (OPTIONS.selectionEndAnimation  and  not selectedUnitsData['unit'][unitID]['selected']) then
					changedScale = 1 - (((currentClock - selectedUnitsData['unit'][unitID]['clock']) / OPTIONS.selectionEndAnimationTime)) * (1 - OPTIONS.selectionEndAnimationScale)
					if (changeOpacity) then
						local newAlpha = a + (((currentClock - selectedUnitsData['unit'][unitID]['clock']) / OPTIONS.selectionEndAnimationTime) * (1-a))
						gl.Color(r,g,b,newAlpha)
					end
				-- check if the unit is newly selected
				elseif (OPTIONS.selectionStartAnimation  and selectedUnitsData['unit'][unitID]['new']) then
					changedScale = OPTIONS.selectionStartAnimationScale + (((currentClock - selectedUnitsData['unit'][unitID]['new']) / OPTIONS.selectionStartAnimationTime)) * (1 - OPTIONS.selectionStartAnimationScale)
					if (changeOpacity) then
						local newAlpha = 1 - OPTIONS.selectionStartAnimationOpacity - (((currentClock - selectedUnitsData['unit'][unitID]['new']) / OPTIONS.selectionStartAnimationTime) * (1-a))
						gl.Color(r,g,b,newAlpha)
					end
				end
			end
			local usedRotationAngle = GetUsedRotationAngle(unitID, unitUnitDefs ,opposite)
			if type == 'normal solid'  or  type == 'normal alpha' then
				
				if relativeScaleSchrinking then
					glDrawListAtUnit(unitID, unit.shape.select, false, (unit.xscale*scale*changedScale)-((unit.xscale*changedScale-5)/10), 1.0, (unit.zscale*scale*changedScale)-((unit.zscale*changedScale-5)/10), usedRotationAngle, 0, degrot[unitID], 0)
				else
					glDrawListAtUnit(unitID, unit.shape.select, false, unit.xscale*scale*changedScale, 1.0, unit.zscale*scale*changedScale, usedRotationAngle, 0, degrot[unitID], 0)
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
				
			elseif type == 'coms' then
				
				if (unitUnitDefs.name == 'corcom'  or  unitUnitDefs.name == 'armcom') then
					scale = 1.34 * OPTIONS.scaleMultiplier * animationMultiplier
					usedRotationAngle = GetUsedRotationAngle(unitID, unitUnitDefs)
					gl.Color(r,g,b,0.25)
					glDrawListAtUnit(unitID, unit.shape.select, false, (unit.xscale*scale*changedScale)-((unit.xscale*changedScale-10)/10), 1.0, (unit.zscale*scale*changedScale)-((unit.zscale*changedScale-10)/10), currentRotationAngleOpposite, 0, degrot[unitID], 0)
					scale = 1.54 * OPTIONS.scaleMultiplier * animationMultiplier
					usedRotationAngle = GetUsedRotationAngle(unitID, unitUnitDefs , true)
					gl.Color(r,g,b,0.33)
					glDrawListAtUnit(unitID, unit.shape.large, false, (unit.xscale*scale*changedScale)-((unit.xscale*changedScale-10)/10), 1.0, (unit.zscale*scale*changedScale)-((unit.zscale*changedScale-10)/10), 0, 0, degrot[unitID], 0)
				end
				
			elseif type == 'building with weapon' then
				
				if (unitUnitDefs.isBuilding or unitUnitDefs.isFactory or unitUnitDefs.speed==0) then
					if (#unitUnitDefs.weapons > 0) then
						scale = 1.34 * OPTIONS.scaleMultiplier * animationMultiplier
						usedRotationAngle = GetUsedRotationAngle(unitID, unitUnitDefs)
						gl.Color(r,g,b,0.5)
						glDrawListAtUnit(unitID, unit.shape.select, false, (unit.xscale*scale*changedScale)-((unit.xscale*changedScale-10)/7.5), 1.0, (unit.zscale*scale*changedScale)-((unit.zscale*changedScale-10)/7.5), usedRotationAngle, 0, degrot[unitID], 0)
						scale = 1.38 * OPTIONS.scaleMultiplier * animationMultiplier
						glDrawListAtUnit(unitID, unit.shape.select, false, (unit.xscale*scale*changedScale)-((unit.xscale*changedScale-10)/7.5), 1.0, (unit.zscale*scale*changedScale)-((unit.zscale*changedScale-10)/7.5), usedRotationAngle, 0, degrot[unitID], 0)
					end
				end
				
			elseif type == 'base solid'  or  type == 'base alpha' then
				
				glDrawListAtUnit(unitID, unit.shape.large, false, (unit.xscale*scale*changedScale)-((unit.xscale*changedScale-10)/10), 1.0, (unit.zscale*scale*changedScale)-((unit.zscale*changedScale-10)/10), degrot[unitID], 0, degrot[unitID], 0)
				
			end			
		end
	end	
end



--  Draw selection circle (nly one layer)
function DrawSelectionSpotters(r,g,b,a,scale, opposite, relativeScaleSchrinking)
	
	-- draw normal spotters solid
	local a1 = (OPTIONS.showNoOverlap and 0 or a)
	
	gl.BlendFunc(GL.ONE_MINUS_SRC_ALPHA, GL.SRC_ALPHA)
	gl.Color(r,g,b,a1)
	DrawSelectionSpottersPart('normal solid', r,g,b,a,scale, opposite, relativeScaleSchrinking)
	
	if OPTIONS.showNoOverlap then
		--  Here the spotters are given the alpha level (this step makes sure overlappings dont have different alpha level)
		gl.BlendFunc(GL.ONE, GL.ZERO)
		gl.Color(r,g,b,a)
		DrawSelectionSpottersPart('normal alpha', r,g,b,a,scale, opposite, relativeScaleSchrinking, true)
	end
	
	--  Here the inner of the selected spotters are removed
	gl.BlendFunc(GL.ONE, GL.ZERO)
	gl.Color(r,g,b,1)
	DrawSelectionSpottersPart('solid overlap', r,g,b,a,scale, opposite, relativeScaleSchrinking)
	
	
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
	
	DrawSelectionSpottersPart('alphabuffer1', r,g,b,a,scale, opposite, relativeScaleSchrinking)
	
	DrawSelectionSpottersPart('alphabuffer2', r,g,b,a,scale, opposite, relativeScaleSchrinking)
end

function widget:DrawWorldPreUnit()
	
	local clockDifference = (os.clock() - previousOsClock)
	previousOsClock = os.clock()
	
   --if Spring.IsGUIHidden() then return end
	
	if (selectedUnitsData['totalSelectedUnits'] == 0) then return end
	
	gl.PushAttrib(GL.COLOR_BUFFER_BIT)
	gl.DepthTest(false)
	
	
	local currentGameSpeed, _, paused = Spring.GetGameSpeed()
	if not paused then
		currentRotationAngle = currentRotationAngle + (OPTIONS.rotationSpeed/2)
		if currentRotationAngle > 360 then
		   currentRotationAngle = currentRotationAngle - 360
		end
		local rotationSpeedMultiplier = (clockDifference * 50) * currentGameSpeed
			
		currentRotationAngle = currentRotationAngle + ((OPTIONS.rotationSpeed/2) * rotationSpeedMultiplier)
		
		
		currentRotationAngleOpposite = currentRotationAngleOpposite - OPTIONS.rotationSpeed
		if currentRotationAngleOpposite < -360 then
		   currentRotationAngleOpposite = currentRotationAngleOpposite + 360
		end
		currentGameSpeed, _, paused = Spring.GetGameSpeed()
		
		currentRotationAngleOpposite = currentRotationAngleOpposite - (OPTIONS.rotationSpeed * rotationSpeedMultiplier)
	end
	
	
	-- animate spotter scale 
	if OPTIONS.animateSpotterSize then
		local addedMultiplierValue = OPTIONS.animationSpeed * (clockDifference * 50)
		if (animationMultiplierAdd  and  animationMultiplier < OPTIONS.maxAnimationMultiplier) then
			animationMultiplier = animationMultiplier + addedMultiplierValue
			animationMultiplierInner = animationMultiplierInner - addedMultiplierValue
			if (animationMultiplier > OPTIONS.maxAnimationMultiplier) then
				animationMultiplierAdd = false
			end
		else
			animationMultiplier = animationMultiplier - addedMultiplierValue
			animationMultiplierInner = animationMultiplierInner + addedMultiplierValue
			if (animationMultiplier < OPTIONS.minAnimationMultiplier) then
				animationMultiplierAdd = true
			end
		end
	end
	
	
		-- loop teams
		for teamListIndex=1, numberOfTeams do
			local teamID = teamList[teamListIndex]
			teamVisibleSelected = {}
			if teamID ~= gaiaTeamID then
				selectedUnitsData['team'][teamID] = {}
				for unitID in pairs(selectedUnitsData['unit']) do
					UnitTeamID = Spring.GetUnitTeam(unitID)
					if UnitTeamID == teamID then
						table.insert(teamVisibleSelected, unitID)
						table.insert(selectedUnitsData['team'][teamID], unitID)
					end
				end
			end
			
			if #teamVisibleSelected > 0 then
				local scale = 1
				if OPTIONS.secondLineOpacity then
					r,g,b = OPTIONS.defaultOwnColor[1], OPTIONS.defaultOwnColor[2], OPTIONS.defaultOwnColor[3]
				else
					r,g,b = Spring.GetTeamColor(teamID)
				end
				
				-- To fix Water
				gl.ColorMask(false,false,false,true)
				gl.BlendFunc(GL.ONE, GL.ONE)
				gl.Color(r,g,b,1)
				-- Does not need to be drawn per Unit .. it covers the whole map
				glCallList(clearquad)
				
				
				-- 1st layer
				if OPTIONS.showFirstLine then
					scale = 1.015 * OPTIONS.scaleMultiplier * animationMultiplierInner
					DrawSelectionSpotters(r,g,b,OPTIONS.firstLineOpacity * OPTIONS.spotterOpacity,scale)
				end
				
				
				-- extra 3rd layer (for coms)
				if OPTIONS.showExtraComLine then
					gl.BlendFunc(GL.ONE_MINUS_SRC_ALPHA, GL.SRC_ALPHA)
					DrawSelectionSpottersPart('coms', r,g,b,a,scale)
				end
				
				
				-- extra 3rd layer (for buildings with a weapon)
				if OPTIONS.showExtraBuildingWeaponLine then
					gl.BlendFunc(GL.ONE_MINUS_SRC_ALPHA, GL.SRC_ALPHA)
					DrawSelectionSpottersPart('building with weapon', r,g,b,a,scale)
					
				end
				
				
				-- 2nd layer
				if OPTIONS.showSecondLine then
					scale = 1.17 * OPTIONS.scaleMultiplier * animationMultiplier
					DrawSelectionSpotters(r,g,b,OPTIONS.secondLineOpacity * OPTIONS.spotterOpacity,scale, true, true)
				end
					
					
				-- base layer
				if OPTIONS.showBase then
					if OPTIONS.useDefaultColor  and  OPTIONS.useOriginalBaseColor then
						r,g,b = Spring.GetTeamColor(teamID)
					end
					scale = 1.32 * OPTIONS.scaleMultiplier * animationMultiplier
					if not showSecondLine then
						scale = scale - 0.18
					end
					gl.Blending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)
					gl.Color(r,g,b,0)
					DrawSelectionSpottersPart('base solid', r,g,b,a,scale)
						
					--  Here the inner of the selected spotters are removed
					gl.BlendFunc(GL.ONE, GL.ZERO)
					a = OPTIONS.baseOpacity * OPTIONS.spotterOpacity
					gl.Color(r,g,b,a)
					DrawSelectionSpottersPart('base alpha', r,g,b,a,scale, false, false, true)
				
					--  Really draw the spotters now  (This could be optimised if we could say Draw as much as DST_ALPHA * SRC_ALPHA is)
					-- (without protecting form drawing them twice)
					gl.ColorMask(true,true,true,true)
					gl.BlendFunc(GL.ONE_MINUS_DST_ALPHA, GL.DST_ALPHA)
					gl.Color(r,g,b,1)
				end
				
				-- Does not need to be drawn per Unit anymore
				glCallList(clearquad)
				
				
			end --if #teamVisibleSelected > 0
		end

	
	
	gl.Color(1,1,1,1)
	gl.PopAttrib()
end
--allySelUnits

	


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Config related



function widget:TextCommand(command)
    local mycommand = false
    if (string.find(command, "+unitspotteropacity") == 1) then OPTIONS.spotterOpacity = OPTIONS.spotterOpacity - 0.02 end
    if (string.find(command, "-unitspotteropacity") == 1) then OPTIONS.spotterOpacity = OPTIONS.spotterOpacity + 0.02 end
    
    if (string.find(command, "+unitspotterbaseopacity") == 1) then OPTIONS.baseOpacity = OPTIONS.baseOpacity - 0.02 end
    if (string.find(command, "-unitspotterbaseopacity") == 1) then OPTIONS.baseOpacity = OPTIONS.baseOpacity + 0.02 end
end

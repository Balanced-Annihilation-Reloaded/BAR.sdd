function widget:GetInfo()
   return {
      name      = "Commands FX",
      desc      = "Adds glow-pulses wherever commands are queued. Including mapmarks.",
      author    = "Floris",
      date      = "14.04.2014",
      license   = "GNU GPL, v2 or later",
      layer     = 2,
      enabled   = true,
   }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- NOTE:  STILL IN DEVELOPMENT!

---TODO
-- show lab waypoints separately
-- optionally show non-self cmd's
-- hotkey to show all issued cmd's (like current shift+space)


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local commandHistory = {
	commands				= {},
	coords					= {},	-- this table is used to count cmd´s with same coordinates
	coordRendered			= {},	-- this table is used to skip cmd´s that have the same coordinates
	units					= {},	-- this table stores the newest queued cmd time of each unit.
	mapDrawNicknameTime		= {},	-- this table is used to filter out previous map drawing nicknames if user has drawn something new
	mapEraseNicknameTime	= {}
}

local ownPlayerID				= Spring.GetMyPlayerID()

-- spring vars
local spGetUnitPosition			= Spring.GetUnitPosition
local spGetCameraPosition		= Spring.GetCameraPosition
local spGetUnitCommands			= Spring.GetUnitCommands
local spGetPlayerInfo			= Spring.GetPlayerInfo
local spTraceScreenRay			= Spring.TraceScreenRay
local spLoadCmdColorsConfig		= Spring.LoadCmdColorsConfig
local spGetTeamColor			= Spring.GetTeamColor
local spIsUnitSelected			= Spring.IsUnitSelected
local spGetSelectedUnitsCount	= Spring.GetSelectedUnitsCount
local spGetSelectedUnitsSorted	= Spring.GetSelectedUnitsSorted

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local OPTIONS = {
	
	showMapmarkFx 				= true,
	showMapmarkSpecNames		= true,
	showMapmarkSpecIcons		= true,		-- showMapmarkFx must be true for this to work
	nicknameOpacityMultiplier	= 6,		-- multiplier applied to the given color opacity of the type: 'map_draw'
	scaleWithCamera				= true,
	
	size 						= 28,		-- overall size
	opacity 					= 0.75,		-- overall opacity
	duration					= 1,		-- overall duration
	
	baseParts					= 14,		-- (note that if camera is distant the number of parts will be reduced, up to 6 as minimum)
	ringParts					= 24,		-- (note that if camera is distant the number of parts will be reduced, up to 6 as minimum)
	ringWidth					= 2,
	ringStartSize				= 4,
	ringScale					= 0.75,
	reduceOverlapEffect			= 0.08,		-- when spotters have the same coordinates: reduce the opacity: 1 is no reducing while 0 is no adding
	
	disableEngineLines 			= false,		-- disables default Spring Engine lines (move, patrol, attack, fight)
	drawLines					= true,
	linePartWidth				= 12,
	linePartLength				= 20,
	
	types = {
		leftclick = {
			size			= 0.58,
			duration		= 1,
			baseColor 		= {1.00 ,0.50 ,0.00 ,0.28},
			ringColor		= {1.00 ,0.50 ,0.00 ,0.12}
		},
		rightclick = {
			size			= 0.58,
			duration		= 1,
			baseColor		= {1.00 ,0.75 ,0.00 ,0.25},
			ringColor		= {1.00 ,0.75 ,0.00 ,0.11}
		},
		move = {
			size			= 1,
			duration		= 1,
			baseColor		= {0.00 ,1.00 ,0.00 ,0.25},
			ringColor		= {0.00 ,1.00 ,0.00 ,0.25}
		},
		fight = {
			size			= 1.2,
			duration		= 1,
			baseColor		= {1.00 ,0.00 ,1.00 ,0.25},
			ringColor		= {1.00 ,0.00 ,1.00 ,0.35}
		},
		attack = {
			size			= 1.4,
			duration		= 1,
			baseColor		= {1.00 ,0.00 ,0.00 ,0.30},
			ringColor		= {1.00 ,0.00 ,0.00 ,0.40}
		},
		patrol = {
			size			= 1,
			duration		= 1,
			baseColor		= {0.00 ,0.00 ,1.00 ,0.25},
			ringColor		= {0.00 ,0.00 ,1.00 ,0.25}
		},
		unload = {
			size			= 1,
			duration		= 1,
			baseColor		= {1.00 ,1.00 ,0.00 ,0.30},
			ringColor		= {1.00 ,1.00 ,0.00 ,0.30}
		},
		map_mark = {
			size			= 2.33,
			duration		= 9,
			baseColor		= {1.00 ,1.00 ,1.00 ,0.40},
			ringColor		= {1.00 ,1.00 ,1.00 ,0.75}
		},
		map_draw = {
			size			= 0.63,
			duration		= 1.5,
			baseColor		= {1.00 ,1.00 ,1.00 ,0.15},
			ringColor		= {1.00 ,1.00 ,1.00 ,0.00}
		},
		map_erase = {
			size			= 2.33,
			duration		= 4,
			baseColor		= {1.00 ,1.00 ,1.00 ,0.13},
			ringColor		= {1.00 ,1.00 ,1.00 ,0.00}
		}
	}
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


function Round(num, idp)
    local mult = 10^(idp or 0)
    return math.floor(num * mult + 0.5) / mult
end


local function DrawBaseGlow(parts, size, r,g,b,a)
	gl.Color(r,g,b,a)
	gl.Vertex(0, 0, 0)
	gl.Color(r,g,b,0)
	local radstep = (2.0 * math.pi) / parts
	for i = 0, parts do
		local a1 = (i * radstep)
		gl.Vertex(math.sin(a1)*size, 0, math.cos(a1)*size)
	end
end


local function DrawRingCircle(parts, ringSize, ringInnerSize, ringOuterSize, rRing,gRing,bRing,aRing)
	local radstep = (2.0 * math.pi) / parts
	for i = 1, parts do
		local a1 = (i * radstep)
		local a2 = ((i+1) * radstep)
		
		local a1Sin = math.sin(a1)
		local a2Sin = math.sin(a2)
		
		a1 = math.cos(a1)
		a2 = math.cos(a2)
		
		--(fadefrom)
		gl.Color(rRing,gRing,bRing,0)
		gl.Vertex(a2Sin*ringInnerSize, 0, a2*ringInnerSize)
		gl.Vertex(a1Sin*ringInnerSize, 0, a1*ringInnerSize)
		--(fadeto)
		gl.Color(rRing,gRing,bRing,aRing)
		gl.Vertex(a1Sin*ringSize, 0, a1*ringSize)
		gl.Vertex(a2Sin*ringSize, 0, a2*ringSize)
		
		--(fadefrom)
		gl.Color(rRing,gRing,bRing,aRing)
		gl.Vertex(a1Sin*ringSize, 0, a1*ringSize)
		gl.Vertex(a2Sin*ringSize, 0, a2*ringSize)
		--(fadeto)
		gl.Color(rRing,gRing,bRing,0)
		gl.Vertex(a2Sin*ringOuterSize, 0, a2*ringOuterSize)
		gl.Vertex(a1Sin*ringOuterSize, 0, a1*ringOuterSize)
	end
end


-- still doesnt render a proper line
local function DrawLine(x1,y1,z1, x2,y2,z2, width, partLength)

	local xDifference		= x2 - x1
	local yDifference		= y2 - y1	-- remember.. in spring 'y' is height/depth
	local zDifference		= z2 - z1
	
	local halfWidth			= width / 2
	local thetaInRadians	= math.atan2(zDifference, xDifference)
	local theta				= thetaInRadians * 180 / math.pi
	local perpendicular		= theta + 90;
	if (perpendicular > 360) then
		perpendicular = perpendicular - 360
	elseif (perpendicular < 0) then
		perpendicular = perpendicular + 360
	end
	local perpendicularInRadians = perpendicular * math.pi / 180

	local zOffset = math.sin(perpendicularInRadians) * halfWidth
	local xOffset = math.cos(perpendicularInRadians) * halfWidth
	
	gl.Vertex(0+xOffset, 0, 0+zOffset)
	gl.Vertex(0-zOffset, 0, 0-zOffset)
	
	gl.Vertex((x2-x1)-xOffset, y2-y1, (z2-z1)-zOffset)
	gl.Vertex((x2-x1)+xOffset, y2-y1, (z2-z1)-zOffset)
	
	if 1 == 2 then
		-- draw lines with gaps
		local distance = math.sqrt(xDifference*xDifference + yDifference*yDifference + zDifference*zDifference)
		local parts = Round(distance / partLength)
		local partDistance = distance / parts
		local partSpacing = 0.8
		for i = 1, parts do
			
			
		end
	end
end


local function DrawGroundquad(wx,gy,wz,size)
	gl.TexCoord(0,0)
	gl.Vertex(wx-size,gy+size,wz-size)
	gl.TexCoord(0,1)
	gl.Vertex(wx-size,gy+size,wz+size)
	gl.TexCoord(1,1)
	gl.Vertex(wx+size,gy+size,wz+size)
	gl.TexCoord(1,0)
	gl.Vertex(wx+size,gy+size,wz-size)
end


local function SetupCommandColors(state)
	local alpha = state and 1 or 0
	spLoadCmdColorsConfig('move     0.5  1.0  0.5  ' .. alpha)
	spLoadCmdColorsConfig('patrol   0.3  0.3  1.0  ' .. alpha)
	spLoadCmdColorsConfig('attack   1.0  0.2  0.2  ' .. alpha)
	spLoadCmdColorsConfig('fight    0.5  0.5  1.0  ' .. alpha)
	spLoadCmdColorsConfig('unload   1.0  1.0  0.0  ' .. alpha)
	spLoadCmdColorsConfig('useQueueIcons ' .. alpha)
end


local function AddCommandSpotter(cmdType, x, y, z, osClock, unitID, playerID)
	if not unitID then
		unitID = 0
	end
	if not playerID then
		playerID = false
	end
	local uniqueNumber = unitID..'_'..osClock
	commandHistory.commands[uniqueNumber] = {
		cmdType		= cmdType,
		x			= x,
		y			= y,
		z			= z,
		osClock		= osClock,
		unitID		= unitID,
		playerID	= playerID
	}
	if commandHistory.coords[cmdType..x..y..z] then
		commandHistory.coords[cmdType..x..y..z] = commandHistory.coords[cmdType..x..y..z] + 1
	else
		commandHistory.coords[cmdType..x..y..z] = 1
	end
	commandHistory.units[unitID] = osClock
end


------------------------------------------------------------------------------------
------------------------------------------------------------------------------------

--	Engine Triggers

------------------------------------------------------------------------------------
------------------------------------------------------------------------------------


function widget:Initialize()
	if OPTIONS.disableEngineLines then
		SetupCommandColors(false)
	end
end


function widget:Shutdown()
	if OPTIONS.disableEngineLines then
		SetupCommandColors(true)
	end
end


function widget:MapDrawCmd(playerID, cmdType, x, y, z, a, b, c)
	local osClock = os.clock()
	if OPTIONS.showMapmarkFx then
		if cmdType == 'point' then
			AddCommandSpotter('map_mark', x, y, z, osClock, false, playerID)
		elseif cmdType == 'line' then
			commandHistory.mapDrawNicknameTime[playerID] = osClock
			AddCommandSpotter('map_draw', x, y, z, osClock, false, playerID)
		elseif cmdType == 'erase' then
			commandHistory.mapEraseNicknameTime[playerID] = osClock
			AddCommandSpotter('map_erase', x, y, z, osClock, false, playerID)
		end
	end
end



function widget:MousePress(x, y, button)
	local traceType, tracedScreenRay = spTraceScreenRay(x, y, true)
	if button == 1 and tracedScreenRay  and tracedScreenRay[3] then
		AddCommandSpotter('leftclick', tracedScreenRay[1], tracedScreenRay[2], tracedScreenRay[3], os.clock())
	end
	if button == 3 and tracedScreenRay  and tracedScreenRay[3] then
		AddCommandSpotter('rightclick', tracedScreenRay[1], tracedScreenRay[2], tracedScreenRay[3], os.clock())
	end
end


--for feature:  hotkey to show all issued cmd's (like current shift+space)
--function widget:KeyPress(key, mods, isRepeat)

--end
--function widget:KeyPress(key, mods, isRepeat)

--end


function widget:UnitCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	local cmdType = false
	if spIsUnitSelected(unitID) then
		if type(cmdOptions) == 'table'  and  #cmdOptions >= 3 then
			if cmdID == CMD.MOVE then
				cmdType = 'move'
				
			elseif cmdID == CMD.FIGHT  and   cmdID ~= CMD.DGUN  then
				cmdType = 'fight'
				
			elseif cmdID == CMD.ATTACK  or   cmdID == CMD.DGUN  then
				cmdType = 'attack'
				
			elseif cmdID == CMD.PATROL  then
				cmdType = 'patrol'
				
			elseif cmdID == CMD.UNLOAD_UNIT   or  cmdID == CMD.UNLOAD_UNITS  then
				cmdType = 'unload'
			end
			if cmdType then
				AddCommandSpotter(cmdType, cmdOptions[1], cmdOptions[2], cmdOptions[3], os.clock(), unitID)
			end
		end
	end
end


function widget:DrawWorldPreUnit()
	
	local osClock = os.clock()
	local camX, camY, camZ = spGetCameraPosition()
	gl.Blending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)
	gl.DepthTest(false)
	
	commandHistory.coordRendered = {}
	
	for cmdKey, cmdValue in pairs(commandHistory.commands) do
	
		local clickOsClock	= cmdValue.osClock
		local cmdType		= cmdValue.cmdType
		local unitID		= cmdValue.unitID
		local playerID		= cmdValue.playerID
		local duration		= OPTIONS.types[cmdType].duration * OPTIONS.duration
		
		-- remove when duration has passed
		if osClock - clickOsClock > duration  then
			if commandHistory.coords[cmdType..cmdValue.x..cmdValue.y..cmdValue.z] <= 1 then
				commandHistory.coords[cmdType..cmdValue.x..cmdValue.y..cmdValue.z] = nil
			else
				commandHistory.coords[cmdType..cmdValue.x..cmdValue.y..cmdValue.z] = commandHistory.coords[cmdType..cmdValue.x..cmdValue.y..cmdValue.z] - 1
			end
			commandHistory.commands[cmdKey] = nil
			
		-- remove nicknames when user has drawn something new
		elseif  OPTIONS.showMapmarkSpecNames  and  cmdType == 'map_draw'  and  commandHistory.mapDrawNicknameTime[playerID] ~= nil  and  clickOsClock < commandHistory.mapDrawNicknameTime[playerID] then
			
			commandHistory.commands[cmdKey] = nil
			
		-- draw all
		elseif  OPTIONS.types[cmdType].baseColor[4] > 0  or  OPTIONS.types[cmdType].ringColor[4] > 0  then
			if commandHistory.coordRendered[cmdType..cmdValue.x..cmdValue.y..cmdValue.z] == nil   or   OPTIONS.drawLines then
				local alphaMultiplier = 1 + (OPTIONS.reduceOverlapEffect * (commandHistory.coords[cmdType..cmdValue.x..cmdValue.y..cmdValue.z] - 1))	 -- add a bit to the multiplier for each cmd issued on the same coords
				
				local size	= OPTIONS.size * OPTIONS.types[cmdType].size
				local a		= (1 - ((osClock - clickOsClock) / duration)) * OPTIONS.opacity * alphaMultiplier
				
				local baseColor = OPTIONS.types[cmdType].baseColor
				local ringColor = OPTIONS.types[cmdType].ringColor
				
				-- use player colors
				if  cmdType == 'map_mark'   or   cmdType == 'map_draw'  or  cmdType == 'map_erase'  then
					local _,_,spec,teamID = spGetPlayerInfo(playerID)
					local r,g,b = 1,1,1
					if not spec then
						r,g,b = spGetTeamColor(teamID)
					end
					baseColor = {r,g,b,baseColor[4]}
					ringColor = {r,g,b,ringColor[4]}
				end
				
				local rRing	= ringColor[1]
				local gRing	= ringColor[2]
				local bRing	= ringColor[3]
				local aRing	= a * ringColor[4]
				local r		= baseColor[1]
				local g		= baseColor[2]
				local b		= baseColor[3]
				a			= a * baseColor[4]
					
				local ringSize = OPTIONS.ringStartSize + (size * OPTIONS.ringScale) * ((osClock - clickOsClock) / duration)
				local ringInnerSize = ringSize - OPTIONS.ringWidth
				local ringOuterSize = ringSize + OPTIONS.ringWidth
				
				gl.PushMatrix()
				gl.Translate(cmdValue.x, cmdValue.y, cmdValue.z)
				
				local xDifference = camX - cmdValue.x
				local yDifference = camY - cmdValue.y
				local zDifference = camZ - cmdValue.z
				local camDistance = math.sqrt(xDifference*xDifference + yDifference*yDifference + zDifference*zDifference)
				
				-- set scale   (based on camera distance)
				local scale = 1
				if OPTIONS.scaleWithCamera and camZ then
					scale = 0.82 + camDistance / 7500
					--gl.Scale(scale,scale,scale)
				end
				
				
				if commandHistory.coordRendered[cmdType..cmdValue.x..cmdValue.y..cmdValue.z] == nil then
					-- base glow
					if baseColor[4] > 0 then
						local parts = Round(((OPTIONS.baseParts - (camDistance / 800)) + (size / 20)) * scale)
						if parts < 6 then parts = 6 end
						gl.BeginEnd(GL.TRIANGLE_FAN, DrawBaseGlow, parts, size, r,g,b,a)
					end
					
					-- ring circle:
					if aRing > 0 then
						local parts = Round(((OPTIONS.ringParts - (camDistance / 800)) + (ringSize / 10)) * scale)
						--parts = parts * (ringSize / (size*OPTIONS.ringScale))		-- this reduces parts when ring is little, but introduces temporary gaps when a part is added
						if parts < 6 then parts = 6 end
						gl.BeginEnd(GL.QUADS, DrawRingCircle, parts, ringSize, ringInnerSize, ringOuterSize, rRing,gRing,bRing,aRing)
					end
				end
				
				-- line
				if commandHistory.units[unitID]  and  commandHistory.units[unitID] == clickOsClock then
					local cmdQueue = spGetUnitCommands(unitID)
					if cmdQueue ~= nil then
						
						-- loop queue
						local prevX, prevY, prevZ = spGetUnitPosition(unitID)
						gl.Translate(-cmdValue.x + prevX, -cmdValue.y + prevY, -cmdValue.z + prevZ)		-- minus cmd position   plus unit position
						for i=1, #cmdQueue do
							local lineColor = nil
							if (cmdQueue[i].id == CMD.MOVE) then
								lineColor = OPTIONS.types['move'].baseColor
							elseif (cmdQueue[i].id == CMD.PATROL) then
								lineColor = OPTIONS.types['patrol'].baseColor
							elseif (cmdQueue[i].id == CMD.ATTACK or cmdQueue[i].id == CMD.DGUN) then
								lineColor = OPTIONS.types['attack'].baseColor
							elseif (cmdQueue[i].id == CMD.FIGHT and cmdQueue[i].id ~= CMD.DGUN) then
								lineColor = OPTIONS.types['fight'].baseColor
							elseif (cmdQueue[i].id == CMD.UNLOAD_UNIT  or  cmdQueue[i].id == CMD.UNLOAD_UNITS) then
								lineColor = OPTIONS.types['unload'].baseColor
							end
							if (lineColor and #cmdQueue[i].params == 3) then
							
								gl.Color(lineColor[1],lineColor[2],lineColor[3],a)
								local originX, originY, originZ	= cmdQueue[i].params[1], cmdQueue[i].params[2], cmdQueue[i].params[3]
							
								gl.Translate(-prevX + originX, -prevY + originY, -prevZ + originZ)		-- minus previous cmd position   plus new cmd position
								gl.BeginEnd(GL.QUADS, DrawLine,    originX, originY, originZ,    prevX, prevY, prevZ,    OPTIONS.linePartWidth, OPTIONS.linePartLength)
								prevX, prevY, prevZ = originX, originY, originZ
							end
						end
					end
				end
				
				-- Mapmarks - draw + erase:   nickname / draw icon
				if  playerID  and  playerID ~= ownPlayerID  and  OPTIONS.showMapmarkSpecNames  and   (cmdType == 'map_draw'  or    cmdType == 'map_erase' and  clickOsClock >= commandHistory.mapEraseNicknameTime[playerID]) then
					
					local nickname,_,spec = spGetPlayerInfo(playerID)
					if (spec) then
						gl.Color(r,g,b, a * OPTIONS.nicknameOpacityMultiplier)
						
						if OPTIONS.showMapmarkSpecIcons then
							if cmdType == 'map_draw' then
								gl.Texture('LuaUI/Images/commandsfx/pencil.png')
							else
								gl.Texture('LuaUI/Images/commandsfx/eraser.png')
							end
							local iconSize = 11
							gl.BeginEnd(GL.QUADS,DrawGroundquad,iconSize,-iconSize,-iconSize,iconSize)
							gl.Texture(false)
						end
						
						gl.Billboard()
						gl.Text(nickname, 0, -28, 20, "cn")
						
					end
				end
				
				commandHistory.coordRendered[cmdType..cmdValue.x..cmdValue.y..cmdValue.z] = true
				
				gl.PopMatrix()
			end
		end
	end
	
	gl.Scale(1,1,1)
	gl.Color(1,1,1,1)
end


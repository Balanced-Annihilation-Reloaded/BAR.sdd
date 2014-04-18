function widget:GetInfo()
   return {
      name      = "Commands FX - dev",
      desc      = "Adds glow-pulses wherever commands are queued. Including mapmarks",
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
-- dont change without asking/permission

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local commandHistory			= {}	
local commandHistoryCoords		= {}	-- this table is used to count cmd´s with same coordinates
local commandCoordsRendered		= {}	-- this table is used to skip cmd´s that have the same coordinates
local mapDrawNicknameTime		= {}	-- this table is used to filter out previous map drawing nicknames if user has drawn something new
local mapEraseNicknameTime		= {}	-- 
local ownPlayerID				= Spring.GetMyPlayerID()

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local OPTIONS = {
	showMapmarkFx 				= true,
	showMapmarkSpecNames		= true,
	nicknameOpacityMultiplier	= 6,		-- multiplier applied to the given color opacity of the type: 'map_draw'
	size 						= 28,
	
	--cameraScalingAmount		= 0,		-- 0: is no scaling, 1: fully scale up according to camera distance.
	
	opacity 					= 1,
	leftClickSize 				= 0.63,
	duration					= 0.7,
	baseParts					= 14,		-- (note that if camera is distant the number of parts will be reduced, up to 6 as minimum)
	ringParts					= 24,		-- (note that if camera is distant the number of parts will be reduced, up to 6 as minimum)
	ringWidth					= 2,
	ringStartSize				= 4,
	ringScale					= 0.75,
	reduceOverlapEffect			= 0.08,		-- when spotters have the same coordinates: reduce the opacity: 1 is no reducing while 0 is no adding
	
	drawLine					= false,
	linePartWidth				= 15,
	linePartLength				= 20,
	
	types = {
		leftclick = {
			size			= 0.58,
			baseColor 		= {1.00 ,0.50 ,0.00 ,0.28},
			ringColor		= {1.00 ,0.50 ,0.00 ,0.12}
		},
		rightclick = {
			size			= 0.58,
			baseColor		= {1.00 ,0.75 ,0.00 ,0.25},
			ringColor		= {1.00 ,0.75 ,0.00 ,0.11}
		},
		move = {
			size			= 1,
			baseColor		= {0.00 ,1.00 ,0.00 ,0.25},
			ringColor		= {0.00 ,1.00 ,0.00 ,0.25}
		},
		fight = {
			size			= 1.2,
			baseColor		= {1.00 ,0.00 ,1.00 ,0.25},
			ringColor		= {1.00 ,0.00 ,1.00 ,0.35}
		},
		attack = {
			size			= 1.4,
			baseColor		= {1.00 ,0.00 ,0.00 ,0.30},
			ringColor		= {1.00 ,0.00 ,0.00 ,0.40}
		},
		patrol = {
			size			= 1,
			baseColor		= {0.00 ,0.00 ,1.00 ,0.25},
			ringColor		= {0.00 ,0.00 ,1.00 ,0.25}
		},
		map_mark = {
			size			= 3,
			baseColor		= {1.00 ,1.00 ,1.00 ,0.50},
			ringColor		= {1.00 ,1.00 ,1.00 ,0.70}
		},
		map_draw = {
			size			= 0.63,
			baseColor		= {1.00 ,1.00 ,1.00 ,0.15},
			ringColor		= {1.00 ,1.00 ,1.00 ,0.00}
		},
		map_erase = {
			size			= 2.7,
			baseColor		= {1.00 ,1.00 ,1.00 ,0.12},
			ringColor		= {1.00 ,1.00 ,1.00 ,0.00}
		}
	}
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


local function AddCommandSpotter(cmdType, x, y, z, osClock, unitID, playerID)
	if not unitID then
		unitID = 0
	end
	if not playerID then
		playerID = false
	end
	local uniqueNumber = unitID..'_'..osClock
	commandHistory[uniqueNumber] = {
		cmdType		= cmdType,
		x			= x,
		y			= y,
		z			= z,
		osClock		= osClock,
		unitID		= unitID,
		playerID	= playerID
	}
	if commandHistoryCoords[cmdType..x..y..z] then
		commandHistoryCoords[cmdType..x..y..z] = commandHistoryCoords[cmdType..x..y..z] + 1
	else
		commandHistoryCoords[cmdType..x..y..z] = 1
	end
end


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


local function DrawLine(x1,y1,z1, x2,y2,z2, width, partLength)
	local xDifference		= x2 - x1
	local yDifference		= y2 - y1
	local zDifference		= z2 - z1
	local halfWidth			= width / 2
	local thetaInRadians	= math.atan2(yDifference, xDifference)
	local theta				= thetaInRadians * 180 / math.pi
	local perpendicular		= theta + 90;
	if (perpendicular > 360) then
		perpendicular = perpendicular - 360
	elseif (perpendicular < 0) then
		perpendicular = perpendicular + 360
	end
	local perpendicularInRadians = perpendicular * math.pi / 180

	local yOffset = math.sin(perpendicularInRadians) * halfWidth
	local xOffset = math.cos(perpendicularInRadians) * halfWidth
	
	--Spring.Echo(yOffset .. '   ' .. xOffset)
	
	gl.Vertex(0+xOffset, 0+yOffset, 0)
	gl.Vertex(0-xOffset, 0-yOffset, 0)
	
	gl.Vertex((x2-x1)-xOffset, (y2-y1)-yOffset, z2-z1)
	gl.Vertex((x2-x1)+xOffset, (y2-y1)+yOffset, z2-z1)
	
	
	if 1 == 2 then
		local distance = math.sqrt(xDifference*xDifference + yDifference*yDifference + zDifference*zDifference)
		local parts = Round(distance / partLength)
		local partDistance = distance / parts
		local partSpacing = 0.8
		for i = 1, parts do
			
			
			
		end
	end
end


local function SetupCommandColors(state)
	local alpha = state and 1 or 0
	--Spring.LoadCmdColorsConfig('move  0.5 1.0 0.5 ' .. alpha)
end


------------------------------------------------------------------------------------
------------------------------------------------------------------------------------

--	Engine Triggers

------------------------------------------------------------------------------------
------------------------------------------------------------------------------------


function widget:Initialize()
	SetupCommandColors(false)
end


function widget:Shutdown()
	SetupCommandColors(true)
end


function widget:MapDrawCmd(playerID, cmdType, x, y, z, a, b, c)
	local osClock = os.clock()
	if OPTIONS.showMapmarkFx then
		if cmdType == 'point' then
			AddCommandSpotter('map_mark', x, y, z, osClock, false, playerID)
		elseif cmdType == 'line' then
			mapDrawNicknameTime[playerID] = osClock
			AddCommandSpotter('map_draw', x, y, z, osClock, false, playerID)
		elseif cmdType == 'erase' then
			mapEraseNicknameTime[playerID] = osClock
			AddCommandSpotter('map_erase', x, y, z, osClock, false, playerID)
		end
	end
end

function widget:MousePress(x, y, button)
	local traceType, tracedScreenRay = Spring.TraceScreenRay(x, y, true)
	if button == 1 and tracedScreenRay  and tracedScreenRay[3] then
		AddCommandSpotter('leftclick', tracedScreenRay[1], tracedScreenRay[2], tracedScreenRay[3], os.clock())
	end
	if button == 3 and tracedScreenRay  and tracedScreenRay[3] then
		AddCommandSpotter('rightclick', tracedScreenRay[1], tracedScreenRay[2], tracedScreenRay[3], os.clock())
	end
end


function widget:UnitCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	local cmdType = false
	if type(cmdOptions) == 'table'  and  #cmdOptions >= 3 then
		if cmdID == CMD.MOVE then
			cmdType = 'move'
			
		elseif cmdID == CMD.FIGHT  and   cmdID ~= CMD.DGUN  then
			cmdType = 'fight'
			
		elseif cmdID == CMD.ATTACK  or   cmdID == CMD.DGUN  then
			cmdType = 'attack'
			
		elseif cmdID == CMD.PATROL  then
			cmdType = 'patrol'
		end
		if cmdType then
			AddCommandSpotter(cmdType, cmdOptions[1], cmdOptions[2], cmdOptions[3], os.clock(), unitID)
		end
	end
end



function widget:DrawWorldPreUnit()
	
	local osClock = os.clock()
	local camX, camY, camZ = Spring.GetCameraPosition()
	gl.Blending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)
	gl.DepthTest(false)
	
	commandCoordsRendered = {}
	
	for cmdKey, cmdValue in pairs(commandHistory) do
	
		local clickOsClock	= cmdValue.osClock
		local cmdType		= cmdValue.cmdType
		local unitID		= cmdValue.unitID
		local playerID		= cmdValue.playerID
		
		-- remove when duration has passed
		if osClock - clickOsClock > OPTIONS.duration then
			if commandHistoryCoords[cmdType..cmdValue.x..cmdValue.y..cmdValue.z] <= 1 then
				commandHistoryCoords[cmdType..cmdValue.x..cmdValue.y..cmdValue.z] = nil
			else
				commandHistoryCoords[cmdType..cmdValue.x..cmdValue.y..cmdValue.z] = commandHistoryCoords[cmdType..cmdValue.x..cmdValue.y..cmdValue.z] - 1
			end
			commandHistory[cmdKey] = nil
			
		-- remove nicknames when user has drawn something new
		elseif  OPTIONS.showMapmarkSpecNames  and  cmdType == 'map_draw'  and  mapDrawNicknameTime[playerID] ~= nil  and  clickOsClock < mapDrawNicknameTime[playerID] then
			
			commandHistory[cmdKey] = nil
			
		-- draw all
		elseif  OPTIONS.types[cmdType].baseColor[4] > 0  or  OPTIONS.types[cmdType].ringColor[4] > 0  then
			if commandCoordsRendered[cmdType..cmdValue.x..cmdValue.y..cmdValue.z] == nil then
				commandCoordsRendered[cmdType..cmdValue.x..cmdValue.y..cmdValue.z] = true
				local alphaMultiplier = 1 + (OPTIONS.reduceOverlapEffect * (commandHistoryCoords[cmdType..cmdValue.x..cmdValue.y..cmdValue.z] - 1))	 -- add a bit to the multiplier for each cmd issued on the same coords
				
				local size	= OPTIONS.size * OPTIONS.types[cmdType].size
				local a		= (1 - ((osClock - clickOsClock) / OPTIONS.duration)) * OPTIONS.opacity * alphaMultiplier
				
				local rRing	= OPTIONS.types[cmdType].ringColor[1]
				local gRing	= OPTIONS.types[cmdType].ringColor[2]
				local bRing	= OPTIONS.types[cmdType].ringColor[3]
				local aRing	= a * OPTIONS.types[cmdType].ringColor[4]
				local r		= OPTIONS.types[cmdType].baseColor[1]
				local g		= OPTIONS.types[cmdType].baseColor[2]
				local b		= OPTIONS.types[cmdType].baseColor[3]
				a			= a * OPTIONS.types[cmdType].baseColor[4]
					
				local ringSize = OPTIONS.ringStartSize + (size * OPTIONS.ringScale) * ((osClock - clickOsClock) / OPTIONS.duration)
				local ringInnerSize = ringSize - OPTIONS.ringWidth
				local ringOuterSize = ringSize + OPTIONS.ringWidth
				
				gl.PushMatrix()
				gl.Translate(cmdValue.x, cmdValue.y, cmdValue.z)
				
				-- base glow
				if OPTIONS.types[cmdType].baseColor[4] > 0 then
					local parts = Round(OPTIONS.baseParts - ((camY - cmdValue.y) / 500))
					if parts < 6 then parts = 6 end
					gl.BeginEnd(GL.TRIANGLE_FAN, DrawBaseGlow, parts, size, r,g,b,a)
				end
				
				-- ring circle:
				if aRing > 0 then
					local parts = Round(OPTIONS.ringParts - ((camY - cmdValue.y) / 150))	-- (if camera is distant the number of parts of the ring will be reduced)
					--parts = parts * (ringSize / (size*OPTIONS.ringScale))		-- this reduces parts when ring is little, but introduces temporary gaps when a part is added
					if parts < 6 then parts = 6 end
					gl.BeginEnd(GL.QUADS, DrawRingCircle, parts, ringSize, ringInnerSize, ringOuterSize, rRing,gRing,bRing,aRing)
				end
				
				-- line
				if OPTIONS.drawLine and cmdType == 'move' then
					gl.Color(r,g,b,a)
					local cmdQueue = Spring.GetUnitCommands(unitID)
					if cmdQueue ~= nil then
						if #cmdQueue < 2  and 1 == 2 then		-- should only be unit coords if unit has no queue with cmd-coords
							local originX, originY, originZ = Spring.GetUnitPosition(unitID)
							gl.BeginEnd(GL.QUADS, DrawLine, cmdValue.x, cmdValue.y, cmdValue.z, originX, originY, originZ, OPTIONS.linePartWidth, OPTIONS.linePartLength)
						end
						
						for i=1, #cmdQueue do
							
							if (cmdQueue[i].id == CMD.MOVE) then
								local originX	= cmdQueue[i].params[1]
								local originY	= cmdQueue[i].params[2]
								local originZ	= cmdQueue[i].params[3]
								if i == 1 then
									local prevX, prevY, prevZ = Spring.GetUnitPosition(unitID)
									--gl.Translate(originX, originY, originZ)
									gl.BeginEnd(GL.QUADS, DrawLine, originX, originY, originZ, prevX, prevY, prevZ, OPTIONS.linePartWidth, OPTIONS.linePartLength)
								else
									local prevX		= cmdQueue[i-1].params[1]
									local prevY		= cmdQueue[i-1].params[2]
									local prevZ		= cmdQueue[i-1].params[3]
									if cmdQueue[i-1].id == CMD.MOVE then
										gl.Translate(originX, originY, originZ)
										--gl.BeginEnd(GL.QUADS, DrawLine, originX, originY, originZ, prevX, prevY, prevZ, OPTIONS.linePartWidth, OPTIONS.linePartLength)
									end
								end
							end
						end
					end
				end
				
				-- text
				if  playerID  and  playerID ~= ownPlayerID  and  OPTIONS.showMapmarkSpecNames  and   cmdType == 'map_draw'  or   cmdType == 'map_erase' and  clickOsClock >= mapEraseNicknameTime[playerID] then
					local nickname,_,isSpec = Spring.GetPlayerInfo(playerID)
					if (isSpec) then
						if cmdType == 'map_erase' then
							nickname = 'ERASING:  '..nickname
						end
						gl.Color(r,g,b, a * OPTIONS.nicknameOpacityMultiplier)
						gl.Billboard()
						gl.Text(nickname, 0, -28, 20, "cn")
					end
				end
				gl.PopMatrix()
				
			end
		end
	end
	
	gl.Color(1,1,1,1)
end


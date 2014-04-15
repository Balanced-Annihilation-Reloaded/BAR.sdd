function widget:GetInfo()
   return {
      name      = "Unit Command FX",
      desc      = "Renders a little glow-pulse wherever commands are queued",
      author    = "Floris",
      date      = "14.04.2014",
      license   = "GNU GPL, v2 or later",
      layer     = 2,
      enabled   = true,
   }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local commandHistory			= {}
local commandHistoryCoords		= {}
local commandCoordsRendered		= {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local OPTIONS = {
	size 					= 28,
	opacity 				= 1,
	leftClickSize 			= 0.63,
	duration				= 0.7,
	baseParts				= 14,
	ringParts				= 24,		-- (note that if camera is distant the number of parts of the ring consists will be reduced, up to 6 as minimum)
	ringWidth				= 2,
	ringStartSize			= 4,
	ringScale				= 0.75,
	reduceOverlapEffect		= 0.15,		-- when spotters have the same coordinates: reduce the opacity: 1 is no reducing while 0 is no adding
	types = {
		leftclick = {
			size			= 0.55,
			color 			= {1.00 ,0.50 ,0.00 ,0.28},
			ringColor		= {1.00 ,0.50 ,0.00 ,0.12}
		},
		rightclick = {
			size			= 0.55,
			color 			= {1.00 ,0.75 ,0.00 ,0.25},
			ringColor		= {1.00 ,0.75 ,0.00 ,0.11}
		},
		move = {
			size			= 1,
			color 			= {0.00 ,1.00 ,0.00 ,0.25},
			ringColor		= {0.00 ,1.00 ,0.00 ,0.25}
		},
		fight = {
			size			= 1.2,
			color 			= {1.00 ,0.00 ,1.00 ,0.25},
			ringColor		= {1.00 ,0.00 ,1.00 ,0.35}
		},
		attack = {
			size			= 1.4,
			color 			= {1.00 ,0.00 ,0.00 ,0.30},
			ringColor		= {1.00 ,0.00 ,0.00 ,0.40}
		},
		patrol = {
			size			= 1,
			color 			= {0.00 ,0.00 ,1.00 ,0.25},
			ringColor		= {0.00 ,0.00 ,1.00 ,0.25}
		}
	}
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


local function AddCommandSpotter(cmdType, x, y, z, osClock, unitID)
	if not unitID then
		unitID = 0
	end
	local uniqueNumber = unitID..'_'..osClock
	commandHistory[uniqueNumber] = {
		cmdType		= cmdType,
		x			= x,
		y			= y,
		z			= z,
		osClock		= osClock,
		unitID		= unitID
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
		
		local a1Cos = math.cos(a1)
		local a2Cos = math.cos(a2)
		
		--(fadefrom)
		gl.Color(rRing,gRing,bRing,0)
		gl.Vertex(a2Sin*ringInnerSize, 0, a2Cos*ringInnerSize)
		gl.Vertex(a1Sin*ringInnerSize, 0, a1Cos*ringInnerSize)
		--(fadeto)
		gl.Color(rRing,gRing,bRing,aRing)
		gl.Vertex(a1Sin*ringSize, 0, a1Cos*ringSize)
		gl.Vertex(a2Sin*ringSize, 0, a2Cos*ringSize)
		
		--(fadefrom)
		gl.Color(rRing,gRing,bRing,aRing)
		gl.Vertex(a1Sin*ringSize, 0, a1Cos*ringSize)
		gl.Vertex(a2Sin*ringSize, 0, a2Cos*ringSize)
		--(fadeto)
		gl.Color(rRing,gRing,bRing,0)
		gl.Vertex(a2Sin*ringOuterSize, 0, a2Cos*ringOuterSize)
		gl.Vertex(a1Sin*ringOuterSize, 0, a1Cos*ringOuterSize)
	end
end


------------------------------------------------------------------------------------
------------------------------------------------------------------------------------


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


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


function widget:DrawWorldPreUnit()
	
	local osClock = os.clock()
	local camX, camY, camZ = Spring.GetCameraPosition()
	gl.Blending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)
	gl.DepthTest(false)
	
	commandCoordsRendered = {}
	
	for cmdKey, cmdValue in pairs(commandHistory) do
	
		local clickOsClock	= cmdValue.osClock
		local cmdType		= cmdValue.cmdType
		
		if osClock - clickOsClock > OPTIONS.duration then
			if commandHistoryCoords[cmdType..cmdValue.x..cmdValue.y..cmdValue.z] <= 1 then
				commandHistoryCoords[cmdType..cmdValue.x..cmdValue.y..cmdValue.z] = nil
			else
				commandHistoryCoords[cmdType..cmdValue.x..cmdValue.y..cmdValue.z] = commandHistoryCoords[cmdType..cmdValue.x..cmdValue.y..cmdValue.z] - 1
			end
			commandHistory[cmdKey] = nil		-- remove because its no longer visible
		elseif  OPTIONS.types[cmdType].color[4] > 0  or  OPTIONS.types[cmdType].ringColor[4] > 0  then
			if commandCoordsRendered[cmdType..cmdValue.x..cmdValue.y..cmdValue.z] == nil then
				commandCoordsRendered[cmdType..cmdValue.x..cmdValue.y..cmdValue.z] = true
				local alphaMultiplier = 1
				--local alphaMultiplier = 1 + (commandHistoryCoords[cmdType..cmdValue.x..cmdValue.y..cmdValue.z] - 1) * OPTIONS.reduceOverlapEffect
				
				local size	= OPTIONS.size * OPTIONS.types[cmdType].size
				local a		= (1 - ((osClock - clickOsClock) / OPTIONS.duration)) * OPTIONS.opacity * alphaMultiplier
				
				local rRing	= OPTIONS.types[cmdType].ringColor[1]
				local gRing	= OPTIONS.types[cmdType].ringColor[2]
				local bRing	= OPTIONS.types[cmdType].ringColor[3]
				local aRing	= a * OPTIONS.types[cmdType].ringColor[4]
				local r		= OPTIONS.types[cmdType].color[1]
				local g		= OPTIONS.types[cmdType].color[2]
				local b		= OPTIONS.types[cmdType].color[3]
				a			= a * OPTIONS.types[cmdType].color[4]
					
				local ringSize = OPTIONS.ringStartSize + (size * OPTIONS.ringScale) * ((osClock - clickOsClock) / OPTIONS.duration)
				local ringInnerSize = ringSize - OPTIONS.ringWidth
				local ringOuterSize = ringSize + OPTIONS.ringWidth
				
				gl.PushMatrix()
				gl.Translate(cmdValue.x, cmdValue.y, cmdValue.z)
				
				-- base glow
				if OPTIONS.types[cmdType].color[4] > 0 then
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
				gl.PopMatrix()
			end
		end
	end
	
	gl.Color(1,1,1,1)
end


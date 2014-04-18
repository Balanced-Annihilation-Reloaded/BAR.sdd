--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--	Copyright (C) 2007.
--	Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name	= "Ally Cursors",
		desc	= "Shows the mouse pos of allied players",
		author	= "jK,TheFatController",
		date	= "Apr,2009",
		license	= "GNU GPL, v2 or later",
		layer	= 0,
		enabled	= true,
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Console commands:

-- /allycursorsnames

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- configs

local cursorSize				= 11
local drawNames					= true
local drawNamesCursorSize		= 7
local fontSizePlayer			= 21
local fontSizeSpec				= 17
local sendPacketEvery			= 0.8
local numMousePos				= 2 --//num mouse pos in 1 packet

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local pairs					= pairs

local spGetGroundHeight		= Spring.GetGroundHeight
local spGetPlayerInfo		= Spring.GetPlayerInfo
local spGetTeamColor		= Spring.GetTeamColor
local spIsSphereInView		= Spring.IsSphereInView

local alliedCursorsPos		= {}


local teamColors			= {}
local color,time,wx,wz,lastUpdateDiff,scale,iscale,fscale,gy --keep memory always allocated for these since they are referenced so frequently
local notIdle				= {}

local usedCursorSize		= 12

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


function widget:Initialize()
	widgetHandler:RegisterGlobal('MouseCursorEvent', MouseCursorEvent)
	
	if drawNames then
		usedCursorSize = drawNamesCursorSize
	end
end


function widget:Shutdown()
	widgetHandler:DeregisterGlobal('MouseCursorEvent')
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function CubicInterpolate2(x0,x1,mix)
	local mix2 = mix*mix;
	local mix3 = mix2*mix;

	return x0*(2*mix3-3*mix2+1) + x1*(3*mix2-2*mix3);
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local playerPos = {}
function MouseCursorEvent(playerID,x,z,click)
	local playerPosList = playerPos[playerID] or {}
	playerPosList[#playerPosList+1] = {x=x,z=z,click=click}
	playerPos[playerID] = playerPosList
	if #playerPosList < numMousePos then
		return
	end
	playerPos[playerID] = {}
	
	if alliedCursorsPos[playerID] then
		local acp = alliedCursorsPos[playerID]

		acp[(numMousePos)*2+1]   = acp[1]
		acp[(numMousePos)*2+2]   = acp[2]

		for i=0,numMousePos-1 do
			acp[i*2+1] = playerPosList[i+1].x
			acp[i*2+2] = playerPosList[i+1].z
		end
		
		acp[(numMousePos+1)*2+1] = os.clock()
		acp[(numMousePos+1)*2+2] = playerPosList[#playerPosList].click
	else
		local acp = {}
		alliedCursorsPos[playerID] = acp

		for i=0,numMousePos-1 do
			acp[i*2+1] = playerPosList[i+1].x
			acp[i*2+2] = playerPosList[i+1].z
		end

		acp[(numMousePos)*2+1]   = playerPosList[(numMousePos-2)*2+1].x
		acp[(numMousePos)*2+2]   = playerPosList[(numMousePos-2)*2+1].z

		acp[(numMousePos+1)*2+1] = os.clock()
		acp[(numMousePos+1)*2+2] = playerPosList[#playerPosList].click
		_,_,_,acp[(numMousePos+1)*2+3] = spGetPlayerInfo(playerID)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


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

local function SetTeamColor(teamID,playerID,a)
	color = teamColors[playerID]
	if color then
		gl.Color(color[1],color[2],color[3],color[4]*a)
		return
	end
	
	--make color
	local r, g, b = spGetTeamColor(teamID)
	local _, _, isSpec = spGetPlayerInfo(playerID)
	if isSpec then
		color = {1, 1, 1, 0.6}
	elseif r and g and b then
		color = {r, g, b, 0.75}
	end
	teamColors[playerID] = color
	gl.Color(color)
	return
end


function widget:PlayerChanged(playerID)
	local _, _, isSpec, teamID = spGetPlayerInfo(playerID)
	local r, g, b = spGetTeamColor(teamID)
	local color
	if isSpec then
		color = {1, 1, 1, 0.6}
	elseif r and g and b then
		color = {r, g, b, 0.75}
	end
	teamColors[playerID] = color
end



function widget:DrawWorldPreUnit()
	gl.DepthTest(GL.ALWAYS)
	gl.Texture('LuaUI/Images/AlliedCursors.png')
	gl.PolygonOffset(-7,-10)
	time = os.clock()
	for playerID,data in pairs(alliedCursorsPos) do 
		--local teamID = data[#data]
		name,_,spec,teamID = spGetPlayerInfo(playerID)
		
		wx,wz = data[1],data[2]
		lastUpdatedDiff = time-data[#data-2] + 0.025
		
		if (lastUpdatedDiff<sendPacketEvery) then
			scale  = (1-(lastUpdatedDiff/sendPacketEvery))*numMousePos
			iscale = math.min(math.floor(scale),numMousePos-1)
			fscale = scale-iscale
			wx = CubicInterpolate2(data[iscale*2+1],data[(iscale+1)*2+1],fscale)
			wz = CubicInterpolate2(data[iscale*2+2],data[(iscale+1)*2+2],fscale)
		end
		
		if notIdle[playerID] then
			--draw a cursor
			local gy = spGetGroundHeight(wx,wz)
			if (spIsSphereInView(wx,gy,wz,usedCursorSize)) then
				SetTeamColor(teamID,playerID,1)
				if not drawNames  or  drawNames and not spec then
					if cursorGlow or drawNames then
						gl.Texture('LuaUI/Images/AlliedCursors.png')
						gl.BeginEnd(GL.QUADS,DrawGroundquad,wx,gy,wz,usedCursorSize)
						gl.Texture(false)
					else
						gl.BeginEnd(GL.QUADS,DrawGroundquad,wx,gy,wz,usedCursorSize)
					end
				end
				
				--draw nickname
				if drawNames then
					gl.PushMatrix()
					gl.Translate(wx, gy, wz)
					gl.Billboard()
					if spec then
						gl.Color(1,1,1,0.55)
						gl.Text(name, 0, 0, fontSizeSpec, "cn")
					else
						local verticalOffset = usedCursorSize + 12.5
						local horizontalOffset = usedCursorSize + 2
						-- text shadow
						gl.Color(0,0,0,0.6)
						gl.Text(name, horizontalOffset-(fontSizePlayer/45), verticalOffset-(fontSizePlayer/38), fontSizePlayer, "n")
						gl.Text(name, horizontalOffset+(fontSizePlayer/45), verticalOffset-(fontSizePlayer/38), fontSizePlayer, "n")
						-- text
						gl.Color(teamColors[playerID][1],teamColors[playerID][2],teamColors[playerID][3],0.72)
						gl.Text(name, horizontalOffset, verticalOffset, fontSizePlayer, "n")
					end
					gl.PopMatrix()
				end
			end
		else
			--mark a player as notIdle as soon as they move (and keep them always set notIdle after this)
			if (n~=0) and wx and wz and wz_old and wz_old and(math.abs(wx_old-wx)>=1 or math.abs(wz_old-wz)>=1) then --math.abs is needed because of floating point used in interpolation
				notIdle[playerID] = true
				wx_old = nil
				wz_old = nil
			else
				wx_old = wx
				wz_old = wz
			end
		end
	end

	gl.PolygonOffset(false)
	gl.Texture(false)
	gl.DepthTest(false)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- (console) commands
function widget:TextCommand(command)
    if (string.find(command, "allycursors_names") == 1  and  string.len(command) == 17) then drawNames = not drawNames end
    
	if drawNames then
		usedCursorSize = drawNamesCursorSize
	end
end

-- save data
function widget:GetConfigData(data)
    savedTable = {}
    savedTable.drawNames  = drawNames
    return savedTable
end

-- restore data
function widget:SetConfigData(data)
    if data.drawNames ~= nil   then  drawNames   = data.drawNames end
	
	if drawNames then
		usedCursorSize = drawNamesCursorSize
	end
end

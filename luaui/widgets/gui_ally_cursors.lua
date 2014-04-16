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
		desc	= "Shows the mouse pos of allied players and spectators",
		author	= "Floris,jK,TheFatController",
		date	= "3,Feb,2014",
		license	= "GNU GPL, v2 or later",
		layer	= 0,
		enabled	= true,
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Console commands:

-- allycursorsspecname
-- allycursorsplayername

-- allycursorsfontshadows
-- allycursorscursorglow

-- +allycursorsspecfontsize       and  -allycursorsspecfontsize
-- +allycursorsspecfontopacity    and  -allycursorsspecfontopacity
-- +allycursorsplayerfontsize     and  -allycursorsplayerfontsize
-- +allycursorsplayerfontopacity  and  -allycursorsplayerfontopacity

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


-- configs
local showTweakUiOptions	= false		-- (everything stays configurable via console commands aswell)

local sendPacketEvery		= 0.6
local numMousePos			= 2 --//num mouse pos in 1 packet
local numTrails				= 2 --//must be >= 1

local showSpectatorName     = true
local showPlayerName        = true

local cursorSize			= 7.5
local cursorGlow			= true
local cursorGlowOpacity		= 0.09
local cursorGlowSize		= 2.33		-- (1 is same size as the cursor= not visible)

local fontShadows			= true		-- will draw 2 additional names, but then in black with an opacity and a position offset
local fontSizePlayer        = 20
local fontOpacityPlayer     = 0.65
local fontSizeSpec          = 16
local fontOpacitySpec       = 0.40

-- tweak ui
local buttonsize					  = 18
local rowgap						  = 6
local leftmargin					  = 20
local buttontab						  = 200
local vsx, vsy 						  = gl.GetViewSizes()
local tweakUiWidth, tweakUiHeight	  = 240, 215
local tweakUiPosX, tweakUiPosY		  = 500, 550

-- images
local optContrast			          = "LuaUI/Images/allycursors/contrast.png"
local optFontSize			          = "LuaUI/Images/allycursors/fontsize.png"
local optCheckBoxOn			          = "LuaUI/Images/allycursors/chkBoxOn.png"
local optCheckBoxOff			      = "LuaUI/Images/allycursors/chkBoxOff.png"
local allyCursors      			      = {"LuaUI/Images/allycursors/allycursor-dot.png", "LuaUI/Images/allycursors/allycursor.png"}
local currentCursor					  = 1

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local Button				= {}
local Panel					= {}
local alliedCursorsPos      = {}


function widget:Initialize()
	widgetHandler:RegisterGlobal('MouseCursorEvent', MouseCursorEvent)

    Button["showSpectatorName"]     = {}
    Button["fontSizeSpec"]          = {}
    Button["fontOpacitySpec"]       = {}
    Button["showPlayerName"]        = {}
    Button["fontSizePlayer"]        = {}
    Button["fontOpacityPlayer"]     = {}
	Panel["main"]				    = {}
	InitButtons()
end


function widget:Shutdown()
	widgetHandler:DeregisterGlobal('MouseCursorEvent')
end


function widget:GetConfigData(data)
    savedTable = {}
    savedTable.showSpectatorName  = showSpectatorName
    savedTable.showPlayerName     = showPlayerName
    savedTable.fontShadows  	  = fontShadows
    savedTable.cursorGlow     	  = cursorGlow
    savedTable.currentCursor      = currentCursor
    savedTable.useTeamColor       = useTeamColor
    savedTable.fontSizePlayer     = fontSizePlayer
    savedTable.fontOpacityPlayer  = fontOpacityPlayer
    savedTable.fontSizeSpec       = fontSizeSpec
    savedTable.fontOpacitySpec    = fontOpacitySpec
    return savedTable
end

function widget:SetConfigData(data)
    if data.showSpectatorName ~= nil   then  showSpectatorName   = data.showSpectatorName end
    if data.showPlayerName ~= nil      then  showPlayerName      = data.showPlayerName end
    if data.fontShadows ~= nil         then  fontShadows         = data.fontShadows end
    if data.cursorGlow ~= nil          then  cursorGlow          = data.cursorGlow end
    if data.currentCursor ~= nil       then  currentCursor       = data.currentCursor end
    if data.useTeamColor ~= nil        then  useTeamColor        = data.useTeamColor end
    fontSizePlayer        = data.fontSizePlayer     or fontSizePlayer
    fontOpacityPlayer     = data.fontOpacityPlayer  or fontOpacityPlayer
    fontSizeSpec          = data.fontSizeSpec       or fontSizeSpec
    fontOpacitySpec       = data.fontOpacitySpec    or fontOpacitySpec
    if (currentCursor > #allyCursors) then
		currentCursor = 1
	end
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
		_,_,_,acp[(numMousePos+1)*2+3] = Spring.GetPlayerInfo(playerID)
	end
end

--------------------------------------------------------------------------------


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


local function DrawGroundquad(wx,gy,wz)
	gl.TexCoord(0,0)
	gl.Vertex(wx-cursorSize,gy+cursorSize,wz-cursorSize)
	gl.TexCoord(0,1)
	gl.Vertex(wx-cursorSize,gy+cursorSize,wz+cursorSize)
	gl.TexCoord(1,1)
	gl.Vertex(wx+cursorSize,gy+cursorSize,wz+cursorSize)
	gl.TexCoord(1,0)
	gl.Vertex(wx+cursorSize,gy+cursorSize,wz-cursorSize)
end


local function ToggleCursorType()
	if currentCursor < #allyCursors then
		currentCursor = currentCursor + 1
	else
		currentCursor = 1
	end
	
end


local teamColors = {}
local notIdle = {}
local time,wx,wz,lastUpdateDiff,scale,iscale,fscale,gy --keep memory always allocated for these since they are referenced so frequently

local function SetTeamColor(teamID,playerID,a)
	local color = teamColors[playerID]
	if color then
		gl.Color(color[1],color[2],color[3],color[4]*a/numTrails)
		return
	end
	
	--make color
	local r, g, b = Spring.GetTeamColor(teamID)
	local _, _, isSpec = Spring.GetPlayerInfo(playerID)
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
	local _, _, isSpec, teamID = Spring.GetPlayerInfo(playerID)
	local r, g, b = Spring.GetTeamColor(teamID)
	local color
	if isSpec then
		color = {1, 1, 1, 0.6}
	elseif r and g and b then
		color = {r, g, b, 0.75}
	end
	teamColors[playerID] = color
end



function widget:DrawWorldPreUnit()
    if Spring.IsGUIHidden() then return end
	gl.DepthTest(GL.ALWAYS)
    gl.Blending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)
	gl.PolygonOffset(-7,-10)
	time = os.clock()
    --gl.BeginText
	for playerID,data in pairs(alliedCursorsPos) do 
		teamID = data[#data]
		for n=0,numTrails do
			local wx,wz = data[1],data[2]
			local lastUpdatedDiff = time-data[#data-2] + 0.025 * n
			
			if (lastUpdatedDiff<sendPacketEvery) then
				local scale  = (1-(lastUpdatedDiff/sendPacketEvery))*numMousePos
				local iscale = math.min(math.floor(scale),numMousePos-1)
				local fscale = scale-iscale
				wx = CubicInterpolate2(data[iscale*2+1],data[(iscale+1)*2+1],fscale)
				wz = CubicInterpolate2(data[iscale*2+2],data[(iscale+1)*2+2],fscale)
			end
			
			if notIdle[playerID] then

				local gy = Spring.GetGroundHeight(wx,wz)
				if (Spring.IsSphereInView(wx,gy,wz,cursorSize)) then
                    local name,_,spec,teamID = Spring.GetPlayerInfo(playerID)
                    SetTeamColor(teamID,playerID,n)
                    local r, g, b = Spring.GetTeamColor(teamID)
                    if not spec  and not showPlayerName    or    spec  and  not showSpectatorName  then
						
							
                        --draw cursor
                        if n == 0 then gl.Texture(allyCursor[1]) end
						gl.Translate(0,0,0)
                        gl.BeginEnd(GL.QUADS,DrawGroundquad,wx,gy,wz)
                    else

                        if not spec then
						
							-- draw cursor glow
							if cursorGlow  and  n == 0 then
								gl.Texture(false)
								gl.PushMatrix()
								gl.Translate(wx, gy, wz)
								gl.BeginEnd(GL.TRIANGLE_FAN, DrawBaseGlow, 6, cursorSize * cursorGlowSize , r,g,b,cursorGlowOpacity)
								gl.PopMatrix()
							end
							if n == 0 then 
								gl.Texture(allyCursors[currentCursor])
							end
							gl.BeginEnd(GL.QUADS,DrawGroundquad,wx,gy,wz)
                            
                        end

                        if n == numTrails then
							
                            --draw nickname
                            gl.PushMatrix()
                            gl.Translate(wx, gy, wz)
                            gl.Billboard()
                            if spec then
                                gl.Color(1,1,1,fontOpacitySpec)
                                gl.Text(name, 0, 0, fontSizeSpec, "cn")
                            else
                                local verticalOffset = cursorSize + 12.5
                                local horizontalOffset = cursorSize + 2
                                if fontShadows then
									gl.Color(0,0,0,fontOpacityPlayer*0.7)
									gl.Text(name, horizontalOffset-(fontSizePlayer/50), verticalOffset-(fontSizePlayer/42), fontSizePlayer, "n")
									gl.Text(name, horizontalOffset+(fontSizePlayer/50), verticalOffset-(fontSizePlayer/42), fontSizePlayer, "n")
								end
                                gl.Color(r,g,b,fontOpacityPlayer)
                                gl.Text(name, horizontalOffset, verticalOffset, fontSizePlayer, "n")
                            end
                            gl.PopMatrix()
                        end
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
	end
    --gl.EndText
	gl.PolygonOffset(false)
	gl.Texture(false)
	gl.DepthTest(false)
end


function widget:TextCommand(command)
    local mycommand = false
    if (string.find(command, "allycursorsspecname") == 1  and  string.len(command) == 19) then showSpectatorName = not showSpectatorName end

    if (string.find(command, "allycursorsplayername") == 1  and  string.len(command) == 21) then showPlayerName = not showPlayerName end
    
    if (string.find(command, "allycursorscursorglow") == 1  and  string.len(command) == 21) then cursorGlow = not cursorGlow end
    
    if (string.find(command, "allycursorsfontshadows") == 1  and  string.len(command) == 22) then fontShadows = not fontShadows end
    
    if (string.find(command, "allycursorscursortype") == 1  and  string.len(command) == 21) then ToggleCursorType() end

    if (string.find(command, "+allycursorsspecfontsize") == 1) then fontSizeSpec = fontSizeSpec + 1.5 end
    if (string.find(command, "-allycursorsspecfontsize") == 1) then fontSizeSpec = fontSizeSpec - 1.5 end

    if (string.find(command, "+allycursorsspecfontopacity") == 1) then fontOpacitySpec = fontOpacitySpec + 0.05 end
    if (string.find(command, "-allycursorsspecfontopacity") == 1) then fontOpacitySpec = fontOpacitySpec - 0.05 end

    if (string.find(command, "+allycursorsplayerfontsize") == 1) then fontSizePlayer = fontSizePlayer + 1.5 end
    if (string.find(command, "-allycursorsplayerfontsize") == 1) then fontSizePlayer = fontSizePlayer - 1.5 end

    if (string.find(command, "+allycursorsplayerfontopacity") == 1) then fontOpacityPlayer = fontOpacityPlayer + 0.05 end
    if (string.find(command, "-allycursorsplayerfontopacity") == 1) then fontOpacityPlayer = fontOpacityPlayer - 0.05 end

    if fontOpacitySpec > 1 then fontOpacitySpec = 1 end if fontOpacitySpec < 0.15 then fontOpacitySpec = 0.15 end
    if fontOpacityPlayer > 1 then fontOpacityPlayer = 1 end if fontOpacityPlayer < 0.15 then fontOpacityPlayer = 0.15 end
    if fontSizeSpec > 60 then fontSizeSpec = 60 end if fontSizeSpec < 10 then fontSizeSpec = 10 end
    if fontSizePlayer > 60 then fontSizePlayer = 60 end if fontSizePlayer < 10 then fontSizePlayer = 10 end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------



function InitButtons()
	Button["showSpectatorName"]["x1"]		= tweakUiPosX + buttontab
	Button["showSpectatorName"]["x2"]  		= Button["showSpectatorName"]["x1"] + buttonsize
	Button["showSpectatorName"]["y1"]  		= tweakUiPosY + tweakUiHeight - 70
	Button["showSpectatorName"]["y2"]  		= Button["showSpectatorName"]["y1"] +  buttonsize
	Button["showSpectatorName"]["above"] 	= false
	Button["showSpectatorName"]["click"]	= showSpectatorName

	Button["fontSizeSpec"]["x1"]		    = tweakUiPosX + buttontab
	Button["fontSizeSpec"]["x2"]  	        = Button["fontSizeSpec"]["x1"] + buttonsize
	Button["fontSizeSpec"]["y1"]            = Button["showSpectatorName"]["y1"] - rowgap - buttonsize
	Button["fontSizeSpec"]["y2"] 	        = Button["fontSizeSpec"]["y1"] + buttonsize
	Button["fontSizeSpec"]["above"] 	    = false
	Button["fontSizeSpec"]["click"]	        = false

	Button["fontOpacitySpec"]["x1"]		    = tweakUiPosX + buttontab
	Button["fontOpacitySpec"]["x2"]  		= Button["fontOpacitySpec"]["x1"] + buttonsize
	Button["fontOpacitySpec"]["y1"]     	= Button["fontSizeSpec"]["y1"] - rowgap - buttonsize
	Button["fontOpacitySpec"]["y2"] 		= Button["fontOpacitySpec"]["y1"] + buttonsize
	Button["fontOpacitySpec"]["above"] 	    = false
	Button["fontOpacitySpec"]["click"]	    = false

	Button["showPlayerName"]["x1"]			= tweakUiPosX + buttontab
	Button["showPlayerName"]["x2"]  		= Button["showPlayerName"]["x1"] + buttonsize
	Button["showPlayerName"]["y1"]      	= Button["fontOpacitySpec"]["y1"] - rowgap - buttonsize - 10
	Button["showPlayerName"]["y2"] 			= Button["showPlayerName"]["y1"] + buttonsize
	Button["showPlayerName"]["above"] 		= false
	Button["showPlayerName"]["click"]		= showPlayerName

	Button["fontSizePlayer"]["x1"]		    = tweakUiPosX + buttontab
	Button["fontSizePlayer"]["x2"]  	    = Button["fontSizePlayer"]["x1"] + buttonsize
	Button["fontSizePlayer"]["y1"]          = Button["showPlayerName"]["y1"] - rowgap - buttonsize
	Button["fontSizePlayer"]["y2"] 	        = Button["fontSizePlayer"]["y1"] + buttonsize
	Button["fontSizePlayer"]["above"] 	    = false
	Button["fontSizePlayer"]["click"]	    = false

	Button["fontOpacityPlayer"]["x1"]		= tweakUiPosX + buttontab
	Button["fontOpacityPlayer"]["x2"]  		= Button["fontOpacityPlayer"]["x1"] + buttonsize
	Button["fontOpacityPlayer"]["y1"]     	= Button["fontSizePlayer"]["y1"] - rowgap - buttonsize
	Button["fontOpacityPlayer"]["y2"] 		= Button["fontOpacityPlayer"]["y1"] + buttonsize
	Button["fontOpacityPlayer"]["above"] 	= false
	Button["fontOpacityPlayer"]["click"]	= false

	Panel["main"]["x1"]				= tweakUiPosX
	Panel["main"]["x2"]				= tweakUiPosX + tweakUiWidth
	Panel["main"]["y1"]				= tweakUiPosY
	Panel["main"]["y2"]				= tweakUiPosY + tweakUiHeight
end


function widget:PlayerChanged()
    if Spring.GetSpectatingState()  and  renderAllTeamsAsSpec then
        skipOwnAllyTeam = false
       -- callfunction = CreateEnemyspotterGl()
    end
end


local function IsOnButton(x, y, BLcornerX, BLcornerY,TRcornerX,TRcornerY)
	if BLcornerX == nil then return false end
	-- check if the mouse is in a rectangle

	return x >= BLcornerX and x <= TRcornerX
	                      and y >= BLcornerY
	                      and y <= TRcornerY
end

function widget:DrawScreen()      -- needed to even draw the tweak ui

end



local function drawOptions()

    gl.Texture(false)       -- because other widgets might be sloppy

	--background panel
	gl.Color(0,0,0,0.5)
	gl.Rect(Panel["main"]["x1"],Panel["main"]["y1"], Panel["main"]["x2"], Panel["main"]["y2"])

	--border
	gl.Color(0,0,0,1)
	gl.Rect(Panel["main"]["x1"]-1,Panel["main"]["y1"], Panel["main"]["x1"], Panel["main"]["y2"])
	gl.Rect(Panel["main"]["x2"],Panel["main"]["y1"], Panel["main"]["x2"]+1, Panel["main"]["y2"])
	gl.Rect(Panel["main"]["x1"],Panel["main"]["y1"]-1, Panel["main"]["x2"], Panel["main"]["y1"])
	gl.Rect(Panel["main"]["x1"],Panel["main"]["y2"], Panel["main"]["x2"], Panel["main"]["y2"]+1)

	-- Heading
	gl.Color(1,1,1,1)
	gl.Text("Ally-cursors", Panel["main"]["x1"] + leftmargin, Panel["main"]["y2"] - 30,15,'sd')

	-- Spec names option
	if Button["showSpectatorName"]["mouse"] then
		gl.Color(1,1,1,1)
	else
		gl.Color(0.6,0.6,0.6,1)
	end

	gl.Text("Show spectator names:", tweakUiPosX+leftmargin, Button["showSpectatorName"]["y1"],12,'sd')

	if Button["showSpectatorName"]["click"] then
		gl.Texture(optCheckBoxOn)
	else
		gl.Texture(optCheckBoxOff)
	end
	gl.TexRect(Button["showSpectatorName"]["x1"],Button["showSpectatorName"]["y1"],Button["showSpectatorName"]["x2"],Button["showSpectatorName"]["y2"])

	-- Spec font size option
	if Button["fontSizeSpec"]["mouse"] then
		gl.Color(1,1,1,1)
	else
		gl.Color(0.6,0.6,0.6,1)
	end

	gl.Text("Spectator font size:", tweakUiPosX+leftmargin, Button["fontSizeSpec"]["y1"],12,'sd')
	gl.Texture(optFontSize)
	gl.TexRect(Button["fontSizeSpec"]["x1"],Button["fontSizeSpec"]["y1"],Button["fontSizeSpec"]["x2"],Button["fontSizeSpec"]["y2"])

	-- Spec font opacity option
	if Button["fontOpacitySpec"]["mouse"] then
		gl.Color(1,1,1,1)
	else
		gl.Color(0.6,0.6,0.6,1)
	end

	gl.Text("Spectator font opacity:", tweakUiPosX+leftmargin, Button["fontOpacitySpec"]["y1"],12,'sd')
	gl.Texture(optContrast)
	gl.TexRect(Button["fontOpacitySpec"]["x1"],Button["fontOpacitySpec"]["y1"],Button["fontOpacitySpec"]["x2"],Button["fontOpacitySpec"]["y2"])

	-- Player names option
	if Button["showPlayerName"]["mouse"] then
		gl.Color(1,1,1,1)
	else
		gl.Color(0.6,0.6,0.6,1)
	end

	gl.Text("Show player names:", tweakUiPosX+leftmargin, Button["showPlayerName"]["y1"],12,'sd')

	if Button["showPlayerName"]["click"] then
		gl.Texture(optCheckBoxOn)
	else
		gl.Texture(optCheckBoxOff)
	end
	gl.TexRect(Button["showPlayerName"]["x1"],Button["showPlayerName"]["y1"],Button["showPlayerName"]["x2"],Button["showPlayerName"]["y2"])

	-- Player font size option
	if Button["fontSizePlayer"]["mouse"] then
		gl.Color(1,1,1,1)
	else
		gl.Color(0.6,0.6,0.6,1)
	end

	gl.Text("Player font size:", tweakUiPosX+leftmargin, Button["fontSizePlayer"]["y1"],12,'sd')
	gl.Texture(optFontSize)
	gl.TexRect(Button["fontSizePlayer"]["x1"],Button["fontSizePlayer"]["y1"],Button["fontSizePlayer"]["x2"],Button["fontSizePlayer"]["y2"])

	-- Player font opacity option
	if Button["fontOpacityPlayer"]["mouse"] then
		gl.Color(1,1,1,1)
	else
		gl.Color(0.6,0.6,0.6,1)
	end

	gl.Text("Player font opacity:", tweakUiPosX+leftmargin, Button["fontOpacityPlayer"]["y1"],12,'sd')
	gl.Texture(optContrast)
	gl.TexRect(Button["fontOpacityPlayer"]["x1"],Button["fontOpacityPlayer"]["y1"],Button["fontOpacityPlayer"]["x2"],Button["fontOpacityPlayer"]["y2"])

	--reset state
	gl.Texture(false)
	gl.Color(1,1,1,1)
end


local function drawIsAbove(x,y)
	if not x or not y then return false end

	for _,button in pairs(Button) do
		button["mouse"] = false
	end

	if IsOnButton(x, y, Button["showSpectatorName"]["x1"],Button["showSpectatorName"]["y1"],Button["showSpectatorName"]["x2"],Button["showSpectatorName"]["y2"]) then
		 Button["showSpectatorName"]["mouse"] = true
		 return true
	elseif IsOnButton(x, y, Button["fontSizeSpec"]["x1"],Button["fontSizeSpec"]["y1"],Button["fontSizeSpec"]["x2"],Button["fontSizeSpec"]["y2"]) then
		 Button["fontSizeSpec"]["mouse"] = true
		 return true
    elseif IsOnButton(x, y, Button["fontOpacitySpec"]["x1"],Button["fontOpacitySpec"]["y1"],Button["fontOpacitySpec"]["x2"],Button["fontOpacitySpec"]["y2"]) then
        Button["fontOpacitySpec"]["mouse"] = true
        return true
	elseif IsOnButton(x, y, Button["showPlayerName"]["x1"],Button["showPlayerName"]["y1"],Button["showPlayerName"]["x2"],Button["showPlayerName"]["y2"]) then
		 Button["showPlayerName"]["mouse"] = true
		 return true
	elseif IsOnButton(x, y, Button["fontSizePlayer"]["x1"],Button["fontSizePlayer"]["y1"],Button["fontSizePlayer"]["x2"],Button["fontSizePlayer"]["y2"]) then
		 Button["fontSizePlayer"]["mouse"] = true
		 return true
	elseif IsOnButton(x, y, Button["fontOpacityPlayer"]["x1"],Button["fontOpacityPlayer"]["y1"],Button["fontOpacityPlayer"]["x2"],Button["fontOpacityPlayer"]["y2"]) then
		 Button["fontOpacityPlayer"]["mouse"] = true
		 return true
	end
	 return false
end

function widget:TweakDrawScreen()
	if showTweakUiOptions then
		drawOptions()
	end
end

function widget:IsAbove(x,y)
	drawIsAbove(x,y)
	--this callin must be present, otherwise function widget:TweakIsAbove(z,y) isn't called. Maybe a bug in widgethandler.
end

function widget:TweakIsAbove(x,y)
	drawIsAbove(x,y)
 end

function widget:TweakMousePress(x, y, button)

	if button == 1 then
		if IsOnButton(x, y, Button["showSpectatorName"]["x1"],Button["showSpectatorName"]["y1"],Button["showSpectatorName"]["x2"],Button["showSpectatorName"]["y2"]) then
			 Spring.SendCommands({"allycursorsspecname"})
			 Button["showSpectatorName"]["click"] = showSpectatorName
			 return true
		elseif IsOnButton(x, y, Button["showPlayerName"]["x1"],Button["showPlayerName"]["y1"],Button["showPlayerName"]["x2"],Button["showPlayerName"]["y2"]) then
			 Spring.SendCommands({"allycursorsplayername"})
			 Button["showPlayerName"]["click"] = showPlayerName
			 return true
		elseif IsOnButton(x, y, Button["fontSizeSpec"]["x1"],Button["fontSizeSpec"]["y1"],Button["fontSizeSpec"]["x1"]+buttonsize/2,Button["fontSizeSpec"]["y2"]) then
			 Spring.SendCommands({"-allycursorsspecfontsize"})
			 return true
		elseif IsOnButton(x, y, (Button["fontSizeSpec"]["x2"]-Button["fontSizeSpec"]["x1"])/2,Button["fontSizeSpec"]["y1"],Button["fontSizeSpec"]["x2"],Button["fontSizeSpec"]["y2"]) then
			 Spring.SendCommands({"+allycursorsspecfontsize"})
			 return true
		elseif IsOnButton(x, y, Button["fontOpacitySpec"]["x1"],Button["fontOpacitySpec"]["y1"],Button["fontOpacitySpec"]["x1"]+buttonsize/2,Button["fontOpacitySpec"]["y2"]) then
			 Spring.SendCommands({"-allycursorsspecfontopacity"})
			 return true
		elseif IsOnButton(x, y, (Button["fontOpacitySpec"]["x2"]-Button["fontOpacitySpec"]["x1"])/2,Button["fontOpacitySpec"]["y1"],Button["fontOpacitySpec"]["x2"],Button["fontOpacitySpec"]["y2"]) then
			 Spring.SendCommands({"+allycursorsspecfontopacity"})
			 return true
		elseif IsOnButton(x, y, Button["fontSizePlayer"]["x1"],Button["fontSizePlayer"]["y1"],Button["fontSizePlayer"]["x1"]+buttonsize/2,Button["fontSizePlayer"]["y2"]) then
			 Spring.SendCommands({"-allycursorsplayerfontsize"})
			 return true
		elseif IsOnButton(x, y, (Button["fontSizePlayer"]["x2"]-Button["fontSizePlayer"]["x1"])/2,Button["fontSizePlayer"]["y1"],Button["fontSizePlayer"]["x2"],Button["fontSizePlayer"]["y2"]) then
			 Spring.SendCommands({"+allycursorsplayerfontsize"})
			 return true
		elseif IsOnButton(x, y, Button["fontOpacityPlayer"]["x1"],Button["fontOpacityPlayer"]["y1"],Button["fontOpacityPlayer"]["x1"]+buttonsize/2,Button["fontOpacityPlayer"]["y2"]) then
			 Spring.SendCommands({"-allycursorsplayerfontopacity"})
			 return true
		elseif IsOnButton(x, y, (Button["fontOpacityPlayer"]["x2"]-Button["fontOpacityPlayer"]["x1"])/2,Button["fontOpacityPlayer"]["y1"],Button["fontOpacityPlayer"]["x2"],Button["fontOpacityPlayer"]["y2"]) then
			 Spring.SendCommands({"+allycursorsplayerfontopacity"})
			 return true
		end
	elseif (button == 2 or button == 3) then
		if IsOnButton(x, y, Panel["main"]["x1"],Panel["main"]["y1"], Panel["main"]["x2"], Panel["main"]["y2"]) then
			  --Dragging
			 return true
		end
	end
	return false
 end

function widget:TweakMouseMove(mx, my, dx, dy, mButton)
     --Dragging
    if mButton == 2 or mButton == 3 then
		 tweakUiPosX = math.max(0, math.min(tweakUiPosX+dx, vsx-tweakUiWidth))	--prevent moving off screen
		 tweakUiPosY = math.max(0, math.min(tweakUiPosY+dy, vsy-tweakUiHeight))
		 InitButtons()
    end
end

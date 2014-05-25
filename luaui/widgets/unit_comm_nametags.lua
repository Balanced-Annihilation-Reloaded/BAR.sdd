local versionNumber = "1.81"

function widget:GetInfo()
  return {
    name      = "Commander Name Tags",
    desc      = versionNumber .." Displays a name tag above each commander.",
    author    = "Evil4Zerggin and CarRepairer",
    date      = "18 April 2008",
    license   = "GNU GPL, v2 or later",
    layer     = -10,
    enabled   = false,  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
-- Console commands
--------------------------------------------------------------------------------

--/comnames_thick
--/comnames_fade
--/comnames_info

--/comnames_rank
--/comnames_trueskill
--/comnames_flag

--------------------------------------------------------------------------------
-- config
--------------------------------------------------------------------------------

local heightOffset			= 28
local infoScale				= 0.77

local fontSize				= 13
local scaleFontSize			= true
local scaleFontAmount		= 133

local useThickLeterring		= true

local showInfo 				= true
local showRank				= true		-- needs showInfo=true
local showTrueskill			= true		-- needs showInfo=true
local showCountry			= true		-- needs showInfo=true

local fadeNames				= false
local fadeStartHeight		= 3200
local fadeEndHeight			= 5200

local fadeIconStartHeight	= 1200		
local fadeIconEndHeight		= 1700		--needs to be smaller than fadeEndHeight

--------------------------------------------------------------------------------
-- speed-ups
--------------------------------------------------------------------------------

local GetUnitTeam         = Spring.GetUnitTeam
local GetTeamInfo         = Spring.GetTeamInfo
local GetPlayerInfo       = Spring.GetPlayerInfo
local GetTeamColor        = Spring.GetTeamColor
local GetUnitViewPosition = Spring.GetUnitViewPosition
local GetVisibleUnits     = Spring.GetVisibleUnits
local GetUnitDefID        = Spring.GetUnitDefID
local GetAllUnits         = Spring.GetAllUnits
local GetUnitHeading      = Spring.GetUnitHeading
local GetCameraPosition   = Spring.GetCameraPosition
local GetUnitPosition     = Spring.GetUnitPosition

local glColor             = gl.Color
local glText              = gl.Text
local glPushMatrix        = gl.PushMatrix
local glPopMatrix         = gl.PopMatrix
local glTranslate         = gl.Translate
local glBillboard         = gl.Billboard
local glDrawFuncAtUnit    = gl.DrawFuncAtUnit
local glBlending          = gl.Blending

local glDepthTest      = gl.DepthTest
local glAlphaTest      = gl.AlphaTest
local glTexture        = gl.Texture
local glTexRect        = gl.TexRect
local glRotate         = gl.Rotate
local GL_GREATER       = GL.GREATER
local GL_SRC_ALPHA				= GL.SRC_ALPHA	
local GL_ONE_MINUS_SRC_ALPHA	= GL.ONE_MINUS_SRC_ALPHA
local glUnitMultMatrix = gl.UnitMultMatrix
local glUnitPieceMultMatrix = gl.UnitPieceMultMatrix
local glScale          = gl.Scale


local usedFontSize	 = fontSize
local font = gl.LoadFont("Fonts/FreeSansBold.otf",50, 6, 15)

--rank pics
local rankImgFolder = "LuaUI/Images/player-ranks/"
local rankImages = {}
rankImages[0] = rankImgFolder.."rank0.png"
rankImages[1] = rankImgFolder.."rank1.png"
rankImages[2] = rankImgFolder.."rank2.png"
rankImages[3] = rankImgFolder.."rank3.png"
rankImages[4] = rankImgFolder.."rank4.png"
rankImages[5] = rankImgFolder.."rank5.png"
rankImages[6] = rankImgFolder.."rank6.png"
rankImages[7] = rankImgFolder.."rank7.png"

--------------------------------------------------------------------------------
-- local variables
--------------------------------------------------------------------------------

--key: unitID
--value: attributes = {name, color, height, currentAttributes, torsoPieceID}
--currentAttributes = {name, color, height}
local comms = {}

--------------------------------------------------------------------------------
-- helper functions
--------------------------------------------------------------------------------

function round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end


function GetSkill(playerID)
	local color = {1,1,1}
	local tskill = ""
	local tskillValue = ""
	local customtable = select(10,GetPlayerInfo(playerID)) -- player custom table
	if customtable.skill ~= nil then 
		local tsMu = customtable.skill
		local tsSigma = customtable.skilluncertainty
		if tsMu then
			tskill = tsMu and tonumber(tsMu:match("%d+%.?%d*")) or 0
			tskill = round(tskill,0)
			tskillValue = tskill
			if string.find(tsMu, ")") then
				tskill = "\255"..string.char(190)..string.char(140)..string.char(140) .. tskill -- ')' means inferred from lobby rank
				color = {190/255, 140/255, 140/255}
			else
			
				-- show privacy mode
				local priv = ""
				if string.find(tsMu, "~") then -- '~' means privacy mode is on
					priv = "\255"..string.char(200)..string.char(200)..string.char(200) .. "*"
				end
				
				--show sigma
				if tsSigma then -- 0 is low sigma, 3 is high sigma
					tsSigma=tonumber(tsSigma)
					local tsRed, tsGreen, tsBlue 
					if tsSigma > 2 then
						tsRed, tsGreen, tsBlue = 190, 130, 130
					elseif tsSigma == 2 then
						tsRed, tsGreen, tsBlue = 140, 140, 140
					elseif tsSigma == 1 then
						tsRed, tsGreen, tsBlue = 195, 195, 195
					elseif tsSigma < 1 then
							tsRed, tsGreen, tsBlue = 250, 250, 250
					end
					tskill = priv .. "\255"..string.char(tsRed)..string.char(tsGreen)..string.char(tsBlue) .. tskill
					color = {tsRed/255, tsGreen/255, tsBlue/255}
				else
					tskill = priv .. "\255"..string.char(195)..string.char(195)..string.char(195) .. tskill --should never happen
					color = {195/255, 195/255, 195/255}
				end
				if priv ~= "" then
					tskillValue = "*"..tskillValue
				end
			end
		else
			tskillValue = "?"
			tskill = "\255"..string.char(160)..string.char(160)..string.char(160) .. "?"
			color = {160/255, 160/255, 160/255}
		end
	end
	return {tskill, tskillValue, color}
end


--gets the name, color, and height of the commander
local function GetCommAttributes(unitID, unitDefID)
  local team = GetUnitTeam(unitID)
  if team == nil then
    return nil
  end
  local _, player = GetTeamInfo(team)
  local name,_,_,_,_,_,_,country,rank = GetPlayerInfo(player)
  local r, g, b, a = GetTeamColor(team)
  local height = UnitDefs[unitDefID].height + heightOffset
  local pm = spGetUnitPieceMap(unitID)
  local pmt = pm["torso"]
  if (pmt == nil) then 
    pmt = pm["chest"]
  end
  return {name or 'Robert Paulson', {r, g, b, a}, height, pmt, rank or '', country or '', GetSkill(player) }
end

local function DrawCommName(unitID, attributes)
       
  local iconHeight = (12.5+usedFontSize/1.6)*(infoScale+((1-infoScale)/2))
  
  glTranslate(0, attributes[3], 0 )
  glBillboard()
   
  font:Begin()
  if useThickLeterring then
    if (attributes[2][1] + attributes[2][2] + attributes[2][3]*0.5) < 1 then
      font:SetTextColor({1,1,1,0.9*attributes[2][4]*attributes[2][4]*attributes[2][4]*attributes[2][4]})
      font:SetOutlineColor(({1,1,1,0.9*attributes[2][4]*attributes[2][4]*attributes[2][4]*attributes[2][4]}))
    else
      font:SetTextColor({0,0,0,0.9*attributes[2][4]*attributes[2][4]*attributes[2][4]*attributes[2][4]})
      font:SetOutlineColor(({0,0,0,0.9*attributes[2][4]*attributes[2][4]*attributes[2][4]*attributes[2][4]}))
    end
    font:Print(attributes[1], -0.6, -0.66, usedFontSize, "con")
    font:Print(attributes[1], 0, -0.66, usedFontSize, "con")
  end
  
  font:SetTextColor(attributes[2])
  
  -- not acurate (enough)   but...   font:SetAutoOutlineColor(true)   doesnt seem to work
  if (attributes[2][1] + attributes[2][2] + attributes[2][3]*0.5) < 1 then
    font:SetOutlineColor(({1,1,1,0.87*attributes[2][4]*attributes[2][4]*attributes[2][4]}))
  else
    font:SetOutlineColor(({0,0,0,0.87*attributes[2][4]*attributes[2][4]*attributes[2][4]}))
  end
  font:Print(attributes[1], -0.3, 0, usedFontSize, "con")
  
  if showInfo and showTrueskill and attributes[8] > 0 and attributes[7] and attributes[7][1] and attributes[7][1] ~= "?" then
    font:SetTextColor({0,0,0,0.55 * attributes[8]})
    font:Print(attributes[7][2], 13.5*infoScale, (iconHeight+1.5)*infoScale, 8*infoScale, "cn")
    
    font:SetTextColor({attributes[7][3][1],attributes[7][3][2],attributes[7][3][3],attributes[8] * attributes[8] * attributes[8]})
    font:Print(attributes[7][2], 13.5*infoScale, (iconHeight+1.9)*infoScale, 8*infoScale, "cn")
  end
  font:End()
  
  if showInfo and attributes[8] > 0 then
    glScale(infoScale,infoScale,infoScale)
    
    if showCountry and attributes[6] and attributes[6] ~= '' then
      glTexture("LuaUI/Images/flags-hq/"..string.upper(attributes[6])..".png")
      glColor(0,0,0,0.55 * attributes[8] * attributes[8] * attributes[8])
      glTexRect(-22.5, iconHeight-2, -10.5, iconHeight+10)
      glColor(1,1,1,attributes[8])
      glTexRect(-22.5, iconHeight-1.5, -10.5, iconHeight+10.5)
      glTexture(false)
    end
    if showRank and rankImages[tonumber(attributes[5])] then
      glTexture(rankImages[tonumber(attributes[5])])
      glColor(0,0,0,0.55 * attributes[8] * attributes[8] * attributes[8])
      glTexRect(-13/2, iconHeight+2, 13/2, iconHeight+2+13)
      glColor(1,1,1,attributes[8])
      glTexRect(-13/2, iconHeight+2.5, 13/2, iconHeight+2.5+13)
      glTexture(false)
    end
    glScale(1,1,1)
    glColor(1,1,1,1)
  end
end


--------------------------------------------------------------------------------
-- callins
--------------------------------------------------------------------------------

function widget:Initialize()
  local allUnits = GetAllUnits()
  for _, unitID in pairs(allUnits) do
    local unitDefID = GetUnitDefID(unitID)
    if (unitDefID and UnitDefs[unitDefID].customParams.iscommander) then
      comms[unitID] = GetCommAttributes(unitID, unitDefID)
    end
  end
end


function spGetUnitPieceMap(unitID,piecename)
  local pieceMap = {}
  local pl = Spring.GetUnitPieceList(unitID)
  if pl == nil then
    return pieceMap
  end
  for piecenum,piecename in pairs(pl) do
    pieceMap[piecename] = piecenum
  end
  return pieceMap
end


function widget:DrawWorld()
  --if Spring.IsGUIHidden() then return end

  glDepthTest(true)
  glAlphaTest(GL_GREATER, 0)
  glBlending(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
      
  local camX, camY, camZ = GetCameraPosition()
  for unitID, attributes in pairs(comms) do
    local heading = GetUnitHeading(unitID)
    if (not heading) then
      return
    end
    
    -- calc opacity
    local x,y,z = GetUnitPosition(unitID)
    local xDifference = camX - x
    local yDifference = camY - y
    local zDifference = camZ - z
    local camDistance = math.sqrt(xDifference*xDifference + yDifference*yDifference + zDifference*zDifference)
    
    if scaleFontSize then
      usedFontSize = (fontSize*0.5) + (camDistance/scaleFontAmount)
    end
    local opacityMultiplier = 1
    if fadeNames then
		opacityMultiplier = 1 - (camDistance-fadeStartHeight) / (fadeEndHeight-fadeStartHeight)
		if opacityMultiplier > 1 then
			opacityMultiplier = 1
		end
    end
    local iconOpacityMultiplier = 1 - (camDistance-fadeIconStartHeight) / (fadeIconEndHeight-fadeIconStartHeight)
    if iconOpacityMultiplier > 1 then
    	iconOpacityMultiplier = 1
    end
    
    if opacityMultiplier > 0 then
      attributes[2][4] = opacityMultiplier
      attributes[8] = iconOpacityMultiplier
      local rot = (heading / 32768) * 180
      glDrawFuncAtUnit(unitID, false, DrawCommName, unitID, attributes)
    end
  end
  
  glAlphaTest(false)
  glColor(1,1,1,1)
  glTexture(false)
  glDepthTest(false)
end

function widget:UnitCreated( unitID,  unitDefID,  unitTeam)
  if (unitDefID and UnitDefs[unitDefID] and UnitDefs[unitDefID].customParams.iscommander) then
    comms[unitID] = GetCommAttributes(unitID, unitDefID)
  end
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
  comms[unitID] = nil
end

function widget:UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
  widget:UnitCreated( unitID,  unitDefID,  unitTeam)
end

function widget:UnitTaken(unitID, unitDefID, unitTeam, newTeam)
  widget:UnitCreated( unitID,  unitDefID,  unitTeam)
end

function widget:UnitEnteredLos(unitID, unitDefID, unitTeam)
  widget:UnitCreated( unitID,  unitDefID,  unitTeam)
end


function widget:GetConfigData(data)
    savedTable = {}
    savedTable.showRank				= showRank
    savedTable.showTrueskill		= showTrueskill
    savedTable.showCountry			= showCountry
    savedTable.fadeNames			= fadeNames
    savedTable.useThickLeterring	= useThickLeterring
    savedTable.showInfo				= showInfo
    return savedTable
end

function widget:SetConfigData(data)
    if data.showRank ~= nil 			then  showRank				= data.showRank end
    if data.showTrueskill ~= nil 		then  showTrueskill			= data.showTrueskill end
    if data.showCountry ~= nil	 		then  showCountry			= data.showCountry end
    if data.fadeNames ~= nil	 		then  fadeNames				= data.fadeNames end
    if data.useThickLeterring ~= nil	then  useThickLeterring		= data.useThickLeterring end
    if data.showInfo ~= nil				then  showInfo				= data.showInfo end
end

function widget:TextCommand(command)
    if (string.find(command, "comnames_rank") == 1  and  string.len(command) == 13) then 
		showRank = not showRank
	end
    if (string.find(command, "comnames_trueskill") == 1  and  string.len(command) == 18) then 
		showTrueskill = not showTrueskill
	end
    if (string.find(command, "comnames_flag") == 1  and  string.len(command) == 13) then 
		showCountry = not showCountry
	end
    if (string.find(command, "comnames_info") == 1  and  string.len(command) == 13) then 
		showInfo = not showInfo
	end
    if (string.find(command, "comnames_fade") == 1  and  string.len(command) == 13) then 
		fadeNames = not fadeNames
	end
    if (string.find(command, "comnames_thick") == 1  and  string.len(command) == 14) then 
		useThickLeterring = not useThickLeterring
	end
	
end

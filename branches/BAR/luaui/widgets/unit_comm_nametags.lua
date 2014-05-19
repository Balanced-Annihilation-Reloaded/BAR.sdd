local versionNumber = "1.80"

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

--/comnames_rank
--/comnames_trueskill
--/comnames_flag


--------------------------------------------------------------------------------
-- config
--------------------------------------------------------------------------------

local showStickyTags	= false --comms literally wear name tags
local heightOffset		= 28
local xOffset			= 0
local yOffset			= 0
local fontSize			= 6
local showRank			= true
local showTrueskill		= true
local showCountry		= true

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

local iconsize   = 10
local iconhsize  = iconsize * 0.5


local glColor             = gl.Color
--local glText              = gl.Text
local glPushMatrix        = gl.PushMatrix
local glPopMatrix         = gl.PopMatrix
local glTranslate         = gl.Translate
local glBillboard         = gl.Billboard
local glDrawFuncAtUnit    = gl.DrawFuncAtUnit

local glDepthTest      = gl.DepthTest
local glAlphaTest      = gl.AlphaTest
local glTexture        = gl.Texture
local glTexRect        = gl.TexRect
local glRotate         = gl.Rotate
local GL_GREATER       = GL.GREATER
local glUnitMultMatrix = gl.UnitMultMatrix
local glUnitPieceMultMatrix = gl.UnitPieceMultMatrix
local glScale          = gl.Scale


local overheadFont	= "LuaUI/Fonts/FreeSansBold_14"
local stickyFont	= "LuaUI/Fonts/FreeSansBold_14"
local fhDraw		= fontHandler.Draw


--rank pics
local rankImages = {}
rankImages[0] = "LuaUI/Images/advplayerslist/Ranks/rank0.png"
rankImages[1] = "LuaUI/Images/advplayerslist/Ranks/rank1.png"
rankImages[2] = "LuaUI/Images/advplayerslist/Ranks/rank2.png"
rankImages[3] = "LuaUI/Images/advplayerslist/Ranks/rank3.png"
rankImages[4] = "LuaUI/Images/advplayerslist/Ranks/rank4.png"
rankImages[5] = "LuaUI/Images/advplayerslist/Ranks/rank5.png"
rankImages[6] = "LuaUI/Images/advplayerslist/Ranks/rank6.png"
rankImages[7] = "LuaUI/Images/advplayerslist/Ranks/rank7.png"

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

function GetSkill(playerID)
	customtable = select(10,Spring.GetPlayerInfo(playerID)) or {} -- player custom table
	tsMu = customtable.skill
	tsSigma = customtable.skilluncertainty or "N/A"
	tskill = 0
	if tsMu then
		tskill = tsMu and tonumber(tsMu:match("%d+%.?%d*")) or 0
		tskill = math.floor(tskill,0)
		--if string.find(tsMu, ")") then
		--	tskill = "\255"..string.char(190)..string.char(140)..string.char(140) .. tskill -- ')' means inferred from lobby rank
		--end
	end
	return tskill
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
  glTranslate(0, attributes[3], 0 )
  glBillboard()
  glColor(attributes[2])
  --glText(attributes[1], xOffset, yOffset, fontSize, "cn")
  fontHandler.UseFont(overheadFont)
  fontHandler.DrawCentered(attributes[1], xOffset,yOffset)
  
  
  if showCountry and attributes[6] and attributes[6] ~= '' then
	glColor(1,1,1,0.9)
    glTexture("LuaUI/Images/flags/"..string.lower(attributes[6])..".png")
    glTexRect(-22.5, 17.5, -10.5, 25.75)
    glTexture(false)
  end
  if showTrueskill and attributes[7] and attributes[7] > 0 then
	glColor(0,0,0,0.33)
    gl.Text(tostring(attributes[7]),8.2,17.8,10.5,"n")
	glColor(1,1,1,0.9)
    gl.Text(tostring(attributes[7]),8.2,18.3,10.5,"n")
  end
  
  if showRank and rankImages[tonumber(attributes[5])] then
    glColor(1,1,1,0.9)
    glTexture(rankImages[tonumber(attributes[5])])
    glTexRect(-13/2,19.5, 13/2, 19.5+13)
    glTexture(false)
  end
  
  glColor(1,1,1,1)
end

local function DrawNameTag(rotation)
  glRotate(rotation,0,1,0)
  glTranslate(8, 35, 7)
  
  glColor(1,1,1,1)
  glTexRect(-iconhsize, 0, iconhsize, iconsize)
end

local function DrawCommName2(unitID, attributes, rotation)
  glRotate(rotation,0,1,0)
  glTranslate(8, 40, 7)

  glColor(attributes[2])
  --glText(attributes[1], xOffset, yOffset, 1, "cn")

  glColor(1,1,1,1)
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

  if (showStickyTags) then
    glTexture('LuaUI/Images/hellomynameis.png')
    for unitID, attributes in pairs(comms) do
	  if (attributes[4]) then
	      glPushMatrix()
	      glUnitMultMatrix(unitID)
	      glUnitPieceMultMatrix(unitID, attributes[4])
	      glRotate(0,0,1,0)
	      glTranslate(8, 0, 7)
	      glColor(1,1,1,1)
	      glTexRect(-iconhsize, 0, iconhsize, iconsize)
	      glPopMatrix()
		end
    end
    for unitID, attributes in pairs(comms) do
	  if (attributes[4]) then
	      glPushMatrix()
	      glUnitMultMatrix(unitID)
	      glUnitPieceMultMatrix(unitID, attributes[4])
	      glRotate(0,0,1,0)
	      glTranslate(8, 0, 7)
	      glColor(attributes[2])
	 
	      glPushMatrix()
	      glScale(0.03, 0.03, 0.03)
	      glTranslate (0,120,5)
	      fontHandler.UseFont(stickyFont)
	      fontHandler.DrawCentered(attributes[1], 0,0)
	      glPopMatrix()
	 
	      glPopMatrix()
	  end
    end

  end
      
  for unitID, attributes in pairs(comms) do
    local heading = GetUnitHeading(unitID)
    if (not heading) then
      return
    end
    local rot = (heading / 32768) * 180
    glDrawFuncAtUnit(unitID, false, DrawCommName, unitID, attributes)
    if (showStickyTags) then
      glDrawFuncAtUnit(unitID, false, DrawCommName2, unitID, attributes, rot)
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
    savedTable.showRank			= showRank
    savedTable.showTrueskill	= showTrueskill
    savedTable.showCountry		= showCountry
    return savedTable
end

function widget:SetConfigData(data)
    if data.showRank ~= nil 		then  showRank		= data.showRank end
    if data.showTrueskill ~= nil 	then  showTrueskill	= data.showTrueskill end
    if data.showCountry ~= nil	 	then  showCountry	= data.showCountry end
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
end

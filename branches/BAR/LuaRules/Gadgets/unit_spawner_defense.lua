--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "BA Chicken Spawner",
    desc      = "Spawns burrows and chickens",
    author    = "TheFatController/quantum",
    date      = "27 February, 2012",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if (gadgetHandler:IsSyncedCode()) then
-- BEGIN SYNCED
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local enabled = tonumber(Spring.GetModOptions().mo_chickengame) or 0

if (enabled == 0) then 
  return false
end
  
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- Speed-ups
--

local GetUnitNeutral       = Spring.GetUnitNeutral
local GetTeamList          = Spring.GetTeamList
local GetTeamLuaAI         = Spring.GetTeamLuaAI
local GetGaiaTeamID        = Spring.GetGaiaTeamID
local SetGameRulesParam    = Spring.SetGameRulesParam
local GetGameRulesParam    = Spring.GetGameRulesParam
local GetTeamUnitsCounts   = Spring.GetTeamUnitsCounts
local GetTeamUnitCount     = Spring.GetTeamUnitCount
local GetGameSpeed         = Spring.GetGameSpeed
local GetGameFrame         = Spring.GetGameFrame
local GetPlayerList        = Spring.GetPlayerList
local GetPlayerInfo        = Spring.GetPlayerInfo
local GetGameSeconds       = Spring.GetGameSeconds
local DestroyUnit          = Spring.DestroyUnit
local GetTeamUnits         = Spring.GetTeamUnits
local GetUnitsInCylinder   = Spring.GetUnitsInCylinder
local GetUnitNearestEnemy  = Spring.GetUnitNearestEnemy
local GetUnitPosition      = Spring.GetUnitPosition
local GiveOrderToUnit      = Spring.GiveOrderToUnit
local TestBuildOrder       = Spring.TestBuildOrder
local GetGroundBlocked     = Spring.GetGroundBlocked
local CreateUnit           = Spring.CreateUnit
local SetUnitBlocking      = Spring.SetUnitBlocking
local GetGroundHeight      = Spring.GetGroundHeight
local GetUnitTeam          = Spring.GetUnitTeam
local GetUnitHealth        = Spring.GetUnitHealth
local GetUnitCommands      = Spring.GetUnitCommands
local SetUnitExperience    = Spring.SetUnitExperience
local GetUnitDefID         = Spring.GetUnitDefID
local SetUnitHealth        = Spring.SetUnitHealth
local GetUnitIsDead        = Spring.GetUnitIsDead
local GetCommandQueue      = Spring.GetCommandQueue
local GetUnitDirection     = Spring.GetUnitDirection

local mRandom             = math.random
local math                = math
local Game                = Game
local table               = table
local ipairs              = ipairs
local pairs               = pairs

local MAPSIZEX = Game.mapSizeX
local MAPSIZEZ = Game.mapSizeZ

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local queenLifePercent    = 100
local maxTries            = 100
local currentWave         = 1
local targetCache         = 1
local minBurrows          = 1
local timeOfLastSpawn     = 0
local timeOfLastFakeSpawn = 0
local timeOfLastWave      = 0
local expMod              = 0
local burrowTarget        = 0
local qDamage             = 0
local lastTeamID          = 0
local targetCacheCount    = 0
local nextSquadSize       = 0
local chickenCount        = 0
local t                   = 0 -- game time in seconds
local timeCounter         = 0
local queenAnger          = 0
local burrowSpawnProgress = 0
local queenMaxHP          = 0
local chickenDebtCount    = 0
local firstSpawn          = true
local showScoresOnce      = true
local gameOver            = false
local qMove               = false
local warningMessage      = false
local computerTeams       = {}
local humanTeams          = {}
local disabledUnits       = {}
local spawnQueue          = {}
local idleOrderQueue      = {}
local endScores           = {}
local queenResistance     = {}
local queenID
local chickenTeamID
local luaAI
local lsx1,lsz1,lsx2,lsz2
local turrets             = {}
local chickenBirths       = {}
local failChickens        = {}
local chickenTargets      = {}
local burrows             = {}

do -- load config file
  local CONFIG_FILE = "LuaRules/Configs/spawn_defs.lua"
  local VFSMODE = VFS.RAW_FIRST
  local s = assert(VFS.LoadFile(CONFIG_FILE, VFSMODE))
  local chunk = assert(loadstring(s, file))
  setfenv(chunk, gadget)
  chunk()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- Teams
--

local modes = {
    [1] = VERYEASY,
    [2] = EASY,
    [3] = NORMAL,
    [4] = HARD,
    [5] = VERYHARD,
    [6] = CUSTOM,
    [7] = SURVIVAL,
}

local function dump(o)
	if type(o) == 'table' then
		local s = '{ '
		for k,v in pairs(o) do
			if type(k) ~= 'number' then k = '"'..k..'"' end
			s = s .. '['..k..'] = ' .. dump(v) .. ',\n'
		end
			return s .. '} '
		else
			return tostring(o)
	end
end
Spring.Echo(VERYEASY)

for i, v in ipairs(modes) do -- make it bi-directional
  modes[v] = i
end

local teams = GetTeamList()
local highestLevel = 0
for _, teamID in ipairs(teams) do
  local teamLuaAI = GetTeamLuaAI(teamID)
  if (teamLuaAI and teamLuaAI ~= "") then
    luaAI = teamLuaAI
    if (modes[teamLuaAI] > highestLevel) then -- get chicken ai with highest level
      highestLevel = modes[teamLuaAI]
    end
    chickenTeamID = teamID
    computerTeams[teamID] = true
  else
    humanTeams[teamID]    = true
  end
end

luaAI = modes[highestLevel]

local gaiaTeamID         = GetGaiaTeamID()
if not chickenTeamID then 
  chickenTeamID = gaiaTeamID
  
  warningMessage = true
else
  computerTeams[gaiaTeamID] = nil
end

humanTeams[gaiaTeamID]    = nil

if (modes[highestLevel] and luaAI == 0) then
  return false
end

SetGameRulesParam("chickenTeamID", chickenTeamID)
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- Utility
--

local function SetToList(set)
  local list = {}
  for k in pairs(set) do
    table.insert(list, k)
  end
  return list
end


local function SetCount(set)
  local count = 0
  for k in pairs(set) do
    count = count + 1
  end
  return count
end

local function getSqrDistance(x1,z1,x2,z2)
  local dx,dz = x1-x2,z1-z2
  return (dx*dx)+(dz*dz)
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- Difficulty
--

local function SetGlobals(difficulty)
  for key, value in pairs(gadget.difficulties[difficulty]) do
    gadget[key] = value
  end
  gadget.difficulties = nil
end

SetGlobals(luaAI or "Chicken: Custom") -- set difficulty

local expIncrement = ((SetCount(humanTeams) * expStep) / queenTime)
if expStep < 0 then expIncrement = ((expStep * -1) / queenTime) end
local nextWave = ((queenTime / 8) / 60)
local gracePenalty = math.max(math.floor(((gracePeriod - 220) / burrowSpawnRate) + 0.5), 0)
chickensPerPlayer = (chickensPerPlayer * SetCount(humanTeams))
maxBurrows = maxBurrows + math.floor(SetCount(humanTeams) * 1.334) 
queenTime = (queenTime + gracePeriod)
chickenDebtCount = math.ceil((math.max((gracePeriod - 220),0) / 3)) 

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- Game Rules
--

local UPDATE = 10

local unitCounts = {}

local chickenDefTypes = {}
for unitName in pairs(chickenTypes) do
  chickenDefTypes[UnitDefNames[unitName].id] = unitName
  unitCounts[string.sub(unitName,1,-2)] = {count = 0, lastCount = 0}
end

local defendersDefs = {}
for unitName in pairs(defenders) do 
  defendersDefs[UnitDefNames[unitName].id] = unitName
end

local function SetupUnit(unitName)
  SetGameRulesParam(unitName.."Count", 0)
  SetGameRulesParam(unitName.."Kills", 0)
end

SetGameRulesParam("queenTime",        queenTime)
SetGameRulesParam("queenLife",        queenLifePercent)
SetGameRulesParam("queenAnger",       queenAnger)
SetGameRulesParam("gracePeriod",      gracePeriod)

for unitName in pairs(chickenTypes) do
  SetupUnit(string.sub(unitName,1,-2))
end

for unitName in pairs(defenders) do
  SetupUnit(string.sub(unitName,1,-2))
end

SetupUnit(burrowName)

local difficulty = modes[luaAI] or 6
SetGameRulesParam("difficulty", difficulty)

local function UpdateUnitCount()
  local teamUnitCounts = GetTeamUnitsCounts(chickenTeamID)
  local total = 0
  
  for shortName in pairs(unitCounts) do
    unitCounts[shortName].count = 0
  end
  
  for unitDefID, number in pairs(teamUnitCounts) do
    if UnitDefs[unitDefID] then
      local shortName = string.match(UnitDefs[unitDefID].name,"%D*")
      if unitCounts[shortName] then
        unitCounts[shortName].count = unitCounts[shortName].count + number
      end
    end
  end
  
  for shortName, counts in pairs(unitCounts) do
    if (counts.count ~= counts.lastCount) then
      SetGameRulesParam(shortName.."Count", counts.count)
      counts.lastCount = counts.count
    end
    total = total + counts.count
  end
  
  return total
end

local EMP_GOO = {}
EMP_GOO[WeaponDefNames['chickenr1_goolauncher'].id] = WeaponDefNames['chickenr1_goolauncher'].damages[1]
EMP_GOO[WeaponDefNames['weaver_death'].id] = WeaponDefNames['weaver_death'].damages[1]
local LOBBER = UnitDefNames["chickenr1"].id
local SKIRMISH = { 
  [UnitDefNames["chickens1"].id] = 270, 
  [UnitDefNames["chickens2"].id] = 620, 
  [UnitDefNames["chickenf2"].id] = 2000, 
  [UnitDefNames["chickenw1b"].id] = 900 
 }
local COWARD = { 
  [UnitDefNames["chickenh1"].id] = 150,
  [UnitDefNames["chickenr1"].id] = 300, 
  [UnitDefNames["chickenw1c"].id] = 900 
 }
local JUNO = { [WeaponDefNames["cjuno_juno_pulse"].id]= true, [WeaponDefNames["ajuno_juno_pulse"]] = true }
local KROW_ID = UnitDefNames["corcrw"].id
local KROW_LASER = "krow_laser_index"
local SMALL_UNIT = UnitDefNames["corllt"].id
local MEDIUM_UNIT = UnitDefNames["armwin"].id
local LARGE_UNIT = UnitDefNames["armsolar"].id

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- Clean up
--

local function KillOldChicken()
  for unitID, birthDate in pairs(chickenBirths) do
    local age = (t - birthDate)
    if (age > maxAge) then
      if (unitID ~= queenID) then 
        DestroyUnit(unitID)
        chickenCount = chickenCount - 1
        chickenDebtCount = chickenDebtCount + 1
      end
    end
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- Game End Stuff
--

local function KillAllChicken()
  local chickenUnits = GetTeamUnits(chickenTeamID)
  for _, unitID in pairs(chickenUnits) do
    if disabledUnits[unitID] then
      DestroyUnit(unitID, false, true)
    else
      DestroyUnit(unitID, true)
    end
  end
end


local function KillAllComputerUnits()
  for teamID in pairs(computerTeams) do
    local teamUnits = GetTeamUnits(teamID)
    for _, unitID in pairs(teamUnits) do
      if disabledUnits[unitID] then
        DestroyUnit(unitID, false, true)
      else
        DestroyUnit(unitID, true)
      end
    end
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- Spawn Dynamics
--

local function addChickenTarget(chickenID, targetID)
  if (not targetID) or (GetUnitTeam(targetID) == chickenTeamID) or (GetUnitTeam(chickenID) ~= chickenTeamID) then return end
  --debug--Spring.Echo(t .. " addChickenTarget " .. chickenID .. "," .. targetID)
  if chickenTargets[chickenID] and chickenTargets[chickenTargets[chickenID]] then
    chickenTargets[chickenTargets[chickenID]][chickenID] = nil
  end
  if (chickenTargets[targetID] == nil) then
    chickenTargets[targetID] = {}
    chickenTargets[targetID][chickenID] = targetID
    chickenTargets[chickenID] = targetID
  else
    chickenTargets[targetID][chickenID] = targetID
    chickenTargets[chickenID] = targetID
  end
end

local function AttackNearestEnemy(unitID, unitDefID, unitTeam)
  local targetID = GetUnitNearestEnemy(unitID)
  if (targetID) and (not GetUnitIsDead(targetID)) and (not GetUnitNeutral(targetID)) then
--    Spring.Echo(t .. " AttackNearestEnemy " .. unitID .. " -> " .. targetID)
    local defID = GetUnitDefID(targetID)
    if UnitDefs[defID] and (UnitDefs[defID].speed > 75) then
      return false
    end
    local x,y,z = GetUnitPosition(targetID)
    idleOrderQueue[unitID] = {cmd = CMD.FIGHT, params = {x,y,z}, opts = {}}
    addChickenTarget(unitID, targetID)
    return true
  else
    return false
  end
end

-- returns a random map position
local function getRandomMapPos()
	local x = math.random(MAPSIZEX-16)
	local z = math.random(MAPSIZEZ-16)
	local y = GetGroundHeight(x, z)
	return {x, y, z}
end

-- selects a enemy target
local function ChooseTarget()
	local humanTeamList = SetToList(humanTeams)
	if (#humanTeamList == 0) or gameOver then
		return getRandomMapPos()
	end
	if targetCache and ((targetCacheCount >= nextSquadSize) or GetUnitIsDead(targetCache)) then
		local tries = 0
		repeat
			local teamID = humanTeamList[mRandom(#humanTeamList)]
			if (teamID == lastTeamID) then
				teamID = humanTeamList[mRandom(#humanTeamList)]
			end
			lastTeamID = teamID
			local units = GetTeamUnits(teamID)
			if units[2] then
				targetCache = units[mRandom(1,#units)]
			else
				targetCache = units[1]
			end
			local slowunit = true
			if targetCache and tries < 5 then
				local defID = GetUnitDefID(targetCache)
				if UnitDefs[defID] and (UnitDefs[defID].speed > 75) then
					slowunit = false
				end
			end      
			tries = (tries + 1)
		until (targetCache and (not GetUnitIsDead(targetCache)) and (not GetUnitNeutral(targetCache)) and slowunit) or (tries > maxTries)
		targetCacheCount = 0
		nextSquadSize = 6 + mRandom(0,4)
	else
		targetCacheCount = targetCacheCount + 1
	end
	if not targetCache then -- no target could be found, use random map pos
		return getRandomMapPos()
	end
	if (mRandom(100) < 50) then
		local angle = math.rad(mRandom(1,360))
--		Spring.Echo(targetCache)
		local x,y,z = GetUnitPosition(targetCache)
		if not x or not y or not z then
			Spring.Echo("Invalid pos in GetUnitPosition: " .. tostring(targetCache))
			return getRandomMapPos()
		end
		local distance = mRandom(50,900)
		x = math.min(math.max(x - (math.sin(angle) * distance),16),MAPSIZEX-16)
		z = math.min(math.max(z - (math.cos(angle) * distance),16),MAPSIZEZ-16)
		return {x,y,z}
	else
		return {GetUnitPosition(targetCache)}
	end
end

local function getChickenSpawnLoc(burrowID, size)
  local x, y, z
  local bx, by, bz    = GetUnitPosition(burrowID)
  if (not bx or not bz) then
    return false
  end
  
  local tries         = 0
  local s             = spawnSquare
      
  repeat
    x = mRandom(bx - s, bx + s)
    z = mRandom(bz - s, bz + s)
    s = s + spawnSquareIncrement
    tries = tries + 1
    if (x >= MAPSIZEX) then x = (MAPSIZEX - mRandom(1,40)) elseif (x <= 0) then x = mRandom(1,40) end
    if (z >= MAPSIZEZ) then z = (MAPSIZEZ - mRandom(1,40)) elseif (z <= 0) then z = mRandom(1,40) end
  until ((TestBuildOrder(size, x, by, z, 1) == 2) and (not GetGroundBlocked(x, z))) or (tries > maxTries)
           
  y = GetGroundHeight(x,z)
  return x, y, z
   
end


local function SpawnTurret(burrowID, turret)
  
  if (mRandom() > defenderChance) or (not turret) or (burrows[burrowID] >= maxTurrets) then
    return
  end
  
  local x, y, z
  local bx, by, bz    = GetUnitPosition(burrowID)
  local tries         = 0
  local s             = spawnSquare

  repeat
    x = mRandom(bx - s, bx + s)
    z = mRandom(bz - s, bz + s)
    s = s + spawnSquareIncrement
    tries = tries + 1
    if (x >= MAPSIZEX) then x = (MAPSIZEX - mRandom(1,40)) elseif (x <= 0) then x = mRandom(1,40) end
    if (z >= MAPSIZEZ) then z = (MAPSIZEZ - mRandom(1,40)) elseif (z <= 0) then z = mRandom(1,40) end
  until (not GetGroundBlocked(x, z) or tries > maxTries)
  
  y = GetGroundHeight(x,z)
  local unitID = CreateUnit(turret, x, y, z, "n", chickenTeamID)
  idleOrderQueue[unitID] = {cmd = CMD.GUARD, params ={burrowID}, opts = {}}
  SetUnitBlocking(unitID, false)
  turrets[unitID] = {burrowID, t}
  burrows[burrowID] = burrows[burrowID] + 1
   
end


local function SpawnBurrow(number)
  
  if (queenID) then -- don't spawn new burrows when queen is there
    return
  end

  local unitDefID = UnitDefNames[burrowName].id
    
  for i=1, (number or 1) do
    local x, z, y
    local tries = 0
  repeat
    if (burrowSpawnType == "initialbox") then 
      x = mRandom(lsx1, lsx2)
      z = mRandom(lsz1, lsz2)
    elseif ((burrowSpawnType == "alwaysbox") and (tries < (maxTries / 2))) then
      x = mRandom(lsx1, lsx2)
      z = mRandom(lsz1, lsz2)
    else
      x = mRandom(spawnSquare, MAPSIZEX - spawnSquare)
      z = mRandom(spawnSquare, MAPSIZEZ - spawnSquare)
    end
    
    y = GetGroundHeight(x, z)
    tries = tries + 1
    local blocking = TestBuildOrder(MEDIUM_UNIT, x, y, z, 1)
    if (blocking == 2) and (burrowSpawnType == "avoid") then
      local proximity = GetUnitsInCylinder(x, z, minBaseDistance)
      local vicinity = GetUnitsInCylinder(x, z, maxBaseDistance)
      local humanUnitsInVicinity = false
      local humanUnitsInProximity = false
      for i=1, #vicinity, 1 do
        if (GetUnitTeam(vicinity[i]) ~= chickenTeamID) then
          humanUnitsInVicinity = true
          break
        end
      end

      for i=1, #proximity ,1 do
        if (GetUnitTeam(proximity[i]) ~= chickenTeamID) then
          humanUnitsInProximity = true
          break
        end
      end

      if (humanUnitsInProximity or not humanUnitsInVicinity) then
        blocking = 1
      end
    end
  until (blocking == 2 or tries > maxTries)

    local unitID = CreateUnit(burrowName, x, y, z, "n", chickenTeamID)
    if (unitID) then
      burrows[unitID] = 0
      SetUnitBlocking(unitID, false)
    end
  end
  
end

local function updateQueenLife()
	if not queenID then
		return
	end
	local curH, maxH = GetUnitHealth(queenID)
	local lifeCheck = math.ceil(((curH/maxH)*100)-0.5)
	if queenLifePercent ~= lifeCheck then -- health changed since last update, update it
		queenLifePercent = lifeCheck
		SetGameRulesParam("queenLife", queenLifePercent)
	end
end

local function stunUnit(unitID, seconds)
	-- get current health and paralizeDamage
	local health, _, paralizeDamage, _, _, _ = GetUnitHealth(unitID)
	-- TODO: limit to max value?
	local stunDamage = math.ceil( (health * seconds) + paralizeDamage)
	SetUnitHealth(unitID, {paralyze=stunDamage})
end

local function SpawnQueen()
  
  local x, y, z
  local tries = 0
  
  repeat
    x = mRandom(1, (MAPSIZEX-1))
    z = mRandom(1, (MAPSIZEZ-1))
    y = GetGroundHeight(x, z)
    tries = tries + 1
    local blocking = TestBuildOrder(LARGE_UNIT, x, y, z, 1)
    
    local proximity = GetUnitsInCylinder(x, z, minBaseDistance)
    local vicinity = GetUnitsInCylinder(x, z, maxBaseDistance)
    local humanUnitsInVicinity = false
    local humanUnitsInProximity = false
    
    for i=1, #vicinity, 1 do
      if (GetUnitTeam(vicinity[i]) ~= chickenTeamID) then
        humanUnitsInVicinity = true
        break
      end
    end

    for i=1, #proximity,1 do
      if (GetUnitTeam(proximity[i]) ~= chickenTeamID) then
        humanUnitsInProximity = true
        break
      end
    end

    if (humanUnitsInProximity or not humanUnitsInVicinity) then
      blocking = 1
    end
  
  until (blocking == 2 or tries > maxTries)
  
  return CreateUnit(queenName, x, y, z, "n", chickenTeamID)
 
end


local function Wave()
  --debug--Spring.Echo(t .. "Wave()")
  
  if gameOver then return end
  
  currentWave = math.min(math.ceil((((t-gracePeriod+queenAnger) / 60) / nextWave)), 8)
  
  if currentWave > #waves then currentWave = #waves end
  
  if (currentWave == 8) then
    COWARD[UnitDefNames["chickenc1"].id] = (150 + mRandom(1,150))
    COWARD[UnitDefNames["chicken2"].id] = (200 + mRandom(1,200))
  end
  
  local cCount = 0
  
  if queenID then -- spawn units from queen
    if queenSpawnMult > 0 then
      for i = 1,queenSpawnMult,1 do
        local squad = waves[9][mRandom(1,#waves[9])]
        for i,sString in pairs(squad) do
          local nEnd,_     = string.find(sString, " ")
          local unitNumber = string.sub(sString,1,(nEnd-1))
          local chickenName  = string.sub(sString,(nEnd+1))
          for i = 1,unitNumber,1 do
            table.insert(spawnQueue, {burrow = queenID, unitName = chickenName, team = chickenTeamID})
          end
          cCount = cCount + unitNumber
        end
      end
    end
    return cCount
  end
  
  for burrowID in pairs(burrows) do
    if (t > (queenTime * 0.33)) then SpawnTurret(burrowID, bonusTurret) end
    local squad = waves[currentWave][mRandom(1,#waves[currentWave])]
    for i,sString in pairs(squad) do
      local skipSpawn = false
      if (cCount > chickensPerPlayer) and (mRandom() > spawnChance) then skipSpawn = true end
      if skipSpawn and (chickenDebtCount > 0) and (mRandom() > 0.5) then
        chickenDebtCount = (chickenDebtCount - 1)
        skipSpawn = false
      end
      if not skipSpawn then
        local nEnd,_     = string.find(sString, " ")
        local unitNumber = string.sub(sString,1,(nEnd-1))
        local chickenName  = string.sub(sString,(nEnd+1))
        for i = 1,unitNumber,1 do
          table.insert(spawnQueue, {burrow = burrowID, unitName = chickenName, team = chickenTeamID})
        end
        cCount = cCount + unitNumber
      end
    end
  end
  return cCount
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- Get rid of the AI
--

local function DisableUnit(unitID)
  Spring.MoveCtrl.Enable(unitID)
  Spring.MoveCtrl.SetNoBlocking(unitID, true)
  Spring.MoveCtrl.SetPosition(unitID, Game.mapSizeX+2450, 4000, Game.mapSizeZ+2450)
  Spring.SetUnitCloak(unitID, true)
  Spring.SetUnitHealth(unitID, {paralyze=99999999})
  Spring.SetUnitNoDraw(unitID, true)
  Spring.SetUnitStealth(unitID, true)
  Spring.SetUnitNoSelect(unitID, true)
  Spring.SetUnitNoMinimap(unitID, true)
  disabledUnits[unitID] = true
end

local function DisableComputerUnits()
  for teamID in pairs(computerTeams) do
    local teamUnits = GetTeamUnits(teamID)
    for _, unitID in ipairs(teamUnits) do
      DisableUnit(unitID)
    end
  end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- Call-ins
--

function gadget:UnitMoveFailed(unitID, unitDefID, unitTeam)
  if gameOver then return end
  if (unitTeam ~= chickenTeamID) or (unitID == queenID) or idleOrderQueue[unitID] then return end
  local px,py,pz = GetUnitPosition(unitID)
  if failChickens[unitID] then
    if (getSqrDistance(failChickens[unitID].x,failChickens[unitID].z,px,pz) < 5000) then
      failChickens[unitID].count = failChickens[unitID].count + 1
      if (failChickens[unitID].count > 3) then
        DestroyUnit(unitID, false, true)
        chickenDebtCount = chickenDebtCount + 1
        chickenCount = chickenCount - 1
        return
      end
    else
      failChickens[unitID].x = px
      failChickens[unitID].z = pz
    end
  else
    failChickens[unitID] = { x = px, z = pz, count = 1 }
  end
  if (mRandom(1,2) == 1) then px = px + mRandom(50,100) else px = px - mRandom(50,100) end
  if (mRandom(1,2) == 1) then pz = pz + mRandom(50,100) else pz = pz - mRandom(50,100) end
  idleOrderQueue[unitID] = {cmd = CMD.MOVE, params = {px,py,pz}, opts = {}}
end

function gadget:UnitIdle(unitID, unitDefID, unitTeam)
	if (unitTeam ~= chickenTeamID) or (not chickenDefTypes[unitDefID]) then -- filter out non chicken units
		return
	end
	-- Spring.Echo(t .. " unitIdle " .. unitID)
	if AttackNearestEnemy(unitID, unitDefID, unitTeam) then
		return
	end
	local chickenParams = ChooseTarget()
	if targetCache then
		if (unitID ~= queenID) and (mRandom(1,10) == 5) then
			idleOrderQueue[unitID] = {cmd = CMD.ATTACK, params = {targetCache}, opts = {}}
		else
			idleOrderQueue[unitID] = {cmd = CMD.FIGHT, params = chickenParams, opts = {}}
		end
		if GetUnitNeutral(targetCache) then
			idleOrderQueue[unitID] = {cmd = CMD.ATTACK, params = {targetCache}, opts = {}}
		end
		addChickenTarget(unitID, targetCache)
	end
end

function gadget:UnitCreated(unitID, unitDefID, unitTeam)
	if (unitTeam == chickenTeamID) or (chickenDefTypes[unitDefID]) then -- filter out chicken units
		return
	end
	if chickenTargets[unitID] then
		chickenTargets[unitID] = nil
	end
end

function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, 
                            weaponID, attackerID, attackerDefID, attackerTeam)

  if (attackerTeam == chickenTeamID) then
    return (damage * damageMod)
  end
  if (unitID == queenID) then -- special case queen
    if (weaponID == -1) and (damage > 25000) then
	  return 25000
    end
    if attackerDefID then
      if (attackerDefID == KROW_ID) then
        weaponID = KROW_LASER
      end
      if not queenResistance[weaponID] then 
        queenResistance[weaponID] = {}
        queenResistance[weaponID].damage = damage
        queenResistance[weaponID].notify = 0
      end
      local resistPercent = (math.min(queenResistance[weaponID].damage/queenMaxHP, 0.75) + 0.2)
      if resistPercent > 0.35 then
        if queenResistance[weaponID].notify == 0 then
          local weaponName
          if (attackerDefID == KROW_ID) then
            weaponName = "HighEnergyLaser"
          else
            weaponName = WeaponDefs[weaponID].description
          end
          Spring.Echo("Queen is becoming resistant to " .. UnitDefs[attackerDefID].humanName .. "'s attacks (" .. weaponName .. ")")
          queenResistance[weaponID].notify = 1
          for i = 1,30,1 do
            table.insert(spawnQueue, {burrow = queenID, unitName = "chickenh4", team = chickenTeamID})
          end
        end
        damage = damage - (damage * resistPercent)
      end
      queenResistance[weaponID].damage = queenResistance[weaponID].damage + damage
      return damage
    end
  end
  return damage         
end

function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, 
                            weaponID, attackerID, attackerDefID, attackerTeam)
                              
  if EMP_GOO[weaponID] and (unitTeam ~= chickenTeamID) and (lobberEMPTime > 0) then
    stunUnit(unitID, ((damage / EMP_GOO[weaponID]) * lobberEMPTime))
  end
     
  if chickenBirths[attackerID] then chickenBirths[attackerID] = t end
  if failChickens[attackerID] then failChickens[attackerID] = nil end
  if failChickens[unitID] then failChickens[unitID] = nil end
  
  if SKIRMISH[attackerDefID] and (unitTeam ~= chickenTeamID) and attackerID then
    local ux,_,uz = GetUnitPosition(unitID)
    local x,y,z = GetUnitPosition(attackerID)
    if x and ux then
	  local angle = math.atan2(ux-x,uz-z)
	  idleOrderQueue[attackerID] = {cmd = CMD.MOVE, params = {x - (math.sin(angle) * SKIRMISH[attackerDefID]),y,z - (math.cos(angle) * SKIRMISH[attackerDefID])}, opts = {}}
	end
  elseif COWARD[unitDefID] and (not idleOrderQueue[unitID]) and (unitTeam == chickenTeamID) and attackerID then
    local curH, maxH = GetUnitHealth(attackerID)
    if curH < (maxH * 0.8) then
      local ax,_,az = GetUnitPosition(attackerID)
      local x,y,z = GetUnitPosition(unitID)
      if x and ax then
	    local angle = math.atan2(ax-x,az-z)
	    idleOrderQueue[unitID] = {cmd = CMD.MOVE, params = {x - (math.sin(angle) * COWARD[unitDefID]),y,z - (math.cos(angle) * COWARD[unitDefID])}, opts = {}}
	  end
	end
  end
  
  if (unitDefID == LOBBER) then
    local nSpawn = false
    if ((GetUnitHealth(unitID) < 2475) and (damage < (2000 + mRandom(1,500)))) then nSpawn = true end
    if ((JUNO[weaponID]) and (mRandom(1,2) == 1)) then nSpawn = true end
    if nSpawn then 
      local bx, by, bz = GetUnitPosition(unitID)
      local h = Spring.GetUnitHeading(unitID)
      SetUnitBlocking(unitID, false)
      local newUnitID = CreateUnit("chickenr2", bx, by, bz, "n", unitTeam)
      Spring.SetUnitNoDraw(newUnitID,true)
      Spring.MoveCtrl.Enable(newUnitID)
      Spring.MoveCtrl.SetHeading(newUnitID, h)
      Spring.MoveCtrl.Disable(newUnitID)
      SetUnitExperience(newUnitID, expMod)
      Spring.SetUnitNoDraw(newUnitID,false)
      DestroyUnit(unitID, false, true)
      idleOrderQueue[newUnitID] = {cmd = CMD.STOP, params = {}, opts = {}}
    return
    end
  elseif (unitID == queenID) then
    if paralyzer then
      SetUnitHealth(unitID, {paralyze=0})
      return
    end
    qDamage = (qDamage + damage)
    if (qDamage > (queenMaxHP/10)) then
      if qMove then
        idleOrderQueue[queenID] = {cmd = CMD.STOP, params = {}, opts = {}}
        qMove = false
        qDamage = 0 - mRandom(1,25000)
      else
        local cC = ChooseTarget()
        local xQ, _, zQ = GetUnitPosition(queenID)
        if cC then
          local angle = math.atan2((cC[1]-xQ), (cC[3]-zQ))
          local dist = math.sqrt(((cC[1]-xQ)*(cC[1]-xQ))+((cC[3]-zQ)*(cC[3]-zQ))) * 0.75
          if (dist < 1500) then
            GiveOrderToUnit(queenID, CMD.MOVE, {(xQ + (math.sin(angle) * dist)), cC[2], (zQ + (math.cos(angle) * dist))}, {})
            GiveOrderToUnit(queenID, CMD.FIGHT, cC, {"shift"})
            if targetCache then addChickenTarget(queenID, targetCache) end
            qDamage = (0 - mRandom(1,25000))
            Wave()
            qMove = true
          else
            idleOrderQueue[queenID] = {cmd = CMD.STOP, params = {}, opts = {}}
            qDamage = 0
            Wave()
          end
        else
          idleOrderQueue[queenID] = {cmd = CMD.STOP, params = {}, opts = {}}
          qDamage = 0
        end
      end
    end
  end
end

function gadget:GameStart()
  if warningMessage then 
    Spring.Echo("Warning: No Chicken team available, add a Chicken bot")
    Spring.Echo("(Assigning Chicken Team to Gaia - AI: Custom)")
  end
  if (burrowSpawnType == "initialbox") or (burrowSpawnType == "alwaysbox") then
    local _,_,_,_,_,luaAllyID = Spring.GetTeamInfo(chickenTeamID)
    if luaAllyID then
      lsx1,lsz1,lsx2,lsz2 = Spring.GetAllyTeamStartBox(luaAllyID)
      if (not lsx1) or (not lsz1) or (not lsx2) or (not lsz2) then
        burrowSpawnType = "avoid"
        Spring.Echo("No Chicken start box available, Burrow Placement set to 'Avoid Players'")
      elseif (lsx1 == 0) and (lsz1 == 0) and (lsx2 == Game.mapSizeX) and (lsz2 == Game.mapSizeX) then
        burrowSpawnType = "avoid"
        Spring.Echo("No Chicken start box available, Burrow Placement set to 'Avoid Players'")
      end
    end
  end
end


local function SpawnChickens()
	local i,defs = next(spawnQueue)
	if not i or not defs then
		return
	end
	local x,y,z
	if (queenID) then
		x, y, z = getChickenSpawnLoc(defs.burrow, MEDIUM_UNIT)
	else
		x, y, z = getChickenSpawnLoc(defs.burrow, SMALL_UNIT)
	end
	if not x or not y or not z then
		return
	end
	local unitID = CreateUnit(defs.unitName, x,y,z, "n", defs.team)
	if unitID then
		SetUnitExperience(unitID, expMod)
		if (queenID) then
			local angle = math.rad(mRandom(1,360))
			idleOrderQueue[unitID] = {cmd = CMD.MOVE, params = {x - (math.sin(angle) * 360),y,z - (math.cos(angle) * 360)}, opts = {}}          
		else
			local chickenParams = ChooseTarget()
			if targetCache and (unitID ~= queenID) and (mRandom(1,15) == 5) then
				idleOrderQueue[unitID] = {cmd = CMD.ATTACK, params = {targetCache}, opts = {}}
			else
				if (mRandom(100) > 20) then
					idleOrderQueue[unitID] = {cmd = CMD.FIGHT, params = chickenParams, opts = {}}
				else
					idleOrderQueue[unitID] = {cmd = CMD.MOVE, params = chickenParams, opts = {}}
				end
			end
			if targetCache then
				if GetUnitNeutral(targetCache) then
					idleOrderQueue[unitID] = {cmd = CMD.ATTACK, params = {targetCache}, opts = {}}
				end
				addChickenTarget(unitID, targetCache)
			end
			chickenBirths[unitID] = t
			chickenCount = chickenCount + 1
		end
	end
	spawnQueue[i] = nil
end

local function chickenEvent(type, num, tech)
	SendToUnsynced("ChickenEvent", type, num, tech)
end


local function updateSpawnQueen()
	if (not queenID) and (not gameOver) then -- spawn queen if not exists
		queenID = SpawnQueen()
		idleOrderQueue[queenID] = {cmd = CMD.STOP, params = {}, opts = {}}
		chickenEvent("queen") -- notify unsynced about queen spawn
		_,queenMaxHP = GetUnitHealth(queenID)
		SetUnitExperience(queenID, (expMod*1.5))
		timeOfLastWave = t
		SKIRMISH[UnitDefNames["chickenc1"].id] = 150
		SKIRMISH[UnitDefNames["chickenf1"].id] = 1200
		SKIRMISH[UnitDefNames["chickenw1"].id] = 1800
		COWARD[UnitDefNames["chicken2"].id] = nil
		COWARD[UnitDefNames["chicken_dodo1"].id] = 300
		for i = 1,80,1 do
			table.insert(spawnQueue, {burrow = queenID, unitName = "chickenh4", team = chickenTeamID})
		end
	else
		if (mRandom() < (spawnChance/5)) then
			table.insert(spawnQueue, {burrow = queenID, unitName = "chickenh4", team = chickenTeamID})
		end
	end
end

function gadget:GameFrame(n)
      
	if gameOver then
		chickenCount = UpdateUnitCount()
		return
	end

	if n == 15 then
		DisableComputerUnits()
	end

	if (chickenCount < maxChicken) then
		SpawnChickens()
	end

	if (n >= timeCounter) then
		timeCounter = (n + UPDATE)
		t = GetGameSeconds()
		if not queenID then
			if t < gracePeriod then
				queenAnger = 0
			else
				queenAnger = math.ceil((t - gracePeriod) / (queenTime - gracePeriod) * 100 % 100)
			end
			SetGameRulesParam("queenAnger", queenAnger)
		end
		KillOldChicken()
	    
		if (t < gracePeriod) then -- do nothing in the grace period
			return
		end
	    
		expMod = (expMod + expIncrement) -- increment expierence

    if next(idleOrderQueue) then
      local processOrderQueue = {}
      for unitID,order in pairs(idleOrderQueue) do
        if GetUnitDefID(unitID) then 
          processOrderQueue[unitID] = order
        end
      end
      idleOrderQueue = {}
      for unitID,order in pairs(processOrderQueue) do
        GiveOrderToUnit(unitID, order.cmd, order.params, order.opts)
        GiveOrderToUnit(unitID, CMD.MOVE_STATE, { mRandom(0,2) }, {})
      end
    end
         
    if queenAnger >= 100 then -- check if the queen should be alive
	updateSpawnQueen()
	updateQueenLife()
    end

    local quicken = 0
    local burrowCount = SetCount(burrows)
     
    if (burrowTarget > 0) and (burrowTarget ~= burrowCount) then
      quicken = (burrowSpawnRate * (1 - (burrowCount / burrowTarget)))
    end
        
    local burrowSpawnTime = (burrowSpawnRate - quicken)
             
    if (burrowSpawnRate < (t - timeOfLastFakeSpawn) and burrowCount < maxBurrows) then
      if firstSpawn then    
        minBurrows = SetCount(humanTeams)
        local hteamID = next(humanTeams)
        local ranCount = GetTeamUnitCount(hteamID)
        for i = 1,ranCount,1 do
          mRandom()
        end
        burrowTarget = math.min(math.ceil(minBurrows * 1.5) + gracePenalty, 40)
      else
        burrowTarget = burrowTarget + 1
      end
      timeOfLastFakeSpawn = t
    end
    
	if (burrowCount < minBurrows) or (burrowSpawnTime <  (t - timeOfLastSpawn) and burrowCount < maxBurrows) then 
		if firstSpawn then
			for i = 1,math.min(math.ceil((SetCount(humanTeams) * 1.5)) + gracePenalty, 40),1 do
				SpawnBurrow()
			end
			timeOfLastWave = (t - (chickenSpawnRate - 6))
			firstSpawn = false
			if (burrowSpawnType == "initialbox") then
				burrowSpawnType = "avoid" 
			end
		else
			SpawnBurrow()
		end
		if (burrowCount >= minBurrows) then timeOfLastSpawn = t end
			chickenEvent("burrowSpawn")
			SetGameRulesParam("roostCount", SetCount(burrows))
		end
    
		if (burrowCount > 0) and (chickenSpawnRate < (t - timeOfLastWave)) then
			local cCount = Wave()
			if cCount and cCount > 0 and (not queenID) then
				chickenEvent("wave", cCount, currentWave)
			end
			timeOfLastWave = t
		end
		chickenCount = UpdateUnitCount()
	end 
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
  --debug--Spring.Echo(t .. " UnitDestroyed " .. unitID)
--  if gameOver then return end
   
  if chickenBirths[unitID] then chickenBirths[unitID] = nil end
  if turrets[unitID] then turrets[unitID] = nil end
  if idleOrderQueue[unitID] then idleOrderQueue[unitID] = nil end
  if failChickens[unitID] then failChickens[unitID] = nil end

  if chickenTargets[unitID] then
    if (unitTeam ~= chickenTeamID) then
      --debug--Spring.Echo(t .. " chickenTargets " .. unitID)
      for chickenID in pairs(chickenTargets[unitID]) do
        --debug--Spring.Echo(t .. " stopChicken " .. chickenID)
        if GetUnitDefID(chickenID) then 
          idleOrderQueue[chickenID] = {cmd = CMD.STOP, params = {}, opts = {}}     
        end
      end
    elseif chickenTargets[chickenTargets[unitID]] then
      chickenTargets[chickenTargets[unitID]][unitID] = nil
    end
    chickenTargets[unitID] = nil
  end
  
  if (unitID == targetCache) then
    targetCache = 1
    targetCacheCount = math.huge
  end
  
  if (unitTeam == chickenTeamID) and chickenDefTypes[unitDefID] then
    local name = UnitDefs[unitDefID].name
    if unitDefID ~= burrowDef then name = string.sub(name,1,-2) end
    local kills = GetGameRulesParam(name.."Kills")
    SetGameRulesParam(name.."Kills", kills + 1)
    chickenCount = chickenCount - 1
  end
  
	if (unitID == queenID) then -- queen destroyed
		queenID = nil
		if modes[highestLevel] == SURVIVAL then
			queenTime = t + (Spring.GetModOptions().mo_queentime or 40) * 60
			queenAnger = 0  -- reenable chicken spawning
			SetGameRulesParam("queenAnger", queenAnger)
			SpawnBurrow()
			SpawnChickens() -- spawn new chickens (because queen could be the last one)
		else
			gameOver = true
			KillAllComputerUnits()
			KillAllChicken()
		end
	end
  
  if (unitDefID == burrowDef) and (not gameOver) then
  
    local kills = GetGameRulesParam(burrowName.."Kills")
    SetGameRulesParam(burrowName.."Kills", kills + 1)
    
    burrows[unitID] = nil
    if (addQueenAnger == 1) then
      queenAnger = (queenAnger + angerBonus)
      expMod = (expMod + (expIncrement * angerBonus))
      SetGameRulesParam("queenAnger", queenAnger)
    end
    
    for turretID,v in pairs(turrets) do
      if (v[1] == unitID) then
        DestroyUnit(turretID, true)
        turrets[turretID] = nil
      end
    end
      
    for burrowID in pairs(burrows) do
        SpawnTurret(burrowID, bonusTurret)
    end
        
    for i,defs in pairs(spawnQueue) do
      if (defs.burrow == unitID) then
        spawnQueue[i] = nil
      end
    end
    
    SetGameRulesParam("roostCount", SetCount(burrows))
  end
  
end

function gadget:TeamDied(teamID)
  if humanTeams[teamID] then
    if (minBurrows > 1) then minBurrows = (minBurrows - 1) end
  end
  humanTeams[teamID] = nil
  computerTeams[teamID] = nil
end

function gadget:UnitTaken(unitID, unitDefID, oldTeam, newTeam)
  if (oldTeam == chickenTeamID) then
    DestroyUnit(unitID, true)
  end
end

function gadget:AllowUnitTransfer(unitID, unitDefID, oldTeam, newTeam, capture)
  if (newTeam == chickenTeamID) then
    return false
  else
    return true
  end
end

function gadget:GameOver()
	if modes[highestLevel] ~= SURVIVAL then -- don't end game in survival mode
--		Spring.Echo("Set Gameover")
		gameOver=true
	end
end

if ((difficulty == 5) and (gracePeriod < 61) and (queenName=="ve_chickenq") and (burrowSpawnType=="avoid")) then queenName = "epic_chickenq" end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
else
-- END SYNCED
-- BEGIN UNSYNCED
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local Script = Script
local hasChickenEvent = false

local function HasChickenEvent(ce)
  hasChickenEvent = (ec ~= "0")
end

function WrapToLuaUI(_, type, num, tech)
  if hasChickenEvent then
    local chickenEventArgs = {}
    if type ~= nil then
      chickenEventArgs["type"] = type
    end
    if num ~= nil then
      chickenEventArgs["number"] = num
    end
    if tech ~= nil then
      chickenEventArgs["tech"] = tech
    end
    Script.LuaUI.ChickenEvent(chickenEventArgs)
  end
end

function gadget:Initialize()
  gadgetHandler:AddSyncAction('ChickenEvent', WrapToLuaUI)
  gadgetHandler:AddChatAction("HasChickenEvent", HasChickenEvent, "toggles hasChickenEvent setting")  
end

function gadget:Shutdown()
  gadgetHandler:RemoveChatAction("HasChickenEvent")
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
end
-- END UNSYNCED
--------------------------------------------------------------------------------

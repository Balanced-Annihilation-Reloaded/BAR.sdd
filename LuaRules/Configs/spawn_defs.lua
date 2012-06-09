--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
maxChicken           = tonumber(Spring.GetModOptions().mo_maxchicken) or 400
maxBurrows           = 20
gracePeriod          = tonumber(Spring.GetModOptions().mo_graceperiod) or 160  -- no chicken spawn in this period, seconds
queenTime            = (Spring.GetModOptions().mo_queentime or 40) * 60 -- time at which the queen appears, seconds
addQueenAnger        = tonumber(Spring.GetModOptions().mo_queenanger) or 1
burrowSpawnType      = Spring.GetModOptions().mo_chickenstart or "avoid"
spawnSquare          = 90       -- size of the chicken spawn square centered on the burrow
spawnSquareIncrement = 2         -- square size increase for each unit spawned
burrowName           = "roost"   -- burrow unit name
maxAge               = 300      -- chicken die at this age, seconds
queenName            = Spring.GetModOptions().mo_queendifficulty or "n_chickenq"
burrowDef            = UnitDefNames[burrowName].id
defenderChance       = 0.5       -- probability of spawning a single turret
maxTurrets           = 3   		 -- Max Turrets per burrow
queenSpawnMult       = 1         -- how many times bigger is a queen hatch than a normal burrow hatch
burrowSpawnRate      = 60
chickenSpawnRate     = 59
minBaseDistance      = 600      
maxBaseDistance      = 7200
chickensPerPlayer    = 8
spawnChance          = 0.5
bonusTurret          = "chickend1" -- Turret that gets spawned when a burrow dies
angerBonus           = 20
expStep              = 0.0625
lobberEMPTime        = 4
damageMod            = 1
waves                = {}


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function Copy(original)
  local copy = {} 
  for k, v in pairs(original) do
    if (type(v) == "table") then
      copy[k] = Copy(v)
    else
      copy[k] = v
    end
  end
  return copy
end

local function addWave(wave, unitList)
 if not waves[wave] then waves[wave] = {} end
 table.insert(waves[wave], unitList)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local chickenTypes = {
  ve_chickenq   =  true,
  e_chickenq    =  true,
  n_chickenq    =  true,
  h_chickenq    =  true,
  vh_chickenq   =  true,
  epic_chickenq =  true,
  chicken1      =  true,
  chicken1b     =  true,
  chicken1c     =  true,
  chicken1d     =  true,
  chicken2      =  true,
  chickena1     =  true,
  chickena1b     =  true,
  chickena1c     =  true,
  chickena2     =  true,
  chickens1     =  true,
  chickens2     =  true,
  chicken_dodo1 =  true,
  chicken_dodo2 =  true,
  chickenf1     =  true,
  chickenf2     =  true,
  chickenc1     =  true,
  chickenc2     =  true,
  chickenr1     =  true,
  chickenr2     =  true,
  chickenr3     =  true,
  chickenh1     =  true,
  chickenh1b    =  true,
  chickenh2     =  true,
  chickenh3     =  true,
  chickenh4     =  true,
  chickenw1     =  true,
  chickenw1b    =  true, 
  chickenw1c    =  true,
  chickenw1d    =  true,
  chickenp1     =  true,
}

local defenders = { 
  chickend1 = true,
}

addWave(1,{"1 chicken1", "1 chicken1b", "1 chicken1c", "1 chickenh1"})
addWave(1,{"1 chicken1", "1 chicken1b", "1 chicken1c", "1 chicken1d"})
addWave(1,{"1 chicken1", "1 chicken1b", "1 chicken1c", "1 chickenh1"})
addWave(1,{"1 chicken1", "1 chicken1b", "1 chicken1c", "1 chicken1d"})
addWave(1,{"3 chicken1"})
addWave(1,{"2 chicken1b", "1 chickenh1b"})
addWave(1,{"2 chicken1c", "1 chickena1"})

addWave(2,{"6 chicken1"})
addWave(2,{"5 chicken1b", "1 chickenf2"})
addWave(2,{"6 chicken1c"})
addWave(2,{"3 chicken1", "1 chickena1b", "1 chickenh1"})
addWave(2,{"1 chickena1", "1 chickena1c", "1 chickenw1b"})
addWave(2,{"1 chickena1b", "1 chickena1c", "1 chickenw1", "1 chickens1"})
addWave(2,{"4 chicken1d", "1 chickens1"})
addWave(2,{"4 chicken1", "1 chickena1"})
addWave(2,{"3 chicken1", "1 chickenh1", "1 chickenh1b"})

addWave(3,{"1 chickena1", "1 chickena1b", "1 chickens1"})
addWave(3,{"1 chickena1b", "1 chickena1c", "1 chickenh1", "1 chickenh1b"})
addWave(3,{"1 chickena1", "1 chickena1b", "1 chickena1c", "1 chickenf2"})
addWave(3,{"1 chickena1", "1 chickena1b", "1 chickena1c", "1 chickens1"})
addWave(3,{"6 chicken1", "1 chickenw1"})
addWave(3,{"3 chicken1b", "2 chickena1", "1 chickenh1"})
addWave(3,{"3 chicken1c", "1 chickens1", "1 chickenh1b"})
addWave(3,{"4 chicken1d", "1 chickenw1c"})
addWave(3,{"2 chickena1b", "1 chickenw1d"})
addWave(3,{"4 chicken1", "1 chickenh1", "1 chickenh1b"})

addWave(4,{"6 chicken1", "2 chickens1", "1 chicken_dodo1"})
addWave(4,{"6 chickens1", "1 chickenw1"})
addWave(4,{"5 chickens1", "1 chickena1b"})
addWave(4,{"4 chickens1", "1 chickena1", "1 chickenf2"})
addWave(4,{"3 chickens1", "1 chickena1c"})
addWave(4,{"3 chickens1", "1 chickenh1", "1 chickenh1b"})
addWave(4,{"1 chickena1", "1 chickena1b", "1 chickena1c", "1 chickenw1b"})
addWave(4,{"5 chicken1", "1 chicken_dodo1", "3 chickenh1"})
addWave(4,{"6 chicken1", "1 chickenw1c", "1 chickenw1d"})
addWave(4,{"3 chickens1", "1 chickenp1"})
addWave(4,{"2 chickenp1", "1 chicken_dodo1", "1 chickenh1b"})

addWave(5,{"1 chicken_dodo1", "3 chickenp1", "1 chickenf2"})
addWave(5,{"1 chicken_dodo1", "4 chickenp1"})
addWave(5,{"1 chicken_dodo1", "4 chickenp1"})
addWave(5,{"1 chicken_dodo1", "2 chickenp1", "1 chickenh1", "1 chickenh1b"})
addWave(5,{"1 chicken_dodo1", "2 chickenp1", "1 chickenw1b", "1 chickenf2", "1 chickenw1"})
addWave(5,{"2 chicken_dodo1", "1 chickenp1", "2 chickenc1"})
addWave(5,{"2 chicken_dodo1", "1 chickena1", "1 chickena1b", "3 chickena1c", "1 chickenw1"})
addWave(5,{"2 chicken_dodo1", "5 chickens1", "1 chickenw1c"})
addWave(5,{"2 chicken_dodo1", "3 chicken1d", "1 chickenf1", "3 chicken2"})
addWave(5,{"2 chicken_dodo1", "1 chickenp1", "1 chickenc1", "1 chickens1", "1 chickena1b", "1 chickenh1"})
addWave(5,{"3 chicken_dodo1", "5 chickenh1"})
addWave(5,{"4 chicken_dodo1", "1 chickenf1", "2 chickenw1d"})

addWave(6,{"2 chickenw1", "2 chickenw1b", "2 chickenw1c", "2 chickenw1d", "1 chicken2"})
addWave(6,{"1 chickenw1b", "1 chickenw1c", "1 chickenw1d", "1 chickena2", "1 chicken_dodo1", "1 chicken2"})
addWave(6,{"1 chickenw1", "3 chickenw1b", "1 chickenw1c", "1 chickenw1d", "2 chickena1", "1 chicken_dodo1", "1 chickenh1"})
addWave(6,{"1 chickenw1", "1 chickenw1b", "2 chickenw1c", "1 chickenw1d", "3 chickens1"})
addWave(6,{"1 chickenw1", "1 chickenw1b", "1 chickenw1c", "3 chickenw1d", "1 chickenp1", "1 chickenh1", "1 chickenh1b"})
addWave(6,{"1 chickenw1", "1 chickenw1b", "3 chickenw1c", "1 chickenw1d", "2 chickenp1", "1 chickens2"})
addWave(6,{"3 chickenw1", "1 chickenw1b", "1 chickenw1c", "1 chickenw1d", "2 chicken2"})
addWave(6,{"1 chickenf1", "3 chicken_dodo1", "2 chickenw1", "1 chicken2"})
addWave(6,{"1 chickenf1", "2 chickena1b", "3 chickenh1b"})
addWave(6,{"2 chickenf1", "1 chickenc1", "2 chickena1c"})
addWave(6,{"3 chickenf1", "4 chicken_dodo1", "1 chickenr1"})

addWave(7,{"2 chickenc1", "1 chickenw1", "1 chickenw1b", "1 chickenw1c", "1 chickenw1d"})
addWave(7,{"2 chickenc1", "1 chickenr1", "3 chicken_dodo1"})
addWave(7,{"2 chickenc1", "2 chickenf1", "1 chickenw1c", "1 chickenw1d"})
addWave(7,{"2 chickenc1", "1 chickenf1", "1 chickenw1", "1 chickenw1b"})
addWave(7,{"3 chickenc1", "4 chickenh1", "3 chickenf2"})
addWave(7,{"3 chickenc1", "1 chickena1", "2 chickena1b", "1 chickena1c", "1 chicken_dodo1"})
addWave(7,{"3 chickenc1", "4 chicken_dodo1"})
addWave(7,{"3 chickenc1", "1 chickens1", "1 chickens2","2 chickenp1", "2 chickenh1b"})
addWave(7,{"4 chickenc1", "1 chickenf1", "1 chicken_dodo1"})
addWave(7,{"4 chickenc1", "3 chicken_dodo1", "1 chickenh2"})
addWave(7,{"2 chickena1", "1 chickena1b", "1 chickena1c", "1 chickena2", "1 chickenr1", "3 chickenf2"})
addWave(7,{"3 chickens1", "2 chickens2", "1 chickenr1"})
addWave(7,{"5 chickenp1", "2 chickenh1", "2 chickenh1b"})
addWave(7,{"9 chicken2", "1 chicken_dodo2"})

addWave(8,{"3 chickenf1", "1 chicken_dodo1", "1 chickena2", "1 chickenh1", "1 chickenw1b", "1 chicken2"})
addWave(8,{"1 chickenr1", "2 chickenf1", "2 chicken_dodo1", "1 chickenh1b", "1 chicken2"})
addWave(8,{"2 chickenf1", "3 chicken_dodo1", "1 chickena2", "1 chickenh1", "1 chickenh2"})
addWave(8,{"1 chickenr1", "3 chickenc1", "1 chickenh1b", "1 chicken2"})
addWave(8,{"3 chickenc1", "1 chicken_dodo2", "1 chickens2", "1 chickenh1", "1 chickenw1d", "1 chicken2"})
addWave(8,{"2 chickenr1", "3 chickenc1", "1 chickenh1b", "1 chicken2"})
addWave(8,{"1 chickenw1", "2 chickenw1b", "2 chickenw1c", "1 chickenw1d", "2 chicken_dodo1", "1 chickens2", "1 chickenh1", "1 chicken2"})
addWave(8,{"1 chickenr1", "6 chickenp1", "4 chickenh1b", "1 chicken2"})
addWave(8,{"2 chickena1", "2 chickena1b", "2 chickena1c", "4 chickenh1", "1 chickenh1", "1 chickenw1", "1 chicken2"})
addWave(8,{"1 chickenr1", "1 chickens2", "4 chickenh1b", "1 chicken2", "1 chickenh2"})
addWave(8,{"6 chicken2", "2 chickenh1", "1 chickenh1", "1 chickenw1c", "1 chickenf2"})

addWave(9,{"3 chickenh1","2 chickenh1b","1 chickenh2","2 chickenh3", "1 chickenc2"})
addWave(9,{"2 chickenh1","3 chickenh1b","1 chickenh2","2 chickenh3", "1 chickenc2"})
addWave(9,{"2 chickenh1","2 chickenh1b","1 chickenh2","2 chickenh3", "1 chickenc2"})
addWave(9,{"2 chickenh1","2 chickenh1b","1 chickenh2","2 chickenh3", "1 chickens2"})
addWave(9,{"2 chickenh1","2 chickenh1b","1 chickenh2","2 chickenh3", "1 chickens2"})
addWave(9,{"2 chickenh1","2 chickenh1b","1 chickenh2","2 chickenh3", "1 chickens2"})
addWave(9,{"3 chickenc2"})
addWave(9,{"3 chickenw1","3 chickenw1b", "3 chickenw1c", "3 chickenw1d"})
addWave(9,{"3 chickens2"})
addWave(9,{"1 chickena2"})

VERYEASY = "Chicken: Very Easy"
EASY = "Chicken: Easy"
NORMAL = "Chicken: Normal"
HARD = "Chicken: Hard"
VERYHARD = "Chicken: Very Hard"
CUSTOM = "Chicken: Custom"
SURVIVAL = "Chicken: Survival"

difficulties = {
  [VERYEASY] = {
    chickenSpawnRate  = 100, 
    burrowSpawnRate   = 120,
    queenSpawnMult    = 0,
    angerBonus        = 20,
    expStep           = 0,
    lobberEMPTime     = 0,
    chickenTypes      = Copy(chickenTypes),
    defenders         = Copy(defenders),
    chickensPerPlayer = 5,
    spawnChance       = 0.25,
    damageMod         = 0.6,
  },
  [EASY] = {
    chickenSpawnRate  = 100, 
    burrowSpawnRate   = 120,
    queenSpawnMult    = 0,
    angerBonus        = 20,
    expStep           = 0.09375,
    lobberEMPTime     = 2.5,
    chickenTypes      = Copy(chickenTypes),
    defenders         = Copy(defenders),
    chickensPerPlayer = 7,
    spawnChance       = 0.33,
    damageMod         = 0.75,
  },

  [NORMAL] = {
    chickenSpawnRate  = 80,
    burrowSpawnRate   = 105,
    queenSpawnMult    = 1,
    angerBonus        = 25,
    expStep           = 0.125,
    lobberEMPTime     = 4,
    chickenTypes      = Copy(chickenTypes),
    defenders         = Copy(defenders),
    chickensPerPlayer = 9,
    spawnChance       = 0.4,
    damageMod         = 1,
  },

  [HARD] = {
    chickenSpawnRate  = 70,
    burrowSpawnRate   = 60,
    queenSpawnMult    = 1,
    angerBonus        = 30,
    expStep           = 0.25,
    lobberEMPTime     = 5,
    chickenTypes      = Copy(chickenTypes),
    defenders         = Copy(defenders),
    chickensPerPlayer = 14,
    spawnChance       = 0.5,
    damageMod         = 1.1,
  },


  [VERYHARD] = {
    chickenSpawnRate  = 45,
    burrowSpawnRate   = 40,
    queenSpawnMult    = 3,
    angerBonus        = 30,
    expStep           = 0.4,
    lobberEMPTime     = 7.5,
    chickenTypes      = Copy(chickenTypes),
    defenders         = Copy(defenders),
    chickensPerPlayer = 18,
    spawnChance       = 0.6,
    damageMod         = 1.25,
  },

  [CUSTOM] = {
    chickenSpawnRate  = tonumber(Spring.GetModOptions().mo_custom_chickenspawn),
    burrowSpawnRate   = tonumber(Spring.GetModOptions().mo_custom_burrowspawn),
    queenSpawnMult    = tonumber(Spring.GetModOptions().mo_custom_queenspawnmult),
    angerBonus        = tonumber(Spring.GetModOptions().mo_custom_angerbonus),
    expStep           = (tonumber(Spring.GetModOptions().mo_custom_expstep) or 0.6) * -1,
    lobberEMPTime     = tonumber(Spring.GetModOptions().mo_custom_lobberemp),
    chickenTypes      = Copy(chickenTypes),
    defenders         = Copy(defenders),
    chickensPerPlayer = tonumber(Spring.GetModOptions().mo_custom_minchicken),
    spawnChance       = (tonumber(Spring.GetModOptions().mo_custom_spawnchance) or 50) / 100,
    damageMod         = (tonumber(Spring.GetModOptions().mo_custom_damagemod) or 100) / 100,
  },

  [SURVIVAL] = {
    chickenSpawnRate    = 80,
    burrowSpawnRate     = 105,
    queenSpawnMult      = 1,
    angerBonus          = 25,
    expStep             = 0.125,
    lobberEMPTime       = 4,
    chickenTypes        = Copy(chickenTypes),
    defenders           = Copy(defenders),
    chickensPerPlayer   = 9,
    spawnChance         = 0.4,
    damageMod           = 1,
  },
}



defaultDifficulty = 'Chicken: Custom'

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

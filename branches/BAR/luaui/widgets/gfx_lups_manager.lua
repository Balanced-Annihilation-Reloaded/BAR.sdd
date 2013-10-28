--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  author:  jK
--
--  Copyright (C) 2007,2008.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "LupsManager",
    desc      = "",
    author    = "jK",
    date      = "Feb, 2008",
    license   = "GNU GPL, v2 or later",
    layer     = 10,
    enabled   = true,
    handler   = true,
  }
end


include("Configs/lupsFXs.lua")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function MergeTable(table1,table2)
  local result = {}
  for i,v in pairs(table2) do 
    if (type(v)=='table') then
      result[i] = MergeTable(v,{})
    else
      result[i] = v
    end
  end
  for i,v in pairs(table1) do 
    if (result[i]==nil) then
      if (type(v)=='table') then
        if (type(result[i])~='table') then result[i] = {} end
        result[i] = MergeTable(v,result[i])
      else
        result[i] = v
      end
    end
  end
  return result
end


local function blendColor(c1,c2,mix)
  if (mix>1) then mix=1 end
  local mixInv = 1-mix
  return {
    c1[1]*mixInv + c2[1]*mix,
    c1[2]*mixInv + c2[2]*mix,
    c1[3]*mixInv + c2[3]*mix,
    (c1[4] or 1)*mixInv + (c2[4] or 1)*mix
  }
end


local function blend(a,b,mix)
  if (mix>1) then mix=1 end
  return a*(1-mix) + b*mix
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local UnitEffects = {

  [UnitDefNames["cjuno"].id] = {
    {class='ShieldSphere',options=cjunoShieldSphere},
    {class='GroundFlash',options=groundFlashJuno},
  },
  [UnitDefNames["ajuno"].id] = {
    {class='ShieldSphere',options=cjunoShieldSphere},
    {class='GroundFlash',options=groundFlashJuno},
  },
  [UnitDefNames["cormakr"].id] = {
    {class='StaticParticles',options=cormakrEffect},
  },
  [UnitDefNames["corfmkr"].id] = {
    {class='StaticParticles',options=cormakrEffect},
  },
  
  --// FUSIONS //--------------------------
  [UnitDefNames["cafus"].id] = {
    --{class='Bursts',options=cafusBursts},
    {class='ShieldSphere',options=cafusShieldSphere},
    {class='ShieldJitter',options={layer=-16, life=math.huge, pos={0,60,0}, size=33, precision=22, repeatEffect=true}},
    {class='GroundFlash',options=groundFlashBlue},
  },
  [UnitDefNames["corfus"].id] = {
   -- {class='Bursts',options=corfusBursts},
    {class='ShieldSphere',options=corfusShieldSphere},
    {class='ShieldJitter',options={life=math.huge, pos={0,50,0}, size=32, precision=22, repeatEffect=true}},
    {class='GroundFlash',options=groundFlashGreen},
  },
  [UnitDefNames["aafus"].id] = {
  
  --TOO EXPENSIVE:
   --{class='SimpleParticles2', options=MergeTable(sparks,{pos={-36,82,-36}, delay=10, lifeSpread=30, partpos="0,0,0"})},
    --{class='SimpleParticles2', options=MergeTable(sparks,{pos={36,82,-36}, delay=60, lifeSpread=30, partpos="0,0,0"})},
    --{class='SimpleParticles2', options=MergeTable(sparks,{pos={36,82,36}, delay=30, lifeSpread=30, partpos="0,0,0"})},
   --{class='SimpleParticles2', options=MergeTable(sparks,{pos={-36,82,36}, delay=90, lifeSpread=30, partpos="0,0,0"})},

	--{class='Sphere', options=MergeTable(aafusGlowBallWhite,{pos={31.2,32.7,0}})},
	--{class='Sphere', options=MergeTable(aafusGlowBallWhite,{pos={-31.2,32.7,0}})},
	--{class='Sphere', options=MergeTable(aafusGlowBallWhite,{pos={0,32.7,31.2}})},
	--{class='Sphere', options=MergeTable(aafusGlowBallWhite,{pos={0,32.7,-31.2}})},

	--{class='Sphere', options=MergeTable(aafusGlowBallTeal,{pos={28.2,36,28.2}})},
	--{class='Sphere', options=MergeTable(aafusGlowBallTeal,{pos={-28.2,36,28.2}})},
	--{class='Sphere', options=MergeTable(aafusGlowBallTeal,{pos={-28.2,36,-28.2}})},
	--{class='Sphere', options=MergeTable(aafusGlowBallTeal,{pos={28.2,36,-28.2}})},

   -- {class='Bursts', options={pos={0,76,0}, size=35, sizeSpread=2, colormap={{1.0,0.2,0.2,0.4}}, life=20, arc=90, rotSpeed=0.7, rotSpread=1, count=43, directional=true, repeatEffect=true}},
	{class='ShieldSphere', options={pos={0,76,0}, size=26, colormap1={ {1.0,0.0,0.0,0.5} }, colormap2={ {1.0,0.3,0.3,0.8},{1.0,0.0,0.0,0.5},{1.0,0.3,0.3,0.8} }, life=20, repeatEffect=true}},
    {class='ShieldJitter', options={layer=-16, life=20, pos={0,76,0}, size=29.7, precision=22, repeatEffect=true}},
  },
  [UnitDefNames["corgate"].id] = {
    --{class='Bursts',options=corgateBursts},
    {class='ShieldSphere',options=corgateShieldSphere},
    {class='ShieldJitter',options={life=math.huge, pos={0,42,0}, size=20, precision=2, repeatEffect=true}},
    {class='GroundFlash',options=groundFlashGreen},
  },    
  [UnitDefNames["armgate"].id] = {
    --{class='Bursts',options=armgateBursts},
    {class='ShieldSphere',options=armgateShieldSphere},
    {class='ShieldJitter',options={life=math.huge, pos={0,20,-5}, size=20, precision=2, repeatEffect=true}},
    {class='GroundFlash',options=groundFlashGreen},
  },    
  [UnitDefNames["cjuno"].id] = {
    {class='ShieldSphere',options=cjunoShieldSphere},
    {class='ShieldJitter',options={life=math.huge, pos={0,72,0}, size=20, precision=22, repeatEffect=true}},
  },

    --// ENERGY STORAGE //--------------------
  [UnitDefNames["corestor"].id] = {
    {class='GroundFlash',options=groundFlashCorestor},
  },
  [UnitDefNames["armestor"].id] = {
    {class='GroundFlash',options=groundFlashArmestor},
  },

  --// PLANES still need to do work here //----------------------------
  [UnitDefNames["armatlas"].id] = {
    {class='AirJet',options={color={0.1,0.4,0.6}, width=7, length=30, piece="thrust", onActive=true}},
  },
  [UnitDefNames["armpeep"].id] = {
    {class='AirJet',options={color={0.1,0.4,0.6}, width=5, length=30, piece="jet1", onActive=true}},
    {class='AirJet',options={color={0.1,0.4,0.6}, width=5, length=30, piece="jet2", onActive=true}},
  },
  [UnitDefNames["armca"].id] = {
    {class='AirJet',options={color={0.1,0.4,0.6}, width=8, length=30, piece="thrust", onActive=true}},
  },
  [UnitDefNames["armaca"].id] = {
    {class='AirJet',options={color={0.1,0.4,0.6}, width=8, length=30, piece="thrust", onActive=true}},
  },
  [UnitDefNames["armcsa"].id] = {
    {class='AirJet',options={color={0.1,0.4,0.6}, width=8, length=30, piece="thrusta", onActive=true}},
    {class='AirJet',options={color={0.1,0.4,0.6}, width=6, length=20, piece="thrustb", onActive=true}},
  },
  [UnitDefNames["armfig"].id] = {
    {class='AirJet',options={color={0.1,0.4,0.6}, width=6, length=45, piece="thrust", onActive=true}},
  },
  [UnitDefNames["armsfig"].id] = {
    {class='AirJet',options={color={0.1,0.4,0.6}, width=4, length=25, piece="thrust", onActive=true}},
  },
  [UnitDefNames["armseap"].id] = {
    {class='AirJet',options={color={0.1,0.4,0.6}, width=6, length=45, piece="thrust", onActive=true}},
  },
  [UnitDefNames["armhawk"].id] = {
    {class='AirJet',options={color={0.1,0.4,0.6}, width=6, length=45, piece="thrust", onActive=true}},
  },
  [UnitDefNames["corfink"].id] = {
    {class='AirJet',options={color={0.3,0.1,0}, width=3, length=35, piece="thrustb", onActive=true}},
  },
  [UnitDefNames["cortitan"].id] = {
    {class='AirJet',options={color={0.3,0.1,0}, width=5, length=65, piece="thrustb", onActive=true}},
  },
  [UnitDefNames["armlance"].id] = {
   {class='AirJet',options={color={0.1,0.4,0.6}, width=5, length=65, piece="thrust1", onActive=true}},
   {class='AirJet',options={color={0.1,0.4,0.6}, width=5, length=65, piece="thrust2", onActive=true}},
  },
  [UnitDefNames["corveng"].id] = {
    {class='AirJet',options={color={0.3,0.1,0}, width=3, length=24, piece="thrust1", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=3, length=24, piece="thrust2", onActive=true}},
  },
  [UnitDefNames["corsfig"].id] = {
    {class='AirJet',options={color={0.3,0.1,0}, width=3, length=42, piece="thrust", onActive=true}},
  },
  [UnitDefNames["corseap"].id] = {
    {class='AirJet',options={color={0.3,0.1,0}, width=3, length=42, piece="thrust", onActive=true}},
  },
  [UnitDefNames["corshad"].id] = {
    {class='AirJet',options={color={0.1,0.4,0}, width=3, length=27, piece="thrusta1", onActive=true}},
    {class='AirJet',options={color={0.1,0.4,0}, width=3, length=27, piece="thrusta2", onActive=true}},
    {class='AirJet',options={color={0.1,0.4,0}, width=6, length=40, piece="thrustb1", onActive=true}},
    {class='AirJet',options={color={0.1,0.4,0}, width=6, length=40, piece="thrustb2", onActive=true}},
  },

  [UnitDefNames["armkam"].id] = {
    {class='ThundAirJet',options={color={0.1,0.4,0.6}, width=2, length=47, piece="thrusta", onActive=true}},
    {class='ThundAirJet',options={color={0.1,0.4,0.6}, width=2, length=47, piece="thrustb", onActive=true}},
  },
  [UnitDefNames["armthund"].id] = {
    {class='ThundAirJet',options={color={0.1,0.4,0.6}, width=2, length=47, piece="thrust1", onActive=true}},
    {class='ThundAirJet',options={color={0.1,0.4,0.6}, width=2, length=47, piece="thrust2", onActive=true}},
    {class='ThundAirJet',options={color={0.1,0.4,0.6}, width=2, length=47, piece="thrust3", onActive=true}},
    {class='ThundAirJet',options={color={0.1,0.4,0.6}, width=2, length=47, piece="thrust4", onActive=true}},
    {class='ThundAirJet',options={color={0.1,0.4,0.6}, width=5, length=60, piece="thrustc", onActive=true}},
  },
  [UnitDefNames["corhurc"].id] = {
    {class='AirJet',options={color={0.9,0.3,0}, width=10, length=80, piece="thrustb", onActive=true}},
    {class='AirJet',options={color={0.9,0.3,0}, width=6, length=60, piece="thrusta1", onActive=true}},
    {class='AirJet',options={color={0.9,0.3,0}, width=6, length=60, piece="thrusta2", onActive=true}},
  },
  [UnitDefNames["armpnix"].id] = {
    {class='AirJet',options={color={0.1,0.4,0.6}, width=8, length=75, piece="thrusta", onActive=true}},
    {class='AirJet',options={color={0.1,0.4,0.6}, width=8, length=75, piece="thrustb", onActive=true}},
  },
  [UnitDefNames["corvamp"].id] = {
    {class='AirJet',options={color={0.6,0.1,0}, width=3.5, length=65, piece="thrusta", onActive=true}},
  },
  [UnitDefNames["corawac"].id] = {
    {class='AirJet',options={color={0.8,0.2,0}, width=4, length=50, piece="thrust", onActive=true}},
  },
  [UnitDefNames["corhunt"].id] = {
    {class='AirJet',options={color={0.8,0.2,0}, width=4, length=50, piece="thrust", onActive=true}},
  },
  [UnitDefNames["armawac"].id] = {
    {class='AirJet',options={color={0.1,0.4,0.6}, width=3.5, length=50, piece="thrust", onActive=true}},
  },
  [UnitDefNames["armsehak"].id] = {
    {class='AirJet',options={color={0.1,0.4,0.6}, width=3.5, length=50, piece="thrust", onActive=true}},
  },
  [UnitDefNames["armcybr"].id] = {
    {class='AirJet',options={color={0.1,0.4,0.6}, width=3.5, length=60, piece="thrusta", onActive=true}},
    {class='AirJet',options={color={0.1,0.4,0.6}, width=3.5, length=60, piece="thrustb", onActive=true}},
  },
  [UnitDefNames["armdfly"].id] = {
    {class='AirJet',options={color={0.1,0.4,0.6}, width=3.5, length=60, piece="thrusta", onActive=true}},
    {class='AirJet',options={color={0.1,0.4,0.6}, width=3.5, length=60, piece="thrustb", onActive=true}},
  },
  [UnitDefNames["corsb"].id] = {
    {class='AirJet',options={color={0.6,0.1,0}, width=3.5, length=76, piece="thrusta", onActive=true}},
    {class='AirJet',options={color={0.6,0.1,0}, width=3.5, length=76, piece="thrustb", onActive=true}},
  },
  [UnitDefNames["armsb"].id] = {
    {class='AirJet',options={color={0.1,0.4,0.6}, width=4.7, length=70, piece="thrustc", onActive=true}},
    {class='AirJet',options={color={0.1,0.4,0.6}, width=2.7, length=25, piece="thrusta", onActive=true}},
    {class='AirJet',options={color={0.1,0.4,0.6}, width=2.7, length=25, piece="thrustb", onActive=true}},
  },
  [UnitDefNames["corgripn"].id] = {
    {class='AirJet',options={color={0.1,0.4,0.6}, width=3.7, length=60, piece="thrusta", onActive=true}},
    {class='AirJet',options={color={0.1,0.4,0.6}, width=3.7, length=60, piece="thrustb", onActive=true}},
  },
  [UnitDefNames["blade"].id] = {
    {class='AirJet',options={color={0.1,0.4,0.6}, width=3.7, length=28, piece="thrust", onActive=true}},
  },
  [UnitDefNames["armbrawl"].id] = {
    {class='AirJet',options={color={0.1,0.4,0.6}, width=3.7, length=15, piece="thrust1", onActive=true}},
    {class='AirJet',options={color={0.1,0.4,0.6}, width=3.7, length=15, piece="thrust2", onActive=true}},
  },
  [UnitDefNames["corape"].id] = {
    {class='AirJet',options={color={0.7,0.4,0.1}, width=8, length=28, piece="thrust1b", emitVector= {0,1,0}, onActive=true}},
    {class='AirJet',options={color={0.7,0.4,0.1}, width=8, length=28, piece="thrust2b", emitVector= {0,1,0}, onActive=true}},
  },
  [UnitDefNames["corcrw"].id] = {
    {class='AirJet',options={color={0.7,0.4,0.1}, width=16, length=28, piece="thrustrra", emitVector= {0,1,0},onActive=true}},
    {class='AirJet',options={color={0.7,0.4,0.1}, width=16, length=28, piece="thrustrla", emitVector= {0,1,0}, onActive=true}},
    {class='AirJet',options={color={0.7,0.4,0.1}, width=12, length=28, piece="thrustfra", emitVector= {0,1,0}, onActive=true}},
    {class='AirJet',options={color={0.7,0.4,0.1}, width=12, length=28, piece="thrustfla", emitVector= {0,1,0}, onActive=true}},
  },
  [UnitDefNames["armsl"].id] = {
    {class='AirJet',options={color={0.7,0.4,0.1}, width=16, length=28, piece="thrustrra", emitVector= {0,1,0},onActive=true}},
    {class='AirJet',options={color={0.7,0.4,0.1}, width=16, length=28, piece="thrustrla", emitVector= {0,1,0}, onActive=true}},
    {class='AirJet',options={color={0.7,0.4,0.1}, width=12, length=28, piece="thrustfra", emitVector= {0,1,0}, onActive=true}},
    {class='AirJet',options={color={0.7,0.4,0.1}, width=12, length=28, piece="thrustfla", emitVector= {0,1,0}, onActive=true}},
  },
  [UnitDefNames["corvalk"].id] = {
    {class='AirJet',options={color={0.7,0.4,0.1}, width=8, length=16, piece="thrust1", emitVector= {0,1,0},onActive=true}},
    {class='AirJet',options={color={0.7,0.4,0.1}, width=8, length=16, piece="thrust3", emitVector= {0,1,0}, onActive=true}},
    {class='AirJet',options={color={0.7,0.4,0.1}, width=8, length=16, piece="thrust2", emitVector= {0,1,0}, onActive=true}},
    {class='AirJet',options={color={0.7,0.4,0.1}, width=8, length=16, piece="thrust4", emitVector= {0,1,0}, onActive=true}},
  },
  [UnitDefNames["cortitan"].id] = {
    {class='AirJet',options={color={0.9,0.3,0}, width=10, length=52, piece="thrustb", onActive=true}},
    {class='AirJet',options={color={0.9,0.3,0}, width=6, length=35, piece="thrusta1", onActive=true}},
    {class='AirJet',options={color={0.9,0.3,0}, width=6, length=35, piece="thrusta2", onActive=true}},
  },

}

local t = os.date('*t')
if (t.yday>350) then --(t.month==12)
  UnitEffects[UnitDefNames["armcom"].id] = {
    {class='SantaHat',options={color={1,0.1,0,1}, pos={0,4,0.35}, emitVector={0.3,1,0.2}, width=2.7, height=6, ballSize=0.7, piecenum=8, piece="head"}},
  }
  UnitEffects[UnitDefNames["armdecom"].id] = {
    {class='SantaHat',options={color={1,0.1,0,1}, pos={0,4,0.35}, emitVector={0.3,1,0.2}, width=2.7, height=6, ballSize=0.7, piecenum=8, piece="head"}},
  }
  UnitEffects[UnitDefNames["corcom"].id] = {
    {class='SantaHat',options={color={1,0.1,0,1}, pos={0,0,0.35}, emitVector={0.3,1,0.2}, width=2.7, height=6, ballSize=0.7, piecenum=16, piece="head"}},
  }
  UnitEffects[UnitDefNames["cordecom"].id] = {
    {class='SantaHat',options={color={1,0.1,0,1}, pos={0,0,0.35}, emitVector={0.3,1,0.2}, width=2.7, height=6, ballSize=0.7, piecenum=16, piece="head"}},
  }
end

local abs = math.abs
local spGetSpectatingState = Spring.GetSpectatingState
local spGetUnitDefID       = Spring.GetUnitDefID
local spGetUnitRulesParam  = Spring.GetUnitRulesParam
local spGetUnitIsActive    = Spring.GetUnitIsActive

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local Lups  -- Lua Particle System
local LupsAddFX
local particleIDs = {}
local initialized = false --// if LUPS isn't started yet, we try it once a gameframe later
local tryloading  = 1     --// try to activate lups if it isn't found

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function ClearFxs(unitID)
  if (particleIDs[unitID]) then
    for _,fxID in ipairs(particleIDs[unitID]) do
      Lups.RemoveParticles(fxID)
    end
    particleIDs[unitID] = nil
  end
end

local function ClearFx(unitID, fxIDtoDel)
  if (particleIDs[unitID]) then
	local newTable = {}
	for _,fxID in ipairs(particleIDs[unitID]) do
		if fxID == fxIDtoDel then 
			Lups.RemoveParticles(fxID)
		else 
			newTable[#newTable+1] = fxID
		end
    end
	if #newTable == 0 then 
		particleIDs[unitID] = nil
	else 
		particleIDs[unitID] = newTable
	end
  end
end

local function AddFxs(unitID,fxID)
  if (not particleIDs[unitID]) then
    particleIDs[unitID] = {}
  end

  local unitFXs = particleIDs[unitID]
  unitFXs[#unitFXs+1] = fxID
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function UnitFinished(_,unitID,unitDefID)

  local effects = UnitEffects[unitDefID]
  if (effects) then
    for _,fx in ipairs(effects) do
      if (not fx.options) then
        Spring.Echo("LUPS DEBUG ", UnitDefs[unitDefID].name, fx and fx.class)
        return
      end

      if (fx.class=="GroundFlash") then
        fx.options.pos = { Spring.GetUnitBasePosition(unitID) }
      end
      fx.options.unit = unitID
      AddFxs( unitID,LupsAddFX(fx.class,fx.options) )
      fx.options.unit = nil
    end
  end
end

local function UnitDestroyed(_,unitID,unitDefID)
  ClearFxs(unitID)
end


local function UnitEnteredLos(_,unitID)
  local spec, fullSpec = spGetSpectatingState()
  if (spec and fullSpec) then return end
    
  local unitDefID = spGetUnitDefID(unitID)
  local effects   = UnitEffects[unitDefID]
  if (effects) then
	for _,fx in ipairs(effects) do
	  if (fx.options.onActive == true) and (spGetUnitIsActive(unitID) == nil) then
		--rewrite this part to allow onactive effect for enemy units
		break
	  else
		if (fx.class=="GroundFlash") then
		  fx.options.pos = { Spring.GetUnitBasePosition(unitID) }
		end
		fx.options.unit = unitID
		fx.options.under_construction = spGetUnitRulesParam(unitID, "under_construction")
		--can a unit that is under construction be active? 
		AddFxs( unitID,LupsAddFX(fx.class,fx.options) )
		fx.options.unit = nil
	  end
	end
  end
  
end


local function UnitLeftLos(_,unitID)
  local spec, fullSpec = spGetSpectatingState()
  if (spec and fullSpec) then return end

  ClearFxs(unitID)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function PlayerChanged(_,playerID)
  if (playerID == Spring.GetMyPlayerID()) then
    --// clear all FXs
    for _,unitFxIDs in pairs(particleIDs) do
      for _,fxID in ipairs(unitFxIDs) do
        Lups.RemoveParticles(fxID)
      end
    end
    particleIDs = {}

    widgetHandler:UpdateWidgetCallIn("Update",widget)
  end
end

local function CheckForExistingUnits()
  --// initialize effects for existing units
  local allUnits = Spring.GetAllUnits();
  for i=1,#allUnits do
    local unitID    = allUnits[i]
    local unitDefID = Spring.GetUnitDefID(unitID)
    if (spGetUnitRulesParam(unitID, "under_construction") ~= 1) then
		UnitFinished(nil,unitID,unitDefID)
	end
  end

  widgetHandler:RemoveWidgetCallIn("Update",widget)
end

function widget:GameFrame()
  if (Spring.GetGameFrame() > 0) then
    Spring.SendLuaRulesMsg("lups running","allies")
    widgetHandler:RemoveWidgetCallIn("GameFrame",widget)
  end
end

function widget:Update()
  Lups = WG['Lups']
  local LupsWidget = widgetHandler.knownWidgets['Lups'] or {}

  --// Lups running?
  if (not initialized) then
    if (Lups and LupsWidget.active) then
      if (tryloading==-1) then
        Spring.Echo("LuaParticleSystem (Lups) activated.")
      end
      initialized=true
      return
    else
      if (tryloading==1) then
        Spring.Echo("Lups not found! Trying to activate it.")
        widgetHandler:EnableWidget("Lups")
        tryloading=-1
        return
      else
        Spring.Echo("LuaParticleSystem (Lups) couldn't be loaded!")
        widgetHandler:RemoveWidgetCallIn("Update",self)
        return
      end
    end
  end

  LupsAddFX = Lups.AddParticles

  Spring.SendLuaRulesMsg("lups running","allies")

  widget.UnitFinished   = UnitFinished
  widget.UnitDestroyed  = UnitDestroyed
  widget.UnitEnteredLos = UnitEnteredLos
  widget.UnitLeftLos    = UnitLeftLos
  widget.GameFrame      = GameFrame
  widget.PlayerChanged  = PlayerChanged
  widgetHandler:UpdateWidgetCallIn("UnitFinished",widget)
  widgetHandler:UpdateWidgetCallIn("UnitDestroyed",widget)
  widgetHandler:UpdateWidgetCallIn("UnitEnteredLos",widget)
  widgetHandler:UpdateWidgetCallIn("UnitLeftLos",widget)
  widgetHandler:UpdateWidgetCallIn("GameFrame",widget)
  widgetHandler:UpdateWidgetCallIn("PlayerChanged",widget)

  widget.Update = CheckForExistingUnits
  widgetHandler:UpdateWidgetCallIn("Update",widget)
end

function widget:Shutdown()
  if (initialized) then
    for _,unitFxIDs in pairs(particleIDs) do
      for _,fxID in ipairs(unitFxIDs) do
        Lups.RemoveParticles(fxID)
      end
    end
    particleIDs = {}
  end

  Spring.SendLuaRulesMsg("lups shutdown","allies")
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
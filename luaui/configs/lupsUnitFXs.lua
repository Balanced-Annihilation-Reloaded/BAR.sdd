-- note that the order of the MergeTable args matters for nested tables (such as colormaps)!

local presets = {
    }

effectUnitDefs = {

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
    {class='ShieldSphere',options=cafusShieldSphere},
    {class='ShieldJitter',options={layer=-16, life=math.huge, pos={0,60,0}, size=33, precision=22, repeatEffect=true}},
    {class='GroundFlash',options=groundFlashBlue},
  },
  [UnitDefNames["corfus"].id] = {
    {class='ShieldSphere',options=corfusShieldSphere},
    {class='ShieldJitter',options={life=math.huge, pos={0,50,0}, size=32, precision=22, repeatEffect=true}},
    {class='GroundFlash',options=groundFlashGreen},
  },
  [UnitDefNames["aafus"].id] = {
    {class='SimpleParticles2', options=MergeTable({pos={0,76,0}, delay=0, lifeSpread=30},plasmaball_aafus)},
    {class='SimpleParticles2', options=MergeTable({pos={0,76,0}, delay=40, lifeSpread=30},plasmaball_aafus)},
    {class='ShieldJitter',options={layer=-16, life=math.huge, pos={0,76,0}, size=30, precision=22, repeatEffect=true}},
    {class='GroundFlash',options=groundFlashBlue},
  },
  [UnitDefNames["corgate"].id] = {
    {class='ShieldSphere',options=corgateShieldSphere},
    {class='SimpleParticles2', options=MergeTable({pos={0,42,0}, lifeSpread=300},shield_corgate)},
    --{class='ShieldJitter',options={life=math.huge, pos={0,42,0}, size=20, precision=2, repeatEffect=true}},
    {class='GroundFlash',options=groundFlashGreen},
  },    
  [UnitDefNames["armgate"].id] = {
    {class='ShieldSphere',options=armgateShieldSphere},
    {class='SimpleParticles2', options=MergeTable({pos={0,25,-5}, lifeSpread=300},shield_armgate)},
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
  
  --T1 ARM 
  [UnitDefNames["armatlas"].id] = {
    {class='AirJet',options={color={0.7,0.4,0.1}, width=7, length=30, piece="thrust", onActive=true}},
  },
  [UnitDefNames["armkam"].id] = {
    {class='ThundAirJet',options={color={0.7,0.4,0.1}, width=4, length=47, piece="thrusta", onActive=true}},
    {class='ThundAirJet',options={color={0.7,0.4,0.1}, width=4, length=47, piece="thrustb", onActive=true}},
  },
  [UnitDefNames["armthund"].id] = {
    {class='ThundAirJet',options={color={0.7,0.4,0.1}, width=2, length=47, piece="thrust1", onActive=true}},
    {class='ThundAirJet',options={color={0.7,0.4,0.1}, width=2, length=47, piece="thrust2", onActive=true}},
    {class='ThundAirJet',options={color={0.7,0.4,0.1}, width=2, length=47, piece="thrust3", onActive=true}},
    {class='ThundAirJet',options={color={0.7,0.4,0.1}, width=2, length=47, piece="thrust4", onActive=true}},
    {class='ThundAirJet',options={color={0.7,0.4,0.1}, width=5, length=60, piece="thrustc", onActive=true}},
  },
  [UnitDefNames["armpeep"].id] = {
    {class='AirJet',options={color={0.7,0.4,0.1}, width=5, length=30, piece="jet1", onActive=true}},
    {class='AirJet',options={color={0.7,0.4,0.1}, width=5, length=30, piece="jet2", onActive=true}},
  },
  [UnitDefNames["armfig"].id] = {
    {class='AirJet',options={color={0.7,0.4,0.1}, width=6, length=45, piece="thrust", onActive=true}},
  },
  [UnitDefNames["armca"].id] = {
    {class='AirJet',options={color={0.7,0.4,0.1}, width=8, length=30, piece="thrust", onActive=true}},
  },
  
  --T1 CORE
  [UnitDefNames["corshad"].id] = {
    {class='AirJet',options={color={0.7,0.4,0.1}, width=3, length=27, piece="thrusta1", onActive=true}},
    {class='AirJet',options={color={0.7,0.4,0.1}, width=3, length=27, piece="thrusta2", onActive=true}},
    {class='AirJet',options={color={0.7,0.4,0.1}, width=6, length=40, piece="thrustb1", onActive=true}},
    {class='AirJet',options={color={0.7,0.4,0.1}, width=6, length=40, piece="thrustb2", onActive=true}},
  },
  [UnitDefNames["corvalk"].id] = {
    {class='AirJet',options={color={0.7,0.4,0.1}, width=8, length=16, piece="thrust1", emitVector= {0,1,0},onActive=true}},
    {class='AirJet',options={color={0.7,0.4,0.1}, width=8, length=16, piece="thrust3", emitVector= {0,1,0}, onActive=true}},
    {class='AirJet',options={color={0.7,0.4,0.1}, width=8, length=16, piece="thrust2", emitVector= {0,1,0}, onActive=true}},
    {class='AirJet',options={color={0.7,0.4,0.1}, width=8, length=16, piece="thrust4", emitVector= {0,1,0}, onActive=true}},
  },
  [UnitDefNames["corfink"].id] = {
    {class='AirJet',options={color={0.7,0.4,0.1}, width=3, length=35, piece="thrustb", onActive=true}},
  },
  [UnitDefNames["corveng"].id] = {
    {class='AirJet',options={color={0.7,0.4,0.1}, width=3, length=24, piece="thrust1", onActive=true}},
    {class='AirJet',options={color={0.7,0.4,0.1}, width=3, length=24, piece="thrust2", onActive=true}},
  },
  
  --T2 ARM
  [UnitDefNames["corgripn"].id] = {
    {class='AirJet',options={color={0.1,0.4,0.6}, width=3.7, length=60, piece="thrusta", onActive=true}},
    {class='AirJet',options={color={0.1,0.4,0.6}, width=3.7, length=60, piece="thrustb", onActive=true}},
  },
  [UnitDefNames["blade"].id] = {
    {class='AirJet',options={color={0.1,0.4,0.6}, width=3.7, length=28, piece="thrust", onActive=true}},
  },
  [UnitDefNames["armcybr"].id] = {
    {class='AirJet',options={color={0.1,0.4,0.6}, width=3.5, length=60, piece="thrusta", onActive=true}},
    {class='AirJet',options={color={0.1,0.4,0.6}, width=3.5, length=60, piece="thrustb", onActive=true}},
  },
  [UnitDefNames["armaca"].id] = {
    {class='AirJet',options={color={0.1,0.4,0.6}, width=8, length=30, piece="thrust", onActive=true}},
  },
  [UnitDefNames["armawac"].id] = {
    {class='AirJet',options={color={0.1,0.4,0.6}, width=3.5, length=50, piece="thrust", onActive=true}},
  },
  [UnitDefNames["armdfly"].id] = {
    {class='AirJet',options={color={0.1,0.4,0.6}, width=3.5, length=60, piece="thrusta", onActive=true}},
    {class='AirJet',options={color={0.1,0.4,0.6}, width=3.5, length=60, piece="thrustb", onActive=true}},
  },
  [UnitDefNames["armbrawl"].id] = {
    {class='AirJet',options={color={0.1,0.4,0.6}, width=3.7, length=15, piece="thrust1", onActive=true}},
    {class='AirJet',options={color={0.1,0.4,0.6}, width=3.7, length=15, piece="thrust2", onActive=true}},
  },
  [UnitDefNames["armlance"].id] = {
   {class='AirJet',options={color={0.1,0.4,0.6}, width=5, length=65, piece="thrust1", onActive=true}},
   {class='AirJet',options={color={0.1,0.4,0.6}, width=5, length=65, piece="thrust2", onActive=true}},
  },
  [UnitDefNames["armpnix"].id] = {
    {class='AirJet',options={color={0.1,0.4,0.6}, width=8, length=75, piece="thrusta", onActive=true}},
    {class='AirJet',options={color={0.1,0.4,0.6}, width=8, length=75, piece="thrustb", onActive=true}},
  },
  [UnitDefNames["armhawk"].id] = {
    {class='AirJet',options={color={0.1,0.4,0.6}, width=6, length=45, piece="thrust", onActive=true}},
  },
  
  --T2 CORE
  
  [UnitDefNames["corhurc"].id] = {
    {class='AirJet',options={color={0.1,0.4,0.6}, width=10, length=80, piece="thrustb", onActive=true}},
    {class='AirJet',options={color={0.1,0.4,0.6}, width=6, length=60, piece="thrusta1", onActive=true}},
    {class='AirJet',options={color={0.1,0.4,0.6}, width=6, length=60, piece="thrusta2", onActive=true}},
  },
  [UnitDefNames["corvamp"].id] = {
    {class='AirJet',options={color={0.1,0.4,0.6}, width=3.5, length=65, piece="thrusta", onActive=true}},
  },
  [UnitDefNames["cortitan"].id] = {
    {class='AirJet',options={color={0.1,0.4,0.6}, width=5, length=65, piece="thrustb", onActive=true}},
  },
  [UnitDefNames["corape"].id] = {
    {class='AirJet',options={color={0.1,0.4,0.6}, width=8, length=28, piece="thrust1b", emitVector= {0,1,0}, onActive=true}},
    {class='AirJet',options={color={0.1,0.4,0.6}, width=8, length=28, piece="thrust2b", emitVector= {0,1,0}, onActive=true}},
  },
  [UnitDefNames["corcrw"].id] = {
    {class='AirJet',options={color={0.1,0.4,0.6}, width=16, length=28, piece="thrustrra", emitVector= {0,1,0},onActive=true}},
    {class='AirJet',options={color={0.1,0.4,0.6}, width=16, length=28, piece="thrustrla", emitVector= {0,1,0}, onActive=true}},
    {class='AirJet',options={color={0.1,0.4,0.6}, width=12, length=28, piece="thrustfra", emitVector= {0,1,0}, onActive=true}},
    {class='AirJet',options={color={0.1,0.4,0.6}, width=12, length=28, piece="thrustfla", emitVector= {0,1,0}, onActive=true}},
  },
  [UnitDefNames["armsl"].id] = {
    {class='AirJet',options={color={0.1,0.4,0.6}, width=16, length=28, piece="thrustrra", emitVector= {0,1,0},onActive=true}},
    {class='AirJet',options={color={0.1,0.4,0.6}, width=16, length=28, piece="thrustrla", emitVector= {0,1,0}, onActive=true}},
    {class='AirJet',options={color={0.1,0.4,0.6}, width=12, length=28, piece="thrustfra", emitVector= {0,1,0}, onActive=true}},
    {class='AirJet',options={color={0.1,0.4,0.6}, width=12, length=28, piece="thrustfla", emitVector= {0,1,0}, onActive=true}},
  },  
  [UnitDefNames["cortitan"].id] = {
    {class='AirJet',options={color={0.1,0.4,0.6}, width=10, length=52, piece="thrustb", onActive=true}},
    {class='AirJet',options={color={0.1,0.4,0.6}, width=6, length=35, piece="thrusta1", onActive=true}},
    {class='AirJet',options={color={0.1,0.4,0.6}, width=6, length=35, piece="thrusta2", onActive=true}},
  },
  --SEAPLANE ARM
  
  [UnitDefNames["armcsa"].id] = {
    {class='AirJet',options={color={0.2,0.8,0.2}, width=8, length=30, piece="thrusta", onActive=true}},
    {class='AirJet',options={color={0.2,0.8,0.2}, width=6, length=20, piece="thrustb", onActive=true}},
  },
  [UnitDefNames["armsfig"].id] = {
    {class='AirJet',options={color={0.2,0.8,0.2}, width=4, length=25, piece="thrust", onActive=true}},
  },
  [UnitDefNames["armseap"].id] = {
    {class='AirJet',options={color={0.2,0.8,0.2}, width=6, length=45, piece="thrust", onActive=true}},
  },
  [UnitDefNames["armsehak"].id] = {
    {class='AirJet',options={color={0.2,0.8,0.2}, width=3.5, length=50, piece="thrust", onActive=true}},
  },
  [UnitDefNames["armsb"].id] = {
    {class='AirJet',options={color={0.2,0.8,0.2}, width=4.7, length=70, piece="thrustc", onActive=true}},
    {class='AirJet',options={color={0.2,0.8,0.2}, width=2.7, length=25, piece="thrusta", onActive=true}},
    {class='AirJet',options={color={0.2,0.8,0.2}, width=2.7, length=25, piece="thrustb", onActive=true}},
  },
  --SEAPLANE CORE
  [UnitDefNames["corsfig"].id] = {
    {class='AirJet',options={color={0.2,0.8,0.2}, width=3, length=42, piece="thrust", onActive=true}},
  },
  [UnitDefNames["corseap"].id] = {
    {class='AirJet',options={color={0.2,0.8,0.2}, width=3, length=42, piece="thrust", onActive=true}},
  },
  [UnitDefNames["corawac"].id] = {
    {class='AirJet',options={color={0.2,0.8,0.2}, width=4, length=50, piece="thrust", onActive=true}},
  },
  [UnitDefNames["corhunt"].id] = {
    {class='AirJet',options={color={0.2,0.8,0.2}, width=4, length=50, piece="thrust", onActive=true}},
  },
  [UnitDefNames["corsb"].id] = {
    {class='AirJet',options={color={0.2,0.8,0.2}, width=3.5, length=76, piece="thrusta", onActive=true}},
    {class='AirJet',options={color={0.2,0.8,0.2}, width=3.5, length=76, piece="thrustb", onActive=true}},
  },


 }

effectUnitDefsXmas = {}

local levelScale = {
    1,
    1.1,
    1.2,
    1.25,
    1.3,
}

-- load presets from unitdefs
for i=1,#UnitDefs do
    local unitDef = UnitDefs[i]
    
    if unitDef.customParams and unitDef.customParams.commtype then
        local s = levelScale[tonumber(unitDef.customParams.level) or 1]
        if unitDef.customParams.commtype == "1" then
            effectUnitDefsXmas[unitDef.name] = {
                {class='SantaHat', options={color={0,0.7,0,1}, pos={0,4*s,0.35*s}, emitVector={0.3,1,0.2}, width=2.7*s, height=6*s, ballSize=0.7*s, piece="head"}},
            }
        elseif unitDef.customParams.commtype == "2" then
            effectUnitDefsXmas[unitDef.name] = {
                {class='SantaHat', options={pos={0,6*s,2*s}, emitVector={0.4,1,0.2}, width=2.7*s, height=6*s, ballSize=0.7*s, piece="head"}},
            }
        elseif unitDef.customParams.commtype == "3" then 
            effectUnitDefsXmas[unitDef.name] = {
                {class='SantaHat', options={color={0,0.7,0,1}, pos={1.5*s,4*s,0.5*s}, emitVector={0.7,1.6,0.2}, width=2.2*s, height=6*s, ballSize=0.7*s, piece="head"}},
            }
        elseif unitDef.customParams.commtype == "4" then 
            effectUnitDefsXmas[unitDef.name] = {
                {class='SantaHat', options={pos={0,3.8*s,0.35*s}, emitVector={0,1,0}, width=2.7*s, height=6*s, ballSize=0.7*s, piece="head"}},
            }
        elseif unitDef.customParams.commtype == "5" then 
            effectUnitDefsXmas[unitDef.name] = {
                {class='SantaHat', options={color={0,0,0.7,1}, pos={0,0,0}, emitVector={0,1,0.1}, width=2.7*s, height=6*s, ballSize=0.7*s, piece="hat"}},
            }        
        elseif unitDef.customParams.commtype == "6" then 
            effectUnitDefsXmas[unitDef.name] = {
                {class='SantaHat', options={color={0,0,0.7,1}, pos={0,0,0}, emitVector={0,1,-0.1}, width=4.05*s, height=9*s, ballSize=1.05*s, piece="hat"}},
            }        
        end
    end
    if unitDef.customParams then
        local fxTableStr = unitDef.customParams.lups_unit_fxs
        if fxTableStr then
            local fxTableFunc = loadstring("return "..fxTableStr)
            local fxTable = fxTableFunc()
            effectUnitDefs[unitDef.name] = effectUnitDefs[unitDef.name] or {}
            for i=1,#fxTable do    -- for each item in preset table
                local toAdd = presets[fxTable[i]]
                for i=1,#toAdd do
                    table.insert(effectUnitDefs[unitDef.name],toAdd[i])    -- append to unit's lupsFX table
                end
            end
        end
    end
end

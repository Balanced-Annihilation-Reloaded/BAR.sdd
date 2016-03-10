--------------------------
-- DOCUMENTATION
-------------------------

-- This file contains BAR _Post fucntions, and the ability to bake any changes they make into files
-- These won't touch defs in dependencies/mutators, and may react badly to mutators using _post

-- What happens:
-- unitdefs_post.lua calls the _Post functions for unitDefs and any weaponDefs that are contained in the unitdef files
-- unitdefs_post.lua writes the corresponding unitDefs to customparams (if wanted)
-- weapondefs_post.lua fetches any weapondefs from the unitdefs, 
-- weapondefs_post.lua fetches the standlaone weapondefs, calls the _post functions for them, writes them to customparams (if wanted)
-- the other defs_post.lua files just call the _Post function here, and then write (if wanted)

-- WHY WEAPON/UNITDEFS ARE SPECIAL:
-- BA contains weapondefs in its unitdef files
-- Standalone weapondefs are only loaded by Spring after unitdefs are loaded
-- So, if we want to do post processing and include all the unit+weapon defs, and have the ability to bake these changes into files, we must do it after both have been loaded (which means, here)


-- Master switch for when we want to save defs into customparams as strings (so as a widget can then write them to file)
-- The widget to do so can be found in 'etc/Lua/bake _post'
SaveDefsToCustomParams = false


-------------------------
-- DEFS POST PROCESSING
-------------------------

-- process unitdef
function UnitDef_Post(name, uDef)

end

-- process weapondef
function WeaponDef_Post(name, wDef)

end

-- process effects
function ExplosionDef_Post(name, eDef)
    --[[
    -- WIP on #645
    Spring.Echo(name)
    for k,v in pairs(eDef) do
        Spring.Echo(" ", k, v, type(k), type(v))
        if type(v)=="table" then
            for k1,v1 in pairs(v) do
                Spring.Echo("  ", k1,v1)
            end
        end
    end
    if eDef.usedefaultexplosions=="1" then
    
    end
    ]]
end


--------------------------
-- MODOPTIONS
-------------------------

-- process modoptions (last, because they should not get baked)
function ModOptions_Post (UnitDefs, WeaponDefs)
  if (Spring.GetModOptions) then
    local modOptions = Spring.GetModOptions()

    -- transporting enemy coms
    if (modOptions.mo_transportenemy == "notcoms") then
      for name,ud in pairs(UnitDefs) do  
        if (name == "armcom" or name == "corcom" or name == "armdecom" or name == "cordecom") then
          ud.transportbyenemy = false
        end
      end
    elseif (modOptions.mo_transportenemy == "none") then
      for name, ud in pairs(UnitDefs) do  
        ud.transportbyenemy = false
      end
    end
    
    -- free fusion
    if (modOptions.mo_freefusion == "1") then
      table.insert(UnitDefs.armcom.buildoptions, "freefusion")
      table.insert(UnitDefs.corcom.buildoptions, "freefusion")    
    end
  end
  
end
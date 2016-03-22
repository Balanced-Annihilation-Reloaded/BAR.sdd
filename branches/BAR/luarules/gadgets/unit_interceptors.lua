function gadget:GetInfo()
    return {
        name     = "Don't target flyover nukes",
        desc     = "bla",
        author     = "ashdnazg + [teh]decay",
        date     = "Too late",
        license     = "GNU GPL, v2 or later",
        layer    = 0,
        enabled  = true
    }
end


-- changelog:
-- 17 jul 2015 [teh]decay - fixed error: unit_interceptors.lua"]:27: bad argument #1 to 'unpack' (table expected, got number)
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

if (not gadgetHandler:IsSyncedCode()) then
    return false    --    no unsynced code
end

local interceptors = {}

function gadget:AllowWeaponInterceptTarget(interceptorUnitID, interceptorWeaponID, targetProjectileID)
    local ud = UnitDefs[Spring.GetUnitDefID(interceptorUnitID)]
    local wd = WeaponDefs[ud.weapons[interceptorWeaponID].weaponDef]
    local ox, _, oz = Spring.GetUnitPosition(interceptorUnitID)
    --Spring.Echo(ud.name, wd.name)

    local targetType, targetID = Spring.GetProjectileTarget(targetProjectileID)
    --Spring.Echo(targetType, targetID)
    
    if targetType then
        local tx, ty, tz;

        if targetType == string.byte('u') then -- unit
            tx, ty,  tz = Spring.GetUnitPosition(targetID)
        elseif targetType == string.byte('f') then -- feature
            tx, ty,  tz = Spring.GetFeaturePosition(targetID)
        elseif targetType == string.byte('p') then --PROJECTILE
            tx, ty,  tz = Spring.GetProjectilePosition(targetID)
        elseif targetType == string.byte('g') then -- ground
            tx, ty, tz = unpack(targetID)
        end

        local cover = ((ox-tx)^2+(oz-tz)^2 < wd.coverageRange^2)
        --Spring.Echo(cover)
        
        return cover
    end
end


function gadget:Initialize()
    for wdid, wd in pairs(WeaponDefs) do
        if wd.interceptor > 0 and wd.coverageRange then
            Script.SetWatchWeapon(wdid, true)
        end
    end
end
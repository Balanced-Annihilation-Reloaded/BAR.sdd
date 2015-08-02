   function gadget:GetInfo()
      return {
        name      = "Reclaim flash",
        desc      = "Nice tree reclaim effect",
        author    = "Beherith",
        date      = "July 2011",
        license   = "PD",
        layer     = 0,
        enabled   = true,
      }
    end
     
if (not gadgetHandler:IsSyncedCode()) then
  return
end

local GetFeaturePosition     = Spring.GetFeaturePosition
local GetFeatureResources     = Spring.GetFeatureResources
local SpawnCEG                = Spring.SpawnCEG
local GetUnitDefID             = Spring.GetUnitDefID
local GetUnitPosition        = Spring.GetUnitPosition

local rezzers={
    [UnitDefNames.armrectr.id] = true,
    [UnitDefNames.armrecl.id] = true,
    [UnitDefNames.cornecro.id] = true,
    [UnitDefNames.correcl.id] = true,
}

function gadget:FeatureDestroyed(featureID,allyteam)
    local fx,fy,fz=GetFeaturePosition(featureID)
    --Spring.Echo(allyteam)
    if (fx ~= nil) then
        rm, mm, re, me, rl = GetFeatureResources(featureID)
        if (rm ~= nil) then
            if mm==0 and re == 0 then
                SpawnCEG("sparklegreen", fx, fy, fz,1,0,1)
            end
        end
    end
end

function gadget:UnitCreated(unitID, unitDefID, teamID, builderID)

    --Spring.Echo('resurrection!', builderID)
    
    if (builderID and builderID > 0 and rezzers[GetUnitDefID(builderID)]) then
        local px,py,pz=GetUnitPosition(unitID)
        if px~=nil then
            SpawnCEG("sparklegreeninverse",px,py,pz)
        end
        --Spring.Echo('resurrection!')
    end
end
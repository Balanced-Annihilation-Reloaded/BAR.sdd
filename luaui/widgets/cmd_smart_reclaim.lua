--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    unit_smart_area_reclaim.lua
--  brief:   Area reclaims only metal or energy depending on the center feature
--  original author: Ryan Hileman
--
--  Copyright (C) 2010.
--  Public Domain.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
    return {
        name      = "Smart Area Reclaim",
        desc      = "Area reclaims only metal or energy depending on the central feature\nAlternatively, hold down alt to reclaim only your own units of the central type",
        author    = "aegis, Google Frog", 
        date      = "Jun 25, 2010",
        license   = "GPL v2 or later",
        layer     = 0,
        enabled   = true
    }
end

-----------------------------------------------------------------
-- manually generated locals because I don't have trepan's script
-----------------------------------------------------------------
local maxUnits = Game.maxUnits

local spGetUnitCommands = Spring.GetUnitCommands
local spGetUnitPosition = Spring.GetUnitPosition
local spGetFeaturesInRectangle = Spring.GetFeaturesInRectangle
local spGetFeaturePosition = Spring.GetFeaturePosition
local spGetFeatureRadius = Spring.GetFeatureRadius
local spGetFeatureResources = Spring.GetFeatureResources

local spGiveOrderToUnit = Spring.GiveOrderToUnit
local spGiveOrderToUnitArray = Spring.GiveOrderToUnitArray
local spGetCommandQueue = Spring.GetCommandQueue
local spGetSelectedUnits = Spring.GetSelectedUnits
local spGetUnitsInCylinder = Spring.GetUnitsInCylinder
local spWorldToScreenCoords = Spring.WorldToScreenCoords
local spTraceScreenRay = Spring.TraceScreenRay
local spGetUnitDefID = Spring.GetUnitDefID
local spGetUnitAllyTeam = Spring.GetUnitAllyTeam
local spGetModKeyState = Spring.GetModKeyState


local reclaimEnemy = Game.reclaimAllowEnemies

local CMD_RECLAIM = CMD.RECLAIM
local CMD_STOP = CMD.STOP

local WorldToScreenCoords = Spring.WorldToScreenCoords
local TraceScreenRay = Spring.TraceScreenRay

local sort = table.sort

local RECLAIM = CMD.RECLAIM
local MOVE = CMD.MOVE
local OPT_SHIFT = CMD.OPT_SHIFT

local abs = math.abs
local sqrt = math.sqrt
local atan2 = math.atan2
-----------------------------------------------------------------
-- end locals----------------------------------------------------
-----------------------------------------------------------------

local function tsp(rList, tList, dx, dz)
    dx = dx or 0
    dz = dz or 0
    tList = tList or {}
    
    if (rList == nil) then return end

    local closestDist
    local closestItem
    local closestIndex
    
    for i=1, #rList do
        local item = rList[i]
        if (item ~= nil) and (item ~= 0) then
            local distx, distz, uid, fid = item[1]-dx, item[2]-dz, item[3], item[4]
            local dist = abs(distx) + abs(distz)
            if (closestDist == nil) or (dist < closestDist) then
                closestDist = dist
                closestItem = item
                closestIndex = i
            end
        end
    end
    
    if (closestItem == nil) then return tList end
    
    tList[#tList+1] = closestItem
    rList[closestIndex] = 0
    return tsp(rList, tList, closestItem[1], closestItem[2])
end

local function stationary(rList)
    local sList = {}
    local sKeys = {}
    
    local lastKey, lastItem
    
    for i=1, #rList do
        local item = rList[i]
        local dx, dz = item[1], item[2]
        
        local theta = atan2(dx, dz)
        if (lastKey ~= theta) then
            sKeys[#sKeys+1] = theta
            lastItem = {item}
            sList[theta] = lastItem
        else
            lastItem[#lastItem+1] = item
            sList[theta] = lastItem
        end
    end
    
    local oList = {}
    sort(sKeys)
    for i=1, #sKeys do
        local theta = sKeys[i]
        local values = sList[theta]
        for j=1, #values do
            oList[#oList+1] = values[j]
        end
    end
    return oList
end

---

local function issue(rList, shift)
    local opts = {}
    
    for i=1, #rList do
        local item = rList[i]
        local uid, fid = item[3], item[4]
        
        local opt = {}
        if (opts[uid] ~= nil) or (shift) then
            opt = OPT_SHIFT
        end
        
        spGiveOrderToUnit(uid, RECLAIM, {fid+maxUnits}, opt)
        opts[uid] = 1
    end
end

local function SmartUnitReclaim(id, params, options)
    local mobiles, stationaries = {}, {}
    local mobileb, stationaryb = false, false
    
    local rUnits = {}
    local sUnits = spGetSelectedUnits()
    for i=1,#sUnits do
        local uid = sUnits[i]
        local udid = spGetUnitDefID(uid)
        local unitDef = UnitDefs[udid]
        if (unitDef.canReclaim == true) then
            if (unitDef.canMove == false) then
                stationaries[uid] = unitDef
                stationaryb = true
            else
                mobiles[uid] = unitDef
                mobileb = true
            end
            
            local ux, uy, uz = spGetUnitPosition(uid)
            if (options.shift) then
                local cmds = spGetUnitCommands(uid,100)
                for ci=#cmds, 1, -1 do
                    local cmd = cmds[ci]
                    if (cmd.id == MOVE) then
                        ux, uy, uz = cmd.params[1], cmd.params[2], cmd.params[3]
                        break
                    end
                end
            end
            
            rUnits[#rUnits+1] = {uid=uid, ux=ux, uz=uz}
        end
    end
    
    if (#rUnits > 0) then
        local len = #params
        local ret = {}
        local rmt = {}
        
        if (len == 4) then
            local x, y, z, r = params[1], params[2], params[3], params[4]
            local xmin, xmax, zmin, zmax = (x-r), (x+r), (z-r), (z+r)
            local rx, rz = (xmax - xmin), (zmax - zmin)
            
            local units = spGetFeaturesInRectangle(xmin, zmin, xmax, zmax)
            
            local mx, my, mz = spWorldToScreenCoords(x, y, z)
            local ct, id = spTraceScreenRay(mx, my)
            
            if (ct == "feature") then
                local cu = id
                
                for i=1,#units,1 do
                    local uid = units[i]
                    local ux, _, uz = spGetFeaturePosition(uid)
                    local ur = spGetFeatureRadius(uid)
                    local urx, urz = abs(ux - x), abs(uz - z)
                    local ud = sqrt((urx * urx) + (urz * urz))-ur*.5
                    
                    if (ud < r) then
                        local mr, _, er, _, _ = spGetFeatureResources(uid)
                        if (mr > 0) then
                            rmt[#rmt+1] = uid
                        elseif (er > 0) then
                            ret[#ret+1] = uid
                        end
                    end
                end
                
                local mr, _, er, _, _ = spGetFeatureResources(cu)
                -- if (mr > 0)and(er > 0) then return end
                
                local mList, sList = {}, {}
                local source = {}
                
                if (#rmt > 0)and(mr > 0) then
                    source = rmt
                elseif (#ret > 0)and(er > 0) then
                    source = ret
                end
                
                for i=1,#source do
                    local fid = source[i]
                    if (fid ~= nil) then
                        local fx, _, fz = spGetFeaturePosition(fid)
                        for ui=1,#rUnits do
                            local unit = rUnits[ui]
                            local uid, ux, uz = unit.uid, unit.ux, unit.uz
                            local dx, dz = ux-fx, uz-fz
                            local dist = dx + dz
                            local item = {dx, dz, uid, fid}
                            if (mobiles[uid] ~= nil) then
                                mList[#mList+1] = item
                            elseif (stationaries[uid] ~= nil) then
                                if (sqrt((dx*dx)+(dz*dz)) <= stationaries[uid].buildDistance) then
                                    sList[#sList+1] = item
                                end
                            end
                        end
                    end
                end
                
                local issued = false
                if (mobileb == true) then
                    mList = tsp(mList)
                    issue(mList, options.shift)
                    issued = true
                end
                
                if (stationaryb == true) then
                    sList = stationary(sList)
                    issue(sList, options.shift)
                    issued = true
                end
                
                return issued
            end
        end
    end
end

local function SpecificUnitReclaim(id, params, options)
    local cx, cy, cz = params[1], params[2], params[3]

    local mx,my,mz = spWorldToScreenCoords(cx, cy, cz)
    local cType,id = spTraceScreenRay(mx,my) 

    if cType == "unit" then 

        local cr = params[4]

        local selUnits = spGetSelectedUnits()
    
        
        local targetEnemy = reclaimEnemy and spGetUnitAllyTeam(id) ~= allyTeam
        local unitDef = spGetUnitDefID(id)
        local areaUnits = spGetUnitsInCylinder(cx ,cz , cr)
        
        if not targetEnemy and not options.ctrl then
            areaUnits = spGetUnitsInCylinder(cx ,cz , cr, team)
        end
        
        local count = 0
        for i, aid in ipairs(areaUnits) do 
            if (targetEnemy and spGetUnitAllyTeam(aid) ~= allyTeam) or ( not targetEnemy and spGetUnitDefID(aid) == unitDef ) then
                local cmdOpts = {}
                if count ~= 0 or options.shift then
                    cmdOpts = {"shift"}
                end
                spGiveOrderToUnitArray( selUnits, CMD_RECLAIM, {aid}, cmdOpts)
                count = count + 1
            end
        end
        return true 
        
    end
end

function widget:CommandNotify(id, params, options)
    if id == RECLAIM then
        if options.alt then
            return SpecificUnitReclaim(id, params, options)
        else
            return SmartUnitReclaim(id, params, options)
        end    
    end
    return false
end
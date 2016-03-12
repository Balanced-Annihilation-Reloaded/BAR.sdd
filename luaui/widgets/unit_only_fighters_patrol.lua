--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    unit_only_fighters_patrol.lua
--  brief:   Only fighters go on factory's patrol route after leaving airlab. Reduces lag.
--  author:  dizekat
--  based on Factory Kickstart by OWen Martindell aka TheFatController
--
--  Copyright (C) 2008
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


function widget:GetInfo()
    return {
        name    = "Only Fighters Patrol",
        desc    = "Only fighters follow factory patrol route after leaving the airlab",
        author    = "dizekat",
        date    = "2008-04-22",
        license    = "GNU GPL, v2 or later",
        layer    = 0,
        enabled    = false,
    }
end

local opts={
    stop_builders=true -- Whether to stop builders or not. Set to true if you don't use factory guard widget.
}

local OrderUnit = Spring.GiveOrderToUnit
local GetMyTeamID = Spring.GetMyTeamID
local GetCommandQueue = Spring.GetCommandQueue
local GetUnitBuildFacing = Spring.GetUnitBuildFacing
local GetUnitPosition = Spring.GetUnitPosition

local function UnitHasPatrolOrder(unitID)
    local queue=GetCommandQueue(unitID,20)
    for i,cmd in ipairs(queue) do
        if cmd.id==CMD.PATROL then
            return true
        end
    end
    return false
end
local function MustStop(unitID, unitDefID)
    local ud=UnitDefs[unitDefID]
    if ud and ud.canFly and (ud.weaponCount==0 or (not ud.isFighterAirUnit) or (ud.humanName=="Liche") or ud.noAutoFire) and UnitHasPatrolOrder(unitID) then 
        if (not opts.stop_builders)and ud and ud.isBuilder then
            return false
        end
        return true
    end
    return false
end
            
function widget:UnitFromFactory(unitID, unitDefID, unitTeam, factID, factDefID, userOrders)
    if (unitTeam ~= GetMyTeamID()) then
        return
    elseif (userOrders) then
        return
    end
    local bd = UnitDefs[factDefID]
    if (not (bd and bd.isFactory)) then
        return
    end
    local ud=UnitDefs[unitDefID]
    if MustStop(unitID, unitDefID) then
        Spring.GiveOrderToUnit(unitID,CMD.STOP,{},{})
    else
    --[[    
        Spring.Echo("-----")
        for name,param in ud:pairs() do
            Spring.Echo(name,param)
        end
    ]]--
    end
    
    --if ud.humanName=="Liche" then
    --    UnitCanTargetAir(unitDefID)
    --end
end
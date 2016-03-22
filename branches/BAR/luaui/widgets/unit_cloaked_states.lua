function widget:GetInfo()
    return {
    name      = "Cloaked Unit States",
    desc      = "Puts cloaked units on hold fire, hold position, and makes their default command be move",
    author    = "BD, Bluestone",
    date      = "-",
    license   = "WTFPL and horses",
    layer     = -100,
    enabled   = true,
    }
end


local CMD_MOVE = CMD.MOVE
local CMD_INSERT = CMD.INSERT
local CMD_FIRE_STATE = CMD.FIRE_STATE
local CMD_MOVE_STATE = CMD.MOVE_STATE

local myPlayerID = Spring.GetMyPlayerID()
local myTeamID = Spring.GetMyTeamID()

local cloakedUnits = {} --cloakedUnits[unitID={savedFireState=,savedMoveState=}
local onlySelectedCloakedUnits = false

function widget:PlayerChanged()
    myTeamID = Spring.GetMyTeamID()
end

function widget:UnitCloaked(unitID, unitDefID, unitTeam)
    if unitTeam~=myTeamID then return end

    local state = Spring.GetUnitStates(unitID)
    cloakedUnits[unitID] = {savedFireState=state.firestate, savedMoveState=state.movestate}    
    Spring.GiveOrderToUnit(unitID, CMD_MOVE_STATE, {0}, 0)
    Spring.GiveOrderToUnit(unitID, CMD_FIRE_STATE, {0}, 0)
end

function widget:UnitDecloaked(unitID, unitDefID, unitTeam)
    if unitTeam~=myTeamID then return end

    if not cloakedUnits[unitID] or not Spring.ValidUnitID(unitID) then return end
    Spring.GiveOrderToUnit(unitID, CMD_MOVE_STATE, {cloakedUnits[unitID].savedMoveState}, 0) 
    Spring.GiveOrderToUnit(unitID, CMD_FIRE_STATE, {cloakedUnits[unitID].savedFireState}, 0) 
    cloakedUnits[unitID] = nil
end

function widget:UnitTaken(unitID, unitDefID, oldTeam, newTeam)
    if newTeam==myTeamID then
        local state = Spring.GetUnitStates(unitID)
        if state and state.cloak then
            widget:UnitCloaked(unitID, unitDefID, myTeamID)        
        end
    end
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam)
    cloakedUnits[unitID] = nil
end

function widget:Initialize()
    local units = Spring.GetAllUnits()
    for _,unitID in ipairs(units) do
        local state = Spring.GetUnitStates(unitID)
        if state and state.cloak then
            widget:UnitCloaked(unitID)
        end
    end
end

function widget:CommandsChanged()
    -- recheck onlySelectedCloakedUnits
    onlySelectedCloakedUnits = true
    local selUnits = Spring.GetSelectedUnits()
    for i=1,#selUnits do
        local unitID = selUnits[i]
        foundCloakedUnit = true
        if not cloakedUnits[unitID] then
            onlySelectedCloakedUnits = false
            break
        end
    end
end

function widget:DefaultCommand()
    if onlySelectedCloakedUnits then
        return CMD_MOVE
    end
end

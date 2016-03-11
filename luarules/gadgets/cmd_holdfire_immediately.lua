
function gadget:GetInfo()
    return {
        name      = "Hold fire Instantly",
        desc      = "Hold fire commands take effect immediately",
        author    = "Niobium",
        date      = "3 April 2010",
        license   = "GNU GPL, v2 or later",
        layer     = 0,
        enabled   = true
    }
end

if gadgetHandler:IsSyncedCode() then
    return false
end


local CMD_FIRE_STATE = CMD.FIRE_STATE
local CMD_INSERT = CMD.INSERT
local CMD_STOP = CMD.STOP
local spGiveOrder = Spring.GiveOrder

function gadget:CommandNotify(cmdID, cmdParams, cmdOptions)
    if (cmdID == CMD_FIRE_STATE) and (cmdParams[1] == 0) then
        Spring.Echo("hold")
        spGiveOrder(CMD_INSERT, {0, CMD_STOP, 0}, {"alt"})
    end
end

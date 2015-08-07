
function widget:GetInfo()
    return {
        name      = "Mex Snap",
        desc      = "Snaps building mexes onto metal spots",
        author    = "Niobium",
        version   = "v1.2",
        date      = "November 2010",
        license   = "GNU GPL, v2 or later",
        layer     = 0,
        enabled   = true,
        handler   = true
    }
end

------------------------------------------------------------
-- Speedups
------------------------------------------------------------
local spGetActiveCommand = Spring.GetActiveCommand
local spGetMouseState = Spring.GetMouseState
local spTraceScreenRay = Spring.TraceScreenRay

local isMex = {}
for uDefID, uDef in pairs(UnitDefs) do
    if uDef.extractsMetal > 0 then
        isMex[uDefID] = true
    end
end

------------------------------------------------------------
-- Functions
------------------------------------------------------------
local function GetClosestMetalSpot(x, z)
    local bestSpot
    local bestDist = math.huge
    local metalSpots = WG.metalSpots
    for i = 1, #metalSpots do
        local spot = metalSpots[i]
        local dx, dz = x - spot.x, z - spot.z
        local dist = dx*dx + dz*dz
        if dist < bestDist then
            bestSpot = spot
            bestDist = dist
        end
    end
    return bestSpot
end

local function GetClosestMexPosition(spot, x, z, uDefID, facing)
    local bestPos
    local bestDist = math.huge
    local positions = WG.GetMexPositions(spot, uDefID, facing, true)
    for i = 1, #positions do
        local pos = positions[i]
        local dx, dz = x - pos[1], z - pos[3]
        local dist = dx*dx + dz*dz
        if dist < bestDist then
            bestPos = pos
            bestDist = dist
        end
    end
    return bestPos
end
   
local function GetClosestPotentialBuildPos (uDefID, bx, bz, bface)     
    local closestSpot = GetClosestMetalSpot(bx, bz)
    if closestSpot and not WG.IsMexPositionValid(closestSpot, bx, bz) then       
        local bestPos = GetClosestMexPosition(closestSpot, bx, bz, uDefID, bface)
        if bestPos then
            return bestPos 
        end
    end
    return nil
end

local function GiveNotifyingOrder(cmdID, cmdParams, cmdOpts)
    
    if widgetHandler:CommandNotify(cmdID, cmdParams, cmdOpts) then
        return
    end
    
    Spring.GiveOrder(cmdID, cmdParams, cmdOpts.coded)
end

local function DoLine(x1, y1, z1, x2, y2, z2)
    gl.Vertex(x1, y1, z1)
    gl.Vertex(x2, y2, z2)
end

------------------------------------------------------------
-- Callins
------------------------------------------------------------

function widget:Initialize()
    if not WG.metalSpots then
        Spring.Echo("<Snap Mex> This widget requires the 'Metalspot Finder' widget to run.")
        widgetHandler:RemoveWidget(self)
    end
        
    WG.MexSnap = {}
end

function widget:DrawWorld()

    -- Check command is to build a mex
    local _, cmdID = spGetActiveCommand()
    if WG.InitialQueue and WG.InitialQueue.selDefID then
        cmdID = -WG.InitialQueue.selDefID
    end
    if not (cmdID and isMex[-cmdID]) then 
        WG.MexSnap.snappedPos = nil
        return 
    end
    
    -- Attempt to get position of command
    local mx, my = spGetMouseState()
    local _, pos = spTraceScreenRay(mx, my, true)
    if not pos then 
        WG.MexSnap.snappedPos = nil
        return 
    end
    
    -- Find build position and check if it is valid (Would get 100% metal)
    local bx, by, bz = Spring.Pos2BuildPos(-cmdID, pos[1], pos[2], pos[3])
    local bface = Spring.GetBuildFacing()
    local bestPos = GetClosestPotentialBuildPos(-cmdID, bx, bz, bface)
    if not bestPos then 
        WG.MexSnap.snappedPos = nil
        return 
    end
    
    
    -- Draw snapped mex
    gl.DepthTest(false)
    
    gl.LineWidth(1.49)
    gl.Color(1, 1, 0, 0.5)
    gl.BeginEnd(GL.LINE_STRIP, DoLine, bx, by, bz, bestPos[1], bestPos[2], bestPos[3])
    gl.LineWidth(1.0)
    
    gl.DepthTest(true)
    gl.DepthMask(true)
    
    gl.Color(1, 1, 1, 0.5)
    gl.PushMatrix()
        gl.Translate(bestPos[1], bestPos[2], bestPos[3])
        gl.Rotate(90 * bface, 0, 1, 0)
        gl.UnitShape(-cmdID, Spring.GetMyTeamID())
    gl.PopMatrix()
    
    gl.DepthTest(false)
    gl.DepthMask(false)
    
    -- Tell other widgets where the snapped mex is
    WG.MexSnap.snappedPos = bestPos
end

function widget:CommandNotify(cmdID, cmdParams, cmdOpts)
    -- intercept the build mex command and build it where we snapped too
    if isMex[-cmdID] then
        local bx, bz = cmdParams[1], cmdParams[3]
        local bface = cmdParams[4]
        local bestPos = GetClosestPotentialBuildPos(-cmdID, bx, bz, bface)
        if bestPos then
            GiveNotifyingOrder(cmdID, {bestPos[1], bestPos[2], bestPos[3], bface}, cmdOpts)
            return true
        end
    end
    return false
end

function widget:ShutDown()
    WG.MexSnap = nil
end

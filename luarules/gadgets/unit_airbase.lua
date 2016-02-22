function gadget:GetInfo()
   return {
      name      = "Airbase Repair Command",
      desc      = "Add command to return to airbase for repairs",
      author    = "ashdnazg",
      date      = "12 February 2016",
      license   = "GNU GPL, v2 or later",
      layer     = 1,
      enabled   = false  --  loaded by default?
   }
end

---------------------------------------------------------------------------------
local FORCE_LAND_CMD_ID = 35430
local LAND_CMD_ID = 35431

if (gadgetHandler:IsSyncedCode()) then

--------------------------------------------------------------------------------
-- Synced
--------------------------------------------------------------------------------

local airbaseDefIDs = {
    [UnitDefNames["armasp"].id] = true,
    [UnitDefNames["corasp"].id] = true,
}

local airbases = {} -- airbaseID = { int pieceNum = unitID reservedFor }

local pendingLanders = {} -- unitIDs of planes that are waiting to be assigned airbases to fly too
local landingPlanes = {} -- planes that are in the process of landing (including flying too) airbases; [1]=airBaseID, [2]=pieceNum 
local landedPlanes = {} -- unitIDs of planes that are landed

local forceLandCmd = {
   id      = FORCE_LAND_CMD_ID,
   name    = "ForceLand",
   action  = "forceland",
   type    = CMDTYPE.ICON,
   tooltip = "Return to base: Force the plane to return to base immediately",
}

local landCmd = {
   id      = LAND_CMD_ID,
   name    = "Land",
   action  = "land",
   cursor  = 'Repair',
   type    = CMDTYPE.ICON_UNIT,
   tooltip = "Land at a specific airbase",
   hidden  = true,
}

-- fixme: add custom commands to CMD table

function AddAirBase(unitID)
   -- add the pads of this airBase to our register
   local airBasePads = {}
   local pieceMap = Spring.GetUnitPieceMap(unitID)
   for pieceName, pieceNum in pairs(pieceMap) do
      if pieceName:find("pad") then
         airBasePads[pieceNum] = false -- value is whether or not the pad is reserved
      end
   end
   airbases[unitID] = airBasePads
end


function CanLandAt(unitID, airbaseID)
   -- returns either false or the piece number of the free pad
   
   -- check that this airbase has pads (needed?)
   local airbasePads = airbases[airbaseID]
   if not airbasePads then
      return false
   end

   -- check that this airbase is on our team
   local unitTeamID = Spring.GetUnitTeam(unitID)
   local airbaseTeamID = Spring.GetUnitTeam(airbaseID)
   if not Spring.AreTeamsAllied(unitTeamID, airbaseTeamID) then
      return false
   end

   -- try to find a vacant pad within this airbase
   local padPieceNum = false
   for pieceNum, reservedBy in pairs(airbasePads) do
      if not reservedBy then
         padPieceNum = pieceNum
      end
      if reservedBy == false then
         padPieceNum = pieceNum
         break
      end
   end
   return padPieceNum
end


function FindAirBase(unitID)
   -- find the nearest airbase with a free pad
   local minDist = math.huge
   local closestAirbaseID
   local closestPieceNum
   for airbaseID, _ in pairs(airbases) do
      local pieceNum = CanLandAt(unitID, airbaseID)
      if pieceNum then
         local dist = Spring.GetUnitSeparation(unitID, airbaseID)
         if dist < minDist then
            minDist = dist
            closestAirbaseID = airbaseID
            closestPieceNum = pieceNum
         end
      end
   end
   
   return closestAirbaseID, closestPieceNum
end

function RemoveLander(unitID)
   -- free up the pad that this landingPlane had reserved
   if landingPlanes[unitID] then
      local airbaseID, pieceNum = landingPlanes[unitID][1], landingPlanes[unitID][2]
      local airbasePads = airbases[airBaseID]
      if airbasePads then
         airbasePads[pieceNum] = false
      end
      landingPlanes[unitID] = nil
      return
   end
end

function NeedsRepair(unitID)
   -- check if this unitID (which is assumed to be a plane) would want to land
   local health, maxHealth = Spring.GetUnitHealth(unitID)
   local landAtState = Spring.GetUnitStates(unitID).autorepairlevel
   return health < maxHealth * landAtState;
end

function IsPlane(unitDefID)
    return UnitDefs[unitDefID].isAirUnit
end

function gadget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
   if UnitDefs[unitDefID].canFly then
      Spring.InsertUnitCmdDesc(unitID, landCmd)
      Spring.InsertUnitCmdDesc(unitID, forceLandCmd)
   end

   local _, _, _, _, buildProgress = Spring.GetUnitHealth(unitID)
   if buildProgress == 1.0 then
      gadget:UnitFinished(unitID, unitDefID, unitTeam)
   end
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
   RemoveLander(unitID)
   airbases[unitID] = nil
   -- fixme: release units from the air base, they might not be dead
   landingPlanes[unitID] = nil
   landedPlanes[unitID] = nil
   pendingLanders[unitID] = nil
end

function gadget:UnitFinished(unitID, unitDefID, unitTeam)
   if airbaseDefIDs[unitDefID] then
      AddAirBase(unitID)
   end
end

-- fixme: missing UnitGiven, etc

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
   if cmdID == LAND_CMD_ID then
      local airbaseID = cmdParams[1]
      return CanLandAt(unitID, airbaseID)
   end
   return true
end

function gadget:CommandFallback(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
   -- handle our two custom commands
   
   if cmdID == LAND_CMD_ID then
      -- clear old pad
      RemoveLander(unitID)
      -- stop if we've landed
      if landedPlanes[unitID] then
         return true, true
      end

      local airbaseID = cmdParams[1]
      local padPieceNum = CanLandAt(unitID, airbaseID)

      -- failed to land
      if not padPieceNum then
         return true, true
      end

      -- update new pad
      airbases[airbaseID][padPieceNum] = unitID
      landingPlanes[unitID] = {airbaseID, padPieceNum}
      return true, false
   end
   
   if cmdID == FORCE_LAND_CMD_ID then
      pendingLanders[unitID] = true
      return true, true
   end

   return false
end

function gadget:UnitCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
   -- detach planes from their pads once they are finished
   -- fixme: currently only acts once the landed unit receives a command
   -- fixme: this also acts on landingPlanes, and removes them + frees their reserved pad, but they'll just get given a new one next frame so its pointless
   if not IsPlane(unitDefID) then
      return
   end
   
   -- remove from our system (fixme)
   landingPlanes[unitID] = nil
   landedPlanes[unitID] = nil
   pendingLanders[unitID] = nil

   RemoveLander(unitID) -- if it was landing, free up the pad that it had reserved

   -- if this unitID was in a pad, detach the unit and release that pad
   local airBaseID = Spring.GetUnitTransporter(unitID)
   if not airBaseID then
      return
   end
   local airbasePads = airbases[airBaseID]
   if not airbasePads then
      return
   end
   for pieceNum, reservedBy in pairs(airbasePads) do
      if reservedBy == unitID then
         airbasePads[pieceNum] = false
      end
   end   
   Spring.UnitDetach(unitID)
end

function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID)
   if IsPlane(unitDefID) and not landingPlanes[unitID] and not landedPlanes[unitID] and NeedsRepair(unitID) then
      pendingLanders[unitID] = true
   end
end



function gadget:GameFrame(n)
   if n%12~=0 then return end

   -- assign airbases & pads to units in pendingLanders
   -- once found, move into landingPlanes
   for unitID, _ in pairs(pendingLanders) do
      local closestAirbaseID, closestPieceNum = FindAirBase(unitID)
      if closestAirbaseID then
         Spring.GiveOrderToUnit(unitID, CMD.INSERT,{0, LAND_CMD_ID, 0, closestAirbaseID},{"alt"})
         landingPlanes[unitID] = {closestAirbaseID, closestPieceNum}
         pendingLanders[unitID] = nil
      end
   end

   -- snap landingPlanes into pads, if 'close enough'
   for unitID, t in pairs(landingPlanes) do
      local airbaseID, padPieceNum = t[1], t[2]
      local px, py, pz = Spring.GetUnitPiecePosDir(airbaseID, padPieceNum)
      local ux, uy, uz = Spring.GetUnitPosition(unitID)
      local dx, dy ,dz = ux - px, uy - py, uz - pz
      local r = Spring.GetUnitRadius(unitID)
      local dist = dx * dx + dy * dy + dz * dz
      
      -- check if we're close enough
      if dist < 0.5 * r * r then -- probably needs more attention
         Spring.UnitAttach(airbaseID, unitID, padPieceNum)
         landingPlanes[unitID] = nil
         landedPlanes[unitID] = true
      else
         Spring.SetUnitLandGoal(unitID, px, py, pz, r)
      end
   end


end

function gadget:Initialize()
   -- fixme: when using new transport mechanics, this is the proper way to define airbases
   for unitDefID, unitDef in pairs(UnitDefs) do
      if unitDef.isAirBase then
         airbaseDefIDs[unitDefID] = true
      end
   end

   -- fake UnitCreated events for existing units, for luarules reload
   local allUnits = Spring.GetAllUnits()
   for i=1,#allUnits do
      local unitID = allUnits[i]
      local unitDefID = Spring.GetUnitDefID(unitID)
      local teamID = Spring.GetUnitTeam(unitID)
      gadget:UnitCreated(unitID, unitDefID)
   end
end

function gadget:UnitLoaded(unitID, unitDefID, unitTeam, transportID, transportTeam)
    -- wtf
    -- fixme: if this has to be here, need to undo in UnitUnloaded
    if IsPlane(unitDefID) then
        Spring.SetUnitNoDraw(unitID, false)
        Spring.SetUnitStealth(unitID, false)
        Spring.SetUnitSonarStealth(unitID, false)
    end
end

--------------------------------------------------------------------------------
-- Unsynced
--------------------------------------------------------------------------------
else

function gadget:Initialize()
   Spring.AssignMouseCursor("Land for repairs", "cursorrepair", false, false)
   Spring.SetCustomCommandDrawData(LAND_CMD_ID, "Land for repairs", {1,0.5,0,.8}, false)
end

local spGetMouseState = Spring.GetMouseState
local spTraceScreenRay = Spring.TraceScreenRay
local spAreTeamsAllied = Spring.AreTeamsAllied
local spGetUnitTeam = Spring.GetUnitTeam
local spGetSelectedUnits = Spring.GetSelectedUnits
local spGetUnitDefID = Spring.GetUnitDefID
local spGetMyTeamID = Spring.GetMyTeamID

function gadget:DefaultCommand()
   local mx, my = spGetMouseState()
   local s, targetID = spTraceScreenRay(mx, my)
   if s ~= "unit" then
      return false
   end

   if not spAreTeamsAllied(spGetMyTeamID(), spGetUnitTeam(targetID)) then
      return false
   end

   if not UnitDefs[spGetUnitDefID(targetID)].isAirBase then
      return false
   end


   local sUnits = spGetSelectedUnits()
   for i=1,#sUnits do
      local unitID = sUnits[i]
      if UnitDefs[spGetUnitDefID(unitID)].canFly then
         return LAND_CMD_ID
      end
   end
   return false
end

end

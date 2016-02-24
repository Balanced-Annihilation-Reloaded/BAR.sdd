function gadget:GetInfo()
   return {
      name      = "Airbase Repair Command",
      desc      = "Add command to return to airbase for repairs",
      author    = "ashdnazg, Bluestone",
      date      = "12 February 2016",
      license   = "GNU GPL, v2 or later",
      layer     = 1,
      enabled   = false  --  loaded by default?
   }
end

---------------------------------------------------------------------------------
local CMD_LAND_AT_ANY_AIRBASE = 35430
local CMD_LAND_AT_AIRBASE = 35431

CMD.LAND_AT_ANY_AIRBASE = CMD_LAND_AT_ANY_AIRBASE
CMD[CMD_LAND_AT_ANY_AIRBASE] = "LAND_AT_ANY_AIRBASE"
CMD.LAND_AT_AIRBASE = CMD_LAND_AT_AIRBASE
CMD[CMD_LAND_AT_AIRBASE] = "LAND_AT_AIRBASE"


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
local landingPlanes = {} -- planes that are in the process of landing (including flying towards) airbases; [1]=airbaseID, [2]=pieceNum 
local landedPlanes = {} -- unitIDs of planes that are landed

---------------------------
-- custom commands
-- todo: names, etc

local forceLandCmd = {
   id      = LAND_AT_ANY_AIRBASE,
   name    = "Land At Any Airbase",
   action  = "land_at_any_airbase",
   type    = CMDTYPE.ICON,
   tooltip = "Lands at the nearest available airbase",
}

local landCmd = {
   id      = LAND_AT_AIRBASE,
   name    = "Land At Airbase",
   action  = "land_at_airbase",
   cursor  = 'Repair',
   type    = CMDTYPE.ICON_UNIT,
   tooltip = "Lands at a specific airbase",
}

---------------------------------------
-- helper funcs

function AddAirBase(unitID)
   -- add the pads of this airbase to our register
   local airbasePads = {}
   local pieceMap = Spring.GetUnitPieceMap(unitID)
   for pieceName, pieceNum in pairs(pieceMap) do
      if pieceName:find("pad") then
         airbasePads[pieceNum] = false -- value is whether or not the pad is reserved
      end
   end
   airbases[unitID] = airbasePads
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

function CanLandAt(unitID, airbaseID)
   -- return either false (-> cannot land at this airbase) or the piece number of a free pad within this airbase
   
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

function RemoveLandingPlane(unitID)
   -- free up the pad that this landingPlane had reserved
   if landingPlanes[unitID] then
      local airbaseID, pieceNum = landingPlanes[unitID][1], landingPlanes[unitID][2]
      local airbasePads = airbases[airbaseID]
      if airbasePads then
         airbasePads[pieceNum] = false
      end
      landingPlanes[unitID] = nil
      return
   end
end

function AttachToPad(unitID, airbaseID, padPieceNum)
   Spring.UnitAttach(airbaseID, unitID, padPieceNum)
end

function DetachFromPad(unitID)
   -- if this unitID was in a pad, detach the unit and free that pad
   local airbaseID = Spring.GetUnitTransporter(unitID)
   if not airbaseID then
      return
   end
   local airbasePads = airbases[airbaseID]
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


function NeedsRepair(unitID)
   -- check if this unitID (which is assumed to be a plane) would want to land
   local health, maxHealth = Spring.GetUnitHealth(unitID)
   local landAtState = Spring.GetUnitStates(unitID).autorepairlevel
   return health < maxHealth * landAtState;
end

function IsPlane(unitDefID)
    return UnitDefs[unitDefID].isAirUnit
end

---------------------------------------
-- unit creation, destruction, etc

function gadget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
   if IsPlane(unitDefID) then
      Spring.InsertUnitCmdDesc(unitID, landCmd)
      Spring.InsertUnitCmdDesc(unitID, forceLandCmd)
   end

   local _, _, _, _, buildProgress = Spring.GetUnitHealth(unitID)
   if buildProgress == 1.0 then
      gadget:UnitFinished(unitID, unitDefID, unitTeam)
   end
end

function gadget:UnitFinished(unitID, unitDefID, unitTeam)
   if airbaseDefIDs[unitDefID] then
      AddAirBase(unitID)
   end
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
   if not IsPlane(unitDefID) and not airbases[unitID] then return end

   RemoveLandingPlane(unitID)
   airbases[unitID] = nil
   landingPlanes[unitID] = nil
   landedPlanes[unitID] = nil
   pendingLanders[unitID] = nil
end

---------------------------------------
-- custom command handling

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
   -- deny landing at a specific airbase if its not possible
   -- fixme: doesn't handle with insert commands
   if cmdID == CMD_LAND_AT_AIRBASE then
      local airbaseID = cmdParams[1]
      return CanLandAt(unitID, airbaseID)
   end
   return true
end

function gadget:CommandFallback(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
   -- handle our two custom commands
   -- todo: combine the two custom commands into one?
   
   -- land at a specific airbase
   if cmdID == CMD_LAND_AT_AIRBASE then
      -- ignore if we are already in a pad
      if landedPlanes[unitID] then
         return true, true
      end
      
      -- remove old landing pad, if there was one
      RemoveLandingPlane(unitID)

      -- find out if this airbase has a free pad
      local padPieceNum = CanLandAt(unitID, airbaseID)
      if not padPieceNum then
         return true, true
      end

      -- add details
      airbases[airbaseID][padPieceNum] = unitID
      landingPlanes[unitID] = {airbaseID, padPieceNum}
      return true, false
   end
   
   -- land at a non-specific airbase
   if cmdID == CMD_LAND_AT_ANY_AIRBASE then
      pendingLanders[unitID] = true
      return true, true
   end

   return false
end

---------------------------------------
-- custom command handling

function gadget:UnitCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
   -- if a plane is given a command, assume the user wants that command to be actioned and release control
   if not IsPlane(unitDefID) then
      return
   end
   
   -- release control of this plane
   if landingPlanes[unitID] then 
      RemoveLandingPlane(unitID) 
   elseif landedPlanes[unitID] then
      DetachFromPad(unitID) 
   end
   
   -- and remove it from our book-keeping 
   -- (in many situations, unless the user changes the RepairAt level, it will be quickly reinserted, but we have to assume that's what they want!)
   landingPlanes[unitID] = nil
   landedPlanes[unitID] = nil
   pendingLanders[unitID] = nil
end

function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID)
   Spring.Echo("damaged", unitID)
   if IsPlane(unitDefID) and not landingPlanes[unitID] and not landedPlanes[unitID] and NeedsRepair(unitID) then
      pendingLanders[unitID] = true
   end
end

function gadget:GameFrame(n)
   if n%16~=0 then return end

   -- assign airbases & pads to units in pendingLanders
   -- once found, move into landingPlanes
   for unitID, _ in pairs(pendingLanders) do
      Spring.Echo("pending", unitID)
      local closestAirbaseID, closestPieceNum = FindAirBase(unitID)
      if closestAirbaseID then
         Spring.GiveOrderToUnit(unitID, CMD.INSERT,{0, LAND_AT_AIRBASE, 0, closestAirbaseID},{"alt"})
         landingPlanes[unitID] = {closestAirbaseID, closestPieceNum}
         pendingLanders[unitID] = nil
      end
   end

   -- snap landingPlanes into pads, if 'close enough'
   for unitID, t in pairs(landingPlanes) do
      Spring.Echo("landing", unitID)
      local airbaseID, padPieceNum = t[1], t[2]
      local px, py, pz = Spring.GetUnitPiecePosDir(airbaseID, padPieceNum)
      local ux, uy, uz = Spring.GetUnitPosition(unitID)
      local dx, dy ,dz = ux - px, uy - py, uz - pz
      local r = Spring.GetUnitRadius(unitID)
      local dist = dx * dx + dy * dy + dz * dz
      
      -- check if we're close enough, attach if so
      if dist < 0.5 * r * r then -- probably needs more attention
         landingPlanes[unitID] = nil
         landedPlanes[unitID] = true
         AttachToPad(unitID, airbaseID, padPieceNum)
      else
         Spring.SetUnitLandGoal(unitID, px, py, pz, r)
      end
   end

   -- check if any of our landed planes are finished repairing, release if so
   for unitID,_ in pairs(landedPlanes) do
      Spring.Echo("landed", unitID)
      local h,mh = Spring.GetUnitHealth(unitID)
      if h==mh then
         Spring.Echo("released", unitID)
         DetachFromPad(unitID)
         landedPlanes[unitID] = nil
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

   -- dummy UnitCreated events for existing units, to handle luarules reload
   local allUnits = Spring.GetAllUnits()
   for i=1,#allUnits do
      local unitID = allUnits[i]
      local unitDefID = Spring.GetUnitDefID(unitID)
      local teamID = Spring.GetUnitTeam(unitID)
      gadget:UnitCreated(unitID, unitDefID)
   end
end

function gadget:UnitLoaded(unitID, unitDefID, unitTeam, transportID, transportTeam)
    Spring.Echo("loaded", unitID)
end

function gadget:UnitUnloaded(unitID, unitDefID, unitTeam, transportID, transportTeam)
   Spring.Echo("unloaded", unitID)
end

--------------------------------------------------------------------------------
-- Unsynced
else
--------------------------------------------------------------------------------

function gadget:Initialize()
   Spring.AssignMouseCursor("Land for repairs", "cursorrepair", false, false)
   Spring.SetCustomCommandDrawData(CMD_LAND_AT_AIRBASE, "Land for repairs", {1,0.5,0,.8}, false)
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
         return LAND_AT_AIRBASE
      end
   end
   return false
end

end

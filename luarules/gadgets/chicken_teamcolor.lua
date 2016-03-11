
function gadget:GetInfo()
  return {
    name      = "Chicken Team Colour",
    desc      = "Changes the Chicken team colour as the queen gets angrier",
    author    = "TheFatController",
    date      = "Aug 07, 2011",
    license   = "MIT",
    layer     = 0, 
    enabled   = true  --  loaded by default?
  }
end

if  (gadgetHandler:IsSyncedCode()) then
    return false
end

local enabled = tonumber(Spring.GetModOptions().mo_chickengame) or 0
if (enabled == 0) then 
  return false
end

local chickenTeamID = Spring.GetGameRulesParam("chickenTeamID")

function gadget:GameFrame(n)
  if (n == 1) then
    chickenTeamID = Spring.GetGameRulesParam("chickenTeamID")
  end
  if (n%63< 1) then
    queenAnger = (Spring.GetGameRulesParam("queenAnger") or 0)
    gracePeriod = (Spring.GetGameRulesParam("gracePeriod") or 0)
    queenTime = (Spring.GetGameRulesParam("queenTime") or 0)
    queenAnger = 1 - math.ceil((((Spring.GetGameSeconds()-gracePeriod+queenAnger)/(queenTime-gracePeriod))*100) -0.5) / 100
    Spring.SetTeamColor(chickenTeamID, 1,queenAnger,queenAnger)
    Spring.Echo(1,queenAnger,queenAnger)
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
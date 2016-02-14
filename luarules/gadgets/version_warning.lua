function gadget:GetInfo()
  return {
    name      = "Version Warning",
    desc      = "Prints a warning if engine version is too low/high",
    author    = "Bluestone",
    date      = "Horses",
    license   = "",
    layer     = math.huge,
    enabled   = true  --  loaded by default?
  }
end

if (gadgetHandler:IsSyncedCode()) then
    return
end

local minEngineVersion = 101 -- major engine version as number
local maxEngineVersion = 101 -- don't forget to update it!
local wantedEngineVersions = ""
if minEngineVersion == maxEngineVersion then
    wantedEngineVersions = tostring(minEngineVersion) .. " or equivalent."
else
    wantedEngineVersions = tostring(minEngineVersion) .. " - " .. tostring(maxEngineVersion) .. " or equivalent."
end

local red = "\255\255\1\1"

function Warning()
    local reportedMajorVersion
    local devEngine
    if string.find(Game.version,".",1,true) then 
        local n = string.find(Game.version,".",1,true)
        reportedMajorVersion = string.sub(Game.version,1,n+1)    
        devEngine = true
    else 
        local n = string.len(Game.version)
        reportedMajorVersion = string.sub(Game.version,1,n+1)  
        devEngine = false
    end
    if not reportedMajorVersion then return end
    
    reportedMajorVersion = tonumber(reportedMajorVersion)
    if (not devEngine and reportedMajorVersion<minEngineVersion) or (devEngine and reportedMajorVersion+1<minEngineVersion) then
        Spring.Echo(red .. "WARNING: You are using Spring " .. Game.version .. ", which is too old for this game.")
        Spring.Echo(red .. "Please update your engine to  " .. wantedEngineVersions)
    elseif reportedMajorVersion>maxEngineVersion then
        Spring.Echo(red .. "WARNING: You are using Spring " .. Game.version .. " which is too recent for this game.")
        Spring.Echo(red .. "Please downgrade your engine to " .. wantedEngineVersions)
    end           
end

function gadget:GameStart()
    Warning()
end




--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

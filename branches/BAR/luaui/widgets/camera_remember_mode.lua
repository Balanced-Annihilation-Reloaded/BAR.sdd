function widget:GetInfo()
  return {
    name      = "Camera Remember",
    desc      = "Remembers the camera mode",
    author    = "Bluestone",
    date      = "April 1st",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true,
    reason_for_existence = "laughable"
  }
end

local camName
local defaultCamName = 'ta'

function widget:SetConfigData(data)
    camName = data and data.name or defaultCamName
end

function widget:Initialize()
    --Spring.Echo("wanted", camName)
    if camName then
        Spring.SendCommands("view" .. camName)
    end
end

--[[
function widget:GameFrame()
    local camState = Spring.GetCameraState()
    Spring.Echo(camState.name)
end
]]

function widget:GetConfigData()
    local camState = Spring.GetCameraState()
    local data = {}
    data.name = camState.name
    --Spring.Echo("saved", data.name, camState.mode)
    return data
end


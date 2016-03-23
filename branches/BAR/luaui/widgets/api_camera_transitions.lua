
function widget:GetInfo()
  return {
    name      = "Camera Transitions",
    desc      = "Provides functionality to smoothly move the camera",
    author    = "ashdnazg, Bluestone",
    date      = "",
    license   = "GPL v2 or later",
    layer     = -100,
    enabled   = true,  
    api     = true,
  }
end

local Camera = {}

local wantedCameraState
local wantedTransitionTime
local beginTime
local beginCameraState
local diffCamerState

-------------------------------

local function Sub(vector1, vector2)
    local result = {}
	for k, v in pairs(vector1) do
		if type(v) == "number" then
			result[k] = vector1[k] - vector2[k]
		end
	end
    return result
end

local function Add(vector1, vector2, exponent)
	local newVector = {}
	for k, v in pairs(vector1) do
		if type(v) == "number" then
			newVector[k] = v + (vector2[k] or 0) * exponent
		else
			newVector[k] = v
		end
	end
	return newVector
end

local function RemoveTilt(cs)
	--Disable engine's tilt when we press arrow key and move mouse
	cs.tiltSpeed = 0
	cs.scrollSpeed = 0
end

local function Superimpose(cs, newState)
	for k, v in pairs(newState) do
		cs[k] = v
	end
end

-------------------------------

function Clear()
    wantedCameraState = nil
    wantedTransitionTime = nil
    beginTime = nil
end

function MatchCameraMode(wantedCameraState)
    -- check this works
    local currentState = Spring.GetCameraState()
    local currentMode = currentState.mode
    local wantedMode = wantedCameraState.mode
    if currentMode ~= wantedMode then
        local cs = {mode=wantedMode}
		Spring.SetCameraState(cs)
	end    
end

function SetWantedCameraState(cameraState, transitionTime)
    if cameraState==nil then 
        Clear()
        return
    end
    
    MatchCameraMode(cameraState) -- because the 'Spring' camera mode is a prissy little bitch, we can't use a single SetCameraState call to change the camera type
    
    beginCameraState = Spring.GetCameraState() -- state from which the transition started
    beginTime = Spring.GetTimer() -- time at which the transition started
    wantedCameraState = cameraState -- target camera state
    wantedTransitionTime = transitionTime -- length of time the transition was asked to take
    diffCamerState = Sub(wantedCameraState, beginCameraState)
end

function widget:Initialize()
    WG.Camera = {}
    WG.Camera.SetWantedCameraState = SetWantedCameraState
end



function widget:Update()
    if not wantedCameraState then return end

    local lapsedTime = Spring.DiffTimers(Spring.GetTimer(), beginTime)
    if lapsedTime >= wantedTransitionTime then
        Spring.SetCameraState(wantedCameraState)
        Clear()
        return
    end
    
    local timeRatio = (wantedTransitionTime - lapsedTime) / (wantedTransitionTime) -- 1 at start, 0 at end
    local tweenExponent = 1.0 - math.pow(timeRatio, 4)
    
    local cs = Spring.GetCameraState()
    local newState = Add(beginCameraState, diffCamerState, tweenExponent) -- fixme: doesn't handle ctrl+scrollwheel interpolation correctly
    Superimpose(cs, newState)
    RemoveTilt(cs)
    Spring.SetCameraState(cs)
end




















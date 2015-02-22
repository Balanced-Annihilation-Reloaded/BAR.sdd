local versionNumber = "v2.91"

function widget:GetInfo()
	return {
		name = "Lock Camera",
		desc = "Allows you to lock onto another player's camera\n",
		author = "Evil4Zerggin, BrainDamage",
		date = "16 January 2009",
		license = "GNU LGPL, v2.1 or later",
		layer = -5,
		enabled = true
        api = true,
	}
end


local transitionTime = 1.5 --how long it takes the camera to move

local GetCameraState = Spring.GetCameraState
local SetCameraState = Spring.SetCameraState
local Echo = Spring.Echo

------------------------------------------------

local lockPlayerID
local lastBroadcasts = {}
local newBroadcaster = false
local totalTime = 0

local myLastCameraState

------------------------------------------------

function LockCamera(playerID)
	if playerID and playerID ~= myPlayerID and playerID ~= lockPlayerID then
		lockPlayerID = playerID
		myLastCameraState = myLastCameraState or GetCameraState()
		local info = lastBroadcasts[lockPlayerID]
		if info then
			SetCameraState(info[2], transitionTime)
		end
	else
		if myLastCameraState then
			SetCameraState(myLastCameraState, transitionTime)
			myLastCameraState = nil
		end
		lockPlayerID = nil
	end
end

WG.LockCamera = LockCamera


function CameraBroadcastEvent(playerID,cameraState)
	--if cameraState is empty then transmission has stopped
	if not cameraState then
		if lastBroadcasts[playerID] then
			lastBroadcasts[playerID] = nil
			newBroadcaster = true
		end
		if lockPlayerID == playerID then
			LockCamera()
		end
		return
	end

	if not lastBroadcasts[playerID] and not newBroadcaster then
		newBroadcaster = true
	end

	lastBroadcasts[playerID] = {totalTime, cameraState}

	if playerID == lockPlayerID then
		 SetCameraState(cameraState, transitionTime)
	end
end

function widget:Initialize()
	widgetHandler:RegisterGlobal('CameraBroadcastEvent', CameraBroadcastEvent)
end

function widget:Shutdown()
	widgetHandler:DeregisterGlobal('CameraBroadcastEvent')
end

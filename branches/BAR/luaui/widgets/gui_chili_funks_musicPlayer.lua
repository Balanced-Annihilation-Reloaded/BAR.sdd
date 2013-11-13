-- WIP heavily based on LEDs music player and music players before that
function widget:GetInfo()
	return {
		name    = 'Funks Music Player',
		desc    = 'Plays music according to the in-game action',
		author  = 'Funkencool',
		date    = 'Sep 2013',
		license = 'GNU GPL v2',
		layer   = 0,
		enabled = true
	}
end

local spGetGameSpeed       = Spring.GetGameSpeed
local spStopSoundStream    = Spring.StopSoundStream
local spPauseSoundStream   = Spring.PauseSoundStream
local spPlaySoundStream    = Spring.PlaySoundStream --setting volume here overrides and disables snd_volmusic
local spGetSoundStreamTime = Spring.GetSoundStreamTime
local spGetTimer           = Spring.GetTimer
local spDiffTimers         = Spring.DiffTimers
local spGetDrawFrame       = Spring.GetDrawFrame
local spGetMouseState      = Spring.GetMouseState
local spGetTeamUnits       = Spring.GetTeamUnits
local spGetUnitDefID       = Spring.GetUnitDefID
local spGetSpectatingState = Spring.GetSpectatingState
local spGetMyTeamID        = Spring.GetMyTeamID
local spGetTeamList        = Spring.GetTeamList
local spGetAllUnits        = Spring.GetAllUnits
local spGetUnitHealth      = Spring.GetUnitHealth
local Echo                 = Spring.Echo
local Chili

-- Chili vars
local musicControl, playButton, skipButton, songLabel, window0, pauseIcon, playIcon,volumeLbl, volume


local normalPEACE_VALUE 	= 0.0025 	-- below this, peace
local normalWAR_VALUE		  = 0.075 	-- above this, war
local normalWAR_COOLDOWN	= .0005  -- rate at which metalDestroyedCounter goes down
local PEACE_VALUE 	      = 0.0025 
local WAR_VALUE		        = 0.045
local WAR_COOLDOWN        = 0.002

local prevTrack                 = 1
local musicVolume 		          = Spring.GetConfigInt('snd_volmusic')
local generalVolume             = Spring.GetConfigInt('snd_volgeneral')
local masterVolume		          = Spring.GetConfigInt('snd_volmaster')
local musicType 				        = 0		-- 0 = peace, 1 = coldwar, 2 = war
local metalDestroyedCounter	    = 0	
local teamMetalTotal 					  = 0
local widgetTime = 0		-- Time elapsed since widget started, in seconds
local lastupdate = 0		-- time at which last metal calculation occurred
local ratioMetal = 1    -- how much the destroyed metal is above the war threshold, for dampening
                        -- added this so that it wouldn't play war music for too long if there was a long break in the fighting after a big battle
local spec 										= false
local debug 									= false
local warTracks     	= {}
local coldwarTracks 	= {}
local peaceTracks   	= {}
local CurrentTrack  	= nil
local info          	= ''
local LastTimer     	= nil
local LastPlayedTime	= 0
local playNew       	= true
local gameStarted 		= false

local labelVar         = 0
local labelString      = ''
local labelScrollSpeed = 5
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
-- Intialize --
----------------------------------------------------------------------------------------

function widget:Initialize()  --loads .ogg files from the directories to table
	for _,track in ipairs(VFS.DirList('music/war/','*.ogg')) do
		warTracks[#warTracks + 1] = track
	end
	for _,track in ipairs(VFS.DirList('music/coldwar/','*.ogg')) do
		coldwarTracks[#coldwarTracks + 1] = track
	end
	for _,track in ipairs(VFS.DirList('music/peace/','*.ogg')) do
		peaceTracks[#peaceTracks + 1] = track
	end
	
	musicType = 0
	metalDestroyedCounter = 0
	teamMetalTotal = 0
	widgetTime = 0
	lastupdate = 0
	
	Chili = WG.Chili
	local screen0 = Chili.Screen0
	
	volumeLbl = Chili.Label:New{caption = 'Volume:',bottom=13, right = 150}
	volume = Chili.Trackbar:New{
	 right = 85,
		height = 15, 
		bottom = 10, 
		width=60, 
		value=musicVolume,
		OnChange = {function(self)	Spring.SendCommands('set snd_volmusic ' .. self.value^2/100+1) end},
	}
	
	playIcon = Chili.Image:New{
	 x      = 4,
  y      = 8, 
	 right  = 4, 
	 bottom = 0,
	 file   = 'luaUI/Images/playsong.png'
	}
	
	pauseIcon = Chili.Image:New{
	 x      = 4,
  y      = 8, 
	 right  = 4, 
	 bottom = 0, 
	 file   = 'luaUI/Images/pausesong.png'
	}
	
	playButton = Chili.Button:New{
	 paused   = false,
	 right    = 42,
		bottom   = 0,
		width    = 40,
		height   = 40,
		padding 	= {8,8,8,8},
		caption  = '', 
		children = {pauseIcon},
		OnClick  = {
		 function(self) 
		  self:ClearChildren()
				Spring.PauseSoundStream()
		  if self.paused then 
				self.paused = false
				self:AddChild(pauseIcon)
		 	else
				self.paused = true
		 		self:AddChild(playIcon)
		 	end
		 end
		},
	}
	
	skipButton = Chili.Button:New{
	 right    = 0, 
		bottom   = 0, 
		width    = 40, 
		height   = 40, 
		padding 	= {8,8,8,8}, 
		caption  = '', 
		OnClick  = {function() playNew = true end},
		children = {
			Chili.Image:New{
				x      = 4,
				y      = 8, 
				right  = 4, 
				bottom = 0,
				file   = 'luaUI/Images/nextsong.png',
			}
		},
	}
	
	musicControl = Chili.Control:New{
		parent   = screen0,
		right    = 0, 
		y        = 45, 
		height   = 40, 
		width    = 300, 
		children = {skipButton,playButton,volume,volumeLbl},
	}
	
	songLabel = Chili.Label:New{x = 0, caption = 'No Song'}
	
	window0	= Chili.Window:New{
		parent    = screen0,
		minHeight = 0, 
		right     = 0, 
		y         = 30, 
		height    = 20,
		width     = 200,
		padding   = {5,2,5,0},
		children  = {songLabel},
	}
end

local function justTheName(text)
	local EndIndex=(string.find(text,'.',string.len(text)-4,true) or 1+string.len(text))-1
	local BeginIndex=1
	repeat
		local NewBeginIndex=string.find(text,'/',BeginIndex,true) or string.find(text,'\\',BeginIndex,true)
		BeginIndex=NewBeginIndex and NewBeginIndex+1 or BeginIndex
	until not NewBeginIndex
	return string.sub(text,BeginIndex,EndIndex)..'       '
end

local function playNewTrack(trackList)
	if not trackList then return end
	
	local betterRand = function() 
	 local x,y=spGetMouseState()
	 return x+y+math.floor(99*(os.clock()%99999)+(99*(os.time())%99999))
	end
	
	local track = trackList[1+(betterRand()%#trackList)]
	if prevTrack == track then
		track = trackList[1+(betterRand()%#trackList)]
	end

	prevTrack = track

	labelString = justTheName(track)
	songLabel:SetCaption(labelString)
	Spring.SendCommands('set snd_volmusic 0')
	Spring.SendCommands('set snd_volmusic ' .. volume.value^2/100+1)
	spPlaySoundStream(track)
end	
	 
function widget:Shutdown()
	spStopSoundStream()                                           
end

function widget:Update(dt)
	widgetTime = widgetTime + dt
	--update once per second
	if (widgetTime - lastupdate > 1) then

  local teamUnits
		lastupdate = widgetTime
		totalMetal = 0

		_, spec, _ = spGetSpectatingState()				

		if spec then
			teamUnits = spGetAllUnits()
		else --not spectator mode
			teamUnits = spGetTeamUnits(spGetMyTeamID())
		end

		for u = 1, #teamUnits do
			local uID = teamUnits[u]
			local uDefID = spGetUnitDefID(uID)
			local _, _, _, _, buildProg = spGetUnitHealth(uID)
			local unitMetalCost = UnitDefs[uDefID].metalCost*buildProg
			totalMetal = totalMetal + unitMetalCost
			teamMetalTotal = totalMetal
		end
			
			
		local PlayedTime, TotalTime = spGetSoundStreamTime()
		PlayedTime=PlayedTime or 0
		TotalTime=TotalTime or 0

		if PlayedTime>=TotalTime-0.1 then
			 playNew=true
		end
		
		if (teamMetalTotal > 0) then
		
			if (metalDestroyedCounter > (teamMetalTotal * WAR_VALUE)) then
				musicType = 2	--war!
				ratioMetal = metalDestroyedCounter / (teamMetalTotal * WAR_VALUE)
				WAR_COOLDOWN = normalWAR_COOLDOWN * ratioMetal ^ 2 
				if (metalDestroyedCounter > (2 * teamMetalTotal * WAR_VALUE)) and (musicType ~= 2) then
				 --immediate play
					playNew = true
				end
			elseif ((metalDestroyedCounter < teamMetalTotal * PEACE_VALUE)) then
				musicType = 0	--peace!
			else
				musicType = 1	--coldwar
			end	
			
		end
		
		if playNew then
				spStopSoundStream()			
				if musicType == 0 then
				 playNewTrack(peaceTracks)
					songLabel.font.color = {0.5,1,0.0,1}
					songLabel.font.outlineColor = {0.5,1,0.0,0.2}
				elseif musicType == 1 then
				 playNewTrack(coldWarTracks)
					songLabel.font.color = {1,0.5,0,1}
					songLabel.font.outlineColor = {1,0.5,0,0.2}
				elseif musicType == 2 then
				 playNewTrack(warTracks)
					songLabel.font.color = {1,0,0,1}
					songLabel.font.outlineColor = {1,0,0,0.2}
				end
				labelVar = 0
				playNew=false
		end
			
		local _,speed,paused = spGetGameSpeed()
		if not paused then
			metalDestroyedCounter = metalDestroyedCounter - (teamMetalTotal * WAR_COOLDOWN * speed)
			--clamp metal counter to positive values
			if (metalDestroyedCounter < 0) then
				metalDestroyedCounter = 0
			end
		end
	
	end
end


-- Scrolls song title ---------------------------------------
local oldn = 0
function widget:GameFrame(n)
	if n % labelScrollSpeed == 0 then
		local labelLen = string.len(labelString)
		if labelLen > 35 and (n - oldn) > 40 then
			if labelVar > labelLen then labelVar = 0; oldn = n end
			songLabel:SetCaption(string.sub(labelString, labelVar)..string.sub(labelString,0, labelVar-1))
			labelVar = labelVar + 1
		end
	end
end

-- Unit Callins ------------------------------------------------------------------------
function widget:UnitDestroyed(unitID, unitDefID, teamID)
	if spec then
		unitHealth, unitMaxHealth, paralyzeProgress, captureProgress, buildProgress = spGetUnitHealth(unitID)
		metalDestroyedCounter = metalDestroyedCounter + UnitDefs[unitDefID].metalCost*buildProgress
	elseif teamID == spGetMyTeamID() then
	 unitHealth, unitMaxHealth, paralyzeProgress, captureProgress, buildProgress = spGetUnitHealth(unitID)
	 metalDestroyedCounter = metalDestroyedCounter + UnitDefs[unitDefID].metalCost*buildProgress
	end
end
 
function widget:GetInfo()
	return {
		name      = "Battle Dynamic Music Player V1.1",
		desc      = "Plays .ogg music from music\* peace/coldwar/war folders according to the in-game action",
		author    = "LEDZ, Funkencool",
		date      = "May 19 2012",
		license   = "GNU GPL v2",
		layer     = 0,
		enabled   = true
	}
end

----------------------------------------------------------------------------------------[[
--[[
Readme:
To use, put appropriately themed .ogg files in peace/coldwar/war folders within the music folder:
Peace; calm, peaceful music
Coldwar; more somber, ominous and suggestive of trouble
War; Exciting music will work well here.

At a certain level past the war threshold, the music will immediately switch to war,
so if there's a big fight, the war music will cut-in just as you would expect

Type /luaui nextsong to skip and /luaui debugmusic to see some information of the variables used to pick type of music

This widget has borrowed heavily from Jool's snd_volume_osd.lua
Functionality of the music player is an improvement on zwzsg's music.lua and Vebyast's gui_OTA_music_adv.lua
--]]
----------------------------------------------------------------------------------------
-- Spring accelerators --
----------------------------------------------------------------------------------------            

local spGetGameSpeed = Spring.GetGameSpeed
local spStopSoundStream = Spring.StopSoundStream
local spPauseSoundStream = Spring.PauseSoundStream
local spPlaySoundStream = Spring.PlaySoundStream --setting volume here overrides and disables snd_volmusic
local spGetSoundStreamTime = Spring.GetSoundStreamTime
local spGetTimer = Spring.GetTimer
local spDiffTimers = Spring.DiffTimers
local spGetDrawFrame = Spring.GetDrawFrame
local spGetMouseState = Spring.GetMouseState
local spGetTeamUnits = Spring.GetTeamUnits
local spGetUnitDefID = Spring.GetUnitDefID
local spGetSpectatingState = Spring.GetSpectatingState
local spGetMyTeamID = Spring.GetMyTeamID
local spGetTeamList = Spring.GetTeamList
local spGetAllUnits = Spring.GetAllUnits
local spGetUnitHealth = Spring.GetUnitHealth
local Echo = Spring.Echo
local Chili

local musicControl, playButton, skipButton, songLabel, window0, pauseIcon, playIcon
----------------------------------------------------------------------------------------
-- Music Volume draw --
----------------------------------------------------------------------------------------

local musicVolume
local TextDraw            		= gl.Text
local vsx,vsy                	= gl.GetViewSizes()
local widgetPosX 							= vsx/3
local widgetPosY 							= vsy/6
local pressedToMove		 				= false
local altdown
local dt											= -1
local drawDelay 							= 0


----------------------------------------------------------------------------------------
-- Dynamic Music --
----------------------------------------------------------------------------------------
local normalPEACE_VALUE 	= 0.0025 	-- below this, peace
local normalWAR_VALUE		= 0.075 	-- above this, war
local normalWAR_COOLDOWN	= .0005  -- rate at which metalDestroyedCounter goes down
local PEACE_VALUE 	= 0.0025 
local WAR_VALUE		= 0.045
local WAR_COOLDOWN = 0.002

local musicVolume 						= Spring.GetConfigInt("snd_volmusic")
local generalVolume 					= Spring.GetConfigInt("snd_volgeneral")
local masterVolume						= Spring.GetConfigInt("snd_volmaster")
local musicType 							= 0		-- 0 = peace, 1 = coldwar, 2 = war
local metalDestroyedCounter		= 0	
local teamMetalTotal 					= 0
local widgetTime 							= 0		-- Time elapsed since widget started, in seconds
local lastupdate 							= 0		-- time at which last metal calculation occurred
local ratioMetal 							= 1   -- how much the destroyed metal is above the war threshold, for dampening
-- added this so that it wouldn't play war music for too long if there was a long break in the fighting after a big battle
local spec 										= false
local debug 									= false
local numPlayers 							= {}
local warTracks      					= {}
local coldwarTracks  					= {}
local peaceTracks     				= {}
local CurrentTrack   					= nil
local info           					= ""
local LastTimer      					= nil
local LastPlayedTime 					= 0
local playNew        					= true
local gameStarted 						= false

local labelVar								= 0
local labelString							= ""
local labelScrollSpeed				= 5
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
-- Intialize --
----------------------------------------------------------------------------------------

function widget:Initialize()  --loads .ogg files from the directories to table
	for _,track in ipairs(VFS.DirList('music/War/','*.ogg')) do
		table.insert(warTracks,track)
	end
	for _,track in ipairs(VFS.DirList('music/Coldwar/','*.ogg')) do
		table.insert(coldwarTracks,track)
	end
	for _,track in ipairs(VFS.DirList('music/Peace/','*.ogg')) do
		table.insert(peaceTracks,track)
	end
	musicType = 0
	curMusicType = 0
	metalDestroyedCounter = 0
	teamMetalTotal = 0
	widgetTime = 0
	lastupdate = 0
	
	Chili = WG.Chili
	local screen0 = Chili.Screen0
	
	skipButton  	= Chili.Button:New{right = 0, bottom = 0, width = 40, height = 40, padding 	= {8,8,8,8}, caption = "", children = {
		Chili.Image:New{width = "100%", height = "95%", x = 0, bottom = 0, file = "luaUI/Images/nextsong.png", OnClick = {function() playNew = true end},}}}

	playIcon 			= Chili.Image:New{width = "100%", height = "95%", x = 0, bottom = 0, file = "luaUI/Images/playsong.png", OnClick = {function() playButton:ClearChildren(); playButton:AddChild(pauseIcon);spPauseSoundStream() end},}
	pauseIcon			= Chili.Image:New{width = "100%", height = "95%", x = 0, bottom = 0, file = "luaUI/Images/pausesong.png", OnClick = {function() playButton:ClearChildren(); playButton:AddChild(playIcon); spPauseSoundStream() end},}
	playButton  	= Chili.Button:New{right = 35, bottom = 0, width = 40, height = 40, padding 	= {8,8,8,8}, caption = "", children = {pauseIcon}}
	songLabel		 	= Chili.Label:New{x = 0, caption = "No Song"}
	musicControl 	= Chili.Control:New{parent = screen0,right = 0, y = 85, height = 40, width = 300, children = {skipButton,playButton}, borderColor = {0,0,0,0}}
	window0			 	= Chili.Window:New{parent = screen0,minHeight = 0, right = 0, y = 70, height = 20, width = 200, children = {songLabel}, padding = {5,2,5,0}}
end

local function JustTheName(text)
	local EndIndex=(string.find(text,".",string.len(text)-4,true) or 1+string.len(text))-1
	local BeginIndex=1
	repeat
		local NewBeginIndex=string.find(text,"/",BeginIndex,true) or string.find(text,"\\",BeginIndex,true)
		BeginIndex=NewBeginIndex and NewBeginIndex+1 or BeginIndex
	until not NewBeginIndex
	return string.sub(text,BeginIndex,EndIndex).."       "
end
 
function widget:Shutdown()
	spStopSoundStream()                                           
end
 
function widget:Update(dt)
	widgetTime = widgetTime + dt
	--update once per second
	if (widgetTime - lastupdate > 1) then
		lastupdate = widgetTime
		_, fullView, _ = spGetSpectatingState()
		if fullView then
			spec = true
		else
			spec = false
		end
		totalMetal = 0

				
		if spec then
			local teamUnits = spGetAllUnits()
			for u = 1, #teamUnits do
				local uID = teamUnits[u]
				local uDefID = spGetUnitDefID(uID)
				local _, _, _, _, buildProg = spGetUnitHealth(uID)
				local unitMetalCost = UnitDefs[uDefID].metalCost*buildProg
				totalMetal = totalMetal + unitMetalCost
				teamMetalTotal = totalMetal
			end
			if Spring.GetGaiaTeamID() then
				numPlayers = #spGetTeamList() - 1
			else
				numPlayers = #spGetTeamList()
			end
			
--[[
			PEACE_VALUE = normalPEACE_VALUE / (numPlayers)
			WAR_VALUE = normalWAR_VALUE / (numPlayers)
			WAR_COOLDOWN = normalWAR_COOLDOWN /(numPlayers) --will be reset below so needs adapting
--]]
		else --not spectator mode
			local teamUnits = spGetTeamUnits(spGetMyTeamID())
			for u = 1, #teamUnits do
				local uID = teamUnits[u]
				local uDefID = spGetUnitDefID(uID)
				local _, _, _, _, buildProg = spGetUnitHealth(uID)
				local unitMetalCost = UnitDefs[uDefID].metalCost*buildProg
				totalMetal = totalMetal + unitMetalCost
				teamMetalTotal = totalMetal
			end
		end

		local PlayedTime, TotalTime = spGetSoundStreamTime()
		PlayedTime=PlayedTime or 0
		TotalTime=TotalTime or 0
		if not LastTimer then
		 LastTimer=spGetTimer()
		 return
		end
		local Timer=spGetTimer()
		if spDiffTimers(Timer,LastTimer)>2 and (PlayedTime>=TotalTime-0.1 or PlayedTime==0) then
			LastTimer=Timer
			if LastPlayedTime==PlayedTime then
				playNew=true
			else
				LastPlayedTime=PlayedTime
			end
		end
		if (teamMetalTotal > 0) then
			if (metalDestroyedCounter > (teamMetalTotal * WAR_VALUE)) then
				musicType = 2	--war!
				if (metalDestroyedCounter > (2 * teamMetalTotal * WAR_VALUE)) and (curMusicType ~= 2) then
					playNew = true
				end
			end
			
			if (metalDestroyedCounter > (teamMetalTotal * PEACE_VALUE)) and (metalDestroyedCounter < (teamMetalTotal * WAR_VALUE)) then 
				musicType = 1	--coldwar
			end	
		
			if ((metalDestroyedCounter < teamMetalTotal * PEACE_VALUE)) then
				musicType = 0	--peace!
			end
			
			if (metalDestroyedCounter > (teamMetalTotal * WAR_VALUE)) then
				ratioMetal = metalDestroyedCounter / (teamMetalTotal * WAR_VALUE)
				COOLDOWNaccelerator = true
				WAR_COOLDOWN = normalWAR_COOLDOWN * ratioMetal * ratioMetal
			else
				COOLDOWNaccelerator = false
				WAR_COOLDOWN = normalWAR_COOLDOWN
			end
		end
		
		if playNew then
			if not warTracks or #warTracks<1 then
				Spring.Echo("\255\1\205\205No music found for War! Copy some .ogg files into \\music\\war")
				widgetHandler:RemoveWidget()
			elseif not coldwarTracks or #coldwarTracks<1 then                                                               
				Spring.Echo("\255\1\205\205No music found for Coldwar! Copy some .ogg files into \\music\\coldwar")
				widgetHandler:RemoveWidget()
			elseif not peaceTracks or #peaceTracks<1 then
				Spring.Echo("\255\1\205\205No music found for Peace! Copy some .ogg files into \\music\\peace")
				widgetHandler:RemoveWidget()                          
			else
				local x,y=spGetMouseState()
				local BetterRand=x+y+math.floor(99*(os.clock()%99999)+(99*(os.time())%99999))--+spGetDrawFrame()+math.random(0,999)
				--Pick random track that wasn't just played
				
				curWarTrack = warTracks[1+(BetterRand%#warTracks)]
				if #warTracks == 1 then
					curWarTrack = warTracks[1]
				end
				if #warTracks >= 2 then
					if prevWarTrack == curWarTrack then
						curWarTrack = warTracks[1+(BetterRand%#warTracks)]
					end
				end
				prevWarTrack = curWarTrack
				
				curColdwarTrack = coldwarTracks[1+(BetterRand%#coldwarTracks)]
				if #coldwarTracks == 1 then
					curColdwarTrack = coldwarTracks[1]
				end
				if #coldwarTracks >= 2 then
					if prevColdwarTrack == curColdwarTrack then
						curColdwarTrack = coldwarTracks[1+(BetterRand%#coldwarTracks)]
					end
				end
				prevColdwarTrack = curColdwarTrack
				
				curPeaceTrack = peaceTracks[1+(BetterRand%#peaceTracks)]
				if #peaceTracks == 1 then
					curPeaceTrack = peaceTracks[1]
				end
				if #peaceTracks >= 2 then
					if prevPeaceTrack == curPeaceTrack then
						curPeaceTrack = peaceTracks[1+(BetterRand%#peaceTracks)]
					end
				end
				prevPeaceTrack = curPeaceTrack
				
				spStopSoundStream()
				if musicType == 0 then
					labelString = JustTheName(curPeaceTrack)
					songLabel:SetCaption(labelString)
					spPlaySoundStream(curPeaceTrack)
					songLabel.font.color = {0.5,1,0.0,1}
					songLabel.font.outlineColor = {0.5,1,0.0,0.2}
					curMusicType = 0
				elseif musicType == 1 then
					labelString = JustTheName(curColdwarTrack)
					songLabel:SetCaption(labelString)
					spPlaySoundStream(curColdwarTrack)
					songLabel.font.color = {1,0.5,0,1}
					songLabel.font.outlineColor = {1,0.5,0,0.2}
					curMusicType = 1
				elseif musicType == 2 then
					labelString = JustTheName(curWarTrack)
					songLabel:SetCaption(labelString)
					spPlaySoundStream(curWarTrack)
					curMusicType = 2
					songLabel.font.color = {1,0,0,1}
					songLabel.font.outlineColor = {1,0,0,0.2}
				end
				labelVar = 0
				playNew=false
			end
		end
			
		local _,speed,paused = spGetGameSpeed()
		if(not paused) then
			metalDestroyedCounter = metalDestroyedCounter - (teamMetalTotal * WAR_COOLDOWN * speed)
			--clamp metal counter to positive values
			if (metalDestroyedCounter < 0) then
				metalDestroyedCounter = 0
			end
		end
		
	end
end

function widget:TextCommand(command)
  if (string.find(command, 'nextsong') == 1) then
    playNew = true
  elseif (string.find(command, 'debugmusic') == 1) and debug == false then
  	debug = true
  elseif (string.find(command, 'debugmusic') == 1) and debug == true then
  	debug = false
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
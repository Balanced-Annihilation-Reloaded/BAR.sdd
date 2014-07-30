-- WIP heavily based on LEDs music player and music players before that
function widget:GetInfo()
	return {
		name    = 'Music Player',
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
local spPlaySoundStream    = Spring.PlaySoundStream
local spGetSoundStreamTime = Spring.GetSoundStreamTime
local spGetDrawFrame       = Spring.GetDrawFrame
local spGetUnitHealth      = Spring.GetUnitHealth

local Chili, Menu
local musicControl, playButton, skipButton, songLabel, window0, pauseIcon, playIcon,volumeLbl, volume

local lowThreshold 	= 0.0025 
local highThreshold	= 0.045
local peakThreshold = 0.06
local cooldownRate  = 0.001
local destruction	  = 0
local totalHealth   = 0

local musicVolume 	= Spring.GetConfigInt('snd_volmusic')
local generalVolume = Spring.GetConfigInt('snd_volgeneral')
local masterVolume	= Spring.GetConfigInt('snd_volmaster')


local tracks = VFS.Include('Music/music.lua') or false
local myTeamID  = Spring.GetMyTeamID()
local isSpec 	  = false
local playNew   = true
local musicType = 'peace'
local curTrack = {}

local disabledTracks = {}

function widget:GetConfigData()
	return disabledTracks
end

function widget:SetConfigData(data)
	if (data and type(data) == 'table') then
		disabledTracks = data
	end
end


local color = {
	war     = {1,0,0,1},
	coldWar = {1,0.5,0,1},
	peace   = {0.5,1,0.0,1},
}

local outlineColor = {
	war     = {1,0,0,0.2},
	coldWar = {1,0.5,0,0.2},
	peace   = {0.5,1,0.0,0.2},
}


local labelVar         = 0
local trackName        = ''
local labelScrollSpeed = 10

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
-- Intialize --
----------------------------------------------------------------------------------------
local function loadOptions()
	local typeTitle = {peace = "Peace", coldWar = "Cold War", war = "War"}
	
	local control = Chili.Control:New{
		x        = 0,
		y        = 0,
		right    = 0,
		bottom   = 0,
		padding  = {5,5,5,5},
	}
	
	local trackList = Chili.StackPanel:New{
		x           = 0,
		y           = 0,
		width       = '100%',
		resizeItems = false,
		autosize    = true,
		padding     = {0,0,0,0},
		itemPadding = {0,0,0,0},
		itemMargin  = {0,0,0,0},
		preserverChildrenOrder = true
	}
	
	for trackType, list in pairs(tracks) do
		Chili.Label:New{parent=trackList,caption=typeTitle[trackType]}
		for trackName,_ in pairs(list) do
			local title = list[trackName].title
			Chili.Checkbox:New{
				caption   = title,
				parent    = trackList,
				--height    = 20,
				width     = '80%',
				x         = '10%',
				textalign = 'left',
				boxalign  = 'right',
				checked   = not disabledTracks[title],
				OnChange  = {
					function(self)
						if curTrack.title == title then playNew = true end
						disabledTracks[title] = self.checked
					end
				}
			}
		end
	end
	
	Chili.ScrollPanel:New{
		parent    = control,
		x         = 0,
		y         = 40,
		right     = 0,
		bottom    = 0,
		children  = {trackList},
	}
	
	Menu.AddControl('Music',control)
		
end

local function createUI()
	
	local screen0 = Chili.Screen0
	
	volumeLbl = Chili.Label:New{caption = 'Vol:',bottom=10, right = 150}
	volume = Chili.Trackbar:New{
		right    = 85,
		height   = 15, 
		bottom   = 10, 
		width    = 60, 
		value    = musicVolume,
		OnChange = {function(self)	Spring.SendCommands('set snd_volmusic ' .. self.value) end},
	}
	
	playIcon = Chili.Image:New{
		x      = 4,
		y      = 8, 
		right  = 4, 
		bottom = 0,
		hidden = true,
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
		children = {pauseIcon, playIcon},
		OnClick  = {
			function(self)
				Spring.PauseSoundStream()
				if self.paused then
					pauseIcon:Show()
					playIcon:Hide()
				else
					pauseIcon:Hide()
					playIcon:Show()
				end
				self.paused = not self.paused
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
		y        = 75, 
		height   = 40, 
		width    = 300, 
		children = {skipButton,playButton,volume,volumeLbl},
	}
	
	songLabel = Chili.Label:New{x = 0, caption = 'No Song'}
	
	window0	= Chili.Window:New{
		parent    = screen0,
		minHeight = 0, 
		right     = 0, 
		y         = 60, 
		height    = 20,
		width     = 200,
		padding   = {5,2,5,0},
		children  = {songLabel},
	}
end

local function playNewTrack()
	
	local trackList = tracks[musicType]
	local track
	repeat
		track = trackList[math.random(1, #trackList)]
	until not disabledTracks[track.title] and (track.filename ~= curTrack.filename)
	
	curTrack = track
	
	trackName = curTrack.title..'       '
	songLabel.font.color = color[musicType]
	songLabel.font.outlineColor = outlineColor[musicType]
	songLabel:SetCaption(trackName)
	
	-- hack fix, needs to be set multiple times to work
	-- I set it 3 times in case two are the same ( and it goes full volume :/ )
	Spring.SendCommands('set snd_volmusic 0')
	Spring.SendCommands('set snd_volmusic 1')
	Spring.SendCommands('set snd_volmusic ' .. volume.value)
	spPlaySoundStream('music/'..musicType..'/'..curTrack.filename)
end	

local function checkStatus()

	local teamUnits
	
	local playedTime, totalTime = spGetSoundStreamTime()
	playedTime = playedTime or 0
	totalTime  = totalTime or 0
	
	if playedTime >= totalTime - 1 then
		playNew = true
	end
	
	
	if destruction > totalHealth * highThreshold then
		if destruction > totalHealth * peakThreshold and musicType ~= 'war' then
			destruction = totalHealth * highThreshold
			playNew = true
		end	
		musicType = 'war'
	elseif destruction > totalHealth * lowThreshold then
		musicType = 'coldWar'
	else
		musicType = 'peace'
	end	
	
	
	if playNew then
		spStopSoundStream()		
		playNewTrack()
		labelVar = 0
		playNew = false
	end
	
	if destruction > totalHealth * peakThreshold then
		destruction = totalHealth * peakThreshold
	end	
	
	destruction = destruction - (totalHealth * cooldownRate)
	
	if destruction < 0 then
		destruction = 0
	end
end

local function scrollName()
	local length = string.len(trackName)
	if length > 35 then
		if labelVar > length then labelVar = 0 end
		songLabel:SetCaption(string.sub(trackName, labelVar)..string.sub(trackName,0, labelVar-1))
		labelVar = labelVar + 1
	end
end


----------------------------------------------------
-- Callins
----------------------------------------------------

function widget:GameFrame(n)

	-- Check battle status
	if n % 30 == 0 then
		checkStatus()
	end
	
	-- Scroll Song Title
	if n % labelScrollSpeed == 0 then
		scrollName()
	end

end

function widget:Initialize()
	if not tracks then
		return 
	end
	isSpec = Spring.GetSpectatingState()
	
	Chili = WG.Chili
	createUI()
	
	Menu = WG.MainMenu
	if Menu then
		loadOptions()
	end
	
end

function widget:UnitCreated(_, unitDefID, teamID)
	if isSpec or teamID == myTeamID then
		totalHealth = totalHealth + UnitDefs[unitDefID].health
	end
end

function widget:UnitDestroyed(_, unitDefID, teamID)
	if isSpec or teamID == myTeamID then
		totalHealth  = totalHealth - UnitDefs[unitDefID].health
	end
end

function widget:UnitDamaged(_, _, teamID, damage)
	if isSpec or teamID == myTeamID then
		destruction = destruction + damage
	end
end

function widget:Shutdown()
	spStopSoundStream()                                           
end

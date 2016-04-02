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


local spGetGameSpeed         = Spring.GetGameSpeed
local spStopSoundStream      = Spring.StopSoundStream
local spPauseSoundStream     = Spring.PauseSoundStream
local spPlaySoundStream      = Spring.PlaySoundStream
local spGetSoundStreamTime   = Spring.GetSoundStreamTime
local spSetSoundStreamVolume = Spring.SetSoundStreamVolume
local spGetDrawFrame         = Spring.GetDrawFrame
local spGetUnitHealth        = Spring.GetUnitHealth

local Chili, Menu
local musicControl, playButton, skipButton, songLabel, window0, pauseIcon, playIcon,volumeLbl, volume

local lowThreshold     = 0.0025 
local highThreshold    = 0.045
local peakThreshold = 0.06
local cooldownRate  = 0.001
local destruction      = 0
local totalHealth   = 0

local musicVolume     = Spring.GetConfigInt('snd_volmusic')
local battleVolume = Spring.GetConfigInt('snd_volbattle')
local masterVolume    = Spring.GetConfigInt('snd_volmaster')

local notePic  = "LuaUI/Images/musical_note.png"
local tankPic  = "LuaUI/Images/small_tank.png"

local buttonColour, panelColour, sliderColour 

local tracks = VFS.Include('Music/music.lua') or false
local myTeamID  = Spring.GetMyTeamID()
local isSpec = false

local playNew = true
local fadeOut = false
local mood = 'peace'
local curTrack = {}
local options = {}
options.disabledTracks = {}

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
local trackLabel        = ''
local labelScrollSpeed = 10

local music_credits = VFS.LoadFile('credits_music.txt')

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
    
    local toggleTrack = function(self)
        if curTrack.title == self.caption then playNew = true end
        options.disabledTracks[self.caption] = self.checked
        
        if self.checked then
            self.font.color        = {1,0,0,1}
            self.font.outlineColor = {1,0,0,0.2}
        else
            self.font.color        = {0.5,1,0,1}
            self.font.outlineColor = {0.5,1,0,0.2}
        end
        self:Invalidate()
    end 
    
    for trackType, list in pairs(tracks) do
        Chili.Label:New{x='0%',fontsize=18,height=25,parent=trackList,caption=typeTitle[trackType]}
        for trackName,_ in pairs(list) do
            local green  = {color = {0.5,1,0,1}, outlineColor = {0.5,1,0,0.2}}
            local red    = {color = {1,0,0,1}, outlineColor = {1,0,0,0.2}}
            local title = list[trackName].title
            Chili.Checkbox:New{
                caption   = title,
                parent    = trackList,
                --height    = 20,
                width     = '80%',
                x         = '10%',
                textalign = 'left',
                boxalign  = 'right',
                checked   = not options.disabledTracks[title],
                font      = options.disabledTracks[title] and red or green,
                OnChange  = {toggleTrack}
            }
        end
    end
    
    trackList:AddChild(Chili.TextBox:New{width='100%',text= "\n\n\n" .. "\255\200\200\240" .. music_credits .. "\n\n"})

    Chili.ScrollPanel:New{
        parent    = control,
        x         = 0,
        y         = 0,
        right     = 0,
        bottom    = 0,
        children  = {trackList},
        borderColor = {0,0,0,0},
        backgroundColor = {0,0,0,0}
    }
    
    Menu.AddTab('Music',control)
        
end

local function createUI()
    
    local screen0 = Chili.Screen0

    -- extra sliders for individual battle/music volumes

    battle_volume = Chili.Trackbar:New{
        right    = 45,
        height   = 15, 
        bottom   = 0, 
        width    = 100, 
        value    = battleVolume,
        borderColor = sliderColour,
        backgroundColor = sliderColour,
       OnChange = {function(self)    Spring.SendCommands('set snd_volbattle ' .. self.value) end},
    }

    battle_pic = Chili.Image:New{
        bottom = 1, 
        right  = 150,
        width  = 15,
        height = 15,
        file   = tankPic,
    }

    music_volume = Chili.Trackbar:New{
        right    = 45,
        height   = 15, 
        bottom   = 20, 
        width    = 100, 
        value    = musicVolume,
        borderColor = sliderColour,
        backgroundColor = sliderColour,
        OnChange = {function(self)    Spring.SendCommands('set snd_volmusic ' .. self.value) end},
    }

    music_pic = Chili.Image:New{
        bottom = 22, 
        right = 150,
        width = 15,
        height = 15,
        file = notePic,
    }

    extra_sliders = Chili.Control:New{
        parent   = screen0,
        right    = 0, 
        y        = 105, 
        height   = 65, 
        width    = 200, 
        children = {battle_pic, battle_volume, music_pic, music_volume},
    }

    local function ToggleSepSliders()
        extra_sliders:ToggleVisibility()
    end
    
    vol_button = Chili.Button:New{
        caption = 'Vol',
        bottom  = 8, 
        right   = 150,
        width   = 35,
        height  = 22,
        borderColor = buttonColour,
        backgroundColor = buttonColour,
        onclick = {ToggleSepSliders},
    }

    -- normally displayed gui

    master_volume = Chili.Trackbar:New{
        right    = 85,
        height   = 15, 
        bottom   = 10, 
        width    = 60, 
        value    = masterVolume,
        borderColor = sliderColour,
        backgroundColor = sliderColour,
          OnChange = {function(self)    Spring.SendCommands('set snd_volmaster ' .. self.value) end},
    }
    
    playIcon = Chili.Image:New{
        name   = 'playIcon',
        x      = 4,
        y      = 8, 
        right  = 4, 
        bottom = 0,
        file   = 'luaUI/Images/playsong.png',
    }
    
    pauseIcon = Chili.Image:New{
        name   = 'pauseIcon',
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
        padding     = {8,8,8,8},
        borderColor = buttonColour,
        backgroundColor = buttonColour,
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
                if not self.paused then
                    checkStatus(true)
                end
            end
        },
    }
    playIcon:Hide()
    
    skipButton = Chili.Button:New{
        right    = 0, 
        bottom   = 0, 
        width    = 40, 
        height   = 40, 
        padding     = {8,8,8,8}, 
        borderColor = buttonColour,
        backgroundColor = buttonColour,
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
        y        = 95, 
        height   = 40, 
        width    = 300, 
        children = {skipButton, playButton, master_volume, vol_button},
    }
    
    songLabel = Chili.Label:New{x = 0, caption = 'No Song'}
    
    window0    = Chili.Window:New{
        parent    = screen0,
        minHeight = 0, 
        right     = 5, 
        y         = 80, 
        height    = 20,
        width     = 200,
        padding   = {5,2,5,0},
        color = buttonColour,
        children  = {songLabel},
    }
end

function playNewTrack()

    local moodChoices = tracks[mood]
    local track
    repeat
        track = moodChoices[math.random(1, #moodChoices)]
    until not options.disabledTracks[track.title] and (track.filename ~= curTrack.filename)

    curTrack = track
    curTrack.mood = mood
    trackLabel = curTrack.title..'       '
    songLabel.font.color = color[mood]
    songLabel.font.outlineColor = outlineColor[mood]
    songLabel:SetCaption(trackLabel)
    
    -- hack fix, needs to be set multiple times to work
    -- I set it 3 times in case two are the same ( and it goes full volume :/ )
    Spring.SendCommands('set snd_volmusic 0')
    Spring.SendCommands('set snd_volmusic 1')
    Spring.SendCommands('set snd_volmusic ' .. master_volume.value)
    spPlaySoundStream('music/'..mood..'/'..curTrack.filename)
end    

function checkStatus(unPause)
    -- cool down destruction
    local hitPeak = false
    if destruction > totalHealth * peakThreshold then
        destruction = totalHealth * peakThreshold
        hitPeak = true
    end        
    destruction = destruction - (totalHealth * cooldownRate)
    if destruction < 0 then
        destruction = 0
    end

    if playButton.paused then return end

    -- change music if needed
    local playedTime, totalTime = spGetSoundStreamTime()
    playedTime = playedTime or 0
    totalTime  = totalTime or 0
    
    if playedTime >= totalTime - 1 and Spring.GetConfigInt("Sound")~=0 then
        playNew = true
    end
    
    if destruction > totalHealth * highThreshold then
        if hitPeak and curTrack.mood ~= 'war' then
            if not unPause then
                fadeOut = Spring.GetGameFrame()
            else
                playNew = true
            end
        end    
        mood = 'war'
    elseif destruction > totalHealth * lowThreshold then
        mood = 'coldWar'
    else
        mood = 'peace'
    end    
    
    
    if playNew then
        spStopSoundStream()        
        playNewTrack()
        labelVar = 0
        playNew = false
    end
end

local function scrollName()
    local length = string.len(trackLabel)
    if length > 35 then
        if labelVar > length then labelVar = 0 end
        songLabel:SetCaption(string.sub(trackLabel, labelVar)..string.sub(trackLabel,0, labelVar-1))
        labelVar = labelVar + 1
    end
end


----------------------------------------------------
-- Callins
----------------------------------------------------

function widget:GameFrame(n)

    -- Fade current track, then play another
    if fadeOut then
        local wantedVol = 1 - math.sqrt((n-fadeOut)/(30))
        if wantedVol>=0 then
            spSetSoundStreamVolume(wantedVol)
        else
            spStopSoundStream()
            fadeOut = false
            playNew = true
        end    
    else
        spSetSoundStreamVolume(1)
    end

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
    buttonColour = WG.buttonColour
    panelColour = WG.panelColour
    sliderColour = WG.sliderColour
    createUI()
    
    Menu = WG.MainMenu
    if Menu then
        loadOptions()
    end

    local units = Spring.GetAllUnits()
    for _,unitID in ipairs(units) do
        local teamID = Spring.GetUnitTeam(unitID)
        local unitDefID = Spring.GetUnitDefID(unitID)
        widget:UnitCreated(unitID, unitDefID, teamID)
    end
    
    extra_sliders:Hide()
    spSetSoundStreamVolume(1)
end

local healthUnitID = {}
function widget:UnitCreated(unitID, unitDefID, teamID)
    if isSpec or teamID == myTeamID then
        totalHealth = totalHealth + UnitDefs[unitDefID].health
        healthUnitID[unitID] = true
    end
end

function widget:UnitDestroyed(unitID, unitDefID, teamID)
    if healthUnitID[unitID] then
        totalHealth  = totalHealth - UnitDefs[unitDefID].health
        healthUnitID[unitID] = nil
    end
end

function widget:UnitDamaged(unitID, unitDefID, teamID, damage)
    if healthUnitID[unitID] then
        local _,mh = Spring.GetUnitHealth(unitID)
        destruction = destruction + math.max(mh,damage)
    end
end

function widget:PlayerChanged()
    isSpec = Spring.GetSpectatingState()
    myTeamID = Spring.GetMyTeamID()
end

function widget:Shutdown()
    spStopSoundStream()                                           
end

function widget:GetConfigData()
    return options
end

function widget:SetConfigData(data)
    if data then
        options = data
    end
end

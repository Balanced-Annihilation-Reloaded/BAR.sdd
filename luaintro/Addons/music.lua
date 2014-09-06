
if addon.InGetInfo then
	return {
		name    = "Music",
		desc    = "plays music",
		author  = "jK",
		date    = "2012,2013",
		license = "GPL2",
		layer   = 0,
		depend  = {"LoadProgress"},
		enabled = true,
	}
end

------------------------------------------

Spring.SetSoundStreamVolume(1)

local sounds = VFS.DirList("luaintro/sounds", "*.ogg")
local startedSound = false


function addon.DrawLoadScreen()
	local loadProgress = SG.GetLoadProgress()

    if not startedSound and (#sounds > 0) then
        Spring.PlaySoundStream(sounds[math.random(#sounds)], 1)
        startedSound = true
    end
    
	-- fade out  with progress
	if (loadProgress > 0.7) then
		Spring.SetSoundStreamVolume(0.7 + ((0.7 - loadProgress) * 7))
	end
end


function addon.Shutdown()
	Spring.StopSoundStream()
	Spring.SetSoundStreamVolume(1)
end

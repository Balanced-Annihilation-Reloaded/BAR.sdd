-- shiva --
-- a unit script for BA remake --
-- by FireStorm --

-- s3o Pieces
local base = piece "base"
local pelvis = piece "pelvis"
local torso = piece "torso"

local ldoor = piece "ldoor"
local rdoor = piece "rdoor"
local rlauncher = piece "rlauncher"
local rocketflare = piece "rocketflare"

local lturret = piece "lturret"
local lrecoil = piece "lrecoil"
local lflare = piece "lflare"

local rturret = piece "rturret"
local rrecoil = piece "rrecoil"
local rflare = piece "rflare"

local lthigh = piece "lthigh"
local lleg = piece "lleg"
local lankle = piece "lankle"
local lfoot = piece "lfoot"

local ltoe1 = piece "ltoe1"
local ltoe2 = piece "ltoe2"
local ltoe3 = piece "ltoe3"
local lwake = piece "lwake"

local rthigh = piece "rthigh"
local rleg = piece "rleg"
local rankle = piece "rankle"
local rfoot = piece "rfoot"

local rtoe1 = piece "rtoe1"
local rtoe2 = piece "rtoe2"
local rtoe3 = piece "rtoe3"
local rwake = piece "rwake"

-- Signals
local SIG_stop = 2
local SIG_walk = 4
local SIG_swim = 8
local SIG_aim1 = 16
local SIG_aim2 = 32
local SIG_aim3 = 64
local SIG_open = 128
local SIG_dive = 256
local SIG_wake = 512

-- Variables And Speed-ups
local echo = Spring.Echo
local VAR_speed_turn_turret_x = 1
local VAR_speed_bump_pelvis = 9
local VAR_speed_propellor = 9
local VAR_accel_propellor = 2

local walking = true
local in_deep_water = false
local swimming_modus = false
local rlaucher_activated = false
local bubbles = false

local currBarrel = 1

-- Walk Animation
local function walk()
	SetSignalMask( SIG_walk )
	local VAR_sleep = 120
	local VAR_speed = 3
	while true do
		--frame1 (right leg steps forward, left leg pushes back)
		Move(pelvis, y_axis, 4, VAR_speed_bump_pelvis)
		Turn(lthigh, x_axis, math.rad(15), VAR_speed)
		Turn(rthigh, x_axis, math.rad(-15), VAR_speed)
		Turn(lleg, x_axis, math.rad(5), VAR_speed)
		Turn(rleg, x_axis, math.rad(15), VAR_speed)
		Turn(lankle, x_axis, math.rad(10), VAR_speed)
		Turn(rankle, x_axis, math.rad(-5), VAR_speed)
		Sleep(VAR_sleep)
		
		--frame2
        Move(pelvis, y_axis, 4, VAR_speed_bump_pelvis)
		Turn(lthigh, x_axis, math.rad(30), VAR_speed)
		Turn(rthigh, x_axis, math.rad(-30), VAR_speed)
        Turn(lleg, x_axis, math.rad(10), VAR_speed)
		Turn(rleg, x_axis, math.rad(30), VAR_speed)
		Turn(lankle, x_axis, math.rad(20), VAR_speed)
		Turn(rankle, x_axis, math.rad(-10), VAR_speed)
		Sleep(VAR_sleep)             
        
		--frame3
        Move(pelvis, y_axis, 4, VAR_speed_bump_pelvis)
		Turn(lthigh, x_axis, math.rad(45), VAR_speed)
		Turn(rthigh, x_axis, math.rad(-45), VAR_speed)
        Turn(lleg, x_axis, math.rad(15), VAR_speed)
		Turn(rleg, x_axis, math.rad(45), VAR_speed)
        Turn(lankle, x_axis, math.rad(30), VAR_speed)
		Turn(rankle, x_axis, math.rad(-15), VAR_speed)
		Sleep(VAR_sleep)    
        
		--frame4
        Move(pelvis, y_axis, -1, VAR_speed_bump_pelvis)
		Turn(lthigh, x_axis, math.rad(30), VAR_speed)
		Turn(rthigh, x_axis, math.rad(-30), VAR_speed)
      	Turn(lleg, x_axis, math.rad(10), VAR_speed)
		Turn(rleg, x_axis, math.rad(30), VAR_speed)
		Turn(lankle, x_axis, math.rad(20), VAR_speed)
		Turn(rankle, x_axis, math.rad(-10), VAR_speed)
		Sleep(VAR_sleep)    
        
		--frame5
        Move(pelvis, y_axis, -1, VAR_speed_bump_pelvis)
		Turn(lthigh, x_axis, math.rad(15), VAR_speed)
		Turn(rthigh, x_axis, math.rad(-15), VAR_speed)
    	Turn(lleg, x_axis, math.rad(5), VAR_speed)
        Turn(rleg, x_axis, math.rad(15), VAR_speed)
		Turn(lankle, x_axis, math.rad(10), VAR_speed)
		Turn(rankle, x_axis, math.rad(-5), VAR_speed)
		Sleep(VAR_sleep)    
        
		--frame6
        Move(pelvis, y_axis, -1, VAR_speed_bump_pelvis)
		Turn(lthigh, x_axis, math.rad(0), VAR_speed)
		Turn(rthigh, x_axis, math.rad(0), VAR_speed)
      	Turn(lleg, x_axis, math.rad(0), VAR_speed)
		Turn(rleg, x_axis, math.rad(0), VAR_speed)
	    Turn(lankle, x_axis, math.rad(0), VAR_speed)
		Turn(rankle, x_axis, math.rad(-0), VAR_speed)
		Sleep(VAR_sleep)    
        
		--frame7
        Move(pelvis, y_axis, 4, VAR_speed_bump_pelvis)
		Turn(lthigh, x_axis, math.rad(-15), VAR_speed)
		Turn(rthigh, x_axis, math.rad(15), VAR_speed)
     	Turn(lleg, x_axis, math.rad(15), VAR_speed)
		Turn(rleg, x_axis, math.rad(5), VAR_speed)
	    Turn(lankle, x_axis, math.rad(-5), VAR_speed)
		Turn(rankle, x_axis, math.rad(10), VAR_speed)
		Sleep(VAR_sleep) 
        
		--frame8
        Move(pelvis, y_axis, 4, VAR_speed_bump_pelvis)
		Turn(lthigh, x_axis, math.rad(-30), VAR_speed)
		Turn(rthigh, x_axis, math.rad(30), VAR_speed)
     	Turn(lleg, x_axis, math.rad(30), VAR_speed)
		Turn(rleg, x_axis, math.rad(10), VAR_speed)
		Turn(lankle, x_axis, math.rad(-10), VAR_speed)
		Turn(rankle, x_axis, math.rad(20), VAR_speed)
		Sleep(VAR_sleep) 
        
		--frame9
        Move(pelvis, y_axis, 4, VAR_speed_bump_pelvis)
		Turn(lthigh, x_axis, math.rad(-45), VAR_speed)
		Turn(rthigh, x_axis, math.rad(45), VAR_speed)
      	Turn(lleg, x_axis, math.rad(45), VAR_speed)
		Turn(rleg, x_axis, math.rad(20), VAR_speed)
		Turn(lankle, x_axis, math.rad(-15), VAR_speed)
		Turn(rankle, x_axis, math.rad(30), VAR_speed)
		Sleep(VAR_sleep)
        
		--frame10
        Move(pelvis, y_axis, -1, VAR_speed_bump_pelvis)
		Turn(lthigh, x_axis, math.rad(-30), VAR_speed)
		Turn(rthigh, x_axis, math.rad(30), VAR_speed)
      	Turn(lleg, x_axis, math.rad(30), VAR_speed)
		Turn(rleg, x_axis, math.rad(10), VAR_speed)
		Turn(lankle, x_axis, math.rad(-10), VAR_speed)
		Turn(rankle, x_axis, math.rad(20), VAR_speed)
		Sleep(VAR_sleep)
        
		--frame11
        Move(pelvis, y_axis, -1, VAR_speed_bump_pelvis)
		Turn(lthigh, x_axis, math.rad(-15), VAR_speed)
		Turn(rthigh, x_axis, math.rad(15), VAR_speed)
      	Turn(lleg, x_axis, math.rad(-15), VAR_speed)
		Turn(rleg, x_axis, math.rad(5), VAR_speed)
		Turn(lankle, x_axis, math.rad(-5), VAR_speed)
		Turn(rankle, x_axis, math.rad(10), VAR_speed)
		Sleep(VAR_sleep)
		
		--frame12
        Move(pelvis, y_axis, -1, VAR_speed_bump_pelvis)
		Turn(lthigh, x_axis, math.rad(0), VAR_speed)
		Turn(rthigh, x_axis, math.rad(0), VAR_speed)
        Turn(lleg, x_axis, math.rad(0), VAR_speed)
		Turn(rleg, x_axis, math.rad(0), VAR_speed)
	  	Turn(lankle, x_axis, math.rad(0), VAR_speed)
		Turn(rankle, x_axis, math.rad(0), VAR_speed)
		Sleep(VAR_sleep)
		end  
end

-- Swimming Animation
local function water_check()
	local VAR_sleep = 500
	local VAR_speed= 1.5
	while true do
    local x, y, z = Spring.GetUnitPosition(unitID)

	-- if unit goes under water
	if y < (-20) then
	in_deep_water = true
		if ( swimming_modus == false ) then
			Signal( SIG_walk )
				-- moving legs in swimming modus
				Turn(lthigh, x_axis, math.rad(45), VAR_speed)
    			Turn(rthigh, x_axis, math.rad(45), VAR_speed)
    			Turn(lleg, x_axis, math.rad(130), VAR_speed)
				Turn(rleg, x_axis, math.rad(130), VAR_speed)
    			WaitForTurn(rleg, x_axis)
    			Turn(lankle, x_axis, math.rad(-90), VAR_speed)
				Turn(rankle, x_axis, math.rad(-90), VAR_speed)
    			WaitForTurn(rankle, x_axis)
    			Move(lfoot, y_axis, -4, VAR_speed)
				Move(rfoot, y_axis, -4, VAR_speed)
    			WaitForMove(rankle, z_axis)
                Spin(lfoot, y_axis, VAR_speed_propellor, VAR_accel_propellor)
    			Spin(rfoot, y_axis, -VAR_speed_propellor, VAR_accel_propellor)
				-- making some bubbles without a move command, ended by stop_swim()
			    bubbles = true
				while ( bubbles == true ) do
				EmitSfx(lwake, 256+3)
				EmitSfx(rwake, 256+3)
				Sleep(250)
				end
			swimming_modus = true
		end
	end

	-- if unit re-emerges out of the water
	if y > (-20) then
	in_deep_water = false
		if ( swimming_modus == true ) then 
            Signal( SIG_wake )
				-- change propellors back to feet
				StopSpin(lfoot, y_axis, VAR_speed_propellor, VAR_accel_propellor)
    			StopSpin(rfoot, y_axis, VAR_speed_propellor, VAR_accel_propellor)
				Move(lfoot, y_axis, 0, VAR_speed)
				Move(rfoot, y_axis, 0, VAR_speed)
                Turn(lfoot, y_axis, math.rad(0), VAR_speed)
				Turn(rfoot, y_axis, math.rad(0), VAR_speed)
				-- stop swimming modus by walking
				StartThread( walk )
			swimming_modus = false
		end
	end

	--Spring.Echo("unit center in deep water", y, in_deep_water, swimming_modus)
	Sleep(500) -- time waited untill next water check
	end
end

local function swim()
	SetSignalMask( SIG_swim )
	Signal( SIG_walk )
	-- spin propellors
	Spin(lfoot, y_axis, VAR_speed_propellor, VAR_accel_propellor)
    Spin(rfoot, y_axis, -VAR_speed_propellor, VAR_accel_propellor)

end

local function wake_bubbles()
    SetSignalMask( SIG_wake )
	while true do
	EmitSfx(lwake, 256+3)
	EmitSfx(rwake, 256+3)
	Sleep(250)
	end
end

-- Stop Animation
local function stop_walk()
	SetSignalMask( SIG_stop )
	Signal( SIG_stop )
	Signal( SIG_walk )
	Signal( SIG_swim )
	local VAR_speed= 1

	Move(pelvis, y_axis, 0, VAR_speed)
		
	Turn(rthigh, x_axis, math.rad(0), VAR_speed)
	Turn(rleg, x_axis, math.rad(0), VAR_speed)
	Turn(lthigh, x_axis, math.rad(0), VAR_speed)
	Turn(lleg, x_axis, math.rad(0), VAR_speed)
		
    Turn(lankle, x_axis, math.rad(0), VAR_speed)
	Turn(rankle, x_axis, math.rad(0), VAR_speed)

	Turn(rturret, x_axis, math.rad(0), VAR_speed)
	Turn(lturret, x_axis, math.rad(0), VAR_speed)

	Turn(torso, x_axis, math.rad(0), VAR_speed)

	Signal( SIG_stop )
end

local function stop_swim()
	SetSignalMask( SIG_stop )
    Signal( SIG_stop )
    Signal( SIG_walk )
	Signal( SIG_swim )
	Signal( SIG_wake )
	bubbles = false
	StopSpin(lfoot, y_axis, VAR_speed_propellor, VAR_accel_propellor)
    StopSpin(rfoot, y_axis, VAR_speed_propellor, VAR_accel_propellor)
	Signal( SIG_stop )
end

local function RestoreAfterDelay(unitID)
	local VAR_speed = 2
	Sleep(3000)
    Move(pelvis, y_axis, 0, VAR_speed)
	Turn(torso, y_axis, math.rad(0), VAR_speed)
    WaitForTurn(torso, y_axis)

	Turn(lturret, x_axis, math.rad(0), VAR_speed)
    Turn(rturret, x_axis, math.rad(0), VAR_speed)
   	WaitForTurn(rturret, x_axis)
	
	Move(lrecoil, z_axis, 0, VAR_speed)
	Move(rrecoil, z_axis, 0, VAR_speed)
   	WaitForMove(rrecoil, x_axis)
	
	-- repack rocket laucher
	Turn(rdoor, z_axis, math.rad(90), 1)
	Turn(ldoor, z_axis, math.rad(-90), 1)
    WaitForTurn(ldoor, z_axis)
    Turn(rdoor, z_axis, math.rad(0), 1)
	Turn(ldoor, z_axis, math.rad(0), 1)
	Move(rlauncher, y_axis, 0, 3)
	WaitForMove(rlauncher, y_axis)
	rlaucher_activated = false
end

-- Shooting Animation
local function ready_rlaucher()
    SetSignalMask( SIG_open )
	Turn(rdoor, z_axis, math.rad(180), 1)
	Turn(ldoor, z_axis, math.rad(-90), 1)
    WaitForTurn(ldoor, z_axis)
    Turn(rdoor, z_axis, math.rad(220), 1)
	Turn(ldoor, z_axis, math.rad(-220), 1)
	Move(rlauncher, y_axis, 3, 3)
	WaitForMove(rlauncher, y_axis)
	Signal( SIG_open )
end

local function fire1()
    local VAR_speed = 50
    EmitSfx(lflare, 1024+0)
    EmitSfx(lrecoil, 256+1)
	Move(lrecoil, z_axis, -6, VAR_speed)
	WaitForMove(lrecoil, z_axis)
	Sleep(200)
	Move(lrecoil, z_axis, 0, 3)
    WaitForMove(lrecoil, z_axis)
	Sleep(1)
end

local function fire2()
    local VAR_speed = 50
    EmitSfx(rflare, 1024+0)
    EmitSfx(rrecoil, 256+1)
	Move(rrecoil, z_axis, -6, VAR_speed)
	WaitForMove(rrecoil, z_axis)
	Sleep(200)
	Move(rrecoil, z_axis, 0, 3)
    WaitForMove(rrecoil, z_axis)
	Sleep(1)
end

local function fire3()
	Sleep(1)
end
	
-- Call-Ins 

------

function script.Create(unitID)
	StartThread( water_check )
end

------

function script.StartMoving()
	if ( in_deep_water == false ) then
	StartThread( walk )
	else
	StartThread( swim )
	StartThread( wake_bubbles )
	end
end

function script.StopMoving()
	if (in_deep_water == false) then
	StartThread( stop_walk )
    else
	StartThread( stop_swim )
	end
end

------

function script.AimFromWeapon1() return torso end

function script.AimWeapon1( heading, pitch )
	Signal( SIG_aim1 )
	SetSignalMask( SIG_aim1 )
	-- keep from turing while underwater
	if ( in_deep_water == true ) then
	return false
    else
	-- turn turrets to target
	Turn(torso, y_axis, heading, 1, 1)
	WaitForTurn(torso, y_axis)
	Turn(lturret, x_axis, -pitch, VAR_speed_turn_turret_x)
    Turn(rturret, x_axis, -pitch, VAR_speed_turn_turret_x)
	WaitForTurn(rturret, x_axis)
	StartThread( RestoreAfterDelay )
	return true
	end
end

function script.QueryWeapon1()
    if (currBarrel == 1) then
    return lflare
    else
    return rflare
    end
end

function script.AimFromWeapon3() return lflare end

function script.AimWeapon3()
    Signal( SIG_aim3 )
	SetSignalMask( SIG_aim3 )
	if (rlaucher_activated == false) then
		StartThread( ready_rlaucher )
	    rlaucher_activated = true
	end
	StartThread( RestoreAfterDelay )
	return true
end

function script.QueryWeapon3() return rocketflare end

------

function script.FireWeapon1()
    if currBarrel == 1 then
   	fire1()
	end

	if currBarrel == 2 then
	fire2()
	end

	currBarrel = currBarrel + 1
	if currBarrel == 3 then currBarrel = 1
	end
end

function script.FireWeapon3()
	fire3()
	Sleep(1)
end

------

function script.Killed(recentDamage, maxHealth)
		local severity = recentDamage/maxHealth
	if severity < 0.5 then
        Explode(pelvis, sfxNone)
		Explode(torso, sfxNone)
		
        Explode(rlauncher, sfxNone)
        Explode(ldoor, sfxNone)
        Explode(rdoor, sfxNone)

		Explode(lturret, sfxNone)
		Explode(rturret, sfxNone)
		Explode(lrecoil, sfxNone)
		Explode(rrecoil, sfxNone)
		
		Explode(lthigh, sfxNone)
		Explode(rthigh, sfxNone)
		Explode(rleg, sfxNone)
		Explode(lleg, sfxNone)
		Explode(rankle, sfxNone)
		Explode(lankle, sfxNone)
        Explode(rfoot, sfxNone)
		Explode(lfoot, sfxNone)

        Explode(ltoe1, sfxNone)
        Explode(ltoe2, sfxNone)
        Explode(ltoe3, sfxNone)

		Explode(rtoe1, sfxNone)
        Explode(rtoe2, sfxNone)
        Explode(rtoe3, sfxNone)
		return 1
	else
        Explode(pelvis, sfxShatter)
		Explode(torso, sfxShatter)
		
		Explode(rlauncher, sfxNone)
        Explode(ldoor, sfxNone)
        Explode(rdoor, sfxNone)
		
		Explode(lturret, sfxSmoke + sfxFire + sfxExplode)
		Explode(rturret, sfxSmoke + sfxFire + sfxExplode)
		Explode(lrecoil, sfxSmoke + sfxFire + sfxExplode)
		Explode(rrecoil, sfxSmoke + sfxFire + sfxExplode)
		
		Explode(lthigh, sfxShatter)
		Explode(rthigh, sfxShatter)
		Explode(rleg, sfxShatter)
		Explode(lleg, sfxShatter)
		Explode(rankle, sfxShatter)
		Explode(lankle, sfxShatter)
        Explode(rfoot, sfxShatter)
		Explode(lfoot, sfxShatter)

        Explode(ltoe1, sfxNone)
        Explode(ltoe2, sfxNone)
        Explode(ltoe3, sfxNone)

		Explode(rtoe1, sfxNone)
        Explode(rtoe2, sfxNone)
        Explode(rtoe3, sfxNone)
		return 2
	end
end
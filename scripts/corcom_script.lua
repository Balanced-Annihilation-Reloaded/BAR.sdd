-- corcom --
-- A  unit script for BA remake --
-- by FireStorm --

-- s3o Pieces
local pelvis = piece "pelvis"
local torso = piece "torso"
local head = piece "head"

local lthigh = piece "lthigh"
local lleg = piece "lleg"
local l_foot = piece "l_foot"

local rthigh = piece "rthigh"
local rleg = piece "rleg"
local r_foot = piece "r_foot"

local luparm = piece "luparm"
local nanolathe = piece "nanolathe"
local lfirept = piece "lfirept"
local nanospray = piece "nanospray"

local ruparm = piece "ruparm"
local biggun = piece "biggun"
local rbigflash = piece "rbigflash"

-- Signals
local SIG_stop = 1
local SIG_walk = 2
local SIG_aim1 = 4
local SIG_aim2 = 8
local SIG_aim3 = 16
local SIG_build = 32

-- Variables And Speed-ups
local echo = Spring.Echo
local VAR_speed_turn_torso_y = math.rad(300)
local VAR_speed_bump_pelvis = 9
local aiming = false

-- Walk Animation
local function start_walk()
	SetSignalMask( SIG_walk )
	local VAR_sleep = 120
	local VAR_speed = 3
	while true do
		--frame1 (right leg steps forward, left leg pushes back)
		Move(pelvis, y_axis, 2, VAR_speed_bump_pelvis)
		Turn(lthigh, x_axis, math.rad(15), VAR_speed)
		Turn(rthigh, x_axis, math.rad(-15), VAR_speed)
		Turn(lleg, x_axis, math.rad(5), VAR_speed)
		Turn(rleg, x_axis, math.rad(15), VAR_speed)
		Turn(l_foot, x_axis, math.rad(10), VAR_speed)
		Turn(r_foot, x_axis, math.rad(-5), VAR_speed)
		Sleep(VAR_sleep)
		
		--frame2
        Move(pelvis, y_axis, 2, VAR_speed_bump_pelvis)
		Turn(lthigh, x_axis, math.rad(30), VAR_speed)
		Turn(rthigh, x_axis, math.rad(-30), VAR_speed)
        Turn(lleg, x_axis, math.rad(10), VAR_speed)
		Turn(rleg, x_axis, math.rad(30), VAR_speed)
		Turn(l_foot, x_axis, math.rad(20), VAR_speed)
		Turn(r_foot, x_axis, math.rad(-10), VAR_speed)
		Sleep(VAR_sleep)             
        
		--frame3
        Move(pelvis, y_axis, 2, VAR_speed_bump_pelvis)
		Turn(lthigh, x_axis, math.rad(45), VAR_speed)
		Turn(rthigh, x_axis, math.rad(-45), VAR_speed)
        Turn(lleg, x_axis, math.rad(15), VAR_speed)
		Turn(rleg, x_axis, math.rad(45), VAR_speed)
        Turn(l_foot, x_axis, math.rad(30), VAR_speed)
		Turn(r_foot, x_axis, math.rad(-15), VAR_speed)
		Sleep(VAR_sleep)    
        
		--frame4
        Move(pelvis, y_axis, -3, VAR_speed_bump_pelvis)
		Turn(lthigh, x_axis, math.rad(30), VAR_speed)
		Turn(rthigh, x_axis, math.rad(-30), VAR_speed)
      	Turn(lleg, x_axis, math.rad(10), VAR_speed)
		Turn(rleg, x_axis, math.rad(30), VAR_speed)
		Turn(l_foot, x_axis, math.rad(20), VAR_speed)
		Turn(r_foot, x_axis, math.rad(-10), VAR_speed)
		Sleep(VAR_sleep)    
        
		--frame5
        Move(pelvis, y_axis, -3, VAR_speed_bump_pelvis)
		Turn(lthigh, x_axis, math.rad(15), VAR_speed)
		Turn(rthigh, x_axis, math.rad(-15), VAR_speed)
    	Turn(lleg, x_axis, math.rad(5), VAR_speed)
        Turn(rleg, x_axis, math.rad(15), VAR_speed)
		Turn(l_foot, x_axis, math.rad(10), VAR_speed)
		Turn(r_foot, x_axis, math.rad(-5), VAR_speed)
		Sleep(VAR_sleep)    
        
		--frame6
        Move(pelvis, y_axis, -3, VAR_speed_bump_pelvis)
		Turn(lthigh, x_axis, math.rad(0), VAR_speed)
		Turn(rthigh, x_axis, math.rad(0), VAR_speed)
      	Turn(lleg, x_axis, math.rad(0), VAR_speed)
		Turn(rleg, x_axis, math.rad(0), VAR_speed)
	    Turn(l_foot, x_axis, math.rad(0), VAR_speed)
		Turn(r_foot, x_axis, math.rad(-0), VAR_speed)
		Sleep(VAR_sleep)    
        
		--frame7
        Move(pelvis, y_axis, 2, VAR_speed_bump_pelvis)
		Turn(lthigh, x_axis, math.rad(-15), VAR_speed)
		Turn(rthigh, x_axis, math.rad(15), VAR_speed)
     	Turn(lleg, x_axis, math.rad(15), VAR_speed)
		Turn(rleg, x_axis, math.rad(5), VAR_speed)
	    Turn(l_foot, x_axis, math.rad(-5), VAR_speed)
		Turn(r_foot, x_axis, math.rad(10), VAR_speed)
		Sleep(VAR_sleep) 
        
		--frame8
        Move(pelvis, y_axis, 2, VAR_speed_bump_pelvis)
		Turn(lthigh, x_axis, math.rad(-30), VAR_speed)
		Turn(rthigh, x_axis, math.rad(30), VAR_speed)
     	Turn(lleg, x_axis, math.rad(30), VAR_speed)
		Turn(rleg, x_axis, math.rad(10), VAR_speed)
		Turn(l_foot, x_axis, math.rad(-10), VAR_speed)
		Turn(r_foot, x_axis, math.rad(20), VAR_speed)
		Sleep(VAR_sleep) 
        
		--frame9
        Move(pelvis, y_axis, 2, VAR_speed_bump_pelvis)
		Turn(lthigh, x_axis, math.rad(-45), VAR_speed)
		Turn(rthigh, x_axis, math.rad(45), VAR_speed)
      	Turn(lleg, x_axis, math.rad(45), VAR_speed)
		Turn(rleg, x_axis, math.rad(20), VAR_speed)
		Turn(l_foot, x_axis, math.rad(-15), VAR_speed)
		Turn(r_foot, x_axis, math.rad(30), VAR_speed)
		Sleep(VAR_sleep)
        
		--frame10
        Move(pelvis, y_axis, -3, VAR_speed_bump_pelvis)
		Turn(lthigh, x_axis, math.rad(-30), VAR_speed)
		Turn(rthigh, x_axis, math.rad(30), VAR_speed)
      	Turn(lleg, x_axis, math.rad(30), VAR_speed)
		Turn(rleg, x_axis, math.rad(10), VAR_speed)
		Turn(l_foot, x_axis, math.rad(-10), VAR_speed)
		Turn(r_foot, x_axis, math.rad(20), VAR_speed)
		Sleep(VAR_sleep)
        
		--frame11
        Move(pelvis, y_axis, -3, VAR_speed_bump_pelvis)
		Turn(lthigh, x_axis, math.rad(-15), VAR_speed)
		Turn(rthigh, x_axis, math.rad(15), VAR_speed)
      	Turn(lleg, x_axis, math.rad(-15), VAR_speed)
		Turn(rleg, x_axis, math.rad(5), VAR_speed)
		Turn(l_foot, x_axis, math.rad(-5), VAR_speed)
		Turn(r_foot, x_axis, math.rad(10), VAR_speed)
		Sleep(VAR_sleep)
		
		--frame12
        Move(pelvis, y_axis, -3, VAR_speed_bump_pelvis)
		Turn(lthigh, x_axis, math.rad(0), VAR_speed)
		Turn(rthigh, x_axis, math.rad(0), VAR_speed)
        Turn(lleg, x_axis, math.rad(0), VAR_speed)
		Turn(rleg, x_axis, math.rad(0), VAR_speed)
	  	Turn(l_foot, x_axis, math.rad(0), VAR_speed)
		Turn(r_foot, x_axis, math.rad(0), VAR_speed)
		Sleep(VAR_sleep)
		end 
end

local function arm_swing()
	SetSignalMask( SIG_walk )
	local VAR_sleep = 120
	local VAR_speed= 1.5
	while (aiming == false) do
    	--frame1
		Turn(biggun, x_axis, math.rad(45), VAR_speed)
		Turn(luparm, x_axis, math.rad(-15), VAR_speed)
		Turn(ruparm, x_axis, math.rad(15), VAR_speed)
		Sleep(VAR_sleep)
     	
		--frame2
    	Turn(luparm, x_axis, math.rad(-30), VAR_speed)
		Turn(ruparm, x_axis, math.rad(30), VAR_speed)
    	Sleep(VAR_sleep)
       	
		--frame3
    	Turn(luparm, x_axis, math.rad(-45), VAR_speed)
		Turn(ruparm, x_axis, math.rad(45), VAR_speed)
		Sleep(VAR_sleep)
         	
		--frame4
    	Turn(luparm, x_axis, math.rad(-30), VAR_speed)
		Turn(ruparm, x_axis, math.rad(30), VAR_speed)
		Sleep(VAR_sleep)
        	
		--frame5
    	Turn(luparm, x_axis, math.rad(-15), VAR_speed)
		Turn(ruparm, x_axis, math.rad(15), VAR_speed)
		Sleep(VAR_sleep)
          	
		--frame6
    	Turn(luparm, x_axis, math.rad(0), VAR_speed)
		Turn(ruparm, x_axis, math.rad(0), VAR_speed)
		Sleep(VAR_sleep)
          	
		--frame7
    	Turn(luparm, x_axis, math.rad(15), VAR_speed)
		Turn(ruparm, x_axis, math.rad(-15), VAR_speed)
		Sleep(VAR_sleep)
         	
		--frame8
    	Turn(luparm, x_axis, math.rad(30), VAR_speed)
		Turn(ruparm, x_axis, math.rad(-30), VAR_speed)
		Sleep(VAR_sleep)
         	
		--frame9
    	Turn(luparm, x_axis, math.rad(45), VAR_speed)
		Turn(ruparm, x_axis, math.rad(-45), VAR_speed)
		Sleep(VAR_sleep)
         	
		--frame10
    	Turn(luparm, x_axis, math.rad(30), VAR_speed)
		Turn(ruparm, x_axis, math.rad(-30), VAR_speed)
		Sleep(VAR_sleep)
           	
		--frame11
    	Turn(luparm, x_axis, math.rad(15), VAR_speed)
		Turn(ruparm, x_axis, math.rad(-15), VAR_speed)
		Sleep(VAR_sleep)
            	
		--frame12
    	Turn(luparm, x_axis, math.rad(0), VAR_speed)
		Turn(ruparm, x_axis, math.rad(0), VAR_speed)
		Sleep(VAR_sleep)
		end
end

-- Stop Animation
local function stop()
		SetSignalMask( SIG_stop )
		Signal( SIG_stop )
		Signal( SIG_walk )
		local VAR_speed= 1
		Move(pelvis, y_axis, 0, VAR_speed_bump_pelvis)
		
		Turn(rthigh, x_axis, math.rad(0), VAR_speed)
		Turn(rleg, x_axis, math.rad(0), VAR_speed)
		Turn(lthigh, x_axis, math.rad(0), VAR_speed)
		Turn(lleg, x_axis, math.rad(0), VAR_speed)
		
        Turn(l_foot, x_axis, math.rad(0), VAR_speed)
		Turn(r_foot, x_axis, math.rad(0), VAR_speed)

		Turn(ruparm, x_axis, math.rad(0), VAR_speed)
		Turn(biggun, x_axis, math.rad(0), VAR_speed)
		Turn(luparm, x_axis, math.rad(0), VAR_speed)
		Turn(nanolathe, x_axis, math.rad(0), VAR_speed)
		
		Turn(pelvis, x_axis, math.rad(0), VAR_speed)
		Turn(torso, x_axis, math.rad(0), VAR_speed)
		Turn(head, x_axis, math.rad(0), VAR_speed)
		Sleep(1)
        Signal( SIG_stop )
end

local function RestoreAfterDelay(unitID)
	local VAR_speed = 2
	Sleep(3000)
	Turn(torso, y_axis, math.rad(0), VAR_speed_turn_torso_y)
    WaitForTurn(torso, y_axis)

	Turn(biggun, x_axis, math.rad(0), VAR_speed)
    Turn(nanolathe, x_axis, math.rad(0), VAR_speed)
   	WaitForTurn(nanolathe, x_axis)
	
	Turn(ruparm, x_axis, math.rad(0), VAR_speed)
	Turn(luparm, x_axis, math.rad(0), VAR_speed)
   	WaitForTurn(luparm, x_axis)
    aiming = false
end

-- Shooting Animation
local function fire1()
	local VAR_speed= 6
	Turn(luparm, x_axis, math.rad(-65), VAR_speed)
	Turn(nanolathe, x_axis, math.rad(65), VAR_speed)
	Sleep(1)
end

local function fire3()
	local VAR_speed= 6
	Turn(ruparm, x_axis, math.rad(15), VAR_speed)
	Turn(biggun, x_axis, math.rad(-15), VAR_speed)
	WaitForTurn(biggun, x_axis)
	Turn(ruparm, x_axis, math.rad(30), VAR_speed)
	Turn(biggun, x_axis, math.rad(-30), VAR_speed)
    WaitForTurn(biggun, x_axis)
	Turn(ruparm, x_axis, math.rad(15), VAR_speed)
	Turn(biggun, x_axis, math.rad(-15), VAR_speed)
    WaitForTurn(biggun, x_axis)
	Turn(ruparm, x_axis, math.rad(0), VAR_speed)
	Turn(biggun, x_axis, math.rad(0), VAR_speed)
	
	Turn(ruparm, x_axis, math.rad(-65), VAR_speed)
	Turn(biggun, x_axis, math.rad(65), VAR_speed)
    WaitForTurn(nanolathe, x_axis)
	Sleep(1)
end

-- Call-Ins 

------

function script.Create(unitID)
end

------

function script.StartMoving()
	StartThread( start_walk )
	StartThread( arm_swing )
end

function script.StopMoving()
	StartThread( stop )
end

------


function script.StartBuilding(heading, pitch)
	Signal( SIG_build )
	SetSignalMask( SIG_build )
	Turn(torso, y_axis, heading, VAR_speed_turn_torso_y)
	Turn(luparm, x_axis, math.rad(-65), 1)
	Turn(nanolathe, x_axis, math.rad(65), 1)
    WaitForTurn(nanolathe, x_axis)
	SetUnitValue(COB.INBUILDSTANCE, 1)
	return 1
end

function script.QueryNanoPiece() return nanospray end

function script.StopBuilding()
   	Signal( SIG_build )
   	SetSignalMask( SIG_build )
   	SetUnitValue(COB.INBUILDSTANCE, 0)
   	Sleep(1)
	StartThread( RestoreAfterDelay )
	return 0
end

------

function script.AimFromWeapon1() return torso end

function script.AimWeapon1( heading, pitch )
	Signal( SIG_aim1 )
	SetSignalMask( SIG_aim1 )
	local _, basepos, _ = Spring.GetUnitPosition(unitID)
	if basepos > -16 then
		aiming = true
		Turn(torso, y_axis, heading, VAR_speed_turn_torso_y)
		WaitForTurn(torso, y_axis)
		StartThread( RestoreAfterDelay )
		return true
	else
		return false
	end	
end

function script.QueryWeapon1() return lfirept end

  
function script.FireWeapon1()
	fire1()
	Sleep(1)
end

--
function script.AimFromWeapon2() return torso end

function script.AimWeapon2( heading, pitch )
	Signal( SIG_aim2 )
	SetSignalMask( SIG_aim2 )
	local _, basepos, _ = Spring.GetUnitPosition(unitID)
	Spring.Echo(basepos)
	if basepos < -40 then
		aiming = true
		Turn(torso, y_axis, heading, VAR_speed_turn_torso_y)
		WaitForTurn(torso, y_axis)
		StartThread( RestoreAfterDelay )
		return true
	else
		return false
	end
end

function script.QueryWeapon2() return lfirept end

  
function script.FireWeapon2()
	fire1()
	Sleep(1)
end
--

function script.AimFromWeapon3() return torso end

function script.AimWeapon3( heading, pitch )
    Signal( SIG_aim3 )
	SetSignalMask( SIG_aim3 )
	aiming = true
	Turn(torso, y_axis, heading, VAR_speed_turn_torso_y)
	WaitForTurn(torso, y_axis)
	StartThread( RestoreAfterDelay )
	return true
end

function script.QueryWeapon3() return rbigflash end


function script.FireWeapon3()
	fire3()
	Sleep(1)
end

------

function script.Killed(recentDamage, maxHealth)
		local severity = recentDamage/maxHealth
	if severity < 0.5 then
		Explode(torso, SFX.NONE)
		Explode(luparm, SFX.NONE)
		Explode(ruparm, SFX.NONE)
		Explode(pelvis, SFX.NONE)
		Explode(lthigh, SFX.NONE)
		Explode(rthigh, SFX.NONE)
		Explode(nanolathe, SFX.NONE)
		Explode(biggun, SFX.NONE)
		Explode(rleg, SFX.NONE)
		Explode(lleg, SFX.NONE)
		Explode(r_foot, SFX.NONE)
		Explode(l_foot, SFX.NONE)
		return 1
	else
		Explode(torso, SFX.SHATTER)
		Explode(luparm, SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(ruparm, SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(pelvis, SFX.SHATTER)
		Explode(lthigh, SFX.SHATTER)
		Explode(rthigh, SFX.SHATTER)
		Explode(nanolathe, SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(biggun, SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(rleg, SFX.SHATTER)
		Explode(lleg, SFX.SHATTER)
		Explode(r_foot, SFX.SHATTER)
		Explode(l_foot, SFX.SHATTER)
		return 1
	end
end
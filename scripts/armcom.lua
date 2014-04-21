-------------------------------------------------------
-- License:	Public Domain
-- Author:	Steve (Smoth) Smith
-- Date:	4/19/2014
-------------------------------------------------------

-- Piece names
	head		= piece 'torso'
	base		= piece 'torso'
	l_arm		= piece 'luparm'
	l_forearm	= piece 'biggun'
	r_arm		= piece 'ruparm'
	r_forearm	= piece 'rloarm'
	lflare		= piece 'lflare'
	nano		= piece 'nano'
	laserflare	= piece 'laserflare'
	cod			= piece 'pelvis'
	right_l		= piece 'rthigh'
	left_l		= piece 'lthigh'
	shin_l		= piece 'lleg'
	shin_r		= piece 'rleg'
	foot_r		= piece 'rfoot'
	foot_l		= piece 'lfoot'
	dish		= piece 'dish'

-- State variables
	isMoving, isAiming, isBuilding = "derpy spring", "derpy spring", "derpy spring"

-- used to restore build aiming
	buildY, buildX	= 0, 0
	firedWeapon		= false

-- Unit Speed
	speedMult		=	1.7

-- Unit animation preferences
	leftArm		=	true;
	rightArm	=	true;
	heavy		=	true;
			

-- Signal definitions
local SIG_AIM			=	2
local SIG_WALK			=	4

-- effects for emitters
local effectA = 1024
local effectB = 1025

--local SMOKEPIECE1 = base

function script.StartMoving()
	isMoving = true
	StartThread(walk)
end

function script.StopMoving()
	isMoving = false
	StartThread(poser)
end	

--#include "\headers\smoke.h"
include("include/walk.lua")



--------------------------------------------------------
--start ups :)
--------------------------------------------------------
function script.Create()
	-- Initial State
	
	Turn(r_forearm, x_axis, math.rad(-15),math.rad(130))
	Turn(lflare, x_axis,math.rad(90))
	Turn(nano, x_axis,math.rad(90))
	Turn(laserflare, x_axis,math.rad(90))

	Spin(dish, y_axis, 2.5)
	
	-- because DERP
	isAiming	= false	
    isBuilding	= false
	isMoving	= false
	
	if(heavy == true ) then
		SquatStance()	
	else
		StandStance()
	end
	-- should do this instead of query nano piece
	--Spring.SetUnitNanoPieces( unitID, {nano} )
end

-----------------------------------------------------------------------
--function to restore the aim if construction was interupted by combat
-----------------------------------------------------------------------	
function ResumeBuilding()
	sleep(400)
	
    if isBuilding and firedWeapon then
	   Turn(base, y_axis, buildY, 2.618)
	   Turn(r_arm, x_axis, 0.5235 - buildx, 2.618 )
    end
end


-----------------------------------------------------------------------
--gun functions;
-----------------------------------------------------------------------	
function script.AimFromWeapon(weaponID)
	if weaponID == 3 then
		return l_arm
	else
		return r_arm
	end
end

function script.QueryWeapon(weaponID)
	if weaponID == 1 then
		return laserflare
	elseif weaponID == 3 then
		return lflare	
	end
end

-----------------------------------------------------------------------
-- This coroutine is restarted with each time a unit reaims, 
-- not the most efficient and should be optimized. Possible
-- augmentation needed to lus.
-----------------------------------------------------------------------
local function RestoreAfterDelayLeft()
	Sleep(1000)
	
	--[[Turn(base, y_axis, 0, math.rad(105))
	Turn(l_forearm, x_axis, math.rad(-38), math.rad(95))
	Turn(l_arm, x_axis, math.rad(15), math.rad(95))]]--

	isAiming = false
end

local function RestoreAfterDelayRight()
	Sleep(1000)
	
	--[[Turn(base, y_axis, 0, math.rad(105))
	Turn(r_forearm, x_axis, math.rad(-38), math.rad(95))
	Turn(r_arm, x_axis, math.rad(15), math.rad(95))]]--
	
	isAiming = false
end

function script.AimWeapon(weaponID, heading, pitch)
	-- Spring.Echo("AimWeapon " .. weaponID)
	
	-- weapon2 is supposed to only fire underwater, check for it.
	if weaponID == 2 then
		local _, basepos, _ = Spring.GetUnitPosition(unitID) 
		if basepos > -16 then
			return false
		end
	end 

	Signal(SIG_AIM)
	SetSignalMask(SIG_AIM)
	isAiming = true
		
	if weaponID == 1 or weaponID == 2 then
		FixArms(false, true)
		
		Turn(base, y_axis, heading, math.rad(105))
		Turn(r_forearm, x_axis, math.rad(-55), math.rad(390))
		Turn(r_arm,	x_axis, math.rad(-45) - pitch, math.rad(390))
				
		WaitForTurn(base, y_axis)
		WaitForTurn(r_arm, x_axis)
		WaitForTurn(r_forearm, x_axis)
		-- Spring.Echo("AimWeapon " .. weaponID .. " done turning")

		StartThread(RestoreAfterDelayRight)
				
		firedWeapon		= false
		-- if I was buidling restore my arm position
		if (isBuilding == true) then
		--	ResumeBuilding();
		end
		
		-- Spring.Echo("AimWeapon " .. weaponID .. " end")
		return true
	elseif weaponID == 3 then
		FixArms(true, false)
		
		Turn(base, y_axis, heading, math.rad(105))
		Turn(l_forearm, x_axis, math.rad(-85), math.rad(390))
		Turn(l_arm,	x_axis, math.rad(-5) - pitch, math.rad(390))
				
		WaitForTurn(base, y_axis)
		WaitForTurn(l_arm, x_axis)
		WaitForTurn(l_forearm, x_axis)
		-- Spring.Echo("AimWeapon done turning")

		StartThread(RestoreAfterDelayLeft)
		
		firedWeapon		= false
		-- if I was buidling restore my arm position
		if (isBuilding == true) then
		--	ResumeBuilding();
		end
		
		-- Spring.Echo("AimWeapon end")
		return true
	else
		return false	
	end	
end

function script.FireWeapon(weaponID) 	
	Sleep(500)
	firedWeapon		= true
end

-----------------------------------------------------------------------
-- I dunno, a bunch of stuff I hastily ported to lua.
-----------------------------------------------------------------------
function script.QueryNanoPiece()
	return nano
end

function script.StartBuilding(heading, pitch)
--	Spring.Echo("StartBuilding")
	IsFiringDgun	= 0;
	isBuilding		= true;
	buildY, buildX	= heading, pitch
	
	Turn(base, y_axis, heading, math.rad(105))
	Turn(r_forearm, x_axis, math.rad(-55), math.rad(390))
	Turn(r_arm,	x_axis, math.rad(-55) - pitch, math.rad(390))

	WaitForTurn(r_arm, x_axis)
	SetUnitValue(COB.INBUILDSTANCE, 1)
end

function script.StopBuilding()
	Sleep(200)
	isBuilding		= false;
	SetUnitValue(COB.INBUILDSTANCE, 0)
--	Spring.Echo("Stop Building", isAiming, isBuilding, isMoving)
end

-----------------------------------------------------------------------
-- death stuffs
-----------------------------------------------------------------------	
function script.Killed(recentDamage, maxHealth)
	-- fall over
	Turn(cod, x_axis, math.rad(270), 5)	
	-- reset parts
	Turn(base, y_axis, 0, 8)	
	Turn(r_arm, z_axis, 4, 3)
	Turn(l_arm, z_axis, -4, 3)
	-- fall
	Move(cod, y_axis, -30, 100)
	Turn(base, x_axis, 0.5, 8)
	Turn(right_l, x_axis, -0.5, 8)
	Turn(left_l, x_axis, -0.5, 8)			
	WaitForMove(cod, y_axis)
	-- land
	Turn(r_forearm, x_axis, 0, 5)
	Turn(l_forearm, x_axis, 0, 5)
	Move(cod, y_axis, -35, 200)	
	Turn(base, x_axis, 0, 10)
	Turn(right_l, x_axis, 0, 10)
	Turn(left_l, x_axis, 0, 10)
	WaitForMove(cod, y_axis)
	
	local severity = recentDamage/maxHealth
	if (severity <= 99) then
		Explode(l_arm, SFX.FALL)
		Explode(r_arm, SFX.FALL)
		Explode(l_arm, SFX.FALL)
		Explode(l_forearm, SFX.FALL)
		Explode(r_arm, SFX.FALL)
		Explode(r_forearm, SFX.FALL)
		return 3
	else
		return 0
	end
end
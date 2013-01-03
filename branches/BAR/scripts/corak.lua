include("include/util.lua")

local torso, ruparm, luparm, rfire, lfire, rloarm, lloarm, pelvis, rleg, rfoot, lleg, lfoot, lthigh, rthigh, lknee, rknee =
		piece("torso", "ruparm", "luparm", "rfire", "lfire", "rloarm", "lloarm", "pelvis", "rleg", "rfoot", "lleg", "lfoot", "lthigh", "rthigh", "lknee", "rknee")

local SIG_WALK = 1
local SIG_AIM = 2

local sfxNone = SFX.NONE
local sfxShatter = SFX.SHATTER
local sfxSmoke = SFX.SMOKE
local sfxFire = SFX.FIRE
local sfxFall = SFX.FALL
local sfxExplode = SFX.EXPLODE

local spGetGroundHeight	= Spring.GetGroundHeight
local spGetUnitPosition = Spring.GetUnitPosition
local spGetPieceTranslation = Spring.UnitScript.GetPieceTranslation
local spGetPieceRotation = Spring.UnitScript.GetPieceRotation
local spGetUnitHeading = Spring.GetUnitHeading
local spGetUnitVelocity = Spring.GetUnitVelocity
local spGetPiecePosDir = Spring.UnitScript.GetPiecePosDir
local deg = math.deg
local rad = math.rad
local sin = math.sin
local cos = math.cos
local tan = math.tan
local atan2 = math.atan2
local sqrt = math.sqrt
local abs = math.abs
local max = math.max
local min = math.min
local rand = math.random

local fire_point = {
	[0] = rfire,
	[1] = lfire
}

local kinChain = {
	left = {
		{p=lthigh, aMax=rad(97.0), aMin=rad(-52.0)},	-- model piece number, max angle, min angle
		{p=lknee, aMax=rad(13.0), aMin=rad(-11.0)},
		{p=lleg, aMax=rad(61.0), aMin=rad(-34.0)},
		{p=lfoot, aMax=rad(25.0), aMin=rad(-60.0)}
	},
	right = {
		{p=rthigh, aMax=rad(97.0), aMin=rad(-52.0)},
		{p=rknee, aMax=rad(13.0), aMin=rad(-11.0)},
		{p=rleg, aMax=rad(61.0), aMin=rad(-34.0)},
		{p=rfoot, aMax=rad(25.0), aMin=rad(-60.0)}
	}
}

local gun = 1
local bMoving = false

local function angleCorrection(ang)	-- converts all angles from 0..2*pi into -pi..pi
	if ang > 3.1415926536 then
		ang = 6.2831853071 - ang
	elseif ang < -3.1415926536 then
		ang = -6.2831853071 -ang
	end
	return ang
end

local function InverseKinematics(leg, v, d, y, pos)	-- A Cyclic Coordinate Descent IK attempt
	if v<=0.1 then
		return
	end
	local kc = kinChain[leg]
	local endLink = kc[4].p
	local from, to, s, rx, data
	if pos then
		from, to, s = 1, 3, 1
	else
		from, to, s = 3, 3, 1
	end
	for i=1, 4 do
		for p=from, to, s do
			data = kc[p]
			local _,y1,z1 = spGetPiecePosDir(data.p)
			local _,ey,ez = spGetPiecePosDir(endLink)
			local oa = atan2(ey-y1,ez-z1)	--origin angle
			local da = atan2(y-y1,d-z1)		--destination angle
			local delta = oa-da
			rx, _, _ = spGetPieceRotation(data.p)
			local a = delta/(5-i) + rx
			a = max(data.aMin, a)	--clamp to max angles
			a = min(data.aMax, a)
			Turn(data.p, x_axis, a)	--instead of calculating the piece origin position manualy
		end
		rx, _, _  = spGetPieceRotation(kc[3].p)
		if not pos then
			if rx>0 then
				rx=rx*1.7
			else
				rx=rx*.7
			end
		end
		rx = max(kc[4].aMin, rx)	--clamp to max angles
		rx = min(kc[4].aMax, rx)
		Turn(endLink, x_axis, -rx)
		Sleep(32)
	end
end

local function MotionControl()
	local justMoved = true
	while true do
		if bMoving then
			local dx, _, dz = spGetUnitVelocity(unitID)
			dx, dz = 2.5 * dx, 2.5 * dz
			local v =  sqrt(dx*dx + dz*dz)
			if v>0.1 and bMoving then
				local he = atan2(dz,dx)
				local heX, heZ = 5.5*sin(he), 5.5*cos(he)
				local x, y, z = spGetUnitPosition(unitID)
				local dyl = 1.6*(spGetGroundHeight(x+heX,z-heZ)-y)
				local dyr = 1.6*(spGetGroundHeight(x+dx-heX,z+dz+heZ)-y)
				Move(pelvis, y_axis, -1.5, 15)
				StartThread(InverseKinematics,"right", v, v*1.3, dyr, true)
				InverseKinematics("left", v, -v, dyl, true)
				justMoved = true
				x, y, z = spGetUnitPosition(unitID)
				dyl = 1.6*(spGetGroundHeight(x+dx+heX,z+dz-heZ)-y)+4
				dyr = 1.6*(spGetGroundHeight(x-heX,z+heZ)-y)
				Move(pelvis, y_axis, 0, 15)
				StartThread(InverseKinematics,"left", v, 0, dyl, false)
				InverseKinematics("right", v, 0, dyr, true)
				dx, _, dz = spGetUnitVelocity(unitID)
				dx, dz = 2.5 * dx, 2.5 * dz
				v =  sqrt(dx*dx + dz*dz)
				if v>0.1 and bMoving then
					x, y, z = spGetUnitPosition(unitID)
					he = atan2(dz,dx)
					heX, heZ = 5.5*sin(he), 5.5*cos(he)
					dyl = 1.6*(spGetGroundHeight(x+dx+heX,z+dz-heZ)-y)
					dyr = 1.6*(spGetGroundHeight(x-heX,z+heZ)-y)
					Move(pelvis, y_axis, -1.5, 15)
					StartThread(InverseKinematics,"right", v, -v, dyr, true)
					InverseKinematics("left", v, v*1.3, dyl, true)
					x, y, z = spGetUnitPosition(unitID)
					dyl = 1.6*(spGetGroundHeight(x+heX,z-heZ)-y)
					dyr = 1.6*(spGetGroundHeight(x+dx-heX,z+dz+heZ)-y)+4
					Move(pelvis, y_axis, 0, 15)
					StartThread(InverseKinematics,"right", v, 0, dyr, false)
					InverseKinematics("left", v, 0, dyl, true)
				else
					Sleep(100)
				end
			else
				Sleep(100)
			end
		else
			if justMoved then
				justMoved = false
				Move(pelvis, y_axis, 0, 15)
				local x, y, z = spGetUnitPosition(unitID)
				local he = spGetUnitHeading(unitID)*9.5873799242852576857380474343247e-5
				local heX, heZ = 5.5*cos(he), 5.5*sin(he)
				local dyl = 1.6*(spGetGroundHeight(x+heX,z-heZ)-y)
				local dyr = 1.6*(spGetGroundHeight(x-heX,z+heZ)-y)
				if abs(dyr-dyl)<0.1 then
					Turn(lthigh, x_axis, 0, 3)
					Turn(lleg, x_axis, 0, 3)
					Turn(lknee, x_axis, 0, 3)
					Turn(lfoot, x_axis, 0, 3)
					Turn(rthigh, x_axis, 0, 3)
					Turn(rleg, x_axis, 0, 3)
					Turn(rknee, x_axis, 0, 3)
					Turn(rfoot, x_axis, 0, 3)
				else
					StartThread(InverseKinematics,"right", 0.2, 0, dyr, true)
					InverseKinematics("left", 0.2, 0, dyl, true)
				end
			end
			Sleep(100)
		end
	end
end

local function SmokeUnit()
	local healthpercent, sleeptime, smoketype
	while GetUnitValue(COB.BUILD_PERCENT_LEFT) ~= 0 do
		Sleep(500)
	end
	StartThread(MotionControl)
	while true do
		healthpercent = GetUnitValue(COB.HEALTH)
		if healthpercent < 66 then
			smoketype = 258
			if rand(1, 66) < healthpercent then
				smoketype = 257
			end
			EmitSfx(torso, smoketype)
		end
		sleeptime = healthpercent * 50
		if sleeptime < 200 then
			sleeptime = 200
		end
		Sleep(sleeptime)
	end
end

function script.Create()
	bMoving = false
	StartThread(SmokeUnit)
end

function script.StartMoving()
	bMoving = true
end

function script.StopMoving()
	bMoving = false
end

local function RestoreAfterDelay()
	Sleep(2750)
	Turn(torso, y_axis, 0.0, 2)
	Turn(ruparm, x_axis, 0.0, 1)
	Turn(luparm, x_axis, 0.0, 1)
	WaitForTurn(torso, y_axis)
	WaitForTurn(luparm, x_axis)
	WaitForTurn(ruparm, x_axis)
end

function script.AimWeapon1(heading, pitch)
	Signal(SIG_AIM)
	SetSignalMask(SIG_AIM)
	Turn(torso, y_axis, heading, 3.0)
	Turn(luparm, x_axis, -pitch, 1.5)
	Turn(ruparm, x_axis, -pitch, 1.5)
	WaitForTurn(torso, y_axis)
	WaitForTurn(luparm, x_axis)
	WaitForTurn(ruparm, x_axis)
	StartThread(RestoreAfterDelay)
	return true
end

function script.FireWeapon1()
	gun = (gun + 1) % 2
end

function script.QueryWeapon1()
    return fire_point[gun]
end

function script.AimFromWeapon1()
    return torso
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity <= .25 then
		Explode(lleg, sfxNone)
		Explode(lloarm, sfxNone)
		Explode(lthigh, sfxNone)
		Explode(luparm, sfxNone)
		Explode(pelvis, sfxNone)
		Explode(rleg, sfxNone)
		Explode(rloarm, sfxNone)
		Explode(rthigh, sfxNone)
		Explode(ruparm, sfxNone)
		Explode(torso, sfxNone)
		return 1
	elseif severity <= .50 then
		Explode(lfire, sfxFall)
		Explode(lloarm, sfxFall)
		Explode(luparm, sfxFall)
		Explode(pelvis, sfxFall)
		Explode(rfire, sfxFall)
		Explode(rloarm, sfxFall)
		Explode(ruparm, sfxFall)
		Explode(torso, sfxShatter)
		return 2
	elseif severity <= .99 then
		Explode(lfire, sfxFall + sfxSmoke + sfxFire)
		Explode(lloarm, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		Explode(lthigh, sfxFall + sfxSmoke + sfxFire)
		Explode(luparm, sfxFall + sfxSmoke + sfxFire)
		Explode(pelvis, sfxFall + sfxSmoke + sfxFire)
		Explode(rfire, sfxFall + sfxSmoke + sfxFire)
		Explode(rloarm, sfxFall + sfxSmoke + sfxFire)
		Explode(rthigh, sfxFall + sfxSmoke + sfxFire)
		Explode(ruparm, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		Explode(torso, sfxShatter)
		return 3
	end
	Explode(lfire, sfxFall + sfxSmoke + sfxFire)
	Explode(lloarm, sfxFall + sfxSmoke + sfxFire + sfxExplode)
	Explode(lthigh, sfxFall + sfxSmoke + sfxFire)
	Explode(luparm, sfxFall + sfxSmoke + sfxFire)
	Explode(pelvis, sfxFall + sfxSmoke + sfxFire)
	Explode(rfire, sfxFall + sfxSmoke + sfxFire)
	Explode(rloarm, sfxFall + sfxSmoke + sfxFire)
	Explode(rthigh, sfxFall + sfxSmoke + sfxFire)
	Explode(ruparm, sfxFall + sfxSmoke + sfxFire + sfxExplode)
	Explode(torso, sfxShatter)
	return 3
end
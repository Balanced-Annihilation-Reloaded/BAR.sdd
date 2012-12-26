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
		{p=lknee, aMax=rad(13.0), aMin=rad(-12.0)},
		{p=lleg, aMax=rad(61.0), aMin=rad(-34.0)},
		{p=lfoot, aMax=rad(15.0), aMin=rad(-40.0)}
	},
	right = {
		{p=rthigh, aMax=rad(97.0), aMin=rad(-52.0)},
		{p=rknee, aMax=rad(13.0), aMin=rad(-12.0)},
		{p=rleg, aMax=rad(61.0), aMin=rad(-34.0)},
		{p=rfoot, aMax=rad(15.0), aMin=rad(-40.0)}
	}
}

local gun = 1
local bMoving = false

---[[
local function InverseKinematics(leg, v, d, y, pos)	-- A Cyclic Coordinate Descent IK attempt
	if v<=0.1 then
		return
	end
	local kc = kinChain[leg]
	local endLink = kc[#kc].p
	local stp = 6
	local stp_ = stp*.75
	for i=1, stp do
		local rx, data
		local from, to, s
		if pos then
			from, to, s = #kc-1, 1, -1
		else
			from, to, s = 1, #kc-1, 1
		end
		for p=from, to, s do
			data = kc[p]
			local _,y1,z1 = spGetPiecePosDir(data.p)
			local _,ey,ez = spGetPiecePosDir(endLink)
			local oa = atan2(ey-y1,ez-z1)	--origin angle
			local da = atan2(y-y1,d-z1)		--destination angle
			local delta = oa-da
			if delta > 3.141592 then
				delta = 6.2831853071 - delta
			elseif delta < -3.141592 then
				delta = -6.2831853071 - delta
			end
			rx, _, _ = spGetPieceRotation(data.p)
			local a = delta/(stp-i+1) + rx
			a = max(data.aMin, a)	--clamp to max angles
			a = min(data.aMax, a)
			Turn(data.p, x_axis, a)	--instead of calculating the piece origin position manualy
		end
		data = kc[#kc-1]
		rx, _, _  = spGetPieceRotation(data.p)
		rx = max(data.aMin, rx)	--clamp to max angles
		rx = min(data.aMax, rx)
		Turn(endLink, x_axis, -rx)
		--if stp>8 then
			if i<stp then
				Sleep(320/stp)
			end
		-- else
			-- if i>1 and i<stp_ then
				-- Sleep(300/stp)
			-- end
		-- end
	end
end
--]]

--[[
local function RetLeg(leg)
	local kc = kinChain[leg]
	local a = {}
	for i=1, #kc-1 do
		local an, _, _ = spGetPieceRotation(kc[i].p)
		a[i] = an/2
		Turn(kc[i].p, x_axis, a[i], abs(a[i]*3))
	end
	--Spring.Echo()
end
--]]



--[[
local function InverseKinematics(leg, v, d, h)	-- A Cyclic Coordinate Descent IK attempt
	if v<=0.1 then
		return
	end
	local kc = kinChain[leg]
	--local endLink = kc[#kc].p
	local a, y, z, oy, oz = {}, {}, {}, {}, {}
	for i=#kc, 1, -1 do
		_, y[i], z[i] = spGetPiecePosDir(kc[i].p)
		oy[i], oz[i] = y[i], z[i]
		if i<#kc then
			a[i] = atan2(y[i+1]-y[i], z[i+1]-z[i])
		else
			a[i] = 0
		end
	end
	--local _, ey, ez = spGetPiecePosDir(endLink)
	for i=1, 4 do
		--local rx, data
		for p=#kc-1, 1, -1 do
			--data = kc[p]			
			local ofZ, ofY = z[p], y[p]
			local oa = atan2(y[#kc]-ofY,z[#kc]-ofZ)	--origin angle
			local da = atan2(h-ofY,d-ofZ)		--destination angle
			local delta = da-oa
			if delta > 3.141592 then
				delta = 6.2831853071 - delta
			elseif delta < -3.141592 then
				delta = -6.2831853071 - delta
			end
			--
			rx, _, _ = spGetPieceRotation(data.p)
			local a = delta + rx
			a = max(data.aMin, a)	--clamp to max angles
			a = min(data.aMax, a)
			Tdelta = a - rx
			--
			for j=p+1, #kc do
				local tZ, tY = z[j]-ofZ, y[j]-ofY
				z[j] = ofZ + tZ*cos(delta) - tY*sin(delta)
				y[j] = ofY + tZ*sin(delta) + tY*cos(delta)
			end
		end
		
		--Sleep(30)
	end
	for i=#kc-1, 1, -1 do
		local s, _, _ = spGetPieceRotation(kc[i].p)
		--local _, y1, z1 = spGetPiecePosDir(kc[i].p)
		--local _, y2, z2 = spGetPiecePosDir(kc[i+1].p)
		local oa = atan2(oy[i+1]-oy[i], oz[i+1]-oz[i])
		local da = atan2(y[i+1]-y[i], z[i+1]-z[i])
		local delta = da - oa
		if delta > 3.141592 then
			delta = 6.2831853071 - delta
		elseif delta < -3.141592 then
			delta = -6.2831853071 - delta
		end
		
		--if b[i]<0 then b[i] = b[i]+3.141592 elseif b[i]>6.2831853071 then b[i]=b[i]-6.2831853071 end
		--Spring.Echo(kc[i].p, deg(oa), deg(da), deg(delta),deg(s), deg(s+delta))
		--Turn(kc[i].p, x_axis, a[i])
		Turn(kc[i].p, x_axis, s + delta, abs(delta)*4)
	end
end
--]]

local SLP = 750

local function MotionControl()
	local justMoved = true
	while true do
		if bMoving then
			local dx, _, dz = spGetUnitVelocity(unitID)
			dx, dz = 2.85 * dx, 2.85 * dz
			local v =  sqrt(dx*dx + dz*dz)
			if v>0.1 and bMoving then
				local he = atan2(dz,dx)
				local heX, heZ = 5*sin(he), 5*cos(he)
				local x, y, z = spGetUnitPosition(unitID)
				local dyl = 1.5*(spGetGroundHeight(x+heX,z-heZ)-y)+1
				local dyr = 1.5*(spGetGroundHeight(x+dx-heX,z+dz+heZ)-y)+1
				--Spring.Echo(x,z, deg(he), dyl, dyr)--, dyl, dyr, he)
				Move(pelvis, y_axis, -1, 8)
				StartThread(InverseKinematics,"left", v, -v, dyl, true)
				InverseKinematics("right", v, v*1.5, dyr, true)
				justMoved = true
				Move(pelvis, y_axis, 0, 8)
				x, y, z = spGetUnitPosition(unitID)
				dyl = 1.5*(spGetGroundHeight(x+dx+heX,z+dz-heZ)-y)+6
				dyr = 1.5*(spGetGroundHeight(x-heX,z+heZ)-y)+1
				StartThread(InverseKinematics,"left", v, 0, dyl, false)
				InverseKinematics("right", v, 0, dyr, true)
				dx, _, dz = spGetUnitVelocity(unitID)
				dx, dz = 2.85 * dx, 2.85 * dz
				v =  sqrt(dx*dx + dz*dz)
				if v>0.1 and bMoving then
					x, y, z = spGetUnitPosition(unitID)
					he = atan2(dz,dx)
					heX, heZ = 5*sin(he), 5*cos(he)
					dyl = 1.5*(spGetGroundHeight(x+dx+heX,z+dz-heZ)-y)+1
					dyr = 1.5*(spGetGroundHeight(x-heX,z+heZ)-y)+1
					Move(pelvis, y_axis, -1, 8)
					StartThread(InverseKinematics,"left", v, v*1.5, dyl, true)
					InverseKinematics("right", v, -v, dyr, true)
					x, y, z = spGetUnitPosition(unitID)
					dyl = 1.5*(spGetGroundHeight(x+heX,z-heZ)-y)+1
					dyr = 1.5*(spGetGroundHeight(x+dx-heX,z+dz+heZ)-y)+6
					Move(pelvis, y_axis, 0, 8)
					StartThread(InverseKinematics,"left", v, 0, dyl, true)
					InverseKinematics("right", v, 0, dyr, false)
				else
					Sleep(100)
				end
			else
				Sleep(100)
			end
		else
			if justMoved then
				justMoved = false
				Move(pelvis, y_axis, 0, 8)
				--[[
				Turn(lthigh, x_axis, 0, 3)
				Turn(lleg, x_axis, 0, 3)
				Turn(lknee, x_axis, 0, 3)
				Turn(lfoot, x_axis, 0, 3)
				Turn(rthigh, x_axis, 0, 3)
				Turn(rleg, x_axis, 0, 3)
				Turn(rknee, x_axis, 0, 3)
				Turn(rfoot, x_axis, 0, 3)
				--]]
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
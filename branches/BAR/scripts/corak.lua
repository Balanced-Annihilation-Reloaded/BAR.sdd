include("include/util.lua")

local torso, ruparm, luparm, rfire, lfire, rloarm, lloarm, pelvis, rleg, rfoot, lleg, lfoot, lthigh, rthigh, lknee, rknee =
		piece("torso", "ruparm", "luparm", "rfire", "lfire", "rloarm", "lloarm", "pelvis", "rleg", "rfoot", "lleg", "lfoot", "lthigh", "rthigh", "lknee", "rknee")

local SIG_WALK = 1
local SIG_AIM = 2

local spGetGroundHeight	= Spring.GetGroundHeight
local spGetUnitPosition = Spring.GetUnitPosition
local spGetPieceTranslation = Spring.UnitScript.GetPieceTranslation
local spGetPieceRotation = Spring.UnitScript.GetPieceRotation
local spGetUnitHeading = Spring.GetUnitHeading
local spGetUnitVelocity = Spring.GetUnitVelocity
local spGetPiecePosDir = Spring.UnitScript.GetPiecePosDir
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
		{p=lthigh, aMax=rad(97.0), aMin=rad(-52.0)},	--x,y,z coordinated of origin point, angle from initial point, max angle, min angle
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

local function SmokeUnit()
	local healthpercent, sleeptime, smoketype
	while GetUnitValue(COB.BUILD_PERCENT_LEFT) ~= 0 do
		Sleep(500)
	end
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

---[[
local function InverseKinematics(leg, v, d, y, pos)	-- A Cyclic Coordinate Descent IK attempt
	if v<=0.1 then
		return
	end
	local kc = kinChain[leg]
	local endLink = kc[#kc].p
	local stp = 8
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
			if i<stp_ or i==stp then
				Sleep(300/stp)
			end
		-- else
			-- if i>1 and i<stp_ then
				-- Sleep(300/stp)
			-- end
		-- end
	end
end

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
local function InverseKinematics(leg, v, d, y)	-- A Cyclic Coordinate Descent IK attempt
	if v<=0.1 then
		return
	end
	local kc = kinChain[leg]
	local endLink = kc[#kc].p
	local a, b = {}, {}
	for i=1, #kc-1 do
		a[i], _, _ = spGetPieceRotation(kc[i].p)
	end
	for i=1, 6 do
		local rx, data
		for p=#kc-1, 1, -1 do
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
			local a = delta + rx
			a = max(data.aMin, a)	--clamp to max angles
			a = min(data.aMax, a)
			Turn(data.p, x_axis, a)	--instead of calculating the piece origin position manualy
		end
	end
	for i=1, #kc-1 do
		b[i], _, _ = spGetPieceRotation(kc[i].p)
		--if b[i]<0 then b[i] = b[i]+3.141592 elseif b[i]>6.2831853071 then b[i]=b[i]-6.2831853071 end
		Spring.Echo(kc[i].p, a[i], b[i], b[i]-a[i])
		--Turn(kc[i].p, x_axis, a[i])
		--Turn(kc[i].p, x_axis, b[i],b[i]-a[i])
	end
end
--]]

function script.Create()
	StartThread(SmokeUnit)
end

local SLP = 750

local function MotionControl()
	while bMoving do
		local x, y, z = spGetUnitPosition(unitID)
		local dx, _, dz = spGetUnitVelocity(unitID)
		dx, dz = 2.85 * dx, 2.85 * dz
		local dy = spGetGroundHeight(x+dx,z+dz)-y
		local v =  sqrt(dx*dx + dz*dz)
		if v>0.1 and bMoving then
			Move(pelvis, y_axis, -1, 8)
			StartThread(InverseKinematics,"left", v, -v, 0, true)
			InverseKinematics("right", v, v*1.5, dy, true)
			--Sleep(SLP)
			--StartThread(InverseKinematics,"left", v, -v/2, 7)
			--InverseKinematics("right", v, v, dy)
			Move(pelvis, y_axis, 0, 8)
			StartThread(InverseKinematics,"left", v, 0, 7, false)
			--RetLeg("left")
			InverseKinematics("right", v, 0, 0, true)
			--Sleep(SLP)
			x, y, z = spGetUnitPosition(unitID)
			dx, _, dz = spGetUnitVelocity(unitID)
			dx, dz = 2.85 * dx, 2.85 * dz
			dy = spGetGroundHeight(x+dx,z+dz)-y
			v =  sqrt(dx*dx + dz*dz)
			if v>0.1 and bMoving then
				Move(pelvis, y_axis, -1, 8)
				StartThread(InverseKinematics,"left", v, v*1.5, dy, true)
				InverseKinematics("right", v, -v, 0, true)
				--Sleep(SLP)
				--StartThread(InverseKinematics,"left", v, v, dy)
				--InverseKinematics("right", v, -v/2, 7)
				Move(pelvis, y_axis, 0, 8)
				StartThread(InverseKinematics,"left", v, 0, 0, true)
				InverseKinematics("right", v, 0, 7, false)
				--RetLeg("right")
				WaitForTurn(rleg, x_axis)
				--Sleep(SLP)
			else
				Sleep(100)
			end
		else
			Sleep(100)
		end
	end
end

function script.StartMoving()
	if bMoving then
		Signal(SIG_WALK)		
	else
		bMoving = true
		StartThread(MotionControl)
	end
end

local function checkStop()
	SetSignalMask(SIG_WALK)
	Sleep(30)
	bMoving = false
	Sleep(300)
	WaitForTurn(lthigh, x_axis)
	WaitForTurn(lleg, x_axis)
	WaitForTurn(lknee, x_axis)
	WaitForTurn(lfoot, x_axis)
	WaitForTurn(rthigh, x_axis)
	WaitForTurn(rleg, x_axis)
	WaitForTurn(rknee, x_axis)
	WaitForTurn(rfoot, x_axis)
	Move(pelvis, y_axis, 0, 8)
	Turn(lthigh, x_axis, 0, 3)
	Turn(lleg, x_axis, 0, 3)
	Turn(lknee, x_axis, 0, 3)
	Turn(lfoot, x_axis, 0, 3)
	Turn(rthigh, x_axis, 0, 3)
	Turn(rleg, x_axis, 0, 3)
	Turn(rknee, x_axis, 0, 3)
	Turn(rfoot, x_axis, 0, 3)
end

function script.StopMoving()
	StartThread(checkStop)
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
end
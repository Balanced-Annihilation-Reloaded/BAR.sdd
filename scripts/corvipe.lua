--Piece definitions
local base, turret, flare, door1, door2, exhaust = piece("base", "turret", "flare", "door1", "door2", "exhaust");

--Variable definitions
local is_open = true;
local restore_delay = 3000;

--Signal definitions
local SIG_AIM = 2;
local SIG_OPENCLOSE = 4;

include("include/util.lua");

local function close()
	UnitScript.SetSignalMask(SIG_OPENCLOSE + SIG_AIM);
	Sleep(restore_delay);

	is_open = false;
	
	UnitScript.Move(turret, y_axis, -44, 100);
	UnitScript.WaitForMove(turret, y_axis);
	
	UnitScript.Move(door1, x_axis, -8.54, 30);
	UnitScript.Move(door2, x_axis, 8.54, 30);
	
	UnitScript.SetUnitValue(COB.ARMORED, 1);
end

local function open()
	UnitScript.Signal(SIG_OPENCLOSE);
	UnitScript.SetSignalMask(SIG_OPENCLOSE);
	
	UnitScript.SetUnitValue(COB.ARMORED, 0);
	
	UnitScript.Move(door1, x_axis, -8.54);
	UnitScript.Move(door2, x_axis, 8.54);
	UnitScript.Move(door1, x_axis, 0, 30);
	UnitScript.Move(door2, x_axis, 0, 30);
	UnitScript.WaitForMove(door1, x_axis);
	
	UnitScript.Move(turret, y_axis, 0, 100);
	UnitScript.WaitForMove(turret, y_axis);
	
	is_open = true;
	UnitScript.StartThread(close);
end

function script.Create()
	UnitScript.StartThread(smoke_unit, base);
	UnitScript.StartThread(close);
end

function script.AimWeapon1(heading, pitch)
	UnitScript.Signal(SIG_AIM);
	UnitScript.SetSignalMask(SIG_AIM);
	if (not is_open) then UnitScript.StartThread(open); return false; end
	UnitScript.Turn(turret, y_axis, heading, math.rad(200));
	UnitScript.WaitForTurn(turret, y_axis);
	UnitScript.StartThread(close);
	return true;
end

function script.FireWeapon1()
	UnitScript.EmitSfx(exhaust, 1024)
end

function script.QueryWeapon1()
	return flare;
end

function script.AimFromWeapon1()
	return flare;
end

function script.Killed(recentDamage, maxHealth)
	local severity = (recentDamage / maxHealth) * 100;
	local corpsetype;

	if (severity <= 25) then
		if (not is_open) then corpsetype = 1; end
		if (is_open) then corpsetype = 2; end
		UnitScript.Explode(base, SFX.NONE);
		UnitScript.Explode(door1, SFX.NONE);
		UnitScript.Explode(door2, SFX.NONE);
		UnitScript.Explode(turret, SFX.NONE);
		UnitScript.Explode(flare, SFX.NONE);
		return corpsetype;
	end
	if (severity <= 50) then
		if (not is_open) then corpsetype = 2; end
		if (is_open) then corpsetype = 3; end
		UnitScript.Explode(base, SFX.NONE);
		UnitScript.Explode(door1, SFX.NONE);
		UnitScript.Explode(door2, SFX.NONE);
		UnitScript.Explode(turret, SFX.NONE);
		UnitScript.Explode(flare, SFX.NONE);
		return corpsetype;
	end
	if (severity <= 99) then
		if (not is_open) then corpsetype = 3; end
		if (is_open) then corpsetype = 4; end
		UnitScript.Explode(base, SFX.NONE);
		UnitScript.Explode(door1, SFX.NONE);
		UnitScript.Explode(door2, SFX.NONE);
		UnitScript.Explode(turret, SFX.NONE);
		UnitScript.Explode(flare, SFX.NONE);
		return corpsetype;
	end
	corpsetype = 4;
	UnitScript.Explode(base, SFX.NONE);
	UnitScript.Explode(door1, SFX.NONE);
	UnitScript.Explode(door2, SFX.NONE);
	UnitScript.Explode(turret, SFX.NONE);
	UnitScript.Explode(flare, SFX.NONE);
	return corpsetype;
end

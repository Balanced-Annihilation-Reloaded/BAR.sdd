local pad,base,nano1,nano2,nano3,nano4,fan1,fan2,doorr,doorl,doorf = piece("pad","base","nano1","nano2","nano3","nano4","fan1","fan2","doorr","doorl","doorf");

local spray = 0;

local SIG_ACTIVATE = 2;
local SIG_OPENCLOSE = 4;

include("include/util.lua");

function open()
	UnitScript.Signal(SIG_OPENCLOSE);
	UnitScript.SetSignalMask(SIG_OPENCLOSE);
	--Activate
	UnitScript.Move(doorl, x_axis, -17, 17);
	UnitScript.Move(doorr, x_axis, 17, 17);
	UnitScript.Move(doorf, y_axis, -16, 16);
	UnitScript.WaitForMove(doorl, x_axis);
	Sleep(1000);	
	--Open yard
	open_yard();
	--Get into buildstance
	UnitScript.SetUnitValue(COB.INBUILDSTANCE, 1);
end

function close()
	UnitScript.Signal(SIG_OPENCLOSE);
	UnitScript.SetSignalMask(SIG_OPENCLOSE);
	--Get out of buildstance
	UnitScript.SetUnitValue(COB.INBUILDSTANCE, 0);
	--Close yard
	close_yard();
	--Deactivate
	UnitScript.Move(doorf, y_axis, 16, 16);
	UnitScript.Move(doorl, x_axis, 0, 17);
	UnitScript.Move(doorr, x_axis, 0, 17);
	UnitScript.Move(doorf, y_axis, 0, 16);
	UnitScript.WaitForMove(doorl, x_axis);
	Sleep(500);
end

function script.Create()
	spray = 0;
	UnitScript.StartThread(smoke_unit, base);
end

function script.QueryNanoPiece()
	local piecenum;
	if (spray == 0) then
		piecenum = nano1;
	end
	if (spray == 1) then
		piecenum = nano2;
	end
	if (spray == 2) then
		piecenum = nano3;
	end
	if (spray == 3) then
		piecenum = nano4;
	end
	spray = spray + 1;
	if(spray == 4) then
		spray = 0;
	end
	return piecenum;
end

function Activate_real()
	UnitScript.Signal(SIG_ACTIVATE);
	UnitScript.StartThread(open);

end

function script.Activate()
	UnitScript.StartThread(Activate_real);
end

function Deactivate_real()
	UnitScript.Signal(SIG_ACTIVATE);
	UnitScript.SetSignalMask(SIG_ACTIVATE);
	Sleep(5000);
	UnitScript.StartThread(close);
end

function script.Deactivate()
	UnitScript.StartThread(Deactivate_real);
end

function script.StartBuilding()
	UnitScript.Spin(fan1, z_axis, math.rad(200), math.rad(5));
	UnitScript.Spin(fan2, z_axis, math.rad(200), math.rad(5));
end

function script.StopBuilding()
	UnitScript.StopSpin(fan1, z_axis, math.rad(3));
	UnitScript.StopSpin(fan2, z_axis, math.rad(3));
end

function script.QueryBuildInfo()
	return pad;
end

function script.Killed(recentDamage, maxHealth)
	local severity = (recentDamage / maxHealth) * 100;
	local corpsetype;
	
	if (severity <= 25) then
		corpsetype = 1;
		UnitScript.Explode(base, SFX.NONE);
		UnitScript.Explode(doorf, SFX.NONE);
		UnitScript.Explode(doorl, SFX.NONE);
		UnitScript.Explode(doorr, SFX.NONE);
		UnitScript.Explode(fan1, SFX.NONE);
		UnitScript.Explode(fan2, SFX.NONE);
		UnitScript.Explode(nano1, SFX.NONE);
		UnitScript.Explode(nano2, SFX.NONE);
		UnitScript.Explode(nano3, SFX.NONE);
		UnitScript.Explode(nano4, SFX.NONE);
		UnitScript.Explode(pad, SFX.NONE);
		return corpsetype;
	end
	if (severity <= 50) then
		corpsetype = 2;
		UnitScript.Explode(base, SFX.NONE);
		UnitScript.Explode(doorf, SFX.NONE);
		UnitScript.Explode(doorl, SFX.NONE);
		UnitScript.Explode(doorr, SFX.NONE);
		UnitScript.Explode(fan1, SFX.NONE);
		UnitScript.Explode(fan2, SFX.NONE);
		UnitScript.Explode(nano1, SFX.NONE);
		UnitScript.Explode(nano2, SFX.NONE);
		UnitScript.Explode(nano3, SFX.NONE);
		UnitScript.Explode(nano4, SFX.NONE);
		UnitScript.Explode(pad, SFX.NONE);
		return corpsetype;
	end
	if (severity <= 99) then
		corpsetype = 3;
		UnitScript.Explode(base, SFX.NONE);
		UnitScript.Explode(doorf, SFX.NONE);
		UnitScript.Explode(doorl, SFX.NONE);
		UnitScript.Explode(doorr, SFX.NONE);
		UnitScript.Explode(fan1, SFX.NONE);
		UnitScript.Explode(fan2, SFX.NONE);
		UnitScript.Explode(nano1, SFX.NONE);
		UnitScript.Explode(nano2, SFX.NONE);
		UnitScript.Explode(nano3, SFX.NONE);
		UnitScript.Explode(nano4, SFX.NONE);
		UnitScript.Explode(pad, SFX.NONE);
		return corpsetype;
	end
	corpsetype = 3;
	UnitScript.Explode(base, SFX.NONE);
	UnitScript.Explode(doorf, SFX.NONE);
	UnitScript.Explode(doorl, SFX.NONE);
	UnitScript.Explode(doorr, SFX.NONE);
	UnitScript.Explode(fan1, SFX.NONE);
	UnitScript.Explode(fan2, SFX.NONE);
	UnitScript.Explode(nano1, SFX.NONE);
	UnitScript.Explode(nano2, SFX.NONE);
	UnitScript.Explode(nano3, SFX.NONE);
	UnitScript.Explode(nano4, SFX.NONE);
	UnitScript.Explode(pad, SFX.NONE);
	return corpsetype;
end

--pieces
        local base = piece "base"

        local turret = piece "turret"

        local spindle = piece "spindle"

        local flare = piece "flare"

	local dmgPieces = { piece "base", piece "flare" }
        local currBarrel = 1


-- includes
	include "dmg_smoke.lua"


--signals
        local SIG_AIM = 1

        
        function script.Create()
	Hide(flare)
	StartThread(dmgsmoke, dmgPieces)
        end

        local function RestoreAfterDelay(unitID)
                Sleep(2500)
                Turn(turret, x_axis, 0, math.rad(50))
		Turn(sleeves, x_axis, 0, math.rad(50))
        end

	function script.QueryWeapon1()
                
                if (currBarrel == 1) then 
                        return flare
                else 
                        return flare
                end
        end
     

        function script.AimFromWeapon1() return turret end
        
        function script.AimWeapon1( heading, pitch )
                Signal(SIG_AIM)
                SetSignalMask(SIG_AIM)
		Turn( turret, y_axis, heading, math.rad(200.043956) )
		Turn( turret, x_axis, -pitch, math.rad(200.043956) )
                WaitForTurn(turret, y_axis)
                WaitForTurn(turret, x_axis)
                return true
        end
        
        function script.FireWeapon1()
		if currBarrel == 1 then
			--EmitSfx(flare1, 1024+0)
			
			Turn (spindle, z_axis, math.rad(0.000000), math.rad(400.093407))
			WaitForTurn(spindle, z_axis)
			--Move (barrel1, z_axis, 0.000000, 1.000000)	
		end
		if currBarrel == 2 then
			--EmitSfx(flare1, 1024+0)
			
			Turn (spindle, z_axis, math.rad(120.000000), math.rad(400.093407))
			WaitForTurn(spindle, z_axis)
			--Move (barrel1, z_axis, 0.000000, 1.000000)	
		end
		if currBarrel == 3 then
			--EmitSfx(flare1, 1024+0)
			
			Turn (spindle, z_axis, math.rad(240.000000), math.rad(400.093407))
			WaitForTurn(spindle, z_axis)
			--Move (barrel1, z_axis, 0.000000, 1.000000)	
		end

		currBarrel = currBarrel + 1
		if currBarrel == 4 then currBarrel = 1 
		end
	
        end
        
	function script.Killed(recentDamage, maxHealth)
		local severity = recentDamage / maxHealth

		if (severity <= .25) then
			--Explode(base, SFX.SHATTER)
			--Explode(turret, SFX.EXPLODE)
			--Explode(spindle, SFX.EXPLODE)

			return 1 -- corpsetype

		elseif (severity <= .5) then
			--Explode(base, SFX.SHATTER)
			--Explode(turret, SFX.EXPLODE)
			Explode(spindle, SFX.EXPLODE)

			return 2 -- corpsetype
		else
			--Explode(base, SFX.SHATTER)
			Explode(turret, SFX.EXPLODE)
			Explode(spindle, SFX.EXPLODE)

			return 3 -- corpsetype
		end
	end

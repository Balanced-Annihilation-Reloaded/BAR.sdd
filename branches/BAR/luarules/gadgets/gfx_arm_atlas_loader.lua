
function gadget:GetInfo()
	return {
		name	= 'Arm Atlas Loader',
		desc	= 'Forces the arm atlas to be loaded',
		author	= 'Bluestone',
		date	= '',
		license	= 'GNU GPL v3',
		layer	= 0, 
		enabled	= true,
	}
end

-- this is a bit of a hack!

if gadgetHandler:IsSyncedCode() then return false end

local n = 0
local ARMCOM = UnitDefNames["armcom"].id

function gadget:DrawWorld()
    n  = n + 1

    if n==1 then
        gl.PushMatrix()
            gl.Translate(-1000, -1000, -1000)
            gl.UnitShape(ARMCOM, 0)
        gl.PopMatrix()
    end
    
    if n>1 then
        gadgetHandler:RemoveGadget()
    end

end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Unittexture Preloader",
    desc      = "Preloads unittextures",
    author    = "beherith",
    date      = "2014 jan",
    license   = "GPLv2",
    layer     = 1000,
    enabled   = true,  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local files = {
    --"unittextures/Arm_color.dds", --preloading these (they are used by S30) seems to have no effect
    --"unittextures/Arm_other.dds",
    "unittextures/Core_normal.dds", -- this does reduce the stall when first unit using this is constructed, but also it should only preload if luaunitshader are enabled? (else its a waste of time and gpu ram)
    "unittextures/Arm_normals.dds",
}




function widget:DrawGenesis()
    --
    -- workaround for https://springrts.com/mantis/view.php?id=5136
    for udid, ud in pairs(UnitDefs) do
        local temp = ud.model.midx
    end
    for fdid, fd in pairs(FeatureDefs) do
        local temp = fd.model.midx
    end
    --
    
    
	if Spring.GetGameFrame() < 1 then 
		for i,file in ipairs(files) do
			gl.Texture(7,file)
			gl.Texture(7,false)
			Spring.Echo('Preloaded',file)
		end
	end
    widgetHandler:RemoveWidget()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
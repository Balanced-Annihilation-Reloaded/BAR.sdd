-- $Id$
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local GetGameFrame=Spring.GetGameFrame
local GetUnitHealth=Spring.GetUnitHealth
local glUniform=gl.Uniform
local sine =math.sin
local maximum=math.max



local function DrawUnit(unitID, material,drawMode)
	--if unitID%100==0 then  Spring.Echo('drawmode',drawMode) end
	if (drawMode ==1)then -- we can skip setting the uniforms as they only affect fragment color, not fragment alpha or vertex positions, so they dont have an effect on shadows, and drawmode 2 is shadows, 1 is normal mode.
		--Spring.Echo('drawing',UnitDefs[Spring.GetUnitDefID(unitID)].name,GetGameFrame())
		local  health,maxhealth=GetUnitHealth(unitID)
		health= 2*maximum(0, (-2*health)/(maxhealth)+1) --inverse of health, 0 if health is 100%-50%, goes to 1 by 0 health
		glUniform(material.etcLoc, 2* maximum(0,sine((unitID%10)+GetGameFrame()/((unitID%7)+6))), health,0 )
	  
	end

  --// engine should still draw it (we just set the uniforms for the shader)
  return false
end

local materials = {
   normalMappedS3O = {
       shaderDefinitions = {
         "#define use_perspective_correct_shadows",
         "#define use_normalmapping",
         --"#define flip_normalmap",
         "#define deferred_mode 0",
       },
       deferredDefinitions = {
         "#define use_perspective_correct_shadows",
         "#define use_normalmapping",
         --"#define flip_normalmap",
         "#define deferred_mode 1",
       },

       shader    = include("ModelMaterials/Shaders/default.lua"),
       deferred  = include("ModelMaterials/Shaders/default.lua"),
       usecamera = false,
       culling   = GL.BACK,
		predl  = nil,
		postdl = nil,
       texunits  = {
         [0] = '%%UNITDEFID:0',
         [1] = '%%UNITDEFID:1',
         [2] = '$shadow',
         [3] = '$specular',
         [4] = '$reflection',
         [5] = '%NORMALTEX',
       },
	   DrawUnit = DrawUnit,
   },
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Automated normalmap detection

local unitMaterials = {}



local function FindNormalmap(tex1, tex2)
  local normaltex

  --// check if there is a corresponding _normals.dds file
  if (VFS.FileExists(tex1)) then
    local basefilename = tex1:gsub("%....","")
    --[[if (tonumber(basefilename:sub(-1,-1))) then
      basefilename = basefilename:sub(1,-2)
    end]]-- -- This code removes trailing numbers, but many S44 units end in a number, e.g. SU-76
    if (basefilename:sub(-1,-1) == "_") then
       basefilename = basefilename:sub(1,-2)
    end
    normaltex = basefilename .. "_normals.dds"
    if (not VFS.FileExists(normaltex)) then
      normaltex = nil
    end
  end --if FileExists

  --[[if (not normaltex) and tex2 and (VFS.FileExists(tex2)) then
    local basefilename = tex2:gsub("%....","")
    if (tonumber(basefilename:sub(-1,-1))) then
      basefilename = basefilename:sub(1,-2)
    end
    if (basefilename:sub(-1,-1) == "_") then
      basefilename = basefilename:sub(1,-2)
    end
    normaltex = basefilename .. "_normals.dds"
    if (not VFS.FileExists(normaltex)) then
      normaltex = nil
    end
  end --if FileExists ]] -- disable tex2 detection for S44

  return normaltex
end



for i=1,#UnitDefs do
  local udef = UnitDefs[i]

  if ((udef.customParams.arm_tank == nil ) and udef.customParams.normaltex and VFS.FileExists(udef.customParams.normaltex)) then
    unitMaterials[udef.name] = {"normalMappedS3O", NORMALTEX = udef.customParams.normaltex}
    --Spring.Echo('normalmapped',udef.name)
  end --elseif
end --for

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

return materials, unitMaterials

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

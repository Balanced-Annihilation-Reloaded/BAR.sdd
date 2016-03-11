-- $Id$
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


local materials = {
	feature_wreck = {
		shader    = include("ModelMaterials/Shaders/default.lua"),
		deferred  = include("ModelMaterials/Shaders/default.lua"),
		shaderDefinitions = {
			-- "#define use_perspective_correct_shadows",
			"#define use_normalmapping",
			--"#define flip_normalmap",
			"#define deferred_mode 0",
			"#define use_vertex_ao",
		},
		deferredDefinitions = {
			--"#define use_perspective_correct_shadows",
			"#define use_normalmapping",
			--"#define flip_normalmap",
			"#define deferred_mode 1",
			"#define use_vertex_ao",
		},
		force     = false, --// always use the shader even when normalmapping is disabled
		usecamera = false,
		culling   = GL.BACK,
		texunits  = {
			[0] = '%%FEATUREDEFID:0',
			[1] = '%%FEATUREDEFID:1',
			[2] = '$shadow',
			[3] = '$specular',
			[4] = '$reflection',
			[5] = '%NORMALTEX',
		},
		--DrawFeature = DrawFeature,
		feature = true, --// This is used to define that this is a feature shader
	},
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- affected featuredefs

local featureMaterials = {}

for id, featureDef in pairs(FeatureDefs) do
	Spring.PreloadFeatureDefModel(id)
	-- how to check if its a wreck or a heap?
	if featureDef.name:find("_dead") and featureDef.model.textures.tex1 then
		if featureDef.model.textures.tex1:find("Arm_wreck") then
			featureMaterials[featureDef.name] = {"feature_wreck", NORMALTEX = "unittextures/Arm_wreck_color_normal.dds"}
			--Spring.Echo('Featuredef info for', featureDef.name, to_string(featureDef.model))
		elseif featureDef.model.textures.tex1:find("Core_color_wreck") then 
			featureMaterials[featureDef.name] = {"feature_wreck", NORMALTEX = "unittextures/Core_color_wreck_normal.dds"}
		else
			Spring.Echo("3_feature_wrecks: featureDef.name has _dead but doesnt have the correct tex1 defined!",featureDef.name, featureDef.model.tex1)
		end
	end
end

function to_string(data, indent)
	local str = ""

	if(indent == nil) then
		indent = 0
	end

	-- Check the type
	if(type(data) == "string") then
		str = str .. ("    "):rep(indent) .. data .. "\n"
	elseif(type(data) == "number") then
		str = str .. ("    "):rep(indent) .. data .. "\n"
	elseif(type(data) == "boolean") then
		if(data == true) then
			str = str .. "true"
		else
			str = str .. "false"
		end
	elseif(type(data) == "table") then
		local i, v
		for i, v in pairs(data) do
			-- Check for a table in a table
			if(type(v) == "table") then
				str = str .. ("    "):rep(indent) .. i .. ":\n"
				str = str .. to_string(v, indent + 2)
			else
				str = str .. ("    "):rep(indent) .. i .. ": " .. to_string(v, 0)
			end
		end
	elseif (data ==nil) then
		str=str..'nil'
	else
		--print_debug(1, "Error: unknown data type: %s", type(data))
		str=str.. "Error: unknown data type:" .. type(data)
		Spring.Echo('X data type')
	end

	return str
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

return materials, featureMaterials

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

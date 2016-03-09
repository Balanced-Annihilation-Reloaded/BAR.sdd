-- $Id$
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


local materials = {
	feature_wreck = {
	shader    = include("ModelMaterials/Shaders/default.lua"),
	deferred  = include("ModelMaterials/Shaders/default.lua"),
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


for id, featureDef in pairs(FeatureDefs) do
	Spring.PreloadFeatureDefModel(fdid)
	-- how to check if its a wreck or a heap?
	if featureDef.name:find("_dead")
		featureMaterials[featureDef.name] = {"feature_wreck", NORMALTEX = "unittextures/Arm_wreck_color_normal.dds"}
			
			--TODO: identify the correct feature names for each unit, and only load BAR features
			--TODO: dont load the models to check for tex1 and tex2, even if that seems like a good idea
			-- loading 400+ wrecks is a BAD idea -- TODO: but hmm, maybe loading them all at gamestart would reduce the stutter they produce when getting loaded for the first time...
			
			

	end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

return materials, featureMaterials

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

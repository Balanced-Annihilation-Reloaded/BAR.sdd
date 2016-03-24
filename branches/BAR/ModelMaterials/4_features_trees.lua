-- $Id$
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local etcLocIDs = {[0] = -2, [1] = -2}

local function DrawFeature(featureID, material, drawMode) -- UNUSED!
  local etcLocIdx = (drawMode == 5) and 1 or 0
  local curShader = (drawMode == 5) and material.deferredShader or material.standardShader

  if etcLocIDs[etcLocIdx] == -2 then
    etcLocIDs[etcLocIdx] = gl.GetUniformLocation(curShader, "etcLoc")
  end
  
  gl.Uniform(etcLocIDs[etcLocIdx], Spring.GetGameFrame(), 0.0, 0.0)
  return false
end

local materials = {
	feature_tree = {
		shader    = include("ModelMaterials/Shaders/default.lua"),
		deferred  = include("ModelMaterials/Shaders/default.lua"),
		shaderDefinitions = {
			"#define use_normalmapping",
			"#define deferred_mode 0",
		},
		deferredDefinitions = {
			--"#define use_normalmapping", --very expensive for trees (too much overdraw)
			"#define deferred_mode 1",
		},
		shaderPlugins = {
			VERTEX_GLOBAL_NAMESPACE = [[
				
			]],
			VERTEX_PRE_TRANSFORM = [[
				//The unique value is generated from the object's X and Z pos in the world.
				//For static objects, like map features, they are usually placed on grids divisible by 8
				// unique_value range is [0,1)
				float unique_value = fract(1.234567*(gl_ModelViewMatrix[3][0]+gl_ModelViewMatrix[3][2]));
				float timer = 0.05 * sin( unique_value + simFrame * ((1+unique_value)*0.07));

				float factor=sin((vertex.x+vertex.y+vertex.z)*0.1+simFrame*0.02)*0.4;
				float factor2=cos((vertex.x+vertex.y+vertex.z)*0.1+simFrame*0.03)*0.4;
				float distancefromtrunk=(abs(vertex.x)+abs(vertex.z))/10;
				
				vertex.x+=vertex.y*timer/20;
				vertex.z-=vertex.y*timer/20;
				
				//vertex.y+=distancefromtrunk*factor;
				//vertex.z+=distancefromtrunk*factor;
				//vertex.x+=distancefromtrunk*factor2;
				
			]],
			FRAGMENT_POST_SHADING = [[
				//gl_FragColor.r=1.0;
			]]
		},
		force     = false, --// always use the shader even when normalmapping is disabled
		feature = true, --// This is used to define that this is a feature shader
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
	},
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- affected unitdefs

local featureMaterials = {}
local featureNameStubs = {"ad0_", "btree", "art"} -- all of the 0ad, beherith and artturi features start with these.
local tex1_to_normaltex = {}
-- All feature defs that contain the string "aleppo" will be affected by it
for id, featureDef in pairs(FeatureDefs) do
	Spring.PreloadFeatureDefModel(id)
	for _,stub in ipairs (featureNameStubs) do 
		if featureDef.model.textures and featureDef.model.textures.tex1 and featureDef.name:find(stub) and featureDef.name:find(stub) == 1 then --also starts with
			--if featureDef.customParam.normaltex then
				Spring.Echo('Feature',featureDef.name,'seems like a nice tree, assigning the default normal texture to it.')
				if featureDef.name:find('btree') == 1 then --beherith's old trees suffer if they get shitty normals
					featureMaterials[featureDef.name] = {"feature_tree", NORMALTEX = "unittextures/blank_normal.tga"}
				else
					featureMaterials[featureDef.name] = {"feature_tree", NORMALTEX = "unittextures/default_tree_normal.tga"}
				end

			--TODO: dont forget the feature normals!
			--TODO: actually generate normals for all these old-ass features, and include them in BAR
			--TODO: add a blank normal map to avoid major fuckups.
			--Todo, grab the texture1 names for features in tex1_to_normaltex assignments, 
			--and hope that I dont have to actually load the models to do so
			
		end
	end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

return materials, featureMaterials

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

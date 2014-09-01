function widget:GetInfo()
	return {
		name      = "BloomShader and LOSshader",
		desc      = "Sets Spring In Bloom",
		author    = "Kloot,Beherith",
		date      = "28-5-2008",
		license   = "Losshader: cc-by-nd",
		layer     = -10000,
		enabled   = true,
	}
end

--INFO: 
--with default params, FPS halves, and memory controller load doubles. That is 2 blur passes and 1 dilate pass.

-- default perf (1766): 116 fps, 4.5% cpu
-- new perf (1766+) with different order.

-- config params
local dbgDraw = 0					-- draw only the bloom-mask? [0 | 1]
local glowAmplifier = 1.2			-- intensity multiplier when filtering a glow source fragment [1, n]
local blurAmplifier = 1.1		-- intensity multiplier when applying a blur pass [1, n] (should be set close to 1)
local illumThreshold = 1			-- how bright does a fragment need to be before being considered a glow source? [0, 1]
local blurPasses = 3				-- how many iterations of (7x7) Gaussian blur should be applied to the glow sources?

-- non-editables
local vsx = 1						-- current viewport width
local vsy = 1						-- current viewport height
local ivsx = 1.0 / vsx
local ivsy = 1.0 / vsy

--quality =2 : 113 fps, 57% memctrler load, 99% shader load
--quality =1 : 90 fps, 9% memctrler load, 99% shader load
--quality =4 : 123 fps, 9% memctrler load, 99% shader load
local quality  = 2


-- shader and texture handles
local blurShaderH71 = nil
local blurShaderV71 = nil

local brightShader = nil
local brightTexture1 = nil
local brightTexture2 = nil

local combineShader = nil
local losShader = nil
local screenTexture = nil
local losTexture = nil

-- speedups
local glGetSun = gl.GetSun

local glCreateTexture = gl.CreateTexture
local glDeleteTexture = gl.DeleteTexture
local glActiveTexture = gl.ActiveTexture
local glCopyToTexture = gl.CopyToTexture
local glRenderToTexture = gl.RenderToTexture
local glTexture = gl.Texture
local glTexRect = gl.TexRect
local glGenerateMipmaps = gl.GenerateMipmap
local glReadPixels = gl.ReadPixels

local glGetShaderLog = gl.GetShaderLog
local glCreateShader = gl.CreateShader
local glDeleteShader = gl.DeleteShader
local glUseShader = gl.UseShader

local glUniformInt = gl.UniformInt
local glUniform = gl.Uniform
local glUniformMatrix = gl.UniformMatrix
local glGetUniformLocation = gl.GetUniformLocation
local glGetActiveUniforms = gl.GetActiveUniforms


local GL_RGBA32F_ARB                = 0x8814
local GL_RGB32F_ARB                 = 0x8815
local GL_ALPHA32F_ARB               = 0x8816
local GL_INTENSITY32F_ARB           = 0x8817
local GL_LUMINANCE32F_ARB           = 0x8818
local GL_LUMINANCE_ALPHA32F_ARB     = 0x8819
local GL_RGBA16F_ARB                = 0x881A
local GL_RGB16F_ARB                 = 0x881B
local GL_ALPHA16F_ARB               = 0x881C
local GL_INTENSITY16F_ARB           = 0x881D
local GL_LUMINANCE16F_ARB           = 0x881E
local GL_LUMINANCE_ALPHA16F_ARB     = 0x881F
local GL_TEXTURE_RED_TYPE_ARB       = 0x8C10
local GL_TEXTURE_GREEN_TYPE_ARB     = 0x8C11
local GL_TEXTURE_BLUE_TYPE_ARB      = 0x8C12
local GL_TEXTURE_ALPHA_TYPE_ARB     = 0x8C13
local GL_TEXTURE_LUMINANCE_TYPE_ARB = 0x8C14
local GL_TEXTURE_INTENSITY_TYPE_ARB = 0x8C15
local GL_TEXTURE_DEPTH_TYPE_ARB     = 0x8C16
local GL_UNSIGNED_NORMALIZED_ARB    = 0x8C17


-- shader uniform locations
local brightShaderText0Loc = nil
local brightShaderInvRXLoc = nil
local brightShaderInvRYLoc = nil
local brightShaderIllumLoc = nil
local brightShaderFragLoc = nil

local blurShaderH51Text0Loc = nil
local blurShaderH51InvRXLoc = nil
local blurShaderH51FragLoc = nil
local blurShaderV51Text0Loc = nil
local blurShaderV51InvRYLoc = nil
local blurShaderV51FragLoc = nil

local blurShaderH71Text0Loc = nil
local blurShaderH71InvRXLoc = nil
local blurShaderH71FragLoc = nil
local blurShaderV71Text0Loc = nil
local blurShaderV71InvRYLoc = nil
local blurShaderV71FragLoc = nil

local combineShaderDebgDrawLoc = nil
local combineShaderTexture0Loc = nil
local combineShaderTexture1Loc = nil


local losShaderViewPrjInvLoc = nil
local losShaderInfoTexLoc = nil
local losShaderColorTexLoc = nil
local losShaderModelDepthTexLoc = nil 
local losShaderMapDepthTexLoc = nil
local losShaderGameFrameLoc = nil
	


local bloomin=0
local minimapbrightness=nil


local mx =math.pow(2, math.ceil(math.log(Game.mapSizeX)/math.log(2)))-- Game.mapSizeX
local mz =math.pow(2, math.ceil(math.log(Game.mapSizeZ)/math.log(2)))-- Game.mapSizeZ
local gnd_min, gnd_max = Spring.GetGroundExtremes()
gnd_min=gnd_min --just in case we blow a massive hole in the map.


local function SetIllumThreshold()
	local ra, ga, ba = glGetSun("ambient")
	local rd, gd, bd = glGetSun("diffuse")
	local rs, gs, bs = glGetSun("specular")

	local ambientIntensity  = ra * 0.299 + ga * 0.587 + ba * 0.114
	local diffuseIntensity  = rd * 0.299 + gd * 0.587 + bd * 0.114
	local specularIntensity = rs * 0.299 + gs * 0.587 + bs * 0.114

	illumThreshold = illumThreshold*(0.8 * ambientIntensity) + (0.5 * diffuseIntensity) + (0.1 * specularIntensity)

	print("[BloomShader::SetIllumThreshold] sun ambient color:  ", ra .. ", " .. ga .. ", " .. ba .. " (intensity: " .. ambientIntensity .. ")")
	print("[BloomShader::SetIllumThreshold] sun diffuse color:  ", rd .. ", " .. gd .. ", " .. bd .. " (intensity: " .. diffuseIntensity .. ")")
	print("[BloomShader::SetIllumThreshold] sun specular color: ", rs .. ", " .. gs .. ", " .. bs .. " (intensity: " .. specularIntensity .. ")")
	print("[BloomShader::SetIllumThreshold] illumination threshold: " .. illumThreshold)
	Spring.Echo("[BloomShader::SetIllumThreshold] illumination threshold: " .. illumThreshold)
end

local function RemoveMe(msg)
	Spring.Echo(msg)
	widgetHandler:RemoveWidget()
end


function widget:ViewResize(viewSizeX, viewSizeY)
	Spring.Echo('gfx_bloom_los_shader.lua viewresize')
	vsx = viewSizeX; ivsx = 1.0 / vsx --we can do /n here!
	vsy = viewSizeY; ivsy = 1.0 / vsy
	  qvsx,qvsy = math.floor(vsx/quality), math.floor(vsy/quality)
	glDeleteTexture(brightTexture1 or "")
	glDeleteTexture(brightTexture2 or "")
	glDeleteTexture(screenTexture or "")
	glDeleteTexture(losTexture or "")

	brightTexture1 = glCreateTexture(qvsx, qvsy, {
		fbo = true, 
		min_filter = GL.LINEAR, mag_filter = GL.LINEAR,
		--format = GL_RGB16F_ARB,
		wrap_s = GL.CLAMP, wrap_t = GL.CLAMP,
	})
	brightTexture2 = glCreateTexture(qvsx, qvsy, {
		fbo = true, min_filter = GL.LINEAR, mag_filter = GL.LINEAR,
		--format = GL_RGB16F_ARB,
		wrap_s = GL.CLAMP, wrap_t = GL.CLAMP,
	})

	screenTexture = glCreateTexture(vsx, vsy, {
		min_filter = GL.LINEAR, mag_filter = GL.NEAREST,
	}) 
	
	losTexture = glCreateTexture(vsx, vsy, {
		min_filter = GL.NEAREST, mag_filter = GL.NEAREST,
	})

	if (brightTexture1 == nil or brightTexture2 == nil or screenTexture == nil or GL.NEAREST == nil) then
		if (brightTexture1 == nil ) then Spring.Echo('brightTexture1 == nil ') end
		if (brightTexture2 == nil ) then Spring.Echo('brightTexture2 == nil ') end
		if (GL.NEAREST == nil ) then Spring.Echo('GL.NEAREST == nil ') end
		if (screenTexture == nil ) then Spring.Echo('screenTexture == nil ') end
		RemoveMe("[BloomShader::ViewResize] removing widget, bad texture target")
		return
	end
end

widget:ViewResize(widgetHandler:GetViewSizes())

--- default uikeys, unbind!
--//  bind              Any+l  togglelos
--//  bind              Any+;  toggleradarandjammer
local updaterate=45

function widget:Initialize()
	-- params=Spring.GetConfigParams()
	-- for i,v in ipairs(params) do
		-- Spring.Echo(i,v,v.name)
	-- end
	if  (Spring.GetConfigString("AllowDeferredMapRendering") == '0' or Spring.GetConfigString("AllowDeferredModelRendering")=='0') then
		RemoveMe('LOS shader requires  AllowDeferredMapRendering and AllowDeferredModelRendering to be enabled in springsettings.cfg!') 
		return
	end
	
	if (glCreateShader == nil) then
		RemoveMe("[BloomShader::Initialize] removing widget, no shader support")
		return
	end

	Spring.SendCommands("unbind Any+l togglelos")
	Spring.SendCommands("bind Any+l luaui los")
	SetIllumThreshold()

	
	losFragSrc=([[
	//--------------------------------------------------------------------
	//SHADER LICENSE: Copyright Beherith, this shader may not be distributed outside of BAR. All rights reserved.
	//--------------------------------------------------------------------
	const float mapxmul= 1.0 / %f;
	const float mapzmul= 1.0 / %f;
	const float mapxmax = %f ;
	const float mapzmax = %f ;
	const float mapymin = %f ;
	const float mapymax = %f ;
	
	uniform sampler2D infotex; // r=los, g= radar, b=jammer
	uniform sampler2D colortex;
	uniform sampler2D modeldepthtex;
	uniform sampler2D mapdepthtex;
	uniform mat4 viewProjectionInv;
	uniform float gameframe;
	float rand(vec2 co, float gf){
		return fract(sin(dot(co.xy ,vec2(12.9898,78.233)) +gf) * 43758.5453);
	}
	void main(void)
	{

		vec4 mappos4 =vec4(vec3(gl_TexCoord[0].st, texture2D( mapdepthtex,gl_TexCoord[0].st ).x) * 2.0 - 1.0 ,1.0);
		vec4 modelpos4 =vec4(vec3(gl_TexCoord[0].st, texture2D( modeldepthtex,gl_TexCoord[0].st ).x) * 2.0 - 1.0 ,1.0);
		float mapfragment=1.0;
		if ((mappos4.z-modelpos4.z)> 0.0) { // this means we are processing a model fragment, not a map fragment
			mappos4 = modelpos4;
			mapfragment=0.0;
		}
		mappos4 = viewProjectionInv * mappos4;
		mappos4.xyz = mappos4.xyz / mappos4.w;
		
		
		vec3 info = texture2D(infotex, vec2(mappos4.x*mapxmul, mappos4.z*mapzmul));
		vec3 color= texture2D(colortex,gl_TexCoord[0].st);
		//gl_FragColor=vec4( info.r,info.g,info.b,0.9);//infotex debugging
		//gl_FragColor = vec4(fract(mappos4.x/50),fract(mappos4.y/50),fract(mappos4.z/50), 1.0);
		//return;
		float rnd= 2*rand(gl_TexCoord[0].st,gameframe);
		float noisefactor=min((1.0-info.g+info.b),1.0); //noise is applied to non-radar or jammed areas
		float desatfactor=max(((0.5-info.r)*2),0.0)*(1.0-info.g);  //desaturation is to be applied to areas outside of airlos AND outside of radar
		float darkenfactor=max((1.0-info.r)*0.4,0.0); //darkening is applied to areas outside of normal los
		
		
		float gamestartfactor=min(1.0, gameframe);
		if ( any( lessThan(mappos4.xyz,vec3(0.0,mapymin,0.0))) || any (greaterThan(mappos4.xyz,vec3(mapxmax,mapymax,mapzmax)))) gamestartfactor=0; //this is possibly cheaper than the one after it
		
		//if (mappos4.z>mapxmax || mappos4.z<0.0 || mappos4.x>mapxmax || mappos4.x<0.0 || mappos4.y>mapymax || mappos4.y<mapymin) gamestartfactor=0; // i hope to god that this isnt expensive, Ill have to check disassembly.
		vec3 newcolor= mix(color, color*(0.95+0.1*rnd),(noisefactor*mapfragment)*(darkenfactor*1.5+0.5));
		float desat=dot(vec3(0.2,0.7,0.1),newcolor);
		newcolor = mix(newcolor, vec3(desat,desat,desat),desatfactor);
		newcolor = newcolor*(1.0-darkenfactor);
		newcolor=mix(color,newcolor, gamestartfactor);
		gl_FragColor=vec4(newcolor.rgb,1.0);
		//gl_FragColor=vec4(noisefactor,desatfactor,darkenfactor,1.0);
		
		
	#ifdef DEBUG_GFX // world position debugging
		const float k  = 100.0;
		vec3 debugColor =worldPos4.xyz;
		gl_FragColor = vec4(fract(worldPos.x/50),fract(worldPos.y/50),fract(worldPos.z/50), 1.0);
		return; // BAIL
	#endif
	} ]]):format(mx,mz, Game.mapSizeX, Game.mapSizeZ, gnd_min -100, gnd_max+1000)
	
	losShader = glCreateShader({
		fragment = losFragSrc,

		--while this vertex shader seems to do nothing, it actually does the very important world space to screen space mapping for gl.TexRect!
		vertex = [[

			void main(void)
			{
				gl_TexCoord[0] = gl_MultiTexCoord0;
				gl_Position    = gl_Vertex;
			}
		]],
		uniformInt = { infotex = 0,colortex = 1,modeldepthtex = 2, mapdepthtex = 3},
		uniformfloat = { gameframe=0}
	})

	if (losShader == nil) then
		Spring.Echo(glGetShaderLog())
		RemoveMe("[BloomShader::Initialize] losShader compilation failed"); print(glGetShaderLog()); return
	end

	combineShader = glCreateShader({
		fragment = [[
			uniform sampler2D texture0;
			uniform sampler2D texture1;
			uniform int debugDraw;

			void main(void) {
				vec4 a = texture2D(texture0, gl_TexCoord[0].st);
				vec4 b = texture2D(texture1, gl_TexCoord[0].st);

				if (!debugDraw) {
					gl_FragColor = a + b;
				} else {
					gl_FragColor = b;
				}
			}
		]],

		--while this vertex shader seems to do nothing, it actually does the very important world space to screen space mapping for gl.TexRect!
		vertex = [[

			void main(void)
			{
				gl_TexCoord[0] = gl_MultiTexCoord0;
				gl_Position    = gl_Vertex;
			}
		]],
		uniformInt = { texture0 = 0, texture1 = 1, debugDraw = 0}
	})

	if (combineShader == nil) then
		RemoveMe("[BloomShader::Initialize] combineShader compilation failed"); print(glGetShaderLog()); return
	end



	blurShaderH71 = glCreateShader({
		fragment = [[
			uniform sampler2D texture0;
			uniform float inverseRX;
			uniform float fragBlurAmplifier;
			const float invKernelSum = 0.01;

			void main(void) {
				vec2 texCoors = vec2(gl_TexCoord[0]);
				vec4 samples[9];

				samples[0] = texture2D(texture0, texCoors + vec2(-4 * inverseRX, 0));
				samples[1] = texture2D(texture0, texCoors + vec2(-3 * inverseRX, 0));
				samples[2] = texture2D(texture0, texCoors + vec2(-2 * inverseRX, 0));
				samples[3] = texture2D(texture0, texCoors + vec2(-1 * inverseRX, 0));
				samples[4] = texture2D(texture0, texCoors + vec2( 0            , 0));
				samples[5] = texture2D(texture0, texCoors + vec2( 1 * inverseRX, 0));
				samples[6] = texture2D(texture0, texCoors + vec2( 2 * inverseRX, 0));
				samples[7] = texture2D(texture0, texCoors + vec2( 3 * inverseRX, 0));
				samples[8] = texture2D(texture0, texCoors + vec2( 4 * inverseRX, 0));

				samples[4] = (3*samples[0] + 7*samples[1] + 15*samples[2] + 20*samples[3] + 25*samples[4] + 20*samples[5] + 15*samples[6] + 7*samples[7]+ 3*samples[8]);
				gl_FragColor = (samples[4] * invKernelSum) * fragBlurAmplifier;
			}
		]],

		uniformInt = {texture0 = 0},
		uniformFloat = {inverseRX, fragBlurAmplifier}
	})

	if (blurShaderH71 == nil) then
		RemoveMe("[BloomShader::Initialize] blurShaderH71 compilation failed"); print(glGetShaderLog()); return
	end

	blurShaderV71 = glCreateShader({
		fragment = [[
			uniform sampler2D texture0;
			uniform float inverseRY;
			uniform float fragBlurAmplifier;
			const float invKernelSum = 0.01;

			void main(void) {
				vec2 texCoors = vec2(gl_TexCoord[0]);
				vec4 samples[9];

				samples[0] = texture2D(texture0, texCoors + vec2(0, -4 * inverseRY));
				samples[1] = texture2D(texture0, texCoors + vec2(0, -3 * inverseRY));
				samples[2] = texture2D(texture0, texCoors + vec2(0, -2 * inverseRY));
				samples[3] = texture2D(texture0, texCoors + vec2(0, -1 * inverseRY));
				samples[4] = texture2D(texture0, texCoors + vec2(0,  0            ));
				samples[5] = texture2D(texture0, texCoors + vec2(0,  1 * inverseRY));
				samples[6] = texture2D(texture0, texCoors + vec2(0,  2 * inverseRY));
				samples[7] = texture2D(texture0, texCoors + vec2(0,  3 * inverseRY));
				samples[8] = texture2D(texture0, texCoors + vec2(0,  4 * inverseRY));

				samples[4] = (3*samples[0] + 7*samples[1] + 15*samples[2] + 20*samples[3] + 25*samples[4] + 20*samples[5] + 15*samples[6] + 7*samples[7]+ 3*samples[8]);
				gl_FragColor = (samples[4] * invKernelSum) * fragBlurAmplifier;
			}
		]],

		uniformInt = {texture0 = 0},
		uniformFloat = {inverseRY, fragBlurAmplifier}
	})

	if (blurShaderV71 == nil) then
		RemoveMe("[BloomShader::Initialize] blurShaderV71 compilation failed"); print(glGetShaderLog()); return
	end





	brightShader = glCreateShader({
		fragment = [[
			uniform sampler2D texture0;
			uniform float illuminationThreshold;
			uniform float fragGlowAmplifier;
			uniform float inverseRX;
			uniform float inverseRY;

			void main(void) {
				vec2 texCoors = vec2(gl_TexCoord[0]);
				vec3 color = vec3(texture2D(texture0, texCoors));
				float illum = dot(color, vec3(0.2990, 0.4870, 0.2140)); //adjusted from the real values of  vec3(0.2990, 0.5870, 0.1140)
				float minlight=min(color.r,min(color.g,color.b));

				if (illum > illuminationThreshold) {
					//gl_FragColor = vec4(mix(color,color-vec3(minlight,minlight,minlight),0.5), 1.0) * fragGlowAmplifier;
					gl_FragColor = vec4(color*(illum-illuminationThreshold), 1.0) * fragGlowAmplifier;
				} else {
					gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
				}
			}
		]],

		uniformInt = {texture0 = 0},
		uniformFloat = {illuminationThreshold, fragGlowAmplifier, inverseRX, inverseRY}
	})

	if (brightShader == nil) then
		RemoveMe("[BloomShader::Initialize] brightShader compilation failed"); print(glGetShaderLog()); return
	end



	brightShaderText0Loc = glGetUniformLocation(brightShader, "texture0")
	brightShaderInvRXLoc = glGetUniformLocation(brightShader, "inverseRX")
	brightShaderInvRYLoc = glGetUniformLocation(brightShader, "inverseRY")
	brightShaderIllumLoc = glGetUniformLocation(brightShader, "illuminationThreshold")
	brightShaderFragLoc = glGetUniformLocation(brightShader, "fragGlowAmplifier")

	blurShaderH71Text0Loc = glGetUniformLocation(blurShaderH71, "texture0")
	blurShaderH71InvRXLoc = glGetUniformLocation(blurShaderH71, "inverseRX")
	blurShaderH71FragLoc = glGetUniformLocation(blurShaderH71, "fragBlurAmplifier")
	blurShaderV71Text0Loc = glGetUniformLocation(blurShaderV71, "texture0")
	blurShaderV71InvRYLoc = glGetUniformLocation(blurShaderV71, "inverseRY")
	blurShaderV71FragLoc = glGetUniformLocation(blurShaderV71, "fragBlurAmplifier")

	combineShaderDebgDrawLoc = glGetUniformLocation(combineShader, "debugDraw")
	combineShaderTexture0Loc = glGetUniformLocation(combineShader, "texture0")
	combineShaderTexture1Loc = glGetUniformLocation(combineShader, "texture1")
	
	losShaderViewPrjInvLoc = glGetUniformLocation(losShader, "viewProjectionInv")
	losShaderInfoTexLoc =glGetUniformLocation(losShader, 'infotex')
	losShaderColorTexLoc =glGetUniformLocation(losShader, 'colortex')
	losShaderModelDepthTexLoc =glGetUniformLocation(losShader, 'modeldepthtex')
	losShaderMapDepthTexLoc =glGetUniformLocation(losShader, 'mapdepthtex')
	losShaderGameFrameLoc =glGetUniformLocation(losShader, 'gameframe')
	

end

function widget:Shutdown()
	Spring.SendCommands("unbind Any+l luaui los")
	Spring.SendCommands("bind Any+l togglelos")
	if (brightTexture1 ~= nil) then glDeleteTexture(brightTexture1) end
	if (brightTexture2 ~= nil) then glDeleteTexture(brightTexture2) end
	if (screenTexture ~= nil) then glDeleteTexture(screenTexture ) end
	if (losTexture ~= nil) then glDeleteTexture(losTexture) end
	

	if (glDeleteShader) then
		if (brightShader ~= nil) then glDeleteShader(brightShader) end
		if (blurShaderH71 ~= nil) then glDeleteShader(blurShaderH71) end
		if (blurShaderV71 ~= nil) then glDeleteShader(blurShaderV71) end
		if (combineShader ~= nil) then glDeleteShader(combineShader) end
		if (losShader ~= nil) then glDeleteShader(losShader) end
	end
end






local function mglDrawTexture(texUnit, tex, w, h, flipS, flipT)
	glTexture(texUnit, tex)
	glTexRect(0, 0, w, h, flipS, flipT)
	glTexture(texUnit, false)
end

local function mglDrawFBOTexture(tex)
	glTexture(tex)
	glTexRect(-1, -1, 1, 1)
	glTexture(false)
end


local function activeTextureFunc(texUnit, tex, w, h, flipS, flipT)
	glTexture(texUnit, tex)
	glTexRect(0, 0, w, h, flipS, flipT)
	glTexture(texUnit, false)
end

local function mglActiveTexture(texUnit, tex, w, h, flipS, flipT)
	glActiveTexture(texUnit, activeTextureFunc, texUnit, tex, w, h, flipS, flipT)
end


-- local function renderToTextureFunc(tex, s, t)
	-- glTexture(tex)
	-- glTexRect(-1 * s, -1 * t,1 * s, 1 * t) --the viewport coords are (-1,-1) to (1,1), and boy are they not linear!
	-- glTexture(false)
-- end

-- local function mglRenderToTexture(FBOTex, tex, s, t)  --target, source, coords
	-- glRenderToTexture(FBOTex, renderToTextureFunc, tex, s, t)
-- end

local function Sampleminimap()
		--get 100 points on minimap
		glTexture("$minimap")

		local r=0
		local g=0
		local b=0
		local a=0
		local cnt =0
		for x=1, 9 do
			
			for y= 1, 9 do
				local pr,pg,pb,pa = glReadPixels(50+10*x,50+10*y,1,1)
				r=r+pr/81
				g=g+pg/81
				b=b+pb/81
				a=a+pa/81
				cnt=cnt+1
			end
		end
		glTexture(false)
		minimapbrightness=r*0.3+g*0.5+b*0.2
		Spring.Echo("Bloom shader minimap brightness values:",cnt,r,g,b,a)
		return minimapbrightness
end




local function Bloom(losUsed)
	if minimapbrightness == nil then
		minimapbrightness=Sampleminimap()
	end
	-- bloomin=bloomin+1
	-- if (bloomin%100==0) then
		-- Spring.Echo('Blooming!!!',bloomin)
	-- end
	gl.Color(1, 1, 1, 1)
	local k=1
	local l=-1
	-- glCopyToTexture(screenTexture, 0, 0, 0, 0, vsx, vsy, nil,0)
 
	glUseShader(brightShader)
		glUniformInt(brightShaderText0Loc, 0)
		glUniform(   brightShaderInvRXLoc, ivsx)
		glUniform(   brightShaderInvRYLoc, ivsy)
		glUniform(   brightShaderIllumLoc, illumThreshold)
		glUniform(   brightShaderFragLoc, glowAmplifier)
		--mglRenderToTexture(brightTexture1, screenTexture, k,l)
		if losUsed then 
			glTexture(losTexture)
		else
			glTexture(screenTexture)
		end
		glRenderToTexture(brightTexture1, gl.TexRect, -1,1,1,-1)
		glTexture(false)
	glUseShader(0)



	for i = 1, blurPasses do
		glUseShader(blurShaderH71)
			glUniformInt(blurShaderH71Text0Loc, 0)
			glUniform(   blurShaderH71InvRXLoc, ivsx)
			glUniform(   blurShaderH71FragLoc, blurAmplifier)
			--mglRenderToTexture(brightTexture2, brightTexture1,k,l)
			glTexture(brightTexture1)
			glRenderToTexture(brightTexture2, gl.TexRect, -1,1,1,-1)
			glTexture(false)
		glUseShader(0)
		glUseShader(blurShaderV71)
			glUniformInt(blurShaderV71Text0Loc, 0)
			glUniform(   blurShaderV71InvRYLoc, ivsy)
			glUniform(   blurShaderV71FragLoc, blurAmplifier)
			-- mglRenderToTexture(brightTexture1, brightTexture2,k,l)
			glTexture(brightTexture2)
			glRenderToTexture(brightTexture1, gl.TexRect, -1,1,1,-1)
			glTexture(false)
		glUseShader(0)
	end



	glUseShader(combineShader)
		glUniformInt(combineShaderDebgDrawLoc, dbgDraw)
		glUniformInt(combineShaderTexture0Loc, 0)
		glUniformInt(combineShaderTexture1Loc, 1)
		--mglActiveTexture(0, screenTexture, vsx, vsy, false, true)
		glTexture(0, screenTexture)
		--glTexRect(0, 0, vsx, vsy, false, true)
		
			gl.TexRect(-1, -1, 1, 1, 0, 0, 1, 1)
		glTexture(0, false)
		--mglActiveTexture(1, brightTexture1, vsx, vsy, false, true)
		glTexture(1, brightTexture1)
		--glTexRect(0, 0, vsx, vsy, false, true)
		
			gl.TexRect(-1, -1, 1, 1, 0, 0, 1, 1)
		glTexture(1, false)
	glUseShader(0)
	--gl.Finish()
end



local spGetGameFrame = Spring.GetGameFrame

local function DrawLOS()
	gl.Color(1,1,1,1)
	glCopyToTexture(screenTexture, 0, 0, 0, 0, vsx, vsy, nil,0)
	
	-- setup the shader and its uniform values
	glUseShader(losShader)

	glUniformMatrix(losShaderViewPrjInvLoc,  "viewprojectioninverse")
	glUniform(losShaderGameFrameLoc,  (math.max((spGetGameFrame()-150),0))/150.0)


	-- render a full screen quad
	glTexture(0, "$info_losmap")
	--glTexture(0, false)
	glTexture(1 , screenTexture)
	glTexture(2 , "$model_gbuffer_zvaltex")
	glTexture(3 , "$map_gbuffer_zvaltex")
	
	--glRenderToTexture(losTexture, gl.TexRect, -1,1,1,-1)
	
	--glTexRect(-1, -1, 1000, 1000)
	glTexRect(-1, -1, 1, 1, 0, 0, 1, 1)
	glTexture(0,false)
	glTexture(1,false)
	glTexture(2,false)
	glTexture(3,false)
	--Spring.Echo('shaded')
	glUseShader(0)

end


--function widget:DrawScreenEffects() Bloom() end --drawworld draws in world space, would need a diff draw matrix...
--function widget:DrawWorld() 

local useLOS = true
local status =false
local spGetGameFrame = Spring.GetGameFrame
local spUpdateInfoTexture = Spring.UpdateInfoTexture
local spGetMapDrawMode = Spring.GetMapDrawMode
local lastupdate=0
local GetSpectatingState = Spring.GetSpectatingState


function widget:DrawWorld()
	--Spring.Echo('gfx_bloom_los_shader, DrawWorld')
	if useLOS then 
		if status==false then  -- losshader just got turned on
		status=true
		Spring.Echo('Turning on LOS mode')
		Spring.SetLosViewColors (	{0,255.0/256.0,0,0}, --R number always, number LOS, number radar, number jam 
									{0,0,1,0}, --G number always, number LOS, number radar, number jam 
									{0,0,0,1}) --B number always, number LOS, number radar, number jam 
		else --we were already on
		end
	else 
		status=false
	end
	local spectating,fullView,fullSelect = GetSpectatingState()
	if spectating and fullView then return end
	
	if status and spGetMapDrawMode() and spGetMapDrawMode()=="normal" then
		gf=spGetGameFrame()
		if gf>lastupdate then
			lastupdate=gf
		--if gf%13==0 then
			spUpdateInfoTexture(1) --update info tex, normally a 1% load with extratextureupdaterate set to 45, now its an unknown amount of load :(
		end
		DrawLOS()
	end
	
	--Bloom(status)
end --drawworld draws in world space, would need a diff draw matrix...

function widget:TextCommand(command)
	local mycommand=false
	if (string.find(command, "+illumthres") == 1) then illumThreshold = illumThreshold + 0.02 ; mycommand=true end
	if (string.find(command, "-illumthres") == 1) then illumThreshold = illumThreshold - 0.02 ; mycommand=true end

	if (string.find(command, "+glowamplif") == 1) then glowAmplifier = glowAmplifier + 0.05 ; mycommand=true end
	if (string.find(command, "-glowamplif") == 1) then glowAmplifier = glowAmplifier - 0.05 ; mycommand=true end

	if (string.find(command, "+bluramplif") == 1) then blurAmplifier = blurAmplifier + 0.05 ; mycommand=true end
	if (string.find(command, "-bluramplif") == 1) then blurAmplifier = blurAmplifier - 0.05 ; mycommand=true end

	if (string.find(command, "+blurpasses") == 1) then blurPasses = blurPasses + 1; mycommand=true  end
	if (string.find(command, "-blurpasses") == 1) then blurPasses = blurPasses - 1 ; mycommand=true end


	if (string.find(command, "+bloomdebug") == 1) then dbgDraw = 1; mycommand=true  end
	if (string.find(command, "-bloomdebug") == 1) then dbgDraw = 0 ; mycommand=true end
	
	
	if (string.find(command, "los") == 1) then
		useLOS= (not useLOS) 
		Spring.Echo('los shader toggled to ',useLOS)
	end

	illumThreshold = math.max(0.0, math.min(1.0, illumThreshold))
	blurPasses = math.max(0, blurPasses)
	if (mycommand) then 
		Spring.Echo("[BloomShader::TextCommand]")
		Spring.Echo("   illumThreshold: " .. illumThreshold)
		Spring.Echo("   glowAmplifier:  " .. glowAmplifier)
		Spring.Echo("   blurAmplifier:  " .. blurAmplifier)
		Spring.Echo("   blurPasses:     " .. blurPasses)
		return true
	else
		return false
	end
end

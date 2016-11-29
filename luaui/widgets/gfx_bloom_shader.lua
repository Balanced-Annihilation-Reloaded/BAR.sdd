function widget:GetInfo()
	return {
		name      = "Bloom Shader", --(v0.5)
		desc      = "Light Bloom Shader, simulates overbrightness",
		author    = "Kloot, Beherith",
		date      = "2016-03-31",
		license   = "GPL V2",
		layer     = 100000000000,
		enabled   = true,
	}
end


-- config params
local dbgDraw = 0                    -- draw only the bloom-mask? [0 | 1]
local glowAmplifier = 1.0            -- intensity multiplier when filtering a glow source fragment [1, n]
local blurAmplifier = 1.0        -- intensity multiplier when applying a blur pass [1, n] (should be set close to 1)
local illumThreshold = 0.8            -- how bright does a fragment need to be before being considered a glow source? [0, 1]
local blurPasses = 1                -- how many iterations of (7x7) Gaussian blur should be applied to the glow sources?

-- non-editables
local vsx = 1                        -- current viewport width
local vsy = 1                        -- current viewport height
local ivsx = 1.0 / vsx
local ivsy = 1.0 / vsy

--quality =2 : 113 fps, 57% memctrler load, 99% shader load
--quality =1 : 90 fps, 9% memctrler load, 99% shader load
--quality =4 : 123 fps, 9% memctrler load, 99% shader load
local quality  = 2
local debugBrightShader = false


-- shader and texture handles
local blurShaderH71 = nil
local blurShaderV71 = nil

local brightShader = nil
local brightTexture1 = nil
local brightTexture2 = nil

local combineShader = nil

-- speedups
local glGetSun = gl.GetSun

local glCreateTexture = gl.CreateTexture
local glDeleteTexture = gl.DeleteTexture
local glActiveTexture = gl.ActiveTexture
local glCopyToTexture = gl.CopyToTexture
local glRenderToTexture = gl.RenderToTexture
local glTexture = gl.Texture
local glTexRect = gl.TexRect

local glGetShaderLog = gl.GetShaderLog
local glCreateShader = gl.CreateShader
local glDeleteShader = gl.DeleteShader
local glUseShader = gl.UseShader

local glUniformInt = gl.UniformInt
local glUniform = gl.Uniform
local glGetUniformLocation = gl.GetUniformLocation
local glGetActiveUniforms = gl.GetActiveUniforms


-- shader uniform locations
local brightShaderText0Loc = nil
local brightShaderText1Loc = nil
local brightShaderIllumLoc = nil
local brightShaderFragLoc = nil


local blurShaderH71Text0Loc = nil
local blurShaderH71FragLoc = nil
local blurShaderV71Text0Loc = nil
local blurShaderV71FragLoc = nil

local combineShaderDebgDrawLoc = nil
local combineShaderTexture0Loc = nil
local combineShaderTexture1Loc = nil


local hasdeferredmodelrendering = nil

local function SetIllumThreshold()
	local ra, ga, ba = glGetSun("ambient", "unit")
	local rd, gd, bd = glGetSun("diffuse","unit")
	local rs, gs, bs = glGetSun("specular")

	local ambientIntensity  = ra * 0.299 + ga * 0.587 + ba * 0.114
	local diffuseIntensity  = rd * 0.299 + gd * 0.587 + bd * 0.114
	local specularIntensity = rs * 0.299 + gs * 0.587 + bs * 0.114

	illumThreshold = illumThreshold*(0.8 * ambientIntensity) + (0.5 * diffuseIntensity) -- + (0.1 * specularIntensity)
	illumThreshold = math.min(illumThreshold, 0.9)
	print("[BloomShader::SetIllumThreshold] sun ambient color:  ", ra .. ", " .. ga .. ", " .. ba .. " (intensity: " .. ambientIntensity .. ")")
	print("[BloomShader::SetIllumThreshold] sun diffuse color:  ", rd .. ", " .. gd .. ", " .. bd .. " (intensity: " .. diffuseIntensity .. ")")
	print("[BloomShader::SetIllumThreshold] sun specular color: ", rs .. ", " .. gs .. ", " .. bs .. " (intensity: " .. specularIntensity .. ")")
	print("[BloomShader::SetIllumThreshold] illumination threshold: " .. illumThreshold)
	Spring.Echo("[BloomShader::SetIllumThreshold] illumination threshold: " .. illumThreshold)
end

local function RemoveMe(msg)
	Spring.Echo(msg)
	widgetHandler:RemoveWidget() -- TODO: fixme, not passing self makes WH error
end

local function MakeBloomShaders() 

	if (glDeleteShader) then
		if brightShader ~= nil then glDeleteShader(brightShader or 0) end
		if blurShaderH71 ~= nil then glDeleteShader(blurShaderH71 or 0) end
		if blurShaderV71 ~= nil then glDeleteShader(blurShaderV71 or 0) end
		if combineShader ~= nil then glDeleteShader(combineShader or 0) end
	end
	
	combineShader = glCreateShader({
		fragment = [[
			uniform sampler2D texture0;
			uniform int debugDraw;

			void main(void) {
				vec4 a = texture2D(texture0, gl_TexCoord[0].st);

				if (!debugDraw) {
					gl_FragColor = a;
				} else {
					a.a= 1.0;
					gl_FragColor = a;
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
		uniformInt = { texture0 = 0, debugDraw = 0}
	})

	if (combineShader == nil) then
		RemoveMe("[BloomShader::Initialize] combineShader compilation failed"); print(glGetShaderLog()); return
	end

	-- How about we do linear sampling instead, using the GPU's built in texture fetching linear blur hardware :)
	-- http://rastergrid.com/blog/2010/09/efficient-gaussian-blur-with-linear-sampling/ 
	-- this allows us to get away with 5 texture fetches instead of 9 for our 9 sized kernel!
	 -- TODO:  all this simplification may result in the accumulation of quantizing errors due to the small numbers that get pushed into the BrightTexture

	blurShaderH71 = glCreateShader({
		fragment = "#define inverseRX " .. tostring(ivsx) .. "\n" .. [[
			uniform sampler2D texture0;
			uniform float fragBlurAmplifier;
			const float invKernelSum = 0.0084; // (1/119)

			void main(void) {
				vec2 texCoors = vec2(gl_TexCoord[0]);
				vec3 newblur;
				
				newblur  = 10*  texture2D(texture0, texCoors + vec2(-3.3 * inverseRX, 0)).rgb;
				newblur += 37*  texture2D(texture0, texCoors + vec2(-1.4 * inverseRX, 0)).rgb;
				newblur += 25*  texture2D(texture0, texCoors + vec2(0               , 0)).rgb;
				newblur += 37*  texture2D(texture0, texCoors + vec2( 1.4 * inverseRX, 0)).rgb;
				newblur += 10*  texture2D(texture0, texCoors + vec2( 3.3 * inverseRX, 0)).rgb;
				gl_FragColor = vec4(newblur * invKernelSum * fragBlurAmplifier, 1.0);
			}
		]],
		uniformInt = {texture0 = 0},
		uniformFloat = {inverseRX, fragBlurAmplifier}
	})

	if (blurShaderH71 == nil) then
		RemoveMe("[BloomShader::Initialize] blurShaderH71 compilation failed"); Spring.Echo(glGetShaderLog()); return
	end

	blurShaderV71 = glCreateShader({
		fragment = "#define inverseRY " .. tostring(ivsy) .. "\n" .. [[
			uniform sampler2D texture0;
			uniform float fragBlurAmplifier;
			const float invKernelSum = 0.0084; // (1/119)

			void main(void) {
				vec2 texCoors = vec2(gl_TexCoord[0]);
				vec3 newblur;
				
				newblur  = 10*  texture2D(texture0, texCoors + vec2(0, -3.3 * inverseRY)).rgb;
				newblur += 37*  texture2D(texture0, texCoors + vec2(0, -1.4 * inverseRY)).rgb;
				newblur += 25*  texture2D(texture0, texCoors + vec2(0,                0)).rgb;
				newblur += 37*  texture2D(texture0, texCoors + vec2(0,  1.4 * inverseRY)).rgb;
				newblur += 10*  texture2D(texture0, texCoors + vec2(0,  3.3 * inverseRY)).rgb;
				gl_FragColor = vec4(newblur * invKernelSum * fragBlurAmplifier, 1.0);
			}
		]],

		uniformInt = {texture0 = 0},
		uniformFloat = {inverseRY, fragBlurAmplifier}
	})

	if (blurShaderV71 == nil) then
		RemoveMe("[BloomShader::Initialize] blurShaderV71 compilation failed"); Spring.Echo(glGetShaderLog()); return
	end

	brightShader = glCreateShader({
		fragment =   [[
			uniform sampler2D modeldiffusetex;
			uniform sampler2D modelspectex;
			uniform float illuminationThreshold;
			uniform float fragGlowAmplifier;

			void main(void) {
				vec2 texCoors = vec2(gl_TexCoord[0]);
				vec3 color = vec3(texture2D(modeldiffusetex, texCoors));
				vec4 model_gbuffer_emittex = texture2D(modelspectex,texCoors);
				float detectchangedbuffer = clamp(model_gbuffer_emittex.g,0.0,1.0); //this is required because some things overwrite all the buffers, and deferred rendering forces this to 0.0 
				color = color *(1.0 - detectchangedbuffer);
				color += color*model_gbuffer_emittex.r;
				
				float illum = dot(color, vec3(0.2990, 0.4870, 0.2140)); //adjusted from the real values of  vec3(0.2990, 0.5870, 0.1140)
				
				if (illum > illuminationThreshold) {
					gl_FragColor = vec4(color*(illum-illuminationThreshold), 1.0) * fragGlowAmplifier;
				} else {
					gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
				}
			}
		]], 

		uniformInt = {modeldiffusetex = 0, modelspectex = 1},
		uniformFloat = {illuminationThreshold, fragGlowAmplifier} --, inverseRX, inverseRY}
	})

	if (brightShader == nil) then
		RemoveMe("[BloomShader::Initialize] brightShader compilation failed"); print(glGetShaderLog()); return
	end



	brightShaderText0Loc = glGetUniformLocation(brightShader, "modeldiffusetex")
	brightShaderText1Loc = glGetUniformLocation(brightShader, "modelspectex")

	brightShaderIllumLoc = glGetUniformLocation(brightShader, "illuminationThreshold")
	brightShaderFragLoc = glGetUniformLocation(brightShader, "fragGlowAmplifier")

	blurShaderH71Text0Loc = glGetUniformLocation(blurShaderH71, "texture0")
	blurShaderH71FragLoc = glGetUniformLocation(blurShaderH71, "fragBlurAmplifier")
	blurShaderV71Text0Loc = glGetUniformLocation(blurShaderV71, "texture0")
	blurShaderV71FragLoc = glGetUniformLocation(blurShaderV71, "fragBlurAmplifier")

	combineShaderDebgDrawLoc = glGetUniformLocation(combineShader, "debugDraw")
	combineShaderTexture0Loc = glGetUniformLocation(combineShader, "texture0")
	-- combineShaderTexture1Loc = glGetUniformLocation(combineShader, "texture1")

end


function widget:ViewResize(viewSizeX, viewSizeY)
	vsx = viewSizeX; ivsx = 1.0 / vsx --we can do /n here!
	vsy = viewSizeY; ivsy = 1.0 / vsy
	qvsx,qvsy = math.floor(vsx/quality), math.floor(vsy/quality)
	glDeleteTexture(brightTexture1 or "")
	glDeleteTexture(brightTexture2 or "")

	brightTexture1 = glCreateTexture(qvsx, qvsy, {
		fbo = true, 
		min_filter = GL.LINEAR, mag_filter = GL.LINEAR,
		wrap_s = GL.CLAMP, wrap_t = GL.CLAMP,
	})
	brightTexture2 = glCreateTexture(qvsx, qvsy, {
		fbo = true, min_filter = GL.LINEAR, mag_filter = GL.LINEAR,
		wrap_s = GL.CLAMP, wrap_t = GL.CLAMP,
	})

	if (brightTexture1 == nil or brightTexture2 == nil) then
		if (brightTexture1 == nil ) then Spring.Echo('brightTexture1 == nil ') end
		if (brightTexture2 == nil ) then Spring.Echo('brightTexture2 == nil ') end
		RemoveMe("[BloomShader::ViewResize] removing widget, bad texture target")
		return
	end
	MakeBloomShaders() --we are gonna reinit the the widget, in order to recompile the shaders with the static IVSX and IVSY values in the blur shaders
end

widget:ViewResize(widgetHandler:GetViewSizes())

SetIllumThreshold()


function widget:Initialize()
 
	if (glCreateShader == nil) then
		RemoveMe("[BloomShader::Initialize] removing widget, no shader support")
		return
	end

	hasdeferredmodelrendering = (Spring.GetConfigString("AllowDeferredModelRendering")=='1')
	if hasdeferredmodelrendering == false then
		RemoveMe("[BloomShader::Initialize] removing widget, AllowDeferredModelRendering is required")
	end
	AddChatActions()
	MakeBloomShaders()

end

function widget:Shutdown()
	RemoveChatActions()

	glDeleteTexture(brightTexture1 or "")

	if (glDeleteShader) then
		if brightShader ~= nil then glDeleteShader(brightShader or 0) end
		if blurShaderH71 ~= nil then glDeleteShader(blurShaderH71 or 0) end
		if blurShaderV71 ~= nil then glDeleteShader(blurShaderV71 or 0) end
		if combineShader ~= nil then glDeleteShader(combineShader or 0) end
	end
end

local function AutoThreshold( )

end 


local function Bloom()
	gl.DepthMask(false)
	gl.Color(1, 1, 1, 1)
 
	glUseShader(brightShader)
		glUniformInt(brightShaderText0Loc, 0)
		glUniformInt(brightShaderText1Loc, 1) 
		glUniform(   brightShaderIllumLoc, illumThreshold)
		glUniform(   brightShaderFragLoc, glowAmplifier)
		glTexture(0, "$model_gbuffer_difftex")
		glTexture(1,"$model_gbuffer_emittex") 
		glRenderToTexture(brightTexture1, gl.TexRect, -1,1,1,-1)
		glTexture(0, false)
		glTexture(1, false)
	glUseShader(0)

	if not debugBrightShader then 
		for i = 1, blurPasses do
			glUseShader(blurShaderH71)
				glUniformInt(blurShaderH71Text0Loc, 0)
				glUniform(blurShaderH71FragLoc, blurAmplifier)
				glTexture(brightTexture1)
				glRenderToTexture(brightTexture2, gl.TexRect, -1,1,1,-1)
				glTexture(false)
			glUseShader(0)
			
			glUseShader(blurShaderV71)
				glUniformInt(blurShaderV71Text0Loc, 0)
				glUniform(blurShaderV71FragLoc, blurAmplifier)
				glTexture(brightTexture2)
				glRenderToTexture(brightTexture1, gl.TexRect, -1,1,1,-1)
				glTexture(false)
			glUseShader(0)
		end
	end

	if dbgDraw == 0 then
		gl.Blending("alpha_add")
	else
		gl.Blending(GL.ONE, GL.ZERO)
	end
	glUseShader(combineShader)
	glUniformInt(combineShaderDebgDrawLoc, dbgDraw)
	glUniformInt(combineShaderTexture0Loc, 0)
	glTexture(0, brightTexture1)
	gl.TexRect(-1, -1, 1, 1, 0, 0, 1, 1)
	glTexture(0, false)
	glUseShader(0)
	gl.Blending("reset")
	gl.DepthMask(true)
end

function widget:DrawWorld() Bloom() end 

function AddChatActions()
	local function EchoVars()
		illumThreshold = math.max(0.0, math.min(1.0, illumThreshold))
		blurPasses = math.max(0, blurPasses)
		Spring.Echo("[BloomShader::TextCommand]")
		Spring.Echo("   illumThreshold: " .. illumThreshold)
		Spring.Echo("   glowAmplifier:  " .. glowAmplifier)
		Spring.Echo("   blurAmplifier:  " .. blurAmplifier)
		Spring.Echo("   blurPasses:     " .. blurPasses)
	end

	local function MoreIllum() illumThreshold = illumThreshold + 0.02 ; EchoVars() end
	local function LessIllum() illumThreshold = illumThreshold - 0.02 ; EchoVars() end

	local function MoreGlow() glowAmplifier = glowAmplifier + 0.05 ; EchoVars() end
	local function LessGlow() glowAmplifier = glowAmplifier - 0.05 ; EchoVars() end

	local function MoreBlur() blurAmplifier = blurAmplifier + 0.05 ; EchoVars() end
	local function LessBlur() blurAmplifier = blurAmplifier - 0.05 ; EchoVars() end

	local function MoreBlurPasses() blurPasses = blurPasses + 1; EchoVars() end
	local function LessBlurPasses() blurPasses = blurPasses - 1; EchoVars() end

	local function BloomDebugOn() dbgDraw = 1; EchoVars() end
	local function BloomDebugOff() dbgDraw = 0; EchoVars() end

	
	widgetHandler:AddAction("+illumthres", MoreIllum, nil, 't')
	widgetHandler:AddAction("-illumthres", LessIllum, nil, 't')

	widgetHandler:AddAction("+glowamplif", MoreGlow, nil, 't')
	widgetHandler:AddAction("-glowamplif", LessGlow, nil, 't')

	widgetHandler:AddAction("+bluramplif", MoreBlur, nil, 't')
	widgetHandler:AddAction("-bluramplif", LessBlur, nil, 't')

	widgetHandler:AddAction("+blurpasses", MoreBlurPasses, nil, 't')
	widgetHandler:AddAction("-blurpasses", LessBlurPasses, nil, 't')

	widgetHandler:AddAction("+bloomdebug", BloomDebugOn, nil, 't')
	widgetHandler:AddAction("-bloomdebug", BloomDebugOff, nil, 't')
end

function RemoveChatActions()
	widgetHandler:RemoveAction("+illumthres", MoreIllum, nil, 't')
	widgetHandler:RemoveAction("-illumthres", LessIllum, nil, 't')

	widgetHandler:RemoveAction("+glowamplif", MoreGlow, nil, 't')
	widgetHandler:RemoveAction("-glowamplif", LessGlow, nil, 't')

	widgetHandler:RemoveAction("+bluramplif", MoreBlur, nil, 't')
	widgetHandler:RemoveAction("-bluramplif", LessBlur, nil, 't')

	widgetHandler:RemoveAction("+blurpasses", MoreBlurPasses, nil, 't')
	widgetHandler:RemoveAction("-blurpasses", LessBlurPasses, nil, 't')

	widgetHandler:RemoveAction("+bloomdebug", BloomDebugOn, nil, 't')
	widgetHandler:RemoveAction("-bloomdebug", BloomDebugOff, nil, 't')
end

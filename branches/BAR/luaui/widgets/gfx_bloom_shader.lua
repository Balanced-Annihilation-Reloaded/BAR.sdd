function widget:GetInfo()
    return {
        name      = "Bloom Shader", --(v0.5)
        desc      = "Light Bloom Shader, simulates overbrightness",
        author    = "Kloot, Beherith",
        date      = "2016-03-22",
        license   = "GPL V2",
        layer     = -10000,
        enabled   = false,
    }
end

--INFO: 
--with default params, FPS halves, and memory controller load doubles. That is 2 blur passes and 1 dilate pass.

-- default perf (1766): 116 fps, 4.5% cpu
-- new perf (1766+) with different order.

-- config params
local dbgDraw = 0                    -- draw only the bloom-mask? [0 | 1]
local glowAmplifier = 1.0            -- intensity multiplier when filtering a glow source fragment [1, n]
local blurAmplifier = 1.0        -- intensity multiplier when applying a blur pass [1, n] (should be set close to 1)
local illumThreshold = 0.8            -- how bright does a fragment need to be before being considered a glow source? [0, 1]
local blurPasses = 3                -- how many iterations of (7x7) Gaussian blur should be applied to the glow sources?

-- non-editables
local vsx = 1                        -- current viewport width
local vsy = 1                        -- current viewport height
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
local screenTexture = nil

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

local bloomin=0
local minimapbrightness=nil

local hasdeferredmodelrendering = nil

local function SetIllumThreshold()
    local ra, ga, ba = glGetSun("ambient")
    local rd, gd, bd = glGetSun("diffuse")
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
    widgetHandler:RemoveWidget()
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
            uniform sampler2D texture1;
            uniform int debugDraw;

            void main(void) {
                vec4 a = texture2D(texture0, gl_TexCoord[0].st);
                vec4 b = texture2D(texture1, gl_TexCoord[0].st);

                if (!debugDraw) {
                    gl_FragColor = mix(a, a + b, clamp(2.0-(a.r+a.g+a.b),0.0,1.0) ); //todo: redo this blending function, to avoid a bit of overbrightness
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



	brightShaderFragment = [[
            uniform sampler2D texture0;
			#ifdef deferredmodel
				uniform sampler2D modelspectex;
			#endif
            uniform float illuminationThreshold;
            uniform float fragGlowAmplifier;

            void main(void) {
                vec2 texCoors = vec2(gl_TexCoord[0]);
                vec3 color = vec3(texture2D(texture0, texCoors));
				#ifdef deferredmodel
					color += vec3(texture2D(modelspectex,texCoors));
				#endif
                float illum = dot(color, vec3(0.2990, 0.4870, 0.2140)); //adjusted from the real values of  vec3(0.2990, 0.5870, 0.1140)
				
                if (illum > illuminationThreshold) {
                    gl_FragColor = vec4(color*(illum-illuminationThreshold), 1.0) * fragGlowAmplifier;
                } else {
                    gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
                }
            }
        ]]

	if hasdeferredmodelrendering then
		brightShaderFragment = '#define deferredmodel\n'..brightShaderFragment
	end
    brightShader = glCreateShader({
        fragment =  brightShaderFragment,

        uniformInt = {texture0 = 0, modelspectex = 1},
        uniformFloat = {illuminationThreshold, fragGlowAmplifier} --, inverseRX, inverseRY}
    })

    if (brightShader == nil) then
        RemoveMe("[BloomShader::Initialize] brightShader compilation failed"); print(glGetShaderLog()); return
    end



    brightShaderText0Loc = glGetUniformLocation(brightShader, "texture0")
    if hasdeferredmodelrendering then
		brightShaderText1Loc = glGetUniformLocation(brightShader, "modelspectex")
	end
    brightShaderIllumLoc = glGetUniformLocation(brightShader, "illuminationThreshold")
    brightShaderFragLoc = glGetUniformLocation(brightShader, "fragGlowAmplifier")

    blurShaderH71Text0Loc = glGetUniformLocation(blurShaderH71, "texture0")
    blurShaderH71FragLoc = glGetUniformLocation(blurShaderH71, "fragBlurAmplifier")
    blurShaderV71Text0Loc = glGetUniformLocation(blurShaderV71, "texture0")
    blurShaderV71FragLoc = glGetUniformLocation(blurShaderV71, "fragBlurAmplifier")

    combineShaderDebgDrawLoc = glGetUniformLocation(combineShader, "debugDraw")
    combineShaderTexture0Loc = glGetUniformLocation(combineShader, "texture0")
    combineShaderTexture1Loc = glGetUniformLocation(combineShader, "texture1")

end


function widget:ViewResize(viewSizeX, viewSizeY)
    vsx = viewSizeX; ivsx = 1.0 / vsx --we can do /n here!
    vsy = viewSizeY; ivsy = 1.0 / vsy
      qvsx,qvsy = math.floor(vsx/quality), math.floor(vsy/quality)
    glDeleteTexture(brightTexture1 or "")
    glDeleteTexture(brightTexture2 or "")
    glDeleteTexture(screenTexture or "")

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
        min_filter = GL.LINEAR, mag_filter = GL.LINEAR, --because we are gonna cheat a bit and use linear sampling gaussian blur
    })

    if (brightTexture1 == nil or brightTexture2 == nil or screenTexture == nil) then
        if (brightTexture1 == nil ) then Spring.Echo('brightTexture1 == nil ') end
        if (brightTexture2 == nil ) then Spring.Echo('brightTexture2 == nil ') end
        if (screenTexture == nil ) then Spring.Echo('screenTexture == nil ') end
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

	hasdeferredmodelrendering = Spring.GetConfigString("AllowDeferredModelRendering")=='1')
    AddChatActions()
	MakeBloomShaders()

end

function widget:Shutdown()
    RemoveChatActions()

    glDeleteTexture(brightTexture1 or "")
    glDeleteTexture(brightTexture2 or "")
    glDeleteTexture(screenTexture or "")

    if (glDeleteShader) then
        if brightShader ~= nil then glDeleteShader(brightShader or 0) end
        if blurShaderH71 ~= nil then glDeleteShader(blurShaderH71 or 0) end
        if blurShaderV71 ~= nil then glDeleteShader(blurShaderV71 or 0) end
        if combineShader ~= nil then glDeleteShader(combineShader or 0) end
    end
end

local function Bloom()
    if minimapbrightness == nil then
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
        
    end
    -- bloomin=bloomin+1
    -- if (bloomin%100==0) then
        -- Spring.Echo('Blooming!!!',bloomin)
    -- end
    gl.Color(1, 1, 1, 1)

    glCopyToTexture(screenTexture, 0, 0, 0, 0, vsx, vsy, nil,0)
 
    glUseShader(brightShader)
        glUniformInt(brightShaderText0Loc, 0)
		if hasdeferredmodelrendering then  glUniformInt(brightShaderText1Loc, 1) end
        glUniform(   brightShaderIllumLoc, illumThreshold)
        glUniform(   brightShaderFragLoc, glowAmplifier)
		
        glTexture(0,screenTexture)
		if hasdeferredmodelrendering then glTexture(1,"$model_gbuffer_spectex") end
        glRenderToTexture(brightTexture1, gl.TexRect, -1,1,1,-1)
        glTexture(0, false)
        if hasdeferredmodelrendering then glTexture(0, false) end
    glUseShader(0)



    for i = 1, blurPasses do
        glUseShader(blurShaderH71)
            glUniformInt(blurShaderH71Text0Loc, 0)
            glUniform(   blurShaderH71FragLoc, blurAmplifier)
			
            glTexture(brightTexture1)
            glRenderToTexture(brightTexture2, gl.TexRect, -1,1,1,-1)
            glTexture(false)
        glUseShader(0)
        glUseShader(blurShaderV71)
            glUniformInt(blurShaderV71Text0Loc, 0)
            glUniform(   blurShaderV71FragLoc, blurAmplifier)
			
            glTexture(brightTexture2)
            glRenderToTexture(brightTexture1, gl.TexRect, -1,1,1,-1)
            glTexture(false)
        glUseShader(0)
    end



    glUseShader(combineShader)
        glUniformInt(combineShaderDebgDrawLoc, dbgDraw)
        glUniformInt(combineShaderTexture0Loc, 0)
        glUniformInt(combineShaderTexture1Loc, 1)
		
        glTexture(0, screenTexture)
        gl.TexRect(-1, -1, 1, 1, 0, 0, 1, 1)
		
        glTexture(0, false)
        glTexture(1, brightTexture1)
        
        gl.TexRect(-1, -1, 1, 1, 0, 0, 1, 1)
        glTexture(1, false)
    glUseShader(0)
    --gl.Finish()
end


--function widget:DrawScreenEffects() Bloom() end --drawworld draws in world space, would need a diff draw matrix...
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

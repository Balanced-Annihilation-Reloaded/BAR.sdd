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
local illumThreshold = 1.3            -- how bright does a fragment need to be before being considered a glow source? [0, 1]
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

local bloomin=0
local minimapbrightness=nil

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
        min_filter = GL.LINEAR, mag_filter = GL.NEAREST,
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

local function MakeBloomShaders() 

	if (glDeleteShader) then
        glDeleteShader(brightShader or 0)
        glDeleteShader(blurShaderH71 or 0)
        glDeleteShader(blurShaderV71 or 0)
        glDeleteShader(combineShader or 0)
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
        fragment = "#define inverseRX " .. tostring(ivsx) .. "\n" .. [[
            uniform sampler2D texture0;
            //uniform float inverseRX; //defined instead
            uniform float fragBlurAmplifier;
            const float invKernelSum = 0.01;

            void main(void) {
                vec2 texCoors = vec2(gl_TexCoord[0]);
                vec3 samples[9];

                samples[0] = texture2D(texture0, texCoors + vec2(-4 * inverseRX, 0)).rgb;
                samples[1] = texture2D(texture0, texCoors + vec2(-3 * inverseRX, 0)).rgb;
                samples[2] = texture2D(texture0, texCoors + vec2(-2 * inverseRX, 0)).rgb;
                samples[3] = texture2D(texture0, texCoors + vec2(-1 * inverseRX, 0)).rgb;
                samples[4] = texture2D(texture0, texCoors + vec2( 0            , 0)).rgb;
                samples[5] = texture2D(texture0, texCoors + vec2( 1 * inverseRX, 0)).rgb;
                samples[6] = texture2D(texture0, texCoors + vec2( 2 * inverseRX, 0)).rgb;
                samples[7] = texture2D(texture0, texCoors + vec2( 3 * inverseRX, 0)).rgb;
                samples[8] = texture2D(texture0, texCoors + vec2( 4 * inverseRX, 0)).rgb;

                samples[4] = (3*samples[0] + 7*samples[1] + 15*samples[2] + 20*samples[3] + 25*samples[4] + 20*samples[5] + 15*samples[6] + 7*samples[7]+ 3*samples[8]);
                gl_FragColor = vec4((samples[4] * invKernelSum) * fragBlurAmplifier,1.0);
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
            //uniform float inverseRY; //defined instead
            uniform float fragBlurAmplifier;
            const float invKernelSum = 0.01;

            void main(void) {
                vec2 texCoors = vec2(gl_TexCoord[0]);
                vec3 samples[9];  //i hope we can just use vec3

                samples[0] = texture2D(texture0, texCoors + vec2(0, -4 * inverseRY)).rgb;
                samples[1] = texture2D(texture0, texCoors + vec2(0, -3 * inverseRY)).rgb;
                samples[2] = texture2D(texture0, texCoors + vec2(0, -2 * inverseRY)).rgb;
                samples[3] = texture2D(texture0, texCoors + vec2(0, -1 * inverseRY)).rgb;
                samples[4] = texture2D(texture0, texCoors + vec2(0,  0            )).rgb;
                samples[5] = texture2D(texture0, texCoors + vec2(0,  1 * inverseRY)).rgb;
                samples[6] = texture2D(texture0, texCoors + vec2(0,  2 * inverseRY)).rgb;
                samples[7] = texture2D(texture0, texCoors + vec2(0,  3 * inverseRY)).rgb;
                samples[8] = texture2D(texture0, texCoors + vec2(0,  4 * inverseRY)).rgb;

                samples[4] = (3*samples[0] + 7*samples[1] + 15*samples[2] + 20*samples[3] + 25*samples[4] + 20*samples[5] + 15*samples[6] + 7*samples[7]+ 3*samples[8]);
                gl_FragColor = vec4((samples[4] * invKernelSum) * fragBlurAmplifier, 1.0);
            }
        ]],

        uniformInt = {texture0 = 0},
        uniformFloat = {inverseRY, fragBlurAmplifier}
    })

    if (blurShaderV71 == nil) then
        RemoveMe("[BloomShader::Initialize] blurShaderV71 compilation failed"); Spring.Echo(glGetShaderLog()); return
    end





    brightShader = glCreateShader({
        fragment = [[
            uniform sampler2D texture0;
            uniform float illuminationThreshold;
            uniform float fragGlowAmplifier;
            //uniform float inverseRX;//unused
            //uniform float inverseRY;// unused

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
        uniformFloat = {illuminationThreshold, fragGlowAmplifier} --, inverseRX, inverseRY}
    })

    if (brightShader == nil) then
        RemoveMe("[BloomShader::Initialize] brightShader compilation failed"); print(glGetShaderLog()); return
    end



    brightShaderText0Loc = glGetUniformLocation(brightShader, "texture0")
    -- brightShaderInvRXLoc = glGetUniformLocation(brightShader, "inverseRX")
    -- brightShaderInvRYLoc = glGetUniformLocation(brightShader, "inverseRY")
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

end

function widget:Initialize()
    -- Spring.Echo('bloomshader allowdeferredmap',Spring.GetConfigString("AllowDeferredMapRendering")) 
    -- Spring.Echo('bloomshader allowdeferredmodel',Spring.GetConfigString("AllowDeferredModelRendering")) 
    if (glCreateShader == nil) then
        RemoveMe("[BloomShader::Initialize] removing widget, no shader support")
        return
    end
    
    AddChatActions()
	MakeBloomShaders()

end

function widget:Shutdown()
    RemoveChatActions()

    glDeleteTexture(brightTexture1 or "")
    glDeleteTexture(brightTexture2 or "")
    glDeleteTexture(screenTexture or "")

    if (glDeleteShader) then
        glDeleteShader(brightShader or 0)
        glDeleteShader(blurShaderH71 or 0)
        glDeleteShader(blurShaderV71 or 0)
        glDeleteShader(combineShader or 0)
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
    local k=1
    local l=-1
    glCopyToTexture(screenTexture, 0, 0, 0, 0, vsx, vsy, nil,0)
 
    glUseShader(brightShader)
        glUniformInt(brightShaderText0Loc, 0)
        -- glUniform(   brightShaderInvRXLoc, ivsx)
        -- glUniform(   brightShaderInvRYLoc, ivsy)
        glUniform(   brightShaderIllumLoc, illumThreshold)
        glUniform(   brightShaderFragLoc, glowAmplifier)
        --mglRenderToTexture(brightTexture1, screenTexture, k,l)
        glTexture(screenTexture)
        glRenderToTexture(brightTexture1, gl.TexRect, -1,1,1,-1)
        glTexture(false)
    glUseShader(0)



    for i = 1, blurPasses do
        glUseShader(blurShaderH71)
            glUniformInt(blurShaderH71Text0Loc, 0)
            -- glUniform(   blurShaderH71InvRXLoc, ivsx)
            glUniform(   blurShaderH71FragLoc, blurAmplifier)
            --mglRenderToTexture(brightTexture2, brightTexture1,k,l)
            glTexture(brightTexture1)
            glRenderToTexture(brightTexture2, gl.TexRect, -1,1,1,-1)
            glTexture(false)
        glUseShader(0)
        glUseShader(blurShaderV71)
            glUniformInt(blurShaderV71Text0Loc, 0)
            -- glUniform(   blurShaderV71InvRYLoc, ivsy)
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

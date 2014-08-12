--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function widget:GetInfo()
  return {
    name      = "LOS widget",
    version   = 3,
    desc      = "Draws nice los",
    author    = "beherith",
    date      = "2008-2011",
    license   = "CC BY ND",
    layer     = 1,
    enabled   = false
  }
end


enabled = true

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Config



--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Automatically generated local definitions

local GL_MODELVIEW           = GL.MODELVIEW
local GL_NEAREST             = GL.NEAREST
local GL_ONE                 = GL.ONE
local GL_ONE_MINUS_SRC_ALPHA = GL.ONE_MINUS_SRC_ALPHA
local GL_PROJECTION          = GL.PROJECTION
local GL_QUADS               = GL.QUADS
local GL_SRC_ALPHA           = GL.SRC_ALPHA
local glBeginEnd             = gl.BeginEnd
local glBlending             = gl.Blending
local glCallList             = gl.CallList
local glColor                = gl.Color
local glColorMask            = gl.ColorMask
local glCopyToTexture        = gl.CopyToTexture
local glCreateList           = gl.CreateList
local glCreateShader         = gl.CreateShader
local glCreateTexture        = gl.CreateTexture
local glDeleteShader         = gl.DeleteShader
local glDeleteTexture        = gl.DeleteTexture
local glDepthMask            = gl.DepthMask
local glDepthTest            = gl.DepthTest
local glGetMatrixData        = gl.GetMatrixData
local glGetShaderLog         = gl.GetShaderLog
local glGetUniformLocation   = gl.GetUniformLocation
local glGetViewSizes         = gl.GetViewSizes
local glLoadIdentity         = gl.LoadIdentity
local glLoadMatrix           = gl.LoadMatrix
local glMatrixMode           = gl.MatrixMode
local glMultiTexCoord        = gl.MultiTexCoord
local glPopMatrix            = gl.PopMatrix
local glPushMatrix           = gl.PushMatrix
local glResetMatrices        = gl.ResetMatrices
local glTexCoord             = gl.TexCoord
local glTexture              = gl.Texture
local glRect                 = gl.Rect
local glUniform              = gl.Uniform
local glUniformMatrix        = gl.UniformMatrix
local glUseShader            = gl.UseShader
local glVertex               = gl.Vertex
local glTranslate            = gl.Translate
local spEcho                 = Spring.Echo
local spGetCameraPosition    = Spring.GetCameraPosition
local spGetCameraVectors     = Spring.GetCameraVectors
local spGetDrawFrame         = Spring.GetDrawFrame

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Extra GL constants
--

local GL_DEPTH_BITS = 0x0D56

local GL_DEPTH_COMPONENT   = 0x1902
local GL_DEPTH_COMPONENT16 = 0x81A5
local GL_DEPTH_COMPONENT24 = 0x81A6
local GL_DEPTH_COMPONENT32 = 0x81A7


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local debugGfx  =false --or true

local GLSLRenderer = true
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local gnd_min, gnd_max = Spring.GetGroundExtremes()
if (gnd_min < 0) then gnd_min = 0 end
if (gnd_max < 0) then gnd_max = 0 end
local vsx, vsy
local mx =math.pow(2, math.ceil(math.log(Game.mapSizeX)/math.log(2)))-- Game.mapSizeX
local mz =math.pow(2, math.ceil(math.log(Game.mapSizeZ)/math.log(2)))-- Game.mapSizeZ

local depthShader
local depthTexture

local uniformEyePos
local uniformViewPrjInv
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:ViewResize()
	vsx, vsy = gl.GetViewSizes()
	if (Spring.GetMiniMapDualScreen()=='left') then
		vsx=vsx/2;
	end
	if (Spring.GetMiniMapDualScreen()=='right') then
		vsx=vsx/2
	end

	if (depthTexture) then
		glDeleteTexture(depthTexture)
	end

	depthTexture = glCreateTexture(vsx, vsy, {
		format = GL_DEPTH_COMPONENT24,
		min_filter = GL_NEAREST,
		mag_filter = GL_NEAREST,
	})

	if (depthTexture == nil) then
		spEcho("Removing LOS widget, bad depth texture")
		widgetHandler:Removewidget()
	end
end

widget:ViewResize()


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local vertSrc = [[

  void main(void)
  {
    gl_TexCoord[0] = gl_MultiTexCoord0;
    gl_Position    = gl_Vertex;
  }
]]

local fragSrc = ([[
	const float mapxmul= 1/ %f;
	const float mapzmul= 1/ %f;
  uniform sampler2D tex0; // r=los, g= radar, b=jammer
  uniform sampler2D infotex;
  uniform mat4 viewProjectionInv;
	float rand(vec2 co){
		return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
	}
  void main(void)
  {
    float z = texture2D(tex0, gl_TexCoord[0].st).x;
	
    vec4 ppos;
    ppos.xyz = vec3(gl_TexCoord[0].st, z) * 2. - 1.;
    ppos.a   = 1.;

    vec4 worldPos4 = viewProjectionInv * ppos;

    vec3 worldPos  = worldPos4.xyz / worldPos4.w;
	vec4 info = texture2D(infotex, vec2(worldPos.x*mapxmul, worldPos.z*mapzmul));
	float rnd= rand(gl_TexCoord[0].st);
	float alpha=0.5;
	alpha=max( 0.5, alpha +(256*(info.r-0.5) ));
	gl_FragColor=vec4(0,0,0,(1-alpha));
	//gl_FragColor=info;
	return;
#ifdef DEBUG_GFX // world position debugging
    const float k  = 100.0;
    vec3 debugColor =worldPos4.xyz;
    gl_FragColor = vec4(fract(worldPos.x/50),fract(worldPos.y/50),fract(worldPos.z/50), 1.0);
    return; // BAIL
#endif

  }
]]):format(mx,mz)



if (debugGfx) then
  fragSrc = '#define DEBUG_GFX\n' .. fragSrc
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()
	if (enabled) then
		if ((not forceNonGLSL) and Spring.GetMiniMapDualScreen()~='left') then --FIXME dualscreen
			if (not glCreateShader) then
				spEcho("Shaders not found, reverting to non-GLSL widget")
				GLSLRenderer = false
			else
				depthShader = glCreateShader({
					vertex = vertSrc,
					fragment = fragSrc,
					uniformInt = {
						tex0 = 0,
						infotex = 1,
					},
				})

				if (not depthShader) then
					spEcho(glGetShaderLog())
					spEcho("Bad shader, reverting to non-GLSL widget.")
					GLSLRenderer = false
				else
					uniformViewPrjInv   = glGetUniformLocation(depthShader, 'viewProjectionInv')
				end
			end
		else
			GLSLRenderer = false
		end
	else
		widgetHandler:Removewidget()
	end
end


function widget:Shutdown()

	Spring.Echo('Turning off LOS widget')
	if status then 
			Spring.Echo('Turning off LOS mode and resetting colors')
			Spring.SetLosViewColors (   {0.25, 0.15, 0.05, 0.25}, --number always, number LOS, number radar, number jam 
										{0.25, 0.05, 0.15, 0.00},
										{0.25, 0.40, -0.2, 0.00})
	end
  if (GLSLRenderer) then
    glDeleteTexture(depthTexture)
    if (glDeleteShader) then
      glDeleteShader(depthShader)
    end
  end
end

local dl

local function DrawLOS()
	--//FIXME handle dualscreen correctly!
	-- copy the depth buffer
	gl.Color(1,1,1,1)
	glCopyToTexture(depthTexture, 0, 0, 0, 0, vsx, vsy ) --FIXME scale down?
	
	-- setup the shader and its uniform values
	glUseShader(depthShader)

	-- set uniforms
	glUniformMatrix(uniformViewPrjInv,  "viewprojectioninverse")

	if (not dl) then
		dl = gl.CreateList(function()
			-- render a full screen quad
			glTexture(0, depthTexture)
			--glTexture(0, false)
			glTexture(1 , "$info")
			gl.TexRect(-1, -1, 1, 1, 0, 0, 1, 1)

			--// finished
			glUseShader(0)
		end)
	end
	glCallList(dl)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local status = false

function widget:DrawWorld()
	gf=Spring.GetGameFrame()
	Spring.UpdateInfoTexture(2) --update info tex, normally a 1% load with extratextureupdaterate set to 45
	if Spring.GetMapDrawMode() == "los" then
		if status==false then -- losshader just got turned on
			status=true
			Spring.Echo('Turning on LOS mode')
			Spring.SetLosViewColors (	{0.5,0.004,0,0}, --number always, number LOS, number radar, number jam 
										{0.5,0,0.004,0},
										{0.5,0,0,0.004})
			
		else --we were already on
		end
	--else --not in los mode
		--if status == true then --we must turn off shader
		--	status= false
			
			--Spring.Echo('Turning off LOS mode')
			--Spring.SetLosViewColors (	{0.25, 0.15, 0.05, 0.25}, --number always, number LOS, number radar, number jam 
								--		{0.25, 0.05, 0.15, 0.00},
								--		{0.25, 0.40, -0.2, 0.00})
		--else -- already off
		--end
	end
	if status then
		if (GLSLRenderer) then
			DrawLOS()
		else
			--Spring.Echo('failed to use GLSL shader')
		end
	end
end



--------------------------------------------------------------------------------
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
--Spring.SetLosViewColors (needs ModUICtrl)
-- ( table reds = { number always, number LOS, number radar, number jam }, 
-- table greens = { number always, number LOS, number radar, number jam },
-- table blues = { number always, number LOS, number radar, number jam } ) -> nil

--Spring.GetMapDrawMode
-- ( ) -> nil | "normal" | "height" | "metal" | "pathTraversability" | "los"


--default loscolors:
-- los+radar should sum up to 0.5, but its only .45, note the darkening when los is on :)
-- we need to hack it so that there is only a bit of difference in each channel, and exploit that shader side
-- also, we need to hope that it will be detectable shader side 
-- 1/256=0.00390625
	-- jamColor[0] = (int)(losColorScale * 0.25f);
	-- jamColor[1] = (int)(losColorScale * 0.0f);
	-- jamColor[2] = (int)(losColorScale * 0.0f);

	-- losColor[0] = (int)(losColorScale * 0.15f);
	-- losColor[1] = (int)(losColorScale * 0.05f);
	-- losColor[2] = (int)(losColorScale * 0.40f);

	-- radarColor[0] = (int)(losColorScale *  0.05f);
	-- radarColor[1] = (int)(losColorScale *  0.15f);
	-- radarColor[2] = (int)(losColorScale * -0.20f);

	-- alwaysColor[0] = (int)(losColorScale * 0.25f);
	-- alwaysColor[1] = (int)(losColorScale * 0.25f);
	-- alwaysColor[2] = (int)(losColorScale * 0.25f);

--------------------------------------------------------------------------------

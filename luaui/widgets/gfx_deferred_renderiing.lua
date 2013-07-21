--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function widget:GetInfo()
  return {
    name      = "Deferred rendering",
    version   = 3,
    desc      = "Deferred rendering widget",
    author    = "beherith",
    date      = "2013 july",
    license   = "GNU GPL, v2 or later",
    layer     = -1000000000,
    enabled   = true
  }
end



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
local spIsSphereInView       = Spring.IsSphereInView
local spWorldToScreenCoords  = Spring.WorldToScreenCoords
local spTraceScreenRay       = Spring.TraceScreenRay
local spGetProjectilesInRectangle       = Spring.GetProjectilesInRectangle
local spGetProjectilePosition       = Spring.GetProjectilePosition
local spGetProjectileType       = Spring.GetProjectileType
local spGetProjectileName       = Spring.GetProjectileName
local spGetCameraPosition       = Spring.GetCameraPosition
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
-- Config


local debugGfx  =false --or true

local GLSLRenderer = true




--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local gnd_min, gnd_max = Spring.GetGroundExtremes()
if (gnd_min < 0) then gnd_min = 0 end
if (gnd_max < 0) then gnd_max = 0 end
local vsx, vsy
local ivsx = 1.0 
local ivsy = 1.0 

local depthShader
local depthTexture

local invrxloc = nil
local invryloc = nil
local lightposloc = nil
local uniformEyePos
local uniformViewPrjInv

local projectileLightTypes = {}
local lights = {}

-- parameters for each light:
-- RGBA: strength in each color channel, radius in elmos.
-- pos: xyz positions

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function GetLightsFromUnitDefs()
--The GetProjectileName function returns 'unitname_weaponnname'. EG: armcom_armcomlaser
	-- This is fine with BA, because unitnames dont use '_' characters
	--Spring.Echo('init')
	local plighttable = {}
	for u=1,#UnitDefs do
		if UnitDefs[u]['weapons'] and #UnitDefs[u]['weapons']>0 then --only units with weapons
			--These projectiles should have lights:
				--Cannon (projectile size: tempsize = 2.0f + std::min(wd.damages[0] * 0.0025f, wd.damageAreaOfEffect * 0.1f);)
				--Dgun
				--MissileLauncher
				--StarburstLauncher
				--LightningCannon --projectile is centered on emit point
			--Shouldnt:
				--AircraftBomb
				--BeamLaser --Beamlasers shouldnt, because they are buggy (GetProjectilePosition returns center of beam, no other info avalable)
				--LaserCannon --only sniper uses it, no need to make shot more visible
				--Melee
				--Shield
				--TorpedoLauncher
				--EmgCannon (only gorg uses it, and lights dont look so good too close to ground)
				--Flame --a bit iffy cause of long projectile life... too bad it looks great.
				
			for w=1,#UnitDefs[u]['weapons'] do 
				--Spring.Echo(UnitDefs[u]['weapons'][w]['weaponDef'])
				local weaponID=UnitDefs[u]['weapons'][w]['weaponDef']
				--Spring.Echo(UnitDefs[u]['name']..'_'..WeaponDefs[weaponID]['name'])
				--WeaponDefs[weaponID]['name'] returns: armcom_armcomlaser
				if (WeaponDefs[weaponID]['type'] == 'Cannon') then
					Spring.Echo('Cannon',WeaponDefs[weaponID]['name'],'size', WeaponDefs[weaponID]['size'])
					size=WeaponDefs[weaponID]['size']
					plighttable[WeaponDefs[weaponID]['name']]={1,1,0.5,100*size}
					
				elseif (WeaponDefs[weaponID]['type'] == 'Dgun') then
					Spring.Echo('Dgun',WeaponDefs[weaponID]['name'],'size', WeaponDefs[weaponID]['size'])
					--size=WeaponDefs[weaponID]['size']
					plighttable[WeaponDefs[weaponID]['name']]={1,1,0.5,300}
					
				elseif (WeaponDefs[weaponID]['type'] == 'MissileLauncher') then
					Spring.Echo('MissileLauncher',WeaponDefs[weaponID]['name'],'size', WeaponDefs[weaponID]['size'])
					size=WeaponDefs[weaponID]['size']
					plighttable[WeaponDefs[weaponID]['name']]={1,1,0.8,100* size}
					
				elseif (WeaponDefs[weaponID]['type'] == 'StarburstLauncher') then
					Spring.Echo('StarburstLauncher',WeaponDefs[weaponID]['name'],'size', WeaponDefs[weaponID]['size'])
					--size=WeaponDefs[weaponID]['size']
					plighttable[WeaponDefs[weaponID]['name']]={1,1,0.8,200}
				elseif (WeaponDefs[weaponID]['type'] == 'LightningCannon') then
					Spring.Echo('LightningCannon',WeaponDefs[weaponID]['name'],'size', WeaponDefs[weaponID]['size'])
					--size=WeaponDefs[weaponID]['size']
					plighttable[WeaponDefs[weaponID]['name']]={0.2,0.2,1,100}
				end
			end
		end
	end
	return plighttable
end

local function GetVisibleProjectiles()
	local x1, y1 = 0, 0
	local x2, y2 = Game.mapSizeX, Game.mapSizeZ
	local plist = {}
	local at, p = spTraceScreenRay(vsx*0.5,vsy*0.5,true,false,false)
	if at=='ground' then
		local cx, cy = p[1], p[3]
		local dcxp1, dcxp3
		local outofbounds = 0
		local d = 0
		--x2=math.min(x2, tl[1])
		--y2=math.min(y2, tl[3])
		
		at, p = spTraceScreenRay(0, 0, true, false, false) --bottom left
		if at=='ground' then
			dcxp1, dcxp3 = cx-p[1], cy-p[3]
			d = math.max(d, dcxp1*dcxp1 + dcxp3*dcxp3)
		else 
			outofbounds = outofbounds+1
		end
		at, p = spTraceScreenRay(vsx-1, 0, true, false, false) --bottom left
		if at=='ground' then
			dcxp1, dcxp3 = cx-p[1], cy-p[3]
			d = math.max(d, dcxp1*dcxp1 + dcxp3*dcxp3)
		else 
			outofbounds = outofbounds+1
		end
		at, p = spTraceScreenRay(vsx-1, vsy-1, true, false, false) --bottom left
		if at=='ground' then
			dcxp1, dcxp3 = cx-p[1], cy-p[3]
			d = math.max(d, dcxp1*dcxp1 + dcxp3*dcxp3)
		else 
			outofbounds = outofbounds+1
		end
		at, p = spTraceScreenRay(0, vsy-1, true, false, false) --bottom left
		if at=='ground' then
			dcxp1, dcxp3 = cx-p[1], cy-p[3]
			d = math.max(d, dcxp1*dcxp1 + dcxp3*dcxp3)
		else 
			outofbounds = outofbounds+1
		end
		if outofbounds>=3 then
			plist = spGetProjectilesInRectangle(x1, y1, x2, y2, false, false) --todo, only those in view or close:P
		else
			d = math.sqrt(d)
			plist = spGetProjectilesInRectangle(cx-d, cy-d , cx+d, cy+d, false, false) 
		end
	else -- if we are not pointing at ground, get the whole list.
		plist = spGetProjectilesInRectangle(x1, y1, x2, y2, false, false) --todo, only those in view or close:P
	end
	return plist
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--Light falloff functions: http://gamedev.stackexchange.com/questions/56897/glsl-light-attenuation-color-and-intensity-formula

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:ViewResize()
	vsx, vsy = gl.GetViewSizes()
	ivsx = 1.0 / vsx --we can do /n here!
	ivsy = 1.0 / vsy
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
		spEcho("Removing Deferred rendering widget, bad depth texture")
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

  uniform float inverseRX;
  uniform float inverseRY;
  uniform sampler2D tex0;
  uniform vec3 eyePos;
  uniform vec4 lightpos;
  uniform vec4 lightcolor;
  uniform mat4 viewProjectionInv;
  // uniform mat4 viewProjection;

  void main(void)
  {
    //http://stackoverflow.com/questions/5281261/generating-a-normal-map-from-a-height-map
	vec2 up2	= gl_TexCoord[0].st + vec2(0 , inverseRY);
	vec4 up4	= vec4(vec3(up2.xy, texture2D( tex0,up2 ).x) * 2.0 - 1.0 ,1.0);
	up4 = viewProjectionInv * up4;
	up4.xyz = up4.xyz / up4.w;
	
	vec2 right2	= gl_TexCoord[0].st + vec2(inverseRY , 0);
	vec4 right4	= vec4(vec3(right2.xy, texture2D( tex0,right2 ).x) * 2.0 - 1.0 ,1.0);
	right4 = viewProjectionInv * right4;
	right4.xyz = right4.xyz / right4.w;
	
	vec4 here4	= vec4(vec3(gl_TexCoord[0].st, texture2D( tex0,gl_TexCoord[0].st ).x) * 2.0 - 1.0 ,1.0);
	here4 = viewProjectionInv * here4;
	here4.xyz = here4.xyz / here4.w;
	
	vec4 herenormal4;
	herenormal4.xyz = -1.0*normalize(cross( up4.xyz - here4.xyz, right4.xyz - here4.xyz));
	float dist_light_here = length(lightpos.xyz - here4.xyz);
	float cosphi = max(0.0 , dot (herenormal4.xyz, lightpos.xyz - here4.xyz) / dist_light_here);
	//float attentuation = 1.0 / ( 1.0 + 1.0*dist + 1.0 *dist*dist); // alternative attentuation function
	//float attentuation =  saturate( ( 1.0 - (dist_light_here*dist_light_here)/(lightpos.w*lightpos.w)) );
	float attentuation =  max(0, ( 1.0 - (dist_light_here)/(lightpos.w)) );
	attentuation *=attentuation;
	
	//gl_FragColor=vec4(normalize(herenormal4.xyz), cosphi*(lightpos.w/(dist_light_here*dist_light_here)));
	//if (attentuation > 0.001) gl_FragColor(1,0,0,1);
	//else gl_FragColor(0,1,0,1);
	gl_FragColor=vec4(lightcolor.rgb, cosphi*attentuation);
	return;
  }
]])

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()
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
					uniformFloat = {inverseRX},
					uniformFloat = {inverseRY},
				},
			})

			if (not depthShader) then
				spEcho(glGetShaderLog())
				spEcho("Bad shader, reverting to non-GLSL widget.")
				GLSLRenderer = false
			else
				invrxloc=glGetUniformLocation(depthShader, "inverseRX")
				invryloc=glGetUniformLocation(depthShader, "inverseRY")
				lightposloc=glGetUniformLocation(depthShader, "lightpos")
				lightcolorloc=glGetUniformLocation(depthShader, "lightcolor")
				uniformEyePos       = glGetUniformLocation(depthShader, 'eyePos')
				uniformViewPrjInv   = glGetUniformLocation(depthShader, 'viewProjectionInv')
			end
		end
		projectileLightTypes=GetLightsFromUnitDefs()
	else
		GLSLRenderer = false
	end
end


function widget:Shutdown()
  if (GLSLRenderer) then
    glDeleteTexture(depthTexture)
    if (glDeleteShader) then
      glDeleteShader(depthShader)
    end
  end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:DrawWorld()
	if (GLSLRenderer) then
		local projectiles=GetVisibleProjectiles()
		if #projectiles == 0 then return end
		--//FIXME handle dualscreen correctly!
		-- copy the depth buffer
		glCopyToTexture(depthTexture, 0, 0, 0, 0, vsx, vsy ) --FIXME scale down?
		
		-- setup the shader and its uniform values
		glBlending("alpha_add")
		glUseShader(depthShader)
		--Spring.Echo('Camera FOV=',Spring.GetCameraFOV()) -- default TA cam fov = 45
		-- set uniforms
		local cpx, cpy, cpz = spGetCameraPosition()
		glUniform(uniformEyePos, cpx, cpy, cpz)
		glUniform(invrxloc, ivsx)
		glUniform(invryloc, ivsy)
		glUniformMatrix(uniformViewPrjInv,  "viewprojectioninverse")
		glTexture(0, depthTexture)
		glTexture(0, false)
		--f= Spring.GetGameFrame()
		--f=f/50
		local lightparams
		for i=1, #projectiles do
			local pID=projectiles[i]
			x,y,z=spGetProjectilePosition(pID)
			local wep,piece=spGetProjectileType(pID)
			if piece then
				lightparams={1,1,0.5,0.3}
			else
				lightparams=projectileLightTypes[spGetProjectileName(pID)]
			end
			if (lightparams and spIsSphereInView(x,y,z,lightparams[4])) then
				local sx,sy,sz = spWorldToScreenCoords(x,y,z) -- returns x,y,z, where x and y are screen pixels, and z is z buffer depth.
				--Spring.Echo('screencoords',sx,sy,sz)
				sx = sx/vsx
				sy = sy/vsy 
				local cx,cy,cz = spGetCameraPosition()
				local dist_sq = (x-cx)^2 + (y-cy)^2 + (z-cz)^2
				local ratio= lightparams[4] / math.sqrt(dist_sq)
				ratio=ratio*2
				glUniform(lightposloc, x,y,z, lightparams[4]) --IN world space
				glUniform(lightcolorloc, 1,1,1,1) --IN world space
				--Spring.Echo('screenratio',ratio,sx,sy)
				
				gl.TexRect(
					math.max(-1 , (sx-0.5)*2-ratio), 
					math.max(-1 , (sy-0.5)*2-ratio), 
					math.min( 1 , (sx-0.5)*2+ratio), 
					math.min( 1 , (sy-0.5)*2+ratio), 
					math.max( 0 , sx - 0.5*ratio), 
					math.max( 0 , sy - 0.5*ratio), 
					math.min( 1 , sx + 0.5*ratio),
					math.min( 1 , sy + 0.5*ratio)) -- screen size goes from -1,-1 to 1,1; uvs go from 0,0 to 1,1
				--gl.TexRect(-1, -1, 1, 1, 0, 0, 1, 1) -- screen size goes from -1,-1 to 1,1; uvs go from 0,0 to 1,1
			end
		end
		--gl.TexRect(0.5,0.5, 1, 1, 0.5, 0.5, 1, 1)

		glUseShader(0)
		glBlending(false)
	else
		Spring.Echo('Removing deferred rendering widget: failed to use GLSL shader')
		widgetHandler:Removewidget()
	end
end




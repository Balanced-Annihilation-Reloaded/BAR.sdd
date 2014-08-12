--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function widget:GetInfo()
  return {
    name      = "Deferred rendering",
    version   = 3,
    desc      = "Does deferred rendering",
    author    = "beherith",
    date      = "2013 july",
    license   = "CC-BY-ND",
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

local spGetProjectilesInRectangle = Spring.GetProjectilesInRectangle
local spGetVisibleProjectiles     = Spring.GetVisibleProjectiles
local spGetProjectilePosition     = Spring.GetProjectilePosition
local spGetProjectileType         = Spring.GetProjectileType
local spGetProjectileName         = Spring.GetProjectileName
local spGetCameraPosition         = Spring.GetCameraPosition
local spGetPieceProjectileParams  = Spring.GetPieceProjectileParams 
local spGetProjectileVelocity     = Spring.GetProjectileVelocity 
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

local depthPointShader
local depthBeamShader

local lightposlocPoint = nil
local lightcolorlocPoint = nil
local lightparamslocPoint = nil
local uniformEyePosPoint
local uniformViewPrjInvPoint

local lightposlocBeam  = nil
local lightpos2locBeam  = nil
local lightcolorlocBeam  = nil
local lightparamslocBeam  = nil
local uniformEyePosBeam 
local uniformViewPrjInvBeam 

local projectileLightTypes = {}
	--[1] red
	--[2] green
	--[3] blue
	--[4] radius
	--[5] constant 
	--[6] squared
	--[7] linear
	--[8] BEAMTYPE, true if BEAM
local lights = {}

-- parameters for each light:
-- RGBA: strength in each color channel, radius in elmos.
-- pos: xyz positions
-- params: ABC: where A is constant, B is quadratic, C is linear

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--Light falloff functions: http://gamedev.stackexchange.com/questions/56897/glsl-light-attenuation-color-and-intensity-formula

local verbose = false
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
					if verbose then Spring.Echo('Cannon',WeaponDefs[weaponID]['name'],'size', WeaponDefs[weaponID]['size']) end
					size=WeaponDefs[weaponID]['size']
					plighttable[WeaponDefs[weaponID]['name']]={0.5,0.5,0.25,100*size, 1,1,0,false}
					
				elseif (WeaponDefs[weaponID]['type'] == 'Dgun') then
					if verbose then Spring.Echo('Dgun',WeaponDefs[weaponID]['name'],'size', WeaponDefs[weaponID]['size']) end
					--size=WeaponDefs[weaponID]['size']
					plighttable[WeaponDefs[weaponID]['name']]={1,1,0.5,300,1,1,0,false}
					
				elseif (WeaponDefs[weaponID]['type'] == 'MissileLauncher') then
					if verbose then Spring.Echo('MissileLauncher',WeaponDefs[weaponID]['name'],'size', WeaponDefs[weaponID]['size']) end
					size=WeaponDefs[weaponID]['size']
					plighttable[WeaponDefs[weaponID]['name']]={0.5,0.5,0.6,100* size, 1,1, 0,false}
					
				elseif (WeaponDefs[weaponID]['type'] == 'StarburstLauncher') then
					if verbose then Spring.Echo('StarburstLauncher',WeaponDefs[weaponID]['name'],'size', WeaponDefs[weaponID]['size']) end
					--size=WeaponDefs[weaponID]['size']
					plighttable[WeaponDefs[weaponID]['name']]={0.5,0.5,0.4,200,1,1,0,false}
				elseif (WeaponDefs[weaponID]['type'] == 'LightningCannon') then
					if verbose then Spring.Echo('LightningCannon',WeaponDefs[weaponID]['name'],'size', WeaponDefs[weaponID]['size']) end
					--size=WeaponDefs[weaponID]['size']
					plighttable[WeaponDefs[weaponID]['name']]={0.3,0.3,1.5,100,1,1,0,true}
				elseif (WeaponDefs[weaponID]['type'] == 'BeamLaser') then
					if verbose then Spring.Echo('BeamLaser',WeaponDefs[weaponID]['name'],'rgbcolor', WeaponDefs[weaponID]['visuals']['colorR']) end
					--size=WeaponDefs[weaponID]['size']
					plighttable[WeaponDefs[weaponID]['name']]={WeaponDefs[weaponID]['visuals']['colorR'],WeaponDefs[weaponID]['visuals']['colorG'],WeaponDefs[weaponID]['visuals']['colorB'],math.min(WeaponDefs[weaponID]['range'],600),1,1,0,true}
				end
			end
		end
	end
	return plighttable
end

--[[
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
--]]



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
local fragSrc
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()
	if  (Spring.GetConfigString("AllowDeferredMapRendering") == '0' or Spring.GetConfigString("AllowDeferredModelRendering")=='0') then
		Spring.Echo('Deferred Rendering (gfx_deferred_rendering.lua) requires  AllowDeferredMapRendering and AllowDeferredModelRendering to be enabled in springsettings.cfg!') 
		widgetHandler:RemoveWidget()
		return
	end
	if ((not forceNonGLSL) and Spring.GetMiniMapDualScreen()~='left') then --FIXME dualscreen
		if (not glCreateShader) then
			spEcho("Shaders not found, reverting to non-GLSL widget")
			GLSLRenderer = false
		else
			fragSrc = VFS.LoadFile("shaders\\deferred_lighting.glsl",VFS.ZIP)
			--Spring.Echo('Shader code:',fragSrc)
			depthPointShader = glCreateShader({
				vertex = vertSrc,
				fragment = fragSrc,
				uniformInt = {
					modelnormals = 0,
					modeldepths = 1,
					mapnormals = 2,
					mapdepths = 3,
					
				},
			})

			if (not depthPointShader) then
				spEcho(glGetShaderLog())
				spEcho("Bad depth point shader, reverting to non-GLSL widget.")
				GLSLRenderer = false
			else
				lightposlocPoint=glGetUniformLocation(depthPointShader, "lightpos")
				lightcolorlocPoint=glGetUniformLocation(depthPointShader, "lightcolor")
				lightparamslocPoint=glGetUniformLocation(depthPointShader, "lightparams")
				uniformEyePosPoint       = glGetUniformLocation(depthPointShader, 'eyePos')
				uniformViewPrjInvPoint   = glGetUniformLocation(depthPointShader, 'viewProjectionInv')
			end
			fragSrc="#define BEAM_LIGHT \n".. fragSrc
			depthBeamShader = glCreateShader({
				vertex = vertSrc,
				fragment = fragSrc,
				uniformInt = {
					modelnormals = 0,
					modeldepths = 1,
					mapnormals = 2,
					mapdepths = 3,
					
				},
			})

			if (not depthBeamShader) then
				spEcho(glGetShaderLog())
				spEcho("Bad depthBeamShader, reverting to non-GLSL widget.")
				GLSLRenderer = false
			else
				lightposlocBeam=glGetUniformLocation(depthBeamShader, "lightpos")
				lightpos2locBeam=glGetUniformLocation(depthBeamShader, "lightpos2")
				lightcolorlocBeam=glGetUniformLocation(depthBeamShader, "lightcolor")
				lightparamslocBeam=glGetUniformLocation(depthBeamShader, "lightparams")
				uniformEyePosBeam       = glGetUniformLocation(depthBeamShader, 'eyePos')
				uniformViewPrjInvBeam   = glGetUniformLocation(depthBeamShader, 'viewProjectionInv')
			end
		end
		projectileLightTypes=GetLightsFromUnitDefs()
	else
		GLSLRenderer = false
	end
end


function widget:Shutdown()
  if (GLSLRenderer) then
    if (glDeleteShader) then
      glDeleteShader(depthPointShader)
      glDeleteShader(depthBeamShader)
    end
  end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function TableConcat(t1,t2)
	tnew={}
	for i=1,#t1 do
		tnew[i]=t1[i]
	end
    for i=1,#t2 do
        tnew[#t1+i] = t2[i]
    end
    return tnew
end
local function DrawLightType(lights,lighttype) -- point = 0 beam = 1
	--Spring.Echo('Camera FOV=',Spring.GetCameraFOV()) -- default TA cam fov = 45
	-- set uniforms
	local cpx, cpy, cpz = spGetCameraPosition()
	if lighttype==0 then --point
		glUseShader(depthPointShader)
		glUniform(uniformEyePosPoint, cpx, cpy, cpz)
		glUniformMatrix(uniformViewPrjInvPoint,  "viewprojectioninverse")
	else --beam
		 glUseShader(depthBeamShader)
		glUniform(uniformEyePosBeam, cpx, cpy, cpz)
		glUniformMatrix(uniformViewPrjInvBeam,  "viewprojectioninverse")
	end

	glTexture(0, "$model_gbuffer_normtex")
	glTexture(1, "$model_gbuffer_zvaltex")
	glTexture(2, "$map_gbuffer_normtex")
	glTexture(3, "$map_gbuffer_zvaltex")
	
	--f= Spring.GetGameFrame()
	--f=f/50
	for i=1, #lights do
		local light=lights[i]
		local inview=false
		local lightradius=0
		--Spring.Echo(light)
		local px=light[9]+light[12]*0.5
		local py=light[10]+light[13]*0.5
		local pz=light[11]+light[14]*0.5
		if lighttype==0 then 
			lightradius=light[4]
			inview=spIsSphereInView(light[9],light[10],light[11],light[4])
		end
		if lighttype==1 then 
			lightradius=light[4]+math.sqrt(light[12]^2+light[13]^2+light[14]^2)*0.5
			inview=spIsSphereInView(light[9]+light[12]*0.5,light[10]+light[13]*0.5,light[11]+light[14]*0.5,lightradius)
		end
		if (inview) then
			--Spring.Echo("Drawlighttype position=",light[9],light[10],light[11])
			local sx,sy,sz = spWorldToScreenCoords(light[9]+light[12]*0.5,light[10]+light[13]*0.5,light[11]+light[14]*0.5) -- returns x,y,z, where x and y are screen pixels, and z is z buffer depth.
			--Spring.Echo('screencoords',sx,sy,sz)
			sx = sx/vsx
			sy = sy/vsy --since FOV is static in the Y direction, the Y ratio is the correct one
			local screenratio=vsy/vsx --so we dont overdraw and only always draw a square
			
			local cx,cy,cz = spGetCameraPosition()
			local dist_sq = (px-cx)^2 + (py-cy)^2 + (pz-cz)^2
			local ratio= lightradius / math.sqrt(dist_sq)
			ratio=ratio*2
			if lighttype==0 then
				glUniform(lightposlocPoint, light[9],light[10],light[11], light[4]) --IN world space
				glUniform(lightcolorlocPoint, light[1],light[2],light[3], 1) 
				glUniform(lightparamslocPoint, light[5],light[6],light[7], 1) 
			end
			if lighttype==1 then
				
				glUniform(lightposlocBeam, light[9],light[10],light[11], light[4]) --IN world space
				glUniform(lightpos2locBeam, light[9]+light[12],light[10]+light[13]+24,light[11]+light[14], light[4]) --IN world space,the magic constant of +24 in the Y pos is needed because of our beam distance calculator function in GLSL
				glUniform(lightcolorlocBeam, light[1],light[2],light[3], 1) 
				glUniform(lightparamslocBeam, light[5],light[6],light[7], 1) 
			end
			
			--Spring.Echo('screenratio',ratio,sx,sy)
			
			gl.TexRect(
				math.max(-1 , (sx-0.5)*2-ratio*screenratio), 
				math.max(-1 , (sy-0.5)*2-ratio), 
				math.min( 1 , (sx-0.5)*2+ratio*screenratio), 
				math.min( 1 , (sy-0.5)*2+ratio), 
				math.max( 0 , sx - 0.5*ratio*screenratio), 
				math.max( 0 , sy - 0.5*ratio), 
				math.min( 1 , sx + 0.5*ratio*screenratio),
				math.min( 1 , sy + 0.5*ratio)) -- screen size goes from -1,-1 to 1,1; uvs go from 0,0 to 1,1
			--gl.TexRect(-1, -1, 1, 1, 0, 0, 1, 1) -- screen size goes from -1,-1 to 1,1; uvs go from 0,0 to 1,1
			
		end
	end
	--gl.TexRect(0.5,0.5, 1, 1, 0.5, 0.5, 1, 1)

	glUseShader(0)
end
function widget:DrawWorld()
	if (GLSLRenderer) then
		local projectiles=spGetVisibleProjectiles()
		if #projectiles == 0 then return end
		local beamlightprojectiles={}
		local pointlightprojectiles={}
		for i, pID in ipairs(projectiles) do
			local x,y,z=spGetProjectilePosition(pID)
			--Spring.Echo("projectilepos=",x,y,z)
			local wep,piece=spGetProjectileType(pID)
			if piece then
				local explosionflags = spGetPieceProjectileParams(pID)
				if explosionflags and (explosionflags%32)>15  then --only stuff with the FIRE explode tag gets a light
					--Spring.Echo('explosionflag=',explosionflags)
					table.insert(pointlightprojectiles,{0.5,0.5,0.25,100,1,1,0,false,x,y,z,0,0,0})
					--lightparams={0.5,0.5,0.25,100,1,1,0}
				--else
				--	lightparams=nil
				end
			else
				lightparams=projectileLightTypes[spGetProjectileName(pID)]
				if lightparams then
					if lightparams[8] then --BEAM type
						local dx,dy,dz=spGetProjectileVelocity(pID)
						--Spring.Echo({x,y,z,dx,dy,dz})
						table.insert(beamlightprojectiles,TableConcat(lightparams,{x,y,z,dx,dy,dz}))
						--Spring.Echo('GetFeatureVelocity=',dx,dy,dz)
					else --point type
						table.insert(pointlightprojectiles,TableConcat(lightparams,{x,y,z,0,0,0}))
						
					end
				end
			end
			
		end 
		
		
		--//FIXME handle dualscreen correctly!
		-- copy the depth buffer
		
		-- setup the shader and its uniform values
		glBlending(GL.DST_COLOR,GL.ONE) -- ResultR=LightR*DestinationR+1*DestinationR
			--glBlending(GL.SRC_ALPHA,GL.SRC_COLOR) 
			--http://www.andersriggelsen.dk/glblendfunc.php
			--glBlending(GL.ONE,GL.DST_COLOR) --http://www.andersriggelsen.dk/glblendfunc.php
		--glBlending(GL.ONE,GL.ZERO)
		if #beamlightprojectiles>0 then DrawLightType(beamlightprojectiles, 1) end
		if #pointlightprojectiles>0 then DrawLightType(pointlightprojectiles, 0) end
		glBlending(false)
	else
		Spring.Echo('Removing deferred rendering widget: failed to use GLSL shader')
		widgetHandler:RemoveWidget()
	end
end




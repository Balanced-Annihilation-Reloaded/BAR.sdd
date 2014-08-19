--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
   return {
      name      = "Depth of Field",
      desc      = "ctrl+] or [ to change intensity",
      author    = "jK, Satirik (shortcuts: BD & Floris)",
      date      = "March, 2013",
      license   = "GNU GPL, v2 or later",
      layer     = 2,
      enabled   = false
   }
end

OPTIONS = {
	shortcuts = {
		intensityIncrease = 'Ctrl+]',
		intensityDecrease = 'Ctrl+[',
	},
	quality = {
		name = 'Quality',
		type = 'number',
		min = 1,
		max = 30,
		step = 1,
		value = 5,
	},
	intensity = {
		name = 'Intensity',
		type = 'number',
		min = 0.05,
		max = 10.,
		step = 0.05,
		value = 0,
	},
	focusCurveExp = {
		name = 'Non linear focused area',
		type = 'number',
		min = 1.,
		max = 4.,
		step = 0.1,
		value = 2,
	},
	focusRangeMultiplier = {
		name = 'Focus range multiplier',
		type = 'number',
		min = 0.1,
		max = 3.0,
		step = 0.1,
		value = 0.2,
	},
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--hardware capability

local canRTT    = (gl.RenderToTexture ~= nil)
local canCTT    = (gl.CopyToTexture ~= nil)
local canShader = (gl.CreateShader ~= nil)

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local GL_DEPTH_BITS = 0x0D56

local GL_DEPTH_COMPONENT   = 0x1902
local GL_DEPTH_COMPONENT16 = 0x81A5
local GL_DEPTH_COMPONENT24 = 0x81A6
local GL_DEPTH_COMPONENT32 = 0x81A7

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local blurShader
local dofShader
local screencopy
local depthcopy

local focusLoc
local focusRangeLoc
local viewXLoc
local viewYLoc
local qualityLoc
local intensityLoc
local focusCurveExpLoc
local focusRangeMultiplierLoc
local focusPtXLoc
local focusPtYLoc

local oldvs = 0
local vsx, vsy   = widgetHandler:GetViewSizes()
function widget:ViewResize(viewSizeX, viewSizeY)
  vsx, vsy  = viewSizeX,viewSizeY

  if (gl.DeleteTextureFBO) then
    gl.DeleteTexture(depthcopy)
    gl.DeleteTextureFBO(blurtex)
    gl.DeleteTextureFBO(blurtex2)
    gl.DeleteTexture(screencopy)
  end

  depthcopy = gl.CreateTexture(vsx,vsy, {
    border = false,
    format = GL_DEPTH_COMPONENT24,
    min_filter = GL.NEAREST,
    mag_filter = GL.NEAREST,
  })
  screencopy = gl.CreateTexture(vsx, vsy, {
    border = false,
    min_filter = GL.NEAREST,
    mag_filter = GL.NEAREST,
  })

  if (screencopy == nil) then
    Spring.Echo("Depth of Field: texture error")
    widgetHandler:RemoveWidget()
    return false
  end
end

function widget:GetConfigData()
  return {
    quality  = OPTIONS.quality.value,
	intensity = OPTIONS.intensity.value,
	focusCurveExp = OPTIONS.focusCurveExp.value,
	focusRangeMultiplier = OPTIONS.focusRangeMultiplier.value,
  }
end

function widget:SetConfigData(data)
  --OPTIONS.quality.value  = data.quality or 2.
  --OPTIONS.intensity.value = data.intensity or 1.
  --OPTIONS.focusCurveExp.value = data.focusCurveExp or 2.
  --OPTIONS.focusRangeMultiplier.value = data.focusRangeMultiplier or 1.
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function CheckHardware()
  if (not canCTT) then
    Spring.Echo("Depth of Field: your hardware is missing the necessary CopyToTexture feature")
    widgetHandler:RemoveWidget()
    return false
  end

  if (not canRTT) then
    Spring.Echo("Depth of Field: your hardware is missing the necessary RenderToTexture feature")
    widgetHandler:RemoveWidget()
    return false
  end

  if (not canShader) then
    Spring.Echo("Depth of Field: your hardware does not support shaders")
    widgetHandler:RemoveWidget()
    return false
  end

  return true
end


-- user controls

function dofIntensity(cmd, line, words)
  OPTIONS.intensity.value = tonumber(words[1])
  --Spring.Echo("Depth of Field: intensity: "..OPTIONS.intensity.value)
  return true
end

function dofIntensityIncrease()
  OPTIONS.intensity.value = OPTIONS.intensity.value + OPTIONS.intensity.step
  if (OPTIONS.intensity.value > OPTIONS.intensity.max) then
  	 OPTIONS.intensity.value = OPTIONS.intensity.max
  end
  if OPTIONS.intensity.value >= OPTIONS.intensity.min and OPTIONS.intensity.value - OPTIONS.intensity.step <= OPTIONS.intensity.min then 
	Spring.Echo("Depth of Field: enabled")
  end
  return true
end

function dofIntensityDecrease()
  OPTIONS.intensity.value = OPTIONS.intensity.value - OPTIONS.intensity.step
  if (OPTIONS.intensity.value < OPTIONS.intensity.min) then
  	 OPTIONS.intensity.value = OPTIONS.intensity.min
  end
  if OPTIONS.intensity.value <= OPTIONS.intensity.min then 
	Spring.Echo("Depth of Field: disabled")
  end
  return true
end

function dofQuality(cmd, line, words)
  OPTIONS.quality.value = tonumber(words[1])
  if (OPTIONS.quality.value > OPTIONS.quality.max) then
  	 OPTIONS.quality.value = OPTIONS.quality.max
  end
  --Spring.Echo("Depth of Field: quality changed to: "..OPTIONS.quality.value)
  return true
end



local fragSrc
function widget:Initialize()
  if (not CheckHardware()) then return false end
  
  -- register user control commands/keys
  widgetHandler:AddAction("dofIntensityIncrease", dofIntensityIncrease, nil, "t")
  Spring.SendCommands({"bind "..OPTIONS.shortcuts.intensityIncrease.." dofIntensityIncrease"})
  
  widgetHandler:AddAction("dofIntensityDecrease", dofIntensityDecrease, nil, "t")
  Spring.SendCommands({"bind "..OPTIONS.shortcuts.intensityDecrease.." dofIntensityDecrease"})
  
  widgetHandler:AddAction("dofQuality", dofQuality, nil, "t")
  widgetHandler:AddAction("dofIntensity", dofIntensity, nil, "t")
  
  
  fragSrc = VFS.LoadFile("shaders\\dof.glsl",VFS.ZIP)
  dofShader = gl.CreateShader({
    fragment = fragSrc,
    uniform = {
      focus      = 0.9955,
      focusRange = 1./0.0005,
    },
    uniformInt = {
      tex0 = 0,
      tex1 = 1,
      tex2 = 2,
    }
  })
  
  Spring.Echo(gl.GetShaderLog())

  -- create blurtexture
  depthcopy = gl.CreateTexture(vsx,vsy, {
    border = false,
    format = GL_DEPTH_COMPONENT24,
    min_filter = GL.NEAREST,
    mag_filter = GL.NEAREST,
  })
  screencopy = gl.CreateTexture(vsx, vsy, {
    border = false,
    min_filter = GL.NEAREST,
    mag_filter = GL.NEAREST,
  })

  -- debug?
  if (screencopy == nil) then
    Spring.Echo("Depth of Field: texture error")
    widgetHandler:RemoveWidget()
    return false
  end

  focusLoc      = gl.GetUniformLocation(dofShader,"focus")
  focusRangeLoc = gl.GetUniformLocation(dofShader,"focusRange")
  viewXLoc = gl.GetUniformLocation(dofShader,"viewX")
  viewYLoc = gl.GetUniformLocation(dofShader,"viewY")
  qualityLoc = gl.GetUniformLocation(dofShader,"quality")
  intensityLoc = gl.GetUniformLocation(dofShader,"intensity")
  focusCurveExpLoc = gl.GetUniformLocation(dofShader,"focusCurveExp")
  focusRangeMultiplierLoc = gl.GetUniformLocation(dofShader,"focusRangeMultiplier")
  focusRangeMultiplierLoc = gl.GetUniformLocation(dofShader,"focusRangeMultiplier")
  focusPtXLoc = gl.GetUniformLocation(dofShader,"focusPtX")
  focusPtYLoc = gl.GetUniformLocation(dofShader,"focusPtY")  
  
  
	local Chili = WG.Chili
	local Menu = WG.MainMenu
	if not Menu then return end
	
	Menu.AddOption{
		tab      = 'Interface',
		children = {
			Chili.Label:New{caption='Depth of Field',x='0%',fontsize=18},
			Chili.Label:New{caption='Intensity'},
			Chili.Trackbar:New{
				x        = '10%',
				width    = '80%',
				min      = OPTIONS.intensity.min,
				max      = OPTIONS.intensity.max,
				step     = OPTIONS.intensity.step,
				value    = OPTIONS.intensity.value,
				OnChange = {function(_,value) 
					OPTIONS.intensity.value = value; 
					OPTIONS.quality.value = 2 + math.floor(value*0.33)
					--Spring.Echo(OPTIONS.quality.value)
				end}
			},
			--[[Chili.Checkbox:New{
				caption='Follow Cursor',x='10%',width='80%',
				checked=OPTIONS.defaults.showUnitHighlightHealth,
				setting=OPTIONS.defaults.showUnitHighlightHealth,
				OnChange={function(_,value) OPTIONS.defaults.showUnitHighlightHealth = value;  OPTIONS[currentOption].showUnitHighlightHealth = value end}
			},]]--
			Chili.Line:New{width='100%'},
		}
	}
	
end


function widget:Shutdown()
  
  if (gl.DeleteTextureFBO) then
    gl.DeleteTexture(depthcopy)
    gl.DeleteTexture(screencopy)
    gl.DeleteTextureFBO(blurtex)
    gl.DeleteTextureFBO(blurtex2)
  end
  if (gl.DeleteShader) then
    gl.DeleteShader(blurShader or 0)
    gl.DeleteShader(dofShader or 0)
  end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:DrawScreenEffects()
  if OPTIONS.intensity.value < OPTIONS.intensity.min then return  end
  
  local zfocus = 0.9995

  local msx,msy = widgetHandler:GetViewSizes()
  msx,msy = 0.5*msx,0.5*msy
  local type,mpos = Spring.TraceScreenRay(msx,msy,true)
  if (type=="ground") then
    _,_,zfocus  = Spring.WorldToScreenCoords(mpos[1],mpos[2],mpos[3])
  end
  
  viewX,viewY = gl.GetViewSizes()
  
  local mouseX,mouseY = Spring.GetMouseState()
  
  local focusRange = 0.8*(1-zfocus) -- + ((1-zfocus)*(1-zfocus)*10)
  --zfocus = zfocus - zfocus^10000

    gl.CopyToTexture(depthcopy, 0, 0, 0, 0, vsx, vsy)
    gl.CopyToTexture(screencopy, 0, 0, 0, 0, vsx, vsy)

    gl.Texture(screencopy)

    gl.UseShader(dofShader)
      gl.Uniform(focusLoc,zfocus)
      gl.Uniform(focusRangeLoc,1/focusRange)
	  gl.Uniform(viewXLoc,viewX)
	  gl.Uniform(viewYLoc,viewY)
	  gl.Uniform(qualityLoc,OPTIONS.quality.value)
	  gl.Uniform(intensityLoc,OPTIONS.intensity.value)
	  gl.Uniform(focusCurveExpLoc,OPTIONS.focusCurveExp.value)
	  gl.Uniform(focusRangeMultiplierLoc,OPTIONS.focusRangeMultiplier.value)
	  gl.Uniform(focusPtXLoc,mouseX/viewX)
	  gl.Uniform(focusPtYLoc,mouseY/viewY)
    gl.Texture(0,screencopy)
    gl.Texture(2,depthcopy)
    gl.TexRect(0,vsy,vsx,0)

    gl.Texture(0,false)
    gl.Texture(1,false)
    gl.Texture(2,false)
    gl.UseShader(0)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

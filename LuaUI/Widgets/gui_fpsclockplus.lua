local versionNumber = "1.0"
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    gui_fpsclockplus.lua
--  brief:   displays the current frames-per-seconds and clock in a nice way
--  author:  Dave Rodgers (originally, modified by Beherith to suit his needs)
--
--  Copyright (C) 2007.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "FPS Clock plus 1.0",
    desc      = "Displays clock and FPS in a nice little bar",
    author    = "Beherith (original widget from trepan)",
    date      = "Sept 9, 2009",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

include("colors.h.lua")
local gl_Blending = gl.Blending
local gl_Color = gl.Color
local gl_Texture = gl.Texture
local gl_TexRect= gl.TexRect
local gl_Text= gl.Text
local Spring_GetGameSeconds = Spring.GetGameSeconds

local floor = math.floor


local vsx, vsy = widgetHandler:GetViewSizes()

-- the 'f' suffixes are fractions  (and can be nil)
local color  = { 1.0, 1.0, 0.25 }
local xposf  = 1
local xpos   = xposf * vsx
local yposf  = 0.9
local ypos   = yposf * vsy
local sizef  = 25
local size   = 16
local font   = "LuaUI/Fonts/FreeSansBold_14"
local font   = "LuaUI/Fonts/Abaddon_30"
local format = "rn"
local fpsoffx= -34
local fpsoffy= 14
local clockoffx = -21
local clockoffy =46
local fh = (font ~= nil)


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Default GUI override
--

local defaultFPSUsed = 0

local defaultClockUsed = 0

function widget:Initialize()
  defaultFPSUsed = Spring.GetConfigInt("ShowFPS", 1)
  Spring.SendCommands({"fps 0"})
  defaultClockUsed = Spring.GetConfigInt("ShowClock", 1)
  Spring.SendCommands({"clock 0"})
end


function widget:Shutdown()
  Spring.SendCommands({"fps " .. defaultFPSUsed})
  Spring.SendCommands({"clock " .. defaultClockUsed})
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Rendering
--
local function GetTimeString()
  local secs = math.floor(Spring.GetGameSeconds())
  if (timeSecs ~= secs) then
    timeSecs = secs
    local h = math.floor(secs / 3600)
    local m = math.floor(math.fmod(secs, 3600) / 60)
    local s = math.floor(math.fmod(secs, 60))
    if (h > 0) then
      timeString = string.format('%01i:%02i:%02i', h, m, s)
    else
      timeString = string.format('0:%02i:%02i', m, s)
    end
  end
  return timeString
end


function widget:DrawScreen()
  xpos   = xposf * vsx
  ypos   = vsy -128
  gl_Color(1,1,1,1)
  gl_Texture('LuaUI/Images/fpsclock.png')	
  gl_TexRect(xpos-127,ypos+128,xpos+1,ypos,0,0,1,1)
 -- Spring.Echo("drawing:"..xpos.." "..ypos.." fract:".."xposf".." ".."yposf")
  if false then--(fh) then
    fh = fontHandler.UseFont(font)
    fontHandler.DisableCache()
    fontHandler.DrawRight(Spring.GetFPS(), floor(xpos)+fpsoffx, floor(ypos)+fpsoffy)
	fontHandler.DrawRight(GetTimeString(), floor(xpos)+clockoffx, floor(ypos)+clockoffy)
    fontHandler.EnableCache()
  else
	gl_Color(0.6,1,1,1)
    gl.Text(Spring.GetFPS(), xpos+fpsoffx, ypos+fpsoffy, size, format)
	gl.Text(GetTimeString(), xpos+clockoffx, ypos+clockoffy, size, format)
  end
    gl_Texture('LuaUI/Images/fpsclockscreen.png')	
  gl_TexRect(xpos-127,ypos+128,xpos+1,ypos,0,0,1,1)
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Geometry Management
--

local function UpdateGeometry()
  -- use the fractions if available
  xpos = (xposf and (xposf * vsx)) or xpos
  ypos = (yposf and (yposf * vsy)) or ypos
  
  -- negative values reference the right/top edges
  xpos = (xpos < 0) and (vsx + xpos) or xpos
  ypos = (ypos < 0) and (vsy + ypos) or ypos
end
UpdateGeometry()


function widget:ViewResize(viewSizeX, viewSizeY)
  vsx = viewSizeX
  vsy = viewSizeY
  UpdateGeometry()
end





--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

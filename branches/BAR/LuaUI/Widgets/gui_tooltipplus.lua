local versionNumber = "1.0"

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    gui_tooltipplus.lua
--  brief:   recolors some of the tooltip info
--  author:  Dave Rodgers (hacked by beherith)
--
--  Copyright (C) 2007.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Tooltip Plus",
    desc      = "A Nice replacement for the default tooltip",
    author    = "Beherith (originally trepan)",
    date      = "Sept 10, 2009",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = false,  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Automatically generated local definitions

local glColor                 = gl.Color
local glText                  = gl.Text
local spGetCurrentTooltip     = Spring.GetCurrentTooltip
local spGetSelectedUnitsCount = Spring.GetSelectedUnitsCount
local spSendCommands          = Spring.SendCommands

local gl_Blending = gl.Blending
local gl_Color = gl.Color
local gl_Texture = gl.Texture
local gl_TexRect= gl.TexRect
local gl_Text= gl.Text

local vsx, vsy = widgetHandler:GetViewSizes()
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

include("colors.h.lua")


local fontSize = 13
local ySpace   = 3
local yStep    = fontSize + ySpace
local gap      = 10






local currentTooltip = ''

--------------------------------------------------------------------------------

local vsx, vsy = widgetHandler:GetViewSizes()

function widget:ViewResize(viewSizeX, viewSizeY)
  vsx = viewSizeX
  vsy = viewSizeY
end


--------------------------------------------------------------------------------

function widget:Initialize()
  spSendCommands({"tooltip 0"})
end


function widget:Shutdown()
  spSendCommands({"tooltip 1"})
end


--------------------------------------------------------------------------------

local magic = '\001'

function widget:WorldTooltip(ttType, data1, data2, data3)
--  do return end
Spring.Echo(" data1:"..data1 .." data2:"..data2 .." data3:"..data3)
  if string.len(data1) >30 then
	splitnum=math.max(string.find(data1, " ", 25),35)
	data1=  string.sub(data1,0,splitnum).. magic ..string.sub(data1,splitnum,string.len(data1))
  end
  if (ttType == 'unit') then
    return magic .. 'unit #' .. data1
  elseif (ttType == 'feature') then
    return magic .. 'feature #' .. data1
  elseif (ttType == 'ground') then
    return magic .. string.format('ground @ %.1f %.1f %.1f',
                                  data1, data2, data3)
  elseif (ttType == 'selection') then
    return magic .. 'selected ' .. spGetSelectedUnitsCount()
  else
    return 'WTF? ' .. '\'' .. tostring(ttType) .. '\''
  end
end


if (true) then
  widget.WorldTooltip = nil
end


--------------------------------------------------------------------------------

function widget:DrawScreen()

  local white = "\255\255\255\255"
  local bland = "\255\211\219\255"
  local mSub, eSub
  local tooltip = spGetCurrentTooltip()

  if (string.sub(tooltip, 1, #magic) == magic) then
    tooltip = 'WORLD TOOLTIP:  ' .. tooltip
  end

  tooltip, mSub = string.gsub(tooltip, bland.."Me",   "\255\1\255\255Me")
  tooltip, eSub = string.gsub(tooltip, bland.."En", "  \255\255\255\1En")
  tooltip = string.gsub(tooltip,
                        "Hotkeys:", "\255\255\128\128Hotkeys:\255\128\192\255")
  tooptip =       string.gsub(tooltip, "a", "b")
  local unitTip = ((mSub + eSub) == 2)
  local i = 0

  
  gl_Color(1,1,1,1)
  gl_Blending(true)
  gl_Texture('LuaUI/Images/tooltipplus.png')	
  gl_TexRect(0,0,127,127,0,1,0.5,0.5)
  gl_TexRect(127,0,127+224,127,1-224/256,1,1,0.5)
 gl_Blending(false)
  for line in string.gmatch(tooltip, "([^\n]*)\n?") do
	
    if string.len(line) >55 and string.find(line,"Metal:")==nil then
		splitnum=string.find(line, " ", 50)
		if (splitnum ~= nil) then
			splitnum=math.min(splitnum,60)
		else 
			splitnum=string.len(line)
		end
		line1=string.sub(line,0,splitnum)
		line2=string.sub(line,splitnum,string.len(line))
		if (unitTip and (i == 0)) then
			line1 = "\255\255\128\255" .. line1
		else
			line1 = "\255\255\255\255" .. line1
		end
		glText(line1, gap, gap + (4 - i) * yStep, fontSize, "")
		i = i + 1
		
	  	if (unitTip and (i == 0)) then
			line2 = "\255\255\128\255" .. line2
		else
			line2 = "\255\255\255\255" .. line2
		end
		if (splitnum~=string.len(line)) then
			glText(line2, gap, gap + (4 - i) * yStep, fontSize, "")
			i = i + 1
		end
	else
	

	if (unitTip and (i == 0)) then
      line = "\255\255\128\255" .. line
    else
      line = "\255\255\255\255" .. line
    end
	

      glText(line, gap, gap + (5 - i) * yStep, fontSize, "")
		i = i + 1
	end
    
  end
  gl_Blending(true)
  gl_Color(0.6,1,1,1)
  gl_Texture('LuaUI/Images/tooltipplus.png')
  gl_TexRect(0,0,127,127,0,0.5,0.5,0)
  gl_TexRect(127,0,127+224,127,1-224/256,0.5,1,0)


end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

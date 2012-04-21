
function widget:GetInfo()
	return {
		name      = 'Select Trim Color',
		desc      = 'Adds GUI to select trim color',
		author    = 'very_bad_soldier',
		date      = 'April 2012',
		license   = 'GNU GPL v2',
		layer     = -100,
		enabled   = true,
	}
end

--------------------------------------------------------------------------------
-- Speedups
--------------------------------------------------------------------------------
local teamList = Spring.GetTeamList()
local myTeamID = Spring.GetMyTeamID()

local glColor = gl.Color
local glShape = gl.Shape
local glRect = gl.Rect
local glDepthTest = gl.DepthTest
local glBeginEnd = gl.BeginEnd
local glPushMatrix = gl.PushMatrix
local glPopMatrix = gl.PopMatrix
local glTranslate = gl.Translate
local glBeginText = gl.BeginText
local glEndText = gl.EndText
local glText = gl.Text
local spSendLuaRulesMsg = Spring.SendLuaRulesMsg

local spGetSpectatingState = Spring.GetSpectatingState

--------------------------------------------------------------------------------
-- Configuration
--------------------------------------------------------------------------------
local colorBarAlpha = 0.8
local defaultMargin = 7
local colorBarHeight = 15
local colorBarSegWidth = 28
local colorBarMarkerWidth = 5
local satBrightMarkerWidth = 4
local captionText = "Choose Trim Color"

local fontSize = 12
local fontBoxHeight = 20
local selectorColor = { 1.0, 1.0, 0.0, 1.0 }

--------------------------------------------------------------------------------
-- Generated Values
--------------------------------------------------------------------------------
local selectedColorRectWidth = colorBarHeight
local colorBarWidthOverall = colorBarSegWidth * 3
local satBrightRectWidth = colorBarWidthOverall + selectedColorRectWidth + defaultMargin
local heightSum = satBrightRectWidth + defaultMargin + colorBarHeight + fontBoxHeight
local panelWidth = satBrightRectWidth + 2*defaultMargin
local panelHeight = heightSum + 2*defaultMargin

local colorBarY = defaultMargin + fontBoxHeight
local selectedColorBoxY = colorBarY
local satBrightBoxY = colorBarY + colorBarHeight + defaultMargin
--------------------------------------------------------------------------------
-- Runtime Variables
--------------------------------------------------------------------------------
local curHsvColor = { h = 0.5, s = 1.0, v = 1.0 }
local curRgbColor = { r = 0.0, g = 0.0, b = 0.0 }
local px, py = 300, 490
local myTeamID = nil
--
--------------------------------------------------------------------------------
-- Funcs
--------------------------------------------------------------------------------
function HSVtoRGB(h, s, v)
  local r, g, b
 
  local i = math.floor(h * 6)
  local f = h * 6 - i
  local p = v * (1 - s)
  local q = v * (1 - f * s)
  local t = v * (1 - (1 - f) * s)
 
  local switch = i % 6
  if switch == 0 then
    r = v g = t b = p
  elseif switch == 1 then
    r = q g = v b = p
  elseif switch == 2 then
    r = p g = v b = t
  elseif switch == 3 then
    r = p g = q b = v
  elseif switch == 4 then
    r = t g = p b = v
  elseif switch == 5 then
    r = v g = p b = q
  end

  return { r = r, g = g, b = b }
end

function SetNewHue(hue)
	curHsvColor.h = hue
	UpdateRgb()
end

function SetNewSatAndVal(sat, val)
	curHsvColor.s = sat
	curHsvColor.v = val
	UpdateRgb()
end

function UpdateRgb()
	curRgbColor = HSVtoRGB( curHsvColor.h, curHsvColor.s, curHsvColor.v )
end

function DrawColorPicker()
	local markerX = colorBarWidthOverall * curHsvColor.h
	-- Text
	glPushMatrix()
	glTranslate( defaultMargin, -defaultMargin, 0.0 )
    glBeginText()
    glText( captionText, 0, 0, fontSize, 'a')
	glEndText()
	glPopMatrix()
	
	--color bar
	glPushMatrix()
	glTranslate( defaultMargin, -colorBarY, 0.0 )
	glShape(GL.TRIANGLE_STRIP, {
      { v = { 0, -colorBarHeight }, 					c = { 1.0, 0.0, 0.0, colorBarAlpha } },
      { v = { 0, 0 }, 									c = { 1.0, 0.0, 0.0, colorBarAlpha } },
	  { v = { colorBarSegWidth, -colorBarHeight }, 		c = { 0.0, 1.0, 0.0, colorBarAlpha } },
	  { v = { colorBarSegWidth, 0 }, 					c = { 0.0, 1.0, 0.0, colorBarAlpha } },
	  { v = { 2 * colorBarSegWidth, -colorBarHeight }, 	c = { 0.0, 0.0, 1.0, colorBarAlpha } },
	  { v = { 2 * colorBarSegWidth, 0 }, 				c = { 0.0, 0.0, 1.0, colorBarAlpha } },
	  { v = { 3 * colorBarSegWidth, -colorBarHeight }, 	c = { 1.0, 0.0, 0.0, colorBarAlpha } },
	  { v = { 3 * colorBarSegWidth, 0 }, 				c = { 1.0, 0.0, 0.0, colorBarAlpha } },
    })
	glPopMatrix()
	
	--selected color box
	glPushMatrix()
	glTranslate( colorBarWidthOverall + 2*defaultMargin, -selectedColorBoxY, 0.0 )
	glColor( curRgbColor.r, curRgbColor.g, curRgbColor.b, 1.0 )
	glRect( 0.0, 0.0, selectedColorRectWidth, -selectedColorRectWidth )
	glPopMatrix()
	
	--hue marker
	glPushMatrix()
    glTranslate( defaultMargin + markerX,-colorBarY, 0)
	glColor( selectorColor )
	glShape(GL.TRIANGLE_STRIP, { 
	  { v = { 0, 0 } },
      { v = { 0 - colorBarMarkerWidth, colorBarMarkerWidth } },
	  { v = { 0 + colorBarMarkerWidth, colorBarMarkerWidth } },
	})
	glPopMatrix()
	
	---saturation / brightness rectangle
	glPushMatrix()
	glTranslate( defaultMargin, -satBrightBoxY, 0)
	local modColor = HSVtoRGB( curHsvColor.h, 1.0, 1.0 )
	glShape(GL.TRIANGLE_STRIP, {
      { v = { 0, 0 }, 									c = { 1.0, 1.0, 1.0, colorBarAlpha } },
      { v = { 0, -satBrightRectWidth }, 				c = { 0.0, 0.0, 0.0, colorBarAlpha } },
	  { v = { satBrightRectWidth, 0 },					c = { modColor.r, modColor.g, modColor.b, colorBarAlpha } },
	  { v = { satBrightRectWidth, -satBrightRectWidth },c = { 0.0, 0.0, 0.0, colorBarAlpha } },
    })

	--sat/bright selection marker
	glPushMatrix()
	glTranslate( satBrightRectWidth * curHsvColor.s, -satBrightRectWidth * (1.0 - curHsvColor.v), 0)
	glColor(selectorColor)
	local widthHalf = satBrightMarkerWidth / 2
	glShape(GL.LINE_LOOP, {
      { v = { 0, satBrightMarkerWidth } },
      { v = { satBrightMarkerWidth, 0 } },
	  { v = { 0, -satBrightMarkerWidth } },
	  { v = { -satBrightMarkerWidth, 0 } },
    })
	glPopMatrix()
	--
	
	glPopMatrix()
end

function MakeInts( r, g, b )
  return math.floor(r*255), math.floor(g*255), math.floor(b*255)
end

--------------------------------------------------------------------------------
-- Callins
--------------------------------------------------------------------------------
function widget:Initialize()
    if spGetSpectatingState() or
       Spring.GetGameFrame() > 0 then
        widgetHandler:RemoveWidget(self)
    end
	
	myTeamId = Spring.GetMyTeamID()
	
	UpdateRgb()
end

function widget:DrawScreen()
    -- Spectator check
    if spGetSpectatingState() then
        widgetHandler:RemoveWidget(self)
        return
    end

    -- Positioning
    glPushMatrix()
    glTranslate(px, py, 0)
	
	glColor(0, 0, 0, 0.5)
    glRect( 0, 0, panelWidth, -panelHeight )
		
	--color picker
	DrawColorPicker()
		
    glPopMatrix()
end

function ProcessMouseAction(mx, my, mButton)
    if mx < px or mx > (px + panelWidth) or my > py or my < (py - panelHeight) then
		return
	end

	-- Spectator check before any action
    if spGetSpectatingState() then
		widgetHandler:RemoveWidget(self)
        return false
    end
			
    -- Check buttons
	if ( mButton == 1 ) then
		local updated = false
		if ( mx >= (px + defaultMargin) and mx <= (px + defaultMargin + colorBarWidthOverall) and
					my <= ( py - colorBarY + colorBarMarkerWidth ) and my >= ( py - colorBarY - colorBarHeight) ) then
			SetNewHue( (mx - px - defaultMargin) / colorBarWidthOverall )
			updated = true
			--Spring.Echo("Color bar click. New hue: " .. curHsvColor.h)
		elseif ( mx >= (px + defaultMargin) and mx <= (px + defaultMargin + satBrightRectWidth) and
				my <= ( py - satBrightBoxY ) and my >= ( py - satBrightBoxY - satBrightRectWidth) ) then
			local newSat = (mx - px - defaultMargin) / satBrightRectWidth
			local newVal = 1.0 - ((py - my - satBrightBoxY) / satBrightRectWidth)
			SetNewSatAndVal( newSat, newVal )
			updated = true
			--Spring.Echo("SatBright rect click. New sat: " .. newSat .. " NewV: " .. newVal)
		end
		
		if ( updated ) then
			--send color data to luarules
			local r,g,b = MakeInts( curRgbColor.r, curRgbColor.g, curRgbColor.b )
			spSendLuaRulesMsg( "trimColor" .. "," .. r .. "," .. g .. "," .. b )
		end
	end
	
	return true
end

function widget:MousePress(mx, my, mButton)
	return ProcessMouseAction(mx, my, mButton)
end

function widget:MouseMove(mx, my, dx, dy, mButton)
    -- Dragging
    if mButton == 2 or mButton == 3 then
        px = px + dx
        py = py + dy
	elseif (mButton == 1 ) then
		ProcessMouseAction(mx, my, mButton)
    end
end

function widget:GameStart()
    widgetHandler:RemoveWidget(self)
end

function widget:GetConfigData()
	local vsx, vsy = gl.GetViewSizes()
	
	local data = {}
	data["position"] = {px / vsx, py / vsy}
	data["trimcolor"] = curHsvColor
	return data
end

function widget:SetConfigData(data)
	if ( data["position"] ~= nil ) then
		local vsx, vsy = gl.GetViewSizes()
		px = math.floor(math.max(0, vsx * math.min(data["position"][1] or 0, 0.95)))
		py = math.floor(math.max(0, vsy * math.min(data["position"][2] or 0, 0.95)))
	end
	
	if ( data["trimcolor"] ~= nil ) then
		curHsvColor = data["trimcolor"]
		UpdateRgb()
	end
end


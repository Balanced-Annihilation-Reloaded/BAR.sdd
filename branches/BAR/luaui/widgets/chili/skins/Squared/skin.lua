
local skin = {
  info = {
    name    = "Squared",
    version = "1",
    author  = "Funk",
		depend = {
      "Robocracy",
    },
  }
}


local function GetTeamColor(m,a)
	local m = m or 1
	local a = a or 1
	local teamID = Spring.GetLocalTeamID()
	local r,g,b = Spring.GetTeamColor(teamID)
	if r+g+b < 0.1 or r+g+b > 2.3 then r,g,b = 0.4,0.4,0.4 end
	return {r*m,g*m,b*m,a}
end

skin.general = {
  borderColor = {1, 1, 1, 1},
  focusColor  = GetTeamColor(1,0.5),
  draggable   = false,
  font        = {
    color        = {1,1,1,1},
    outlineColor = {0,0,0,0.9},
    outline      = false,
    shadow       = true,
    size         = 14,
  },
}

skin.panel = {
	TileImageBK = ":cl:bg.png",
	TileImageFG = ":cl:panel_fg.png",
	tiles = {62, 62, 62, 62},
	backgroundColor = GetTeamColor(0.1, 0.5),
	borderColor = GetTeamColor(1, 1),
	DrawControl = DrawPanel,
}

skin.button = {
	TileImageBK = ":cl:bg.png",
	TileImageFG = ":cl:button_fg.png",
	tiles = {26, 26, 26, 26},
	backgroundColor = {0, 0, 0, 0.5},
	borderColor = {1,1,1,0.8},
	DrawControl = DrawButton,
}

skin.tabbaritem = {
  TileImageBK = ":cl:bg.png",
  TileImageFG = ":cl:tab_fg.png",
  tiles = {32, 32, 32, 0}, --// tile widths: left,top,right,bottom
  padding = {5, 3, 3, 2},
  backgroundColor = {0, 0, 0, 0.8},

  DrawControl = DrawTabBarItem,
}

skin.window = {
  TileImage = ":c:window_fg.png",
  tiles = {62, 62, 62, 62}, --// tile widths: left,top,right,bottom
  padding = {13, 13, 13, 13},
  hitpadding = {4, 4, 4, 4},

  captionColor = {1, 1, 1, 0.45},

  boxes = {
    resize = {-21, -21, -10, -10},
    drag = {0, 0, "100%", 10},
  },

  NCHitTest = NCHitTestWithPadding,
  NCMouseDown = WindowNCMouseDown,
  NCMouseDownPostChildren = WindowNCMouseDownPostChildren,

  DrawControl = DrawWindow,
  DrawDragGrip = function() end,
  DrawResizeGrip = DrawResizeGrip,
}

skin.control = skin.general


return skin

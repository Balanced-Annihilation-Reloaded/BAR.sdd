
local skin = {
  info = {
    name    = "Robofunk",
    version = "1",
    author  = "JK,Funk",
		depend = {
      "Robocracy",
    },
  }
}



skin.general = {
  borderColor = {1, 1, 1, .8},
  focusColor  = {r, g, b, 1},
	draggable   = false,
  font        = {
    color        = {1,1,1,1},
    outlineColor = {0,0,0,0.9},
    outline      = false,
    shadow       = true,
    size         = 14,
  },
}

skin.window = {
	TileImage = ":cl:flatbk.png",
	
  tiles      = {4, 4, 4, 4},
  padding    = {14, 23, 14, 14},
  hitpadding = {10, 4, 10, 10},
  captionColor = {0, 0, 0, 0.55},

  boxes = {
    resize = {-25, -25, -14, -14},
    drag = {0, 0, "100%", 24},
  },

  NCHitTest   = NCHitTestWithPadding,
  NCMouseDown = WindowNCMouseDown,
  NCMouseDownPostChildren = WindowNCMouseDownPostChildren,

  DrawControl    = DrawWindow,
  DrawDragGrip   = DrawDragGrip,
  DrawResizeGrip = DrawResizeGrip,
}

skin.control = skin.general


return skin

--//=============================================================================
--// Skin

local skin = {
  info = {
    name    = "Flat",
    version = "v1",
    author  = "Funkencool",
  }
}

--//=============================================================================
--//
local teamID = Spring.GetLocalTeamID()
local r,g,b = Spring.GetTeamColor(teamID)
if r+g+b < 0.1 or r+g+b > 2.3 then r,g,b = 0.4,0.4,0.4 end
skin.general = {
  borderColor  = {1, 1, 1, .8},
  focusColor = {r, g, b, 1},
	draggable = false,

  font = {
    font    = "luaUI/fonts/AGENCYB.TTF",
    color        = {1,1,1,1},
    outlineColor = {0.05,0.05,0.05,0.9},
    outline = false,
    shadow  = true,
    size    = 14,
  },

  --padding         = {5, 5, 5, 5}, --// padding: left, top, right, bottom
}


skin.icons = {
  imageplaceholder = ":cl:placeholder.png",
}

skin.button = {
  TileImageBK = ":cl:glassbk.png",
  TileImageFG = ":cl:glassfg.png",
  tiles = {22, 22, 22, 22}, --// tile widths: left,top,right,bottom
  padding = {5, 5, 5, 5},
  focusColor = {r, g, b, 0.5},

  backgroundColor = {0,0,0,0.5},
  borderColor = {1,1,1,0},

  DrawControl = DrawButton,
}

skin.combobox = {
	TileImageBK = ":cl:glassbk.png",
	TileImageFG = ":cl:glassfg.png",
	TileImageArrow = ":cl:combobox_ctrl_arrow.png",
	tiles   = {22, 22, 48, 22},
	padding = {5, 5, 5, 5},
	backgroundColor = {1, 1, 1, 0.7},
	borderColor = {1,1,1,0},

	DrawControl = DrawComboBox,
}


skin.combobox_window = {
	clone     = "window";
	TileImage = ":cl:glassbk.png";
	tiles     = {10, 10, 10, 10};
	backgroundColor = {1, 1, 1, 0.7},
	padding   = {4, 3, 3, 4};
}


skin.combobox_scrollpanel = {
	clone       = "scrollpanel";
	borderColor = {1, 1, 1, 0};
	padding     = {0, 0, 0, 0};
}


skin.combobox_item = {
	clone       = "button";
	borderColor = {1, 1, 1, 0};
}


skin.checkbox = {
  TileImageFG = ":cl:tech_checkbox_checked.png",
  TileImageBK = ":cl:tech_checkbox_unchecked.png",
  tiles       = {3,3,3,3},
  boxsize     = 13,

  DrawControl = DrawCheckbox,
}

skin.editbox = {
  backgroundColor = {0.1, 0.1, 0.1, 1},
  cursorColor     = {r, g, b, 0.6},

  TileImageBK = ":cl:panel2_bg.png",
  TileImageFG = ":cl:panel2_border.png",
  tiles       = {14,14,14,14},

  DrawControl = DrawEditBox,
}

skin.imagelistview = {
  imageFolder      = "folder.png",
  imageFolderUp    = "folder_up.png",

  --DrawControl = DrawBackground,

  colorBK          = {1,1,1,0.3},
  colorBK_selected = {1,0.7,0.1,0.8},

  colorFG          = {0, 0, 0, 0},
  colorFG_selected = {1,1,1,1},

  imageBK  = ":cl:node_selected_bw.png",
  imageFG  = ":cl:node_selected.png",
  tiles    = {9, 9, 9, 9},

  DrawItemBackground = DrawItemBkGnd,
}
--[[
skin.imagelistviewitem = {
  imageFG = ":cl:glassFG.png",
  imageBK = ":cl:glassBK.png",
  tiles = {17,15,17,20},

  padding = {12, 12, 12, 12},

  DrawSelectionItemBkGnd = DrawSelectionItemBkGnd,
}
--]]

skin.panel = {
  TileImageBK = ":cl:glassbk.png",
	TileImageFG = ":cl:glassfg.png",
  tiles = {22, 22, 22, 22},

  DrawControl = DrawPanel,
}

skin.progressbar = {
  TileImageFG = ":cl:tech_progressbar_full.png",
  TileImageBK = ":cl:tech_progressbar_empty.png",
  tiles       = {10, 10, 10, 10},

  font = {
    shadow = true,
  },

  backgroundColor = {1,1,1,1},

  DrawControl = DrawProgressbar,
}

skin.scrollpanel = {
  BorderTileImage = ":cl:panel2_border.png",
  bordertiles = {14,14,14,14},

  BackgroundTileImage = ":cl:panel2_bg.png",
  bkgndtiles = {14,14,14,14},

  TileImage = ":cl:glassbk.png",
  tiles     = {7,7,7,7},
  KnobTileImage = ":cl:glassfg.png",
  KnobTiles     = {6,8,6,8},
	
  HTileImage = ":cl:glassbk.png",
  htiles     = {7,7,7,7},
  HKnobTileImage = ":cl:glassfg.png",
  HKnobTiles     = {6,8,6,8},
	KnobColor      = {r,g,b,0.5},
  KnobColorSelected = {r,g,b,0.8},

  padding = {5, 5, 5, 0},

  scrollbarSize = 11,
  DrawControl = DrawScrollPanel,
  DrawControlPostChildren = DrawScrollPanelBorder,
}

skin.trackbar = {
  TileImage = ":cn:trackbar.png",
  tiles     = {10, 14, 10, 14}, --// tile widths: left,top,right,bottom

  ThumbImage = ":cl:trackbar_thumb.png",
  StepImage  = ":cl:trackbar_step.png",

  hitpadding  = {4, 4, 5, 4},

  DrawControl = DrawTrackbar,
}

skin.treeview = {
  --ImageNode         = ":cl:node.png",
  ImageNodeSelected = ":cl:node_selected.png",
  tiles = {9, 9, 9, 9},

  ImageExpanded  = ":cl:treeview_node_expanded.png",
  ImageCollapsed = ":cl:treeview_node_collapsed.png",
  treeColor = {1,1,1,0.1},

  DrawNode = DrawTreeviewNode,
  DrawNodeTree = DrawTreeviewNodeTree,
}

skin.window = {
  TileImage = ":cl:glassbk.png",
  tiles = {62, 62, 62, 62}, --// tile widths: left,top,right,bottom
  padding = {13, 13, 13, 13},
  hitpadding = {4, 4, 4, 4},
	resizable = false,
  captionColor = {1, 1, 1, 0.45},
  color = {0, 0, 0, .6},

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

skin.line = {
  TileImage = ":cl:tech_line.png",
  tiles = {0, 0, 0, 0},
  TileImageV = ":cl:tech_line_vert.png",
  tilesV = {0, 0, 0, 0},
  DrawControl = DrawLine,
}

skin.tabbar = {
  padding = {3, 1, 1, 0},
}

skin.tabbaritem = {
  TileImageBK = ":cl:glassbk.png",
  TileImageFG = ":cl:glassfg.png",
  tiles = {10, 10, 10, 0}, --// tile widths: left,top,right,bottom
  padding = {5, 3, 3, 2},
	borderColor = {0, 0, 0, 0.8},
  focusColor = {r, g, b, 0.5},

  DrawControl = DrawTabBarItem,
}


skin.control = skin.general


--//=============================================================================
--//

return skin

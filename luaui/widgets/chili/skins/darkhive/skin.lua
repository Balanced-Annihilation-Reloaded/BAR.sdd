--//=============================================================================
--// Skin

local skin = {
  info = {
    name    = "DarkHive",
    version = "1",
    author  = "luckywaldo7, funkencool",
	
	-- this differs from ZKs
  }
}

--//=============================================================================
--//

skin.general = {
  fontOutline = false,
  fontsize    = 13,
  textColor   = {1,1,1,1},
  backgroundColor = {0.1, 0.1, 0.1, 0.7},
}


skin.icons = {
  imageplaceholder = ":cl:placeholder.png",
}

skin.button = {
  TileImageBK = ":cl:button.png",
  TileImageFG = ":cl:empty.png",
  tiles = {22, 22, 22, 22}, --// tile widths: left,top,right,bottom
  padding = {10, 10, 10, 10},

  backgroundColor = {1, 1, 1, 0.7},

  DrawControl = DrawButton,
}

skin.combobox = {
	TileImageBK = ":cl:combobox_ctrl.png",
	TileImageFG = ":cl:empty.png",
	TileImageArrow = ":cl:combobox_ctrl_arrow.png",
	tiles   = {22, 22, 22, 22},
	padding = {10, 10, 24, 10},

	backgroundColor = {1, 1, 1, 0.7},
	borderColor = {1,1,1,0},

	DrawControl = DrawComboBox,
}

skin.combobox_window = {
	clone     = "window";
	TileImage = ":cl:panel2_border.png";
	tiles     = {22, 22, 22, 22};
	padding   = {4, 3, 3, 4};
}

skin.combobox_scrollpanel = {
	clone       = "scrollpanel";
	borderColor = {1, 1, 1, 0};
	padding     = {0, 0, 0, 0};
}


skin.combobox_item = {
	clone       = "button";
	TileImageBK = ":cl:combobox_ctrl_btm.png",
	borderColor = {1, 1, 1, 0};
}

skin.checkbox = {
  TileImageFG = ":cl:checkbox_checked.png",
  TileImageBK = ":cl:checkbox_unchecked.png",
  tiles       = {3,3,3,3},
  boxsize     = 13,

  DrawControl = DrawCheckbox,
}

skin.editbox = {
  backgroundColor = {0.1, 0.1, 0.1, 0.7},
  cursorColor     = {1.0, 0.7, 0.1, 0.8},

  TileImageBK = ":cl:panel2_bg.png",
  TileImageFG = ":cl:panel2_border.png",
  tiles       = {14,14,14,14},

  DrawControl = DrawEditBox,
}

skin.imagelistview = {
  imageFolder      = "folder.png",
  imageFolderUp    = "folder_up.png",

  colorBK          = {1,1,1,0.3},
  colorBK_selected = {1,0.7,0.1,0.8},

  colorFG          = {0, 0, 0, 0},
  colorFG_selected = {1,1,1,1},

  imageBK  = ":cl:node_selected_bw.png",
  imageFG  = ":cl:node_selected.png",
  tiles    = {9, 9, 9, 9},

  --tiles = {17,15,17,20},

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
  TileImageBK = ":cl:button.png",
  TileImageFG = ":cl:empty.png",
  tiles = {22, 22, 22, 22},

  backgroundColor = {1, 1, 1, 0.6},

  DrawControl = DrawPanel,
}

skin.progressbar = {
  TileImageFG = ":cl:progressbar_full.png",
  TileImageBK = ":cl:progressbar_empty.png",
  tiles       = {10, 10, 10, 10},

  font = {
    shadow = true,
  },

  DrawControl = DrawProgressbar,
}

skin.scrollpanel = {
  BorderTileImage = ":cl:panel2_border.png",
  bordertiles = {30,14,30,14},

  BackgroundTileImage = ":cl:panel2_bg.png",
  bkgndtiles = {14,14,14,14},

  TileImage = ":cl:scrollbar.png",
  tiles     = {7,7,7,7},
  KnobTileImage = ":cl:scrollbar_knob.png",
  KnobTiles     = {6,8,6,8},

  HTileImage = ":cl:scrollbar.png",
  htiles     = {7,7,7,7},
  HKnobTileImage = ":cl:scrollbar_knob.png",
  HKnobTiles     = {6,8,6,8},

  KnobColorSelected = {1,0.7,0.1,0.8},

  scrollbarSize = 11,
  DrawControl = DrawScrollPanel,
  DrawControlPostChildren = DrawScrollPanelBorder,
}

skin.trackbar = {
  TileImage = ":cl:trackbar.png",
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
  TileImage = ":cl:window.png",
  tiles = {30, 30, 30, 30}, --// tile widths: left,top,right,bottom
  padding = {5, 5, 5, 5},
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

skin.tabbaritem = {
  TileImageBK = ":cl:tabbaritem.png",
  TileImageFG = ":cl:empty.png",
  tiles = {30, 30, 30, 0}, --// tile widths: left,top,right,bottom
  padding = {5, 3, 3, 2},
  backgroundColor = {1, 1, 1, 1.0},

  DrawControl = DrawTabBarItem,
}

skin.control = skin.general


--//=============================================================================
--//

return skin

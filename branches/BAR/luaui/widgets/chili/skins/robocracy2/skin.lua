
local skin = {
  info = {
    name    = "Robocracy Alternate 1",
    version = "162",
    author  = "JK,Funk",
		depend = {
      "Robocracy",
    },
  }
}


local function GetTeamColor()
	local teamID = Spring.GetLocalTeamID()
	local r,g,b = Spring.GetTeamColor(teamID)
	if r+g+b < 0.1 or r+g+b > 2.3 then r,g,b = 0.4,0.4,0.4 end
	return {r,g,b,1}
end

skin.general = {
  borderColor = {1, 1, 1, 1},
  focusColor  = GetTeamColor(),
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
	TileImageBK = ":cl:tech_window.png",
	TileImageFG = ":cl:empty.png",
	tiles = {62, 62, 62, 62},
	backgroundColor = {1, 1, 1, 1},
	DrawControl = DrawPanel,
}

skin.control = skin.general


return skin

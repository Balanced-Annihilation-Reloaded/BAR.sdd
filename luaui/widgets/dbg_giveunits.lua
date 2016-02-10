function widget:GetInfo()
   return {
      name      = "Give units, givecore, givearm",
      desc      = "use /luaui givecore, /luaui givearm and /luaui givefeatures",
      author    = "Beherith",
      version   = "v1.0",
      date      = "2013",
      license   = "GNU GPL, v3 or later",
      layer     = 200,
      enabled   = false,
   }
end
   
   
function widget:TextCommand(command)
	--Spring.Echo(command)
	if (string.find(command, "givearm") == 1) then GiveStuff("Arm") end
	if (string.find(command, "givecore") == 1) then GiveStuff("Core") end
	if (string.find(command, "givefeatures") == 1) then GiveFeatures() end
end

function GiveStuff(key)
  -- Spring.SendCommands({"say .cheat 1"}) -- enable cheating
  --reserve a 
  local cnt=0
  local mx, my= Spring.GetMouseState()
  local at, pos=Spring.TraceScreenRay(mx,my,true,false)
  Spring.Echo(at)
  if at ~= "ground" then return end
  
  cx,cy,cz = Spring.GetCameraPosition()
  local x=0
  local y=0
  local spacing=128
	for udid,ud in pairs(UnitDefs) do
		if (ud.customParams) and ud.customParams["normaltex"] then
			Spring.Echo(ud.customParams["normaltex"], string.find(ud.customParams["normaltex"],key ) )
			if (string.find(ud.customParams["normaltex"],key ) ) then
				--Spring.SetCameraTarget(pos[1]+x, pos[2], pos[3]+y)
				x=x+spacing
				if x> 10*spacing then
					x=0
					y=y+spacing
				end
				cmd="give 1 " .. ud.name .. " 0 @"..math.floor(pos[1])+x .. "," ..  math.floor(pos[2]) ..",".. math.floor( pos[3]+y ) 
				Spring.Echo(cmd)
				Spring.SendCommands({cmd})
			end
		end
	end 
end
function GiveFeatures()
  -- Spring.SendCommands({"say .cheat 1"}) -- enable cheating

  local cnt=0
  local mx, my= Spring.GetMouseState()
  local at, pos=Spring.TraceScreenRay(mx,my,true,false)
  Spring.Echo(at)
  if at ~= "ground" then return end
  
  cx,cy,cz = Spring.GetCameraPosition()
  local x=0
  local y=0
  local spacing=128
	for id,featureDef in pairs(FeatureDefs) do
		x=x+spacing
		if x> 10*spacing then
			x=0
			y=y+spacing
		end
		cmd="give 1 " .. featureDef.name .. " 0 @"..math.floor(pos[1])+x .. "," ..  math.floor(pos[2]) ..",".. math.floor( pos[3]+y ) 
		Spring.Echo(cmd)
		Spring.SendCommands({cmd})
	end
end
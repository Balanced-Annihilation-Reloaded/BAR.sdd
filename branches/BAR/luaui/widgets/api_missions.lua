function widget:GetInfo()
  return {
    name      = "Mission Framework",
    desc      = "Configures BAR appropriately when a mission is run\nDisplays the missions GUI",
    author    = "Bluestone",
    license   = "GPLv3",
    version   = "1.0",
    layer     = math.huge, --run after _everything_ else
    enabled   = true,  
    handler   = true,
    hidden    = true,
  }
end

--[[ 
    NOTES
        
    Missions have their own spawn/end behaviour and are single player only
    The mission communicates with the missions GUI by calling functions exposed to WG
    
    
]]

local isMission = false

local to_unload = {
    ["Player List"]=true, 
    ["Com Counter"]=true,
    ["Chat Console"]=true,
    ["Initial Queue"]=true,
    ["Faction Change"]=true,
    ["Ready Button"]=true,
    ["End Graph"]=true,
    ["Awards"]=true,
    ["Center n Select"]=true,
    ["Game Type Info"]=true,
    ["Ally Selected Units"]=true,
}


local to_reload = {}
local Chili

function widget:SetConfigData(data)
    to_reload = data
end

function widget:Initialize()
    -- reload any widgets that were disabled because the previous game was a mission
    if not isMission then 
        for name,_ in pairs(to_reload) do
            if widgetHandler.knownWidgets[name] and not widgetHandler.knownWidgets[name].active then
                widgetHandler:ToggleWidget(name)   
            end
        end
        
        widgetHandler:RemoveWidget()
        return
    end
    
    Chili = WG.Chili

    -- if this game is a mission, unload unwanted widgets
    for name,w in pairs(widgetHandler.knownWidgets) do
        if to_unload[name] and w.active then 
            Spring.Echo("Missions: Removing " .. name)
            widgetHandler:ToggleWidget(name)   
            to_reload[name] = true
        end   
    end
    
    -- hide (engine) console, unless its $VERSION in which case assume we are developing and show it
    if not string.find(Game.gameVersion, "VERSION") then
        Spring.SendCommands('console 0')
    end
    
    -- missions GUI
    CreateMissionGUI()
end

function widget:ShutDown ()
	Spring.SendCommands('console 1')
	Spring.SetConfigString('InputTextGeo', '0.26 0.73 0.02 0.028') --default pos
end

function widget:GetConfigData()
    return to_reload
end

------------------------------------

function CreateMissionGUI()

    window = Chili.Panel:New{
        parent = Chili.Screen0,
		right  = 450+50,
        y      = 0,
		width  = 525,
        minHeight = 25,
		autosize = true,
    }
    
    master_panel = Chili.LayoutPanel:New{
        parent = window,
        width = '100%',
		resizeItems = false,
        autosize = true,
        minHeight = 25,
		padding     = {0,0,0,0},
		itemPadding = {0,0,0,0},
		itemMargin  = {0,0,0,0},
        orientation = 'vertical',
    }   




end



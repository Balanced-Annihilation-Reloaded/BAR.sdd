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

    -- if this game is a mission, unload unwanted widgets
    for name,w in pairs(widgetHandler.knownWidgets) do
        if to_unload[name] and w.active then 
            Spring.Echo("Missions: Removing " .. name)
            widgetHandler:ToggleWidget(name)   
            to_reload[name] = true
        end   
    end
    
    -- hide console
    
    -- missions GUI
end

function widget:GetConfigData()
    return to_reload
end


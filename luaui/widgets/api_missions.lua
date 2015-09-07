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
    api       = true,
  }
end

--[[ 
    NOTES
    
    Missions have their own spawn/end behaviour and are single player only.
    The mission gives instructions/data to this GUI via WG.
    
    Missions announce their existence by setting WG.isMission==true
    Some mission editors don't allow to set values in WG until GamePreload. 
    Also, we don't want to include this API inside the missions themselves, because then only BAR devs could make/update missions.
    So, we have to remove widgets that aren't wanted during missions here, in GamePreload.
    This means we also have to use this widget to re-instate them, next time we run and its not a mission.
    
]]

local isMission --= true

local to_unload = {
    --["Player List"]=true, 
    ["Com Counter"]=true,
    ["Chat Console"]=true,
    ["Initial Queue"]=true,
    ["Faction Change"]=true,
    ["Ready Button"]=true,
    ["Game End Graphs"]=true,
    ["Awards"]=true,
    ["Center n Select"]=true,
    ["Game Type Info"]=true,
    ["Ally Selected Units"]=true,
    ["Open Host List"]=true,
    ["Ally Resource Stats"]=true,
    ["AutoQuit"]=true,
}


local to_reload = {}

local Chili
local loadedGUI = false

function widget:SetConfigData(data)
    to_reload = data
end

function widget:Initialize()
    Chili = WG.Chili
end

function widget:GamePreload()
    isMission = isMission or WG.isMission
    if isMission then
        Spring.Echo("Missions: Activated")
    end
    
    -- reload any widgets that were disabled because the previous game was a mission
    if not isMission then 
        for name,_ in pairs(to_reload) do
            if widgetHandler.knownWidgets[name] and not widgetHandler.knownWidgets[name].active then
                widgetHandler:ToggleWidget(name)   
            end
        end

        to_reload = {}
        
        widgetHandler:RemoveWidget(self)
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
    
    -- hide (engine) console, unless its $VERSION in which case assume we are developing and show it
    if not string.find(Game.gameVersion, "VERSION") then
        Spring.SendCommands('console 0')
    end
    Spring.SendCommands('endgraph 0')
    
    -- missions GUI
    CreateMissionGUI()
    loadedGUI = true
end

--testing only - load the GUI on luaui reload if isMission has been forced true
function widget:GameFrame()
    if not loadedGUI and isMission and Spring.GetGameFrame()>0 then --for testing only
        CreateMissionGUI()
        loadedGUI = true    
    end
end

function widget:GameOver(winningAllyTeams)
    local won = false
    local myAllyTeamID = Spring.GetMyAllyTeamID()
    for _,tID in pairs(winningAllyTeams) do
        if myAllyTeamID==tID then
            won = true
            break
        end        
    end
    
    if won then  -- TODO: offer restart button?
        NewMissionObjective("Mission complete. Good work!")
    else
        NewMissionObjective("Mission failed. Better luck next time!")
    end
    
end


function widget:Shutdown ()
    if isMission then
        -- for debugging, in case this widget crashes
        Spring.SendCommands('console 1')
        Spring.SetConfigString('InputTextGeo', '0.26 0.73 0.02 0.028') 
    end
    
    Spring.SendCommands('endgraph 1')
end

function widget:GetConfigData()
    return to_reload
end

------------------------------------

local turquoise = "\255\0\240\180"
local red = "\255\255\20\20"
local green = "\255\0\255\0"
local white = "\255\255\255\255"
local blue = "\255\170\170\255"
local grey = "\255\190\190\190"

function NewMissionObjective(objective)
    mission_objective_text:SetText(objective)
    --Spring.PlaySoundStream('sounds/missions/NewObjective.wav') 
    if mission_objective.hidden then
        mission_objective:Show()
    end
    -- TODO: flashing indicator or something
end

function CreateMissionGUI()

    window = Chili.Panel:New{
        parent = Chili.Screen0,
        right  = 450+50,
        y      = 0,
        width  = 525,
        minHeight = 25,
        autosize = true,
    }
    
    mission_name_window = Chili.Panel:New{
        parent = window,
        width = 525,
        autosize = false,
        height = 35,
        padding     = {0,0,0,0},
        itemPadding = {2,2,2,2},
        itemMargin  = {0,0,0,0},
    }   
        
    mission_name_text = Chili.TextBox:New{
        parent = mission_name_window,
        width = '100%',
        height = 30,
        y = 10,
        x = 10,
        text = white .. "Mission:  " .. green .. (WG.MissionName or "Test Mission"),  
        font = {
            size = 16,
        }
    }

    mission_objective = Chili.LayoutPanel:New{
        parent = window,
        width = '100%',
        autosize = true,
        height = 100,
        y = 35,
        padding     = {5,5,5,5},
        itemPadding = {2,2,2,2},
        itemMargin  = {0,0,0,0},
    }   
    
    mission_objective_text = Chili.TextBox:New{
        parent = mission_objective,
        width = '100%',
        height = 1,
        text = blue .. (WG.MissionObjective or "Test Mission Objective. Go forth and multiply! Type extra text so you get to see what happens with a linebreak."),  
        font = {
            outline          = true,
            autoOutlineColor = true,
            outlineWidth     = 3,
            outlineWeight    = 8,
            size             = 15,        
        }
    }
    
    local function ShowHide()
        if mission_objective.hidden then
            showhide_button:SetCaption(grey .. "hide")
            mission_objective:Show()
            window:Invalidate()
        else
            showhide_button:SetCaption(grey .. "show")
            mission_objective:Hide()
            window:Invalidate()
        end
    
    end

    showhide_button = Chili.Button:New{
        parent = mission_name_window,
        y = 0,
        right = 0,
        height = 33,
        width = 70,
        caption = grey .. "hide",
        onclick = {ShowHide},
    }

    --[[
    -- TODO
    mission_menu_button = Chili.Button:New{
        parent = mission_nam_window;
        y = 0;
        right = 70,
        height = 33,
        width = 50,
        caption = grey .. "menu",
        onclick = {function() WG.MainMenu.ShowHide("Beta Release") end},   
    }
    ]]

    WG.NewMissionObjective = NewMissionObjective -- make it callable by the mission
    
end








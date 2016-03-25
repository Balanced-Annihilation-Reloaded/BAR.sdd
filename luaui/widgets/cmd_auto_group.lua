
function widget:GetInfo()
  return {
    name      = "Auto Group",
    desc      = "Alt+[0-9] sets autogroup for selected unit type(s)\nAlt+\~ deletes autogroup for selected unit type(s) \nNewly built units get added to group equal to their autogroup number",
    author    = "Licho, CarRepairer, very_bad_solider",
    date      = "Mar 23, 2007",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

include("keysym.h.lua")

local finiGroup = {}
local unit2group = {}
local selUnitDefs = {}
local createdFrame = {}

local myTeam = Spring.GetMyTeamID()

local verboseMode = true

-- options & defaults
local options = {
    loadGroups = false,
    addAll = false,
    groups = {},
}

--[[
local helpText = {
    'Alt+0-9 sets autogroup# for selected unit type(s). Newly built units get added to group# equal to their autogroup#.',
    'Alt+\~ deletes autogrouping for selected unit type(s).',
    'Ctrl+~ removes nearest selected unit from its group and selects it. ',
    --'Extra function: Ctrl+q picks single nearest unit from current selection.',
}]]
        

-- speedups
local SetUnitGroup         = Spring.SetUnitGroup
local GetSelectedUnits     = Spring.GetSelectedUnits
local GetUnitDefID         = Spring.GetUnitDefID
local Echo                 = Spring.Echo
local GetAllUnits          = Spring.GetAllUnits
local GetUnitHealth        = Spring.GetUnitHealth
local GetMouseState        = Spring.GetMouseState
local GetUnitTeam          = Spring.GetUnitTeam
local SelectUnitArray      = Spring.SelectUnitArray
local TraceScreenRay       = Spring.TraceScreenRay
local GetUnitPosition      = Spring.GetUnitPosition
local UDefTab              = UnitDefs


function widget:Initialize() 
    local Chili = WG.Chili
    local Menu = WG.MainMenu
    Menu.AddWidgetOption{
        name = widget:GetInfo().name,
        children = {
            Chili.Checkbox:New{caption='Save groups between games',x='0%',width='100%',checked=options.loadGroups,
                OnChange={function() 
                        loadGroups = not loadGroups
                    end
                }
            }, 
            Chili.Checkbox:New{caption='Auto-add pre-existing units',x='0%',width='100%',checked=options.addAll,
                OnChange={function() 
                        addAll = not addAll
                    end
                }
            },
        }        
    }
  
end

function widget:PlayerChanged()
    myTeam = Spring.GetMyTeamID()
end

function widget:UnitFinished(unitID, unitDefID, unitTeam)
  if (unitTeam == myTeam and unitID ~= nil) then
    if (createdFrame[unitID] == Spring.GetGameFrame()) then
        local gr = unit2group[unitDefID]
        if gr ~= nil then SetUnitGroup(unitID, gr) end
    else 
        finiGroup[unitID] = 1
    end
  end
end



function widget:UnitCreated(unitID, unitDefID, unitTeam, builderID) 
    if (unitTeam == myTeam) then
        createdFrame[unitID] = Spring.GetGameFrame()
    end
end


function widget:UnitDestroyed(unitID, unitDefID, teamID)
  finiGroup[unitID] = nil
  createdFrame[unitID] = nil
end

function widget:UnitGiven(unitID, unitDefID, newTeamID, teamID)
  if (newTeamID == myTeam) then
    local gr = unit2group[unitDefID]
    if gr ~= nil then SetUnitGroup(unitID, gr) end
  end
  createdFrame[unitID] = nil
  finiGroup[unitID] = nil
end


function widget:UnitTaken(unitID, unitDefID, oldTeamID, teamID)
  if (teamID == myTeam) then
    local gr = unit2group[unitDefID]
    if gr ~= nil then SetUnitGroup(unitID, gr) end
  end
  createdFrame[unitID] = nil
  finiGroup[unitID] = nil
end


function widget:UnitIdle(unitID, unitDefID, unitTeam) 
  if (unitTeam == myTeam and finiGroup[unitID]~=nil) then
    local gr = unit2group[unitDefID]
    if gr ~= nil then SetUnitGroup(unitID, gr) end
    finiGroup[unitID] = nil
  end
end


function widget:KeyPress(key, modifier, isRepeat)
    if ( modifier.alt and not modifier.meta ) then
        local gr
        if (key == KEYSYMS.N_0) then gr = 0 end
        if (key == KEYSYMS.N_1) then gr = 1 end
        if (key == KEYSYMS.N_2) then gr = 2 end 
        if (key == KEYSYMS.N_3) then gr = 3 end
        if (key == KEYSYMS.N_4) then gr = 4 end
        if (key == KEYSYMS.N_5) then gr = 5 end
        if (key == KEYSYMS.N_6) then gr = 6 end
        if (key == KEYSYMS.N_7) then gr = 7 end
        if (key == KEYSYMS.N_8) then gr = 8 end
        if (key == KEYSYMS.N_9) then gr = 9 end
         if (key == KEYSYMS.BACKQUOTE) then gr = -1 end
        if (gr ~= nil) then
                if (gr == -1) then gr = nil end
                selUnitDefIDs = {}
                local exec = false --set to true when there is at least one unit to process
                for _, uid in ipairs(GetSelectedUnits()) do
                    local udid = GetUnitDefID(uid)
                    if ( not UDefTab[udid]["isFactory"] and not UDefTab[udid]["isBuilding"] ) then
                        selUnitDefIDs[udid] = true
                        unit2group[udid] = gr
                        exec = true
                    end
                end
                
                if ( exec == false ) then
                    return false --nothing to do
                end
                
                for udid,_ in pairs(selUnitDefIDs) do
                    if verboseMode then
                        if gr then
                            Echo('Added '..  UnitDefs[udid].humanName ..' to autogroup #'.. gr ..'.')
                        else
                            Echo('Removed '..  UnitDefs[udid].humanName ..' from autogroups.')
                        end
                    end
                end
                    
                if options.addAll then
                    local allUnits = GetAllUnits()
                    for _, unitID in pairs(allUnits) do
                        local unitTeam = GetUnitTeam(unitID)
                        if unitTeam == myTeam then
                            local curUnitDefID = GetUnitDefID(unitID)
                            if selUnitDefIDs[curUnitDefID] then
                                if gr         then
                                    local _, _, _, _, buildProgress = GetUnitHealth(unitID)
                                    if buildProgress == 1 then
                                        SetUnitGroup(unitID, gr)
                                        SelectUnitArray({unitID}, true)
                                    end
                                else
                                    SetUnitGroup(unitID, -1)
                                end
                            end
                        end
                    end
                end
                
                return true     --key was processed by widget
            end
    elseif (modifier.ctrl and not modifier.meta) then    
        if (key == KEYSYMS.BACKQUOTE) then
          local mx,my = GetMouseState()
          local _,pos = TraceScreenRay(mx,my,true)     
          local mindist = math.huge
          local muid = nil
          if (pos == nil) then return end
          for _, uid in ipairs(GetSelectedUnits()) do  
            local x,_,z = GetUnitPosition(uid)
            dist = (pos[1]-x)*(pos[1]-x) + (pos[3]-z)*(pos[3]-z)
            if (dist < mindist) then
              mindist = dist
              muid = uid
            end
                end
          if (muid ~= nil) then
          
            SetUnitGroup(muid,-1)
            SelectUnitArray({muid})
          end
        end
        --[[
        if (key == KEYSYMS.Q) then
          for _, uid in ipairs(GetSelectedUnits()) do  
            SetUnitGroup(uid,-1)
          end
        end
        --]]
    end
    
    return false
end


function widget:GetConfigData()
  local groups = {}
  for id, gr in pairs(unit2group) do 
    table.insert(groups, {UnitDefs[id].name, gr})
  end 
  options.groups = groups 
  return options
end
    
function widget:SetConfigData(data)
    if not (data and type(data) == 'table') then
        return
    end

    options = data
    
    local groupData = data.groups
    if options.loadGroups and groupData and type(groupData) == 'table' then
        for _, nam in ipairs(groupData) do
          if type(nam) == 'table' then
              local gr = UnitDefNames[nam[1]]
              if (gr ~= nil) then
                unit2group[gr.id] = nam[2]
              end
          end
        end
    end    
end


--------------------------------------------------------------------------------

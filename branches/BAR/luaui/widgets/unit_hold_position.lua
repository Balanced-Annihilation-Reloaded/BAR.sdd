function widget:GetInfo()
  return {
    name      = "Hold Position",
    desc      = "Sets the move state of newly built units to hold position",
    author    = "Bluestone", -- based on earlier widgets by quantum and MastaAli
    date      = "",
    license   = "If you use this widget, and you buy a horse, I own that horse",
    layer     = 0,
    enabled   = true
  }
end

local spec,_ = Spring.GetSpectatingState()
function widget:PlayerChanged()
  spec,_ = Spring.GetSpectatingState()
  if spec then
    Spring.Echo("MOOOO")
    widgetHandler:RemoveWidget()
  end
end



local factoryHoldPos = false

function widget:Initialize()
    local Chili = WG.Chili
    local Menu = WG.MainMenu
  
    Menu.AddWidgetOption{
        title = 'Hold Position',
        name = widget:GetInfo().name,
        children = {
            Chili.ComboBox:New{
                x        = '10%',
                width    = '80%',
                items    = {"Auto units (arty, aa, etc)", "All factories except air"},
                selected = options.factoryHoldPos and 2 or 1,
                OnSelect = {
                    function(_,sel)
                        if sel == 1 then
                            factoryHoldPos = false
                        else
                            factoryHoldPos = true
                        end
                    end
                }
            },
        }
    }    

end



local holdPosUnitArray = {
  -- coms
  "armcom","corcom",
  -- aa 
  "armjeth","armaak","corcrash","coraak",
  "armsam","armyork","cormist","corsent",
  "armah","corah","armmls","cormls","armaas","corarch",
  -- arty
  "tawf013","armham","corwolv",
  "armmart","armmerl","cormart","corvroc","trem","armsnipe","corhrk",
  "armraven","armshock",
  -- random ships
  "armmh","cormh","armroy","corroy","tawf009","corssub",
  "armmship","cormship","armbats","corbats","aseadragon","corblackhy",
  -- skirmish support
  "armjanus","armrock","corstorm", 
  "tawf114","armmanni","cormort",
  -- scouts
  "armflea","armfav","corfav","armspy",
  "armpt","corpt",
  -- shields/jammers/radars
  "armaser","armjam","armjamt","armsjam","coreter","corspec","corsjam",
  "armseer","armmark","corvrad","corvoyr",
  -- antinukes
  "armscab","cormabm","armcarry","corcarry",  
}
local holdPosUnits = {}
for _,unitName in pairs(holdPosUnitArray) do
    local unitDefID = UnitDefNames[unitName].id
    holdPosUnits[unitDefID] = true
end

local holdPosFacArray = {
  -- all facs except air
  "corlab","armlab","corvp","armvp","corsy","armsy","corhp","armhp",
  "coralab","armalab","coravp","armavp","corasy","armasy",
  "corgant","armshltx",
}
local holdPosFacs = {}
for _,unitName in pairs(holdPosFacArray) do
    local unitDefID = UnitDefNames[unitName].id
    holdPosFacs[unitDefID] = true
end



function widget:UnitCreated(unitID, unitDefID, unitTeam)
  -- units
  if unitTeam == Spring.GetMyTeamID() and holdPosUnits[unitDefID] then
    Spring.GiveOrderToUnit(unitID, CMD.MOVE_STATE, { 0 }, {})
  end
  
  -- facs
  if factoryHoldPos and unitTeam == Spring.GetMyTeamID() and holdPosFacs[unitDefID] then
    Spring.Echo("f",unitID)
    Spring.GiveOrderToUnit(unitID, CMD.MOVE_STATE, { 0 }, {})
  end
end



function widget:GetConfigData()
    options.factoryHoldPos = factoryHoldPos
    return options
end

function widget:SetConfigData(data)
    if data then
        options = data
    end
end




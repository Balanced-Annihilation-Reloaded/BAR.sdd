-------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Factory Bar", 
    desc      = "Always displays a build menu for factories",
    author    = "CarRepairer, jK, Bluestone",
    date      = "2010+",
    license   = "GNU GPL, v2 or later",
    layer     = 1001,
    enabled   = true,
  }
end


WhiteStr   = "\255\255\255\255"
GreyStr    = "\255\210\210\210"
GreenStr   = "\255\092\255\092"

local buttonColour, queueColor 
local progColor = {0,0.9,0.2,0.7}

local window_facbar, stack_main, label_main
local imageDir = 'luaui/images/buildIcons/'


local options = {
    maxVisibleBuilds = 6,    
    maxFacs = 8,
    
    buttonSize = 50,
}


-- list and interface vars
local facs = {} -- table of our factories

local waypointFac = -1
local waypointMode = 0   -- 0 = off; 1=lazy; 2=greedy (greedy means: you have to left click once before leaving waypoint mode and you can have units selected)

local myTeamID = 0

local r,g,b = Spring.GetTeamColor(Spring.GetMyTeamID())
local teamColor = {r,g,b}

local spGetUnitDefID       = Spring.GetUnitDefID
local spGetUnitHealth      = Spring.GetUnitHealth
local spGetUnitStates      = Spring.GetUnitStates
local spDrawUnitCommands   = Spring.DrawUnitCommands
local spGetSelectedUnits   = Spring.GetSelectedUnits
local spGetFullBuildQueue  = Spring.GetFullBuildQueue
local spGetUnitIsBuilding  = Spring.GetUnitIsBuilding
local spValidUnitID        = Spring.ValidUnitID
local spGetSpectatingState = Spring.GetSpectatingState

-------------------------------------------------------------------------------           
-- buttons

local function AddFacButton(unitID, unitDefID) --fixme, facsPos need to be uniq, but if facs are destroyed it won't be pos in facs anymore!
    -- add the button for this factory
    local facButton = Chili.Button:New{
            caption = "",
            width = options.buttonSize*1.2,
            height = options.buttonSize*1.0,
            tooltip =             'Click - '             .. GreenStr .. 'Select factory / Build unit \n'                     
                .. WhiteStr ..     'Middle click - '     .. GreenStr .. 'Go to \n'
                .. WhiteStr ..     'Right click - '     .. GreenStr .. 'Quick Rallypoint Mode' 
                ,
            backgroundColor = buttonColour,
            
            OnClick = {
                function(_,_,_,button)
                    if button == 2 then
                        local x,y,z = Spring.GetUnitPosition(unitID)
                        Spring.SetCameraTarget(x,y,z)
                    elseif button == 3 then
                        Spring.Echo("FactoryBar: Entered rallypoint mode")
                        waypointMode = 2 -- greedy mode
                        waypointFac  = unitID
                    else
                        Spring.SelectUnitArray({unitID})
                        window_facbar:Hide()
                    end
                end
            },
            OnMouseOver = {
                function() WG.FacBar.mouseOverUnitDefID = unitDefID end
            },
            OnMouseOut = {
                function() WG.FacBar.mouseOverUnitDefID = nil end            
            },
            padding={3, 3, 3, 3},
            --margin={0, 0, 0, 0},
            children = {
                Chili.Progressbar:New{
                    value = 0.0,
                    name    = 'prog';
                    max     = 1;
                    color           = progColor,
                    backgroundColor = {1,1,1,  0.01},
                    x=2, bottom=2, height=3, right=2,
                },
                Chili.Image:New {
                    file = '#'..unitDefID,
                    flip = false,
                    keepAspect = false;
                    width = '100%',
                    height = '100%',
                    children = {
                        Chili.Image:New{
                            color  = teamColor,
                            keepAspect = false;
                            height = '100%', width = '100%',
                            file   = imageDir..'Overlays/'..UnitDefs[unitDefID].name..'.dds',
                        },
                    },
                }                
            },
        }

    local qStack = Chili.StackPanel:New{
        name = unitID .. '_q',
        itemMargin={0,0,0,0},
        itemPadding={0,0,0,0},
        padding={0,0,0,0},
        --margin={0, 0, 0, 0},
        x=0,
        width=700,
        height = options.buttonSize,
        resizeItems = false,
        orientation = 'horizontal',
        centerItems = false,
    }
    
    local facStack = Chili.StackPanel:New{
        name = unitID .. "_fac",
        itemMargin={0,0,0,0},
        itemPadding={0,0,0,0},
        padding={0,0,0,0},
        --margin={0, 0, 0, 0},
        width=800,
        height = options.buttonSize,
        resizeItems = false,
        orientation = 'horizontal',
        centerItems = false,
    }
    
    facStack:AddChild(facButton)
    facStack:AddChild(qStack)
    stack_main:AddChild(facStack)
    return facStack, facButton, qStack
end

local function AddBuildButton(unitDefID, facID)

    local ud = UnitDefs[unitDefID]
  
    return
        Chili.Button:New{
            name = unitDefID,
            x=0,
            caption="",
            width = options.buttonSize,
            height = options.buttonSize,
            padding = {4, 4, 4, 4},
            --margin={0, 0, 0, 0},
            backgroundColor = queueColor,
            OnClick = {
                function(_,_,_,button)
                    local alt, ctrl, meta, shift = Spring.GetModKeyState()
                    local rb = button == 3
                    local lb = button == 1
                    if not (lb or rb) then return end
                    
                    local opt = {}
                    if alt   then table.insert(opt,"alt")   end
                    if ctrl  then table.insert(opt,"ctrl")  end
                    if meta  then table.insert(opt,"meta")  end
                    if shift then table.insert(opt,"shift") end
                    
                    if rb then
                        table.insert(opt,"right")
                    end
                    
                    Spring.GiveOrderToUnit(facID, -(unitDefID), {}, opt)
                end
            },
            OnMouseOver = {
                function() WG.FacBar.mouseOverUnitDefID = unitDefID end
            },
            OnMouseOut = {
                function() WG.FacBar.mouseOverUnitDefID = nil end            
            },
            children = {
                Chili.Label:New {
                    name='count',
                    autosize=false,
                    width="90%",
                    height="100%",
                    align="right",
                    valign="top",
                    caption = "",
                    fontSize = 14,
                    fontShadow = true,
                },

                Chili.Progressbar:New{
                    value = 0.0,
                    name    = 'prog';
                    max     = 1;
                    color           = progColor,
                    backgroundColor = {1,1,1,  0.01},
                    x=2, bottom=2, height=3, right=2,
                },
                        
                Chili.Image:New {
                    name = 'bp',
                    --file = "#"..unitDefID,
                    file = '#'..unitDefID,
                    keepAspect = false;
                    flip   = false,
                    width = '100%', height = '80%', y = '5%',
                    children = {
                        Chili.Image:New{
                            color  = teamColor,
                            height = '100%', width = '100%',
                            keepAspect = false;
                            file   = imageDir..'Overlays/'..UnitDefs[unitDefID].name..'.dds',
                        },
                    },
                },
            },
        }
    
end

-------------------------------------------------------------------------------
-- bookkeeping

function Cost(uDID)
    return 60*UnitDefs[uDID].metalCost + UnitDefs[uDID].energyCost
end
function CostComparator(i,j)
    return Cost(i) < Cost(j)
end

function AddFactory(unitID, unitDefID)
    -- add factory to facs, set up its chili controls
    local buildOptions =  UnitDefs[unitDefID] and UnitDefs[unitDefID].buildOptions or {}
    if buildOptions and #buildOptions > 0 then    
      table.sort(buildOptions, CostComparator)
    end    

    local facInfo = {unitID=unitID, unitDefID=unitDefID}
    facInfo.buildOptions = buildOptions
    
    local _,_,_,_,progress = spGetUnitHealth(facInfo.unitID)
    facInfo.built = (progress==1)
    
    local facStack, facButton, qStack = AddFacButton(unitID, unitDefID)
    facInfo.facStack = facStack
    facInfo.facButton = facButton -- the facs own button
    facInfo.qStack    = qStack -- currently displayed build buttons
    facInfo.qStore    = {} -- all build buttons, indexed by unitDefID
    
    local buildOptions = UnitDefs[unitDefID].buildOptions
    for j,buildDefID in ipairs(buildOptions) do
        facInfo.qStore[buildDefID] = AddBuildButton(buildDefID, unitID)
    end
    
    table.insert(facs, facInfo)    
    if #facs>0 and not label_main.visible then label_main:Show() end
end

function RemoveFactory(unitID)
    for i,facInfo in ipairs(facs) do
        if unitID==facInfo.unitID then
            -- destroy its chili controls
            stack_main:RemoveChild(facInfo.facStack)        
            -- and remove
            table.remove(facs,i)
            return
        end
    end
    if #facs==0 and label_main.visible then label_main:Hide() end
end

function RecreateFacs()
    -- recreate facs table from scratch
    facs = {}

    local teamUnits = Spring.GetTeamUnits(myTeamID)
    local totalUnits = #teamUnits

    for num = 1, totalUnits do
        local unitID = teamUnits[num]
        local unitDefID = spGetUnitDefID(unitID)
        if UnitDefs[unitDefID].isFactory then
            AddFactory(unitID, unitDefID)
        end
    end

    if #facs>0 and not label_main.visible then label_main:Show() 
    elseif label_main.visible then label_main:Hide() end
end

function UpdateFacProgressBars(facInfo)
    -- update build progress of the factory, if its still being built
    if not facInfo.built then
        local _,_,_,_,progress = spGetUnitHealth(facInfo.unitID)
        local fBar = facInfo.facButton:GetChildByName('prog')
        fBar:SetValue(progress)
    end
    

    -- update the build progress bars
    local progress = 0
    local unitBuildID = spGetUnitIsBuilding(facInfo.unitID) -- unit being built by this factory
    local unitBuildDefID
    if unitBuildID then
        unitBuildDefID = spGetUnitDefID(unitBuildID)
        _,_,_,_,progress = spGetUnitHealth(unitBuildID)
    end
    if not unitBuildID or not unitBuildDefID then return end    
    local qButton = facInfo.qStore[unitBuildDefID]
    local qBar = qButton:GetChildByName('prog')
    qBar:SetValue(progress)
end

function UpdateFacBuildCounts(facInfo)
    -- update factory build counts, hide buildDefIDs with 0 in queue
    local unitID = facInfo.unitID
    local buildQueue = spGetFullBuildQueue(unitID)
    
    local buildCounts = {}
    for i=1,#buildQueue do
        local unitDefIDb, count = next(buildQueue[i], nil)
        buildCounts[unitDefIDb] = (buildCounts[unitDefIDb] or 0) + count    
    end
    
    local qStack = facInfo.qStack
    local qStore = facInfo.qStore
    local buildOptions = facInfo.buildOptions

    for i=1,#buildOptions do
        local unitDefIDb = buildOptions[i]
        local count = buildCounts[unitDefIDb] or 0
        local qButton = qStore[unitDefIDb]
        local qCount = qButton:GetChildByName('count')
        qCount:SetCaption(count)
        if count>0 and not qStack:GetChildByName(qButton.name) then
            qStack:AddChild(qButton)
        elseif count==0 and qStack:GetChildByName(qButton.name) then
            qStack:RemoveChild(qButton)
        end
    end
end   

function widget:UnitCreated(unitID, unitDefID, unitTeam, facID, facDefID)
    if unitTeam == myTeamID and UnitDefs[unitDefID].isFactory then
        AddFactory(unitID, unitDefID)
    end
end

function widget:UnitFinished(unitID, unitDefID, unitTeam)
    if unitTeam == myTeamID and UnitDefs[unitDefID].isFactory then
        for i=1,#facs do
            if unitID==facs[i].unitID then
                facs[i].built = true
                local fBar = facs[i].facButton:GetChildByName('prog')
                fBar:SetValue(0)
            end
        end
    end
end

function widget:UnitFromFactory(unitID, unitDefID, unitTeam)
    if unitTeam== myTeamID then
        updateCounts = 'UnitFromFactory'
        for i=1,#facs do
            if unitID==facs[i].unitID then
                local qButton = fac[i].qStore[unitDefID]
                local qBar = qButton:GetChildByName('prog')
                qBar:SetValue(0)
                return
            end        
        end        
    end
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
    if (unitTeam == myTeamID) and UnitDefs[unitDefID].isFactory then
        RemoveFactory(unitID)
    end
    if unit==waypointFac then
        waypointFac = -1
    end
end

function widget:UnitTaken(unitID, unitDefID, unitTeam, newTeam)
    widget:UnitDestroyed(unitID, unitDefID, unitTeam)
    widget:UnitCreated(unitID, unitDefID, newTeam)
end

function widget:UnitCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOpts, cmdTag)
    if (unitTeam == myTeamID) and UnitDefs[unitDefID].isFactory then
        -- factory has been given a (probably build) order, update its build counts
        updateCounts = 'UnitCommand' -- we can't call widget:CommandsChanged() and update the build counts just yet, because GetFullBuildQueue won't return the new counts yet
    end
end

-------------------------------------------------------------------------------
-- waypoint handler

function WaypointHandler(x,y,button)
    if (button==1)or(button>3) then
        Spring.Echo("FactoryBar: Exited rallypoint mode")
        waypointFac  = -1
        waypointMode = 0
        return
    end

    local alt, ctrl, meta, shift = Spring.GetModKeyState()
    local opt = {"right"}
    if alt   then table.insert(opt,"alt")   end
    if ctrl  then table.insert(opt,"ctrl")  end
    if meta  then table.insert(opt,"meta")  end
    if shift then table.insert(opt,"shift") end

    local type,param = Spring.TraceScreenRay(x,y)
    if type=='ground' then
        Spring.GiveOrderToUnit(waypointFac, CMD.MOVE,param,opt) 
    elseif type=='unit' then
        Spring.GiveOrderToUnit(waypointFac, CMD.GUARD,{param},opt)     
    else --feature, etc
        type,param = Spring.TraceScreenRay(x,y,true)
        Spring.GiveOrderToUnit(waypointFac, CMD.MOVE,param,opt)
    end
end  

function widget:DrawWorld()
    -- draw factories command lines
    if waypointMode>1 then
        local unitID
        if waypointMode>1 then 
            spDrawUnitCommands(waypointFac)
        end
    end
end

function widget:MousePress(x, y, button)
    if waypointMode>1 then
        -- greedy waypointMode
        return (button~=2) -- we allow middle click scrolling in greedy waypoint mode
    end
    if waypointMode>1 then
        Spring.Echo("FactoryBar: Exited easy waypoint mode")
    end
    waypointFac  = -1
    waypointMode = 0
    return false
end

function widget:MouseRelease(x, y, button)
    if waypointMode>0 and waypointMode>0 and waypointFac>0 then
        WaypointHandler(x,y,button)    
    end
    return -1
end

-------------------------------------------------------------------------------
-- show/hide

function ShowFacBar()
    if window_facbar.hidden and not Spring.GetSpectatingState() then
        window_facbar:Show()
    end
end

function HideFacBar()
    if not window_facbar.hidden then
        window_facbar:Hide()
    end
end

local prevSpecState,_ = Spring.GetSpectatingState()
function widget:PlayerChanged()
    local spec,_ = Spring.GetSpectatingState()
    if spec then
        -- hide facbar if we are a spec
        HideFacBar()
    elseif not spec and prevSpecState and Spring.spGetSelectedUnitsCount()==0 then
        -- activate facbar if we were previous and spec and now became a player
        ShowFacBar()
        RecreateFacs()
    end
    prevSpecState = spec
    
    -- handle changing team
    local teamID = spGetMyTeamID()
    if myTeamID ~= teamID then
        myTeamID = teamID
        r,g,b = Spring.GetTeamColor(myTeamID)
        teamColor = {r,g,b}
        RecreateFacs()
    end
end

-------------------------------------------------------------------------------
-- init/shutdown/etc 

function widget:Initialize()
    if (not WG.Chili) then
        widgetHandler:RemoveWidget(widget)
        return
    end
    buttonColour = WG.buttonColour
    queueColor = buttonColour -- button colour for queue buttons
    
    WG.FacBar = {}
    WG.FacBar.Show = ShowFacBar
    WG.FacBar.Hide = HideFacBar
    
    -- setup Chili
    Chili = WG.Chili

    stack_main = Chili.Grid:New{
        y=20,
        padding = {0,0,0,0},
        itemPadding = {0, 0, 0, 0},
        itemMargin = {0, 0, 0, 0},
        width='100%',
        height = '100%',
        resizeItems = false,
        orientation = 'horizontal',
        centerItems = false,
        columns=1,
    }
    label_main =  Chili.Label:New{ 
        caption='Factories', 
        fontShadow = true, 
    }
    window_facbar = Chili.Window:New{
        padding = {3,3,3,3,},
        name = "facbar",
        x = 0, y = "20%",
        width  = 600,
        height = 450, 
        parent = Chili.Screen0,
        draggable = false,
        resizable = false,
        minWidth = 200,
        minHeight = 450,
        color = {0,0,0,0},
        children = {
            label_main, stack_main,
        },
    }
    label_main:Hide()
    myTeamID = Spring.GetMyTeamID()

    RecreateFacs()

    if spGetSpectatingState() or Spring.GetSelectedUnitsCount()>0 then
        HideFacBar()
    end
end

function widget:CommandsChanged()
    for i=1,#facs do
        local facInfo = facs[i]
        if spValidUnitID(facInfo.unitID) then
            UpdateFacBuildCounts(facInfo)
        end
    end
end

function widget:Update()
    if updateCounts then
        --Spring.Echo("fac bar update reason: " .. updateCounts)
        widget:CommandsChanged()
        updateCounts = nil
    end
end

function widget:GameFrame()
    for i=1,#facs do
        local facInfo = facs[i]
        if spValidUnitID(facInfo.unitID) then
            UpdateFacProgressBars(facInfo)
        end
    end
end

function widget:Shutdown()
    stack_main:Dispose()
    window_facbar:Dispose()
    WG.FacBar = nil
end

function widget:GetConfigData()
    return options
end

function widget:SetConfigData(data)
    if data then
        options = data
    end
end

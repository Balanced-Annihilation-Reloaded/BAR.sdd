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

local spGetUnitDefID      = Spring.GetUnitDefID
local spGetUnitHealth     = Spring.GetUnitHealth
local spGetUnitStates     = Spring.GetUnitStates
local spDrawUnitCommands  = Spring.DrawUnitCommands
local spGetSelectedUnits  = Spring.GetSelectedUnits
local spGetFullBuildQueue = Spring.GetFullBuildQueue
local spGetUnitIsBuilding = Spring.GetUnitIsBuilding

-------------------------------------------------------------------------------           
-- buttons

local function AddFacButton(unitID, unitDefID, tocontrol, stackname)
    -- add the button for this factory
    tocontrol:AddChild(
        Chili.Button:New{
            caption = "",
            width = options.buttonSize*1.2,
            height = options.buttonSize*1.0,
            tooltip =             'Click - '             .. GreenStr .. 'Select factory / Build unit \n'                     
                .. WhiteStr ..     'Middle click - '     .. GreenStr .. 'Go to \n'
                .. WhiteStr ..     'Right click - '     .. GreenStr .. 'Quick Rallypoint Mode' 
                ,
            backgroundColor = buttonColour,
            
            OnClick = {
                unitID ~= 0 and
                    function(_,_,_,button)
                        if button == 2 then
                            local x,y,z = Spring.GetUnitPosition(unitID)
                            Spring.SetCameraTarget(x,y,z)
                        elseif button == 3 then
                            Spring.Echo("FactoryBar: Entered rallypoint mode")
                            waypointMode = 2 -- greedy mode
                            waypointFac  = stackname
                        else
                            Spring.SelectUnitArray({unitID})
                            window_facbar:Hide()
                        end
                        

                    end
                    or nil
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
                unitID ~= 0 and
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
                or nil,
            },
        }
    )

    local qStack = Chili.StackPanel:New{
        name = stackname .. '_q',
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
    local qStore = {}
    
    local facStack = Chili.StackPanel:New{
        name = stackname,
        itemMargin={0,0,0,0},
        itemPadding={0,0,0,0},
        padding={0,0,0,0},
        --margin={0, 0, 0, 0},
        width=800,
        height = options.buttonSize*1.0,
        resizeItems = false,
        centerItems = false,
    }
    
    facStack:AddChild( qStack )
    tocontrol:AddChild( facStack )
    return facStack, qStack, qStore
end

local function AddBuildButton(unitDefID, facID, facIndex)

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

function RecreateFacbar()
    -- recreate facs table from scratch (without touching chili)
    facs = {}

    local teamUnits = Spring.GetTeamUnits(myTeamID)
    local totalUnits = #teamUnits

    local t = 0
  
    for num = 1, totalUnits do
        local unitID = teamUnits[num]
        local unitDefID = spGetUnitDefID(unitID)
        if UnitDefs[unitDefID].isFactory then
            local bo =  UnitDefs[unitDefID] and UnitDefs[unitDefID].buildOptions or {}
            if bo and #bo > 0 then    
              table.sort(bo, CostComparator)
              table.insert(facs,{ unitID=unitID, unitDefID=unitDefID, buildList=bo })
            end
            t = t + 1
            if t>=options.maxFacs then break end
        end
    end

    -- now re-create chili controls
    stack_main:ClearChildren()
    
    if #facs>0 and not label_main.visible then label_main:Show() 
    elseif label_main.visible==true then label_main:Hide() end
    
    for i,facInfo in ipairs(facs) do
        local unitDefID = facInfo.unitDefID
        local facStack, qStack, qStore = AddFacButton(facInfo.unitID, unitDefID, stack_main, i)
        --DEBUG #780 Spring.Echo("ADDFACBUTTON", i, unitDefID, facStack, qStack, qStore)

        facs[i].facStack = facStack
        facs[i].qStack   = qStack
        facs[i].qStore   = qStore
        
        local buildList = facInfo.buildList
        for j,unitDefIDb in ipairs(buildList) do
            local unitDefIDb = unitDefIDb
            qStore[i .. '|' .. unitDefIDb] = AddBuildButton(unitDefIDb, facInfo.unitID, i)
        end
        
    end

    stack_main:Invalidate()
    stack_main:UpdateLayout()
end

local function UpdateFac(i, facInfo) -- facs[i]=facInfo
    local unitBuildDefID
    local unitBuildID 

    -- fac is still being built?
    local progress = 0
    unitBuildID      = spGetUnitIsBuilding(facInfo.unitID)
    if unitBuildID then
        unitBuildDefID = spGetUnitDefID(unitBuildID)
        _, _, _, _, progress = spGetUnitHealth(unitBuildID)
    end

    local buildList  = facInfo.buildList
    local buildQueue  = spGetFullBuildQueue(facInfo.unitID)
    for j=1,#buildList do
        local unitDefIDb = buildList[j] 
        
        --Spring.Echo("BUILDLISTLOOP",i,j,unitDefIDb,facs[i],facs[i].qStore)
        local qButton = facs[i].qStore[i .. '|' .. unitDefIDb]        
        local qBar = qButton.childrenByName['prog']
        local qCount = qButton.childrenByName['count']   
        
        qBar:SetValue(0) -- consistency
        if unitDefIDb == unitBuildDefID then
            qBar:SetValue(progress)
        end
        qCount.count = 0 -- we'll count them up in the next loop        
    end
    
    -- remove & re-add children to fac q
    facs[i].qStack:ClearChildren()
    if (buildQueue ~= nil) then        
        local n,j = 1,options.maxVisibleBuilds
      
        while (buildQueue[n]) do
            local unitDefIDb, count = next(buildQueue[n], nil)
            
            local qButton = facs[i].qStore[i .. '|' .. unitDefIDb]
            local qCount = qButton.childrenByName['count']   
            
            --Spring.Echo("BUILDQLOOP",i,n,unitDefIDb,qButton)
            if not facs[i].qStack:GetChildByName(qButton.name) then -- we are iterating the build *queue*, so we may see the same unitDefID in more than one position
                facs[i].qStack:AddChild(qButton)
                j = j-1
            end
            
            qCount.count = qCount.count + count
            qCount:SetCaption(qCount.count)            
        
            if j==0 then break end
            n = n+1
        end
    end
end   

------------------------------------------------------
-- unit created/destroyed/etc

function widget:UnitCreated(unitID, unitDefID, unitTeam)
    if (unitTeam ~= myTeamID) then
      return
    end

    if UnitDefs[unitDefID].isFactory then
        -- add a new fac
        local bo =  UnitDefs[unitDefID] and UnitDefs[unitDefID].buildOptions
        if #facs>=options.maxFacs then
            table.remove(facs,1)
        end
        if bo and #bo > 0 then
            table.insert(facs,{ unitID=unitID, unitDefID=unitDefID, buildList=UnitDefs[unitDefID].buildOptions })
            needsRecreate = true
        end
    end
end

function widget:UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
    widget:UnitCreated(unitID, unitDefID, unitTeam)
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
    if (unitTeam ~= myTeamID) then
        return
    end
  
    if UnitDefs[unitDefID].isFactory then
        for i,facInfo in ipairs(facs) do
            if unitID==facInfo.unitID then
                table.remove(facs,i)
                needsRecreate = true
                return
            end
        end
    end
end

function widget:UnitTaken(unitID, unitDefID, unitTeam, newTeam)
    widget:UnitDestroyed(unitID, unitDefID, unitTeam)
    widget:UnitCreated(unitID, unitDefID, newTeam)
end

function widget:Update()
    if myTeamID~=Spring.GetMyTeamID() then
        myTeamID = Spring.GetMyTeamID()
        r,g,b = Spring.GetTeamColor(myTeamID)
        teamColor = {r,g,b}
        needsRecreate = true
    end
  
    if needsRecreate then
        RecreateFacbar()
        needsRecreate = false
    end
    
    for i,facInfo in ipairs(facs) do
        if Spring.ValidUnitID( facInfo.unitID ) then
            UpdateFac(i, facInfo)
        end
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
        Spring.GiveOrderToUnit(facs[waypointFac].unitID, CMD.MOVE,param,opt) 
    elseif type=='unit' then
        Spring.GiveOrderToUnit(facs[waypointFac].unitID, CMD.GUARD,{param},opt)     
    else --feature, etc
        type,param = Spring.TraceScreenRay(x,y,true)
        Spring.GiveOrderToUnit(facs[waypointFac].unitID, CMD.MOVE,param,opt)
    end
end  

function widget:DrawWorld()
    -- draw factories command lines
    if waypointMode>1 then
        local unitID
        if waypointMode>1 then 
            unitID = facs[waypointFac].unitID
        end
        spDrawUnitCommands(unitID)
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

local prevSpecState = Spring.GetSpectatingState()
function widget:PlayerChanged()
    local specState = Spring.GetSpectatingState()
    if specState then
        -- hide facbar if we are a spec
        HideFacBar()
    elseif not specState and prevSpecState and Spring.spGetSelectedUnitsCount()==0 then
        -- activate facbar if we were previous and spec and now became a player
        ShowFacBar()
    end
    prevSpecState = specState
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
        columns=2,
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

    needsRecreate = true

    if Spring.GetSpectatingState() or Spring.GetSelectedUnitsCount()>0 then
        HideFacBar()
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

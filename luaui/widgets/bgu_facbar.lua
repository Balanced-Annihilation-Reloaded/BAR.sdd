-------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Factory Bar", 
    desc      = "Always displays a build menu for factories",
    author    = "CarRepairer (converted from jK's Buildbar), Bluestone",
    date      = "2010-11-10",
    license   = "GNU GPL, v2 or later",
    layer     = 1001,
    enabled   = true,
  }
end


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

WhiteStr   = "\255\255\255\255"
GreyStr    = "\255\210\210\210"
GreenStr   = "\255\092\255\092"

local buttonColor = {0,0,0,0.5}
local queueColor = {0.0,0.4,0.4,0.9}
local progColor = {0,0.9,0.2,0.7}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local Chili
local Button
local Label
local Window
local StackPanel
local Grid
local TextBox
local Image
local Progressbar
local screen0

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

local window_facbar, stack_main, label_main
local echo = Spring.Echo
local imageDir = 'luaui/images/buildIcons/'

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

local needsRecreate = true
local function RecreateFacbar() end

options_path = 'Settings/Interface/FactoryBar'
options = {
    maxVisibleBuilds = {
        type = 'number',
        name = 'Visible Units in Que',
        desc = "The maximum units to show in the factory's queue",
        min = 2, max = 14,
        value = 5,
    },    
    
    buttonsize = {
        type = 'number',
        name = 'Button Size',
        min = 40, max = 100, step=5,
        value = 50,
        OnChange = function() RecreateFacbar() end,
    },
}

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------


-- list and interface vars
local facs = {}
local unfinished_facs = {}
local waypointFac = -1
local waypointMode = 0   -- 0 = off; 1=lazy; 2=greedy (greedy means: you have to left click once before leaving waypoint mode and you can have units selected)

local myTeamID = 0
local cycle_half_s = 1
local cycle_2_s = 1

local r,g,b = Spring.GetTeamColor(Spring.GetMyTeamID())
local teamColor = {r,g,b}


-------------------------------------------------------------------------------
-- SCREENSIZE FUNCTIONS
-------------------------------------------------------------------------------
local vsx, vsy   = widgetHandler:GetViewSizes()
function widget:ViewResize(viewSizeX, viewSizeY)
  vsx = viewSizeX
  vsy = viewSizeY
end

-------------------------------------------------------------------------------

local GetUnitDefID      = Spring.GetUnitDefID
local GetUnitHealth     = Spring.GetUnitHealth
local GetUnitStates     = Spring.GetUnitStates
local DrawUnitCommands  = Spring.DrawUnitCommands
local GetSelectedUnits  = Spring.GetSelectedUnits
local GetFullBuildQueue = Spring.GetFullBuildQueue
local GetUnitIsBuilding = Spring.GetUnitIsBuilding

local insert        = table.insert
local remove        = table.remove

local MAX_FACS = 8

-------------------------------------------------------------------------------

local function GetBuildQueue(unitID)
  local result = {}
  local queue = GetFullBuildQueue(unitID)
  if (queue ~= nil) then
    for _,buildPair in ipairs(queue) do
      local udef, count = next(buildPair, nil)
      if result[udef]~=nil then
        result[udef] = result[udef] + count
      else
        result[udef] = count
      end
    end
  end
  return result
end


local function UpdateFac(i, facInfo)
    --local unitDefID = facInfo.unitDefID
    
    local unitBuildDefID = -1
    local unitBuildID    = -1

    -- building?
    local progress = 0
    unitBuildID      = GetUnitIsBuilding(facInfo.unitID)
    if unitBuildID then
        unitBuildDefID = GetUnitDefID(unitBuildID)
        _, _, _, _, progress = GetUnitHealth(unitBuildID)
    end

    local buildList   = facInfo.buildList
    local buildQueue  = GetBuildQueue(facInfo.unitID)
    for j,unitDefIDb in ipairs(buildList) do
        local unitDefIDb = unitDefIDb
        
        --DEBUG Spring.Echo("BUILDLISTLOOP",i,j,unitDefIDb,facs[i],facs[i].boStack,facs[i].qStore)
        local boButton = facs[i].boStack.childrenByName[unitDefIDb]
        local qButton = facs[i].qStore[i .. '|' .. unitDefIDb]
        
        local boBar = boButton.childrenByName['prog']
        local qBar = qButton.childrenByName['prog']
        
        local amount = buildQueue[unitDefIDb] or 0
        local boCount = boButton.childrenByName['count']
        local qCount = qButton.childrenByName['count']            
        
        facs[i].qStack:RemoveChild(qButton)
        
        boBar:SetValue(0)
        qBar:SetValue(0)
        if unitDefIDb == unitBuildDefID then
            boBar:SetValue(progress)
            qBar:SetValue(progress)
        end
        
        if amount > 0 then
            boButton.backgroundColor = queueColor
        else
            boButton.backgroundColor = buttonColor
        end
        boButton:Invalidate()
        
        boCount:SetCaption(amount > 0 and amount or '')
        qCount:SetCaption(amount > 0 and amount or '')
    end
end

local function UpdateFacQ(i, facInfo)
    local unitBuildDefID = -1
    local unitBuildID    = -1

    -- building?
    local progress = 0
    unitBuildID      = GetUnitIsBuilding(facInfo.unitID)
    if unitBuildID then
        unitBuildDefID = GetUnitDefID(unitBuildID)
        _, _, _, _, progress = GetUnitHealth(unitBuildID)
    end
    local buildQueue  = Spring.GetFullBuildQueue(facInfo.unitID, options.maxVisibleBuilds.value +1)
                
    if (buildQueue ~= nil) then
        
        local n,j = 1,options.maxVisibleBuilds.value
        
        while (buildQueue[n]) do
            local unitDefIDb, count = next(buildQueue[n], nil)
            
            local qButton = facs[i].qStore[i .. '|' .. unitDefIDb]
            
            --DEBUG Spring.Echo("BUILDQLOOP",i,n,unitDefIDb,qButton)
            if not facs[i].qStack:GetChildByName(qButton.name) then
                facs[i].qStack:AddChild(qButton)
            end
        
            j = j-1
            if j==0 then break end
            n = n+1
        end
    end
end                

local function AddFacButton(unitID, unitDefID, tocontrol, stackname)
    -- add the button for this factory
    tocontrol:AddChild(
        Button:New{
            caption = "",
            width = options.buttonsize.value*1.2,
            height = options.buttonsize.value*1.0,
            tooltip =             'Click - '             .. GreenStr .. 'Select factory / Build unit \n'                     
                .. WhiteStr ..     'Middle click - '     .. GreenStr .. 'Go to \n'
                .. WhiteStr ..     'Right click - '     .. GreenStr .. 'Quick Rallypoint Mode' 
                ,
            backgroundColor = buttonColor,
            
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
                function() WG.FacBar.mouseOverDefID = unitDefID end
            },
            OnMouseOut = {
                function() WG.FacBar.mouseOverDefID = nil end            
            },
            padding={3, 3, 3, 3},
            --margin={0, 0, 0, 0},
            children = {
                unitID ~= 0 and
                    Image:New {
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

    local boStack = StackPanel:New{
        name = stackname .. '_bo',
        itemMargin={0,0,0,0},
        itemPadding={0,0,0,0},
        padding={0,0,0,0},
        --margin={0, 0, 0, 0},
        x=0,
        width=700,
        height = options.buttonsize.value,
        resizeItems = false,
        orientation = 'horizontal',
        centerItems = false,
    }
    local qStack = StackPanel:New{
        name = stackname .. '_q',
        itemMargin={0,0,0,0},
        itemPadding={0,0,0,0},
        padding={0,0,0,0},
        --margin={0, 0, 0, 0},
        x=0,
        width=700,
        height = options.buttonsize.value,
        resizeItems = false,
        orientation = 'horizontal',
        centerItems = false,
    }
    local qStore = {}
    
    local facStack = StackPanel:New{
        name = stackname,
        itemMargin={0,0,0,0},
        itemPadding={0,0,0,0},
        padding={0,0,0,0},
        --margin={0, 0, 0, 0},
        width=800,
        height = options.buttonsize.value*1.0,
        resizeItems = false,
        centerItems = false,
    }
    
    facStack:AddChild( qStack )
    tocontrol:AddChild( facStack )
    return facStack, boStack, qStack, qStore
end

local function MakeButton(unitDefID, facID, facIndex)

    local ud = UnitDefs[unitDefID]
  
    return
        Button:New{
            name = unitDefID,
            x=0,
            caption="",
            width = options.buttonsize.value,
            height = options.buttonsize.value,
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
                    if alt   then insert(opt,"alt")   end
                    if ctrl  then insert(opt,"ctrl")  end
                    if meta  then insert(opt,"meta")  end
                    if shift then insert(opt,"shift") end
                    
                    if rb then
                        insert(opt,"right")
                    end
                    
                    Spring.GiveOrderToUnit(facID, -(unitDefID), {}, opt)
                    
                    --UpdateFac(facIndex, facs[facIndex])
                    
                end
            },
            OnMouseOver = {
                function() WG.FacBar.mouseOverDefID = unitDefID end
            },
            OnMouseOut = {
                function() WG.FacBar.mouseOverDefID = nil end            
            },
            children = {
                Label:New {
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

                Progressbar:New{
                    value = 0.0,
                    name    = 'prog';
                    max     = 1;
                    color           = progColor,
                    backgroundColor = {1,1,1,  0.01},
                    x=2, y=2, height=3, right=2,
                },
                        
                Label:New{ caption = ud.metalCost .. ' m', fontSize = 11, x=2, bottom=2, fontShadow = true, },
                Image:New {
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

function Cost(uDID)
    return 60*UnitDefs[uDID].metalCost + UnitDefs[uDID].energyCost
end
function CostComparator(i,j)
    return Cost(i) < Cost(j)
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

local function WaypointHandler(x,y,button)
  if (button==1)or(button>3) then
    Spring.Echo("FactoryBar: Exited rallypoint mode")
    waypointFac  = -1
    waypointMode = 0
    return
  end

  local alt, ctrl, meta, shift = Spring.GetModKeyState()
  local opt = {"right"}
  if alt   then insert(opt,"alt")   end
  if ctrl  then insert(opt,"ctrl")  end
  if meta  then insert(opt,"meta")  end
  if shift then insert(opt,"shift") end

  local type,param = Spring.TraceScreenRay(x,y)
  if type=='ground' then
    Spring.GiveOrderToUnit(facs[waypointFac].unitID, CMD.MOVE,param,opt) 
  elseif type=='unit' then
    Spring.GiveOrderToUnit(facs[waypointFac].unitID, CMD.GUARD,{param},opt)     
  else --feature
    type,param = Spring.TraceScreenRay(x,y,true)
    Spring.GiveOrderToUnit(facs[waypointFac].unitID, CMD.MOVE,param,opt)
  end

  --if not shift then waypointMode = 0; return true end
end

RecreateFacbar = function()
    -- recreate our chili controls from scratch, based on facs[]

    stack_main:ClearChildren()
    
    if #facs>0 and not label_main.visible then label_main:Show() 
    elseif label_main.visible==true then label_main:Hide() end
    
    for i,facInfo in ipairs(facs) do
        local unitDefID = facInfo.unitDefID
        
        local unitBuildDefID = -1
        local unitBuildID    = -1
        local progress

        -- building?
        unitBuildID      = GetUnitIsBuilding(facInfo.unitID)
        if unitBuildID then
            unitBuildDefID = GetUnitDefID(unitBuildID)
            _, _, _, _, progress = GetUnitHealth(unitBuildID)
            unitDefID      = unitBuildDefID
        elseif (unfinished_facs[facInfo.unitID]) then
            _, _, _, _, progress = GetUnitHealth(facInfo.unitID)
            if (progress>=1) then 
                progress = -1
                unfinished_facs[facInfo.unitID] = nil
            end
        end

        local facStack, boStack, qStack, qStore = AddFacButton(facInfo.unitID, unitDefID, stack_main, i)
        --DEBUG #780 Spring.Echo("ADDFACBUTTON", i, unitDefID, facStack, boStack, qStack, qStore)
        facs[i].facStack     = facStack
        facs[i].boStack     = boStack
        facs[i].qStack         = qStack
        facs[i].qStore         = qStore
        
        local buildList   = facInfo.buildList
        local buildQueue  = GetBuildQueue(facInfo.unitID)
        for j,unitDefIDb in ipairs(buildList) do
            local unitDefIDb = unitDefIDb
            boStack:AddChild( MakeButton(unitDefIDb, facInfo.unitID, i) )
            qStore[i .. '|' .. unitDefIDb] = MakeButton(unitDefIDb, facInfo.unitID, i)
        end
        
    end

    stack_main:Invalidate()
    stack_main:UpdateLayout()
end

local function UpdateFactoryList()
  -- recreate our table of our own factories from scratch (without touching chili)
  facs = {}

  local teamUnits = Spring.GetTeamUnits(myTeamID)
  local totalUnits = #teamUnits

  local t = 0
  
  for num = 1, totalUnits do
    local unitID = teamUnits[num]
    local unitDefID = GetUnitDefID(unitID)
    if UnitDefs[unitDefID].isFactory then
        local bo =  UnitDefs[unitDefID] and UnitDefs[unitDefID].buildOptions or {}
        if bo and #bo > 0 then    
          table.sort(bo, CostComparator)
          insert(facs,{ unitID=unitID, unitDefID=unitDefID, buildList=bo })
          local _, _, _, _, buildProgress = GetUnitHealth(unitID)
          if (buildProgress)and(buildProgress<1) then
            unfinished_facs[unitID] = true
          end
        end
        t = t + 1
        if t>=MAX_FACS then break end
    end
  end

  needsRecreate = true
end

------------------------------------------------------

function widget:DrawWorld()
    -- Draw factories command lines
    if waypointMode>1 then
        local unitID
        if waypointMode>1 then 
            unitID = facs[waypointFac].unitID
        end
        DrawUnitCommands(unitID)
    end
end

function widget:UnitCreated(unitID, unitDefID, unitTeam)
  if (unitTeam ~= myTeamID) then
    return
  end

  if UnitDefs[unitDefID].isFactory then
    local bo =  UnitDefs[unitDefID] and UnitDefs[unitDefID].buildOptions
    if #facs>=MAX_FACS then
        remove(facs,1)
    end
    if bo and #bo > 0 then
        insert(facs,{ unitID=unitID, unitDefID=unitDefID, buildList=UnitDefs[unitDefID].buildOptions })
        needsRecreate = true
    end
  end
  unfinished_facs[unitID] = true
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
        unfinished_facs[unitID] = nil
        needsRecreate = true
        return
      end
    end
  end
end

function widget:UnitTaken(unitID, unitDefID, unitTeam, newTeam)
  widget:UnitDestroyed(unitID, unitDefID, unitTeam)
end

function widget:Update()
    if myTeamID~=Spring.GetMyTeamID() then
        myTeamID = Spring.GetMyTeamID()
        r,g,b = Spring.GetTeamColor(myTeamID)
        teamColor = {r,g,b}
        UpdateFactoryList()
    end
  
    cycle_half_s = (cycle_half_s % 16) + 1
    cycle_2_s = (cycle_2_s % (32*2)) + 1
    
    if needsRecreate then
        RecreateFacbar()
        needsRecreate = false
    end
    
    if cycle_half_s == 1 then 
        for i,facInfo in ipairs(facs) do
            if Spring.ValidUnitID( facInfo.unitID ) then
                if cycle_2_s == 1 then  
                    UpdateFac(i, facInfo)
                end
                UpdateFacQ(i, facInfo)
            end
        end
    end

end



-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

function widget:MouseRelease(x, y, button)
    if waypointMode>0 and waypointMode>0 and waypointFac>0 then
        WaypointHandler(x,y,button)    
    end
    return -1
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
    elseif not specState and prevSpecState and Spring.GetSelectedUnitsCount()==0 then
        -- activate facbar if we were previous and spec and now became a player
        ShowFacBar()
    end
    prevSpecState = specState
end

function widget:Initialize()
    if (not WG.Chili) then
        widgetHandler:RemoveWidget(widget)
        return
    end
    
    WG.FacBar = {}
    WG.FacBar.Show = ShowFacBar
    WG.FacBar.Hide = HideFacBar
    
    -- setup Chili
    Chili = WG.Chili
    Button = Chili.Button
    Label = Chili.Label
    Window = Chili.Window
    StackPanel = Chili.StackPanel
    Grid = Chili.Grid
    TextBox = Chili.TextBox
    Image = Chili.Image
    Progressbar = Chili.Progressbar
    screen0 = Chili.Screen0

    stack_main = Grid:New{
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
    label_main =  Label:New{ 
        caption='Factories', 
        fontShadow = true, 
    }
    window_facbar = Window:New{
        padding = {3,3,3,3,},
        name = "facbar",
        x = 0, y = "20%",
        width  = 600,
        height = 450, --enough for max 5 factories
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

    UpdateFactoryList()

    local viewSizeX, viewSizeY = widgetHandler:GetViewSizes()
    self:ViewResize(viewSizeX, viewSizeY)
    
    if Spring.GetSpectatingState() or Spring.GetSelectedUnitsCount()>0 then
        HideFacBar()
    end
end

function widget:Shutdown()
    stack_main:Dispose()
    window_facbar:Dispose()
    WG.FacBar = nil
end

function widget:GetInfo()
  return {
    name      = "Ally Resource Stats", 
    desc      = "Shows your allies resources",
    author    = "Bluestone", -- based on the original widget of the same name, by TheFatController
    date      = "",
    license   = "GPL v2 or later",
    layer     = 1, 
    enabled   = true
  }
end

local spGetTeamResources = Spring.GetTeamResources
local abs = math.abs
local sformat = string.format


local amISpec
local amIFullView
local myAllyTeamID
local myTeamID

local teamPanels = {}
local allyTeamPanels = {}
local allyTeamStats = {}
local allyTeamOfTeam = {}

local nAllyTeams
local nTeams

local resources = { -- if the number of resources changes from 2, the display panels must be redesigned
    [1] = {name="metal", color={0.6, 0.6, 0.8, 0.8},},
    [2] = {name="energy", color={1.0, 1.0, 0.3, 0.6},},
}    
 
local Chili, window, stack
local height, width
local settings = {}

local panelHeight = 20
local panelWidth = 110

local buttonColour = {0,0,0,1}


-----------------------

function format(num, idp)
  return sformat("%." .. (idp or 0) .. "f", num)
end
local function readable(num)
    local s = ""
    if num < 0 then
        s = '-'
    else
        s = '+'
    end
    num = abs(num)
    if num < 1000 then
        s = s .. format(num,1)
    elseif num >= 10000 then
        s = s .. format(num/1000,0)..'k'
    elseif num >= 1000 then
        s = s .. format(num/1000,1)..'k'
    else
        s = s .. format(num,0)
    end
    return s
end

function UpdateAllyTeamPanel(t,res)
    local aID = t.aID
    local text = readable(allyTeamStats[aID][res.name].income)
    t.panel:GetChildByName(res.name):SetText(text)
end

function UpdateTeamPanel(t, res)
    local tID = t.tID
    local aID = allyTeamOfTeam[tID]
    local currentLevel, storage, pull, income, expense, share, sent, received = spGetTeamResources(tID, res.name)
    if not currentLevel then return end
    
    t.panel:GetChildByName(res.name).children[1]:SetValue(currentLevel/storage)
    
    local a = allyTeamStats[aID][res.name]
    a.lev      = a.lev + currentLevel
    a.storage  = a.storage + storage
    a.income   = a.income + income
    a.expense  = a.expense + expense
end

function UpdatePanels(updateText)
    --update stats
    for _,res in ipairs(resources) do
        for _,a in pairs(allyTeamStats) do
            a[res.name].lev = 0
            a[res.name].storage = 0
            a[res.name].income = 0
            a[res.name].expense = 0
        end
        
        for _,t in ipairs(allyTeamPanels) do
            local aID = t.aID
            for _,s in ipairs(teamPanels[aID]) do
                UpdateTeamPanel(s, res) 
            end    
            if (updateText) then -- only needed after a slow update
                UpdateAllyTeamPanel(t, res)
            end
        end
    end    
end

function widget:GameFrame(n)    
    if needUpdate then return end -- wait until its happened

    local updateText = (n%30==1) 
    UpdatePanels(updateText)
end

function widget:Update()
    local teamID = Spring.GetMyTeamID()
    if teamID~= myTeamID then
        myTeamID = teamID
        needUpdate = true
    end

    needUpdate = needUpdate or CheckMyState()
    if needUpdate then
        SetupPanels()
        UpdatePanels(true)
        needUpdate = false
    end
end
-----------------------

function ShareResource(self)
    local myTeamID = Spring.GetMyTeamID()
    local targetTeamID = self.tID
    if amISpec or targetTeamID==myTeamID then return end
    
    local res = self.name
    local currentLevel,_ = spGetTeamResources(myTeamID, res)
    local toShare = currentLevel * 0.25
   
    Spring.ShareResources(targetTeamID,res,toShare)   
end


-----------------------

function ConstructAllyTeamPanel(aID)
    local panel = Chili.Control:New{
        bordercolor = {0,0,0,0},
        width     = panelWidth,
        height    = panelHeight,
        padding   = {0,0,0,0},
        margin    = {0,0,0,0},
    }
    
    local wPos = 15
    for _,res in pairs(resources) do
        Chili.TextBox:New{
            parent = panel,
            name = res.name,
            x = wPos,
            y = panelHeight/2-3,
            height = 14,
            width = (panelWidth-2*wPos)/2 + 1,
            text = "+0",
            font = {
                size = 13,
                color = res.color,
                outline          = true,
                autoOutlineColor = true,
                outlineWidth     = 7,
                outlineWeight    = 3,
            }
        }    
        wPos = wPos + (panelWidth-2*wPos)/2 + 6
    end


    return panel
end

function ConstructTeamPanel(tID)
    local panel = Chili.Control:New{
        bordercolor = {0,0,0,0},
        width     = panelWidth,
        height    = panelHeight,
        padding   = {0,0,0,0},
        margin    = {0,0,0,0},
    }

    local hPadding = 3

    local r,g,b = Spring.GetTeamColor(tID)
    local imageHeight = 10
    Chili.Image:New{
        parent = panel,
        name = 'factionpic',
        height = imageHeight,
        width = imageHeight,
        x=7,
        y=panelHeight/2 - imageHeight + 4,
        file = "LuaUI/Images/playerlist/default.png", --TODO
        color = {r,g,b},
    }
    
    
    local hPos = hPadding/2
    for _,res in pairs(resources) do
        local button = Chili.Button:New{
            parent = panel,
            name   = res.name, 
            tID    = tID,
            caption = "",
            x      = imageHeight+9, 
            y      = hPos, 
            width  = panelWidth-imageHeight-15,        
            height = 8,
            padding   = {0,0,0,0},
            margin    = {0,0,0,0},
            OnClick = {ShareResource},
        }
        Chili.Progressbar:New{
            parent = button,
            x = 0,
            y = 0,
            width = '100%',
            height = '100%',
            color  = res.color,
            padding   = {0,0,0,0},
            margin    = {0,0,0,0},
            max = 1,
        }    
        hPos = hPos + (panelHeight-hPadding)/2
    end
    
    return panel
end

function ConstructPanels()
    teamPanels = {} -- array table
    allyTeamPanels = {} -- array table
    allyTeamStats = {} -- allyTeamState[aID][res] = {...}
    allyTeamOfTeam = {} -- allTeamOfTeam[tID] = aID   
    nAllyTeams = 0
    nTeams = 0
    
    local notAlone = false
    local myTeamID = Spring.GetMyTeamID()
    local myAllyTeamID = Spring.GetMyAllyTeamID()    
    local gaiaTeamID = Spring.GetGaiaTeamID()
    
    local aList = WG.PlayerList and WG.PlayerList.allyTeamList or Spring.GetAllyTeamList() -- use the same order as bgu_player_list, if present
    for _,aID in ipairs(aList) do
        if aID==myAllyTeamID or amISpec then

            local tList = WG.PlayerList and WG.PlayerList.teamLists[aID] or Spring.GetTeamList(aID)
            for _,tID in ipairs(tList) do
                if tID~=gaiaTeamID then
                    local notMe = amISpec or (tID~=myTeamID)
                    local canView = notMe and not (amIFullView and aID~=myAllyTeamID)
                    notAlone = notAlone or notMe
                
                    if canView and not allyTeamStats[aID] then
                        -- insert ally team
                        table.insert(allyTeamPanels, {aID=aID, panel=ConstructAllyTeamPanel(aID)})
                        allyTeamStats[aID] = {}
                        for _,res in pairs(resources) do
                            allyTeamStats[aID][res.name] = {}
                        end
                        nAllyTeams = nAllyTeams + 1
                    end
                    
                    -- insert team         
                    if canView then
                        teamPanels[aID] = teamPanels[aID] or {}
                        table.insert(teamPanels[aID], {tID=tID, panel=ConstructTeamPanel(tID)})
                        allyTeamOfTeam[tID] = aID
                        nTeams = nTeams + 1
                    end
                end
            end
        end
    end
    
    if not notAlone then -- don't show if we are alone!
        if window.visible then window:Hide() end
    else
        if window.hidden then window:Show() end 
    end
end

-----------------------

function PaddingPanel()
    return Chili.Control:New{height=panelHeight, width=panelWidth}
end

function SetupPanels()
    grid:ClearChildren()
    ConstructPanels()
    
    -- get the max number of teams in any ally team
    local maxTeamsPerAllyTeam = 0
    for _,t in pairs(allyTeamPanels) do
        maxTeamsPerAllyTeam = math.max(maxTeamsPerAllyTeam, #teamPanels[t.aID])
    end
    
    -- choose number of cols
    local nPanels = nTeams + nAllyTeams -- not including padding
    local maxRowsPerCol = 14
    if nPanels <= maxRowsPerCol then
        cols = 1
    else
        cols = math.min(math.ceil(nPanels/maxRowsPerCol), maxTeamsPerAllyTeam+1)
    end        
    
    -- add the panels, with padding where appropriate
    for _,t in ipairs(allyTeamPanels) do
        local m = 0 -- # of panels & team panels & padding panels for this ally team
        local aID = t.aID
        -- ally team panel
        grid:AddChild(t.panel)
        m = m + 1
        -- padding if needed, to make the team panels start on a new line if the team panels wouldn't fit on this line
        if #teamPanels[aID]>cols-1 and cols>1 then
            for i=1,cols-1 do
                grid:AddChild(PaddingPanel())            
                m = m + 1
            end
        end        
        
        -- team panels
        for _,s in ipairs(teamPanels[aID]) do
            local tID = s.tID
            grid:AddChild(s.panel)
            m = m + 1
        end
        -- padding if needed, to make the next ally team start on a new line
        while (m%cols~=0) do
            grid:AddChild(PaddingPanel())            
            m = m + 1
        end        
    end    
    
    rows = math.ceil(#grid.children/cols)
    
    -- set grid & window dimensions
    grid.columns = cols
    grid.rows = rows
    local vsx,vsy = Spring.GetViewGeometry()
    local w = cols*panelWidth
    local h = rows*panelHeight + 14
    window.right = w
    window.width = w
    window.height = h
    window:Invalidate() -- SetPos can't align to right
    window:Resize(window.width+1,_) -- hack
    window:Resize(window.width-1,_)
end

function CheckMyState()
    local changed = false
    local spec, notFullView, fullSelect = Spring.GetSpectatingState()
    if spec~=amISpec or (not notFullView)~=amIFullView then
        changed = true
        amIFullView = not notFullView 
        amISpec = spec
    end
    local aID = Spring.GetMyAllyTeamID()
    if aID~=myAllyTeamID then
        changed = true
        myAllyTeamID = aID
    end
    return changed
end

function widget:Initialize()
    Chili = WG.Chili
    buttonColour = WG.buttonColour
    
    -- construct window, stack
    window = Chili.Window:New{
        name      = 'ally res window',
        parent    = Chili.Screen0,
        right     = 0,
        y         = 175,
        width     = panelWidth,
        resizeable= false,
        padding   = {0,6,0,8},
        color     = buttonColour,
    }
    grid = Chili.Grid:New{
        parent   = window,
        name     = 'ally res grid',
        x        = 0,
        y        = 0,
        right    = 0,
        bottom   = 0,
        columns  = 1,
        rows     = 1,
        padding  = {0,0,0,0},
        orientation = 'horizontal',
    }
    
    CheckMyState()
    needUpdate = true

    if settings.x and settings.y then
        --window:SetPos(settings.x,settings.y) -- disabled, currently not moveable
    end    
end

function widget:PlayerChanged()
    needUpdate = true
end

--[[
function widget:GetConfigData()
    local data = {}
    if window then
        data.x = window.x
        data.y = window.y
    end
    return data
end

function widget:SetConfigData(data)
    settings = data
end
]]

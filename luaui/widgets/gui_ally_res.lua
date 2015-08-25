function widget:GetInfo()
  return {
    name      = "Ally Resource Stats", 
    desc      = "Shows your allies resources",
    author    = "Bluestone", -- based on the original widget of the same name, by TheFatController
    date      = "",
    license   = "GPL v2 or later",
    layer     = 0, 
    enabled   = true
  }
end

local spGetTeamResources = Spring.GetTeamResources
local abs = math.abs
local sformat = string.format


local amISpec
local myAllyTeamID

local panels = {}
local teamPanels = {}
local allyTeamPanels = {}
local allyTeamStats = {}
local allyTeamOfTeam = {}

local resources = { -- if the number of resources changes from 2, the display panels must be redesigned
    [1] = {name="metal", color={0.6, 0.6, 0.8, 0.8},},
    [2] = {name="energy", color={1.0, 1.0, 0.3, 0.6},},
}    
 
local Chili, window, stack
local height, width
local settings = {}

local panelHeight = 35
local panelWidth = 100


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
    if num < 10 then
        s = s .. format(num,1)
    elseif num >10000 then
        s = s .. format(num/1000,0)..'k'
    elseif num >1000 then
        s = s .. format(num/1000,1)..'k'
    else
        s = s .. format(num,0)
    end
    return s
end

function UpdateAllyTeamPanel(aID,res)
    local text = readable(allyTeamStats[aID][res.name].income)
    allyTeamPanels[aID]:GetChildByName(res.name):SetText(text)
    
    -- TODO: make image size on team panels depend on contribution % ?
end

function UpdateTeamPanel(tID, res)
    local aID = allyTeamOfTeam[tID]
    local currentLevel, storage, pull, income, expense, share, sent, received = spGetTeamResources(tID, res.name)

    teamPanels[tID]:GetChildByName(res.name):SetValue(currentLevel/storage)
    
    local a = allyTeamStats[aID][res.name]
    a.lev      = a.lev + currentLevel
    a.storage  = a.storage + storage
    a.income   = a.income + income
    a.expense  = a.expense + expense
end

function widget:GameFrame()
    if needUpdate then
        CheckMyState()
        SetupPanels()
    end
    
    --update stats
    for _,res in pairs(resources) do
        for _,a in pairs(allyTeamStats) do
            a[res.name].lev = 0
            a[res.name].storage = 0
            a[res.name].income = 0
            a[res.name].expense = 0
        end
        
        for tID,_ in pairs(teamPanels) do
            UpdateTeamPanel(tID, res) 
        end    

        for aID,_ in pairs(allyTeamPanels) do
            UpdateAllyTeamPanel(aID, res)
        end
    end    
end

-----------------------

function ConstructFactionPic(tID) 
    -- actually, we could get them from the player list?
    -- TODO    
end

function ConstructAllyTeamPanel(aID)
    local panel = Chili.Control:New{
        bordercolor = {0,0,0,0},
        width     = panelWidth,
        height    = panelHeight,
        padding   = {0,0,0,0},
        margin    = {0,0,0,0},
    }
    
    if aID~=0 then
    local separator = Chili.Line:New{
        parent = panel,
        x = panelWidth/6,
        width   = 2*panelWidth/3,
    }    
    end

    local wPos = panelWidth/8
    for _,res in pairs(resources) do
        Chili.TextBox:New{
            parent = panel,
            name = res.name,
            x = wPos,
            y = panelHeight/2-2,
            height = 14,
            width = 30,
            text = "+0",
            font = {
                color = res.color
            }
        }    
        wPos = wPos + 3*panelWidth/8 + 1
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
    local imageHeight = 15
    Chili.Image:New{
        parent = panel,
        name = 'factionpic',
        height = imageHeight,
        width = imageHeight,
        x=5,
        y=panelHeight/2 - imageHeight + 2,
        file = "LuaUI/Images/playerlist/default.png", --TODO
        color = {r,g,b},
    }
    
    
    local hPos = hPadding/2
    for _,res in pairs(resources) do
        Chili.Progressbar:New{
            parent = panel, 
            name   = res.name,
            x      = imageHeight+6, 
            y      = hPos, 
            width  = panelWidth-imageHeight-13,
            color  = res.color,
            padding   = {0,0,0,0},
            margin    = {0,0,0,0},
            height = 10,
            max = 1,
            -- OnClick TODO: share res, but onclick seems to fail here, strangely onmouseout works
            --caption= "",
        }    
        hPos = hPos + (panelHeight-hPadding)/2
    end
    
    return panel
end

function ConstructPanels()
    panels = {}
    teamPanels = {}
    allyTeamPanels = {}
    allyTeamStats = {}
    allyTeamOfTeam = {}
    
    local notMe = false
    local myTeamID = Spring.GetMyTeamID()
    local myAllyTeamID = Spring.GetMyAllyTeamID()    
    local gaiaTeamID = Spring.GetGaiaTeamID()
    
    local aList = Spring.GetAllyTeamList()
    for _,aID in ipairs(aList) do
        if aID==myAllyTeamID or amISpec then

            local tList = Spring.GetTeamList(aID)
            for _,tID in ipairs(tList) do
                if tID~=gaiaTeamID then
                    if amISpec or (tID~=myTeamID and aID==myAllyTeamID) then notMe = true end
                
                    if not allyTeamPanels[aID] then
                        -- insert ally team
                        allyTeamPanels[aID] = ConstructAllyTeamPanel(aID)
                        panels[#panels+1] = allyTeamPanels[aID]
                        allyTeamStats[aID] = {}
                        for _,res in pairs(resources) do
                            allyTeamStats[aID][res.name] = {}
                        end                    
                    end
                    
                    -- insert team         
                    teamPanels[tID] = ConstructTeamPanel(tID)
                    panels[#panels+1] = teamPanels[tID]
                    allyTeamOfTeam[tID] = aID
                end
            end
        end
    end
    
    if not notMe then -- don't run if we are alone!
        if window.visible then window:Hide() end
    else
        if window.hidden then window:Show() end 
    end
end

-----------------------

function SetupPanels()
    -- dispose of any old panels in the stack
    stack:ClearChildren()

    -- choose which aIDs/tID will be visible and make panels for them
    ConstructPanels()

    -- set the dimensions
    height = #panels * panelHeight
    window:SetPos(_,_,width,height+5)
    
    --add the panels into the stack    
    for _,panel in ipairs(panels) do
        stack:AddChild(panel)
    end
end

function CheckMyState()
    local changed = false
    local spec = Spring.GetSpectatingState()
    if spec~=amISpec then
        changed = true
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

    -- construct window, stack
    window = Chili.Window:New{
        name      = 'ally res window',
        parent    = Chili.Screen0,
        right     = panelWidth+50,
        bottom    = 400,
        height    = panelHeight,
        width     = panelWidth,
        padding   = {0,0,0,0},
        itemPadding = {0,0,0,0},
        itemMargin  = {0,0,0,0},
        tweakdraggable = true,
    }
    stack = Chili.LayoutPanel:New{
        parent      = window,
        name        = 'ally res stack',
        width       = '100%',
        height      = '100%',
        resizeItems = false,
        padding     = {0,0,0,0},
        itemPadding = {0,0,0,0},
        itemMargin  = {0,0,0,0},
        children    = {},
        preserveChildrenOrder = true,
    }
    
    CheckMyState()
    SetupPanels()

    if settings.x and settings.y then
        window:SetPos(settings.x,settings.y)
    end    
end

function widget:PlayerChanged()
    needUpdate = true
end

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


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
local amIFullView
local myAllyTeamID

local panels = {}
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

local allyTeamPanelHeight = 18
local teamPanelHeight = 20
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

function UpdateAllyTeamPanel(aID,res)
    local text = readable(allyTeamStats[aID][res.name].income)
    allyTeamPanels[aID]:GetChildByName(res.name):SetText(text)
    
    -- TODO: make image size on team panels depend on contribution % ?
end

function UpdateTeamPanel(tID, res)
    local aID = allyTeamOfTeam[tID]
    local currentLevel, storage, pull, income, expense, share, sent, received = spGetTeamResources(tID, res.name)
    
    teamPanels[tID]:GetChildByName(res.name).children[1]:SetValue(currentLevel/storage)
    
    local a = allyTeamStats[aID][res.name]
    a.lev      = a.lev + currentLevel
    a.storage  = a.storage + storage
    a.income   = a.income + income
    a.expense  = a.expense + expense
end

function widget:GameFrame()
    needUpdate = needUpdate or CheckMyState()
    if needUpdate then
        SetupPanels()
        needUpdate = false
    end
    
    --update stats
    for _,res in ipairs(resources) do
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
    local panelHeight = allyTeamPanelHeight
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
        x = 0,
        width   = '100%',
        maxheight = 3,
    }    
    end

    local wPos = 13
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
        wPos = wPos + (panelWidth-2*wPos)/2 + 2
    end


    return panel
end

function ConstructTeamPanel(tID)
    local panelHeight = teamPanelHeight
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
    panels = {}
    teamPanels = {}
    allyTeamPanels = {}
    allyTeamStats = {}
    allyTeamOfTeam = {}    
    nAllyTeams = 0
    nTeams = 0
    
    local notAlone = false
    local myTeamID = Spring.GetMyTeamID()
    local myAllyTeamID = Spring.GetMyAllyTeamID()    
    local gaiaTeamID = Spring.GetGaiaTeamID()
    
    local aList = Spring.GetAllyTeamList()
    for _,aID in ipairs(aList) do
        if aID==myAllyTeamID or amISpec then

            local tList = Spring.GetTeamList(aID)
            for _,tID in ipairs(tList) do
                if tID~=gaiaTeamID then
                    local notMe = amISpec or (tID~=myTeamID)
                    local canView = notMe and not (amIFullView and aID~=myAllyTeamID)
                    notAlone = notAlone or notMe
                
                    if canView and not allyTeamPanels[aID] then
                        -- insert ally team
                        allyTeamPanels[aID] = ConstructAllyTeamPanel(aID)
                        panels[#panels+1] = allyTeamPanels[aID]
                        allyTeamStats[aID] = {}
                        for _,res in pairs(resources) do
                            allyTeamStats[aID][res.name] = {}
                        end
                        nAllyTeams = nAllyTeams + 1
                    end
                    
                    -- insert team         
                    if canView then
                        teamPanels[tID] = ConstructTeamPanel(tID)
                        panels[#panels+1] = teamPanels[tID]
                        allyTeamOfTeam[tID] = aID
                        nTeams = nTeams + 1
                    end
                end
            end
        end
    end
    
    if not notAlone then -- don't run if we are alone!
        if window.visible then window:Hide() end
    else
        if window.hidden then window:Show() end 
    end
end

-----------------------

function SetupPanels()
    stack:ClearChildren()
    ConstructPanels()
    for _,panel in ipairs(panels) do
        stack:AddChild(panel)
    end    
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
        resizeable = false,
        autosize = true,
        padding   = {0,0,0,6},
        color = buttonColour,
        caption = "",
     }
    stack = Chili.StackPanel:New{
        parent      = window,
        name        = 'ally res stack',
        width       = '100%',
        autosize = true,
        resizeItems = false,
        padding     = {0,2,0,0},
        itemPadding = {0,0,0,0},
        itemMargin  = {0,0,0,0},
        children    = {},
        preserveChildrenOrder = true,
    }
    
    CheckMyState()
    SetupPanels()

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

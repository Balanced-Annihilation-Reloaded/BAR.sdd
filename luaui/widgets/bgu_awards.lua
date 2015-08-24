function widget:GetInfo()
    return {
        name    = 'Awards',
        desc    = 'Awards awards!',
        author  = 'Funkencool, Bluestone',
        date    = 'July 2014',
        license = 'GNU GPL v2',
        layer   = 0,
        enabled = true
    }
end


------------
-- Vars

local Chili, container, stackPanel
local playerListByTeam = {}

------------
-- Auxillary Functions

function colourNames(teamID)
        if teamID < 0 then return "" end
        nameColourR,nameColourG,nameColourB,nameColourA = Spring.GetTeamColor(teamID)
        R255 = math.floor(nameColourR*255)  --the first \255 is just a tag (not colour setting) no part can end with a zero due to engine limitation (C)
        G255 = math.floor(nameColourG*255)
        B255 = math.floor(nameColourB*255)
        if ( R255%10 == 0) then
                R255 = R255+1
        end
        if( G255%10 == 0) then
                G255 = G255+1
        end
        if ( B255%10 == 0) then
                B255 = B255+1
        end
    return "\255"..string.char(R255)..string.char(G255)..string.char(B255) --works thanks to zwzsg
end 

function FindPlayerName(teamID)
    local plList = playerListByTeam[teamID]
    local name 
    if plList[1] then
        name = plList[1]
        if #plList > 1 then
            name = name .. " (coop)"
        end
    else
        name = "(unknown)"
    end

    return colourNames(teamID) .. name .. "\255\255\255\255"
end

function round(num, idp)
  return string.format("%." .. (idp or 0) .. "f", num)
end

------------
-- Main Functions

local function createContainer()
    stackPanel = Chili.StackPanel:New{
        x           = 0,
        y           = 0,
        width       = '100%',
        resizeItems = false,
        autosize    = true,
        padding     = {0,0,0,0},
        itemPadding = {0,0,0,0},
        itemMargin  = {0,0,0,0},
        preserverChildrenOrder = true
    }
    
    container = Chili.ScrollPanel:New{
        x        = 0,
        y        = 0,
        right    = 0,
        bottom   = 0,
        children = {stackPanel},
    }
    
    WG.MainMenu.AddControl('Awards', container)
end

local function createAward(award)
    return Chili.Control:New{
        parent   = container,
        x        = 0,
        width    = 550,
        height   = 100,
        children = {
            Chili.Label:New{x=0 ,y=0,caption="test award"}
        },
    }
end

------------
-- Callins

function widget:Initialize()
    if not WG.Chili then return end
    
    widgetHandler:RegisterGlobal('AwardAward', AwardAward)
    
    -- init Chili
    Chili = WG.Chili
    
    --load a list of players for each team into playerListByTeam
    local teamList = Spring.GetTeamList()
    for _,teamID in pairs(teamList) do
        local playerList = Spring.GetPlayerList(teamID)
        local list = {} --without specs
        for _,playerID in pairs(playerList) do
            local name, _, isSpec = Spring.GetPlayerInfo(playerID)
            if not isSpec then
                table.insert(list, name)
            end
        end
        playerListByTeam[teamID] = list
    end
end

function widget:Shutdown()
    widgetHandler:DeregisterGlobal('AwardAward')
end

function widget:GameOver()
    Spring.SendCommands('endgraph 0')    
end

function AwardAward(name, action, first, first_score, second, second_score, third, third_score)

    -- Create the chili element containing the awards
    createContainer()
    --
    
    if true then return end --WIP    

    local award = {}
    createAward(award)
    
end

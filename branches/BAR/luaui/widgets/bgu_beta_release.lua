function widget:GetInfo()
    return {
        name    = 'Beta Release Menu',
        desc    = 'They said it would never happen',
        author  = 'Bluestone',
        date    = 'August 2015',
        license = 'GNU GPL v2',
        layer   = 0,
        enabled = true
    }
end


------------
-- Vars

local Chili, container, stackPanel
local playerListByTeam = {}

local initialText = "Welcome to the BAR Beta Release!\n\nPlease choose a mission from the menu on the left, or press esc to close this menu and continue in sandbox mode."

local selectedBorderColor = {1,127/255,0,0.45}
local normalBorderColor = {1,1,1,0.1}
local selectedButton

------------

function ReadScript(file)
    return VFS.LoadFile('luaui/configs/beta_release_scripts/'..file, VFS.ZIP_ONLY)
end

local options = {}
local info = {}
local script = {}
--[[options.chickens = {
    ["CHICKEN_DIFFICULTY"] = {},
    ["CHICKEN_QUEEN_DIFFICULTY"] = {},
    ["MAPNAME"] = {},
}]]
options["AI Skirmish"] = {
    ["MAPNAME"] = {
        humanName = "Map",
        [1] = "Tundra", --TODO: choose maps
        [2] = "Talus",
    },
}
info["AI Skirmish"] = "Fight against an AI!\n\nStart positions are randomly chosen."
script["AI Skirmish"] = ReadScript("ai.txt")



------------

function round(num, idp)
  return string.format("%." .. (idp or 0) .. "f", num)
end

function DeselectButtons()
    for _,child in ipairs(selectionPanel.children) do
        if child.caption~="line" then child.borderColor = normalBorderColor end
    end
end

local function Load (self)
    DeselectButtons()
    self.borderColor = selectedBorderColor
    selectedButton = self
    
    optionsBox:ClearChildren()

    local gameMode = self.caption
    local options = options[gameMode] or {} -- {} prevents crash for wip game modes
    
    textInfoBox:SetText(info[gameMode])
    
    for name,choices in pairs(options) do
        local thisOption = Chili.LayoutPanel:New{
            parent = optionsBox,
            name = name,
            width = tostring(100/math.max(2,#options)) .. '%',
            height = '100%',
            orientation = "vertical", 
            resizeItems = false,
        }
        Chili.Label:New{
            parent = thisOption,
            caption = choices.humanName,
            width = '100%',
            height = 20,
            
        }
        Chili.ComboBox:New{
            parent = thisOption,
            name = "comboBox",
            items = choices,   
            width = '100%',
        }
    end

end

function Start()
    if not selectedButton then return end
    local gameMode = selectedButton.caption
    local startScript = script[gameMode]
    
    for _,child in ipairs(optionsBox.children) do
        local name = child.name
        local comboBox = child:GetChildByName("comboBox")
        local choice = comboBox.items[comboBox.selected]
        startScript = string.gsub(startScript, name, choice)    
    end
    
    Spring.Reload(startScript)
end

------------

local function AddToMenu()

    container = Chili.Control:New{
        x        = 0,
        y        = 0,
        right    = 0,
        bottom   = 0,
        width    = '100%',
        height   = '100%',
    }
    
    optionsBox = Chili.Panel:New{
        parent  = container,
        x       = '50%',
        y       = '0%',
        width   = '50%',
        height  = '20%',    
    }

    textInfoBox = Chili.TextBox:New{width='100%',text=initialText, padding = {8,8,8,8}}    
    textInfoScrollPanel = Chili.ScrollPanel:New{
        parent      = container,
        x           = '50%',
        y           = '20%',
        width       = '50%',
        height      = '50%',
        resizeItems = false,
        autosize    = true,
        padding     = {0,0,0,0},
        children = { 
            textInfoBox
        }
    }

    textWarningBox = Chili.TextBox:New{width='100%',text="", padding = {8,8,8,8}}    
    textWarningScrollPanel = Chili.ScrollPanel:New{
        parent      = container,
        x           = '50%',
        y           = '70%',
        width       = '50%',
        height      = '20%',
        resizeItems = false,
        autosize    = true,
        padding     = {0,0,0,0},
        children = { 
            textWarningBox
        }
    }

    startButton = Chili.Button:New{
        parent = container,
        x = '50%',
        y = '90%',
        height = '10%',
        width = '50%',
        caption = "START",
        OnClick = {Start},
        borderColor = {0.2,1,0.2,0.35}
    }
    

    selectionPanel = Chili.StackPanel:New{
        parent = container,
        x = 0,
        y = 0,
        width = '50%',
        height = '100%',
        itemMargin = {2,2,2,2},
        orientation = "vertical",
        resizeItems = true,
        children = {
            Chili.Line:New{width = '50%', height = 2},
            Chili.Button:New{height = 70, width = '80%', caption = "AI Skirmish", OnClick = {Load},},
            Chili.Line:New{width = '50%', height = 2},
            Chili.Button:New{height = 70, width = '80%', caption = "Chickens (Tower Defence)", OnClick = {Load},},
            Chili.Line:New{width = '50%', height = 2},
            Chili.Button:New{height = 70, width = '80%', caption = "Mission 1: Glacier", OnClick = {Load},},
            Chili.Button:New{height = 70, width = '80%', caption = "Mission 2: ?", OnClick = {Load},},
            Chili.Button:New{height = 70, width = '80%', caption = "Mission 3: ?", OnClick = {Load},},
            Chili.Line:New{width = '50%', height = 2},
        }    
    }
    
    WG.MainMenu.AddControl('Beta Release', container, 100)
end

------------

function widget:Initialize()
    if not WG.Chili then return end
    
    Chili = WG.Chili
    AddToMenu()
    
end

function widget:ShutDown()
end

function widget:GameOver()
end

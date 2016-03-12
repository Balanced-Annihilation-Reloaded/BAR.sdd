-- WIP
function widget:GetInfo()
    return {
        name    = 'Clock and FPS',
        desc    = 'Small panel to show clock, FPS indicator and button for main menu',
        author  = 'Funkencool, Bluestone',
        date    = '2013',
        license = 'GNU GPL v2',
        layer   = 10,
        enabled = true
    }
end

local spGetFPS = Spring.GetFPS
local Chili, Menu
local clockType = "ingame" -- or "system", meaning ingame time or system time
local oTime,rTime
local timeFormatStr = '%I:%M:%S'

local options = {}

local function round(num, idp)
  return string.format("%." .. (idp or 0) .. "f", num)
end

local buttonColour, panelColour, sliderColour 

local function setGameTime(n)
    -- Possibly add option to include time paused?
    -- local gameSeconds = Spring.GetGameSeconds()
    local gameSeconds = math.floor(n / 30)
    local seconds = round(gameSeconds % 60)
    if string.len(seconds)==1 then seconds = "0" .. seconds end
    local minutes = round((gameSeconds - seconds) / 60)
    timeLbl:SetCaption('\255\255\127\1 '.. minutes .. ":" .. seconds)
end

local function setRealTime(rTime)
    oTime = rTime
    if string.find(rTime,'0')==1 then rTime = string.sub(rTime,2) end
    timeLbl:SetCaption('\255\255\127\1'..string.lower(rTime))
end

local function loadOptions()
    Menu.AddWidgetOption{
        title = 'Clock',
        name = widget:GetInfo().name,
        children = {
            Chili.ComboBox:New{
                x        = '0%',
                width    = '100%',
                items    = {"Ingame time", "System clock"},
                selected = (options.clockType=="system" and 2) or 1,
                OnSelect = {
                    function(_,sel)
                        if sel == 1 then
                            setGameTime(Spring.GetGameFrame())
                            clockType = 'ingame'
                        else
                            setRealTime(os.date(timeFormatStr))
                            clockType = 'system'
                        end
                        options.clockType = clockType
                    end
                }
            },
        }
    }
    
    if clockType=='ingame' then
        timeLbl:SetCaption('\255\255\127\0 00:00')
    end

end

local function loadMinMenu()
    
    timeLbl = Chili.Label:New{
        caption = os.date('%I:%M %p'),
        x = 0,
        y = 1,
    }
    
    fpsLbl = Chili.Label:New{
        caption = 'FPS:   ',
        x = 59,
        y = 1,
    }
    
    menuBtn = Chili.Button:New{
        caption = 'Menu', 
        right   = 0,
        height  = '100%', 
        width   = 50,
        borderColor = {0,0,0,0},
        backgroundColor = sliderColour,
        Onclick = {
            function() 
                WG.MainMenu.ShowHide() 
            end
        },
    }
    
    minMenu = Chili.Window:New{
        parent    = Chili.Screen0,
        right     = 210, 
        y         = 80, 
        width     = 180,
        minheight = 20, 
        height    = 20,
        padding   = {5,0,0,0},
        color = buttonColour,
        caption = "",
        children  = {timeLbl,fpsLbl,menuBtn}
    }
end

function widget:Initialize()
    Chili = WG.Chili  
    buttonColour = WG.buttonColour
    panelColour = WG.panelColour
    sliderColour = WG.sliderColour
    
    Menu = WG.MainMenu
    loadMinMenu()
    if Menu then
        loadOptions()
    end
    
    Spring.SendCommands('fps 0')
    Spring.SendCommands('clock 0')
end

function widget:Update()

    local fps = 'FPS: '..'\255\255\127\0'..spGetFPS()
    fpsLbl:SetCaption(fps)
    
    if clockType=="system" then
        local rTime = os.date(timeFormatStr)
        if oTime ~= rTime then setRealTime(rTime) end
    end

end

function widget:GameFrame(n)
    if n%30~=0 then return end
    if clockType=="ingame" then setGameTime(n) end
end

function widget:ShutDown()
    Spring.SendCommands('fps 1')
    Spring.SendCommands('clock 1')
end

function widget:GetConfigData()
    return options
end

function widget:SetConfigData(data)
    if data then
        options = data
    end
end

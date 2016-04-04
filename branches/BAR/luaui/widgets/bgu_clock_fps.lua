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
local Chili, Menu, fontSize
local clockType = "ingame" -- or "system", meaning ingame time or system time
local oTime,rTime
local timeFormatStr = '%I:%M:%S'
local relFontSize = 14

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
        x = '2%',
        y = '10%',
        font = {size=fontSize},
    }
    
    fpsLbl = Chili.Label:New{
        caption = 'FPS:   ',
        x = '33%',
        y = '10%',
        font = {size=fontSize},
    }
    
    menuBtn = Chili.Button:New{
        caption = 'Menu', 
        right   = '2%',
        y = '0%',
        width   = '30%',
        height = '100%',
        --borderColor = {0,0,0,0},
        backgroundColor = sliderColour,
        font = {size=fontSize},
        Onclick = {
            function() 
                WG.MainMenu.ShowHide() 
            end
        },
    }
    
    minMenu = Chili.Window:New{
        parent    = Chili.Screen0,
        padding   = {0,0,0,0},
        color = buttonColour,
        caption = "",
        minheight = 0,
        children  = {timeLbl,fpsLbl,menuBtn}
    }
    
    ResizeUI()
end

function widget:Initialize()
    Chili = WG.Chili  
    buttonColour = WG.buttonColour
    panelColour = WG.panelColour
    sliderColour = WG.sliderColour
    fontSize = WG.RelativeFontSize(relFontSize)
    
    Menu = WG.MainMenu
    loadMinMenu()
    if Menu then
        loadOptions()
    end
    
    Spring.SendCommands('fps 0')
    Spring.SendCommands('clock 0')
end

local nextUpdateTime = 0
local updateInterval = 0.25 --seconds
local curTime = 0
function widget:Update(dt)
    curTime = curTime + dt
    if curTime<nextUpdateTime then
        return 
    end
    nextUpdateTime = curTime + updateInterval
        
    
    
    local fps = 'FPS: '..'\255\255\127\0'..spGetFPS()
    fpsLbl:SetCaption(fps)
    
    if clockType=="system" then
        local rTime = os.date(timeFormatStr)
        if oTime ~= rTime then setRealTime(rTime) end
    end
end

function widget:ViewResize()
    ResizeUI()
end

function ResizeUI()
    local x = WG.UIcoords.clockFPS.x
    local y = WG.UIcoords.clockFPS.y
    local w = WG.UIcoords.clockFPS.w
    local h = WG.UIcoords.clockFPS.h
    minMenu:SetPos(x,y,w,h)
    
    fontSize = WG.RelativeFontSize(relFontSize)
    timeLbl.font.size = fontSize
    timeLbl:Invalidate()
    fpsLbl.font.size = fontSize
    fpsLbl:Invalidate()
    menuBtn.font.size = fontSize
    menuBtn:Invalidate()
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

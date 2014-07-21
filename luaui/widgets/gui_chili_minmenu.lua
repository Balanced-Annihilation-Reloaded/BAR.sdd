-- WIP
function widget:GetInfo()
    return {
        name    = 'Funks Min Menu',
        desc    = 'Small Window to access Main Menu, as well as show time and FPS',
        author  = 'Funkencool',
        date    = '2013',
        license = 'GNU GPL v2',
        layer   = 10,
        handler = true,
        enabled = true
    }
end

local spGetFPS = Spring.GetFPS
local Chili
local clockType = "ingame" -- or "system", meaning ingame time or system time
local oTime,rTime

local function loadMinMenu()
    
    timeLbl = Chili.Label:New{
        caption = '10:30pm',
        x       = 0
    }
    
    fpsLbl = Chili.Label:New{
        caption = 'FPS: 65',
        x       = 65
    }
    
    menuBtn = Chili.Button:New{
        caption = 'Menu', 
        right   = 0,
        height  = '100%', 
        width   = 50,
        Onclick = {
            function() 
                WG.MainMenu.ShowHide() 
            end
        },
    }
    
    minMenu = Chili.Window:New{
        parent    = Chili.Screen0,
        right     = 210, 
        y         = 60, 
        width     = 180,
        minheight = 20, 
        height    = 20,
        padding   = {5,0,0,0},
        children  = {timeLbl,fpsLbl,menuBtn}
    }
end

function dbl(s)
    if s<9 then
        return "0" .. s
    else
        return s
    end
end

function widget:Initialize()
    Chili = WG.Chili
    loadMinMenu()
    Menu = WG.MainMenu
    
    clockType = Menu.Load('clockType') or clockType
    
    local function onSelect(obj, v)
        if (v==1) then clockType="ingame" else clockType="system" end
        
        if clockType=='ingame' then 
            local n = Spring.GetGameFrame()
            local gameSeconds = math.floor(n / 30)
            local seconds = gameSeconds % 60
            local minutes = (gameSeconds - seconds) / 60
            timeLbl:SetCaption('\255\255\127\0 '.. dbl(minutes) .. ":" .. dbl(seconds))
        else
            local rTime = os.date('%I:%M %p')
            oTime = rTime
            if string.find(rTime,'0')==1 then rTime = string.sub(rTime,2) end
            timeLbl:SetCaption('\255\255\127\0'..string.lower(rTime))
        end
        
        Menu.Save('clockType', clockType)
    end
    
    local options = Chili.Control:New{
        x        = 0,
        width    = '100%',
        height   = 35,
        padding  = {0,0,0,0},
        children = {
            Chili.Label:New{caption='Clock',x=0,y=0},
            Chili.ComboBox:New{
                width = 200,
                y = 15,
                right = 0,
                items = {"Ingame time", "System clock"},
                selected = ((clockType=="ingame") and 1 or 2),
                OnSelect={onSelect}
            },
            Chili.Line:New{y=30,width='100%'},
        }
    }
    
    Menu.AddToStack('Interface', options)
    
    if clockType=='ingame' then
        timeLbl:SetCaption('\255\255\127\0 '.. dbl(0) .. ":" .. dbl(0))
    end
end

function widget:Update()
    local fps = 'FPS: '..'\255\255\127\0'..spGetFPS()
    fpsLbl:SetCaption(fps)
    if clockType=="system" then
        local rTime = os.date('%I:%M %p')
        if oTime ~= rTime then
            oTime = rTime
            if string.find(rTime,'0')==1 then rTime = string.sub(rTime,2) end
            timeLbl:SetCaption('\255\255\127\0'..string.lower(rTime))
        end
    end
end

function widget:GameFrame(n)
    if n%30~=0 then return end
    if clockType=="ingame" then
        local gameSeconds = n / 30
        local seconds = gameSeconds % 60
        local minutes = (gameSeconds - seconds) / 60
        timeLbl:SetCaption('\255\255\127\0 '.. dbl(minutes) .. ":" .. dbl(seconds))
    end
end
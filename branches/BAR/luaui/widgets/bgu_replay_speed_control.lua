function widget:GetInfo()
    return {
        name = "Replay Speed Controls",
        desc = "Add buttons to change replay speed",
        author = "Bluestone", 
        date = "",
        license = "GPL v2 or later",
        layer = 0,
        enabled = true,        
    }
end

local wantedAllowedSpeeds = {0.5, 1, 2, 5, 10, 20} -- in order
local allowedSpeeds = {}
local selectedSpeed
local wantedSpeed 
local minSpeed, maxSpeed 

local Chili
local window, stack
local buttonW = 60
local buttonH = 50
local labelH = 25
local selectedBorderColor = {1,127/255,0,0.75}
local normalBorderColor = {1,1,1,0.1}

local settings = {}

-------------------

function SetReplaySpeed (obj)
    local speed = obj.speed
    currentSpeed,_,paused = Spring.GetGameSpeed()    
    
    if speed=="pause" then
        Spring.SendCommands("pause")
        return 
    end
        
    --Spring.Echo ("setting speed to: " .. speed  .. ", current is " .. currentSpeed)
    if (speed > currentSpeed) then    --speedup
        Spring.SendCommands ("setminspeed " .. speed)
        Spring.SendCommands ("setminspeed " .. minSpeed)
    else    --slowdown
        Spring.SendCommands("setmaxspeed " .. speed) 
        Spring.SendCommands ("setmaxspeed " .. maxSpeed)        
    end    
end

function widget:Update()
    -- check we have the right button highlighted (user may change speed themselves)
    currentSpeed,_,paused = Spring.GetGameSpeed()    
    if (paused and selectedSpeed~="pause") or (currentSpeed~=selectedSpeed) then
        ResetBorderColors()
        selectedSpeed = currentSpeed
    end
end

-------------------

function ChooseAllowedSpeeds()
    minSpeed = tonumber(Spring.GetModOptions().minspeed) or 0
    maxSpeed = tonumber(Spring.GetModOptions().maxspeed) or math.huge
    allowedSpeeds[1] = "pause"
    local usedSpeeds = {}
    for _,speed in pairs(wantedAllowedSpeeds) do
        if speed<=minSpeed and not usedSpeeds[minSpeed] then 
            table.insert(allowedSpeeds,minSpeed)
            usedSpeeds[minSpeed] = true
        elseif speed>=maxSpeed and not usedSpeeds[maxSpeed] then
            table.insert(allowedSpeeds,maxSpeed)
            usedSpeeds[maxSpeed] = true
        elseif speed>minSpeed and speed<maxSpeed and usedSpeeds[speed]==nil then
            table.insert(allowedSpeeds,speed)
            usedSpeeds[speed] = true
        end        
    end
end

-------------------

function createSpeedButton (speed)
    local button = Chili.Button:New{
        speed     = speed,
        caption   = tostring(speed),
        width     = buttonW,
        height    = buttonH,
        padding   = {0,0,0,0},
        margin    = {0,0,0,0},
        OnMouseUp = {SetReplaySpeed},
        font      = {
            size  = 16,
        },
    }
    stack:AddChild(button)
end

function widget:Initialize()
    if (not Spring.IsReplay()) then
        widgetHandler:RemoveWidget(self)
        return
    end
    
    ChooseAllowedSpeeds()
    
    Spring.Echo("IN")
    
    -- set up Chili stuff
    Chili = WG.Chili    
    local Screen0 = Chili.Screen0
    
    window = Chili.Window:New{
        parent    = Screen0,
        name      = 'replay speed control window',
        right     = 325,
        bottom    = 100,
        height    = (#allowedSpeeds) * buttonH + labelH,
        width     = buttonW,
        draggable = true,
        padding     = {0,0,0,0},
        itemPadding = {0,0,0,0},
        itemMargin  = {0,0,0,0},
        draggable = true,
    }
    stack = Chili.LayoutPanel:New{
        parent      = window,
        name        = 'replay speed control stack',
        width       = '100%',
        height      = '100%',
        resizeItems = false,
        padding     = {0,0,0,0},
        itemPadding = {0,0,0,0},
        itemMargin  = {0,0,0,0},
        children    = {},
        preserveChildrenOrder = true,
    }
    
    local label = Chili.Label:New{
        parent    = stack, 
        caption   = "speed",
        width     = '100%',
        height    = 0,
        y         = 10,
        padding   = {0,0,0,0},
        margin    = {0,0,0,0},
        OnMouseUp = {},
        font      = {
            size  = 16,
            color = {1,127/255,0,1}
        },
    }    
    
    for _,speed in ipairs(allowedSpeeds) do
        createSpeedButton(speed)
    end
    
    if settings.x and settings.y then
        window:SetPos(settings.x,settings.y)
    end
end

function ResetBorderColors()
    for _,child in ipairs(stack.children) do
        if child.speed then SetBorderColor(child) end
    end
end

function SetBorderColor(button)
    if (button.speed=="pause" and paused) or (button.speed~="pause" and math.abs(button.speed-currentSpeed)<0.01) then
        button.borderColor = selectedBorderColor
    else
        button.borderColor = normalBorderColor
    end
end

-------------------

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



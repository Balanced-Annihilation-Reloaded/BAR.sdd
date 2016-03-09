-- WIP
function widget:GetInfo()
    return {
        name    = 'Chat Console',
        desc    = 'Displays the chat history', -- chonsole handles chat input
        author  = 'Funkencool, Bluestone',
        date    = '2013',
        license = 'GNU GPL v2',
        layer   = 50,
        enabled = true
    }
end

-- Spring Functions --
include("keysym.h.lua")
local spGetTimer         = Spring.GetTimer
local spDiffTimers       = Spring.DiffTimers
local spSendCommands     = Spring.SendCommands
local spGetConsoleBuffer = Spring.GetConsoleBuffer
local spGetPlayerRoster  = Spring.GetPlayerRoster
local spGetTeamColor     = Spring.GetTeamColor
local spGetMouseState    = Spring.GetMouseState
local spGetDrawFrame   = Spring.GetDrawFrame
local ssub = string.sub
local slen = string.len
local sfind = string.find
----------------------


-- Config --
local cfg = {
    msgTime  = 8, -- time to display messages in seconds
    hideChat = true,
    msgCap   = 50,
}
local fontSize = 16
------------

-- Chili elements --
local Chili
local screen
local window
local msgWindow
local log
local buttonColour, panelColour, sliderColour 
--------------------

-- Local Variables --
local messages = {}
local endTime = spGetTimer() 
local startTime = endTime --time of last message (or last time at which we checked to hide the console and then didn't)
local myID = Spring.GetMyPlayerID()
local myAllyID = Spring.GetMyAllyTeamID()
local gameOver = false --is the game over?
---------------------

-- Text Colour Config --
local color = {
    oAlly = '\255\255\128\128', --enemy ally messages (seen only when spectating)
    misc  = '\255\200\200\200', --everything else
    game  = '\255\102\255\255', --server (autohost) chat
    other = '\255\255\255\255', --normal chat color
    ally  = '\255\001\255\001', --ally chat
    spec  = '\255\255\255\001', --spectator chat
}

local function mouseIsOverChat()
    local x,y = spGetMouseState()
    y = screen.height - y -- chili has y axis with 0 at top!    
    if x > window.x and x < window.x + window.width and y > 0 and ((msgWindow.visible and y < window.height) or (msgWindow.hidden and y < msgWindow.height)) then
        return true
    else
        return false
    end
end

local function showChat()
    -- show chat
    startTime = spGetTimer()
    if msgWindow.hidden then
        msgWindow:Show()
    end
end

local function hideChat()
    -- hide the chat, unless the mouse is hovering over the chat window
    if msgWindow.visible and cfg.hideChat and not mouseIsOverChat() then
        msgWindow:Hide()
    end
end

local function getConsoleDimensions(vsx, vsy)
    local r_avoid = 450/vsx -- distance/vsx of left edge of resbars from right of screen
    local l_avoid = vsy*0.2*1.06/vsx+200/vsx -- distance/vsx of right edge of state menu from left of screen
    local l_loc = math.max(l_avoid, 0.26) -- chonsole is at 0.26
    local r_loc = math.max(0, 1.0-r_avoid)
    local w = math.max(0, r_loc-l_loc)*vsx
    local x = l_loc*vsx
    local h = vsy*0.18
    return x,w,h
end


local screenResized = true
local hackResize = true
function widget:ViewResize(viewSizeX, viewSizeY)
    local x,w,h = getConsoleDimensions(viewSizeX, viewSizeY)
    window:SetPos(x,1,w,h)
    hackResize = spGetDrawFrame()+1
    screenResized = true  
end

local function loadWindow()
    
    -- parent
    window = Chili.Control:New{
        parent  = screen,
        width   = minChatWidth,
        color   = {0,0,0,0},
        height  = 0,
        padding = {0,0,0,0},
        y       = 0,
    }
    
    -- chat box
    msgWindow = Chili.ScrollPanel:New{
        verticalSmartScroll = true,
        scrollPosX  = 0,
        scrollPosY  = 0,        
        parent      = window,
        x           = 0,
        y           = 0,
        right       = 0,
        bottom      = 0,
        padding     = {0,0,0,0},
        borderColor = {0,0,0,0},
        backgroundColor = sliderColour, -- controls the scroll slider
        knobcolorselected = {1,1,1,1}, -- slider button when hovered
        
    }

    log = Chili.StackPanel:New{
        parent      = msgWindow,
        x           = 0,
        y           = 0,
        height      = 0,
        width       = '100%',
        autosize    = true,
        resizeItems = false,
        padding     = {0,0,0,0},
        itemPadding = {3,0,3,2},
        itemMargin  = {3,0,3,2},
        preserveChildrenOrder = true,
    }
    
    widget:ViewResize(screen.width, screen.height)
end

local function loadOptions()
    for key,_ in pairs(cfg) do
        local value = Menu.Load(key)
        if value or type(value)=='boolean' then 
            cfg[key] = value 
        end
        Menu.Save(cfg)
    end

    Menu.AddWidgetOption{
        title = 'Chat',
        name = widget:GetInfo().name,
        children = {
            Chili.Checkbox:New{
                caption  = 'Auto-Hide Chat',
                x        = '10%',
                width    = '80%',
                checked  = cfg.hideChat,
                OnChange = {
                    function()
                        cfg.hideChat = not cfg.hideChat
                        Menu.Save{hideChat=cfg.hideChat}
                        if not cfg.hideChat then showChat() end
                    end
                }
            },
            
            Chili.Label:New{caption='Delay (seconds)'},
            Chili.Trackbar:New{
                x        = '10%',
                width    = '80%',
                min      = 1,
                max      = 10,
                step     = 1,
                value    = cfg.msgTime,
                OnChange = {function(_,value) cfg.msgTime=value; Menu.Save{msgTime=value} end}
            },            
        }
    }
end

local function getInline(r,g,b)
    if type(r) == 'table' then
        return string.char(255, (r[1]*255), (r[2]*255), (r[3]*255))
    else
        return string.char(255, (r*255), (g*255), (b*255))
    end
end

function widget:Initialize()
    Chili  = WG.Chili
    screen = Chili.Screen0
    buttonColour = WG.buttonColour
    panelColour = WG.panelColour
    sliderColour = WG.sliderColour    
    Menu   = WG.MainMenu
    
    if Menu then 
        loadOptions() 
    end
    
    loadWindow()
    
    -- disable engine console
    spSendCommands('console 0')    
end


function widget:Update()
    -- if console has been visible for longer than msgTime since last event, see if its not needed anymore
    endTime = spGetTimer()
    if spDiffTimers(endTime, startTime) > cfg.msgTime then
        startTime = endTime
        hideChat()
    end
    if screenResized then
        -- without this, chili mangles the children of the console stackpanel when the screen is resized
        -- for some reason, it usually un-mangles as soon as a new chat message is sent
        -- so we block the engines message about window resized and send our own just afterwards to make it un-mangle 
        -- this is a hacky workaround, but it works!
        local vsx,vsy = Spring.GetViewGeometry()
        Spring.Echo("Set view resolution: " .. vsx .. " x " .. vsy)
        screenResized = nil
    end   
    if hackResize==spGetDrawFrame() then
        -- another mechanism to wake chili up when it needs to redraw the stackpanel
        window:Resize(window.width-1)
        window:Resize(window.width+1)
        hackResize = nil
    end    
end

function widget:GameOver()
    gameOver = true
end

local function processLine(line)

    -- get data from player roster 
    local roster = spGetPlayerRoster()
    local names = {}
    
    for i=1,#roster do
        names[roster[i][1]] = {
            ID     = roster[i][2],
            allyID = roster[i][4],
            spec   = roster[i][5],
            teamID = roster[i][3],
            color  = getInline(spGetTeamColor(roster[i][3])),
        }
    end
    -------------------------------
    
    local name = ''
    local dedup = 1
    
    if (names[ssub(line,2,(sfind(line,"> ") or 1)-1)] ~= nil) then
        -- Player Message
        name = ssub(line,2,sfind(line,"> ")-1)
        text = ssub(line,slen(name)+4)
        dedup = 5
    elseif (names[ssub(line,2,(sfind(line,"] ") or 1)-1)] ~= nil) then
        -- Spec Message
        name = ssub(line,2,sfind(line,"] ")-1)
        text = ssub(line,slen(name)+4)
        dedup = 5
    elseif (names[ssub(line,2,(sfind(line,"(replay)") or 3)-3)] ~= nil) then
        -- Spec Message (replay)
        name = ssub(line,2,sfind(line,"(replay)")-3)
        text = ssub(line,slen(name)+13)
        dedup = 5
    elseif (names[ssub(line,1,(sfind(line," added point: ") or 1)-1)] ~= nil) then
        -- Map point
        name = ssub(line,1,sfind(line," added point: ")-1)
        text = ssub(line,slen(name.." added point: ")+1)
        dedup = 5
    elseif (ssub(line,1,1) == ">") then
        -- Game Message
        text = ssub(line,3)
        dedup = 1
        if ssub(line,1,3) == "> <" then --player speaking in battleroom
            local i = sfind(ssub(line,4,slen(line)), ">")
            name = ssub(line,4,i+2)
        end
    elseif sfind(line,'-> Version') or sfind(line,'ClientReadNet') or sfind(line,'Address') or (gameOver and sfind(line,'left the game')) or sfind(line,'video mode set to') or sfind(line, 'RectangleOptimizer') then --surplus info when user connects
        -- Filter out unwanted engine messages
        return _, true, _ --ignore
    end
    
    if WG.ignoredPlayers and WG.ignoredPlayers[name] then
        -- Filter out ignored players
        return _,true, _ --ignore 
    end
    
    if names[name] then
        local player = names[name]
        local textColor = color.other
        local nameColor = color.other
        
        if player.spec then
            nameColor = color.spec
            if text:find('Spectators: ') or text:find('Allies: ') then
                textColor = color.spec
            end
        else
            nameColor = player.color
            if text:find('Allies: ') then
                if player.allyID == myAllyID then
                    textColor = color.ally
                else
                    textColor = color.oAlly
                end
            elseif text:find('Spectators: ') then
                textColor = color.spec            
            end
        end
        -- Get rid of any (now) unneeded info in the text
        text = text:gsub('Allies: ','')
        text = text:gsub('Spectators: ','')
        line = nameColor .. name .. ': ' .. textColor .. text
    end

    return color.misc .. line, false, dedup
end

local consoleBuffer = ""
function widget:AddConsoleLine(msg)
    -- parse the new line
    local text, ignore, dedup = processLine(msg)
    if ignore then return end

    -- check for duplicates
    for i=0,dedup-1 do
        local prevMsg = log.children[#log.children - i]
        if prevMsg and (text == prevMsg.text or text == prevMsg.origText) then
            prevMsg.duplicates = prevMsg.duplicates + 1
            showChat()
            prevMsg.origText = text
            prevMsg:SetText(getInline{1,0,0}..(prevMsg.duplicates + 1)..'x \b'..text)
            return
        end
    end
    
    NewConsoleLine(text)
end

function NewConsoleLine(text)
    --    avoid creating insane numbers of children (chili can't handle it)
    if #log.children > cfg.msgCap then
        log:RemoveChild(log.children[1])
    end
    
    -- print text into the console
    Chili.TextBox:New{
        parent      = log,
        text        = text,
        width       = '100%',
        autoHeight  = true,
        autoObeyLineHeight = true,
        align       = "left",
        valign      = "ascender",
        padding     = {0,0,0,0},
        duplicates  = 0,
        font        = {
            outline          = true,
            autoOutlineColor = true,
            outlineWidth     = 4,
            outlineWeight    = 3,
            size             = fontSize,
        },
    }
    
    showChat()
    hackResize = spGetDrawFrame()+1
end

function widget:KeyPress(key, mods, isRepeat)

    -- show the chat window when we send a message
    if (key == KEYSYMS.RETURN) then
        showChat()
    end 

    -- if control is pressed and the mouse is hovering over the text input box, show the console 
    if mods.ctrl and mouseIsOverChat() then
        showChat()
    end

end

function widget:Shutdown()
end

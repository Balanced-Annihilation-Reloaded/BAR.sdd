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
local getTimer         = Spring.GetTimer
local diffTimers       = Spring.DiffTimers
local sendCommands     = Spring.SendCommands
local setConfigString  = Spring.SetConfigString
local getConsoleBuffer = Spring.GetConsoleBuffer
local getPlayerRoster  = Spring.GetPlayerRoster
local getTeamColor     = Spring.GetTeamColor
local getMouseState    = Spring.GetMouseState
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
--------------------

-- Local Variables --
local messages = {}
local endTime = getTimer() 
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
    local x,y = Spring.GetMouseState()
    y = screen.height - y -- chili has y axis with 0 at top!    
    if x > window.x and x < window.x + window.width and y > 0 and ((msgWindow.visible and y < window.height) or (msgWindow.hidden and y < 60)) then
        return true
    else
        return false
    end
end

local function showChat()
    -- show chat
    startTime = getTimer()
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
    local w1 = math.max(vsx-450,0)/vsx-0.26 -- width proportion to avoid resbars
    local w = math.min(vsx*0.5, vsx*w1) 
    local x = vsx*0.26
    local h = vsy*0.18
    return x,w,h
end


local screenResized = true
function widget:ViewResize(viewSizeX, viewSizeY)
    local x,w,h = getConsoleDimensions(viewSizeX, viewSizeY)
    window:SetPos(x,0,w,h)
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
            
            Chili.Line:New{width='100%'}
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
    Menu   = WG.MainMenu
    
    if Menu then 
        loadOptions() 
    end
    
    loadWindow()
    
    -- disable engine console
    sendCommands('console 0')    
end


function widget:Update()
    -- if console has been visible for longer than msgTime since last event, see if its not needed anymore
    endTime = getTimer()
    if diffTimers(endTime, startTime) > cfg.msgTime then
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
        screenResized = false
    end    
end

function widget:GameOver()
    gameOver = true
end

local function processLine(line)

    -- get data from player roster 
    local roster = getPlayerRoster()
    local names = {}
    
    for i=1,#roster do
        names[roster[i][1]] = {
            ID     = roster[i][2],
            allyID = roster[i][4],
            spec   = roster[i][5],
            teamID = roster[i][3],
            color  = getInline(getTeamColor(roster[i][3])),
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
            name = '(s) '.. name
            textColor = color.spec
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

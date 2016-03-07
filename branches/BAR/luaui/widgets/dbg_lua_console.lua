-- WIP
function widget:GetInfo()
    return {
        name    = 'Debug Console',
        desc    = 'Displays errors', 
        author  = 'Bluestone',
        date    = '2016',
        license = 'GNU GPL v2',
        layer   = 50,
        enabled = false
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
local slower = string.lower
----------------------


-- Config --
local cfg = {
    msgCap   = 20, 
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
    red   = '\255\255\001\001', 
    orange= '\255\255\165\001',
    blue  = '\255\001\255\255',
}

function loadWindow()
    
    -- parent
    window = Chili.Window:New{
        parent  = screen,
        draggable = true,
        resizable = true,
        width   = '35%',
        x = '60%',
        y = '25%',
        height = '40%',
        itemPadding = {5,5,10,10},
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
        itemPadding = {3,0,3,8},
        itemMargin  = {3,0,3,2},
        preserveChildrenOrder = true,
    }   
    
end

function widget:Initialize()
    Chili  = WG.Chili
    screen = Chili.Screen0
    Menu   = WG.MainMenu
    
    loadWindow()
    
    local buffer = getConsoleBuffer(500)
    for _,l in ipairs(buffer) do
        if sfind(l.text, "LuaUI Entry Point:") then -- luaui reload happened here
            RemoveAllMessages()
        end
        widget:AddConsoleLine(l.text)    
    end    
    
end

function widget:Update()
    if not hack then return end
    local hack2 = Spring.GetDrawFrame()
    if hack2~=hack then
        window:Resize(window.width-1)
        window:Resize(window.width+1)
        hack = nil
    end
end

local function processLine(line)

    -- get data from player roster 
    local roster = getPlayerRoster()
    local names = {}
    
    for i=1,#roster do
        names[roster[i][1]] = true
    end
    -------------------------------
    
    local name = ''
    local dedup = cfg.msgCap
    
    if (names[ssub(line,2,(sfind(line,"> ") or 1)-1)] ~= nil) then
        -- Player Message
        return _, true, _ --ignore
    elseif (names[ssub(line,2,(sfind(line,"] ") or 1)-1)] ~= nil) then
        -- Spec Message
        return _, true, _ --ignore
    elseif (names[ssub(line,2,(sfind(line,"(replay)") or 3)-3)] ~= nil) then
        -- Spec Message (replay)
        return _, true, _ --ignore
    elseif (names[ssub(line,1,(sfind(line," added point: ") or 1)-1)] ~= nil) then
        -- Map point
        return _, true, _ --ignore
    elseif (ssub(line,1,1) == ">") then
        -- Game Message
        text = ssub(line,3)
        if ssub(line,1,3) == "> <" then --player speaking in battleroom
            return _, true, _ --ignore
        end
    else
        text = line
    end
    
    local lowerLine = slower(line) 
    if sfind(lowerLine,"error") then
        textColor = color.red
    elseif sfind(lowerLine,"warning") then
        textColor = color.orange
    else
        return _, true, _ --ignore
    end
    line = textColor .. text
    
    return line, false, dedup
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
            prevMsg.origText = text
            prevMsg:SetText(color.blue ..(prevMsg.duplicates + 1)..'x \b'..text)
            return
        end
    end
    
    NewConsoleLine(text)
    hack = hack or Spring.GetDrawFrame()+1
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
    
    invalidate = true
end

function RemoveAllMessages()
    log:ClearChildren()
end

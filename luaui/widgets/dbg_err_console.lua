-- WIP
function widget:GetInfo()
    return {
        name    = 'Debug Err Console',
        desc    = 'Displays errors', 
        author  = 'Bluestone',
        date    = '2016',
        license = 'GNU GPL v2',
        layer   = 50,
        enabled = false
    }
end

local ssub = string.sub
local slen = string.len
local sfind = string.find
local slower = string.lower

local Chili,screen,window,msgWindow,clearButton,reloadButton,log

-- Config --
local cfg = {
    msgCap      = 50, 
    reloadLines = 2000,
}
local fontSize = 16

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
        y = '30%',
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
        height      = '85%',
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
    
    clearButton = Chili.Button:New{
        parent = window,
        x = '2.5%',
        y = '85%',
        width = '30%',
        height = '15%',
        caption = "clear",
        tooltip = "clear all messages",
        OnClick = {function() RemoveAllMessages() end}
    }
    
    clearBeforeLastReset = Chili.Button:New{
        parent = window,
        x = '35%',
        y = '85%',
        width = '30%',
        height = '15%',
        tooltip = 'show messages since the most recent luaui/luarules reload',
        caption = "soft reload",
        OnClick = {function() RemoveAllMessages(); SoftReload() end}
    }

    clearButton = Chili.Button:New{
        parent = window,
        x = '67.5%',
        y = '85%',
        width = '30%',
        height = '15%',
        tooltip = 'show all messages',
        caption = "hard reload",
        OnClick = {function() RemoveAllMessages(); ReloadAllMessages() end}
    }        
end

function widget:Initialize()
    Chili  = WG.Chili
    screen = Chili.Screen0
    Menu   = WG.MainMenu
    
    loadWindow()
    ReloadAllMessages()    
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
    local roster = Spring.GetPlayerRoster()
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
    if sfind(lowerLine,"error") or sfind(lowerLine,"failed") then
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
end

function RemoveAllMessages()
    log:ClearChildren()
end

function ReloadAllMessages()
    local buffer = Spring.GetConsoleBuffer(cfg.reloadLines)
    for _,l in ipairs(buffer) do
        widget:AddConsoleLine(l.text)    
    end    
end

function SoftReload()
    local buffer = Spring.GetConsoleBuffer(cfg.reloadLines)
    for _,l in ipairs(buffer) do
        if sfind(l.text,"LuaUI Entry Point") or sfind(l.text,"LuaRules Entry Point") then
            RemoveAllMessages()
        end
        widget:AddConsoleLine(l.text)    
    end    

end

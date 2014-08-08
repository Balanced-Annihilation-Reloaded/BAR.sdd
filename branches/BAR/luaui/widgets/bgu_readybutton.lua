-- WIP
function widget:GetInfo()
	return {
		name    = 'Ready Button',
		desc    = 'Displays the ready button',
		author  = 'Bluestone',
		date    = '2013',
		license = 'GNU GPL v3',
		layer   = 0,
		enabled = true,
	}
end

local Chili, button, panel, text
local startTime, countDown, amNewbie
local countText = 'Game is starting in 3 seconds...'

local yellow = "\255\255\230\0"
local white = "\255\255\255\255"

function widget:Initialize()
    amNewbie = (Spring.GetTeamRulesParam(Spring.GetMyTeamID(), 'isNewbie') == 1)
    if amNewbie or Spring.GetGameFrame()>0 then
        widgetHandler:RemoveWidget()
    end

	Chili = WG.Chili
    
    window = Chili.Window:New{
        name = 'readybutton_window',
        parent = Chili.Screen0,
        right = 300,
        y = 200,
        height = 50,
        width = 100,
		padding     = {0,0,0,0},
		itemPadding = {0,0,0,0},
		itemMargin  = {0,0,0,0},
    }

    button = Chili.Button:New{
        name = 'readybutton',
        parent = window,
        height = 50,
        width = 100,
        caption = "Ready",   
        onclick = {ReadyUp},
        font = {
            size = 22,
        }
    }
    
    text = Chili.TextBox:New{
        name = 'gamestarting_text',
        height = '100%',
        width = '100%',
        text = "",
        font        = {
            outline          = true,
            outlineColor     = {0.8,0,0,1},
            autoOutlineColor = false,
            outlineWidth     = 2,
            outlineWeight    = 5,
            size             = 22,
        },
    }
    
    panel = Chili.LayoutPanel:New{
        name = 'gamestarting_panel',
        parent = Chili.Screen0,
        right = 400,
        y = 200,
        height = 45,
        width = 400,
		padding     = {0,0,0,0},
		itemPadding = {10,10,10,10},
		itemMargin  = {0,0,0,0},
        children = {text},
    }
    
    window:Show()
    panel:Hide()
        
	widgetHandler:RegisterGlobal('ReadyButtonState', ReadyButtonState)
end

function StartPointChosen()
    haveStartPoint = true
end

function ReadyButtonState(n) -- called by game_initial_spawn
    if n==0 and not window.hidden then
        window:Hide()
    elseif n==1 and window.hidden then
        window:Show()
    elseif n==2 then
        if not window.hidden then
            window:Hide()
        end
        panel:Show()
        startTime = Spring.GetTimer()
    end
end

function Update()
    if startTime then
        -- display count down
        local now = Spring.GetTimer()
        local dt = Spring.DiffTimers(now,startTime)
        if not countDown then
            countDown = 3
        end

        if dt > 3-countDown+1 and countDown>=1 then
            countDown = countDown - 1
            countText = 'Game is starting in ' .. countDown .. ' seconds...'
        end        
    
        -- flash text colour
        if dt % 0.75 <= 0.375 then
            text:SetText(white .. countText)
        else
            text:SetText(yellow .. countText)
        end
    end
end

function ReadyUp()
    local readyState = Spring.GetGameRulesParam("player_" .. tostring(Spring.GetMyPlayerID()) .. "_readyState") 
    local haveStartPoint = (readyState==4)
    if haveStartPoint then
        Spring.SendLuaRulesMsg('\157')
    else
        Spring.Echo("Please chose a start point!")
    end
end

function widget:GameStart()
    widgetHandler:RemoveWidget()
end

function widget:Shutdown()
	widgetHandler:DeregisterGlobal('ReadyButtonState')
end


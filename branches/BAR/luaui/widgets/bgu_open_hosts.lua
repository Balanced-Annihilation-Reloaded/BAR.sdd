
if not (Spring.GetConfigInt("LuaSocketEnabled", 0) == 1) then
	Spring.Echo("Lua Socket is disabled, Open Host List cannot run")
	return false
end

function widget:GetInfo()
return {
	name    = "Open Host List",
	desc    = "Shows a list of open hosts",
	author  = "Bluestone, dansan, abma, BrainDamage",
	date    = "June 2014",
	license = "GNU GPL, v2 or later",
	layer   = -5,
	enabled = true,
}
end


---------------------------------------------------------
------------- Get the data from the socket and process it into the battleList
---------------------------------------------------------

local socket = socket

local client
local set
local headersent

local host = "replays.springrts.com"
local port = 8222

local battleList = {} -- battleList[type][hostname] = battle, each subtable sorted by battle.playerCount
local battlePanels = {} -- battlePanels[hostname] = ChiliControl
local battleTypes = {['team']=6, ['ffa']=2, ['1v1']=2, ['chickens']=2} --battleTypes[type] = max number of this type to display
for t,_ in pairs(battleTypes) do
    battleList[t] = {}
end

local Chili, window, panel, showhide_button

local updateTime = 10
local prevTimer = Spring.GetTimer()
local needUpdate = true

local myPlayerID = Spring.GetMyPlayerID()
local amISpec = Spring.GetSpectatingState()

local function dumpConfig()
	-- dump all luasocket related config settings to console
	for _, conf in ipairs({"TCPAllowConnect", "TCPAllowListen", "UDPAllowConnect", "UDPAllowListen"  }) do
		Spring.Echo(conf .. " = " .. Spring.GetConfigString(conf, ""))
	end

end

-- split a string at the next line break, or return nil if there is no such line break
local function getLine(str)
    if not str then return nil,nil end
    local breakPos = string.find(str,'\n')
    if not breakPos then 
        return nil,nil
    else
        local line = string.sub(str,1,breakPos-2) .. ',' --remove the (two!?) end of line chars, add a final comma since it makes parsing the line easier 
        local data = string.sub(str,breakPos+1,string.len(str))
        return line,data
    end
end

-- turn the string "XX",YY into the pair of strings XX,YY
local function extract(str) 
    if not str then return nil,nil end
    local breakPos = string.find(str,',')
    if not breakPos then
        return nil,nil
    else
        local e = string.sub(str,2,breakPos-2)
        local line = string.sub(str,breakPos+1,string.len(str)) 
        return e,line
    end
end

-- i hate lua
function toboolean(v)
    return (type(v) == "string" and (v == "true" or v == "True")) or (type(v) == "number" and v ~= 0) or (type(v) == "boolean" and v)
end



-- something to do with sockets...
local function newset()
    local reverse = {}
    local set = {}
    return setmetatable(set, {__index = {
        insert = function(set, value)
            if not reverse[value] then
                table.insert(set, value)
                reverse[value] = table.getn(set)
            end
        end,
        remove = function(set, value)
            local index = reverse[value]
            if index then
                reverse[value] = nil
                local top = table.remove(set)
                if top ~= value then
                    reverse[top] = index
                    set[index] = top
                end
            end
        end
    }})
end

-- initiates a connection to host:port, returns true on success
local function SocketConnect(host, port)
	client=socket.tcp()
	client:settimeout(0)
	res, err = client:connect(host, port)
	if not res and not res=="timeout" then
		Spring.Echo("OpenHostList: Error in connect to " .. host .. ": " .. err)
        widgetHandler:RemoveWidget() 
		return false
	end
	set = newset()
	set:insert(client)
	return true
end

function widget:Initialize()
	--dumpConfig() //use for debugging
	--Spring.Echo(socket.dns.toip("localhost"))
	--FIXME dns-request seems to block
	SocketConnect(host, port)
    CreateGUI()
end

function widget:ShutDown()
    window:Dispose()
end

function BattleType(battle) 
    if battle.passworded or (battle.locked and false) or battle.rankLimit>0 or battle.playerCount==0 then return nil end
    if battle.playerCount==0 then return nil end
    
    local founder = battle.founder
    if founder=="BlackHoleHost1" or founder=="BlackHoleHost2" or founder=="BlackHoleHost6" or founder=="[ACE]Ortie" or founder=="[ACE]Perge" or founder=="[ACE]Pirine" then
        return "team"
    elseif founder=="BlackHoleHost3" or founder=="[ACE]Sure" then
        return "ffa"
    elseif founder=="BlackHoleHost5" or founder=="[ACE]Censur" or founder=="[ACE]Embleur" then
        return "1v1"
    elseif founder=="[ACE]Sombri" then
        return "chickens" 
    end
    return nil
end

function BattleCompare(battle1,battle2)
    return battle1.playerCount > battle2.playerCount
end

-- called when data was received through socket
local function SocketDataReceived(sock, data)
    -- load data into battleList
	--Spring.Echo("data!")
    --Spring.Echo(data)
    local line
    while data do
        local battle  = {}
        line,data = getLine(data)
        --Spring.Echo(line)
        if line and not (string.find(line,"START") or string.find(line,"END") or string.find(line,"battleID")) then --ignore the three 'padding' lines
            --extract battle info from line            
            battle.ID, line         = extract(line) 
            battle.founder, line    = extract(line)
            battle.passworded, line = extract(line)
            battle.rankLimit, line  = extract(line)
            battle.engineVer, line  = extract(line)
            battle.map, line        = extract(line)
            battle.title, line      = extract(line)
            battle.gameName, line   = extract(line)
            battle.locked, line     = extract(line)
            battle.specCount, line  = extract(line)
            battle.playerCount, line= extract(line)
            battle.isInGame, line   = extract(line) -- line should now be nil
            
            -- i hate lua
            battle.ID           = tonumber(battle.ID)
            battle.passworded   = toboolean(battle.passworded)
            battle.rankLimit    = tonumber(battle.rankLimit) or 0
            battle.locked       = toboolean(battle.locked)
            battle.specCount    = tonumber(battle.specCount) or 0
            battle.playerCount  = tonumber(battle.playerCount) or 0
            battle.isInGame     = toboolean(battle.isInGame)
            
            battle.type = BattleType(battle)
            if battle.type and battle.playerCount>0 then
                battleList[battle.type][battle.founder] = battle
            end
        end    
    end
    
    -- Sort
    for t,_ in pairs(battleTypes) do
        table.sort(battleList[t],BattleCompare)      
    end
    
    --Spring.Echo(#battleList)
    RefreshBattles()
end

-- called when a socket is open and we want to send something to it
local function SocketSendRequest(sock)
    --Spring.Echo("Sending to socket")
    sock:send("ALL MOD balanc\r\n\r\n") --see http://imolarpg.dyndns.org/trac/balatest/ticket/562 for what info can be requested
end

-- called when a connection is closed
local function SocketClosed(sock)
    --Spring.Echo("Closed Socket")
end

function widget:Update()
	if set==nil or #set<=0 then
		return -- no sockets?
	end
    
    -- update every 10 seconds, and once at the start
    local timer = Spring.GetTimer()
    local diffSecs = Spring.DiffTimers(timer,prevTimer)
    if diffSecs < updateTime and not needUpdate then 
        return
    end
    prevTimer = timer
            
	-- update socket state
	local readable, writeable, err = socket.select(set, set, 0)
    --Spring.Echo(#readable, #writeable)
	
    -- check for error
    if err~=nil then
		-- some error happened in select
		if err=="timeout" then
			-- nothing to do, return
            Spring.Echo("Socket timed out")
			return
		end
		Spring.Echo("Error in socket.select: " .. error)
	end
    
    -- see if we received anything back
	for _, input in ipairs(readable) do
		local s, status, partial = input:receive('*a') --try to read all data
		if status == "timeout" or status == nil then
            --Spring.Echo("Socket data:")
			SocketDataReceived(input, s or partial)
            if needUpdate then
                needUpdate = false
            end
		elseif status == "closed" then
            --Spring.Echo("Socket closed")
			SocketClosed(input)
			input:close()
			set:remove(input)
        else
        --Spring.Echo(s, status, partial)
		end
	end
    
    -- ask for an update
    for __, output in ipairs(writeable) do
       -- socket is writeable
       SocketSendRequest(output)
    end

end

---------------------------------------------------------
------------- Draw on screen
---------------------------------------------------------

local spIsGUIHidden = Spring.IsGUIHidden

local glColor = gl.Color
local glLineWidth = gl.LineWidth
local glPolygonMode = gl.PolygonMode
local glRect = gl.Rect
local glText = gl.Text
local glShape = gl.Shape

local glCreateList = gl.CreateList
local glCallList = gl.CallList
local glDeleteList = gl.DeleteList

local glPopMatrix = gl.PopMatrix
local glPushMatrix = gl.PushMatrix
local glTranslate = gl.Translate
local glScale = gl.Scale

local GL_FILL = GL.FILL
local GL_FRONT_AND_BACK = GL.FRONT_AND_BACK
local GL_LINE_STRIP = GL.LINE_STRIP

local vsx, vsy = Spring.GetViewGeometry()
function widget:ViewResize()
  vsx,vsy = Spring.GetViewGeometry()
end

local textSize = 0.75
local textMargin = 0.125
local lineWidth = 0.0625

local posX = 0.3
local posY = 0

local buttonGL
local battlesGL
local show = false -- show the battles?

local function DrawL()
	local vertices = {
		{v = {0, 1, 0}},
		{v = {0, 0, 0}},
		{v = {1, 0, 0}},
	}
	glShape(GL_LINE_STRIP, vertices)
end

function DrawButton()
    glPolygonMode(GL_FRONT_AND_BACK, GL_FILL)
    glColor(0, 0, 0, 0.2)
    glRect(0, 0, 8, 1)
    DrawL()
    glText("Open Battles", textMargin, textMargin, textSize, "no")
end

local red = '\255\255\0\0'
local green = '\255\0\255\0'
local blue = '\255\0\0\255'
local white = '\255\255\255\255'

function BattleText(battle)
    local plural_s = (battle.specCount==1) and "" or "s"
    local ingame = (battle.isIngame) and red .. "ingame" or green .. "open"
    return blue .. battle.type .. ": " .. white .. battle.founder .. " (" .. battle.playerCount .. " players" .. ", " .. battle.specCount .. " spec" .. plural_s .. ", " .. ingame .. white .. ")"
end

function NewBattle(battle)
    -- create the panel for this battle
    return Chili.TextBox:New{
        minHeight = 16,
        width = '100%',
        text = BattleText(battle),
        font = {
            outline          = true,
            autoOutlineColor = true,
            outlineWidth     = 4,
            outlineWeight    = 6,
            size             = 14,        
        }
    }   
end

function RefreshBattles()
    local _,_,spec = Spring.GetPlayerInfo(Spring.GetMyPlayerID())
    if not spec then 
        -- don't show anything
        WG.OpenHostsList = false
        if not window.hidden then
            window:Hide()
        end
        return
    end
    
    -- show at least the control panel
    WG.OpenHostsList = true --tell sMenu that we're displaying the hosts lists, and it should hide the actions bar
    if window.hidden then
        window:Show()
    end
    
    -- clear all children of battles panel, re-add as appropriate
    panel:ClearChildren()

    local i = 0
    local n_players = 0
    local n_specs = 0
    local n_battles = 0
    for t,_ in pairs(battleTypes) do
        for founder,battle in pairs(battleList[t]) do
            if battlePanels[founder] then
                --update text
                battlePanels[founder]:SetText(BattleText(battle))
            else
                --create new
                battlePanels[founder] = NewBattle(battle)
            end
            
            if not panel.hidden then
                panel:AddChild(battlePanels[founder])
            end
            
            n_players = n_players + battle.playerCount
            n_specs = n_specs + battle.specCount
            n_battles = n_battles + 1
            
            -- stop if we have too many
            i = i + 1
            if i==battleTypes[t] then break end
        end
    end
    
    if n_battles>0 then
        panel:AddChild(line)
    end
    
    local player_plural = (n_players==1) and "" or "s"
    local spec_plural = (n_specs==1) and "" or "s"
    local battle_plural = (n_battles==1) and "" or "s"
    showhide_text:SetText(n_players .. " player" .. player_plural .. " and " .. n_specs .. " spectator" .. spec_plural .. " in " .. n_battles .. " battle" .. battle_plural)
end

function ShowHide()
    if panel.hidden then
        panel:Show()
        RefreshBattles()
        showhide_button:SetCaption('hide battles')
    else
        panel:ClearChildren()
        panel:Hide()
        showhide_button:SetCaption('show battles')
    end
end


function CreateGUI()
    Chili = WG.Chili
    
    -- dimensions of minimap
    local scrH = Chili.Screen0.height
	local aspect = Game.mapX/Game.mapY
	local minMapH = scrH * 0.3
	local minMapW = minMapH * aspect
	if aspect > 1 then
		minMapW = minMapH * aspect^0.5
		minMapH = minMapW / aspect
	end
    
    window = Chili.Window:New{
        parent = Chili.Screen0,
        bottom = 0,
        minHeight = 25,
		x      = minMapW,
		autosize = true,
		width  = 500,
    }
    
    master_panel = Chili.LayoutPanel:New{
        parent = window,
        width = '100%',
		resizeItems = false,
        autosize = true,
        minHeight = 25,
		padding     = {0,0,0,0},
		itemPadding = {0,0,0,0},
		itemMargin  = {0,0,0,0},
        orientation = 'vertical',
    }   
    
    panel = Chili.LayoutPanel:New{
        parent = master_panel,
        width = '100%',
		resizeItems = false,
        autosize = true,
        minHeight = 1,
		padding     = {0,0,0,0},
		itemPadding = {10,0,0,0},
		itemMargin  = {0,0,0,0},
        orientation = 'vertical',
    }   
    
    line = Chili.Line:New{
        width = '100%',
    }

    
    controlbar = Chili.LayoutPanel:New{
        parent = master_panel,
        width = '100%',
        height = 25,
        minHeight = 25,
		padding     = {0,0,0,0},
		itemPadding = {0,0,0,0},
		itemMargin  = {0,0,0,0},
        orientation = 'horizontal',
    }   

    showhide_button = Chili.Button:New{
        parent = controlbar,
        height = 25,
        width = 100,
        caption = "hide battles",
        onclick = {ShowHide},
    }
    
    showhide_text = Chili.TextBox:New{
        parent = controlbar,
        height = 20,
        width = 350,
        text = "",
        font = {
            outline          = true,
            autoOutlineColor = true,
            outlineWidth     = 3,
            outlineWeight    = 8,
            size             = 14,        
        }    
    }
    
     RefreshBattles()    
end

function widget:PlayerChanged(pID)
    -- show the battle list if we suddenly became a spec
    if pID==Spring.GetMyPlayerID() then
        RefreshBattles()
    end
end

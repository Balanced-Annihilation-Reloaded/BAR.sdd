function widget:GetInfo()
    return {
        name = "Highlight Selected Units",
        desc = "Highlights Selected Units",
        author = "Bluestone", 
        date = "Horse",
        license = "Tarquin Fin-tim-lin-bin-whin-bim-lim-bus-stop-F'tang-F'tang-Olé-Biscuitbarrel",
        layer = 0,
        enabled = true
    }
end


local myPlayerID = Spring.GetMyPlayerID()

-- selected unit tracking
local selUnits = {} --indexed by unitID, value is table with lots of info
local playerSelUnits = {} --indexed by playerID, value is hash table of unitID 
local toRemove = {} -- has table of unitIDs waiting to be removed from our book-keeping
local prevSelUnits = {} -- units selected at previous CommandsChanged 
local visibleUnits = {}

local unitScales = {}

-- constants for selected units visuals
local alphaExpWeight = 7 -- how fast we fade in/out 
local rotSpeed = 5 -- how fast we rotate
local alphaDrawOwnUnits = 0.55 -- alpha for own units
local alphaDrawOthersUnits = 0.35 -- alpha for other units
local thinLineWidth = 1.7
local thickLineWidth = 3
local fadeTime = 1/4
local alphaZero = 0.01
local alphaOne = 1-alphaZero
local additionalScaleMult = 1.05

-- vars 
local rot = 0
local curTime = 0



-- option & defaults
local options = {
    -- todo: implement option changes & chili options
    selected = {
        useTeamColour = false,
        useThickLines = false,
        showAllySelected = true,
        -- useXRayShader = false --todo
    }
    --[[
    todo: merge in highlight_unit
    enemy = {
        showPlatters = true,
        colourMode = "auto", -- also "team" and "ally team"; "auto" means only in mo_noowner
        showOwnTeam = "auto", -- also "on" and "off"; "auto" means only if spectator
    }
    ]]
}

local lineWidth = options.selected.useThickLines and thickLineWidth or thinLineWidth

------------------------------------------------------
-- helpers
------------------------------------------------------

function GetUnitScales() 
    for uDID, unitDef in pairs(UnitDefs) do
        local xsize, zsize = unitDef.xsize, unitDef.zsize
        local scale = 4*( xsize^2 + zsize^2 )^0.5 -- approximately unit radius
        unitScales[uDID] = scale * additionalScaleMult
    end
end

function RecheckIsSelected(t)
    -- recalculate t.selected based on t.selectedBy
    -- update t.selectedChangeTime if t.selected changes
    local selected = false
    for _,_ in pairs(t.selectedBy) do
        selected = true
        break
    end    
    t.selectedChangeTime = (selected==t.selected) and t.selectedChangeTime or curTime
    t.selected = selected 
end

------------------------------------------------------
-- receive players selected units info
------------------------------------------------------

function widget:Initialize()
    -- incoming info about other players
	widgetHandler:RegisterGlobal('selectedUnitsRemove', SelectedUnitsRemove_Wrapper)
	widgetHandler:RegisterGlobal('selectedUnitsClear', SelectedUnitsClear_Wrapper)
	widgetHandler:RegisterGlobal('selectedUnitsAdd', SelectedUnitsAdd_Wrapper)
    
    GetUnitScales()
    InitializeGL()
    HijackCmdColors()
end

function widget:Shutdown()
	widgetHandler:DeregisterGlobal('selectedUnitsRemove')
	widgetHandler:DeregisterGlobal('selectedUnitsClear')
	widgetHandler:DeregisterGlobal('selectedUnitsAdd')
    
    ShutdownGL()
    UnhijackCmdColors()
end

function widget:CommandsChanged()
    -- local info about ourself, to avoid time lag
    -- (the wrappers ignore incoming info about ourself)
    local newSelUnits = Spring.GetSelectedUnits()
    
    -- no selected units -> clear 
    if #newSelUnits==0 and #prevSelUnits>0 then
        SelectedUnitsClear(myPlayerID)
        return
    end
    
    -- add units that are newly selected
    local newSelUnitsHash = {}
    for i=1,#newSelUnits do
        local unitID = newSelUnits[i]
        if not prevSelUnits[unitID] then -- don't check against selUnits, which contains fading non-selected units
            SelectedUnitsAdd(myPlayerID, unitID)
        end
        newSelUnitsHash[unitID] = true
    end
    -- remove units that are no longer selected
    --for unitID,_ in pairs(playerSelUnits[myPlayerID]) do
    for i=1,#prevSelUnits do
        local unitID = prevSelUnits[i]
        if not newSelUnitsHash[unitID] then
            SelectedUnitsRemove(myPlayerID, unitID)
        end
    end
    prevSelUnits = newSelUnits
end

function SelectedUnitsClear_Wrapper(playerID)
    if playerID~=myPlayerID and showAllySelected then 
        SelectedUnitsClear(playerID)
    end
end

function SelectedUnitsAdd_Wrapper(playerID, unitID)
    if playerID~=myPlayerID and showAllySelected then 
        SelectedUnitsAdd(playerID, unitID)
    end
end

function SelectedUnitsRemove_Wrapper(playerID, unitID)
    if playerID~=myPlayerID and showAllySelected then 
        SelectedUnitsRemove(playerID, unitID)
    end
end

------------------------------------------------------
-- book-keeping
------------------------------------------------------

function widget:PlayerChanged()
    myPlayerID = Spring.GetMyPlayerID()
    local spec,_,_ = Spring.GetSpectatingState()
    if spec then
        myPlayerID = -1
    end
end

function SelectedUnitsClear(playerID)
    -- player newly has no selected units
    playerSelUnits[playerID] = playerSelUnits[playerID] or {}
    for unitID,_ in pairs(playerSelUnits[playerID]) do
        SelectedUnitsRemove(playerID, unitID)
    end
end

function SelectedUnitsAdd(playerID, unitID)
    -- newly selected unit
    selUnits[unitID] = selUnits[unitID] or {}
    selUnits[unitID] = UpdateUnitInfo(unitID, playerID)
    playerSelUnits[playerID] = playerSelUnits[playerID] or {}
    playerSelUnits[playerID][unitID] = true
end

function SelectedUnitsRemove(playerID, unitID)
    -- newly deselected unit; we don't want to actually remove it (yet), just mark it as not selected any more
    if selUnits[unitID] then
        selUnits[unitID].selectedBy[playerID] = nil
        RecheckIsSelected(selUnits[unitID])    
    end
end

function Delete(unitID)
    -- and here is where we remove it! 
    if not selUnits[unitID] then return end 
    for playerID,_ in pairs(selUnits[unitID].selectedBy) do
        playerSelUnits[playerID][unitID] = nil
    end
    selUnits[unitID] = nil
end

function UpdateUnitInfo(unitID, playerID)
    local teamID = Spring.GetUnitTeam(unitID)
    local unitDefID = Spring.GetUnitDefID(unitID)
    local r,g,b
    if teamID and options.selected.useTeamColour then
        r,g,b = Spring.GetTeamColor(teamID)
    else -- allied unit probably died while msg was in network, or smth
        r,g,b = 0,1,0
    end

    -- information that we maintain about the unitID
    local t = selUnits[unitID] or {}
    t.unitScale = t.unitScale or unitScales[unitDefID]
    t.r = t.r or r
    t.g = t.g or g
    t.b = t.b or b

    t.randomAngle = t.randomAngle or 360*math.random()
    t.randomSign = t.randomSign or ((math.random()<0.5) and 1 or -1)

    t.selectedBy = t.selectedBy or {} 
    t.selectedBy[playerID] = true
    RecheckIsSelected(t) --t.selected, t.selectedChangeTime

    -- these only get updated when the unit is on screen
    t.alpha = t.alpha or 0
    t.alphaMax = t.selectedBy[myPlayerID] and alphaDrawOwnUnits or alphaDrawOthersUnits
    t.alphaUpdateTime = t.alphaUpdateTime or curTime
    
    return t
end

function widget:Update(dt)
    -- maintain curTime
    curTime = curTime + dt
    
    -- maintain rotation 
    rot = rot + rotSpeed*dt
    if rot>360 then
        rot = rot - 360
    end
    
    -- remove once faded out (mostly from UpdateAlpha)
    for i=1,#toRemove do
        local unitID = toRemove[i]
        Delete(unitID)
    end    
    toRemove = {}    
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam)
    if selUnits[unitID] then
        Delete(unitID)
    end
end

function widget:UnitGiven(unitID, unitDefID, newTeam, oldTeam)
    if selUnits[unitID] then
        Delete(unitID)
    end
end    

------------------------------------------------------
-- draw
------------------------------------------------------

--[[
function QuadVerts(r)
    gl.TexCoord(0, 0); gl.Vertex(-r, 0, -r)
    gl.TexCoord(1, 0); gl.Vertex(r, 0, -r)
    gl.TexCoord(1, 1); gl.Vertex(r, 0, r)
    gl.TexCoord(0, 1); gl.Vertex(-r, 0, r)
end

function Platter(t)
    -- draw current gl.Texture
    gl.PushMatrix()
    gl.Rotate(360*t.random+secs, 0,1,0)
    gl.BeginEnd(GL.QUADS, QuadVerts, t.unitScale)
end
]]


local hexagonList
function InitializeGL()
    hexagonList = gl.CreateList(function()
        gl.BeginEnd(GL.LINE_LOOP, function()
            local theta = 0
            for i=0,6 do
                theta = theta + math.pi/3
                local x = math.cos(theta)
                local z = math.sin(theta) 
                gl.Vertex(x,0,z)
            end    
        end)    
    end)
end

function ShutdownGL()
    gl.DeleteList(hexagonList)
end

local gl_DepthTest = gl.DepthTest
local gl_LineWidth = gl.LineWidth
local gl_Color = gl.Color
local gl_DrawListAtUnit = gl.DrawListAtUnit
local gl_DepthTest = gl.DepthTest
local GL_ALWAYS = GL.ALWAYS

local spIsGUIHidden = Spring.IsGUIHidden
local spGetVisibleUnits = Spring.GetVisibleUnits

local max = math.max


function UpdateAlpha(t, unitID)
    local dt = curTime-t.selectedChangeTime
    if t.selected and dt < fadeTime then
        -- fade in
        return max(t.alpha, dt/fadeTime)
    elseif t.selected then
        -- on
        return 1.0
    elseif dt < fadeTime then 
        -- fade out
        return 1.0 - dt/fadeTime
    else
        -- off
        toRemove[unitID] = true -- can't delete here without adding an extra conditional, so better to just wait
        return 0.0
    end 
end

function widget:DrawWorldPreUnit()
    if spIsGUIHidden() then 
        return 
    end
    visibleUnits = spGetVisibleUnits(-1,-1,false)
    
    gl_DepthTest(GL_ALWAYS)
    gl_LineWidth(lineWidth)
    local unitID, t
    for i=1,#visibleUnits do
        unitID = visibleUnits[i]
        t = selUnits[unitID]
        if t then
            t.alpha = UpdateAlpha(t, unitID)
            gl_Color(t.r, t.g, t.b, t.alpha*t.alphaMax)
            gl_DrawListAtUnit(unitID, hexagonList, false, t.unitScale,t.unitScale,t.unitScale, t.randomAngle+t.randomSign*rot)
        end
    end
    gl_DepthTest(true)
end


------------------------------------------------------
-- cmd colors
------------------------------------------------------


function HijackCmdColors()
    --todo
end
function UnhijackCmdColors()
    --todo
end
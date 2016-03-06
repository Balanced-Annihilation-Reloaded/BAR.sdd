function widget:GetInfo()
    return {
        name = "Highlight Selected Units",
        desc = "Highlights Selected Units, also sets cmdcolors",
        author = "Bluestone", 
        date = "Horse",
        license = "Tarquin Fin-tim-lin-bin-whin-bim-lim-bus-stop-F'tang-F'tang-Olé-Biscuitbarrel",
        layer = 0,
        enabled = true
    }
end


local amISpec,_ = Spring.GetSpectatingState()
local myPlayerID = Spring.GetMyPlayerID()
local myAllyTeamID = Spring.GetMyAllyTeamID()
local mo_noowner = (tonumber(Spring.GetModOptions().mo_noowner)==1) or false 

-- selected unit tracking
local selUnits = {} --indexed by unitID, value is table with lots of info
local playerSelUnits = {} --indexed by playerID, value is hash table of unitID 
local toRemove = {} -- has table of unitIDs waiting to be removed from our book-keeping
local prevSelUnits = {} -- units selected at previous CommandsChanged 

-- generic information about all unitScale
local platterUnits = {} -- indexed by unitID
local platterPolys = {} -- indexed by teamID

-- unitDef info
local unitScales = {}
local selScaleFactor = 1.05
local platterScaleFactor = 2.9

-- constants for selected units visuals
local alphaExpWeight = 7 -- how fast we fade in/out 
local rotSpeed = 5 -- how fast we rotate
local alphaDrawOwnUnits = 0.55 -- alpha for own units
local alphaDrawOthersUnits = 0.35 -- alpha for other units
local thinLineWidth = 1.7
local thickLineWidth = 3
local fadeTime = 1/4

-- constants for platter visuals
local platterSize = 1.3 -- fade size compared to circle scale (1 = not rendered)
local platterColourBank = { -- default color values
    {0,0,1} , {1,0,1} , {0,1,1} , {0,1,0} , {1,0.5,0} , {0,1,1} , {1,1,0} , {1,1,1} , 
    {0.5,0.5,0.5} , {0,0,0} , {0.5,0,0} , {0,0.5,0} , {0,0,0.5} , {0.5,0.5,0} , {0.5,0,0.5} , 
    {0,0.5,0.5} , {1,0.5,0.5} , {0.5,0.5,0.1} , {0.5,0.1,0.5},
}

-- constants for xray shader
local edgeExponent = 1.5
local xRayOpacity = 1.7

-- vars 
local rot = 0
local curTime = 0
local lineWidth 
local guiHidden 
local visibleUnits = {}
local n_visibleUnits


-- option & defaults
local options = {
    -- todo: implement option changes & chili options
    selected = {
        colourMode = "green", -- also, "team"
        useThickLines = false,
        showAllySelected = true,
        useXRayShader = false,
    },
    platter = {
        showPlatters = true,
        colourMode = "auto", -- also "team" and "ally team"; "auto" means only in mo_noowner
        showAllyPlatters = "auto", -- also "on" and "off"; "auto" means only if spectator
    }
}

------------------------------------------------------
-- helpers
------------------------------------------------------

function GetUnitScales() 
    for uDID, unitDef in pairs(UnitDefs) do
        local xsize, zsize = unitDef.xsize, unitDef.zsize
        local scale = 4*( xsize^2 + zsize^2 )^0.5 -- approximately unit radius
        unitScales[uDID] = scale
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
        
    SetupMenuOptions()    
        
    GetUnitScales()
    InitializeGL()
    SetCmdColors() -- we do it in this widget because we remove the engines own selected unit gfx, but this also sets up the colours to match sMenu

    local units = Spring.GetAllUnits()
    for _,unitID in ipairs(units) do
        local unitDefID = Spring.GetUnitDefID(unitID)
        widget:UnitCreated(unitID, unitDefID)
    end    
end

function widget:Shutdown()
	widgetHandler:DeregisterGlobal('selectedUnitsRemove')
	widgetHandler:DeregisterGlobal('selectedUnitsClear')
	widgetHandler:DeregisterGlobal('selectedUnitsAdd')
    
    ShutdownGL()
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
    if playerID~=myPlayerID and options.selected.showAllySelected then 
        SelectedUnitsClear(playerID)
    end
end

function SelectedUnitsAdd_Wrapper(playerID, unitID)
    if playerID~=myPlayerID and options.selected.showAllySelected then 
        SelectedUnitsAdd(playerID, unitID)
    end
end

function SelectedUnitsRemove_Wrapper(playerID, unitID)
    if playerID~=myPlayerID and options.selected.showAllySelected then 
        SelectedUnitsRemove(playerID, unitID)
    end
end

------------------------------------------------------
-- book-keeping
------------------------------------------------------

function widget:PlayerChanged(playerID)
    local wasSpec = amISpec
    amISpec,_ = Spring.GetSpectatingState()
    myAllyTeamID = Spring.GetMyAllyTeamID()
    if wasSpec~=amISpec then
        UpdateEverything()
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
    selUnits[unitID] = UpdateSelectedUnit(unitID, playerID)
    if not selUnits[unitID] then return end
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

function SelectedUnitsDelete(unitID)
    -- and here is where we remove it! shortly after de-selection, once the alpha has faded to zero
    selUnits[unitID] = nil
    if playerSelUnits[playerID] and playerSelUnits[playerID][unitID] then  
        for playerID,_ in pairs(selUnits[unitID].selectedBy) do
            playerSelUnits[playerID][unitID] = nil
        end
    end
end

function UpdateSelectedUnit(unitID, playerID)
    -- information that we maintain about the unitID
    local t = selUnits[unitID] or {}

    t.teamID = Spring.GetUnitTeam(unitID)
    t.allyTeamID = Spring.GetUnitAllyTeam(unitID)
    t.unitDefID = t.unitDefID or Spring.GetUnitDefID(unitID)
    if not t.teamID or not t.unitDefID then 
        return nil -- unit died before the 'was selected' message reached us, or suchlike
    end 
    
    local r,g,b
    if t.teamID and options.selected.colourMode=="team" then
        r,g,b = Spring.GetTeamColor(t.teamID)
    else 
        r,g,b = 0,1,0
    end
    t.r = r 
    t.g = g
    t.b = b

    t.unitScale = t.unitScale or unitScales[t.unitDefID] * selScaleFactor

    t.randomAngle = t.randomAngle or 360*math.random()
    t.randomSign = t.randomSign or ((math.random()<0.5) and 1 or -1)

    t.selectedBy = t.selectedBy or {} 
    if playerID then -- option changes won't send a playerID
        t.selectedBy[playerID] = true
    end
    RecheckIsSelected(t) --t.selected, t.selectedChangeTime

    -- these only get updated when the unit is on screen
    t.alpha = t.alpha or 0
    t.alphaMax = t.selectedBy[myPlayerID] and alphaDrawOwnUnits or alphaDrawOthersUnits
    t.alphaUpdateTime = t.alphaUpdateTime or curTime
    
    return t
end

function UpdatePlatterUnit(unitID)
    if not options.platter.showPlatters then return nil end 

    local t = platterUnits[unitID] or {}
    t.teamID = Spring.GetUnitTeam(unitID)    
    t.allyTeamID = Spring.GetUnitAllyTeam(unitID)
    t.unitDefID = t.unitDefID or Spring.GetUnitDefID(unitID)
    if not t.teamID or not team.unitDefID then return nil end
    
    if t.allyTeamID==myAllyTeamID then 
        if options.platter.showAllyPlatters=="false" then return nil end
        if (not amISpec) and options.platter.showAllyPlatters=="auto" then return nil end
    end

    t.unitScale = unitScales[t.unitDefID] * platterScaleFactor
    t.randomAngle = t.randomAngle or 360*math.random()   

    return t
end

function widget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
    platterUnits[unitID] = UpdatePlatterUnit(unitID)
end

function widget:UnitGiven(unitID, unitDefID, newTeam, oldTeam)
    platterUnits[unitID] = UpdatePlatterUnit(unitID)
    if selUnits[unitID] then
        SelectedUnitsDelete(unitID)
    end
end  

function widget:UnitDestroyed(unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam)
    platterUnits[unitID] = nil
    if selUnits[unitID] then
        SelectedUnitsDelete(unitID)
    end
end

function widget:Update(dt)
    -- maintain curTime & rotation
    curTime = curTime + dt
    rot = rot + rotSpeed*dt
    if rot>360 then
        rot = rot - 360
    end
    
    -- action cached delete
    for i=1,#toRemove do
        local unitID = toRemove[i]
        SelectedUnitsDelete(unitID)
    end    
    toRemove = {}    
end  

------------------------------------------------------
-- draw init
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
    gl.PopMatrix()
end
]]


local hexagonList
local platterPolys = {}

function InitializeGL()
    CreateHexagonList()
    CreatePlatterLists()
    CreateXRayShader()
end

function ShutdownGL()
    gl.DeleteList(hexagonList)
    DeletePlatterLists()
    gl.DeleteShader(shader)
end


function CreateHexagonList()
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

local platterParts = 12
function CreatePlatterList(r,g,b,a)
    local list = gl.CreateList(function()
        -- colored inner circle:
        gl.BeginEnd(GL.TRIANGLE_FAN, function()
            gl.Color(r, g, b, 0)
            gl.Vertex(0, 0, 0)
            local radstep = (2.0 * math.pi) / platterParts
            for i = 1, platterParts do
                local a1 = (i * radstep)
                local a2 = ((i+1) * radstep)
                
                gl.Color(r, g, b, a)
                gl.Vertex(math.sin(a1), 0, math.cos(a1))
                gl.Vertex(math.sin(a2), 0, math.cos(a2))
            end
        end)

        if (platterSize ~= 1) then
            -- colored outer circle:
            gl.BeginEnd(GL.QUADS, function()
                local radstep = (2.0 * math.pi) / platterParts
                for i = 1, platterParts do
                    local a1 = (i * radstep)
                    local a2 = ((i+1) * radstep)
                    
                    gl.Color(r, g, b, a)
                    gl.Vertex(math.sin(a1), 0, math.cos(a1))
                    gl.Vertex(math.sin(a2), 0, math.cos(a2))
                    
                    gl.Color(r, g, b, 0)
                    gl.Vertex(math.sin(a2)*platterSize, 0, math.cos(a2)*platterSize)
                    gl.Vertex(math.sin(a1)*platterSize, 0, math.cos(a1)*platterSize)
                end
            end)
        end
    end)
    
    return list
end

function GetPlatterColour(teamID)
    if not teamID then return 1,1,1,1 end
    
    local r,g,b,a
    if ((options.platter.colourMode=="auto" and not mo_noowner) or options.platter.colourMode=="team") then
        r,g,b = Spring.GetTeamColor(teamID)
        a = 0.15
    else
        -- use colour bank, per allyteam
        local _,_,_,_,_,allyTeamID = Spring.GetTeamInfo(teamID)   
        if allyTeamID+1<#platterColourBank then return 0,0,0,1 end
        local col = platterColourBank[allyTeamID+1]
        r,g,b = col[1],col[2],col[3]
        a = 0.1
    end
    return r,g,b,a
end

function CreatePlatterLists()
    DeletePlatterLists()
    local allyTeamList = Spring.GetAllyTeamList()
    for _,allyTeamID in ipairs(allyTeamList) do      
        local teamList = Spring.GetTeamList(allyTeamID)
        local colourTeamID = teamList[1]
        local r,g,b,a = GetPlatterColour(colourTeamID)
        local polys = CreatePlatterList(r,g,b, a, platterParts)    
                
        for _,teamID in ipairs(teamList) do
            platterPolys[teamID] = {}
            platterPolys[teamID] = polys           
        end
    end
end

function DeletePlatterLists()
    for _,v in pairs(platterPolys) do
        gl.DeleteList(v)
    end
    platterPolys = {}
end

function CreateXRayShader()
    gl.DeleteShader(shader)
    
    shader = gl.CreateShader({

    uniform = {
      edgeExponent = edgeExponent * xRayOpacity,
    },

    vertex = [[
      // Application to vertex shader
      varying vec3 normal;
      varying vec3 eyeVec;
      varying vec3 color;
      uniform mat4 camera;
      uniform mat4 caminv;

      void main()
      {
        vec4 P = gl_ModelViewMatrix * gl_Vertex;
              
        eyeVec = P.xyz;
              
        normal  = gl_NormalMatrix * gl_Normal;
              
        color = gl_Color.rgb;
              
        gl_Position = gl_ProjectionMatrix * P;
      }
    ]],  

    fragment = [[
      varying vec3 normal;
      varying vec3 eyeVec;
      varying vec3 color;

      uniform float edgeExponent;

      void main()
      {
        float opac = 1.7*dot(normalize(normal), normalize(eyeVec));
        opac = max(0.1, 1.0 - abs(opac));
        opac = pow(opac, edgeExponent);
          
        gl_FragColor.rgb = color;
        gl_FragColor.a = opac;
      }
    ]],
    })
end

------------------------------------------------------
-- draw 
------------------------------------------------------

local gl_DepthTest = gl.DepthTest
local gl_LineWidth = gl.LineWidth
local gl_Color = gl.Color
local gl_DrawListAtUnit = gl.DrawListAtUnit
local gl_DepthTest = gl.DepthTest
local gl_Unit = gl.Unit
local gl_Smoothing = gl.Smoothing
local gl_UseShader = gl.UseShader
local gl_PolygonOffset = gl.PolygonOffset
local gl_Blending = gl.Blending
local GL_SRC_ALPHA = GL.SRC_ALPHA
local GL_ONE_MINUS_SRC_ALPHA = GL.ONE_MINUS_SRC_ALPHA
local GL_ALWAYS = GL.ALWAYS
local GL_ONE = GL.ONE

local spIsGUIHidden = Spring.IsGUIHidden
local spGetVisibleUnits = Spring.GetVisibleUnits

local max = math.max

function UpdateSelectedUnitAlpha(t, unitID)
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
        toRemove[#toRemove+1] = unitID -- can't delete here without adding an extra conditional, so better to just wait
        return 0.0
    end 
end



function widget:DrawWorldPreUnit()
    if spIsGUIHidden() then 
        guiHidden = true
        return 
    else
        guiHidden = false
    end
    
    visibleUnits = spGetVisibleUnits(-1,-1,false)
    n_visibleUnits = #visibleUnits
    
    gl_DepthTest(GL_ALWAYS)
    gl_LineWidth(lineWidth)
    local unitID, t
    for i=1,n_visibleUnits do
        -- draw selection hexagons
        unitID = visibleUnits[i]
        t = selUnits[unitID]
        if t then
            t.alpha = UpdateSelectedUnitAlpha(t, unitID)
            gl_Color(t.r, t.g, t.b, t.alpha*t.alphaMax)
            gl_DrawListAtUnit(unitID, hexagonList, false, t.unitScale,1.0,t.unitScale, t.randomAngle+t.randomSign*rot)
        end
        
        -- draw platters
        t = platterUnits[unitID]
        if t then
            gl_DrawListAtUnit(unitID, platterPolys[t.teamID], false, t.unitScale,1.0,t.unitScale, t.randomAngle) 
        end
    end
    gl_DepthTest(false)
end

function widget:DrawWorld()
    if not options.selected.useXRayShader or guiHidden then
        return 
    end

    gl_Smoothing(nil, nil, true)
    gl_UseShader(shader)
    gl_DepthTest(true)
    gl_Blending(GL_SRC_ALPHA, GL_ONE)
    gl_PolygonOffset(-2, -2)

    local unitID,t
    for i=1, n_visibleUnits do
        unitID = visibleUnits[i]
        t = selUnits[unitID]
        if t then
            -- draw xRay shader
            gl_Color(t.r, t.g, t.b, t.alpha*t.alphaMax)
            gl_Unit(unitID, true)
        end
    end

    gl_PolygonOffset(false)
    gl_Blending(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
    gl.DepthTest(false)
    gl_UseShader(0)
    gl_Color(1, 1, 1, 1)
    gl_Smoothing(nil, nil, false)
end

------------------------------------------------------
-- options 
------------------------------------------------------


function SetupMenuOptions()
    Chili  = WG.Chili
    if not Chili then return end
    screen = Chili.Screen0
    Menu   = WG.MainMenu
    
    if not Menu then return end    
    
    Menu.AddWidgetOption{
        title = "Highlight Units",
        name = widget:GetInfo().name,
        children = {
            Chili.Label:New{x='5%',width='95%',height=15, caption="Selected unit highlights:"},
            Chili.Control:New{x='10%',width='80%',autoSize=true,padding={0,0,0,0},
                children = {
                    Chili.TextBox:New{x='0%',width='50%',text="Colour mode:"},
                    Chili.ComboBox:New{x='50%',width='50%',
                        items    = {"green", "team"},
                        selected = (options.selected.colourMode=="green" and 1) or (options.selected.colourMode=="team" and 2),
                        OnSelect = {
                            function(_,sel)
                                if sel==1 then options.selected.colourMode="green"
                                elseif sel==2 then options.selected.colourMode="team"
                                end
                                UpdateEverything()
                            end
                            }
                        }
                    }                
            },
            Chili.Checkbox:New{caption='Show allies selected units',x='10%',width='80%',
                    checked=options.selected.showAllySelected, OnChange={function() options.selected.showAllySelected = not options.selected.showAllySelected; UpdateEverything(); end}},
            Chili.Checkbox:New{caption='Thickened lines',x='10%',width='80%',
                    checked=options.selected.useThickLines, OnChange={function() options.selected.useThickLines = not options.selected.useThickLines; UpdateEverything(); end}},
            Chili.Checkbox:New{caption='Use XRay shader',x='10%',width='80%',
                    checked=options.selected.useXRayShader,OnChange={function() options.selected.useXRayShader = not options.selected.useXRayShader; UpdateEverything(); end}},

            Chili.Label:New{x='5%',width='95%',height=15, caption="Unit platters:"},
            Chili.Checkbox:New{caption='Show platters',x='10%',width='80%',
                    checked=options.platter.showPlatters, OnChange={function() options.platter.showPlatters = not options.platter.showPlatters; UpdateEverything(); end}}, 
            Chili.Control:New{x='10%',width='80%',autoSize=true,padding={0,0,0,0},
                children = {
                    Chili.TextBox:New{x='0%',width='50%',text="Colour mode:"},
                    Chili.ComboBox:New{x='50%',width='50%',
                        items    = {"team", "auto", "ally team"},
                        selected = (options.platter.colourMode=="team" and 1) or (options.platter.colourMode=="auto" and 2) or (options.platter.colourMode=="ally team" and 3),
                        OnSelect = {
                            function(_,sel)
                                if sel==1 then options.platter.colourMode="team"
                                elseif sel==2 then options.platter.colourMode="auto"
                                elseif sel==3 then options.platter.colourMode="ally team"
                                end
                                UpdateEverything()
                            end
                            }
                        }
                    }                
            },
            Chili.Control:New{x='10%',width='80%',autoSize=true,padding={0,0,0,0},
                children = {
                    Chili.TextBox:New{x='0%',width='50%',text="Ally platters:"},
                    Chili.ComboBox:New{x='50%',width='50%',
                        items    = {"on", "if spectating", "off"},
                        selected = (options.platter.colourMode=="on" and 1) or (options.platter.colourMode=="auto" and 2) or (options.platter.colourMode=="off" and 3),
                        OnSelect = {
                            function(_,sel)
                                if sel==1 then options.platter.showAllyPlatters="on"
                                elseif sel==2 then options.platter.showAllyPlatters="auto"
                                elseif sel==3 then options.platter.showAllyPlatters="off"
                                end
                                UpdateEverything()
                            end
                            }
                        }
                    }                
            }
        }
    }
    

end

function UpdateEverything()
    -- update everything, re-initialize GL
    for unitID,_ in pairs(selUnits) do        
        selUnits[unitID] = UpdateSelectedUnit(unitID)
    end
    local units = Spring.GetAllUnits()
    for _,unitID in pairs(units) do
        platterUnits[unitID] = UpdatePlatterUnit(unitID)
    end
    
    lineWidth = options.selected.useThickLines and thickLineWidth or thinLineWidth    
    ShutdownGL()
    InitializeGL()
end

function widget:GetConfigData()
    return options
end

function widget:SetConfigData(data)
    if data then
        options = data
    end
end

------------------------------------------------------
-- cmd colors
------------------------------------------------------

function SetCmdColors()
    local cmdColors = VFS.LoadFile('luaui/configs/cmdcolors.txt')
    Spring.LoadCmdColorsConfig(cmdColors) 
end

function widget:GetInfo()
   return {
      name      = "Highlight Units",
      desc      = "Highlights units with glowing platters or x-ray shader",
      author    = "Dave Rodges, TradeMark, Floris, Bluestone",
      date      = "July 2014",
      license   = "GNU GPL, v2 or later",
      layer     = 5,
      enabled   = true
   }
end

--------------------------------------------------------------------------------
-- Defaults
--------------------------------------------------------------------------------

local drawPlatter						= true
local drawXRayShader					= false
local highlightAllyTeam                 = true

--------------------------------------------------------------------------------
-- Config
--------------------------------------------------------------------------------

local useTeamColours                    = (tonumber(Spring.GetModOptions().mo_noowner)==1) or false 
local updateTime                        = 0.2

local circleParts						= 13      	-- number of parts for a cirlce, when not using useVariableSpotterDetail
local circlePartsMin					= 6      	-- minimal number of parts for a cirlce, when zoomed out
local circlePartsMax					= 12      	-- maximum number of parts for a cirlce, when zoomed in

local spotterOpacity					= 0.18
local innerSize							= 1.30		-- circle scale compared to unit radius
local outerSize							= 1.30		-- outer fade size compared to circle scale (1 = not rendered)
                                        
local spotterColours = {								-- default color values
    {0,0,1} , {1,0,1} , {0,1,1} , {0,1,0} , {1,0.5,0} , {0,1,1} , {1,1,0} , {1,1,1} , {0.5,0.5,0.5} , {0,0,0} , {0.5,0,0} , {0,0.5,0} , {0,0,0.5} , {0.5,0.5,0} , {0.5,0,0.5} , {0,0.5,0.5} , {1,0.5,0.5} , {0.5,0.5,0.1} , {0.5,0.1,0.5},
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local glDrawListAtUnit        = gl.DrawListAtUnit
local glUnit                  = gl.Unit
local glColor                 = gl.Color
local GL_ONE                  = GL.ONE
local GL_ONE_MINUS_SRC_ALPHA  = GL.ONE_MINUS_SRC_ALPHA
local GL_SRC_ALPHA            = GL.SRC_ALPHA

local spGetTeamColor          = Spring.GetTeamColor
local spGetUnitDefDimensions  = Spring.GetUnitDefDimensions
local spGetUnitDefID          = Spring.GetUnitDefID
local spGetUnitTeam           = Spring.GetUnitTeam
local spGetUnitAllyTeam       = Spring.GetUnitAllyTeam
local spGetSpectatingState    = Spring.GetSpectatingState
local spIsUnitSelected        = Spring.IsUnitSelected
local spIsUnitIcon            = Spring.IsUnitIcon
local spGetAllyTeamList       = Spring.GetAllyTeamList
local spGetTeamList           = Spring.GetTeamList
local spGetVisibleUnits       = Spring.GetVisibleUnits
local spIsGUIHidden           = Spring.IsGUIHidden
local spGetTimer              = Spring.GetTimer
local spDiffTimers            = Spring.DiffTimers
local spValidUnitID           = Spring.ValidUnitID
          
--local myTeamID                = Spring.GetLocalTeamID()
local myAllyID                = Spring.GetMyAllyTeamID()
--local gaiaTeamID			  = Spring.GetGaiaTeamID()

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local circlePolys			= {}
local colours      		    = {}
local unitConf				= {}
local visibleUnits          = {}
local n_visibleUnits        = 0
local guiHidden             = false
local prevUpdate = spGetTimer()

local edgeExponent			= 1.5
local highlightOpacity		= 1.7
local smoothPolys			= gl.Smoothing -- can save a bit of perf by turning this off, without much impact to visuals

local rectangleFactor		= 3.3
local scaleFactor			= 2.9

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function CreateSpotterList(r,g,b,a, parts)
    local list = gl.CreateList(function()
        -- colored inner circle:
        gl.BeginEnd(GL.TRIANGLE_FAN, function()
            gl.Color(r, g, b, 0)
            gl.Vertex(0, 0, 0)
            local radstep = (2.0 * math.pi) / parts
            for i = 1, parts do
                local a1 = (i * radstep)
                local a2 = ((i+1) * radstep)
                
                gl.Color(r, g, b, a)
                gl.Vertex(math.sin(a1), 0, math.cos(a1))
                gl.Vertex(math.sin(a2), 0, math.cos(a2))
            end
        end)

        if (outerSize ~= 1) then
            -- colored outer circle:
            gl.BeginEnd(GL.QUADS, function()
                local radstep = (2.0 * math.pi) / parts
                for i = 1, parts do
                    local a1 = (i * radstep)
                    local a2 = ((i+1) * radstep)
                    
                    gl.Color(r, g, b, a)
                    gl.Vertex(math.sin(a1), 0, math.cos(a1))
                    gl.Vertex(math.sin(a2), 0, math.cos(a2))
                    
                    gl.Color(r, g, b, 0)
                    gl.Vertex(math.sin(a2)*outerSize, 0, math.cos(a2)*outerSize)
                    gl.Vertex(math.sin(a1)*outerSize, 0, math.cos(a1)*outerSize)
                end
            end)
        end
    end)
    
    return list
end

function DeleteSpotterLists()
    for _,lists in pairs(circlePolys) do
        for _,v in pairs(lists) do
            gl.DeleteList(v)
        end
    end
    circlePolys = {}
end

function CreateSpotterLists()

    DeleteSpotterLists()

    local allyTeamList = spGetAllyTeamList()

    if useTeamColours then
        spotterOpacity = 0.15
        for _,allyID in ipairs(allyTeamList) do
            local teamList = Spring.GetTeamList(allyID)
            for _,teamID in ipairs(teamList) do
                local thisColour = {}
                thisColour[1],thisColour[2],thisColour[3] = Spring.GetTeamColor(teamID)
                colours[teamID] = thisColour
                circlePolys[teamID] = {}
                for j=circlePartsMin,circlePartsMax do
                    circlePolys[teamID][j] = CreateSpotterList(colours[teamID][1],colours[teamID][2],colours[teamID][3],spotterOpacity,j)
                end
            end
        end
    else --use ally team colours taken from spotterColours
        spotterOpacity = 0.1
        for i,allyID in ipairs(allyTeamList) do
            local thisColour = spotterColours[i]
            local circlePolyIDs = {}
            for j=circlePartsMin,circlePartsMax do
                circlePolyIDs[j] = CreateSpotterList(thisColour[1],thisColour[2],thisColour[3],spotterOpacity,j)                
            end
      
            local teamList = Spring.GetTeamList(allyID)
            for _,teamID in ipairs(teamList) do
                colours[teamID] = thisColour
                circlePolys[teamID] = {}
                for j=circlePartsMin,circlePartsMax do
                    circlePolys[teamID][j] = circlePolyIDs[j]                
                end
            end
            if i>#spotterColours then end
        end
    end

end

function CreateXRayShader()
    gl.DeleteShader(shader)
    
    shader = gl.CreateShader({

    uniform = {
      edgeExponent = edgeExponent * highlightOpacity,
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

function SetUnitConf() -- currently only using circles and xscale!
    for udid, unitDef in pairs(UnitDefs) do
        local xsize, zsize = unitDef.xsize, unitDef.zsize
        local scale = scaleFactor*( xsize^2 + zsize^2 )^0.5
        local shape, xscale, zscale
        
        -- old code, kept for reference
        --[[if (unitDef.isBuilding or unitDef.isFactory or unitDef.speed==0) then
            shape = 'square'
            xscale, zscale = rectangleFactor * xsize, rectangleFactor * zsize
        elseif (unitDef.isAirUnit) then
            shape = 'triangle'
            xscale, zscale = scale, scale
        else
        ]]
            shape = 'circle'
            xscale, zscale = scale, scale
        --end
        unitConf[udid] = {shape=shape, xscale=xscale, zscale=zscale}
    end
end


--------------------------------------------------------------------------------
-- Drawing
--------------------------------------------------------------------------------

function widget:Initialize()    
    SetUnitConf()
    CreateSpotterLists()
    CreateXRayShader()
    
    visibleUnits = Spring.GetAllUnits()    
    n_visibleUnits = #visibleUnits
    
    if not gl.CreateShader or not gl.DeleteShader or true then
        Spring.Log("gui_highlight_units.lua", LOG.WARNING, "Your hardware does not support shaders, disabled")
        widgetHandler:RemoveWidget(self)
    end
   
    Chili  = WG.Chili
    if not Chili then return end
    screen = Chili.Screen0
    Menu   = WG.MainMenu
    
    Menu.AddOption{
			tab = 'Interface',
			children = {
				Chili.Label:New{caption='Highlight Units',x='0%',fontsize=18},
				Chili.Checkbox:New{caption='Show platters',x='10%',width='80%',
						checked=drawPlatter,setting=drawPlatter,OnChange={function() drawPlatter = not drawPlatter; end}}, --toggle doesn't work
				Chili.Checkbox:New{caption='Use XRay shader',x='10%',width='80%',
						checked=drawXRayShader,setting=drawXRayShader,OnChange={function() drawXRayShader = not drawXRayShader; end}},
				Chili.Checkbox:New{caption='Highlight allies',x='10%',width='80%',
						checked=highlightAllyTeam,setting=highlightAllyTeam,OnChange={function() highlightAllyTeam = not highlightAllyTeam; end}},
				Chili.Line:New{width='100%'}
        }
    }
    
end

function widget:Shutdown()    
    DeleteSpotterLists()
    gl.DeleteShader(shader)
end

function widget:PlayerChanged()
    amISpec = spGetSpectatingState()
    CreateSpotterLists()
end

local visibleUnits = {}
function widget:DrawWorldPreUnit()

    local timer = spGetTimer()
    if (drawPlatter or drawXRayShader) and updateTime < spDiffTimers(timer,prevUpdate) then 
        visibleUnits = spGetVisibleUnits()
        n_visibleUnits = #visibleUnits
        prevUpdate = timer
    end
    
    if spIsGUIHidden() then 
        guiHidden = true
        return 
    else
        guiHidden = false
    end

    if not drawPlatter then
        return 
    end

    gl.DepthTest(true)
    gl.PolygonOffset(-100, -2)
    gl.Blending(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)     
    for i=1, n_visibleUnits do
        local unitID = visibleUnits[i]
        if spValidUnitID(unitID) then
            local teamID = spGetUnitTeam(unitID)
            local allyID = spGetUnitAllyTeam(unitID)
            local unitDefID = spGetUnitDefID(unitID)
            if circlePolys[teamID] ~= nil and unitDefID then
                if highlightAllyTeam or amISpec or (allyID ~= myAllyID) then
                    local unitScale = unitConf[unitDefID].xscale*2
                    glDrawListAtUnit(unitID, circlePolys[teamID][12], false, unitScale, 1.0, unitScale) 
                end
            end
        end
    end
end

function widget:DrawWorld()
    if not drawXRayShader or useTeamColours or guiHidden then
        return 
    end

    if smoothPolys then
        gl.Smoothing(nil, nil, true)
    end

    gl.UseShader(shader)
    gl.DepthTest(true)
    gl.Blending(GL_SRC_ALPHA, GL_ONE)
    gl.PolygonOffset(-2, -2)

    for i=1, n_visibleUnits do
        local unitID = visibleUnits[i] 
        local teamID = spGetUnitTeam(unitID)
        local allyID = spGetUnitAllyTeam(unitID)
        if circlePolys[teamID] ~= nil and not spIsUnitIcon(unitID) then
            if highlightAllyTeam or amISpec or (allyID ~= myAllyID) then
                glColor(colours[teamID][1], colours[teamID][2], colours[teamID][3],0.1)
                glUnit(unitID, true)
            end
        end
    end

    gl.PolygonOffset(false)
    gl.Blending(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
    gl.DepthTest(false)
    gl.UseShader(0)
    gl.Color(1, 1, 1, 1)
            
    if smoothPolys then
        gl.Smoothing(nil, nil, false)
    end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetConfigData(data)
    savedTable = {}
    savedTable.drawPlatter				= drawPlatter
    savedTable.drawXRayShader			= drawXRayShader
    savedTable.highlightAllyTeam		= highlightAllyTeam
    return savedTable
end

function widget:SetConfigData(data)
    if data.drawPlatter ~= nil				then  drawPlatter				= data.drawPlatter end
    if data.drawXRayShader ~= nil			then  drawXRayShader			= data.drawXRayShader end
    if data.highlightAllyTeam ~= nil		then  highlightAllyTeam		    = data.highlightAllyTeam end
end

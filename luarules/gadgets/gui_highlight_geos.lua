
function gadget:GetInfo()
    return {
        name      = 'Highlight Geos',
        desc      = 'Highlights geothermal spots when in metal map view',
        author    = 'Niobium',
        version   = '1.0',
        date      = 'Mar, 2011',
        license   = 'GNU GPL, v2 or later',
        layer     = 0,
        enabled   = true,  --  loaded by default?
    }
end

if  (gadgetHandler:IsSyncedCode()) then
    return false
end


----------------------------------------------------------------
-- Globals
----------------------------------------------------------------
local geoDisplayList

----------------------------------------------------------------
-- Speedups
----------------------------------------------------------------
local glBeginEnd = gl.BeginEnd
local glDepthTest = gl.DepthTest
local glCallList = gl.CallList
local glColor = gl.Color
local glVertex = gl.Vertex
local GL_TRIANGLE_FAN = GL.TRIANGLE_FAN
local spGetMapDrawMode = Spring.GetMapDrawMode
local SpGetSelectedUnits = Spring.GetSelectedUnits

local am_geo = UnitDefNames.amgeo.id
local arm_geo = UnitDefNames.armgeo.id
local arm_gmm = UnitDefNames.armgmm.id
local cm_geo = UnitDefNames.cmgeo.id
local corbhmth_geo = UnitDefNames.corbhmth.id
local cor_geo = UnitDefNames.corgeo.id

----------------------------------------------------------------
-- Functions
----------------------------------------------------------------
local num_segs = 20

local function DrawGeo(x,y,z)
    
    glBeginEnd(GL_TRIANGLE_FAN, function()    
        glColor(1,1,0,1) -- colour of effect 
        glVertex(x, y, z)
        glColor(1,1,0,0)

        local theta = 0
        for i=0,num_segs do 
            glVertex(x+100*math.sin(theta),y,z+100*math.cos(theta))                        
            theta = theta + 2*math.pi/num_segs
        end                
    end)
end

local function HighlightGeos()
    local features = Spring.GetAllFeatures()
    for i = 1, #features do
        local fID = features[i]
        if FeatureDefs[Spring.GetFeatureDefID(fID)].geoThermal then
            local fx, fy, fz = Spring.GetFeaturePosition(fID)
            DrawGeo(fx,fy,fz)
        end
    end
end

----------------------------------------------------------------
-- Callins
----------------------------------------------------------------
function gadget:Shutdown()
    if geoDisplayList then
        gl.DeleteList(geoDisplayList)
    end
end

function gadget:DrawWorld()
    local _, cmdID = Spring.GetActiveCommand()
    if spGetMapDrawMode() == 'metal' or cmdID == -am_geo or cmdID == -arm_geo or cmdID == -cm_geo
    or cmdID == -corbhmth_geo or cmdID == -cor_geo or cmdID == -arm_gmm then
        
        if not geoDisplayList then
            geoDisplayList = gl.CreateList(HighlightGeos)
        end
        
        glDepthTest(false)
        glCallList(geoDisplayList)
        glColor(1, 1, 1, 1)
        glDepthTest(true)
    end
end

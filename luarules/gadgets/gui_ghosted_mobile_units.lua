function gadget:GetInfo()
    return {
        name      = "Ghost Mobile Units",
        desc      = "Displays ghosted mobile enemy units under their radar blips\n(the engine does it automatically for immobile units)",
        author    = "very_bad_soldier",
        date      = "July 21, 2008",
        license   = "GNU GPL v2",
        layer     = 0,
        enabled   = true
    }
end

if  (gadgetHandler:IsSyncedCode()) then
    return false
end

local lineWidth = 1.0 -- calcs dynamic now

local printDebug

local udefTab                 = UnitDefs
local spGetUnitDefID          = Spring.GetUnitDefID
local spEcho                  = Spring.Echo
local spGetUnitPosition       = Spring.GetUnitPosition
local spGetGameSeconds        = Spring.GetGameSeconds
local floor                   = math.floor
local pairs                   = pairs
local spGetMyPlayerID         = Spring.GetMyPlayerID
local spGetPlayerInfo         = Spring.GetPlayerInfo
local spIsUnitInView          = Spring.IsUnitInView
local spIsUnitAllied          = Spring.IsUnitAllied
local spGetUnitPosErrorParams = Spring.GetUnitPosErrorParams
local spGetRadarErrorParams   = Spring.GetRadarErrorParams

local glColor               = gl.Color
local glDepthTest           = gl.DepthTest
local glUnitShape           = gl.UnitShape
local glPopMatrix           = gl.PopMatrix
local glPushMatrix          = gl.PushMatrix
local glTranslate           = gl.Translate
----------------------------------------------------------------

local debug = false
local dots = {}
local lastTime
local updateInt = 2 --seconds for the ::update loop

local myTeamID = Spring.GetMyTeamID()
local allyTeamID = Spring.GetMyAllyTeamID()

function gadget:PlayerChanged()
    myTeamID = Spring.GetMyTeamID()
    allyTeamID = Spring.GetMyAllyTeamID()
end

function gadget:UnitEnteredRadar(unitID, allyTeam)
    if spIsUnitAllied(unitID) then
        return
    end

    if ( dots[unitID] ~= nil ) then
        dots[unitID]["radar"] = true
    end
end

function gadget:UnitEnteredLos(unitID, allyTeam )
    if spIsUnitAllied(unitID) then
        return
    end

    --update unitID info, ID could have been reused already!
    local udefID = spGetUnitDefID(unitID)
    local udef = udefTab[udefID]
        
    -- skip buildings, they get drawn ghosted anyway by the engine
    -- but mobile units don't
    -- (both buildings and mobile units do get 'ghosted' radar dots)
    if ( udef.isBuilding == false and udef.isFactory == false ) then 
        dots[unitID] = {}
        dots[unitID]["unitDefId"] = udefID
        dots[unitID]["teamId"] = allyTeam
        dots[unitID]["radar"] = true
        dots[unitID]["los"] = true
    else
        dots[unitID] = nil    
    end
end


function gadget:UnitCreated(unitID, allyTeam)
    if spIsUnitAllied(unitID) then
        return
    end

    --kill the dot info if this unitID gets reused on own team
    if ( dots[unitID] ~= nil ) then
        dots[unitID] = nil
    end
end

function gadget:UnitDestroyed(unitID, unitDefID, teamID, attackerID, attackerDefID, attackerTeamID)
    if spIsUnitAllied(unitID) then
        return
    end

    if ( dots[unitID] ~= nil ) then
        dots[unitID] = nil
    end
end

function gadget:UnitLeftRadar(unitID, allyTeam)
    if spIsUnitAllied(unitID) then
        return
    end

    if ( dots[unitID] ~= nil ) then
        dots[unitID]["radar"] = false
    end
end

function gadget:UnitLeftLos(unitID, allyTeam)
    if spIsUnitAllied(unitID) then
        return
    end

    if ( dots[unitID] ~= nil ) then
        dots[unitID]["los"] = false
    end
end


function gadget:DrawWorld()
    glColor(1.0, 1.0, 1.0, 0.35 )
    glDepthTest(true)

    for unitID, dot in pairs( dots ) do
        if ( dot["radar"] == true ) and ( dot["los"] == false ) and ( dot["unitDefId"] ~= nil ) then
            local x, y, z = spGetUnitPosition(unitID)
            local ex, ey, ez = spGetUnitPosErrorParams(unitID)
            local allyteamErrorSize,_,_ = spGetRadarErrorParams(allyTeamID)
            if x and ( spIsUnitInView(unitID) ) then
                glPushMatrix()
                glTranslate( x+ex*allyteamErrorSize, y+ey*allyteamErrorSize + 5 , z+ez*allyteamErrorSize )
                glUnitShape( dot["unitDefId"], dot["teamId"], false, true, false)                          
                glPopMatrix()
            end
        end
    end

    glDepthTest(false)
     glColor(1, 1, 1, 1)
end

function gadget:Update()
    local timef = spGetGameSeconds()
    local time = floor(timef)

    -- update timers once every <updateInt> seconds
    if (time % updateInt == 0 and time ~= lastTime) then    
        lastTime = time
        --do update stuff:
        local playerID = spGetMyPlayerID()
        local _, _, spec, _, _, _, _, _ = spGetPlayerInfo(playerID)
        
        if ( spec == true ) then
            gadgetHandler:RemoveGadget()
            return false
        end
    end
end

function printDebug( value )
    if ( debug ) then
        if ( type( value ) == "boolean" ) then
            if ( value == true ) then spEcho( "true" )
                else spEcho("false") end
        elseif ( type(value ) == "table" ) then
            spEcho("Dumping table:")
            for key,val in pairs(value) do 
                spEcho(key,val) 
            end
        else
            spEcho( value )
        end
    end
end
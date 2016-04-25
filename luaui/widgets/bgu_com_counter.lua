function widget:GetInfo()
    return {
        name        = "Com Counter",
        desc        = "Shows the number of bois left",
        author      = "BrainDamage, Bluestone",
        date        = "Feb, 2014",
        license     = "GNU GPL, v2 or later",
        layer       = 0,
        enabled     = true
    }
end

---------------------------------------------------------------------------------------------------
--  Declarations
---------------------------------------------------------------------------------------------------

local armcomDefID = UnitDefNames.armcom.id
local corcomDefID = UnitDefNames.corcom.id

local spGetMyTeamID         = Spring.GetMyTeamID
local spGetGameFrame        = Spring.GetGameFrame

local receiveCount          = (tostring(Spring.GetModOptions().mo_enemycomcount) == "1") or nil

local allyComs              = 0
local enemyComs             = 0 
local prevEnemyComs         = 0 -- track changes when receiving TeamRulesParam
local amISpec               = Spring.GetSpectatingState()
local myTeamID              = spGetMyTeamID()
local myAllyTeamID          = Spring.GetMyAllyTeamID()
local inProgress            = spGetGameFrame() > 0
local countChanged          = true
local flickerLastState      = nil
local is1v1                 = Spring.GetTeamList() == 3 -- +1 because of gaia
local comMarkers            = {}
local removeMarkerFrame     = -1
local lastMarkerFrame       = -1

local largeRelFontSize = 24
local smallRelFontSize = 15
local largeFontSize, smallFontSize


---------------------------------------------------------------------------------------------------
--  GUI
---------------------------------------------------------------------------------------------------

function makeText(i) return (i~=nil) and tostring(i) or "" end

local green        = {0.2, 1.0, 0.2, 1.0}
local red          = {1.0, 0.2, 0.2, 1.0}

local buttonColour, panelColour, sliderColour 

function widget:Initialize()
    Chili = WG.Chili
    buttonColour = WG.buttonColour

    yellowOverlay = Chili.Image:New{
        color  = {1,0.95,0.4, 0.2},
        height = '100%', 
        width  = '100%',
        file   = 'LuaUI/Images/comIcon.png',
    }
                    
    enemyComText = Chili.Label:New{ 
        bottom = '5%',
        right = '5%',
        caption  = makeText(enemyComs),
        align = "right",
        valign = "bottom", 
        margin = {0,0,0,0},
        font = {
            color = red,
            outline          = true,
            autoOutlineColor = true,
            outlineWidth     = 5,
            outlineWeight    = 3,
        },
    } 

    allyComText = Chili.Label:New{
        x = '18%', --hack because label center alignment don't take account of text length
        width = '80%',
        y = '25%',
        caption  = makeText(allyComs),
        align = "center", 
        valign = "center",
        margin = {0,0,0,0},
        font = {
            color = green,
            outline          = true,
            autoOutlineColor = true,
            outlineWidth     = 5,
            outlineWeight    = 3,
        },
    }
    
    button = Chili.bguButton:New{
        x = 0,
        y = 0,
        width = '100%',
        height = '100%',        
        padding   = {0,0,0,0}, 
        onClick   = {MarkComs},
        borderColor = {0,0,0,0},
        borderColor2 = {0,0,0,0},
        backgroundColor = buttonColour,
        caption = "",
        children  = {
            Chili.Image:New {
                color       = {1,1,1,0.3},
                file        = 'LuaUI/Images/comIcon.png',
                x = '12%',
                y = '12%',
                width       = '76%',
                height      = '76%',
                children = {
                    yellowOverlay, enemyComText, allyComText
                },
            }
    
        }
    }

    window = Chili.Window:New{
        parent    = Chili.Screen0,
        padding   = {0,0,0,0}, 
        color     = {0,0,0,0},
        draggable = false,
        tweakdraggable = false,
        resizable = false,
        tweakResizable = false,
        children = {button}    
    }
    
    ResizeUI()

    enemyComText:Hide()
    allyComText:Hide()    
    
    if Spring.GetGameFrame() > 0 then
        widget:GameStart()
    end
    
end

function ResizeUI()
    smallFontSize = WG.RelativeFontSize(smallRelFontSize)
    largeFontSize = WG.RelativeFontSize(largeRelFontSize)
    
    allyComText.font.size = largeFontSize
    allyComText:Invalidate()
    enemyComText.font.size = smallFontSize
    enemyComText:Invalidate()
    
    local x = WG.UIcoords.comCounter.x
    local y = WG.UIcoords.comCounter.y
    local w = WG.UIcoords.comCounter.w
    local h = WG.UIcoords.comCounter.h
    window:SetPos(x,y,w,h)
end

---------------------------------------------------------------------------------------------------
--  Counting
---------------------------------------------------------------------------------------------------

function isCom(unitID,unitDefID)
    if not unitDefID and unitID then
        unitDefID =  Spring.GetUnitDefID(unitID)
    end
    if not unitDefID or not UnitDefs[unitDefID] or not UnitDefs[unitDefID].customParams then
        return false
    end
    return UnitDefs[unitDefID].customParams.iscommander ~= nil
end

function UpdateCaptions()
    allyComText:SetCaption(makeText(allyComs))
    enemyComText:SetCaption(makeText(enemyComs))
end

function Recount()
    -- recount my own ally team coms
    allyComs = 0
    local myAllyTeamList = Spring.GetTeamList(myAllyTeamID)
    for _,teamID in ipairs(myAllyTeamList) do
        allyComs = allyComs + Spring.GetTeamUnitDefCount(teamID, armcomDefID) + Spring.GetTeamUnitDefCount(teamID, corcomDefID)
    end
    countChanged = true
    
    if amISpec then
        -- recount enemy ally team coms
        enemyComs = 0
        local allyTeamList = Spring.GetAllyTeamList()
        for _,allyTeamID in ipairs(allyTeamList) do
            if allyTeamID ~= myAllyTeamID then
                local teamList = Spring.GetTeamList(allyTeamID)
                for _,teamID in ipairs(teamList) do
                    enemyComs = enemyComs + Spring.GetTeamUnitDefCount(teamID, armcomDefID) + Spring.GetTeamUnitDefCount(teamID, corcomDefID)
                end
            end
        end
    end
    
    UpdateCaptions()
end

function widget:UnitCreated(unitID, unitDefID, unitTeam)
    if not isCom(unitID,unitDefID) then
        return
    end
    
    --record com created
    local _,_,_,_,_,allyTeamID = Spring.GetTeamInfo(unitTeam)
    if allyTeamID == myAllyTeamID then
        allyComs = allyComs + 1
    elseif amISpec then
        enemyComs = enemyComs + 1
    end
    countChanged = true
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
    if not isCom(unitID,unitDefID) then
        return
    end
    
    --record com died
    local _,_,_,_,_,allyTeamID = Spring.GetTeamInfo(unitTeam)
    if allyTeamID == myAllyTeamID then
        allyComs = allyComs - 1
    elseif amISpec then
        enemyComs = enemyComs - 1
    end
    countChanged = true
end

-- BA does not allow sharing to enemy, so no need to check Given, Taken, etc

--------------------------------------------------------------------------------

function MarkComs()
    local units = Spring.GetAllUnits()
    -- place a mark on each com
    for i=1,#units do
        if Spring.GetUnitAllyTeam(units[i]) == myAllyTeamID then
            if isCom(units[i],_) then
                local x,y,z = Spring.GetUnitPosition(units[i])
                Spring.MarkerAddPoint(x,y,z,"",true)
                comMarkers[#comMarkers+1] = {x,y,z}
                removeMarkerFrame = Spring.GetGameFrame() + 30*5
            end
        end
    end
end

function CheckStatus()
    --update my identity
    amISpec    = Spring.GetSpectatingState()
    myAllyTeamID = Spring.GetMyAllyTeamID()
    myTeamID = Spring.GetMyTeamID()
    if amISpec and enemyComText.hidden then
        enemyComText:Show()
    end
end

function flicker()
    return spGetGameFrame() % 12 < 6
end 

function widget:GameStart()
    inProgress = true
    CheckStatus()
    Recount()
    
    allyComText:Show()
    if receiveCount then
        enemyComText:Show()
    end
end

function widget:GameFrame(n)
    -- check if the team that we are spectating changed
    if amISpec and myTeamID ~= spGetMyTeamID() then
        CheckStatus()
        Recount()
    end
    
    -- check if we have received a TeamRulesParam from the gadget part
    if not amISpec and receiveCount then
        enemyComs = Spring.GetTeamRulesParam(myTeamID, "enemyComCount")
        if enemyComs ~= prevEnemyComs then
            countChanged = true
            prevEnemyComs = enemyComs
        end
    end
    
    -- remove all markers
    if markers and n == removeMarkerFrame then
        for i=1,#comMarkers do
            Spring.MarkerErasePosition(comMarkers[i][1], comMarkers[i][2], comMarkers[i][3])
            comMarkers[i] = nil
        end
    end
end

function widget:PlayerChanged()
    -- probably not needed but meh, its cheap
    CheckStatus()
    Recount()
end

function widget:GameOver()
    inProgress = false
    if not yellowOverlay.hidden then
        yellowOverlay:Hide()
    end
end


function widget:Update()
    if not inProgress then return end
    
    local flickerState = flicker()
    if countChanged or flickerLastState ~= flickerState then
        countChanged = false
        CheckStatus()
        UpdateCaptions()
       
        if (allyComs <= 1) and not is1v1 then
            if flickerState then
                if not yellowOverlay.hidden then
                    yellowOverlay:Hide()
                end
            else
                if yellowOverlay.hidden then
                    yellowOverlay:Show()
                end
            end
        end        
        flickerLastState = flickerState
    end    
end

function widget:ViewResize()
    ResizeUI()
end

function widget:Shutdown()
    window:Dispose()
end




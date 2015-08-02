-- WIP
function widget:GetInfo()
    return {
        name      = 'Selection info',
        desc      = 'Shows information about the current selection',
        author    = 'Funkencool',
        date      = '2013',
        license   = 'GNU GPL v2',
        layer     = 2000,
        enabled   = true,
        handler   = true,
    }
end

local imageDir = 'luaui/images/buildIcons/'

local Chili, screen, infoWindow, groundInfo, groundText
local unitInfo, unitName, unitIcon, selectionGrid, unitHealthText, unitHealth
local healthBars = {}
local updateNow  = false

local curTip --[[ current tooltip type: 
                  -3 for ground info
                  -2 for so many unitDefIDs that we just give text info 
                  -1 for multiple unitDefIDs that fit with pics (<=9)
                  >=0 for a single unit & is the unitID  ]]

local spGetTimer                = Spring.GetTimer
local spDiffTimers              = Spring.DiffTimers
local spGetUnitDefID            = Spring.GetUnitDefID
local spGetUnitTooltip          = Spring.GetUnitTooltip
local spGetSelectedUnits        = Spring.GetSelectedUnits
local spGetUnitHealth           = Spring.GetUnitHealth
local spGetSelectedUnitsSorted  = Spring.GetSelectedUnitsSorted
local spGetMouseState           = Spring.GetMouseState
local spTraceScreenRay          = Spring.TraceScreenRay
local spGetGroundHeight         = Spring.GetGroundHeight
local spGetGroundInfo           = Spring.GetGroundInfo
local spGetUnitResources        = Spring.GetUnitResources
local spGetSelectedUnitsCounts  = Spring.GetSelectedUnitsCounts
local floor = math.floor

local r,g,b     = Spring.GetTeamColor(Spring.GetMyTeamID())
local teamColor = {r,g,b}

local timer = spGetTimer()
local healthTimer = timer
local groundTimer = timer

local green = '\255\0\255\0'
local red = '\255\255\0\0'
local grey = '\255\150\150\150'
local white = '\255\255\255\255'
local mColour = '\255\153\153\204'
local eColour = '\255\255\255\76'
local blue = "\255\200\200\255"

function round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

----------------------------------
local function refineSelection(obj)
        Spring.SelectUnitArray(obj.unitIDs)
end

-- add unitDefID (curTip = -1)
local function addUnitGroup(name,texture,overlay,unitIDs)
    local count = #unitIDs
    if count == 1 then count = '' end
    
    local unitCount = Chili.Label:New{
        caption = count,
        y       = 0,
        right   = 0,
    }
    
    healthBars[#healthBars + 1] = Chili.Progressbar:New{
        unitIDs = unitIDs,
        value   = 0,
        bottom  = 1,
        x       = 0,
        width   = '100%',
        height  = 6,
        color   = {0.5,1,0,1},
    }
    
    local unitIcon = Chili.Image:New{
        file     = texture,
        height   = '100%',
        width    = '100%',
        children = {
            Chili.Image:New{
                color    = teamColor,
                height   = '100%',
                width    = '100%',
                file     = overlay,
                children = {unitCount}
            },
        },
    }
    
    local button = Chili.Button:New{
        unitIDs = unitIDs,
        caption  = '',
        margin   = {1,1,1,1},
        padding  = {0,0,0,0},
        children = {unitIcon, healthBars[#healthBars]},
        onclick = {refineSelection},       
    }
    
    selectionGrid:AddChild(button)
end


----------------------------------
-- unit info (curTip >= 0)

function round(num, idp)
    return string.format("%." .. (idp or 0) .. "f", num) -- lua is such a great language that this is the only reliable way to round
end

local function ResToolTip(Mmake, Muse, Emake, Euse)
    --if Mmake>0.01 or Muse>0.01 or Emake>0.01 or Euse>0.01 then
        return white .. "M: " .. green .. '+' .. round(Mmake,1) .. '  ' .. red .. '-' .. round(Muse,1) .. "\n" ..  white .. "E:  " .. green .. '+' .. round(Emake,1) .. '  ' .. red .. "-" .. round(Euse,1)
    --else
    --   return ""
    --end
end


local function showUnitInfo(unitDefID, texture, overlay, description, humanName, health, maxHealth, Mmake, Muse, Emake, Euse, Mcost, Ecost, n)

    local numText = ""
    if n>1 then numText = "\n " .. blue .. "(x" .. tostring(n) .. ")" end
    
    unitName = Chili.TextBox:New{
        x      = 0,
        y      = 5,
        right  = 0,
        bottom = 0,
        text   = " " .. humanName..'\n'.. " " .. description .. numText,
    }
    
    unitHealthText = Chili.TextBox:New{
        x      = 5,
        bottom = 21,
        text   = math.floor(health) ..' / '.. math.floor(maxHealth),
    }
    
    unitHealth = Chili.Progressbar:New{
        value   = 0,
        bottom  = 5,
        x       = 5,
        width   = '50%',
        height  = 10,
        color   = {0.5,1,0,1},
    }
        
    unitCostTextTitle = Chili.TextBox:New{
        x      = '60%',
        height = 10,
        bottom = 35,
        text   = 'Total:',
    }

    unitCostText = Chili.TextBox:New{
        x      = '62%',
        height = 28,
        bottom = 3,
        text   = mColour .. Mcost .. '\n' .. eColour .. Ecost,
    }
    
    unitResText = Chili.TextBox:New{
        x        = 5,
        bottom   = 35,
        height   = 24,
        text     =  ResToolTip(Mmake, Muse, Emake, Euse),
        fontsize = 12,
    }
        
    unitIcon = Chili.Image:New{
        file     = texture,
        y        = 0,
        height   = '100%',
        width    = '100%',
        children = {
            Chili.Image:New{
                color    = teamColor,
                height   = '100%',
                width    = '100%',
                file     = overlay,
                children = {unitName, unitHealthText, unitHealth, unitResText, unitCostTextTitle, unitCostText},
            }
        }
    }
    
    
    unitInfo:AddChild(unitIcon)
    
    if UnitDefs[unitDefID].customParams.iscommander then
        unitCostText:Hide()
    end
    if (n==1) then unitCostTextTitle:Hide() end
        
end

local function addUnitGroupInfo()

    unitCostText = Chili.TextBox:New{
        name     = "unitCostText",
        x        = '70%',
        height   = 28,
        bottom   = 10,
        text     = "", --mColour .. Mcost .. '\n' .. eColour .. Ecost,
        fontsize = 12
    }
        
    unitResText = Chili.TextBox:New{
        name     = "unitResText",
        x        = 5,
        bottom   = 10,
        height   = 24,
        text     =  "", --ResToolTip(Mmake, Muse, Emake, Euse),
        fontsize = 12,
    }

    unitInfo:AddChild(unitCostText)
    unitInfo:AddChild(unitResText)
end

----------------------------------
-- text unit info only (curTip = -2)
local function showBasicSelectionInfo(num, numTypes)
    
    basicUnitInfo = Chili.TextBox:New{
        x      = 0,
        y      = 5,
        right  = 0,
        bottom = 0,
        text   = " Units selected: " .. num .. "\n Unit types: " .. numTypes,
    }
    
    unitInfo:AddChild(basicUnitInfo)
end

----------------------------------
local max = math.max
local min = math.min
local schar = string.char
local modColScale = 2
local function speedModCol(x)
    x = (x-1)*modColScale + 1
    local r,g,b = 1,1,1
    if x<1 then
        g = max(0.01,x)
        b = max(0.01,x)
    elseif x>1 then
        x = min(x, 1.99)
        r = min(0.99,2-x)
        b = min(0.99,2-x)
    end
    return schar(255, r*255, g*255, b*255)
end
----------------------------------
-- ground info (curTip = -3)
local function updateGroundInfo()
    local mx, my    = spGetMouseState()
    local focus,map = spTraceScreenRay(mx,my,true)
    if map and map[1] then
        if groundInfo.hidden then groundInfo:Show() end
        local px,pz = math.floor(map[1]),math.floor(map[3])
        local py = math.floor(spGetGroundHeight(px,pz))
        groundText:SetText(
            "Map Coordinates"..
            "\n Height: " .. py ..
            "\n X: ".. px ..
            "\n Z: ".. pz .. "\n\n"
        )

        local _,_,_,veh,bot,hvr,ship,_ = spGetGroundInfo(px,pz)
        vehCol = speedModCol(veh)
        botCol = speedModCol(bot)
        hvrCol = speedModCol(hvr)
        shipCol = speedModCol(ship)
        groundText2:SetText(
            "Speeds" ..
            "\n  Veh: " .. vehCol .. round(veh,2) .. white .. 
            "  Bot: " .. botCol .. round(bot,2) .. white ..
            "\n  Hvr: " .. hvrCol .. round(hvr,2) .. white ..
            "  Ship: " .. shipCol .. round(ship,2) .. white           
        )
    elseif groundInfo.visible then
        groundInfo:Hide()
    end
end

----------------------------------
local function updateUnitInfo()
    
    if curTip >= 0 then     
        --single unit    
        units = spGetSelectedUnits()
        
        local curHealth = 0
        local maxHealth = 0
        local Mmake, Muse, Emake, Euse = 0,0,0,0
        for _, uID in ipairs(units) do
            c, m = spGetUnitHealth(uID)
            mm, mu, em, eu = spGetUnitResources(uID)
            curHealth = curHealth + (c or 0)
            maxHealth = maxHealth + (m or 0)
            Mmake = Mmake + (mm or 0)
            Muse = Muse + (mu or 0)
            Emake = Emake + (em or 0)
            Euse = Euse + (eu or 0)
        end
        unitHealthText:SetText(math.floor(curHealth) ..' / '.. math.floor(maxHealth)) 
        unitHealth:SetMinMax(0, maxHealth)
        unitHealth:SetValue(curHealth) 
          unitResText:SetText(ResToolTip(Mmake, Muse, Emake, Euse))
        
    elseif curTip == -1 then 
        --multiple units, but not so many we cant fit pics
        local Ecost,Mcost = 0,0
        local Mmake,Muse,Emake,Euse = 0,0,0,0
        for a = 1, #healthBars do
            local health,max = 0,0
            for b = 1, #healthBars[a].unitIDs do
                local unitID = healthBars[a].unitIDs[b]
                local defID = spGetUnitDefID(unitID)
                if defID then
                    local h, m = spGetUnitHealth(unitID)
                    max   = max + (m or 0)
                    health = health + (h or 0)
                    local Mm, Mu, Em, Eu = spGetUnitResources(unitID)
                    local Ec = UnitDefs[defID].energyCost
                    local Mc = UnitDefs[defID].metalCost
                    Mmake = Mmake + (Mm or 0)
                    Emake = Emake + (Em or 0)
                    Muse = Muse + (Mu or 0)
                    Euse = Euse + (Eu or 0)
                    if not UnitDefs[defID].customParams.iscommander then
                        Mcost = Mcost + Mc
                        Ecost = Ecost + Ec                
                    end
                end
            end
            healthBars[a].max = max
            healthBars[a]:SetValue(health)
        end
        
        unitInfo:GetChildByName('unitResText'):SetText(ResToolTip(Mmake, Muse, Emake, Euse))
        if Mcost>0 then
            unitInfo:GetChildByName('unitCostText'):SetText(mColour .. Mcost .. '\n' .. eColour .. Ecost)
        end
    end
    
    updateNow = false
end

----------------------------------
local function getInfo()
    local r,g,b = Spring.GetTeamColor(Spring.GetMyTeamID())
    teamColor = {r,g,b}

    units = spGetSelectedUnits()
    sUnits = spGetSelectedUnitsCounts()

    if #units == 0 then
        --info about point on map corresponding to cursor 
        curTip = -3
        return
    end    
        
    if sUnits["n"] == 1 then
        
        --detailed info about a single unitDefID
        local unitID      = units[1]
        local defID       = spGetUnitDefID(unitID)
        curTip = defID

        local description = UnitDefs[defID].tooltip or ''
        local name        = UnitDefs[defID].name
        local texture     = imageDir..'Units/' .. name .. '.dds'
        local overlay     = imageDir..'Overlays/' .. name .. '.dds'
        local humanName   = UnitDefs[defID].humanName

        local Ecost = 0
        local Mcost = 0
        local curHealth = 0
        local maxHealth = 0
        local Mmake, Muse, Emake, Euse = 0,0,0,0
        for _, uID in ipairs(units) do
            Ecost = Ecost + UnitDefs[defID].energyCost
            Mcost = Mcost + UnitDefs[defID].metalCost 
            local c, m = spGetUnitHealth(uID)
            local mm, mu, em, eu = spGetUnitResources(uID)
            curHealth = curHealth + (c or 0)
            maxHealth = maxHealth + (m or 0)
            Mmake = Mmake + (mm or 0)
            Muse = Muse + (mu or 0)
            Emake = Emake + (em or 0)
            Euse = Euse + (eu or 0)
        end
                
        showUnitInfo(defID, texture, overlay, description, humanName, curHealth, maxHealth, Mmake, Muse, Emake, Euse, Mcost, Ecost, #units)        
    else
        --broad info about lots of units
        local sortedUnits = spGetSelectedUnitsSorted()
        local unitDefIDCount = 0
        local unitCount = 0
        --see if sortedUnits has too many elements
        if sortedUnits["n"] <= 6 then 
            curTip = -1
            --pics & healthbars, grouped by UnitDefID, if it fits
            for unitDefID, unitIDs in pairs(sortedUnits) do
                if unitDefID ~= 'n' then 
                    local name    = UnitDefs[unitDefID].name
                    local texture = imageDir..'Units/' .. name .. '.dds'
                    local overlay = imageDir..'Overlays/' .. name .. '.dds'
                    addUnitGroup(name,texture,overlay,unitIDs, unitDefID)
                end
            end
            addUnitGroupInfo()
        else
            curTip = -2
            showBasicSelectionInfo(#units, sortedUnits["n"])
        end
    end
        
    updateUnitInfo()
end

----------------------------------
function widget:Initialize()
    

    
    if (not WG.Chili) then
        widgetHandler:RemoveWidget()
        return
    end
    
    Chili   = WG.Chili
    screen = Chili.Screen0
    local winSize = screen.height * 0.2
    
    --Main window, ancestor of everything
    infoWindow = Chili.Panel:New{
        padding = {6,6,6,6},
        parent  = screen,
        x       = 0,
        y       = 0,
        width   = winSize * 1.05,
        height  = winSize,
    }
    
    groundInfo = Chili.Panel:New{
        padding = {6,6,6,6},
        parent  = screen,
        x       = 0,
        y       = 0,
        width   = 150,
        height  = 101,
    }    
    
    selectionGrid = Chili.Grid:New{
        parent  = infoWindow,
        x       = 0,
        y       = 0,
        height  = '100%',
        width   = '100%',
        rows    = 3,
        columns = 3,
        padding = {0,0,0,0},
        margin  = {0,0,0,0},
    }
    
    unitInfo = Chili.Control:New{
        parent  = infoWindow,
        x       = 0,
        y       = 0,
        height  = '100%',
        width   = '100%',
        padding = {0,0,0,0},
        margin  = {0,0,0,0},
    }
    
    groundText = Chili.TextBox:New{
        parent = groundInfo,
        x      = 0,
        y      = 1,
        right  = 0,
        bottom = 0,
        text   = '',
    }

    groundText2 = Chili.TextBox:New{
        parent = groundInfo,
        x      = 0,
        y      = 60,
        right  = 0,
        bottom = 0,
        text   = '',
        font   = {size=10},
    }
    
    Spring.SetDrawSelectionInfo(false)
    widget:CommandsChanged()
end

----------------------------------
function widget:CommandsChanged()
    curTip = nil
    healthBars = {}
    selectionGrid:ClearChildren()
    unitInfo:ClearChildren()
    getInfo()
    updateNow = true
end

-- Updates health bars or ground info depending on curtip
--   -3 for ground info
--   -2 for so many unitDefIDs that we just give text info (doesn't require updating)
--   -1 for multiple unitDefIDs that fit with pics (<=9)
--   >=0 for a single unit & is the unitID
function widget:Update()
    
    if curTip == nil then return end
    
    if curTip == -3 then
        if infoWindow.visible then infoWindow:Hide() end
    else
        if groundInfo.visible then groundInfo:Hide() end
        if infoWindow.hidden then infoWindow:Show() end
    end
    
    local timer = spGetTimer()
    local updateGround = curTip == -3 and spDiffTimers(timer, groundTimer) > 0.05 
    
    if updateGround then
        updateGroundInfo()
        groundTimer = timer
    end
end

function widget:GameFrame()
    updateUnitInfo()
end

----------------------------------
function widget:ViewResize(_,scrH)
    infoWindow:Resize(scrH*0.2,scrH*0.2)
end
----------------------------------
function widget:Shutdown()
    infoWindow:Dispose()
    Spring.SetDrawSelectionInfo(true)
end


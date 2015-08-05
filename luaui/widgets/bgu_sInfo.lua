-- WIP
function widget:GetInfo()
    return {
        name      = 'Selection info',
        desc      = 'Shows information about the current selection',
        author    = 'Funkencool',
        date      = '2013',
        license   = 'GNU GPL v2',
        layer     = 0,
        enabled   = true,
    }
end

local imageDir = 'luaui/images/buildIcons/'

local Chili, screen, infoWindow, groundInfo, groundText
local unitInfo, unitName, unitIcon, selectionGrid, unitHealthText, unitHealth
local healthBars = {}

local curTip -- general info about 
local focusDefID -- unitDefID of unit we are currently thinking of building

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

local groundTimer = spGetTimer()

local green = '\255\0\255\0'
local red = '\255\255\0\0'
local grey = '\255\150\150\150'
local white = '\255\255\255\255'
local mColour = '\255\153\153\204'
local eColour = '\255\255\255\76'
local blue = "\255\200\200\255"
local darkblue = "\255\100\100\255"
local yellow = "\255\255\255\0"
local lilac = "\255\200\162\200"
local tomato = "\255\255\99\71"

function round(num, idp)
    return string.format("%." .. (idp or 0) .. "f", num) -- lua is such a great language that this is the only reliable way to round
end 

local function getInline(r,g,b)
    if type(r) == 'table' then
        return string.char(255, (r[1]*255), (r[2]*255), (r[3]*255))
    else
        return string.char(255, (r*255), (g*255), (b*255))
    end
end

----------------------------------
-- multi-unitdef info

local function refineSelection(obj)
    Spring.SelectUnitArray(obj.unitIDs)
end

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
    
    infoWindow:Show()
end

----------------------------------
-- single unitdef info

local function ResToolTip(Mmake, Muse, Emake, Euse)
    return white .. "M: " .. green .. '+' .. round(Mmake,1) .. '  ' .. red .. '-' .. round(Muse,1) .. "\n" ..  white .. "E:  " .. green .. '+' .. round(Emake,1) .. '  ' .. red .. "-" .. round(Euse,1)
end

local function showUnitInfo()
    local defID = curTip.selDefID
    local selUnits = curTip.selUnits 
    local n = #selUnits

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
    for _, uID in ipairs(selUnits) do
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

    local numText = ""
    if n>1 then numText = "\n " .. blue .. "(x" .. tostring(n) .. ")" end
    
    unitName = Chili.TextBox:New{
        x      = 5,
        y      = 5,
        right  = 0,
        bottom = 0,
        text   = humanName .. numText,
    }
    
    unitHealthText = Chili.TextBox:New{
        x      = 5,
        bottom = 21,
        text   = math.floor(curHealth) ..' / '.. math.floor(maxHealth),
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
        parent   = unitInfo,
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
    
    
    if UnitDefs[defID].customParams.iscommander then
        unitCostText:Hide()
    end
    if (n==1) or UnitDefs[defID].customParams.iscommander then 
        unitCostTextTitle:Hide() 
    end
    
    infoWindow:Show()        
end

----------------------------------
-- basic unit info

local function showBasicUnitInfo()

    basicUnitInfo = Chili.TextBox:New{
        parent = unitInfo,
        x      = 5,
        y      = 5,
        right  = 0,
        bottom = 0,
        text   = "Units selected: " .. curTip.n .. "\nUnit types: " .. curTip.nType,
    }
    
    infoWindow:Show()
end

----------------------------------
-- focus unit info

local function GetMaxWeaponRange (ud)
    -- get the max range of this units weapons
    local range = -1
    for _,v in pairs(ud.weapons) do
        local wDID = v.weaponDef
        local wd = WeaponDefs[wDID]
        range = math.max(range,wd.range)    
    end
    return floor(range)
end
local function GetMaxWeaponReload (ud)
    -- get the max weapon reload time of this units weapons
    local reload = -1
    for _,v in pairs(ud.weapons) do
        local wDID = v.weaponDef
        local wd = WeaponDefs[wDID]
        reload = math.max(reload,wd.reload)    
    end
    return floor(reload)
end
local function GetMaxDamage (wd)
    -- get the max damage dealt by a single shot of this weapon
    local dmg = -1
    for _,v in pairs(wd.damages) do
        dmg = math.max(dmg,v)
    end
    return dmg
end
local function GetDamageCategory (ud)
    -- classify the DPS of the weapons of this unit
    local damage = 0
    local n = 0
    for _,v in pairs(ud.weapons) do
        n = n + 1
        local wDID = v.weaponDef
        local wd = WeaponDefs[wDID]
        local dmg_per_shot = GetMaxDamage(wd)
        local rate = wd.salvoSize/(wd.reload/30)
        damage = damage + (dmg_per_shot*wd.projectiles*rate)
    end
    damage = damage/n
    return "TODO"
end
local function GetMissileDamageCategory (ud)
    -- classify the damage of a single missile fired by this units first weapon
    return "TODO"
end
local function GetPerShotDamageCategory (ud)
    -- classify the damage of a single missile fired by this units first weapon
    return "TODO"
end
local function GetBombDamageCategory (ud)
    -- classify the damage of a single missile fired by this units first weapon
    return "TODO"
end

local function GetUnitDefKeyProperties (defID)
    local ud = UnitDefs[defID]
    local t = {}
    t[#t+1] = {"Health", green .. tostring(ud.health)}
    
    -- deal with special cases
    if defID==UnitDefNames.commando.id then
        -- commando, gimp, maverick, sniper, behemoth, junos
    end
    
    if ud.isFactory or (ud.isBuilder and ud.speed==0) then
        t[#t+1] = {"Build Power", lilac .. tostring(ud.buildSpeed)}
    elseif ud.isBuilder and ud.canMove then
        t[#t+1] = {"Build Power", lilac .. tostring(ud.buildSpeed)}
        t[#t+1] = {"Max Speed", tomato .. tostring(round(ud.speed))}
    elseif ud.energyMake>=20 and #ud.weapons==0 and ud.speed==0 then
        t[#t+1] = {"Energy Output", eColour .. tostring(ud.energyMake)}
    elseif (ud.radarRadius>200 or ud.sonarRadius>200) and #ud.weapons==0 then
        if ud.radarRadius>200 then t[#t+1] = {"Radar Range", lilac .. tostring(ud.radarRadius)} end
        if ud.sonarRadius>200 then t[#t+1] = {"Sonar Range", lilac .. tostring(ud.sonarRadius)} end
    elseif ud.jammerRadius>0 and #ud.weapons==0 then
        t[#t+1] = {"Jammer Radius", blue .. tostring(ud.jammerRadius)}
        -- note: there are no sonar jammers
    elseif ud.seismicRadius>0 then
        t[#t+1] = {"Coverage Radius", blue .. tostring(ud.seismicRadius)}
    elseif ud.energyStorage>=3000 then
        t[#t+1] = {"Energy Storage", eColour .. tostring(ud.energyStorage)} 
    elseif ud.metalStorage>=1000 then
        t[#t+1] = {"Metal Storage", mColour .. tostring(ud.metalStorage)}
    elseif ud.windGenerator>0 then
        t[#t+1] = {"Wind", blue .. tostring(Game.windMin) .. " - " .. tostring(Game.windMax)}
    elseif ud.tidalGenerator>0 then
        t[#t+1] = {"Tidal", blue .. tostring(Game.tidal)}
    --elseif ud.isExtractor then
        -- do nothing, extraction shows in the tooltip as a result of prospector
        -- if it has a weapon, it'll get picked up later
    elseif #ud.weapons>0 and WeaponDefs[ud.weapons[1].weaponDef].interceptor~=0 then
        -- anti-nukes
        local wd = WeaponDefs[ud.weapons[1].weaponDef]
        t[#t+1] = {"Coverage Radius", blue .. tostring(wd.coverageRange)}
        t[#t+1] = {"Stockpile Time", blue .. tostring(wd.stockpileTime/30) .. "s"}
        if ud.energyMake>=20 then t[#t+1] = {"Energy Output", eColour .. tostring(ud.energyMake)} end -- mobile antis make 200e
    elseif #ud.weapons>0 and WeaponDefs[ud.weapons[1].weaponDef].type=="Shield" then
        local wd = WeaponDefs[ud.weapons[1].weaponDef]
        t[#t+1] = {"Coverage Radius", blue .. tostring(wd.shieldRadius)}  
    elseif (false) then --TODO: crawling bombs
        t[#t+1] = {"Damage", GetBombDamageCategory(ud)} 
    elseif (#ud.weapons>0) and (not ud.canMove) and WeaponDefs[ud.weapons[1].weaponDef].type=="StarburstLauncher" then
        -- static launchers
        local wd = WeaponDefs[ud.weapons[1].weaponDef]
        t[#t+1] = {"Weapon Range", red .. tostring(GetMaxWeaponRange(ud))}
        t[#t+1] = {"AOE", red .. tostring(wd.damageAreaOfEffect)}
        t[#t+1] = {"Stockpile Time", blue .. tostring(wd.stockpileTime/30) .. "s"}
        t[#t+1] = {"Damage", GetMissileDamageCategory(ud)}
    elseif #ud.weapons>0 then
        -- mobile units & static def
        if ud.speed>0 then t[#t+1] = {"Max Speed", tomato .. tostring(round(ud.speed))} end
        t[#t+1] = {"Weapon Range", red .. tostring(GetMaxWeaponRange(ud))}
        if GetMaxWeaponReload(ud)>10 then 
            t[#t+1] = {"Reload Time", red .. tostring(GetMaxWeaponReload(ud)) .. "s"}
            if WeaponDefs[ud.weapons[1].weaponDef].paralyzer then
                t[#t+1] = {"Paralyze Time", blue .. tostring(WeaponDefs[ud.weapons[1].weaponDef].damages.paralyzeDamageTime).. "s"}            
            else            
                t[#t+1] = {"Damage", GetPerShotDamageCategory(ud)}
            end
        else 
            if WeaponDefs[ud.weapons[1].weaponDef].paralyzer then
                t[#t+1] = {"Paralyze Time", blue .. tostring(WeaponDefs[ud.weapons[1].weaponDef].damages.paralyzeDamageTime) .. "s"}            
            else            
                t[#t+1] = {"Damage", GetDamageCategory(ud)}     
            end
        end
    end

    return t
end

local function showFocusInfo()
    local defID = curTip.focusDefID
    local unitDef = UnitDefs[defID]

    local description = UnitDefs[defID].tooltip or ''
    local name        = UnitDefs[defID].name
    local texture     = imageDir..'Units/' .. name .. '.dds'
    local overlay     = imageDir..'Overlays/' .. name .. '.dds'
    local humanName   = UnitDefs[defID].humanName

    local Ecost = UnitDefs[defID].energyCost
    local Mcost = UnitDefs[defID].metalCost 
    local maxHealth = UnitDefs[defID].health

    -- picture
    local overlayColor = {} -- desaturate and aim for 0.3 brightness, else unit properties are hard to read
    overlayColor[4] = 0.75 
    local average = 1/6 * (teamColor[1] + teamColor[2] + teamColor[3] + 0.9) 
    local bias = 0.3
    for i=1,3 do
        overlayColor[i] = (1-bias)*average + bias*teamColor[i]
    end
    focusIcon = Chili.Image:New{
        parent   = unitInfo,
        file     = texture,
        color    = overlayColor,
        y        = 0,
        height   = '100%',
        width    = '100%',
    }
    focusOverlay = Chili.Image:New{
        parent = focusIcon,
        color    = overlayColor,
        height   = '100%',
        width    = '100%',
        file     = overlay,
    }
    
    -- name
    focusName = Chili.TextBox:New{
        parent = focusOverlay,
        x      = 5,
        y      = 5,
        right  = 0,
        bottom = 0,
        text   = humanName .. "\n" .. description,
    }
    
    -- costs + buildtime
    focusCost = Chili.TextBox:New{
        parent = focusOverlay,
        x        = 5,
        bottom   = 20,
        height   = 24,
        text     =  "Cost: " .. mColour .. unitDef.metalCost .. " " .. eColour .. unitDef.energyCost,
    }
    focusBuildTime = Chili.TextBox:New{
        parent = focusOverlay,
        x        = 5,
        bottom   = 5,
        height   = 24,
        text     =  "Build Time: " .. lilac .. unitDef.buildTime, -- this isn't very intuitive
    }
    
    -- key properties
    local keyProperties = GetUnitDefKeyProperties(defID)
    local bottom = 25+16*(#keyProperties)
    for _,v in pairs(keyProperties) do
        local text = tostring(v[1]) .. ": " .. tostring(v[2])
        local property = Chili.TextBox:New{
            parent = focusOverlay,
            x        = 5,
            bottom   = bottom,
            height   = 24,
            text     = text,
        }
        bottom = bottom - 16
    end
        

    
    infoWindow:Show()        
end

----------------------------------
-- ground info

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
  
    if curTip.type == "unitDefID" then     
        -- single unit type
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
        
    elseif curTip.type == "unitDefPics" then 
        -- multiple units, but not so many we cant fit pics
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
end

----------------------------------
-- (re-)setting up 

local function ChooseCurTip()
    curTip = {}

    -- determine if we have any selected units
    local selUnits = spGetSelectedUnits()
    local sortedSelUnits = spGetSelectedUnitsSorted()
    
    curTip.selUnits = selUnits
    curTip.sortedSelUnits = sortedSelUnits
    curTip.n = #selUnits
    curTip.nType = sortedSelUnits['n']

    if focusDefID then
        -- info about a unit we are thinking to build
        curTip.type = "focusDefID"
        curTip.focusDefID = focusDefID         
    elseif #selUnits == 0 then
        --info about point on map corresponding to cursor 
        curTip.type = "ground"
    elseif sortedSelUnits["n"] == 1 then
        -- info about units of a single unitDefID )
        curTip.type = "unitDefID"
        curTip.selDefID = Spring.GetUnitDefID(selUnits[1])  
    elseif sortedSelUnits["n"] <= 6 then 
        -- info about multiple unitDefIDs, but few enough that we can display a small pic for each
        curTip.type = "unitDefPics"
    else
        -- so many units that we just give basic info
        curTip.type = "basicUnitInfo"
    end
        
end

local function ResetTip()
    -- delete/hide the old tip
    curTip = nil
    healthBars = {}
    if infoWindow.visible then infoWindow:Hide() end
    if groundInfo.visible then groundInfo:Hide() end
    selectionGrid:ClearChildren()
    unitInfo:ClearChildren()
    
    -- choose the new tip
    ChooseCurTip()

    if curTip.type=="focusDefID" then
        showFocusInfo()
    elseif curTip.type=="unitDefID" then
        showUnitInfo()
        updateUnitInfo()
    elseif curTip.type=="unitDefPics" then
        for unitDefID, unitIDs in pairs(curTip.sortedSelUnits) do
            if unitDefID ~= 'n' then 
                local name    = UnitDefs[unitDefID].name
                local texture = imageDir..'Units/' .. name .. '.dds'
                local overlay = imageDir..'Overlays/' .. name .. '.dds'
                addUnitGroup(name,texture,overlay,unitIDs, unitDefID)
            end
        end
        addUnitGroupInfo()
        updateUnitInfo()
    elseif curTip.type=="basicUnitInfo" then
        showBasicUnitInfo()    
    elseif curTip.type=="ground" then
        updateGroundInfo()
    end
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
    local r,g,b = Spring.GetTeamColor(Spring.GetMyTeamID())
    teamColor = {r,g,b}

    ResetTip()
end

function widget:Update()
    -- check if focus unit for build command has changed
    local _,cmdID,_ = Spring.GetActiveCommand()
    local newFocusDefID
    if cmdID and cmdID<0 then
        newFocusDefID = -cmdID
    elseif WG.InitialQueue and WG.InitialQueue.selDefID then
        newFocusDefID = WG.InitialQueue.selDefID
    elseif WG.sMenu and WG.sMenu.mouseOverDefID then
        newFocusDefID = WG.sMenu.mouseOverDefID 
    end    
    if newFocusDefID~= focusDefID then
        focusDefID = newFocusDefID
        widget:CommandsChanged()
    end

    -- update ground info, if needed
    local timer = spGetTimer()
    local updateGround = (curTip.type=="ground") and spDiffTimers(timer, groundTimer) > 0.05 
    if updateGround then
        updateGroundInfo()
        groundTimer = timer
    end
end

function widget:GameFrame()
    if curTip.type=="unitDefID" or curTip.type=="unitDefPics" then
        updateUnitInfo()
    end
end

function widget:ViewResize(_,scrH)
    infoWindow:Resize(scrH*0.2,scrH*0.2)
    -- ground info does not resize
end

function widget:Shutdown()
    infoWindow:Dispose()
    groundInfo:Dispose()
    Spring.SetDrawSelectionInfo(true)
end


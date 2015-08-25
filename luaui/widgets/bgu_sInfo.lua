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

local Chili, screen, unitWindow, groundWindow, groundText
local unitWindow, unitName, unitPicture, unitPictureOverlay, unitHealthText, unitHealth, unitCostTextTitle, unitResText
local focusName, focusPicture, focusPictureOverlay, focusCost, focusBuildTime
local unitGrid 
local healthBars = {}

local curTip -- general info about 
local focusDefID -- unitDefID of unit we are currently thinking of building
local preferFocusInfo = false -- when there is just a single unit,do we prefer the focus info (i.e. UnitDefs info) or the unit info?

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
local turqoise = "\255\48\213\200"

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
-- converting losRadius to elmos
local modRules = VFS.Include("gamedata/modrules.lua")
local losResMult = modRules["sensors"]["los"]["losMul" ]
local losMipLevel = modRules["sensors"]["los"]["losMipLevel"]
local losSqSize = Game.squareSize * math.pow(2, losMipLevel)
local losToElmos = losSqSize / losResMult
function losRadiusInElmos(ud)
    return ud.losRadius * losToElmos
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
    
    unitGrid:AddChild(button)
end

local function showUnitGrid()
    for unitDefID, unitIDs in pairs(curTip.sortedSelUnits) do
        if unitDefID ~= 'n' then 
            local name    = UnitDefs[unitDefID].name
            local texture = imageDir..'Units/' .. name .. '.dds'
            local overlay = imageDir..'Overlays/' .. name .. '.dds'
            addUnitGroup(name,texture,overlay,unitIDs, unitDefID)
        end
    end

    unitCostText = Chili.TextBox:New{
        name     = "unitCostText",
        x        = '70%',
        height   = 28,
        bottom   = 10,
        text     = "", 
        fontsize = 12
    }
        
    unitResText = Chili.TextBox:New{
        name     = "unitResText",
        x        = 5,
        bottom   = 10,
        height   = 24,
        text     =  "", 
        fontsize = 12,
    }

    unitGridWindow:AddChild(unitCostText)
    unitGridWindow:AddChild(unitResText)
    unitGridWindow:AddChild(unitGrid)

    unitGridWindow:Show()
end

----------------------------------
-- single unitdef info

local function ResToolTip(Mmake, Muse, Emake, Euse)
    return mColour .. "M: " .. green .. '+' .. round(Mmake,1) .. '  ' .. red .. '-' .. round(Muse,1) .. "\n" ..  eColour .. "E:  " .. green .. '+' .. round(Emake,1) .. '  ' .. red .. "-" .. round(Euse,1)
end

function GetOverlayColor()
    local overlayColor = {} -- desaturate and aim for 0.3 brightness, else unit properties are hard to read
    overlayColor[4] = 0.75 
    local average = 1/6 * (teamColor[1] + teamColor[2] + teamColor[3] + 0.9) 
    local bias = 0.3
    for i=1,3 do
        overlayColor[i] = (1-bias)*average + bias*teamColor[i]
    end
    return overlayColor
end

local function showUnitInfo()
    local defID = curTip.selDefID
    local selUnits = curTip.selUnits 
    local n = #selUnits

    local description = UnitDefs[defID].tooltip or ''
    local name        = UnitDefs[defID].name
    local texture     = imageDir..'Units/' .. name .. '.dds'
    local overlay     = imageDir..'Overlays/' .. name .. '.dds'
    local overlayColor = GetOverlayColor()
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
    
    unitPicture = Chili.Image:New{
        parent   = unitWindow,
        file     = texture,
        color    = overlayColor,
        y        = 0,
        height   = '100%',
        width    = '100%',
    }
    unitPictureOverlay = Chili.Image:New{
        parent = unitPicture,
        color    = overlayColor,
        height   = '100%',
        width    = '100%',
        file     = overlay,
    }
    
    unitName = Chili.TextBox:New{
        parent = unitPictureOverlay,
        x      = 5,
        y      = 5,
        right  = 0,
        bottom = 0,
        text   = humanName .. numText,
    }
    
    unitHealthText = Chili.TextBox:New{
        parent = unitPictureOverlay,
        x      = 5,
        bottom = 21,
        text   = math.floor(curHealth) ..' / '.. math.floor(maxHealth),
    }
    
    unitHealth = Chili.Progressbar:New{
        parent = unitPictureOverlay,
        value   = 0,
        bottom  = 5,
        x       = 5,
        width   = '95%',
        height  = 10,
        color   = {0.5,1,0,1},
    }
    
    unitResText = Chili.TextBox:New{
        parent = unitPictureOverlay,
        x        = 5,
        bottom   = 37,
        height   = 24,
        text     =  ResToolTip(Mmake, Muse, Emake, Euse),
        fontsize = 14,
    }

    unitWindow:Show()        
end

----------------------------------
-- basic unit info

local function showBasicUnitInfo()

    basicUnitInfo = Chili.TextBox:New{
        parent = unitGridWindow,
        x      = 5,
        y      = 5,
        right  = 0,
        bottom = 0,
        text   = "Units selected: " .. curTip.n .. "\nUnit types: " .. curTip.nType,
    }
    
    local mCost = 0
    local eCost = 0
    for uDID,t in pairs(curTip.sortedSelUnits) do
        if uDID~="n" and UnitDefs[uDID].customParams.iscommander~="1" then
            mCost = mCost + (#t)*UnitDefs[uDID].metalCost
            eCost = eCost + (#t)*UnitDefs[uDID].energyCost
        end    
    end

    basicUnitInfo = Chili.TextBox:New{
        parent = unitGridWindow,
        x      = 5,
        y      = 45,
        right  = 0,
        bottom = 0,
        text   = "Total cost: \n" .. mColour .. mCost .. "\n" .. eColour .. eCost,       
    }
    
    unitGridWindow:Show()
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
    return range
end
local function GetMaxWeaponReload (ud)
    -- get the max weapon reload time of this units weapons
    local reload = -1
    for _,v in pairs(ud.weapons) do
        local wDID = v.weaponDef
        local wd = WeaponDefs[wDID]
        reload = math.max(reload,wd.reload)    
    end
    return reload
end
local function GetMaxDamage (wd)
    -- get the max damage dealt by a single shot of this weapon
    local dmg = -1
    for _,v in pairs(wd.damages) do
        dmg = math.max(dmg,v)
    end
    return dmg
end
local function GetDamagePerSec (ud)
    -- classify the DPS of the weapons of this unit
    local damage = 0
    local n = 0
    for _,v in pairs(ud.weapons) do
        n = n + 1
        local wDID = v.weaponDef
        local wd = WeaponDefs[wDID]
        local oDmg = GetMaxDamage(wd)
        local oBurst = wd.salvoSize*wd.projectiles
        local oRld = math.max(1/30,wd.stockpile and wd.stockpileTime or wd.reload)
        damage = damage + oBurst*oDmg/oRld
    end

    return damage
end
local function GetDamagePerShot (ud)
    -- classify the damage of a single missile fired by this units first weapon
    local wDID = ud.weapons[1].weaponDef
    local wd = WeaponDefs[wDID]
    local oBurst = wd.salvoSize*wd.projectiles
    local damage = GetMaxDamage(wd) * oBurst
    return damage
end
local function GetWindString()
    local lower = round(Game.windMin)
    local upper = round(Game.windMax)
    if tonumber(lower)<tonumber(upper) then
        return lower .. " - " .. upper
    end
    return lower
end

local function isKamikaze(ud)
    if #ud.weapons~=2 then return false end
    local wd = WeaponDefs[ud.weapons[1].weaponDef]
    if string.find(wd.name,"mine_dummy") then return true end
    if string.find(wd.name,"crawl_dummy") then return true end
    return false
end
    
local function GetUnitDefKeyProperties (defID)
    local ud = UnitDefs[defID]
    local t = {}
    
    -- deal with mines and crawling bombs
    if isKamikaze(ud) then
        if ud.speed>0 then t[#t+1] = {"Max Speed", tomato .. round(ud.speed)} end
        local bomb_wd = WeaponDefs[ud.weapons[2].weaponDef]
        t[#t+1] = {"Damage", red .. round(GetMaxDamage(bomb_wd))} 
        return t
    end
    
    -- deal with two very special cases
    if defID==UnitDefNames.commando.id then
        t[#t+1] = {"Health", green .. tostring(ud.health)}
        t[#t+1] = {"Build Power", lilac .. round(ud.buildSpeed)}
        t[#t+1] = {"Max Speed", tomato .. round(ud.speed)}
        t[#t+1] = {"Weapon Range", turqoise .. round(GetMaxWeaponRange(ud))}
        t[#t+1] = {"Damage Per Sec", red .. round(GetDamagePerSec(ud))}    
        return t
    elseif ud.customParams.iscommander=="1" then
        t[#t+1] = {"Health", green .. tostring(ud.health)}
        t[#t+1] = {"Build Power", lilac .. round(ud.buildSpeed)}
        t[#t+1] = {"Max Speed", tomato .. round(ud.speed)}
        t[#t+1] = {"Weapon Range", turqoise .. round(GetMaxWeaponRange(ud))}
        return t
    end
    
    -- deal with the rest
    t[#t+1] = {"Health", green .. tostring(ud.health)}
    
    if ud.isFactory or (ud.isBuilder and ud.speed==0) then
        t[#t+1] = {"Build Power", lilac .. round(ud.buildSpeed)}
    elseif ud.isBuilder and ud.canMove then
        t[#t+1] = {"Build Power", lilac .. round(ud.buildSpeed)}
        t[#t+1] = {"Max Speed", tomato .. round(ud.speed)}
    elseif ud.energyMake>=20 and #ud.weapons==0 and ud.speed==0 then
        t[#t+1] = {"Energy Output", eColour .. round(ud.energyMake)}
    elseif (ud.radarRadius>200 or ud.sonarRadius>200) and #ud.weapons==0 then
        if ud.radarRadius>200 then t[#t+1] = {"Radar Range", turqoise .. round(ud.radarRadius)} end
        if ud.sonarRadius>200 then t[#t+1] = {"Sonar Range", turqoise .. round(ud.sonarRadius)} end
        if ud.losRadius>0 then t[#t+1] = {"LOS Range", turqoise .. round(losRadiusInElmos(ud))} end
    elseif ud.jammerRadius>0 and #ud.weapons==0 then
        t[#t+1] = {"Jammer Radius", turqoise .. round(ud.jammerRadius)}
        -- note: there are no sonar jammers
    elseif ud.seismicRadius>0 then
        t[#t+1] = {"Coverage Radius", turqoise .. round(ud.seismicRadius)}
    elseif ud.energyStorage>=3000 then
        t[#t+1] = {"Energy Storage", eColour .. round(ud.energyStorage)} 
    elseif ud.metalStorage>=1000 then
        t[#t+1] = {"Metal Storage", mColour .. round(ud.metalStorage)}
    elseif ud.windGenerator>0 then
        t[#t+1] = {"Energy Output", eColour .. GetWindString()}
    elseif ud.tidalGenerator>0 then
        t[#t+1] = {"Energy Output", eColour .. round(Game.tidal)}
    --elseif ud.isExtractor then
        -- do nothing, extraction shows in the tooltip as a result of prospector
        -- if it has a weapon, it'll get picked up later
    elseif #ud.weapons>0 and WeaponDefs[ud.weapons[1].weaponDef].interceptor~=0 then
        -- anti-nukes
        local wd = WeaponDefs[ud.weapons[1].weaponDef]
        t[#t+1] = {"Coverage Radius", turqoise .. round(wd.coverageRange)}
        t[#t+1] = {"Stockpile Time", blue .. round(wd.stockpileTime/30) .. "s"}
        if ud.energyMake>=20 then t[#t+1] = {"Energy Output", eColour .. round(ud.energyMake)} end -- mobile antis make 200e
    elseif #ud.weapons>0 and WeaponDefs[ud.weapons[1].weaponDef].type=="Shield" then
        local wd = WeaponDefs[ud.weapons[1].weaponDef]
        t[#t+1] = {"Coverage Radius", turqoise .. round(wd.shieldRadius)}  
    elseif (#ud.weapons>0) and (not ud.canMove) and (WeaponDefs[ud.weapons[1].weaponDef].type=="StarburstLauncher" or WeaponDefs[ud.weapons[1].weaponDef].stockpileTime/30>7) then
        -- static launchers
        local wd = WeaponDefs[ud.weapons[1].weaponDef]
        t[#t+1] = {"Weapon Range", turqoise .. round(GetMaxWeaponRange(ud))}
        t[#t+1] = {"AOE", turqoise .. round(wd.damageAreaOfEffect)}
        t[#t+1] = {"Stockpile Time", blue .. round(wd.stockpileTime/30) .. "s"}
        t[#t+1] = {"Damage Per Shot", red .. round(GetDamagePerShot(ud))}
        -- missile costs would be nice but no space
    elseif #ud.weapons>0 then
        -- mobile units & static def
        if ud.speed>0 then t[#t+1] = {"Max Speed", tomato .. round(ud.speed)} end
        if not ud.isBomberAirUnit then t[#t+1] = {"Weapon Range", turqoise .. round(GetMaxWeaponRange(ud))} end
        if GetMaxWeaponReload(ud)>=7 then 
            t[#t+1] = {"Reload Time", blue .. round(GetMaxWeaponReload(ud)) .. "s"}
            if WeaponDefs[ud.weapons[1].weaponDef].paralyzer then
                t[#t+1] = {"Paralyze Time", blue .. round(WeaponDefs[ud.weapons[1].weaponDef].damages.paralyzeDamageTime).. "s"}            
            else            
                t[#t+1] = {"Weapon Damage", red .. round(GetDamagePerShot(ud))}
            end
        else 
            if WeaponDefs[ud.weapons[1].weaponDef].paralyzer then
                t[#t+1] = {"Paralyze Time", blue .. round(WeaponDefs[ud.weapons[1].weaponDef].damages.paralyzeDamageTime) .. "s"}            
            else            
                t[#t+1] = {"Damage Per Sec", red .. round(GetDamagePerSec(ud))}     
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
    local overlayColor = GetOverlayColor()
    local humanName   = UnitDefs[defID].humanName

    local Ecost = UnitDefs[defID].energyCost
    local Mcost = UnitDefs[defID].metalCost 
    local maxHealth = UnitDefs[defID].health

    -- picture
    focusPicture = Chili.Image:New{
        parent   = unitWindow,
        file     = texture,
        color    = overlayColor,
        y        = 0,
        height   = '100%',
        width    = '100%',
    }
    focusPictureOverlay = Chili.Image:New{
        parent = focusPicture,
        color    = overlayColor,
        height   = '100%',
        width    = '100%',
        file     = overlay,
    }
        
    -- name
    focusName = Chili.TextBox:New{
        parent = focusPictureOverlay,
        x      = 5,
        y      = 5,
        right  = 0,
        bottom = 0,
        text   = humanName .. "\n" .. description,
    }
    
    -- costs + buildtime
    if unitDef.customParams.iscommander~="1" then  
        focusCost = Chili.TextBox:New{
            parent = focusPictureOverlay,
            x        = 5,
            bottom   = 20,
            height   = 24,
            text     =  "Cost: " .. mColour .. unitDef.metalCost .. " " .. eColour .. unitDef.energyCost,
        }
        focusBuildTime = Chili.TextBox:New{
            parent = focusPictureOverlay,
            x        = 5,
            bottom   = 5,
            height   = 24,
            text     =  "Build Time: " .. lilac .. unitDef.buildTime, -- this isn't very intuitive
        }
    end
    
    -- key properties
    local keyProperties = GetUnitDefKeyProperties(defID)
    local bottom = 25+16*(#keyProperties)
    for _,v in pairs(keyProperties) do
        local text = tostring(v[1]) .. ": " .. tostring(v[2])
        local property = Chili.TextBox:New{
            parent = focusPictureOverlay,
            x        = 5,
            bottom   = bottom,
            height   = 24,
            text     = text,
        }
        bottom = bottom - 16
    end
        

    
    unitWindow:Show()        
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
        if groundWindow.hidden then groundWindow:Show() end
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
    elseif groundWindow.visible then
        groundWindow:Hide()
    end
end

----------------------------------
local function updateUnitInfo()
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
end

local function updateUnitGrid()
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
    
    unitGridWindow:GetChildByName('unitResText'):SetText(ResToolTip(Mmake, Muse, Emake, Euse))
    if Mcost>0 then
        unitGridWindow:GetChildByName('unitCostText'):SetText(mColour .. Mcost .. '\n' .. eColour .. Ecost)
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
    elseif sortedSelUnits["n"] == 1 and preferFocus then
        curTip.type = "focusDefID"
        curTip.focusDefID = Spring.GetUnitDefID(selUnits[1])  
    elseif sortedSelUnits["n"] == 1 then
        -- info about units of a single unitDefID )
        curTip.type = "unitDefID"
        curTip.selDefID = Spring.GetUnitDefID(selUnits[1])  
    elseif sortedSelUnits["n"] <= 6 and sortedSelUnits["n"] > 1 then 
        -- info about multiple unitDefIDs, but few enough that we can display a small pic for each
        curTip.type = "unitDefPics"
    elseif sortedSelUnits["n"] > 6 then
        -- so many units that we just give basic info
        curTip.type = "basicUnitInfo"
    else
        --info about point on map corresponding to cursor 
        curTip.type = "ground"
    end
    
end

local function ResetTip()
    -- delete/hide the old tip
    curTip = nil
    healthBars = {}
    if unitWindow.visible then unitWindow:Hide() end
    if groundWindow.visible then groundWindow:Hide() end
    if unitGridWindow.visible then unitGridWindow:Hide() end
    unitWindow:ClearChildren()
    unitGridWindow:ClearChildren()
    unitGrid:ClearChildren()
    
    -- choose the new tip
    ChooseCurTip()

    if curTip.type=="focusDefID" then
        showFocusInfo()
    elseif curTip.type=="unitDefID" then
        showUnitInfo()
        updateUnitInfo()
    elseif curTip.type=="unitDefPics" then
        showUnitGrid()
        updateUnitGrid()
    elseif curTip.type=="basicUnitInfo" then
        showBasicUnitInfo()    
    elseif curTip.type=="ground" then
        updateGroundInfo()
    end
end

local function TogglePreferredUnitInfo()
    if unitWindow.visible then
        preferFocus = not preferFocus
        ResetTip()
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
    
    unitWindow = Chili.Button:New{ -- parent for all the single unit info stuffs (including focus)
        parent  = screen,
        padding = {6,6,6,6},
        borderColor = {1,1,1,1},
        caption = "",
        x       = 0,
        y       = 0,
        width   = winSize * 1.05,
        height  = winSize,
        OnClick = {TogglePreferredUnitInfo},
    }
    
    unitGridWindow = Chili.Window:New{ -- parent for unit grid display, children are regenerated on each change
        parent  = screen,
        padding = {6,6,6,6},
        borderColor = {1,1,1,1},
        caption = "",
        parent  = screen,
        x       = 0,
        y       = 0,
        width   = winSize * 1.05,
        height  = winSize,
        OnClick = {TogglePreferredUnitInfo},
    }
    unitGrid = Chili.Grid:New{ 
        x       = 0,
        y       = 0,
        height  = '100%',
        width   = '100%',
        rows    = 3,
        columns = 3,
        padding = {0,0,0,0},
        margin  = {0,0,0,0},
    }    
    
    groundWindow = Chili.Panel:New{ -- parent for ground info, children are permanent
        parent  = screen,
        padding = {6,6,6,6},
        x       = 0,
        y       = 0,
        width   = 150,
        height  = 101,
    }    
    groundText = Chili.TextBox:New{
        parent = groundWindow,
        x      = 0,
        y      = 1,
        right  = 0,
        bottom = 0,
        text   = '',
    }
    groundText2 = Chili.TextBox:New{
        parent = groundWindow,
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
    if curTip.type=="unitDefID" then
        updateUnitInfo()    
    elseif curTip.type=="unitDefPics" then
        updateUnitGrid()
    end
end

function widget:ViewResize(_,scrH)
    unitWindow:Resize(scrH*0.2,scrH*0.2)
    unitGridWindow:Resize(scrH*0.2,scrH*0.2)
    -- ground info does not resize
end

function widget:Shutdown()
    unitWindow:Dispose()
    groundWindow:Dispose()
    Spring.SetDrawSelectionInfo(true)
end



function widget:GetInfo()
    return {
        name = "Hotkeys",
        desc = "Sets up many hotkeys" ,
        author = "Bluestone", --incorporates Context Build widget by BD and Dizekat
        date = "30 July 2009",
        license = "GNU LGPL, v2.1 or later",
        layer = -500,
        enabled = true
    }
end

---------------------------------------
-- general keybinds

local binds = {
    -- buildspacing
    "bind Any+h buildspacing inc",
    "bind Any+n buildspacing dec",
    
    -- numpad movement
    "bind numpad2 moveback",
    "bind numpad6 moveright",
    "bind numpad4 moveleft",
    "bind numpad8 moveforward",
    "bind numpad9 moveup",
    "bind numpad3 movedown",
    "bind numpad1 movefast",
    
    -- chat/fullscreen keys
    "bind Alt+backspace  fullscreen",
    "bind Alt+enter  chatally",
    "bind Alt+enter  chatswitchally",
    "bind Ctrl+enter  chatall",
    "bind Ctrl+enter  chatswitchall",
    "bind Shift+enter  chatspec",
    "bind Shift+enter  chatswitchspec",
    
    -- settarget
    -- "bind y settarget", -- see SetYZState()
    "bind j canceltarget",
    
    -- drawing
    "bind q drawinmap", --some keyboards don't have ` or \

    -- buildfacing
    "bind ,    buildfacing inc", --because some keyboards don't have [ and ] keys
    "bind .    buildfacing dec",
    "bind o buildfacing inc", --apparently some keyboards don't have , and . either...
}
    
local unbinds={
    -- unwanted default bindings
    "bind any+c controlunit",
    "bind c controlunit",
    "bind Any+x  buildspacing dec",
    "bind x  buildspacing dec",
    "bindaction buildspacing dec",
    "bind any+z buildspacing inc",
    "bind z buildspacing inc",
    "bindaction buildspacing inc",
    "bind , prevmenu",
    "bind . nextmenu",
    "bind Alt+enter fullscreen",
    "bind backspace mousestate",
}

function SetBinds()
    for k,v in ipairs(unbinds) do
        Spring.SendCommands("un"..v)
    end
    for k,v in ipairs(binds) do
        Spring.SendCommands(v)
    end
    SetYZState()
end

function SetUnBinds()
    for k,v in ipairs(binds) do
        Spring.SendCommands("un"..v)
    end
    for k,v in ipairs(unbinds) do
        Spring.SendCommands(v)
    end
    Spring.SendCommands("unbind y settarget")
    Spring.SendCommands("unbind z settarget")
end

function SetYZState()
    Spring.SendCommands("unbind y settarget")
    Spring.SendCommands("unbind z settarget")
    if WG.swapYZbinds then
        Spring.SendCommands("bind z settarget")
        Z_KEY = KEYSYMS.Y
    else
        Spring.SendCommands("bind y settarget")
        Z_KEY = KEYSYMS.Z    
    end
end


---------------------------------------
-- z,x,c,v,b hotkeys and water/land based context build

local waterLandPairsHuman = {
-- human friendly, bidirectional 
{'armmex','armuwmex'},
{'cormex','coruwmex'},
{'armmakr','armfmkr'},
{'cormakr','corfmkr'},
{'armdrag','armfdrag'},  
{'cordrag','corfdrag'},  
{'armmstor','armuwms'},
{'armestor','armuwes'},
{'cormstor','coruwms'},
{'corestor','coruwes'},
{'armrl','armfrt'},
{'corrl','corfrt'},
{'armhp','armfhp'},
{'corhp','corfhp'},
{'armrad','armfrad'},
{'corrad','corfrad'},
{'armhlt','armfhlt'},
{'corhlt','corfhlt'},
{'armtarg','armfatf'},
{'cortarg','corfatf'},
{'armmmkr','armfmmm'},
{'cormmkr','corfmmm'},
{'armfus','armuwfus'},
{'corfus','coruwfus'},
{'armflak','armfflak'},
{'corflak','corenaa'},
{'armmoho','armuwmme'},
{'cormoho','coruwmme'},
{'armsolar','armtide'},
{'corsolar','cortide'},
{'armlab','armsy'},
{'corlab','corsy'},
{'armllt','armtl'},
{'corllt','cortl'},
{'armaap','armplat'},
{'coraap','corplat'},
}

include('keysym.h.lua')
local Z_KEY = KEYSYMS.Z
local X_KEY = KEYSYMS.X
local C_KEY = KEYSYMS.C
local V_KEY = KEYSYMS.V
local B_KEY = KEYSYMS.B

local updateRate = 1/2 -- in seconds, time interval that must elapse in between each change of context
local timeCounter = -updateRate
local lastUpdate = timeCounter

local waterLandPairs = {}

local hotkeys = {} -- all z,x,c,v,b hotkeys, hotkey[uDID]=key
local waterHotkeys = {} -- only the water ones
local landHotkeys = {} -- only the land ones
local contextHotkeys = {} -- equal to waterHotkeys or landHotkeys, according to context
local prevInWater


function Cost(uDID)
    return 60*UnitDefs[uDID].metalCost + UnitDefs[uDID].energyCost
end

function MustBeBuiltInWater(uDID)
    -- must be built in water (we only care about immobile units)
    return UnitDefs[uDID].maxWaterDepth>0
end

function ConstructUnitOrder(Score)
    -- construct a table of uDIDs with non-nil score, in increasing order of score
    local t = {}
    for uDID,uDef in pairs(UnitDefs) do
        local score = Score(uDID)
        if score then
            t[#t+1] = {uDID=uDID,score=score}
        end
    end
    local function Comparator (i,j)
        return (i.score<j.score)
    end
    table.sort(t,Comparator)
    local t2 = {}
    for k,v in ipairs(t) do
        t2[k] = v.uDID
    end
    return t2
end

function PrintArrayTable(t)
    for k,v in ipairs(t) do
        Spring.Echo(k,v, UnitDefs[v].name)
    end
end

function BuildsInWater(uDID)
    return (UnitDefs[uDID].minWaterDepth > 0)
end

function CheckContextBuildOrder(uDID, inWater)
    -- check if the water depth at this location is suitable for building this unitDefID
    -- don't check anything else, or we deprive the user of useful info
    return (inWater == BuildsInWater(uDID))
end

function CheckContextBuild(uDID, inWater)
    -- check if uDID is buildable in current context, return uDID if it is, else return its pairedID if that is, otherwise return nil   
    if CheckContextBuildOrder(uDID, inWater) then
        return uDID
    end
    local pairedID = waterLandPairs[uDID]
    if pairedID and CheckContextBuildOrder(pairedID, inWater) then
        --Spring.Echo("paired", uDID, pairedID)
        return pairedID
    end
    return nil
end

function SetActiveBuildUnit(uDID)
    Spring.SetActiveCommand('buildunit_'..UnitDefs[uDID].name)
    if WG.InitialQueue and WG.sMenu then -- if the game hasn't started, we can't set buildunit_ as the active command, so we tell sMenu directly
        WG.sMenu.ForceSelect(uDID)
    end
end


function widget:Initialize()
    SetBinds()
    SetYZState()
    WG.SetYZState = SetYZState
    
    -- setup pairs
    for _,v in pairs(waterLandPairsHuman) do
        local uDID1 = UnitDefNames[v[1]].id
        local uDID2 = UnitDefNames[v[2]].id
        if waterLandPairs[uDID1] or waterLandPairs[uDID2] then
            Spring.Echo("WARNING: found duplicate water-land pairing for (" .. v[1] .. "," .. v[2] .. ")")
        end
        waterLandPairs[uDID1] = uDID2
        waterLandPairs[uDID2] = uDID1
    end
    
    -- setup Z (metal extractors)
    local function Z_Score (uDID)
        if not UnitDefs[uDID].isExtractor then return end
        return Cost(uDID)
    end
    Z_units = ConstructUnitOrder(Z_Score)
    --Spring.Echo("Z TABLE")
    --PrintArrayTable(Z_units)
        
    -- setup X (energy producers)
    local function X_Score (uDID)
        if not UnitDefs[uDID].isBuilding then return end
        if UnitDefs[uDID].isBuilder then return end
        if UnitDefs[uDID].energyMake<20 and (UnitDefs[uDID].tidalGenerator==0) and (UnitDefs[uDID].windGenerator==0) then return end
        return Cost(uDID)
    end
    X_units = ConstructUnitOrder(X_Score)
    --Spring.Echo("X TABLE")
    --PrintArrayTable(X_units)
    
    -- setup C (static defence and radar/sonar)
    local function C_Score (uDID)
        if not UnitDefs[uDID].isBuilding then return end
        if UnitDefs[uDID].isFactory then return end
        if UnitDefs[uDID].isExtractor then return end
        if UnitDefs[uDID].energyMake>=20 then return end
        if #UnitDefs[uDID].weapons>0 and WeaponDefs[UnitDefs[uDID].weapons[1].weaponDef].type=="StarburstLauncher" then return end
        if #UnitDefs[uDID].weapons==0 and UnitDefs[uDID].radarRadius<200 and UnitDefs[uDID].sonarRadius<200 then return end        
        local weapons = UnitDefs[uDID].weapons
        local nonAAweapon = #UnitDefs[uDID].weapons==0 and true or false
        for _,weapon in pairs(weapons) do
            local onlyTargets = weapon.onlyTargets
            if onlyTargets['vtol']==nil or onlyTargets['vtol']==false then 
                nonAAweapon = true
                break
            end        
        end
        if not nonAAweapon then return end
        return Cost(uDID)    
    end
    C_units = ConstructUnitOrder(C_Score)
    --Spring.Echo("C TABLE")
    --PrintArrayTable(C_units)
    
    -- setup V (nanos & labs)
    local function V_Score (uDID)
        if UnitDefs[uDID].name=="cornanotc" or UnitDefs[uDID].name=="cornanotc" then return Cost(uDID) end
        if not UnitDefs[uDID].isFactory then return end
        if not UnitDefs[uDID].buildOptions or #UnitDefs[uDID].buildOptions==0 then return end
        return Cost(uDID)    
    end
    V_units = ConstructUnitOrder(V_Score)
    --Spring.Echo("V TABLE")
    --PrintArrayTable(V_units)  
    
    -- setup B (anti-air)
    local function B_Score (uDID)
        if not UnitDefs[uDID].isBuilding then return end
        if UnitDefs[uDID].isFactory then return end
        if UnitDefs[uDID].isExtractor then return end
        if UnitDefs[uDID].energyMake>=20 then return end
        if #UnitDefs[uDID].weapons>0 and WeaponDefs[UnitDefs[uDID].weapons[1].weaponDef].type=="StarburstLauncher" then return end
        if #UnitDefs[uDID].weapons==0 then return end  
        local weapons = UnitDefs[uDID].weapons
        for _,weapon in pairs(weapons) do
            local onlyTargets = weapon.onlyTargets
            if onlyTargets['vtol']==nil or onlyTargets['vtol']==false then return end        
        end
        return Cost(uDID)    
    end
    B_units = ConstructUnitOrder(B_Score)
    --Spring.Echo("B TABLE")
    --PrintArrayTable(B_units)  
    
    -- put all these unitDefIDs together into one table
    local hotkeys = {}
    for _,v in ipairs(Z_units) do hotkeys[v] = "Z" end
    for _,v in ipairs(X_units) do hotkeys[v] = "X" end
    for _,v in ipairs(C_units) do hotkeys[v] = "C" end
    for _,v in ipairs(V_units) do hotkeys[v] = "V" end
    for _,v in ipairs(B_units) do hotkeys[v] = "B" end
    
    -- construct waterHotkeys and landHotkeys
    -- out of context keys get the empty string, which makes life easier for sMenu when it has to update
    for uDID,key in pairs(hotkeys) do
        waterHotkeys[uDID] = BuildsInWater(uDID) and key or ''
        landHotkeys[uDID] = BuildsInWater(uDID) and '' or key
    end
    
    WG.buildingHotkeys = {}
end

function AdvanceToNextBuildable(t, cmdID)
    local pos = 0 -- current pos in table, or 0
    if cmdID and cmdID < 0 then
        local uDID = -cmdID
        for k,v in ipairs(t) do
            if v==uDID then
                pos = k
                break
            end        
        end
    end
    
    -- make a list of all the units our current selection can build
    local canBuild = {}
    local units = Spring.GetSelectedUnits()
    for _,unitID in ipairs(units) do
        local cmdList = Spring.GetUnitCmdDescs(unitID)
        for i = 1, #cmdList do
            local cmd = cmdList[i]
            if UnitDefNames[cmd.name] then
                local uDID = UnitDefNames[cmd.name].id
                canBuild[uDID] = true
            end
        end
    end        
    if WG.InitialQueue and WG.startUnit then
        local buildOptions = UnitDefs[WG.startUnit].buildOptions
        for _,uDID        in ipairs(buildOptions) do
            canBuild[uDID] = true
        end
    end
    
    -- find the next unitDefID in the (circular) array that we can build, skipping over any units that cannot be built in current context, and set is as the active build command
    local i = (pos>0) and pos+1 or 1
    if i>#t then i=1 end
    while (i~=pos) do
        if pos==0 then pos=1 end
        local uDID = t[i]
        if canBuild[uDID] and contextHotkeys[uDID] and contextHotkeys[uDID]~='' then -- we can build it, and it has a hotkey in the current context
            SetActiveBuildUnit(uDID)
            return true
        end
        i = i + 1
        if i>#t then i=1 end    
    end
end

function widget:KeyPress(key, mods, isRepeat)
    if mods.meta or (mods.ctrl and not mods.shift) then return end

    -- if we are queueing build commands, and ZXCV is pressed, move onto the next unitDefID that at least one of our selected units can build
    local _,cmdID,_ = Spring.GetActiveCommand()
    if WG.InitialQueue and WG.InitialQueue.selDefID then
        cmdID = -WG.InitialQueue.selDefID
    end
    
    local advanced = false
    if key==Z_KEY then
        advanced = AdvanceToNextBuildable(Z_units, cmdID)
    elseif key==X_KEY then
        advanced = AdvanceToNextBuildable(X_units, cmdID)
    elseif key==C_KEY then
        advanced = AdvanceToNextBuildable(C_units, cmdID)
    elseif key==V_KEY then
        advanced = AdvanceToNextBuildable(V_units, cmdID)
    elseif key==B_KEY then
        advanced = AdvanceToNextBuildable(B_units, cmdID)
    end    
    return advanced
end

function widget:Update(dt)
    -- swap water-land pairs due to context, if it helps
    -- also, keep WG.buildingHotkeys updated for the current context
    timeCounter = timeCounter + dt

    -- get the cursor pos on map
    local mx, my = Spring.GetMouseState()
    local _, coords = Spring.TraceScreenRay(mx, my, true, true, false, true)
    if not coords then return uDID end
    local x,y,z = coords[1],coords[2],coords[3]
    if x<0 or x>Game.mapSizeX or z<0 or z>Game.mapSizeZ then return uDID end
    
    -- set the context i.e. is the mouse in the water or not
    local inWater = (y<0)
    if (inWater==prevInWater) or (timeCounter<lastUpdate+updateRate) then return end -- we only change context based on water, so no need to do anything here
    prevInWater = inWater
    lastUpdate = timeCounter
    
    -- set which units have hotkeys in the current context 
    -- expose these to WG & make sMenu update accordingly   
    contextHotkeys = inWater and waterHotkeys or landHotkeys
    WG.buildingHotkeys = contextHotkeys 
    if WG.sMenu then
        WG.sMenu.ForceUpdateHotkeys()
    end
    
    -- get the active build order, if there is one
    local _,cmdID,_ = Spring.GetActiveCommand()
    if WG.InitialQueue and WG.InitialQueue.selDefID then
        cmdID = -WG.InitialQueue.selDefID
    end
    if (not cmdID) or (cmdID>=0) then
        return
    end
    
    -- check if we want to change the active build order based on context 
    local unitDefID = -cmdID
    local pairedID = CheckContextBuild(unitDefID, inWater)
    if pairedID and unitDefID ~= pairedID then
        SetActiveBuildUnit(pairedID)
    end
end

function widget:Shutdown()
    WG.SetYZState = nil
    SetUnBinds()
end

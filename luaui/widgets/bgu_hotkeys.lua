
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
}

local binds = {
    -- buildspacing
    "bind any+b buildspacing inc",
    "bind any+n buildspacing dec",
    
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

include('keysym.h.lua')
local Z_KEY = KEYSYMS.Z
local X_KEY = KEYSYMS.X
local C_KEY = KEYSYMS.C
local V_KEY = KEYSYMS.V

local updateRate = 1/3 -- in seconds
local timeCounter = 0

local waterLandPairs = {}

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

function Cost(uDID)
    return 60*UnitDefs[uDID].metalCost + UnitDefs[uDID].energyCost
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
        if canBuild[t[i]] and CheckContextBuild(t[i])==t[i] then
            SetActiveBuildUnit(t[i])
            return true
        end
        i = i + 1
        if i>#t then i=1 end    
    end
end

function CheckContextBuild(uDID)
    -- check if we can build uDID in current context, return uDID if it is, return its pairedID if that is, return nil otherwise
    local mx, my = Spring.GetMouseState()
    local _, coords = Spring.TraceScreenRay(mx, my, true, true)
    if (not coords) then
        return uDID
    end
    if coords[1]<0 or coords[1]>Game.mapSizeX or coords[3]<0 or coords[3]>Game.mapSizeZ then
        return uDID
    end

    if Spring.TestBuildOrder(uDID, coords[1], coords[2], coords[3], 1) == 0 then
        if waterLandPairs[uDID] then 
            local pairedID = waterLandPairs[uDID]
            if Spring.TestBuildOrder(pairedID, coords[1], coords[2], coords[3], 1) ~= 0 then
                --Spring.Echo("paired", uDID, pairedID)
                return pairedID
            end
        end
        return nil
    end
    return uDID
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
    
    -- setup C (defences)
    local function C_Score (uDID)
        if not UnitDefs[uDID].isBuilding then return end
        if UnitDefs[uDID].isFactory then return end
        if UnitDefs[uDID].isExtractor then return end
        if UnitDefs[uDID].energyMake>=20 then return end
        if #UnitDefs[uDID].weapons>0 and WeaponDefs[UnitDefs[uDID].weapons[1].weaponDef].type=="StarburstLauncher" then return end
        if #UnitDefs[uDID].weapons==0 and UnitDefs[uDID].radarRadius<200 and UnitDefs[uDID].sonarRadius<200 then return end        
        return Cost(uDID)    
    end
    C_units = ConstructUnitOrder(C_Score)
    --Spring.Echo("C TABLE")
    --PrintArrayTable(C_units)
    
    -- setup V (labs)
    local function V_Score (uDID)
        if not UnitDefs[uDID].isFactory then return end
        if not UnitDefs[uDID].buildOptions or #UnitDefs[uDID].buildOptions==0 then return end
        return Cost(uDID)    
    end
    V_units = ConstructUnitOrder(V_Score)
    --Spring.Echo("V TABLE")
    --PrintArrayTable(V_units)  
    
    --expose inverse of _key tables to WG (they should be disjoint)
    local hotkeys = {}
    for _,v in pairs(Z_units) do
        hotkeys[v] = "Z"
    end
    for _,v in pairs(X_units) do
        hotkeys[v] = "X"
    end
    for _,v in pairs(C_units) do
        hotkeys[v] = "C"
    end
    for _,v in pairs(V_units) do
        hotkeys[v] = "V"
    end
    WG.buildingHotkeys = hotkeys
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
    end    
    return advanced
end

function widget:Update(deltaTime)
    -- swap water-land pairs due to context, if it helps
    timeCounter = timeCounter + deltaTime
    if timeCounter >= updateRate then -- update only x times per second
        timeCounter = 0
    else
        return
    end

    local _,cmdID,_ = Spring.GetActiveCommand()
    if WG.InitialQueue and WG.InitialQueue.selDefID then
        cmdID = -WG.InitialQueue.selDefID
    end
    if (not cmdID) or (cmdID>=0) then
        return
    end
    
    local unitDefID = -cmdID
    local pairedID = CheckContextBuild(unitDefID)
    if pairedID and unitDefID ~= pairedID then
        SetActiveBuildUnit(pairedID)
    end
end

function widget:Shutdown()
    WG.SetYZState = nil
    SetUnBinds()
end

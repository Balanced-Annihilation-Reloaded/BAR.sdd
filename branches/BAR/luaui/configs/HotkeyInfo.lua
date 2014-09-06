-- it has to be like this to make the colours and line breaks get parsed correctly+.

local white = "\255\255\255\255"
local green = "\255\0\255\0"
local blue = "\255\150\150\255"

local General = {
    {"Chat", title=true},
    {"enter",               "Send chat message"},
    {"alt (x2)",            "Send chat message to allies"},
    {"shift (x2)",          "Send chat message to spectators"},
    {blankLine=true},    
    {"Menus", title=true},
    {"i",                   "Main menu"},
    {"shift + esc",         "Quit menu"},
    {"f11",                 "Widget list"},
    {blankLine=true},
    {"Camera movement", title=true},
    {"scrollwheel",                 "Zoom camera"},
    {"arrow keys / mouse at screen edge", "Move camera"},
    {"ctrl + scrollwheel",          "Change camera angle"},
    {"middle click (+ drag)",       "Drag camera"},
    {blankLine=true},
    {"Camera modes", title=true},
    {"ctrl + f1,2,3,4,5",           "Change camera type"},
    {"tab",                         "Toggle overview camera"},
    {"l",   "Toggle LOS view"},
    {"f1",  "Show height map"},
    {"f2",  "Show passability (for selected unit)"},
    {"f3",  "Cycle through recently placed markers"},
    {"f4",  "Show metal map"},
    {"f5",  "Hide GUI"},
    {blankLine=true},
    {"Drawing", title=true},
    {"` + dbl click",       "Place marker on map"},
    {"` + drag left mouse", "Draw on map"},
    {"` + draw right mouse","Erase drawings and markers"},
    {blankLine=true},
    {"Other", title=true},
    {"alt -/+",             "Change replay speed"},
    {"f6",                  "Toggle mute"},

}

local Units_I = {

    {"Selecting units", title=true},           
    {"left mouse (+ drag)",      "Select or deselect units"},
    {blankLine=true},    
    {"Selecting orders", title=true},
    {white .. "The " .. green .. "default order" .. white .. " is move", noFormat=true},
    {"m",   "move"},
    {"a",   "attack"},
    {"y",   "set priority target"},
    {"r",   "repair"},
    {"e",   "reclaim"},
    {"o",   "resurrect"},
    {"f",   "fight"},
    {"p",   "patrol"},
    {"k",   "cloak"},
    {blankLine=true},    
    {"s",   "stop (clears order queue)"},
    {"w",   "wait (pause current command)"},
    {"j",   "cancel priority target"},
    {blankLine=true},    
    {"d",   "manual fire (dgun)"},
    {"ctrl + d", "self-destruct"},
}

local Units_II ={

    {"Giving move orders", title=true},           
    {"right mouse (single click or drag)",   "Give move order to unit(s)"},
    {blankLine=true},    
    {"Giving all other orders", title=true},
    {"left mouse (single click)",    "Give order to unit(s)"},
    {"right mouse (single click)",   "Revert to default order"},
    {"right mouse + drag",           "Give formation order to unit(s)"},
    {blankLine=true},    
    {"Queueing orders", title=true},
    {"shift + (some order)",         "Add order to end of order queue"},
    {"space + (some order)",         "Add order to start of order queue"},
}


local Units_III = {

    {"Selecting build orders", title=true},
    {"(none)",    "Select from units build-menu"},
    {"z",         "Cycle through mexes"},
    {"x",         "Cycle through energy production"},
    {"c",         "Cycle through radar/defence/etc"},
    {"v",         "Cycle through factories"},
    {"[ and ]",   "Change facing of buildings"},
    {blankLine=true},    
    {"Giving build orders", title=true},
    {"left mouse",   "Give build order"},
    {"right mouse",  "De-select build order"},
    {"shift + (build order)", "Build in a line"},
    {"shift + alt + (build order)", "Build in a square"},
    {"b",           "Increase build spacing"},
    {"n",           "Decrease build spacing"},
    {blankLine=true},    
    {"Group selection", title=true},
    {"ctrl + a",                "Select all units"},
    {"ctrl + b",                "Select all constructors"},
    {"ctrl + (num)",            "Add units to group (num=1,2,..)"},
    {"(num)",                   "Select all units assigned to group (num)"},
    {"ctrl + z",                "Select all units of same type as current"},
    {"double left click",       "Select all units of targeted type within current view"},
    
}

    

local function FormatTable(a)
    local text = ""
    for _,t in ipairs(a) do
        if t.blankLine then
            text = text .. '\n'
        elseif t.title then
            text = text .. blue .. t[1] .. '\n'
        elseif t.noFormat then
            text = text .. t[1] .. '\n'
        else
            text = text .. green .. t[1] .. ": " .. white .. t[2] .. '\n'
        end
    end
    return text
end

local text = {}
text['General'] = FormatTable(General)
text['Units I'] = FormatTable(Units_I)
text['Units II'] = FormatTable(Units_II)
text['Units III'] = FormatTable(Units_III)

return text 

-- it has to be like this to make the colours and line breaks get parsed correctly+.

local white = "\255\255\255\255"
local green = "\255\0\255\0"
local blue = "\255\150\150\255"

local General = {
    {"Chat", title=true},
    {"enter",               "Send chat message"},
    {"alt + enter",            "Send chat message to allies"},
    {"shift + enter",          "Send chat message to spectators"},
    {"ctrl + enter",           "Send chat message to all"},
    {blankLine=true},      
    {"Menus", title=true},
    {"esc (or i)",          "Main menu"},
    {"f10",                 "Graphics"},
    {"f11",                 "Interface"},
    {"i",                   "Show introduction"},
    {blankLine=true},
    {"Camera movement", title=true},
    {"scrollwheel",                 "Zoom camera"},
    {"arrow keys / mouse at screen edge", "Move camera"},
    {"ctrl + scrollwheel",          "Change camera angle"},
    {"middle click (+ drag)",       "Drag camera"},
    {blankLine=true},
    {"Camera modes", title=true},
    {"alt + backspace", "Toggle fulscreen"},
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
    {"q + dbl click",       "Place marker on map"},
    {"q + drag left mouse", "Draw on map"},
    {"q + draw right mouse","Erase drawings and markers"},
    {"delete",              "Erase all drawings and markers"},
    {blankLine=true},
    {"Other", title=true},
    {"alt -/+",             "Change replay speed"},
    {"f6",                  "Toggle mute"},

}

local Units_I = {

    {"Unit information", title=true},           
    {"mouse over",               "Show unit information"},
    {"right mouse (on unit)",    "Toggle unit info between health & stats"},
    {blankLine=true},
    {"Selecting units", title=true},           
    {"left mouse (+ drag)",      "Select or deselect units"},
    {blankLine=true},    
    {"Group selection", title=true},
    {"ctrl + a",                "Select all units"},
    {"ctrl + b",                "Select all constructors"},
    {"ctrl + c",                "Select commander"},
    {"ctrl + (num)",            "Add units to group (num=1,2,..)"},
    {"(num)",                   "Select all units assigned to group (num)"},
    {"ctrl + z",                "Select all units of same type as current"},
    {"double left click",       "Select all units of targeted type within current view"},
}


local Units_II ={
    {"Giving default orders", title=true},           
    {"right mouse (single click)",   "Give order to selected unit(s)"},
    {"right mouse (drag)",           "Give formation order to selected unit(s)"},
    {blankLine=true},    
    {"Queueing orders", title=true},
    {"shift + (some order)",         "Add order to end of queue"},
    {"space + (some order)",         "Add order to start of queue"},
    {blankLine=true},    
    {"Selecting specific orders", title=true},
    {"left mouse",  "Select from units order-menu"},
    {"m",   "move"},
    {"a",   "attack"},
    {"y",   "set priority target"},
    {"r",   "repair"},
    {"g",   "guard"},
    {"e",   "reclaim"},
    {"o",   "resurrect"},
    {"f",   "fight"},
    {"p",   "patrol"},
    {"k",   "cloak"},
    {blankLine=true},    
    {"s",   "stop (clears order queue)"},
    {"w",   "wait (pause/unpause current command)"},
    {"j",   "cancel priority target"},
    {blankLine=true},    
    {"d",   "manual fire (dgun)"},
    {"ctrl + d", "self-destruct"},
    {blankLine=true},    
    {"Giving specific orders", title=true},
    {"left mouse (single click)",    "Give order to selected unit(s)"},
    {"right mouse (drag)",           "Give formation order to selected unit(s)"},
    {blankLine=true},    
    {"right mouse (single click)",   "De-select specific order"},
}


local Units_III = {

    {"Selecting build orders", title=true},
    {"left mouse",    "Select from units build-menu"},
    {"z",   "cycle through mexes"},
    {"x",   "cycle through energy production"},
    {"c",   "cycle through static defence and radar/sonar"},
    {"v",   "cycle through labs"},
    {"b",   "cycle through anti-air"},
    {blankLine=true},    
    {"[ and ], o",   "Change facing of buildings"},
    {"h",           "Increase build spacing"},
    {"n",           "Decrease build spacing"},
    {blankLine=true},    
    {"Giving build orders", title=true},
    {"left mouse",   "Give build order"},
    {"shift + left mouse (drag)",   "Give line formation build order"},
    {"shift + alt + left mouse (drag)",   "Give square formation build order"},
    {blankLine=true},    
    {"right mouse",  "De-select build order"},
    
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
text['Selecting Units'] = FormatTable(Units_I)
text['Giving Orders'] = FormatTable(Units_II)
text['Build Orders'] = FormatTable(Units_III)

return text 

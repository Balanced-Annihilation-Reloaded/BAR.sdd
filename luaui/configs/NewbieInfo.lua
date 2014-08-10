-- it has to be like this to make the colours and line breaks get parsed correctly...

local lines = {
    [1]  = "Welcome to BAR! Some useful info:",
    [2]  = "",
    [3]  = "You can toggle this menu by pressing \255\255\150\000i\255\255\255\255",
    [4]  = "",
    [5]  = "Click left \255\50\200\20mouse\255\255\255\255 and drag to select units.",
    [6]  = "Click the right mouse to move units.",
    [7]  = "",
    [8]  = "Select \255\50\200\20orders\255\255\255\255 or \255\50\200\20build commands\255\255\255\255 from the units menu.",
    [9]  = "Use the left/right mouse to give orders to unit(s).",
    [9]  = "To give a formation command, select multiple units, then right click and drag.",
    [10]  = "Hold shift to queue orders.",
    [11] = "",
    [12] = "\255\255\255\76Energy\255\255\255\255 comes from solar collectors, wind/tidal generators and fusion plants.",
    [13] = "\255\153\153\204Metal\255\255\255\255 comes from metal extractors, which should be placed onto metal spots.",
    [14] = "Press \255\220\220\255f4\255\255\255\255 to highlight where metal spots are.",
    [15] = "You can also get metal by using constructors to reclaim dead units!",
    [16] = "",
    [17] = "BAR has many \255\50\200\20hotkeys\255\255\255\255.",
    [18] = "For example, with a unit selected, \255\255\150\000a\255\255\255\255ttack, \255\255\150\0f\255\255\255\255ight, \255\255\150\0r\255\255\255\255epair, \255\255\150\0p\255\255\255\255atrol, r\255\255\150\0e\255\255\255\255claim and \255\255\150\0g\255\255\255\255uard.",
    [19] = "With a constructor selected, use \255\255\150\000z\255\255\255\255,\255\255\150\000x\255\255\255\255,\255\255\150\000c\255\255\255\255,\255\255\150\000v\255\255\255\255 to cycle through some useful buildings.",
    [20] = "You can find out all the hotkeys from within this menu - use the dropdown menu on the right to change the text inside this window! (TODO:)",
    [21] = "",
    [22] = "You can spend your \255\50\200\20resources\255\255\255\255 on fighting units and buildings.",
    [23] = "Begin each game by making a few metal extractors, a few solars/winds/tidals and then a factory.",
    [24] = "A constructor that is guarding a factory will help it to build faster.",
    [25] = "",
    [26] = "It's important to \255\50\200\20balance your time\255\255\255\255 - between resource production, building units and fighting your enemies.",
    [27] = "Don't try to build things that you can't afford.",
    [28] = "Reclaiming your own units and buildings will give you back their metal.",
    [29] = "",
    [30] = "For your first few games, a \255\50\200\20faction\255\255\255\255 and \255\50\200\20start position\255\255\255\255 will be chosen for you.",
    [31] = "After that, you will be able to choose your own.",
    [32] = "Don't forget to check our forum on \255\200\200\250springrts.com\255\255\255\255.",
    [33] = "",
    [34] = "Good luck!",
}

local text = ""
for _,l in ipairs(lines) do
    if l == "" then
        text = text .. '\n'
    else
        text = text .. "\255\50\200\20" .. "> " .. "\255\255\255\255" .. l .. '\n'
    end
end
return text 

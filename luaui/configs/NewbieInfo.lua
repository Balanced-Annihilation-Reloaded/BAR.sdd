-- it has to be like this to make the colours and line breaks get parsed correctly...

local lines = {
    [1]  = "Welcome to BAR! Some useful info:",
    [2]  = "",
    [3]  = "You can toggle this menu by pressing \255\255\150\000i\255\255\255\255",
    [4]  = "",
    [5]  = "Click the left \255\50\200\20mouse\255\255\255\255 and drag to select units",
    [6]  = "Click the right mouse to move units",
    [7]  = "",
    [8]  = "Select \255\50\200\20orders\255\255\255\255 or \255\50\200\20build commands\255\255\255\255 from the units menu",
    [9]  = "Use the left/right mouse to give orders to unit(s)",
    [10]  = "Hold right click and drag to give a formation order to multiple units",
    [11]  = "Hold shift to queue orders.",
    [12] = "",
    [13] = "\255\255\255\76Energy\255\255\255\255 comes from solar collectors, wind/tidal generators and fusion plants",
    [14] = "\255\153\153\204Metal\255\255\255\255 comes from metal extractors, which should be placed onto metal spots",
    [15] = "You can also get metal by using constructors to reclaim dead (and live!) units",
    [16] = "",
    [17] = "You can spend your \255\50\200\20resources\255\255\255\255 on units and buildings",
    [18] = "Don't try to build things that you can't afford!",
    [19] = "Begin the game by making a few metal extractors, a few solars, winds or tidals and then a factory",
    [20] = "Guard your factory with a constructor to help it build",
    [21] = "",
    [22] = "BAR has many \255\50\200\20hotkeys\255\255\255\255",
    [23] = "You can find out all the hotkeys from this menu - see the button on the right side of this window!",
    [24] = "",
    [25] = "For your first few online multiplayer games, a \255\50\200\20faction\255\255\255\255 and \255\50\200\20start position\255\255\255\255 will be chosen for you",
    [26] = "After that, you will be able to choose your own",
    [27] = "Don't forget to check our forum on \255\200\200\250springrts.com\255\255\255\255",
    [28] = "",
    [29] = "Good luck!",
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

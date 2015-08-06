--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "LuaUI Reset",
    desc      = "Provides a '/luaui reset' command, to wipe the luaui config and reload luaui",
    author    = "Bluestone",
    date      = "",
    license   = "GPLv2",
    layer     = 0,
    enabled   = true,  
    handler   = true,
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function widget:TextCommand(s)
    local token = {}
    local n = 0
    for w in string.gmatch(s, "%S+") do
        n = n + 1
        token[n] = w        
    end
    
    if n==1 and token[1]=="reset" then
        Spring.Echo("LuaUI Reset Requested")
        widgetHandler.__reset_luaui = true
        Spring.SendCommands("luarules reloadluaui")    
    end    
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
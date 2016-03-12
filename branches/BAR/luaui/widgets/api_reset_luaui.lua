--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "LuaUI Reset",
    desc      = "Provides luaui reset, factoryreset, and disable/enable_user_widgets",
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
        widgetHandler.__blankOutConfig = true
        Spring.SendCommands("luaui reload")    
    end    
    
    if n==1 and token[1]=="factoryreset" then
        Spring.Echo("LuaUI Factory Reset Requested")
        widgetHandler.__blankOutConfig = true
        widgetHandler.__allowUserWidgets = false        
        Spring.SendCommands("luaui reload")    
    end    
    
    if n==1 and token[1]=="disable_user_widgets" then
        Spring.Echo("LuaUI User Widget Disable Requested")
        widgetHandler.__allowUserWidgets = false        
        Spring.SendCommands("luaui reload")    
    end    
    
    if n==1 and token[1]=="enable_user_widgets" then
        Spring.Echo("LuaUI User Widget Enable Requested")
        widgetHandler.__allowUserWidgets = true
        Spring.SendCommands("luaui reload")    
    end    
    
    if n==1 and token[1]=="toggle_user_widgets" then
        if widgetHandler.allowUserWidgets then
            Spring.SendCommands("luaui disable_user_widgets")
        else
            Spring.SendCommands("luaui enable_user_widgets")        
        end
    end    

end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
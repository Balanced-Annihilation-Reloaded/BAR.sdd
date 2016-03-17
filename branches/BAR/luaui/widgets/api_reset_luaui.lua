--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "LuaUI Reset",
    desc      = "Provides luaui reset, factoryreset, and disable/enable_user_widgets",
    author    = "Bluestone",
    date      = "",
    license   = "Meringue",
    layer     = 0,
    enabled   = true,  
    handler   = true,
    api     = true,
  }
end

function widget:Initialize()

    local function Reset()
        Spring.Echo("LuaUI Reset Requested")
        widgetHandler.__blankOutConfig = true
        Spring.SendCommands("luaui reload")    
    end    
    
    local function FactoryReset()
        Spring.Echo("LuaUI Factory Reset Requested")
        widgetHandler.__blankOutConfig = true
        widgetHandler.__allowUserWidgets = false        
        Spring.SendCommands("luaui reload")    
    end    
    
    local function DisableUserWidgets()
        Spring.Echo("LuaUI User Widget Disable Requested")
        widgetHandler.__allowUserWidgets = false        
        Spring.SendCommands("luaui reload")    
    end    
    
    local function EnableUserWidgets()
        Spring.Echo("LuaUI User Widget Enable Requested")
        widgetHandler.__allowUserWidgets = true
        Spring.SendCommands("luaui reload")    
    end    
    
    local function ToggleUserWidgets()
        if widgetHandler.allowUserWidgets then
            Spring.SendCommands("luaui disable_user_widgets")
        else
            Spring.SendCommands("luaui enable_user_widgets")        
        end
    end    
    
    widgetHandler.actionHandler:AddAction(widget,'reset', Reset, nil, 't')
    widgetHandler.actionHandler:AddAction(widget,'factoryreset', FactoryReset, nil, 't')
    widgetHandler.actionHandler:AddAction(widget,'disable_user_widgets', DisableUserWidgets, nil, 't')
    widgetHandler.actionHandler:AddAction(widget,'enable_user_widgets', EnableUserWidgets, nil, 't')
   widgetHandler.actionHandler:AddAction(widget,'toggle_user_widgets', ToggleUserWidgets, nil, 't')
end

function widget:Shutdown()
end


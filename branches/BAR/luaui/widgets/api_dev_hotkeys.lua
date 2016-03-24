
function widget:GetInfo()
    return {
        name    = 'Dev Hotkeys',
        desc    = 'binds f8 to debug err console and f9 to widget profiler',
        author  = 'Bluestone',
        date    = '',
        license = 'My lovely horse tralalalalalala',
        layer   = -0, 
        handler = true,
        enabled = true,
        api     = true,
    }
end


function widget:Initialize()
    local toggleWidgetProfiler  = function() 
        widgetHandler:ToggleWidget("Widget Profiler")
    end
    local toggleErrConsole = function() 
        widgetHandler:ToggleWidget("Debug Err Console")
    end
    
    widgetHandler.actionHandler:AddAction(widget,'toggleWidgetProfiler', toggleWidgetProfiler, nil, 't')
    widgetHandler.actionHandler:AddAction(widget,'toggleErrConsole', toggleErrConsole, nil, 't')

    Spring.SendCommands('bind f8 toggleErrConsole')
    Spring.SendCommands('bind f9 toggleWidgetProfiler')
end

function widget:Shutdown()
    Spring.SendCommands('unbind f8 toggleErrConsole')
    Spring.SendCommands('unbind f9 toggleWidgetProfiler')
end


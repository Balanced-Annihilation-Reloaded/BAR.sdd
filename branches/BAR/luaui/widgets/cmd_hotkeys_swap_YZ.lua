function widget:GetInfo()
    return {
        name = "Hotkey Y-Z Swap",
        desc = "Swaps Y and Z keys in BARs hotkeys (useful for AZERTY keyboards)" ,
        author = "Beherith, Bluestone",
        date = "",
        license = "GNU LGPL, v2.1 or later",
        layer = 0,
        enabled = false
    }
end

function widget:Initialize()
    if WG.SetYZState then
        WG.swapYZbinds = true
        WG.SetYZState()
    else
        Spring.Echo("BAR hotkeys widget not found, cannot swap YZ")
        widgetHandler:RemoveWidget(self)
    end
end

function widget:Shutdown()
    WG.swapYZbinds = nil
    if WG.SetYZState then
        WG.SetYZState()
    else
        Spring.Echo("BAR hotkeys widget not found, cannot swap YZ")
    end
end

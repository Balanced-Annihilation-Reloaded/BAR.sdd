function widget:GetInfo()
	return {
		name = "Hotkeys -- swap Y and Z",
		desc = "Swaps Y and Z keys in hotkeys widget (useful for AZERTY keyboards)" ,
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
        Spring.Echo("Hotkeys widget not found, cannot swap YZ")
        widgetHandler:RemoveWidget(self)
    end
end

function widget:Shutdown()
    WG.swapYZbinds = nil
    if WG.SetYZState then
        WG.SetYZState()
    else
        Spring.Echo("BA Hotkeys widget not found, cannot swap YZ")
    end
end

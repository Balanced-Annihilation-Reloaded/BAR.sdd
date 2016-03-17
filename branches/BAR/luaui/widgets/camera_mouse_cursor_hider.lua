function widget:GetInfo()
return {
     name      = "Hide Mouse",
     desc      = "Hides the cursor when the GUI is hidden",
     author    = "quantum",
     date      = "22 June 2007",
     license   = "GNU GPL, v2 or later",
     layer     = 5,
     enabled   = true  -- loaded by default?
   }
end
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local spIsGuiHidden = Spring.IsGUIHidden
local spSetMouseCursor = Spring.SetMouseCursor
local none = "none"

function widget:Update()
    if spIsGuiHidden() then
        spSetMouseCursor(none) 
    end
end
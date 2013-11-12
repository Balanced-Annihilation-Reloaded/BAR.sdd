function widget:GetInfo()
return {
     name      = "Mouse cursor hider",
     desc      = "Hides the cursor",
     author    = "quantum",
     date      = "22 June 2007",
     license   = "GNU GPL, v2 or later",
     layer     = 5,
     enabled   = false  -- loaded by default?
   }
end
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
function widget:Update()
	
	Spring.SetMouseCursor("none") 
end
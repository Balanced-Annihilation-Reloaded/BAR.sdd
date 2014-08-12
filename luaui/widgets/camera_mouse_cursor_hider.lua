function widget:GetInfo()
return {
     name      = "Hide Mouse",
     desc      = "Hides the cursor, it might be hard to get it back!",
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
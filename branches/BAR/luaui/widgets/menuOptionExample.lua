-- This will be the playground for messing with the Menu API

function widget:GetInfo()
	return {
		name    = 'Menu "API" Examples',
		desc    = 'Various examples of how to expand the main menu through global functions',
		author  = 'Funkencool, BlueStone',
		date    = '2013',
		license = 'GNU GPL v2',
		layer   = 10,
		enabled = false
	}
end

local function loadOptions()
	local popup = Chili.Window:New{
		x = '45%',
		y = '45%',
		width = 200,
		height = 75,
		draggable = true,
		children = {
			Chili.Button:New{x='20%',width='60%',bottom=0,height=20,caption='Okay...',OnMouseUp = {
				function(self) self.parent:Hide() end}
			}
		}
	}
	
--[[

	The 'children' are added to the main 'stack' of the tab mentioned
a stack is basically a custom chili control using a scrollpanel and stackpanel (native controls)
with a generic name of 'stack'

	This means chili handles the vertical aspect of all the controls added
	
	To be continued...

]]--


	Menu.AddOption{
		tab      = 'Interface',
		-- title    = 'Example 1',
		-- bLine    = true,
		children = {
			Chili.Label:New{caption='Example 1',x='0%',fontsize=18},
			Chili.ComboBox:New{
				x        = '10%',
				width    = '80%',
				items    = {"Option 1", "Option 2", "Option 3"},
				selected = 1,
				OnSelect = {
					function(_,sel)
						if sel == 3 then
							Chili.Screen0:AddChild(warning)
							popup:BringToFront()
						else
							Spring.Echo("Option "..sel.." Selected")
						end
					end
				}
			},
			Chili.Line:New{width='100%'}
		}
	}
	
end

function widget:Initialize()
	
	Chili = WG.Chili
	Menu = WG.MainMenu
	if Menu then 
		loadOptions()
	end
	
end


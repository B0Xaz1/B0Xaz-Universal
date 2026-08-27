local Workspace = game:GetService("Workspace")

return function(services: any, tab: any)
	local ThemeEngine = services:Get("ThemeEngine")
	local LocomotionService = services:Get("LocomotionService")
	local FlightService = services:Get("FlightService")
	local UIEngine = services:Get("UIEngine")
	local Disposer = services:Get("Disposer")
	local Require = services:Get("Require")
	local DOM = services:Get("DOM")

	local Toggle = Require("src/UI/Components/Toggle.luau", services)
	local Slider = Require("src/UI/Components/Slider.luau", services)
	local Keybind = Require("src/UI/Components/Keybind.luau", services)
	local Components = Require("src/UI/Components/Textbox.luau", services)

	local function createSection(parent: Instance, title: string): Frame
		local secFrame = DOM.Create("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = ThemeEngine:GetToken("Panel"),
			BorderSizePixel = 0,
			Parent = parent,
		}, {
			DOM.CreateStroke(ThemeEngine:GetToken("Border"), 1),
			DOM.Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }),
		}) :: Frame
		ThemeEngine:BindToken(secFrame, "BackgroundColor3", "Panel")

		local header = DOM.Create("Frame", {
			Size = UDim2.new(1, 0, 0, 20),
			BackgroundColor3 = ThemeEngine:GetToken("Side"),
			BorderSizePixel = 0,
			Parent = secFrame,
		}, {
			DOM.Create("Frame", {
				Size = UDim2.new(1, 0, 0, 1),
				Position = UDim2.new(0, 0, 1, -1),
				BackgroundColor3 = ThemeEngine:GetToken("Accent"),
				BorderSizePixel = 0,
			}),
			DOM.Create("TextLabel", {
				Text = "  " .. title,
				Font = Enum.Font.Code,
				TextSize = 11,
				TextColor3 = ThemeEngine:GetToken("TextDim"),
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
			}),
		})
		ThemeEngine:BindToken(header, "BackgroundColor3", "Side")

		local content = DOM.Create("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Parent = secFrame,
		}, {
			DOM.Create("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }),
			DOM.CreatePadding(4, 6, 6, 6),
		}) :: Frame

		return content
	end

	local speedSec = createSection(tab.LeftCol, "Speed & Jump Controls")
	Slider.new(speedSec, "Walk Speed", 16, 500, "Movement.Speed", 2, " ws")
	Slider.new(speedSec, "Jump Power", 50, 500, "Movement.JumpPower", 5, " jp")
	Toggle.new(speedSec, "Shift to Sprint", "Movement.SprintEnabled")
	Slider.new(speedSec, "Sprint Speed", 16, 500, "Movement.SprintSpeed", 2, " ws")
	Toggle.new(speedSec, "Infinite Air Jump", "Movement.InfJump")
	Toggle.new(speedSec, "CFrame Displacement Step", "Movement.CFrameSpeed", nil, 1)
	Slider.new(speedSec, "CFrame Step Speed", 1, 300, "Movement.CFrameSpeedValue", 5, " sps")

	local flightSec = createSection(tab.LeftCol, "Constraint Flight")
	Toggle.new(flightSec, "Enable Flight Mode", "Movement.FlyEnabled", function(active)
		if active then FlightService:Start() else FlightService:Stop() end
	end, 1)
	Slider.new(flightSec, "Flight Velocity Speed", 10, 500, "Movement.FlySpeed", 5)
	Keybind.new(flightSec, "Flight Toggle Hotkey", "Movement.FlyKeybind")

	local worldSec = createSection(tab.RightCol, "World Physics")
	-- Gravity is a live server property; remember the original so unload can
	-- put the world back instead of leaving the modified value behind.
	local originalGravity = Workspace.Gravity
	Slider.new(worldSec, "World Gravity", 0, 300, math.floor(originalGravity), 5, "", function(grav)
		Workspace.Gravity = grav
	end)
	Disposer:Add(function()
		if Workspace.Gravity ~= originalGravity then
			Workspace.Gravity = originalGravity
		end
	end)
	-- Same reasoning as gravity: the camera keeps whatever FOV was set unless
	-- unload puts the original back.
	local originalFov = Workspace.CurrentCamera and Workspace.CurrentCamera.FieldOfView or 70
	Slider.new(worldSec, "Camera Field of View", 70, 120, "Camera.FOV", 1, "°", function(fov)
		local cam = Workspace.CurrentCamera
		if cam then cam.FieldOfView = fov end
	end)
	Disposer:Add(function()
		local cam = Workspace.CurrentCamera
		if cam then cam.FieldOfView = originalFov end
	end)

	local tpSec = createSection(tab.RightCol, "Position Bookmarks")
	Components.CreateButton(tpSec, "Save Current Location", function()
		if LocomotionService:SavePosition() then
			UIEngine:Notify("Position", "Coordinates saved successfully.", 2, ThemeEngine:GetToken("Success"))
		end
	end)
	Components.CreateButton(tpSec, "Teleport to Saved Location", function()
		if LocomotionService:TeleportToSaved() then
			UIEngine:Notify("Position", "Teleported to bookmark.", 2, ThemeEngine:GetToken("Success"))
		else
			UIEngine:Notify("Position", "No coordinates saved yet.", 2, ThemeEngine:GetToken("Danger"))
		end
	end)
	Toggle.new(tpSec, "Click to Teleport (Ctrl + Click)", "Settings.TpToMouse", nil, 1)
end

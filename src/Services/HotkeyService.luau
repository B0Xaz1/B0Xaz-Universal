local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")

-- Every hotkey-able feature: the bind lives at Settings.Binds.<Key> and the
-- key it flips lives at Path. Cycle entries step a string setting instead of
-- flipping a boolean.
local BIND_TARGETS: { { Key: string, Label: string, Path: string, Cycle: { string }? } } = {
	{ Key = "Fly", Label = "Toggle Flight", Path = "Movement.FlyEnabled" },
	{ Key = "Fullbright", Label = "Toggle Fullbright", Path = "Visuals.Fullbright" },
	{ Key = "ESP", Label = "Toggle Player ESP", Path = "ESP.Enabled" },
	{ Key = "Chams", Label = "Toggle Chams", Path = "Chams.Enabled" },
	{ Key = "Aimbot", Label = "Toggle Aimbot", Path = "Aimbot.Enabled" },
	{ Key = "SpeedLines", Label = "Toggle Speed Lines", Path = "Extras.SpeedLines" },
	{
		Key = "LightingMode",
		Label = "Cycle Lighting Mode",
		Path = "Lighting.Mode",
		Cycle = { "Off", "Static Day", "Static Night", "Dynamic" },
	},
}

return function(services: any)
	local StateStore = services:Get("StateStore")
	local Environment = services:Get("Environment")
	local Disposer = services:Get("Disposer")

	local HotkeyService = {
		Targets = BIND_TARGETS,
	}

	local function notify(title: string, text: string, tokenName: string?)
		if not services:Has("UIEngine") then return end
		local uiEngine = services:Get("UIEngine")
		local color = nil
		if services:Has("ThemeEngine") then
			color = services:Get("ThemeEngine"):GetToken(tokenName or "Accent")
		end
		pcall(function()
			uiEngine:Notify(title, text, 2, color)
		end)
	end

	-- A bind that points at a tier-locked feature stays inert rather than
	-- silently failing inside StateStore:Set.
	local function trigger(target: any)
		if target.Cycle then
			local current = tostring(StateStore:Get(target.Path) or target.Cycle[1])
			local index = table.find(target.Cycle, current) or 1
			local nextValue = target.Cycle[(index % #target.Cycle) + 1]
			StateStore:Set(target.Path, nextValue)
			notify("Hotkey", target.Label .. ": " .. nextValue)
			return
		end

		local newValue = StateStore:Get(target.Path) ~= true
		if newValue and not StateStore:HasPermission(target.Path) then
			notify("Hotkey", target.Label .. " needs a higher tier key.", "Danger")
			return
		end

		StateStore:Set(target.Path, newValue)
		notify("Hotkey", target.Label .. ": " .. (newValue and "ON" or "OFF"), newValue and "Success" or "TextDim")
	end

	function HotkeyService:Initialize()
		local conn = UserInputService.InputBegan:Connect(function(input: InputObject)
			-- Typing in a textbox or recording a new bind must never fire one
			if UserInputService:GetFocusedTextBox() ~= nil or StateStore:GetTransient("IsBindingKey") then return end

			for _, target in ipairs(BIND_TARGETS) do
				local bind = Environment.ParseKeybind(StateStore:Get("Settings.Binds." .. target.Key))
				if bind and (input.KeyCode == bind or input.UserInputType == bind) then
					trigger(target)
				end
			end
		end)
		Disposer:Add(conn)

		-- Auto rejoin: the disconnect prompt is the only reliable signal a
		-- client gets for a kick or a dropped connection.
		local function rejoin()
			if StateStore:Get("Settings.AutoRejoin") ~= true then return end

			local globalEnv = (getgenv and getgenv()) or _G
			local initUrl = tostring(globalEnv.B0XazInitURL or "")
			if initUrl ~= "" then
				Environment.QueueTeleport("loadstring(game:HttpGet('" .. initUrl .. "'))()")
			end

			task.delay(1, function()
				pcall(function()
					if #Players:GetPlayers() <= 1 then
						TeleportService:Teleport(game.PlaceId, Players.LocalPlayer)
					else
						TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Players.LocalPlayer)
					end
				end)
			end)
		end

		local errorConn = GuiService.ErrorMessageChanged:Connect(function(message: string)
			if message and message ~= "" then
				rejoin()
			end
		end)
		Disposer:Add(errorConn)

		-- Some clients raise the prompt without touching ErrorMessageChanged,
		-- so the prompt GUI itself is watched as a second signal.
		pcall(function()
			local coreGui = game:GetService("CoreGui")
			local promptGui = coreGui:FindFirstChild("RobloxPromptGui")
			local overlay = promptGui and promptGui:FindFirstChild("promptOverlay")
			if not overlay then return end

			local promptConn = overlay.ChildAdded:Connect(function(child: Instance)
				if child.Name:find("ErrorPrompt") then
					rejoin()
				end
			end)
			Disposer:Add(promptConn)
		end)
	end

	return HotkeyService
end

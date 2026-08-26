--!strict
-- ══════════════════════════════════════════════════════════════════════════════
-- B0XazUniversal - Players & Interactions UI Tab
-- Target filtering, player search, whitelist management, spectating,
-- and target fling actions.
-- ══════════════════════════════════════════════════════════════════════════════

return function(services: any, tab: any)
	local ThemeEngine = services:Get("ThemeEngine")
	local StateStore = services:Get("StateStore")
	local PlayerTracker = services:Get("PlayerTracker")
	local LocomotionService = services:Get("LocomotionService")
	local Environment = services:Get("Environment")
	local UIEngine = services:Get("UIEngine")
	local Require = services:Get("Require")
	local DOM = services:Get("DOM")

	local Dropdown = Require("B0XazUniversal/src/UI/Components/Dropdown.luau", services)
	local Components = Require("B0XazUniversal/src/UI/Components/Textbox.luau", services)

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

	local selectedPlayerName: string = ""
	local playerList = PlayerTracker:GetPlayerNames(true)
	if #playerList > 0 then selectedPlayerName = playerList[1] end

	-- ─────────────────────────────────────────────────────────────────────────
	-- Left Column: Target Selection & Whitelist
	-- ─────────────────────────────────────────────────────────────────────────
	local targetSec = createSection(tab.LeftCol, "Target Selection")

	local playerDropdown = Dropdown.new(targetSec, "Select Target", playerList, selectedPlayerName, function(selected)
		selectedPlayerName = selected
		StateStore:SetTransient("SelectedPlayer", selected)
	end)

	Components.CreateTextbox(targetSec, "Filter Players", "", "Search username...", function(query)
		local allNames = PlayerTracker:GetPlayerNames(true)
		local filtered = {}
		local q = query:lower()
		for _, name in ipairs(allNames) do
			if name:lower():find(q, 1, true) then
				table.insert(filtered, name)
			end
		end
		playerDropdown:Refresh(#filtered > 0 and filtered or { "No Players Found" }, false)
	end)

	Components.CreateButton(targetSec, "Refresh Player List", function()
		local updated = PlayerTracker:GetPlayerNames(true)
		playerDropdown:Refresh(updated, true)
		UIEngine:Notify("Players", "List refreshed.", 1.5, ThemeEngine:GetToken("Accent"))
	end)

	local wlSec = createSection(tab.LeftCol, "Whitelist Management")
	Components.CreateButton(wlSec, "Whitelist Selected Player", function()
		if selectedPlayerName ~= "" and selectedPlayerName ~= "No Players Found" then
			local wl = StateStore:Get("Settings.Whitelist") or {}
			wl[selectedPlayerName] = true
			StateStore:Set("Settings.Whitelist", wl)
			UIEngine:Notify("Whitelist", "Added: " .. selectedPlayerName, 2, ThemeEngine:GetToken("Success"))
		end
	end)
	Components.CreateButton(wlSec, "Remove from Whitelist", function()
		if selectedPlayerName ~= "" then
			local wl = StateStore:Get("Settings.Whitelist") or {}
			wl[selectedPlayerName] = nil
			StateStore:Set("Settings.Whitelist", wl)
			UIEngine:Notify("Whitelist", "Removed: " .. selectedPlayerName, 2, ThemeEngine:GetToken("Warning"))
		end
	end)
	Components.CreateButton(wlSec, "Clear Entire Whitelist", function()
		StateStore:Set("Settings.Whitelist", {})
		UIEngine:Notify("Whitelist", "All whitelists cleared.", 2, ThemeEngine:GetToken("Success"))
	end)

	-- ─────────────────────────────────────────────────────────────────────────
	-- Right Column: Target Actions
	-- ─────────────────────────────────────────────────────────────────────────
	local actionSec = createSection(tab.RightCol, "Target Actions")
	Components.CreateButton(actionSec, "Teleport to Player", function()
		local target = PlayerTracker:GetPlayerByName(selectedPlayerName)
		local assets = target and PlayerTracker:GetPlayerAssets(target)
		if assets and assets.RootPart then
			LocomotionService:TeleportToPosition(assets.RootPart.Position)
			UIEngine:Notify("Teleport", "Teleported to " .. selectedPlayerName, 2, ThemeEngine:GetToken("Success"))
		else
			UIEngine:Notify("Teleport", "Target is not alive.", 2, ThemeEngine:GetToken("Danger"))
		end
	end)

	Components.CreateButton(actionSec, "Spectate Target View", function()
		local target = PlayerTracker:GetPlayerByName(selectedPlayerName)
		if target and PlayerTracker:StartSpectate(target) then
			UIEngine:Notify("Spectate", "Spectating " .. selectedPlayerName, 2, ThemeEngine:GetToken("Success"))
		else
			UIEngine:Notify("Spectate", "Target unavailable.", 2, ThemeEngine:GetToken("Danger"))
		end
	end)

	Components.CreateButton(actionSec, "Stop Camera Spectate", function()
		PlayerTracker:StopSpectate()
		UIEngine:Notify("Spectate", "Camera returned to local.", 2, ThemeEngine:GetToken("Accent"))
	end)

	Components.CreateButton(actionSec, "Copy Player Username", function()
		if selectedPlayerName ~= "" then
			Environment.SetClipboard(selectedPlayerName)
			UIEngine:Notify("Clipboard", "Copied: " .. selectedPlayerName, 2, ThemeEngine:GetToken("Success"))
		end
	end)

	Components.CreateButton(actionSec, "Fling Attack Player", function()
		local target = PlayerTracker:GetPlayerByName(selectedPlayerName)
		if target and LocomotionService:StartFling(target) then
			UIEngine:Notify("Fling", "Fling attack engaged on " .. selectedPlayerName, 2, ThemeEngine:GetToken("Warning"))
		else
			UIEngine:Notify("Fling", "Fling requires Tier 3 access.", 2, ThemeEngine:GetToken("Danger"))
		end
	end, 3)

	Components.CreateButton(actionSec, "Stop Fling Attack", function()
		LocomotionService:StopFling()
		UIEngine:Notify("Fling", "Fling attack stopped.", 2, ThemeEngine:GetToken("Accent"))
	end, 3)
end

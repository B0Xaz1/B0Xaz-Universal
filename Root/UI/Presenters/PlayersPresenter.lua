-- ════════════════════════════════════════════════════════════════════════════
-- UI/Presenters/PlayersPresenter.lua
-- Binds Player targeting, spectating, whitelist, and fling controls
-- ════════════════════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Dropdown = require(script.Parent.Parent.Components.Dropdown)
local Button = require(script.Parent.Parent.Components.Button)
local Section = require(script.Parent.Parent.Components.Section)

local PlayersPresenter = {}

function PlayersPresenter.Build(tab, container, themeEngine)
	local entity = container:Get("EntityService")
	local fling = container:Get("FlingService")
	local config = container:Get("ConfigService")
	local localPlayer = Players.LocalPlayer
	local page = tab.Page

	local selectedName = nil
	local originalCameraSubject = nil

	local function getPlayerNames()
		local list = {}
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= localPlayer then table.insert(list, p.Name) end
		end
		return #list == 0 and { "No Players Found" } or list
	end

	local names = getPlayerNames()
	selectedName = names[1] ~= "No Players Found" and names[1] or nil

	Section.new(page, "Targeting", themeEngine)
	local playerDropdown = Dropdown.new(page, "Select Target Player", names, function(v)
		selectedName = v ~= "No Players Found" and v or nil
	end, selectedName or "No Players Found", themeEngine)

	Button.new(page, "Refresh Player List", function()
		playerDropdown:Refresh(getPlayerNames(), true)
	end, themeEngine)

	-- Actions
	Section.new(page, "Actions", themeEngine)
	Button.new(page, "Teleport to Target", function()
		if not selectedName then return end
		local target = Players:FindFirstChild(selectedName)
		local assets = target and entity:GetAssets(target)
		local myRoot = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
		if assets and assets.RootPart and myRoot then
			myRoot.CFrame = assets.RootPart.CFrame + Vector3.new(0, 3, 3)
		end
	end, themeEngine)

	Button.new(page, "Spectate Target Camera", function()
		if not selectedName then return end
		local target = Players:FindFirstChild(selectedName)
		local assets = target and entity:GetAssets(target)
		local camera = Workspace.CurrentCamera
		if camera and assets and assets.Humanoid then
			if not originalCameraSubject then originalCameraSubject = camera.CameraSubject end
			camera.CameraSubject = assets.Humanoid
		end
	end, themeEngine)

	Button.new(page, "Reset Camera Spectate", function()
		local camera = Workspace.CurrentCamera
		local myHum = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")
		if camera and myHum then
			camera.CameraSubject = originalCameraSubject or myHum
			originalCameraSubject = nil
		end
	end, themeEngine)

	Button.new(page, "Launch Fling Attack", function()
		if not selectedName then return end
		local target = Players:FindFirstChild(selectedName)
		if target then fling:Start(target) end
	end, themeEngine)

	Button.new(page, "Stop Fling Attack", function()
		fling:Stop()
	end, themeEngine)
end

return PlayersPresenter

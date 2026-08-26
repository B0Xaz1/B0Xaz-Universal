--!strict
-- ══════════════════════════════════════════════════════════════════════════════
-- B0XazUniversal - Player Entity Lifecycle & Tracker Service
-- Observes character additions/removals, maintains clean weak references to
-- character limbs without memory leaks, and provides camera spectate handling.
-- ══════════════════════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

export type PlayerAssets = {
	Player: Player,
	Character: Model,
	Humanoid: Humanoid,
	RootPart: BasePart,
	Head: BasePart,
}

return function(services: any)
	local Disposer = services:Get("Disposer")
	local EventBus = services:Get("EventBus")

	local LocalPlayer = Players.LocalPlayer
	local PlayerTracker = {
		_registry = {} :: { [Player]: PlayerAssets },
		_spectatingTarget = nil :: Player?,
		_spectateConnection = nil :: RBXScriptConnection?,
		_originalCameraSubject = nil :: Instance?,
	}

	local function onCharacterAdded(player: Player, character: Model)
		local hum = character:WaitForChild("Humanoid", 5) :: Humanoid?
		local root = character:WaitForChild("HumanoidRootPart", 5) :: BasePart?
		local head = character:WaitForChild("Head", 5) :: BasePart?

		if hum and root and head then
			PlayerTracker._registry[player] = {
				Player = player,
				Character = character,
				Humanoid = hum,
				RootPart = root,
				Head = head,
			}
			EventBus:Publish("PlayerCharacterAdded", player, character)
		end
	end

	local function onCharacterRemoving(player: Player, character: Model)
		PlayerTracker._registry[player] = nil
		EventBus:Publish("PlayerCharacterRemoving", player, character)
	end

	function PlayerTracker:GetPlayerAssets(player: Player?): PlayerAssets?
		if not player then return nil end
		return self._registry[player]
	end

	function PlayerTracker:GetLocalAssets(): PlayerAssets?
		return self:GetPlayerAssets(LocalPlayer)
	end

	function PlayerTracker:IsAlive(player: Player?): boolean
		local assets = self:GetPlayerAssets(player)
		return assets ~= nil and assets.Humanoid.Health > 0 and assets.RootPart:IsDescendantOf(Workspace)
	end

	function PlayerTracker:GetPlayerByName(query: string): Player?
		if query == "" then return nil end
		local lowerQuery = query:lower()

		for player in pairs(self._registry) do
			if player.Name == query or player.DisplayName == query then
				return player
			end
		end

		for player in pairs(self._registry) do
			if player.Name:lower():find(lowerQuery, 1, true) or player.DisplayName:lower():find(lowerQuery, 1, true) then
				return player
			end
		end
		return nil
	end

	function PlayerTracker:GetPlayerNames(excludeLocal: boolean): { string }
		local list = {}
		for _, player in ipairs(Players:GetPlayers()) do
			if not excludeLocal or player ~= LocalPlayer then
				table.insert(list, player.Name)
			end
		end
		table.sort(list)
		return list
	end

	-- ─────────────────────────────────────────────────────────────────────────
	-- Camera Spectate Management
	-- ─────────────────────────────────────────────────────────────────────────
	function PlayerTracker:StartSpectate(targetPlayer: Player): boolean
		if not targetPlayer or targetPlayer == LocalPlayer or not self:IsAlive(targetPlayer) then
			return false
		end

		self:StopSpectate()
		local cam = Workspace.CurrentCamera
		if not cam then return false end

		self._spectatingTarget = targetPlayer
		self._originalCameraSubject = cam.CameraSubject

		local assets = self:GetPlayerAssets(targetPlayer)
		if assets then
			cam.CameraSubject = assets.Humanoid
		end

		self._spectateConnection = targetPlayer.CharacterAdded:Connect(function()
			task.wait(0.5)
			if self._spectatingTarget == targetPlayer then
				local newAssets = self:GetPlayerAssets(targetPlayer)
				if newAssets and Workspace.CurrentCamera then
					Workspace.CurrentCamera.CameraSubject = newAssets.Humanoid
				end
			end
		end)

		return true
	end

	function PlayerTracker:StopSpectate()
		if self._spectateConnection then
			self._spectateConnection:Disconnect()
			self._spectateConnection = nil
		end

		local cam = Workspace.CurrentCamera
		if cam then
			local localAssets = self:GetLocalAssets()
			if localAssets and localAssets.Humanoid then
				cam.CameraSubject = localAssets.Humanoid
			end
		end

		self._spectatingTarget = nil
		self._originalCameraSubject = nil
	end

	function PlayerTracker:OnLocalCharacterRespawn(callback: () -> ())
		if LocalPlayer then
			LocalPlayer.CharacterAdded:Connect(function()
				task.wait(0.2)
				callback()
			end)
		end
	end

	function PlayerTracker:OnPlayerAdded(callback: (player: Player) -> ())
		EventBus:Subscribe("PlayerJoined", callback)
	end

	function PlayerTracker:OnPlayerRemoving(callback: (player: Player) -> ())
		EventBus:Subscribe("PlayerLeft", callback)
	end

	function PlayerTracker:Initialize()
		for _, player in ipairs(Players:GetPlayers()) do
			if player.Character then
				task.spawn(onCharacterAdded, player, player.Character)
			end
			player.CharacterAdded:Connect(function(char) onCharacterAdded(player, char) end)
			player.CharacterRemoving:Connect(function(char) onCharacterRemoving(player, char) end)
		end

		local pAdded = Players.PlayerAdded:Connect(function(player)
			player.CharacterAdded:Connect(function(char) onCharacterAdded(player, char) end)
			player.CharacterRemoving:Connect(function(char) onCharacterRemoving(player, char) end)
			EventBus:Publish("PlayerJoined", player)
		end)
		Disposer:Add(pAdded)

		local pRemoving = Players.PlayerRemoving:Connect(function(player)
			if self._spectatingTarget == player then
				self:StopSpectate()
			end
			self._registry[player] = nil
			EventBus:Publish("PlayerLeft", player)
		end)
		Disposer:Add(pRemoving)
	end

	return PlayerTracker
end

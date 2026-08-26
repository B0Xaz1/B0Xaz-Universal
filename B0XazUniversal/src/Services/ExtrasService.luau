--!strict
-- ══════════════════════════════════════════════════════════════════════════════
-- B0XazUniversal - Hitbox & Spin Bot Service
-- Applies reversible local hitbox expansion and local character rotation.
-- ══════════════════════════════════════════════════════════════════════════════

local Players = game:GetService("Players")

export type HitboxBackup = {
	Part: BasePart,
	Size: Vector3,
	Transparency: number,
	CanCollide: boolean,
}

return function(services: any)
	local StateStore = services:Get("StateStore")
	local TaskScheduler = services:Get("TaskScheduler")
	local Disposer = services:Get("Disposer")
	local PlayerTracker = services:Get("PlayerTracker")
	local LocalPlayer = Players.LocalPlayer

	local ExtrasService = {
		_hitboxBackups = {} :: { [Player]: HitboxBackup },
		_spinRoot = nil :: BasePart?,
		_spinAngularVelocity = nil :: Vector3?,
	}

	local function restoreHitbox(player: Player, backup: HitboxBackup)
		local part = backup.Part
		if part and part.Parent then
			part.Size = backup.Size
			part.Transparency = backup.Transparency
			part.CanCollide = backup.CanCollide
		end
		ExtrasService._hitboxBackups[player] = nil
	end

	function ExtrasService:RestoreHitboxes()
		for player, backup in pairs(self._hitboxBackups) do
			restoreHitbox(player, backup)
		end
		table.clear(self._hitboxBackups)
	end

	local function updateHitboxes(enabled: boolean)
		if not enabled then
			ExtrasService:RestoreHitboxes()
			return
		end

		local requestedSize = math.clamp(tonumber(StateStore:Get("Extras.Hitbox.Size")) or 10, 2, 60)
		local expandedSize = Vector3.new(requestedSize, requestedSize, requestedSize)

		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer then
				local assets = PlayerTracker:GetPlayerAssets(player)
				local part = assets and assets.RootPart
				if part and part.Parent then
					local backup = ExtrasService._hitboxBackups[player]
					if backup and backup.Part ~= part then
						restoreHitbox(player, backup)
						backup = nil
					end
					if not backup then
						backup = {
							Part = part,
							Size = part.Size,
							Transparency = part.Transparency,
							CanCollide = part.CanCollide,
						}
						ExtrasService._hitboxBackups[player] = backup
					end
					part.Size = expandedSize
					part.Transparency = math.max(backup.Transparency, 0.5)
					part.CanCollide = false
				end
			end
		end
	end

	local function updateSpin(enabled: boolean, dt: number)
		local assets = PlayerTracker:GetLocalAssets()
		local root = assets and assets.RootPart
		if not enabled or not root or not root.Parent then
			if ExtrasService._spinRoot and ExtrasService._spinRoot.Parent and ExtrasService._spinAngularVelocity then
				ExtrasService._spinRoot.AssemblyAngularVelocity = ExtrasService._spinAngularVelocity
			end
			ExtrasService._spinRoot = nil
			ExtrasService._spinAngularVelocity = nil
			return
		end

		if ExtrasService._spinRoot ~= root then
			ExtrasService._spinRoot = root
			ExtrasService._spinAngularVelocity = root.AssemblyAngularVelocity
		end

		local speed = math.clamp(tonumber(StateStore:Get("Extras.SpinBot.Speed")) or 20, 1, 100)
		root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(speed) * dt, 0)
	end

	local function onHeartbeat(dt: number)
		local hitboxEnabled = StateStore:Get("Extras.Hitbox.Enabled") == true
		local spinEnabled = StateStore:Get("Extras.SpinBot.Enabled") == true
		if hitboxEnabled and not StateStore:HasPermission("Extras.Hitbox.Enabled") then
			hitboxEnabled = false
		end
		if spinEnabled and not StateStore:HasPermission("Extras.SpinBot.Enabled") then
			spinEnabled = false
		end
		updateHitboxes(hitboxEnabled)
		updateSpin(spinEnabled, dt)
	end

	function ExtrasService:Initialize()
		TaskScheduler:RegisterHeartbeat("ExtrasUpdate", 12, onHeartbeat)
		Disposer:Add(function()
			self:Destroy()
		end)
		local playerRemoving = Players.PlayerRemoving:Connect(function(player)
			local backup = self._hitboxBackups[player]
			if backup then
				restoreHitbox(player, backup)
			end
		end)
		Disposer:Add(playerRemoving)
	end

	function ExtrasService:Destroy()
		self:RestoreHitboxes()
		updateSpin(false, 0)
	end

	return ExtrasService
end

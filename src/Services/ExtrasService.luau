-- Hitbox expansion, spin bot, and impulse-based fling defense.

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
		_antiFlingRoot = nil :: BasePart?,
		_antiFlingLastVel = Vector3.zero,
		_antiFlingLastCFrame = CFrame.new(),
		_lastFlingBlockNotify = 0,
	}

	-- UIEngine and ThemeEngine are registered with the container after this
	-- service is built, so they are resolved lazily on first use instead of
	-- at factory time.
	local uiEngineRef: any = nil
	local themeEngineRef: any = nil
	local function getUIAndTheme(): (any, any)
		if uiEngineRef == nil and services:Has("UIEngine") then
			uiEngineRef = services:Get("UIEngine")
			if services:Has("ThemeEngine") then
				themeEngineRef = services:Get("ThemeEngine")
			end
		end
		return uiEngineRef, themeEngineRef
	end

	local function restoreHitbox(player: Player, backup: HitboxBackup)
		local part = backup.Part
		if part and part.Parent then
			pcall(function()
				part.Size = backup.Size
				part.Transparency = backup.Transparency
				part.CanCollide = backup.CanCollide
			end)
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
				if not part and player.Character then
					part = player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
				end
				if part and part:IsA("BasePart") and part.Parent then
					-- A respawn swaps the root part; the old backup is
					-- restored before a fresh one is taken for the new part.
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
					pcall(function()
						part.Size = expandedSize
						-- HumanoidRootPart is normally invisible; keeping the
						-- expansion visible makes the feature verifiable.
						part.Transparency = 0.5
						part.CanCollide = false
					end)
				end
			end
		end
	end

	local function updateSpin(enabled: boolean, dt: number)
		local assets = PlayerTracker:GetLocalAssets()
		local root = assets and assets.RootPart
		if not enabled or not root or not root.Parent then
			-- Restore the angular velocity captured before the spin started
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
		-- The slider is degrees per frame at 60 FPS; scaling by dt keeps the
		-- spin rate identical across frame rates.
		root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(speed) * dt * 60, 0)
	end

	-- Fling defense: combines collision prevention (disabling collision on
	-- other players' character parts so they phase through without pushing)
	-- with impulse and velocity clamping on the local assembly. Normal
	-- movement (walking, jumping, falling) is never blocked, while extreme
	-- fling impulses, violent spin, or extreme velocity spikes are zeroed
	-- and snapped back.
	local function updateAntiFling(enabled: boolean, dt: number)
		local assets = PlayerTracker:GetLocalAssets()
		local root = assets and assets.RootPart
		local hum = assets and assets.Humanoid

		if not root or not root.Parent or not hum or hum.Health <= 0 then
			ExtrasService._antiFlingRoot = nil
			return
		end

		-- A respawn swaps the root part; re-baseline before comparing.
		if ExtrasService._antiFlingRoot ~= root then
			ExtrasService._antiFlingRoot = root
			ExtrasService._antiFlingLastVel = root.AssemblyLinearVelocity
			ExtrasService._antiFlingLastCFrame = root.CFrame
			return
		end

		-- While the guard is off or suppressed we still refresh the baseline
		-- so it cannot false-positive on the frame it re-engages.
		local suppressed = os.clock() < (StateStore:GetTransient("AntiFlingSuppressUntil") or 0)
		if not enabled or suppressed then
			ExtrasService._antiFlingLastVel = root.AssemblyLinearVelocity
			ExtrasService._antiFlingLastCFrame = root.CFrame
			return
		end

		-- Passive collision defense: other players' character parts cannot
		-- collide with or transfer momentum to our assembly
		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer and player.Character then
				for _, part in ipairs(player.Character:GetDescendants()) do
					if part:IsA("BasePart") and part.CanCollide then
						part.CanCollide = false
					end
				end
			end
		end

		local threshold = math.clamp(tonumber(StateStore:Get("Extras.AntiFling.Threshold")) or 300, 200, 5000)
		local vel = root.AssemblyLinearVelocity
		local angVel = root.AssemblyAngularVelocity
		local deltaVel = (vel - ExtrasService._antiFlingLastVel).Magnitude
		local impulse = deltaVel / math.max(dt, 1e-4)

		-- Only classify as a fling if velocity or angular spin is truly beyond
		-- any physically possible player movement. Normal walking, sprinting,
		-- jumping, and falling can never produce these extreme velocities.
		local maxSelfDelta = math.max((hum.WalkSpeed or 16) * 1.5 + (hum.JumpPower or 50), 120)

		local isFling = false
		if (deltaVel > maxSelfDelta and impulse > threshold) or angVel.Magnitude > 250 then
			isFling = true
		end

		if isFling then
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
			if StateStore:Get("Extras.AntiFling.SnapBack") == true then
				root.CFrame = ExtrasService._antiFlingLastCFrame
			end
			ExtrasService._antiFlingLastVel = Vector3.zero
			-- Throttled so repeated contact does not spam notifications
			if os.clock() - ExtrasService._lastFlingBlockNotify > 2 then
				ExtrasService._lastFlingBlockNotify = os.clock()
				local ui, theme = getUIAndTheme()
				if ui and theme then
					ui:Notify("Fling Defense", "Fling attack blocked.", 1.5, theme:GetToken("Success"))
				end
			end
		else
			ExtrasService._antiFlingLastCFrame = root.CFrame
			ExtrasService._antiFlingLastVel = vel
		end
	end

	local function onAntiFlingUpdate(dt: number)
		local antiFlingEnabled = StateStore:Get("Extras.AntiFling.Enabled") == true
		if antiFlingEnabled and not StateStore:HasPermission("Extras.AntiFling.Enabled") then
			antiFlingEnabled = false
		end
		updateAntiFling(antiFlingEnabled, dt)
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

		-- The fling guard runs on the pre-simulation step so the impulse
		-- velocity is zeroed before the physics engine integrates it into a
		-- position change.
		TaskScheduler:RegisterPreSim("AntiFlingUpdate", 5, onAntiFlingUpdate)
		Disposer:Add(function()
			self:Destroy()
		end)
		-- Players who leave while expanded get their hitbox restored instead
		-- of holding a stale backup forever.
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

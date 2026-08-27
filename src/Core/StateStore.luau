local DEFAULT_SETTINGS = {
	Aimbot = {
		Enabled = false,
		UseCamera = false,
		Keybind = Enum.UserInputType.MouseButton2,
		Hitpart = "Head",
		Smoothness = 4,
		MovementMode = "Linear",
		WindStrength = 1.0,
		WindDamping = 0.8,
		LockMode = "Hold",
		Prediction = { Horizontal = 0, Vertical = 0 },
		TeamCheck = false,
		FriendCheck = true,
		WhitelistCheck = true,
		ForceFieldCheck = true,
		VisCheck = true,
		MaxDistance = 1000,
		ShakeIntensity = 0,
		UnlockOnDeath = true,
		BreakOnPull = false,
		MaxLockRadius = 200,
		Triggerbot = {
			Enabled = false,
			Delay = 0.05,
			TeamCheck = false,
			FriendCheck = true,
			WhitelistCheck = true,
			ForceFieldCheck = true,
			VisCheck = false,
			MaxDistance = 1000,
		},
		FOV = {
			Size = 150,
			Show = true,
			Filled = false,
			Thickness = 1,
			Sides = 64,
			Rainbow = false,
			Pulse = false,
		},
	},
	Movement = {
		Speed = 16,
		JumpPower = 50,
		InfJump = false,
		FlyEnabled = false,
		FlySpeed = 50,
		FlyKeybind = Enum.KeyCode.F,
		MobileFlyUp = false,
		MobileFlyDown = false,
		SprintEnabled = false,
		SprintSpeed = 30,
		CFrameSpeed = false,
		CFrameSpeedValue = 50,
	},
	ESP = {
		Enabled = false,
		Box = false,
		Name = false,
		Health = false,
		Distance = false,
		Tool = false,
		Backpack = false,
		Tracers = false,
		Skeleton = false,
		HeadDot = false,
		LookDir = false,
		TeamCheck = false,
		MaxDist = 500,
		Color = Color3.fromRGB(0, 200, 255),
		Font = "Monospace",
		Outline = true,
		AutoScaling = true,
	},
	Chams = {
		Enabled = false,
		UseTeamColor = false,
		DepthMode = "AlwaysOnTop",
		FillColor = Color3.fromRGB(0, 170, 255),
		OutlineColor = Color3.fromRGB(255, 255, 255),
	},
	Camera = { FOV = 90 },
	Visuals = { Fullbright = false },
	Lighting = {
		Mode = "Off",
		TimeOfDay = 6,
		CycleDuration = 600,
		Paused = false,
		PresetBrightness = 100,
		Vignette = true,
		RemasterMaterials = true,
	},
	Extras = {
		Hitbox = { Enabled = false, Size = 10 },
		SpinBot = { Enabled = false, Speed = 20 },
		SpeedLines = false,
		AntiFling = { Enabled = false, Threshold = 300, SnapBack = true },
	},
	Performance = {
		NoTextures = false,
		LowMaterials = false,
		OptimizeTerrain = false,
		NoPostProcessing = false,
		NoShadows = false,
		NoParticles = false,
	},
	Game = {} :: { [string]: any },
	Settings = {
		UIScale = 1.0,
		MenuKeybind = Enum.KeyCode.RightShift,
		UnloadKeybind = Enum.KeyCode.End,
		ShowFPS = false,
		ShowPing = false,
		AntiAfk = false,
		TpToMouse = false,
		Whitelist = {} :: { [string]: boolean },
	},
	Theme = {
		ActivePreset = "Default Cyan",
	},
}

-- Features that only unlock from a given key tier upward
local TIER_REQUIREMENTS: { [string]: number } = {
	["Aimbot.Enabled"] = 3,
	["Aimbot.Triggerbot.Enabled"] = 3,
	["Game"] = 3,
	["Locomotion.Fling"] = 3,
	["ESP.Enabled"] = 2,
	["Chams.Enabled"] = 2,
	["Movement.FlyEnabled"] = 1,
	["Movement.CFrameSpeed"] = 1,
	["Extras.Hitbox.Enabled"] = 1,
	["Extras.SpinBot.Enabled"] = 1,
	["Extras.AntiFling.Enabled"] = 1,
	["Visuals.Fullbright"] = 1,
}

local function deepClone<T>(src: T): T
	if typeof(src) ~= "table" then return src end
	local copy = {}
	for k, v in pairs(src :: any) do
		copy[k] = deepClone(v)
	end
	return (copy :: any) :: T
end

local function mergeWithDefaults<T>(defaults: T, source: T): T
	local merged = deepClone(defaults)
	local function apply(target: any, values: any)
		for key, value in pairs(values) do
			if typeof(value) == "table" and typeof(target[key]) == "table" then
				apply(target[key], value)
			else
				target[key] = deepClone(value)
			end
		end
	end
	apply(merged :: any, source :: any)
	return merged
end

return function(eventBus: any, disposer: any)
	local StateStore = {
		_currentTier = 0,
		_settings = deepClone(DEFAULT_SETTINGS),
		_transients = {
			AimTarget = nil :: Player?,
			AimTargetName = nil :: string?,
			AimLocked = false,
			AimHoldActive = false,
			SelectedPlayer = nil :: string?,
			SavedPosition = nil :: CFrame?,
			MenuVisible = true,
			IsBindingKey = false,
			OriginalHitboxSizes = {} :: { [Player]: { Size: Vector3, Transparency: number, CanCollide: boolean } },
		},
		_defaults = deepClone(DEFAULT_SETTINGS),
	}

	function StateStore:SetTier(tier: number)
		self._currentTier = math.clamp(tonumber(tier) or 0, 0, 3)
		eventBus:Publish("TierChanged", self._currentTier)
		self:EnforcePermissions()
	end

	function StateStore:GetTier(): number
		return self._currentTier
	end

	function StateStore:HasPermission(featurePath: string): boolean
		local req = TIER_REQUIREMENTS[featurePath]
		if not req then return true end
		return self._currentTier >= req
	end

	-- Forces locked features back off whenever the tier is downgraded so a
	-- stale "true" in settings can never outlive the key that granted it.
	function StateStore:EnforcePermissions()
		if self._currentTier < 3 then
			self:Set("Aimbot.Enabled", false)
			self:Set("Aimbot.Triggerbot.Enabled", false)
			local gameTable = self:Get("Game")
			if typeof(gameTable) == "table" then
				for k in pairs(gameTable) do
					self:Set("Game." .. k, false)
				end
			end
		end
		if self._currentTier < 2 then
			self:Set("ESP.Enabled", false)
			self:Set("Chams.Enabled", false)
		end
		if self._currentTier < 1 then
			self:Set("Movement.FlyEnabled", false)
			self:Set("Movement.CFrameSpeed", false)
			self:Set("Movement.InfJump", false)
			self:Set("Extras.Hitbox.Enabled", false)
			self:Set("Extras.SpinBot.Enabled", false)
			self:Set("Extras.AntiFling.Enabled", false)
			self:Set("Visuals.Fullbright", false)
		end
	end

	local function navigate(root: any, path: string, createMissing: boolean?): (any, string)
		local segments = string.split(path, ".")
		local current = root
		for i = 1, #segments - 1 do
			local seg = segments[i]
			if current[seg] == nil then
				if createMissing then
					current[seg] = {}
				else
					return nil, segments[#segments]
				end
			end
			current = current[seg]
		end
		return current, segments[#segments]
	end

	function StateStore:Get(path: string): any
		local parent, key = navigate(self._settings, path, false)
		if parent ~= nil and parent[key] ~= nil then
			return parent[key]
		end
		return nil
	end

	function StateStore:Set(path: string, value: any, bypassPermCheck: boolean?): boolean
		if not bypassPermCheck and not self:HasPermission(path) and value == true then
			return false
		end

		local parent, key = navigate(self._settings, path, true)
		local oldValue = parent[key]

		-- Tables are stored by copy: callers frequently mutate a table they
		-- obtained from Get and Set it back, which would compare equal by
		-- reference and never emit a change signal.
		local storedValue = typeof(value) == "table" and deepClone(value) or value

		if oldValue ~= storedValue then
			parent[key] = storedValue
			eventBus:Publish("StateChanged:" .. path, storedValue, oldValue)
			eventBus:Publish("StateChanged", path, storedValue, oldValue)
			return true
		end
		return false
	end

	function StateStore:GetTransient(key: string): any
		return self._transients[key]
	end

	function StateStore:SetTransient(key: string, value: any)
		local old = self._transients[key]
		if old ~= value then
			self._transients[key] = value
			eventBus:Publish("TransientChanged:" .. key, value, old)
		end
	end

	function StateStore:Observe(path: string, callback: (newValue: any, oldValue: any) -> ()): any
		return eventBus:Subscribe("StateChanged:" .. path, callback)
	end

	function StateStore:GetSettingsSnapshot(): { [string]: any }
		return deepClone(self._settings)
	end

	-- Public accessor for the defaults so services do not reach into the
	-- internal clone directly.
	function StateStore:GetDefaultSettings(): { [string]: any }
		return deepClone(self._defaults)
	end

	function StateStore:LoadSettingsSnapshot(snapshot: { [string]: any })
		if typeof(snapshot) ~= "table" then return end
		self._settings = mergeWithDefaults(DEFAULT_SETTINGS, snapshot)
		self:EnforcePermissions()
		eventBus:Publish("StateHydrated", self._settings)
	end

	return StateStore
end

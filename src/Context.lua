-- // src/Context.lua
local DEFAULT_FEATURE_CONFIG = {
	Aimbot = {
		Enabled = false,
		Keybind = Enum.UserInputType.MouseButton2,
		Hitpart = "Head",
		AirHitpart = "Head",
		Smoothness = 4,
		LockMode = "Hold",
		Prediction = { Horizontal = 0, Vertical = 0 },
		TeamCheck = false,
		VisCheck = false,
		MaxDistance = 1000,
		ShakeIntensity = 0,
		LockNPC = false,
		UnlockOnDeath = true,
		BreakOnPull = false,
		MaxLockRadius = 200,
		Triggerbot = { Enabled = false, Delay = 0.05 },
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
		MobileFlyUp = false,
		MobileFlyDown = false,
		SprintEnabled = false,
		SprintSpeed = 30,
		CFrameSpeed = false,
		CFrameSpeedValue = 50,
		Bhop = false,
	},
	ESP = {
		Enabled = false,
		Box = false,
		Name = false,
		Health = false,
		Distance = false,
		Tracers = false,
		Skeleton = false,
		HeadDot = false,
		LookDir = false,
		TeamCheck = false,
		MaxDist = 500,
		Color = Color3.fromRGB(0, 200, 255),
	},
	Chams = {
		Enabled = false,
		FillColor = Color3.fromRGB(0, 170, 255),
		OutlineColor = Color3.fromRGB(255, 255, 255),
	},
	Camera = { FOV = 90 },
	Visuals = { Fullbright = false },
	Extras = {
		Hitbox = { Enabled = false, Size = 10 },
		SpinBot = { Enabled = false, Speed = 20 },
		Crosshair = {
			Visible = false,
			Size = 12,
			Gap = 4,
			Thickness = 2,
			Color = Color3.fromRGB(255, 255, 255),
		},
		SpeedLines = false,
		Wallbang = false,
	},
	Performance = {
		NoTextures = false,
		LowMaterials = false,
		OptimizeTerrain = false,
		NoPostProcessing = false,
		NoShadows = false,
		NoParticles = false,
	},
	Game = {
		DoorPhase = false,
		DoorGlow = true,
		GlowColor = Color3.fromRGB(0, 200, 220),
		PhaseTransparency = 0.65,
		NoSpread = false,
		FastFire = false,
		ForceAuto = false,
		ForceRange = false,
		FireRateValue = 0.001,
		RangeValue = 10000,
	},
}

local DEFAULT_STATE = {
	AimTarget = nil,
	AimHoldActive = false,
	AimLocked = false,
	AimSettleCounter = 0,
	SelectedPlayer = nil,
	SavedPosition = nil,
	OriginalHitboxSizes = {},
	FlyBodyVelocity = nil,
	FlyBodyGyro = nil,
	SpinBotAngle = 0,
	OrbitAngle = 0,
	SpinTargetAngle = 0,
	FOVHue = 0,
	FOVPulse = 0,
	LoopTeleport = false,
	OrbitEnabled = false,
	OrbitRadius = 8,
	OrbitSpeed = 2,
	LoopJump = false,
	SpinTarget = false,
	TpToMouse = false,
	MenuVisible = true,
	MenuKeybind = Enum.KeyCode.RightShift,
	includeSelf = false,
}

local DEFAULT_STATS = {
	ShowFPS = false,
	ShowPing = false,
}

local function deepCopy(target)
	if type(target) ~= "table" then
		return target
	end
	local copy = {}
	for k, v in pairs(target) do
		copy[k] = deepCopy(v)
	end
	return copy
end

return function(CONFIG, DefaultLighting, Utils, DrawingManager)
	local env = (getgenv and getgenv()) or _G

	env.B0XazConnections = env.B0XazConnections or {}
	env.B0XazThreads = env.B0XazThreads or {}
	env.B0XazDrawings = env.B0XazDrawings or {}

	local rawConns = env.B0XazConnections
	local rawThreads = env.B0XazThreads

	local Connections = {}

	function Connections.Add(conn)
		if conn then
			table.insert(rawConns, conn)
		end
		return conn
	end

	function Connections.Track(thread)
		if thread then
			table.insert(rawThreads, thread)
		end
		return thread
	end

	function Connections.DisconnectAll()
		for i = #rawConns, 1, -1 do
			local conn = rawConns[i]
			if conn then
				pcall(function()
					if typeof(conn) == "RBXScriptConnection" or type(conn.Disconnect) == "function" then
						conn:Disconnect()
					end
				end)
			end
			rawConns[i] = nil
		end

		for i = #rawThreads, 1, -1 do
			local th = rawThreads[i]
			if th then
				pcall(function() task.cancel(th) end)
			end
			rawThreads[i] = nil
		end
	end

	local featureConfig = deepCopy(DEFAULT_FEATURE_CONFIG)
	local state = deepCopy(DEFAULT_STATE)
	local statsConfig = deepCopy(DEFAULT_STATS)

	env.B0XazState = state

	local folderName = (CONFIG and CONFIG.FOLDER) or "B0XazUniversal"
	if Utils and type(Utils.MakeFolder) == "function" then
		pcall(function()
			Utils.MakeFolder(folderName)
			Utils.MakeFolder(folderName .. "/Themes")
		end)
	end

	return {
		CONFIG = CONFIG,
		DefaultLighting = DefaultLighting,
		Utils = Utils,
		DrawingManager = DrawingManager,
		Connections = Connections,
		FeatureConfig = featureConfig,
		State = state,
		StatsConfig = statsConfig,
		UIRegistry = {},
	}
end

local SETTINGS = {
	FOLDERS = {
		ROOT = "B0XazUniversal",
		THEMES_SUBFOLDER = "/Themes",
	},
	DEFAULTS = {
		FEATURE_CONFIG = {
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
		},
		STATE = {
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
		},
		STATS = {
			ShowFPS = false,
			ShowPing = false,
		},
	},
}

local function deepCopy(source)
	if type(source) ~= "table" then
		return source
	end
	local copy = {}
	for key, value in pairs(source) do
		copy[key] = deepCopy(value)
	end
	return copy
end

return function(CONFIG, DefaultLighting, Utils, DrawingManager)
	local globalEnv = getgenv and getgenv() or _G

	globalEnv.B0XazConnections = globalEnv.B0XazConnections or {}
	globalEnv.B0XazThreads = globalEnv.B0XazThreads or {}
	globalEnv.B0XazDrawings = globalEnv.B0XazDrawings or {}

	local rawConnections = globalEnv.B0XazConnections
	local rawThreads = globalEnv.B0XazThreads

	local Connections = {}

	function Connections.Add(conn)
		if conn then
			table.insert(rawConnections, conn)
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
		for index = #rawConnections, 1, -1 do
			local conn = rawConnections[index]
			if conn then
				pcall(function()
					if typeof(conn) == "RBXScriptConnection" or conn.Disconnect then
						conn:Disconnect()
					end
				end)
			end
			rawConnections[index] = nil
		end

		for index = #rawThreads, 1, -1 do
			local thread = rawThreads[index]
			if thread then
				pcall(function()
					task.cancel(thread)
				end)
			end
			rawThreads[index] = nil
		end
	end

	local FeatureConfig = deepCopy(SETTINGS.DEFAULTS.FEATURE_CONFIG)
	local State = deepCopy(SETTINGS.DEFAULTS.STATE)
	local StatsConfig = deepCopy(SETTINGS.DEFAULTS.STATS)

	globalEnv.B0XazState = State

	local folderName = (CONFIG and CONFIG.FOLDER) or SETTINGS.FOLDERS.ROOT
	if Utils and Utils.MakeFolder then
		pcall(function()
			Utils.MakeFolder(folderName)
			Utils.MakeFolder(folderName .. SETTINGS.FOLDERS.THEMES_SUBFOLDER)
		end)
	end

	return {
		CONFIG = CONFIG,
		DefaultLighting = DefaultLighting,
		Utils = Utils,
		DrawingManager = DrawingManager,
		Connections = Connections,
		FeatureConfig = FeatureConfig,
		State = State,
		StatsConfig = StatsConfig,
		UIRegistry = {},
	}
end

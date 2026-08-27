local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local MaterialService = game:GetService("MaterialService")
local Players = game:GetService("Players")

local EFFECT_PREFIX = "B0Xaz_Cinematic_"

-- Lighting properties the cycle writes every frame. Snapshot/restore walk
-- this list with pcall so a property missing on an older client build is
-- skipped instead of erroring the whole service.
local LIGHTING_PROPERTIES: { string } = {
	"Technology",
	"ClockTime",
	"GeographicLatitude",
	"Brightness",
	"Ambient",
	"OutdoorAmbient",
	"ColorShift_Top",
	"ColorShift_Bottom",
	"FogColor",
	"FogStart",
	"FogEnd",
	"ExposureCompensation",
	"GlobalShadows",
	"ShadowSoftness",
	"EnvironmentDiffuseScale",
	"EnvironmentSpecularScale",
}

local TERRAIN_PROPERTIES: { string } = {
	"Decoration",
	"WaterColor",
	"WaterReflectance",
	"WaterTransparency",
	"WaterWaveSize",
	"WaterWaveSpeed",
}

-- Static day profile: a fixed late-afternoon golden hour. Specular and
-- exposure are held down and the bloom threshold high for the same reason
-- the dynamic keyframes do it - white clothing and pale walls must not glow.
local STATIC_DAY_PROFILE = {
	Lighting = {
		ClockTime = 17.25,
		GeographicLatitude = 41.8,
		Brightness = 2.2,
		Ambient = Color3.fromRGB(65, 70, 85),
		OutdoorAmbient = Color3.fromRGB(120, 100, 90),
		ColorShift_Top = Color3.fromRGB(240, 170, 100),
		ColorShift_Bottom = Color3.fromRGB(40, 45, 65),
		GlobalShadows = true,
		ShadowSoftness = 0.1,
		EnvironmentDiffuseScale = 0.8,
		EnvironmentSpecularScale = 0.5,
		ExposureCompensation = -0.05,
		FogStart = 400,
		FogEnd = 15000,
		FogColor = Color3.fromRGB(220, 140, 95),
	},
	ColorCorrection = {
		Contrast = 0.1,
		Saturation = 0.12,
		TintColor = Color3.fromRGB(255, 235, 215),
	},
	Bloom = {
		Intensity = 0.08,
		Size = 8,
		Threshold = 1.4,
	},
	SunRays = {
		Intensity = 0.25,
		Spread = 0.5,
	},
	Atmosphere = {
		Density = 0.4,
		Offset = 0.25,
		Color = Color3.fromRGB(230, 120, 80),
		Decay = Color3.fromRGB(255, 115, 65),
		Glare = 0.2,
		Haze = 1.8,
	},
	DepthOfField = {
		FarIntensity = 0.2,
		FocusDistance = 80,
		InFocusRadius = 40,
		NearIntensity = 0,
	},
	Clouds = {
		Cover = 0.5,
		Density = 0.4,
		Color = Color3.fromRGB(240, 140, 100),
	},
	Water = {
		WaterColor = Color3.fromRGB(35, 75, 105),
		WaterReflectance = 0.8,
		WaterTransparency = 0.7,
	},
}

-- Static night profile: a stylized moonlit blue hour rather than a literal
-- midnight. Moonlight is deliberately overdriven and the ambients kept well
-- above black so the scene reads as graded night instead of an unlit map.
local STATIC_NIGHT_PROFILE = {
	Lighting = {
		ClockTime = 0.4,
		GeographicLatitude = 41.8,
		Brightness = 2.4,
		Ambient = Color3.fromRGB(58, 68, 100),
		OutdoorAmbient = Color3.fromRGB(74, 90, 132),
		ColorShift_Top = Color3.fromRGB(130, 160, 230),
		ColorShift_Bottom = Color3.fromRGB(28, 34, 62),
		GlobalShadows = true,
		ShadowSoftness = 0.2,
		EnvironmentDiffuseScale = 0.85,
		EnvironmentSpecularScale = 0.45,
		ExposureCompensation = 0.05,
		FogStart = 250,
		FogEnd = 12000,
		FogColor = Color3.fromRGB(38, 50, 92),
	},
	-- Strong contrast plus a cold tint is what sells the grade; saturation
	-- stays positive so neon and emissive props keep their color.
	ColorCorrection = {
		Contrast = 0.22,
		Saturation = 0.1,
		TintColor = Color3.fromRGB(198, 214, 255),
	},
	-- Threshold is lower than the day preset on purpose: at night the only
	-- things bright enough to cross it are lamps, neon, and moon highlights,
	-- so the glow lands on light sources instead of on white surfaces.
	Bloom = {
		Intensity = 0.16,
		Size = 14,
		Threshold = 1.1,
	},
	SunRays = {
		Intensity = 0.1,
		Spread = 0.6,
	},
	Atmosphere = {
		Density = 0.3,
		Offset = 0.15,
		Color = Color3.fromRGB(48, 64, 118),
		Decay = Color3.fromRGB(75, 100, 180),
		Glare = 0.18,
		Haze = 1.5,
	},
	DepthOfField = {
		FarIntensity = 0.18,
		FocusDistance = 85,
		InFocusRadius = 45,
		NearIntensity = 0,
	},
	Clouds = {
		Cover = 0.55,
		Density = 0.45,
		Color = Color3.fromRGB(60, 78, 130),
	},
	Water = {
		WaterColor = Color3.fromRGB(26, 58, 95),
		WaterReflectance = 0.95,
		WaterTransparency = 0.7,
	},
}

-- "Static" is the pre-split name for the day preset; it is kept so a saved
-- profile written before the night preset existed still resolves.
local STATIC_PROFILES: { [string]: any } = {
	["Static Day"] = STATIC_DAY_PROFILE,
	["Static Night"] = STATIC_NIGHT_PROFILE,
	["Static"] = STATIC_DAY_PROFILE,
}

-- 24-hour keyframes. Bloom values are deliberately low and the bloom
-- threshold is held high in the update loop; both exist to stop white
-- clothing and pale walls from blowing out into a glow.
local KEYFRAMES = {
	{ -- Midnight
		Time = 0,
		Brightness = 0.5,
		Ambient = Color3.fromRGB(12, 14, 25),
		OutdoorAmbient = Color3.fromRGB(8, 10, 18),
		ColorShiftTop = Color3.fromRGB(30, 40, 70),
		ColorShiftBottom = Color3.fromRGB(4, 4, 15),
		FogColor = Color3.fromRGB(6, 8, 16),
		FogStart = 50,
		FogEnd = 3000,
		Exposure = -0.35,
		Saturation = -0.12,
		Contrast = 0.18,
		TintColor = Color3.fromRGB(195, 205, 255),
		BloomIntensity = 0.04,
		BloomSize = 4,
		RaysIntensity = 0.0,
		AtmoDensity = 0.3,
		AtmoColor = Color3.fromRGB(12, 16, 32),
		AtmoHaze = 1.0,
		CloudCover = 0.4,
		CloudDensity = 0.3,
		CloudColor = Color3.fromRGB(10, 12, 22),
		DofFarIntensity = 0.18,
		DofFocusDistance = 90,
		DofInFocusRadius = 50,
		WindForce = Vector3.new(4, 0, 4),
	},
	{ -- Dawn
		Time = 5.5,
		Brightness = 1.7,
		Ambient = Color3.fromRGB(85, 55, 65),
		OutdoorAmbient = Color3.fromRGB(140, 75, 65),
		ColorShiftTop = Color3.fromRGB(255, 130, 100),
		ColorShiftBottom = Color3.fromRGB(45, 30, 45),
		FogColor = Color3.fromRGB(145, 75, 85),
		FogStart = 150,
		FogEnd = 9000,
		Exposure = -0.08,
		Saturation = 0.08,
		Contrast = 0.12,
		TintColor = Color3.fromRGB(255, 210, 195),
		BloomIntensity = 0.10,
		BloomSize = 8,
		RaysIntensity = 0.12,
		AtmoDensity = 0.48,
		AtmoColor = Color3.fromRGB(200, 95, 80),
		AtmoHaze = 2.2,
		CloudCover = 0.55,
		CloudDensity = 0.45,
		CloudColor = Color3.fromRGB(195, 115, 100),
		DofFarIntensity = 0.28,
		DofFocusDistance = 60,
		DofInFocusRadius = 25,
		WindForce = Vector3.new(12, 0, 8),
	},
	{ -- Sunrise / golden hour
		Time = 6.5,
		Brightness = 2.9,
		Ambient = Color3.fromRGB(195, 145, 95),
		OutdoorAmbient = Color3.fromRGB(255, 180, 110),
		ColorShiftTop = Color3.fromRGB(255, 215, 150),
		ColorShiftBottom = Color3.fromRGB(90, 70, 80),
		FogColor = Color3.fromRGB(255, 190, 140),
		FogStart = 400,
		FogEnd = 18000,
		Exposure = 0.0,
		Saturation = 0.16,
		Contrast = 0.13,
		TintColor = Color3.fromRGB(255, 240, 220),
		BloomIntensity = 0.14,
		BloomSize = 10,
		RaysIntensity = 0.28,
		AtmoDensity = 0.42,
		AtmoColor = Color3.fromRGB(255, 165, 110),
		AtmoHaze = 1.35,
		CloudCover = 0.5,
		CloudDensity = 0.4,
		CloudColor = Color3.fromRGB(255, 195, 145),
		DofFarIntensity = 0.25,
		DofFocusDistance = 75,
		DofInFocusRadius = 35,
		WindForce = Vector3.new(10, 0, 10),
	},
	{ -- Midday
		Time = 12.0,
		Brightness = 3.2,
		Ambient = Color3.fromRGB(135, 145, 155),
		OutdoorAmbient = Color3.fromRGB(180, 200, 225),
		ColorShiftTop = Color3.fromRGB(255, 252, 248),
		ColorShiftBottom = Color3.fromRGB(145, 165, 185),
		FogColor = Color3.fromRGB(195, 225, 255),
		FogStart = 800,
		FogEnd = 35000,
		Exposure = 0.0,
		Saturation = 0.08,
		Contrast = 0.08,
		TintColor = Color3.fromRGB(255, 255, 255),
		BloomIntensity = 0.06,
		BloomSize = 6,
		RaysIntensity = 0.08,
		AtmoDensity = 0.2,
		AtmoColor = Color3.fromRGB(190, 220, 255),
		AtmoHaze = 0.3,
		CloudCover = 0.25,
		CloudDensity = 0.25,
		CloudColor = Color3.fromRGB(255, 255, 255),
		DofFarIntensity = 0.08,
		DofFocusDistance = 140,
		DofInFocusRadius = 75,
		WindForce = Vector3.new(6, 0, 4),
	},
	{ -- Sunset / golden hour
		Time = 17.5,
		Brightness = 2.6,
		Ambient = Color3.fromRGB(215, 140, 105),
		OutdoorAmbient = Color3.fromRGB(255, 150, 90),
		ColorShiftTop = Color3.fromRGB(255, 185, 125),
		ColorShiftBottom = Color3.fromRGB(80, 50, 85),
		FogColor = Color3.fromRGB(255, 155, 105),
		FogStart = 350,
		FogEnd = 16000,
		Exposure = 0.0,
		Saturation = 0.18,
		Contrast = 0.14,
		TintColor = Color3.fromRGB(255, 220, 190),
		BloomIntensity = 0.16,
		BloomSize = 11,
		RaysIntensity = 0.32,
		AtmoDensity = 0.48,
		AtmoColor = Color3.fromRGB(255, 125, 85),
		AtmoHaze = 2.2,
		CloudCover = 0.58,
		CloudDensity = 0.48,
		CloudColor = Color3.fromRGB(255, 140, 95),
		DofFarIntensity = 0.28,
		DofFocusDistance = 70,
		DofInFocusRadius = 30,
		WindForce = Vector3.new(15, 0, -10),
	},
	{ -- Dusk / blue hour
		Time = 19.0,
		Brightness = 1.0,
		Ambient = Color3.fromRGB(45, 35, 65),
		OutdoorAmbient = Color3.fromRGB(35, 30, 75),
		ColorShiftTop = Color3.fromRGB(110, 90, 150),
		ColorShiftBottom = Color3.fromRGB(12, 12, 30),
		FogColor = Color3.fromRGB(25, 20, 55),
		FogStart = 100,
		FogEnd = 7000,
		Exposure = -0.28,
		Saturation = -0.06,
		Contrast = 0.13,
		TintColor = Color3.fromRGB(180, 190, 255),
		BloomIntensity = 0.05,
		BloomSize = 5,
		RaysIntensity = 0.01,
		AtmoDensity = 0.36,
		AtmoColor = Color3.fromRGB(32, 26, 64),
		AtmoHaze = 1.2,
		CloudCover = 0.45,
		CloudDensity = 0.35,
		CloudColor = Color3.fromRGB(40, 35, 70),
		DofFarIntensity = 0.16,
		DofFocusDistance = 80,
		DofInFocusRadius = 40,
		WindForce = Vector3.new(8, 0, -8),
	},
	{ -- Midnight again, so hour 23.x interpolates back into hour 0
		Time = 24.0,
		Brightness = 0.5,
		Ambient = Color3.fromRGB(12, 14, 25),
		OutdoorAmbient = Color3.fromRGB(8, 10, 18),
		ColorShiftTop = Color3.fromRGB(30, 40, 70),
		ColorShiftBottom = Color3.fromRGB(4, 4, 15),
		FogColor = Color3.fromRGB(6, 8, 16),
		FogStart = 50,
		FogEnd = 3000,
		Exposure = -0.35,
		Saturation = -0.12,
		Contrast = 0.18,
		TintColor = Color3.fromRGB(195, 205, 255),
		BloomIntensity = 0.04,
		BloomSize = 4,
		RaysIntensity = 0.0,
		AtmoDensity = 0.3,
		AtmoColor = Color3.fromRGB(12, 16, 32),
		AtmoHaze = 1.0,
		CloudCover = 0.4,
		CloudDensity = 0.3,
		CloudColor = Color3.fromRGB(10, 12, 22),
		DofFarIntensity = 0.18,
		DofFocusDistance = 90,
		DofInFocusRadius = 50,
		WindForce = Vector3.new(4, 0, 4),
	},
}

local function lerpNumber(a: number, b: number, t: number): number
	return a + (b - a) * t
end

local function smoothStep(t: number): number
	return t * t * (3 - 2 * t)
end

local function boundingKeyframes(clockTime: number)
	for index = 1, #KEYFRAMES - 1 do
		local first = KEYFRAMES[index]
		local second = KEYFRAMES[index + 1]
		if clockTime >= first.Time and clockTime <= second.Time then
			local alpha = (clockTime - first.Time) / (second.Time - first.Time)
			return first, second, smoothStep(alpha)
		end
	end
	return KEYFRAMES[1], KEYFRAMES[2], 0
end

return function(services: any)
	local StateStore = services:Get("StateStore")
	local Disposer = services:Get("Disposer")
	local EventBus = services:Get("EventBus")
	local TaskScheduler = services:Get("TaskScheduler")
	local Environment = services:Get("Environment")

	local LightingService = {
		Mode = "Off",
		CurrentTime = 6,
		_snapshot = nil :: { [string]: any }?,
		_terrainSnapshot = nil :: { [string]: any }?,
		_windSnapshot = nil :: Vector3?,
		_use2022Snapshot = nil :: boolean?,
		_effects = {} :: { Instance },
		_reflectanceCache = {} :: { [BasePart]: number },
		_lightCache = {} :: { [Instance]: { Brightness: number, Shadows: boolean } },
		_cycleJob = nil :: any,
		_staticJob = nil :: any,
		_descendantConn = nil :: RBXScriptConnection?,
		_vignetteGui = nil :: ScreenGui?,
	}

	-- UIEngine/ThemeEngine are registered after this service is built, so
	-- they are resolved lazily the first time a notification is raised.
	local function notify(title: string, text: string, tokenName: string?)
		if not services:Has("UIEngine") then return end
		local uiEngine = services:Get("UIEngine")
		local color = nil
		if services:Has("ThemeEngine") then
			color = services:Get("ThemeEngine"):GetToken(tokenName or "Accent")
		end
		pcall(function()
			uiEngine:Notify(title, text, 2.5, color)
		end)
	end

	local function getTerrain(): Terrain?
		return Workspace:FindFirstChildOfClass("Terrain")
	end

	-- Taken once, on the first apply. A second apply (mode switch while
	-- already active) must not overwrite it with already-modified values.
	local function takeSnapshot()
		if LightingService._snapshot then return end

		local snapshot: { [string]: any } = {}
		for _, property in ipairs(LIGHTING_PROPERTIES) do
			local lightingAny = Lighting :: any
			local ok, value = pcall(function()
				return lightingAny[property]
			end)
			if ok then
				snapshot[property] = value
			end
		end
		LightingService._snapshot = snapshot

		local terrain = getTerrain()
		if terrain then
			local terrainSnapshot: { [string]: any } = {}
			for _, property in ipairs(TERRAIN_PROPERTIES) do
				local terrainAny = terrain :: any
				local ok, value = pcall(function()
					return terrainAny[property]
				end)
				if ok then
					terrainSnapshot[property] = value
				end
			end
			LightingService._terrainSnapshot = terrainSnapshot
		end

		pcall(function()
			LightingService._windSnapshot = Workspace.GlobalWind
		end)
		pcall(function()
			LightingService._use2022Snapshot = MaterialService.Use2022Materials
		end)
	end

	local function restoreSnapshot()
		local snapshot = LightingService._snapshot
		if snapshot then
			local lightingAny = Lighting :: any
			for property, value in pairs(snapshot) do
				pcall(function()
					lightingAny[property] = value
				end)
			end
			LightingService._snapshot = nil
		end

		local terrainSnapshot = LightingService._terrainSnapshot
		local terrain = getTerrain()
		if terrainSnapshot and terrain then
			local terrainAny = terrain :: any
			for property, value in pairs(terrainSnapshot) do
				pcall(function()
					terrainAny[property] = value
				end)
			end
		end
		LightingService._terrainSnapshot = nil

		if LightingService._windSnapshot then
			pcall(function()
				Workspace.GlobalWind = LightingService._windSnapshot
			end)
			LightingService._windSnapshot = nil
		end

		if LightingService._use2022Snapshot ~= nil then
			pcall(function()
				MaterialService.Use2022Materials = LightingService._use2022Snapshot
			end)
			LightingService._use2022Snapshot = nil
		end
	end

	-- Effects are created under a B0Xaz-prefixed name and tracked so the
	-- restore path destroys ours without touching the game's own effects.
	local function acquireEffect(parent: Instance, className: string, key: string): Instance
		local name = EFFECT_PREFIX .. key
		local existing = parent:FindFirstChild(name)
		if existing and existing.ClassName == className then
			table.insert(LightingService._effects, existing)
			return existing
		end
		if existing then
			existing:Destroy()
		end

		local effect = Instance.new(className)
		effect.Name = name
		effect.Parent = parent
		table.insert(LightingService._effects, effect)
		return effect
	end

	-- Properties are written one at a time under pcall so a single property
	-- missing on an older client build cannot abort the whole preset.
	local function applyProperties(target: Instance, properties: { [string]: any })
		local targetAny = target :: any
		for property, value in pairs(properties) do
			pcall(function()
				targetAny[property] = value
			end)
		end
	end

	local function destroyEffects()
		for _, effect in ipairs(LightingService._effects) do
			if effect and effect.Parent then
				pcall(function()
					effect:Destroy()
				end)
			end
		end
		table.clear(LightingService._effects)
		LightingService._vignetteGui = nil
	end

	local function createVignette()
		if LightingService._vignetteGui then return end

		local screenGui = Instance.new("ScreenGui")
		screenGui.Name = EFFECT_PREFIX .. "Vignette"
		screenGui.ResetOnSpawn = false
		screenGui.IgnoreGuiInset = true
		-- Below the suite's own 999 window so the menu is never dimmed
		screenGui.DisplayOrder = 990

		local vignette = Instance.new("ImageLabel")
		vignette.Name = "Vignette"
		vignette.Size = UDim2.fromScale(1, 1)
		vignette.BackgroundTransparency = 1
		vignette.Image = "rbxassetid://2570113110"
		vignette.ImageColor3 = Color3.fromRGB(0, 0, 0)
		vignette.ImageTransparency = 0.45
		vignette.Parent = screenGui

		-- The executor-safe host is preferred; PlayerGui is the fallback so
		-- the overlay still shows on executors without gethui/CoreGui.
		local ok = pcall(function()
			screenGui.Parent = Environment.GetSafeGuiParent()
		end)
		if not ok or not screenGui.Parent then
			local localPlayer = Players.LocalPlayer
			local playerGui = localPlayer and localPlayer:FindFirstChildOfClass("PlayerGui")
			if not playerGui then
				screenGui:Destroy()
				return
			end
			screenGui.Parent = playerGui
		end

		LightingService._vignetteGui = screenGui
		table.insert(LightingService._effects, screenGui)
	end

	local function destroyVignette()
		if LightingService._vignetteGui then
			local gui = LightingService._vignetteGui
			local index = table.find(LightingService._effects, gui)
			if index then
				table.remove(LightingService._effects, index)
			end
			pcall(function()
				gui:Destroy()
			end)
			LightingService._vignetteGui = nil
		end
	end

	-- Bright, near-white parts get their reflectance pulled down instead of
	-- up; boosting them is what makes white surfaces bloom into a haze.
	local function remasterPart(instance: Instance)
		if not instance:IsA("BasePart") then return end
		local part = instance :: BasePart

		if LightingService._reflectanceCache[part] == nil then
			LightingService._reflectanceCache[part] = part.Reflectance
		end

		local brightness = (part.Color.R + part.Color.G + part.Color.B) / 3
		if brightness > 0.75 then
			part.Reflectance = math.min(part.Reflectance, 0.02)
			return
		end

		if part.Material == Enum.Material.Glass then
			part.Reflectance = math.clamp(part.Reflectance, 0.15, 0.5)
		elseif part.Material == Enum.Material.Metal then
			part.Reflectance = math.clamp(part.Reflectance, 0.08, 0.3)
		end
	end

	local function upgradeLight(instance: Instance)
		if not instance:IsA("Light") then return end
		local light = instance :: Light

		if LightingService._lightCache[light] == nil then
			LightingService._lightCache[light] = { Brightness = light.Brightness, Shadows = light.Shadows }
		end

		light.Shadows = true
		-- Mild boost only, capped both multiplicatively and additively so
		-- already-bright map lights do not turn into white blobs.
		light.Brightness = math.min(light.Brightness * 1.1, light.Brightness + 0.5)
	end

	local function restoreWorldRemaster()
		for part, reflectance in pairs(LightingService._reflectanceCache) do
			if part and part.Parent then
				pcall(function()
					part.Reflectance = reflectance
				end)
			end
		end
		table.clear(LightingService._reflectanceCache)

		for light, original in pairs(LightingService._lightCache) do
			if light and light.Parent then
				pcall(function()
					local typedLight = light :: Light
					typedLight.Brightness = original.Brightness
					typedLight.Shadows = original.Shadows
				end)
			end
		end
		table.clear(LightingService._lightCache)
	end

	local function applyWorldRemaster()
		local remasterMaterials = StateStore:Get("Lighting.RemasterMaterials") == true
		local upgradeLights = StateStore:Get("Lighting.UpgradeMapLights") == true
		if not remasterMaterials and not upgradeLights then return end

		for _, descendant in ipairs(Workspace:GetDescendants()) do
			if remasterMaterials then
				remasterPart(descendant)
			end
			if upgradeLights then
				upgradeLight(descendant)
			end
		end

		-- Late-arriving objects go through the same cached path, so restore
		-- stays lossless for anything streamed in while the mode is active.
		local conn = Workspace.DescendantAdded:Connect(function(descendant: Instance)
			if StateStore:Get("Lighting.RemasterMaterials") == true then
				remasterPart(descendant)
			end
			if StateStore:Get("Lighting.UpgradeMapLights") == true then
				upgradeLight(descendant)
			end
		end)
		LightingService._descendantConn = conn
		Disposer:Bind("B0XazLightingDescendants", conn)
	end

	local colorCorrection: ColorCorrectionEffect? = nil
	local bloom: BloomEffect? = nil
	local sunRays: SunRaysEffect? = nil
	local atmosphere: Atmosphere? = nil
	local depthOfField: DepthOfFieldEffect? = nil
	local clouds: Clouds? = nil

	local function buildDynamicEffects()
		colorCorrection = acquireEffect(Lighting, "ColorCorrectionEffect", "ColorCorrection") :: ColorCorrectionEffect
		bloom = acquireEffect(Lighting, "BloomEffect", "Bloom") :: BloomEffect
		sunRays = acquireEffect(Lighting, "SunRaysEffect", "SunRays") :: SunRaysEffect
		atmosphere = acquireEffect(Lighting, "Atmosphere", "Atmosphere") :: Atmosphere
		depthOfField = acquireEffect(Lighting, "DepthOfFieldEffect", "DepthOfField") :: DepthOfFieldEffect

		local terrain = getTerrain()
		clouds = terrain and (acquireEffect(terrain, "Clouds", "Clouds") :: Clouds) or nil
	end

	local function applyEngineQuality()
		-- Future lighting and 2022 materials are not writable on every
		-- client build, so both are attempted and ignored on failure.
		pcall(function()
			Lighting.Technology = Enum.Technology.Future
		end)
		pcall(function()
			MaterialService.Use2022Materials = true
		end)

		local terrain = getTerrain()
		if terrain then
			pcall(function()
				terrain.Decoration = true
			end)
			pcall(function()
				terrain.WaterColor = Color3.fromRGB(35, 75, 105)
				terrain.WaterReflectance = 1.0
				terrain.WaterTransparency = 0.8
				terrain.WaterWaveSize = 0.15
				terrain.WaterWaveSpeed = 14
			end)
		end
	end

	local function stepCycle(deltaTime: number)
		local paused = StateStore:Get("Lighting.Paused") == true
		local cycleDuration = tonumber(StateStore:Get("Lighting.CycleDuration")) or 600

		if not paused and cycleDuration > 0 then
			LightingService.CurrentTime = (LightingService.CurrentTime + (deltaTime / cycleDuration) * 24) % 24
		end

		local first, second, alpha = boundingKeyframes(LightingService.CurrentTime)

		Lighting.ClockTime = LightingService.CurrentTime
		Lighting.GeographicLatitude = 41.8
		-- NoShadows owns the shadow state whenever it is active, so the
		-- cycle never fights the performance tab over GlobalShadows.
		Lighting.GlobalShadows = StateStore:Get("Performance.NoShadows") ~= true
		Lighting.ShadowSoftness = 0.08
		Lighting.EnvironmentDiffuseScale = 1
		-- Kept below 1 on purpose: full specular is a white-blowout source
		Lighting.EnvironmentSpecularScale = 0.7

		Lighting.Brightness = lerpNumber(first.Brightness, second.Brightness, alpha)
		Lighting.Ambient = first.Ambient:Lerp(second.Ambient, alpha)
		Lighting.OutdoorAmbient = first.OutdoorAmbient:Lerp(second.OutdoorAmbient, alpha)
		Lighting.ColorShift_Top = first.ColorShiftTop:Lerp(second.ColorShiftTop, alpha)
		Lighting.ColorShift_Bottom = first.ColorShiftBottom:Lerp(second.ColorShiftBottom, alpha)
		Lighting.FogColor = first.FogColor:Lerp(second.FogColor, alpha)
		Lighting.FogStart = lerpNumber(first.FogStart, second.FogStart, alpha)
		Lighting.FogEnd = lerpNumber(first.FogEnd, second.FogEnd, alpha)
		Lighting.ExposureCompensation = lerpNumber(first.Exposure, second.Exposure, alpha)

		pcall(function()
			Workspace.GlobalWind = first.WindForce:Lerp(second.WindForce, alpha)
		end)

		if colorCorrection then
			colorCorrection.Saturation = lerpNumber(first.Saturation, second.Saturation, alpha)
			colorCorrection.Contrast = lerpNumber(first.Contrast, second.Contrast, alpha)
			colorCorrection.TintColor = first.TintColor:Lerp(second.TintColor, alpha)
		end

		if bloom then
			-- Scaled down and hard-clamped; the high threshold means only
			-- genuine highlights bloom, not white clothing or walls.
			bloom.Intensity = math.min(lerpNumber(first.BloomIntensity, second.BloomIntensity, alpha) * 0.55, 0.2)
			bloom.Size = lerpNumber(first.BloomSize, second.BloomSize, alpha) * 0.75
			bloom.Threshold = 1.35
		end

		if sunRays then
			sunRays.Intensity = lerpNumber(first.RaysIntensity, second.RaysIntensity, alpha)
			sunRays.Spread = 0.55
		end

		if atmosphere then
			atmosphere.Density = lerpNumber(first.AtmoDensity, second.AtmoDensity, alpha)
			atmosphere.Color = first.AtmoColor:Lerp(second.AtmoColor, alpha)
			atmosphere.Haze = lerpNumber(first.AtmoHaze, second.AtmoHaze, alpha)
			atmosphere.Glare = lerpNumber(first.RaysIntensity * 0.6, second.RaysIntensity * 0.6, alpha)
		end

		if depthOfField then
			depthOfField.FarIntensity = lerpNumber(first.DofFarIntensity, second.DofFarIntensity, alpha)
			depthOfField.FocusDistance = lerpNumber(first.DofFocusDistance, second.DofFocusDistance, alpha)
			depthOfField.InFocusRadius = lerpNumber(first.DofInFocusRadius, second.DofInFocusRadius, alpha)
			depthOfField.NearIntensity = 0.05
		end

		if clouds then
			clouds.Cover = lerpNumber(first.CloudCover, second.CloudCover, alpha)
			clouds.Density = lerpNumber(first.CloudDensity, second.CloudDensity, alpha)
			clouds.Color = first.CloudColor:Lerp(second.CloudColor, alpha)
		end
	end

	-- Whichever static preset is live; the reassert job reads it so day and
	-- night share one code path.
	local activeStaticProfile: any = nil

	-- Re-asserting the core Lighting values keeps a game's own day/night
	-- script from silently walking the preset back. Post-process effects
	-- are not re-applied here; nothing else writes to instances we own.
	-- Scales a profile colour without letting any channel clip past white,
	-- which is what would reintroduce the white-surface glow.
	local function scaleColor(color: Color3, scale: number): Color3
		return Color3.new(
			math.clamp(color.R * scale, 0, 1),
			math.clamp(color.G * scale, 0, 1),
			math.clamp(color.B * scale, 0, 1)
		)
	end

	local function assertStaticLighting()
		if not activeStaticProfile then return end
		applyProperties(Lighting, activeStaticProfile.Lighting)

		-- User brightness trim, applied on top of the preset so the grade
		-- (colours, fog, contrast) is preserved at any exposure level.
		local scale = (tonumber(StateStore:Get("Lighting.PresetBrightness")) or 100) / 100
		if scale ~= 1 then
			local base = activeStaticProfile.Lighting
			Lighting.Brightness = base.Brightness * scale
			Lighting.Ambient = scaleColor(base.Ambient, scale)
			Lighting.OutdoorAmbient = scaleColor(base.OutdoorAmbient, scale)
			Lighting.ExposureCompensation = base.ExposureCompensation + (scale - 1) * 0.25
		end

		-- NoShadows still owns the shadow state when it is active
		if StateStore:Get("Performance.NoShadows") == true then
			Lighting.GlobalShadows = false
		end
	end

	-- Heartbeat with an accumulator instead of a spawned while-loop: the
	-- job dies with the scheduler and costs nothing between ticks.
	local staticElapsed = 0
	local function stepStatic(deltaTime: number)
		staticElapsed += deltaTime
		if staticElapsed < 1 then return end
		staticElapsed = 0
		assertStaticLighting()
	end

	-- Both presets write to the same effect instances, so switching between
	-- them reuses them instead of leaving a stale set behind.
	local function buildStaticEffects(profile: any)
		local cc = acquireEffect(Lighting, "ColorCorrectionEffect", "StaticColorCorrection")
		applyProperties(cc, profile.ColorCorrection)

		local bloomFx = acquireEffect(Lighting, "BloomEffect", "StaticBloom")
		applyProperties(bloomFx, profile.Bloom)

		local rays = acquireEffect(Lighting, "SunRaysEffect", "StaticSunRays")
		applyProperties(rays, profile.SunRays)

		local atmo = acquireEffect(Lighting, "Atmosphere", "StaticAtmosphere")
		applyProperties(atmo, profile.Atmosphere)

		local dof = acquireEffect(Lighting, "DepthOfFieldEffect", "StaticDepthOfField")
		applyProperties(dof, profile.DepthOfField)

		local terrain = getTerrain()
		if terrain then
			local cloudLayer = acquireEffect(terrain, "Clouds", "StaticClouds")
			applyProperties(cloudLayer, profile.Clouds)
			applyProperties(terrain, profile.Water)
		end
	end

	function LightingService:SetTime(clockTime: number)
		self.CurrentTime = math.clamp(clockTime, 0, 24) % 24
	end

	function LightingService:Restore()
		if self._cycleJob then
			self._cycleJob.Enabled = false
		end
		if self._staticJob then
			self._staticJob.Enabled = false
		end
		activeStaticProfile = nil
		Disposer:Unbind("B0XazLightingDescendants")
		self._descendantConn = nil

		destroyEffects()
		colorCorrection, bloom, sunRays, atmosphere, depthOfField, clouds = nil, nil, nil, nil, nil, nil

		restoreWorldRemaster()
		restoreSnapshot()
		self.Mode = "Off"
	end

	function LightingService:ApplyStatic(modeName: string)
		local profile = STATIC_PROFILES[modeName]
		if not profile then return end

		takeSnapshot()
		activeStaticProfile = profile

		buildStaticEffects(profile)
		assertStaticLighting()

		if StateStore:Get("Lighting.Vignette") == true then
			createVignette()
		end

		if self._staticJob then
			self._staticJob.Enabled = true
		end
		self.Mode = modeName
	end

	function LightingService:ApplyDynamic()
		takeSnapshot()
		self.CurrentTime = tonumber(StateStore:Get("Lighting.TimeOfDay")) or 6

		applyEngineQuality()
		buildDynamicEffects()
		applyWorldRemaster()

		if StateStore:Get("Lighting.Vignette") == true then
			createVignette()
		end

		if self._cycleJob then
			self._cycleJob.Enabled = true
		end
		self.Mode = "Dynamic"
	end

	function LightingService:SetMode(mode: string)
		local target = "Off"
		if mode == "Dynamic" or STATIC_PROFILES[mode] then
			target = mode
		end
		if target == self.Mode then return end

		-- Always fully restore before applying a different mode so two
		-- presets can never leave half of each other's state behind.
		self:Restore()

		if target == "Dynamic" then
			self:ApplyDynamic()
		elseif STATIC_PROFILES[target] then
			self:ApplyStatic(target)
		end

		if target ~= "Off" and StateStore:Get("Visuals.Fullbright") == true then
			notify("Lighting", "Fullbright is overriding the cinematic preset.", "Warning")
		end
	end

	function LightingService:Initialize()
		self._cycleJob = TaskScheduler:RegisterRender("CinematicLighting", 30, stepCycle)
		self._cycleJob.Enabled = false

		self._staticJob = TaskScheduler:RegisterHeartbeat("StaticLighting", 30, stepStatic)
		self._staticJob.Enabled = false

		Disposer:Add(function()
			self:Restore()
		end)

		StateStore:Observe("Lighting.Mode", function(newMode)
			self:SetMode(tostring(newMode))
		end)

		StateStore:Observe("Lighting.TimeOfDay", function(newTime)
			self:SetTime(tonumber(newTime) or 6)
		end)
		-- The reassert job would pick this up within a second anyway; this
		-- makes dragging the slider feel immediate.
		StateStore:Observe("Lighting.PresetBrightness", function()
			assertStaticLighting()
		end)

		-- Vignette and world remaster can be flipped while a mode is live
		StateStore:Observe("Lighting.Vignette", function(enabled)
			if self.Mode == "Off" then return end
			if enabled == true then
				createVignette()
			else
				destroyVignette()
			end
		end)

		local function reapplyRemaster()
			if self.Mode == "Off" then return end
			Disposer:Unbind("B0XazLightingDescendants")
			restoreWorldRemaster()
			applyWorldRemaster()
		end
		StateStore:Observe("Lighting.RemasterMaterials", reapplyRemaster)
		StateStore:Observe("Lighting.UpgradeMapLights", reapplyRemaster)

		-- Loading a config profile replays the saved mode
		EventBus:Subscribe("StateHydrated", function()
			self:SetTime(tonumber(StateStore:Get("Lighting.TimeOfDay")) or 6)
			self:SetMode(tostring(StateStore:Get("Lighting.Mode") or "Off"))
		end)
	end

	return LightingService
end

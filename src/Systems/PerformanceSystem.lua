local SETTINGS = {
	TARGET_MATERIAL = Enum.Material.SmoothPlastic,
	OPTIMIZED_TERRAIN = {
		Decoration = false,
		WaterWaveSize = 0,
		WaterWaveSpeed = 0,
		WaterReflectance = 0,
		WaterTransparency = 0,
	},
	POST_PROCESSING_EFFECTS = {
		"BloomEffect",
		"BlurEffect",
		"DepthOfFieldEffect",
		"SunRaysEffect",
		"ColorCorrectionEffect",
	},
	PARTICLE_CLASSES = {
		ParticleEmitter = true,
		Trail = true,
		Smoke = true,
		Fire = true,
		Sparkles = true,
	},
}

return function(Context)
	local Workspace = game:GetService("Workspace")
	local Lighting = game:GetService("Lighting")

	local FeatureConfig = (Context and Context.FeatureConfig) or {}
	local Connections = (Context and Context.Connections) or {}

	if not FeatureConfig.Performance then
		FeatureConfig.Performance = {}
	end

	local PerformanceSystem = {}

	local textureCache = setmetatable({}, { __mode = "k" })
	local materialCache = setmetatable({}, { __mode = "k" })
	local shadowCache = setmetatable({}, { __mode = "k" })
	local particleCache = setmetatable({}, { __mode = "k" })
	local lightingEffectsCache = setmetatable({}, { __mode = "k" })
	local terrainDefaults = nil

	local function getCamera()
		return Workspace.CurrentCamera
	end

	local function getTerrain()
		return Workspace:FindFirstChildOfClass("Terrain")
	end

	local function isParticleEmitter(instance)
		return SETTINGS.PARTICLE_CLASSES[instance.ClassName] ~= nil
	end

	function PerformanceSystem.SetNoTextures(enabled)
		FeatureConfig.Performance.NoTextures = enabled
		if enabled then
			for _, obj in ipairs(Workspace:GetDescendants()) do
				if obj:IsA("Decal") or obj:IsA("Texture") then
					if textureCache[obj] == nil then
						textureCache[obj] = obj.Texture
					end
					obj.Texture = ""
				end
			end
		else
			for obj, originalTexture in pairs(textureCache) do
				if obj and obj.Parent then
					pcall(function()
						obj.Texture = originalTexture
					end)
				end
			end
			table.clear(textureCache)
		end
	end

	function PerformanceSystem.SetLowMaterials(enabled)
		FeatureConfig.Performance.LowMaterials = enabled
		if enabled then
			for _, obj in ipairs(Workspace:GetDescendants()) do
				if obj:IsA("BasePart") and not obj:IsA("Terrain") then
					if materialCache[obj] == nil then
						materialCache[obj] = obj.Material
					end
					obj.Material = SETTINGS.TARGET_MATERIAL
				end
			end
		else
			for obj, originalMat in pairs(materialCache) do
				if obj and obj.Parent then
					pcall(function()
						obj.Material = originalMat
					end)
				end
			end
			table.clear(materialCache)
		end
	end

	function PerformanceSystem.SetOptimizeTerrain(enabled)
		FeatureConfig.Performance.OptimizeTerrain = enabled
		local terrain = getTerrain()
		if not terrain then return end

		if enabled then
			if not terrainDefaults then
				terrainDefaults = {
					Decoration = terrain.Decoration,
					WaterWaveSize = terrain.WaterWaveSize,
					WaterWaveSpeed = terrain.WaterWaveSpeed,
					WaterReflectance = terrain.WaterReflectance,
					WaterTransparency = terrain.WaterTransparency,
				}
			end
			for prop, val in pairs(SETTINGS.OPTIMIZED_TERRAIN) do
				pcall(function()
					terrain[prop] = val
				end)
			end
		else
			if terrainDefaults then
				for prop, val in pairs(terrainDefaults) do
					pcall(function()
						terrain[prop] = val
					end)
				end
			end
		end
	end

	local function processPostProcessingContainer(container, enabled)
		if not container then return end
		for _, className in ipairs(SETTINGS.POST_PROCESSING_EFFECTS) do
			for _, child in ipairs(container:GetChildren()) do
				if child:IsA(className) then
					if enabled then
						if lightingEffectsCache[child] == nil then
							lightingEffectsCache[child] = child.Enabled
						end
						child.Enabled = false
					end
				end
			end
		end
	end

	function PerformanceSystem.SetNoPostProcessing(enabled)
		FeatureConfig.Performance.NoPostProcessing = enabled
		if enabled then
			processPostProcessingContainer(Lighting, true)
			processPostProcessingContainer(getCamera(), true)
		else
			for effect, originalState in pairs(lightingEffectsCache) do
				if effect and effect.Parent then
					pcall(function()
						effect.Enabled = originalState
					end)
				end
			end
			table.clear(lightingEffectsCache)
		end
	end

	function PerformanceSystem.SetNoShadows(enabled)
		FeatureConfig.Performance.NoShadows = enabled
		Lighting.GlobalShadows = not enabled
		if enabled then
			for _, obj in ipairs(Workspace:GetDescendants()) do
				if obj:IsA("BasePart") then
					if shadowCache[obj] == nil then
						shadowCache[obj] = obj.CastShadow
					end
					obj.CastShadow = false
				end
			end
		else
			for obj, originalCast in pairs(shadowCache) do
				if obj and obj.Parent then
					pcall(function()
						obj.CastShadow = originalCast
					end)
				end
			end
			table.clear(shadowCache)
		end
	end

	function PerformanceSystem.SetNoParticles(enabled)
		FeatureConfig.Performance.NoParticles = enabled
		if enabled then
			for _, obj in ipairs(Workspace:GetDescendants()) do
				if isParticleEmitter(obj) then
					if particleCache[obj] == nil then
						particleCache[obj] = obj.Enabled
					end
					obj.Enabled = false
				end
			end
		else
			for obj, originalState in pairs(particleCache) do
				if obj and obj.Parent then
					pcall(function()
						obj.Enabled = originalState
					end)
				end
			end
			table.clear(particleCache)
		end
	end

	local function onDescendantAdded(descendant)
		local perfConfig = FeatureConfig.Performance
		if not perfConfig then return end

		if perfConfig.NoTextures and (descendant:IsA("Decal") or descendant:IsA("Texture")) then
			if textureCache[descendant] == nil then
				textureCache[descendant] = descendant.Texture
			end
			descendant.Texture = ""
		end

		if descendant:IsA("BasePart") then
			if perfConfig.LowMaterials and not descendant:IsA("Terrain") then
				if materialCache[descendant] == nil then
					materialCache[descendant] = descendant.Material
				end
				descendant.Material = SETTINGS.TARGET_MATERIAL
			end
			if perfConfig.NoShadows then
				if shadowCache[descendant] == nil then
					shadowCache[descendant] = descendant.CastShadow
				end
				descendant.CastShadow = false
			end
		end

		if perfConfig.NoParticles and isParticleEmitter(descendant) then
			if particleCache[descendant] == nil then
				particleCache[descendant] = descendant.Enabled
			end
			descendant.Enabled = false
		end
	end

	if Connections and Connections.Add then
		Connections.Add(Workspace.DescendantAdded:Connect(function(descendant)
			task.defer(onDescendantAdded, descendant)
		end))
	end

	return PerformanceSystem
end

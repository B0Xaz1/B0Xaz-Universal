-- // src/Systems/PerformanceSystem.lua
return function(Context)
	local Workspace = game:GetService("Workspace")
	local Lighting = game:GetService("Lighting")
	local FeatureConfig = Context.FeatureConfig or {}
	local Connections = Context.Connections or {}

	if not FeatureConfig.Performance then FeatureConfig.Performance = {} end

	local PerformanceSystem = {}
	local textureCache = setmetatable({}, { __mode = "k" })
	local materialCache = setmetatable({}, { __mode = "k" })
	local shadowCache = setmetatable({}, { __mode = "k" })
	local particleCache = setmetatable({}, { __mode = "k" })
	local effectCache = setmetatable({}, { __mode = "k" })
	local terrainDefaults = nil

	local PARTICLES = {
		ParticleEmitter = true, Trail = true, Smoke = true, Fire = true, Sparkles = true,
	}
	local FX = { "BloomEffect", "BlurEffect", "DepthOfFieldEffect", "SunRaysEffect", "ColorCorrectionEffect" }

	function PerformanceSystem.SetNoTextures(enabled)
		FeatureConfig.Performance.NoTextures = enabled
		if enabled then
			for _, obj in ipairs(Workspace:GetDescendants()) do
				if obj:IsA("Decal") or obj:IsA("Texture") then
					if textureCache[obj] == nil then textureCache[obj] = obj.Texture end
					obj.Texture = ""
				end
			end
		else
			for obj, tex in pairs(textureCache) do
				if obj and obj.Parent then pcall(function() obj.Texture = tex end) end
			end
			table.clear(textureCache)
		end
	end

	function PerformanceSystem.SetLowMaterials(enabled)
		FeatureConfig.Performance.LowMaterials = enabled
		if enabled then
			for _, obj in ipairs(Workspace:GetDescendants()) do
				if obj:IsA("BasePart") and not obj:IsA("Terrain") then
					if materialCache[obj] == nil then materialCache[obj] = obj.Material end
					obj.Material = Enum.Material.SmoothPlastic
				end
			end
		else
			for obj, mat in pairs(materialCache) do
				if obj and obj.Parent then pcall(function() obj.Material = mat end) end
			end
			table.clear(materialCache)
		end
	end

	function PerformanceSystem.SetOptimizeTerrain(enabled)
		FeatureConfig.Performance.OptimizeTerrain = enabled
		local terrain = Workspace:FindFirstChildOfClass("Terrain")
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
			pcall(function()
				terrain.Decoration = false
				terrain.WaterWaveSize = 0
				terrain.WaterWaveSpeed = 0
				terrain.WaterReflectance = 0
				terrain.WaterTransparency = 0
			end)
		elseif terrainDefaults then
			for k, v in pairs(terrainDefaults) do
				pcall(function() terrain[k] = v end)
			end
		end
	end

	function PerformanceSystem.SetNoPostProcessing(enabled)
		FeatureConfig.Performance.NoPostProcessing = enabled
		local function process(container)
			if not container then return end
			for _, className in ipairs(FX) do
				for _, child in ipairs(container:GetChildren()) do
					if child:IsA(className) then
						if enabled then
							if effectCache[child] == nil then effectCache[child] = child.Enabled end
							child.Enabled = false
						end
					end
				end
			end
		end
		if enabled then
			process(Lighting)
			process(Workspace.CurrentCamera)
		else
			for fx, state in pairs(effectCache) do
				if fx and fx.Parent then pcall(function() fx.Enabled = state end) end
			end
			table.clear(effectCache)
		end
	end

	function PerformanceSystem.SetNoShadows(enabled)
		FeatureConfig.Performance.NoShadows = enabled
		Lighting.GlobalShadows = not enabled
		if enabled then
			for _, obj in ipairs(Workspace:GetDescendants()) do
				if obj:IsA("BasePart") then
					if shadowCache[obj] == nil then shadowCache[obj] = obj.CastShadow end
					obj.CastShadow = false
				end
			end
		else
			for obj, cast in pairs(shadowCache) do
				if obj and obj.Parent then pcall(function() obj.CastShadow = cast end) end
			end
			table.clear(shadowCache)
		end
	end

	function PerformanceSystem.SetNoParticles(enabled)
		FeatureConfig.Performance.NoParticles = enabled
		if enabled then
			for _, obj in ipairs(Workspace:GetDescendants()) do
				if PARTICLES[obj.ClassName] then
					if particleCache[obj] == nil then particleCache[obj] = obj.Enabled end
					obj.Enabled = false
				end
			end
		else
			for obj, state in pairs(particleCache) do
				if obj and obj.Parent then pcall(function() obj.Enabled = state end) end
			end
			table.clear(particleCache)
		end
	end

	if Connections and Connections.Add then
		Connections.Add(Workspace.DescendantAdded:Connect(function(d)
			task.defer(function()
				local p = FeatureConfig.Performance
				if not p then return end
				if p.NoTextures and (d:IsA("Decal") or d:IsA("Texture")) then
					if textureCache[d] == nil then textureCache[d] = d.Texture end
					d.Texture = ""
				end
				if d:IsA("BasePart") then
					if p.LowMaterials and not d:IsA("Terrain") then
						if materialCache[d] == nil then materialCache[d] = d.Material end
						d.Material = Enum.Material.SmoothPlastic
					end
					if p.NoShadows then
						if shadowCache[d] == nil then shadowCache[d] = d.CastShadow end
						d.CastShadow = false
					end
				end
				if p.NoParticles and PARTICLES[d.ClassName] then
					if particleCache[d] == nil then particleCache[d] = d.Enabled end
					d.Enabled = false
				end
			end)
		end))
	end

	return PerformanceSystem
end

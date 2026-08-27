local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local SMOOTH_PLASTIC = Enum.Material.SmoothPlastic
local PARTICLE_CLASSES: { [string]: boolean } = {
	ParticleEmitter = true,
	Trail = true,
	Smoke = true,
	Fire = true,
	Sparkles = true,
}

local POST_FX_CLASSES: { [string]: boolean } = {
	BloomEffect = true,
	BlurEffect = true,
	DepthOfFieldEffect = true,
	SunRaysEffect = true,
	ColorCorrectionEffect = true,
}

return function(services: any)
	local StateStore = services:Get("StateStore")
	local Disposer = services:Get("Disposer")
	local EventBus = services:Get("EventBus")

	local OptimizerService = {
		_textureCache = {} :: { [Instance]: string },
		_materialCache = {} :: { [BasePart]: Enum.Material },
		_shadowCache = {} :: { [BasePart]: boolean },
		_particleCache = {} :: { [Instance]: boolean },
		_postFxCache = {} :: { [Instance]: boolean },
		_originalGlobalShadows = Lighting.GlobalShadows,
		_terrainDefaults = nil :: { [string]: any }?,
	}

	-- Every mutation path (initial scan or late-arriving object) goes
	-- through this function so originals are always cached before they are
	-- changed; skipping the cache would make restore incomplete.
	local function processInstance(obj: Instance, perf: { [string]: any })
		if perf.NoTextures == true and (obj:IsA("Decal") or obj:IsA("Texture")) then
			local decal = obj :: Decal
			if self._textureCache[decal] == nil then
				self._textureCache[decal] = decal.Texture
			end
			decal.Texture = ""
		end

		if obj:IsA("BasePart") and not obj:IsA("Terrain") then
			local part = obj :: BasePart
			if perf.LowMaterials == true then
				if self._materialCache[part] == nil then
					self._materialCache[part] = part.Material
				end
				part.Material = SMOOTH_PLASTIC
			end
			if perf.NoShadows == true then
				if self._shadowCache[part] == nil then
					self._shadowCache[part] = part.CastShadow
				end
				part.CastShadow = false
			end
		end

		if perf.NoParticles == true and PARTICLE_CLASSES[obj.ClassName] then
			local emitter = obj :: any
			if self._particleCache[emitter] == nil then
				self._particleCache[emitter] = emitter.Enabled
			end
			emitter.Enabled = false
		end
	end

	function OptimizerService:ApplyAllOptimizations()
		local perf = StateStore:Get("Performance")
		if not perf then return end

		if perf.NoShadows == true then
			Lighting.GlobalShadows = false
		else
			Lighting.GlobalShadows = self._originalGlobalShadows
		end

		local allDescendants = Workspace:GetDescendants()
		for i = 1, #allDescendants do
			processInstance(allDescendants[i], perf)
		end

		self:SetOptimizeTerrain(perf.OptimizeTerrain == true)
		self:SetNoPostProcessing(perf.NoPostProcessing == true)
	end

	function OptimizerService:SetOptimizeTerrain(enabled: boolean)
		local terrain = Workspace:FindFirstChildOfClass("Terrain")
		if not terrain then return end

		if enabled then
			if not self._terrainDefaults then
				self._terrainDefaults = {
					Decoration = terrain.Decoration,
					WaterWaveSize = terrain.WaterWaveSize,
					WaterWaveSpeed = terrain.WaterWaveSpeed,
					WaterReflectance = terrain.WaterReflectance,
					WaterTransparency = terrain.WaterTransparency,
				}
			end
			terrain.Decoration = false
			terrain.WaterWaveSize = 0
			terrain.WaterWaveSpeed = 0
			terrain.WaterReflectance = 0
			terrain.WaterTransparency = 0
		elseif self._terrainDefaults then
			local terrainAny = terrain :: any
			for prop, val in pairs(self._terrainDefaults) do
				pcall(function() terrainAny[prop] = val end)
			end
			self._terrainDefaults = nil
		end
	end

	function OptimizerService:SetNoPostProcessing(enabled: boolean)
		local containers = { Lighting, Workspace.CurrentCamera }
		for _, container in ipairs(containers) do
			if container then
				for _, child in ipairs(container:GetChildren()) do
					if POST_FX_CLASSES[child.ClassName] then
						local fx = child :: any
						if enabled then
							if self._postFxCache[fx] == nil then
								self._postFxCache[fx] = fx.Enabled
							end
							fx.Enabled = false
						else
							if self._postFxCache[fx] ~= nil then
								fx.Enabled = self._postFxCache[fx]
							end
						end
					end
				end
			end
		end
		if not enabled then
			table.clear(self._postFxCache)
		end
	end

	function OptimizerService:RestoreAll()
		for obj, tex in pairs(self._textureCache) do
			if obj and obj.Parent then
				local decal = obj :: Decal
				decal.Texture = tex
			end
		end
		table.clear(self._textureCache)

		for part, mat in pairs(self._materialCache) do
			if part and part.Parent then part.Material = mat end
		end
		table.clear(self._materialCache)

		for part, cast in pairs(self._shadowCache) do
			if part and part.Parent then part.CastShadow = cast end
		end
		table.clear(self._shadowCache)

		for emitter, state in pairs(self._particleCache) do
			if emitter and emitter.Parent then
				local particleEmitter = emitter :: any
				particleEmitter.Enabled = state
			end
		end
		table.clear(self._particleCache)

		Lighting.GlobalShadows = self._originalGlobalShadows
		self:SetOptimizeTerrain(false)
		self:SetNoPostProcessing(false)
	end

	function OptimizerService:Initialize()
		Disposer:Add(function()
			self:RestoreAll()
		end)

		-- Any perf flag that turns off first restores everything, then
		-- re-applies the flags that are still on, so features never fight.
		local function onPerfFlagChanged(enabled: any)
			if enabled then
				self:ApplyAllOptimizations()
			else
				self:RestoreAll()
				self:ApplyAllOptimizations()
			end
		end
		EventBus:Subscribe("StateChanged:Performance.NoTextures", onPerfFlagChanged)
		EventBus:Subscribe("StateChanged:Performance.LowMaterials", onPerfFlagChanged)
		EventBus:Subscribe("StateChanged:Performance.NoShadows", onPerfFlagChanged)
		EventBus:Subscribe("StateChanged:Performance.NoParticles", onPerfFlagChanged)

		EventBus:Subscribe("StateChanged:Performance.OptimizeTerrain", function(enabled)
			self:SetOptimizeTerrain(enabled == true)
		end)
		EventBus:Subscribe("StateChanged:Performance.NoPostProcessing", function(enabled)
			self:SetNoPostProcessing(enabled == true)
		end)

		local descConn = Workspace.DescendantAdded:Connect(function(d: Instance)
			local perf = StateStore:Get("Performance")
			if not perf then return end

			-- Late objects go through the same cached path as the scan so
			-- restore stays lossless for them as well.
			if perf.NoTextures or perf.LowMaterials or perf.NoShadows or perf.NoParticles then
				processInstance(d, perf)
			end
		end)
		Disposer:Add(descConn)
	end

	return OptimizerService
end

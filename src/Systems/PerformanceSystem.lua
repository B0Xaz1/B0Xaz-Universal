-- src/Systems/PerformanceSystem.lua
return function(Context)
    local Workspace = game:GetService("Workspace")
    local Lighting = game:GetService("Lighting")

    local FeatureConfig = Context.FeatureConfig
    local Connections = Context.Connections

    local PerformanceSystem = {}

    local textureCache = setmetatable({}, { __mode = "k" })
    local materialCache = setmetatable({}, { __mode = "k" })
    local lightingEffectsCache = setmetatable({}, { __mode = "k" })
    local terrainDefaults = nil

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
                    pcall(function() obj.Texture = originalTexture end)
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
                    obj.Material = Enum.Material.SmoothPlastic
                end
            end
        else
            for obj, originalMat in pairs(materialCache) do
                if obj and obj.Parent then
                    pcall(function() obj.Material = originalMat end)
                end
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
            terrain.Decoration = false
            terrain.WaterWaveSize = 0
            terrain.WaterWaveSpeed = 0
            terrain.WaterReflectance = 0
            terrain.WaterTransparency = 0
        else
            if terrainDefaults then
                terrain.Decoration = terrainDefaults.Decoration
                terrain.WaterWaveSize = terrainDefaults.WaterWaveSize
                terrain.WaterWaveSpeed = terrainDefaults.WaterWaveSpeed
                terrain.WaterReflectance = terrainDefaults.WaterReflectance
                terrain.WaterTransparency = terrainDefaults.WaterTransparency
            end
        end
    end

    function PerformanceSystem.SetNoPostProcessing(enabled)
        FeatureConfig.Performance.NoPostProcessing = enabled
        local classes = {"BloomEffect", "BlurEffect", "DepthOfFieldEffect", "SunRaysEffect", "ColorCorrectionEffect"}
        local camera = Workspace.CurrentCamera

        if enabled then
            for _, class in ipairs(classes) do
                for _, effect in ipairs(Lighting:GetChildren()) do
                    if effect:IsA(class) then
                        if lightingEffectsCache[effect] == nil then
                            lightingEffectsCache[effect] = effect.Enabled
                        end
                        effect.Enabled = false
                    end
                end
                if camera then
                    for _, effect in ipairs(camera:GetChildren()) do
                        if effect:IsA(class) then
                            if lightingEffectsCache[effect] == nil then
                                lightingEffectsCache[effect] = effect.Enabled
                            end
                            effect.Enabled = false
                        end
                    end
                end
            end
        else
            for effect, originalState in pairs(lightingEffectsCache) do
                if effect and effect.Parent then
                    pcall(function() effect.Enabled = originalState end)
                end
            end
            table.clear(lightingEffectsCache)
        end
    end

    function PerformanceSystem.SetNoShadows(enabled)
        FeatureConfig.Performance.NoShadows = enabled
        Lighting.GlobalShadows = not enabled
        for _, o in ipairs(Workspace:GetDescendants()) do
            if o:IsA("BasePart") then
                o.CastShadow = not enabled
            end
        end
    end

    function PerformanceSystem.SetNoParticles(enabled)
        FeatureConfig.Performance.NoParticles = enabled
        for _, o in ipairs(Workspace:GetDescendants()) do
            if o:IsA("ParticleEmitter") or o:IsA("Trail") or o:IsA("Smoke") or o:IsA("Fire") or o:IsA("Sparkles") then
                pcall(function() o.Enabled = not enabled end)
            end
        end
    end

    Connections.Add(Workspace.DescendantAdded:Connect(function(desc)
        task.defer(function()
            if FeatureConfig.Performance.NoTextures and (desc:IsA("Decal") or desc:IsA("Texture")) then
                if textureCache[desc] == nil then textureCache[desc] = desc.Texture end
                desc.Texture = ""
            end
            if FeatureConfig.Performance.LowMaterials and desc:IsA("BasePart") and not desc:IsA("Terrain") then
                if materialCache[desc] == nil then materialCache[desc] = desc.Material end
                desc.Material = Enum.Material.SmoothPlastic
            end
            if FeatureConfig.Performance.NoShadows and desc:IsA("BasePart") then
                desc.CastShadow = false
            end
            if FeatureConfig.Performance.NoParticles then
                if desc:IsA("ParticleEmitter") or desc:IsA("Trail") or desc:IsA("Smoke") or desc:IsA("Fire") or desc:IsA("Sparkles") then
                    pcall(function() desc.Enabled = false end)
                end
            end
        end)
    end))

    return PerformanceSystem
end

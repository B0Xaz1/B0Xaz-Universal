-- src/Systems/PerformanceSystem.lua
return function(Context)
    local Workspace = game:GetService("Workspace")
    local Lighting = game:GetService("Lighting")
    
    local FeatureConfig = Context.FeatureConfig
    local Connections = Context.Connections

    local PerformanceSystem = {}

    -- Weak-keyed caches to prevent memory leaks when parts are destroyed by the engine
    local textureCache = setmetatable({}, { __mode = "k" })
    local materialCache = setmetatable({}, { __mode = "k" })
    local lightingEffectsCache = setmetatable({}, { __mode = "k" })

    ----------------------------------------------------------------
    -- 1. Texture Optimizer
    ----------------------------------------------------------------
    function PerformanceSystem.SetNoTextures(enabled)
        FeatureConfig.Performance.NoTextures = enabled
        if enabled then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("Decal") or obj:IsA("Texture") then
                    if not textureCache[obj] then
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

    ----------------------------------------------------------------
    -- 2. Material Optimizer (Smooth Plastic Force)
    ----------------------------------------------------------------
    function PerformanceSystem.SetLowMaterials(enabled)
        FeatureConfig.Performance.LowMaterials = enabled
        if enabled then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("BasePart") and not obj:IsA("Terrain") then
                    if not materialCache[obj] then
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

    ----------------------------------------------------------------
    -- 3. Terrain Optimizer
    ----------------------------------------------------------------
    function PerformanceSystem.SetOptimizeTerrain(enabled)
        FeatureConfig.Performance.OptimizeTerrain = enabled
        local terrain = Workspace:FindFirstChildOfClass("Terrain")
        if not terrain then return end

        if enabled then
            terrain.Decoration = false
            terrain.WaterWaveSize = 0
            terrain.WaterWaveSpeed = 0
            terrain.WaterReflectance = 0
            terrain.WaterTransparency = 0
        else
            terrain.Decoration = true
            terrain.WaterWaveSize = 0.15
            terrain.WaterWaveSpeed = 10
            terrain.WaterReflectance = 1
            terrain.WaterTransparency = 1
        end
    end

    ----------------------------------------------------------------
    -- 4. Post-Processing Optimizer
    ----------------------------------------------------------------
    function PerformanceSystem.SetNoPostProcessing(enabled)
        FeatureConfig.Performance.NoPostProcessing = enabled
        local classes = {"BloomEffect", "BlurEffect", "DepthOfFieldEffect", "SunRaysEffect", "ColorCorrectionEffect"}
        
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
                for _, effect in ipairs(Workspace.CurrentCamera:GetChildren()) do
                    if effect:IsA(class) then
                        if lightingEffectsCache[effect] == nil then
                            lightingEffectsCache[effect] = effect.Enabled
                        end
                        effect.Enabled = false
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

    ----------------------------------------------------------------
    -- 5. Part-Level Shadow Optimizations
    ----------------------------------------------------------------
    function PerformanceSystem.SetNoShadows(enabled)
        FeatureConfig.Performance.NoShadows = enabled
        Lighting.GlobalShadows = not enabled
        for _, o in ipairs(Workspace:GetDescendants()) do
            if o:IsA("BasePart") then
                o.CastShadow = not enabled
            end
        end
    end

    ----------------------------------------------------------------
    -- 6. Dynamic Asset Listener (Applies optimization to streaming parts)
    ----------------------------------------------------------------
    Connections.Add(Workspace.DescendantAdded:Connect(function(desc)
        task.defer(function()
            if FeatureConfig.Performance.NoTextures and (desc:IsA("Decal") or desc:IsA("Texture")) then
                if not textureCache[desc] then textureCache[desc] = desc.Texture end
                desc.Texture = ""
            end
            if FeatureConfig.Performance.LowMaterials and desc:IsA("BasePart") and not desc:IsA("Terrain") then
                if not materialCache[desc] then materialCache[desc] = desc.Material end
                desc.Material = Enum.Material.SmoothPlastic
            end
            if FeatureConfig.Performance.NoShadows and desc:IsA("BasePart") then
                desc.CastShadow = false
            end
        end)
    end))

    return PerformanceSystem
end

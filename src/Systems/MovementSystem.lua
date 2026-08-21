-- src/Systems/MovementSystem.lua
return function(Context)
    local RS = game:GetService("RunService")
    local FeatureConfig = Context.FeatureConfig
    local Utils = Context.Utils
    local Connections = Context.Connections

    local MovementSystem = {}

    -- Auto-Bhop: Runs on Stepped (RIGHT BEFORE Roblox calculates physics)
    Connections.Add(RS.Stepped:Connect(function()
        if not FeatureConfig.Movement.Bhop then return end

        local hum = Utils.GetHumanoid()
        if not hum or hum.Health <= 0 then return end

        -- Trigger jump the exact millisecond the feet touch any ground/floor
        if hum.FloorMaterial ~= Enum.Material.Air then
            hum.Jump = true
        end
    end))

    -- CFrame Speed: Runs on RenderStepped for buttery-smooth movement
    Connections.Add(RS.RenderStepped:Connect(function(dt)
        if not FeatureConfig.Movement.CFrameSpeed then return end

        local hum = Utils.GetHumanoid()
        local root = Utils.GetRootPart()
        if not hum or not root or hum.Health <= 0 then return end
        if FeatureConfig.Movement.FlyEnabled then return end

        local moveDir = hum.MoveDirection
        if moveDir.Magnitude < 0.05 then return end

        local speed = FeatureConfig.Movement.CFrameSpeedValue or 50
        root.CFrame = root.CFrame + (moveDir * speed * dt)
    end))

    return MovementSystem
end

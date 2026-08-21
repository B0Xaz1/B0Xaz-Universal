-- src/Systems/MovementSystem.lua
return function(Context)
    local RS = game:GetService("RunService")
    local FeatureConfig = Context.FeatureConfig
    local Utils = Context.Utils
    local Connections = Context.Connections

    local MovementSystem = {}
    local lastJumpTime = 0

    -- Auto-Bhop: Runs on Stepped (Pre-Physics)
    Connections.Add(RS.Stepped:Connect(function()
        if not FeatureConfig.Movement.Bhop then return end

        local hum = Utils.GetHumanoid()
        if not hum or hum.Health <= 0 then return end

        -- Cooldown check (250ms) to ensure character has physically left the ground
        if tick() - lastJumpTime < 0.25 then return end

        local state = hum:GetState()
        local isGrounded = (hum.FloorMaterial ~= Enum.Material.Air) 
            and (state ~= Enum.HumanoidStateType.Jumping) 
            and (state ~= Enum.HumanoidStateType.Freefall)

        if isGrounded then
            lastJumpTime = tick()
            hum.Jump = true
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end))

    -- CFrame Speed Override: Runs on RenderStepped
    Connections.Add(RS.RenderStepped:Connect(function(dt)
        if not FeatureConfig.Movement.CFrameSpeed then return end

        local hum = Utils.GetHumanoid()
        local root = Utils.GetRootPart()
        if not hum or not root or hum.Health <= 0 then return end
        if FeatureConfig.Movement.FlyEnabled then return end

        local moveDir = hum.MoveDirection
        if moveDir.Magnitude < 0.05 then return end

        local targetSpeed = FeatureConfig.Movement.CFrameSpeedValue or 50
        local currentWalkSpeed = hum.WalkSpeed

        -- Calculate the exact delta needed to match the slider value
        local deltaSpeed = targetSpeed - currentWalkSpeed
        root.CFrame = root.CFrame + (moveDir * deltaSpeed * dt)
    end))

    return MovementSystem
end

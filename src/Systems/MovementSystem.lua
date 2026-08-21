-- src/Systems/MovementSystem.lua
return function(Context)
    local FeatureConfig = Context.FeatureConfig
    local Utils = Context.Utils

    local MovementSystem = {}
    local lastJumpTime = 0

    function MovementSystem.UpdateBhop()
        if not FeatureConfig.Movement or not FeatureConfig.Movement.Bhop then return end

        local hum = Utils.GetHumanoid()
        if not hum or hum.Health <= 0 then return end

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
    end

    function MovementSystem.UpdateCFrameSpeed(dt)
        if not FeatureConfig.Movement or not FeatureConfig.Movement.CFrameSpeed then return end

        local hum = Utils.GetHumanoid()
        local root = Utils.GetRootPart()
        if not hum or not root or hum.Health <= 0 then return end
        if FeatureConfig.Movement.FlyEnabled then return end

        local moveDir = hum.MoveDirection
        if moveDir.Magnitude < 0.05 then return end

        local targetSpeed = FeatureConfig.Movement.CFrameSpeedValue or 50
        local currentWalkSpeed = hum.WalkSpeed
        local deltaSpeed = targetSpeed - currentWalkSpeed

        root.CFrame = root.CFrame + (moveDir * deltaSpeed * (dt or 0.016))
    end

    function MovementSystem.Update(dt)
        MovementSystem.UpdateBhop()
        MovementSystem.UpdateCFrameSpeed(dt)
    end

    return MovementSystem
end

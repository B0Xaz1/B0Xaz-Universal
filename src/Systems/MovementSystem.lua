-- src/Systems/MovementSystem.lua
return function(Context)
    local FeatureConfig = Context.FeatureConfig
    local Utils = Context.Utils

    local MovementSystem = {}

    function MovementSystem.UpdateCFrameSpeed(dt)
        if not FeatureConfig.Movement.CFrameSpeed then return end

        local hum = Utils.GetHumanoid()
        local root = Utils.GetRootPart()
        if not hum or not root then return end
        if FeatureConfig.Movement.FlyEnabled then return end

        local moveDir = hum.MoveDirection
        if moveDir.Magnitude < 0.05 then return end

        local speed = FeatureConfig.Movement.CFrameSpeedValue or 50
        root.CFrame = root.CFrame + moveDir * speed * dt
    end

    function MovementSystem.UpdateBhop()
        if not FeatureConfig.Movement.Bhop then return end

        local hum = Utils.GetHumanoid()
        if not hum or hum.Health <= 0 then return end

        local state = hum:GetState()

        -- Only trigger when touching the ground (not in mid-air)
        if hum.FloorMaterial ~= Enum.Material.Air 
           and state ~= Enum.HumanoidStateType.Jumping 
           and state ~= Enum.HumanoidStateType.Freefall then
            
            hum.Jump = true
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end

    function MovementSystem.Update(dt)
        MovementSystem.UpdateCFrameSpeed(dt)
        MovementSystem.UpdateBhop()
    end

    return MovementSystem
end

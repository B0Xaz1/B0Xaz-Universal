-- src/Systems/MovementSystem.lua
return function(Context)
    local UIS = game:GetService("UserInputService")
    local Workspace = game:GetService("Workspace")

    local FeatureConfig = Context.FeatureConfig
    local Utils = Context.Utils
    local Connections = Context.Connections

    local MovementSystem = {}
    local _bhopConn = nil

    function MovementSystem.UpdateCFrameSpeed(dt)
        if not FeatureConfig.Movement.CFrameSpeed then return end

        local hum = Utils.GetHumanoid()
        local root = Utils.GetRootPart()
        if not hum or not root then return end
        if FeatureConfig.Movement.FlyEnabled then return end -- don't fight fly

        local moveDir = hum.MoveDirection
        if moveDir.Magnitude < 0.05 then return end

        local speed = FeatureConfig.Movement.CFrameSpeedValue or 50
        -- Extra CFrame push on top of normal walk (bypass-style)
        root.CFrame = root.CFrame + moveDir * speed * dt
    end

    function MovementSystem.UpdateBhop()
        if not FeatureConfig.Movement.Bhop then return end

        local hum = Utils.GetHumanoid()
        if not hum then return end

        -- Hold Space = auto hop on landing
        local holdingJump = UIS:IsKeyDown(Enum.KeyCode.Space)
        if not holdingJump then return end

        if hum.FloorMaterial ~= Enum.Material.Air then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end

    function MovementSystem.Update(dt)
        MovementSystem.UpdateCFrameSpeed(dt)
        MovementSystem.UpdateBhop()
    end

    -- Optional: also fire on JumpRequest for snappier bhop
    function MovementSystem.BindBhopInput()
        if _bhopConn then return end
        _bhopConn = Connections.Add(UIS.JumpRequest:Connect(function()
            if not FeatureConfig.Movement.Bhop then return end
            local hum = Utils.GetHumanoid()
            if hum then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end))
    end

    MovementSystem.BindBhopInput()

    return MovementSystem
end

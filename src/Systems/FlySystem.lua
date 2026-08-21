-- src/Systems/FlySystem.lua
return function(Context)
    local UIS = game:GetService("UserInputService")
    local Workspace = game:GetService("Workspace")
    local Camera = Workspace.CurrentCamera
    local IsMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled

    local FeatureConfig = Context.FeatureConfig
    local State = Context.State
    local Utils = Context.Utils

    local FlySystem = {}

    function FlySystem.Cleanup()
        if State.FlyBodyVelocity then
            pcall(function() State.FlyBodyVelocity:Destroy() end)
            State.FlyBodyVelocity = nil
        end
        if State.FlyBodyGyro then
            pcall(function() State.FlyBodyGyro:Destroy() end)
            State.FlyBodyGyro = nil
        end
    end

    function FlySystem.Start()
        if FeatureConfig.Movement.FlyEnabled then return end
        local hum, root = Utils.GetHumanoid(), Utils.GetRootPart()
        if not hum or not root then return end
        
        FlySystem.Cleanup()
        FeatureConfig.Movement.FlyEnabled = true

        local bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.one * 1e5
        bv.Velocity = Vector3.zero
        bv.Parent = root
        State.FlyBodyVelocity = bv

        local bg = Instance.new("BodyGyro")
        bg.MaxTorque = Vector3.one * 1e5
        bg.D = 50
        bg.P = 1000
        bg.CFrame = root.CFrame
        bg.Parent = root
        State.FlyBodyGyro = bg

        hum.PlatformStand = true
        hum.AutoRotate = false
    end

    function FlySystem.Stop()
        if not FeatureConfig.Movement.FlyEnabled then return end
        FeatureConfig.Movement.FlyEnabled = false
        FlySystem.Cleanup()

        local hum = Utils.GetHumanoid()
        local root = Utils.GetRootPart()
        if hum then
            hum.PlatformStand = false
            hum.AutoRotate = true
        end
        if root then
            pcall(function()
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
            end)
        end
    end

    function FlySystem.Update()
        if not FeatureConfig.Movement.FlyEnabled then return end
        local bv, bg = State.FlyBodyVelocity, State.FlyBodyGyro
        if not bv or not bv.Parent or not bg or not bg.Parent then
            FlySystem.Stop()
            return
        end
        local root = Utils.GetRootPart()
        if not root then
            FlySystem.Stop()
            return
        end

        bg.CFrame = Camera.CFrame
        local move = Vector3.zero

        if not IsMobile then
            if UIS:IsKeyDown(Enum.KeyCode.W) then move = move + Camera.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.S) then move = move - Camera.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.A) then move = move - Camera.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D) then move = move + Camera.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.yAxis end
            if UIS:IsKeyDown(Enum.KeyCode.LeftShift) and not FeatureConfig.Movement.SprintEnabled then
                move = move - Vector3.yAxis
            end
        else
            local hum = Utils.GetHumanoid()
            if hum and hum.MoveDirection.Magnitude > 0.1 then
                local fwd = Vector3.new(Camera.CFrame.LookVector.X, 0, Camera.CFrame.LookVector.Z)
                local right = Vector3.new(Camera.CFrame.RightVector.X, 0, Camera.CFrame.RightVector.Z)
                if fwd.Magnitude > 0 then fwd = fwd.Unit end
                if right.Magnitude > 0 then right = right.Unit end
                move = fwd * -hum.MoveDirection.Z + right * hum.MoveDirection.X
            end
            if FeatureConfig.Movement.MobileFlyUp then move = move + Vector3.yAxis end
            if FeatureConfig.Movement.MobileFlyDown then move = move - Vector3.yAxis end
        end

        bv.Velocity = move.Magnitude > 0 and (move.Unit * FeatureConfig.Movement.FlySpeed) or Vector3.zero
    end

    return FlySystem
end

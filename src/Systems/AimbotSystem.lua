-- src/Systems/AimbotSystem.lua
return function(Context)
    local Players = game:GetService("Players")
    local UIS = game:GetService("UserInputService")
    local Workspace = game:GetService("Workspace")
    local LocalPlayer = Players.LocalPlayer
    local Camera = Workspace.CurrentCamera

    local FeatureConfig = Context.FeatureConfig
    local State = Context.State
    local CONFIG = Context.CONFIG
    local Utils = Context.Utils

    local AimbotSystem = {}
    local _lastAimScreenPos = nil

    function AimbotSystem.EvaluateTarget(model, playerRef)
        if not model or not model.Parent or model == Utils.GetCharacter() then return nil end
        local hum = model:FindFirstChildOfClass("Humanoid")
        local root = model:FindFirstChild("HumanoidRootPart")
        if not hum or not root or hum.Health <= 0 then return nil end
        if playerRef and FeatureConfig.Aimbot.TeamCheck and Utils.SameTeam(playerRef) then return nil end

        local part = model:FindFirstChild(FeatureConfig.Aimbot.Hitpart) or root
        local myRoot = Utils.GetRootPart()
        if myRoot and (myRoot.Position - part.Position).Magnitude > FeatureConfig.Aimbot.MaxDistance then return nil end

        local sp, onScreen = Utils.WorldToScreen(part.Position)
        if not onScreen then return nil end

        local dist2d = (Utils.GetMousePosition() - sp).Magnitude
        if dist2d > FeatureConfig.Aimbot.FOV.Size then return nil end
        if FeatureConfig.Aimbot.VisCheck and not Utils.IsVisible(part) then return nil end

        return {
            model = model,
            player = playerRef,
            name = playerRef and (playerRef.DisplayName or playerRef.Name) or model.Name,
            dist2d = dist2d
        }
    end

    function AimbotSystem.GetClosestTarget()
        local closest, closestDist = nil, math.huge
        if FeatureConfig.Aimbot.LockNPC then
            for _, obj in ipairs(Workspace:GetChildren()) do
                if obj:IsA("Model") and obj ~= Utils.GetCharacter() then
                    local pr = Utils.FindPlayerFromModel(obj)
                    if pr ~= LocalPlayer then
                        local t = AimbotSystem.EvaluateTarget(obj, pr)
                        if t and t.dist2d < closestDist then
                            closestDist = t.dist2d
                            closest = t
                        end
                    end
                end
            end
        else
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    local t = AimbotSystem.EvaluateTarget(p.Character, p)
                    if t and t.dist2d < closestDist then
                        closestDist = t.dist2d
                        closest = t
                    end
                end
            end
        end
        return closest
    end

    function AimbotSystem.LockOn()
        local t = AimbotSystem.GetClosestTarget()
        if not t then return false end
        State.AimTarget = t
        State.AimLocked = true
        State.AimSettleCounter = 0
        _lastAimScreenPos = nil
        return true
    end

    function AimbotSystem.LockOff()
        State.AimLocked = false
        State.AimTarget = nil
        State.AimHoldActive = false
        State.AimSettleCounter = 0
        _lastAimScreenPos = nil
    end

    function AimbotSystem.UpdateAim()
        if not FeatureConfig.Aimbot.Enabled then return end
        if FeatureConfig.Aimbot.LockMode == "Hold" and not State.AimHoldActive then
            if State.AimLocked then AimbotSystem.LockOff() end
            return
        end
        if not State.AimLocked or not State.AimTarget then return end

        local td = State.AimTarget
        if not td or not td.model or not td.model.Parent then AimbotSystem.LockOff(); return end

        local char = td.model
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then AimbotSystem.LockOff(); return end

        local partName = (hum.FloorMaterial == Enum.Material.Air) and FeatureConfig.Aimbot.AirHitpart or FeatureConfig.Aimbot.Hitpart
        local hitpart = char:FindFirstChild(partName) or char:FindFirstChild("HumanoidRootPart")
        if not hitpart then return end

        local vel = hitpart.AssemblyLinearVelocity
        local predPos = hitpart.Position + Vector3.new(
            vel.X * FeatureConfig.Aimbot.Prediction.Horizontal,
            vel.Y * FeatureConfig.Aimbot.Prediction.Vertical,
            vel.Z * FeatureConfig.Aimbot.Prediction.Horizontal
        )

        if FeatureConfig.Aimbot.ShakeIntensity > 0 then
            local s = FeatureConfig.Aimbot.ShakeIntensity / 10
            predPos = predPos + Vector3.new((math.random() * 2 - 1) * s, (math.random() * 2 - 1) * s, 0)
        end

        local sp, onScreen, depth = Utils.WorldToScreen(predPos)
        if not onScreen or depth <= 0 then return end

        local mousePos = UIS:GetMouseLocation()
        if not _lastAimScreenPos then _lastAimScreenPos = mousePos end
        _lastAimScreenPos = _lastAimScreenPos:Lerp(sp, 0.2)

        local rawDelta = _lastAimScreenPos - mousePos
        if rawDelta.Magnitude < CONFIG.AIM_DEADZONE then return end

        local sm = math.max(FeatureConfig.Aimbot.Smoothness, CONFIG.AIM_MIN_SMOOTHNESS)
        local step = rawDelta / sm
        if step.Magnitude > CONFIG.AIM_MAX_STEP then step = step.Unit * CONFIG.AIM_MAX_STEP end

        local moved = false
        if mousemoverel then
            moved = pcall(function() mousemoverel(step.X, step.Y) end)
        end
        if not moved then
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, predPos), math.min(1, 1 / math.max(sm, 1)))
        end
    end

    function AimbotSystem.UpdateTriggerbot()
        if not FeatureConfig.Aimbot.Triggerbot.Enabled or not FeatureConfig.Aimbot.Enabled then return end

        local mousePos = Utils.GetMousePosition()
        for _, p in ipairs(Players:GetPlayers()) do
            if p == LocalPlayer then continue end
            if FeatureConfig.Aimbot.TeamCheck and Utils.SameTeam(p) then continue end
            if not Utils.IsAlive(p) then continue end

            local char = p.Character
            if not char then continue end
            for _, part in ipairs(char:GetChildren()) do
                if not part:IsA("BasePart") then continue end
                local sp, onScreen, depth = Utils.WorldToScreen(part.Position)
                if not onScreen or depth <= 0 then continue end
                if (mousePos - sp).Magnitude < 14 then
                    task.delay(FeatureConfig.Aimbot.Triggerbot.Delay, function()
                        if not FeatureConfig.Aimbot.Triggerbot.Enabled then return end
                        if mouse1click then
                            mouse1click()
                        else
                            local vui = game:GetService("VirtualInputManager")
                            pcall(function()
                                vui:SendMouseButtonEvent(0, 0, 0, true, game, 1)
                                task.wait(0.02)
                                vui:SendMouseButtonEvent(0, 0, 0, false, game, 1)
                            end)
                        end
                    end)
                    return
                end
            end
        end
    end

    return AimbotSystem
end

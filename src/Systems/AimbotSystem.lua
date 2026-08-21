-- src/Systems/AimbotSystem.lua
return function(Context)
    local RunService = game:GetService("RunService")
    local Workspace = game:GetService("Workspace")
    local Players = game:GetService("Players")
    local UserInputService = game:GetService("UserInputService")

    local LocalPlayer = Players.LocalPlayer
    local Camera = Workspace.CurrentCamera

    local FeatureConfig = Context.FeatureConfig
    local State = Context.State
    local Utils = Context.Utils
    local Connections = Context.Connections

    local TargetPlayer = nil
    local ActiveHeldInputs = {}

    -- Rig limb definitions
    local R6Parts = {
        ["Head"] = "Head",
        ["Torso"] = "Torso",
        ["LeftArm"] = "Left Arm",
        ["RightArm"] = "Right Arm",
        ["LeftLeg"] = "Left Leg",
        ["RightLeg"] = "Right Leg",
        ["Root"] = "HumanoidRootPart",
    }

    local R15Parts = {
        ["Head"] = "Head",
        ["Torso"] = "UpperTorso",
        ["LowerTorso"] = "LowerTorso",
        ["LeftUpperArm"] = "LeftUpperArm",
        ["LeftLowerArm"] = "LeftLowerArm",
        ["LeftHand"] = "LeftHand",
        ["RightUpperArm"] = "RightUpperArm",
        ["RightLowerArm"] = "RightLowerArm",
        ["RightHand"] = "RightHand",
        ["LeftUpperLeg"] = "LeftUpperLeg",
        ["LeftLowerLeg"] = "LeftLowerLeg",
        ["LeftFoot"] = "LeftFoot",
        ["RightUpperLeg"] = "RightUpperLeg",
        ["RightLowerLeg"] = "RightLowerLeg",
        ["RightFoot"] = "RightFoot",
        ["Root"] = "HumanoidRootPart",
    }

    local function IsR15(character)
        if not character then return false end
        return character:FindFirstChild("UpperTorso") ~= nil
    end

    local function GetHitpartName(character)
        local partName = FeatureConfig.Aimbot.Hitpart or "Head"
        if IsR15(character) then
            return R15Parts[partName] or partName
        else
            return R6Parts[partName] or partName
        end
    end

    local function IsTeammate(player)
        if not FeatureConfig.Aimbot.TeamCheck then return false end
        return Utils.SameTeam(player)
    end

    local function IsCharacterValid(character)
        if not character then return false end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not humanoid or not rootPart then return false end
        if humanoid.Health <= 0 then return false end
        return true
    end

    local function IsVisible(targetPart)
        if not FeatureConfig.Aimbot.VisCheck then return true end
        return Utils.IsVisible(targetPart)
    end

    local function MatchesKey(input, bindItem)
        if typeof(bindItem) == "string" then
            local kc = Utils.GetKeyCode(bindItem)
            return kc and input.KeyCode == kc
        elseif typeof(bindItem) == "EnumItem" then
            if bindItem.EnumType == Enum.KeyCode then
                return input.KeyCode == bindItem
            elseif bindItem.EnumType == Enum.UserInputType then
                return input.UserInputType == bindItem
            end
        end
        return false
    end

    local function GetMatchingBind(input)
        local bind = FeatureConfig.Aimbot.Keybind
        if typeof(bind) == "table" then
            for _, b in ipairs(bind) do
                if MatchesKey(input, b) then return b end
            end
        else
            if MatchesKey(input, bind) then return bind end
        end
        return nil
    end

    local function IsAnyKeyHeld()
        for _ in pairs(ActiveHeldInputs) do
            return true
        end
        return false
    end

    local function GetClosestPlayer()
        local closestDistance = math.huge
        local closestPlayer = nil
        local mouseLocation = UserInputService:GetMouseLocation()
        local cfg = FeatureConfig.Aimbot

        for _, player in ipairs(Players:GetPlayers()) do
            if player == LocalPlayer then continue end
            if IsTeammate(player) then continue end
            if not IsCharacterValid(player.Character) then continue end

            local hitpartName = GetHitpartName(player.Character)
            local hitpart = player.Character:FindFirstChild(hitpartName) or player.Character:FindFirstChild("HumanoidRootPart")
            if not hitpart then continue end

            local screenPosition, isVisible = Camera:WorldToViewportPoint(hitpart.Position)
            if not isVisible then continue end
            if not IsVisible(hitpart) then continue end

            local screenVector = Vector2.new(screenPosition.X, screenPosition.Y)
            local distance = (mouseLocation - screenVector).Magnitude

            if cfg.FOV and cfg.FOV.Show and distance > (cfg.FOV.Size or 100) then
                continue
            end

            if cfg.MaxDistance then
                local myRoot = Utils.GetRootPart()
                if myRoot then
                    local worldDistance = (myRoot.Position - hitpart.Position).Magnitude
                    if worldDistance > cfg.MaxDistance then continue end
                end
            end

            if distance < closestDistance then
                closestPlayer = player
                closestDistance = distance
            end
        end

        return closestPlayer
    end

    -- Registered Inputs via Connection Tracker
    Connections.Add(UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed or not FeatureConfig.Aimbot.Enabled then return end

        local matchedBind = GetMatchingBind(input)
        if not matchedBind then return end

        ActiveHeldInputs[matchedBind] = true

        if FeatureConfig.Aimbot.LockMode == "Toggle" then
            if TargetPlayer then
                TargetPlayer = nil
                State.AimLocked = false
                State.AimTarget = nil
            else
                TargetPlayer = GetClosestPlayer()
                if TargetPlayer then
                    State.AimLocked = true
                    State.AimTarget = TargetPlayer
                end
            end
        elseif FeatureConfig.Aimbot.LockMode == "Hold" then
            TargetPlayer = GetClosestPlayer()
            if TargetPlayer then
                State.AimLocked = true
                State.AimTarget = TargetPlayer
            end
        end
    end))

    Connections.Add(UserInputService.InputEnded:Connect(function(input)
        local matchedBind = GetMatchingBind(input)
        if not matchedBind then return end

        ActiveHeldInputs[matchedBind] = nil

        if FeatureConfig.Aimbot.LockMode == "Hold" and not IsAnyKeyHeld() then
            TargetPlayer = nil
            State.AimLocked = false
            State.AimTarget = nil
        end
    end))

    Connections.Add(Players.PlayerRemoving:Connect(function(player)
        if player == TargetPlayer then
            TargetPlayer = nil
            State.AimLocked = false
            State.AimTarget = nil
        end
    end))

    local AimbotSystem = {}

    function AimbotSystem.GetClosestTarget()
        return GetClosestPlayer()
    end

    function AimbotSystem.LockOn()
        TargetPlayer = GetClosestPlayer()
        if TargetPlayer then
            State.AimLocked = true
            State.AimTarget = TargetPlayer
            return true
        end
        return false
    end

    function AimbotSystem.LockOff()
        TargetPlayer = nil
        State.AimLocked = false
        State.AimTarget = nil
        State.AimHoldActive = false
        table.clear(ActiveHeldInputs)
    end

    function AimbotSystem.UpdateAim(dt)
        local cfg = FeatureConfig.Aimbot
        if not cfg.Enabled then return end

        if cfg.LockMode == "Hold" and IsAnyKeyHeld() and not TargetPlayer then
            TargetPlayer = GetClosestPlayer()
            if TargetPlayer then
                State.AimLocked = true
                State.AimTarget = TargetPlayer
            end
        end

        if not TargetPlayer then return end

        if not IsCharacterValid(TargetPlayer.Character) then
            AimbotSystem.LockOff()
            return
        end

        local hitpartName = GetHitpartName(TargetPlayer.Character)
        local hitpart = TargetPlayer.Character:FindFirstChild(hitpartName) or TargetPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hitpart then
            AimbotSystem.LockOff()
            return
        end

        if not IsVisible(hitpart) then
            AimbotSystem.LockOff()
            return
        end

        local pred = cfg.Prediction or {Horizontal = 0.165, Vertical = 0.100}
        local predX = pred.Horizontal or pred.X or 0
        local predY = pred.Vertical or pred.Y or 0

        local velocity = hitpart.AssemblyLinearVelocity or hitpart.Velocity or Vector3.zero
        local predictedPosition = hitpart.Position + (velocity * Vector3.new(predX, predY, predX))

        local targetCFrame = CFrame.new(Camera.CFrame.Position, predictedPosition)
        local smoothness = math.max(1, cfg.Smoothness or 1)
        local deltaTime = dt or 0.016
        local alpha = math.clamp(deltaTime * (60 / smoothness), 0, 1)

        Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, alpha)
    end

    function AimbotSystem.UpdateTriggerbot()
        local cfg = FeatureConfig.Aimbot
        if not cfg.Triggerbot or not cfg.Triggerbot.Enabled or not cfg.Enabled then return end

        local mousePos = Utils.GetMousePosition()
        for _, p in ipairs(Players:GetPlayers()) do
            if p == LocalPlayer then continue end
            if IsTeammate(p) then continue end
            if not Utils.IsAlive(p) then continue end

            local char = p.Character
            if not char then continue end
            for _, part in ipairs(char:GetChildren()) do
                if not part:IsA("BasePart") then continue end
                local sp, onScreen, depth = Utils.WorldToScreen(part.Position)
                if not onScreen or depth <= 0 then continue end
                if (mousePos - sp).Magnitude < 14 then
                    task.delay(cfg.Triggerbot.Delay or 0.05, function()
                        if not cfg.Triggerbot.Enabled then return end
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

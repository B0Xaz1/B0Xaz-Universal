return function(Context)
    local Workspace = game:GetService("Workspace")
    local Players = game:GetService("Players")
    local UIS = game:GetService("UserInputService")

    local LocalPlayer = Players.LocalPlayer
    local Camera = Workspace.CurrentCamera

    local FeatureConfig = Context.FeatureConfig
    local State = Context.State
    local Utils = Context.Utils
    local Connections = Context.Connections

    local AimbotSystem = {}
    local TargetPlayer = nil
    local ActiveHeldInputs = {}

    local R6Parts = {
        Head = "Head", Torso = "Torso", Root = "HumanoidRootPart",
        LeftArm = "Left Arm", RightArm = "Right Arm",
        LeftLeg = "Left Leg", RightLeg = "Right Leg",
    }
    local R15Parts = {
        Head = "Head", Torso = "UpperTorso", LowerTorso = "LowerTorso",
        Root = "HumanoidRootPart",
        LeftArm = "LeftUpperArm", RightArm = "RightUpperArm",
        LeftLeg = "LeftUpperLeg", RightLeg = "RightUpperLeg",
    }

    local function getHitPart(character)
        if not character or not character.Parent then return nil end
        local key = FeatureConfig.Aimbot.Hitpart or "Head"
        local isR15 = character:FindFirstChild("UpperTorso") ~= nil
        local map = isR15 and R15Parts or R6Parts
        local name = map[key] or key
        return character:FindFirstChild(name)
            or character:FindFirstChild("Head")
            or character:FindFirstChild("HumanoidRootPart")
    end

    local function isTeammate(player)
        if not FeatureConfig.Aimbot.TeamCheck then return false end
        return Utils.SameTeam(player)
    end

    local function isVisible(part)
        if not FeatureConfig.Aimbot.VisCheck then return true end
        if not part then return false end
        return Utils.IsVisible(part)
    end

    local function matchesBind(input, bindItem)
        if bindItem == nil then return false end
        if typeof(bindItem) == "string" then
            local upper = bindItem:upper()
            if upper == "MB1" or upper == "MOUSEBUTTON1" then
                return input.UserInputType == Enum.UserInputType.MouseButton1
            elseif upper == "MB2" or upper == "MOUSEBUTTON2" then
                return input.UserInputType == Enum.UserInputType.MouseButton2
            elseif upper == "MB3" or upper == "MOUSEBUTTON3" then
                return input.UserInputType == Enum.UserInputType.MouseButton3
            end
            local kc = Utils.GetKeyCode(bindItem)
            return kc ~= nil and input.KeyCode == kc
        end
        if typeof(bindItem) == "EnumItem" then
            if bindItem.EnumType == Enum.KeyCode then
                return input.KeyCode == bindItem
            elseif bindItem.EnumType == Enum.UserInputType then
                return input.UserInputType == bindItem
            end
        end
        return false
    end

    local function getMatchingBind(input)
        local bind = FeatureConfig.Aimbot.Keybind
        if typeof(bind) == "table" then
            for _, b in ipairs(bind) do
                if matchesBind(input, b) then return b end
            end
            return nil
        end
        if matchesBind(input, bind) then return bind end
        return nil
    end

    local function isAnyKeyHeld()
        return next(ActiveHeldInputs) ~= nil
    end

    local function getClosestPlayer()
        local cfg = FeatureConfig.Aimbot
        local closestDist = math.huge
        local closest = nil
        local mouse = UIS:GetMouseLocation()
        local fovSize = (cfg.FOV and cfg.FOV.Size) or 150
        local myAssets = Utils.GetPlayerAssets(LocalPlayer)

        for _, player in ipairs(Players:GetPlayers()) do
            if player == LocalPlayer then continue end
            if isTeammate(player) then continue end
            local assets = Utils.GetPlayerAssets(player)
            if not assets then continue end

            local hit = getHitPart(assets.Character)
            if not hit then continue end

            local screen, onScreen = Camera:WorldToViewportPoint(hit.Position)
            if not onScreen or screen.Z <= 0 then continue end
            if not isVisible(hit) then continue end

            local screenPos = Vector2.new(screen.X, screen.Y)
            local dist2d = (mouse - screenPos).Magnitude

            if dist2d > fovSize then continue end

            if myAssets and cfg.MaxDistance then
                local worldDist = (myAssets.RootPart.Position - hit.Position).Magnitude
                if worldDist > cfg.MaxDistance then continue end
            end

            if dist2d < closestDist then
                closestDist = dist2d
                closest = player
            end
        end

        return closest
    end

    local function setTarget(player)
        TargetPlayer = player
        State.AimTarget = player
        State.AimLocked = player ~= nil
        State.AimHoldActive = player ~= nil and FeatureConfig.Aimbot.LockMode == "Hold"
    end

    function AimbotSystem.LockOn()
        local t = getClosestPlayer()
        setTarget(t)
        return t ~= nil
    end

    function AimbotSystem.LockOff()
        setTarget(nil)
        table.clear(ActiveHeldInputs)
    end

    function AimbotSystem.GetClosestTarget()
        return getClosestPlayer()
    end

    function AimbotSystem.UpdateAim(dt)
        local cfg = FeatureConfig.Aimbot
        if not cfg or not cfg.Enabled then return end
        dt = dt or 0.016

        if cfg.LockMode == "Hold" then
            if isAnyKeyHeld() then
                local assets = TargetPlayer and Utils.GetPlayerAssets(TargetPlayer)
                if not assets then
                    local t = getClosestPlayer()
                    if t then setTarget(t) end
                end
            else
                if TargetPlayer then setTarget(nil) end
                return
            end
        end

        if not TargetPlayer then return end

        local assets = Utils.GetPlayerAssets(TargetPlayer)
        if not assets then
            setTarget(nil)
            return
        end

        local hit = getHitPart(assets.Character)
        if not hit or not hit:IsDescendantOf(Workspace) then
            setTarget(nil)
            return
        end

        if not isVisible(hit) then
            setTarget(nil)
            return
        end

        local mouse = UIS:GetMouseLocation()
        local screenPos, onScreen = Camera:WorldToViewportPoint(hit.Position)
        if not onScreen or screenPos.Z <= 0 then
            setTarget(nil)
            return
        end

        if cfg.BreakOnPull then
            local distFromCrosshair = (mouse - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
            if distFromCrosshair > (cfg.MaxLockRadius or 200) then
                setTarget(nil)
                return
            end
        end

        local pred = cfg.Prediction or {}
        local predX = pred.Horizontal or pred.X or 0
        local predY = pred.Vertical or pred.Y or 0
        local vel = hit.AssemblyLinearVelocity or hit.Velocity or Vector3.zero
        local predicted = hit.Position + Vector3.new(vel.X * predX, vel.Y * predY, vel.Z * predX)

        if (cfg.ShakeIntensity or 0) > 0 then
            local s = cfg.ShakeIntensity / 10
            predicted = predicted + Vector3.new((math.random() * 2 - 1) * s, (math.random() * 2 - 1) * s, 0)
        end

        local smoothness = math.max(tonumber(cfg.Smoothness) or 1, 1)
        local alpha = math.clamp(dt * (60 / smoothness), 0, 1)

        local screen = Vector2.new(screenPos.X, screenPos.Y)
        local delta = screen - mouse
        if delta.Magnitude > 0.5 then
            local step = delta * alpha
            local moved = false
            if mousemoverel then
                moved = pcall(function() mousemoverel(step.X, step.Y) end)
            end
            if not moved then
                local targetCF = CFrame.new(Camera.CFrame.Position, predicted)
                Camera.CFrame = Camera.CFrame:Lerp(targetCF, alpha)
            end
            return
        end

        local targetCF = CFrame.new(Camera.CFrame.Position, predicted)
        Camera.CFrame = Camera.CFrame:Lerp(targetCF, alpha)
    end

    function AimbotSystem.UpdateTriggerbot()
        local cfg = FeatureConfig.Aimbot
        if not cfg.Enabled or not cfg.Triggerbot or not cfg.Triggerbot.Enabled then return end

        local mousePos = Utils.GetMousePosition()
        for _, p in ipairs(Players:GetPlayers()) do
            if p == LocalPlayer then continue end
            if isTeammate(p) then continue end
            local assets = Utils.GetPlayerAssets(p)
            if not assets then continue end

            for _, part in ipairs(assets.Character:GetChildren()) do
                if not part:IsA("BasePart") then continue end
                local sp, onScreen, depth = Utils.WorldToScreen(part.Position)
                if not 

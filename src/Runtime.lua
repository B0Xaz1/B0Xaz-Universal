-- src/Runtime.lua
return function(Context)
    local RS = game:GetService("RunService")
    local UIS = game:GetService("UserInputService")
    local Players = game:GetService("Players")
    local Lighting = game:GetService("Lighting")
    local Workspace = game:GetService("Workspace")

    local LocalPlayer = Players.LocalPlayer
    local Camera = Workspace.CurrentCamera
    local Mouse = LocalPlayer:GetMouse()
    local IsMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled

    local FeatureConfig = Context.FeatureConfig
    local State = Context.State
    local StatsConfig = Context.StatsConfig
    local Utils = Context.Utils
    local Connections = Context.Connections
    local DefaultLighting = Context.DefaultLighting

    local AimbotSystem = Context.AimbotSystem
    local ESPSystem = Context.ESPSystem
    local FlySystem = Context.FlySystem
    local OverlayManager = Context.OverlayManager

    local DrawingESP = getgenv().B0XazDrawingESP
    local SkeletonLines = getgenv().B0XazSkeletonLines

    local _fpsCounter = 0
    local _fpsTimer = 0
    local _fpsDisplay = 0

    local function applyHitboxes()
        local sz = FeatureConfig.Extras.Hitbox.Size
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local root = p.Character:FindFirstChild("HumanoidRootPart")
                if root and root:IsA("BasePart") then
                    if not State.OriginalHitboxSizes[p] then State.OriginalHitboxSizes[p] = root.Size end
                    if root.Size.X ~= sz then root.Size = Vector3.new(sz, sz, sz) end
                    root.Transparency = 0.9
                    root.CanCollide = false
                end
            end
        end
    end

    Context.ResetHitboxes = function()
        for p, sz in pairs(State.OriginalHitboxSizes) do 
            if p.Character then 
                local root = p.Character:FindFirstChild("HumanoidRootPart")
                if root then root.Size = sz; root.Transparency = 1 end 
            end 
        end
        table.clear(State.OriginalHitboxSizes)
    end

    -- Teleport Hook
    pcall(function()
        Connections.Add(LocalPlayer.OnTeleport:Connect(function(teleportState)
            if teleportState == Enum.TeleportState.Started or teleportState == Enum.TeleportState.InProgress then
                Utils.PrepareTeleport()
            end
        end))
    end)

    -- Aimbot Key Bindings
    Connections.Add(UIS.InputBegan:Connect(function(input, processed)
        if processed or IsMobile or not FeatureConfig.Aimbot.Enabled then return end
        local key = Utils.GetKeyCode(FeatureConfig.Aimbot.Keybind)
        if not key or input.KeyCode ~= key then return end
        if FeatureConfig.Aimbot.LockMode == "Hold" then 
            State.AimHoldActive = true
            AimbotSystem.LockOn()
        else 
            if State.AimLocked then AimbotSystem.LockOff() else AimbotSystem.LockOn() end 
        end
    end))

    Connections.Add(UIS.InputEnded:Connect(function(input)
        if IsMobile then return end
        local key = Utils.GetKeyCode(FeatureConfig.Aimbot.Keybind)
        if not key or input.KeyCode ~= key then return end
        if FeatureConfig.Aimbot.LockMode == "Hold" then 
            State.AimHoldActive = false
            AimbotSystem.LockOff() 
        end
    end))

    Connections.Add(UIS.JumpRequest:Connect(function() 
        if FeatureConfig.Movement.InfJump then 
            local h = Utils.GetHumanoid()
            if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end 
        end 
    end))

    if IsMobile then
        Connections.Add(UIS.TouchTap:Connect(function(tps)
            if not State.TpToMouse then return end
            local r = Utils.GetRootPart()
            if not r then return end
            local ray = Camera:ViewportPointToRay(tps[1].X, tps[1].Y)
            local params = RaycastParams.new()
            params.FilterDescendantsInstances = {Utils.GetCharacter()}
            params.FilterType = Enum.RaycastFilterType.Exclude
            local res = Workspace:Raycast(ray.Origin, ray.Direction * 500, params)
            if res then r.CFrame = CFrame.new(res.Position + Vector3.new(0, 3, 0)) end
        end))
    else
        Connections.Add(Mouse.Button1Down:Connect(function()
            if State.TpToMouse and UIS:IsKeyDown(Enum.KeyCode.LeftControl) then 
                local r = Utils.GetRootPart()
                if r then r.CFrame = CFrame.new(Mouse.Hit.Position + Vector3.new(0, 3, 0)) end 
            end
        end))
    end

    -- Main Render Loop
    Connections.Add(RS.RenderStepped:Connect(function(dt)
        Camera.FieldOfView = FeatureConfig.Camera.FOV
        AimbotSystem.UpdateAim()
        AimbotSystem.UpdateTriggerbot()
        OverlayManager.UpdateFOVCircle(dt)
        FlySystem.Update()

        _fpsCounter += 1
        _fpsTimer += dt
        if _fpsTimer >= 1 then 
            _fpsDisplay = _fpsCounter
            _fpsCounter = 0
            _fpsTimer = 0 
        end
        if OverlayManager.FPSLabel and StatsConfig.ShowFPS then 
            OverlayManager.FPSLabel.Text = "FPS: " .. _fpsDisplay
            OverlayManager.FPSLabel.Position = Vector2.new(8, 8)
            OverlayManager.FPSLabel.Visible = true
        elseif OverlayManager.FPSLabel then 
            OverlayManager.FPSLabel.Visible = false 
        end
        if OverlayManager.PingLabel and StatsConfig.ShowPing then
            local ping = 0
            pcall(function() ping = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()) end)
            OverlayManager.PingLabel.Text = "Ping: " .. ping .. "ms"
            OverlayManager.PingLabel.Position = Vector2.new(8, 26)
            OverlayManager.PingLabel.Visible = true
        elseif OverlayManager.PingLabel then 
            OverlayManager.PingLabel.Visible = false 
        end

        if FeatureConfig.Extras.SpinBot.Enabled then
            local r = Utils.GetRootPart()
            if r then 
                State.SpinBotAngle = (State.SpinBotAngle + FeatureConfig.Extras.SpinBot.Speed * dt * 10) % 360
                r.CFrame = CFrame.new(r.Position) * CFrame.Angles(0, math.rad(State.SpinBotAngle), 0) 
            end
        end
        
        OverlayManager.UpdateCrosshair()
        OverlayManager.UpdateSpeedLines(dt)
        ESPSystem.Update()
    end))

    -- Main Heartbeat Loop
    Connections.Add(RS.Heartbeat:Connect(function(dt)
        local hum = Utils.GetHumanoid()
        if hum then
            if FeatureConfig.Movement.SprintEnabled and UIS:IsKeyDown(Enum.KeyCode.LeftShift) then 
                hum.WalkSpeed = FeatureConfig.Movement.SprintSpeed
            elseif FeatureConfig.Movement.SprintEnabled then 
                hum.WalkSpeed = FeatureConfig.Movement.Speed 
            end
        end
        
        if FeatureConfig.Visuals.Fullbright then 
            Lighting.Ambient = Color3.fromRGB(255,255,255)
            Lighting.OutdoorAmbient = Color3.fromRGB(255,255,255)
            Lighting.Brightness = 2
            Lighting.GlobalShadows = false 
        end
        
        if FeatureConfig.Extras.Hitbox.Enabled then applyHitboxes() end

        if State.SelectedPlayer then
            local t = Utils.GetPlayerByName(State.SelectedPlayer)
            local mr = Utils.GetRootPart()
            local tr = t and t.Character and t.Character:FindFirstChild("HumanoidRootPart")
            
            if State.LoopTeleport and mr and tr then 
                mr.CFrame = tr.CFrame + Vector3.new(3,0,0) 
            end
            if State.OrbitEnabled and t and Utils.IsAlive(t) and mr and tr then
                State.OrbitAngle += State.OrbitSpeed * dt
                mr.CFrame = CFrame.new(tr.Position.X + math.cos(State.OrbitAngle)*State.OrbitRadius, tr.Position.Y, tr.Position.Z + math.sin(State.OrbitAngle)*State.OrbitRadius) * CFrame.Angles(0, -State.OrbitAngle - math.pi/2, 0)
            end
            if State.LoopJump and t and Utils.IsAlive(t) and mr and tr then 
                mr.CFrame = tr.CFrame + Vector3.new(0,4,0) 
            end
            if State.SpinTarget and t and Utils.IsAlive(t) and mr and tr then
                State.SpinTargetAngle += 10 * dt
                mr.CFrame = CFrame.new(tr.Position.X + math.cos(State.SpinTargetAngle)*2, tr.Position.Y, tr.Position.Z + math.sin(State.SpinTargetAngle)*2)
            end
        end
    end))

    local function onCharacterAdded(char)
        task.wait(1)
        local h = char:FindFirstChildOfClass("Humanoid")
        if h then 
            h.WalkSpeed = FeatureConfig.Movement.Speed
            h.JumpPower = FeatureConfig.Movement.JumpPower 
        end
        if FeatureConfig.Movement.FlyEnabled then FlySystem.Stop() end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                if not DrawingESP[p] then ESPSystem.CreatePlayerESP(p) end
                if not SkeletonLines[p] then ESPSystem.CreateSkeleton(p) end
            end
        end
    end

    Connections.Add(LocalPlayer.CharacterAdded:Connect(onCharacterAdded))
    if LocalPlayer.Character then 
        task.spawn(function() onCharacterAdded(LocalPlayer.Character) end) 
    end

    Connections.Add(Players.PlayerAdded:Connect(function(p)
        ESPSystem.CreatePlayerESP(p)
        ESPSystem.CreateSkeleton(p)
        if FeatureConfig.Chams.Enabled and p.Character then ESPSystem.AddHighlight(p) end
        Connections.Add(p.CharacterAdded:Connect(function()
            task.wait(0.5)
            ESPSystem.RemovePlayerESP(p)
            ESPSystem.RemoveSkeleton(p)
            ESPSystem.CreatePlayerESP(p)
            ESPSystem.CreateSkeleton(p)
            if FeatureConfig.Chams.Enabled then 
                ESPSystem.RemoveHighlight(p)
                task.wait(0.1)
                ESPSystem.AddHighlight(p) 
            end
        end))
    end))

    Connections.Add(Players.PlayerRemoving:Connect(function(p)
        ESPSystem.RemovePlayerESP(p)
        ESPSystem.RemoveSkeleton(p)
        ESPSystem.RemoveHighlight(p)
        State.OriginalHitboxSizes[p] = nil
    end))
end

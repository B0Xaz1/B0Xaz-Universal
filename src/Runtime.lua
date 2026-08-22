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

    local FeatureConfig = Context.FeatureConfig or {}
    local State = Context.State or {}
    local StatsConfig = Context.StatsConfig or {}
    local Utils = Context.Utils or {}
    local Connections = Context.Connections or {}

    local AimbotSystem = Context.AimbotSystem
    local ESPSystem = Context.ESPSystem
    local FlySystem = Context.FlySystem
    local MovementSystem = Context.MovementSystem
    local OverlayManager = Context.OverlayManager
    local GameLoader = Context.GameLoader

    local SessionId = getgenv().B0XazSessionId or 0
    local function isSessionAlive()
        return getgenv().B0XazSessionId == SessionId
    end

    local _fpsCounter = 0
    local _fpsTimer = 0
    local _fpsDisplay = 0

    ----------------------------------------------------------------
    -- Rock-Solid Matrix Stretch Res (Works at all pitch/yaw angles)
    ----------------------------------------------------------------
    local function applyMatrixStretchRes()
        local cfg = FeatureConfig.Extras and FeatureConfig.Extras.StretchRes
        if not cfg or not cfg.Enabled then return end

        local xFactor = tonumber(cfg.X) or 1.333
        local yFactor = tonumber(cfg.Y) or 1.0

        if xFactor == 1 and yFactor == 1 then return end

        local cf = Camera.CFrame
        local pos = cf.Position

        -- Extract normalized unit vectors to prevent compounding scale & NaN matrix collapse
        local right = cf.RightVector.Unit
        local up = cf.UpVector.Unit
        local look = cf.LookVector.Unit

        -- Direct raw component matrix construction (bypasses CFrame.fromMatrix auto-normalization)
        Camera.CFrame = CFrame.new(
            pos.X, pos.Y, pos.Z,
            right.X * xFactor, up.X * yFactor, -look.X,
            right.Y * xFactor, up.Y * yFactor, -look.Y,
            right.Z * xFactor, up.Z * yFactor, -look.Z
        )
    end

    ----------------------------------------------------------------
    -- Hitboxes
    ----------------------------------------------------------------
    local function applyHitboxes()
        if not FeatureConfig.Extras or not FeatureConfig.Extras.Hitbox or not FeatureConfig.Extras.Hitbox.Enabled then return end
        local sz = FeatureConfig.Extras.Hitbox.Size or 10
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local root = p.Character:FindFirstChild("HumanoidRootPart")
                if root and root:IsA("BasePart") then
                    if State.OriginalHitboxSizes and not State.OriginalHitboxSizes[p] then
                        State.OriginalHitboxSizes[p] = root.Size
                    end
                    if root.Size.X ~= sz then root.Size = Vector3.new(sz, sz, sz) end
                    root.Transparency = 0.9
                    root.CanCollide = false
                end
            end
        end
    end

    Context.ResetHitboxes = function()
        if not State.OriginalHitboxSizes then return end
        for p, sz in pairs(State.OriginalHitboxSizes) do
            if p and p.Character then
                local root = p.Character:FindFirstChild("HumanoidRootPart")
                if root then
                    root.Size = sz
                    root.Transparency = 1
                end
            end
        end
        table.clear(State.OriginalHitboxSizes)
    end

    if Connections.Add then
        pcall(function()
            Connections.Add(LocalPlayer.OnTeleport:Connect(function(teleportState)
                if not isSessionAlive() then return end
                if teleportState == Enum.TeleportState.Started or teleportState == Enum.TeleportState.InProgress then
                    if Utils.PrepareTeleport then Utils.PrepareTeleport() end
                end
            end))
        end)
    end

    if Connections.Add then
        Connections.Add(UIS.JumpRequest:Connect(function()
            if not isSessionAlive() then return end
            if FeatureConfig.Movement and FeatureConfig.Movement.InfJump then
                local h = Utils.GetHumanoid and Utils.GetHumanoid()
                if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
            end
        end))
    end

    if IsMobile and Connections.Add then
        Connections.Add(UIS.TouchTap:Connect(function(tps)
            if not isSessionAlive() then return end
            if not State.TpToMouse then return end
            local r = Utils.GetRootPart and Utils.GetRootPart()
            if not r then return end
            local ray = Camera:ViewportPointToRay(tps[1].X, tps[1].Y)
            local params = RaycastParams.new()
            params.FilterDescendantsInstances = {Utils.GetCharacter and Utils.GetCharacter()}
            params.FilterType = Enum.RaycastFilterType.Exclude
            local res = Workspace:Raycast(ray.Origin, ray.Direction * 500, params)
            if res then r.CFrame = CFrame.new(res.Position + Vector3.new(0, 3, 0)) end
        end))
    elseif Connections.Add then
        Connections.Add(Mouse.Button1Down:Connect(function()
            if not isSessionAlive() then return end
            if State.TpToMouse and UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
                local r = Utils.GetRootPart and Utils.GetRootPart()
                if r then r.CFrame = CFrame.new(Mouse.Hit.Position + Vector3.new(0, 3, 0)) end
            end
        end))
    end

    if Connections.Add then
        Connections.Add(RS.RenderStepped:Connect(function(dt)
            if not isSessionAlive() then return end

            if FeatureConfig.Camera and FeatureConfig.Camera.FOV then
                Camera.FieldOfView = FeatureConfig.Camera.FOV
            end

            -- Apply Matrix Stretch Res AFTER FOV updates
            applyMatrixStretchRes()

            if AimbotSystem then
                if type(AimbotSystem.UpdateAim) == "function" then
                    AimbotSystem.UpdateAim(dt)
                end
                if type(AimbotSystem.UpdateTriggerbot) == "function" then
                    AimbotSystem.UpdateTriggerbot()
                end
            end

            if OverlayManager then
                if type(OverlayManager.UpdateFOVCircle) == "function" then OverlayManager.UpdateFOVCircle(dt) end
                if type(OverlayManager.UpdateCrosshair) == "function" then OverlayManager.UpdateCrosshair() end
                if type(OverlayManager.UpdateSpeedLines) == "function" then OverlayManager.UpdateSpeedLines(dt) end
            end

            if FlySystem and type(FlySystem.Update) == "function" then
                FlySystem.Update()
            end

            _fpsCounter = _fpsCounter + 1
            _fpsTimer = _fpsTimer + dt
            if _fpsTimer >= 1 then
                _fpsDisplay = _fpsCounter
                _fpsCounter = 0
                _fpsTimer = 0
            end

            if OverlayManager and OverlayManager.FPSLabel then
                if StatsConfig.ShowFPS then
                    OverlayManager.FPSLabel.Text = "FPS: " .. _fpsDisplay
                    OverlayManager.FPSLabel.Position = Vector2.new(8, 8)
                    OverlayManager.FPSLabel.Visible = true
                else
                    OverlayManager.FPSLabel.Visible = false
                end
            end

            if OverlayManager and OverlayManager.PingLabel then
                if StatsConfig.ShowPing then
                    local ping = 0
                    pcall(function() ping = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()) end)
                    OverlayManager.PingLabel.Text = "Ping: " .. ping .. "ms"
                    OverlayManager.PingLabel.Position = Vector2.new(8, 26)
                    OverlayManager.PingLabel.Visible = true
                else
                    OverlayManager.PingLabel.Visible = false
                end
            end

            if FeatureConfig.Extras and FeatureConfig.Extras.SpinBot and FeatureConfig.Extras.SpinBot.Enabled then
                local r = Utils.GetRootPart and Utils.GetRootPart()
                if r then
                    State.SpinBotAngle = ((State.SpinBotAngle or 0) + (FeatureConfig.Extras.SpinBot.Speed or 20) * dt * 10) % 360
                    r.CFrame = CFrame.new(r.Position) * CFrame.Angles(0, math.rad(State.SpinBotAngle), 0)
                end
            end

            if ESPSystem and type(ESPSystem.Update) == "function" then
                ESPSystem.Update()
            end
        end))
    end

    if Connections.Add then
        Connections.Add(RS.Heartbeat:Connect(function(dt)
            if not isSessionAlive() then return end

            local hum = Utils.GetHumanoid and Utils.GetHumanoid()
            if hum and FeatureConfig.Movement then
                if FeatureConfig.Movement.SprintEnabled and UIS:IsKeyDown(Enum.KeyCode.LeftShift) then
                    hum.WalkSpeed = FeatureConfig.Movement.SprintSpeed or 30
                elseif FeatureConfig.Movement.SprintEnabled then
                    hum.WalkSpeed = FeatureConfig.Movement.Speed or 16
                end
            end

            if MovementSystem and type(MovementSystem.Update) == "function" then
                MovementSystem.Update(dt)
            end

            if GameLoader and type(GameLoader.Update) == "function" then
                GameLoader.Update(dt)
            end

            if FeatureConfig.Visuals and FeatureConfig.Visuals.Fullbright then
                Lighting.Ambient = Color3.fromRGB(255, 255, 255)
                Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
                Lighting.Brightness = 2
                Lighting.GlobalShadows = false
            end

            if FeatureConfig.Extras and FeatureConfig.Extras.Hitbox and FeatureConfig.Extras.Hitbox.Enabled then
                applyHitboxes()
            end

            if State.SelectedPlayer then
                local t = Utils.GetPlayerByName and Utils.GetPlayerByName(State.SelectedPlayer)
                local mr = Utils.GetRootPart and Utils.GetRootPart()
                local tr = t and t.Character and t.Character:FindFirstChild("HumanoidRootPart")

                if State.LoopTeleport and mr and tr then
                    mr.CFrame = tr.CFrame + Vector3.new(3, 0, 0)
                end
                if State.OrbitEnabled and t and Utils.IsAlive(t) and mr and tr then
                    State.OrbitAngle = (State.OrbitAngle or 0) + (State.OrbitSpeed or 2) * dt
                    mr.CFrame = CFrame.new(tr.Position.X + math.cos(State.OrbitAngle) * (State.OrbitRadius or 8), tr.Position.Y, tr.Position.Z + math.sin(State.OrbitAngle) * (State.OrbitRadius or 8)) * CFrame.Angles(0, -State.OrbitAngle - math.pi / 2, 0)
                end
                if State.LoopJump and t and Utils.IsAlive(t) and mr and tr then
                    mr.CFrame = tr.CFrame + Vector3.new(0, 4, 0)
                end
                if State.SpinTarget and t and Utils.IsAlive(t) and mr and tr then
                    State.SpinTargetAngle = (State.SpinTargetAngle or 0) + 10 * dt
                    mr.CFrame = CFrame.new(tr.Position.X + math.cos(State.SpinTargetAngle) * 2, tr.Position.Y, tr.Position.Z + math.sin(State.SpinTargetAngle) * 2)
                end
            end
        end))
    end
end

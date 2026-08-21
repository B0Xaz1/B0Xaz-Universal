-- src/Systems/ESPSystem.lua
return function(Context)
    local Players = game:GetService("Players")
    local Workspace = game:GetService("Workspace")
    local LocalPlayer = Players.LocalPlayer
    local Camera = Workspace.CurrentCamera

    local FeatureConfig = Context.FeatureConfig
    local CONFIG = Context.CONFIG
    local Utils = Context.Utils
    local DrawingManager = Context.DrawingManager

    local DrawingESP = getgenv().B0XazDrawingESP or {}
    getgenv().B0XazDrawingESP = DrawingESP

    local TracerLines = getgenv().B0XazTracerLines or {}
    getgenv().B0XazTracerLines = TracerLines

    local SkeletonLines = getgenv().B0XazSkeletonLines or {}
    getgenv().B0XazSkeletonLines = SkeletonLines

    local Highlights = getgenv().B0XazHighlights or {}
    getgenv().B0XazHighlights = Highlights

    local ESPSystem = {}

    function ESPSystem.CreatePlayerESP(player)
        if player == LocalPlayer or DrawingESP[player] or not DrawingManager.Available then return end
        local col = FeatureConfig.ESP.Color
        local data = {
            Box = DrawingManager.NewSquare({Thickness=2,Color=col}), 
            Name = DrawingManager.NewText({Size=CONFIG.ESP_TEXT_SIZE_NAME,Color=col}), 
            Health = DrawingManager.NewSquare({Filled=true}), 
            HealthBG = DrawingManager.NewSquare({Filled=true}), 
            Distance = DrawingManager.NewText({Size=CONFIG.ESP_TEXT_SIZE_DIST,Color=col}), 
            HeadDot = DrawingManager.NewCircle({Radius=4,Filled=true,Color=col}), 
            LookLine = DrawingManager.NewLine({Thickness=2,Color=col})
        }
        for _, d in pairs(data) do 
            if not d then 
                for _, dd in pairs(data) do DrawingManager.SafeRemove(dd) end
                return 
            end 
        end
        DrawingESP[player] = data
    end

    function ESPSystem.RemovePlayerESP(player) 
        local d = DrawingESP[player]
        if d then 
            for _, dd in pairs(d) do DrawingManager.SafeRemove(dd) end
            DrawingESP[player] = nil 
        end 
    end

    function ESPSystem.CreateSkeleton(player)
        if player == LocalPlayer or SkeletonLines[player] or not DrawingManager.Available then return end
        local lines = {}
        for _ = 1, 6 do 
            local l = DrawingManager.NewLine({Thickness=CONFIG.ESP_SKELETON_THICKNESS})
            if l then table.insert(lines, l) end 
        end
        if #lines == 6 then 
            SkeletonLines[player] = lines 
        else 
            for _, l in ipairs(lines) do DrawingManager.SafeRemove(l) end 
        end
    end

    function ESPSystem.RemoveSkeleton(player) 
        local lines = SkeletonLines[player]
        if lines then 
            for _, l in ipairs(lines) do DrawingManager.SafeRemove(l) end
            SkeletonLines[player] = nil 
        end 
    end

    function ESPSystem.AddHighlight(player)
        if Highlights[player] or not player.Character then return end
        local h = Instance.new("Highlight")
        h.Name = "B0XazChams"
        h.Adornee = player.Character
        h.FillColor = FeatureConfig.Chams.FillColor
        h.OutlineColor = FeatureConfig.Chams.OutlineColor
        h.FillTransparency = 0.5
        h.Parent = player.Character
        Highlights[player] = h
    end

    function ESPSystem.RemoveHighlight(player) 
        if Highlights[player] then 
            pcall(function() Highlights[player]:Destroy() end)
            Highlights[player] = nil 
        end 
    end

    local function hideDrawings(d) 
        if not d then return end
        for _, dr in pairs(d) do 
            if dr then pcall(function() dr.Visible = false end) end 
        end 
    end

    local function hideSkeletonLines(p) 
        local lines = SkeletonLines[p]
        if not lines then return end
        for _, l in ipairs(lines) do 
            if l then pcall(function() l.Visible = false end) end 
        end 
    end

    local function clearTracers() 
        for i = #TracerLines, 1, -1 do 
            DrawingManager.SafeRemove(TracerLines[i])
            TracerLines[i] = nil 
        end 
    end

    local function hasAnyESPFeature() 
        local e = FeatureConfig.ESP
        return e.Box or e.Name or e.Health or e.Distance or e.Tracers or e.Skeleton or e.HeadDot or e.LookDir 
    end

    function ESPSystem.Update()
        clearTracers()

        -- Auto-register any connected or newly joined players
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                if not DrawingESP[p] then ESPSystem.CreatePlayerESP(p) end
                if not SkeletonLines[p] then ESPSystem.CreateSkeleton(p) end
            end
        end

        -- Clean up players who disconnected
        for player, data in pairs(DrawingESP) do
            if not player or not player.Parent then
                ESPSystem.RemovePlayerESP(player)
                ESPSystem.RemoveSkeleton(player)
                ESPSystem.RemoveHighlight(player)
            end
        end

        local espEnabled = FeatureConfig.ESP and FeatureConfig.ESP.Enabled and hasAnyESPFeature()
        local chamsEnabled = FeatureConfig.Chams and FeatureConfig.Chams.Enabled

        -- Explicitly hide all elements if ESP & Chams are turned off
        if not espEnabled and not chamsEnabled then
            for player, data in pairs(DrawingESP) do
                hideDrawings(data)
                hideSkeletonLines(player)
                ESPSystem.RemoveHighlight(player)
            end
            return
        end

        local myRoot = Utils.GetRootPart()
        local myPos = myRoot and myRoot.Position
        local col = FeatureConfig.ESP.Color

        for player, data in pairs(DrawingESP) do
            if not player or not player.Parent then continue end

            local alive = Utils.IsAlive(player)
            local teamSkip = FeatureConfig.ESP.TeamCheck and Utils.SameTeam(player)
            local shouldShow = espEnabled and alive and not teamSkip

            if chamsEnabled and alive and not teamSkip then
                if not Highlights[player] or Highlights[player].Adornee ~= player.Character then 
                    ESPSystem.RemoveHighlight(player)
                    ESPSystem.AddHighlight(player) 
                end
                local h = Highlights[player]
                if h then 
                    h.FillColor = FeatureConfig.Chams.FillColor
                    h.OutlineColor = FeatureConfig.Chams.OutlineColor 
                end
            else 
                ESPSystem.RemoveHighlight(player) 
            end

            if not shouldShow then 
                hideDrawings(data)
                hideSkeletonLines(player)
                continue 
            end

            local char = player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local head = char and char:FindFirstChild("Head")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if not root or not head or not hum then 
                hideDrawings(data)
                hideSkeletonLines(player)
                continue 
            end

            local dist3d = myPos and (myPos - root.Position).Magnitude or 0
            if dist3d > FeatureConfig.ESP.MaxDist then 
                hideDrawings(data)
                hideSkeletonLines(player)
                continue 
            end

            local rootScreen, rootOnScreen, rootZ = Utils.WorldToScreen(root.Position)
            if not rootOnScreen or rootZ <= 0 then 
                hideDrawings(data)
                hideSkeletonLines(player)
                continue 
            end

            local headScreen = Utils.WorldToScreen(head.Position + Vector3.new(0, 0.5, 0))
            local feetScreen = Utils.WorldToScreen(root.Position - Vector3.new(0, 3, 0))
            local height = math.abs(headScreen.Y - feetScreen.Y)
            local width = height / 2

            if data.Box then 
                data.Box.Visible = FeatureConfig.ESP.Box
                if FeatureConfig.ESP.Box then 
                    data.Box.Size = Vector2.new(width, height)
                    data.Box.Position = Vector2.new(rootScreen.X - width/2, rootScreen.Y - height/2)
                    data.Box.Color = col 
                end 
            end
            if data.Name then 
                data.Name.Visible = FeatureConfig.ESP.Name
                if FeatureConfig.ESP.Name then 
                    data.Name.Text = player.DisplayName or player.Name
                    data.Name.Position = Vector2.new(rootScreen.X, headScreen.Y - 30)
                    data.Name.Color = col 
                end 
            end
            if data.Health and data.HealthBG then
                data.Health.Visible = FeatureConfig.ESP.Health
                data.HealthBG.Visible = FeatureConfig.ESP.Health
                if FeatureConfig.ESP.Health then
                    local ratio = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
                    local barX = rootScreen.X - width/2 - 8
                    local barY = rootScreen.Y - height/2
                    data.HealthBG.Size = Vector2.new(4, height)
                    data.HealthBG.Position = Vector2.new(barX, barY)
                    data.HealthBG.Color = Color3.new(0,0,0)
                    data.HealthBG.Transparency = 0.5
                    data.Health.Size = Vector2.new(4, height * ratio)
                    data.Health.Position = Vector2.new(barX, barY + height*(1-ratio))
                    data.Health.Color = Color3.fromHSV(ratio/3, 1, 1)
                end
            end
            if data.Distance then 
                data.Distance.Visible = FeatureConfig.ESP.Distance
                if FeatureConfig.ESP.Distance then 
                    data.Distance.Text = math.floor(dist3d) .. "st"
                    data.Distance.Position = Vector2.new(rootScreen.X, feetScreen.Y + 5)
                    data.Distance.Color = col 
                end 
            end
            if data.HeadDot then 
                data.HeadDot.Visible = FeatureConfig.ESP.HeadDot
                if FeatureConfig.ESP.HeadDot then 
                    data.HeadDot.Position = headScreen
                    data.HeadDot.Color = col 
                end 
            end
            if data.LookLine then 
                data.LookLine.Visible = FeatureConfig.ESP.LookDir
                if FeatureConfig.ESP.LookDir then 
                    data.LookLine.From = headScreen
                    data.LookLine.To = Utils.WorldToScreen(head.Position + head.CFrame.LookVector * 5)
                    data.LookLine.Color = col 
                end 
            end

            if FeatureConfig.ESP.Tracers and DrawingManager.Available then
                local tracer = DrawingManager.NewLine({Thickness=CONFIG.ESP_TRACER_THICKNESS, Color=col})
                if tracer then 
                    local center = Utils.GetScreenCenter()
                    tracer.From = Vector2.new(center.X, Camera.ViewportSize.Y)
                    tracer.To = rootScreen
                    tracer.Visible = true
                    table.insert(TracerLines, tracer) 
                end
            end

            if FeatureConfig.ESP.Skeleton and SkeletonLines[player] then
                local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
                local lower = char:FindFirstChild("LowerTorso") or torso
                local la = char:FindFirstChild("LeftUpperArm") or char:FindFirstChild("Left Arm")
                local ra = char:FindFirstChild("RightUpperArm") or char:FindFirstChild("Right Arm")
                local ll = char:FindFirstChild("LeftUpperLeg") or char:FindFirstChild("Left Leg")
                local rl = char:FindFirstChild("RightUpperLeg") or char:FindFirstChild("Right Leg")
                local bones = {{head,torso},{torso,lower},{torso,la},{torso,ra},{lower,ll},{lower,rl}}
                local sk = SkeletonLines[player]
                for i, b in ipairs(bones) do
                    local sl = sk[i]
                    if sl and b[1] and b[2] then 
                        local as, _, az = Utils.WorldToScreen(b[1].Position)
                        local bs, _, bz = Utils.WorldToScreen(b[2].Position)
                        if az > 0 and bz > 0 then 
                            sl.From = as
                            sl.To = bs
                            sl.Color = col
                            sl.Visible = true 
                        else 
                            sl.Visible = false 
                        end
                    elseif sl then 
                        sl.Visible = false 
                    end
                end
            elseif SkeletonLines[player] then 
                hideSkeletonLines(player) 
            end
        end
    end

    function ESPSystem.InitializeAll() 
        for _, p in ipairs(Players:GetPlayers()) do 
            if p ~= LocalPlayer then 
                ESPSystem.CreatePlayerESP(p)
                ESPSystem.CreateSkeleton(p) 
            end 
        end 
    end

    return ESPSystem
end

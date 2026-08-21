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
    local Connections = Context.Connections

    local DrawingESP = getgenv().B0XazDrawingESP or {}
    getgenv().B0XazDrawingESP = DrawingESP

    local Highlights = getgenv().B0XazHighlights or {}
    getgenv().B0XazHighlights = Highlights

    local CharacterCache = {}
    local ESPSystem = {}

    ----------------------------------------------------------------
    -- Character Rig Caching (Eliminates FindFirstChild per frame)
    ----------------------------------------------------------------
    local function cacheCharacterParts(player, char)
        if not char then
            CharacterCache[player] = nil
            return
        end

        local hum = char:WaitForChild("Humanoid", 2) or char:FindFirstChildOfClass("Humanoid")
        local root = char:WaitForChild("HumanoidRootPart", 2) or char:FindFirstChild("HumanoidRootPart")
        local head = char:WaitForChild("Head", 2) or char:FindFirstChild("Head")

        if not hum or not root or not head then
            CharacterCache[player] = nil
            return
        end

        local isR15 = hum.RigType == Enum.HumanoidRigType.R15
        local bones = {}

        if isR15 then
            local upperTorso = char:FindFirstChild("UpperTorso")
            local lowerTorso = char:FindFirstChild("LowerTorso")
            local leftUpperArm = char:FindFirstChild("LeftUpperArm")
            local rightUpperArm = char:FindFirstChild("RightUpperArm")
            local leftUpperLeg = char:FindFirstChild("LeftUpperLeg")
            local rightUpperLeg = char:FindFirstChild("RightUpperLeg")

            if upperTorso and lowerTorso then
                table.insert(bones, {head, upperTorso})
                table.insert(bones, {upperTorso, lowerTorso})
                if leftUpperArm then table.insert(bones, {upperTorso, leftUpperArm}) end
                if rightUpperArm then table.insert(bones, {upperTorso, rightUpperArm}) end
                if leftUpperLeg then table.insert(bones, {lowerTorso, leftUpperLeg}) end
                if rightUpperLeg then table.insert(bones, {lowerTorso, rightUpperLeg}) end
            end
        else
            local torso = char:FindFirstChild("Torso")
            local leftArm = char:FindFirstChild("Left Arm")
            local rightArm = char:FindFirstChild("Right Arm")
            local leftLeg = char:FindFirstChild("Left Leg")
            local rightLeg = char:FindFirstChild("Right Leg")

            if torso then
                table.insert(bones, {head, torso})
                if leftArm then table.insert(bones, {torso, leftArm}) end
                if rightArm then table.insert(bones, {torso, rightArm}) end
                if leftLeg then table.insert(bones, {torso, leftLeg}) end
                if rightLeg then table.insert(bones, {torso, rightLeg}) end
            end
        end

        CharacterCache[player] = {
            Char = char,
            Hum = hum,
            Root = root,
            Head = head,
            Bones = bones
        }
    end

    local function uncacheCharacter(player)
        CharacterCache[player] = nil
    end

    ----------------------------------------------------------------
    -- Persistent Drawing Object Management
    ----------------------------------------------------------------
    function ESPSystem.CreatePlayerESP(player)
        if player == LocalPlayer or DrawingESP[player] or not DrawingManager.Available then return end
        local col = FeatureConfig.ESP.Color

        local skeletonLines = {}
        for _ = 1, 6 do
            local l = DrawingManager.NewLine({Thickness = CONFIG.ESP_SKELETON_THICKNESS or 1, Color = col})
            if l then table.insert(skeletonLines, l) end
        end

        local data = {
            Box = DrawingManager.NewSquare({Thickness = 2, Color = col}),
            Name = DrawingManager.NewText({Size = CONFIG.ESP_TEXT_SIZE_NAME or 13, Color = col}),
            Health = DrawingManager.NewSquare({Filled = true}),
            HealthBG = DrawingManager.NewSquare({Filled = true}),
            Distance = DrawingManager.NewText({Size = CONFIG.ESP_TEXT_SIZE_DIST or 11, Color = col}),
            HeadDot = DrawingManager.NewCircle({Radius = 4, Filled = true, Color = col}),
            LookLine = DrawingManager.NewLine({Thickness = 2, Color = col}),
            Tracer = DrawingManager.NewLine({Thickness = CONFIG.ESP_TRACER_THICKNESS or 1.5, Color = col}),
            Skeleton = skeletonLines
        }

        DrawingESP[player] = data
    end

    function ESPSystem.RemovePlayerESP(player)
        local d = DrawingESP[player]
        if d then
            DrawingManager.SafeRemove(d.Box)
            DrawingManager.SafeRemove(d.Name)
            DrawingManager.SafeRemove(d.Health)
            DrawingManager.SafeRemove(d.HealthBG)
            DrawingManager.SafeRemove(d.Distance)
            DrawingManager.SafeRemove(d.HeadDot)
            DrawingManager.SafeRemove(d.LookLine)
            DrawingManager.SafeRemove(d.Tracer)
            if d.Skeleton then
                for _, line in ipairs(d.Skeleton) do
                    DrawingManager.SafeRemove(line)
                end
            end
            DrawingESP[player] = nil
        end
        ESPSystem.RemoveHighlight(player)
        uncacheCharacter(player)
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

    local function hidePlayerDrawings(d)
        if not d then return end
        if d.Box and d.Box.Visible then d.Box.Visible = false end
        if d.Name and d.Name.Visible then d.Name.Visible = false end
        if d.Health and d.Health.Visible then d.Health.Visible = false end
        if d.HealthBG and d.HealthBG.Visible then d.HealthBG.Visible = false end
        if d.Distance and d.Distance.Visible then d.Distance.Visible = false end
        if d.HeadDot and d.HeadDot.Visible then d.HeadDot.Visible = false end
        if d.LookLine and d.LookLine.Visible then d.LookLine.Visible = false end
        if d.Tracer and d.Tracer.Visible then d.Tracer.Visible = false end
        if d.Skeleton then
            for i = 1, #d.Skeleton do
                if d.Skeleton[i].Visible then d.Skeleton[i].Visible = false end
            end
        end
    end

    ----------------------------------------------------------------
    -- Lifecycle Event Listeners
    ----------------------------------------------------------------
    local function hookPlayer(p)
        if p == LocalPlayer then return end
        ESPSystem.CreatePlayerESP(p)
        if p.Character then cacheCharacterParts(p, p.Character) end

        Connections.Add(p.CharacterAdded:Connect(function(c)
            task.wait(0.1)
            cacheCharacterParts(p, c)
            if FeatureConfig.Chams.Enabled then
                ESPSystem.RemoveHighlight(p)
                ESPSystem.AddHighlight(p)
            end
        end))

        Connections.Add(p.CharacterRemoving:Connect(function()
            uncacheCharacter(p)
            ESPSystem.RemoveHighlight(p)
            if DrawingESP[p] then hidePlayerDrawings(DrawingESP[p]) end
        end))
    end

    function ESPSystem.InitializeAll()
        for _, p in ipairs(Players:GetPlayers()) do
            hookPlayer(p)
        end
        Connections.Add(Players.PlayerAdded:Connect(hookPlayer))
        Connections.Add(Players.PlayerRemoving:Connect(function(p)
            ESPSystem.RemovePlayerESP(p)
        end))
    end

    ----------------------------------------------------------------
    -- Fast Render Loop
    ----------------------------------------------------------------
    function ESPSystem.Update()
        local espCfg = FeatureConfig.ESP
        local chamsCfg = FeatureConfig.Chams

        local hasESP = espCfg and espCfg.Enabled and (
            espCfg.Box or espCfg.Name or espCfg.Health or espCfg.Distance or
            espCfg.Tracers or espCfg.Skeleton or espCfg.HeadDot or espCfg.LookDir
        )
        local hasChams = chamsCfg and chamsCfg.Enabled

        if not hasESP and not hasChams then
            for _, data in pairs(DrawingESP) do
                hidePlayerDrawings(data)
            end
            for p, _ in pairs(Highlights) do
                ESPSystem.RemoveHighlight(p)
            end
            return
        end

        local myRoot = Utils.GetRootPart()
        local myPos = myRoot and myRoot.Position
        local espColor = espCfg.Color
        local maxDist = espCfg.MaxDist or 500
        local teamCheck = espCfg.TeamCheck

        local viewportSize = Camera.ViewportSize
        local screenBottom = Vector2.new(viewportSize.X / 2, viewportSize.Y)

        for player, data in pairs(DrawingESP) do
            local cached = CharacterCache[player]
            if not cached or not cached.Root or not cached.Head or not cached.Hum or cached.Hum.Health <= 0 then
                hidePlayerDrawings(data)
                continue
            end

            if teamCheck and Utils.SameTeam(player) then
                hidePlayerDrawings(data)
                ESPSystem.RemoveHighlight(player)
                continue
            end

            -- Fast distance rejection
            local rootPos = cached.Root.Position
            local dist3D = myPos and (myPos - rootPos).Magnitude or 0
            if dist3D > maxDist then
                hidePlayerDrawings(data)
                continue
            end

            -- Chams Handler
            if hasChams then
                local h = Highlights[player]
                if not h or h.Adornee ~= cached.Char then
                    ESPSystem.RemoveHighlight(player)
                    ESPSystem.AddHighlight(player)
                else
                    h.FillColor = chamsCfg.FillColor
                    h.OutlineColor = chamsCfg.OutlineColor
                end
            else
                ESPSystem.RemoveHighlight(player)
            end

            if not hasESP then
                hidePlayerDrawings(data)
                continue
            end

            -- Single viewport transform for RootPart
            local rootScreen, rootOnScreen = Camera:WorldToViewportPoint(rootPos)
            if not rootOnScreen or rootScreen.Z <= 0 then
                hidePlayerDrawings(data)
                continue
            end

            local headPos = cached.Head.Position
            local headScreen = Camera:WorldToViewportPoint(headPos + Vector3.new(0, 0.5, 0))
            local feetScreen = Camera:WorldToViewportPoint(rootPos - Vector3.new(0, 3, 0))

            local height = math.abs(headScreen.Y - feetScreen.Y)
            local width = height * 0.55
            local halfW = width * 0.5
            local rootScreenPos = Vector2.new(rootScreen.X, rootScreen.Y)
            local headScreenPos = Vector2.new(headScreen.X, headScreen.Y)

            -- Box
            if espCfg.Box and data.Box then
                data.Box.Size = Vector2.new(width, height)
                data.Box.Position = Vector2.new(rootScreenPos.X - halfW, rootScreenPos.Y - height * 0.5)
                data.Box.Color = espColor
                data.Box.Visible = true
            elseif data.Box then
                data.Box.Visible = false
            end

            -- Name
            if espCfg.Name and data.Name then
                data.Name.Text = player.DisplayName or player.Name
                data.Name.Position = Vector2.new(rootScreenPos.X, headScreenPos.Y - 24)
                data.Name.Color = espColor
                data.Name.Visible = true
            elseif data.Name then
                data.Name.Visible = false
            end

            -- Health Bar
            if espCfg.Health and data.Health and data.HealthBG then
                local hum = cached.Hum
                local ratio = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
                local barX = rootScreenPos.X - halfW - 6
                local barY = rootScreenPos.Y - height * 0.5

                data.HealthBG.Size = Vector2.new(3, height)
                data.HealthBG.Position = Vector2.new(barX, barY)
                data.HealthBG.Color = Color3.new(0, 0, 0)
                data.HealthBG.Transparency = 0.5
                data.HealthBG.Visible = true

                data.Health.Size = Vector2.new(3, height * ratio)
                data.Health.Position = Vector2.new(barX, barY + height * (1 - ratio))
                data.Health.Color = Color3.fromHSV(ratio * 0.33, 1, 1)
                data.Health.Visible = true
            elseif data.Health then
                data.Health.Visible = false
                data.HealthBG.Visible = false
            end

            -- Distance
            if espCfg.Distance and data.Distance then
                data.Distance.Text = math.floor(dist3D) .. "m"
                data.Distance.Position = Vector2.new(rootScreenPos.X, feetScreen.Y + 3)
                data.Distance.Color = espColor
                data.Distance.Visible = true
            elseif data.Distance then
                data.Distance.Visible = false
            end

            -- Head Dot
            if espCfg.HeadDot and data.HeadDot then
                data.HeadDot.Position = headScreenPos
                data.HeadDot.Color = espColor
                data.HeadDot.Visible = true
            elseif data.HeadDot then
                data.HeadDot.Visible = false
            end

            -- Look Direction
            if espCfg.LookDir and data.LookLine then
                local lookWorld = Camera:WorldToViewportPoint(headPos + cached.Head.CFrame.LookVector * 4.5)
                data.LookLine.From = headScreenPos
                data.LookLine.To = Vector2.new(lookWorld.X, lookWorld.Y)
                data.LookLine.Color = espColor
                data.LookLine.Visible = true
            elseif data.LookLine then
                data.LookLine.Visible = false
            end

            -- Tracer (Persistent Drawing)
            if espCfg.Tracers and data.Tracer then
                data.Tracer.From = screenBottom
                data.Tracer.To = rootScreenPos
                data.Tracer.Color = espColor
                data.Tracer.Visible = true
            elseif data.Tracer then
                data.Tracer.Visible = false
            end

            -- Skeleton (Zero allocations per frame)
            if espCfg.Skeleton and data.Skeleton then
                local bones = cached.Bones
                local skLines = data.Skeleton
                for i = 1, #skLines do
                    local line = skLines[i]
                    local pair = bones[i]
                    if pair and pair[1] and pair[2] then
                        local p1, on1 = Camera:WorldToViewportPoint(pair[1].Position)
                        local p2, on2 = Camera:WorldToViewportPoint(pair[2].Position)
                        if p1.Z > 0 and p2.Z > 0 and (on1 or on2) then
                            line.From = Vector2.new(p1.X, p1.Y)
                            line.To = Vector2.new(p2.X, p2.Y)
                            line.Color = espColor
                            line.Visible = true
                        else
                            line.Visible = false
                        end
                    else
                        line.Visible = false
                    end
                end
            elseif data.Skeleton then
                for i = 1, #data.Skeleton do
                    data.Skeleton[i].Visible = false
                end
            end
        end
    end

    return ESPSystem
end

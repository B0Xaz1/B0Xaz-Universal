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

    local DrawingESP = {}
    getgenv().B0XazDrawingESP = DrawingESP

    local Highlights = {}
    getgenv().B0XazHighlights = Highlights

    local ESPSystem = {}
    local SessionId = getgenv().B0XazSessionId or 0

    local function isSessionAlive()
        return getgenv().B0XazSessionId == SessionId
    end

    local function destroyESPData(data)
        if type(data) ~= "table" then return end
        DrawingManager.SafeRemove(data.Box)
        DrawingManager.SafeRemove(data.Name)
        DrawingManager.SafeRemove(data.Health)
        DrawingManager.SafeRemove(data.HealthBG)
        DrawingManager.SafeRemove(data.Distance)
        DrawingManager.SafeRemove(data.HeadDot)
        DrawingManager.SafeRemove(data.LookLine)
        DrawingManager.SafeRemove(data.Tracer)
        if type(data.Skeleton) == "table" then
            for _, line in ipairs(data.Skeleton) do
                DrawingManager.SafeRemove(line)
            end
        end
    end

    function ESPSystem.CreatePlayerESP(player)
        if not isSessionAlive() then return end
        if player == LocalPlayer or not DrawingManager.Available then return end

        if DrawingESP[player] then
            destroyESPData(DrawingESP[player])
            DrawingESP[player] = nil
        end

        local col = FeatureConfig.ESP.Color

        local skeletonLines = {}
        for _ = 1, 6 do
            local l = DrawingManager.NewLine({Thickness = CONFIG.ESP_SKELETON_THICKNESS or 1, Color = col})
            if l then table.insert(skeletonLines, l) end
        end

        DrawingESP[player] = {
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
    end

    function ESPSystem.RemovePlayerESP(player)
        local d = DrawingESP[player]
        if d then
            destroyESPData(d)
            DrawingESP[player] = nil
        end
        ESPSystem.RemoveHighlight(player)
    end

    function ESPSystem.AddHighlight(player)
        if not isSessionAlive() then return end
        if Highlights[player] then return end
        local char = player and player.Character
        if not char or not char.Parent then return end

        local ok, h = pcall(function()
            local hl = Instance.new("Highlight")
            hl.Name = "B0XazChams"
            hl.Adornee = char
            hl.FillColor = FeatureConfig.Chams.FillColor
            hl.OutlineColor = FeatureConfig.Chams.OutlineColor
            hl.FillTransparency = 0.5
            hl.Parent = char
            return hl
        end)
        if ok and h then
            Highlights[player] = h
        end
    end

    function ESPSystem.RemoveHighlight(player)
        if Highlights[player] then
            pcall(function() Highlights[player]:Destroy() end)
            Highlights[player] = nil
        end
    end

    local function hidePlayerDrawings(d)
        if not d then return end
        pcall(function() if d.Box then d.Box.Visible = false end end)
        pcall(function() if d.Name then d.Name.Visible = false end end)
        pcall(function() if d.Health then d.Health.Visible = false end end)
        pcall(function() if d.HealthBG then d.HealthBG.Visible = false end end)
        pcall(function() if d.Distance then d.Distance.Visible = false end end)
        pcall(function() if d.HeadDot then d.HeadDot.Visible = false end end)
        pcall(function() if d.LookLine then d.LookLine.Visible = false end end)
        pcall(function() if d.Tracer then d.Tracer.Visible = false end end)
        if d.Skeleton then
            for i = 1, #d.Skeleton do
                pcall(function() if d.Skeleton[i] then d.Skeleton[i].Visible = false end end)
            end
        end
    end

    local function getBones(char, hum)
        local isR15 = hum.RigType == Enum.HumanoidRigType.R15
        local bones = {}
        local head = char:FindFirstChild("Head")
        if not head then return bones end

        if isR15 then
            local ut = char:FindFirstChild("UpperTorso")
            local lt = char:FindFirstChild("LowerTorso")
            if ut and lt then
                table.insert(bones, {head, ut})
                table.insert(bones, {ut, lt})
                local lua = char:FindFirstChild("LeftUpperArm")
                local rua = char:FindFirstChild("RightUpperArm")
                local lul = char:FindFirstChild("LeftUpperLeg")
                local rul = char:FindFirstChild("RightUpperLeg")
                if lua then table.insert(bones, {ut, lua}) end
                if rua then table.insert(bones, {ut, rua}) end
                if lul then table.insert(bones, {lt, lul}) end
                if rul then table.insert(bones, {lt, rul}) end
            end
        else
            local torso = char:FindFirstChild("Torso")
            if torso then
                table.insert(bones, {head, torso})
                local la = char:FindFirstChild("Left Arm")
                local ra = char:FindFirstChild("Right Arm")
                local ll = char:FindFirstChild("Left Leg")
                local rl = char:FindFirstChild("Right Leg")
                if la then table.insert(bones, {torso, la}) end
                if ra then table.insert(bones, {torso, ra}) end
                if ll then table.insert(bones, {torso, ll}) end
                if rl then table.insert(bones, {torso, rl}) end
            end
        end
        return bones
    end

    local function hookPlayer(p)
        if not isSessionAlive() then return end
        if p == LocalPlayer then return end
        ESPSystem.CreatePlayerESP(p)

        Connections.Add(p.CharacterAdded:Connect(function(c)
            if not isSessionAlive() then return end
            task.wait(0.2)
            if FeatureConfig.Chams.Enabled then
                ESPSystem.RemoveHighlight(p)
                ESPSystem.AddHighlight(p)
            end
        end))

        Connections.Add(p.CharacterRemoving:Connect(function()
            if not isSessionAlive() then return end
            ESPSystem.RemoveHighlight(p)
            if DrawingESP[p] then hidePlayerDrawings(DrawingESP[p]) end
        end))
    end

    function ESPSystem.DestroyAll()
        for player, _ in pairs(DrawingESP) do
            ESPSystem.RemovePlayerESP(player)
        end
        table.clear(DrawingESP)
        for p, _ in pairs(Highlights) do
            ESPSystem.RemoveHighlight(p)
        end
        table.clear(Highlights)
    end

    function ESPSystem.InitializeAll()
        if not isSessionAlive() then return end
        ESPSystem.DestroyAll()

        for _, p in ipairs(Players:GetPlayers()) do
            task.spawn(hookPlayer, p)
        end
        Connections.Add(Players.PlayerAdded:Connect(function(p)
            if not isSessionAlive() then return end
            hookPlayer(p)
        end))
        Connections.Add(Players.PlayerRemoving:Connect(function(p)
            if not isSessionAlive() then return end
            ESPSystem.RemovePlayerESP(p)
        end))
    end

    function ESPSystem.Update()
        if not isSessionAlive() then return end

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

        local myAssets = Utils.GetPlayerAssets(LocalPlayer)
        local myPos = myAssets and myAssets.RootPart.Position
        local espColor = espCfg.Color
        local maxDist = espCfg.MaxDist or 500
        local teamCheck = espCfg.TeamCheck

        local viewportSize = Camera.ViewportSize
        local screenBottom = Vector2.new(viewportSize.X / 2, viewportSize.Y)

        for player, data in pairs(DrawingESP) do
            if not isSessionAlive() then return end

            local assets = Utils.GetPlayerAssets(player)
            if not assets then
                hidePlayerDrawings(data)
                continue
            end

            if teamCheck and Utils.SameTeam(player) then
                hidePlayerDrawings(data)
                ESPSystem.RemoveHighlight(player)
                continue
            end

            local rootPos = assets.RootPart.Position
            local dist3D = myPos and (myPos - rootPos).Magnitude or 0
            if dist3D > maxDist then
                hidePlayerDrawings(data)
                continue
            end

            if hasChams then
                local h = Highlights[player]
                if not h or not h.Parent or h.Adornee ~= assets.Character then
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

            local rootScreen, rootOnScreen = Camera:WorldToViewportPoint(rootPos)
            if not rootOnScreen or rootScreen.Z <= 0 then
                hidePlayerDrawings(data)
                continue
            end

            local headPos = assets.Head.Position
            local headScreen = Camera:WorldToViewportPoint(headPos + Vector3.new(0, 0.5, 0))
            local feetScreen = Camera:WorldToViewportPoint(rootPos - Vector3.new(0, 3, 0))

            local height = math.abs(headScreen.Y - feetScreen.Y)
            local width = height * 0.55
            local halfW = width * 0.5
            local rootScreenPos = Vector2.new(rootScreen.X, rootScreen.Y)
            local headScreenPos = Vector2.new(headScreen.X, headScreen.Y)

            if espCfg.Box and data.Box then
                data.Box.Size = Vector2.new(width, height)
                data.Box.Position = Vector2.new(rootScreenPos.X - halfW, rootScreenPos.Y - height * 0.5)
                data.Box.Color = espColor
                data.Box.Visible = true
            elseif data.Box then
                data.Box.Visible = false
            end

            if espCfg.Name and data.Name then
                data.Name.Text = player.DisplayName or player.Name
                data.Name.Position = Vector2.new(rootScreenPos.X, headScreenPos.Y - 24)
                data.Name.Color = espColor
                data.Name.Visible = true
            elseif data.Name then
                data.Name.Visible = false
            end

            if espCfg.Health and data.Health and data.HealthBG then
                local hum = assets.Humanoid
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
                if data.HealthBG then data.HealthBG.Visible = false end
            end

            if espCfg.Distance and data.Distance then
                data.Distance.Text = math.floor(dist3D) .. "m"
                data.Distance.Position = Vector2.new(rootScreenPos.X, feetScreen.Y + 3)
                data.Distance.Color = espColor
                data.Distance.Visible = true
            elseif data.Distance then
                data.Distance.Visible = false
            end

            if espCfg.HeadDot and data.HeadDot then
                data.HeadDot.Position = headScreenPos
                data.HeadDot.Color = espColor
                data.HeadDot.Visible = true
            elseif data.HeadDot then
                data.HeadDot.Visible = false
            end

            if espCfg.LookDir and data.LookLine then
                local lookWorld = Camera:WorldToViewportPoint(headPos + assets.Head.CFrame.LookVector * 4.5)
                data.LookLine.From = headScreenPos
                data.LookLine.To = Vector2.new(lookWorld.X, lookWorld.Y)
                data.LookLine.Color = espColor
                data.LookLine.Visible = true
            elseif data.LookLine then
                data.LookLine.Visible = false
            end

            if espCfg.Tracers and data.Tracer then
                data.Tracer.From = screenBottom
                data.Tracer.To = rootScreenPos
                data.Tracer.Color = espColor
                data.Tracer.Visible = true
            elseif data.Tracer then
                data.Tracer.Visible = false
            end

            if espCfg.Skeleton and data.Skeleton then
                local bones = getBones(assets.Character, assets.Humanoid)
                local skLines = data.Skeleton
                for i = 1, #skLines do
                    local line = skLines[i]
                    local pair = bones[i]
                    if pair and pair[1] and pair[2] and pair[1].Parent and pair[2].Parent then
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

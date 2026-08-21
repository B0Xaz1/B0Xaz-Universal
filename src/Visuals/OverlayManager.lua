-- src/Visuals/OverlayManager.lua
return function(Context)
    local FeatureConfig = Context.FeatureConfig
    local State = Context.State
    local StatsConfig = Context.StatsConfig
    local CONFIG = Context.CONFIG
    local Utils = Context.Utils
    local DrawingManager = Context.DrawingManager

    getgenv().B0XazDrawings = getgenv().B0XazDrawings or {}

    local fovCircle = DrawingManager.NewCircle({Radius = 100, Color = Color3.fromRGB(0, 200, 255), Thickness = 2, NumSides = 64})
    if fovCircle then table.insert(getgenv().B0XazDrawings, fovCircle) end

    local fpsLabel = DrawingManager.NewText({Size = 14, Color = Color3.fromRGB(255, 255, 255)})
    local pingLabel = DrawingManager.NewText({Size = 14, Color = Color3.fromRGB(255, 255, 255)})
    if fpsLabel then fpsLabel.Center = false; fpsLabel.Outline = true; table.insert(getgenv().B0XazDrawings, fpsLabel) end
    if pingLabel then pingLabel.Center = false; pingLabel.Outline = true; table.insert(getgenv().B0XazDrawings, pingLabel) end

    local crosshairLines = {}
    if DrawingManager.Available then
        for _ = 1, 4 do
            local l = DrawingManager.NewLine({Thickness = 2})
            if l then
                table.insert(crosshairLines, l)
                table.insert(getgenv().B0XazDrawings, l)
            end
        end
    end

    local speedLines, speedLineData = {}, {}
    if DrawingManager.Available then
        for i = 1, (CONFIG.SPEED_LINES_COUNT or 30) do
            local l = DrawingManager.NewLine({Thickness = 1, Color = Color3.fromRGB(200, 230, 255)})
            if l then
                l.Transparency = 0.5
                table.insert(speedLines, l)
                table.insert(getgenv().B0XazDrawings, l)
                speedLineData[i] = {
                    angle = math.random() * math.pi * 2,
                    dist = math.random(CONFIG.SPEED_LINES_MIN_DIST or 150, CONFIG.SPEED_LINES_MAX_DIST or 500)
                }
            end
        end
    end

    local OverlayManager = {
        FPSLabel = fpsLabel,
        PingLabel = pingLabel
    }

    function OverlayManager.UpdateFOVCircle(dt)
        if not fovCircle then return end
        fovCircle.Position = Utils.GetMousePosition()
        if FeatureConfig.Aimbot.FOV.Rainbow then
            State.FOVHue = (State.FOVHue + (dt or 0.016) * 0.5) % 1
            fovCircle.Color = Color3.fromHSV(State.FOVHue, 1, 1)
        else
            fovCircle.Color = FeatureConfig.ESP.Color
        end

        if FeatureConfig.Aimbot.FOV.Pulse then
            fovCircle.Radius = FeatureConfig.Aimbot.FOV.Size + math.sin(State.FOVPulse) * 20
            State.FOVPulse = State.FOVPulse + (dt or 0.016) * 3
        else
            fovCircle.Radius = FeatureConfig.Aimbot.FOV.Size
        end

        fovCircle.Thickness = FeatureConfig.Aimbot.FOV.Thickness
        fovCircle.Filled = FeatureConfig.Aimbot.FOV.Filled
        fovCircle.NumSides = FeatureConfig.Aimbot.FOV.Sides
        fovCircle.Visible = FeatureConfig.Aimbot.FOV.Show and FeatureConfig.Aimbot.Enabled
    end

    function OverlayManager.UpdateCrosshair()
        if not FeatureConfig.Extras.Crosshair.Visible or #crosshairLines < 4 then
            for _, l in ipairs(crosshairLines) do pcall(function() l.Visible = false end) end
            return
        end
        local c = Utils.GetScreenCenter()
        local cx, cy = c.X, c.Y
        local s, g = FeatureConfig.Extras.Crosshair.Size, FeatureConfig.Extras.Crosshair.Gap
        crosshairLines[1].From = Vector2.new(cx - s - g, cy); crosshairLines[1].To = Vector2.new(cx - g, cy)
        crosshairLines[2].From = Vector2.new(cx + g, cy); crosshairLines[2].To = Vector2.new(cx + s + g, cy)
        crosshairLines[3].From = Vector2.new(cx, cy - s - g); crosshairLines[3].To = Vector2.new(cx, cy - g)
        crosshairLines[4].From = Vector2.new(cx, cy + g); crosshairLines[4].To = Vector2.new(cx, cy + s + g)
        for _, l in ipairs(crosshairLines) do
            l.Color = FeatureConfig.Extras.Crosshair.Color
            l.Thickness = FeatureConfig.Extras.Crosshair.Thickness
            l.Visible = true
        end
    end

    function OverlayManager.UpdateSpeedLines(dt)
        if not FeatureConfig.Extras.SpeedLines or #speedLines == 0 then
            for _, l in ipairs(speedLines) do pcall(function() l.Visible = false end) end
            return
        end
        local c = Utils.GetScreenCenter()
        for i, line in ipairs(speedLines) do
            local d = speedLineData[i]
            if not d then continue end
            d.dist = d.dist + (dt or 0.016) * (CONFIG.SPEED_LINES_SPEED or 600)
            if d.dist > (CONFIG.SPEED_LINES_MAX_RANGE or 700) then
                d.dist = math.random(CONFIG.SPEED_LINES_SPAWN_MIN or 50, CONFIG.SPEED_LINES_SPAWN_MAX or 150)
                d.angle = math.random() * math.pi * 2
            end
            local cos, sin = math.cos(d.angle), math.sin(d.angle)
            line.From = Vector2.new(c.X + cos * d.dist, c.Y + sin * d.dist)
            line.To = Vector2.new(c.X + cos * (d.dist + (CONFIG.SPEED_LINES_LENGTH or 60)), c.Y + sin * (d.dist + (CONFIG.SPEED_LINES_LENGTH or 60)))
            line.Transparency = math.clamp(1 - (d.dist / (CONFIG.SPEED_LINES_MAX_RANGE or 700)), 0.1, 1)
            line.Visible = true
        end
    end

    return OverlayManager
end

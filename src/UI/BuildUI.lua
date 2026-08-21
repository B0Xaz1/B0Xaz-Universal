-- src/UI/BuildUI.lua
return function(Context)
    local Players = game:GetService("Players")
    local Workspace = game:GetService("Workspace")
    local Lighting = game:GetService("Lighting")
    local UIS = game:GetService("UserInputService")
    local HttpService = game:GetService("HttpService")

    local LocalPlayer = Players.LocalPlayer
    local Camera = Workspace.CurrentCamera
    local IsMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled

    -- Extract from Context
    local CONFIG = Context.CONFIG
    local ShankUI = Context.ShankUI
    local Theme = Context.Theme
    local FeatureConfig = Context.FeatureConfig
    local State = Context.State
    local StatsConfig = Context.StatsConfig
    local UIRegistry = Context.UIRegistry
    local Utils = Context.Utils
    local Connections = Context.Connections
    local DefaultLighting = Context.DefaultLighting

    local AimbotSystem = Context.AimbotSystem
    local ESPSystem = Context.ESPSystem
    local FlySystem = Context.FlySystem
    local FlingSystem = Context.FlingSystem
    local ConfigSystem = Context.ConfigSystem
    local OverlayManager = Context.OverlayManager

    -- Create Main UI Instance (Only once!)
    local UI = ShankUI.new("B0Xaz Universal")
    Context.UI = UI
    getgenv().B0XazLibrary = UI

    -- Toggle Menu bind
    local _listeningForMenuKey = false
    Connections.Add(UIS.InputBegan:Connect(function(input, processed)
        if _listeningForMenuKey or processed then return end
        if input.KeyCode == State.MenuKeybind then
            State.MenuVisible = not State.MenuVisible
            UI.Main.Visible = State.MenuVisible
        end
    end))

    -- TAB: Aimbot
    local aimbotTab = UI:AddTab("Aimbot")
    local aimMain = aimbotTab:AddSection("Main")
    UIRegistry.Aimbot_Enabled = aimMain:AddToggle("Aimbot Enabled", FeatureConfig.Aimbot.Enabled, function(v) FeatureConfig.Aimbot.Enabled = v; if not v then AimbotSystem.LockOff() end end)
    UIRegistry.Aimbot_Keybind = aimMain:AddTextbox("Keybind", FeatureConfig.Aimbot.Keybind, function(text, enter)
        if not enter then return end
        local k = (text or ""):gsub("%s",""):upper():sub(1,1)
        if Utils.GetKeyCode(k) then FeatureConfig.Aimbot.Keybind = k; UI:Notify("Keybind", "Set to " .. k, nil, Theme.Success) else UI:Notify("Keybind", "Invalid", nil, Theme.Danger) end
    end, "Key")
    UIRegistry.Aimbot_LockMode = aimMain:AddDropdown("Lock Mode", {"Toggle","Hold"}, function(v) FeatureConfig.Aimbot.LockMode = v; AimbotSystem.LockOff() end, FeatureConfig.Aimbot.LockMode)
    UIRegistry.Aimbot_Hitpart = aimMain:AddDropdown("Hit Part", {"HumanoidRootPart","Head","UpperTorso","LowerTorso"}, function(v) FeatureConfig.Aimbot.Hitpart = v end, FeatureConfig.Aimbot.Hitpart)
    UIRegistry.Aimbot_AirHitpart = aimMain:AddDropdown("Air Hit Part", {"Head","HumanoidRootPart","UpperTorso","LowerTorso"}, function(v) FeatureConfig.Aimbot.AirHitpart = v end, FeatureConfig.Aimbot.AirHitpart)
    UIRegistry.Aimbot_Smoothness = aimMain:AddSlider("Smoothness", math.floor(FeatureConfig.Aimbot.Smoothness*10), 1, 50, function(v) FeatureConfig.Aimbot.Smoothness = math.max(v/10, CONFIG.AIM_MIN_SMOOTHNESS) end)
    UIRegistry.Aimbot_ShakeIntensity = aimMain:AddSlider("Shake", FeatureConfig.Aimbot.ShakeIntensity, 0, 10, function(v) FeatureConfig.Aimbot.ShakeIntensity = v end)

    local aimCheck = aimbotTab:AddSection("Checks")
    UIRegistry.Aimbot_TeamCheck = aimCheck:AddToggle("Team Check", FeatureConfig.Aimbot.TeamCheck, function(v) FeatureConfig.Aimbot.TeamCheck = v end)
    UIRegistry.Aimbot_VisCheck = aimCheck:AddToggle("Visibility Check", FeatureConfig.Aimbot.VisCheck, function(v) FeatureConfig.Aimbot.VisCheck = v end)
    UIRegistry.Aimbot_LockNPC = aimCheck:AddToggle("Target NPCs", FeatureConfig.Aimbot.LockNPC, function(v) FeatureConfig.Aimbot.LockNPC = v end)
    UIRegistry.Aimbot_MaxDistance = aimCheck:AddSlider("Max Distance", FeatureConfig.Aimbot.MaxDistance, 50, 500, function(v) FeatureConfig.Aimbot.MaxDistance = v end)

    local aimFov = aimbotTab:AddSection("FOV Circle")
    UIRegistry.Aimbot_FOV_Show = aimFov:AddToggle("Show FOV", FeatureConfig.Aimbot.FOV.Show, function(v) FeatureConfig.Aimbot.FOV.Show = v end)
    UIRegistry.Aimbot_FOV_Filled = aimFov:AddToggle("Filled", FeatureConfig.Aimbot.FOV.Filled, function(v) FeatureConfig.Aimbot.FOV.Filled = v end)
    UIRegistry.Aimbot_FOV_Rainbow = aimFov:AddToggle("Rainbow", FeatureConfig.Aimbot.FOV.Rainbow, function(v) FeatureConfig.Aimbot.FOV.Rainbow = v end)
    UIRegistry.Aimbot_FOV_Pulse = aimFov:AddToggle("Pulse", FeatureConfig.Aimbot.FOV.Pulse, function(v) FeatureConfig.Aimbot.FOV.Pulse = v end)
    UIRegistry.Aimbot_FOV_Size = aimFov:AddSlider("FOV Size", FeatureConfig.Aimbot.FOV.Size, 10, 500, function(v) FeatureConfig.Aimbot.FOV.Size = v end)
    UIRegistry.Aimbot_FOV_Thickness = aimFov:AddSlider("Thickness", FeatureConfig.Aimbot.FOV.Thickness, 1, 10, function(v) FeatureConfig.Aimbot.FOV.Thickness = v end)
    UIRegistry.Aimbot_FOV_Sides = aimFov:AddSlider("Sides", FeatureConfig.Aimbot.FOV.Sides, 3, 100, function(v) FeatureConfig.Aimbot.FOV.Sides = v end)

    local aimPred = aimbotTab:AddSection("Prediction")
    UIRegistry.Aimbot_Prediction_Horizontal = aimPred:AddSlider("Horizontal", math.floor(FeatureConfig.Aimbot.Prediction.Horizontal*200), 0, 100, function(v) FeatureConfig.Aimbot.Prediction.Horizontal = v/200 end)
    UIRegistry.Aimbot_Prediction_Vertical = aimPred:AddSlider("Vertical", math.floor(FeatureConfig.Aimbot.Prediction.Vertical*200), 0, 100, function(v) FeatureConfig.Aimbot.Prediction.Vertical = v/200 end)
    aimPred:AddButton("Reset Prediction", function()
        FeatureConfig.Aimbot.Prediction.Horizontal = 0.165
        FeatureConfig.Aimbot.Prediction.Vertical = 0.100
        if UIRegistry.Aimbot_Prediction_Horizontal then UIRegistry.Aimbot_Prediction_Horizontal.Set(33, true) end
        if UIRegistry.Aimbot_Prediction_Vertical then UIRegistry.Aimbot_Prediction_Vertical.Set(20, true) end
        UI:Notify("Prediction", "Reset", nil, Theme.Success)
    end)

    local aimTrig = aimbotTab:AddSection("Triggerbot")
    UIRegistry.Aimbot_Triggerbot_Enabled = aimTrig:AddToggle("Enable Triggerbot", false, function(v) FeatureConfig.Aimbot.Triggerbot.Enabled = v end)
    UIRegistry.Aimbot_Triggerbot_Delay = aimTrig:AddSlider("Trigger Delay", 5, 0, 50, function(v) FeatureConfig.Aimbot.Triggerbot.Delay = v / 100 end, " ms")

    -- TAB: ESP
    local espTab = UI:AddTab("ESP")
    local espMain = espTab:AddSection("ESP")
    UIRegistry.ESP_Enabled = espMain:AddToggle("Enable ESP", FeatureConfig.ESP.Enabled, function(v) FeatureConfig.ESP.Enabled = v end)
    UIRegistry.ESP_Box = espMain:AddToggle("Box", FeatureConfig.ESP.Box, function(v) FeatureConfig.ESP.Box = v end)
    UIRegistry.ESP_Name = espMain:AddToggle("Name", FeatureConfig.ESP.Name, function(v) FeatureConfig.ESP.Name = v end)
    UIRegistry.ESP_Health = espMain:AddToggle("Health Bar", FeatureConfig.ESP.Health, function(v) FeatureConfig.ESP.Health = v end)
    UIRegistry.ESP_Distance = espMain:AddToggle("Distance", FeatureConfig.ESP.Distance, function(v) FeatureConfig.ESP.Distance = v end)
    UIRegistry.ESP_Tracers = espMain:AddToggle("Tracers", FeatureConfig.ESP.Tracers, function(v) FeatureConfig.ESP.Tracers = v end)
    UIRegistry.ESP_Skeleton = espMain:AddToggle("Skeleton", FeatureConfig.ESP.Skeleton, function(v) FeatureConfig.ESP.Skeleton = v end)
    UIRegistry.ESP_HeadDot = espMain:AddToggle("Head Dot", FeatureConfig.ESP.HeadDot, function(v) FeatureConfig.ESP.HeadDot = v end)
    UIRegistry.ESP_LookDir = espMain:AddToggle("Look Direction", FeatureConfig.ESP.LookDir, function(v) FeatureConfig.ESP.LookDir = v end)
    UIRegistry.ESP_TeamCheck = espMain:AddToggle("Team Check", FeatureConfig.ESP.TeamCheck, function(v) FeatureConfig.ESP.TeamCheck = v end)

    local espSet = espTab:AddSection("Settings")
    UIRegistry.ESP_MaxDist = espSet:AddSlider("Max Distance", FeatureConfig.ESP.MaxDist, 100, 2000, function(v) FeatureConfig.ESP.MaxDist = v end)
    UIRegistry.ESP_Color = espSet:AddColorPicker("ESP Color", FeatureConfig.ESP.Color, function(c) FeatureConfig.ESP.Color = c end)

    local chamsSec = espTab:AddSection("Chams")
    UIRegistry.ESP_Chams_Enabled = chamsSec:AddToggle("Enable Chams", FeatureConfig.Chams.Enabled, function(v)
        FeatureConfig.Chams.Enabled = v
        if v then 
            for _, p in ipairs(Players:GetPlayers()) do 
                if p ~= LocalPlayer and Utils.IsAlive(p) then 
                    local teamSkip = FeatureConfig.ESP.TeamCheck and Utils.SameTeam(p)
                    if not teamSkip then ESPSystem.RemoveHighlight(p); ESPSystem.AddHighlight(p) end 
                end 
            end
        else 
            for _, p in ipairs(Players:GetPlayers()) do ESPSystem.RemoveHighlight(p) end 
        end
    end)
    UIRegistry.ESP_Chams_FillColor = chamsSec:AddColorPicker("Fill Color", FeatureConfig.Chams.FillColor, function(c) FeatureConfig.Chams.FillColor = c end)
    UIRegistry.ESP_Chams_OutlineColor = chamsSec:AddColorPicker("Outline Color", FeatureConfig.Chams.OutlineColor, function(c) FeatureConfig.Chams.OutlineColor = c end)

    -- TAB: Movement
    local moveTab = UI:AddTab("Movement")
    local charSec = moveTab:AddSection("Character")
    UIRegistry.Movement_Speed = charSec:AddSlider("Walk Speed", FeatureConfig.Movement.Speed, 16, 500, function(v) FeatureConfig.Movement.Speed = v; local h = Utils.GetHumanoid(); if h then h.WalkSpeed = v end end, " ws")
    UIRegistry.Movement_JumpPower = charSec:AddSlider("Jump Power", FeatureConfig.Movement.JumpPower, 50, 500, function(v) FeatureConfig.Movement.JumpPower = v; local h = Utils.GetHumanoid(); if h then h.JumpPower = v end end, " jp")
    UIRegistry.Movement_SprintEnabled = charSec:AddToggle("Sprint (Hold Shift)", false, function(v) FeatureConfig.Movement.SprintEnabled = v end)
    UIRegistry.Movement_SprintSpeed = charSec:AddSlider("Sprint Speed", 30, 16, 500, function(v) FeatureConfig.Movement.SprintSpeed = v end, " ws")
    UIRegistry.Movement_InfJump = charSec:AddToggle("Infinite Jump", FeatureConfig.Movement.InfJump, function(v) FeatureConfig.Movement.InfJump = v end)
    charSec:AddToggle("Freeze Character", false, function(v) local h, r = Utils.GetHumanoid(), Utils.GetRootPart(); if h then h.PlatformStand = v end; if r then r.Anchored = v end end)

    local flySec = moveTab:AddSection("Fly")
    UIRegistry.Movement_FlySpeed = flySec:AddSlider("Fly Speed", FeatureConfig.Movement.FlySpeed, 10, 500, function(v) FeatureConfig.Movement.FlySpeed = v end)
    UIRegistry.Movement_FlyEnabled = flySec:AddToggle("Enable Fly", FeatureConfig.Movement.FlyEnabled, function(v) if v then FlySystem.Start() else FlySystem.Stop() end end)
    if not IsMobile then flySec:AddKeybind("Fly Key", Enum.KeyCode.F, function() if FeatureConfig.Movement.FlyEnabled then FlySystem.Stop() else FlySystem.Start() end end) end

    local worldSec = moveTab:AddSection("World")
    worldSec:AddSlider("Gravity", math.floor(Workspace.Gravity), 0, 300, function(v) Workspace.Gravity = v end)
    worldSec:AddSlider("Hip Height", 0, 0, 48, function(v) local h = Utils.GetHumanoid(); if h then h.HipHeight = v + 2 end end)
    UIRegistry.Camera_FOV = worldSec:AddSlider("Camera FOV", FeatureConfig.Camera.FOV, 70, 120, function(v) FeatureConfig.Camera.FOV = v end)
    worldSec:AddSlider("Camera Zoom", 400, 10, 500, function(v) LocalPlayer.CameraMaxZoomDistance = v end)

    local tpSec = moveTab:AddSection("Teleports")
    tpSec:AddButton("Save Position", function() 
        local r = Utils.GetRootPart()
        if not r then UI:Notify("Pos", "No character", nil, Theme.Danger); return end
        State.SavedPosition = r.CFrame
        UI:Notify("Pos", "Saved", nil, Theme.Success) 
    end)
    tpSec:AddButton("Return to Saved", function() 
        local r = Utils.GetRootPart()
        if r and State.SavedPosition then 
            r.CFrame = State.SavedPosition
            UI:Notify("Pos", "Returned", nil, Theme.Success) 
        else 
            UI:Notify("Pos", "No saved position", nil, Theme.Danger) 
        end 
    end)
    tpSec:AddToggle(IsMobile and "Teleport on Tap" or "TP to Mouse (CTRL+Click)", false, function(v) State.TpToMouse = v end)

    -- TAB: Players
    local playersTab = UI:AddTab("Players")
    local selSec = playersTab:AddSection("Selection")
    local playerDropdown = selSec:AddDropdown("Target", Utils.GetPlayerNameList(true), function(v) State.SelectedPlayer = (v ~= "None" and v ~= "") and v or nil end)
    selSec:AddButton("Refresh List", function()
        local list = Utils.GetPlayerNameList(true); playerDropdown.Refresh(list, true)
        if State.SelectedPlayer and not table.find(list, State.SelectedPlayer) then 
            State.SelectedPlayer = list[1]
            playerDropdown.Set(State.SelectedPlayer or "None", true) 
        end
        UI:Notify("Players", "Refreshed (" .. #list .. ")", nil, Theme.Success)
    end)

    Connections.Add(Players.PlayerAdded:Connect(function() task.wait(0.5); playerDropdown.Refresh(Utils.GetPlayerNameList(true), true) end))
    Connections.Add(Players.PlayerRemoving:Connect(function(p)
        task.wait(0.1); local list = Utils.GetPlayerNameList(true); playerDropdown.Refresh(list, State.SelectedPlayer ~= p.Name)
        if State.SelectedPlayer == p.Name then 
            State.SelectedPlayer = list[1]
            playerDropdown.Set(State.SelectedPlayer or "None", true) 
        end
    end))

    local actSec = playersTab:AddSection("Actions")
    actSec:AddButton("TP to Selected", function()
        if not State.SelectedPlayer then UI:Notify("TP", "Select player", nil, Theme.Danger); return end
        local t = Utils.GetPlayerByName(State.SelectedPlayer); local mr = Utils.GetRootPart()
        if t and t.Character and mr then 
            local r = t.Character:FindFirstChild("HumanoidRootPart")
            if r then mr.CFrame = r.CFrame + Vector3.new(3,0,0); UI:Notify("TP", "Done", nil, Theme.Success); return end 
        end
        UI:Notify("TP", "Failed", nil, Theme.Danger)
    end)
    actSec:AddButton("TP to Aim Target", function()
        local mr = Utils.GetRootPart()
        if State.AimTarget and mr then 
            local r = State.AimTarget.model:FindFirstChild("HumanoidRootPart")
            if r then mr.CFrame = r.CFrame * CFrame.new(0,0,3); UI:Notify("TP", "Done", nil, Theme.Success); return end 
        end
        UI:Notify("TP", "No target", nil, Theme.Danger)
    end)
    actSec:AddButton("Spectate Selected", function()
        if not State.SelectedPlayer then UI:Notify("Spectate", "Select player", nil, Theme.Danger); return end
        local t = Utils.GetPlayerByName(State.SelectedPlayer)
        if t and t.Character then 
            local h = t.Character:FindFirstChildOfClass("Humanoid")
            if h then Camera.CameraSubject = h; Camera.CameraType = Enum.CameraType.Follow; UI:Notify("Spectate", State.SelectedPlayer, nil, Theme.Success); return end 
        end
        UI:Notify("Spectate", "Failed", nil, Theme.Danger)
    end)
    actSec:AddButton("Stop Spectating", function() local h = Utils.GetHumanoid(); if h then Camera.CameraSubject = h; Camera.CameraType = Enum.CameraType.Custom end; UI:Notify("Spectate", "Reset") end)
    actSec:AddToggle("Loop TP to Selected", false, function(v) State.LoopTeleport = v end)

    local flingSec = playersTab:AddSection("Fling")
    flingSec:AddToggle("Touch Fling", false, function(v)
        if v then FlingSystem.Start(); UI:Notify("Fling", "Enabled - walk into players", nil, Theme.Success)
        else FlingSystem.Stop(); UI:Notify("Fling", "Disabled") end
    end)

    local orbitSec = playersTab:AddSection("Orbit")
    orbitSec:AddSlider("Radius", State.OrbitRadius, 3, 50, function(v) State.OrbitRadius = v end)
    orbitSec:AddSlider("Speed", State.OrbitSpeed, 1, 20, function(v) State.OrbitSpeed = v end)
    orbitSec:AddToggle("Orbit Selected", false, function(v) State.OrbitEnabled = v end)
    orbitSec:AddToggle("Loop Jump on Target", false, function(v) State.LoopJump = v end)
    orbitSec:AddToggle("Spin Around Target", false, function(v) State.SpinTarget = v end)

    -- TAB: Extras
    local extrasTab = UI:AddTab("Extras")
    local hitSec = extrasTab:AddSection("Hitbox")
    UIRegistry.Extras_Hitbox_Enabled = hitSec:AddToggle("Hitbox Expander", false, function(v) 
        FeatureConfig.Extras.Hitbox.Enabled = v
        if not v and Context.ResetHitboxes then Context.ResetHitboxes() end 
    end)
    UIRegistry.Extras_Hitbox_Size = hitSec:AddSlider("Hitbox Size", FeatureConfig.Extras.Hitbox.Size, 4, 60, function(v) FeatureConfig.Extras.Hitbox.Size = v end)

    local spinSec = extrasTab:AddSection("Spin Bot")
    UIRegistry.Extras_SpinBot_Enabled = spinSec:AddToggle("Enable Spin Bot", false, function(v) FeatureConfig.Extras.SpinBot.Enabled = v end)
    UIRegistry.Extras_SpinBot_Speed = spinSec:AddSlider("Spin Speed", FeatureConfig.Extras.SpinBot.Speed, 1, 500, function(v) FeatureConfig.Extras.SpinBot.Speed = v end)

    local crossSec = extrasTab:AddSection("Crosshair")
    UIRegistry.Extras_Crosshair_Visible = crossSec:AddToggle("Show Crosshair", false, function(v) FeatureConfig.Extras.Crosshair.Visible = v end)
    UIRegistry.Extras_Crosshair_Size = crossSec:AddSlider("Size", FeatureConfig.Extras.Crosshair.Size, 4, 40, function(v) FeatureConfig.Extras.Crosshair.Size = v end)
    UIRegistry.Extras_Crosshair_Gap = crossSec:AddSlider("Gap", FeatureConfig.Extras.Crosshair.Gap, 0, 20, function(v) FeatureConfig.Extras.Crosshair.Gap = v end)
    UIRegistry.Extras_Crosshair_Thickness = crossSec:AddSlider("Thickness", FeatureConfig.Extras.Crosshair.Thickness, 1, 6, function(v) FeatureConfig.Extras.Crosshair.Thickness = v end)
    UIRegistry.Extras_Crosshair_Color = crossSec:AddColorPicker("Color", FeatureConfig.Extras.Crosshair.Color, function(c) FeatureConfig.Extras.Crosshair.Color = c end)

    local visSec = extrasTab:AddSection("Visuals")
    UIRegistry.Extras_SpeedLines = visSec:AddToggle("Speed Lines", false, function(v) FeatureConfig.Extras.SpeedLines = v end)
    UIRegistry.Extras_Wallbang = visSec:AddToggle("Wallbang", false, function(v)
        FeatureConfig.Extras.Wallbang = v; local myChar = Utils.GetCharacter()
        for _, o in ipairs(Workspace:GetDescendants()) do
            if o:IsA("BasePart") and (not myChar or not o:IsDescendantOf(myChar)) then
                if v then 
                    if not o:GetAttribute("B0XazOrigT") then o:SetAttribute("B0XazOrigT", o.Transparency) end
                    o.Transparency = math.max(o.Transparency, 0.85)
                else 
                    local orig = o:GetAttribute("B0XazOrigT")
                    if orig ~= nil then o.Transparency = orig; o:SetAttribute("B0XazOrigT", nil) end 
                end
            end
        end
    end)

    local lightSec = extrasTab:AddSection("Lighting")
    UIRegistry.Visuals_Fullbright = lightSec:AddToggle("Fullbright", false, function(v) 
        FeatureConfig.Visuals.Fullbright = v
        if not v then 
            Lighting.Ambient = DefaultLighting.Ambient
            Lighting.OutdoorAmbient = DefaultLighting.OutdoorAmbient
            Lighting.Brightness = DefaultLighting.Brightness
            Lighting.GlobalShadows = DefaultLighting.GlobalShadows 
        end 
    end)
    lightSec:AddSlider("Clock Time", math.floor(Lighting.ClockTime), 0, 24, function(v) Lighting.ClockTime = v end)
    lightSec:AddButton("Reset Lighting", function() 
        for k,v in pairs(DefaultLighting) do pcall(function() Lighting[k] = v end) end
        UI:Notify("Lighting", "Reset", nil, Theme.Success) 
    end)

    local perfSec = extrasTab:AddSection("Performance")
    perfSec:AddToggle("Show FPS", false, function(v) StatsConfig.ShowFPS = v; if OverlayManager.FPSLabel then OverlayManager.FPSLabel.Visible = v end end)
    perfSec:AddToggle("Show Ping", false, function(v) StatsConfig.ShowPing = v; if OverlayManager.PingLabel then OverlayManager.PingLabel.Visible = v end end)
    perfSec:AddToggle("Remove Shadows", false, function(v) 
        Lighting.GlobalShadows = not v
        for _, o in ipairs(Workspace:GetDescendants()) do if o:IsA("BasePart") then o.CastShadow = not v end end 
    end)
    perfSec:AddToggle("Disable Particles", false, function(v) 
        for _, o in ipairs(Workspace:GetDescendants()) do 
            if o:IsA("ParticleEmitter") or o:IsA("Trail") or o:IsA("Smoke") or o:IsA("Fire") or o:IsA("Sparkles") then 
                pcall(function() o.Enabled = not v end) 
            end 
        end 
    end)
    perfSec:AddButton("Unlock FPS", function() pcall(function() setfpscap(999) end); UI:Notify("FPS", "Unlocked", nil, Theme.Success) end)
    perfSec:AddButton("Cap FPS 60", function() pcall(function() setfpscap(60) end); UI:Notify("FPS", "Capped") end)

    local miscSec = extrasTab:AddSection("Misc")
    miscSec:AddToggle("Anti-AFK", false, function(v)
        if v then 
            Connections.Add(LocalPlayer.Idled:Connect(function() 
                pcall(function() 
                    local VU = game:GetService("VirtualUser")
                    VU:CaptureController()
                    VU:ClickButton2(Vector2.new()) 
                end) 
            end))
            UI:Notify("Anti-AFK", "On", nil, Theme.Success) 
        end
    end)
    miscSec:AddToggle("Auto Rejoin on Kick", false, function(v)
        if v then
            Connections.Add(LocalPlayer.Kicked:Connect(function()
                Utils.PrepareTeleport()
                task.wait(3)
                pcall(function() game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer) end)
            end))
            UI:Notify("Auto Rejoin", "On", nil, Theme.Success)
        end
    end)
    miscSec:AddButton("Server Hop", function()
        UI:Notify("Server Hop", "Finding server...", nil, Theme.Accent)
        task.spawn(function()
            local ok, servers = pcall(function() return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")) end)
            if not ok or not servers or not servers.data then UI:Notify("Server Hop", "Failed to fetch servers", nil, Theme.Danger); return end
            for _, server in ipairs(servers.data) do
                if server.id ~= game.JobId and server.playing and server.maxPlayers and server.playing < server.maxPlayers then
                    Utils.PrepareTeleport()
                    pcall(function() game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer) end)
                    return
                end
            end
            UI:Notify("Server Hop", "No servers found", nil, Theme.Danger)
        end)
    end)

    do
        local menuKeyBtn = nil
        local _, menuKeyContent = (function()
            local secRef = miscSec
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, 34)
            row.BackgroundTransparency = 1
            row.Parent = secRef.Frame
            
            local lbl = Instance.new("TextLabel")
            lbl.Text = "Menu Toggle Key"
            lbl.Font = Enum.Font.Gotham
            lbl.TextSize = 12
            lbl.TextColor3 = Theme.Text
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.BackgroundTransparency = 1
            lbl.Position = UDim2.new(0, 10, 0, 0)
            lbl.Size = UDim2.new(1, -80, 1, 0)
            lbl.Parent = row

            menuKeyBtn = Instance.new("TextButton")
            menuKeyBtn.Text = State.MenuKeybind.Name
            menuKeyBtn.Font = Enum.Font.Gotham
            menuKeyBtn.TextSize = 11
            menuKeyBtn.TextColor3 = Theme.Text
            menuKeyBtn.BackgroundColor3 = Theme.Elem
            menuKeyBtn.BorderSizePixel = 0
            menuKeyBtn.Size = UDim2.new(0, 58, 0, 20)
            menuKeyBtn.Position = UDim2.new(1, -66, 0.5, -10)
            menuKeyBtn.AutoButtonColor = false
            menuKeyBtn.Parent = row
            Instance.new("UICorner", menuKeyBtn).CornerRadius = UDim.new(0, 4)

            table.insert(secRef.Elements, {Container = row, Name = "Menu Toggle Key"})
            return row, row
        end)()

        menuKeyBtn.MouseButton1Click:Connect(function()
            _listeningForMenuKey = true
            menuKeyBtn.Text = "..."
            menuKeyBtn.TextColor3 = Theme.Accent
        end)
        Connections.Add(UIS.InputBegan:Connect(function(input, processed)
            if _listeningForMenuKey and input.UserInputType == Enum.UserInputType.Keyboard then
                if input.KeyCode ~= Enum.KeyCode.Escape then
                    State.MenuKeybind = input.KeyCode
                    menuKeyBtn.Text = input.KeyCode.Name
                else
                    menuKeyBtn.Text = State.MenuKeybind.Name
                end
                menuKeyBtn.TextColor3 = Theme.Text
                _listeningForMenuKey = false
            end
        end))
    end

    -- TAB: Config
    local cfgTab = UI:AddTab("Config")
    local cfgSec = cfgTab:AddSection("Manage")
    local cfgState = {Selected = nil, Name = "MyConfig"}
    local function getCfgList() local n = ConfigSystem.GetSavedNames(); return #n > 0 and n or {"None"} end
    local cfgDropdown = cfgSec:AddDropdown("Saved Configs", getCfgList(), function(v) cfgState.Selected = v ~= "None" and v or nil end)
    cfgSec:AddButton("Refresh", function() cfgDropdown.Refresh(getCfgList(), true); UI:Notify("Configs", "Refreshed") end)
    cfgSec:AddTextbox("Config Name", cfgState.Name, function(t) if type(t) == "string" and #t > 0 then cfgState.Name = Utils.SanitizeFileName(t) end end, "Name")
    cfgSec:AddButton("Save Config", function() 
        local name = Utils.SanitizeFileName(cfgState.Name or "")
        if #name == 0 then UI:Notify("Config", "Enter name", nil, Theme.Danger); return end
        local ok, err = ConfigSystem.Save(name)
        if ok then 
            cfgDropdown.Refresh(getCfgList(), true)
            UI:Notify("Saved", name, nil, Theme.Success) 
        else 
            UI:Notify("Failed", tostring(err), nil, Theme.Danger) 
        end 
    end)
    cfgSec:AddButton("Load Selected", function() 
        if not cfgState.Selected then UI:Notify("Config", "Select one", nil, Theme.Danger); return end
        local ok, err = ConfigSystem.Load(cfgState.Selected)
        if ok then UI:Notify("Loaded", cfgState.Selected, nil, Theme.Success) else UI:Notify("Failed", tostring(err), nil, Theme.Danger) end 
    end)
    cfgSec:AddButton("Delete Selected", function() 
        if not cfgState.Selected then UI:Notify("Config", "Select one", nil, Theme.Danger); return end
        ConfigSystem.Delete(cfgState.Selected)
        cfgState.Selected = nil
        cfgDropdown.Refresh(getCfgList())
        UI:Notify("Deleted", "OK", nil, Theme.Success) 
    end)

    local cfgIO = cfgTab:AddSection("Import / Export")
    local rawImportString = ""

    cfgIO:AddButton("Copy Config to Clipboard", function()
        local ok, encoded = pcall(function() return HttpService:JSONEncode(ConfigSystem.Serialize()) end)
        if ok then
            local ok2 = pcall(function() setclipboard(encoded) end)
            if ok2 then UI:Notify("Export", "Copied to clipboard!", nil, Theme.Success) else UI:Notify("Export", "Clipboard function unavailable", nil, Theme.Danger) end
        else
            UI:Notify("Export", "Failed to encode config", nil, Theme.Danger)
        end
    end)

    cfgIO:AddTextbox("Paste Config Data", "", function(v) rawImportString = v end, "JSON Config String")

    cfgIO:AddButton("Import Config from Textbox", function()
        if not rawImportString or #rawImportString == 0 then
            UI:Notify("Import", "Please paste config data first", nil, Theme.Danger)
            return
        end
        local ok, data = pcall(function() return HttpService:JSONDecode(rawImportString) end)
        if ok and type(data) == "table" then
            ConfigSystem.Deserialize(data)
            ConfigSystem.UpdateUI()

            local saveName = Utils.SanitizeFileName(cfgState.Name or "ImportedConfig")
            if #saveName == 0 then saveName = "ImportedConfig" end
            local saved, saveErr = ConfigSystem.Save(saveName)
            if saved then
                cfgDropdown.Refresh(getCfgList(), true)
                UI:Notify("Import", "Applied & saved as: " .. saveName, nil, Theme.Success)
            else
                UI:Notify("Import", "Applied, but failed to save: " .. tostring(saveErr), nil, Theme.Danger)
            end
        else
            UI:Notify("Import", "Invalid config format", nil, Theme.Danger)
        end
    end)

    return UI
end

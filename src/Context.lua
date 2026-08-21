-- src/Context.lua
return function(CONFIG, DefaultLighting, Utils, DrawingManager)
    getgenv().B0XazConnections = getgenv().B0XazConnections or {}
    getgenv().B0XazThreads = getgenv().B0XazThreads or {}
    getgenv().B0XazDrawings = getgenv().B0XazDrawings or {}

    local _rawConnections = getgenv().B0XazConnections
    local _rawThreads = getgenv().B0XazThreads

    local Connections = {}
    function Connections.Add(conn)
        if conn then table.insert(_rawConnections, conn) end
        return conn
    end
    function Connections.Track(th)
        if th then table.insert(_rawThreads, th) end
        return th
    end
    function Connections.DisconnectAll()
        for i = #_rawConnections, 1, -1 do
            pcall(function()
                local c = _rawConnections[i]
                if c and c.Connected then c:Disconnect() end
            end)
            _rawConnections[i] = nil
        end
        for i = #_rawThreads, 1, -1 do
            pcall(function() task.cancel(_rawThreads[i]) end)
            _rawThreads[i] = nil
        end
    end

    local FeatureConfig = {
        Aimbot = {
            Enabled = false,
            Keybind = "C",
            Hitpart = "HumanoidRootPart",
            AirHitpart = "Head",
            Smoothness = 1,
            LockMode = "Toggle",
            Prediction = {Horizontal = 0.165, Vertical = 0.100},
            TeamCheck = false,
            VisCheck = false,
            MaxDistance = 250,
            ShakeIntensity = 0,
            LockNPC = false,
            Triggerbot = {Enabled = false, Delay = 0.05},
            FOV = {Size = 100, Show = false, Filled = false, Thickness = 2, Sides = 64, Rainbow = false, Pulse = false},
        },
        Movement = {
            Speed = 16,
            JumpPower = 50,
            InfJump = false,
            FlyEnabled = false,
            FlySpeed = 50,
            MobileFlyUp = false,
            MobileFlyDown = false,
            SprintEnabled = false,
            SprintSpeed = 30,
            CFrameSpeed = false,
            CFrameSpeedValue = 50,
            Bhop = false,
        },
        ESP = {
            Enabled = false,
            Box = false,
            Name = false,
            Health = false,
            Distance = false,
            Tracers = false,
            Skeleton = false,
            HeadDot = false,
            LookDir = false,
            TeamCheck = false,
            MaxDist = 500,
            Color = Color3.fromRGB(0, 200, 255),
        },
        Chams = {
            Enabled = false,
            FillColor = Color3.fromRGB(0, 170, 255),
            OutlineColor = Color3.fromRGB(255, 255, 255)
        },
        Camera = {FOV = 90},
        Visuals = {Fullbright = false},
        Extras = {
            Hitbox = {Enabled = false, Size = 10},
            SpinBot = {Enabled = false, Speed = 20},
            Crosshair = {Visible = false, Size = 12, Gap = 4, Thickness = 2, Color = Color3.fromRGB(255, 255, 255)},
            SpeedLines = false,
            Wallbang = false,
        },
        Game = {
            DoorPhase = false,
            DoorGlow = true,
            GlowColor = Color3.fromRGB(0, 200, 220),
            PhaseTransparency = 0.65,
            NoSpread = false,
            FastFire = false,
            ForceAuto = false,
            ForceRange = false,
            FireRateValue = 0.001,
            RangeValue = 10000,
        }
    }

    local State = {
        AimTarget = nil,
        AimHoldActive = false,
        AimLocked = false,
        AimSettleCounter = 0,
        SelectedPlayer = nil,
        SavedPosition = nil,
        OriginalHitboxSizes = {},
        FlyBodyVelocity = nil,
        FlyBodyGyro = nil,
        SpinBotAngle = 0,
        OrbitAngle = 0,
        SpinTargetAngle = 0,
        FOVHue = 0,
        FOVPulse = 0,
        LoopTeleport = false,
        OrbitEnabled = false,
        OrbitRadius = 8,
        OrbitSpeed = 2,
        LoopJump = false,
        SpinTarget = false,
        TpToMouse = false,
        MenuVisible = true,
        MenuKeybind = Enum.KeyCode.RightShift,
    }
    getgenv().B0XazState = State

    local StatsConfig = {ShowFPS = false, ShowPing = false}

    Utils.MakeFolder(CONFIG.FOLDER)

    return {
        CONFIG = CONFIG,
        DefaultLighting = DefaultLighting,
        Utils = Utils,
        DrawingManager = DrawingManager,
        Connections = Connections,
        FeatureConfig = FeatureConfig,
        State = State,
        StatsConfig = StatsConfig,
        UIRegistry = {}
    }
end

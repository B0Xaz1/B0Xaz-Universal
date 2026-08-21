-- src/Systems/ConfigSystem.lua
return function(Context)
    local HttpService = game:GetService("HttpService")
    local FeatureConfig = Context.FeatureConfig
    local CONFIG = Context.CONFIG
    local Utils = Context.Utils
    local UIRegistry = Context.UIRegistry

    local ConfigSystem = {}

    function ConfigSystem.Serialize()
        return {
            Aimbot = {
                Enabled = FeatureConfig.Aimbot.Enabled, Keybind = FeatureConfig.Aimbot.Keybind, 
                Hitpart = FeatureConfig.Aimbot.Hitpart, AirHitpart = FeatureConfig.Aimbot.AirHitpart, 
                Smoothness = FeatureConfig.Aimbot.Smoothness, LockMode = FeatureConfig.Aimbot.LockMode, 
                Prediction = table.clone(FeatureConfig.Aimbot.Prediction), TeamCheck = FeatureConfig.Aimbot.TeamCheck, 
                VisCheck = FeatureConfig.Aimbot.VisCheck, MaxDistance = FeatureConfig.Aimbot.MaxDistance, 
                ShakeIntensity = FeatureConfig.Aimbot.ShakeIntensity, LockNPC = FeatureConfig.Aimbot.LockNPC, 
                FOV = table.clone(FeatureConfig.Aimbot.FOV)
            },
            Movement = table.clone(FeatureConfig.Movement),
            ESP = {
                Enabled = FeatureConfig.ESP.Enabled, Box = FeatureConfig.ESP.Box, 
                Name = FeatureConfig.ESP.Name, Health = FeatureConfig.ESP.Health, 
                Distance = FeatureConfig.ESP.Distance, Tracers = FeatureConfig.ESP.Tracers, 
                Skeleton = FeatureConfig.ESP.Skeleton, HeadDot = FeatureConfig.ESP.HeadDot, 
                LookDir = FeatureConfig.ESP.LookDir, TeamCheck = FeatureConfig.ESP.TeamCheck, 
                MaxDist = FeatureConfig.ESP.MaxDist, Color = Utils.ColorToTable(FeatureConfig.ESP.Color)
            },
            Chams = {
                Enabled = FeatureConfig.Chams.Enabled, 
                FillColor = Utils.ColorToTable(FeatureConfig.Chams.FillColor), 
                OutlineColor = Utils.ColorToTable(FeatureConfig.Chams.OutlineColor)
            },
            Camera = {FOV = FeatureConfig.Camera.FOV},
            Visuals = {Fullbright = FeatureConfig.Visuals.Fullbright},
            Extras = {
                Hitbox = table.clone(FeatureConfig.Extras.Hitbox), 
                SpinBot = table.clone(FeatureConfig.Extras.SpinBot), 
                Crosshair = {
                    Visible = FeatureConfig.Extras.Crosshair.Visible, 
                    Size = FeatureConfig.Extras.Crosshair.Size, 
                    Gap = FeatureConfig.Extras.Crosshair.Gap, 
                    Thickness = FeatureConfig.Extras.Crosshair.Thickness, 
                    Color = Utils.ColorToTable(FeatureConfig.Extras.Crosshair.Color)
                }, 
                SpeedLines = FeatureConfig.Extras.SpeedLines, 
                Wallbang = FeatureConfig.Extras.Wallbang
            },
        }
    end

    function ConfigSystem.Deserialize(data)
        if type(data) ~= "table" then return end
        if type(data.Aimbot) == "table" then 
            for k, v in pairs(data.Aimbot) do 
                if (k == "Prediction" or k == "FOV") and type(v) == "table" then 
                    for k2, v2 in pairs(v) do FeatureConfig.Aimbot[k][k2] = v2 end 
                else 
                    FeatureConfig.Aimbot[k] = v 
                end 
            end 
        end
        if type(data.Movement) == "table" then for k,v in pairs(data.Movement) do FeatureConfig.Movement[k] = v end end
        if type(data.ESP) == "table" then 
            for k,v in pairs(data.ESP) do 
                if k == "Color" then FeatureConfig.ESP.Color = Utils.TableToColor(v) else FeatureConfig.ESP[k] = v end 
            end 
        end
        if type(data.Chams) == "table" then 
            for k,v in pairs(data.Chams) do 
                if k == "FillColor" or k == "OutlineColor" then FeatureConfig.Chams[k] = Utils.TableToColor(v) else FeatureConfig.Chams[k] = v end 
            end 
        end
        if type(data.Camera) == "table" and type(data.Camera.FOV) == "number" then FeatureConfig.Camera.FOV = data.Camera.FOV end
        if type(data.Visuals) == "table" and data.Visuals.Fullbright ~= nil then FeatureConfig.Visuals.Fullbright = data.Visuals.Fullbright end
        if type(data.Extras) == "table" then
            if type(data.Extras.Hitbox) == "table" then for k,v in pairs(data.Extras.Hitbox) do FeatureConfig.Extras.Hitbox[k] = v end end
            if type(data.Extras.SpinBot) == "table" then for k,v in pairs(data.Extras.SpinBot) do FeatureConfig.Extras.SpinBot[k] = v end end
            if type(data.Extras.Crosshair) == "table" then 
                for k,v in pairs(data.Extras.Crosshair) do 
                    if k == "Color" then FeatureConfig.Extras.Crosshair.Color = Utils.TableToColor(v) else FeatureConfig.Extras.Crosshair[k] = v end 
                end 
            end
            if data.Extras.SpeedLines ~= nil then FeatureConfig.Extras.SpeedLines = data.Extras.SpeedLines end
            if data.Extras.Wallbang ~= nil then FeatureConfig.Extras.Wallbang = data.Extras.Wallbang end
        end
    end

    function ConfigSystem.GetSavedNames()
        local names = {}
        for _, path in ipairs(Utils.ListFiles(CONFIG.FOLDER)) do 
            local name = path:match("[/\\]?([^/\\]+)$") or path
            if name:sub(-#CONFIG.EXT) == CONFIG.EXT then 
                table.insert(names, name:sub(1, -#CONFIG.EXT - 1)) 
            end 
        end
        table.sort(names)
        return names
    end

    function ConfigSystem.Save(name) 
        if not name or #name == 0 then return false, "Empty name" end
        local ok, encoded = pcall(function() return HttpService:JSONEncode(ConfigSystem.Serialize()) end)
        if not ok then return false, tostring(encoded) end
        return Utils.WriteFile(CONFIG.FOLDER .. "/" .. name .. CONFIG.EXT, encoded) 
    end

    function ConfigSystem.UpdateUI()
        local function set(key, value)
            if UIRegistry[key] and UIRegistry[key].Set then
                UIRegistry[key].Set(value, true)
            end
        end

        set("Aimbot_Enabled", FeatureConfig.Aimbot.Enabled)
        set("Aimbot_Keybind", FeatureConfig.Aimbot.Keybind)
        set("Aimbot_LockMode", FeatureConfig.Aimbot.LockMode)
        set("Aimbot_Hitpart", FeatureConfig.Aimbot.Hitpart)
        set("Aimbot_AirHitpart", FeatureConfig.Aimbot.AirHitpart)
        set("Aimbot_Smoothness", math.floor(FeatureConfig.Aimbot.Smoothness * 10))
        set("Aimbot_ShakeIntensity", FeatureConfig.Aimbot.ShakeIntensity)
        set("Aimbot_TeamCheck", FeatureConfig.Aimbot.TeamCheck)
        set("Aimbot_VisCheck", FeatureConfig.Aimbot.VisCheck)
        set("Aimbot_LockNPC", FeatureConfig.Aimbot.LockNPC)
        set("Aimbot_MaxDistance", FeatureConfig.Aimbot.MaxDistance)
        set("Aimbot_FOV_Show", FeatureConfig.Aimbot.FOV.Show)
        set("Aimbot_FOV_Filled", FeatureConfig.Aimbot.FOV.Filled)
        set("Aimbot_FOV_Rainbow", FeatureConfig.Aimbot.FOV.Rainbow)
        set("Aimbot_FOV_Pulse", FeatureConfig.Aimbot.FOV.Pulse)
        set("Aimbot_FOV_Size", FeatureConfig.Aimbot.FOV.Size)
        set("Aimbot_FOV_Thickness", FeatureConfig.Aimbot.FOV.Thickness)
        set("Aimbot_FOV_Sides", FeatureConfig.Aimbot.FOV.Sides)
        set("Aimbot_Prediction_Horizontal", math.floor(FeatureConfig.Aimbot.Prediction.Horizontal * 200))
        set("Aimbot_Prediction_Vertical", math.floor(FeatureConfig.Aimbot.Prediction.Vertical * 200))
        set("Aimbot_Triggerbot_Enabled", FeatureConfig.Aimbot.Triggerbot.Enabled)
        set("Aimbot_Triggerbot_Delay", math.floor(FeatureConfig.Aimbot.Triggerbot.Delay * 100))

        set("ESP_Enabled", FeatureConfig.ESP.Enabled)
        set("ESP_Box", FeatureConfig.ESP.Box)
        set("ESP_Name", FeatureConfig.ESP.Name)
        set("ESP_Health", FeatureConfig.ESP.Health)
        set("ESP_Distance", FeatureConfig.ESP.Distance)
        set("ESP_Tracers", FeatureConfig.ESP.Tracers)
        set("ESP_Skeleton", FeatureConfig.ESP.Skeleton)
        set("ESP_HeadDot", FeatureConfig.ESP.HeadDot)
        set("ESP_LookDir", FeatureConfig.ESP.LookDir)
        set("ESP_TeamCheck", FeatureConfig.ESP.TeamCheck)
        set("ESP_MaxDist", FeatureConfig.ESP.MaxDist)
        set("ESP_Color", FeatureConfig.ESP.Color)
        set("ESP_Chams_Enabled", FeatureConfig.Chams.Enabled)
        set("ESP_Chams_FillColor", FeatureConfig.Chams.FillColor)
        set("ESP_Chams_OutlineColor", FeatureConfig.Chams.OutlineColor)

        set("Movement_Speed", FeatureConfig.Movement.Speed)
        set("Movement_JumpPower", FeatureConfig.Movement.JumpPower)
        set("Movement_SprintEnabled", FeatureConfig.Movement.SprintEnabled)
        set("Movement_SprintSpeed", FeatureConfig.Movement.SprintSpeed)
        set("Movement_InfJump", FeatureConfig.Movement.InfJump)
        set("Movement_FlySpeed", FeatureConfig.Movement.FlySpeed)
        set("Movement_FlyEnabled", FeatureConfig.Movement.FlyEnabled)
        set("Movement_CFrameSpeed", FeatureConfig.Movement.CFrameSpeed)
        set("Movement_CFrameSpeedValue", FeatureConfig.Movement.CFrameSpeedValue or 50)
        set("Movement_Bhop", FeatureConfig.Movement.Bhop)
        set("Camera_FOV", FeatureConfig.Camera.FOV)

        set("Extras_Hitbox_Enabled", FeatureConfig.Extras.Hitbox.Enabled)
        set("Extras_Hitbox_Size", FeatureConfig.Extras.Hitbox.Size)
        set("Extras_SpinBot_Enabled", FeatureConfig.Extras.SpinBot.Enabled)
        set("Extras_SpinBot_Speed", FeatureConfig.Extras.SpinBot.Speed)
        set("Extras_Crosshair_Visible", FeatureConfig.Extras.Crosshair.Visible)
        set("Extras_Crosshair_Size", FeatureConfig.Extras.Crosshair.Size)
        set("Extras_Crosshair_Gap", FeatureConfig.Extras.Crosshair.Gap)
        set("Extras_Crosshair_Thickness", FeatureConfig.Extras.Crosshair.Thickness)
        set("Extras_Crosshair_Color", FeatureConfig.Extras.Crosshair.Color)
        set("Extras_SpeedLines", FeatureConfig.Extras.SpeedLines)
        set("Extras_Wallbang", FeatureConfig.Extras.Wallbang)
        set("Visuals_Fullbright", FeatureConfig.Visuals.Fullbright)
    end

    function ConfigSystem.Load(name)
        local content = Utils.ReadFile(CONFIG.FOLDER .. "/" .. name .. CONFIG.EXT)
        if not content then return false, "Not found" end
        local ok, data = pcall(function() return HttpService:JSONDecode(content) end)
        if not ok then return false, tostring(data) end
        ConfigSystem.Deserialize(data)
        ConfigSystem.UpdateUI()
        return true
    end

    function ConfigSystem.Delete(name) 
        return pcall(function() delfile(CONFIG.FOLDER .. "/" .. name .. CONFIG.EXT) end) 
    end

    return ConfigSystem
end

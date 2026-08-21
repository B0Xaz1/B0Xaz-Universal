-- src/Utils.lua
return function(CONFIG)
    local Players = game:GetService("Players")
    local Workspace = game:GetService("Workspace")
    local UIS = game:GetService("UserInputService")
    local Camera = Workspace.CurrentCamera
    local LocalPlayer = Players.LocalPlayer
    local IsMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled

    local Utils = {}

    function Utils.GetCharacter()
        return LocalPlayer and LocalPlayer.Character
    end

    function Utils.GetHumanoid()
        local c = Utils.GetCharacter()
        return c and c:FindFirstChildOfClass("Humanoid")
    end

    function Utils.GetRootPart()
        local c = Utils.GetCharacter()
        if not c then return nil end
        local r = c:FindFirstChild("HumanoidRootPart")
        return (r and r:IsA("BasePart")) and r or nil
    end

    function Utils.IsAlive(player)
        if not player then return false end
        local c = player.Character
        if not c then return false end
        local root = c:FindFirstChild("HumanoidRootPart")
        local hum = c:FindFirstChildOfClass("Humanoid")
        return root ~= nil and hum ~= nil and hum.Health > 0
    end

    function Utils.SameTeam(player)
        if not LocalPlayer or not LocalPlayer.Team or not player or not player.Team then return false end
        return LocalPlayer.Team == player.Team
    end

    function Utils.IsVisible(part)
        if not part or not part.Parent then return false end
        local origin = Camera.CFrame.Position
        local direction = part.Position - origin
        local params = RaycastParams.new()
        
        local filter = {Camera}
        if LocalPlayer.Character then table.insert(filter, LocalPlayer.Character) end
        params.FilterDescendantsInstances = filter
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.IgnoreWater = true

        local result = Workspace:Raycast(origin, direction, params)
        if not result then return true end
        return result.Instance:IsDescendantOf(part.Parent)
    end

    function Utils.GetPlayerByName(name)
        if not name or #name == 0 then return nil end
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Name == name or p.DisplayName == name then return p end
        end
        return nil
    end

    function Utils.GetPlayerNameList(excludeLocal)
        local list = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if not excludeLocal or p ~= LocalPlayer then
                table.insert(list, p.Name)
            end
        end
        table.sort(list)
        return list
    end

    function Utils.GetKeyCode(keyStr)
        if not keyStr or #keyStr == 0 then return nil end
        local ok, result = pcall(function() return Enum.KeyCode[keyStr:upper()] end)
        return (ok and typeof(result) == "EnumItem") and result or nil
    end

    function Utils.FindPlayerFromModel(model)
        if not model then return nil end
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character == model then return p end
        end
        return nil
    end

    function Utils.WorldToScreen(position)
        local sp, onScreen = Camera:WorldToViewportPoint(position)
        return Vector2.new(sp.X, sp.Y), onScreen, sp.Z
    end

    function Utils.GetMousePosition()
        if IsMobile then
            return Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        end
        return UIS:GetMouseLocation()
    end

    function Utils.GetScreenCenter()
        return Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    end

    function Utils.ColorToTable(c)
        return {r = c.R, g = c.G, b = c.B}
    end

    function Utils.TableToColor(t)
        if not t then return Color3.new(1, 1, 1) end
        return Color3.new(
            math.clamp(tonumber(t.r) or 1, 0, 1),
            math.clamp(tonumber(t.g) or 1, 0, 1),
            math.clamp(tonumber(t.b) or 1, 0, 1)
        )
    end

    function Utils.WriteFile(path, content)
        local ok, err = pcall(function() writefile(path, content) end)
        return ok, err
    end

    function Utils.ReadFile(path)
        local ok, result = pcall(function() return readfile(path) end)
        return ok and result or nil
    end

    function Utils.ListFiles(folder)
        local ok, result = pcall(function() return listfiles(folder) end)
        return ok and result or {}
    end

    function Utils.MakeFolder(folder)
        pcall(function()
            if isfolder and not isfolder(folder) then
                makefolder(folder)
            end
        end)
    end

    function Utils.SanitizeFileName(name)
        local out = (name or ""):gsub("[/\\%.:%*%?<>|%c\"]", "_"):gsub("^%s+", ""):gsub("%s+$", "")
        if #out > (CONFIG.CONFIG_NAME_MAX_LEN or 40) then
            out = out:sub(1, CONFIG.CONFIG_NAME_MAX_LEN or 40)
        end
        return out
    end

    function Utils.SafeCall(fn, ...)
        if type(fn) ~= "function" then return end
        local ok, err = pcall(fn, ...)
        if not ok then
            pcall(function() warn("[B0Xaz] Error: " .. tostring(err)) end)
        end
    end

    local getQueueOnTeleport = function()
        return queue_on_teleport or (syn and syn.queue_on_teleport) or queueonteleport or (Fluxus and Fluxus.queue_on_teleport)
    end

    function Utils.PrepareTeleport()
        local qot = getQueueOnTeleport()
        if not qot then return end

        local codeToQueue
        if getgenv().B0XazScriptURL then
            codeToQueue = string.format([[
                repeat task.wait() until game:IsLoaded()
                task.wait(1)
                pcall(function() loadstring(game:HttpGet("%s"))() end)
            ]], getgenv().B0XazScriptURL)
        else
            codeToQueue = [[
                repeat task.wait() until game:IsLoaded()
                task.wait(1)
                if isfile and isfile("B0XazUniversal/AutoRun.lua") then
                    pcall(function() loadstring(readfile("B0XazUniversal/AutoRun.lua"))() end)
                end
            ]]
        end

        pcall(function() qot(codeToQueue) end)
    end

    return Utils
end

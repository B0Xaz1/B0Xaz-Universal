-- src/Cleanup.lua
return function()
    local g = getgenv()

    -- 1. Destroy existing UI Library instance
    if g.B0XazLibrary then
        pcall(function() g.B0XazLibrary:Destroy() end)
        g.B0XazLibrary = nil
    end

    -- 2. Disconnect and clear event connections
    if type(g.B0XazConnections) == "table" then
        for _, conn in ipairs(g.B0XazConnections) do
            pcall(function()
                if conn and conn.Connected then conn:Disconnect() end
            end)
        end
    end
    g.B0XazConnections = {}

    -- 3. Cancel tracked threads / tasks
    if type(g.B0XazThreads) == "table" then
        for _, th in ipairs(g.B0XazThreads) do
            pcall(function() task.cancel(th) end)
        end
    end
    g.B0XazThreads = {}

    -- 4. Clean up generic Drawings
    if type(g.B0XazDrawings) == "table" then
        for _, d in pairs(g.B0XazDrawings) do
            pcall(function() d:Remove() end)
        end
    end
    g.B0XazDrawings = {}

    -- 5. Clean up ESP Drawings
    if type(g.B0XazDrawingESP) == "table" then
        for _, espData in pairs(g.B0XazDrawingESP) do
            if type(espData) == "table" then
                for _, drawing in pairs(espData) do
                    pcall(function() drawing:Remove() end)
                end
            end
        end
    end
    g.B0XazDrawingESP = {}

    -- 6. Clean up Tracer Lines
    if type(g.B0XazTracerLines) == "table" then
        for _, line in ipairs(g.B0XazTracerLines) do
            pcall(function() line:Remove() end)
        end
    end
    g.B0XazTracerLines = {}

    -- 7. Clean up Skeleton Lines
    if type(g.B0XazSkeletonLines) == "table" then
        for _, lines in pairs(g.B0XazSkeletonLines) do
            if type(lines) == "table" then
                for _, line in ipairs(lines) do
                    pcall(function() line:Remove() end)
                end
            end
        end
    end
    g.B0XazSkeletonLines = {}

    -- 8. Clean up Highlights / Chams
    if type(g.B0XazHighlights) == "table" then
        for _, h in pairs(g.B0XazHighlights) do
            pcall(function() h:Destroy() end)
        end
    end
    g.B0XazHighlights = {}

    -- Clean any orphaned character highlights
    for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
        if player.Character then
            for _, obj in ipairs(player.Character:GetChildren()) do
                if obj:IsA("Highlight") and obj.Name:find("B0Xaz") then
                    pcall(function() obj:Destroy() end)
                end
            end
        end
    end

    -- 9. Game-Specific Restores (Prison Life Doors & Guns)
    pcall(function()
        if type(g.B0XazRestoreDoors) == "function" then
            g.B0XazRestoreDoors()
            g.B0XazRestoreDoors = nil
        end
    end)

    pcall(function()
        if type(g.B0XazRestoreGuns) == "function" then
            g.B0XazRestoreGuns()
            g.B0XazRestoreGuns = nil
        end
    end)

    if type(g.B0XazDoorCache) == "table" then
        for part, c in pairs(g.B0XazDoorCache) do
            if part and part.Parent and type(c) == "table" then
                pcall(function()
                    part.CanCollide = c.CanCollide
                    part.Transparency = c.Transparency
                    part.Color = c.Color
                    part.Material = c.Material
                end)
            end
        end
        table.clear(g.B0XazDoorCache)
    end
    g.B0XazDoorCache = {}
    g.B0XazDoorParts = {}
    g.B0XazGunCache = {}

    -- 10. Destroy any leftover ScreenGuis
    local guiParents = {}
    pcall(function() table.insert(guiParents, game:GetService("CoreGui")) end)
    pcall(function()
        local lp = game:GetService("Players").LocalPlayer
        if lp and lp:FindFirstChild("PlayerGui") then
            table.insert(guiParents, lp.PlayerGui)
        end
    end)
    pcall(function() if gethui then table.insert(guiParents, gethui()) end end)

    for _, parent in ipairs(guiParents) do
        pcall(function()
            for _, gui in ipairs(parent:GetChildren()) do
                if gui:IsA("ScreenGui") and (gui.Name == "B0XazUI" or gui.Name:find("B0Xaz")) then
                    pcall(function() gui:Destroy() end)
                end
            end
        end)
    end

    g.B0XazState = nil
end

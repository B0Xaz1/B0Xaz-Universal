return function()
	local g = getgenv()

	g.B0XazSessionId = (tonumber(g.B0XazSessionId) or 0) + 1

	pcall(function()
		game:GetService("RunService"):UnbindFromRenderStep("B0XazStretchRes")
	end)

	if g.B0XazLibrary then
		pcall(function() g.B0XazLibrary:Destroy() end)
		g.B0XazLibrary = nil
	end

	if type(g.B0XazConnections) == "table" then
		for i = #g.B0XazConnections, 1, -1 do
			pcall(function()
				local conn = g.B0XazConnections[i]
				if conn and conn.Disconnect then conn:Disconnect() end
			end)
			g.B0XazConnections[i] = nil
		end
	end
	g.B0XazConnections = {}

	if type(g.B0XazThreads) == "table" then
		for i = #g.B0XazThreads, 1, -1 do
			pcall(function() task.cancel(g.B0XazThreads[i]) end)
			g.B0XazThreads[i] = nil
		end
	end
	g.B0XazThreads = {}

	local function nukeDrawing(d)
		if not d then return end
		pcall(function() d.Visible = false end)
		pcall(function()
			if type(d) == "table" then
				for k, sub in pairs(d) do
					nukeDrawing(sub)
					d[k] = nil
				end
			elseif d.Remove then
				d:Remove()
			end
		end)
	end

	if type(g.B0XazAllDrawings) == "table" then
		for i = #g.B0XazAllDrawings, 1, -1 do
			nukeDrawing(g.B0XazAllDrawings[i])
			g.B0XazAllDrawings[i] = nil
		end
	end
	g.B0XazAllDrawings = {}

	if type(g.B0XazDrawings) == "table" then
		for k, d in pairs(g.B0XazDrawings) do
			nukeDrawing(d)
			g.B0XazDrawings[k] = nil
		end
	end
	g.B0XazDrawings = {}

	if type(g.B0XazDrawingESP) == "table" then
		for k, espData in pairs(g.B0XazDrawingESP) do
			nukeDrawing(espData)
			g.B0XazDrawingESP[k] = nil
		end
	end
	g.B0XazDrawingESP = {}

	if type(g.B0XazTracerLines) == "table" then
		for i = #g.B0XazTracerLines, 1, -1 do
			nukeDrawing(g.B0XazTracerLines[i])
			g.B0XazTracerLines[i] = nil
		end
	end
	g.B0XazTracerLines = {}

	if type(g.B0XazSkeletonLines) == "table" then
		for k, lines in pairs(g.B0XazSkeletonLines) do
			nukeDrawing(lines)
			g.B0XazSkeletonLines[k] = nil
		end
	end
	g.B0XazSkeletonLines = {}

	if type(g.B0XazHighlights) == "table" then
		for k, h in pairs(g.B0XazHighlights) do
			pcall(function() if h then h:Destroy() end end)
			g.B0XazHighlights[k] = nil
		end
	end
	g.B0XazHighlights = {}

	for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
		if player.Character then
			for _, obj in ipairs(player.Character:GetDescendants()) do
				if obj:IsA("Highlight") and (obj.Name == "B0XazChams" or tostring(obj.Name):find("B0Xaz")) then
					pcall(function() obj:Destroy() end)
				end
			end
		end
	end

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
			g.B0XazDoorCache[part] = nil
		end
	end
	g.B0XazDoorCache = {}
	g.B0XazDoorParts = {}
	g.B0XazGunCache = {}

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
				if gui:IsA("ScreenGui") and (gui.Name == "B0XazUI" or gui.Name == "B0XazAuth" or gui.Name == "B0XazStretchRes" or tostring(gui.Name):find("B0Xaz")) then
					pcall(function() gui:Destroy() end)
				end
			end
		end)
	end

	g.B0XazState = nil
	g.B0XazContext = nil
	task.wait()
end

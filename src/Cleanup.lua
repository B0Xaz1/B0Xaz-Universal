-- // src/Cleanup.lua
return function()
	local RunService = game:GetService("RunService")
	local Players = game:GetService("Players")
	local CoreGui = game:GetService("CoreGui")

	local env = (getgenv and getgenv()) or _G

	-- Increment session ID to immediately invalidate all running background loops
	env.B0XazSessionId = (tonumber(env.B0XazSessionId) or 0) + 1

	-- Unbind render steps
	pcall(function()
		RunService:UnbindFromRenderStep("B0XazStretchRes")
	end)

	-- Destroy main library instance if present
	if env.B0XazLibrary then
		pcall(function() env.B0XazLibrary:Destroy() end)
		env.B0XazLibrary = nil
	end

	-- Disconnect all tracked connections
	if type(env.B0XazConnections) == "table" then
		for index = #env.B0XazConnections, 1, -1 do
			local conn = env.B0XazConnections[index]
			if conn then
				pcall(function()
					if typeof(conn) == "RBXScriptConnection" or type(conn.Disconnect) == "function" then
						conn:Disconnect()
					end
				end)
			end
			env.B0XazConnections[index] = nil
		end
	end
	env.B0XazConnections = {}

	-- Cancel all tracked threads
	if type(env.B0XazThreads) == "table" then
		for index = #env.B0XazThreads, 1, -1 do
			local thread = env.B0XazThreads[index]
			if thread then
				pcall(function() task.cancel(thread) end)
			end
			env.B0XazThreads[index] = nil
		end
	end
	env.B0XazThreads = {}

	-- Helper to safely remove drawing objects
	local function destroyDrawing(obj)
		if not obj then return end
		if type(obj) == "table" then
			for k, subObj in pairs(obj) do
				destroyDrawing(subObj)
				obj[k] = nil
			end
		end
		pcall(function()
			if obj.Visible ~= nil then obj.Visible = false end
			if obj.Remove then obj:Remove() elseif obj.Destroy then obj:Destroy() end
		end)
	end

	-- Clear drawing tables
	local drawingKeys = {
		"B0XazAllDrawings", "B0XazDrawings", "B0XazDrawingESP",
		"B0XazTracerLines", "B0XazSkeletonLines"
	}
	for _, key in ipairs(drawingKeys) do
		local container = env[key]
		if type(container) == "table" then
			for subKey, item in pairs(container) do
				destroyDrawing(item)
				container[subKey] = nil
			end
		end
		env[key] = {}
	end

	-- Clear chams highlights
	if type(env.B0XazHighlights) == "table" then
		for key, highlight in pairs(env.B0XazHighlights) do
			if highlight then
				pcall(function() highlight:Destroy() end)
			end
			env.B0XazHighlights[key] = nil
		end
	end
	env.B0XazHighlights = {}

	-- Clear remaining orphan highlights from characters
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		if char then
			for _, descendant in ipairs(char:GetDescendants()) do
				if descendant:IsA("Highlight") and (descendant.Name == "B0XazChams" or descendant.Name:find("^B0Xaz")) then
					pcall(function() descendant:Destroy() end)
				end
			end
		end
	end

	-- Restore modified doors
	if type(env.B0XazRestoreDoors) == "function" then
		pcall(env.B0XazRestoreDoors)
		env.B0XazRestoreDoors = nil
	end

	-- Restore modified guns
	if type(env.B0XazRestoreGuns) == "function" then
		pcall(env.B0XazRestoreGuns)
		env.B0XazRestoreGuns = nil
	end

	-- Manual restore for door parts if cache still populated
	if type(env.B0XazDoorCache) == "table" then
		for part, props in pairs(env.B0XazDoorCache) do
			if part and part.Parent and type(props) == "table" then
				pcall(function()
					part.CanCollide = props.CanCollide
					part.Transparency = props.Transparency
					part.Color = props.Color
					part.Material = props.Material
				end)
			end
		end
	end

	env.B0XazDoorCache = {}
	env.B0XazDoorParts = {}
	env.B0XazGunCache = {}

	-- Remove ScreenGuis
	local containers = {}
	pcall(function() table.insert(containers, CoreGui) end)
	pcall(function()
		local pGui = Players.LocalPlayer and Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
		if pGui then table.insert(containers, pGui) end
	end)
	pcall(function()
		if gethui then table.insert(containers, gethui()) end
	end)

	for _, container in ipairs(containers) do
		pcall(function()
			for _, child in ipairs(container:GetChildren()) do
				if child:IsA("ScreenGui") and (child.Name == "B0XazUI" or child.Name == "B0XazAuth" or child.Name:find("^B0Xaz")) then
					pcall(function() child:Destroy() end)
				end
			end
		end)
	end

	-- Clear global state pointers
	env.B0XazState = nil
	env.B0XazContext = nil

	task.wait()
end

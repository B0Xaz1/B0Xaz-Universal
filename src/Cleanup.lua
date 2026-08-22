local SETTINGS = {
	RENDER_STEP_BINDINGS = {
		"B0XazStretchRes",
	},
	DRAWING_TABLE_KEYS = {
		"B0XazAllDrawings",
		"B0XazDrawings",
		"B0XazDrawingESP",
		"B0XazTracerLines",
		"B0XazSkeletonLines",
	},
	GLOBAL_STATE_KEYS = {
		"B0XazState",
		"B0XazContext",
		"B0XazLibrary",
	},
	CACHE_KEYS = {
		"B0XazDoorCache",
		"B0XazDoorParts",
		"B0XazGunCache",
	},
	CLEANUP_CALLBACK_KEYS = {
		"B0XazRestoreDoors",
		"B0XazRestoreGuns",
	},
	NAME_PATTERNS = {
		GUI = "^B0Xaz",
		HIGHLIGHT = "^B0Xaz",
	},
	GUI_TARGET_NAMES = {
		["B0XazUI"] = true,
		["B0XazAuth"] = true,
		["B0XazStretchRes"] = true,
	},
	HIGHLIGHT_TARGET_NAMES = {
		["B0XazChams"] = true,
	},
}

return function()
	local RunService = game:GetService("RunService")
	local Players = game:GetService("Players")
	local CoreGui = game:GetService("CoreGui")

	local globalEnv = getgenv and getgenv() or _G

	globalEnv.B0XazSessionId = (tonumber(globalEnv.B0XazSessionId) or 0) + 1

	for _, bindName in ipairs(SETTINGS.RENDER_STEP_BINDINGS) do
		pcall(function()
			RunService:UnbindFromRenderStep(bindName)
		end)
	end

	if globalEnv.B0XazLibrary then
		pcall(function()
			globalEnv.B0XazLibrary:Destroy()
		end)
		globalEnv.B0XazLibrary = nil
	end

	local function disconnectAll(connectionsList)
		if type(connectionsList) ~= "table" then return end
		for index = #connectionsList, 1, -1 do
			local conn = connectionsList[index]
			if conn then
				pcall(function()
					if typeof(conn) == "RBXScriptConnection" or conn.Disconnect then
						conn:Disconnect()
					end
				end)
			end
			connectionsList[index] = nil
		end
	end

	local function cancelAll(threadsList)
		if type(threadsList) ~= "table" then return end
		for index = #threadsList, 1, -1 do
			local thread = threadsList[index]
			if thread then
				pcall(function()
					task.cancel(thread)
				end)
			end
			threadsList[index] = nil
		end
	end

	disconnectAll(globalEnv.B0XazConnections)
	globalEnv.B0XazConnections = {}

	cancelAll(globalEnv.B0XazThreads)
	globalEnv.B0XazThreads = {}

	local function destroyDrawing(drawingObject)
		if not drawingObject then return end
		if type(drawingObject) == "table" then
			for key, subItem in pairs(drawingObject) do
				destroyDrawing(subItem)
				drawingObject[key] = nil
			end
		end
		pcall(function()
			if drawingObject.Visible ~= nil then
				drawingObject.Visible = false
			end
			if drawingObject.Remove then
				drawingObject:Remove()
			elseif drawingObject.Destroy then
				drawingObject:Destroy()
			end
		end)
	end

	for _, key in ipairs(SETTINGS.DRAWING_TABLE_KEYS) do
		local container = globalEnv[key]
		if type(container) == "table" then
			for subKey, item in pairs(container) do
				destroyDrawing(item)
				container[subKey] = nil
			end
		end
		globalEnv[key] = {}
	end

	local highlightsContainer = globalEnv.B0XazHighlights
	if type(highlightsContainer) == "table" then
		for key, highlight in pairs(highlightsContainer) do
			if highlight then
				pcall(function()
					highlight:Destroy()
				end)
			end
			highlightsContainer[key] = nil
		end
	end
	globalEnv.B0XazHighlights = {}

	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		if character then
			for _, descendant in ipairs(character:GetDescendants()) do
				if descendant:IsA("Highlight") and (SETTINGS.HIGHLIGHT_TARGET_NAMES[descendant.Name] or descendant.Name:match(SETTINGS.NAME_PATTERNS.HIGHLIGHT)) then
					pcall(function()
						descendant:Destroy()
					end)
				end
			end
		end
	end

	for _, callbackKey in ipairs(SETTINGS.CLEANUP_CALLBACK_KEYS) do
		local cleanupFn = globalEnv[callbackKey]
		if type(cleanupFn) == "function" then
			pcall(cleanupFn)
			globalEnv[callbackKey] = nil
		end
	end

	local doorCache = globalEnv.B0XazDoorCache
	if type(doorCache) == "table" then
		for part, originalProperties in pairs(doorCache) do
			if part and part.Parent and type(originalProperties) == "table" then
				pcall(function()
					part.CanCollide = originalProperties.CanCollide
					part.Transparency = originalProperties.Transparency
					part.Color = originalProperties.Color
					part.Material = originalProperties.Material
				end)
			end
			doorCache[part] = nil
		end
	end

	for _, cacheKey in ipairs(SETTINGS.CACHE_KEYS) do
		globalEnv[cacheKey] = {}
	end

	local guiContainers = {}
	pcall(function()
		table.insert(guiContainers, CoreGui)
	end)
	pcall(function()
		local localPlayer = Players.LocalPlayer
		local playerGui = localPlayer and localPlayer:FindFirstChild("PlayerGui")
		if playerGui then
			table.insert(guiContainers, playerGui)
		end
	end)
	pcall(function()
		if gethui then
			table.insert(guiContainers, gethui())
		end
	end)

	for _, container in ipairs(guiContainers) do
		pcall(function()
			for _, child in ipairs(container:GetChildren()) do
				if child:IsA("ScreenGui") and (SETTINGS.GUI_TARGET_NAMES[child.Name] or child.Name:match(SETTINGS.NAME_PATTERNS.GUI)) then
					pcall(function()
						child:Destroy()
					end)
				end
			end
		end)
	end

	for _, stateKey in ipairs(SETTINGS.GLOBAL_STATE_KEYS) do
		globalEnv[stateKey] = nil
	end

	task.wait()
end

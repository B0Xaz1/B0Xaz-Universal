local SETTINGS = {
	LIMITS = {
		DEFAULT_CONFIG_NAME_MAX_LEN = 40,
		MIN_RAYCAST_MAGNITUDE = 0.1,
		DEFAULT_WAIT_TIMEOUT = 10,
		MAX_PLAYER_SEARCH_DEPTH = 200,
	},
	PATTERNS = {
		FILENAME_SANITIZE = "[/\\%.:%*%?<>|%c\"]",
		TRIM_WHITESPACE = "^%s*(.-)%s*$",
	},
	TEMPLATES = {
		TELEPORT_URL = "repeat task.wait() until game:IsLoaded()\ntask.wait(1)\npcall(function() loadstring(game:HttpGet(\"%s\"))() end)",
		TELEPORT_FILE = "repeat task.wait() until game:IsLoaded()\ntask.wait(1)\nif isfile and isfile(\"B0XazUniversal/AutoRun.lua\") then\n\tpcall(function() loadstring(readfile(\"B0XazUniversal/AutoRun.lua\"))() end)\nend",
	},
	DEFAULTS = {
		COLOR_TABLE = { r = 1, g = 1, b = 1 },
	},
}

return function(CONFIG)
	local Players = game:GetService("Players")
	local Workspace = game:GetService("Workspace")
	local UserInputService = game:GetService("UserInputService")

	local LocalPlayer = Players.LocalPlayer
	local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

	local function getCamera()
		return Workspace.CurrentCamera
	end

	local cachedRaycastParams = RaycastParams.new()
	cachedRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
	cachedRaycastParams.IgnoreWater = true

	local Utils = {}

	function Utils.WaitForGameLoad(timeout)
		if not game:IsLoaded() then
			game.Loaded:Wait()
		end
		if not LocalPlayer then
			local startTime = os.clock()
			local maxWait = timeout or SETTINGS.LIMITS.DEFAULT_WAIT_TIMEOUT
			while not Players.LocalPlayer and (os.clock() - startTime) < maxWait do
				task.wait()
			end
			LocalPlayer = Players.LocalPlayer
		end
		return LocalPlayer
	end

	function Utils.SafeGetService(serviceName)
		local success, service = pcall(game.GetService, game, serviceName)
		return success and service or nil
	end

	function Utils.GetCharacter()
		return LocalPlayer and LocalPlayer.Character
	end

	function Utils.GetHumanoid()
		local char = Utils.GetCharacter()
		if not (char and char.Parent) then return nil end
		return char:FindFirstChildOfClass("Humanoid")
	end

	function Utils.GetRootPart()
		local char = Utils.GetCharacter()
		if not (char and char.Parent) then return nil end
		local root = char:FindFirstChild("HumanoidRootPart")
		return (root and root:IsA("BasePart") and root:IsDescendantOf(Workspace)) and root or nil
	end

	function Utils.GetPlayerAssets(player)
		if not player then return nil end
		local char = player.Character
		if not (char and char.Parent) then return nil end

		local hum = char:FindFirstChildOfClass("Humanoid")
		local root = char:FindFirstChild("HumanoidRootPart")
		local head = char:FindFirstChild("Head")

		if not (hum and root and head) then return nil end
		if not root:IsDescendantOf(Workspace) then return nil end
		if hum.Health <= 0 then return nil end

		return {
			Character = char,
			Humanoid = hum,
			RootPart = root,
			Head = head,
		}
	end

	function Utils.IsAlive(player)
		return Utils.GetPlayerAssets(player) ~= nil
	end

	function Utils.SameTeam(player)
		if not (LocalPlayer and LocalPlayer.Team and player and player.Team) then
			return false
		end
		return LocalPlayer.Team == player.Team
	end

	function Utils.IsVisible(part)
		if not (part and part.Parent and part:IsDescendantOf(Workspace)) then
			return false
		end
		local camera = getCamera()
		if not camera then
			return false
		end

		local origin = camera.CFrame.Position
		local direction = part.Position - origin
		if direction.Magnitude < SETTINGS.LIMITS.MIN_RAYCAST_MAGNITUDE then
			return true
		end

		local filterList = { camera }
		local character = LocalPlayer and LocalPlayer.Character
		if character then
			table.insert(filterList, character)
		end
		cachedRaycastParams.FilterDescendantsInstances = filterList

		local success, result = pcall(function()
			return Workspace:Raycast(origin, direction, cachedRaycastParams)
		end)

		if not success then return false end
		if not result then return true end
		return result.Instance:IsDescendantOf(part.Parent)
	end

	function Utils.GetPlayerByName(name)
		if not name or #name == 0 then return nil end
		local searchLower = name:lower()
		for _, player in ipairs(Players:GetPlayers()) do
			if player.Name == name or player.DisplayName == name or player.Name:lower() == searchLower or player.DisplayName:lower() == searchLower then
				return player
			end
		end
		return nil
	end

	function Utils.GetPlayerNameList(excludeLocal)
		local players = Players:GetPlayers()
		local list = table.create(#players)
		for _, player in ipairs(players) do
			if not excludeLocal or player ~= LocalPlayer then
				table.insert(list, player.Name)
			end
		end
		table.sort(list)
		return list
	end

	function Utils.GetKeyCode(keyStr)
		if not keyStr or #keyStr == 0 then return nil end
		local success, result = pcall(function()
			return Enum.KeyCode[keyStr:upper()]
		end)
		return (success and typeof(result) == "EnumItem") and result or nil
	end

	function Utils.FindPlayerFromModel(model)
		if not model then return nil end
		for _, player in ipairs(Players:GetPlayers()) do
			if player.Character == model then
				return player
			end
		end
		return nil
	end

	function Utils.WorldToScreen(position)
		local camera = getCamera()
		if not camera then return Vector2.zero, false, 0 end
		local success, screenPos, onScreen = pcall(function()
			return camera:WorldToViewportPoint(position)
		end)
		if not success then return Vector2.zero, false, 0 end
		return Vector2.new(screenPos.X, screenPos.Y), onScreen, screenPos.Z
	end

	function Utils.GetMousePosition()
		local camera = getCamera()
		if isMobile and camera then
			return Vector2.new(camera.ViewportSize.X * 0.5, camera.ViewportSize.Y * 0.5)
		end
		return UserInputService:GetMouseLocation()
	end

	function Utils.GetScreenCenter()
		local camera = getCamera()
		if not camera then return Vector2.zero end
		return Vector2.new(camera.ViewportSize.X * 0.5, camera.ViewportSize.Y * 0.5)
	end

	function Utils.ColorToTable(color)
		if typeof(color) ~= "Color3" then
			return SETTINGS.DEFAULTS.COLOR_TABLE
		end
		return { r = color.R, g = color.G, b = color.B }
	end

	function Utils.TableToColor(tbl)
		if type(tbl) ~= "table" then
			return Color3.new(1, 1, 1)
		end
		return Color3.new(
			math.clamp(tonumber(tbl.r) or 1, 0, 1),
			math.clamp(tonumber(tbl.g) or 1, 0, 1),
			math.clamp(tonumber(tbl.b) or 1, 0, 1)
		)
	end

	function Utils.WriteFile(path, content)
		if not writefile then return false, "writefile unavailable" end
		local success, err = pcall(writefile, path, content)
		return success, err
	end

	function Utils.ReadFile(path)
		if not (readfile and isfile and isfile(path)) then return nil end
		local success, result = pcall(readfile, path)
		return success and result or nil
	end

	function Utils.ListFiles(folder)
		if not (listfiles and isfolder and isfolder(folder)) then return {} end
		local success, result = pcall(listfiles, folder)
		return (success and type(result) == "table") and result or {}
	end

	function Utils.MakeFolder(folder)
		if makefolder and isfolder and not isfolder(folder) then
			pcall(makefolder, folder)
		end
	end

	function Utils.SanitizeFileName(name)
		local cleaned = tostring(name or ""):gsub(SETTINGS.PATTERNS.FILENAME_SANITIZE, "_")
		cleaned = cleaned:match(SETTINGS.PATTERNS.TRIM_WHITESPACE) or ""
		local maxLen = (CONFIG and CONFIG.CONFIG_NAME_MAX_LEN) or SETTINGS.LIMITS.DEFAULT_CONFIG_NAME_MAX_LEN
		if #cleaned > maxLen then
			cleaned = cleaned:sub(1, maxLen)
		end
		return cleaned
	end

	function Utils.SafeCall(func, ...)
		if type(func) ~= "function" then return false end
		return pcall(func, ...)
	end

	local function getQueueOnTeleport()
		return queue_on_teleport or (syn and syn.queue_on_teleport) or queueonteleport or (Fluxus and Fluxus.queue_on_teleport)
	end

	function Utils.PrepareTeleport()
		local queueFunction = getQueueOnTeleport()
		if not queueFunction then return end

		local globalEnv = getgenv and getgenv() or _G
		local codeToQueue
		if globalEnv.B0XazScriptURL then
			codeToQueue = string.format(SETTINGS.TEMPLATES.TELEPORT_URL, tostring(globalEnv.B0XazScriptURL))
		else
			codeToQueue = SETTINGS.TEMPLATES.TELEPORT_FILE
		end

		pcall(queueFunction, codeToQueue)
	end

	return Utils
end

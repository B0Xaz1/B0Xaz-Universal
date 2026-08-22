-- // src/Utils.lua
return function(CONFIG)
	local Players = game:GetService("Players")
	local Workspace = game:GetService("Workspace")
	local UserInputService = game:GetService("UserInputService")

	local LocalPlayer = Players.LocalPlayer
	local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

	local Utils = {}

	function Utils.WaitForGameLoad(timeout)
		if not game:IsLoaded() then
			pcall(function() game.Loaded:Wait() end)
		end
		if not LocalPlayer then
			local t0 = os.clock()
			local maxWait = timeout or 10
			while not Players.LocalPlayer and (os.clock() - t0) < maxWait do
				task.wait()
			end
			LocalPlayer = Players.LocalPlayer
		end
		return LocalPlayer
	end

	function Utils.GetCharacter()
		return LocalPlayer and LocalPlayer.Character
	end

	function Utils.GetHumanoid()
		local char = Utils.GetCharacter()
		return char and char:FindFirstChildOfClass("Humanoid")
	end

	function Utils.GetRootPart()
		local char = Utils.GetCharacter()
		if not char then return nil end
		local root = char:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") and root:IsDescendantOf(Workspace) then
			return root
		end
		return nil
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
		local camera = Workspace.CurrentCamera
		if not camera then return false end

		local origin = camera.CFrame.Position
		local direction = part.Position - origin
		if direction.Magnitude < 0.1 then return true end

		local params = RaycastParams.new()
		local filter = { camera }
		if LocalPlayer and LocalPlayer.Character then
			table.insert(filter, LocalPlayer.Character)
		end
		params.FilterDescendantsInstances = filter
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.IgnoreWater = true

		local ok, result = pcall(function()
			return Workspace:Raycast(origin, direction, params)
		end)
		if not ok then return false end
		if not result then return true end
		return result.Instance:IsDescendantOf(part.Parent)
	end

	function Utils.GetPlayerByName(name)
		if not name or #name == 0 then return nil end
		local lower = name:lower()
		for _, player in ipairs(Players:GetPlayers()) do
			if player.Name == name
				or player.DisplayName == name
				or player.Name:lower() == lower
				or player.DisplayName:lower() == lower then
				return player
			end
		end
		return nil
	end

	function Utils.GetPlayerNameList(excludeLocal)
		local list = {}
		for _, player in ipairs(Players:GetPlayers()) do
			if not excludeLocal or player ~= LocalPlayer then
				table.insert(list, player.Name)
			end
		end
		table.sort(list)
		return list
	end

	function Utils.GetKeyCode(keyStr)
		if not keyStr or #keyStr == 0 then return nil end
		local ok, result = pcall(function()
			return Enum.KeyCode[keyStr:upper()]
		end)
		if ok and typeof(result) == "EnumItem" then
			return result
		end
		return nil
	end

	function Utils.WorldToScreen(position)
		local camera = Workspace.CurrentCamera
		if not camera then return Vector2.zero, false, 0 end
		local ok, screenPos, onScreen = pcall(function()
			return camera:WorldToViewportPoint(position)
		end)
		if not ok then return Vector2.zero, false, 0 end
		return Vector2.new(screenPos.X, screenPos.Y), onScreen, screenPos.Z
	end

	function Utils.GetMousePosition()
		local camera = Workspace.CurrentCamera
		if isMobile and camera then
			return Vector2.new(camera.ViewportSize.X * 0.5, camera.ViewportSize.Y * 0.5)
		end
		return UserInputService:GetMouseLocation()
	end

	function Utils.GetScreenCenter()
		local camera = Workspace.CurrentCamera
		if not camera then return Vector2.zero end
		return Vector2.new(camera.ViewportSize.X * 0.5, camera.ViewportSize.Y * 0.5)
	end

	function Utils.ColorToTable(color)
		if typeof(color) ~= "Color3" then
			return { r = 1, g = 1, b = 1 }
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
		local ok, err = pcall(writefile, path, content)
		return ok, err
	end

	function Utils.ReadFile(path)
		if not (readfile and isfile and isfile(path)) then return nil end
		local ok, result = pcall(readfile, path)
		return ok and result or nil
	end

	function Utils.ListFiles(folder)
		if not (listfiles and isfolder and isfolder(folder)) then return {} end
		local ok, result = pcall(listfiles, folder)
		return (ok and type(result) == "table") and result or {}
	end

	function Utils.MakeFolder(folder)
		if makefolder and isfolder and not isfolder(folder) then
			pcall(makefolder, folder)
		end
	end

	function Utils.SanitizeFileName(name)
		local cleaned = tostring(name or ""):gsub("[/\\%.:%*%?<>|%c\"]", "_")
		cleaned = cleaned:match("^%s*(.-)%s*$") or ""
		local maxLen = (CONFIG and CONFIG.CONFIG_NAME_MAX_LEN) or 40
		if #cleaned > maxLen then
			cleaned = cleaned:sub(1, maxLen)
		end
		return cleaned
	end

	function Utils.SafeCall(fn, ...)
		if type(fn) ~= "function" then return false end
		return pcall(fn, ...)
	end

	local function getQueueOnTeleport()
		return queue_on_teleport
			or (syn and syn.queue_on_teleport)
			or queueonteleport
			or (Fluxus and Fluxus.queue_on_teleport)
	end

	function Utils.PrepareTeleport()
		local queueFn = getQueueOnTeleport()
		if not queueFn then return end
		local env = (getgenv and getgenv()) or _G
		local code
		if env.B0XazScriptURL then
			code = string.format(
				'repeat task.wait() until game:IsLoaded()\ntask.wait(1)\npcall(function() loadstring(game:HttpGet("%s"))() end)',
				tostring(env.B0XazScriptURL)
			)
		else
			code = [[repeat task.wait() until game:IsLoaded()
task.wait(1)
if isfile and isfile("B0XazUniversal/AutoRun.lua") then
	pcall(function() loadstring(readfile("B0XazUniversal/AutoRun.lua"))() end)
end]]
		end
		pcall(queueFn, code)
	end

	return Utils
end

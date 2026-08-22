return function(CONFIG)
	local Players = game:GetService("Players")
	local Workspace = game:GetService("Workspace")
	local UIS = game:GetService("UserInputService")
	local Camera = Workspace.CurrentCamera
	local LocalPlayer = Players.LocalPlayer
	local IsMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled

	local Utils = {}

	function Utils.WaitForGameLoad()
		if not game:IsLoaded() then
			game.Loaded:Wait()
		end
		if not LocalPlayer then
			repeat task.wait() until Players.LocalPlayer
			LocalPlayer = Players.LocalPlayer
		end
	end

	function Utils.SafeGetService(name)
		local ok, service = pcall(function() return game:GetService(name) end)
		return ok and service or nil
	end

	function Utils.GetCharacter()
		return LocalPlayer and LocalPlayer.Character
	end

	function Utils.GetHumanoid()
		local c = Utils.GetCharacter()
		if not c or not c.Parent then return nil end
		return c:FindFirstChildOfClass("Humanoid")
	end

	function Utils.GetRootPart()
		local c = Utils.GetCharacter()
		if not c or not c.Parent then return nil end
		local r = c:FindFirstChild("HumanoidRootPart")
		return (r and r:IsA("BasePart") and r:IsDescendantOf(Workspace)) and r or nil
	end

	function Utils.GetPlayerAssets(player)
		if not player then return nil end
		local char = player.Character
		if not char or not char.Parent then return nil end

		local hum = char:FindFirstChildOfClass("Humanoid")
		local root = char:FindFirstChild("HumanoidRootPart")
		local head = char:FindFirstChild("Head")

		if not hum or not root or not head then return nil end
		if not root:IsDescendantOf(Workspace) then return nil end
		if hum.Health <= 0 then return nil end

		return {
			Character = char,
			Humanoid = hum,
			RootPart = root,
			Head = head
		}
	end

	function Utils.IsAlive(player)
		return Utils.GetPlayerAssets(player) ~= nil
	end

	function Utils.SameTeam(player)
		if not LocalPlayer or not LocalPlayer.Team or not player or not player.Team then return false end
		return LocalPlayer.Team == player.Team
	end

	function Utils.IsVisible(part)
		if not part or not part.Parent or not part:IsDescendantOf(Workspace) then return false end
		local origin = Camera.CFrame.Position
		local direction = part.Position - origin
		if direction.Magnitude < 0.1 then return true end

		local params = RaycastParams.new()
		local filter = {Camera}
		if LocalPlayer and LocalPlayer.Character then table.insert(filter, LocalPlayer.Character) end
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
		if not Camera then return Vector2.zero, false, 0 end
		local ok, sp, onScreen = pcall(function()
			local s, o = Camera:WorldToViewportPoint(position)
			return s, o
		end)
		if not ok then return Vector2.zero, false, 0 end
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
		if typeof(c) ~= "Color3" then return {r = 1, g = 1, b = 1} end
		return {r = c.R, g = c.G, b = c.B}
	end

	function Utils.TableToColor(t)
		if type(t) ~= "table" then return Color3.new(1, 1, 1) end
		return Color3.new(
			math.clamp(tonumber(t.r) or 1, 0, 1),
			math.clamp(tonumber(t.g) or 1, 0, 1),
			math.clamp(tonumber(t.b) or 1, 0, 1)
		)
	end

	function Utils.WriteFile(path, content)
		if not writefile then return false, "writefile not supported" end
		local ok, err = pcall(function() writefile(path, content) end)
		return ok, err
	end

	function Utils.ReadFile(path)
		if not readfile or not isfile then return nil end
		if not isfile(path) then return nil end
		local ok, result = pcall(function() return readfile(path) end)
		return ok and result or nil
	end

	function Utils.ListFiles(folder)
		if not listfiles or not isfolder then return {} end
		if not isfolder(folder) then return {} end
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
		return ok
	end

	local function getQueueOnTeleport()
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

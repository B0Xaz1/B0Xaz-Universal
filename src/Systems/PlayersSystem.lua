-- // src/Systems/PlayersSystem.lua
return function(Context)
	local Players = game:GetService("Players")
	local Workspace = game:GetService("Workspace")
	local RunService = game:GetService("RunService")
	local LocalPlayer = Players.LocalPlayer
	local Utils = Context.Utils or {}
	local Connections = Context.Connections or {}

	local PlayersSystem = {}
	local spectating, spectateConn, originalSubject = nil, nil, nil
	local flingTarget, flingThread = nil, nil

	local function getRoot(char)
		if not char then return nil end
		return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
	end

	function PlayersSystem.StartSpectate(name)
		local target = Utils.GetPlayerByName and Utils.GetPlayerByName(name)
		if not target or target == LocalPlayer then return false, "Invalid target" end
		if Utils.IsAlive and not Utils.IsAlive(target) then return false, "Target is not alive" end

		PlayersSystem.StopSpectate()
		local cam = Workspace.CurrentCamera
		if not cam then return false, "No camera" end

		spectating = target
		if not originalSubject then originalSubject = cam.CameraSubject end

		local subj = target.Character and (target.Character:FindFirstChildOfClass("Humanoid") or getRoot(target.Character))
		if subj then cam.CameraSubject = subj end

		spectateConn = target.CharacterAdded:Connect(function(char)
			task.wait(0.5)
			if spectating == target then
				local c = Workspace.CurrentCamera
				local s = char:FindFirstChildOfClass("Humanoid") or getRoot(char)
				if c and s then c.CameraSubject = s end
			end
		end)
		if Connections.Add then Connections.Add(spectateConn) end
		return true
	end

	function PlayersSystem.StopSpectate()
		if spectateConn then pcall(function() spectateConn:Disconnect() end) spectateConn = nil end
		local cam = Workspace.CurrentCamera
		if cam then
			if originalSubject and originalSubject.Parent then
				pcall(function() cam.CameraSubject = originalSubject end)
			else
				local hum = Utils.GetHumanoid and Utils.GetHumanoid()
				if hum then cam.CameraSubject = hum end
			end
		end
		originalSubject = nil
		spectating = nil
	end

	function PlayersSystem.GetSpectating() return spectating end

	function PlayersSystem.TeleportTo(name, offset)
		local target = Utils.GetPlayerByName and Utils.GetPlayerByName(name)
		if not target or target == LocalPlayer then return false, "Invalid target" end
		if Utils.IsAlive and not Utils.IsAlive(target) then return false, "Target is not alive" end
		local myRoot = Utils.GetRootPart and Utils.GetRootPart()
		local tRoot = getRoot(target.Character)
		if not myRoot or not tRoot then return false, "Missing character" end
		myRoot.CFrame = tRoot.CFrame + (offset or Vector3.new(0, 3, 3))
		return true
	end

	function PlayersSystem.StartFling(name)
		local target = Utils.GetPlayerByName and Utils.GetPlayerByName(name)
		if not target or target == LocalPlayer then return false, "Invalid target" end
		PlayersSystem.StopFling()
		flingTarget = target

		local loop = task.spawn(function()
			local off = 0.1
			while flingTarget == target and target.Parent do
				RunService.Heartbeat:Wait()
				local myRoot = getRoot(Utils.GetCharacter and Utils.GetCharacter())
				local tRoot = getRoot(target.Character)
				if myRoot and tRoot then
					pcall(function() myRoot.CFrame = tRoot.CFrame end)
					local prev = myRoot.AssemblyLinearVelocity or Vector3.zero
					pcall(function() myRoot.AssemblyLinearVelocity = prev * 10000 + Vector3.new(0, 10000, 0) end)
					RunService.RenderStepped:Wait()
					if myRoot.Parent then pcall(function() myRoot.AssemblyLinearVelocity = prev end) end
					RunService.Stepped:Wait()
					if myRoot.Parent then
						pcall(function() myRoot.AssemblyLinearVelocity = prev + Vector3.new(0, off, 0) end)
						off = -off
					end
				end
			end
		end)
		flingThread = (Connections.Track and Connections.Track(loop)) or loop
		return true
	end

	function PlayersSystem.StopFling()
		flingTarget = nil
		if flingThread then pcall(function() task.cancel(flingThread) end) flingThread = nil end
		local hum = Utils.GetHumanoid and Utils.GetHumanoid()
		local root = Utils.GetRootPart and Utils.GetRootPart()
		if hum then hum.PlatformStand = false end
		if root then
			pcall(function()
				root.AssemblyLinearVelocity = Vector3.zero
				root.AssemblyAngularVelocity = Vector3.zero
			end)
		end
	end

	function PlayersSystem.GetFlingTarget() return flingTarget end

	if Connections and Connections.Add then
		Connections.Add(Players.PlayerRemoving:Connect(function(p)
			if spectating == p then PlayersSystem.StopSpectate() end
			if flingTarget == p then PlayersSystem.StopFling() end
		end))
	end

	return PlayersSystem
end

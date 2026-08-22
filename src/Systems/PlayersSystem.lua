local SETTINGS = {
	TELEPORT_OFFSET = Vector3.new(0, 3, 3),
	PHYSICS = {
		VELOCITY_MULTIPLIER = 10000,
		VERTICAL_BURST = Vector3.new(0, 10000, 0),
		INITIAL_OFFSET = 0.1,
		ROOT_CANDIDATES = { "HumanoidRootPart", "Torso" },
	},
	LIMITS = {
		SPECTATE_RESPAWN_DELAY = 0.5,
	},
	ERRORS = {
		INVALID_TARGET = "Invalid target",
		TARGET_NOT_ALIVE = "Target is not alive",
		MISSING_CHARACTER = "Missing character",
	},
}

return function(Context)
	local Players = game:GetService("Players")
	local Workspace = game:GetService("Workspace")
	local RunService = game:GetService("RunService")

	local LocalPlayer = Players.LocalPlayer
	local Utils = (Context and Context.Utils) or {}
	local Connections = (Context and Context.Connections) or {}

	local PlayersSystem = {}

	local spectatingPlayer = nil
	local spectateConnection = nil
	local originalCameraSubject = nil

	local flingTarget = nil
	local flingThread = nil

	local function getCamera()
		return Workspace.CurrentCamera
	end

	local function getRootPart(character)
		if not character then return nil end
		for _, partName in ipairs(SETTINGS.PHYSICS.ROOT_CANDIDATES) do
			local part = character:FindFirstChild(partName)
			if part and part:IsA("BasePart") then
				return part
			end
		end
		return nil
	end

	local function setLinearVelocity(part, velocity)
		pcall(function()
			part.AssemblyLinearVelocity = velocity
		end)
	end

	local function getLinearVelocity(part)
		return part.AssemblyLinearVelocity or part.Velocity or Vector3.zero
	end

	local function getTargetSubject(character)
		if not character then return nil end
		return character:FindFirstChildOfClass("Humanoid") or getRootPart(character)
	end

	function PlayersSystem.StartSpectate(playerName)
		local target = Utils.GetPlayerByName and Utils.GetPlayerByName(playerName)
		if not target or target == LocalPlayer then
			return false, SETTINGS.ERRORS.INVALID_TARGET
		end
		if Utils.IsAlive and not Utils.IsAlive(target) then
			return false, SETTINGS.ERRORS.TARGET_NOT_ALIVE
		end

		PlayersSystem.StopSpectate()

		local camera = getCamera()
		if not camera then
			return false, SETTINGS.ERRORS.MISSING_CHARACTER
		end

		spectatingPlayer = target
		if not originalCameraSubject then
			originalCameraSubject = camera.CameraSubject
		end

		local subject = getTargetSubject(target.Character)
		if subject then
			camera.CameraSubject = subject
		end

		spectateConnection = target.CharacterAdded:Connect(function(character)
			task.wait(SETTINGS.LIMITS.SPECTATE_RESPAWN_DELAY)
			if spectatingPlayer == target then
				local cam = getCamera()
				local newSubject = getTargetSubject(character)
				if cam and newSubject then
					cam.CameraSubject = newSubject
				end
			end
		end)

		if Connections and type(Connections.Add) == "function" then
			Connections.Add(spectateConnection)
		end

		return true
	end

	function PlayersSystem.StopSpectate()
		if spectateConnection then
			pcall(function()
				spectateConnection:Disconnect()
			end)
			spectateConnection = nil
		end

		local camera = getCamera()
		if camera then
			if originalCameraSubject and originalCameraSubject.Parent then
				pcall(function()
					camera.CameraSubject = originalCameraSubject
				end)
			else
				local myHumanoid = Utils.GetHumanoid and Utils.GetHumanoid()
				if myHumanoid then
					camera.CameraSubject = myHumanoid
				end
			end
		end

		originalCameraSubject = nil
		spectatingPlayer = nil
	end

	function PlayersSystem.GetSpectating()
		return spectatingPlayer
	end

	function PlayersSystem.TeleportTo(playerName, offset)
		local target = Utils.GetPlayerByName and Utils.GetPlayerByName(playerName)
		if not target or target == LocalPlayer then
			return false, SETTINGS.ERRORS.INVALID_TARGET
		end
		if Utils.IsAlive and not Utils.IsAlive(target) then
			return false, SETTINGS.ERRORS.TARGET_NOT_ALIVE
		end

		local myRoot = Utils.GetRootPart and Utils.GetRootPart()
		local targetRoot = getRootPart(target.Character)
		if not myRoot or not targetRoot then
			return false, SETTINGS.ERRORS.MISSING_CHARACTER
		end

		local targetOffset = offset or SETTINGS.TELEPORT_OFFSET
		myRoot.CFrame = targetRoot.CFrame + targetOffset
		return true
	end

	function PlayersSystem.StartFling(playerName)
		local target = Utils.GetPlayerByName and Utils.GetPlayerByName(playerName)
		if not target or target == LocalPlayer then
			return false, SETTINGS.ERRORS.INVALID_TARGET
		end

		PlayersSystem.StopFling()
		flingTarget = target

		local flingLoop = task.spawn(function()
			local stepOffset = SETTINGS.PHYSICS.INITIAL_OFFSET
			while flingTarget == target and target.Parent do
				RunService.Heartbeat:Wait()

				local myChar = Utils.GetCharacter and Utils.GetCharacter()
				local targetChar = target.Character
				if not myChar or not targetChar then continue end

				local myRoot = getRootPart(myChar)
				local targetRoot = getRootPart(targetChar)
				if not myRoot or not targetRoot then continue end

				pcall(function()
					myRoot.CFrame = targetRoot.CFrame
				end)

				local previousVelocity = getLinearVelocity(myRoot)
				local burstVelocity = (previousVelocity * SETTINGS.PHYSICS.VELOCITY_MULTIPLIER) + SETTINGS.PHYSICS.VERTICAL_BURST

				setLinearVelocity(myRoot, burstVelocity)

				RunService.RenderStepped:Wait()
				if myRoot and myRoot.Parent then
					setLinearVelocity(myRoot, previousVelocity)
				end

				RunService.Stepped:Wait()
				if myRoot and myRoot.Parent then
					setLinearVelocity(myRoot, previousVelocity + Vector3.new(0, stepOffset, 0))
					stepOffset = -stepOffset
				end
			end
		end)

		if Connections and type(Connections.Track) == "function" then
			flingThread = Connections.Track(flingLoop)
		else
			flingThread = flingLoop
		end

		return true
	end

	function PlayersSystem.StopFling()
		flingTarget = nil
		if flingThread then
			pcall(function()
				task.cancel(flingThread)
			end)
			flingThread = nil
		end

		local myHumanoid = Utils.GetHumanoid and Utils.GetHumanoid()
		local myRoot = Utils.GetRootPart and Utils.GetRootPart()

		if myHumanoid then
			myHumanoid.PlatformStand = false
		end
		if myRoot then
			setLinearVelocity(myRoot, Vector3.zero)
			pcall(function()
				myRoot.AssemblyAngularVelocity = Vector3.zero
			end)
		end
	end

	function PlayersSystem.GetFlingTarget()
		return flingTarget
	end

	if Connections and type(Connections.Add) == "function" then
		Connections.Add(Players.PlayerRemoving:Connect(function(player)
			if spectatingPlayer == player then
				PlayersSystem.StopSpectate()
			end
			if flingTarget == player then
				PlayersSystem.StopFling()
			end
		end))
	end

	return PlayersSystem
end

local SETTINGS = {
	PHYSICS = {
		VELOCITY_MULTIPLIER = 10000,
		VERTICAL_BURST = Vector3.new(0, 10000, 0),
		INITIAL_OFFSET = 0.1,
		ROOT_CANDIDATES = { "HumanoidRootPart", "Torso" },
	},
}

return function(Context)
	local RunService = game:GetService("RunService")
	local Utils = (Context and Context.Utils) or {}
	local Connections = (Context and Context.Connections) or {}

	local FlingSystem = {
		_active = false,
		_thread = nil,
		_stepOffset = SETTINGS.PHYSICS.INITIAL_OFFSET,
	}

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

	function FlingSystem.Start()
		if FlingSystem._active then return end
		FlingSystem._active = true
		FlingSystem._stepOffset = SETTINGS.PHYSICS.INITIAL_OFFSET

		local flingLoop = task.spawn(function()
			while FlingSystem._active do
				RunService.Heartbeat:Wait()
				local character = Utils.GetCharacter and Utils.GetCharacter()
				local rootPart = getRootPart(character)

				if rootPart and rootPart.Parent then
					local previousVelocity = getLinearVelocity(rootPart)
					local burstVelocity = (previousVelocity * SETTINGS.PHYSICS.VELOCITY_MULTIPLIER) + SETTINGS.PHYSICS.VERTICAL_BURST

					setLinearVelocity(rootPart, burstVelocity)

					RunService.RenderStepped:Wait()
					if rootPart and rootPart.Parent then
						setLinearVelocity(rootPart, previousVelocity)
					end

					RunService.Stepped:Wait()
					if rootPart and rootPart.Parent then
						setLinearVelocity(rootPart, previousVelocity + Vector3.new(0, FlingSystem._stepOffset, 0))
						FlingSystem._stepOffset = -FlingSystem._stepOffset
					end
				end
			end
		end)

		if Connections and type(Connections.Track) == "function" then
			FlingSystem._thread = Connections.Track(flingLoop)
		else
			FlingSystem._thread = flingLoop
		end
	end

	function FlingSystem.Stop()
		FlingSystem._active = false
		if FlingSystem._thread then
			pcall(function()
				task.cancel(FlingSystem._thread)
			end)
			FlingSystem._thread = nil
		end
	end

	return FlingSystem
end

local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

return function(services: any)
	local StateStore = services:Get("StateStore")
	local TaskScheduler = services:Get("TaskScheduler")
	local Disposer = services:Get("Disposer")
	local PlayerTracker = services:Get("PlayerTracker")
	local Environment = services:Get("Environment")

	local FlightService = {
		_active = false,
		-- A child disposer is used for the movers so they can be re-created on
		-- every flight start without touching the shared master disposer.
		_flightDisposer = Disposer:CreateChild("FlightDisposer"),
		_linearVelocity = nil :: LinearVelocity?,
		_bodyGyro = nil :: BodyGyro?,
		_attachment = nil :: Attachment?,
	}

	local function isMobile(): boolean
		return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	end

	function FlightService:CleanupMovers()
		-- A Disposer cannot accept items after Dispose(), so the child
		-- container is discarded and rebuilt on every stop/start cycle.
		self._flightDisposer:Dispose()
		self._flightDisposer = Disposer:CreateChild("FlightDisposer")
		self._linearVelocity = nil
		self._bodyGyro = nil
		self._attachment = nil

		local myAssets = PlayerTracker:GetLocalAssets()
		if myAssets and myAssets.Humanoid then
			myAssets.Humanoid.PlatformStand = false
			myAssets.Humanoid.AutoRotate = true
		end
		if myAssets and myAssets.RootPart then
			myAssets.RootPart.AssemblyLinearVelocity = Vector3.zero
			myAssets.RootPart.AssemblyAngularVelocity = Vector3.zero
		end
	end

	function FlightService:Start()
		if self._active then return end
		if not StateStore:HasPermission("Movement.FlyEnabled") then return end

		local myAssets = PlayerTracker:GetLocalAssets()
		if not (myAssets and myAssets.RootPart and myAssets.Humanoid) then return end

		self:CleanupMovers()
		local root = myAssets.RootPart
		local hum = myAssets.Humanoid

		local attachment = Instance.new("Attachment")
		attachment.Name = "B0XazFlightAttachment"
		attachment.Parent = root
		self._attachment = attachment
		self._flightDisposer:Add(attachment)

		-- LinearVelocity + BodyGyro constraint pair: velocity drives movement
		-- while the gyro holds the assembly level, so the physics solver does
		-- not fight the humanoid controller.
		local linearVel = Instance.new("LinearVelocity")
		linearVel.Name = "B0XazFlightVelocity"
		linearVel.Attachment0 = attachment
		linearVel.MaxForce = 1e7
		linearVel.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
		linearVel.RelativeTo = Enum.ActuatorRelativeTo.World
		linearVel.VectorVelocity = Vector3.zero
		linearVel.Parent = root
		self._linearVelocity = linearVel
		self._flightDisposer:Add(linearVel)

		local bg = Instance.new("BodyGyro")
		bg.Name = "B0XazFlightGyro"
		bg.MaxTorque = Vector3.one * 1e6
		bg.D = 50
		bg.P = 2000
		bg.CFrame = root.CFrame
		bg.Parent = root
		self._bodyGyro = bg
		self._flightDisposer:Add(bg)

		hum.PlatformStand = true
		hum.AutoRotate = false

		self._active = true
		StateStore:Set("Movement.FlyEnabled", true, true)
	end

	function FlightService:Stop()
		if not self._active then return end
		self._active = false
		self:CleanupMovers()
		StateStore:Set("Movement.FlyEnabled", false, true)
	end

	function FlightService:Toggle()
		if self._active then
			self:Stop()
		else
			self:Start()
		end
	end

	local function onFlightUpdate(dt: number)
		if not FlightService._active then
			-- The toggle can be flipped before PlayerTracker finishes indexing
			-- the character, so retry here once the assets become available.
			if StateStore:Get("Movement.FlyEnabled") == true then
				FlightService:Start()
			end
			return
		end

		-- Permission or state can be revoked outside the UI (logout, tier
		-- downgrade), in which case flight must stop on the next tick.
		if StateStore:Get("Movement.FlyEnabled") ~= true or not StateStore:HasPermission("Movement.FlyEnabled") then
			FlightService:Stop()
			return
		end

		local myAssets = PlayerTracker:GetLocalAssets()
		local cam = Workspace.CurrentCamera
		if not (myAssets and myAssets.RootPart and cam and FlightService._linearVelocity and FlightService._bodyGyro) then
			FlightService:Stop()
			return
		end

		-- The velocity constraint ramps the assembly almost instantly, which
		-- the fling guard would read as an impulse; stay suppressed while
		-- flying.
		StateStore:SetTransient("AntiFlingSuppressUntil", os.clock() + 0.1)
		FlightService._bodyGyro.CFrame = cam.CFrame
		local flySpeed = math.clamp(tonumber(StateStore:Get("Movement.FlySpeed")) or 50, 1, 500)
		local moveDir = Vector3.zero

		if not isMobile() then
			local camCF = cam.CFrame
			if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += camCF.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= camCF.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= camCF.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += camCF.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir += Vector3.yAxis end
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir -= Vector3.yAxis end
		else
			local humMove = myAssets.Humanoid.MoveDirection
			if humMove.Magnitude > 0.05 then
				moveDir = humMove
			end
			if StateStore:Get("Movement.MobileFlyUp") then moveDir += Vector3.yAxis end
			if StateStore:Get("Movement.MobileFlyDown") then moveDir -= Vector3.yAxis end
		end

		local targetVel = moveDir.Magnitude > 0 and (moveDir.Unit * flySpeed) or Vector3.zero
		FlightService._linearVelocity.VectorVelocity = targetVel
	end

	function FlightService:Initialize()
		TaskScheduler:RegisterHeartbeat("FlightUpdate", 5, onFlightUpdate)

		local bindConn = UserInputService.InputBegan:Connect(function(input, gp)
			if UserInputService:GetFocusedTextBox() ~= nil or isMobile() or StateStore:GetTransient("IsBindingKey") then return end
			local flyBind = StateStore:Get("Movement.FlyKeybind")
			local parsed = Environment.ParseKeybind(flyBind)
			if parsed and (input.KeyCode == parsed or input.UserInputType == parsed) then
				FlightService:Toggle()
			end
		end)
		Disposer:Add(bindConn)
		Disposer:Add(function()
			self._active = false
			self:CleanupMovers()
		end)

		PlayerTracker:OnLocalCharacterRespawn(function()
			if StateStore:Get("Movement.FlyEnabled") then
				FlightService:Stop()
				task.wait(0.5)
				FlightService:Start()
			end
		end)
	end

	return FlightService
end

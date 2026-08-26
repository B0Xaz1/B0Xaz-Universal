-- ════════════════════════════════════════════════════════════════════════════
-- Services/LocomotionService.lua
-- Locomotion controller, CFrame stepping, and modern constraint flight
-- ════════════════════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local LocomotionService = {}
LocomotionService.__index = LocomotionService

function LocomotionService.new()
	local self = setmetatable({}, LocomotionService)
	self._flyActive = false
	self._flyAttachment = nil
	self._flyVelocity = nil
	return self
end

function LocomotionService:Init(container)
	self._config = container:Get("ConfigService")
	self._entity = container:Get("EntityService")
	self._scheduler = container:Get("Scheduler")
	self._input = container:Get("InputService")
	self._janitor = container:Get("Janitor")
	
	self._localPlayer = Players.LocalPlayer

	-- Infinite Jump Hook
	local jumpConn = UserInputService.JumpRequest:Connect(function()
		if self._config:Get("Movement.InfJump") then
			local char = self._localPlayer.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
		end
	end)
	
	if self._janitor then self._janitor:Add(jumpConn) end

	-- Physics Step Loop
	self._scheduler:AddTask("Physics", "Locomotion_Update", function(dt)
		self:_updateLocomotion(dt)
	end)
end

function LocomotionService:StartFly()
	if self._flyActive then return end
	local char = self._localPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not (root and hum) then return end

	self:StopFly()
	self._flyActive = true

	local attachment = Instance.new("Attachment")
	attachment.Name = "B0XazFlyAttachment"
	attachment.Parent = root

	local lv = Instance.new("LinearVelocity")
	lv.Name = "B0XazFlyVelocity"
	lv.Attachment0 = attachment
	lv.MaxForce = 1e6
	lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	lv.RelativeTo = Enum.ActuatorRelativeTo.World
	lv.VectorVelocity = Vector3.zero
	lv.Parent = root

	self._flyAttachment = attachment
	self._flyVelocity = lv
	hum.PlatformStand = true
	self._config:Set("Movement.FlyEnabled", true)
end

function LocomotionService:StopFly()
	self._flyActive = false
	if self._flyVelocity then pcall(function() self._flyVelocity:Destroy() end) self._flyVelocity = nil end
	if self._flyAttachment then pcall(function() self._flyAttachment:Destroy() end) self._flyAttachment = nil end

	local char = self._localPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart")

	if hum then hum.PlatformStand = false end
	if root then
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
	end
	self._config:Set("Movement.FlyEnabled", false)
end

function LocomotionService:_updateLocomotion(dt)
	local char = self._localPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not (char and hum and root and hum.Health > 0) then return end

	-- Sprint and Base WalkSpeed
	local sprintEnabled = self._config:Get("Movement.SprintEnabled")
	local isSprinting = sprintEnabled and UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
	local targetSpeed = isSprinting and (self._config:Get("Movement.SprintSpeed") or 30) or (self._config:Get("Movement.Speed") or 16)

	if hum.WalkSpeed ~= targetSpeed and not self._flyActive then
		hum.WalkSpeed = targetSpeed
	end

	-- CFrame Movement Stepping
	if self._config:Get("Movement.CFrameSpeed") and not self._flyActive then
		local md = hum.MoveDirection
		if md.Magnitude > 0.05 then
			local sps = self._config:Get("Movement.CFrameSpeedValue") or 50
			root.CFrame = root.CFrame + (md * sps * dt)
		end
	end

	-- Flight Physics Update
	if self._flyActive and self._flyVelocity then
		local cam = Workspace.CurrentCamera
		if not cam then return end

		local dir = Vector3.zero
		local speed = self._config:Get("Movement.FlySpeed") or 50

		if not self._input.IsMobile then
			local cf = cam.CFrame
			if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cf.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cf.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cf.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cf.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.yAxis end
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.yAxis end
		else
			dir = hum.MoveDirection
		end

		self._flyVelocity.VectorVelocity = dir.Magnitude > 0 and (dir.Unit * speed) or Vector3.zero
	end
end

function LocomotionService:Destroy()
	self:StopFly()
end

return LocomotionService

-- ════════════════════════════════════════════════════════════════════════════
-- Services/FlingService.lua
-- Deterministic physics momentum and velocity oscillation engine
-- ════════════════════════════════════════════════════════════════════════════

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local FlingService = {}
FlingService.__index = FlingService

function FlingService.new()
	local self = setmetatable({}, FlingService)
	self.IsFlinging = false
	self.TargetPlayer = nil
	self._thread = nil
	return self
end

function FlingService:Init(container)
	self._entity = container:Get("EntityService")
	self._janitor = container:Get("Janitor")
	self._localPlayer = Players.LocalPlayer
end

-- Launches self-flinging or targets a remote player
function FlingService:Start(targetPlayer)
	self:Stop()
	self.IsFlinging = true
	self.TargetPlayer = targetPlayer

	self._thread = task.spawn(function()
		local offset = 0.1
		while self.IsFlinging do
			RunService.Heartbeat:Wait()
			
			local myChar = self._localPlayer.Character
			local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
			if not myRoot then break end

			if self.TargetPlayer then
				local targetAssets = self._entity:GetAssets(self.TargetPlayer)
				if not targetAssets or not targetAssets.RootPart then break end
				pcall(function() myRoot.CFrame = targetAssets.RootPart.CFrame end)
			end

			local prevVel = myRoot.AssemblyLinearVelocity or Vector3.zero
			pcall(function()
				myRoot.AssemblyLinearVelocity = prevVel * 10000 + Vector3.new(0, 10000, 0)
			end)

			RunService.RenderStepped:Wait()
			if myRoot.Parent then
				pcall(function() myRoot.AssemblyLinearVelocity = prevVel end)
			end

			RunService.Stepped:Wait()
			if myRoot.Parent then
				pcall(function()
					myRoot.AssemblyLinearVelocity = prevVel + Vector3.new(0, offset, 0)
				end)
				offset = -offset
			end
		end
		self:Stop()
	end)
end

-- Halts active fling tasks and neutralizes residual player physics
function FlingService:Stop()
	self.IsFlinging = false
	self.TargetPlayer = nil

	if self._thread then
		pcall(task.cancel, self._thread)
		self._thread = nil
	end

	local char = self._localPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart")

	if hum then hum.PlatformStand = false end
	if root then
		pcall(function()
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
		end)
	end
end

function FlingService:Destroy()
	self:Stop()
end

return FlingService

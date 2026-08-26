-- ════════════════════════════════════════════════════════════════════════════
-- Services/CombatService.lua
-- Combat targeting pipeline, trajectory prediction, and aiming drivers
-- ════════════════════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local CombatService = {}
CombatService.__index = CombatService

local BODY_PARTS = {
	Head = "Head",
	Torso = "UpperTorso",
	Root = "HumanoidRootPart",
}

function CombatService.new()
	local self = setmetatable({}, CombatService)
	self.TargetPlayer = nil
	self.IsAiming = false
	self._windVelocity = Vector2.zero
	self._lastTriggerTime = 0
	return self
end

function CombatService:Init(container)
	self._config = container:Get("ConfigService")
	self._entity = container:Get("EntityService")
	self._math = container:Get("MathUtil")
	self._spatial = container:Get("SpatialUtil")
	self._input = container:Get("InputService")
	self._scheduler = container:Get("Scheduler")
	self._localPlayer = Players.LocalPlayer

	-- Aim render step loop
	self._scheduler:AddTask("Render", "Combat_AimLoop", function(dt)
		self:_updateAimbot(dt)
		self:_updateTriggerbot()
	end)

	-- Input binding listener
	self._input.OnInputBegan:Connect(function(input, gp)
		if gp or not self._config:Get("Aimbot.Enabled") then return end
		local bind = self._config:Get("Aimbot.Keybind")
		if self._input:MatchesBind(input, bind) then
			if self._config:Get("Aimbot.LockMode") == "Toggle" then
				self.IsAiming = not self.IsAiming
				if not self.IsAiming then self.TargetPlayer = nil end
			else
				self.IsAiming = true
			end
		end
	end)

	self._input.OnInputEnded:Connect(function(input)
		local bind = self._config:Get("Aimbot.Keybind")
		if self._input:MatchesBind(input, bind) and self._config:Get("Aimbot.LockMode") == "Hold" then
			self.IsAiming = false
			self.TargetPlayer = nil
			self._windVelocity = Vector2.zero
		end
	end)
end

-- Resolve best target inside FOV circle
function CombatService:GetClosestTarget()
	local mousePos = self._input:GetMouseViewportPosition()
	local maxFov = self._config:Get("Aimbot.FOV.Size") or 150
	local maxFovSq = maxFov * maxFov
	local bestTarget, bestDistSq = nil, math.huge

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= self._localPlayer then
			local assets = self._entity:GetAssets(player)
			if assets and assets.Character and assets.Head then
				local screenPos, onScreen = self._spatial.WorldToViewport(assets.Head.Position)
				if onScreen then
					local distSq = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).NonlinearMagnitude or ((screenPos.X - mousePos.X)^2 + (screenPos.Y - mousePos.Y)^2)
					if distSq <= maxFovSq and distSq < bestDistSq then
						if self._spatial.IsVisible(assets.Head) then
							bestDistSq = distSq
							bestTarget = player
						end
					end
				end
			end
		end
	end
	return bestTarget
end

function CombatService:_updateAimbot(dt)
	if not (self._config:Get("Aimbot.Enabled") and self.IsAiming) then return end

	if not self.TargetPlayer or not self._entity:GetAssets(self.TargetPlayer) then
		self.TargetPlayer = self:GetClosestTarget()
	end
	if not self.TargetPlayer then return end

	local assets = self._entity:GetAssets(self.TargetPlayer)
	if not assets or not assets.Character then return end

	local hitpartName = BODY_PARTS[self._config:Get("Aimbot.Hitpart")] or "Head"
	local targetPart = assets.Character:FindFirstChild(hitpartName) or assets.Head
	if not targetPart then return end

	local pred = self._config:Get("Aimbot.Prediction") or { Horizontal = 0, Vertical = 0 }
	local aimPosition = self._math.PredictPosition(
		targetPart.Position, 
		targetPart.AssemblyLinearVelocity, 
		pred.Horizontal, 
		pred.Vertical
	)

	local screenPos, onScreen = self._spatial.WorldToViewport(aimPosition)
	if not onScreen then return end

	local mousePos = self._input:GetMouseViewportPosition()
	local delta = Vector2.new(screenPos.X, screenPos.Y) - mousePos
	local smooth = self._config:Get("Aimbot.Smoothness") or 4

	if self._config:Get("Aimbot.UseCamera") then
		local camera = Workspace.CurrentCamera
		if camera then
			local targetCF = CFrame.lookAt(camera.CFrame.Position, aimPosition)
			camera.CFrame = camera.CFrame:Lerp(targetCF, 1 - math.exp(-dt * (60 / smooth)))
		end
	else
		local alpha = 1 - math.exp(-dt * (60 / smooth))
		local step = delta * alpha
		if self._config:Get("Aimbot.MovementMode") == "WindMouse" then
			local strength = self._config:Get("Aimbot.WindStrength") or 1
			local damping = self._config:Get("Aimbot.WindDamping") or 0.8
			step, self._windVelocity = self._math.CalculateWindMouseStep(delta, alpha, dt, strength, damping, self._windVelocity)
		end
		if mousemoverel and step.Magnitude > 0.5 then
			mousemoverel(math.floor(step.X), math.floor(step.Y))
		end
	end
end

function CombatService:_updateTriggerbot()
	if not (self._config:Get("Aimbot.Enabled") and self._config:Get("Aimbot.Triggerbot.Enabled")) then return end
	local now = os.clock()
	local delay = self._config:Get("Aimbot.Triggerbot.Delay") or 0.05
	if now - self._lastTriggerTime < (delay + 0.05) then return end

	local mousePos = self._input:GetMouseViewportPosition()
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= self._localPlayer then
			local assets = self._entity:GetAssets(player)
			if assets and assets.Head then
				local sp, onScreen = self._spatial.WorldToViewport(assets.Head.Position)
				if onScreen and (Vector2.new(sp.X, sp.Y) - mousePos).Magnitude <= 14 then
					self._lastTriggerTime = now
					if mouse1click then
						pcall(mouse1click)
					else
						pcall(function()
							VirtualInputManager:SendMouseButtonEvent(mousePos.X, mousePos.Y, 0, true, game, 1)
							task.wait(0.02)
							VirtualInputManager:SendMouseButtonEvent(mousePos.X, mousePos.Y, 0, false, game, 1)
						end)
					end
					break
				end
			end
		end
	end
end

function CombatService:Destroy()
	self.TargetPlayer = nil
	self.IsAiming = false
end

return CombatService

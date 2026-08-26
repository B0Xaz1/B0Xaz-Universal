-- ════════════════════════════════════════════════════════════════════════════
-- Games/Adapters/PrisonLife/MeleeController.lua
-- Melee remote dispatch, Punch Aura, Super Punch, and Anti-Taser system
-- ════════════════════════════════════════════════════════════════════════════

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local MeleeController = {}
MeleeController.__index = MeleeController

function MeleeController.new(configService, entityService)
	local self = setmetatable({}, MeleeController)
	self._config = configService
	self._entity = entityService
	self._meleeEvent = ReplicatedStorage:FindFirstChild("meleeEvent")
	self._localPlayer = Players.LocalPlayer
	self._lastPunch = 0
	return self
end

function MeleeController:FireMelee(target)
	if not self._meleeEvent then
		self._meleeEvent = ReplicatedStorage:FindFirstChild("meleeEvent")
	end
	if self._meleeEvent then
		pcall(function()
			if target then self._meleeEvent:FireServer(target) else self._meleeEvent:FireServer() end
		end)
	end
end

function MeleeController:RunPunchAura()
	if not self._config:Get("Game.PunchAura") then return end
	local now = os.clock()
	if now - self._lastPunch < 0.1 then return end
	self._lastPunch = now

	local myChar = self._localPlayer.Character
	local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
	if not myRoot then return end

	local maxDist = self._config:Get("Game.PunchAuraRange") or 15
	local maxDistSq = maxDist * maxDist

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= self._localPlayer then
			local assets = self._entity:GetAssets(player)
			if assets and assets.RootPart then
				local distSq = (assets.RootPart.Position - myRoot.Position).Magnitude^2
				if distSq <= maxDistSq then
					self:FireMelee(player)
				end
			end
		end
	end
end

function MeleeController:ExecuteSuperPunch()
	if not self._config:Get("Game.SuperPunch") then return end
	local hits = math.clamp(self._config:Get("Game.SuperPunchHits") or 10, 1, 30)
	for _ = 1, hits do
		self:FireMelee()
	end
end

function MeleeController:EnforceAntiRestrict()
	if not self._config:Get("Game.AntiRestrict") then return end
	local char = self._localPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		if hum.WalkSpeed < 16 and not self._config:Get("Movement.FlyEnabled") then
			hum.WalkSpeed = self._config:Get("Movement.Speed") or 16
		end
		if hum.JumpPower < 50 then hum.JumpPower = self._config:Get("Movement.JumpPower") or 50 end
		if hum.PlatformStand then hum.PlatformStand = false end
	end
end

return MeleeController

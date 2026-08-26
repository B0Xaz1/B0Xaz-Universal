--!strict

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

return function(services: any)
	local StateStore = services:Get("StateStore")
	local TaskScheduler = services:Get("TaskScheduler")
	local Disposer = services:Get("Disposer")
	local PlayerTracker = services:Get("PlayerTracker")
	local TargetFilter = services:Get("TargetFilter")

	local LocalPlayer = Players.LocalPlayer
	local TriggerbotService = {
		_isFiring = false,
		_lastTriggerTime = 0,
	}

	local function executeClick()
		-- Prefer the executor's native click when present; otherwise emulate
		-- a full press/release pair through the virtual input manager
		if mouse1click and typeof(mouse1click) == "function" then
			pcall(mouse1click)
		else
			local mousePos = UserInputService:GetMouseLocation()
			VirtualInputManager:SendMouseButtonEvent(mousePos.X, mousePos.Y, 0, true, game, 1)
			task.wait(0.02)
			VirtualInputManager:SendMouseButtonEvent(mousePos.X, mousePos.Y, 0, false, game, 1)
		end
	end

	local function onPreSimUpdate(dt: number)
		local aimCfg = StateStore:Get("Aimbot")
		local triggerCfg = aimCfg and aimCfg.Triggerbot
		if not aimCfg or not aimCfg.Enabled or not triggerCfg or not triggerCfg.Enabled then
			return
		end
		if not StateStore:HasPermission("Aimbot.Triggerbot.Enabled") then
			return
		end

		-- The configured delay gates both the pre-check and the actual click,
		-- so the slider value is honored end to end
		local delayTime = math.clamp(tonumber(triggerCfg.Delay) or 0.05, 0, 0.5)
		local now = os.clock()
		if TriggerbotService._isFiring or (now - TriggerbotService._lastTriggerTime) < delayTime then
			return
		end

		local cam = Workspace.CurrentCamera
		if not cam then return end

		local mousePos = UserInputService:GetMouseLocation()
		local myAssets = PlayerTracker:GetLocalAssets()
		local myPos = myAssets and myAssets.RootPart and myAssets.RootPart.Position or cam.CFrame.Position

		local maxDist = tonumber(triggerCfg.MaxDistance) or 1000
		local maxDistSq = maxDist * maxDist
		local toleranceSq = 196 -- 14px radius squared

		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer then
				local assets = PlayerTracker:GetPlayerAssets(player)
				if assets and assets.Character and assets.Humanoid.Health > 0 then
					if TargetFilter:ValidateTarget(player, assets.RootPart, triggerCfg) then
						local rootPos = assets.RootPart.Position
						local dist3DSq = (myPos - rootPos).Magnitude ^ 2

						if dist3DSq <= maxDistSq then
							local screenPos, onScreen = cam:WorldToViewportPoint(rootPos)
							if onScreen and screenPos.Z > 0 then
								local dx = mousePos.X - screenPos.X
								local dy = mousePos.Y - screenPos.Y
								if (dx * dx + dy * dy) <= toleranceSq then
									TriggerbotService._isFiring = true
									TriggerbotService._lastTriggerTime = now

									Disposer:Delay(delayTime, function()
										if StateStore:Get("Aimbot.Triggerbot.Enabled") then
											executeClick()
										end
										TriggerbotService._isFiring = false
									end)
									return
								end
							end
						end
					end
				end
			end
		end
	end

	function TriggerbotService:Initialize()
		TaskScheduler:RegisterPreSim("TriggerbotUpdate", 5, onPreSimUpdate)
	end

	return TriggerbotService
end

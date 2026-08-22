-- // src/Systems/FlingSystem.lua
return function(Context)
	local RunService = game:GetService("RunService")
	local Utils = Context.Utils or {}
	local Connections = Context.Connections or {}

	local FlingSystem = { _active = false, _thread = nil, _offset = 0.1 }

	local function getRoot(char)
		if not char then return nil end
		return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
	end

	function FlingSystem.Start()
		if FlingSystem._active then return end
		FlingSystem._active = true
		FlingSystem._offset = 0.1

		local loop = task.spawn(function()
			while FlingSystem._active do
				RunService.Heartbeat:Wait()
				local root = getRoot(Utils.GetCharacter and Utils.GetCharacter())
				if root and root.Parent then
					local prev = root.AssemblyLinearVelocity or Vector3.zero
					pcall(function()
						root.AssemblyLinearVelocity = prev * 10000 + Vector3.new(0, 10000, 0)
					end)
					RunService.RenderStepped:Wait()
					if root.Parent then
						pcall(function() root.AssemblyLinearVelocity = prev end)
					end
					RunService.Stepped:Wait()
					if root.Parent then
						pcall(function()
							root.AssemblyLinearVelocity = prev + Vector3.new(0, FlingSystem._offset, 0)
						end)
						FlingSystem._offset = -FlingSystem._offset
					end
				end
			end
		end)

		FlingSystem._thread = (Connections.Track and Connections.Track(loop)) or loop
	end

	function FlingSystem.Stop()
		FlingSystem._active = false
		if FlingSystem._thread then
			pcall(function() task.cancel(FlingSystem._thread) end)
			FlingSystem._thread = nil
		end
	end

	return FlingSystem
end

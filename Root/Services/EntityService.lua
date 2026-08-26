-- ════════════════════════════════════════════════════════════════════════════
-- Services/EntityService.lua
-- Event-driven fast O(1) character and humanoid tracking repository
-- ════════════════════════════════════════════════════════════════════════════

local Players = game:GetService("Players")

local EntityService = {}
EntityService.__index = EntityService

function EntityService.new()
	local self = setmetatable({}, EntityService)
	self._cache = setmetatable({}, { __mode = "k" })
	self._connections = {}
	return self
end

function EntityService:Init(container)
	self._janitor = container:Get("Janitor")
	
	local function track(player)
		if player == Players.LocalPlayer then return end
		
		local function onCharacter(char)
			if not char then return end
			
			local hum = char:WaitForChild("Humanoid", 5)
			local root = char:WaitForChild("HumanoidRootPart", 5)
			local head = char:WaitForChild("Head", 5)
			
			if hum and root and head then
				self._cache[player] = {
					Character = char,
					Humanoid = hum,
					RootPart = root,
					Head = head,
					RigType = hum.RigType,
				}
			end
		end

		table.insert(self._connections, player.CharacterAdded:Connect(onCharacter))
		table.insert(self._connections, player.CharacterRemoving:Connect(function()
			self._cache[player] = nil
		end))
		
		if player.Character then
			task.spawn(onCharacter, player.Character)
		end
	end

	table.insert(self._connections, Players.PlayerAdded:Connect(track))
	table.insert(self._connections, Players.PlayerRemoving:Connect(function(player)
		self._cache[player] = nil
	end))

	for _, player in ipairs(Players:GetPlayers()) do
		track(player)
	end
	
	if self._janitor then
		for _, conn in ipairs(self._connections) do
			self._janitor:Add(conn)
		end
	end
end

-- O(1) retrieval of cached player assets
function EntityService:GetAssets(player)
	local assets = self._cache[player]
	if assets and assets.Character and assets.Character.Parent 
		and assets.Humanoid and assets.Humanoid.Health > 0 then
		return assets
	end
	return nil
end

function EntityService:Destroy()
	for _, conn in ipairs(self._connections) do
		pcall(conn.Disconnect, conn)
	end
	table.clear(self._cache)
	table.clear(self._connections)
end

return EntityService

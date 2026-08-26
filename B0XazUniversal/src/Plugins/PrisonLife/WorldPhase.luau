--!strict

local Workspace = game:GetService("Workspace")

type DoorBackup = {
	CanCollide: boolean,
	Transparency: number,
	Color: Color3,
	Material: Enum.Material,
}

return function(services: any, manifest: any)
	local StateStore = services:Get("StateStore")
	local Disposer = services:Get("Disposer")

	local WorldPhase = {
		_doorCache = {} :: { [BasePart]: DoorBackup },
		_doorConnections = {} :: { [BasePart]: RBXScriptConnection },
		_pluginDisposer = Disposer:CreateChild("WorldPhaseDisposer"),
	}

	local NEON_MAT = Enum.Material.Neon

	-- A part counts as a door if any ancestor folder matches a known
	-- container name; walking up is bounded by the workspace depth.
	local function isDoorPart(part: BasePart): boolean
		local parent = part.Parent
		while parent and parent ~= Workspace do
			if manifest.DOOR_FOLDERS[parent.Name:lower()] == true then
				return true
			end
			parent = parent.Parent
		end
		return false
	end

	function WorldPhase:ProcessPart(part: BasePart)
		if not isDoorPart(part) then return end

		-- Originals are cached once, before the first visual change, so
		-- repeated processing never overwrites the true backup values.
		if not self._doorCache[part] then
			self._doorCache[part] = {
				CanCollide = part.CanCollide,
				Transparency = part.Transparency,
				Color = part.Color,
				Material = part.Material,
			}
		end

		local phaseEnabled = StateStore:Get("Game.DoorPhase") == true
		if not phaseEnabled then return end

		part.CanCollide = false
		local transparency = tonumber(StateStore:Get("Game.PhaseTransparency")) or 0.65
		part.Transparency = math.clamp(transparency, 0.1, 0.95)

		if StateStore:Get("Game.DoorGlow") == true then
			part.Material = NEON_MAT
			part.Color = StateStore:Get("Game.GlowColor") or Color3.fromRGB(0, 200, 220)
		end

		-- The game can re-enable collision on its own (doors closing), so a
		-- property listener re-asserts the phase while it is enabled.
		if not self._doorConnections[part] then
			self._doorConnections[part] = part:GetPropertyChangedSignal("CanCollide"):Connect(function()
				if StateStore:Get("Game.DoorPhase") == true and part.CanCollide then
					part.CanCollide = false
				end
			end)
		end
	end

	function WorldPhase:ScanAllDoors()
		for _, child in ipairs(Workspace:GetChildren()) do
			if manifest.DOOR_FOLDERS[child.Name:lower()] == true then
				for _, descendant in ipairs(child:GetDescendants()) do
					if descendant:IsA("BasePart") then
						self:ProcessPart(descendant)
					end
				end
			end
		end
	end

	function WorldPhase:RestoreAll()
		for part, conn in pairs(self._doorConnections) do
			conn:Disconnect()
		end
		table.clear(self._doorConnections)

		for part, backup in pairs(self._doorCache) do
			if part and part.Parent then
				part.CanCollide = backup.CanCollide
				part.Transparency = backup.Transparency
				part.Color = backup.Color
				part.Material = backup.Material
			end
		end
		table.clear(self._doorCache)
	end

	function WorldPhase:Initialize()
		-- New obstacles are picked up without a full workspace rescan
		local descConn = Workspace.DescendantAdded:Connect(function(d)
			if StateStore:Get("Game.DoorPhase") and d:IsA("BasePart") then
				task.defer(function() self:ProcessPart(d :: BasePart) end)
			end
		end)
		self._pluginDisposer:Add(descConn)
	end

	return WorldPhase
end

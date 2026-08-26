--!strict
-- ══════════════════════════════════════════════════════════════════════════════
-- B0XazUniversal - Prison Life Reactive Weapon Attributes Modifier
-- Modifies SpreadRadius, FireRate, AutoFire, and Range on all weapons
-- using event-driven container listeners with zero periodic polling.
-- ══════════════════════════════════════════════════════════════════════════════

local Players = game:GetService("Players")

type GunAttributeBackup = { [string]: any }

return function(services: any, manifest: any)
	local StateStore = services:Get("StateStore")
	local Disposer = services:Get("Disposer")
	local LocalPlayer = Players.LocalPlayer

	local WeaponMods = {
		_attributeBackups = {} :: { [Instance]: GunAttributeBackup },
		_containerConns = {} :: { [Instance]: RBXScriptConnection },
		_pluginDisposer = Disposer:CreateChild("WeaponModsDisposer"),
	}

	local function modifyInstance(obj: Instance)
		local isNoSpread = StateStore:Get("Game.NoSpread") == true
		local isFastFire = StateStore:Get("Game.FastFire") == true
		local isForceAuto = StateStore:Get("Game.ForceAuto") == true
		local isForceRange = StateStore:Get("Game.ForceRange") == true

		if not (isNoSpread or isFastFire or isForceAuto or isForceRange) then return end

		if not WeaponMods._attributeBackups[obj] then
			WeaponMods._attributeBackups[obj] = {
				SpreadRadius = obj:GetAttribute("SpreadRadius"),
				FireRate = obj:GetAttribute("FireRate"),
				AutoFire = obj:GetAttribute("AutoFire"),
				Range = obj:GetAttribute("Range"),
			}
		end

		if isNoSpread and obj:GetAttribute("SpreadRadius") ~= nil then
			obj:SetAttribute("SpreadRadius", 0)
		end
		if isFastFire and obj:GetAttribute("FireRate") ~= nil then
			obj:SetAttribute("FireRate", 0.001)
		end
		if isForceAuto and obj:GetAttribute("AutoFire") ~= nil then
			obj:SetAttribute("AutoFire", true)
		end
		if isForceRange and obj:GetAttribute("Range") ~= nil then
			obj:SetAttribute("Range", 10000)
		end
	end

	function WeaponMods:ApplyToTool(tool: Tool)
		if not manifest.PRISON_GUNS[tool.Name] then return end
		modifyInstance(tool)
		for _, child in ipairs(tool:GetDescendants()) do
			if child:GetAttribute("SpreadRadius") ~= nil or child:GetAttribute("FireRate") ~= nil or child:GetAttribute("AutoFire") ~= nil then
				modifyInstance(child)
			end
		end
	end

	function WeaponMods:ScanAllWeapons()
		local containers = {}
		if LocalPlayer then
			local bp = LocalPlayer:FindFirstChild("Backpack")
			if bp then table.insert(containers, bp) end
			if LocalPlayer.Character then table.insert(containers, LocalPlayer.Character) end
		end
		for _, container in ipairs(containers) do
			for _, tool in ipairs(container:GetChildren()) do
				if tool:IsA("Tool") then
					self:ApplyToTool(tool)
				end
			end
		end
	end

	function WeaponMods:RestoreAll()
		for obj, backups in pairs(self._attributeBackups) do
			if obj and obj.Parent then
				for attr, val in pairs(backups) do
					obj:SetAttribute(attr, val)
				end
			end
		end
		table.clear(self._attributeBackups)
	end

	function WeaponMods:HookContainer(container: Instance?)
		if not container then return end
		if self._containerConns[container] then
			self._containerConns[container]:Disconnect()
		end

		self._containerConns[container] = container.ChildAdded:Connect(function(child)
			if child:IsA("Tool") and manifest.PRISON_GUNS[child.Name] then
				task.defer(function() self:ApplyToTool(child) end)
			end
		end)
	end

	function WeaponMods:Initialize()
		if LocalPlayer then
			self:HookContainer(LocalPlayer:FindFirstChild("Backpack"))
			self:HookContainer(LocalPlayer.Character)

			LocalPlayer.CharacterAdded:Connect(function(char)
				self:HookContainer(char)
				local bp = LocalPlayer:WaitForChild("Backpack", 5)
				self:HookContainer(bp)
				task.wait(0.5)
				self:ScanAllWeapons()
			end)
		end
	end

	return WeaponMods
end

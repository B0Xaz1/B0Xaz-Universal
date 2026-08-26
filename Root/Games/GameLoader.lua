-- ════════════════════════════════════════════════════════════════════════════
-- Games/GameLoader.lua
-- Discovers, loads, and manages lifecycle for game-specific adapters
-- ════════════════════════════════════════════════════════════════════════════

local GameRegistry = require(script.Parent.GameRegistry)

local GameLoader = {}
GameLoader.__index = GameLoader

function GameLoader.new()
	local self = setmetatable({}, GameLoader)
	self.PlaceId = tostring(game.PlaceId)
	self.UniverseId = tostring(game.GameId)
	self.Info = GameRegistry.Resolve(self.PlaceId, self.UniverseId)
	self.Adapter = nil
	return self
end

function GameLoader:Init(container)
	self._container = container
	if self:IsSupported() then
		self:Load()
	end
end

function GameLoader:IsSupported()
	return self.Info ~= nil
end

function GameLoader:GetDisplayName()
	return self.Info and self.Info.Name or "Universal Mode"
end

function GameLoader:Load()
	if self.Adapter then return self.Adapter end
	if not self:IsSupported() then return nil end

	-- Resolve adapter instance by folder name
	if self.Info.Folder == "PrisonLife" then
		local PrisonLifeAdapter = require(script.Parent.Adapters.PrisonLife.PrisonLifeAdapter)
		self.Adapter = PrisonLifeAdapter.new()
		if type(self.Adapter.Init) == "function" then
			self.Adapter:Init(self._container)
		end
		return self.Adapter
	end

	return nil
end

function GameLoader:BuildUI(tab)
	if self.Adapter and type(self.Adapter.BuildUI) == "function" then
		return pcall(self.Adapter.BuildUI, self.Adapter, tab)
	end
	return false, "No adapter UI"
end

function GameLoader:Update(dt)
	if self.Adapter and type(self.Adapter.Update) == "function" then
		pcall(self.Adapter.Update, self.Adapter, dt)
	end
end

function GameLoader:Destroy()
	if self.Adapter and type(self.Adapter.Destroy) == "function" then
		pcall(self.Adapter.Destroy, self.Adapter)
	end
	self.Adapter = nil
end

return GameLoader

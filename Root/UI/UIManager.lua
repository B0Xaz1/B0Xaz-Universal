-- ════════════════════════════════════════════════════════════════════════════
-- UI/UIManager.lua
-- Instantiates draggable windows and binds UI presentational state
-- ════════════════════════════════════════════════════════════════════════════

local Window = require(script.Parent.Window)
local CombatPresenter = require(script.Parent.Presenters.CombatPresenter)
local VisualsPresenter = require(script.Parent.Presenters.VisualsPresenter)
local MovementPresenter = require(script.Parent.Presenters.MovementPresenter)
local PlayersPresenter = require(script.Parent.Presenters.PlayersPresenter)
local UtilityPresenter = require(script.Parent.Presenters.UtilityPresenter)
local SettingsPresenter = require(script.Parent.Presenters.SettingsPresenter)
local GamePresenter = require(script.Parent.Presenters.GamePresenter)

local UIManager = {}
UIManager.__index = UIManager

function UIManager.new()
	return setmetatable({}, UIManager)
end

function UIManager:Init(container)
	self._config = container:Get("ConfigService")
	self._theme = container:Get("ThemeEngine")
	self._input = container:Get("InputService")
	self._janitor = container:Get("Janitor")
	self._container = container

	-- Initialize Window
	self.Window = Window.new("B0Xaz Universal Hub", self._theme, container)
	self._janitor:Add(self.Window)

	-- Build Core UI Page Tabs
	local combatTab = self.Window:AddTab("Combat")
	local visualsTab = self.Window:AddTab("Visuals")
	local movementTab = self.Window:AddTab("Movement")
	local playersTab = self.Window:AddTab("Players")
	local gameTab = self.Window:AddTab("Game")
	local utilityTab = self.Window:AddTab("Utility")
	local settingsTab = self.Window:AddTab("Settings")

	-- Bind Presenter Controllers to Views
	CombatPresenter.Build(combatTab, container, self._theme)
	VisualsPresenter.Build(visualsTab, container, self._theme)
	MovementPresenter.Build(movementTab, container, self._theme)
	PlayersPresenter.Build(playersTab, container, self._theme)
	GamePresenter.Build(gameTab, container, self._theme)
	UtilityPresenter.Build(utilityTab, container, self._theme)
	SettingsPresenter.Build(settingsTab, container, self._theme)

	-- Hook Viewport Toggle Hotkey
	local inputConn = self._input.OnInputBegan:Connect(function(input, gp)
		if gp then return end
		local toggleBind = self._config:Get("Settings.MenuKeybind")
		if self._input:MatchesBind(input, toggleBind) then
			self.Window:SetVisible(not self.Window.Visible)
		end
	end)
	self._janitor:Add(inputConn)
end

function UIManager:Destroy()
	if self.Window then self.Window:Destroy() end
end

return UIManager

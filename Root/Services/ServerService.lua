-- ════════════════════════════════════════════════════════════════════════════
-- Services/ServerService.lua
-- Anti-AFK controller, server hopping, and teleport persistence
-- ════════════════════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")

local ServerService = {}
ServerService.__index = ServerService

function ServerService.new()
	local self = setmetatable({}, ServerService)
	self._afkConn = nil
	return self
end

function ServerService:Init(container)
	self._config = container:Get("ConfigService")
	self._http = container:Get("HttpUtil")
	self._janitor = container:Get("Janitor")
	self._localPlayer = Players.LocalPlayer

	self:SetAntiAfk(self._config:Get("Settings.AntiAfk") == true)
end

function ServerService:SetAntiAfk(enabled)
	self._config:Set("Settings.AntiAfk", enabled)
	if self._afkConn then
		pcall(self._afkConn.Disconnect, self._afkConn)
		self._afkConn = nil
	end

	if enabled and self._localPlayer then
		self._afkConn = self._localPlayer.Idled:Connect(function()
			pcall(function()
				VirtualUser:CaptureController()
				VirtualUser:ClickButton2(Vector2.zero)
			end)
		end)
		if self._janitor then self._janitor:Add(self._afkConn) end
	end
end

function ServerService:ServerHop()
	local url = string.format("https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Asc&limit=100", tostring(game.PlaceId))
	local ok, res = self._http.Request({ Url = url, Method = "GET" })
	if not ok or not res then return false, "Failed to contact Roblox server API" end

	local data = self._http.JSONDecode(res.Body or res.body)
	if not data or not data.data then return false, "Invalid server list data" end

	for _, server in ipairs(data.data) do
		if server.id ~= game.JobId and server.playing and server.maxPlayers and server.playing < server.maxPlayers then
			self:PrepareTeleport()
			pcall(function()
				TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, self._localPlayer)
			end)
			return true
		end
	end
	return false, "No viable public servers found"
end

function ServerService:PrepareTeleport()
	local queueFn = queue_on_teleport or (syn and syn.queue_on_teleport) or queueonteleport
	if not queueFn then return end

	local code = [[
		repeat task.wait() until game:IsLoaded()
		task.wait(1)
		if isfile and isfile("B0XazUniversal/AutoRun.lua") then
			pcall(function() loadstring(readfile("B0XazUniversal/AutoRun.lua"))() end)
		end
	]]
	pcall(queueFn, code)
end

function ServerService:Destroy()
	if self._afkConn then pcall(self._afkConn.Disconnect, self._afkConn) end
end

return ServerService

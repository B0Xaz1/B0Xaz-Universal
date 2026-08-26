-- ════════════════════════════════════════════════════════════════════════════
-- Core/Signal.lua
-- Lightweight decoupled Observer / Event Signal
-- ════════════════════════════════════════════════════════════════════════════

local Signal = {}
Signal.__index = Signal

local Connection = {}
Connection.__index = Connection

function Connection.new(signal, callback)
	return setmetatable({
		_signal = signal,
		_callback = callback,
		Connected = true,
	}, Connection)
end

function Connection:Disconnect()
	if not self.Connected then return end
	self.Connected = false
	local listeners = self._signal._listeners
	for i = 1, #listeners do
		if listeners[i] == self then
			table.remove(listeners, i)
			break
		end
	end
end

function Signal.new()
	local self = setmetatable({}, Signal)
	self._listeners = {}
	return self
end

function Signal:Connect(callback)
	assert(type(callback) == "function", "Signal:Connect requires a function")
	local conn = Connection.new(self, callback)
	table.insert(self._listeners, conn)
	return conn
end

function Signal:Fire(...)
	local listeners = self._listeners
	for i = 1, #listeners do
		local conn = listeners[i]
		if conn and conn.Connected then
			task.spawn(conn._callback, ...)
		end
	end
end

function Signal:Wait()
	local thread = coroutine.running()
	local conn
	conn = self:Connect(function(...)
		conn:Disconnect()
		task.spawn(thread, ...)
	end)
	return coroutine.yield()
end

function Signal:Destroy()
	for i = #self._listeners, 1, -1 do
		self._listeners[i].Connected = false
		self._listeners[i] = nil
	end
end

return Signal

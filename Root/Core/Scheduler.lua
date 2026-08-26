-- ════════════════════════════════════════════════════════════════════════════
-- Core/Scheduler.lua
-- Centralized throttled scheduler for Render, Heartbeat, and Stepped loops
-- ════════════════════════════════════════════════════════════════════════════

local RunService = game:GetService("RunService")

local Scheduler = {}
Scheduler.__index = Scheduler

function Scheduler.new()
	local self = setmetatable({}, Scheduler)
	self._renderTasks = {}
	self._physicsTasks = {}
	self._connections = {}
	return self
end

function Scheduler:Init()
	table.insert(self._connections, RunService.RenderStepped:Connect(function(dt)
		for _, task in ipairs(self._renderTasks) do
			if task.active then
				task.elapsed = task.elapsed + dt
				if task.elapsed >= task.throttle then
					task.elapsed = 0
					pcall(task.callback, dt)
				end
			end
		end
	end))

	table.insert(self._connections, RunService.Heartbeat:Connect(function(dt)
		for _, task in ipairs(self._physicsTasks) do
			if task.active then
				task.elapsed = task.elapsed + dt
				if task.elapsed >= task.throttle then
					task.elapsed = 0
					pcall(task.callback, dt)
				end
			end
		end
	end))
end

-- Registers a task into the frame update loops
function Scheduler:AddTask(loopType, id, callback, fpsLimit)
	local target = loopType == "Render" and self._renderTasks or self._physicsTasks
	local throttle = fpsLimit and (1 / fpsLimit) or 0
	
	-- Uniqueness check
	for i = #target, 1, -1 do
		if target[i].id == id then
			table.remove(target, i)
		end
	end

	table.insert(target, {
		id = id,
		callback = callback,
		throttle = throttle,
		elapsed = 0,
		active = true,
	})
end

-- Toggles execution state of a registered task
function Scheduler:SetTaskActive(loopType, id, active)
	local target = loopType == "Render" and self._renderTasks or self._physicsTasks
	for _, task in ipairs(target) do
		if task.id == id then
			task.active = active
			break
		end
	end
end

-- Clears task connection registries
function Scheduler:Destroy()
	for _, conn in ipairs(self._connections) do
		pcall(conn.Disconnect, conn)
	end
	table.clear(self._renderTasks)
	table.clear(self._physicsTasks)
	table.clear(self._connections)
end

return Scheduler

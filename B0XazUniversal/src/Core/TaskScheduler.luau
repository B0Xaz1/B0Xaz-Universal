--!strict
-- ══════════════════════════════════════════════════════════════════════════════
-- B0XazUniversal - Multi-Phase Lifecycle Task Scheduler
-- ══════════════════════════════════════════════════════════════════════════════

local RunService = game:GetService("RunService")

export type TaskJob = {
	Name: string,
	Priority: number,
	Callback: (dt: number) -> (),
	Enabled: boolean,
}

local TaskScheduler = {}
TaskScheduler.__index = TaskScheduler

function TaskScheduler.new(disposer: any)
	local self = setmetatable({}, TaskScheduler)
	self._disposer = disposer

	self._preSimJobs = {} :: { TaskJob }
	self._heartbeatJobs = {} :: { TaskJob }
	self._renderJobs = {} :: { TaskJob }
	self._cameraJobs = {} :: { TaskJob }

	self:_bindEnginePipelines()
	return self
end

local function sortJobs(a: TaskJob, b: TaskJob): boolean
	return a.Priority < b.Priority
end

function TaskScheduler:_bindEnginePipelines()
	local steppedConn = RunService.Stepped:Connect(function(_, dt: number)
		for _, job in ipairs(self._preSimJobs) do
			if job.Enabled then
				local ok, err = pcall(job.Callback, dt)
				if not ok then job.Enabled = false warn("[Scheduler PreSim Error] " .. job.Name .. ": " .. tostring(err)) end
			end
		end
	end)
	self._disposer:Add(steppedConn)

	local heartbeatConn = RunService.Heartbeat:Connect(function(dt: number)
		for _, job in ipairs(self._heartbeatJobs) do
			if job.Enabled then
				local ok, err = pcall(job.Callback, dt)
				if not ok then job.Enabled = false warn("[Scheduler Heartbeat Error] " .. job.Name .. ": " .. tostring(err)) end
			end
		end
	end)
	self._disposer:Add(heartbeatConn)

	local renderConn = RunService.RenderStepped:Connect(function(dt: number)
		for _, job in ipairs(self._renderJobs) do
			if job.Enabled then
				local ok, err = pcall(job.Callback, dt)
				if not ok then job.Enabled = false warn("[Scheduler Render Error] " .. job.Name .. ": " .. tostring(err)) end
			end
		end
	end)
	self._disposer:Add(renderConn)

	local CAMERA_BIND_KEY = "B0XazCameraOverride"
	pcall(function() RunService:UnbindFromRenderStep(CAMERA_BIND_KEY) end)

	RunService:BindToRenderStep(CAMERA_BIND_KEY, Enum.RenderPriority.Camera.Value + 1, function(dt: number)
		for _, job in ipairs(self._cameraJobs) do
			if job.Enabled then
				local ok, err = pcall(job.Callback, dt)
				if not ok then job.Enabled = false warn("[Scheduler Camera Error] " .. job.Name .. ": " .. tostring(err)) end
			end
		end
	end)

	self._disposer:Add(function()
		pcall(function() RunService:UnbindFromRenderStep(CAMERA_BIND_KEY) end)
	end)
end

function TaskScheduler:RegisterPreSim(name: string, priority: number, callback: (dt: number) -> ()): TaskJob
	local job = { Name = name, Priority = priority, Callback = callback, Enabled = true }
	table.insert(self._preSimJobs, job)
	table.sort(self._preSimJobs, sortJobs)
	return job
end

function TaskScheduler:RegisterHeartbeat(name: string, priority: number, callback: (dt: number) -> ()): TaskJob
	local job = { Name = name, Priority = priority, Callback = callback, Enabled = true }
	table.insert(self._heartbeatJobs, job)
	table.sort(self._heartbeatJobs, sortJobs)
	return job
end

function TaskScheduler:RegisterRender(name: string, priority: number, callback: (dt: number) -> ()): TaskJob
	local job = { Name = name, Priority = priority, Callback = callback, Enabled = true }
	table.insert(self._renderJobs, job)
	table.sort(self._renderJobs, sortJobs)
	return job
end

function TaskScheduler:RegisterCamera(name: string, priority: number, callback: (dt: number) -> ()): TaskJob
	local job = { Name = name, Priority = priority, Callback = callback, Enabled = true }
	table.insert(self._cameraJobs, job)
	table.sort(self._cameraJobs, sortJobs)
	return job
end

-- Factory Wrapper
return function(disposer: any)
	return TaskScheduler.new(disposer)
end

local RunService = game:GetService("RunService")

export type TaskJob = {
	Name: string,
	Priority: number,
	Callback: (dt: number) -> (),
	Enabled: boolean,
	_failures: number?,
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

-- Lower priority value runs first within a pipeline
local function sortJobs(a: TaskJob, b: TaskJob): boolean
	return a.Priority < b.Priority
end

-- Each pipeline wraps every job call in pcall. To protect performance
-- against infinite error loops, a job is disabled only after consecutive
-- failures, while any successful execution resets its failure count.
local function makePipelineRunner(scheduler: any, jobs: { TaskJob }, label: string)
	return function(dt: number)
		for _, job in ipairs(jobs) do
			if job.Enabled then
				local ok, err = pcall(job.Callback, dt)
				if not ok then
					local fails = (job._failures or 0) + 1
					job._failures = fails
					if fails >= 5 then
						job.Enabled = false
						warn(string.format("[Scheduler %s Error] %s permanently disabled after %d consecutive failures: %s", label, job.Name, fails, tostring(err)))
					else
						warn(string.format("[Scheduler %s Error] %s (strike %d/5): %s", label, job.Name, fails, tostring(err)))
					end
				else
					job._failures = 0
				end
			end
		end
	end
end

function TaskScheduler:_bindEnginePipelines()
	-- Stepped fires with (time, step) while every other pipeline signal
	-- passes the frame delta directly, so the PreSim runner is wrapped to
	-- forward only the step argument.
	local preSimRunner = makePipelineRunner(self, self._preSimJobs, "PreSim")
	local steppedConn = RunService.Stepped:Connect(function(_, dt: number)
		preSimRunner(dt)
	end)
	self._disposer:Add(steppedConn)

	local heartbeatConn = RunService.Heartbeat:Connect(makePipelineRunner(self, self._heartbeatJobs, "Heartbeat"))
	self._disposer:Add(heartbeatConn)

	local renderConn = RunService.RenderStepped:Connect(makePipelineRunner(self, self._renderJobs, "Render"))
	self._disposer:Add(renderConn)

	-- Camera jobs run through BindToRenderStep so they fire just after the
	-- camera has been updated for the frame.
	local CAMERA_BIND_KEY = "B0XazCameraOverride"
	pcall(function() RunService:UnbindFromRenderStep(CAMERA_BIND_KEY) end)

	RunService:BindToRenderStep(CAMERA_BIND_KEY, Enum.RenderPriority.Camera.Value + 1, makePipelineRunner(self, self._cameraJobs, "Camera"))

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

return function(disposer: any)
	return TaskScheduler.new(disposer)
end

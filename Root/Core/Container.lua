-- ════════════════════════════════════════════════════════════════════════════
-- Core/Container.lua
-- Service locator, dependency injector, and lifecycle dispatcher
-- ════════════════════════════════════════════════════════════════════════════

local Container = {}
Container.__index = Container

function Container.new()
	local self = setmetatable({}, Container)
	self._services = {}
	self._serviceOrder = {}
	self._isStarted = false
	return self
end

-- Register a service or module
function Container:Register(name, service)
	assert(type(name) == "string", "Service name must be a string")
	assert(service ~= nil, "Service instance cannot be nil")
	
	self._services[name] = service
	table.insert(self._serviceOrder, name)
	return service
end

-- Resolve a registered service
function Container:Get(name)
	local service = self._services[name]
	if not service then
		warn(string.format("[Container] Service '%s' requested but not registered.", tostring(name)))
	end
	return service
end

-- Initialize all services in registration order
function Container:InitAll()
	for _, name in ipairs(self._serviceOrder) do
		local service = self._services[name]
		if type(service) == "table" and type(service.Init) == "function" then
			local ok, err = pcall(service.Init, service, self)
			if not ok then
				warn(string.format("[Container] Error initializing service '%s': %s", name, tostring(err)))
			end
		end
	end
end

-- Start all services once initialization completes
function Container:StartAll()
	if self._isStarted then return end
	self._isStarted = true

	for _, name in ipairs(self._serviceOrder) do
		local service = self._services[name]
		if type(service) == "table" and type(service.Start) == "function" then
			local ok, err = pcall(service.Start, service)
			if not ok then
				warn(string.format("[Container] Error starting service '%s': %s", name, tostring(err)))
			end
		end
	end
end

-- Clean up and destroy all services in reverse registration order
function Container:Destroy()
	for i = #self._serviceOrder, 1, -1 do
		local name = self._serviceOrder[i]
		local service = self._services[name]
		if type(service) == "table" and type(service.Destroy) == "function" then
			pcall(service.Destroy, service)
		end
		self._services[name] = nil
		self._serviceOrder[i] = nil
	end
	self._isStarted = false
end

return Container

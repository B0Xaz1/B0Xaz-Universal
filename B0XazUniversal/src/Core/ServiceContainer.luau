--!strict

export type Service = {
	Initialize: ((self: any) -> ())?,
	Destroy: ((self: any) -> ())?,
	[string]: any,
}

local ServiceContainer = {
	_services = {} :: { [string]: any },
	_loadOrder = {} :: { string },
}

function ServiceContainer:Register<T>(name: string, serviceInstance: T): T
	if self._services[name] ~= nil then
		warn(string.format("[ServiceContainer] Overwriting existing service registration: '%s'", name))
	else
		table.insert(self._loadOrder, name)
	end
	self._services[name] = serviceInstance
	return serviceInstance
end

function ServiceContainer:Get<T>(name: string): T
	local service = self._services[name]
	if service == nil then
		error(string.format("[ServiceContainer] Requested unregistered service: '%s'", name))
	end
	return service :: T
end

function ServiceContainer:Has(name: string): boolean
	return self._services[name] ~= nil
end

-- InitializeAll walks the load order forward; DestroyAll walks it backward so
-- dependents tear down before the services they consume.
function ServiceContainer:InitializeAll()
	for _, name in ipairs(self._loadOrder) do
		local service = self._services[name]
		if typeof(service) == "table" and typeof(service.Initialize) == "function" then
			local ok, err = pcall(service.Initialize, service)
			if not ok then
				warn(string.format("[ServiceContainer] Error initializing '%s': %s", name, tostring(err)))
			end
		end
	end
end

function ServiceContainer:DestroyAll()
	for i = #self._loadOrder, 1, -1 do
		local name = self._loadOrder[i]
		local service = self._services[name]
		if typeof(service) == "table" and typeof(service.Destroy) == "function" then
			pcall(service.Destroy, service)
		end
		self._services[name] = nil
	end
	table.clear(self._loadOrder)
end

return ServiceContainer

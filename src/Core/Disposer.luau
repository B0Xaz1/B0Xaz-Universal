type Destructible =
	RBXScriptConnection
	| thread
	| Instance
	| () -> ()
	| { Dispose: (any) -> () }
	| { Destroy: (any) -> () }
	| { Remove: (any) -> () }
	| { Disconnect: (any) -> () }

export type DisposerInstance = {
	Name: string,
	IsDisposed: boolean,
	Add: <T>(self: DisposerInstance, item: T, customMethod: string?) -> T,
	Spawn: (self: DisposerInstance, callback: () -> ()) -> thread,
	Delay: (self: DisposerInstance, duration: number, callback: () -> ()) -> thread,
	Bind: <T>(self: DisposerInstance, key: string, item: T, customMethod: string?) -> T,
	Unbind: (self: DisposerInstance, key: string) -> (),
	CreateChild: (self: DisposerInstance, childName: string?) -> DisposerInstance,
	Dispose: (self: DisposerInstance) -> (),
}

local Disposer = {}
Disposer.__index = Disposer

function Disposer.new(name: string?): DisposerInstance
	local self = setmetatable({}, Disposer)
	self.Name = name or "Disposer_ " .. tostring(os.clock())
	self.IsDisposed = false
	self._items = {}
	self._keyedItems = {}
	return (self :: any) :: DisposerInstance
end

local function cleanItem(item: any, customMethod: string?)
	if item == nil then return end

	if customMethod and typeof(item) == "table" and typeof(item[customMethod]) == "function" then
		pcall(item[customMethod], item)
		return
	end

	local itemType = typeof(item)
	if itemType == "RBXScriptConnection" then
		pcall(function() item:Disconnect() end)
	elseif itemType == "thread" then
		pcall(function()
			if coroutine.status(item) ~= "dead" then
				task.cancel(item)
			end
		end)
	elseif itemType == "function" then
		pcall(item)
	elseif itemType == "Instance" then
		pcall(function() item:Destroy() end)
	elseif itemType == "table" then
		-- Tables are cleaned through whichever lifecycle method they expose.
		-- Disconnect is included so EventBus connection objects registered
		-- here are actually released, not just dropped.
		if typeof(item.Dispose) == "function" then
			pcall(function() item:Dispose() end)
		elseif typeof(item.Destroy) == "function" then
			pcall(function() item:Destroy() end)
		elseif typeof(item.Disconnect) == "function" then
			pcall(function() item:Disconnect() end)
		elseif typeof(item.Remove) == "function" then
			pcall(function() item:Remove() end)
		elseif item.Visible ~= nil then
			-- Drawing primitives are hidden first so a failed Remove call
			-- cannot leave visible artifacts on screen.
			item.Visible = false
			pcall(function()
				if typeof(item.Remove) == "function" then item:Remove()
				elseif typeof(item.Destroy) == "function" then item:Destroy() end
			end)
		end
	end
end

function Disposer:Add<T>(item: T, customMethod: string?): T
	if self.IsDisposed then
		-- Accepts new items even after disposal so late registrations are
		-- cleaned immediately instead of leaking.
		cleanItem(item, customMethod)
		return item
	end
	if item ~= nil then
		table.insert(self._items, { item = item, method = customMethod })
	end
	return item
end

function Disposer:Spawn(callback: () -> ()): thread
	local thread = task.spawn(callback)
	self:Add(thread)
	return thread
end

function Disposer:Delay(duration: number, callback: () -> ()): thread
	local thread = task.delay(duration, callback)
	self:Add(thread)
	return thread
end

function Disposer:Bind<T>(key: string, item: T, customMethod: string?): T
	if self.IsDisposed then
		cleanItem(item, customMethod)
		return item
	end
	if self._keyedItems[key] then
		-- Rebinding the same key disposes the previous item first, which is
		-- what makes Bind a drop-in replacement for "swap this resource".
		self:Unbind(key)
	end
	if item ~= nil then
		self._keyedItems[key] = { item = item, method = customMethod }
	end
	return item
end

function Disposer:Unbind(key: string)
	local entry = self._keyedItems[key]
	if entry then
		self._keyedItems[key] = nil
		cleanItem(entry.item, entry.method)
	end
end

function Disposer:CreateChild(childName: string?): DisposerInstance
	local child = Disposer.new(childName or (self.Name .. "_Child"))
	self:Add(child)
	return child
end

function Disposer:Dispose()
	if self.IsDisposed then return end
	self.IsDisposed = true

	for _, entry in pairs(self._keyedItems) do
		cleanItem(entry.item, entry.method)
	end
	table.clear(self._keyedItems)

	-- Array items are cleaned in reverse so later registrations tear down
	-- first, mirroring the order they were set up.
	for i = #self._items, 1, -1 do
		local entry = self._items[i]
		cleanItem(entry.item, entry.method)
		self._items[i] = nil
	end
	table.clear(self._items)
end

return Disposer

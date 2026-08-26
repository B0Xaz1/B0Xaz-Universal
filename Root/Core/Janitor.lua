-- ════════════════════════════════════════════════════════════════════════════
-- Core/Janitor.lua
-- Deterministic resource and memory lifecycle manager
-- ════════════════════════════════════════════════════════════════════════════

local Janitor = {}
Janitor.__index = Janitor

function Janitor.new()
	local self = setmetatable({}, Janitor)
	self._objects = {}
	self._isDestroyed = false
	return self
end

-- Adds any resource to be cleaned up upon disposal
function Janitor:Add(object, customMethod)
	if self._isDestroyed then
		self:_cleanupObject(object, customMethod)
		return object
	end
	table.insert(self._objects, { Item = object, Method = customMethod })
	return object
end

-- Internal helper to safely dispose of a specific object
function Janitor:_cleanupObject(object, customMethod)
	if not object then return end

	pcall(function()
		if type(customMethod) == "string" and typeof(object[customMethod]) == "function" then
			object[customMethod](object)
		elseif type(object) == "function" then
			object()
		elseif typeof(object) == "RBXScriptConnection" or (type(object) == "table" and type(object.Disconnect) == "function") then
			object:Disconnect()
		elseif type(object) == "thread" then
			task.cancel(object)
		elseif typeof(object) == "Instance" then
			object:Destroy()
		elseif type(object) == "table" then
			if type(object.Destroy) == "function" then
				object:Destroy()
			elseif type(object.Remove) == "function" then
				object:Remove()
			elseif type(object.Disconnect) == "function" then
				object:Disconnect()
			end
		end
	end)
end

-- Removes a tracked object from the janitor without destroying it immediately
function Janitor:Remove(object)
	for i = #self._objects, 1, -1 do
		if self._objects[i].Item == object then
			table.remove(self._objects, i)
			break
		end
	end
	return object
end

-- Cleans all registered objects without marking the Janitor as destroyed
function Janitor:Cleanup()
	for i = #self._objects, 1, -1 do
		local entry = self._objects[i]
		self._objects[i] = nil
		self:_cleanupObject(entry.Item, entry.Method)
	end
end

-- Destroys all registered objects and renders the Janitor inert
function Janitor:Destroy()
	if self._isDestroyed then return end
	self._isDestroyed = true
	self:Cleanup()
end

return Janitor

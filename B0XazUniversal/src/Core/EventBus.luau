--!strict
-- ══════════════════════════════════════════════════════════════════════════════
-- B0XazUniversal - High-Performance Pub/Sub EventBus
-- ══════════════════════════════════════════════════════════════════════════════

export type Connection = {
	Connected: boolean,
	Disconnect: (self: Connection) -> (),
}

type Node = {
	fn: (...any) -> (),
	next: Node?,
	prev: Node?,
	connected: boolean,
}

local EventBus = {}
EventBus.__index = EventBus

function EventBus.new(disposer: any?)
	local self = setmetatable({}, EventBus)
	self._events = {} :: { [string]: { head: Node?, tail: Node? } }
	self._disposer = disposer

	if disposer and typeof(disposer.Add) == "function" then
		disposer:Add(self)
	end
	return self
end

function EventBus:Subscribe(eventName: string, handler: (...any) -> ()): Connection
	local list = self._events[eventName]
	if not list then
		list = { head = nil, tail = nil }
		self._events[eventName] = list
	end

	local node: Node = {
		fn = handler,
		next = nil,
		prev = list.tail,
		connected = true,
	}

	if list.tail then
		list.tail.next = node
		list.tail = node
	else
		list.head = node
		list.tail = node
	end

	local connection: Connection = {
		Connected = true,
		Disconnect = function(connSelf)
			if not node.connected then return end
			node.connected = false
			connSelf.Connected = false

			if node.prev then
				node.prev.next = node.next
			else
				list.head = node.next
			end

			if node.next then
				node.next.prev = node.prev
			else
				list.tail = node.prev
			end
		end,
	}

	if self._disposer and typeof(self._disposer.Add) == "function" then
		self._disposer:Add(connection)
	end

	return connection
end

function EventBus:Publish(eventName: string, ...: any)
	local list = self._events[eventName]
	if not list or not list.head then return end

	local current = list.head
	while current do
		local nextNode = current.next
		if current.connected then
			task.spawn(current.fn, ...)
		end
		current = nextNode
	end
end

function EventBus:Dispose()
	for _, list in pairs(self._events) do
		local current = list.head
		while current do
			current.connected = false
			current = current.next
		end
	end
	table.clear(self._events)
end

-- Factory Wrapper
return function(disposer: any?)
	return EventBus.new(disposer)
end

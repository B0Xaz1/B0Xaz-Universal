--!strict

export type PoolableDrawing = any

return function(services: any)
	local Disposer = services:Get("Disposer")
	local DrawingPool = {
		Available = false,
		_pools = {
			Line = {} :: { PoolableDrawing },
			Text = {} :: { PoolableDrawing },
			Square = {} :: { PoolableDrawing },
			Circle = {} :: { PoolableDrawing },
		},
		_activeObjects = {} :: { [PoolableDrawing]: string },
	}

	-- Probe the executor's Drawing API once; on executors without it the pool
	-- stays empty and consumers fall back to no drawing.
	pcall(function()
		if Drawing and typeof(Drawing.new) == "function" then
			local testLine = Drawing.new("Line")
			if testLine then
				DrawingPool.Available = true
				testLine.Visible = false
				if typeof(testLine.Remove) == "function" then testLine:Remove()
				elseif typeof(testLine.Destroy) == "function" then testLine:Destroy() end
			end
		end
	end)

	local function createPrimitive(primitiveType: string): PoolableDrawing?
		if not DrawingPool.Available then return nil end
		local ok, primitive = pcall(Drawing.new, primitiveType)
		if ok and primitive then
			primitive.Visible = false
			return primitive
		end
		return nil
	end

	function DrawingPool:Acquire(primitiveType: "Line" | "Text" | "Square" | "Circle"): PoolableDrawing?
		if not self.Available then return nil end

		local pool = self._pools[primitiveType]
		local instance: PoolableDrawing? = nil

		if pool and #pool > 0 then
			-- Recycling a hidden primitive avoids a native allocation
			instance = table.remove(pool)
		else
			instance = createPrimitive(primitiveType)
		end

		if instance then
			self._activeObjects[instance] = primitiveType
		end
		return instance
	end

	function DrawingPool:Release(instance: PoolableDrawing?)
		if not instance or not self.Available then return end
		local primitiveType = self._activeObjects[instance]
		if not primitiveType then return end

		instance.Visible = false
		self._activeObjects[instance] = nil

		local pool = self._pools[primitiveType]
		if pool then
			table.insert(pool, instance)
		end
	end

	function DrawingPool:DestroyAll()
		for instance in pairs(self._activeObjects) do
			instance.Visible = false
			pcall(function()
				if typeof(instance.Remove) == "function" then instance:Remove()
				elseif typeof(instance.Destroy) == "function" then instance:Destroy() end
			end)
		end
		table.clear(self._activeObjects)

		for _, pool in pairs(self._pools) do
			for _, instance in ipairs(pool) do
				pcall(function()
					if typeof(instance.Remove) == "function" then instance:Remove()
					elseif typeof(instance.Destroy) == "function" then instance:Destroy() end
				end)
			end
			table.clear(pool)
		end
	end

	Disposer:Add(function()
		DrawingPool:DestroyAll()
	end)

	return DrawingPool
end

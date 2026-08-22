-- // src/Visuals/DrawingManager.lua
return function()
	local env = (getgenv and getgenv()) or _G
	env.B0XazAllDrawings = env.B0XazAllDrawings or {}

	local drawingAvailable = false
	pcall(function()
		if Drawing and type(Drawing.new) == "function" then
			local test = Drawing.new("Line")
			if test then
				drawingAvailable = true
				test.Visible = false
				if test.Remove then test:Remove()
				elseif test.Destroy then test:Destroy() end
			end
		end
	end)

	local allDrawings = env.B0XazAllDrawings

	local function track(obj)
		if obj then table.insert(allDrawings, obj) end
		return obj
	end

	local DrawingManager = { Available = drawingAvailable }

	local function create(className, defaults, props)
		if not drawingAvailable then return nil end
		local ok, inst = pcall(Drawing.new, className)
		if not ok or not inst then return nil end

		pcall(function()
			inst.Visible = false
			inst.Color = (props and props.Color) or Color3.new(1, 1, 1)
			inst.Transparency = (props and props.Transparency) or 1
			for key, def in pairs(defaults) do
				if key ~= "Color" and key ~= "Transparency" then
					inst[key] = (props and props[key] ~= nil) and props[key] or def
				end
			end
		end)

		return track(inst)
	end

	function DrawingManager.NewLine(props)
		return create("Line", { Thickness = 1 }, props)
	end

	function DrawingManager.NewCircle(props)
		return create("Circle", {
			Radius = 10, Thickness = 1, Filled = false, NumSides = 64,
		}, props)
	end

	function DrawingManager.NewSquare(props)
		return create("Square", { Thickness = 2, Filled = false }, props)
	end

	function DrawingManager.NewText(props)
		-- Font left unset intentionally — numeric fonts crash some executors
		return create("Text", {
			Size = 14, Center = true, Outline = true, Text = "",
		}, props)
	end

	function DrawingManager.SafeRemove(drawing)
		if not drawing then return end
		pcall(function()
			if drawing.Visible ~= nil then drawing.Visible = false end
		end)
		pcall(function()
			if drawing.Remove then drawing:Remove()
			elseif drawing.Destroy then drawing:Destroy() end
		end)
	end

	function DrawingManager.RemoveAll()
		for i = #allDrawings, 1, -1 do
			DrawingManager.SafeRemove(allDrawings[i])
			allDrawings[i] = nil
		end
	end

	return DrawingManager
end

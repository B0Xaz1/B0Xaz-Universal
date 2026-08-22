-- // src/Visuals/DrawingManager.lua
local SETTINGS = {
	DEFAULTS = {
		COLOR = Color3.new(1, 1, 1),
		TRANSPARENCY = 1,
		LINE = {
			Thickness = 1,
		},
		CIRCLE = {
			Radius = 10,
			Thickness = 1,
			Filled = false,
			NumSides = 64,
		},
		SQUARE = {
			Thickness = 2,
			Filled = false,
		},
		TEXT = {
			Size = 14,
			Center = true,
			Outline = true,
			Font = 2,
			Text = "",
		},
	},
	GLOBAL_DRAWINGS_KEY = "B0XazAllDrawings",
}

return function()
	local globalEnv = getgenv and getgenv() or _G
	globalEnv[SETTINGS.GLOBAL_DRAWINGS_KEY] = globalEnv[SETTINGS.GLOBAL_DRAWINGS_KEY] or {}

	local drawingAvailable = false
	pcall(function()
		if Drawing and type(Drawing.new) == "function" then
			local testObject = Drawing.new("Line")
			if testObject then
				drawingAvailable = true
				testObject.Visible = false
				if testObject.Remove then
					testObject:Remove()
				elseif testObject.Destroy then
					testObject:Destroy()
				end
			end
		end
	end)

	local allDrawings = globalEnv[SETTINGS.GLOBAL_DRAWINGS_KEY]

	local function track(obj)
		if obj then
			table.insert(allDrawings, obj)
		end
		return obj
	end

	local DrawingManager = {
		Available = drawingAvailable,
	}

	local function createDrawing(drawingType, defaultProperties, customProperties)
		if not drawingAvailable then return nil end

		local success, instance = pcall(Drawing.new, drawingType)
		if not success or not instance then return nil end

		instance.Visible = false
		instance.Color = (customProperties and customProperties.Color) or SETTINGS.DEFAULTS.COLOR
		instance.Transparency = (customProperties and customProperties.Transparency) or SETTINGS.DEFAULTS.TRANSPARENCY

		for property, defaultValue in pairs(defaultProperties) do
			if property ~= "Color" and property ~= "Transparency" then
				if customProperties and customProperties[property] ~= nil then
					instance[property] = customProperties[property]
				else
					instance[property] = defaultValue
				end
			end
		end

		return track(instance)
	end

	function DrawingManager.NewLine(props)
		return createDrawing("Line", SETTINGS.DEFAULTS.LINE, props)
	end

	function DrawingManager.NewCircle(props)
		return createDrawing("Circle", SETTINGS.DEFAULTS.CIRCLE, props)
	end

	function DrawingManager.NewSquare(props)
		return createDrawing("Square", SETTINGS.DEFAULTS.SQUARE, props)
	end

	function DrawingManager.NewText(props)
		return createDrawing("Text", SETTINGS.DEFAULTS.TEXT, props)
	end

	function DrawingManager.SafeRemove(drawing)
		if not drawing then return end
		pcall(function()
			if drawing.Visible ~= nil then
				drawing.Visible = false
			end
		end)
		pcall(function()
			if drawing.Remove then
				drawing:Remove()
			elseif drawing.Destroy then
				drawing:Destroy()
			end
		end)
	end

	function DrawingManager.RemoveAll()
		for index = #allDrawings, 1, -1 do
			DrawingManager.SafeRemove(allDrawings[index])
			allDrawings[index] = nil
		end
	end

	return DrawingManager
end

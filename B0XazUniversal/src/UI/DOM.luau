--!strict
-- ══════════════════════════════════════════════════════════════════════════════
-- B0XazUniversal - DOM & Fast Instance Factory
-- Eliminates dynamic closure allocations and pcall overhead during UI mounting,
-- providing fast ASCII string generators, UIStrokes, and layout helpers.
-- ══════════════════════════════════════════════════════════════════════════════

export type InstanceProperties = { [string]: any }

local DOM = {}

-- Fast Pseudo-Random String Generator (Zero allocation byte buffering)
function DOM.GenerateGUID(): string
	local bytes = table.create(16)
	for i = 1, 16 do
		bytes[i] = math.random(65, 90) -- Uppercase ASCII (A-Z)
	end
	return string.char(table.unpack(bytes))
end

-- Fast Property Applier
function DOM.Create(className: string, properties: InstanceProperties?, children: { Instance }?): Instance
	local instance = Instance.new(className)
	local targetParent: Instance? = nil

	if properties then
		for prop, value in pairs(properties) do
			if prop == "Parent" then
				targetParent = value
			else
				local target = instance :: any
				target[prop] = value
			end
		end
	end

	if children then
		for i = 1, #children do
			children[i].Parent = instance
		end
	end

	if targetParent then
		instance.Parent = targetParent
	end

	return instance
end

function DOM.CreateStroke(color: Color3, thickness: number?): UIStroke
	return DOM.Create("UIStroke", {
		Color = color,
		Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}) :: UIStroke
end

function DOM.CreatePadding(top: number, bottom: number?, left: number?, right: number?): UIPadding
	if bottom == nil then
		return DOM.Create("UIPadding", {
			PaddingTop = UDim.new(0, top),
			PaddingBottom = UDim.new(0, top),
			PaddingLeft = UDim.new(0, top),
			PaddingRight = UDim.new(0, top),
		}) :: UIPadding
	end
	return DOM.Create("UIPadding", {
		PaddingTop = UDim.new(0, top),
		PaddingBottom = UDim.new(0, bottom or 0),
		PaddingLeft = UDim.new(0, left or 0),
		PaddingRight = UDim.new(0, right or 0),
	}) :: UIPadding
end

return DOM

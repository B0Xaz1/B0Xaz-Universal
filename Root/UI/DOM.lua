-- ════════════════════════════════════════════════════════════════════════════
-- UI/DOM.lua
-- Declarative instance factory and safe viewport container resolver
-- ════════════════════════════════════════════════════════════════════════════

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

local DOM = {}

-- Resolves the safest parent container available in the executor environment
function DOM.GetSafeParent()
	if type(gethui) == "function" then
		local ok, hui = pcall(gethui)
		if ok and hui then return hui end
	end

	local testOk = pcall(function()
		local f = Instance.new("Folder")
		f.Name = "B0XazProbe"
		f.Parent = CoreGui
		f:Destroy()
	end)
	if testOk then return CoreGui end

	local lp = Players.LocalPlayer
	local pGui = lp and (lp:FindFirstChildOfClass("PlayerGui") or lp:WaitForChild("PlayerGui", 3))
	return pGui or CoreGui
end

-- Generates randomized obfuscated instance names
function DOM.RandomName()
	local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
	local out = {}
	for _ = 1, math.random(12, 18) do
		local idx = math.random(1, #chars)
		table.insert(out, chars:sub(idx, idx))
	end
	return table.concat(out)
end

-- Declarative Instance builder: applies properties & children BEFORE parenting
function DOM.Create(className, properties, children)
	local inst = Instance.new(className)
	local targetParent = nil

	if properties then
		for k, v in pairs(properties) do
			if k == "Parent" then
				targetParent = v
			else
				pcall(function() inst[k] = v end)
			end
		end
	end

	if children then
		for _, child in ipairs(children) do
			if child then child.Parent = inst end
		end
	end

	if targetParent then
		pcall(function() inst.Parent = targetParent end)
	end

	return inst
end

-- Pre-styled UIStroke factory
function DOM.CreateStroke(color, thickness)
	return DOM.Create("UIStroke", {
		Color = color or Color3.fromRGB(55, 55, 65),
		Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

-- Pre-styled UIPadding factory
function DOM.CreatePadding(top, bottom, left, right)
	if bottom == nil then
		return DOM.Create("UIPadding", {
			PaddingTop = UDim.new(0, top), PaddingBottom = UDim.new(0, top),
			PaddingLeft = UDim.new(0, top), PaddingRight = UDim.new(0, top),
		})
	end
	return DOM.Create("UIPadding", {
		PaddingTop = UDim.new(0, top or 0), PaddingBottom = UDim.new(0, bottom or 0),
		PaddingLeft = UDim.new(0, left or 0), PaddingRight = UDim.new(0, right or 0),
	})
end

return DOM

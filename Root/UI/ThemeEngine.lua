-- ════════════════════════════════════════════════════════════════════════════
-- UI/ThemeEngine.lua
-- Design tokens, preset palettes, and reactive UI theme bindings
-- ════════════════════════════════════════════════════════════════════════════

local ThemeEngine = {}
ThemeEngine.__index = ThemeEngine

local PRESETS = {
	["Default Cyan"] = {
		Bg = Color3.fromRGB(18, 18, 20),
		Panel = Color3.fromRGB(26, 26, 30),
		Elem = Color3.fromRGB(32, 32, 38),
		ElemHover = Color3.fromRGB(42, 42, 50),
		Side = Color3.fromRGB(22, 22, 26),
		Accent = Color3.fromRGB(0, 200, 220),
		Text = Color3.fromRGB(225, 225, 230),
		TextDim = Color3.fromRGB(145, 145, 155),
		TextMuted = Color3.fromRGB(95, 95, 105),
		Border = Color3.fromRGB(55, 55, 65),
		BorderDim = Color3.fromRGB(40, 40, 48),
		ToggleOff = Color3.fromRGB(40, 40, 48),
		ToggleOn = Color3.fromRGB(0, 200, 220),
		Success = Color3.fromRGB(90, 200, 120),
		Danger = Color3.fromRGB(220, 80, 80),
		Warning = Color3.fromRGB(230, 175, 70),
	},
	["Midnight Purple"] = {
		Bg = Color3.fromRGB(14, 12, 20),
		Panel = Color3.fromRGB(22, 18, 30),
		Elem = Color3.fromRGB(28, 24, 38),
		ElemHover = Color3.fromRGB(38, 32, 52),
		Side = Color3.fromRGB(18, 14, 25),
		Accent = Color3.fromRGB(170, 70, 250),
		Text = Color3.fromRGB(235, 230, 245),
		TextDim = Color3.fromRGB(160, 150, 175),
		TextMuted = Color3.fromRGB(105, 95, 120),
		Border = Color3.fromRGB(65, 50, 80),
		BorderDim = Color3.fromRGB(45, 35, 60),
		ToggleOff = Color3.fromRGB(45, 35, 60),
		ToggleOn = Color3.fromRGB(170, 70, 250),
		Success = Color3.fromRGB(90, 200, 120),
		Danger = Color3.fromRGB(220, 80, 80),
		Warning = Color3.fromRGB(230, 175, 70),
	},
	["Blood Crimson"] = {
		Bg = Color3.fromRGB(18, 12, 12),
		Panel = Color3.fromRGB(28, 18, 18),
		Elem = Color3.fromRGB(38, 24, 24),
		ElemHover = Color3.fromRGB(50, 30, 30),
		Side = Color3.fromRGB(22, 14, 14),
		Accent = Color3.fromRGB(235, 50, 65),
		Text = Color3.fromRGB(240, 225, 225),
		TextDim = Color3.fromRGB(170, 145, 145),
		TextMuted = Color3.fromRGB(115, 95, 95),
		Border = Color3.fromRGB(75, 45, 45),
		BorderDim = Color3.fromRGB(50, 35, 35),
		ToggleOff = Color3.fromRGB(50, 35, 35),
		ToggleOn = Color3.fromRGB(235, 50, 65),
		Success = Color3.fromRGB(90, 200, 120),
		Danger = Color3.fromRGB(220, 80, 80),
		Warning = Color3.fromRGB(230, 175, 70),
	},
	["Emerald Neon"] = {
		Bg = Color3.fromRGB(12, 18, 14),
		Panel = Color3.fromRGB(18, 28, 22),
		Elem = Color3.fromRGB(24, 38, 28),
		ElemHover = Color3.fromRGB(32, 50, 38),
		Side = Color3.fromRGB(15, 22, 18),
		Accent = Color3.fromRGB(0, 225, 120),
		Text = Color3.fromRGB(225, 240, 230),
		TextDim = Color3.fromRGB(145, 170, 155),
		TextMuted = Color3.fromRGB(95, 115, 100),
		Border = Color3.fromRGB(45, 75, 55),
		BorderDim = Color3.fromRGB(35, 50, 40),
		ToggleOff = Color3.fromRGB(35, 50, 40),
		ToggleOn = Color3.fromRGB(0, 225, 120),
		Success = Color3.fromRGB(90, 200, 120),
		Danger = Color3.fromRGB(220, 80, 80),
		Warning = Color3.fromRGB(230, 175, 70),
	},
	["Abyss Dark"] = {
		Bg = Color3.fromRGB(10, 10, 10),
		Panel = Color3.fromRGB(16, 16, 16),
		Elem = Color3.fromRGB(22, 22, 22),
		ElemHover = Color3.fromRGB(30, 30, 30),
		Side = Color3.fromRGB(13, 13, 13),
		Accent = Color3.fromRGB(200, 200, 200),
		Text = Color3.fromRGB(240, 240, 240),
		TextDim = Color3.fromRGB(150, 150, 150),
		TextMuted = Color3.fromRGB(90, 90, 90),
		Border = Color3.fromRGB(45, 45, 45),
		BorderDim = Color3.fromRGB(30, 30, 30),
		ToggleOff = Color3.fromRGB(30, 30, 30),
		ToggleOn = Color3.fromRGB(200, 200, 200),
		Success = Color3.fromRGB(90, 200, 120),
		Danger = Color3.fromRGB(220, 80, 80),
		Warning = Color3.fromRGB(230, 175, 70),
	},
}

function ThemeEngine.new()
	local self = setmetatable({}, ThemeEngine)
	self.Presets = PRESETS
	self.ActivePreset = "Default Cyan"
	self.Current = {}
	self._bindings = {}

	for k, v in pairs(PRESETS["Default Cyan"]) do
		self.Current[k] = v
	end
	return self
end

function ThemeEngine:Init(container)
	self._signalClass = container:Get("Signal")
	self.OnThemeUpdated = self._signalClass.new()
end

-- Binds a property of an instance to a dynamic theme token
function ThemeEngine:Bind(instance, property, tokenKey)
	table.insert(self._bindings, { Instance = instance, Property = property, Key = tokenKey })
	if self.Current[tokenKey] then
		pcall(function() instance[property] = self.Current[tokenKey] end)
	end
end

-- Switches the active theme preset
function ThemeEngine:SetPreset(presetName)
	local target = self.Presets[presetName]
	if not target then return end

	self.ActivePreset = presetName
	for k, v in pairs(target) do
		self.Current[k] = v
	end
	self:Refresh()
end

-- Updates a single color token manually
function ThemeEngine:SetToken(key, color)
	self.Current[key] = color
	self:Refresh()
end

-- Repaints all bound UI instances
function ThemeEngine:Refresh()
	for i = #self._bindings, 1, -1 do
		local b = self._bindings[i]
		if b.Instance and b.Instance.Parent then
			local val = self.Current[b.Key]
			if val then
				pcall(function() b.Instance[b.Property] = val end)
			end
		else
			table.remove(self._bindings, i)
		end
	end
	self.OnThemeUpdated:Fire(self.Current)
end

function ThemeEngine:Destroy()
	table.clear(self._bindings)
	self.OnThemeUpdated:Destroy()
end

return ThemeEngine

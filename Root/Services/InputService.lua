-- ════════════════════════════════════════════════════════════════════════════
-- Services/InputService.lua
-- Unified multi-platform input detector and keybind manager
-- ════════════════════════════════════════════════════════════════════════════

local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Workspace = game:GetService("Workspace")

local InputService = {}
InputService.__index = InputService

local KEY_ALIASES = {
	MB1 = Enum.UserInputType.MouseButton1,
	MB2 = Enum.UserInputType.MouseButton2,
	MB3 = Enum.UserInputType.MouseButton3,
}

function InputService.new()
	local self = setmetatable({}, InputService)
	self.IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	return self
end

function InputService:Init(container)
	self._signalClass = container:Get("Signal")
	self._janitor = container:Get("Janitor")
	
	self.OnInputBegan = self._signalClass.new()
	self.OnInputEnded = self._signalClass.new()

	local conn1 = UserInputService.InputBegan:Connect(function(input, gp)
		self.OnInputBegan:Fire(input, gp)
	end)
	local conn2 = UserInputService.InputEnded:Connect(function(input, gp)
		self.OnInputEnded:Fire(input, gp)
	end)

	if self._janitor then
		self._janitor:Add(conn1)
		self._janitor:Add(conn2)
	end
end

-- Get viewport-relative mouse or touch position
function InputService:GetMouseViewportPosition()
	local camera = Workspace.CurrentCamera
	if self.IsMobile and camera then
		return Vector2.new(camera.ViewportSize.X * 0.5, camera.ViewportSize.Y * 0.5)
	end
	
	local mouse = UserInputService:GetMouseLocation()
	local inset = Vector2.zero
	pcall(function() inset = GuiService:GetGuiInset() end)
	return Vector2.new(mouse.X - inset.X, mouse.Y - inset.Y)
end

-- Evaluates if an input matches a given bind
function InputService:MatchesBind(input, bind)
	if not input or bind == nil then return false end
	
	local t = typeof(bind)
	if t == "string" then
		local alias = KEY_ALIASES[bind:upper()]
		if alias then return input.UserInputType == alias end
		local ok, code = pcall(function() return Enum.KeyCode[bind:upper()] end)
		return ok and input.KeyCode == code
	elseif t == "EnumItem" then
		if bind.EnumType == Enum.KeyCode then
			return input.KeyCode == bind
		elseif bind.EnumType == Enum.UserInputType then
			return input.UserInputType == bind
		end
	end
	return false
end

function InputService:IsKeyDown(keyCode)
	return UserInputService:IsKeyDown(keyCode)
end

function InputService:IsMouseButtonPressed(buttonType)
	return UserInputService:IsMouseButtonPressed(buttonType)
end

function InputService:Destroy()
	self.OnInputBegan:Destroy()
	self.OnInputEnded:Destroy()
end

return InputService

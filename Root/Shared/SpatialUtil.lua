-- ════════════════════════════════════════════════════════════════════════════
-- Shared/SpatialUtil.lua
-- Spatial culling, coordinates mapping, and line-of-sight verification
-- ════════════════════════════════════════════════════════════════════════════

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local SpatialUtil = {}

local visParams = RaycastParams.new()
visParams.FilterType = Enum.RaycastFilterType.Exclude
visParams.IgnoreWater = true

local filterInstances = { nil, nil }
local lastCamera, lastCharacter = nil, nil

-- Returns viewport-relative position and visibility
function SpatialUtil.WorldToViewport(position)
	local camera = Workspace.CurrentCamera
	if not camera then return Vector2.zero, false, 0 end
	
	local screenPos, onScreen = camera:WorldToViewportPoint(position)
	return Vector2.new(screenPos.X, screenPos.Y), onScreen, screenPos.Z
end

-- Performs screen-bottom bounding tracers coordinate resolution
function SpatialUtil.GetScreenBottomCenter()
	local camera = Workspace.CurrentCamera
	if not camera then return Vector2.zero end
	
	local size = camera.ViewportSize
	return Vector2.new(size.X * 0.5, size.Y)
end

-- Throttled Raycast Line-of-Sight check excluding local client components
function SpatialUtil.IsVisible(targetPart)
	if not (targetPart and targetPart.Parent and targetPart:IsDescendantOf(Workspace)) then 
		return false 
	end

	local camera = Workspace.CurrentCamera
	if not camera then return false end

	local origin = camera.CFrame.Position
	local direction = targetPart.Position - origin
	if direction:Dot(direction) < 0.01 then return true end

	local localChar = Players.LocalPlayer and Players.LocalPlayer.Character
	if lastCamera ~= camera or lastCharacter ~= localChar then
		lastCamera = camera
		lastCharacter = localChar
		filterInstances[1] = camera
		filterInstances[2] = localChar
		visParams.FilterDescendantsInstances = filterInstances
	end

	local result = Workspace:Raycast(origin, direction, visParams)
	if not result then return true end

	local model = result.Instance:FindFirstAncestorOfClass("Model")
	return model ~= nil and (model == targetPart.Parent or model:IsDescendantOf(targetPart.Parent))
end

return SpatialUtil

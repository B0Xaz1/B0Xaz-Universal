-- ════════════════════════════════════════════════════════════════════════════
-- Shared/MathUtil.lua
-- Kinematic math formulas, smoothing algorithms, and predictive calculations
-- ════════════════════════════════════════════════════════════════════════════

local MathUtil = {}

-- Frame-rate independent exponential interpolation (exponential decay)
function MathUtil.ExponentialDecay(current, target, smooth, dt)
	local alpha = 1 - math.exp(-dt * (60 / math.max(smooth, 1)))
	return typeof(current) == "Vector2" and current:Lerp(target, alpha) 
		or current + (target - current) * alpha
end

-- Simulates human mouse movement via the WindMouse model
function MathUtil.CalculateWindMouseStep(delta, alpha, dt, windStrength, windDamping, windVelocity)
	local distance = delta.Magnitude
	if distance < 0.1 then return Vector2.zero, windVelocity end

	local direction = delta.Unit
	local scale = math.clamp(distance / 150, 0.2, 1.2) * windStrength
	local randomWind = Vector2.new(math.random() * 2 - 1, math.random() * 2 - 1) * scale
	
	local damping = math.clamp(windDamping + dt * 1.5, 0.1, 0.96)
	local newWindVelocity = windVelocity * damping + randomWind * (1 - damping)

	local step = delta * alpha + newWindVelocity * 0.5
	local maxStep = math.max(0.5, math.min(distance, distance * alpha * 1.8 + 0.5))
	
	if step.Magnitude > maxStep then 
		step = step.Unit * maxStep 
	end
	if step:Dot(direction) < 0 then
		step = direction * math.min(maxStep, distance * alpha)
	end

	return step, newWindVelocity
end

-- Calculates target trajectory lead using linear velocity
function MathUtil.PredictPosition(position, velocity, horizontalPrediction, verticalPrediction)
	local h = tonumber(horizontalPrediction) or 0
	local v = tonumber(verticalPrediction) or 0
	return position + Vector3.new(velocity.X * h, velocity.Y * v, velocity.Z * h)
end

return MathUtil

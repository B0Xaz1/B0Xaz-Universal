-- ════════════════════════════════════════════════════════════════════════════
-- tools/boot_test.lua
-- Headless boot + interaction test for the B0Xaz Universal hub.
--
-- Stubs the Roblox API (game, Instance, task, datatypes, services), loads
-- Init.lua which then pulls every module from the LOCAL file tree (game:HttpGet
-- is mapped onto disk), boots the full service container, and simulates UI
-- interaction (clicking every button, toggles, keybinds, hotkey).
--
-- Usage:
--   lua51 tools/boot_test.lua [repoRoot] [placeId] [authMode]
--     repoRoot   default: parent of tools/  (the repo root)
--     placeId    default: 155615604 (Prison Life -> exercises the adapter)
--     authMode   default: none   (none | valid | invalid)
--
-- Exit code 0 = all checks passed.
-- ════════════════════════════════════════════════════════════════════════════

local repoRoot = (arg and arg[1]) or (function()
	local s = arg and arg[0] or "tools/boot_test.lua"
	return (s:match("^(.*)/tools/")) or "."
end)()
local PLACE_ID = tonumber(arg and arg[2]) or 155615604
local AUTH_MODE = (arg and arg[3]) or "none"

-- ── Harness state ───────────────────────────────────────────────────────────
local H = {
	errors = {},        -- fatal task/listener/boot errors
	pcallErrors = {},   -- errors swallowed by pcall inside hub code
	prints = {},
	clipboard = {},
	fpsCaps = {},
	mouseClicks = 0,
	clicks = 0,
}
local function fail(msg) H.errors[#H.errors + 1] = tostring(msg) end

local rawPrint = print
local function vprint(...)
	local parts = {}
	for i = 1, select("#", ...) do parts[i] = tostring(select(i, ...)) end
	local line = table.concat(parts, "\t")
	H.prints[#H.prints + 1] = line
	rawPrint(line)
end
print = vprint

warn = function(...)
	local parts = {}
	for i = 1, select("#", ...) do parts[i] = tostring(select(i, ...)) end
	local line = "[warn] " .. table.concat(parts, "\t")
	H.prints[#H.prints + 1] = line
	rawPrint(line)
end

local rawPcall = pcall
pcall = function(fn, ...)
	local ok, err = rawPcall(fn, ...)
	if not ok then H.pcallErrors[#H.pcallErrors + 1] = tostring(err) end
	return ok, err
end

-- ── Luau stdlib shims (present in Roblox, absent in plain Lua 5.1) ─────────
if not table.clear then
	table.clear = function(t) for k in pairs(t) do t[k] = nil end return t end
end
if not table.find then
	table.find = function(list, value, start)
		for i = start or 1, #list do if list[i] == value then return i end end
		return nil
	end
end
if not math.clamp then
	math.clamp = function(v, lo, hi) return math.min(math.max(v, lo), hi) end
end

-- some trimmed Lua 5.1 builds lack coroutine.main
if not coroutine.main then
	local mainThread = coroutine.running()
	coroutine.main = function() return mainThread end
end

getgenv = function() return _G end
setclipboard = function(t) H.clipboard[#H.clipboard + 1] = t end
setfpscap = function(f) H.fpsCaps[#H.fpsCaps + 1] = f end
mouse1click = function() H.mouseClicks = H.mouseClicks + 1 end

-- ── Datatypes ───────────────────────────────────────────────────────────────
local Vector2 = {}
local V2_METHODS = {}
function V2_METHODS.Dot(self, o) return self.X * o.X + self.Y * o.Y end
function V2_METHODS.Lerp(self, o, a) return Vector2.new(self.X + (o.X - self.X) * a, self.Y + (o.Y - self.Y) * a) end
Vector2.__index = function(t, k)
	local m = V2_METHODS[k]
	if m then return m end
	if k == "Magnitude" then return math.sqrt(t.X * t.X + t.Y * t.Y) end
	if k == "Unit" then
		local m = math.sqrt(t.X * t.X + t.Y * t.Y)
		if m < 1e-9 then return Vector2.new(0, 0) end
		return Vector2.new(t.X / m, t.Y / m)
	end
	return nil
end
function Vector2.new(x, y) return setmetatable({ X = x or 0, Y = y or 0, __roType = "Vector2" }, Vector2) end
Vector2.zero, Vector2.xAxis, Vector2.yAxis = Vector2.new(), Vector2.new(1, 0), Vector2.new(0, 1)
Vector2.__add = function(a, b) return Vector2.new(a.X + b.X, a.Y + b.Y) end
Vector2.__sub = function(a, b) return Vector2.new(a.X - b.X, a.Y - b.Y) end
Vector2.__mul = function(a, b)
	if type(a) == "number" then return Vector2.new(a * b.X, a * b.Y) end
	if type(b) == "number" then return Vector2.new(a.X * b, a.Y * b) end
	return Vector2.new(a.X * b.X, a.Y * b.Y)
end
Vector2.__unm = function(a) return Vector2.new(-a.X, -a.Y) end

local Vector3 = {}
local V3_METHODS = {}
function V3_METHODS.Dot(self, o) return self.X * o.X + self.Y * o.Y + self.Z * o.Z end
function V3_METHODS.Cross(self, o)
	return Vector3.new(self.Y * o.Z - self.Z * o.Y, self.Z * o.X - self.X * o.Z, self.X * o.Y - self.Y * o.X)
end
function V3_METHODS.Lerp(self, o, a)
	return Vector3.new(self.X + (o.X - self.X) * a, self.Y + (o.Y - self.Y) * a, self.Z + (o.Z - self.Z) * a)
end
Vector3.__index = function(t, k)
	local m = V3_METHODS[k]
	if m then return m end
	if k == "Magnitude" then return math.sqrt(t.X * t.X + t.Y * t.Y + t.Z * t.Z) end
	if k == "Unit" then
		local m = math.sqrt(t.X * t.X + t.Y * t.Y + t.Z * t.Z)
		if m < 1e-9 then return Vector3.new(0, 0, 0) end
		return Vector3.new(t.X / m, t.Y / m, t.Z / m)
	end
	return nil
end
function Vector3.new(x, y, z) return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0, __roType = "Vector3" }, Vector3) end
Vector3.zero = Vector3.new()
Vector3.xAxis, Vector3.yAxis, Vector3.zAxis = Vector3.new(1, 0, 0), Vector3.new(0, 1, 0), Vector3.new(0, 0, 1)
Vector3.__add = function(a, b) return Vector3.new(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
Vector3.__sub = function(a, b) return Vector3.new(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
Vector3.__mul = function(a, b)
	if type(a) == "number" then return Vector3.new(a * b.X, a * b.Y, a * b.Z) end
	if type(b) == "number" then return Vector3.new(a.X * b, a.Y * b, a.Z * b) end
	return a:Dot(b)
end
Vector3.__unm = function(a) return Vector3.new(-a.X, -a.Y, -a.Z) end

local Color3 = {}
Color3.__index = Color3
function Color3.new(r, g, b) return setmetatable({ R = r or 0, G = g or 0, B = b or 0, __roType = "Color3" }, Color3) end
function Color3.fromRGB(r, g, b)
	return setmetatable({
		R = math.clamp(r, 0, 255) / 255,
		G = math.clamp(g, 0, 255) / 255,
		B = math.clamp(b, 0, 255) / 255,
		__roType = "Color3",
	}, Color3)
end
function Color3.fromHSV(h, s, v)
	local r, g, b
	local i = math.floor(h * 6) % 6
	local f = h * 6 - math.floor(h * 6)
	local p, q, t = v * (1 - s), v * (1 - f * s), v * (1 - (1 - f) * s)
	if i == 0 then r, g, b = v, t, p elseif i == 1 then r, g, b = q, v, p
	elseif i == 2 then r, g, b = p, v, t elseif i == 3 then r, g, b = p, q, v
	elseif i == 4 then r, g, b = t, p, v else r, g, b = v, p, q end
	return Color3.new(r, g, b)
end

local UDim = {}
UDim.__index = UDim
function UDim.new(scale, offset) return setmetatable({ Scale = scale or 0, Offset = offset or 0, __roType = "UDim" }, UDim) end

local UDim2 = {}
UDim2.__index = UDim2
function UDim2.new(xs, xo, ys, yo)
	return setmetatable({ X = UDim.new(xs, xo), Y = UDim.new(ys, yo), __roType = "UDim2" }, UDim2)
end
function UDim2.fromOffset(x, y) return UDim2.new(0, x, 0, y) end
function UDim2.fromScale(x, y) return UDim2.new(x, 0, y, 0) end

local CFrame = {}
CFrame.__index = CFrame
local function cframeFromPosition(pos)
	return setmetatable({
		Position = pos,
		LookVector = Vector3.new(0, 0, -1),
		RightVector = Vector3.new(1, 0, 0),
		UpVector = Vector3.new(0, 1, 0),
		__roType = "CFrame",
	}, CFrame)
end
function CFrame.new(x, y, z)
	if type(x) == "table" then return cframeFromPosition(Vector3.new(x.X or 0, x.Y or 0, x.Z or 0)) end
	return cframeFromPosition(Vector3.new(x or 0, y or 0, z or 0))
end
function CFrame.lookAt(from, to)
	local d = Vector3.new(to.X - from.X, to.Y - from.Y, to.Z - from.Z)
	local cf = cframeFromPosition(Vector3.new(from.X, from.Y, from.Z))
	if d.Magnitude > 1e-9 then
		cf.LookVector = Vector3.new(d.X / d.Magnitude, d.Y / d.Magnitude, d.Z / d.Magnitude)
	end
	return cf
end
function CFrame:Lerp(o, a)
	local cf = cframeFromPosition(self.Position:Lerp(o.Position, a))
	cf.LookVector = self.LookVector:Lerp(o.LookVector, a)
	return cf
end
CFrame.__add = function(a, b) return cframeFromPosition(a.Position + b) end

local RaycastParams = {}
RaycastParams.__index = RaycastParams
function RaycastParams.new() return setmetatable({ __roType = "RaycastParams" }, RaycastParams) end

-- expose to the hub code the same way Roblox does
_G.Color3 = Color3
_G.Vector2 = Vector2
_G.Vector3 = Vector3
_G.UDim = UDim
_G.UDim2 = UDim2
_G.CFrame = CFrame
_G.RaycastParams = RaycastParams

typeof = function(v)
	local t = type(v)
	if t == "table" then
		local tag = rawget(v, "__roType")
		if tag then return tag end
		return "table"
	end
	if t == "userdata" then
		local mt = getmetatable(v)
		if mt and mt.__roType then return mt.__roType end
	end
	return t
end

-- ── Enum (identity-stable items, like Roblox) ───────────────────────────────
-- EnumItems are userdata in Roblox (type() == "userdata"), which matters:
-- deep-copying config tables must treat them as opaque values, not recurse.
Enum = setmetatable({}, {
	__index = function(self, typeName)
		local et = setmetatable({ __roType = "EnumType", TypeName = typeName }, {
			__index = function(t, itemName)
				local cache = rawget(t, "__items") or {}
				local item = cache[itemName]
				if not item then
					local proxy = newproxy(true)
					local mt = {
						__roType = "EnumItem",
						Name = itemName,
						EnumType = t,
						__index = function(p, k)
							local m = getmetatable(p)
							if k == "Name" then return m.Name end
							if k == "EnumType" then return m.EnumType end
							return nil
						end,
					}
					setmetatable(proxy, mt)
					item = proxy
					cache[itemName] = item
					rawset(t, "__items", cache)
				end
				return item
			end,
		})
		rawset(self, typeName, et)
		return et
	end,
})

-- ── task + coroutine scheduler ──────────────────────────────────────────────
local CLOCK = 0
local ready, sleepers = {}, {}
local deadThreads = {} -- threads are immutable in Lua 5.1; track death externally
local function isDead(co)
	if deadThreads[co] then return true end
	return coroutine.status(co) == "dead"
end
local task = {}
function task.spawn(fn, ...)
	if type(fn) == "thread" then
		if not isDead(fn) then
			ready[#ready + 1] = { co = fn, args = { ... } }
		end
		return fn
	end
	local co = coroutine.create(fn)
	ready[#ready + 1] = { co = co, args = { ... } }
	return co
end
function task.wait(t)
	local co = coroutine.running()
	if co == coroutine.main() then return t or 0.016 end
	sleepers[#sleepers + 1] = { co = co, wakeAt = CLOCK + (t or 0.016) }
	return coroutine.yield()
end
function task.delay(t, fn, ...)
	local args = { ... }
	task.spawn(function()
		task.wait(t)
		task.spawn(fn, unpack(args))
	end)
end
function task.cancel(co)
	if type(co) == "thread" then deadThreads[co] = true end
	return nil
end
_G.task = task

-- ── Events + Instance ───────────────────────────────────────────────────────
local function newEvent(inst, name)
	local ev = {
		__roType = "RBXScriptSignal",
		_inst = inst,
		_name = name,
		_listeners = {},
		_waiters = {},
	}
	function ev:Connect(fn)
		local conn = { __roType = "RBXScriptConnection", Connected = true, _ev = ev, _fn = fn }
		function conn.Disconnect(c)
			if c.Connected then
				c.Connected = false
				for i = #ev._listeners, 1, -1 do
					if ev._listeners[i] == conn then table.remove(ev._listeners, i) break end
				end
			end
			return nil
		end
		table.insert(ev._listeners, conn)
		return conn
	end
	function ev:Wait()
		local co = coroutine.running()
		if co == coroutine.main() then error("Event:Wait from main thread") end
		table.insert(ev._waiters, co)
		return coroutine.yield()
	end
	function ev:Fire(...)
		fireEvent(ev, ...)
	end
	return ev
end

local function fireEvent(ev, ...)
		local waiters = ev._waiters
		ev._waiters = {}
		for _, co in ipairs(waiters) do
			if not deadThreads[co] and coroutine.status(co) ~= "dead" then
				ready[#ready + 1] = { co = co }
			end
		end
	local listeners = ev._listeners
	for i = #listeners, 1, -1 do
		local c = listeners[i]
		if c.Connected then
			local ok, err = pcall(c._fn, ...)
			if not ok then
				local where = (ev._inst and (ev._inst.ClassName or "?")) or "?"
				fail("[" .. tostring(where) .. "." .. tostring(ev._name) .. "] " .. tostring(err))
			end
		end
	end
end

local EVENT_NAMES = {
	InputBegan = true, InputEnded = true, InputChanged = true,
	MouseButton1Click = true, MouseButton1Down = true, MouseButton2Click = true,
	MouseEnter = true, MouseLeave = true, FocusLost = true,
	CharacterAdded = true, CharacterRemoving = true,
	PlayerAdded = true, PlayerRemoving = true,
	Idled = true, JumpRequest = true,
}

local NOOP_METHODS = {
	EquipTool = true, ChangeState = true, FireServer = true, FireClient = true,
	CaptureController = true, ClickButton2 = true, TeleportToPlaceInstance = true,
	SendMouseButtonEvent = true, Fire = true,
}

local Instance = {}
local InstanceMeta = {
	__index = function(t, k)
		local v = rawget(t, k)
		if v ~= nil then return v end
		if k == "Parent" then return t._parent end
		if k == "Name" then return t._name end
		if k == "ClassName" then return t._class end
		local m = Instance[k]
		if m then return m end
		if NOOP_METHODS[k] then
			return function() return nil end
		end
		if EVENT_NAMES[k] then
			local evs = rawget(t, "_events") or {}
			local ev = evs[k]
			if not ev then
				ev = newEvent(t, k)
				evs[k] = ev
				rawset(t, "_events", evs)
			end
			return ev
		end
		local props = rawget(t, "_props")
		if props then return props[k] end
		return nil
	end,
	__newindex = function(t, k, v)
		if type(k) == "string" and k:sub(1, 1) == "_" then
			rawset(t, k, v)
		elseif k == "Parent" then
			if t._parent then
				local pch = t._parent._children
				for i = #pch, 1, -1 do
					if pch[i] == t then table.remove(pch, i) break end
				end
			end
			t._parent = v
			if v and type(v) == "table" then
				local ch = rawget(v, "_children")
				if not ch then ch = {}; rawset(v, "_children", ch) end
				table.insert(ch, t)
			end
		elseif k == "Name" then
			rawset(t, "_name", v)
		else
			local props = rawget(t, "_props")
			if not props then props = {}; rawset(t, "_props", props) end
			props[k] = v
		end
	end,
}

function Instance.new(className)
	return setmetatable({
		__roType = "Instance",
		_class = className,
		_name = className,
		_children = {},
		_attrs = {},
		_props = {},
		_destroyed = false,
	}, InstanceMeta)
end

local IS_A_MAP = { BasePart = "Part", Part = "Volume", Decal = "Texture" }
function Instance:IsA(class)
	if class == "Instance" then return not self._destroyed end
	local c = self._class
	while c do
		if c == class then return true end
		c = IS_A_MAP[c]
	end
	return false
end
function Instance:GetChildren()
	local out = {}
	local ch = rawget(self, "_children") or {}
	for i = 1, #ch do out[i] = ch[i] end
	return out
end
function Instance:GetDescendants()
	local out = {}
	local function walk(n)
		local ch = rawget(n, "_children") or {}
		for i = 1, #ch do
			out[#out + 1] = ch[i]
			walk(ch[i])
		end
	end
	walk(self)
	return out
end
function Instance:FindFirstChild(name)
	local ch = rawget(self, "_children") or {}
	for i = 1, #ch do
		if ch[i]._name == name then return ch[i] end
	end
	return nil
end
function Instance:FindFirstChildOfClass(class)
	local ch = rawget(self, "_children") or {}
	for i = 1, #ch do
		if ch[i]:IsA(class) then return ch[i] end
	end
	return nil
end
function Instance:FindFirstAncestorOfClass(class)
	local n = self._parent
	while n do
		if n:IsA(class) then return n end
		n = n._parent
	end
	return nil
end
function Instance:IsDescendantOf(other)
	local n = self._parent
	while n do
		if n == other then return true end
		n = n._parent
	end
	return false
end
function Instance:WaitForChild(name, timeout)
	local deadline = CLOCK + (timeout or 5)
	local child = self:FindFirstChild(name)
	while not child and CLOCK < deadline do
		task.wait(0.05)
		child = self:FindFirstChild(name)
	end
	return child
end
function Instance:Destroy()
	self._destroyed = true
	if self._parent then
		local pch = self._parent._children
		for i = #pch, 1, -1 do
			if pch[i] == self then table.remove(pch, i) break end
		end
		self._parent = nil
	end
end
function Instance:GetAttribute(k) return self._attrs[k] end
function Instance:SetAttribute(k, v) self._attrs[k] = v end
function Instance:WorldToViewportPoint(pos)
	return Vector3.new(300 + (pos and pos.X or 0) * 0.1, 250 + (pos and pos.Y or 0), 10), true
end
_G.Instance = Instance

-- expose harness internals for the driver
_harness_fire = function(inst, name, ...)
	local evs = rawget(inst, "_events")
	if evs and evs[name] then fireEvent(evs[name], ...) end
end

-- ── Frame pump ──────────────────────────────────────────────────────────────
local rsRender, rsHeartbeat, rsStepped

local function pump(frames)
	for _ = 1, frames do
		CLOCK = CLOCK + 1 / 60
		for i = #sleepers, 1, -1 do
			local s = sleepers[i]
			if s.wakeAt <= CLOCK then
				table.remove(sleepers, i)
				if not deadThreads[s.co] and coroutine.status(s.co) ~= "dead" then
					ready[#ready + 1] = { co = s.co }
				end
			end
		end
		fireEvent(rsRender, 1 / 60)
		fireEvent(rsHeartbeat, 1 / 60)
		fireEvent(rsStepped, 1 / 60)
		local batch, readyNext = ready, {}
		ready = readyNext
		for i = 1, #batch do
			local co = batch[i].co
			if not deadThreads[co] and coroutine.status(co) == "suspended" then
				local ok, err = coroutine.resume(co, unpack(batch[i].args or {}))
				if not ok then fail("[task] " .. tostring(err)) end
			end
		end
	end
end

-- ── JSON (small, good enough for the harness) ───────────────────────────────
local function jsonEncode(v, depth)
	depth = depth or 0
	if depth > 12 then return "null" end
	local t = type(v)
	if v == nil then return "null"
	elseif t == "boolean" then return tostring(v)
	elseif t == "number" then
		if v ~= v or v == math.huge or v == -math.huge then return "null" end
		return tostring(v)
	elseif t == "string" then
		return '"' .. v:gsub('[%c"\\]', function(c)
			if c == '"' then return '\\"' elseif c == "\\" then return '\\\\'
			elseif c == '\n' then return '\\n' elseif c == '\t' then return '\\t'
			elseif c == '\r' then return '\\r' end
			return string.format('\\u%04x', string.byte(c))
		end) .. '"'
	elseif t == "table" then
		local ro = rawget(v, "__roType")
		if ro == "Color3" then
			return string.format('"%s,%s,%s"', v.R, v.G, v.B)
		elseif ro == "EnumItem" then
			return '"' .. tostring(v.Name) .. '"'
		elseif ro and ro ~= "Instance" then
			return '"' .. tostring(ro) .. '"'
		end
		if rawget(v, "_class") then return "null" end
		local n = 0
		for _ in pairs(v) do n = n + 1 end
		local parts = {}
		if n == #v and n > 0 then
			for i = 1, #v do parts[i] = jsonEncode(v[i], depth + 1) end
			return "[" .. table.concat(parts, ",") .. "]"
		end
		for k, val in pairs(v) do
			parts[#parts + 1] = jsonEncode(tostring(k), depth + 1) .. ":" .. jsonEncode(val, depth + 1)
		end
		return "{" .. table.concat(parts, ",") .. "}"
	end
	return "null"
end

local function jsonDecode(str)
	local pos = 1
	local function jerr(msg) error("json: " .. msg .. " at " .. pos, 0) end
	local function skipWS()
		while pos <= #str do
			local c = str:sub(pos, pos)
			if c == " " or c == "\t" or c == "\n" or c == "\r" then pos = pos + 1 else break end
		end
	end
	local parseValue
	local function parseString()
		if str:sub(pos, pos) ~= '"' then jerr("expected string") end
		pos = pos + 1
		local out = {}
		while pos <= #str do
			local c = str:sub(pos, pos)
			if c == '"' then
				pos = pos + 1
				return table.concat(out)
			elseif c == "\\" then
				local e = str:sub(pos + 1, pos + 1)
				if e == "u" then
					local hex = str:sub(pos + 2, pos + 5)
					local code = tonumber(hex, 16)
					if not code then jerr("bad unicode escape") end
					if code < 128 then out[#out + 1] = string.char(code) else out[#out + 1] = "?" end
					pos = pos + 6
				else
					local map = { ['"'] = '"', ["\\"] = "\\", ["/"] = "/", n = "\n", t = "\t", r = "\r", b = "\b", f = "\f" }
					out[#out + 1] = map[e] or e
					pos = pos + 2
				end
			else
				out[#out + 1] = c
				pos = pos + 1
			end
		end
		jerr("unterminated string")
	end
	local function parseObject()
		pos = pos + 1
		local obj = {}
		skipWS()
		if str:sub(pos, pos) == "}" then pos = pos + 1 return obj end
		while true do
			skipWS()
			local k = parseString()
			skipWS()
			if str:sub(pos, pos) ~= ":" then jerr("expected :") end
			pos = pos + 1
			skipWS()
			obj[k] = parseValue()
			skipWS()
			local c = str:sub(pos, pos)
			if c == "," then pos = pos + 1
			elseif c == "}" then pos = pos + 1 return obj
			else jerr("expected , or }") end
		end
	end
	local function parseArray()
		pos = pos + 1
		local arr = {}
		skipWS()
		if str:sub(pos, pos) == "]" then pos = pos + 1 return arr end
		while true do
			skipWS()
			arr[#arr + 1] = parseValue()
			skipWS()
			local c = str:sub(pos, pos)
			if c == "," then pos = pos + 1
			elseif c == "]" then pos = pos + 1 return arr
			else jerr("expected , or ]") end
		end
	end
	parseValue = function()
		skipWS()
		local c = str:sub(pos, pos)
		if c == '"' then return parseString()
		elseif c == "{" then return parseObject()
		elseif c == "[" then return parseArray()
		elseif c == "t" then pos = pos + 4 return true
		elseif c == "f" then pos = pos + 5 return false
		elseif c == "n" then pos = pos + 4 return nil
		end
		local numStr = str:match("^-?%d+%.?%d*[eE]?[+-]?%d*", pos)
		if numStr and numStr ~= "" then
			local v = tonumber(numStr)
			pos = pos + #numStr
			return v
		end
		jerr("unexpected character")
	end
	local ok, v = rawPcall(parseValue)
	if not ok then error(tostring(v), 0) end
	return v
end

-- ── Services & world ────────────────────────────────────────────────────────
local services = {}
local function service(name, stub) services[name] = stub return stub end
local function addMethod(inst, name, fn) rawset(inst, name, fn) end

local function makePlayer(name, opts)
	opts = opts or {}
	local p = Instance.new("Model")
	p._name = name
	p.DisplayName = name

	local char = Instance.new("Model")
	char._name = "Character:" .. name
	char.Parent = p
	local hum = Instance.new("Humanoid")
	hum._name = "Humanoid"
	hum.Health, hum.MaxHealth = 100, 100
	hum.WalkSpeed, hum.JumpPower = 16, 50
	hum.PlatformStand = false
	hum.MoveDirection = Vector3.zero
	hum.RigType = 0
	hum.Parent = char
	local root = Instance.new("BasePart")
	root._name = "HumanoidRootPart"
	root.CanCollide = false
	root.CFrame = CFrame.new(0, 5, 0)
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	root.Parent = char
	local head = Instance.new("BasePart")
	head._name = "Head"
	head.CanCollide = false
	head.CFrame = CFrame.new(0, 7.5, 0)
	head.Position = Vector3.new(0, 7.5, 0)
	head.Parent = char
	local torso = Instance.new("BasePart")
	torso._name = "UpperTorso"
	torso.CanCollide = false
	torso.CFrame = CFrame.new(0, 6, 0)
	torso.Position = Vector3.new(0, 6, 0)
	torso.Parent = char

	local bp = Instance.new("Backpack") -- its own class in Roblox; found via FindFirstChildOfClass
	bp._name = "Backpack"
	bp.Parent = p
	if opts.guns then
		for _, gun in ipairs(opts.guns) do
			local tool = Instance.new("Tool")
			tool._name = gun
			tool.Parent = bp
		end
	end

	p.Character = char
	p._character = char
	return p
end

local localPlayer = makePlayer("LocalPlayer", { guns = { "M9" } })
local remotePlayers = { makePlayer("Prisoner_1"), makePlayer("Prisoner_2") }

local Players = service("Players", Instance.new("Model"))
Players._name = "Players"
Players.LocalPlayer = localPlayer
for _, p in ipairs(remotePlayers) do p.Parent = Players end
addMethod(Players, "GetPlayers", function(self)
	local out = { self.LocalPlayer }
	for _, p in ipairs(self._children) do
		if p ~= self.LocalPlayer then out[#out + 1] = p end
	end
	return out
end)

local Workspace = service("Workspace", Instance.new("Model"))
Workspace._name = "Workspace"
Workspace.Gravity = 196.2

local camera = {
	__roType = "Camera",
	CFrame = CFrame.new(0, 6, 10),
	ViewportSize = Vector2.new(1024, 576),
	CameraSubject = localPlayer._character,
}
function camera:WorldToViewportPoint(pos)
	return Vector3.new(300 + (pos and pos.X or 0) * 0.1, 250 + (pos and pos.Y or 0) * 2, 10), true
end
Workspace.CurrentCamera = camera

local doorFolder = Instance.new("Folder")
doorFolder._name = "doors"
doorFolder.Parent = Workspace
local door = Instance.new("BasePart")
door._name = "CellDoor"
door.CanCollide = true
door.Transparency = 0
door.Color = Color3.fromRGB(90, 90, 90)
door.Material = Enum.Material.SmoothPlastic
door.Parent = doorFolder

local CoreGui = service("CoreGui", Instance.new("Model"))
CoreGui._name = "CoreGui"

local ReplicatedStorage = service("ReplicatedStorage", Instance.new("Model"))
ReplicatedStorage._name = "ReplicatedStorage"
local meleeEvent = Instance.new("RemoteEvent")
meleeEvent._name = "meleeEvent"
meleeEvent.Parent = ReplicatedStorage

local Lighting = service("Lighting", {
	Ambient = Color3.fromRGB(120, 120, 120),
	OutdoorAmbient = Color3.fromRGB(120, 120, 120),
	Brightness = 1,
	GlobalShadows = true,
	ClockTime = 14,
})

local UserInputService = service("UserInputService", Instance.new("Model"))
UserInputService._name = "UserInputService"
UserInputService.TouchEnabled = false
UserInputService.KeyboardEnabled = true
addMethod(UserInputService, "GetMouseLocation", function() return Vector2.new(512, 288) end)
addMethod(UserInputService, "IsKeyDown", function() return false end)
addMethod(UserInputService, "IsMouseButtonPressed", function() return false end)

local GuiService = service("GuiService", Instance.new("Model"))
addMethod(GuiService, "GetGuiInset", function() return Vector2.zero end)

rsRender, rsHeartbeat, rsStepped = newEvent(nil, "RenderStepped"), newEvent(nil, "Heartbeat"), newEvent(nil, "Stepped")
local RunService = service("RunService", {
	RenderStepped = rsRender,
	Heartbeat = rsHeartbeat,
	Stepped = rsStepped,
})

local Stats = service("Stats", {
	Network = {
		ServerStatsItem = {
			["Data Ping"] = { GetValue = function() return 25 end },
		},
	},
})

local RbxAnalytics = service("RbxAnalyticsService", {})
addMethod(RbxAnalytics, "GetClientId", function() return "0123456789abcdef" end)

local VirtualUser = service("VirtualUser", {})
addMethod(VirtualUser, "CaptureController", function() return nil end)
addMethod(VirtualUser, "ClickButton2", function() return nil end)

local TeleportService = service("TeleportService", {})
addMethod(TeleportService, "TeleportToPlaceInstance", function()
	H.prints[#H.prints + 1] = "[stub] TeleportToPlaceInstance"
	rawPrint("[stub] TeleportToPlaceInstance")
	return nil
end)

local VirtualInputManager = service("VirtualInputManager", {})
addMethod(VirtualInputManager, "SendMouseButtonEvent", function() return nil end)

local LICENSE_BODY = (AUTH_MODE == "valid") and '{"valid":true,"tier":"Full"}' or '{"valid":false,"error":"Invalid license key."}'
local SERVERS_BODY = '{"data":[{"id":"job-abc","name":"s1","playing":3,"maxPlayers":10}]}'
local function apiBodyFor(url)
	if url:find("validate-license", 1, true) then return LICENSE_BODY end
	if url:find("games.roblox.com", 1, true) then return SERVERS_BODY end
	return "{}"
end

local HttpServiceStub = service("HttpService", {})
addMethod(HttpServiceStub, "JSONEncode", function(self, v) return jsonEncode(v) end)
addMethod(HttpServiceStub, "JSONDecode", function(self, s)
	local ok, r = rawPcall(jsonDecode, s)
	return ok and r or nil
end)
addMethod(HttpServiceStub, "GenerateGUID", function(self, withDashes)
	return withDashes and "00000000-0000-0000-0000-000000000000" or "00000000000000000000000000000000"
end)
addMethod(HttpServiceStub, "RequestAsync", function(self, options)
	return { Success = true, Status = 200, Headers = {}, Body = apiBodyFor(options.Url) }
end)

game = setmetatable({
	__roType = "DataModel",
	PlaceId = PLACE_ID,
	GameId = 999,
	JobId = "job-local",
	Loaded = newEvent(nil, "Loaded"),
	Workspace = Workspace,
	ReplicatedStorage = ReplicatedStorage,
}, {
	__index = function(t, k)
		if k == "GetService" then
			return function(_, name)
				local s = services[name]
				if not s then error("GetService: unknown service " .. tostring(name)) end
				return s
			end
		elseif k == "IsLoaded" then
			return function() return true end
		elseif k == "HttpGet" then
			return function(_, url)
				local path = url:match("/Root/(.*)")
				if path then
					path = path:match("^[^?]*") -- strip cache-buster
					local f = io.open(repoRoot .. "/Root/" .. path, "rb")
					if f then
						local content = f:read("*a")
						f:close()
						return content
					end
					return "404: Not Found"
				end
				return "404: Not Found"
			end
		end
		return nil
	end,
})
workspace = Workspace

-- ── File API (auth modes that simulate a saved key) ─────────────────────────
local SALT = "B0Xaz_Universal_Key_System_2026"
local function bitXor(a, b)
	local res, p = 0, 1
	while a > 0 or b > 0 do
		local a1, b1 = a % 2, b % 2
		if a1 ~= b1 then res = res + p end
		a, b = math.floor(a / 2), math.floor(b / 2)
		p = p * 2
	end
	return res
end
local B64C = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local function b64encode(data)
	local out, k = {}, 1
	for i = 1, #data, 3 do
		local b1, b2, b3 = data:byte(i), data:byte(i + 1), data:byte(i + 2)
		local n = (b1 * 65536) + ((b2 or 0) * 256) + (b3 or 0)
		out[k] = B64C:sub(math.floor(n / 262144) % 64 + 1, math.floor(n / 262144) % 64 + 1)
		out[k + 1] = B64C:sub(math.floor(n / 4096) % 64 + 1, math.floor(n / 4096) % 64 + 1)
		out[k + 2] = b2 and B64C:sub(math.floor(n / 64) % 64 + 1, math.floor(n / 64) % 64 + 1) or "="
		out[k + 3] = b3 and B64C:sub(n % 64 + 1, n % 64 + 1) or "="
		k = k + 4
	end
	return table.concat(out)
end
local function xorEncode(salt, payload)
	local out = {}
	for i = 1, #payload do
		local kb = string.byte(salt, ((i - 1) % #salt) + 1)
		out[i] = string.char(bitXor(string.byte(payload, i), kb))
	end
	return b64encode(table.concat(out))
end

if AUTH_MODE ~= "none" then
	local KEY_PATH = "B0XazUniversal/_key.json"
	local blob = xorEncode(SALT, '{"Key":"TESTKEY123","SavedAt":1700000000}')
	isfile = function(p) return p == KEY_PATH end
	readfile = function(p) return p == KEY_PATH and blob or nil end
	writefile = function(p)
		H.prints[#H.prints + 1] = "[stub] writefile " .. tostring(p)
		rawPrint("[stub] writefile " .. tostring(p))
		return true
	end
	delfile = function() return true end
end

-- ── Syntax pre-check: every module must parse ───────────────────────────────
local files = {}
local popenOk, list = pcall(function()
	local it = io.popen('find "' .. repoRoot .. '/Root" -type f -name "*.lua"')
	local out = {}
	if it then
		for line in it:lines() do out[#out + 1] = line end
		it:close()
	end
	return out
end)
if popenOk then files = list end
for _, f in ipairs(files) do
	local chunk, err = loadfile(f)
	if not chunk then
		fail("[syntax] " .. f .. ": " .. tostring(err))
	end
end
vprint("[harness] syntax-checked " .. #files .. " module files (place=" .. PLACE_ID .. " auth=" .. AUTH_MODE .. ")")

-- ── Boot ────────────────────────────────────────────────────────────────────
local bootOk, bootErr = pcall(dofile, repoRoot .. "/Init.lua")
if not bootOk then
	fail("[boot] Init.lua crashed: " .. tostring(bootErr))
end
pump(5)

-- ── Driver helpers ──────────────────────────────────────────────────────────
local function allInstances(root)
	local out = { root }
	for _, d in ipairs(root:GetDescendants()) do out[#out + 1] = d end
	return out
end
local function findButtons(root)
	local out = {}
	for _, inst in ipairs(allInstances(root)) do
		if inst._class == "TextButton" then out[#out + 1] = inst end
	end
	return out
end
local function findText(root, text)
	for _, inst in ipairs(allInstances(root)) do
		local cls = inst._class
		if cls == "TextLabel" or cls == "TextButton" or cls == "TextBox" then
			local t = inst._props and inst._props.Text
			if type(t) == "string" and (t == text or t:find(text, 1, true)) then return inst end
		end
	end
	return nil
end
local function findByName(root, name)
	for _, inst in ipairs(allInstances(root)) do
		if inst._name == name then return inst end
	end
	return nil
end
local function printAllTexts(root, tag)
	vprint("[harness:" .. tag .. "] UI labels:")
	for _, inst in ipairs(allInstances(root)) do
		local cls = inst._class
		if cls == "TextLabel" or cls == "TextButton" or cls == "TextBox" then
			local t = inst._props and inst._props.Text
			if type(t) == "string" and t ~= "" then
				vprint("    " .. cls .. ": " .. t)
			end
		end
	end
end

local hubGui = CoreGui._children[1]
if not hubGui or hubGui._class ~= "ScreenGui" then
	fail("[ui] hub ScreenGui was not created in CoreGui")
end

local uiAvailable = (hubGui ~= nil)

-- ── Checks ──────────────────────────────────────────────────────────────────
local checks = {}
local function check(cond, label)
	checks[#checks + 1] = { ok = cond and true or false, label = label }
	if not cond then vprint("[FAIL] " .. label) end
end

local mainFrame
if uiAvailable then
	for _, inst in ipairs(allInstances(hubGui)) do
		if inst._class == "Frame" and inst._props and inst._props.ClipsDescendants then
			mainFrame = inst
			break
		end
	end
end
check(mainFrame ~= nil, "main window frame exists")

if AUTH_MODE == "none" then
	if uiAvailable then
		check(findText(CoreGui, "Authentication Required") ~= nil, "auth modal shown when no key is saved")
	else
		check(false, "auth modal shown when no key is saved")
	end
else
	check(table.concat(H.prints, "\n"):find("Universal Hub Online", 1, true) ~= nil,
		"hub reports Universal Hub Online (key verified + launch)")
end

if PLACE_ID == 155615604 then
	if uiAvailable then
		check(findText(hubGui, "Grab Gun: M9") ~= nil, "Prison Life adapter UI built (Gun Grabber button)")
		check(findText(hubGui, "Phase Doors & Gates") ~= nil, "Prison Life adapter UI built (Door Phase toggle)")
	else
		check(false, "Prison Life adapter UI built (Gun Grabber button)")
	end
else
	if uiAvailable then
		check(findText(hubGui, "Universal fallbacks active") ~= nil, "universal fallback label shown for unsupported place")
	else
		check(false, "universal fallback label shown for unsupported place")
	end
end

-- ── Interaction passes ──────────────────────────────────────────────────────
local function clickPass()
	local count = 0
	for _, guiRoot in ipairs(CoreGui:GetChildren()) do
		for _, btn in ipairs(findButtons(guiRoot)) do
			_harness_fire(btn, "MouseEnter")
			_harness_fire(btn, "MouseButton1Click")
			_harness_fire(btn, "MouseLeave")
			count = count + 1
		end
	end
	return count
end

if not uiAvailable then
	vprint("[harness] UI unavailable — skipping interaction tests")
end

local n1, n2 = 0, 0
if uiAvailable then
	n1 = clickPass()
	pump(10)
	n2 = clickPass() -- second pass catches dropdown items / modals created by pass 1
	pump(10)
end
H.clicks = n1 + n2
vprint(string.format("[harness] clicked %d buttons across 2 passes", n1 + n2))

-- keybind capture: the "Aimbot Keybind" button was left in binding mode by the
-- click passes; press V to commit it.
if uiAvailable then
	_harness_fire(UserInputService, "InputBegan", {
		UserInputType = Enum.UserInputType.Keyboard,
		KeyCode = Enum.KeyCode.V,
		Position = Vector2.new(0, 0),
	})
	pump(2)
	check(findText(hubGui, "[V]") ~= nil, "keybind capture: pressing V updates the aimbot keybind to [V]")
else
	check(false, "keybind capture: pressing V updates the aimbot keybind to [V]")
end

-- menu hotkey toggles the window. The keybind-capture test above rebound the
-- menu hotkey to V (the capture is still live), so press V.
local visibleBefore = mainFrame and mainFrame.Visible
_harness_fire(UserInputService, "InputBegan", {
	UserInputType = Enum.UserInputType.Keyboard,
	KeyCode = Enum.KeyCode.V,
	Position = Vector2.new(0, 0),
})
pump(2)
check(mainFrame and mainFrame.Visible == (not visibleBefore), "menu hotkey toggles the window")
_harness_fire(UserInputService, "InputBegan", {
	UserInputType = Enum.UserInputType.Keyboard,
	KeyCode = Enum.KeyCode.V,
	Position = Vector2.new(0, 0),
})
pump(2)

-- settings: saving "Default" must notify via the tab
if uiAvailable then
	check(findText(hubGui, "Cannot overwrite default snapshot.") ~= nil,
		"tab:Notify works (Default profile save guard notification)")
	check(findText(CoreGui, "Configuration JSON Data") ~= nil, "Export Profile JSON opens the export modal")
else
	check(false, "tab:Notify works (Default profile save guard notification)")
	check(false, "Export Profile JSON opens the export modal")
end

-- settings: clicking every theme preset leaves the last sorted preset applied
-- (Midnight Purple = RGB 14,12,20)
if mainFrame and mainFrame._props.BackgroundColor3 then
	local c = mainFrame._props.BackgroundColor3
	check(math.abs(c.R - 14 / 255) < 0.001 and math.abs(c.G - 12 / 255) < 0.001 and math.abs(c.B - 20 / 255) < 0.001,
		"theme preset switch repaints the window (final preset = Midnight Purple)")
else
	check(false, "theme preset switch repaints the window (final preset = Midnight Purple)")
end

-- auth modal: submit a key (last, so nothing overwrites the verdict label)
if AUTH_MODE == "none" then
	if uiAvailable then
		local submitBtn, keyBox
		for _, inst in ipairs(allInstances(CoreGui)) do
			if inst._class == "TextButton" and inst._props and inst._props.Text == "Authenticate" then
				submitBtn = inst
			elseif inst._class == "TextBox" and inst._props and inst._props.PlaceholderText == "Paste access key token here..." then
				keyBox = inst
			end
		end
		if keyBox then keyBox.Text = "PASTED-KEY-123" end -- user pastes a key
		if submitBtn then
			_harness_fire(submitBtn, "MouseButton1Click")
			pump(5)
			check(findText(CoreGui, "Invalid license key.") ~= nil, "auth modal reports license server verdict")
		else
			check(false, "auth modal reports license server verdict (no Authenticate button)")
		end
	else
		check(false, "auth modal reports license server verdict")
	end
end

-- Prison Life: door phase round-trip + weapon modder
if PLACE_ID == 155615604 and uiAvailable then
	local function toggleButtonForLabel(labelText)
		for _, lab in ipairs(allInstances(hubGui)) do
			if lab._class == "TextLabel" and lab._props and lab._props.Text == labelText and lab._parent then
				for _, sib in ipairs(lab._parent:GetChildren()) do
					if sib._class == "TextButton" then return sib end
				end
			end
		end
		return nil
	end
	local phaseBtn = toggleButtonForLabel("Phase Doors & Gates")
	if phaseBtn then
		_harness_fire(phaseBtn, "MouseButton1Click")
		pump(3)
		check(door.CanCollide == false and door.Material == Enum.Material.Neon,
			"door phase: CanCollide off + Neon glow applied")
		_harness_fire(phaseBtn, "MouseButton1Click")
		pump(3)
		check(door.CanCollide == true, "door phase restore: CanCollide back on")
	else
		check(false, "door phase toggle located")
	end
	local backpack = localPlayer:FindFirstChild("Backpack")
	local m9 = backpack and backpack:FindFirstChild("M9")
	local noSpreadBtn = toggleButtonForLabel("No Spread")
	if noSpreadBtn then
		_harness_fire(noSpreadBtn, "MouseButton1Click")
		pump(3)
		check(m9 and m9:GetAttribute("SpreadRadius") == 0,
			"no-spread: M9 SpreadRadius attribute set to 0")
	else
		check(false, "no-spread toggle located")
	end
elseif PLACE_ID == 155615604 then
	check(false, "door phase round-trip (UI missing)")
end

-- server hop button drives the notification flow
if uiAvailable then
	check(findText(hubGui, "Searching open instances.") ~= nil, "server hop button drives the notification flow")
else
	check(false, "server hop button drives the notification flow")
end

-- ── Report ──────────────────────────────────────────────────────────────────
local passCount, failCount = 0, 0
for _, c in ipairs(checks) do
	if c.ok then passCount = passCount + 1 else failCount = failCount + 1 end
end
if (failCount > 0 or #H.pcallErrors > 0 or #H.errors > 0) and hubGui then
	printAllTexts(hubGui, "debug")
end

vprint("")
vprint(string.rep("─", 12) .. string.format(" scenario: place=%d auth=%s ", PLACE_ID, AUTH_MODE) .. string.rep("─", 20))
vprint(string.format("checks passed: %d", passCount))
vprint(string.format("checks FAILED: %d", failCount))
if #H.pcallErrors > 0 then
	vprint("[swallowed pcall errors] " .. #H.pcallErrors)
	for i = 1, #H.pcallErrors do vprint("  - " .. H.pcallErrors[i]) end
end
if #H.errors > 0 then
	vprint("[fatal harness errors] " .. #H.errors)
	for i = 1, #H.errors do vprint("  - " .. H.errors[i]) end
end
local ok = failCount == 0 and #H.errors == 0 and #H.pcallErrors == 0
vprint(ok and "RESULT: PASS" or "RESULT: FAIL")
os.exit(ok and 0 or 1)

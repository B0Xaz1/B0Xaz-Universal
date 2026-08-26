-- ════════════════════════════════════════════════════════════════════════════
-- Shared/Crypto.lua
-- Pure-Luau Base64 encoding/decoding, XOR cipher, and HWID resolver
-- ════════════════════════════════════════════════════════════════════════════

local HttpService = game:GetService("HttpService")

local Crypto = {}
local B64_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local B64_LOOKUP = {}
for i = 1, 64 do
	B64_LOOKUP[B64_CHARS:sub(i, i)] = i - 1
end

local bitXor = (bit32 and bit32.bxor) or (bit and bit.bxor)
if not bitXor then
	bitXor = function(a, b)
		local res, p = 0, 1
		while a > 0 and b > 0 do
			local a1, b1 = a % 2, b % 2
			if a1 ~= b1 then res = res + p end
			a = math.floor(a / 2)
			b = math.floor(b / 2)
			p = p * 2
		end
		if a > 0 then res = res + a * p end
		if b > 0 then res = res + b * p end
		return res
	end
end

-- Base64 Encode with executor API support or pure Luau fallback
function Crypto.Base64Encode(data)
	if crypt and crypt.base64encode then
		local ok, res = pcall(crypt.base64encode, data)
		if ok and res then return res end
	end
	if base64_encode then
		local ok, res = pcall(base64_encode, data)
		if ok and res then return res end
	end

	local len = #data
	local out = {}
	local k = 1

	for i = 1, len, 3 do
		local b1 = string.byte(data, i)
		local b2 = string.byte(data, i + 1)
		local b3 = string.byte(data, i + 2)

		local n = (b1 * 65536) + ((b2 or 0) * 256) + (b3 or 0)
		out[k] = B64_CHARS:sub(math.floor(n / 262144) % 64 + 1, math.floor(n / 262144) % 64 + 1)
		out[k + 1] = B64_CHARS:sub(math.floor(n / 4096) % 64 + 1, math.floor(n / 4096) % 64 + 1)
		out[k + 2] = b2 and B64_CHARS:sub(math.floor(n / 64) % 64 + 1, math.floor(n / 64) % 64 + 1) or "="
		out[k + 3] = b3 and B64_CHARS:sub(n % 64 + 1, n % 64 + 1) or "="
		k = k + 4
	end

	return table.concat(out)
end

-- Base64 Decode with executor API support or pure Luau fallback
function Crypto.Base64Decode(data)
	if crypt and crypt.base64decode then
		local ok, res = pcall(crypt.base64decode, data)
		if ok and res then return res end
	end
	if base64_decode then
		local ok, res = pcall(base64_decode, data)
		if ok and res then return res end
	end

	data = data:gsub("[^A-Za-z0-9+/=]", "")
	local len = #data
	local out = {}
	local k = 1

	for i = 1, len, 4 do
		local ch1, ch2, ch3, ch4 = data:sub(i, i), data:sub(i + 1, i + 1), data:sub(i + 2, i + 2), data:sub(i + 3, i + 3)
		local v1, v2 = B64_LOOKUP[ch1] or 0, B64_LOOKUP[ch2] or 0
		local v3, v4 = B64_LOOKUP[ch3], B64_LOOKUP[ch4]

		local n = (v1 * 262144) + (v2 * 4096) + ((v3 or 0) * 64) + (v4 or 0)
		out[k] = string.char(math.floor(n / 65536) % 256)
		k = k + 1
		if ch3 ~= "=" and v3 then
			out[k] = string.char(math.floor(n / 256) % 256)
			k = k + 1
		end
		if ch4 ~= "=" and v4 then
			out[k] = string.char(n % 256)
			k = k + 1
		end
	end

	return table.concat(out)
end

-- Symmetric XOR cipher
function Crypto.Xor(str, key)
	local out = {}
	for i = 1, #str do
		local b = string.byte(str, i)
		local kb = string.byte(key, ((i - 1) % #key) + 1)
		table.insert(out, string.char(bitXor(b, kb)))
	end
	return table.concat(out)
end

-- Resolve a stable client hardware ID
function Crypto.GetDeviceId()
	local stableId
	pcall(function()
		local analytics = game:GetService("RbxAnalyticsService")
		stableId = analytics:GetClientId()
	end)
	if type(stableId) == "string" and #stableId >= 16 then
		return stableId
	end
	return HttpService:GenerateGUID(false)
end

return Crypto

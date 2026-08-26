-- ════════════════════════════════════════════════════════════════════════════
-- Shared/HttpUtil.lua
-- Resilient, polymorphic HTTP request executor and JSON parser
-- ════════════════════════════════════════════════════════════════════════════

local HttpService = game:GetService("HttpService")

local HttpUtil = {}

-- Safe wrapper for JSON serialization
function HttpUtil.JSONEncode(tbl)
	local ok, res = pcall(HttpService.JSONEncode, HttpService, tbl)
	return ok and res or nil
end

-- Safe wrapper for JSON deserialization
function HttpUtil.JSONDecode(str)
	if type(str) ~= "string" or #str == 0 then return nil end
	local ok, res = pcall(HttpService.JSONDecode, HttpService, str)
	return ok and res or nil
end

-- Standardized Request wrapper supporting multiple exploit HTTP backends
function HttpUtil.Request(options)
	local requestFn = request or http_request or (syn and syn.request) or (http and http.request)
	
	if type(requestFn) == "function" then
		return pcall(requestFn, {
			Url = options.Url,
			Method = options.Method or "GET",
			Headers = options.Headers,
			Body = options.Body,
		})
	end

	-- Roblox game-engine fallback
	return pcall(function()
		return HttpService:RequestAsync({
			Url = options.Url,
			Method = options.Method or "GET",
			Headers = options.Headers,
			Body = options.Body,
		})
	end)
end

return HttpUtil

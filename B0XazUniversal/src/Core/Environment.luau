--!strict

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

return function(disposer: any)
	local Environment = {}
	local ROOT_FOLDER: string = "B0XazUniversal"

	local function debug(message: string)
		print("[B0Xaz][Environment] " .. message)
	end

	-- Capabilities are probed once at boot so per-frame code never has to
	-- typeof-check executor globals again.
	local hasHui: boolean = typeof(gethui) == "function"
	local hasWriteFile: boolean = typeof(writefile) == "function"
	local hasReadFile: boolean = typeof(readfile) == "function"
	local hasIsFile: boolean = typeof(isfile) == "function"
	local hasListFiles: boolean = typeof(listfiles) == "function"
	local hasMakeFolder: boolean = typeof(makefolder) == "function"
	local hasDelFile: boolean = typeof(delfile) == "function"
	local hasMouseRel: boolean = typeof(mousemoverel) == "function"
	local hasClipboard: boolean = typeof(setclipboard) == "function"
	local hasGetClipboard: boolean = typeof(getclipboard) == "function"
	local hasQueueTeleport: boolean = typeof(queue_on_teleport) == "function"
		or (syn and typeof(syn.queue_on_teleport) == "function")
		or (fluxus and typeof(fluxus.queue_on_teleport) == "function")

	debug(string.format(
		"Capabilities readfile=%s isfile=%s writefile=%s request=%s",
		tostring(hasReadFile),
		tostring(hasIsFile),
		tostring(hasWriteFile),
		tostring(typeof(request) == "function" or typeof(http_request) == "function")
	))

	if hasMakeFolder then
		debug("Creating filesystem folders")
		pcall(makefolder, ROOT_FOLDER)
		pcall(makefolder, ROOT_FOLDER .. "/Configs")
		pcall(makefolder, ROOT_FOLDER .. "/Themes")
	else
		debug("makefolder unavailable; filesystem persistence may be disabled")
	end

	local cachedHostParent: Instance? = nil

	function Environment.GetSafeGuiParent(): Instance
		if cachedHostParent and cachedHostParent.Parent then
			return cachedHostParent
		end

		if hasHui then
			local ok, huiInstance = pcall(gethui)
			if ok and huiInstance then
				cachedHostParent = huiInstance
				return huiInstance
			end
		end

		-- CoreGui is usable on some executors but not all; probe with a
		-- throwaway instance instead of assuming.
		local canAccessCore, _ = pcall(function()
			local test = Instance.new("Folder")
			test.Parent = CoreGui
			test:Destroy()
		end)

		if canAccessCore then
			cachedHostParent = CoreGui
			return CoreGui
		end

		local lp = Players.LocalPlayer
		if lp then
			local pGui = lp:FindFirstChildOfClass("PlayerGui") or lp:WaitForChild("PlayerGui", 5)
			if pGui then
				cachedHostParent = pGui
				return pGui
			end
		end

		cachedHostParent = CoreGui
		return CoreGui
	end

	function Environment.GetDeviceId(): string
		local deviceFile = ROOT_FOLDER .. "/_device.json"
		debug("GetDeviceId: checking " .. deviceFile)

		local deviceFileExists = false
		if hasReadFile and hasIsFile then
			local existsOk, exists = pcall(isfile, deviceFile)
			deviceFileExists = existsOk and exists == true
			debug(string.format("GetDeviceId: isfile check ok=%s exists=%s", tostring(existsOk), tostring(deviceFileExists)))
		else
			debug("GetDeviceId: readfile/isfile unavailable")
		end

		if deviceFileExists then
			local readOk, content = pcall(readfile, deviceFile)
			if readOk and typeof(content) == "string" and content ~= "" then
				local decodeOk, data = pcall(HttpService.JSONDecode, HttpService, content)
				if decodeOk and typeof(data) == "table" and typeof(data.Id) == "string" and #data.Id >= 16 then
					debug("GetDeviceId: using saved device id")
					return data.Id
				end
				debug("GetDeviceId: saved device file was invalid")
			else
				debug("GetDeviceId: could not read saved device file")
			end
		end

		local rbxClientId: string? = nil
		local analyticsOk = pcall(function()
			local analytics = game:GetService("RbxAnalyticsService")
			rbxClientId = analytics:GetClientId()
		end)

		if analyticsOk and rbxClientId and #rbxClientId >= 16 then
			debug("GetDeviceId: using Roblox analytics id")
			return rbxClientId
		end
		debug("GetDeviceId: using generated id")

		local generatedId = HttpService:GenerateGUID(false)
		if hasWriteFile then
			local writeOk = pcall(writefile, deviceFile, HttpService:JSONEncode({ Id = generatedId, CreatedAt = os.time() }))
			debug("GetDeviceId: saved generated id=" .. tostring(writeOk))
		else
			debug("GetDeviceId: writefile unavailable; generated id will not persist")
		end
		return generatedId
	end

	local b64Chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	local b64Lookup = {}
	for i = 1, 64 do
		b64Lookup[b64Chars:sub(i, i)] = i - 1
	end

	-- The Luau fallbacks mirror the standard base64 algorithm so configs and
	-- keys keep working on executors without the native crypt library.
	function Environment.Base64Encode(data: string): string
		if crypt and typeof(crypt.base64encode) == "function" then
			local ok, res = pcall(crypt.base64encode, data)
			if ok and res then return res end
		end

		local len = #data
		local out = table.create(math.ceil(len / 3) * 4)
		local k = 1

		for i = 1, len, 3 do
			local b1 = string.byte(data, i)
			local b2 = string.byte(data, i + 1)
			local b3 = string.byte(data, i + 2)

			local n = bit32.lshift(b1, 16) + (b2 and bit32.lshift(b2, 8) or 0) + (b3 or 0)

			out[k] = b64Chars:sub(bit32.band(bit32.rshift(n, 18), 63) + 1, bit32.band(bit32.rshift(n, 18), 63) + 1)
			out[k + 1] = b64Chars:sub(bit32.band(bit32.rshift(n, 12), 63) + 1, bit32.band(bit32.rshift(n, 12), 63) + 1)
			out[k + 2] = b2 and b64Chars:sub(bit32.band(bit32.rshift(n, 6), 63) + 1, bit32.band(bit32.rshift(n, 6), 63) + 1) or "="
			out[k + 3] = b3 and b64Chars:sub(bit32.band(n, 63) + 1, bit32.band(n, 63) + 1) or "="
			k += 4
		end

		return table.concat(out)
	end

	function Environment.Base64Decode(data: string): string
		if crypt and typeof(crypt.base64decode) == "function" then
			local ok, res = pcall(crypt.base64decode, data)
			if ok and res then return res end
		end

		local cleanData = data:gsub("[^A-Za-z0-9+/=]", "")
		local len = #cleanData
		local out = table.create(math.floor(len * 0.75))
		local k = 1

		for i = 1, len, 4 do
			local c1 = cleanData:sub(i, i)
			local c2 = cleanData:sub(i + 1, i + 1)
			local c3 = cleanData:sub(i + 2, i + 2)
			local c4 = cleanData:sub(i + 3, i + 3)

			local v1 = b64Lookup[c1] or 0
			local v2 = b64Lookup[c2] or 0
			local v3 = b64Lookup[c3]
			local v4 = b64Lookup[c4]

			local n = bit32.lshift(v1, 18) + bit32.lshift(v2, 12) + (v3 and bit32.lshift(v3, 6) or 0) + (v4 or 0)

			out[k] = string.char(bit32.band(bit32.rshift(n, 16), 255))
			k += 1
			if c3 ~= "=" and v3 then
				out[k] = string.char(bit32.band(bit32.rshift(n, 8), 255))
				k += 1
			end
			if c4 ~= "=" and v4 then
				out[k] = string.char(bit32.band(n, 255))
				k += 1
			end
		end

		return table.concat(out)
	end

	function Environment.XorCipher(data: string, key: string): string
		local keyLen = #key
		local out = table.create(#data)
		for i = 1, #data do
			local byte = string.byte(data, i)
			local keyByte = string.byte(key, ((i - 1) % keyLen) + 1)
			out[i] = string.char(bit32.bxor(byte, keyByte))
		end
		return table.concat(out)
	end

	-- All paths are pinned under ROOT_FOLDER; callers may or may not pass
	-- the prefix, so it is stripped before joining.
	function Environment.WriteFile(relativePath: string, content: string): (boolean, string?)
		if not hasWriteFile then return false, "writefile unavailable" end
		local fullPath = ROOT_FOLDER .. "/" .. relativePath:gsub("^" .. ROOT_FOLDER .. "/", "")
		local ok, err = pcall(writefile, fullPath, content)
		return ok, ok and nil or tostring(err)
	end

	function Environment.ReadFile(relativePath: string): string?
		if not (hasReadFile and hasIsFile) then return nil end
		local fullPath = ROOT_FOLDER .. "/" .. relativePath:gsub("^" .. ROOT_FOLDER .. "/", "")
		if not isfile(fullPath) then return nil end
		local ok, result = pcall(readfile, fullPath)
		return ok and result or nil
	end

	function Environment.ListFiles(relativeFolder: string): { string }
		if not hasListFiles then return {} end
		local fullFolder = ROOT_FOLDER .. "/" .. relativeFolder:gsub("^" .. ROOT_FOLDER .. "/", ""):gsub("[/\\]+$", "")
		local ok, result = pcall(listfiles, fullFolder)
		if ok and typeof(result) == "table" then
			return result
		end
		return {}
	end

	function Environment.DeleteFile(relativePath: string): boolean
		if not hasDelFile then return false end
		local fullPath = ROOT_FOLDER .. "/" .. relativePath:gsub("^" .. ROOT_FOLDER .. "/", "")
		local ok = pcall(delfile, fullPath)
		return ok
	end

	function Environment.MouseMove(deltaX: number, deltaY: number): boolean
		if not hasMouseRel then return false end
		return pcall(mousemoverel, deltaX, deltaY)
	end

	function Environment.SetClipboard(text: string): boolean
		if not hasClipboard then return false end
		return pcall(setclipboard, text)
	end

	function Environment.GetClipboard(): string?
		if not hasGetClipboard then return nil end
		local ok, text = pcall(getclipboard)
		return ok and typeof(text) == "string" and text or nil
	end

	function Environment.QueueTeleport(scriptSource: string): boolean
		if not hasQueueTeleport then return false end
		local queueFn = queue_on_teleport
			or (syn and syn.queue_on_teleport)
			or (fluxus and fluxus.queue_on_teleport)
		if queueFn then
			return pcall(queueFn, scriptSource)
		end
		return false
	end

	-- Keycode lookups are precomputed so keybind parsing stays O(1) at runtime
	local KEYCODE_CACHE: { [string]: Enum.KeyCode } = {}
	for _, enumItem in ipairs(Enum.KeyCode:GetEnumItems()) do
		KEYCODE_CACHE[enumItem.Name:upper()] = enumItem
	end

	local MOUSE_ALIASES: { [string]: Enum.UserInputType } = {
		["MB1"] = Enum.UserInputType.MouseButton1,
		["MOUSEBUTTON1"] = Enum.UserInputType.MouseButton1,
		["MB2"] = Enum.UserInputType.MouseButton2,
		["MOUSEBUTTON2"] = Enum.UserInputType.MouseButton2,
		["MB3"] = Enum.UserInputType.MouseButton3,
		["MOUSEBUTTON3"] = Enum.UserInputType.MouseButton3,
	}

	function Environment.ParseKeybind(input: any): (Enum.KeyCode | Enum.UserInputType)?
		if typeof(input) == "EnumItem" then
			if input.EnumType == Enum.KeyCode or input.EnumType == Enum.UserInputType then
				return input :: any
			end
		elseif typeof(input) == "string" then
			local upper = input:upper()
			local mouseEnum = MOUSE_ALIASES[upper]
			if mouseEnum then return mouseEnum end
			return KEYCODE_CACHE[upper]
		elseif typeof(input) == "table" and input.__type == "EnumItem" and input.name then
			local cleanEnum = tostring(input.enum or "KeyCode"):gsub("^Enum%.", "")
			local enumType = (Enum :: any)[cleanEnum]
			if enumType then
				return enumType[input.name]
			end
		end
		return nil
	end

	function Environment.FormatKeybindName(bind: any): string
		if not bind then return "None" end
		if typeof(bind) == "EnumItem" then
			if bind.EnumType == Enum.UserInputType then
				if bind == Enum.UserInputType.MouseButton1 then return "MB1" end
				if bind == Enum.UserInputType.MouseButton2 then return "MB2" end
				if bind == Enum.UserInputType.MouseButton3 then return "MB3" end
			end
			return bind.Name
		elseif typeof(bind) == "table" and bind.__type == "EnumItem" and bind.name then
			if bind.name == "MouseButton1" then return "MB1" end
			if bind.name == "MouseButton2" then return "MB2" end
			if bind.name == "MouseButton3" then return "MB3" end
			return tostring(bind.name)
		end
		return tostring(bind)
	end

	return Environment
end

-- // src/Games/Loader.lua
local SETTINGS = {
	PATHS = {
		REGISTRY = "src/Games/Registry.lua",
		MODULE_INIT = "src/Games/%s/init.lua",
		MODULE_SINGLE = "src/Games/%s.lua",
	},
	FALLBACK_REGISTRY = {
		["155615604"] = {
			Name = "Prison Life",
			Folder = "155615604",
			Description = "Prison Life automated door phasing, gun grabbers, and melee exploits",
		},
	},
	FALLBACK_NAME_FORMAT = "Universal (%s)",
	ERRORS = {
		IMPORT_UNAVAILABLE = "Import function unavailable",
		REGISTRY_UNAVAILABLE = "Game registry unavailable",
		BUILD_UI_MISSING = "Module missing or no BuildUI function",
	},
}

return function(Context, import)
	local placeId = tostring(game.PlaceId)
	local universeId = tostring(game.GameId)

	local registry = SETTINGS.FALLBACK_REGISTRY
	if type(import) == "function" then
		local success, regResult = pcall(import, SETTINGS.PATHS.REGISTRY, true)
		if success and type(regResult) == "function" then
			local callSuccess, callResult = pcall(regResult)
			if callSuccess and type(callResult) == "table" then
				registry = callResult
			end
		elseif success and type(regResult) == "table" then
			registry = regResult
		end
	end

	local gameInfo = registry[placeId]

	local GameLoader = {
		PlaceId = placeId,
		UniverseId = universeId,
		Info = gameInfo,
		Module = nil,
		LoadError = nil,
		Supported = gameInfo ~= nil,
	}

	function GameLoader.GetDisplayName()
		if GameLoader.Info and GameLoader.Info.Name then
			return GameLoader.Info.Name
		end
		return string.format(SETTINGS.FALLBACK_NAME_FORMAT, placeId)
	end

	function GameLoader.IsSupported()
		return GameLoader.Supported
	end

	function GameLoader.ListSupported()
		local list = {}
		for id, info in pairs(registry) do
			if type(info) == "table" then
				table.insert(list, {
					PlaceId = tostring(id),
					Name = info.Name or tostring(id),
					Description = info.Description or "",
				})
			end
		end
		table.sort(list, function(a, b)
			return a.Name < b.Name
		end)
		return list
	end

	function GameLoader.Load()
		if not GameLoader.Supported then
			return nil
		end
		if GameLoader.Module then
			return GameLoader.Module
		end

		local targetName = GameLoader.Info and (GameLoader.Info.Folder or GameLoader.Info.Name) or placeId
		local cleanName = targetName:gsub("%s+", "")

		local pathsToTry = {
			string.format("src/Games/%s.lua", placeId),
			string.format("src/Games/%s.lua", cleanName),
			string.format("src/Games/%s.lua", targetName),
			string.format(SETTINGS.PATHS.MODULE_SINGLE, targetName),
			string.format(SETTINGS.PATHS.MODULE_SINGLE, cleanName),
			string.format(SETTINGS.PATHS.MODULE_INIT, targetName),
			string.format("src/Games/%s/init.lua", placeId),
		}

		local lastErr = ""

		if type(import) == "function" then
			for _, path in ipairs(pathsToTry) do
				local success, factory = pcall(import, path, true)
				if success and factory then
					local resolvedModule = factory
					if type(factory) == "function" then
						local runSuccess, runResult = pcall(factory, Context)
						if runSuccess then
							resolvedModule = runResult
						else
							lastErr = tostring(runResult)
							resolvedModule = nil
						end
					end

					if type(resolvedModule) == "table" then
						GameLoader.Module = resolvedModule
						GameLoader.LoadError = nil
						return resolvedModule
					end
				else
					if factory then lastErr = tostring(factory) end
				end
			end
		end

		GameLoader.LoadError = lastErr ~= "" and lastErr or SETTINGS.ERRORS.REGISTRY_UNAVAILABLE
		GameLoader.Module = nil
		return nil
	end

	function GameLoader.BuildUI(tab)
		local mod = GameLoader.Load()
		if mod and type(mod.BuildUI) == "function" then
			local success, err = pcall(mod.BuildUI, tab)
			if not success then
				return false, tostring(err)
			end
			return true
		end
		return false, GameLoader.LoadError or SETTINGS.ERRORS.BUILD_UI_MISSING
	end

	function GameLoader.Update(dt)
		if GameLoader.Module and type(GameLoader.Module.Update) == "function" then
			pcall(GameLoader.Module.Update, dt)
		end
	end

	function GameLoader.Destroy()
		if GameLoader.Module and type(GameLoader.Module.Destroy) == "function" then
			pcall(GameLoader.Module.Destroy)
		end
		GameLoader.Module = nil
		GameLoader.LoadError = nil
	end

	return GameLoader
end

-- // src/Games/Loader.lua
return function(Context, import)
	local placeId = tostring(game.PlaceId)

	local registry = {
		["155615604"] = {
			Name = "Prison Life",
			Folder = "155615604",
			Description = "Door phasing, gun grabbers, weapon mods",
		},
	}

	if type(import) == "function" then
		local ok, regFactory = pcall(import, "src/Games/Registry.lua", true)
		if ok and type(regFactory) == "function" then
			local ok2, reg = pcall(regFactory)
			if ok2 and type(reg) == "table" then registry = reg end
		elseif ok and type(regFactory) == "table" then
			registry = regFactory
		end
	end

	local info = registry[placeId]

	local GameLoader = {
		PlaceId = placeId,
		UniverseId = tostring(game.GameId),
		Info = info,
		Module = nil,
		LoadError = nil,
		Supported = info ~= nil,
	}

	function GameLoader.GetDisplayName()
		return (GameLoader.Info and GameLoader.Info.Name) or ("Universal (" .. placeId .. ")")
	end

	function GameLoader.IsSupported()
		return GameLoader.Info ~= nil
	end

	function GameLoader.Load()
		if GameLoader.Module then return GameLoader.Module end
		if not GameLoader.Info then
			GameLoader.LoadError = "Unsupported place"
			return nil
		end
		if type(import) ~= "function" then
			GameLoader.LoadError = "Import unavailable"
			return nil
		end

		-- Folder layout: src/Games/<placeId>/init.lua
		local folder = GameLoader.Info.Folder or placeId
		local paths = {
			string.format("src/Games/%s/init.lua", folder),
			string.format("src/Games/%s.lua", folder),
		}

		for _, path in ipairs(paths) do
			local ok, factory = pcall(import, path, true)
			if ok and factory then
				local mod = factory
				if type(factory) == "function" then
					local ok2, result = pcall(factory, Context)
					if ok2 then mod = result end
				end
				if type(mod) == "table" then
					GameLoader.Module = mod
					GameLoader.LoadError = nil
					return mod
				end
			end
		end

		GameLoader.LoadError = "Module load failed"
		return nil
	end

	function GameLoader.BuildUI(tab)
		local mod = GameLoader.Load()
		if mod and type(mod.BuildUI) == "function" then
			local ok, err = pcall(mod.BuildUI, tab)
			if not ok then return false, tostring(err) end
			return true
		end
		return false, GameLoader.LoadError or "No BuildUI"
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
	end

	return GameLoader
end

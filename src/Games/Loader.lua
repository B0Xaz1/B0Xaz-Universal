-- src/Games/Loader.lua
return function(Context, import)
	local Registry = import("src/Games/Registry.lua")()
	local placeId = tostring(game.PlaceId)

	local GameLoader = {
		PlaceId = placeId,
		UniverseId = tostring(game.GameId),
		Info = Registry[placeId],
		Module = nil,
		LoadError = nil,
		Supported = Registry[placeId] ~= nil,
	}

	function GameLoader.GetDisplayName()
		if GameLoader.Info then
			return GameLoader.Info.Name
		end
		return "Unknown Game (" .. placeId .. ")"
	end

	function GameLoader.IsSupported()
		return GameLoader.Supported
	end

	function GameLoader.ListSupported()
		local list = {}
		for id, info in pairs(Registry) do
			table.insert(list, { PlaceId = id, Name = info.Name, Description = info.Description or "" })
		end
		table.sort(list, function(a, b) return a.Name < b.Name end)
		return list
	end

	function GameLoader.Load()
		if not GameLoader.Supported then
			return nil
		end

		local folder = GameLoader.Info.Folder or placeId
		local path = "src/Games/" .. folder .. "/init.lua"

		local ok, result = pcall(function()
			local factory = import(path)
			if type(factory) == "function" then
				return factory(Context)
			end
			return factory
		end)

		if ok and type(result) == "table" then
			GameLoader.Module = result
			GameLoader.LoadError = nil
			return result
		end

		GameLoader.LoadError = tostring(result)
		warn("[B0Xaz GameLoader] Error loading " .. path .. ": " .. tostring(result))
		GameLoader.Module = nil
		return nil
	end

	function GameLoader.BuildUI(tab)
		if GameLoader.Module and type(GameLoader.Module.BuildUI) == "function" then
			local ok, err = pcall(function()
				GameLoader.Module.BuildUI(tab)
			end)
			if not ok then
				warn("[B0Xaz GameLoader] Error building UI: " .. tostring(err))
				return false, tostring(err)
			end
			return true
		end
		return false, GameLoader.LoadError or "Module missing or no BuildUI function"
	end

	function GameLoader.Update(dt)
		if GameLoader.Module and type(GameLoader.Module.Update) == "function" then
			pcall(function() GameLoader.Module.Update(dt) end)
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

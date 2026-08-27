export type IGamePlugin = {
	Name: string,
	Initialize: (self: IGamePlugin, services: any) -> (),
	BuildUI: (self: IGamePlugin, tab: any) -> (),
	Destroy: (self: IGamePlugin) -> (),
}

return function(services: any)
	local Require = services:Get("Require")
	local Disposer = services:Get("Disposer")
	local PluginRegistry = Require("src/Plugins/PluginRegistry.luau")

	-- The manifest is resolved once at boot from the current Place/Universe id
	local activeManifest = PluginRegistry.Resolve(game.PlaceId, game.GameId)
	local activePluginInstance: IGamePlugin? = nil

	local PluginManager = {}

	function PluginManager:IsGameSupported(): boolean
		return activeManifest ~= nil
	end

	function PluginManager:GetActivePluginName(): string
		if activeManifest then
			return activeManifest.Name
		end
		return "Universal Mode"
	end

	function PluginManager:MountUI(tab: any)
		if activePluginInstance and typeof(activePluginInstance.BuildUI) == "function" then
			pcall(activePluginInstance.BuildUI, activePluginInstance, tab)
		end
	end

	function PluginManager:Initialize()
		if not activeManifest then return end

		local factory = Require(activeManifest.PluginModule)
		if typeof(factory) == "function" then
			local instance = factory(services)
			if typeof(instance) == "table" then
				activePluginInstance = instance
				if typeof(instance.Initialize) == "function" then
					instance:Initialize(services)
				end
			end
		end
	end

	function PluginManager:Destroy()
		if activePluginInstance and typeof(activePluginInstance.Destroy) == "function" then
			pcall(activePluginInstance.Destroy, activePluginInstance)
		end
		activePluginInstance = nil
	end

	Disposer:Add(function()
		PluginManager:Destroy()
	end)

	return PluginManager
end

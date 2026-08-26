--[[
    B0XazUniversal . Plugins/PluginManager.luau
    Plugin loader & lifecycle coordinator
    ----------------------------------------
    On boot: PluginRegistry.Resolve(placeId); if a plugin matches, mount
    its module list in declared order and drive Init -> Start -> Stop.
    Plugins may inject their own UI section through GameTab.

    Exposes:
        Boot()                     resolve + load active plugin (once)
        IsActive()                 -> boolean
        GetActive()                -> definition | nil
        Stop()                     run plugin teardown via Disposer
        OnGameChanged()            TeleportService hook -> re-resolve

    Lifecycle per plugin module: Init(ctx) -> Start(ctx) -> Stop()

    Status: SCAFFOLD
]]

local PluginManager = {}

function PluginManager.Boot()
    error("[PluginManager.Boot] not implemented (scaffold)", 2)
end

function PluginManager.IsActive(): boolean
    error("[PluginManager.IsActive] not implemented (scaffold)", 2)
end

function PluginManager.GetActive()
    error("[PluginManager.GetActive] not implemented (scaffold)", 2)
end

function PluginManager.Stop()
    error("[PluginManager.Stop] not implemented (scaffold)", 2)
end

return PluginManager

--[[
    B0XazUniversal . Plugins/PluginRegistry.luau
    O(1) PlaceId & UniverseId hash-lookup registry
    ----------------------------------------
    Static declaration of every game-specific plugin. Lookup is two flat
    hash reads (placeId -> universeId -> plugin), never a linear scan.

    Exposes:
        Register(universeId, definition)   declare plugin for a universe
        Alias(placeId, universeId)         map extra placeIds onto a universe
        Resolve(placeId)                   -> plugin definition | nil (O(1))
        All()                              -> { universeId: definition }

    Definition shape:
        { id, name, universeId, places = { placeId }, modules = { ... } }

    Status: SCAFFOLD
]]

local PluginRegistry = {}

-- placeId -> universeId, universeId -> definition
local placeIndex: { [number]: number } = {}
local universeIndex: { [number]: any } = {}

function PluginRegistry.Register(universeId: number, definition: any)
    error("[PluginRegistry.Register] not implemented (scaffold)", 2)
end

function PluginRegistry.Alias(placeId: number, universeId: number)
    error("[PluginRegistry.Alias] not implemented (scaffold)", 2)
end

function PluginRegistry.Resolve(placeId: number): any?
    error("[PluginRegistry.Resolve] not implemented (scaffold)", 2)
end

function PluginRegistry.All(): { [number]: any }
    error("[PluginRegistry.All] not implemented (scaffold)", 2)
end

return PluginRegistry

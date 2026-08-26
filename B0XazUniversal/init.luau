--[[
    B0XazUniversal . init.luau
    Unified Bootstrap & Startup Orchestrator
    ----------------------------------------
    Single entry point for the whole runtime. Loads every module in
    deterministic phases so dependencies always resolve before consumers.

    Boot order
      0  Environment   Core/Environment                       probe executor + capabilities
      1  Core           ServiceContainer, Disposer, EventBus, StateStore, TaskScheduler
      2  Services       KeyService, ConfigService, PlayerTracker, OptimizerService
      3  Subsystems     Locomotion, Combat, Visuals
      4  Interface      DOM, ThemeEngine, UIEngine, Modals, Tabs
      5  Plugins        PluginRegistry, PluginManager

    Status: SCAFFOLD -- boot order defined, execution pending.
]]

local ROOT = script

local Bootstrap = {}

local BOOT_ORDER = {
    { phase = "Environment", modules = {
        "Core/Environment",
    } },
    { phase = "Core", modules = {
        "Core/ServiceContainer",
        "Core/Disposer",
        "Core/EventBus",
        "Core/StateStore",
        "Core/TaskScheduler",
    } },
    { phase = "Services", modules = {
        "Services/KeyService",
        "Services/ConfigService",
        "Services/PlayerTracker",
        "Services/OptimizerService",
    } },
    { phase = "Subsystems", modules = {
        "Locomotion/LocomotionService",
        "Locomotion/FlightService",
        "Combat/TargetFilter",
        "Combat/AimbotService",
        "Combat/TriggerbotService",
        "Visuals/DrawingPool",
        "Visuals/ESPController",
        "Visuals/OverlayController",
    } },
    { phase = "Interface", modules = {
        "UI/DOM",
        "UI/ThemeEngine",
        "UI/UIEngine",
        "UI/Modals/KeyAuthModal",
        "UI/Modals/ConfigShareModal",
        "UI/Tabs/CombatTab",
        "UI/Tabs/VisualsTab",
        "UI/Tabs/MovementTab",
        "UI/Tabs/PlayersTab",
        "UI/Tabs/UtilityTab",
        "UI/Tabs/GameTab",
        "UI/Tabs/SettingsTab",
    } },
    { phase = "Plugins", modules = {
        "Plugins/PluginRegistry",
        "Plugins/PluginManager",
    } },
}

-- Bootstrap.Run() : execute every phase in order, halting on first failure.
function Bootstrap.Run()
    error("[init.Bootstrap.Run] not implemented (scaffold)", 2)
end

-- Bootstrap.Shutdown() : dispose every phase in reverse dependency order.
function Bootstrap.Shutdown()
    error("[init.Bootstrap.Shutdown] not implemented (scaffold)", 2)
end

return Bootstrap

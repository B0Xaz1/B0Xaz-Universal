--[[
    B0XazUniversal . UI/Tabs/CombatTab.luau
    Aimbot, FOV, WindMouse, Prediction, Triggerbot controls
    ----------------------------------------
    Presenter contract (Model-View-Presenter): tabs never touch services
    directly. They read/write StateStore paths and mount Components that
    are bound to ConfigService schema entries; reactive side effects live
    in subsystem services, not in the view.

    Exposes:
        Mount(UIEngine, StateStore)   -> TabHandle
        TabHandle.Root                container Instance
        TabHandle.OnShown() / OnHidden()   lifecycle hooks

    Status: SCAFFOLD
]]

local CombatTab = {}

function CombatTab.Mount(UIEngine: any, StateStore: any)
    error("[CombatTab.Mount] not implemented (scaffold)", 2)
end

return CombatTab

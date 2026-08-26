--[[
    B0XazUniversal . UI/Tabs/UtilityTab.luau
    Performance boosters, hitboxes, spinbot, server hopper
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

local UtilityTab = {}

function UtilityTab.Mount(UIEngine: any, StateStore: any)
    error("[UtilityTab.Mount] not implemented (scaffold)", 2)
end

return UtilityTab

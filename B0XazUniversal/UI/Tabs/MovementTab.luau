--[[
    B0XazUniversal . UI/Tabs/MovementTab.luau
    Speed, jump, flight parameters, position bookmarks
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

local MovementTab = {}

function MovementTab.Mount(UIEngine: any, StateStore: any)
    error("[MovementTab.Mount] not implemented (scaffold)", 2)
end

return MovementTab

--[[
    B0XazUniversal . UI/Tabs/PlayersTab.luau
    Player list, search filter, whitelist, spectate & fling controls
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

local PlayersTab = {}

function PlayersTab.Mount(UIEngine: any, StateStore: any)
    error("[PlayersTab.Mount] not implemented (scaffold)", 2)
end

return PlayersTab

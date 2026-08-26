--[[
    B0XazUniversal . UI/Components/Keybind.luau
    Key capture control supporting mouse buttons + modifier combos + toggle/hold modes
    ----------------------------------------
    Component contract (all Components follow it):
        New(parent, props)      -> Handle
        Handle:Set(value)       programmatic write (no OnChange re-emit loop)
        Handle:Get()            -> current value
        Handle:OnChange(cb)     subscribe to user-driven changes
        Handle:Destroy()        clean teardown via Disposer

    props always includes: { Label, BindPath (StateStore path), Default }

    Status: SCAFFOLD
]]

local Keybind = {}

function Keybind.New(parent: Instance, props: { [string]: any })
    error("[Keybind.New] not implemented (scaffold)", 2)
end

return Keybind

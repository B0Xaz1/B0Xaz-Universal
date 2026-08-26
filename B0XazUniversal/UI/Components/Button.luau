--[[
    B0XazUniversal . UI/Components/Button.luau
    Action button with hover/press states, optional confirmation + icon
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

local Button = {}

function Button.New(parent: Instance, props: { [string]: any })
    error("[Button.New] not implemented (scaffold)", 2)
end

return Button

--[[
    B0XazUniversal . UI/Components/Textbox.luau
    Validated text input (number, hex, any) with placeholder + focus styling
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

local Textbox = {}

function Textbox.New(parent: Instance, props: { [string]: any })
    error("[Textbox.New] not implemented (scaffold)", 2)
end

return Textbox

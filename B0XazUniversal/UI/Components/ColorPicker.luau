--[[
    B0XazUniversal . UI/Components/ColorPicker.luau
    HSB color picker + hex input + preset swatches + alpha slider
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

local ColorPicker = {}

function ColorPicker.New(parent: Instance, props: { [string]: any })
    error("[ColorPicker.New] not implemented (scaffold)", 2)
end

return ColorPicker

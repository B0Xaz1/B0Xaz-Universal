--[[
    B0XazUniversal . UI/Components/Slider.luau
    Numeric drag slider with min/max/step/rounding precision, optional suffix textbox
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

local Slider = {}

function Slider.New(parent: Instance, props: { [string]: any })
    error("[Slider.New] not implemented (scaffold)", 2)
end

return Slider

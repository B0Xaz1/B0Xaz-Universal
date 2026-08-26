--[[
    B0XazUniversal . UI/DOM.luau
    Fast ASCII byte element constructor, stroke/padding builders
    ----------------------------------------
    Declarative Instance builder: tag strings and property keys are
    matched via byte comparisons (string.byte) instead of string.match,
    keeping construction cost minimal for bulk UI generation.

    Exposes:
        New(tag, props, children)     tag like "Frame" / "TextButton"
        Stroke(parent, props)         UIStroke builder
        Padding(parent, props)        UIPadding builder
        Corner(parent, radius)        UICorner builder
        Clear(parent)                 destroy children
        ByteKey(prop)                 fast prop-name interning (internal)

    Status: SCAFFOLD
]]

local DOM = {}

function DOM.New(tag: string, props: { [string]: any }?, children: { Instance }?): Instance
    error("[DOM.New] not implemented (scaffold)", 2)
end

function DOM.Stroke(parent: Instance, props: { [string]: any }?): UIStroke
    error("[DOM.Stroke] not implemented (scaffold)", 2)
end

function DOM.Padding(parent: Instance, props: { [string]: any }): UIPadding
    error("[DOM.Padding] not implemented (scaffold)", 2)
end

function DOM.Corner(parent: Instance, radius: number): UICorner
    error("[DOM.Corner] not implemented (scaffold)", 2)
end

function DOM.Clear(parent: Instance)
    error("[DOM.Clear] not implemented (scaffold)", 2)
end

return DOM

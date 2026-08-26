--[[
    B0XazUniversal . UI/UIEngine.luau
    Window manager, DraggableComponent controller, Toast notifications
    ----------------------------------------
    Owns the ScreenGui root, window instances, tab switching, focus /
        unfocus keybind, and the drag system (delta-based, DPI safe).
    Toasts stack bottom-right with auto-expiry and levels.

    Exposes:
        CreateWindow(config)         title, size, keybind, theme, resizable
        CreateTab(name, icon?)       -> tab mount point (presenter target)
        MakeDragable(handle, frame)  register draggable component
        Toast(message, level?)       "info" | "success" | "warn" | "error"
        Toggle(visible?)             show/hide window
        SetScale(scale)              UIScale multiplier (Settings tab)

    Status: SCAFFOLD
]]

local UIEngine = {}

function UIEngine.CreateWindow(config: { [string]: any })
    error("[UIEngine.CreateWindow] not implemented (scaffold)", 2)
end

function UIEngine.CreateTab(name: string, icon: string?)
    error("[UIEngine.CreateTab] not implemented (scaffold)", 2)
end

function UIEngine.MakeDragable(handle: Instance, frame: Instance)
    error("[UIEngine.MakeDragable] not implemented (scaffold)", 2)
end

function UIEngine.Toast(message: string, level: string?)
    error("[UIEngine.Toast] not implemented (scaffold)", 2)
end

function UIEngine.Toggle(visible: boolean?)
    error("[UIEngine.Toggle] not implemented (scaffold)", 2)
end

function UIEngine.SetScale(scale: number)
    error("[UIEngine.SetScale] not implemented (scaffold)", 2)
end

return UIEngine

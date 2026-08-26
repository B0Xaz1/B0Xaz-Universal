--[[
    B0XazUniversal . UI/Modals/KeyAuthModal.luau
    License key verification dialog
    ----------------------------------------
    Full-screen overlay shown pre-verification. Key entry -> KeyService.Verify;
    surfaces pending / denied / expired states and a paste-from-clipboard
    affordance. Auto-dismisses into the main window on success.

    Exposes:
        Mount(parent)               build + show modal
        Unmount()                   destroy (on verified)
        SetState(state, message?)   "pending" | "denied" | "expired"

    Status: SCAFFOLD
]]

local KeyAuthModal = {}

function KeyAuthModal.Mount(parent: Instance)
    error("[KeyAuthModal.Mount] not implemented (scaffold)", 2)
end

function KeyAuthModal.Unmount()
    error("[KeyAuthModal.Unmount] not implemented (scaffold)", 2)
end

function KeyAuthModal.SetState(state: string, message: string?)
    error("[KeyAuthModal.SetState] not implemented (scaffold)", 2)
end

return KeyAuthModal

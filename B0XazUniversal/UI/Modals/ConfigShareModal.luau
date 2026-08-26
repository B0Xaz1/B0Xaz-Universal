--[[
    B0XazUniversal . UI/Modals/ConfigShareModal.luau
    Two-way JSON import & clipboard export modal
    ----------------------------------------
    Export: ConfigService.Serialize() -> clipboard via Environment.
    Import: paste JSON -> schema validation -> apply, with a diff preview
    before commit. Errors render inline (bad key, out-of-bounds, etc.).

    Exposes:
        Mount(parent)               build + show modal
        Unmount()                   destroy
        ExportToClipboard()         copy current profile JSON
        ImportFromText(json)        -> ok, err (validated apply)

    Status: SCAFFOLD
]]

local ConfigShareModal = {}

function ConfigShareModal.Mount(parent: Instance)
    error("[ConfigShareModal.Mount] not implemented (scaffold)", 2)
end

function ConfigShareModal.Unmount()
    error("[ConfigShareModal.Unmount] not implemented (scaffold)", 2)
end

function ConfigShareModal.ExportToClipboard()
    error("[ConfigShareModal.ExportToClipboard] not implemented (scaffold)", 2)
end

function ConfigShareModal.ImportFromText(json: string): (boolean, string?)
    error("[ConfigShareModal.ImportFromText] not implemented (scaffold)", 2)
end

return ConfigShareModal

--[[
    B0XazUniversal . Services/KeyService.luau
    Supabase License Validator, HWID, native C-Crypt persistence
    ----------------------------------------
    Verifies license keys against the Supabase edge function, binds them
    to a Hardware ID, and persists the session grant locally encrypted
    via Environment.Crypt. Resolved tier feeds StateStore.SetTier.

    Exposes:
        Verify(key)               async check -> tier (yields)
        HasSession()              -> boolean (valid cached grant)
        GetTier()                 -> number (0 = free / unlicensed)
        GetLicenseInfo()          -> { expiry, key, tier, hwid }
        Logout()                  clear persisted grant
        Events                    "Verified" | "Denied" | "Expired" via EventBus

    Status: SCAFFOLD
]]

local KeyService = {}

function KeyService.Verify(key: string): number
    error("[KeyService.Verify] not implemented (scaffold)", 2)
end

function KeyService.HasSession(): boolean
    error("[KeyService.HasSession] not implemented (scaffold)", 2)
end

function KeyService.GetTier(): number
    error("[KeyService.GetTier] not implemented (scaffold)", 2)
end

function KeyService.GetLicenseInfo()
    error("[KeyService.GetLicenseInfo] not implemented (scaffold)", 2)
end

function KeyService.Logout()
    error("[KeyService.Logout] not implemented (scaffold)", 2)
end

return KeyService

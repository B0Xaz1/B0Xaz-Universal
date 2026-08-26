--[[
    B0XazUniversal . Core/Environment.luau
    Platform API Bridge
    ----------------------------------------
    Normalizes the host executor surface into one interface so no other
    module ever branches on exploit-specific globals.

    Exposes:
        Probe()          resolve executor name / version / identity / capabilities
        Request(...)     unified HTTP bridge (syn.request / http_request / request)
        Crypt()          C-crypto bridge (AES / HMAC / Hash / Random) + Lua fallback
        Input()          unified mouse + keyboard surface
        HWID()           stable hardware fingerprint for KeyService
        Save / Load      C-encrypted local persistence helpers

    Status: SCAFFOLD
]]

local Environment = {}

export type ExecutorInfo = {
    name: string,
    version: string,
    identity: number,
    capabilities: {
        request: boolean,
        crypt: boolean,
        cloneref: boolean,
        filesystem: boolean,
        clipboard: boolean,
    },
}

local executor: ExecutorInfo? = nil

function Environment.Probe(): ExecutorInfo
    error("[Environment.Probe] not implemented (scaffold)", 2)
end

function Environment.Request(url: string, method: string?, body: string?, headers: { [string]: string }?)
    error("[Environment.Request] not implemented (scaffold)", 2)
end

function Environment.Crypt()
    -- -> { Encrypt, Decrypt, Hash, Hmac, Random }
    error("[Environment.Crypt] not implemented (scaffold)", 2)
end

function Environment.Input()
    -- -> { MousePos, MouseTarget, IsButtonDown, IsKeyDown, OnKey }
    error("[Environment.Input] not implemented (scaffold)", 2)
end

function Environment.HWID(): string
    error("[Environment.HWID] not implemented (scaffold)", 2)
end

function Environment.Save(key: string, payload: string)
    error("[Environment.Save] not implemented (scaffold)", 2)
end

function Environment.Load(key: string): string?
    error("[Environment.Load] not implemented (scaffold)", 2)
end

return Environment

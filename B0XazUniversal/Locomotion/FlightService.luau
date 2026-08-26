--[[
    B0XazUniversal . Locomotion/FlightService.luau
    Modern Constraint Flight (LinearVelocity) with Gyro fallbacks
    ----------------------------------------
    Primary path: LinearVelocity + AlignOrientation (modern constraints).
    Legacy path:  BodyVelocity + BodyGyro when constraints are filtered.
    Selection is automatic per-environment and cached for the session.

    Exposes:
        SetEnabled(enabled)       toggle flight (spawns/destroys rig)
        SetSpeed(studs)           vertical + planar velocity budget
        SetStyle(style)           "Constraint" | "Legacy" | "Auto"
        IsFlying()                -> boolean
        HandleInput(delta)        direction vector from bound keys

    Status: SCAFFOLD
]]

local FlightService = {}

function FlightService.SetEnabled(enabled: boolean)
    error("[FlightService.SetEnabled] not implemented (scaffold)", 2)
end

function FlightService.SetSpeed(studs: number)
    error("[FlightService.SetSpeed] not implemented (scaffold)", 2)
end

function FlightService.SetStyle(style: string)
    error("[FlightService.SetStyle] not implemented (scaffold)", 2)
end

function FlightService.IsFlying(): boolean
    error("[FlightService.IsFlying] not implemented (scaffold)", 2)
end

function FlightService.HandleInput(delta: number)
    error("[FlightService.HandleInput] not implemented (scaffold)", 2)
end

return FlightService

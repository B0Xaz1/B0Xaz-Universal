--[[
    B0XazUniversal . Locomotion/LocomotionService.luau
    Speed, JumpPower, InfJump, CFrame displacement, Fling & TP
    ----------------------------------------
    Applies movement mutations through a single per-frame writer so
    features never fight over the Humanoid. Restores originals on disable.

    Exposes:
        SetSpeed(studs)            WalkSpeed override (0 = restore)
        SetJumpPower(power)        JumpPower / UseJumpPower override
        SetInfJump(enabled)        zero-gravity window jump loop
        Displace(offsetCFrame)     direct CFrame translation (no physics)
        Fling(target, power)       velocity impulse fling on a player
        Teleport(cframe | player)  CFramed teleport (self or target)
        RestoreAll()               undo every mutation

    Status: SCAFFOLD
]]

local LocomotionService = {}

function LocomotionService.SetSpeed(studs: number)
    error("[LocomotionService.SetSpeed] not implemented (scaffold)", 2)
end

function LocomotionService.SetJumpPower(power: number)
    error("[LocomotionService.SetJumpPower] not implemented (scaffold)", 2)
end

function LocomotionService.SetInfJump(enabled: boolean)
    error("[LocomotionService.SetInfJump] not implemented (scaffold)", 2)
end

function LocomotionService.Displace(offsetCFrame: CFrame)
    error("[LocomotionService.Displace] not implemented (scaffold)", 2)
end

function LocomotionService.Fling(target: Player, power: number)
    error("[LocomotionService.Fling] not implemented (scaffold)", 2)
end

function LocomotionService.Teleport(destination: any)
    error("[LocomotionService.Teleport] not implemented (scaffold)", 2)
end

function LocomotionService.RestoreAll()
    error("[LocomotionService.RestoreAll] not implemented (scaffold)", 2)
end

return LocomotionService

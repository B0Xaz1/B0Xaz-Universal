--[[
    B0XazUniversal . Visuals/OverlayController.luau
    FOV circle, non-allocating Speedlines, FPS & Ping telemetry
    ----------------------------------------
    RenderStepped overlay layer. FOV circle tracks the aimbot window.
    Speedlines reuse a fixed Drawing array -- positions are mutated in
    place, never re-created. Telemetry keeps rolling averages.

    Exposes:
        SetFovCircle(enabled, radius?)   sync with AimbotService config
        SetSpeedlines(enabled, params)
        SetTelemetry(enabled)            FPS / ping watermark
        Update(dt)                       scheduler tick (RenderStepped)

    Status: SCAFFOLD
]]

local OverlayController = {}

function OverlayController.SetFovCircle(enabled: boolean, radius: number?)
    error("[OverlayController.SetFovCircle] not implemented (scaffold)", 2)
end

function OverlayController.SetSpeedlines(enabled: boolean, params: { [string]: any }?)
    error("[OverlayController.SetSpeedlines] not implemented (scaffold)", 2)
end

function OverlayController.SetTelemetry(enabled: boolean)
    error("[OverlayController.SetTelemetry] not implemented (scaffold)", 2)
end

function OverlayController.Update(dt: number)
    error("[OverlayController.Update] not implemented (scaffold)", 2)
end

return OverlayController

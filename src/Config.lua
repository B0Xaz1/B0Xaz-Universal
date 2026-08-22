-- src/Config.lua
return function()
    local Lighting = game:GetService("Lighting")

    local CONFIG = {
        AIM_SETTLE_FRAMES = 0,
        AIM_DEADZONE = 0.5,
        AIM_MAX_STEP = 25,
        AIM_MIN_SMOOTHNESS = 1,

        ESP_TRACER_THICKNESS = 1.5,
        ESP_SKELETON_THICKNESS = 1,
        ESP_TEXT_SIZE_NAME = 13,
        ESP_TEXT_SIZE_DIST = 11,

        SPEED_LINES_COUNT = 30,
        SPEED_LINES_MIN_DIST = 150,
        SPEED_LINES_MAX_DIST = 500,
        SPEED_LINES_SPAWN_MIN = 50,
        SPEED_LINES_SPAWN_MAX = 150,
        SPEED_LINES_SPEED = 600,
        SPEED_LINES_MAX_RANGE = 700,
        SPEED_LINES_LENGTH = 60,

        FOLDER = "B0XazUniversal",
        EXT = ".json",
        UI_W = 660,
        UI_H = 460,
        UI_TITLEBAR_H = 28,
        DROPDOWN_ROW_HEIGHT = 22,
        DROPDOWN_MAX_ROWS = 6,
        NOTIFY_DEFAULT_TIME = 3.5,
        CONFIG_NAME_MAX_LEN = 40,
    }

    if not getgenv().B0XazDefaultLighting then
        getgenv().B0XazDefaultLighting = {
            FogEnd = Lighting.FogEnd,
            FogStart = Lighting.FogStart,
            FogColor = Lighting.FogColor,
            GlobalShadows = Lighting.GlobalShadows,
            Ambient = Lighting.Ambient,
            Brightness = Lighting.Brightness,
            OutdoorAmbient = Lighting.OutdoorAmbient,
            ClockTime = Lighting.ClockTime
        }
    end

    return CONFIG, getgenv().B0XazDefaultLighting
end

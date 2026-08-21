-- src/UI/Theme.lua
return function()
    return {
        -- Backgrounds
        Bg = Color3.fromRGB(18, 18, 20),
        Panel = Color3.fromRGB(26, 26, 30),
        Elem = Color3.fromRGB(32, 32, 38),
        ElemHover = Color3.fromRGB(42, 42, 50),
        Side = Color3.fromRGB(22, 22, 26),

        -- Accent (cyan — less "AI purple")
        Accent = Color3.fromRGB(0, 200, 220),
        AccentDark = Color3.fromRGB(0, 140, 160),
        AccentDim = Color3.fromRGB(0, 90, 105),

        -- Text
        Text = Color3.fromRGB(225, 225, 230),
        TextDim = Color3.fromRGB(145, 145, 155),
        TextMuted = Color3.fromRGB(95, 95, 105),

        -- Borders (gray, not full accent)
        Border = Color3.fromRGB(55, 55, 65),
        BorderDim = Color3.fromRGB(40, 40, 48),

        -- Toggle
        ToggleOff = Color3.fromRGB(40, 40, 48),
        ToggleOn = Color3.fromRGB(0, 200, 220),

        -- Status
        Success = Color3.fromRGB(90, 200, 120),
        Danger = Color3.fromRGB(220, 80, 80),
        Warning = Color3.fromRGB(230, 175, 70),
    }
end

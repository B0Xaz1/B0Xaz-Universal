-- src/UI/Theme.lua
return function()
    return {
        Bg = Color3.fromRGB(14, 14, 18), Side = Color3.fromRGB(18, 18, 24),
        Panel = Color3.fromRGB(22, 22, 28), Elem = Color3.fromRGB(30, 30, 38),
        ElemHover = Color3.fromRGB(38, 38, 48), Accent = Color3.fromRGB(0, 160, 255),
        AccentDark = Color3.fromRGB(0, 100, 170), Text = Color3.fromRGB(235, 235, 240),
        TextDim = Color3.fromRGB(155, 155, 170), TextMuted = Color3.fromRGB(100, 100, 115),
        Border = Color3.fromRGB(38, 38, 50), ToggleOff = Color3.fromRGB(50, 50, 65),
        ToggleOn = Color3.fromRGB(0, 160, 255), Success = Color3.fromRGB(70, 185, 105),
        Danger = Color3.fromRGB(220, 75, 75),
    }
end

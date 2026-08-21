-- src/UI/Theme.lua
return function()
    return {
        -- Backgrounds
        Bg = Color3.fromRGB(20, 20, 22),           -- Main window background (near-black)
        Panel = Color3.fromRGB(28, 28, 32),        -- Section box background
        Elem = Color3.fromRGB(34, 34, 40),         -- Input fields (textbox, dropdown, slider track)
        ElemHover = Color3.fromRGB(44, 44, 52),    -- Hover state for elements
        Side = Color3.fromRGB(24, 24, 28),         -- Title bar / tab strip background

        -- Accent (Purple)
        Accent = Color3.fromRGB(163, 102, 255),    -- Primary purple (checkboxes, sliders, active tab)
        AccentDark = Color3.fromRGB(120, 70, 200), -- Darker purple (borders, subtle highlights)
        AccentDim = Color3.fromRGB(80, 50, 130),   -- Very dim purple (inactive borders)

        -- Text
        Text = Color3.fromRGB(230, 230, 235),      -- Main text
        TextDim = Color3.fromRGB(150, 150, 160),   -- Section titles, inactive tabs
        TextMuted = Color3.fromRGB(95, 95, 105),   -- Placeholder text, disabled labels

        -- Borders
        Border = Color3.fromRGB(163, 102, 255),    -- Section box borders (purple, matches accent)
        BorderDim = Color3.fromRGB(60, 60, 70),    -- Subtle dividers

        -- Toggle States
        ToggleOff = Color3.fromRGB(40, 40, 48),    -- Checkbox empty fill
        ToggleOn = Color3.fromRGB(163, 102, 255),  -- Checkbox filled (purple)

        -- Status Colors
        Success = Color3.fromRGB(120, 200, 130),   -- Green for success notifications
        Danger = Color3.fromRGB(220, 90, 90),      -- Red for errors
        Warning = Color3.fromRGB(230, 180, 90),    -- Yellow for warnings
    }
end

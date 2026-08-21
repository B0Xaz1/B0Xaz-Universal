-- src/UI/BuildUI.lua
return function(Context)
    local Players = game:GetService("Players")
    local Workspace = game:GetService("Workspace")
    local Lighting = game:GetService("Lighting")
    local UIS = game:GetService("UserInputService")
    local HttpService = game:GetService("HttpService")

    local LocalPlayer = Players.LocalPlayer
    local Camera = Workspace.CurrentCamera
    local IsMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled

    -- Extract from Context
    local CONFIG = Context.CONFIG
    local UIEngine = Context.UIEngine
    local Theme = Context.Theme
    local FeatureConfig = Context.FeatureConfig
    local State = Context.State
    local StatsConfig = Context.StatsConfig
    local UIRegistry = Context.UIRegistry
    local Utils = Context.Utils
    local Connections = Context.Connections
    local DefaultLighting = Context.DefaultLighting

    local AimbotSystem = Context.AimbotSystem
    local ESPSystem = Context.ESPSystem
    local FlySystem = Context.FlySystem
    local FlingSystem = Context.FlingSystem
    local ConfigSystem = Context.ConfigSystem
    local OverlayManager = Context.OverlayManager

    -- Create Main UI Instance using the renamed engine
    local UI = UIEngine.new("B0Xaz Universal")
    Context.UI = UI
    getgenv().B0XazLibrary = UI

    -- Toggle Menu bind
    local _listeningForMenuKey = false
    Connections.Add(UIS.InputBegan:Connect(function(input, processed)
        if _listeningForMenuKey or processed then return end
        if input.KeyCode == State.MenuKeybind then
            State.MenuVisible = not State.MenuVisible
            UI.Main.Visible = State.MenuVisible
        end
    end))

    -- (The rest of BuildUI.lua remains unchanged below this line...)

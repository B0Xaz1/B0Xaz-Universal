-- init.lua
local GITHUB_USER = "B0Xaz1"
local GITHUB_REPO = "B0Xaz-Universal"
local GITHUB_BRANCH = "main"

local BASE_URL = string.format("https://raw.githubusercontent.com/%s/%s/%s/", GITHUB_USER, GITHUB_REPO, GITHUB_BRANCH)
getgenv().B0XazScriptURL = BASE_URL .. "init.lua"

getgenv().B0XazContext = {}
local Context = getgenv().B0XazContext

local function import(path)
    local url = BASE_URL .. path .. "?t=" .. tostring(tick())
    local ok, source = pcall(function()
        return game:HttpGet(url)
    end)

    if not ok or not source or #source == 0 or source:sub(1, 3) == "404" or source:find("404: Not Found") or source:find("<!DOCTYPE html>") then
        error("[B0Xaz Loader] 404 File Not Found: " .. path .. "\nCheck URL: " .. url)
    end

    local chunk, err = loadstring(source, path)
    if not chunk then
        error("[B0Xaz Loader] Syntax Error in " .. path .. " : " .. tostring(err))
    end
    return chunk()
end

print("[B0Xaz] Loading modules...")

-- 1. Full Session Cleanup
import("src/Cleanup.lua")()

-- 2. Base Configurations & Utils
local CONFIG, DefaultLighting = import("src/Config.lua")()
Context.CONFIG = CONFIG
Context.DefaultLighting = DefaultLighting
Context.Utils = import("src/Utils.lua")(CONFIG)
Context.DrawingManager = import("src/DrawingManager.lua")()

-- 3. Context & State Initialization
local ctxData = import("src/Context.lua")(CONFIG, DefaultLighting, Context.Utils, Context.DrawingManager)
for k, v in pairs(ctxData) do Context[k] = v end

-- 4. UI Engine & Theme
Context.Theme = import("src/UI/Theme.lua")()
Context.UIEngine = import("src/UI/UI.lua")(Context, Context.Theme)

if not Context.UIEngine then
    error("[B0Xaz Loader] src/UI/UI.lua failed to return the UI engine!")
end

-- 5. Core Systems
Context.FlingSystem = import("src/Systems/FlingSystem.lua")(Context)
Context.FlySystem = import("src/Systems/FlySystem.lua")(Context)
Context.MovementSystem = import("src/Systems/MovementSystem.lua")(Context)
Context.ESPSystem = import("src/Systems/ESPSystem.lua")(Context)
Context.AimbotSystem = import("src/Systems/AimbotSystem.lua")(Context)
Context.ConfigSystem = import("src/Systems/ConfigSystem.lua")(Context)
Context.PerformanceSystem = import("src/Systems/PerformanceSystem.lua")(Context)
Context.OverlayManager = import("src/Visuals/OverlayManager.lua")(Context)

-- 6. Game Specific Loader
Context.GameLoader = import("src/Games/Loader.lua")(Context, import)
Context.GameModule = Context.GameLoader.Load()

-- 7. Build User Interface
import("src/UI/BuildUI.lua")(Context)

-- 8. Runtime & ESP Loops
Context.ESPSystem.InitializeAll()
import("src/Runtime.lua")(Context)

local gameName = Context.GameLoader.GetDisplayName()
local supportStr = Context.GameLoader.IsSupported() and "Supported Game" or "Universal Mode"
Context.UI:Notify("B0Xaz Universal", gameName .. " (" .. supportStr .. ")", 4, Context.Theme.Success)

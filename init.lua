-- init.lua
local GITHUB_USER = "YOUR_GITHUB_USERNAME"
local GITHUB_REPO = "YOUR_REPOSITORY_NAME"
local GITHUB_BRANCH = "main"

local BASE_URL = string.format("https://raw.githubusercontent.com/%s/%s/%s/", GITHUB_USER, GITHUB_REPO, GITHUB_BRANCH)
getgenv().B0XazScriptURL = BASE_URL .. "init.lua"

local function import(path)
    local url = BASE_URL .. path .. "?t=" .. tostring(os.time())
    local ok, source = pcall(function()
        return game:HttpGet(url)
    end)
    if not ok or not source or #source == 0 then
        error("[B0Xaz Loader] Failed to fetch: " .. path .. " -> " .. tostring(source))
    end
    
    local fn, compileErr = loadstring(source, path)
    if not fn then
        error("[B0Xaz Loader] Syntax error in " .. path .. ": " .. tostring(compileErr))
    end
    return fn
end

-- 1. Initialize Cleanup
import("src/Cleanup.lua")()

-- 2. Load Core Dependencies
local CONFIG, DefaultLighting = import("src/Config.lua")()
local Utils = import("src/Utils.lua")(CONFIG)
local DrawingManager = import("src/DrawingManager.lua")()
local Context = import("src/Context.lua")(CONFIG, DefaultLighting, Utils, DrawingManager)

-- 3. Load UI Engine & Theme
local Theme = import("src/UI/Theme.lua")()
local ShankUI = import("src/UI/ShankUI.lua")(Context, Theme)
Context.Theme = Theme
Context.ShankUI = ShankUI

-- 4. Load Feature Systems
Context.FlingSystem = import("src/Systems/FlingSystem.lua")(Context)
Context.FlySystem = import("src/Systems/FlySystem.lua")(Context)
Context.ESPSystem = import("src/Systems/ESPSystem.lua")(Context)
Context.AimbotSystem = import("src/Systems/AimbotSystem.lua")(Context)
Context.ConfigSystem = import("src/Systems/ConfigSystem.lua")(Context)

-- 5. Load Visual Overlays
Context.OverlayManager = import("src/Visuals/OverlayManager.lua")(Context)

-- 6. Construct UI
Context.UI = import("src/UI/BuildUI.lua")(Context)
getgenv().B0XazLibrary = Context.UI

-- 7. Initialize ESP & Start Runtime Engine
Context.ESPSystem.InitializeAll()
import("src/Runtime.lua")(Context)

Context.UI:Notify("B0Xaz Universal", "Loaded - RShift to toggle menu", 4, Theme.Success)

-- init.lua
local GITHUB_USER = "B0Xaz1"
local GITHUB_REPO = "B0Xaz-Universal"
local GITHUB_BRANCH = "main"

local BASE_URL = string.format("https://raw.githubusercontent.com/%s/%s/%s/", GITHUB_USER, GITHUB_REPO, GITHUB_BRANCH)
getgenv().B0XazScriptURL = BASE_URL .. "init.lua"

-- This is the "Global Table" that fixes the "index function" error
getgenv().B0XazContext = {}
local Context = getgenv().B0XazContext

local function import(path)
    local url = BASE_URL .. path .. "?t=" .. tostring(tick())
    local source = game:HttpGet(url)
    
    if not source or #source == 0 then
        warn("[B0Xaz] Failed to load: " .. path)
        return function() end
    end
    
    local chunk, err = loadstring(source, path)
    if not chunk then
        error("[B0Xaz] Syntax Error in " .. path .. ": " .. tostring(err))
    end
    
    -- Execute the script and return whatever it returns (the constructor function)
    return chunk()
end

print("[B0Xaz] Starting Modules...")

-- 1. Reset previous UI/Connections
import("src/Cleanup.lua")()

-- 2. Load Base Configurations
local CONFIG, DefaultLighting = import("src/Config.lua")()
Context.CONFIG = CONFIG
Context.DefaultLighting = DefaultLighting

-- 3. Load Core Utilities & State
Context.Utils = import("src/Utils.lua")(CONFIG)
Context.DrawingManager = import("src/DrawingManager.lua")()

-- 4. Load the Context (FeatureConfig, State, etc.)
local ctxData = import("src/Context.lua")(CONFIG, DefaultLighting, Context.Utils, Context.DrawingManager)
for k, v in pairs(ctxData) do Context[k] = v end

-- 5. Load Visuals & Theme
Context.Theme = import("src/UI/Theme.lua")()
Context.OverlayManager = import("src/Visuals/OverlayManager.lua")(Context)

-- 6. Load Systems
Context.FlingSystem = import("src/Systems/FlingSystem.lua")(Context)
Context.FlySystem = import("src/Systems/FlySystem.lua")(Context)
Context.ESPSystem = import("src/Systems/ESPSystem.lua")(Context)
Context.AimbotSystem = import("src/Systems/AimbotSystem.lua")(Context)
Context.ConfigSystem = import("src/Systems/ConfigSystem.lua")(Context)

-- 7. Build the UI
-- Passing Context here is where the "index function" error usually happens
-- We ensure Context is the table defined at the top
Context.UI = import("src/UI/ShankUI.lua")(Context, Context.Theme)
import("src/UI/BuildUI.lua")(Context)

-- 8. Run
Context.ESPSystem.InitializeAll()
import("src/Runtime.lua")(Context)

Context.UI:Notify("B0Xaz Universal", "Modular Load Complete", 4, Context.Theme.Success)

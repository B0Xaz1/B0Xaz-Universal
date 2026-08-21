-- init.lua
local GITHUB_USER = "B0Xaz1"
local GITHUB_REPO = "B0Xaz-Universal"
local GITHUB_BRANCH = "main"

local BASE_URL = string.format("https://raw.githubusercontent.com/%s/%s/%s/", GITHUB_USER, GITHUB_REPO, GITHUB_BRANCH)
getgenv().B0XazScriptURL = BASE_URL .. "init.lua"

-- Create a shared container to prevent "index function" errors
getgenv().B0XazShared = {}
local Context = getgenv().B0XazShared

local function import(path)
    -- The "?t=" part forces GitHub to give us the newest version of your code
    local url = BASE_URL .. path .. "?t=" .. tostring(tick())
    local ok, source = pcall(function()
        return game:HttpGet(url)
    end)
    
    if not ok or not source or #source == 0 then
        warn("[B0Xaz] Failed to download: " .. path)
        return nil
    end
    
    local chunk, compileErr = loadstring(source, path)
    if not chunk then
        error("[B0Xaz] Syntax error in " .. path .. ": " .. tostring(compileErr))
    end
    
    local success, result = pcall(chunk)
    if not success then
        error("[B0Xaz] Execution error in " .. path .. ": " .. tostring(result))
    end
    
    return result
end

print("[B0Xaz] Starting Load...")

-- 1. Cleanup
import("src/Cleanup.lua")

-- 2. Load Core (These return functions that we call immediately)
local configFunc = import("src/Config.lua")
local CONFIG, DefaultLighting = configFunc()
Context.CONFIG = CONFIG
Context.DefaultLighting = DefaultLighting

local utilsFunc = import("src/Utils.lua")
Context.Utils = utilsFunc(CONFIG)

local dmFunc = import("src/DrawingManager.lua")
Context.DrawingManager = dmFunc()

local ctxFunc = import("src/Context.lua")
local ctxTable = ctxFunc(CONFIG, DefaultLighting, Context.Utils, Context.DrawingManager)

-- Merge the context table into our shared global
for k, v in pairs(ctxTable) do Context[k] = v end

-- 3. Load UI & Theme
local themeFunc = import("src/UI/Theme.lua")
Context.Theme = themeFunc()

local uiFunc = import("src/UI/ShankUI.lua")
Context.ShankUI = uiFunc(Context, Context.Theme)

-- 4. Systems
Context.FlingSystem = import("src/Systems/FlingSystem.lua")(Context)
Context.FlySystem = import("src/Systems/FlySystem.lua")(Context)
Context.ESPSystem = import("src/Systems/ESPSystem.lua")(Context)
Context.AimbotSystem = import("src/Systems/AimbotSystem.lua")(Context)
Context.ConfigSystem = import("src/Systems/ConfigSystem.lua")(Context)
Context.OverlayManager = import("src/Visuals/OverlayManager.lua")(Context)

-- 5. Build UI
Context.UI = import("src/UI/BuildUI.lua")(Context)
getgenv().B0XazLibrary = Context.UI

-- 6. Start
Context.ESPSystem.InitializeAll()
import("src/Runtime.lua")(Context)

Context.UI:Notify("B0Xaz Universal", "Loaded Successfully", 4, Context.Theme.Success)

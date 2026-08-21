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
    local source = game:HttpGet(url)
    if not source or #source == 0 then error("Failed to load: " .. path) end
    local chunk, err = loadstring(source, path)
    if not chunk then error("Syntax Error: " .. path .. " : " .. tostring(err)) end
    return chunk()
end

-- 1. Reset
import("src/Cleanup.lua")()

-- 2. Base Load
local CONFIG, DefaultLighting = import("src/Config.lua")()
Context.CONFIG = CONFIG
Context.DefaultLighting = DefaultLighting
Context.Utils = import("src/Utils.lua")(CONFIG)
Context.DrawingManager = import("src/DrawingManager.lua")()

-- 3. Load Context Table
local ctxData = import("src/Context.lua")(CONFIG, DefaultLighting, Context.Utils, Context.DrawingManager)
for k, v in pairs(ctxData) do Context[k] = v end

-- 4. Load UI blueprint and Theme
Context.Theme = import("src/UI/Theme.lua")()
-- We save the UI "Class" into the context here
Context.ShankUI = import("src/UI/ShankUI.lua")(Context, Context.Theme)

-- 5. Load Systems
Context.FlingSystem = import("src/Systems/FlingSystem.lua")(Context)
Context.FlySystem = import("src/Systems/FlySystem.lua")(Context)
Context.ESPSystem = import("src/Systems/ESPSystem.lua")(Context)
Context.AimbotSystem = import("src/Systems/AimbotSystem.lua")(Context)
Context.ConfigSystem = import("src/Systems/ConfigSystem.lua")(Context)
Context.OverlayManager = import("src/Visuals/OverlayManager.lua")(Context)

-- 6. Construct the UI Menu
-- This calls BuildUI.lua and passes the whole Context
import("src/UI/BuildUI.lua")(Context)

-- 7. Start
Context.ESPSystem.InitializeAll()
import("src/Runtime.lua")(Context)

Context.UI:Notify("B0Xaz Universal", "Loaded Successfully", 4, Context.Theme.Success)

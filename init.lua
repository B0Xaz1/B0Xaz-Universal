local GITHUB_USER = "B0Xaz1"
local GITHUB_REPO = "B0Xaz-Universal"
local GITHUB_BRANCH = "main"

local BASE_URL = string.format(
	"https://raw.githubusercontent.com/%s/%s/%s/",
	GITHUB_USER, GITHUB_REPO, GITHUB_BRANCH
)
getgenv().B0XazScriptURL = BASE_URL .. "init.lua"
getgenv().B0XazContext = {}
local Context = getgenv().B0XazContext

local function import(path)
	local url = BASE_URL .. path .. "?t=" .. tostring(tick())
	local ok, source = pcall(function()
		return game:HttpGet(url)
	end)
	if not ok or not source or #source == 0
		or source:sub(1, 3) == "404"
		or source:find("404: Not Found")
		or source:find("<!DOCTYPE html>") then
		error("[B0Xaz Loader] 404 File Not Found: " .. path .. "\n" .. url)
	end
	local chunk, err = loadstring(source, path)
	if not chunk then
		error("[B0Xaz Loader] Syntax Error in " .. path .. " : " .. tostring(err))
	end
	return chunk()
end

Context.import = import
print("[B0Xaz] Loading modules...")

import("src/Cleanup.lua")()
getgenv().B0XazSessionId = getgenv().B0XazSessionId or 1

local CONFIG, DefaultLighting = import("src/Config.lua")()
Context.CONFIG = CONFIG
Context.DefaultLighting = DefaultLighting
Context.Utils = import("src/Utils.lua")(CONFIG)
Context.DrawingManager = import("src/DrawingManager.lua")()

local ctxData = import("src/Context.lua")(CONFIG, DefaultLighting, Context.Utils, Context.DrawingManager)
for k, v in pairs(ctxData) do
	Context[k] = v
end

local activeTheme, themeMgr = import("src/UI/Theme.lua")()
Context.Theme = activeTheme
Context.ThemeManager = themeMgr

-- Key system BEFORE UI (passed import function)
Context.KeySystem = import("src/Systems/KeySystem.lua")(Context, import)
print("[B0Xaz] KeySystem loaded")

Context.UIEngine = import("src/UI/UI.lua")(Context, Context.Theme)
if not Context.UIEngine then
	error("[B0Xaz Loader] UI engine failed to load")
end
if type(Context.UIEngine.CreateKeyPrompt) ~= "function" then
	error("[B0Xaz Loader] UI.lua is missing CreateKeyPrompt — push latest UI.lua to GitHub")
end

local function BootScript()
	print("[B0Xaz] Booting tier:", Context.KeySystem.CurrentTier, Context.KeySystem.GetTierName())

	Context.FlingSystem = import("src/Systems/FlingSystem.lua")(Context)
	Context.FlySystem = import("src/Systems/FlySystem.lua")(Context)
	Context.MovementSystem = import("src/Systems/MovementSystem.lua")(Context)
	Context.ESPSystem = import("src/Systems/ESPSystem.lua")(Context)
	Context.AimbotSystem = import("src/Systems/AimbotSystem.lua")(Context)
	Context.ConfigSystem = import("src/Systems/ConfigSystem.lua")(Context)
	Context.PerformanceSystem = import("src/Systems/PerformanceSystem.lua")(Context)
	Context.PlayersSystem = import("src/Systems/PlayersSystem.lua")(Context)
	Context.OverlayManager = import("src/Visuals/OverlayManager.lua")(Context)

	Context.GameLoader = import("src/Games/Loader.lua")(Context, import)
	Context.GameModule = Context.GameLoader.Load()

	import("src/UI/BuildUI.lua")(Context)

	if not Context.UI then
		error("[B0Xaz Loader] BuildUI did not set Context.UI — check BuildUI.lua")
	end

	pcall(function()
		if Context.ConfigSystem then
			if Context.ConfigSystem.LoadAutoload() then
				Context.ConfigSystem.UpdateUI()
			end
			Context.ConfigSystem.StartAutosaveLoop()
		end
	end)

	Context.ESPSystem.InitializeAll()
	import("src/Runtime.lua")(Context)

	Context.UI:Notify(
		"B0Xaz Universal",
		"Access: " .. Context.KeySystem.GetTierName(),
		5,
		Context.Theme.Success
	)
end

local hasKey, tier, msg = Context.KeySystem.LoadAndVerify()
if hasKey then
	BootScript()
else
	Context.UIEngine:CreateKeyPrompt(Context.KeySystem, Context.Theme, BootScript, msg)
end

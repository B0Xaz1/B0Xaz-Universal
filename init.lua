local GITHUB_USER = "B0Xaz1"
local GITHUB_REPO = "B0Xaz-Universal"
local GITHUB_BRANCH = "main"

local BASE_URL = string.format(
	"https://raw.githubusercontent.com/%s/%s/%s/",
	GITHUB_USER, GITHUB_REPO, GITHUB_BRANCH
)
getgenv().B0XazScriptURL = BASE_URL .. "init.lua"

if not game:IsLoaded() then
	game.Loaded:Wait()
end
local Players = game:GetService("Players")
if not Players.LocalPlayer then
	repeat task.wait() until Players.LocalPlayer
end

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
	local success, result = pcall(chunk)
	if not success then
		error("[B0Xaz Loader] Runtime Error in " .. path .. " : " .. tostring(result))
	end
	return result
end

Context.import = import
print("[B0Xaz] Loading modules...")

local okCleanup, errCleanup = pcall(function()
	import("src/Cleanup.lua")()
end)
if not okCleanup then warn("[B0Xaz] Cleanup failed: " .. tostring(errCleanup)) end

getgenv().B0XazSessionId = (getgenv().B0XazSessionId or 0) + 1

local CONFIG, DefaultLighting = import("src/Config.lua")()
Context.CONFIG = CONFIG
Context.DefaultLighting = DefaultLighting
Context.Utils = import("src/Utils.lua")(CONFIG)

if Context.Utils.WaitForGameLoad then
	Context.Utils.WaitForGameLoad()
end

Context.DrawingManager = import("src/DrawingManager.lua")()

local ctxData = import("src/Context.lua")(CONFIG, DefaultLighting, Context.Utils, Context.DrawingManager)
for k, v in pairs(ctxData) do
	Context[k] = v
end

local activeTheme, themeMgr = import("src/UI/Theme.lua")()
Context.Theme = activeTheme
Context.ThemeManager = themeMgr

Context.KeySystem = import("src/Systems/KeySystem.lua")(Context, import)
print("[B0Xaz] KeySystem loaded")

Context.UIEngine = import("src/UI/UI.lua")(Context, Context.Theme)
if not Context.UIEngine then
	error("[B0Xaz Loader] UI engine failed to load")
end
if type(Context.UIEngine.CreateKeyPrompt) ~= "function" then
	error("[B0Xaz Loader] UI.lua is missing CreateKeyPrompt")
end

local function BootScript()
	print("[B0Xaz] Booting tier:", Context.KeySystem.CurrentTier, Context.KeySystem.GetTierName())

	local loadSystems = {
		{"FlingSystem", "src/Systems/FlingSystem.lua"},
		{"FlySystem", "src/Systems/FlySystem.lua"},
		{"MovementSystem", "src/Systems/MovementSystem.lua"},
		{"ESPSystem", "src/Systems/ESPSystem.lua"},
		{"AimbotSystem", "src/Systems/AimbotSystem.lua"},
		{"ConfigSystem", "src/Systems/ConfigSystem.lua"},
		{"PerformanceSystem", "src/Systems/PerformanceSystem.lua"},
		{"PlayersSystem", "src/Systems/PlayersSystem.lua"},
		{"OverlayManager", "src/Visuals/OverlayManager.lua"},
	}

	for _, entry in ipairs(loadSystems) do
		local ok, res = pcall(function() return import(entry[2])(Context) end)
		if ok then
			Context[entry[1]] = res
			print("[B0Xaz] Loaded: " .. entry[1])
		else
			warn("[B0Xaz] Failed to load " .. entry[1] .. ": " .. tostring(res))
		end
	end

	pcall(function()
		Context.GameLoader = import("src/Games/Loader.lua")(Context, import)
		Context.GameModule = Context.GameLoader.Load()
	end)

	local okBuild, errBuild = pcall(function()
		import("src/UI/BuildUI.lua")(Context)
	end)
	if not okBuild then
		error("[B0Xaz Loader] BuildUI failed: " .. tostring(errBuild))
	end

	if not Context.UI then
		error("[B0Xaz Loader] BuildUI did not set Context.UI")
	end

	pcall(function()
		if Context.ConfigSystem then
			if Context.ConfigSystem.LoadAutoload() then
				Context.ConfigSystem.UpdateUI()
			end
			Context.ConfigSystem.StartAutosaveLoop()
		end
	end)

	if Context.ESPSystem then
		pcall(function() Context.ESPSystem.InitializeAll() end)
	end

	pcall(function() import("src/Runtime.lua")(Context) end)

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

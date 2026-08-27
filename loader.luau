-- B0Xaz Universal — branch loader
-- Launches the build on branch: arena/01a044ee-b0xaz-universal
-- (Performance tab: Performance Boosters + On-Screen Telemetry moved out of Utility)
--
-- Paste this whole file into your executor, or use the one-line version:
--   loadstring(game:HttpGet("https://raw.githubusercontent.com/B0Xaz1/B0Xaz-Universal/arena/01a044ee-b0xaz-universal/loader.luau"))()

local BRANCH = "arena/01a044ee-b0xaz-universal"
local BASE = "https://raw.githubusercontent.com/B0Xaz1/B0Xaz-Universal/" .. BRANCH

local globalEnv = (getgenv and getgenv()) or _G

-- init.luau reads these: B0XazBaseURL wins over B0XazRef, and both are
-- re-normalized there, so the branch sticks across relaunch / server hop.
globalEnv.B0XazRef = BRANCH
globalEnv.B0XazBaseURL = BASE

-- Cache buster: raw.githubusercontent edge nodes hold a branch file for a
-- few minutes, so a fresh push can otherwise load as the previous build.
local source = game:HttpGet(BASE .. "/init.luau?t=" .. tostring(os.time()))
local chunk, err = loadstring(source, "@B0XazInit")
if not chunk then
	error("[B0Xaz] Loader compile failed: " .. tostring(err))
end
chunk()

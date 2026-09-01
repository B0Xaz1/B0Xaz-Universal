local Players = game:GetService("Players")

local globalEnv = (getgenv and getgenv()) or _G

local BRANCH = globalEnv.B0XazRef or "arena/01a05a68-b0xaz-universal"
local BASE = globalEnv.B0XazBaseURL or ("https://raw.githubusercontent.com/B0Xaz1/B0Xaz-Universal/" .. BRANCH)

-- init.luau reads these: B0XazBaseURL wins over B0XazRef, and both are
-- re-normalized there, so the branch sticks across relaunch / server hop.
globalEnv.B0XazRef = BRANCH
globalEnv.B0XazBaseURL = BASE

-- Autoexec fires this file before the place is ready, and a second executor
-- run would otherwise stack a whole second suite on top of the first.
if globalEnv.B0XazLoaderBusy then return end
globalEnv.B0XazLoaderBusy = true

local function ready()
	-- HttpGet and the UI both need a loaded place with a local player, which
	-- an autoexec run reaches only several seconds after the script starts.
	local start = os.clock()
	while not game:IsLoaded() and (os.clock() - start) < 60 do
		task.wait(0.2)
	end
	start = os.clock()
	while not Players.LocalPlayer and (os.clock() - start) < 60 do
		task.wait(0.2)
	end
end

local function fetch(url: string): string?
	-- The network stack is frequently not up on the first autoexec tick, so
	-- a single failed request must not kill the launch.
	for attempt = 1, 5 do
		local ok, result = pcall(function()
			return game:HttpGet(url, true)
		end)
		if ok and typeof(result) == "string" and result ~= "" and not result:match("^404") then
			return result
		end
		task.wait(attempt * 0.6)
	end
	return nil
end

task.spawn(function()
	ready()

	-- Cache buster: raw.githubusercontent edge nodes hold a branch file for a
	-- few minutes, so a fresh push can otherwise load as the previous build.
	local source = fetch(BASE .. "/init.luau?t=" .. tostring(os.time()))

	if not source then
		globalEnv.B0XazLoaderBusy = nil
		warn("[B0Xaz] Loader could not download init.luau")
		return
	end

	local chunk, err = loadstring(source, "@B0XazInit")
	if not chunk then
		globalEnv.B0XazLoaderBusy = nil
		warn("[B0Xaz] Loader compile failed: " .. tostring(err))
		return
	end

	local ok, runErr = pcall(chunk)
	globalEnv.B0XazLoaderBusy = nil
	if not ok then
		warn("[B0Xaz] Loader run failed: " .. tostring(runErr))
	end
end)

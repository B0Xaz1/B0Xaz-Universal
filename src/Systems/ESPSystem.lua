-- // src/Systems/ESPSystem.lua
return function(Context)
	local Players = game:GetService("Players")
	local Workspace = game:GetService("Workspace")
	local LocalPlayer = Players.LocalPlayer

	local FeatureConfig = Context.FeatureConfig or {}
	local CONFIG = Context.CONFIG or {}
	local Utils = Context.Utils or {}
	local DrawingManager = Context.DrawingManager or {}
	local Connections = Context.Connections or {}

	local env = (getgenv and getgenv()) or _G
	local DrawingESP = {}
	env.B0XazDrawingESP = DrawingESP
	local Highlights = {}
	env.B0XazHighlights = Highlights

	local ESPSystem = {}
	local sessionId = env.B0XazSessionId or 0

	local function alive()
		return env.B0XazSessionId == sessionId
	end

	local function destroyData(data)
		if type(data) ~= "table" or not DrawingManager.SafeRemove then return end
		DrawingManager.SafeRemove(data.Box)
		DrawingManager.SafeRemove(data.Name)
		DrawingManager.SafeRemove(data.Health)
		DrawingManager.SafeRemove(data.HealthBG)
		DrawingManager.SafeRemove(data.Distance)
		DrawingManager.SafeRemove(data.HeadDot)
		DrawingManager.SafeRemove(data.LookLine)
		DrawingManager.SafeRemove(data.Tracer)
		if type(data.Skeleton) == "table" then
			for _, line in ipairs(data.Skeleton) do
				DrawingManager.SafeRemove(line)
			end
		end
	end

	local function hide(data)
		if not data then return end
		if data.Box then data.Box.Visible = false end
		if data.Name then data.Name.Visible = false end
		if data.Health then data.Health.Visible = false end
		if data.HealthBG then data.HealthBG.Visible = false end
		if data.Distance then data.Distance.Visible = false end
		if data.HeadDot then data.HeadDot.Visible = false end
		if data.LookLine then data.LookLine.Visible = false end
		if data.Tracer then data.Tracer.Visible = false end
		if data.Skeleton then
			for _, line in ipairs(data.Skeleton) do
				if line then line.Visible = false end
			end
		end
	end

	function ESPSystem.CreatePlayerESP(player)
		if not alive() or player == LocalPlayer or not DrawingManager.Available then return end
		if DrawingESP[player] then
			destroyData(DrawingESP[player])
			DrawingESP[player] = nil
		end

		local color = (FeatureConfig.ESP and FeatureConfig.ESP.Color) or Color3.new(1, 1, 1)
		local skelThick = CONFIG.ESP_SKELETON_THICKNESS or 1
		local tracerThick = CONFIG.ESP_TRACER_THICKNESS or 1.5
		local nameSize = CONFIG.ESP_TEXT_SIZE_NAME or 13
		local distSize = CONFIG.ESP_TEXT_SIZE_DIST or 11

		local skeleton = {}
		for _ = 1, 6 do
			local line = DrawingManager.NewLine({ Thickness = skelThick, Color = color })
			if line then table.insert(skeleton, line) end
		end

		DrawingESP[player] = {
			Box = DrawingManager.NewSquare({ Thickness = 2, Color = color }),
			Name = DrawingManager.NewText({ Size = nameSize, Color = color }),
			Health = DrawingManager.NewSquare({ Filled = true }),
			HealthBG = DrawingManager.NewSquare({ Filled = true }),
			Distance = DrawingManager.NewText({ Size = distSize, Color = color }),
			HeadDot = DrawingManager.NewCircle({ Radius = 4, Filled = true, Color = color }),
			LookLine = DrawingManager.NewLine({ Thickness = 2, Color = color }),
			Tracer = DrawingManager.NewLine({ Thickness = tracerThick, Color = color }),
			Skeleton = skeleton,
		}
	end

	function ESPSystem.RemovePlayerESP(player)
		if DrawingESP[player] then
			destroyData(DrawingESP[player])
			DrawingESP[player] = nil
		end
		ESPSystem.RemoveHighlight(player)
	end

	function ESPSystem.AddHighlight(player)
		if not alive() or Highlights[player] then return end
		local char = player and player.Character
		if not char or not char.Parent then return end
		local chams = FeatureConfig.Chams or {}
		local ok, hl = pcall(function()
			local h = Instance.new("Highlight")
			h.Name = "B0XazChams"
			h.Adornee = char
			h.FillColor = chams.FillColor or Color3.new(1, 1, 1)
			h.OutlineColor = chams.OutlineColor or Color3.new(0, 0, 0)
			h.FillTransparency = 0.5
			h.Parent = char
			return h
		end)
		if ok and hl then Highlights[player] = hl end
	end

	function ESPSystem.RemoveHighlight(player)
		local hl = Highlights[player]
		if hl then
			pcall(function() hl:Destroy() end)
			Highlights[player] = nil
		end
	end

	local function getBones(character, humanoid)
		local bones = {}
		local head = character:FindFirstChild("Head")
		if not head then return bones end
		local isR15 = humanoid and humanoid.RigType == Enum.HumanoidRigType.R15

		if isR15 then
			local ut = character:FindFirstChild("UpperTorso")
			local lt = character:FindFirstChild("LowerTorso")
			if ut and lt then
				table.insert(bones, { head, ut })
				table.insert(bones, { ut, lt })
				local lua = character:FindFirstChild("LeftUpperArm")
				local rua = character:FindFirstChild("RightUpperArm")
				local lul = character:FindFirstChild("LeftUpperLeg")
				local rul = character:FindFirstChild("RightUpperLeg")
				if lua then table.insert(bones, { ut, lua }) end
				if rua then table.insert(bones, { ut, rua }) end
				if lul then table.insert(bones, { lt, lul }) end
				if rul then table.insert(bones, { lt, rul }) end
			end
		else
			local torso = character:FindFirstChild("Torso")
			if torso then
				table.insert(bones, { head, torso })
				local la = character:FindFirstChild("Left Arm")
				local ra = character:FindFirstChild("Right Arm")
				local ll = character:FindFirstChild("Left Leg")
				local rl = character:FindFirstChild("Right Leg")
				if la then table.insert(bones, { torso, la }) end
				if ra then table.insert(bones, { torso, ra }) end
				if ll then table.insert(bones, { torso, ll }) end
				if rl then table.insert(bones, { torso, rl }) end
			end
		end
		return bones
	end

	local function hookPlayer(player)
		if not alive() or player == LocalPlayer then return end
		ESPSystem.CreatePlayerESP(player)
		if Connections and Connections.Add then
			Connections.Add(player.CharacterAdded:Connect(function()
				if not alive() then return end
				task.wait(0.2)
				if FeatureConfig.Chams and FeatureConfig.Chams.Enabled then
					ESPSystem.RemoveHighlight(player)
					ESPSystem.AddHighlight(player)
				end
			end))
			Connections.Add(player.CharacterRemoving:Connect(function()
				if not alive() then return end
				ESPSystem.RemoveHighlight(player)
				if DrawingESP[player] then hide(DrawingESP[player]) end
			end))
		end
	end

	function ESPSystem.DestroyAll()
		for player in pairs(DrawingESP) do ESPSystem.RemovePlayerESP(player) end
		table.clear(DrawingESP)
		for player in pairs(Highlights) do ESPSystem.RemoveHighlight(player) end
		table.clear(Highlights)
	end

	function ESPSystem.InitializeAll()
		if not alive() then return end
		ESPSystem.DestroyAll()
		for _, player in ipairs(Players:GetPlayers()) do
			task.spawn(hookPlayer, player)
		end
		if Connections and Connections.Add then
			Connections.Add(Players.PlayerAdded:Connect(function(p)
				if alive() then hookPlayer(p) end
			end))
			Connections.Add(Players.PlayerRemoving:Connect(function(p)
				if alive() then ESPSystem.RemovePlayerESP(p) end
			end))
		end
	end

	function ESPSystem.Update()
		if not alive() then return end
		local cam = Workspace.CurrentCamera
		if not cam then return end

		local espCfg = FeatureConfig.ESP
		local chamsCfg = FeatureConfig.Chams
		local hasESP = espCfg and espCfg.Enabled and (
			espCfg.Box or espCfg.Name or espCfg.Health or espCfg.Distance
			or espCfg.Tracers or espCfg.Skeleton or espCfg.HeadDot or espCfg.LookDir
		)
		local hasChams = chamsCfg and chamsCfg.Enabled

		if not hasESP and not hasChams then
			for _, data in pairs(DrawingESP) do hide(data) end
			for player in pairs(Highlights) do ESPSystem.RemoveHighlight(player) end
			return
		end

		local myAssets = Utils.GetPlayerAssets and Utils.GetPlayerAssets(LocalPlayer)
		local myPos = myAssets and myAssets.RootPart and myAssets.RootPart.Position
		local espColor = (espCfg and espCfg.Color) or Color3.new(1, 1, 1)
		local maxDist = (espCfg and espCfg.MaxDist) or 500
		local teamCheck = espCfg and espCfg.TeamCheck
		local screenBottom = Vector2.new(cam.ViewportSize.X * 0.5, cam.ViewportSize.Y)

		for player, data in pairs(DrawingESP) do
			if not alive() then return end

			local assets = Utils.GetPlayerAssets and Utils.GetPlayerAssets(player)
			if not (assets and assets.Character and assets.RootPart and assets.Head and assets.Humanoid) then
				hide(data)
			elseif teamCheck and Utils.SameTeam and Utils.SameTeam(player) then
				hide(data)
				ESPSystem.RemoveHighlight(player)
			else
				local rootPos = assets.RootPart.Position
				local dist3D = myPos and (myPos - rootPos).Magnitude or 0

				if dist3D > maxDist then
					hide(data)
				else
					if hasChams then
						local hl = Highlights[player]
						if not hl or not hl.Parent or hl.Adornee ~= assets.Character then
							ESPSystem.RemoveHighlight(player)
							ESPSystem.AddHighlight(player)
						else
							hl.FillColor = chamsCfg.FillColor or Color3.new(1, 1, 1)
							hl.OutlineColor = chamsCfg.OutlineColor or Color3.new(0, 0, 0)
						end
					else
						ESPSystem.RemoveHighlight(player)
					end

					if not hasESP then
						hide(data)
					else
						local rootScreen, rootOn = cam:WorldToViewportPoint(rootPos)
						if not rootOn or rootScreen.Z <= 0 then
							hide(data)
						else
							local headPos = assets.Head.Position
							local headScreen = cam:WorldToViewportPoint(headPos + Vector3.new(0, 0.5, 0))
							local feetScreen = cam:WorldToViewportPoint(rootPos - Vector3.new(0, 3, 0))
							local height = math.abs(headScreen.Y - feetScreen.Y)
							local width = height * 0.55
							local halfW, halfH = width * 0.5, height * 0.5
							local rootV = Vector2.new(rootScreen.X, rootScreen.Y)
							local headV = Vector2.new(headScreen.X, headScreen.Y)

							if espCfg.Box and data.Box then
								data.Box.Size = Vector2.new(width, height)
								data.Box.Position = Vector2.new(rootV.X - halfW, rootV.Y - halfH)
								data.Box.Color = espColor
								data.Box.Visible = true
							elseif data.Box then data.Box.Visible = false end

							if espCfg.Name and data.Name then
								data.Name.Text = player.DisplayName or player.Name
								data.Name.Position = Vector2.new(rootV.X, headV.Y - 24)
								data.Name.Color = espColor
								data.Name.Visible = true
							elseif data.Name then data.Name.Visible = false end

							if espCfg.Health and data.Health and data.HealthBG then
								local hum = assets.Humanoid
								local ratio = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
								local bx = rootV.X - halfW - 6
								local by = rootV.Y - halfH
								data.HealthBG.Size = Vector2.new(3, height)
								data.HealthBG.Position = Vector2.new(bx, by)
								data.HealthBG.Color = Color3.new(0, 0, 0)
								data.HealthBG.Transparency = 0.5
								data.HealthBG.Visible = true
								data.Health.Size = Vector2.new(3, height * ratio)
								data.Health.Position = Vector2.new(bx, by + height * (1 - ratio))
								data.Health.Color = Color3.fromHSV(ratio * 0.33, 1, 1)
								data.Health.Visible = true
							elseif data.Health then
								data.Health.Visible = false
								if data.HealthBG then data.HealthBG.Visible = false end
							end

							if espCfg.Distance and data.Distance then
								data.Distance.Text = string.format("%dm", math.floor(dist3D))
								data.Distance.Position = Vector2.new(rootV.X, feetScreen.Y + 3)
								data.Distance.Color = espColor
								data.Distance.Visible = true
							elseif data.Distance then data.Distance.Visible = false end

							if espCfg.HeadDot and data.HeadDot then
								data.HeadDot.Position = headV
								data.HeadDot.Color = espColor
								data.HeadDot.Visible = true
							elseif data.HeadDot then data.HeadDot.Visible = false end

							if espCfg.LookDir and data.LookLine then
								local lookEnd = headPos + (assets.Head.CFrame.LookVector * 4.5)
								local lw = cam:WorldToViewportPoint(lookEnd)
								data.LookLine.From = headV
								data.LookLine.To = Vector2.new(lw.X, lw.Y)
								data.LookLine.Color = espColor
								data.LookLine.Visible = true
							elseif data.LookLine then data.LookLine.Visible = false end

							if espCfg.Tracers and data.Tracer then
								data.Tracer.From = screenBottom
								data.Tracer.To = rootV
								data.Tracer.Color = espColor
								data.Tracer.Visible = true
							elseif data.Tracer then data.Tracer.Visible = false end

							if espCfg.Skeleton and data.Skeleton then
								local bones = getBones(assets.Character, assets.Humanoid)
								for i = 1, #data.Skeleton do
									local line = data.Skeleton[i]
									local pair = bones[i]
									if pair and pair[1] and pair[2] and pair[1].Parent and pair[2].Parent then
										local s1, o1 = cam:WorldToViewportPoint(pair[1].Position)
										local s2, o2 = cam:WorldToViewportPoint(pair[2].Position)
										if s1.Z > 0 and s2.Z > 0 and (o1 or o2) then
											line.From = Vector2.new(s1.X, s1.Y)
											line.To = Vector2.new(s2.X, s2.Y)
											line.Color = espColor
											line.Visible = true
										else
											line.Visible = false
										end
									else
										line.Visible = false
									end
								end
							elseif data.Skeleton then
								for _, line in ipairs(data.Skeleton) do line.Visible = false end
							end
						end
					end
				end
			end
		end
	end

	return ESPSystem
end

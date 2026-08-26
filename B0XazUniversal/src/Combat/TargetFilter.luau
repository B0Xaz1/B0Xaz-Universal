--!strict

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

export type TargetFilterInstance = {
	IsTeammate: (self: any, player: Player) -> boolean,
	GetTeamColor: (self: any, player: Player) -> Color3?,
	IsFriend: (self: any, player: Player) -> boolean,
	IsWhitelisted: (self: any, player: Player) -> boolean,
	HasForceField: (self: any, player: Player) -> boolean,
	IsVisible: (self: any, targetPart: BasePart) -> boolean,
	ValidateTarget: (self: any, player: Player, targetPart: BasePart?, configScope: any) -> boolean,
}

return function(services: any)
	local StateStore = services:Get("StateStore")
	local PlayerTracker = services:Get("PlayerTracker")
	local LocalPlayer = Players.LocalPlayer

	local TargetFilter = {}
	local friendCache: { [number]: boolean } = {}

	-- One shared RaycastParams instance keeps visibility checks allocation-free
	local visRaycastParams = RaycastParams.new()
	visRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
	visRaycastParams.IgnoreWater = true

	-- The exclude list holds the local character and camera so local viewmodels,
	-- accessories, and the local avatar body cannot occlude targets.
	local baseFilterList: { Instance } = {}
	local activeFilterList: { Instance } = {}
	local lastLocalCharacter: Model? = nil
	local lastCamera: Camera? = nil

	function TargetFilter:IsTeammate(player: Player): boolean
		if not player or player == LocalPlayer then return false end
		if LocalPlayer and LocalPlayer.Team and player.Team then
			return LocalPlayer.Team == player.Team
		end
		if LocalPlayer and LocalPlayer.TeamColor and player.TeamColor then
			return LocalPlayer.TeamColor == player.TeamColor
		end
		return false
	end

	function TargetFilter:GetTeamColor(player: Player): Color3?
		if not player then return nil end
		if player.Team and player.Team.TeamColor then
			return player.Team.TeamColor.Color
		elseif player.TeamColor then
			return player.TeamColor.Color
		end
		return nil
	end

	-- IsFriendsWith is a network round trip, so results are cached per UserId
	function TargetFilter:IsFriend(player: Player): boolean
		if not player or player == LocalPlayer or not player.UserId then return false end
		local userId = player.UserId
		if friendCache[userId] ~= nil then
			return friendCache[userId]
		end

		local isFr = false
		local ok = pcall(function()
			isFr = LocalPlayer:IsFriendsWith(userId)
		end)
		if ok then
			friendCache[userId] = isFr
			return isFr
		end
		return false
	end

	-- The whitelist matches either display name or UserId string, since
	-- usernames can collide across servers
	function TargetFilter:IsWhitelisted(player: Player): boolean
		if not player or player == LocalPlayer then return false end
		local whitelistMap = StateStore:Get("Settings.Whitelist")
		if typeof(whitelistMap) == "table" then
			if whitelistMap[player.Name] == true then return true end
			if player.UserId and whitelistMap[tostring(player.UserId)] == true then return true end
		end
		return false
	end

	function TargetFilter:HasForceField(player: Player): boolean
		local assets = PlayerTracker:GetPlayerAssets(player)
		if not assets or not assets.Character then return false end
		return assets.Character:FindFirstChildOfClass("ForceField") ~= nil
	end

	function TargetFilter:IsVisible(targetPart: BasePart): boolean
		if not targetPart or not targetPart.Parent or not targetPart:IsDescendantOf(Workspace) then
			return false
		end

		local cam = Workspace.CurrentCamera
		if not cam then return false end

		local origin = cam.CFrame.Position
		local targetPos = targetPart.Position
		local direction = targetPos - origin

		-- Targets closer than this are always treated as visible; a short ray
		-- is more likely to clip into the local character than to reveal a wall
		if direction.Magnitude < 0.5 then return true end

		local myAssets = PlayerTracker:GetLocalAssets()
		local myChar = myAssets and myAssets.Character or (LocalPlayer and LocalPlayer.Character)
		if myChar ~= lastLocalCharacter or cam ~= lastCamera or #baseFilterList == 0 then
			lastLocalCharacter = myChar
			lastCamera = cam
			table.clear(baseFilterList)
			if myChar then table.insert(baseFilterList, myChar) end
			table.insert(baseFilterList, cam)
		end

		table.clear(activeFilterList)
		for i = 1, #baseFilterList do
			activeFilterList[i] = baseFilterList[i]
		end
		visRaycastParams.FilterDescendantsInstances = activeFilterList

		local targetModel = targetPart.Parent

		-- Multi-pass penetration: penetrates through non-collidable trigger
		-- volumes, invisible parts, transparent glass/fences, and phased doors
		-- while stopping firmly on solid walls
		for _ = 1, 4 do
			local result = Workspace:Raycast(origin, direction, visRaycastParams)
			if not result then
				return true
			end

			local hitInstance = result.Instance
			if hitInstance == targetPart or hitInstance:IsDescendantOf(targetModel) then
				return true
			end

			-- Invisible barriers, non-collidable trigger zones, or transparent obstacles
			-- should not block line of sight; add to exclude filter and continue past them
			if not hitInstance.CanCollide or hitInstance.Transparency >= 0.75 then
				table.insert(activeFilterList, hitInstance)
				visRaycastParams.FilterDescendantsInstances = activeFilterList
			else
				-- Solid opaque wall or obstacle
				return false
			end
		end

		return false
	end

	function TargetFilter:ValidateTarget(player: Player, targetPart: BasePart?, configScope: any): boolean
		if not player or player == LocalPlayer then return false end
		if not PlayerTracker:IsAlive(player) then return false end

		local cfg = configScope or StateStore:Get("Aimbot")
		if not cfg then return false end

		if cfg.TeamCheck and self:IsTeammate(player) then return false end
		if cfg.FriendCheck ~= false and self:IsFriend(player) then return false end
		if cfg.WhitelistCheck ~= false and self:IsWhitelisted(player) then return false end
		if cfg.ForceFieldCheck ~= false and self:HasForceField(player) then return false end

		if targetPart and cfg.VisCheck and not self:IsVisible(targetPart) then
			return false
		end

		return true
	end

	return TargetFilter
end

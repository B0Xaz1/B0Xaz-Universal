-- src/Systems/PlayersSystem.lua
return function(Context)
    local Players = game:GetService("Players")
    local Workspace = game:GetService("Workspace")
    local RS = game:GetService("RunService")

    local LocalPlayer = Players.LocalPlayer
    local Camera = Workspace.CurrentCamera

    local Utils = Context.Utils
    local State = Context.State
    local Connections = Context.Connections
    local FlingSystem = Context.FlingSystem

    local PlayersSystem = {}

    local _spectating = nil
    local _spectateConn = nil
    local _originalCameraSubject = nil

    local _flingTarget = nil
    local _flingThread = nil

    ----------------------------------------------------------------
    -- Spectate
    ----------------------------------------------------------------
    function PlayersSystem.StartSpectate(playerName)
        local target = Utils.GetPlayerByName(playerName)
        if not target or target == LocalPlayer then return false, "Invalid target" end
        if not Utils.IsAlive(target) then return false, "Target is not alive" end

        PlayersSystem.StopSpectate()

        _spectating = target
        if not _originalCameraSubject then
            _originalCameraSubject = Camera.CameraSubject
        end

        Camera.CameraSubject = target.Character:FindFirstChildOfClass("Humanoid") or target.Character:FindFirstChild("HumanoidRootPart")

        _spectateConn = target.CharacterAdded:Connect(function(char)
            task.wait(0.5)
            if _spectating == target then
                local hum = char:FindFirstChildOfClass("Humanoid") or char:FindFirstChild("HumanoidRootPart")
                if hum then Camera.CameraSubject = hum end
            end
        end)
        Connections.Add(_spectateConn)

        return true
    end

    function PlayersSystem.StopSpectate()
        if _spectateConn then
            pcall(function() _spectateConn:Disconnect() end)
            _spectateConn = nil
        end

        if _originalCameraSubject then
            pcall(function() Camera.CameraSubject = _originalCameraSubject end)
        else
            local myHum = Utils.GetHumanoid()
            if myHum then Camera.CameraSubject = myHum end
        end
        _originalCameraSubject = nil
        _spectating = nil
    end

    function PlayersSystem.GetSpectating()
        return _spectating
    end

    ----------------------------------------------------------------
    -- Teleport To
    ----------------------------------------------------------------
    function PlayersSystem.TeleportTo(playerName, offset)
        local target = Utils.GetPlayerByName(playerName)
        if not target or target == LocalPlayer then return false, "Invalid target" end
        if not Utils.IsAlive(target) then return false, "Target is not alive" end

        local myRoot = Utils.GetRootPart()
        local targetRoot = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
        if not myRoot or not targetRoot then return false, "Missing character" end

        offset = offset or Vector3.new(0, 3, 3)
        myRoot.CFrame = targetRoot.CFrame + offset
        return true
    end

    ----------------------------------------------------------------
    -- Fling Attack (targeted)
    ----------------------------------------------------------------
    function PlayersSystem.StartFling(playerName)
        local target = Utils.GetPlayerByName(playerName)
        if not target or target == LocalPlayer then return false, "Invalid target" end

        PlayersSystem.StopFling()
        _flingTarget = target

        _flingThread = Connections.Track(task.spawn(function()
            local movel = 0.1
            while _flingTarget == target and target.Parent do
                RS.Heartbeat:Wait()

                local myChar = Utils.GetCharacter()
                local targetChar = target.Character
                if not myChar or not targetChar then continue end

                local myRoot = myChar:FindFirstChild("HumanoidRootPart") or myChar:FindFirstChild("Torso")
                local targetRoot = targetChar:FindFirstChild("HumanoidRootPart") or targetChar:FindFirstChild("Torso")
                if not myRoot or not targetRoot then continue end

                -- Position on target
                pcall(function()
                    myRoot.CFrame = targetRoot.CFrame
                end)

                local oldVel = myRoot.Velocity
                myRoot.Velocity = oldVel * 10000 + Vector3.new(0, 10000, 0)
                RS.RenderStepped:Wait()

                if myRoot and myRoot.Parent then myRoot.Velocity = oldVel end
                RS.Stepped:Wait()

                if myRoot and myRoot.Parent then
                    myRoot.Velocity = oldVel + Vector3.new(0, movel, 0)
                    movel = movel * -1
                end
            end
        end))

        return true
    end

    function PlayersSystem.StopFling()
        _flingTarget = nil
        if _flingThread then
            pcall(function() task.cancel(_flingThread) end)
            _flingThread = nil
        end
        local myHum = Utils.GetHumanoid()
        local myRoot = Utils.GetRootPart()
        if myHum then myHum.PlatformStand = false end
        if myRoot then
            pcall(function()
                myRoot.AssemblyLinearVelocity = Vector3.zero
                myRoot.AssemblyAngularVelocity = Vector3.zero
            end)
        end
    end

    function PlayersSystem.GetFlingTarget()
        return _flingTarget
    end

    ----------------------------------------------------------------
    -- Cleanup on player leave
    ----------------------------------------------------------------
    Connections.Add(Players.PlayerRemoving:Connect(function(p)
        if _spectating == p then PlayersSystem.StopSpectate() end
        if _flingTarget == p then PlayersSystem.StopFling() end
    end))

    return PlayersSystem
end

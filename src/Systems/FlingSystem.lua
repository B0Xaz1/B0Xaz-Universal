-- src/Systems/FlingSystem.lua
return function(Context)
    local RS = game:GetService("RunService")
    local Utils = Context.Utils
    local Connections = Context.Connections

    local FlingSystem = {_active = false, _thread = nil, _movel = 0.1}

    function FlingSystem.Start()
        if FlingSystem._active then return end
        FlingSystem._active = true
        FlingSystem._movel = 0.1
        FlingSystem._thread = Connections.Track(task.spawn(function()
            while FlingSystem._active do
                RS.Heartbeat:Wait()
                local char = Utils.GetCharacter()
                if not char then continue end
                local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
                if not hrp then continue end
                local oldVelocity = hrp.Velocity
                hrp.Velocity = oldVelocity * 10000 + Vector3.new(0, 10000, 0)
                RS.RenderStepped:Wait()
                if hrp and hrp.Parent then hrp.Velocity = oldVelocity end
                RS.Stepped:Wait()
                if hrp and hrp.Parent then
                    hrp.Velocity = oldVelocity + Vector3.new(0, FlingSystem._movel, 0)
                    FlingSystem._movel = FlingSystem._movel * -1
                end
            end
        end))
    end

    function FlingSystem.Stop()
        FlingSystem._active = false
        if FlingSystem._thread then
            pcall(function() task.cancel(FlingSystem._thread) end)
            FlingSystem._thread = nil
        end
    end

    return FlingSystem
end

--[[
    Cora • TAB FILE: Main  —  goes in /maintab.lua
    (This is a TAB file, NOT the bootstrap. The bootstrap lives in main.lua.)
    Movement: Walk Speed (+slider), Fast Stop, Speed Bypass (DOORS), Fly (+speed).
    Speed Bypass ported from public Doors scripts (CollisionClone + Crouch spam).
--]]

return function(Cora)
    local Library = Cora.Library
    local Window  = Cora.Window
    local Toggles = Library.Toggles
    local Options = Library.Options

    local Players          = game:GetService("Players")
    local RunService       = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local ReplicatedStorage= game:GetService("ReplicatedStorage")
    local LP               = Players.LocalPlayer

    ----------------------------------------------------------------
    -- Character state
    ----------------------------------------------------------------
    local character, humanoid, hrp
    local DEFAULT_SPEED = 16

    -- Fly state (BodyVelocity only - Doors-friendly, no PlatformStand/Gyro)
    local flyEnabled = false
    local flyBV

    local function stopFly()
        if flyBV then flyBV:Destroy(); flyBV = nil end
    end

    local function startFly()
        if not hrp then return end
        stopFly()
        flyBV = Instance.new("BodyVelocity")
        flyBV.Name     = "CoraFlightVelocity"
        flyBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        flyBV.Velocity = Vector3.zero
        flyBV.P        = 9e4
        flyBV.Parent   = hrp
    end

    -- DOORS speed bypass state
    local CollisionClone

    local function getRemotes()
        return ReplicatedStorage:FindFirstChild("EntityInfo")
            or ReplicatedStorage:FindFirstChild("Bricks")
            or ReplicatedStorage:FindFirstChild("RemotesFolder")
    end

    local function ensureCollisionClone()
        if not character then return end
        local existing = character:FindFirstChild("CollisionClone")
        if existing then CollisionClone = existing; return end

        local cp = character:FindFirstChild("CollisionPart")
        if cp then
            CollisionClone = cp:Clone()
            CollisionClone.Name         = "CollisionClone"
            CollisionClone.RootPriority = 127
            CollisionClone.Anchored     = false
            CollisionClone.CanCollide   = false
            local cc = CollisionClone:FindFirstChild("CollisionCrouch")
            if cc then cc:Destroy() end
            CollisionClone.Parent = character
        end
    end

    local function onCharacter(char)
        character = char
        humanoid  = char:WaitForChild("Humanoid", 10)
        hrp       = char:WaitForChild("HumanoidRootPart", 10)
        CollisionClone = nil -- recreated by the bypass loop after respawn
        if flyEnabled then startFly() end
    end

    LP.CharacterAdded:Connect(onCharacter)
    if LP.Character then task.spawn(onCharacter, LP.Character) end

    ----------------------------------------------------------------
    -- Home icon: try both ImgBB hosts, validate PNG bytes, else lucide "house"
    ----------------------------------------------------------------
    local homeIcon = "house"
    pcall(function()
        if not (writefile and getcustomasset) then return end

        local function isPNG(data)
            return type(data) == "string" and #data > 100
                and data:sub(1, 8) == "\137PNG\r\n\26\n"
        end

        -- Reuse a valid cached file; clear a corrupt one
        local cached = false
        if isfile and isfile("cora_home.png") then
            local ok, data = pcall(readfile, "cora_home.png")
            if ok and isPNG(data) then
                cached = true
            elseif delfile then
                pcall(delfile, "cora_home.png")
            end
        end

        if not cached then
            local urls = {
                "https://i.ibb.co/Qz0ZKBh/home-1000dp-E3-E3-E3-FILL0-wght400-GRAD0-opsz48.png",
                "https://i.ibb.co/MWdbCTK/home-1000dp-E3-E3-E3-FILL0-wght400-GRAD0-opsz48.png",
            }
            for _, url in ipairs(urls) do
                local ok, data = pcall(game.HttpGet, game, url)
                if ok and isPNG(data) then
                    writefile("cora_home.png", data)
                    cached = true
                    break
                end
            end
        end

        if cached then
            homeIcon = getcustomasset("cora_home.png")
        end
    end)

    local MainTab = Window:AddTab("Main", homeIcon)
    pcall(function() MainTab:SetDescription("Main Features") end)
    Cora.Tabs.Main = MainTab

    ----------------------------------------------------------------
    -- UI
    ----------------------------------------------------------------
    local Movement = MainTab:AddLeftGroupbox("Movement", "footprints")

    Movement:AddToggle("WalkSpeedEnabled", {
        Text    = "Walk Speed",
        Default = false,
        Tooltip = "Override your walk speed.",
    })

    Movement:AddSlider("WalkSpeedValue", {
        Text     = "Walk Speed",
        Default  = 16,
        Min      = 16,
        Max      = 25,
        Rounding = 0,
        Compact  = false,
        Disabled = true, -- greyed until Walk Speed is enabled
        Tooltip  = "16-25 normally, up to 100 with Speed Bypass.",
        DisabledTooltip = "Enable Walk Speed first.",
    })

    Movement:AddToggle("FastStop", {
        Text    = "Fast Stop",
        Default = false,
        Tooltip = "No acceleration - you stop instantly (no slide).",
    })

    Movement:AddToggle("SpeedBypass", {
        Text    = "Speed Bypass",
        Default = false,
        Tooltip = "Doors anti-cheat bypass. Lets Walk Speed go up to 100.",
    })

    Movement:AddToggle("Fly", {
        Text    = "Fly",
        Default = false,
        Tooltip = "Fly using the camera direction. Bindable below.",
    })
    Toggles.Fly:AddKeyPicker("FlyKeybind", {
        Default         = "None",   -- nothing bound by default
        SyncToggleState = true,
        Mode            = "Toggle",
        Text            = "Fly",
        NoUI            = false,
    })

    Movement:AddSlider("FlySpeed", {
        Text     = "Fly Speed",
        Default  = 16,
        Min      = 16,
        Max      = 100,
        Rounding = 0,
        Tooltip  = "Speed used while flying.",
    })

    ----------------------------------------------------------------
    -- Logic
    ----------------------------------------------------------------
    -- Grey/un-grey the Walk Speed slider with its toggle
    Toggles.WalkSpeedEnabled:OnChanged(function()
        local on = Toggles.WalkSpeedEnabled.Value
        pcall(function() Options.WalkSpeedValue:SetDisabled(not on) end)
        if not on and humanoid then
            humanoid.WalkSpeed = DEFAULT_SPEED
        end
    end)

    -- Speed Bypass: extend the slider range; the bypass loop does the real work
    Toggles.SpeedBypass:OnChanged(function()
        local on = Toggles.SpeedBypass.Value
        pcall(function()
            if Options.WalkSpeedValue.SetMax then
                Options.WalkSpeedValue:SetMax(on and 100 or 25)
            else
                Options.WalkSpeedValue.Max = on and 100 or 25
            end
        end)
        if not on then
            if Options.WalkSpeedValue.Value > 25 then
                pcall(function() Options.WalkSpeedValue:SetValue(25) end)
            end
            -- Stand back up + restore mass when turning the bypass off
            pcall(function()
                local rf = getRemotes()
                local crouch = rf and rf:FindFirstChild("Crouch")
                if crouch then crouch:FireServer(false) end
            end)
            pcall(function()
                if CollisionClone and CollisionClone.Parent then
                    CollisionClone.Massless = false
                end
            end)
        end
    end)

    -- Fly on/off
    Toggles.Fly:OnChanged(function()
        flyEnabled = Toggles.Fly.Value
        if flyEnabled then startFly() else stopFly() end
    end)

    -- Apply walk speed continuously while enabled (Doors resets it constantly)
    RunService.Heartbeat:Connect(function()
        if humanoid and Toggles.WalkSpeedEnabled.Value then
            if humanoid.WalkSpeed ~= Options.WalkSpeedValue.Value then
                humanoid.WalkSpeed = Options.WalkSpeedValue.Value
            end
        end
    end)

    -- DOORS speed bypass loop: massless CollisionClone + crouch spam
    task.spawn(function()
        while true do
            task.wait()
            if Library.Unloaded then break end
            pcall(function()
                if not (Toggles.SpeedBypass and Toggles.SpeedBypass.Value) then return end
                if not (character and character.Parent) then return end
                if LP:GetAttribute("Alive") == false then return end

                ensureCollisionClone()
                if CollisionClone and CollisionClone.Parent then
                    CollisionClone.Massless = true
                end
                local rf = getRemotes()
                local crouch = rf and rf:FindFirstChild("Crouch")
                if crouch then
                    crouch:FireServer(true, true)
                end
            end)
        end
    end)

    -- Fast stop + fly steering
    RunService.RenderStepped:Connect(function()
        -- Fast stop (skip while flying)
        if not flyEnabled and Toggles.FastStop.Value and humanoid and hrp then
            if humanoid.MoveDirection.Magnitude == 0 then
                local v = hrp.AssemblyLinearVelocity
                hrp.AssemblyLinearVelocity = Vector3.new(0, v.Y, 0)
            end
        end

        -- Fly
        if flyEnabled and flyBV and hrp then
            local cam = workspace.CurrentCamera
            local dir = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W)           then dir += cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S)           then dir -= cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A)           then dir -= cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D)           then dir += cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space)       then dir += Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.new(0, 1, 0) end
            if dir.Magnitude > 0 then dir = dir.Unit end
            flyBV.Velocity = dir * Options.FlySpeed.Value
        end
    end)
end

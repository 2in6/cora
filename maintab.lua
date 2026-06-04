--[[
    Cora • TAB FILE: Main  —  goes in /maintab.lua
    (This is a TAB file, NOT the bootstrap. The bootstrap lives in main.lua.)
    Movement: Walk Speed (+slider), Fast Stop, Speed Bypass (massless), Fly (+speed).
    Inspired by common public Doors movement scripts.
--]]

return function(Cora)
    local Library = Cora.Library
    local Window  = Cora.Window
    local Toggles = Library.Toggles
    local Options = Library.Options

    local Players          = game:GetService("Players")
    local RunService       = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local LP               = Players.LocalPlayer

    ----------------------------------------------------------------
    -- Character state
    ----------------------------------------------------------------
    local character, humanoid, hrp
    local DEFAULT_SPEED = 16

    -- Fly state (declared early so character hook can use it)
    local flyEnabled = false
    local flyBV, flyBG

    local function stopFly()
        if flyBV then flyBV:Destroy(); flyBV = nil end
        if flyBG then flyBG:Destroy(); flyBG = nil end
        if humanoid then pcall(function() humanoid.PlatformStand = false end) end
    end

    local function startFly()
        if not hrp then return end
        stopFly()
        flyBG = Instance.new("BodyGyro")
        flyBG.P         = 9e4
        flyBG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        flyBG.CFrame    = hrp.CFrame
        flyBG.Parent    = hrp

        flyBV = Instance.new("BodyVelocity")
        flyBV.Velocity = Vector3.zero
        flyBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        flyBV.Parent   = hrp

        if humanoid then pcall(function() humanoid.PlatformStand = true end) end
    end

    local function applyMassless(state)
        if not character then return end
        for _, p in ipairs(character:GetDescendants()) do
            if p:IsA("BasePart") and p ~= hrp then
                pcall(function() p.Massless = state end)
            end
        end
    end

    local function onCharacter(char)
        character = char
        humanoid  = char:WaitForChild("Humanoid", 10)
        hrp       = char:WaitForChild("HumanoidRootPart", 10)

        -- Re-apply massless if Speed Bypass is on
        if Toggles.SpeedBypass and Toggles.SpeedBypass.Value then
            applyMassless(true)
        end
        -- Keep new parts massless while enabled
        char.DescendantAdded:Connect(function(d)
            if d:IsA("BasePart") and d ~= hrp and Toggles.SpeedBypass and Toggles.SpeedBypass.Value then
                pcall(function() d.Massless = true end)
            end
        end)

        -- Restart fly if it was on when we respawned
        if flyEnabled then startFly() end
    end

    LP.CharacterAdded:Connect(onCharacter)
    if LP.Character then task.spawn(onCharacter, LP.Character) end

    ----------------------------------------------------------------
    -- UI
    ----------------------------------------------------------------
    -- Home icon (download -> asset, fallback to lucide "home")
    local homeIcon = "home"
    pcall(function()
        if writefile and getcustomasset then
            if not (isfile and isfile("cora_home.png")) then
                writefile("cora_home.png", game:HttpGet(
                    "https://i.ibb.co/Qz0ZKBh/home-1000dp-E3-E3-E3-FILL0-wght400-GRAD0-opsz48.png"
                ))
            end
            homeIcon = getcustomasset("cora_home.png")
        end
    end)

    local MainTab = Window:AddTab("Main", homeIcon, "Main Features")
    Cora.Tabs.Main = MainTab

    local Movement = MainTab:AddLeftGroupbox("Movement", "footprints")

    -- Walk Speed toggle + slider (slider greyed while disabled)
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
        Disabled = true, -- starts greyed since the toggle is off
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
        Tooltip = "Massless bypass. Lets Walk Speed go up to 100.",
    })

    Movement:AddToggle("Fly", {
        Text    = "Fly",
        Default = false,
        Tooltip = "Fly using the camera direction. Bindable below.",
    })
    -- Bindable keybind for Fly, unbound by default
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
    -- Logic (decoupled from UI creation)
    ----------------------------------------------------------------
    -- Grey/un-grey the Walk Speed slider with its toggle
    Toggles.WalkSpeedEnabled:OnChanged(function()
        local on = Toggles.WalkSpeedEnabled.Value
        pcall(function() Options.WalkSpeedValue:SetDisabled(not on) end)
        if not on and humanoid then
            humanoid.WalkSpeed = DEFAULT_SPEED -- restore game default
        end
    end)

    -- Speed Bypass: massless on/off + extend the Walk Speed slider max
    Toggles.SpeedBypass:OnChanged(function()
        local on = Toggles.SpeedBypass.Value
        applyMassless(on)
        pcall(function()
            if Options.WalkSpeedValue.SetMax then
                Options.WalkSpeedValue:SetMax(on and 100 or 25)
            else
                Options.WalkSpeedValue.Max = on and 100 or 25
            end
        end)
        if not on and Options.WalkSpeedValue.Value > 25 then
            pcall(function() Options.WalkSpeedValue:SetValue(25) end)
        end
    end)

    -- Fly on/off
    Toggles.Fly:OnChanged(function()
        flyEnabled = Toggles.Fly.Value
        if flyEnabled then startFly() else stopFly() end
    end)

    -- Apply walk speed continuously while enabled
    RunService.Heartbeat:Connect(function()
        if humanoid and Toggles.WalkSpeedEnabled.Value then
            humanoid.WalkSpeed = Options.WalkSpeedValue.Value
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
        if flyEnabled and flyBV and flyBG then
            local cam = workspace.CurrentCamera
            flyBG.CFrame = cam.CFrame

            local dir = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W)          then dir += cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S)          then dir -= cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A)          then dir -= cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D)          then dir += cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space)      then dir += Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.new(0, 1, 0) end

            if dir.Magnitude > 0 then dir = dir.Unit end
            flyBV.Velocity = dir * Options.FlySpeed.Value
        end
    end)
end

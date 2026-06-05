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
    -- Home icon: byte-for-byte the same simple method as the working
    -- Settings gear (no validation, no SetDescription). Falls back to
    -- lucide "house" if the executor lacks custom assets.
    ----------------------------------------------------------------
    pcall(function()
        if makefolder and not (isfolder and isfolder("CoraData")) then
            makefolder("CoraData")
        end
    end)
    local homeIcon = "house"
    pcall(function()
        if writefile and getcustomasset then
            local path = "CoraData/cora_main.png"
            if not (isfile and isfile(path)) then
                writefile(path, game:HttpGet(
                    "https://i.ibb.co/hRzVz0b9/home-100dp-E3-E3-E3-FILL0-wght400-GRAD0-opsz48.png"
                ))
            end
            homeIcon = getcustomasset(path)
        end
    end)

    local MainTab = Window:AddTab("Main", homeIcon)
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

    -- Prompt Exploits group (right side, next to Movement)
    local Prompts = MainTab:AddRightGroupbox("Prompt Exploits", "zap")

    Prompts:AddToggle("PromptClip", {
        Text    = "Prompt Clip",
        Default = false,
        Tooltip = "Interact with some prompts through walls.",
    })

    Prompts:AddToggle("PromptRange", {
        Text    = "Prompt Range",
        Default = false,
        Tooltip = "Trigger prompts from further away.",
    })

    Prompts:AddSlider("PromptRangeMult", {
        Text     = "Prompt Range Multiplier",
        Default  = 2,
        Min      = 1.1,
        Max      = 2,
        Rounding = 1,
        Suffix   = "x",
        Disabled = true, -- greyed until Prompt Range is enabled
        Tooltip  = "Multiplies prompt activation distance. ~2x is the Doors limit.",
        DisabledTooltip = "Enable Prompt Range first.",
    })

    Prompts:AddToggle("InstantPrompt", {
        Text    = "Instant Prompt",
        Default = false,
        Tooltip = "Removes hold time (key doors, levers, etc. trigger instantly).",
    })

    Prompts:AddToggle("AutoPrompt", {
        Text    = "Auto Prompt",
        Default = false,
        Tooltip = "Automatically triggers nearby prompts (chests, doors, pickups).",
    })
    Toggles.AutoPrompt:AddKeyPicker("AutoPromptKeybind", {
        Default         = "None", -- nothing bound by default
        SyncToggleState = true,
        Mode            = "Toggle",
        Text            = "Auto Prompt",
        NoUI            = false,
    })

    Prompts:AddDropdown("AutoPromptIgnore", {
        Values  = { "Jeff Items", "Gold", "Drops", "Glitch Fragment",
                    "Paintings", "Light Source Items", "Skull Prompts", "Hiding Places", "Rifts" },
        Default = {},
        Multi   = true,
        Text    = "Auto Prompt Ignore",
        Tooltip = "Selected categories are never auto-triggered.",
    })

    Prompts:AddSlider("AutoPromptInterval", {
        Text     = "Auto Prompt Interval",
        Default  = 0.05,
        Min      = 0,
        Max      = 0.15,
        Rounding = 2,
        Suffix   = "s",
        Tooltip  = "Delay between auto triggers. 0 = every frame.",
    })

    -- Useful group (left, under Movement)
    local Useful = MainTab:AddLeftGroupbox("Useful", "wrench")

    Useful:AddToggle("AutoHeartbeat", {
        Text    = "Auto Heartbeat Mini-Game",
        Default = false,
        Tooltip = "Automatically passes the Figure heartbeat mini-game.",
    })

    Useful:AddToggle("AutoSolveLibrary", {
        Text    = "Auto Solve Library",
        Default = false,
        Tooltip = "Door 50: once every book is collected, opens the locked door when you're near it.",
    })

    Useful:AddToggle("AutoBreaker", {
        Text    = "Auto Breaker Box",
        Default = false,
        Tooltip = "Automatically completes the breaker box (legit method).",
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

    ----------------------------------------------------------------
    -- Prompt Exploits logic
    ----------------------------------------------------------------
    local fireprompt = fireproximityprompt -- executor fn (may be nil)

    local function getPromptPart(p)
        local par = p.Parent
        if not par then return nil end
        if par:IsA("BasePart") then return par end
        if par:IsA("Model") and par.PrimaryPart then return par.PrimaryPart end
        local bp = par:FindFirstChildWhichIsA("BasePart")
        if bp then return bp end
        -- walk up to the nearest BasePart ancestor (covers cabinets/drawers)
        local a = par.Parent
        while a and a ~= workspace and a ~= game do
            if a:IsA("BasePart") then return a end
            if a:IsA("Model") and a.PrimaryPart then return a.PrimaryPart end
            a = a.Parent
        end
        return nil
    end

    -- Store originals in attributes so the three toggles don't clash on restore
    local function applyClip(p, on)
        if on then
            if p:GetAttribute("CoraClip") == nil then
                p:SetAttribute("CoraClip", p.RequiresLineOfSight)
            end
            p.RequiresLineOfSight = false
        else
            local o = p:GetAttribute("CoraClip")
            if o ~= nil then p.RequiresLineOfSight = o; p:SetAttribute("CoraClip", nil) end
        end
    end

    local function applyRange(p, on, mult)
        if on then
            if p:GetAttribute("CoraRange") == nil then
                p:SetAttribute("CoraRange", p.MaxActivationDistance)
            end
            p.MaxActivationDistance = (p:GetAttribute("CoraRange") or p.MaxActivationDistance) * mult
        else
            local o = p:GetAttribute("CoraRange")
            if o ~= nil then p.MaxActivationDistance = o; p:SetAttribute("CoraRange", nil) end
        end
    end

    local function applyInstant(p, on)
        if on then
            if p:GetAttribute("CoraDur") == nil then
                p:SetAttribute("CoraDur", p.HoldDuration)
            end
            p.HoldDuration = 0
        else
            local o = p:GetAttribute("CoraDur")
            if o ~= nil then p.HoldDuration = o; p:SetAttribute("CoraDur", nil) end
        end
    end

    local function eachPrompt(fn)
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("ProximityPrompt") then pcall(fn, v) end
        end
    end

    Toggles.PromptClip:OnChanged(function()
        local on = Toggles.PromptClip.Value
        eachPrompt(function(p) applyClip(p, on) end)
    end)

    Toggles.PromptRange:OnChanged(function()
        local on = Toggles.PromptRange.Value
        pcall(function() Options.PromptRangeMult:SetDisabled(not on) end)
        eachPrompt(function(p) applyRange(p, on, Options.PromptRangeMult.Value) end)
    end)

    Options.PromptRangeMult:OnChanged(function()
        if Toggles.PromptRange.Value then
            eachPrompt(function(p) applyRange(p, true, Options.PromptRangeMult.Value) end)
        end
    end)

    Toggles.InstantPrompt:OnChanged(function()
        local on = Toggles.InstantPrompt.Value
        eachPrompt(function(p) applyInstant(p, on) end)
    end)

    -- Auto Prompt ignore categories
    local LightSources = {
        Flashlight = true, Candle = true, Lighter = true, Lantern = true,
        Bulklight = true, Straplight = true, Shakelight = true,
        Glowsticks = true, LaserPointer = true,
    }
    local HidingPlaces = {
        Wardrobe = true, Rooms_Locker = true, Rooms_Locker_Fridge = true,
        Locker_Large = true, Backdoor_Wardrobe = true, Bed = true,
        Double_Bed = true, Toolshed = true, RetroWardrobe = true,
        CircularVent = true,
    }
    local function isIgnored(p)
        -- Always skip the revive prompt: it spams and fires while dead.
        if p.Name == "RevivePrompt" then return true end
        local ig = Options.AutoPromptIgnore.Value
        if type(ig) ~= "table" then return false end
        local par = p.Parent
        local pname = par and par.Name or ""
        if ig["Gold"] and pname == "GoldPile" then return true end
        if ig["Jeff Items"] and par and par:GetAttribute("JeffShop") then return true end
        if ig["Drops"] then
            local drops = workspace:FindFirstChild("Drops")
            if drops and p:IsDescendantOf(drops) then return true end
        end
        if ig["Glitch Fragment"] and (pname:find("Glitch") or pname:find("Fragment")) then return true end
        if ig["Paintings"] and pname:find("Painting") then return true end
        if ig["Light Source Items"] and LightSources[pname] then return true end
        if ig["Skull Prompts"] and (pname == "SkullLock" or pname:find("Skull")) then return true end
        if ig["Hiding Places"] and (p.Name == "HidePrompt" or HidingPlaces[pname]) then return true end
        if ig["Rifts"] and (p.Name == "RiftPrompt" or p.Name == "StarRiftPrompt" or pname:find("Rift")) then return true end
        return false
    end

    -- Best-effort auto-equip a key/skeleton key for lock/door prompts (Doors-specific)
    local LockNames = {
        Lock = true, Lock1 = true, Lock2 = true, SkullLock = true,
        ChestBoxLocked = true, Toolbox_Locked = true,
    }
    local function tryEquipFor(p)
        local char = LP.Character
        if not char then return end
        local par = p.Parent
        local pname = par and par.Name or ""
        if not (LockNames[pname] or pname:find("Lock") or pname:find("Key") or pname:find("Door")) then
            return
        end
        -- already holding something usable?
        if char:FindFirstChild("Key") or char:FindFirstChild("SkeletonKey")
            or char:FindFirstChild("Lockpick") then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local bp  = LP:FindFirstChild("Backpack")
        local tool = bp and (bp:FindFirstChild("Key") or bp:FindFirstChild("SkeletonKey")
            or bp:FindFirstChild("Lockpick"))
        if tool and hum then pcall(function() hum:EquipTool(tool) end) end
    end

    local function firePrompt(p)
        if fireprompt then
            pcall(fireprompt, p)
        else
            pcall(function()
                p:InputHoldBegin()
                task.wait(p.HoldDuration or 0)
                p:InputHoldEnd()
            end)
        end
    end

    -- Collected prompts for Auto Prompt (kept in sync with the world)
    local interactions = {}
    local fired = {} -- prompts already triggered this session (prevents cabinet open/close spam)
    local function rebuildInteractions()
        table.clear(interactions)
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("ProximityPrompt") then table.insert(interactions, v) end
        end
    end

    Toggles.AutoPrompt:OnChanged(function()
        if Toggles.AutoPrompt.Value then rebuildInteractions() else table.clear(interactions) end
        table.clear(fired)
    end)

    -- Apply settings to newly-spawned prompts and track them for Auto Prompt
    workspace.DescendantAdded:Connect(function(v)
        if not v:IsA("ProximityPrompt") then return end
        task.defer(function()
            if not v.Parent then return end
            if Toggles.PromptClip.Value    then pcall(applyClip, v, true) end
            if Toggles.PromptRange.Value   then pcall(applyRange, v, true, Options.PromptRangeMult.Value) end
            if Toggles.InstantPrompt.Value then pcall(applyInstant, v, true) end
            if Toggles.AutoPrompt.Value    then table.insert(interactions, v) end
        end)
    end)

    workspace.DescendantRemoving:Connect(function(v)
        if not v:IsA("ProximityPrompt") then return end
        fired[v] = nil
        for i = #interactions, 1, -1 do
            if interactions[i] == v then table.remove(interactions, i); break end
        end
    end)

    -- Auto Prompt loop
    local AUTO_REACH = 18 -- min reach so cabinets/drawers work even without Prompt Range
    local autoTimer = 0
    RunService.Heartbeat:Connect(function(dt)
        if not Toggles.AutoPrompt.Value then return end
        if LP:GetAttribute("Alive") == false then return end -- never auto-fire while dead
        autoTimer += dt
        if autoTimer < Options.AutoPromptInterval.Value then return end
        autoTimer = 0

        local char = LP.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end

        for i = #interactions, 1, -1 do
            local p = interactions[i]
            if not p or not p.Parent then
                table.remove(interactions, i)
            elseif not fired[p] and not isIgnored(p) then
                local part = getPromptPart(p)
                if part then
                    local reach = math.max(p.MaxActivationDistance, AUTO_REACH)
                    local dist = (root.Position - part.Position).Magnitude
                    if dist <= reach then
                        if not p.Enabled then pcall(function() p.Enabled = true end) end
                        tryEquipFor(p)
                        firePrompt(p)
                        fired[p] = true -- fire each prompt once (no cabinet open/close spam)
                    end
                end
            end
        end
    end)

    ----------------------------------------------------------------
    -- Useful logic (Doors-specific; everything guarded for other games/lobby)
    ----------------------------------------------------------------
    -- Read the full library code from the hint paper ("_" for missing slots)
    local function getLibraryCode()
        local gd    = ReplicatedStorage:FindFirstChild("GameData")
        local floor = gd and gd:FindFirstChild("Floor")
        local codeLen = (floor and floor.Value == "Fools") and 10 or 5
        local slot = table.create(codeLen, "_")

        local paper
        for _, plr in ipairs(Players:GetPlayers()) do
            local ch = plr.Character
            local bp = plr:FindFirstChild("Backpack")
            paper = (ch and (ch:FindFirstChild("LibraryHintPaper") or ch:FindFirstChild("LibraryHintPaperHard")))
                 or (bp and (bp:FindFirstChild("LibraryHintPaper") or bp:FindFirstChild("LibraryHintPaperHard")))
            if paper then break end
        end
        if not (paper and paper:FindFirstChild("UI")) then return table.concat(slot) end

        local pg     = LP:FindFirstChild("PlayerGui")
        local permUI = pg and pg:FindFirstChild("PermUI")
        local hintsF = permUI and permUI:FindFirstChild("Hints")
        if not hintsF then return table.concat(slot) end
        local hints = hintsF:GetChildren()

        for _, i in ipairs(paper.UI:GetChildren()) do
            if i:IsA("ImageLabel") and i.Name ~= "Image" then
                local pos = tonumber(i.Name)
                if pos and slot[pos] then
                    for _, v in ipairs(hints) do
                        if v.Name == "Icon" and v.ImageRectOffset.X == i.ImageRectOffset.X then
                            local label = v:FindFirstChild("TextLabel")
                            if label then slot[pos] = label.Text end
                            break
                        end
                    end
                end
            end
        end
        return table.concat(slot)
    end

    -- Auto Solve Library: submit the full code when near the Door 50 lock
    local libTimer = 0
    RunService.Heartbeat:Connect(function(dt)
        if not Toggles.AutoSolveLibrary.Value then return end
        libTimer += dt
        if libTimer < 0.4 then return end
        libTimer = 0
        pcall(function()
            local gd     = ReplicatedStorage:FindFirstChild("GameData")
            local latest = gd and gd:FindFirstChild("LatestRoom")
            if not latest or latest.Value ~= 50 then return end

            local code = getLibraryCode()
            if not code or code:find("_") then return end -- not all books collected yet

            local char = LP.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if not root then return end

            local near = true
            local rooms = workspace:FindFirstChild("CurrentRooms")
            local room50 = rooms and rooms:FindFirstChild("50")
            local door = room50 and room50:FindFirstChild("Door")
            local doorPart = door and door:FindFirstChild("Door")
            if doorPart then
                near = (root.Position - doorPart.Position).Magnitude < 35
            end

            if near then
                local rf = getRemotes()
                local PL = rf and rf:FindFirstChild("PL")
                if PL then PL:FireServer(code) end
            end
        end)
    end)

    -- Auto Breaker Box (legit method, ported from public Doors scripts)
    local function breaker(part)
        pcall(function()
            local gui = part:WaitForChild("SurfaceGui", 5)
            if not gui then return end
            local codeLabel = gui:WaitForChild("Frame"):WaitForChild("Code")

            local function run()
                task.wait(0.05)
                if not Toggles.AutoBreaker.Value then return end
                local target = tonumber(codeLabel.Text)
                if not target then return end
                for _, v in ipairs(part:GetChildren()) do
                    if v.Name == "BreakerSwitch" and v:GetAttribute("ID") == target then
                        local cf    = codeLabel:FindFirstChild("Frame")
                        local trans = cf and cf.BackgroundTransparency
                        local pc    = v:FindFirstChild("PrismaticConstraint")
                        local light = v:FindFirstChild("Light")
                        local snd   = v:FindFirstChild("Sound")
                        if trans == 0 then
                            if v:GetAttribute("Enabled") then return end
                            v:SetAttribute("Enabled", true)
                            if pc then pc.TargetPosition = -0.2 end
                            if light then
                                light.Material = Enum.Material.Neon
                                local spark = light:FindFirstChild("Spark", true)
                                if spark then spark:Emit(1) end
                            end
                            if snd then snd:Play() end
                        elseif trans == 1 then
                            if not v:GetAttribute("Enabled") then return end
                            v:SetAttribute("Enabled", false)
                            if pc then pc.TargetPosition = 0.2 end
                            if light then light.Material = Enum.Material.Glass end
                            if snd then snd:Play() end
                        end
                        break
                    end
                end
            end

            codeLabel:GetPropertyChangedSignal("Text"):Connect(run)
            run()
        end)
    end

    Toggles.AutoBreaker:OnChanged(function()
        if not Toggles.AutoBreaker.Value then return end
        local rooms = workspace:FindFirstChild("CurrentRooms")
        if rooms then
            for _, v in ipairs(rooms:GetDescendants()) do
                if v.Name == "ElevatorBreaker" then breaker(v) end
            end
        end
    end)

    workspace.DescendantAdded:Connect(function(v)
        if v.Name == "ElevatorBreaker" and Toggles.AutoBreaker.Value then
            breaker(v)
        end
    end)

    -- Auto Heartbeat: force a perfect beat by intercepting the game's own remote call
    if hookmetamethod and getnamecallmethod then
        local old
        old = hookmetamethod(game, "__namecall", function(self, ...)
            if not (Library and Library.Unloaded)
               and Toggles.AutoHeartbeat and Toggles.AutoHeartbeat.Value then
                if getnamecallmethod() == "FireServer" and self.Name == "ClutchHeartbeat" then
                    return old(self, true)
                end
            end
            return old(self, ...)
        end)
    end
end

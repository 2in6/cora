--[[
    Cora • TAB FILE: Main  —  goes in /maintab.lua
    (This is a TAB file, NOT the bootstrap. The bootstrap lives in main.lua.)
    Movement / Prompt Exploits / Useful / Manual.
    Toggle effects driven by a state-watcher loop (no re-toggle needed).
    Auto Prompt scans the prompt list and fires every prompt within its REAL
    (pre-Prompt-Range) activation distance, so Prompt Range can't break it and
    containers/tables aren't blocked by prompt exclusivity.
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
    local TeleportService  = game:GetService("TeleportService")
    local LP               = Players.LocalPlayer

    ----------------------------------------------------------------
    -- State-watcher: runs fn(value) once at startup and on every change
    ----------------------------------------------------------------
    local _watch = {}
    local function watch(getter, fn) table.insert(_watch, { get = getter, last = nil, fn = fn }) end
    RunService.Heartbeat:Connect(function()
        for _, w in ipairs(_watch) do
            local ok, v = pcall(w.get)
            if ok and v ~= w.last then
                w.last = v
                pcall(w.fn, v)
            end
        end
    end)
    local function tval(idx) return function() return Toggles[idx] and Toggles[idx].Value end end
    local function oval(idx) return function() return Options[idx] and Options[idx].Value end end

    ----------------------------------------------------------------
    -- State
    ----------------------------------------------------------------
    local character, humanoid, hrp
    local DEFAULT_SPEED = 16
    local flyEnabled = false
    local flyBV
    local CollisionClone

    ----------------------------------------------------------------
    -- Fly helpers
    ----------------------------------------------------------------
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

    ----------------------------------------------------------------
    -- Doors remotes + collision clone
    ----------------------------------------------------------------
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
        CollisionClone = nil
        if flyEnabled then startFly() end
    end
    LP.CharacterAdded:Connect(onCharacter)
    if LP.Character then task.spawn(onCharacter, LP.Character) end

    ----------------------------------------------------------------
    -- Manual action helpers
    ----------------------------------------------------------------
    local function killSelf()
        pcall(function()
            local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.Health = 0 end
        end)
    end

    local function reviveSelf()
        pcall(function()
            local rf = getRemotes()
            if not rf then return end
            for _, n in ipairs({ "Revive", "ReviveCharacter", "RevivePlayer", "ReviveSelf" }) do
                local r = rf:FindFirstChild(n)
                if r then
                    if r:IsA("RemoteEvent") then r:FireServer(LP)
                    elseif r:IsA("RemoteFunction") then r:InvokeServer(LP) end
                    return
                end
            end
        end)
    end

    -- Trigger a GUI button's handlers directly (no real mouse click needed)
    local function fireButton(b)
        local sigs = { "MouseButton1Click", "Activated", "MouseButton1Down", "MouseButton1Up" }
        if getconnections then
            for _, s in ipairs(sigs) do
                pcall(function()
                    for _, c in ipairs(getconnections(b[s])) do
                        if c.Fire then c:Fire() elseif c.Function then c.Function() end
                    end
                end)
            end
        end
        if firesignal then
            for _, s in ipairs(sigs) do pcall(function() firesignal(b[s]) end) end
        end
    end

    -- Build a searchable label from the button text, its name, and child label text
    local function buttonLabel(b)
        local s = (((b:IsA("TextButton")) and b.Text) or "") .. " " .. b.Name
        for _, d in ipairs(b:GetDescendants()) do
            if d:IsA("TextLabel") or d:IsA("TextButton") then s = s .. " " .. d.Text end
        end
        return s:lower()
    end

    local function clickButton(matches)
        local pg = LP:FindFirstChild("PlayerGui")
        if not pg then return false end
        local hit = false
        for _, b in ipairs(pg:GetDescendants()) do
            if b:IsA("GuiButton") then
                local label = buttonLabel(b)
                for _, m in ipairs(matches) do
                    if label:find(m) then fireButton(b); hit = true; break end
                end
            end
        end
        return hit
    end
    local function playAgain()
        local ok = clickButton({ "play again", "playagain", "play_again", "again", "retry", "rejoin", "restart" })
        if not ok then
            pcall(function() TeleportService:Teleport(game.PlaceId, LP) end) -- fallback: rejoin
        end
    end
    local function lobby() clickButton({ "lobby", "menu", "leave", "exit", "main menu" }) end

    ----------------------------------------------------------------
    -- Prompt helpers
    ----------------------------------------------------------------
    local fireprompt = fireproximityprompt -- executor fn (may be nil)

    local function getPromptPart(p)
        local par = p.Parent
        if not par then return nil end
        if par:IsA("BasePart") then return par end
        if par:IsA("Model") and par.PrimaryPart then return par.PrimaryPart end
        local bp = par:FindFirstChildWhichIsA("BasePart")
        if bp then return bp end
        local a = par.Parent
        while a and a ~= workspace and a ~= game do
            if a:IsA("BasePart") then return a end
            if a:IsA("Model") and a.PrimaryPart then return a.PrimaryPart end
            a = a.Parent
        end
        return nil
    end

    local function applyClip(p, on)
        if on then
            if p:GetAttribute("CoraClip") == nil then p:SetAttribute("CoraClip", p.RequiresLineOfSight) end
            p.RequiresLineOfSight = false
        else
            local o = p:GetAttribute("CoraClip")
            if o ~= nil then p.RequiresLineOfSight = o; p:SetAttribute("CoraClip", nil) end
        end
    end
    local function applyRange(p, on, mult)
        if on then
            if p:GetAttribute("CoraRange") == nil then p:SetAttribute("CoraRange", p.MaxActivationDistance) end
            p.MaxActivationDistance = (p:GetAttribute("CoraRange") or p.MaxActivationDistance) * mult
        else
            local o = p:GetAttribute("CoraRange")
            if o ~= nil then p.MaxActivationDistance = o; p:SetAttribute("CoraRange", nil) end
        end
    end
    local function applyInstant(p, on)
        if on then
            if p:GetAttribute("CoraDur") == nil then p:SetAttribute("CoraDur", p.HoldDuration) end
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
    -- the REAL (server-side) activation distance, ignoring any Prompt Range boost
    local function realDistance(p)
        return p:GetAttribute("CoraRange") or p.MaxActivationDistance
    end

    local LightSources = {
        Flashlight = true, Candle = true, Lighter = true, Lantern = true,
        Bulklight = true, Straplight = true, Shakelight = true,
        Glowsticks = true, LaserPointer = true,
    }
    local HidingPlaces = {
        Wardrobe = true, Rooms_Locker = true, Rooms_Locker_Fridge = true,
        Locker_Large = true, Backdoor_Wardrobe = true, Bed = true,
        Double_Bed = true, Toolshed = true, RetroWardrobe = true, CircularVent = true,
    }
    local function isIgnored(p)
        if p.Name == "RevivePrompt" then return true end
        local ig = Options.AutoPromptIgnore and Options.AutoPromptIgnore.Value
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

    -- door/lock prompts need a key + can need several tries, so they retry on a
    -- cooldown instead of fire-once
    local function isDoorLike(p)
        local n = (((p.Parent and p.Parent.Name) or "") .. " " .. p.Name):lower()
        return (n:find("door") or n:find("lock") or n:find("gate")) ~= nil
    end

    local LockNames = {
        Lock = true, Lock1 = true, Lock2 = true, SkullLock = true,
        ChestBoxLocked = true, Toolbox_Locked = true,
    }
    local function tryEquipFor(p)
        local char = LP.Character
        if not char then return end
        local par = p.Parent
        local pname = par and par.Name or ""
        if not (LockNames[pname] or pname:find("Lock") or pname:find("Key") or pname:find("Door")) then return end
        if char:FindFirstChild("Key") or char:FindFirstChild("SkeletonKey") or char:FindFirstChild("Lockpick") then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local bp  = LP:FindFirstChild("Backpack")
        local tool = bp and (bp:FindFirstChild("Key") or bp:FindFirstChild("SkeletonKey") or bp:FindFirstChild("Lockpick"))
        if tool and hum then pcall(function() hum:EquipTool(tool) end) end
    end

    local function firePrompt(p)
        if not p.Enabled then pcall(function() p.Enabled = true end) end
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

    -- collected prompts + per-prompt fire bookkeeping
    local interactions = {}
    local fired = {}     -- pickups/cabinets: fired once until you leave range
    local cooldown = {}  -- door/lock: last attempt time
    local function rebuildInteractions()
        table.clear(interactions)
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("ProximityPrompt") then table.insert(interactions, v) end
        end
    end

    ----------------------------------------------------------------
    -- Useful helpers
    ----------------------------------------------------------------
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

    local function breaker(part)
        pcall(function()
            local gui = part:WaitForChild("SurfaceGui", 5)
            if not gui then return end
            local codeLabel = gui:WaitForChild("Frame"):WaitForChild("Code")
            local function run()
                task.wait(0.05)
                if not (Toggles.AutoBreaker and Toggles.AutoBreaker.Value) then return end
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

    ----------------------------------------------------------------
    -- Tab + UI
    ----------------------------------------------------------------
    local MainTab = Window:AddTab("Main", "house")
    Cora.Tabs.Main = MainTab

    local Movement = MainTab:AddLeftGroupbox("Movement", "footprints")
    Movement:AddToggle("WalkSpeedEnabled", { Text = "Walk Speed", Default = false })
    Movement:AddSlider("WalkSpeedValue", { Text = "Walk Speed", Default = 16, Min = 16, Max = 25, Rounding = 0, Disabled = true })
    Movement:AddToggle("FastStop", { Text = "Fast Stop", Default = false })
    Movement:AddToggle("SpeedBypass", { Text = "Speed Bypass", Default = false })
    Movement:AddToggle("Fly", { Text = "Fly", Default = false })
    Toggles.Fly:AddKeyPicker("FlyKeybind", { Default = "None", SyncToggleState = true, Mode = "Toggle", Text = "Fly", NoUI = false })
    Movement:AddSlider("FlySpeed", { Text = "Fly Speed", Default = 16, Min = 16, Max = 100, Rounding = 0 })

    local Prompts = MainTab:AddRightGroupbox("Prompt Exploits", "zap")
    Prompts:AddToggle("PromptClip", { Text = "Prompt Clip", Default = false })
    Prompts:AddToggle("PromptRange", { Text = "Prompt Range", Default = false })
    Prompts:AddSlider("PromptRangeMult", { Text = "Prompt Range Multiplier", Default = 2, Min = 1.1, Max = 2, Rounding = 1, Suffix = "x", Disabled = true })
    Prompts:AddToggle("InstantPrompt", { Text = "Instant Prompt", Default = false })
    Prompts:AddToggle("AutoPrompt", { Text = "Auto Prompt", Default = false })
    Toggles.AutoPrompt:AddKeyPicker("AutoPromptKeybind", { Default = "None", SyncToggleState = true, Mode = "Toggle", Text = "Auto Prompt", NoUI = false })
    Prompts:AddDropdown("AutoPromptIgnore", {
        Values  = { "Jeff Items", "Gold", "Drops", "Glitch Fragment",
                    "Paintings", "Light Source Items", "Skull Prompts", "Hiding Places", "Rifts" },
        Default = {}, Multi = true, Text = "Auto Prompt Ignore",
    })
    Prompts:AddSlider("AutoPromptInterval", { Text = "Auto Prompt Interval", Default = 0.05, Min = 0, Max = 0.15, Rounding = 2, Suffix = "s" })

    local Useful = MainTab:AddLeftGroupbox("Useful", "wrench")
    Useful:AddToggle("AutoHeartbeat", { Text = "Auto Heartbeat Mini-Game", Default = false })
    Useful:AddToggle("AutoSolveLibrary", { Text = "Auto Solve Library", Default = false })
    Useful:AddToggle("AutoBreaker", { Text = "Auto Breaker Box", Default = false })

    local Manual = MainTab:AddRightGroupbox("Manual", "hand")
    Manual:AddButton({ Text = "Kill Self",  Func = killSelf })
    Manual:AddButton({ Text = "Revive",     Func = reviveSelf })
    Manual:AddButton({ Text = "Play Again", Func = playAgain })
    Manual:AddButton({ Text = "Lobby",      Func = lobby })

    ----------------------------------------------------------------
    -- Toggle effects (state-watcher)
    ----------------------------------------------------------------
    watch(tval("WalkSpeedEnabled"), function(v)
        pcall(function() Options.WalkSpeedValue:SetDisabled(not v) end)
        if not v and humanoid then humanoid.WalkSpeed = DEFAULT_SPEED end
    end)

    watch(tval("SpeedBypass"), function(v)
        pcall(function()
            if Options.WalkSpeedValue.SetMax then Options.WalkSpeedValue:SetMax(v and 100 or 25)
            else Options.WalkSpeedValue.Max = v and 100 or 25 end
        end)
        if not v then
            if Options.WalkSpeedValue.Value > 25 then pcall(function() Options.WalkSpeedValue:SetValue(25) end) end
            pcall(function()
                local rf = getRemotes()
                local crouch = rf and rf:FindFirstChild("Crouch")
                if crouch then crouch:FireServer(false) end
            end)
            pcall(function() if CollisionClone and CollisionClone.Parent then CollisionClone.Massless = false end end)
        end
    end)

    watch(tval("Fly"), function(v) flyEnabled = v; if v then startFly() else stopFly() end end)

    watch(tval("PromptClip"), function(v) eachPrompt(function(p) applyClip(p, v) end) end)
    watch(tval("PromptRange"), function(v)
        pcall(function() Options.PromptRangeMult:SetDisabled(not v) end)
        eachPrompt(function(p) applyRange(p, v, Options.PromptRangeMult.Value) end)
    end)
    watch(oval("PromptRangeMult"), function(v)
        if Toggles.PromptRange and Toggles.PromptRange.Value then
            eachPrompt(function(p) applyRange(p, true, v) end)
        end
    end)
    watch(tval("InstantPrompt"), function(v) eachPrompt(function(p) applyInstant(p, v) end) end)

    watch(tval("AutoPrompt"), function(v)
        if v then rebuildInteractions() else table.clear(interactions) end
        table.clear(fired); table.clear(cooldown)
    end)

    watch(tval("AutoBreaker"), function(v)
        if not v then return end
        local rooms = workspace:FindFirstChild("CurrentRooms")
        if rooms then
            for _, b in ipairs(rooms:GetDescendants()) do
                if b.Name == "ElevatorBreaker" then breaker(b) end
            end
        end
    end)

    ----------------------------------------------------------------
    -- World connections
    ----------------------------------------------------------------
    workspace.DescendantAdded:Connect(function(v)
        if v:IsA("ProximityPrompt") then
            task.defer(function()
                if not v.Parent then return end
                if Toggles.PromptClip.Value    then pcall(applyClip, v, true) end
                if Toggles.PromptRange.Value   then pcall(applyRange, v, true, Options.PromptRangeMult.Value) end
                if Toggles.InstantPrompt.Value then pcall(applyInstant, v, true) end
                if Toggles.AutoPrompt.Value    then table.insert(interactions, v) end
            end)
        elseif v.Name == "ElevatorBreaker" and Toggles.AutoBreaker.Value then
            breaker(v)
        end
    end)
    workspace.DescendantRemoving:Connect(function(v)
        if not v:IsA("ProximityPrompt") then return end
        fired[v] = nil; cooldown[v] = nil
        for i = #interactions, 1, -1 do
            if interactions[i] == v then table.remove(interactions, i); break end
        end
    end)

    ----------------------------------------------------------------
    -- Auto Prompt loop (fires within REAL range; Prompt Range can't break it)
    ----------------------------------------------------------------
    local autoTimer = 0
    RunService.Heartbeat:Connect(function(dt)
        if not Toggles.AutoPrompt.Value then return end
        if LP:GetAttribute("Alive") == false then return end
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
            else
                local part = getPromptPart(p)
                if part then
                    local dist = (root.Position - part.Position).Magnitude
                    local reach = realDistance(p)
                    if dist <= reach and not isIgnored(p) then
                        if isDoorLike(p) then
                            -- equip a key, give it a beat to register, then fire; retry on cooldown
                            if tick() - (cooldown[p] or 0) >= 0.8 then
                                cooldown[p] = tick()
                                task.spawn(function()
                                    tryEquipFor(p)
                                    task.wait(0.2)
                                    if Toggles.AutoPrompt.Value and p.Parent then firePrompt(p) end
                                end)
                            end
                        elseif not fired[p] then
                            fired[p] = true
                            firePrompt(p)
                        end
                    elseif dist > reach then
                        fired[p] = nil -- left range; allow it to fire again next time
                    end
                end
            end
        end
    end)

    ----------------------------------------------------------------
    -- Runtime loops
    ----------------------------------------------------------------
    RunService.Heartbeat:Connect(function()
        if humanoid and Toggles.WalkSpeedEnabled.Value then
            if humanoid.WalkSpeed ~= Options.WalkSpeedValue.Value then
                humanoid.WalkSpeed = Options.WalkSpeedValue.Value
            end
        end
    end)

    task.spawn(function()
        while true do
            task.wait()
            if Library.Unloaded then break end
            pcall(function()
                if not Toggles.SpeedBypass.Value then return end
                if not (character and character.Parent) then return end
                if LP:GetAttribute("Alive") == false then return end
                ensureCollisionClone()
                if CollisionClone and CollisionClone.Parent then CollisionClone.Massless = true end
                local rf = getRemotes()
                local crouch = rf and rf:FindFirstChild("Crouch")
                if crouch then crouch:FireServer(true, true) end
            end)
        end
    end)

    RunService.RenderStepped:Connect(function()
        if not flyEnabled and Toggles.FastStop.Value and humanoid and hrp then
            if humanoid.MoveDirection.Magnitude == 0 then
                local v = hrp.AssemblyLinearVelocity
                hrp.AssemblyLinearVelocity = Vector3.new(0, v.Y, 0)
            end
        end
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
            if not code or code:find("_") then return end
            local char = LP.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if not root then return end
            local near = true
            local rooms = workspace:FindFirstChild("CurrentRooms")
            local room50 = rooms and rooms:FindFirstChild("50")
            local door = room50 and room50:FindFirstChild("Door")
            local doorPart = door and door:FindFirstChild("Door")
            if doorPart then near = (root.Position - doorPart.Position).Magnitude < 35 end
            if near then
                local rf = getRemotes()
                local PL = rf and rf:FindFirstChild("PL")
                if PL then PL:FireServer(code) end
            end
        end)
    end)

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

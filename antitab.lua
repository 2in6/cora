--[[
    Cora • TAB FILE: Anti  —  goes in /antitab.lua
    (This is a TAB file, NOT the bootstrap. The bootstrap lives in main.lua.)
    Anti-entity / anti-mechanic toggles, wired from the Supreme Hub reference.
    Each toggle's state is mirrored into `state` by the watcher; swap-style ones
    (Screech/Dread/Halt) and CanTouch ones fire an onChange handler, while the
    damage-spoof ones (Eyes/Lookman/Figure Hearing) run in a per-frame loop.
--]]

return function(Cora)
    local Library = Cora.Library
    local Window  = Cora.Window
    local Toggles = Library.Toggles
    local Options = Library.Options

    local Players           = game:GetService("Players")
    local RunService        = game:GetService("RunService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local LP                = Players.LocalPlayer

    local AntiTab = Window:AddTab("Anti", "shield-off")
    Cora.Tabs.Anti = AntiTab

    ----------------------------------------------------------------
    -- Game references
    ----------------------------------------------------------------
    local rf = ReplicatedStorage:FindFirstChild("EntityInfo")
        or ReplicatedStorage:FindFirstChild("Bricks")
        or ReplicatedStorage:FindFirstChild("RemotesFolder")
    local ClientModules = ReplicatedStorage:FindFirstChild("ModulesClient")
        or ReplicatedStorage:FindFirstChild("ClientModules")
    local MotorReplication = rf and rf:FindFirstChild("MotorReplication")
    local Crouch           = rf and rf:FindFirstChild("Crouch")

    ----------------------------------------------------------------
    -- State watcher (mirrors toggles into `state`, fires onChange)
    ----------------------------------------------------------------
    local state  = {}
    local _watch = {}
    local function add(group, idx, text, onChange)
        group:AddToggle(idx, { Text = text, Default = false })
        state[idx] = false
        table.insert(_watch, { idx = idx, last = false, fn = onChange })
    end

    ----------------------------------------------------------------
    -- Handlers
    ----------------------------------------------------------------
    -- Anti Screech: swap the real Screech remote with a dud so its damage fires
    -- into nothing (Supreme's FakeScreech method).
    local FakeScreech, screechOn
    pcall(function()
        if rf then
            FakeScreech = Instance.new("RemoteEvent")
            FakeScreech.Name = "Screech_"
            FakeScreech.Parent = rf
        end
    end)
    local function onScreech(v)
        if not (rf and FakeScreech) then return end
        if v then
            pcall(function() if rf:FindFirstChild("Screech") then rf.Screech.Name = "Screech_" end end)
            pcall(function() FakeScreech.Name = "Screech" end)
            screechOn = true
        elseif screechOn then
            pcall(function()
                local s = rf:FindFirstChild("Screech_")
                if s and s ~= FakeScreech then s.Name = "Screech" end
            end)
            pcall(function() FakeScreech.Name = "Screech_" end)
        end
    end

    -- Anti A-90: swap the real A90 remote with a dud (same trick as Screech).
    local FakeA90, a90On
    pcall(function()
        if rf then
            FakeA90 = Instance.new("RemoteEvent")
            FakeA90.Name = "A90_"
            FakeA90.Parent = rf
        end
    end)
    local function onA90(v)
        if not (rf and FakeA90) then return end
        if v then
            pcall(function() if rf:FindFirstChild("A90") then rf.A90.Name = "A90_" end end)
            pcall(function() FakeA90.Name = "A90" end)
            a90On = true
        elseif a90On then
            pcall(function()
                local s = rf:FindFirstChild("A90_")
                if s and s ~= FakeA90 then s.Name = "A90" end
            end)
            pcall(function() FakeA90.Name = "A90_" end)
        end
    end

    -- Anti Dread: rename the Dread instance so its module stops finding it.
    local function onDread(v)
        pcall(function()
            local d = LP:FindFirstChild("Dread", true) or LP:FindFirstChild("_Dread", true)
            if d then d.Name = v and "_Dread" or "Dread" end
        end)
    end

    -- Anti Halt: rename the Shade (Halt) client module.
    local function onHalt(v)
        pcall(function()
            if not ClientModules then return end
            local em = ClientModules:FindFirstChild("EntityModules")
            if not em then return end
            local s = em:FindFirstChild("Shade", true) or em:FindFirstChild("_Shade", true)
            if s then s.Name = v and "_Shade" or "Shade" end
        end)
    end

    -- CanTouch-based anti (Snare / Giggle / Dupe / Seek obstructions).
    local function applyInstance(v)
        pcall(function()
            local n = v.Name
            if n == "Snare" then
                local hb = v:FindFirstChild("Hitbox")
                if hb then hb.CanTouch = not state.AntiSnare end
            elseif n == "GiggleCeiling" then
                local hb = v:FindFirstChild("Hitbox")
                if hb then hb.CanTouch = not state.AntiGiggle end
            elseif n == "DoorFake" and v.Parent and v.Parent.Name == "SideroomDupe" then
                local h = v:FindFirstChild("Hidden")
                if h then h.CanTouch = not state.AntiDupe end
            elseif n == "Seek_Arm" or n == "ChandelierObstruction" then
                for _, i in ipairs(v:GetChildren()) do
                    if i:IsA("BasePart") then i.CanTouch = not state.AntiSeekObstructions end
                end
            end
        end)
    end
    local function rescanCanTouch()
        local rooms = workspace:FindFirstChild("CurrentRooms")
        if not rooms then return end
        for _, v in ipairs(rooms:GetDescendants()) do applyInstance(v) end
    end

    ----------------------------------------------------------------
    -- Toggles
    ----------------------------------------------------------------
    local Entities = AntiTab:AddLeftGroupbox("Entities", "ghost")
    add(Entities, "AntiScreech",       "Anti Screech",        onScreech)
    add(Entities, "AntiA90",           "Anti A-90",           onA90)
    add(Entities, "AntiEyes",          "Anti Eyes")           -- loop below
    add(Entities, "AntiHalt",          "Anti Halt",           onHalt)
    add(Entities, "AntiDread",         "Anti Dread",          onDread)
    add(Entities, "AntiFigureHearing", "Anti Figure Hearing") -- loop below
    add(Entities, "AntiLookman",       "Anti Lookman")        -- loop below
    add(Entities, "AntiSnare",         "Anti Snare",          rescanCanTouch)

    local Misc = AntiTab:AddRightGroupbox("Misc", "ban")
    add(Misc, "NoSpiderJumpscare",   "No Spider Jumpscare Visual") -- GUI hook below
    add(Misc, "AntiDupe",            "Anti Dupe",                 rescanCanTouch)
    add(Misc, "AntiGiggle",          "Anti Giggle",               rescanCanTouch)
    add(Misc, "AntiSeekObstructions","Anti Seek Obstructions",    rescanCanTouch)

    ----------------------------------------------------------------
    -- Watcher loop
    ----------------------------------------------------------------
    RunService.Heartbeat:Connect(function()
        for _, w in ipairs(_watch) do
            local t = Toggles[w.idx]
            if t then
                local v = t.Value
                state[w.idx] = v
                if v ~= w.last then
                    w.last = v
                    if w.fn then pcall(w.fn, v) end
                end
            end
        end
    end)

    ----------------------------------------------------------------
    -- New instances get the current anti state applied
    ----------------------------------------------------------------
    workspace.DescendantAdded:Connect(function(v)
        task.spawn(function()
            pcall(function()
                local n = v.Name
                if n == "Snare" or n == "GiggleCeiling" then
                    local t = 0
                    repeat task.wait(0.03) t += 0.03 until t > 2 or v:FindFirstChild("Hitbox")
                elseif n == "DoorFake" then
                    v:WaitForChild("Hidden", 5)
                end
                applyInstance(v)
            end)
        end)
    end)

    ----------------------------------------------------------------
    -- Damage-spoof / continuous loops
    ----------------------------------------------------------------
    RunService.Heartbeat:Connect(function()
        pcall(function()
            local char = LP.Character
            if not char then return end
            local hiding = char:GetAttribute("Hiding")

            -- Anti Eyes: spoof rotation so Eyes/Lookman can't catch you moving
            if state.AntiEyes and not hiding and MotorReplication then
                if workspace:FindFirstChild("Eyes") or workspace:FindFirstChild("Lookman") then
                    if rf and rf.Name ~= "RemotesFolder" then
                        MotorReplication:FireServer(0, -650, 0, false)
                    else
                        MotorReplication:FireServer(-650)
                    end
                end
            end

            -- Anti Lookman (backdoor)
            if state.AntiLookman and not hiding and MotorReplication then
                if workspace:FindFirstChild("BackdoorLookman") then
                    MotorReplication:FireServer(-650)
                end
            end
        end)
    end)

    -- Anti Figure Hearing: keep signalling silent movement
    local hearTimer = 0
    RunService.Heartbeat:Connect(function(dt)
        hearTimer += dt
        if hearTimer < 0.2 then return end
        hearTimer = 0
        pcall(function()
            if state.AntiFigureHearing and Crouch then
                Crouch:FireServer(true, true)
            end
        end)
    end)

    -- No Spider Jumpscare Visual: hide the spider jumpscare GUI if it appears
    pcall(function()
        local pg = LP:WaitForChild("PlayerGui")
        pg.ChildAdded:Connect(function(gui)
            pcall(function()
                if not state.NoSpiderJumpscare then return end
                local n = gui.Name:lower()
                if n:find("spider") or n:find("timothy") then gui.Enabled = false end
            end)
        end)
    end)
end

--[[
    Cora • TAB FILE: Floor  —  goes in /floortab.lua
    (This is a TAB file, NOT the bootstrap. The bootstrap lives in main.lua.)
    General progression toggles (Auto Heartbeat / Library / Breaker - their LOGIC
    lives in maintab and reads these toggles live) plus per-floor features ported
    from the Supreme Hub reference. CanTouch/CanCollide features apply to existing
    objects on toggle and to new ones via DescendantAdded.
--]]

return function(Cora)
    local Library = Cora.Library
    local Window  = Cora.Window
    local Toggles = Library.Toggles
    local Options = Library.Options

    local Players    = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local Debris     = game:GetService("Debris")
    local LP         = Players.LocalPlayer

    local FloorTab = Window:AddTab("Floor", "sparkles")
    Cora.Tabs.Floor = FloorTab

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
    -- Helpers
    ----------------------------------------------------------------
    local SeekPath = Instance.new("Folder")
    SeekPath.Name = "CoraSeekPath"
    SeekPath.Parent = workspace

    local function showSeekPath(v)
        pcall(function()
            local part = Instance.new("Part")
            part.Size = Vector3.new(1.5, 1.5, 1.5)
            part.Anchored = true
            part.Shape = Enum.PartType.Ball
            part.Position = v.Position
            part.CanCollide = false
            part.Color = Color3.new(0, 1, 0)
            part.Material = Enum.Material.Neon
            part.Parent = SeekPath
            Debris:AddItem(part, 60)
        end)
    end

    local function fixBridge(v)
        pcall(function()
            for _, i in ipairs(v:GetChildren()) do
                if i.Name == "PlayerBarrier" and i:IsA("BasePart") and i.Rotation.X == 180 then
                    local b = i:Clone()
                    b.CFrame = CFrame.new(i.Position.X, i.Position.Y, i.Position.Z) * CFrame.new(0, -7, 0)
                    b.Size = Vector3.new(40, 0.1, 40)
                    b.Transparency = 0.5
                    b.Color = Color3.new(0.5, 0, 0.5)
                    b.Material = Enum.Material.ForceField
                    b.Name = "CoraBridgeBarrier"
                    b.Anchored = true
                    b.CanCollide = true
                    b.Parent = v
                end
            end
        end)
    end

    -- Apply a CanTouch/CanCollide floor feature to a single instance.
    local function applyFloor(v)
        pcall(function()
            local n = v.Name
            if n == "Lava" then
                v.CanTouch = not state.AntiLava
            elseif n == "BananaPeel" then
                v.CanTouch = not state.AntiBanana
            elseif n == "SeekFloodline" then
                v.CanCollide = state.AntiSeekFlood and true or false
            elseif n == "ScaryWall" then
                for _, i in ipairs(v:GetChildren()) do
                    if i:IsA("BasePart") then i.CanTouch = not state.AntiSeekWall end
                end
            elseif n == "Bridge" and v:IsA("BasePart") and v.CanCollide == false then
                v.Transparency = state.ShowRealBridge and 1 or 0
            end
        end)
    end
    local function rescanFloor()
        local rooms = workspace:FindFirstChild("CurrentRooms")
        if rooms then for _, v in ipairs(rooms:GetDescendants()) do applyFloor(v) end end
        for _, v in ipairs(workspace:GetChildren()) do applyFloor(v) end
    end

    local function applyJeff()
        if not state.AntiJeff then return end
        local v = workspace:FindFirstChild("JeffTheKiller")
        if not v then return end
        task.spawn(function()
            pcall(function()
                repeat task.wait() until v.PrimaryPart or not v.Parent
                if not v.Parent then return end
                if isnetworkowner and not isnetworkowner(v.PrimaryPart) then return end
                for _, i in ipairs(v:GetChildren()) do
                    if i:IsA("BasePart") then i.CanTouch = false end
                end
                local hum = v:FindFirstChildOfClass("Humanoid")
                if hum then hum.Health = 0 end
            end)
        end)
    end

    local function onFixBridge(v)
        local rooms = workspace:FindFirstChild("CurrentRooms")
        if v then
            if rooms then for _, b in ipairs(rooms:GetDescendants()) do if b.Name == "Bridge" then fixBridge(b) end end end
        else
            if rooms then
                for _, b in ipairs(rooms:GetDescendants()) do
                    if b.Name == "CoraBridgeBarrier" then b:Destroy() end
                end
            end
        end
    end
    local function onShowSeekPath(v)
        if v then
            local rooms = workspace:FindFirstChild("CurrentRooms")
            if rooms then for _, s in ipairs(rooms:GetDescendants()) do if s.Name == "SeekGuidingLight" then showSeekPath(s) end end end
        else
            SeekPath:ClearAllChildren()
        end
    end

    ----------------------------------------------------------------
    -- Toggles
    ----------------------------------------------------------------
    -- General: these three are wired in the Main tab's logic (it reads the
    -- toggles live); they live here because they're progression helpers.
    local General = FloorTab:AddLeftGroupbox("General", "wrench")
    General:AddToggle("AutoHeartbeat",    { Text = "Auto Heartbeat Mini-Game", Default = false })
    General:AddToggle("AutoSolveLibrary", { Text = "Auto Solve Library",       Default = false })
    General:AddToggle("AutoBreaker",      { Text = "Auto Breaker Box",         Default = false })

    local Fools = FloorTab:AddLeftGroupbox("Fools", "party-popper")
    add(Fools, "AntiBanana", "Anti Banana", rescanFloor)
    add(Fools, "AntiJeff",   "Anti Jeff",   function() rescanFloor(); applyJeff() end)

    local Mines = FloorTab:AddRightGroupbox("Mines", "pickaxe")
    add(Mines, "AntiSeekFlood",   "Anti Seek Flood",  rescanFloor)
    add(Mines, "FixBrokenBridge", "Fix Broken Bridge", onFixBridge)
    add(Mines, "ShowSeekPath",    "Show Seek Path",    onShowSeekPath)

    local Retro = FloorTab:AddRightGroupbox("Retro", "joystick")
    add(Retro, "AntiLava",      "Anti Lava",      rescanFloor)
    add(Retro, "AntiSeekWall",  "Anti Seek Wall", rescanFloor)
    add(Retro, "ShowRealBridge","Show Real Bridge", rescanFloor)

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
    -- New instances pick up the current floor state
    ----------------------------------------------------------------
    workspace.DescendantAdded:Connect(function(v)
        task.defer(function()
            if not v.Parent then return end
            applyFloor(v)
            pcall(function()
                if state.FixBrokenBridge and v.Name == "Bridge" then fixBridge(v) end
                if state.ShowSeekPath and v.Name == "SeekGuidingLight" then showSeekPath(v) end
                if state.AntiJeff and v.Name == "JeffTheKiller" then applyJeff() end
            end)
        end)
    end)
end

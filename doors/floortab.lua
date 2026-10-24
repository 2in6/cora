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

    ----------------------------------------------------------------
    -- Rooms: Auto A-1000 (auto-walk, adapted from GIFKITS Rooms Auto Walk V2)
    -- Walks to the current room's door; if A-60/A-120 spawn it heads to the
    -- nearest locker and hides instead (built-in dodge). Enabling it also turns
    -- on Anti A-90 (and flips that toggle in the GUI).
    ----------------------------------------------------------------
    local ReplicatedStorage  = game:GetService("ReplicatedStorage")
    local PathfindingService = game:GetService("PathfindingService")

    local arf = ReplicatedStorage:FindFirstChild("EntityInfo")
        or ReplicatedStorage:FindFirstChild("Bricks")
        or ReplicatedStorage:FindFirstChild("RemotesFolder")
    local camLock    = arf and arf:FindFirstChild("CamLock")
    local gd         = ReplicatedStorage:FindFirstChild("GameData")
    local latestRoom = gd and gd:FindFirstChild("LatestRoom")

    local cameraScript, a90Frame
    pcall(function()
        local pg     = LP:FindFirstChild("PlayerGui")
        local mainUI = pg and pg:FindFirstChild("MainUI")
        cameraScript = mainUI and mainUI.Initiator.Main_Game:FindFirstChild("Camera")
        local js     = mainUI and mainUI:FindFirstChild("Jumpscare")
        a90Frame     = js and js:FindFirstChild("Jumpscare_A90")
    end)

    local awPath = PathfindingService:CreatePath({ WaypointSpacing = 1, AgentCanJump = true, AgentRadius = 2 })
    local awChar, awHum, awRoot, awHead
    local function awUpdateChar()
        awChar = LP.Character
        awHum  = awChar and awChar:FindFirstChildOfClass("Humanoid")
        awRoot = awChar and awChar:FindFirstChild("HumanoidRootPart")
        awHead = awChar and awChar:FindFirstChild("Head")
    end
    awUpdateChar()
    LP.CharacterAdded:Connect(function() task.wait(0.3); awUpdateChar() end)

    local camLockObject, currentGoal, prevGoal, currentAction, prevAction
    local waypoints, waypointIndex, lastComputed = {}, 1, 0

    local function awFirePrompt(prompt)
        if not prompt then return end
        local part = prompt.Parent
        if part:IsA("Model") then part = part.PrimaryPart end
        camLockObject = part
        task.wait(0.3)
        pcall(function() fireproximityprompt(prompt) end)
        task.wait(prompt.HoldDuration)
        camLockObject = nil
    end

    local function awGetLocker()
        local rooms = workspace:FindFirstChild("CurrentRooms")
        if not (rooms and awRoot) then return end
        local closest
        for _, prompt in ipairs(rooms:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") and prompt.Name == "HidePrompt" then
                local locker = prompt.Parent
                local base   = locker:FindFirstChild("Base")
                local hidden = locker:FindFirstChild("HiddenPlayer")
                if base and hidden and not hidden.Value then
                    if not closest
                        or (base.Position - awRoot.Position).Magnitude < (closest.Position - awRoot.Position).Magnitude then
                        closest = base
                    end
                end
            end
        end
        return closest
    end

    local function awCheckAction()
        if workspace:FindFirstChild("A60") or workspace:FindFirstChild("A120") then return "locker" end
        return "door"
    end

    local function awGetGoal()
        local rooms = workspace:FindFirstChild("CurrentRooms")
        local room  = rooms and latestRoom and rooms:FindFirstChild(tostring(latestRoom.Value))
        if not room then return end
        currentAction = awCheckAction()
        if currentAction ~= "locker" and prevAction == "locker" and camLock then
            pcall(function() camLock:FireServer() end)
        end
        prevAction = currentAction
        if currentAction == "locker" then return awGetLocker() end
        local door1 = room:FindFirstChild("Door")
        return door1 and door1:FindFirstChild("Door")
    end

    local function awStopPath() waypointIndex = 1; waypoints = {} end

    local function awComplete()
        if currentAction == "locker" and currentGoal then
            local locker = currentGoal.Parent
            local prompt = locker and locker:FindFirstChildOfClass("ProximityPrompt")
            if not prompt then return end
            if a90Frame and a90Frame.Visible then
                repeat task.wait() until not a90Frame.Visible or not state.AutoA1000
                task.wait(0.2)
            end
            awFirePrompt(prompt)
        end
    end

    local function awCompute()
        if not (awRoot and currentGoal) then return end
        local now = os.clock()
        if now - lastComputed < 1 and prevGoal == currentGoal then return end
        lastComputed = now
        if prevGoal ~= currentGoal then awStopPath() end
        prevGoal = currentGoal
        local targetPos = currentGoal.Position
        if currentAction == "door" then
            targetPos = targetPos + (-currentGoal.CFrame.LookVector) * 2
        elseif currentAction == "locker" then
            targetPos = targetPos + (currentGoal.CFrame.LookVector) * 3
        end
        local ok = pcall(function() awPath:ComputeAsync(awRoot.Position, targetPos) end)
        if ok and awPath.Status == Enum.PathStatus.Success then
            waypoints = awPath:GetWaypoints()
            waypointIndex = 2
            return
        end
        prevGoal = nil
    end

    local Rooms = FloorTab:AddLeftGroupbox("Rooms", "door-open")
    add(Rooms, "AutoA1000", "Auto A-1000", function(v)
        if v then
            -- auto-enable Anti A-90 (also flips its toggle in the GUI)
            pcall(function() if Toggles.AntiA90 then Toggles.AntiA90:SetValue(true) end end)
        else
            awStopPath(); prevGoal = nil; camLockObject = nil
            pcall(function()
                if awRoot then awRoot.CanCollide = true end
                local col = awChar and awChar:FindFirstChild("Collision")
                if col then col.CanCollide = true end
                if cameraScript then cameraScript.Enabled = true end
            end)
        end
    end)

    RunService.RenderStepped:Connect(function(dt)
        if not state.AutoA1000 then return end
        pcall(function()
            if not (awHum and awRoot and awHead) then awUpdateChar() end
            if not (awHum and awRoot) then return end

            -- look at the hide target while hiding, otherwise hand camera back
            if camLockObject and awHead and cameraScript then
                cameraScript.Enabled = false
                local target = CFrame.new(awHead.CFrame.Position, camLockObject.Position)
                workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame:Lerp(target, dt * 12)
            elseif cameraScript then
                cameraScript.Enabled = true
            end

            -- noclip while walking so doorways don't snag the path
            awRoot.CanCollide = false
            local col = awChar:FindFirstChild("Collision")
            if col then col.CanCollide = false end

            currentGoal = awGetGoal()
            if not currentGoal then return end
            awCompute()

            if waypointIndex > #waypoints then awStopPath() return end
            local targetPos = waypoints[waypointIndex].Position
            local offset = (targetPos - awRoot.Position) * Vector3.new(1, 0, 1)
            if offset.Magnitude < 2 then
                waypointIndex += 1
                if waypointIndex > #waypoints then awComplete() end
            else
                awHum:MoveTo(targetPos)
            end
        end)
    end)
end

--[[
    Cora • TAB FILE: Visuals  —  goes in /visualstab.lua
    (This is a TAB file, NOT the bootstrap. The bootstrap lives in main.lua.)
    Overall (QoL): Fullbright, No Fog, No Camera Shaking, No Cutscenes.
    Toggle effects driven by a state-watcher loop (no re-toggle needed).
--]]

return function(Cora)
    local Library = Cora.Library
    local Window  = Cora.Window
    local Toggles = Library.Toggles
    local Options = Library.Options

    local Players           = game:GetService("Players")
    local RunService        = game:GetService("RunService")
    local Lighting          = game:GetService("Lighting")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local LP                = Players.LocalPlayer

    -- State-watcher (fires fn once at startup and on every change)
    local _watch = {}
    local function watch(idx, fn) table.insert(_watch, { idx = idx, last = nil, fn = fn }) end
    RunService.Heartbeat:Connect(function()
        for _, w in ipairs(_watch) do
            local t = Toggles[w.idx]
            if t then
                local v = t.Value
                if v ~= w.last then w.last = v; pcall(w.fn, v) end
            end
        end
    end)

    local VisualsTab = Window:AddTab("Visuals", "eye")
    pcall(function() VisualsTab:SetDescription("ESP & Quality of Life") end)
    Cora.Tabs.Visuals = VisualsTab

    local Overall = VisualsTab:AddLeftGroupbox("Overall", "sun")
    Overall:AddToggle("FullBright",  { Text = "Fullbright", Default = false })
    Overall:AddToggle("NoFog",       { Text = "No Fog", Default = false })
    Overall:AddToggle("NoCamShake",  { Text = "No Camera Shaking", Default = false })
    Overall:AddToggle("NoCutscenes", { Text = "No Cutscenes", Default = false })

    local WHITE = Color3.new(1, 1, 1)

    -- Fullbright: store defaults on enable, restore on disable (enforced in loop)
    local fbDefaults
    watch("FullBright", function(on)
        if on then
            if not fbDefaults then
                fbDefaults = {
                    Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient,
                    GlobalShadows = Lighting.GlobalShadows, Brightness = Lighting.Brightness,
                }
            end
        else
            if fbDefaults then
                pcall(function()
                    Lighting.Ambient        = fbDefaults.Ambient
                    Lighting.OutdoorAmbient = fbDefaults.OutdoorAmbient
                    Lighting.GlobalShadows  = fbDefaults.GlobalShadows
                    Lighting.Brightness     = fbDefaults.Brightness
                end)
                fbDefaults = nil
            end
            local rooms = workspace:FindFirstChild("CurrentRooms")
            if rooms then
                for _, r in ipairs(rooms:GetChildren()) do
                    local old = r:GetAttribute("CoraOldAmbient")
                    if old ~= nil then pcall(function() r:SetAttribute("Ambient", old) end) end
                end
            end
        end
    end)

    -- No Fog: store FogEnd on enable, restore on disable
    local fogDefault
    watch("NoFog", function(on)
        if on then
            if not fogDefault then fogDefault = Lighting.FogEnd end
        else
            if fogDefault then Lighting.FogEnd = fogDefault; fogDefault = nil end
            for _, v in ipairs(Lighting:GetChildren()) do
                if v:IsA("Atmosphere") then pcall(function() v.Density = 0.94 end) end
            end
        end
    end)

    -- No Camera Shake: requires the Main_Game client module
    local RequiredMainGame
    local function resolveMainGame()
        if RequiredMainGame then return end
        pcall(function()
            local pg = LP:FindFirstChild("PlayerGui")
            local mui = pg and pg:FindFirstChild("MainUI")
            local init = mui and mui:FindFirstChild("Initiator")
            local mg = init and init:FindFirstChild("Main_Game")
            if mg then RequiredMainGame = require(mg) end
        end)
    end
    resolveMainGame()

    -- No Cutscenes: rename the Cutscenes listener so they never play
    local function getRemoteListener()
        local pg = LP:FindFirstChild("PlayerGui")
        local mui = pg and pg:FindFirstChild("MainUI")
        local init = mui and mui:FindFirstChild("Initiator")
        local mg = init and init:FindFirstChild("Main_Game")
        return mg and mg:FindFirstChild("RemoteListener")
    end
    local function applyCutscenes(on)
        local rl = getRemoteListener()
        if not rl then return end
        local cs = rl:FindFirstChild("Cutscenes") or rl:FindFirstChild("Cutscenes_")
        if not cs then return end
        cs.Name = on and "Cutscenes_" or "Cutscenes"
    end
    watch("NoCutscenes", function(on) applyCutscenes(on) end)

    LP.CharacterAdded:Connect(function()
        task.wait(1.5)
        RequiredMainGame = nil
        resolveMainGame()
        if Toggles.NoCutscenes and Toggles.NoCutscenes.Value then pcall(applyCutscenes, true) end
    end)

    -- Enforcement loop
    RunService.Heartbeat:Connect(function()
        if Toggles.FullBright.Value then
            pcall(function()
                if Lighting.Ambient ~= WHITE then Lighting.Ambient = WHITE end
                if Lighting.OutdoorAmbient ~= WHITE then Lighting.OutdoorAmbient = WHITE end
                if Lighting.GlobalShadows then Lighting.GlobalShadows = false end
                local rooms = workspace:FindFirstChild("CurrentRooms")
                local cur = LP:GetAttribute("CurrentRoom")
                if rooms and cur then
                    local room = rooms:FindFirstChild(tostring(cur))
                    if room then
                        if room:GetAttribute("CoraOldAmbient") == nil then
                            room:SetAttribute("CoraOldAmbient", room:GetAttribute("Ambient"))
                        end
                        if room:GetAttribute("Ambient") ~= WHITE then room:SetAttribute("Ambient", WHITE) end
                    end
                end
            end)
        end
        if Toggles.NoFog.Value then
            pcall(function()
                if Lighting.FogEnd < 100000 then Lighting.FogEnd = 100000 end
                for _, v in ipairs(Lighting:GetChildren()) do
                    if v:IsA("Atmosphere") and v.Density > 0 then v.Density = 0 end
                end
            end)
        end
        if Toggles.NoCamShake.Value and RequiredMainGame then
            pcall(function() RequiredMainGame.csgo = CFrame.new(0, 0, 0) end)
        end
    end)

    ----------------------------------------------------------------
    -- ESP
    ----------------------------------------------------------------
    -- name maps (pulled from the reference hub)
    local ItemNames = {
        Bandage="Bandage", BandagePack="Bandage Pack", Flashlight="Flashlight", Battery="Battery",
        BatteryPack="Battery Pack", SkeletonKey="Skeleton Key", Crucifix="Crucifix", CrucifixWall="Crucifix",
        Straplight="Strap Light", Lockpick="Lockpick", Bulklight="Bulk Light", Vitamins="Vitamins",
        Shears="Shears", LaserPointer="Laser Pointer", Candle="Candle", Smoothie="Smoothie",
        Glowsticks="Glow Sticks", Lantern="Lantern", Shakelight="Shake Light", HolyGrenade="Holy Grenade",
        ShieldMini="Mini Shield", ShieldBig="Big Shield", AlarmClock="Alarm Clock", Compass="Compass",
        GoldGun="Golden Gun", Candy="Candy", ChestBox="Chest", ChestBoxLocked="Locked Chest",
        Chest_Vine="Vine Chest", Toolbox_Locked="Locked Toolbox", Toolshed_Small="Toolshed",
        StarJug="Jug", StardustPickup="Stardust", StarVial="Star Vial", StarBottle="Star Bottle",
        LotusPetalPickup="Lotus Petal", KeyIron="Iron Key",
    }
    local ObjectiveNames = {
        KeyObtain="Key", ElectricalKeyObtain="Electrical Key", FuseObtain="Fuse",
        MinesGenerator="Generator", MinesGateButton="Gate Button", MinesAnchor="Anchor",
        LeverForGate="Gate Lever", LiveHintBook="Library Book", LiveBreakerPolePickup="Breaker",
        WaterPump="Water Pump", VineGuillotine="Vine Lever", TimerLever="Lever",
    }
    local EntityNamesESP = {
        RushMoving="Rush", AmbushMoving="Ambush", A60="A-60", A120="A-120",
        GlitchRush="Glitch Rush", GlitchAmbush="Glitch Ambush", Eyes="Eyes", Lookman="Eyes",
        BackdoorRush="Blitz", BackdoorLookman="Lookman", JeffTheKiller="Jeff",
        FigureRig="Figure", FigureRagdoll="Figure", GrumbleRig="Grumble",
        Groundskeeper="Groundskeeper", MandrakeLive="Mandrake", LiveEntityBramble="Bramble",
        GiggleCeiling="Giggle",
    }
    local HazardNames = {
        Snare="Snare", GloomEgg="Gloom Egg", Lava="Lava", BananaPeel="Banana",
        ScaryWall="Seek Wall", SeekFloodline="Flood", Seek_Arm="Seek Arm",
        ChandelierObstruction="Chandelier",
    }

    local DefaultColors = {
        Player    = Color3.fromRGB(255, 255, 255),
        Door      = Color3.fromRGB(0, 255, 255),
        Item      = Color3.fromRGB(255, 130, 255),
        Gold      = Color3.fromRGB(255, 215, 0),
        Objective = Color3.fromRGB(0, 255, 140),
        Entity    = Color3.fromRGB(255, 40, 40),
        Hazard    = Color3.fromRGB(255, 140, 0),
    }
    local function catColor(cat)
        local opt = Options[cat .. "ESPColor"]
        return (opt and opt.Value) or DefaultColors[cat] or Color3.new(1, 1, 1)
    end

    -- UI
    local ESP = VisualsTab:AddRightGroupbox("ESP", "radar")
    local function espRow(idx, text, cat)
        ESP:AddToggle(idx, { Text = text, Default = false })
            :AddColorPicker(idx .. "Color", { Default = DefaultColors[cat], Title = text .. " Color" })
    end
    espRow("PlayerESP",    "Player ESP",    "Player")
    espRow("DoorESP",      "Door ESP",      "Door")
    espRow("ItemESP",      "Item ESP",      "Item")
    espRow("GoldESP",      "Gold ESP",      "Gold")
    espRow("ObjectiveESP", "Objective ESP", "Objective")
    espRow("EntityESP",    "Entity ESP",    "Entity")
    espRow("HazardESP",    "Hazard ESP",    "Hazard")
    ESP:AddSlider("ESPTextSize", { Text = "Text Size", Default = 14, Min = 8, Max = 28, Rounding = 0 })
    ESP:AddToggle("ShowTracers", { Text = "Show Tracers", Default = false })

    -- manager
    local espMap = {}   -- [obj] = { cat, hl, bb, lbl, part }
    local tracers = {}  -- [obj] = Drawing line
    local hasDrawing = (typeof(Drawing) == "table" or type(Drawing) == "table") and true or (Drawing ~= nil)

    local function adornPart(obj)
        if obj:IsA("BasePart") then return obj end
        if obj:IsA("Model") then return obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart") end
        return obj:FindFirstChildWhichIsA("BasePart")
    end

    local function addESP(obj, cat)
        if espMap[obj] then return end
        local color = catColor(cat)
        local hl = Instance.new("Highlight")
        hl.FillColor = color; hl.OutlineColor = color
        hl.FillTransparency = 0.6; hl.OutlineTransparency = 0
        hl.Adornee = obj
        pcall(function() hl.Parent = obj end)
        local part = adornPart(obj)
        local bb, lbl
        if part then
            bb = Instance.new("BillboardGui")
            bb.Size = UDim2.new(0, 220, 0, 26)
            bb.AlwaysOnTop = true
            bb.StudsOffset = Vector3.new(0, 2.5, 0)
            bb.Adornee = part
            lbl = Instance.new("TextLabel")
            lbl.BackgroundTransparency = 1
            lbl.Size = UDim2.new(1, 0, 1, 0)
            lbl.Font = Enum.Font.GothamBold
            lbl.TextColor3 = color
            lbl.TextStrokeTransparency = 0.4
            lbl.TextSize = Options.ESPTextSize.Value
            lbl.Parent = bb
            pcall(function() bb.Parent = obj end)
        end
        espMap[obj] = { cat = cat, hl = hl, bb = bb, lbl = lbl, part = part }
    end

    local function removeESP(obj)
        local e = espMap[obj]
        if not e then return end
        pcall(function() if e.hl then e.hl:Destroy() end end)
        pcall(function() if e.bb then e.bb:Destroy() end end)
        espMap[obj] = nil
        local tr = tracers[obj]
        if tr then pcall(function() tr:Remove() end); tracers[obj] = nil end
    end

    -- build the set of objects that should currently have ESP
    local function collectDesired()
        local desired = {}
        if Toggles.PlayerESP.Value then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LP and plr.Character then
                    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then
                        desired[plr.Character] = { cat = "Player",
                            text = plr.Name .. " [" .. math.floor((hum.Health / hum.MaxHealth) * 100) .. "%]" }
                    end
                end
            end
        end
        local rooms = workspace:FindFirstChild("CurrentRooms")
        if rooms then
            if Toggles.DoorESP.Value then
                -- only the door of the room you're currently in (and the one just
                -- ahead), so passed doors unload immediately. Highlight the door
                -- PANEL part - highlighting the whole Door model grabs its large
                -- invisible bounds and looks stretched.
                local cur = tonumber(LP:GetAttribute("CurrentRoom"))
                for _, room in ipairs(rooms:GetChildren()) do
                    local door = room:FindFirstChild("Door")
                    if door then
                        local rid = tonumber(room.Name) or tonumber(door:GetAttribute("RoomID"))
                        local show = (not cur) or (rid and rid >= cur and rid <= cur + 1)
                        if show then
                            local doorPart = door:FindFirstChild("Door") or door.PrimaryPart
                            if doorPart then
                                local id = door:GetAttribute("RoomID") or room.Name
                                desired[doorPart] = { cat = "Door", text = "Door [" .. tostring(id) .. "]" }
                            end
                        end
                    end
                end
            end
            local needDesc = Toggles.ItemESP.Value or Toggles.ObjectiveESP.Value
                or Toggles.GoldESP.Value or Toggles.EntityESP.Value or Toggles.HazardESP.Value
            if needDesc then
                for _, v in ipairs(rooms:GetDescendants()) do
                    local n = v.Name
                    if Toggles.GoldESP.Value and n == "GoldPile" then
                        desired[v] = { cat = "Gold", text = "Gold " .. tostring(v:GetAttribute("GoldValue") or "") }
                    elseif Toggles.ObjectiveESP.Value and ObjectiveNames[n] then
                        desired[v] = { cat = "Objective", text = ObjectiveNames[n] }
                    elseif Toggles.ItemESP.Value and ItemNames[n] then
                        desired[v] = { cat = "Item", text = ItemNames[n] }
                    elseif Toggles.EntityESP.Value and EntityNamesESP[n] then
                        desired[v] = { cat = "Entity", text = EntityNamesESP[n] }
                    elseif Toggles.HazardESP.Value and HazardNames[n] then
                        desired[v] = { cat = "Hazard", text = HazardNames[n] }
                    end
                end
            end
        end
        if Toggles.EntityESP.Value then
            for _, v in ipairs(workspace:GetChildren()) do
                if EntityNamesESP[v.Name] then
                    desired[v] = { cat = "Entity", text = EntityNamesESP[v.Name] }
                end
            end
        end
        return desired
    end

    -- scan: add/update/remove ESP, and re-apply colour + text + size (so colour
    -- pickers and the text-size slider take effect with no callbacks needed)
    local scanTimer = 0
    RunService.Heartbeat:Connect(function(dt)
        scanTimer += dt
        if scanTimer < 0.2 then return end
        scanTimer = 0
        pcall(function()
            local anyOn = Toggles.PlayerESP.Value or Toggles.DoorESP.Value or Toggles.ItemESP.Value
                or Toggles.GoldESP.Value or Toggles.ObjectiveESP.Value or Toggles.EntityESP.Value
                or Toggles.HazardESP.Value
            if not anyOn and next(espMap) == nil then return end

            local desired = anyOn and collectDesired() or {}
            for obj, info in pairs(desired) do
                addESP(obj, info.cat)
                local e = espMap[obj]
                if e then
                    local c = catColor(e.cat)
                    if e.hl then e.hl.FillColor = c; e.hl.OutlineColor = c end
                    if e.lbl then e.lbl.TextColor3 = c; e.lbl.TextSize = Options.ESPTextSize.Value; e.lbl.Text = info.text end
                end
            end
            for obj, e in pairs(espMap) do
                if not desired[obj] or not obj.Parent then removeESP(obj) end
            end
        end)
    end)

    -- tracers: line from bottom-centre of the screen to each ESP object
    RunService.RenderStepped:Connect(function()
        pcall(function()
            local cam = workspace.CurrentCamera
            local showT = hasDrawing and Toggles.ShowTracers and Toggles.ShowTracers.Value
            if not cam then return end
            for obj, e in pairs(espMap) do
                if showT and obj.Parent then
                    local part = (e.part and e.part.Parent) and e.part or adornPart(obj)
                    if part then
                        local sp, onScreen = cam:WorldToViewportPoint(part.Position)
                        local tr = tracers[obj]
                        if not tr then
                            tr = Drawing.new("Line"); tr.Thickness = 1
                            tracers[obj] = tr
                        end
                        tr.Color = catColor(e.cat)
                        tr.Visible = onScreen
                        if onScreen then
                            tr.From = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y)
                            tr.To = Vector2.new(sp.X, sp.Y)
                        end
                    end
                elseif tracers[obj] then
                    pcall(function() tracers[obj]:Remove() end)
                    tracers[obj] = nil
                end
            end
        end)
    end)

    ----------------------------------------------------------------
    -- Camera (custom FOV)
    ----------------------------------------------------------------
    local DEFAULT_FOV = 70
    local Camera = VisualsTab:AddLeftGroupbox("Camera", "video")
    Camera:AddToggle("CustomFOV", { Text = "Field Of View", Default = false })
    Camera:AddSlider("FOVValue", {
        Text = "Field Of View", Default = DEFAULT_FOV, Min = 70, Max = 120, Rounding = 0,
    })

    -- when turned off, snap back to the default FOV once
    watch("CustomFOV", function(v)
        if not v then
            pcall(function()
                if workspace.CurrentCamera then workspace.CurrentCamera.FieldOfView = DEFAULT_FOV end
            end)
        end
    end)
    -- while on, hold the chosen FOV every frame (so the game can't override it)
    RunService.RenderStepped:Connect(function()
        pcall(function()
            if Toggles.CustomFOV and Toggles.CustomFOV.Value then
                local cam = workspace.CurrentCamera
                if cam then cam.FieldOfView = Options.FOVValue.Value end
            end
        end)
    end)

    ----------------------------------------------------------------
    -- Notifications (entity notifier + custom sounds)
    ----------------------------------------------------------------
    -- file.kiwi links can't be HttpGet'd (they're encrypted download pages), so
    -- the sounds are pulled from the repo's /sounds folder. Upload the 7 files
    -- there as the names below; they download + cache to disk on first launch.
    local SOUND_BASE = "https://raw.githubusercontent.com/2in6/cora/main/sounds/"
    local SOUNDS = {
        { name = "Apple Pay",     file = "applepay.ogg" },
        { name = "Fah",           file = "fah.ogg" },
        { name = "Geometry Dash", file = "geometrydash.ogg" },
        { name = "Screech",       file = "screech.ogg" },
        { name = "Greed",         file = "greed.ogg" },
        { name = "Badge",         file = "badge.ogg" },
        { name = "Samsunify",     file = "samsunify.ogg" },
    }
    local soundNames = {}
    for _, s in ipairs(SOUNDS) do table.insert(soundNames, s.name) end

    local soundAssets = {}   -- name -> custom asset uri
    local canFiles = (writefile and isfile and readfile) and true or false
    if canFiles then
        pcall(function()
            if makefolder and isfolder and not isfolder("CoraData/sounds") then
                makefolder("CoraData/sounds")
            end
        end)
        task.spawn(function()
            for _, s in ipairs(SOUNDS) do
                local path = "CoraData/sounds/" .. s.file
                pcall(function()
                    if not isfile(path) then
                        writefile(path, game:HttpGet(SOUND_BASE .. s.file))
                    end
                    if getcustomasset then soundAssets[s.name] = getcustomasset(path) end
                end)
            end
        end)
    end

    local notifSound = Instance.new("Sound")
    notifSound.Name   = "CoraNotifSound"
    notifSound.Volume = 1
    pcall(function() notifSound.Parent = game:GetService("SoundService") end)

    local function playSound(name)
        local id = soundAssets[name]
        if not id then
            pcall(function() Library:Notify("Sound '" .. tostring(name) .. "' not downloaded yet.", 3) end)
            return
        end
        pcall(function()
            notifSound.SoundId = id
            notifSound.TimePosition = 0
            notifSound:Play()
        end)
    end

    local Notif = VisualsTab:AddRightGroupbox("Notifications", "bell")
    Notif:AddToggle("EntityNotifier", { Text = "Entity Notifier", Default = false })
    Notif:AddDropdown("EntityNotifierSound", {
        Text    = "Entity Notifier Sound",
        Values  = soundNames,
        Default = soundNames[1],
        Multi   = false,
        Callback = function(value)        -- preview the sound on selection
            playSound(value)
        end,
    })

    -- Entity notifier: announce + play the chosen sound when a new entity appears.
    local NotifEntities = {
        RushMoving = "Rush", AmbushMoving = "Ambush", A60 = "A-60", A120 = "A-120",
        GlitchRush = "Glitch Rush", GlitchAmbush = "Glitch Ambush", Eyes = "Eyes",
        Lookman = "Eyes", BackdoorRush = "Blitz", BackdoorLookman = "Lookman",
        JeffTheKiller = "Jeff", FigureRig = "Figure", FigureRagdoll = "Figure",
        GrumbleRig = "Grumble", Groundskeeper = "Groundskeeper", MandrakeLive = "Mandrake",
        LiveEntityBramble = "Bramble", GiggleCeiling = "Giggle", Snare = "Snare",
    }
    local notifSeen = {}
    local notifTimer = 0
    RunService.Heartbeat:Connect(function(dt)
        notifTimer += dt
        if notifTimer < 0.25 then return end
        notifTimer = 0
        pcall(function()
            if not (Toggles.EntityNotifier and Toggles.EntityNotifier.Value) then
                if next(notifSeen) then notifSeen = {} end
                return
            end
            local found = {}
            local function check(inst)
                local disp = NotifEntities[inst.Name]
                if disp then
                    found[inst] = true
                    if not notifSeen[inst] then
                        notifSeen[inst] = true
                        Library:Notify(disp .. " has spawned!", 4)
                        local sel = Options.EntityNotifierSound and Options.EntityNotifierSound.Value
                        if sel then playSound(sel) end
                    end
                end
            end
            for _, v in ipairs(workspace:GetChildren()) do check(v) end
            local rooms = workspace:FindFirstChild("CurrentRooms")
            if rooms then for _, v in ipairs(rooms:GetDescendants()) do check(v) end end
            -- forget entities that despawned, so they re-notify next time
            for inst in pairs(notifSeen) do
                if not found[inst] then notifSeen[inst] = nil end
            end
        end)
    end)
end

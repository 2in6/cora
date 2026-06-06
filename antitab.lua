--[[
    Cora • TAB FILE: Anti  —  goes in /antitab.lua
    (This is a TAB file, NOT the bootstrap. The bootstrap lives in main.lua.)
    Anti-entity / anti-mechanic toggles. Each toggle's state is mirrored into a
    `state` table by a watcher loop, so the per-entity logic can read it live.
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
    -- State watcher: mirrors every toggle into state[idx] live
    ----------------------------------------------------------------
    local state  = {}
    local _watch = {}
    local function add(group, idx, text, default)
        group:AddToggle(idx, { Text = text, Default = default or false })
        table.insert(_watch, idx)
        state[idx] = Toggles[idx] and Toggles[idx].Value or false
    end
    RunService.Heartbeat:Connect(function()
        for _, idx in ipairs(_watch) do
            local t = Toggles[idx]
            if t then state[idx] = t.Value end
        end
    end)

    ----------------------------------------------------------------
    -- Toggles
    ----------------------------------------------------------------
    local Entities = AntiTab:AddLeftGroupbox("Entities", "ghost")
    add(Entities, "AntiScreech",       "Anti Screech")
    add(Entities, "AntiEyes",          "Anti Eyes")
    add(Entities, "AntiHalt",          "Anti Halt")
    add(Entities, "AntiGlitch",        "Anti Glitch")
    add(Entities, "AntiVoid",          "Anti Void")
    add(Entities, "AntiDread",         "Anti Dread")
    add(Entities, "AntiHide",          "Anti Hide")
    add(Entities, "AntiFigureHearing", "Anti Figure Hearing")
    add(Entities, "AntiLookman",       "Anti Lookman")
    add(Entities, "AntiSeek",          "Anti Seek")
    add(Entities, "AntiSnare",         "Anti Snare")
    add(Entities, "AntiTimothy",       "Anti Timothy")

    local Misc = AntiTab:AddRightGroupbox("Misc", "ban")
    add(Misc, "NoSpiderJumpscare", "No Spider Jumpscare Visual")
    add(Misc, "AntiDupe",          "Anti Dupe")
    add(Misc, "AntiJack",          "Anti Jack")
    add(Misc, "AntiWindow",        "Anti Window")
    add(Misc, "AntiGiggle",        "Anti Giggle")
    add(Misc, "AntiGreed",         "Anti Greed")
    add(Misc, "AntiA120",          "Anti A-120")
    add(Misc, "AntiLagSpike",      "Anti Lag Spike")

    ----------------------------------------------------------------
    -- Helpers
    ----------------------------------------------------------------
    local function getRemotes()
        return ReplicatedStorage:FindFirstChild("RemotesFolder")
            or ReplicatedStorage:FindFirstChild("EntityInfo")
            or ReplicatedStorage:FindFirstChild("Bricks")
    end

    ----------------------------------------------------------------
    -- Implemented behaviours
    ----------------------------------------------------------------
    -- Anti Figure Hearing: keep telling the server you're moving silently.
    -- (Same Crouch signal the god-mode port uses for figure-hearing.)
    local hearTimer = 0
    RunService.Heartbeat:Connect(function(dt)
        hearTimer += dt
        if hearTimer < 0.2 then return end
        hearTimer = 0
        pcall(function()
            if not state.AntiFigureHearing then return end
            local rf = getRemotes()
            local crouch = rf and rf:FindFirstChild("Crouch")
            if crouch then crouch:FireServer(true, true) end
        end)
    end)

    -- No Spider Jumpscare Visual: hide the spider jumpscare GUI if it appears.
    LP:WaitForChild("PlayerGui")
    LP.PlayerGui.ChildAdded:Connect(function(gui)
        pcall(function()
            if not state.NoSpiderJumpscare then return end
            local n = gui.Name:lower()
            if n:find("spider") or n:find("timothy") then
                gui.Enabled = false
            end
        end)
    end)
end

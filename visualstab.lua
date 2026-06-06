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
end

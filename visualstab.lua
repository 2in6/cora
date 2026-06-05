--[[
    Cora • TAB FILE: Visuals  —  goes in /visualstab.lua
    (This is a TAB file, NOT the bootstrap. The bootstrap lives in main.lua.)
    Overall (QoL): Fullbright, No Fog, No Camera Shaking, No Cutscenes.
    Visual logic ported from public Doors scripts.
--]]

return function(Cora)
    local Library = Cora.Library
    local Window  = Cora.Window
    local Toggles = Library.Toggles
    local Options = Library.Options

    local Players          = game:GetService("Players")
    local RunService       = game:GetService("RunService")
    local Lighting         = game:GetService("Lighting")
    local ReplicatedStorage= game:GetService("ReplicatedStorage")
    local LP               = Players.LocalPlayer

    ----------------------------------------------------------------
    -- Star icon (download -> asset, fallback to lucide "star")
    ----------------------------------------------------------------
    pcall(function()
        if makefolder and not (isfolder and isfolder("CoraData")) then
            makefolder("CoraData")
        end
    end)
    local starIcon = "star"
    pcall(function()
        if writefile and getcustomasset then
            local path = "CoraData/cora_visuals.png"
            if not (isfile and isfile(path)) then
                writefile(path, game:HttpGet(
                    "https://i.ibb.co/rVHzTjq/star-100dp-E3-E3-E3-FILL0-wght400-GRAD0-opsz48.png"
                ))
            end
            starIcon = getcustomasset(path)
        end
    end)

    local VisualsTab = Window:AddTab("Visuals", starIcon)
    pcall(function() VisualsTab:SetDescription("ESP & Quality of Life") end)
    Cora.Tabs.Visuals = VisualsTab

    ----------------------------------------------------------------
    -- Overall group
    ----------------------------------------------------------------
    local Overall = VisualsTab:AddLeftGroupbox("Overall", "eye")

    Overall:AddToggle("FullBright", {
        Text    = "Fullbright",
        Default = false,
        Tooltip = "See clearly everywhere - dark rooms become bright.",
    })

    Overall:AddToggle("NoFog", {
        Text    = "No Fog",
        Default = false,
        Tooltip = "Disables all fog.",
    })

    Overall:AddToggle("NoCamShake", {
        Text    = "No Camera Shaking",
        Default = false,
        Tooltip = "Removes camera shake.",
    })

    Overall:AddToggle("NoCutscenes", {
        Text    = "No Cutscenes",
        Default = false,
        Tooltip = "Disables cutscenes.",
    })

    ----------------------------------------------------------------
    -- Logic (Doors-specific; everything guarded for lobby/other games)
    ----------------------------------------------------------------
    local WHITE = Color3.new(1, 1, 1)

    -- Fullbright: store defaults on enable, enforce in loop, restore on disable
    local fbDefaults
    Toggles.FullBright:OnChanged(function()
        if Toggles.FullBright.Value then
            if not fbDefaults then
                fbDefaults = {
                    Ambient        = Lighting.Ambient,
                    OutdoorAmbient = Lighting.OutdoorAmbient,
                    GlobalShadows  = Lighting.GlobalShadows,
                    Brightness     = Lighting.Brightness,
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
    Toggles.NoFog:OnChanged(function()
        if Toggles.NoFog.Value then
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
    local function applyCutscenes()
        local rl = getRemoteListener()
        if not rl then return end
        local cs = rl:FindFirstChild("Cutscenes") or rl:FindFirstChild("Cutscenes_")
        if not cs then return end
        cs.Name = Toggles.NoCutscenes.Value and "Cutscenes_" or "Cutscenes"
    end
    Toggles.NoCutscenes:OnChanged(applyCutscenes)

    -- Re-apply module-dependent toggles after respawn (Main_Game rebuilds)
    LP.CharacterAdded:Connect(function()
        task.wait(1.5)
        RequiredMainGame = nil
        resolveMainGame()
        if Toggles.NoCutscenes.Value then pcall(applyCutscenes) end
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
                        if room:GetAttribute("Ambient") ~= WHITE then
                            room:SetAttribute("Ambient", WHITE)
                        end
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

--[[
    Cora • CORE / BOOTSTRAP  —  goes in /main.lua
    (This is NOT the Main tab. The Main tab lives in maintab.lua.)
    Loads Obsidian + addons, downloads the logo icon, creates the window,
    forces a dark theme with a white accent, and loads the tabs.
    The window toggles with the menu key natively (no CanvasGroup wrapper -
    wrapping the window broke input on the controls).
--]]

return function(Cora)
    local Players = game:GetService("Players")
    local LP      = Players.LocalPlayer

    -- Single instance: tear down any previous Cora before building a new one,
    -- so re-running doesn't stack multiple windows.
    pcall(function()
        if getgenv and getgenv().CoraUnload then getgenv().CoraUnload() end
    end)

    local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"

    local Library      = loadstring(game:HttpGet(repo .. "Library.lua"))()
    local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
    local SaveManager  = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

    -- Download the window logo -> usable asset (falls back to lucide "moon")
    pcall(function()
        if makefolder and not (isfolder and isfolder("CoraData")) then
            makefolder("CoraData")
        end
    end)
    local moonIcon = "moon"
    pcall(function()
        if writefile and getcustomasset then
            local path = "CoraData/cora_logo.png"
            if not (isfile and isfile(path)) then
                writefile(path, game:HttpGet(
                    "https://i.ibb.co/4RjdkFND/bedtime-100dp-E3-E3-E3-FILL0-wght400-GRAD0-opsz48.png"
                ))
            end
            moonIcon = getcustomasset(path)
        end
    end)

    local Window = Library:CreateWindow({
        Title         = "Cora",
        Footer        = Cora.Version,
        Icon          = moonIcon,
        Center        = true,
        AutoShow      = true,
        Resizable     = true,
        ToggleKeybind = Enum.KeyCode.P,
        NotifySide    = "Right",
    })

    -- Dark background, white accent. Defined as a function so we can
    -- re-assert it AFTER ThemeManager / config autoload run.
    local function applyCoraScheme()
        pcall(function()
            local S = Library.Scheme
            S.BackgroundColor = Color3.fromRGB(12, 12, 12)
            S.MainColor       = Color3.fromRGB(18, 18, 18)
            S.AccentColor     = Color3.fromRGB(255, 255, 255)
            S.OutlineColor    = Color3.fromRGB(40, 40, 40)
            S.FontColor       = Color3.fromRGB(255, 255, 255)
            if Library.UpdateColorsUsingRegistry then
                Library:UpdateColorsUsingRegistry()
            end
        end)
    end
    applyCoraScheme()

    -- Share objects with other modules
    Cora.Library      = Library
    Cora.ThemeManager = ThemeManager
    Cora.SaveManager  = SaveManager
    Cora.Window       = Window
    Cora.Tabs         = {}

    ThemeManager:SetLibrary(Library)
    SaveManager:SetLibrary(Library)
    SaveManager:IgnoreThemeSettings()
    SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
    ThemeManager:SetFolder("Cora")
    SaveManager:SetFolder("Cora")

    -- Register the unload handle NOW (right after the window exists), so the
    -- single-instance guard works even if a tab errors while loading.
    if getgenv then
        getgenv().CoraUnload = function()
            pcall(function() Library:Unload() end)
            pcall(function()
                local pg = LP:FindFirstChild("PlayerGui")
                local kg = pg and pg:FindFirstChild("CoraKeySystem")
                if kg then kg:Destroy() end
            end)
            getgenv().CoraUnload = nil
        end
    end

    -- Load each tab in isolation. If one tab errors it must NOT stop the others
    -- (this is why Settings stopped loading before), and the real error is shown.
    local function loadTab(file)
        local ok, err = pcall(function() Cora.fetch(file)()(Cora) end)
        if not ok then
            warn("[Cora] tab '" .. file .. "' failed: " .. tostring(err))
            pcall(function()
                Library:Notify("[Cora] " .. file .. " error: " .. tostring(err), 8)
            end)
        end
    end
    loadTab("maintab.lua")
    loadTab("visualstab.lua")
    loadTab("settings.lua")

    -- Autoload config, then re-assert the white accent so it wins
    pcall(function() SaveManager:LoadAutoloadConfig() end)
    applyCoraScheme()
end

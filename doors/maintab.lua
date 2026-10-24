--[[
    Cora • CORE / BOOTSTRAP  —  goes in /main.lua
    Loads Obsidian + addons, downloads the logo icon, creates the "Cora Hub"
    window, forces a dark theme with a white accent, then loads the DOORS tabs
    from /doors and the shared settings.lua from the repo root.
--]]

return function(Cora)
    local Players = game:GetService("Players")
    local LP      = Players.LocalPlayer

    -- Single instance: if Cora is already running, just reveal the existing
    -- window and STOP. Rebuilding on every execution re-ran the tabs each time,
    -- which re-applied loops and the __namecall hook - that stacking caused the
    -- crash and the window flicker. To load a new version, use the Unload button
    -- in the Settings tab first, then run again.
    if getgenv and getgenv().CoraLoaded then
        -- Verify the UI still exists. A place teleport (e.g. entering The Rooms
        -- from the Hotel) wipes the GUI but leaves these globals set, which used
        -- to make Cora think it was still loaded and refuse to rebuild - so it
        -- "didn't load" in sub-places. If the marker is gone we're in a fresh
        -- place: clear the globals (and the hook guard so the hook re-installs)
        -- and fall through to a full rebuild.
        local alive = false
        pcall(function()
            local m = getgenv().CoraMarker
            alive = m ~= nil and m.Parent ~= nil
        end)
        if alive then
            pcall(function() if getgenv().CoraShow then getgenv().CoraShow() end end)
            return
        end
        pcall(function() if getgenv().CoraUnload then getgenv().CoraUnload() end end)
        getgenv().CoraLoaded   = nil
        getgenv().CoraShow     = nil
        getgenv().CoraUnload   = nil
        getgenv().CoraHBHooked = nil
    end

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

    -- Resolve the area for display in Settings. The main DOORS place covers
    -- several floors under one place id, so refine from the live floor when
    -- possible; otherwise keep the loader's default. Stored on Cora so the
    -- Settings tab can show it. The window title itself is always "Cora Hub".
    local Window = Library:CreateWindow({
        Title         = "Cora Hub",
        Footer        = Cora.Version or "Cora",
        Icon          = moonIcon,
        Center        = true,
        AutoShow      = true,
        Resizable     = true,
        NotifySide    = "Right",
    })
    -- NOTE: the menu toggle key is intentionally NOT set here. It is owned solely
    -- by the Settings tab's MenuKeybind keypicker (Library.ToggleKeybind =
    -- Options.MenuKeybind), exactly as the Obsidian Example does. Setting it in
    -- both places makes two handlers fire on the same key = open+close = no-op.

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
    -- Themes in the global "Cora" folder; configs in a separate subfolder.
    ThemeManager:SetFolder("Cora")
    SaveManager:SetFolder("Cora/doors")

    -- Register the unload handle NOW (right after the window exists), so the
    -- single-instance guard works even if a tab errors while loading.
    if getgenv then
        -- Liveness marker we fully control: it shares the window's lifetime and,
        -- crucially, is destroyed by a place teleport. The guard at the top uses
        -- it to tell "already loaded here" apart from "stale globals left over
        -- after teleporting into a sub-place like The Rooms".
        pcall(function()
            local old = getgenv().CoraMarker
            if old then old:Destroy() end
        end)
        local marker = Instance.new("ScreenGui")
        marker.Name         = "CoraMarker"
        marker.ResetOnSpawn = false
        pcall(function() marker.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
        getgenv().CoraMarker = marker

        getgenv().CoraLoaded = true
        getgenv().CoraShow = function()
            pcall(function() Library:Notify("Cora is already loaded.", 4) end)
            pcall(function() Library.Toggled = true end)
        end
        getgenv().CoraUnload = function()
            pcall(function() Library:Unload() end)
            pcall(function()
                local pg = LP:FindFirstChild("PlayerGui")
                local kg = pg and pg:FindFirstChild("CoraKeySystem")
                if kg then kg:Destroy() end
            end)
            pcall(function() if getgenv().CoraMarker then getgenv().CoraMarker:Destroy() end end)
            getgenv().CoraMarker = nil
            getgenv().CoraUnload = nil
            getgenv().CoraLoaded = nil
            getgenv().CoraShow   = nil
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
    -- DOORS tabs (in the /doors folder) + the shared settings.lua (repo root).
    loadTab("doors/maintab.lua")
    loadTab("doors/antitab.lua")
    loadTab("doors/floortab.lua")
    loadTab("doors/visualstab.lua")
    loadTab("settings.lua")

    -- Autoload config, then re-assert the white accent so it wins. ThemeManager
    -- applies its own default theme (a purple accent) on a DEFERRED frame when the
    -- Settings tab builds, which lands after this point — so we re-assert Cora's
    -- scheme on the next frame (and once more shortly after as a safety net) to
    -- override it. These run once at load, so the user can still pick another
    -- theme afterward and it will stick.
    pcall(function() SaveManager:LoadAutoloadConfig() end)
    applyCoraScheme()
    task.defer(applyCoraScheme)
    task.delay(0.25, applyCoraScheme)
end

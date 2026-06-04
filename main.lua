--[[
    Cora • Main
    Loads Obsidian + addons, downloads the moon icon, creates the window,
    sets the default dark/white theme, then loads the Settings tab.
--]]

return function(Cora)
    local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"

    local Library      = loadstring(game:HttpGet(repo .. "Library.lua"))()
    local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
    local SaveManager  = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

    -- Download the moon icon and turn it into a usable asset.
    -- Falls back to the lucide "moon" icon if the executor can't do custom assets.
    local moonIcon = "moon"
    pcall(function()
        if writefile and getcustomasset then
            if not (isfile and isfile("cora_moon.png")) then
                writefile("cora_moon.png", game:HttpGet(Cora.MoonURL))
            end
            moonIcon = getcustomasset("cora_moon.png")
        end
    end)

    -- Create the window (moon icon sits left of the title)
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

    -- Default theme: dark background, white as the main/accent colour.
    pcall(function()
        local Scheme = Library.Scheme
        Scheme.BackgroundColor = Color3.fromRGB(12, 12, 12)
        Scheme.MainColor       = Color3.fromRGB(18, 18, 18)
        Scheme.AccentColor     = Color3.fromRGB(255, 255, 255)
        Scheme.OutlineColor    = Color3.fromRGB(40, 40, 40)
        Scheme.FontColor       = Color3.fromRGB(255, 255, 255)
        if Library.UpdateColorsUsingRegistry then
            Library:UpdateColorsUsingRegistry()
        end
    end)

    -- Expose shared objects to other modules
    Cora.Library      = Library
    Cora.ThemeManager = ThemeManager
    Cora.SaveManager  = SaveManager
    Cora.Window       = Window
    Cora.Tabs         = {}

    -- Wire up the addon libraries
    ThemeManager:SetLibrary(Library)
    SaveManager:SetLibrary(Library)
    SaveManager:IgnoreThemeSettings()
    SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
    ThemeManager:SetFolder("Cora")
    SaveManager:SetFolder("Cora")

    -- Load tabs
    Cora.fetch("src/tabs/settings.lua")()(Cora)

    -- Load the autoloaded config (if any) after everything is built
    pcall(function() SaveManager:LoadAutoloadConfig() end)
end

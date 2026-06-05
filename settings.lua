--[[
    Cora • Settings tab
    Sections: Theme (dark/white) • Menu keybind (default P) • Configuration
--]]

return function(Cora)
    local Library      = Cora.Library
    local ThemeManager = Cora.ThemeManager
    local SaveManager  = Cora.SaveManager
    local Window       = Cora.Window
    local Options      = Library.Options

    -- Custom gear icon: download -> usable asset (same trick as the moon).
    -- Falls back to lucide "settings" if the executor lacks custom assets.
    pcall(function()
        if makefolder and not (isfolder and isfolder("CoraData")) then
            makefolder("CoraData")
        end
    end)
    local gearIcon = "settings"
    pcall(function()
        if writefile and getcustomasset then
            local path = "CoraData/cora_settings.png"
            if not (isfile and isfile(path)) then
                writefile(path, game:HttpGet(
                    "https://i.ibb.co/bjLVWWwT/settings-100dp-E3-E3-E3-FILL0-wght400-GRAD0-opsz48.png"
                ))
            end
            gearIcon = getcustomasset(path)
        end
    end)

    local SettingsTab = Window:AddTab("Settings", gearIcon)
    Cora.Tabs.Settings = SettingsTab

    -- ── Menu / keybind section ──────────────────────────────
    local MenuGroup = SettingsTab:AddLeftGroupbox("Menu", "menu")

    MenuGroup:AddToggle("KeybindMenuOpen", {
        Text    = "Show Keybind Menu",
        Default = false,
        Callback = function(value)
            if Library.KeybindFrame then
                Library.KeybindFrame.Visible = value
            end
        end,
    })

    MenuGroup:AddDivider()

    MenuGroup:AddLabel("Menu keybind"):AddKeyPicker("MenuKeybind", {
        Default = "P",
        NoUI    = true,
        Text    = "Menu keybind",
    })
    -- Route the window toggle through the editable keypicker
    Library.ToggleKeybind = Options.MenuKeybind

    MenuGroup:AddButton("Unload Cora", function()
        Library:Unload()
    end)

    -- ── Theme section (dark / white) ────────────────────────
    -- Builds the full theme picker (presets, custom colours, save/load)
    ThemeManager:ApplyToTab(SettingsTab)

    -- ── Configuration section ───────────────────────────────
    -- Create / overwrite / load / delete / autoload configs
    SaveManager:BuildConfigSection(SettingsTab)

    Library:Notify("Cora " .. Cora.Version .. " loaded.", 4)
end

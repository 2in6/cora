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
    local Toggles      = Library.Toggles

    local SettingsTab = Window:AddTab("Settings", "settings")
    Cora.Tabs.Settings = SettingsTab

    -- notify duration kept as a non-literal so number-obfuscation passes don't choke
    local NOTIF = tonumber("4")

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

    MenuGroup:AddButton({
        Text = "Unload Cora",
        Func = function()
            Library:Unload()
        end,
    })

    -- Route the window toggle through the editable keypicker (set AFTER the
    -- button, exactly like the Obsidian Example).
    Library.ToggleKeybind = Options.MenuKeybind

    -- ── Discord section ─────────────────────────────────────
    local DiscordGroup = SettingsTab:AddRightGroupbox("Discord", "message-circle")
    DiscordGroup:AddButton("Copy Discord Link", function()
        local link = "https://discord.gg/HgPXcUj98U"
        local copier = setclipboard or toclipboard or (syn and syn.write_clipboard) or set_clipboard
        pcall(function() if copier then copier(link) end end)
        pcall(function() Library:Notify("Discord Link Copied to Clipboard!", NOTIF) end)
        if Cora.PlayNotifSound then pcall(Cora.PlayNotifSound) end
    end)

    -- ── Configuration section ───────────────────────────────
    -- Create / overwrite / load / delete / autoload configs.
    -- Built BEFORE the theme picker, matching the Obsidian Example order.
    SaveManager:BuildConfigSection(SettingsTab)

    -- ── Theme section (dark / white) ────────────────────────
    -- Builds the full theme picker (presets, custom colours, save/load)
    ThemeManager:ApplyToTab(SettingsTab)

    Library:Notify("Cora " .. (Cora.Version or "?") .. " loaded.", NOTIF)
end

--[[
    Cora • CORE / BOOTSTRAP  —  goes in /main.lua
    (This is NOT the Main tab. The Main tab lives in maintab.lua.)
    Loads Obsidian + addons, downloads the moon icon, creates the window,
    forces a dark theme with a white accent, loads the tabs (maintab + settings),
    and adds a best-effort fade in/out on toggle.
--]]

return function(Cora)
    local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"

    local Library      = loadstring(game:HttpGet(repo .. "Library.lua"))()
    local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
    local SaveManager  = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

    -- Download the moon icon -> usable asset (falls back to lucide "moon")
    pcall(function()
        if makefolder and not (isfolder and isfolder("CoraData")) then
            makefolder("CoraData")
        end
    end)
    local moonIcon = "moon"
    pcall(function()
        if writefile and getcustomasset then
            local path = "CoraData/cora_moon.png"
            if not (isfile and isfile(path)) then
                writefile(path, game:HttpGet(Cora.MoonURL))
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

    -- Tabs (order = creation order)
    Cora.fetch("maintab.lua")()(Cora)
    Cora.fetch("settings.lua")()(Cora)

    -- Autoload config, then re-assert the white accent so it wins
    pcall(function() SaveManager:LoadAutoloadConfig() end)
    applyCoraScheme()

    ----------------------------------------------------------------
    -- Best-effort fade in/out on toggle (graceful no-op on failure)
    ----------------------------------------------------------------
    task.spawn(function()
        local UIS = game:GetService("UserInputService")
        local TS  = game:GetService("TweenService")
        local Options = Library.Options

        task.wait(0.3) -- let layout/AbsoluteSize settle

        -- Find the window root by locating the "Cora" title label,
        -- then walking up to the top-level frame under its ScreenGui.
        local function getWindowRoot()
            local roots = {}
            pcall(function() if gethui then table.insert(roots, gethui()) end end)
            pcall(function() table.insert(roots, game:GetService("CoreGui")) end)
            pcall(function()
                table.insert(roots, game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"))
            end)

            local best, bestArea
            for _, parent in ipairs(roots) do
                for _, sg in ipairs(parent:GetChildren()) do
                    if sg:IsA("ScreenGui") then
                        for _, d in ipairs(sg:GetDescendants()) do
                            if d:IsA("TextLabel") and d.Text == "Cora" then
                                local node = d
                                while node.Parent and node.Parent ~= sg do
                                    node = node.Parent
                                end
                                local area = node.AbsoluteSize.X * node.AbsoluteSize.Y
                                if not bestArea or area > bestArea then
                                    best, bestArea = node, area
                                end
                            end
                        end
                    end
                end
            end
            return best
        end

        local ok, err = pcall(function()
            local root = getWindowRoot()
            if not root then return end -- can't find it; skip silently

            -- Use existing CanvasGroup if the library already wraps it,
            -- otherwise wrap the window in a full-screen CanvasGroup.
            local cg
            if root:IsA("CanvasGroup") then
                cg = root
            else
                cg = Instance.new("CanvasGroup")
                cg.Name                  = "CoraFade"
                cg.BackgroundTransparency = 1
                cg.AnchorPoint           = Vector2.new(0, 0)
                cg.Position              = UDim2.fromScale(0, 0)
                cg.Size                  = UDim2.fromScale(1, 1)
                cg.ClipsDescendants      = false
                cg.ZIndex                = root.ZIndex
                cg.Parent                = root.Parent
                root.Parent              = cg
                -- root keeps its own Position/Size/AnchorPoint so drag/resize still work
            end

            local open = (root.Visible ~= false)
            cg.Visible          = true
            cg.GroupTransparency = open and 0 or 1
            cg.Interactable     = open

            local function animate(state)
                open = state
                pcall(function() root.Visible = true end) -- keep rendered; cg controls visibility
                cg.Interactable = state
                if state then cg.Visible = true end
                local ti = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                local tw = TS:Create(cg, ti, { GroupTransparency = state and 0 or 1 })
                tw:Play()
                if not state then
                    tw.Completed:Once(function()
                        if not open then cg.Visible = false end
                    end)
                end
            end

            -- Stop the library from instant-toggling so our fade is visible
            pcall(function() Library.ToggleKeybind = nil end)

            -- Drive the toggle ourselves, reading the editable keypicker value
            UIS.InputBegan:Connect(function(input, gp)
                if gp then return end
                if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
                if UIS:GetFocusedTextBox() then return end

                local picking = false
                pcall(function() picking = Options.MenuKeybind and Options.MenuKeybind.Picking end)
                if picking then return end

                local keyName = "P"
                pcall(function()
                    if Options.MenuKeybind and Options.MenuKeybind.Value then
                        keyName = Options.MenuKeybind.Value
                    end
                end)

                if input.KeyCode.Name == keyName then
                    animate(not open)
                end
            end)
        end)

        if not ok then
            warn("[Cora] Fade animation skipped (UI works normally): " .. tostring(err))
        end
    end)
end

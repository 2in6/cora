--[[
    Cora • Key System (Junkie)
    Returns a function(Cora) that blocks until a valid key is entered,
    then returns true. Saves the key so returning users skip the UI.
--]]

return function(Cora)
    local Junkie = loadstring(game:HttpGet("https://jnkie.com/sdk/library.lua"))()
    Junkie.service    = "Cora"
    Junkie.identifier = "1118494"
    Junkie.provider   = "Cora"

    local Players     = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

    -- Load any saved key
    local savedKey
    pcall(function()
        if isfile and isfile("cora_key.txt") then
            savedKey = readfile("cora_key.txt"):match("^%s*(.-)%s*$")
            if savedKey == "" then savedKey = nil end
        end
    end)

    local function verifyKey(key)
        local result = Junkie.check_key(key)
        if result and result.valid then
            if result.message == "KEYLESS" then
                getgenv().SCRIPT_KEY = "KEYLESS"
                return true, "Keyless mode"
            elseif result.message == "KEY_VALID" then
                getgenv().SCRIPT_KEY = key
                pcall(function() if writefile then writefile("cora_key.txt", key) end end)
                return true, "Key valid"
            end
            return false, "Invalid key"
        end
        return false, "Verification failed"
    end

    -- Silent auto-verify of saved key
    if savedKey then
        local ok = verifyKey(savedKey)
        if ok then return true end
    end

    -- Build custom key UI (Obsidian has no built-in key UI)
    local verified = false

    local KeyGui = Instance.new("ScreenGui")
    KeyGui.Name           = "CoraKeySystem"
    KeyGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    KeyGui.ResetOnSpawn   = false
    KeyGui.DisplayOrder    = 999
    KeyGui.IgnoreGuiInset  = true
    KeyGui.Parent          = PlayerGui

    local Backdrop = Instance.new("Frame")
    Backdrop.Size                   = UDim2.fromScale(1, 1)
    Backdrop.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
    Backdrop.BackgroundTransparency = 0.45
    Backdrop.BorderSizePixel        = 0
    Backdrop.ZIndex                 = 1
    Backdrop.Parent                 = KeyGui

    local Card = Instance.new("Frame")
    Card.Size             = UDim2.fromOffset(420, 240)
    Card.Position         = UDim2.fromScale(0.5, 0.5)
    Card.AnchorPoint      = Vector2.new(0.5, 0.5)
    Card.BackgroundColor3 = Color3.fromRGB(12, 12, 14)
    Card.BorderSizePixel  = 0
    Card.ZIndex           = 2
    Card.Parent           = KeyGui
    Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 12)
    local cs = Instance.new("UIStroke", Card)
    cs.Color, cs.Transparency, cs.Thickness = Color3.fromRGB(255,255,255), 0.82, 1

    local Header = Instance.new("Frame")
    Header.Size             = UDim2.new(1, 0, 0, 52)
    Header.BackgroundColor3 = Color3.fromRGB(18, 18, 20)
    Header.BorderSizePixel  = 0
    Header.ZIndex           = 3
    Header.Parent           = Card
    Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 12)
    local hfix = Instance.new("Frame", Header)
    hfix.Size, hfix.Position = UDim2.new(1,0,0,12), UDim2.new(0,0,1,-12)
    hfix.BackgroundColor3, hfix.BorderSizePixel, hfix.ZIndex = Color3.fromRGB(18,18,20), 0, 3

    local Title = Instance.new("TextLabel")
    Title.Size, Title.Position           = UDim2.new(1,-20,1,0), UDim2.fromOffset(20,0)
    Title.BackgroundTransparency         = 1
    Title.Text                           = "🌙  Cora"
    Title.TextColor3                     = Color3.fromRGB(240,240,240)
    Title.Font, Title.TextSize           = Enum.Font.GothamBold, 17
    Title.TextXAlignment                 = Enum.TextXAlignment.Left
    Title.ZIndex                         = 4
    Title.Parent                         = Header

    local Sub = Instance.new("TextLabel")
    Sub.Size, Sub.Position       = UDim2.new(1,-40,0,22), UDim2.fromOffset(20,62)
    Sub.BackgroundTransparency   = 1
    Sub.Text                     = "Enter your key to continue."
    Sub.TextColor3               = Color3.fromRGB(155,155,165)
    Sub.Font, Sub.TextSize       = Enum.Font.Gotham, 13
    Sub.TextXAlignment           = Enum.TextXAlignment.Left
    Sub.ZIndex                   = 3
    Sub.Parent                   = Card

    local Input = Instance.new("TextBox")
    Input.Size, Input.Position   = UDim2.new(1,-40,0,40), UDim2.fromOffset(20,94)
    Input.BackgroundColor3       = Color3.fromRGB(22,22,26)
    Input.BorderSizePixel        = 0
    Input.Text                   = ""
    Input.PlaceholderText        = "Paste key here..."
    Input.PlaceholderColor3      = Color3.fromRGB(90,90,100)
    Input.TextColor3             = Color3.fromRGB(220,220,230)
    Input.Font, Input.TextSize   = Enum.Font.Gotham, 13
    Input.ClearTextOnFocus       = false
    Input.ZIndex                 = 3
    Input.Parent                 = Card
    Instance.new("UICorner", Input).CornerRadius = UDim.new(0, 8)
    local is = Instance.new("UIStroke", Input)
    is.Color, is.Transparency, is.Thickness = Color3.fromRGB(255,255,255), 0.88, 1
    Instance.new("UIPadding", Input).PaddingLeft = UDim.new(0, 10)

    local Status = Instance.new("TextLabel")
    Status.Size, Status.Position   = UDim2.new(1,-40,0,18), UDim2.fromOffset(20,140)
    Status.BackgroundTransparency  = 1
    Status.Text                    = ""
    Status.TextColor3              = Color3.fromRGB(220,80,80)
    Status.Font, Status.TextSize   = Enum.Font.Gotham, 12
    Status.TextXAlignment          = Enum.TextXAlignment.Left
    Status.ZIndex                  = 3
    Status.Parent                  = Card

    local Row = Instance.new("Frame")
    Row.Size, Row.Position       = UDim2.new(1,-40,0,38), UDim2.fromOffset(20,168)
    Row.BackgroundTransparency   = 1
    Row.ZIndex                   = 3
    Row.Parent                   = Card
    local rl = Instance.new("UIListLayout", Row)
    rl.FillDirection            = Enum.FillDirection.Horizontal
    rl.HorizontalAlignment      = Enum.HorizontalAlignment.Right
    rl.VerticalAlignment        = Enum.VerticalAlignment.Center
    rl.Padding                  = UDim.new(0, 10)

    local function mkBtn(text, bg, fg)
        local b = Instance.new("TextButton")
        b.Size            = UDim2.fromOffset(110, 36)
        b.BackgroundColor3= bg
        b.BorderSizePixel = 0
        b.Text            = text
        b.TextColor3      = fg
        b.Font, b.TextSize= Enum.Font.GothamBold, 13
        b.AutoButtonColor = false
        b.ZIndex          = 4
        b.Parent          = Row
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
        return b
    end

    local CopyBtn   = mkBtn("Copy Link", Color3.fromRGB(30,30,35), Color3.fromRGB(200,200,210))
    local SubmitBtn = mkBtn("Submit Key", Color3.fromRGB(240,240,240), Color3.fromRGB(10,10,12))

    CopyBtn.MouseEnter:Connect(function() CopyBtn.BackgroundColor3 = Color3.fromRGB(45,45,52) end)
    CopyBtn.MouseLeave:Connect(function() CopyBtn.BackgroundColor3 = Color3.fromRGB(30,30,35) end)
    SubmitBtn.MouseEnter:Connect(function() SubmitBtn.BackgroundColor3 = Color3.fromRGB(210,210,210) end)
    SubmitBtn.MouseLeave:Connect(function() SubmitBtn.BackgroundColor3 = Color3.fromRGB(240,240,240) end)

    CopyBtn.MouseButton1Click:Connect(function()
        local link = Junkie.get_key_link()
        if setclipboard then
            setclipboard(link)
            Status.TextColor3 = Color3.fromRGB(100,210,130)
            Status.Text = "Link copied to clipboard."
            task.delay(2.5, function()
                if Status and Status.Text == "Link copied to clipboard." then Status.Text = "" end
            end)
        end
    end)

    local busy = false
    local function submit()
        if busy then return end
        local key = Input.Text:match("^%s*(.-)%s*$")
        if key == "" then
            Status.TextColor3 = Color3.fromRGB(220,80,80)
            Status.Text = "Please enter a key."
            return
        end
        busy = true
        SubmitBtn.Text = "Verifying..."
        Status.Text = ""
        task.spawn(function()
            local ok, msg = verifyKey(key)
            busy = false
            SubmitBtn.Text = "Submit Key"
            if ok then
                Status.TextColor3 = Color3.fromRGB(100,210,130)
                Status.Text = msg .. " — loading..."
                task.wait(0.8)
                KeyGui:Destroy()
                verified = true
            else
                Status.TextColor3 = Color3.fromRGB(220,80,80)
                Status.Text = msg
            end
        end)
    end

    SubmitBtn.MouseButton1Click:Connect(submit)
    Input.FocusLost:Connect(function(enter) if enter then submit() end end)

    repeat task.wait(0.1) until verified
    return true
end

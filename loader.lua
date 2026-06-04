local BASE = "https://raw.githubusercontent.com/2in6/cora/refs/heads/main/"
local repo = "https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/"

local Junkie = loadstring(game:HttpGet("https://jnkie.com/sdk/library.lua"))()
Junkie.service="Cora" Junkie.identifier="1118494" Junkie.provider="Cora"

local Players=game:GetService("Players")
local UserInputService=game:GetService("UserInputService")
local TweenService=game:GetService("TweenService")
local CoreGui=game:GetService("CoreGui")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local localPlayer=Players.LocalPlayer

local function buildKeyUI()
    local savedKey=nil
    pcall(function() if not isfolder('CoraHub') then makefolder('CoraHub') end if isfile('CoraHub/key.txt') then savedKey=readfile('CoraHub/key.txt') end end)
    if savedKey and savedKey~='' then local r=Junkie.check_key(savedKey) if r and r.valid then if r.message=="KEYLESS" then getgenv().SCRIPT_KEY="KEYLESS" return elseif r.message=="KEY_VALID" then getgenv().SCRIPT_KEY=savedKey return end end end
    local kl=Junkie.check_key("") if kl and kl.valid and kl.message=="KEYLESS" then getgenv().SCRIPT_KEY="KEYLESS" return end
    local SG=Instance.new('ScreenGui') SG.Name='CoraKey' SG.ZIndexBehavior=Enum.ZIndexBehavior.Global SG.ResetOnSpawn=false
    pcall(function() SG.Parent=CoreGui end) if not SG.Parent then SG.Parent=localPlayer:WaitForChild('PlayerGui') end
    local BD=Instance.new('Frame') BD.Size=UDim2.fromScale(1,1) BD.BackgroundColor3=Color3.new(0,0,0) BD.BackgroundTransparency=0.4 BD.BorderSizePixel=0 BD.ZIndex=10 BD.Parent=SG
    local M=Instance.new('Frame') M.Size=UDim2.fromOffset(420,240) M.AnchorPoint=Vector2.new(0.5,0.5) M.Position=UDim2.fromScale(0.5,0.5) M.BackgroundColor3=Color3.fromRGB(15,15,26) M.BorderSizePixel=0 M.ZIndex=11 M.Parent=SG
    Instance.new('UICorner',M).CornerRadius=UDim.new(0,6)
    local ab=Instance.new('Frame') ab.Size=UDim2.new(1,0,0,2) ab.BackgroundColor3=Color3.fromRGB(232,232,255) ab.BorderSizePixel=0 ab.ZIndex=12 ab.Parent=M
    Instance.new('UIStroke',M).Color=Color3.fromRGB(42,42,74)
    local function lbl(t,y,sz,col,xa) local l=Instance.new('TextLabel') l.Size=UDim2.new(1,-40,0,sz==22 and 30 or 20) l.Position=UDim2.fromOffset(0,y) l.BackgroundTransparency=1 l.Font=Enum.Font.Code l.Text=t l.TextColor3=col or Color3.fromRGB(255,255,255) l.TextSize=sz l.TextXAlignment=xa or Enum.TextXAlignment.Center l.ZIndex=12 l.Parent=M return l end
    lbl('Cora',16,22) lbl('Key System',46,13,Color3.fromRGB(140,140,180))
    local div=Instance.new('Frame') div.Size=UDim2.new(1,-40,0,1) div.Position=UDim2.fromOffset(20,72) div.BackgroundColor3=Color3.fromRGB(42,42,74) div.BorderSizePixel=0 div.ZIndex=12 div.Parent=M
    lbl('Enter your key to continue.',84,12,Color3.fromRGB(140,140,180),Enum.TextXAlignment.Left)
    local ibg=Instance.new('Frame') ibg.Size=UDim2.new(1,-40,0,36) ibg.Position=UDim2.fromOffset(20,112) ibg.BackgroundColor3=Color3.fromRGB(26,26,46) ibg.BorderSizePixel=0 ibg.ZIndex=12 ibg.Parent=M
    Instance.new('UICorner',ibg).CornerRadius=UDim.new(0,4)
    local iout=Instance.new('UIStroke') iout.Color=Color3.fromRGB(42,42,74) iout.Thickness=1 iout.Parent=ibg
    local inp=Instance.new('TextBox') inp.Size=UDim2.new(1,-16,1,0) inp.Position=UDim2.fromOffset(10,0) inp.BackgroundTransparency=1 inp.Font=Enum.Font.Code inp.Text='' inp.PlaceholderText='Paste your key here...' inp.PlaceholderColor3=Color3.fromRGB(80,80,120) inp.TextColor3=Color3.fromRGB(232,232,255) inp.TextSize=13 inp.TextXAlignment=Enum.TextXAlignment.Left inp.ClearTextOnFocus=false inp.ZIndex=13 inp.Parent=ibg
    local stt=Instance.new('TextLabel') stt.Size=UDim2.new(1,-40,0,16) stt.Position=UDim2.fromOffset(20,152) stt.BackgroundTransparency=1 stt.Font=Enum.Font.Code stt.Text='' stt.TextColor3=Color3.fromRGB(140,140,180) stt.TextSize=12 stt.TextXAlignment=Enum.TextXAlignment.Left stt.ZIndex=12 stt.Parent=M
    local function mkBtn(t,x,w,ac) local b=Instance.new('TextButton') b.Size=UDim2.fromOffset(w,32) b.Position=UDim2.fromOffset(x,176) b.BackgroundColor3=ac and Color3.fromRGB(232,232,255) or Color3.fromRGB(26,26,46) b.BorderSizePixel=0 b.Font=Enum.Font.Code b.Text=t b.TextColor3=ac and Color3.fromRGB(15,15,26) or Color3.fromRGB(180,180,220) b.TextSize=13 b.ZIndex=12 b.Parent=M Instance.new('UICorner',b).CornerRadius=UDim.new(0,4) local s=Instance.new('UIStroke') s.Color=ac and Color3.fromRGB(232,232,255) or Color3.fromRGB(42,42,74) s.Thickness=1 s.Parent=b return b end
    local bV=mkBtn('Verify Key',20,190,true) local bG=mkBtn('Get Key',220,90,false) local bP=mkBtn('Paste',320,80,false)
    local function setS(m,c) stt.Text=m stt.TextColor3=c or Color3.fromRGB(140,140,180) end
    local function fadeOut() TweenService:Create(BD,TweenInfo.new(0.4),{BackgroundTransparency=1}):Play() TweenService:Create(M,TweenInfo.new(0.4),{BackgroundTransparency=1}):Play() for _,d in ipairs(M:GetDescendants()) do if d:IsA('TextLabel') or d:IsA('TextBox') or d:IsA('TextButton') then TweenService:Create(d,TweenInfo.new(0.4),{TextTransparency=1}):Play() end end task.delay(0.45,function() SG:Destroy() end) end
    local vfy=false
    bV.MouseButton1Click:Connect(function() if vfy then return end local key=inp.Text:match('^%s*(.-)%s*$') if key=='' then setS('! Enter a key.',Color3.fromRGB(255,100,100)) return end vfy=true bV.Text='Verifying...' setS('Checking...') task.spawn(function() local ok,r=pcall(function() return Junkie.check_key(key) end) if ok and r and r.valid then if r.message=="KEYLESS" then getgenv().SCRIPT_KEY="KEYLESS" setS('✓ Keyless.',Color3.fromRGB(100,255,140)) elseif r.message=="KEY_VALID" then getgenv().SCRIPT_KEY=key setS('✓ Accepted!',Color3.fromRGB(100,255,140)) pcall(function() if not isfolder('CoraHub') then makefolder('CoraHub') end writefile('CoraHub/key.txt',key) end) else setS('✗ Invalid key.',Color3.fromRGB(255,100,100)) bV.Text='Verify Key' vfy=false return end task.delay(0.8,fadeOut) else setS('✗ Invalid or expired.',Color3.fromRGB(255,100,100)) bV.Text='Verify Key' vfy=false end end) end)
    bG.MouseButton1Click:Connect(function() local ok,link=pcall(function() return Junkie.get_key_link() end) if ok and link then pcall(function() if setclipboard then setclipboard(link) end end) setS('✓ Link copied!',Color3.fromRGB(100,255,140)) end end)
    bP.MouseButton1Click:Connect(function() local ok,t=pcall(function() return getclipboard and getclipboard() or '' end) if ok and t and t~='' then inp.Text=t:match('^%s*(.-)%s*$') setS('Pasted.') end end)
    local drag,ds,sp=false,nil,nil
    M.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=true ds=i.Position sp=M.Position end end)
    M.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end end)
    UserInputService.InputChanged:Connect(function(i) if drag and i.UserInputType==Enum.UserInputType.MouseMovement then local d=i.Position-ds M.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y) end end)
    M.BackgroundTransparency=1 BD.BackgroundTransparency=1
    TweenService:Create(BD,TweenInfo.new(0.3),{BackgroundTransparency=0.4}):Play()
    TweenService:Create(M,TweenInfo.new(0.3),{BackgroundTransparency=0}):Play()
    while not getgenv().SCRIPT_KEY do task.wait(0.05) end
end
buildKeyUI()

local SupportedGames={[286090429]="arsenal",[126509999114328]="nights"}
local module=SupportedGames[game.PlaceId]
if not module then
    if ReplicatedStorage:FindFirstChild("EntityInfo") or ReplicatedStorage:FindFirstChild("RemotesFolder") or ReplicatedStorage:FindFirstChild("Bricks") then module="doors" else module="unsupported" end
end

getgenv().Cora={
    Library      = loadstring(game:HttpGet(repo.."Library.lua"))(),
    ThemeManager = loadstring(game:HttpGet(repo.."addons/ThemeManager.lua"))(),
    SaveManager  = loadstring(game:HttpGet(repo.."addons/SaveManager.lua"))(),
    gameName     = module,
}

loadstring(game:HttpGet(BASE..module..".lua"))()

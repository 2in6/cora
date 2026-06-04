local Cora = getgenv().Cora
local Library, ThemeManager, SaveManager = Cora.Library, Cora.ThemeManager, Cora.SaveManager

local Players=game:GetService('Players')
local UserInputService=game:GetService('UserInputService')
local RunService=game:GetService('RunService')
local HttpService=game:GetService('HttpService')
local ReplicatedStorage=game:GetService('ReplicatedStorage')
local Lighting=game:GetService('Lighting')
local PathfindingService=game:GetService('PathfindingService')
local Debris=game:GetService('Debris')
local localPlayer=Players.LocalPlayer
local camera=workspace.CurrentCamera

local gameName=Cora.gameName
local titleMap={arsenal='Arsenal',nights='99 Nights in the Forest',doors='Doors',unsupported='Unsupported'}
local windowTitle='Cora - '..(titleMap[gameName] or 'Unsupported')
local configFolder='CoraHub/'..tostring(game.PlaceId)

local character=localPlayer.Character or localPlayer.CharacterAdded:Wait()
local humanoid=character:WaitForChild('Humanoid')
local rootPart=character:WaitForChild('HumanoidRootPart')
localPlayer.CharacterAdded:Connect(function(c) character=c humanoid=c:WaitForChild('Humanoid') rootPart=c:WaitForChild('HumanoidRootPart') end)

local Window=Library:CreateWindow({Title=windowTitle,Center=true,AutoShow=true,TabPadding=8,MenuFadeTime=0.2})
local Tabs={}

local UnbindKeys={Enum.KeyCode.Escape,Enum.KeyCode.Backspace,Enum.KeyCode.Home}
local function isUnbindKey(kc) for _,k in ipairs(UnbindKeys) do if k==kc then return true end end return false end
local function getScreenCenter() return Vector2.new(camera.ViewportSize.X/2,camera.ViewportSize.Y/2) end
local function w2v(pos) local sp,on=camera:WorldToViewportPoint(pos) return Vector2.new(sp.X,sp.Y),on,sp.Z end
local function notify(t,m) Library:Notify(t..': '..m,4) end
local function nameContains(name,kw) local low=name:lower() for _,k in ipairs(kw) do if low:find(k:lower(),1,true) then return true end end return false end
local function isValidEnemy(player,tc) if player==localPlayer then return false end local c=player.Character if not c then return false end local h=c:FindFirstChildOfClass('Humanoid') if not h or h.Health<=0 then return false end if not c:FindFirstChild('HumanoidRootPart') then return false end if tc and Library.Toggles[tc] and Library.Toggles[tc].Value then if player.Team and localPlayer.Team and player.Team==localPlayer.Team then return false end end return true end
local Options=Library.Options local Toggles=Library.Toggles
local function makeKeyPicker(gb,text,idx,onOn,onOff) local lbl=gb:AddLabel(text) lbl:AddKeyPicker(idx,{Default='None',Mode='Toggle',Text=text,NoUI=false,ChangedCallback=function(new) if typeof(new)=='EnumItem' and new.EnumType==Enum.KeyCode then if isUnbindKey(new) then Options[idx]:SetValue({'None',Options[idx].Mode or 'Toggle'}) end end end}) Options[idx]:OnClick(function() if Options[idx].Mode=='Toggle' then if Options[idx]:GetState() then onOn() else onOff() end end end) Library:GiveSignal(RunService.Heartbeat:Connect(function() if Options[idx] and Options[idx].Mode=='Hold' then if Options[idx]:GetState() then onOn() else onOff() end end end)) return lbl end

local SKEL={{'Head','UpperTorso'},{'UpperTorso','LowerTorso'},{'UpperTorso','LeftUpperArm'},{'LeftUpperArm','LeftLowerArm'},{'LeftLowerArm','LeftHand'},{'UpperTorso','RightUpperArm'},{'RightUpperArm','RightLowerArm'},{'RightLowerArm','RightHand'},{'LowerTorso','LeftUpperLeg'},{'LeftUpperLeg','LeftLowerLeg'},{'LeftLowerLeg','LeftFoot'},{'LowerTorso','RightUpperLeg'},{'RightUpperLeg','RightLowerLeg'},{'RightLowerLeg','RightFoot'}}
local function newD(t,p) local d=Drawing.new(t) for k,v in pairs(p) do d[k]=v end return d end
local function makeESPObj(label) return {drawings={boxOutline=newD('Square',{Visible=false,Filled=false,Thickness=3,Color=Color3.new(0,0,0)}),box=newD('Square',{Visible=false,Filled=false,Thickness=1}),name=newD('Text',{Visible=false,Size=13,Center=true,Outline=true,Text=label or ''}),hpBg=newD('Square',{Visible=false,Filled=true,Color=Color3.new(0,0,0)}),hp=newD('Square',{Visible=false,Filled=true}),tracer=newD('Line',{Visible=false,Thickness=1})},skel=(function() local t={} for i=1,#SKEL do t[i]=newD('Line',{Visible=false,Thickness=1}) end return t end)()} end
local function hideObj(o) for _,d in pairs(o.drawings) do d.Visible=false end for _,l in pairs(o.skel) do l.Visible=false end end
local function renderObj(o,rp,hp_,label,hp,maxHp,color,trCol,skCol,sBox,sName,sHp,sTr,sSkel,char) local rsp,ron,depth=w2v(rp) local hsp,hon=w2v(hp_) if not ron or not hon or depth<=0 then hideObj(o) return end local h=math.abs(rsp.Y-hsp.Y) local w=h*0.65 local bx=rsp.X-w/2 local by=hsp.Y if sBox then o.drawings.boxOutline.Size=Vector2.new(w+2,h+2) o.drawings.boxOutline.Position=Vector2.new(bx-1,by-1) o.drawings.boxOutline.Visible=true o.drawings.box.Size=Vector2.new(w,h) o.drawings.box.Position=Vector2.new(bx,by) o.drawings.box.Color=color o.drawings.box.Visible=true else o.drawings.box.Visible=false o.drawings.boxOutline.Visible=false end if sName then o.drawings.name.Position=Vector2.new(rsp.X,hsp.Y-16) o.drawings.name.Color=color o.drawings.name.Visible=true else o.drawings.name.Visible=false end if sHp and hp and maxHp then local pct=math.clamp(hp/math.max(maxHp,1),0,1) local barH=h*pct local barX=bx-6 o.drawings.hpBg.Size=Vector2.new(4,h) o.drawings.hpBg.Position=Vector2.new(barX,by) o.drawings.hpBg.Visible=true o.drawings.hp.Size=Vector2.new(4,barH) o.drawings.hp.Position=Vector2.new(barX,by+(h-barH)) o.drawings.hp.Color=Color3.fromRGB((1-pct)*255,pct*255,0) o.drawings.hp.Visible=true else o.drawings.hpBg.Visible=false o.drawings.hp.Visible=false end if sTr then local c=getScreenCenter() o.drawings.tracer.From=Vector2.new(c.X,camera.ViewportSize.Y) o.drawings.tracer.To=rsp o.drawings.tracer.Color=trCol o.drawings.tracer.Visible=true else o.drawings.tracer.Visible=false end if sSkel and char then for i,conn in ipairs(SKEL) do local pA=char:FindFirstChild(conn[1]) local pB=char:FindFirstChild(conn[2]) local ln=o.skel[i] if pA and pB then local spA,onA,dA=w2v(pA.Position) local spB,onB,dB=w2v(pB.Position) if onA and onB and dA>0 and dB>0 then ln.From=spA ln.To=spB ln.Color=skCol ln.Visible=true else ln.Visible=false end else ln.Visible=false end end else for _,l in pairs(o.skel) do l.Visible=false end end end

-- movement (used by arsenal/nights/unsupported)
local wsEnabled=false local defaultWS=16 local customWS=50
local flyEnabled=false local flySpeed=50 local flyBV,flyBG,flyConn=nil,nil,nil
local freecamEnabled=false local fcSpeed=20 local fcConn=nil local fcPitch=0 local fcYaw=0 local savedCamType=nil local isRMB=false
local function startFly() if flyConn then flyConn:Disconnect() flyConn=nil end if flyBV then flyBV:Destroy() end if flyBG then flyBG:Destroy() end flyBV=Instance.new('BodyVelocity') flyBV.Velocity=Vector3.zero flyBV.MaxForce=Vector3.new(1e5,1e5,1e5) flyBV.Parent=rootPart flyBG=Instance.new('BodyGyro') flyBG.MaxTorque=Vector3.new(1e5,1e5,1e5) flyBG.P=1e4 flyBG.Parent=rootPart humanoid.PlatformStand=true flyConn=RunService.Heartbeat:Connect(function() local cam=workspace.CurrentCamera local dir=Vector3.zero if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir+=cam.CFrame.LookVector end if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir-=cam.CFrame.LookVector end if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir-=cam.CFrame.RightVector end if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir+=cam.CFrame.RightVector end if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir+=Vector3.new(0,1,0) end if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir-=Vector3.new(0,1,0) end if dir.Magnitude>0 then dir=dir.Unit end flyBV.Velocity=dir*flySpeed flyBG.CFrame=cam.CFrame end) end
local function stopFly() flyEnabled=false if flyConn then flyConn:Disconnect() flyConn=nil end if flyBV then flyBV:Destroy() flyBV=nil end if flyBG then flyBG:Destroy() flyBG=nil end if humanoid then humanoid.PlatformStand=false end if Toggles.FlyToggle then Toggles.FlyToggle:SetValue(false) end end
local function startFreecam() local cam=workspace.CurrentCamera savedCamType=cam.CameraType cam.CameraType=Enum.CameraType.Scriptable if rootPart then local hcf=rootPart.CFrame*CFrame.new(0,1.5,0) cam.CFrame=hcf local lv=hcf.LookVector fcPitch=math.asin(math.clamp(lv.Y,-1,1)) fcYaw=math.atan2(-lv.X,-lv.Z) end if humanoid then humanoid.WalkSpeed=0 humanoid.JumpPower=0 end fcConn=RunService.RenderStepped:Connect(function(dt) if not freecamEnabled then return end local c=workspace.CurrentCamera if isRMB then UserInputService.MouseBehavior=Enum.MouseBehavior.LockCurrentPosition local d=UserInputService:GetMouseDelta() fcYaw-=d.X*0.004 fcPitch=math.clamp(fcPitch-d.Y*0.004,-math.pi/2+0.01,math.pi/2-0.01) else UserInputService.MouseBehavior=Enum.MouseBehavior.Default end local rot=CFrame.Angles(0,fcYaw,0)*CFrame.Angles(fcPitch,0,0) local dir=Vector3.zero if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir+=rot.LookVector end if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir-=rot.LookVector end if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir-=rot.RightVector end if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir+=rot.RightVector end if UserInputService:IsKeyDown(Enum.KeyCode.E) then dir+=Vector3.new(0,1,0) end if UserInputService:IsKeyDown(Enum.KeyCode.Q) then dir-=Vector3.new(0,1,0) end if dir.Magnitude>0 then dir=dir.Unit end c.CFrame=CFrame.new(c.CFrame.Position+dir*fcSpeed*dt)*rot end) end
local function stopFreecam() freecamEnabled=false isRMB=false UserInputService.MouseBehavior=Enum.MouseBehavior.Default if fcConn then fcConn:Disconnect() fcConn=nil end if humanoid then humanoid.WalkSpeed=wsEnabled and customWS or defaultWS humanoid.JumpPower=50 end local cam=workspace.CurrentCamera if savedCamType then cam.CameraType=savedCamType end if Toggles.FreecamToggle then Toggles.FreecamToggle:SetValue(false) end end
UserInputService.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton2 then isRMB=true end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton2 then isRMB=false if not freecamEnabled then UserInputService.MouseBehavior=Enum.MouseBehavior.Default end end end)

local fovCircle=Drawing.new('Circle') fovCircle.Visible=false fovCircle.Radius=120 fovCircle.Color=Color3.fromRGB(255,255,255) fovCircle.Thickness=1 fovCircle.Filled=false fovCircle.NumSides=64
local aimbotActive=false

Tabs.Player=Window:AddTab('Player')
local MB=Tabs.Player:AddLeftGroupbox('Movement') local CB=Tabs.Player:AddRightGroupbox('Camera')
MB:AddToggle('WalkspeedToggle',{Text='Walkspeed',Default=false,Callback=function(v) wsEnabled=v if humanoid then humanoid.WalkSpeed=v and customWS or defaultWS end end})
MB:AddSlider('WalkspeedValue',{Text='Walk Speed',Default=50,Min=16,Max=250,Rounding=0,Callback=function(v) customWS=v if wsEnabled and humanoid then humanoid.WalkSpeed=customWS end end})
makeKeyPicker(MB,'Walkspeed Key','WalkspeedKeybind',function() wsEnabled=true if humanoid then humanoid.WalkSpeed=customWS end Toggles.WalkspeedToggle:SetValue(true) end,function() wsEnabled=false if humanoid then humanoid.WalkSpeed=defaultWS end Toggles.WalkspeedToggle:SetValue(false) end)
MB:AddDivider()
MB:AddToggle('FlyToggle',{Text='Fly',Default=false,Callback=function(v) flyEnabled=v if v then startFly() else stopFly() end end})
MB:AddSlider('FlySpeed',{Text='Fly Speed',Default=50,Min=10,Max=300,Rounding=0,Callback=function(v) flySpeed=v end})
makeKeyPicker(MB,'Fly Key','FlyKeybind',function() if not flyEnabled then flyEnabled=true startFly() Toggles.FlyToggle:SetValue(true) end end,function() if flyEnabled then stopFly() end end)
CB:AddToggle('FreecamToggle',{Text='Freecam',Default=false,Callback=function(v) freecamEnabled=v if v then startFreecam() else stopFreecam() end end})
CB:AddSlider('FreecamSpeed',{Text='Freecam Speed',Default=20,Min=5,Max=200,Rounding=0,Callback=function(v) fcSpeed=v end})
makeKeyPicker(CB,'Freecam Key','FreecamKeybind',function() if not freecamEnabled then freecamEnabled=true startFreecam() Toggles.FreecamToggle:SetValue(true) end end,function() if freecamEnabled then stopFreecam() end end)

-- ===== SETTINGS FOOTER (paste at end of every module) =====
Tabs.Settings=Window:AddTab('Settings')
local MenuBox=Tabs.Settings:AddLeftGroupbox('Menu') local ThemeBox=Tabs.Settings:AddLeftGroupbox('Theme')
MenuBox:AddLabel('UI Toggle Key'):AddKeyPicker('MenuKeybind',{Default='P',NoUI=true,Text='UI Toggle Key'})
Library.ToggleKeybind=Options.MenuKeybind
MenuBox:AddButton({Text='Unload',Func=function() pcall(function() fovCircle:Remove() end) Library:Unload() end})
ThemeManager.BuiltInThemes['Cora']={1,HttpService:JSONDecode('{"FontColor":"ffffff","MainColor":"1a1a2e","AccentColor":"e8e8ff","BackgroundColor":"0f0f1a","OutlineColor":"2a2a4a"}')}
ThemeManager:SetLibrary(Library) ThemeManager:SetFolder('CoraHub') ThemeManager:ApplyToGroupbox(ThemeBox)
SaveManager:SetLibrary(Library) SaveManager:IgnoreThemeSettings() SaveManager:SetIgnoreIndexes({'MenuKeybind'})
SaveManager:SetFolder(configFolder) SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyTheme('Cora') SaveManager:LoadAutoloadConfig()

local Cora = getgenv().Cora
assert(Cora and Cora.Library, "[Cora] Library missing - loader failed")
local Library, ThemeManager, SaveManager = Cora.Library, Cora.ThemeManager, Cora.SaveManager
local Options, Toggles = Library.Options, Library.Toggles

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

Tabs.Aimbot=Window:AddTab('Aimbot') Tabs.ESP=Window:AddTab('ESP')
local arsenalESP={}
local function rm(p) local o=arsenalESP[p] if not o then return end for _,d in pairs(o.drawings) do pcall(function() d:Remove() end) end for _,l in pairs(o.skel) do pcall(function() l:Remove() end) end arsenalESP[p]=nil end
for _,p in ipairs(Players:GetPlayers()) do if p~=localPlayer then arsenalESP[p]=makeESPObj(p.Name) end end
Players.PlayerAdded:Connect(function(p) p.CharacterAdded:Connect(function() task.wait(0.1) arsenalESP[p]=makeESPObj(p.Name) end) end)
Players.PlayerRemoving:Connect(rm)
Library:GiveSignal(RunService.RenderStepped:Connect(function() local en=Toggles.ESPEnabled and Toggles.ESPEnabled.Value local sB=Toggles.ESPBox and Toggles.ESPBox.Value local sN=Toggles.ESPName and Toggles.ESPName.Value local sH=Toggles.ESPHealth and Toggles.ESPHealth.Value local sT=Toggles.ESPTracer and Toggles.ESPTracer.Value local sS=Toggles.ESPSkeleton and Toggles.ESPSkeleton.Value local ec=Options.ESPColor and Options.ESPColor.Value or Color3.fromRGB(255,50,50) local tc=Options.ESPTracerColor and Options.ESPTracerColor.Value or Color3.fromRGB(255,255,255) local sc=Options.ESPSkelColor and Options.ESPSkelColor.Value or Color3.fromRGB(255,255,255) for _,p in ipairs(Players:GetPlayers()) do if p==localPlayer then continue end local o=arsenalESP[p] if not o then continue end if not en or not isValidEnemy(p,'ESPTeamCheck') then hideObj(o) continue end local c=p.Character local r=c and c:FindFirstChild('HumanoidRootPart') local hd=c and c:FindFirstChild('Head') local h=c and c:FindFirstChildOfClass('Humanoid') if not r or not hd or not h then hideObj(o) continue end renderObj(o,r.Position,hd.Position+Vector3.new(0,0.7,0),p.Name,h.Health,h.MaxHealth,ec,tc,sc,sB,sN,sH,sT,sS,c) end end))
Library:GiveSignal(RunService.RenderStepped:Connect(function() local en=Toggles.AimbotEnabled and Toggles.AimbotEnabled.Value fovCircle.Visible=en or false if en then fovCircle.Position=getScreenCenter() fovCircle.Radius=Options.AimbotFOV and Options.AimbotFOV.Value or 120 end if not en or not aimbotActive then return end local ctr=getScreenCenter() local fovR=Options.AimbotFOV and Options.AimbotFOV.Value or 120 local cl,cd=nil,fovR for _,p in ipairs(Players:GetPlayers()) do if not isValidEnemy(p,'AimbotTeamCheck') then continue end local hd=p.Character and p.Character:FindFirstChild('Head') if not hd then continue end local sp,on,d=w2v(hd.Position) if not on or d<=0 then continue end local dist=(ctr-sp).Magnitude if dist<cd then cd=dist cl=hd end end if not cl then return end local f=1/(Options.AimbotSmoothing and Options.AimbotSmoothing.Value or 5) camera.CFrame=camera.CFrame:Lerp(CFrame.new(camera.CFrame.Position,cl.Position),f) end))
local AL=Tabs.Aimbot:AddLeftGroupbox('Aimbot') local AR=Tabs.Aimbot:AddRightGroupbox('Settings')
AL:AddToggle('AimbotEnabled',{Text='Enable Aimbot',Default=false}) AL:AddToggle('AimbotTeamCheck',{Text='Team Check',Default=true})
AL:AddLabel('Aimbot Key'):AddKeyPicker('AimbotKeybind',{Default='MB2',Mode='Hold',Text='Aimbot',NoUI=false,ChangedCallback=function(new) if typeof(new)=='EnumItem' and new.EnumType==Enum.KeyCode then if isUnbindKey(new) then Options.AimbotKeybind:SetValue({'None','Hold'}) end end end})
Library:GiveSignal(RunService.Heartbeat:Connect(function() if Options.AimbotKeybind then aimbotActive=Options.AimbotKeybind:GetState() end end))
AR:AddSlider('AimbotFOV',{Text='FOV Radius',Default=120,Min=10,Max=500,Rounding=0}) AR:AddSlider('AimbotSmoothing',{Text='Smoothness',Default=5,Min=1,Max=20,Rounding=0})
local EL=Tabs.ESP:AddLeftGroupbox('ESP') local ER=Tabs.ESP:AddRightGroupbox('Style')
EL:AddToggle('ESPEnabled',{Text='Enable ESP',Default=false}) EL:AddToggle('ESPTeamCheck',{Text='Team Check',Default=true}) EL:AddToggle('ESPBox',{Text='Box',Default=true}) EL:AddToggle('ESPName',{Text='Name',Default=true}) EL:AddToggle('ESPHealth',{Text='Health Bar',Default=true}) EL:AddToggle('ESPSkeleton',{Text='Skeleton',Default=false}) EL:AddToggle('ESPTracer',{Text='Tracers',Default=false})
makeKeyPicker(EL,'ESP Key','ESPKeybind',function() Toggles.ESPEnabled:SetValue(true) end,function() if Options.ESPKeybind and Options.ESPKeybind.Mode=='Hold' then Toggles.ESPEnabled:SetValue(false) end end)
ER:AddLabel('Box Color'):AddColorPicker('ESPColor',{Default=Color3.fromRGB(255,50,50),Title='Box'}) ER:AddLabel('Skeleton Color'):AddColorPicker('ESPSkelColor',{Default=Color3.fromRGB(255,255,255),Title='Skeleton'}) ER:AddLabel('Tracer Color'):AddColorPicker('ESPTracerColor',{Default=Color3.fromRGB(255,255,255),Title='Tracer'})

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

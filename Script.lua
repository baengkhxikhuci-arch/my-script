--[[ BankZa Mdz - Arc Warp v4 | Delta Android
     created by BankZa Mdz
     + เมนูชิดขวา + ขอบดำกัน UI ทับ/เลื่อนมั่วตอนวิ่ง
     + รูปโปรไฟล์ + ชื่อ + ไอดี
     + เวลาปัจจุบัน ]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")

local PLR = Players.LocalPlayer
local MAKER = "BankZa Mdz"

local CFG = {
    pin = nil, arcHeight = 450, liftTime = 0.10, flyTime = 0.25, dropTime = 0.15,
    god = true, antiStun = true, godUntil = 0,
    speed_on = false, speed_val = 16, speed_min = 1, speed_max = 10000,
    lockDrag = true  -- ล็อกตำแหน่งเมนูกันเลื่อนมั่วตอนวิ่ง
}

local char, hum, hrp
local function refresh()
    char = PLR.Character
    hum = char and char:FindFirstChildOfClass("Humanoid")
    hrp = char and char:FindFirstChild("HumanoidRootPart")
end
PLR.CharacterAdded:Connect(function() task.wait(0.6) refresh() end)
refresh()

local function groundAt(pos)
    local p = RaycastParams.new()
    p.FilterType = Enum.RaycastFilterType.Exclude
    p.FilterDescendantsInstances = {char}
    local hit = workspace:Raycast(pos + Vector3.new(0, 80, 0), Vector3.new(0, -900, 0), p)
    return hit and (hit.Position + Vector3.new(0, 4, 0)) or (pos + Vector3.new(0, 4, 0))
end

local function lockStates()
    hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
    pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end)
end

local function moveSteps(fromP, toP, time, steps)
    local dt = time / steps
    for i = 1, steps do
        if not (hrp and hrp.Parent) then return false end
        hrp.CFrame = CFrame.new(fromP:Lerp(toP, i / steps))
        if hum.Health < hum.MaxHealth then hum.Health = hum.MaxHealth end
        if i < steps then task.wait(dt) end
    end
    return true
end

local warping = false
local function returnBase()
    if warping or not CFG.pin then return end
    refresh()
    if not (hrp and hum) then return end
    warping = true
    CFG.godUntil = os.clock() + CFG.liftTime + CFG.flyTime + CFG.dropTime + 1.5
    lockStates()
    local g = groundAt(CFG.pin.Position)
    local s = hrp.CFrame.Position
    local topY = math.max(s.Y, g.Y) + CFG.arcHeight
    if not moveSteps(s, Vector3.new(s.X, topY, s.Z), CFG.liftTime, 6) then warping = false return end
    if not moveSteps(Vector3.new(s.X, topY, s.Z), Vector3.new(g.X, topY, g.Z), CFG.flyTime, 8) then warping = false return end
    if not moveSteps(Vector3.new(g.X, topY, g.Z), g, CFG.dropTime, 6) then warping = false return end
    if hrp and hrp.Parent then
        hrp.CFrame = CFrame.new(g)
        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        lockStates()
        print(" | ARC WARP สำเร็จ | " .. (CFG.liftTime + CFG.flyTime + CFG.dropTime) .. "s")
    end
    warping = false
end

RunService.Heartbeat:Connect(function()
    if not (hum and hum.Parent) then refresh() return end
    if CFG.god then
        if hum.Health < hum.MaxHealth then hum.Health = hum.MaxHealth end
        hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
    end
    if CFG.antiStun and not warping then
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        local st = hum:GetState()
        if st == Enum.HumanoidStateType.GettingUp or st == Enum.HumanoidStateType.Ragdoll
            or st == Enum.HumanoidStateType.FallingDown or st == Enum.HumanoidStateType.Physics then
            pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end)
        end
        if hrp and hrp.Parent then
            local v = hrp.AssemblyLinearVelocity
            if math.abs(v.Y) > 0.1 and hum:GetState() == Enum.HumanoidStateType.Running then
                hrp.AssemblyLinearVelocity = Vector3.new(v.X, 0, v.Z)
            end
        end
    end
    if CFG.speed_on and not warping then
        hum.WalkSpeed = math.clamp(CFG.speed_val, CFG.speed_min, CFG.speed_max)
    end
end)

RunService.Heartbeat:Connect(function()
    if not (char and CFG.antiStun) then return end
    for _, v in ipairs(char:GetChildren()) do
        if v:IsA("BoolValue") or v:IsA("StringValue") then
            local n = v.Name:lower()
            if n:find("stun") or n:find("freeze") or n:find("knock") or n:find("down")
                or n:find("ragdoll") or n:find("slow") then pcall(function() v:Destroy() end) end
        end
    end
    for _, a in ipairs(char:GetAttributes()) do
        local n = a:lower()
        if n:find("stun") or n:find("freeze") or n:find("knock") or n:find("ragdoll") or n:find("down") then
            pcall(function() char:SetAttribute(a, false) end)
        end
    end
end)

PLR.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new(0, 0))
end)

-- ===== GUI: ฝั่งขวา + ขอบดำ =====
local gui = Instance.new("ScreenGui")
gui.Name = "BZ_" .. MAKER:gsub("%s", "")
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = PLR:WaitForChild("PlayerGui")

local function blackBorder(inst, thick)
    local s = Instance.new("UIStroke")
    s.Color = Color3.new(0, 0, 0)
    s.Thickness = thick or 2
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = inst
    return s
end

-- ปุ่มเปิด/ปิด (ชิดขอบขวา)
local openBtn = Instance.new("TextButton")
openBtn.Size = UDim2.new(0, 110, 0, 38)
openBtn.Position = UDim2.new(1, -122, 0.35, 0)
openBtn.BackgroundColor3 = Color3.fromRGB(120, 20, 140)
openBtn.Text = "BZ เปิดเมนู"
openBtn.TextColor3 = Color3.fromRGB(255, 235, 90)
openBtn.Font = Enum.Font.GothamBold
openBtn.TextSize = 13
openBtn.BorderSizePixel = 0
openBtn.Parent = gui
Instance.new("UICorner", openBtn).CornerRadius = UDim.new(0, 8)
blackBorder(openBtn, 3)

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 250, 0, 380)
frame.Position = UDim2.new(1, -262, 0.12, 0)  -- ชิดขอบขวา
frame.BackgroundColor3 = Color3.fromRGB(16, 16, 22)
frame.BorderSizePixel = 0
frame.Active = true
frame.Visible = false
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)
blackBorder(frame, 4)  -- ขอบดำกัน UI ทับ/กันไม่ให้เลื่อนมั่ว

openBtn.MouseButton1Click:Connect(function()
    frame.Visible = not frame.Visible
    openBtn.Text = frame.Visible and "BZ ปิดเมนู" or "BZ เปิดเมนู"
end)

local top = Instance.new("Frame")
top.Size = UDim2.new(1, 0, 0, 34)
top.BackgroundColor3 = Color3.fromRGB(120, 20, 140)
top.BorderSizePixel = 0
top.Parent = frame
Instance.new("UICorner", top).CornerRadius = UDim.new(0, 12)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -8, 1, 0)
title.BackgroundTransparency = 1
title.Text = " | " .. MAKER
title.TextColor3 = Color3.fromRGB(255, 235, 90)
title.Font = Enum.Font.GothamBold
title.TextSize = 13
title.Parent = top

local function flash(msg)
    title.Text = " | " .. msg
    task.delay(2.2, function() title.Text = " | " .. MAKER end)
end

-- ===== แถบโปรไฟล์: รูป + ชื่อ + ไอดี =====
local prof = Instance.new("Frame")
prof.Size = UDim2.new(1, -16, 0, 62)
prof.Position = UDim2.new(0, 8, 0, 40)
prof.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
prof.BorderSizePixel = 0
prof.Parent = frame
Instance.new("UICorner", prof).CornerRadius = UDim.new(0, 8)
blackBorder(prof, 2)

local avatar = Instance.new("ImageLabel")
avatar.Size = UDim2.new(0, 48, 0, 48)
avatar.Position = UDim2.new(0, 6, 0.5, -24)
avatar.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
avatar.BorderSizePixel = 0
avatar.Parent = prof
Instance.new("UICorner", avatar).CornerRadius = UDim.new(0.5, 0)

task.spawn(function()
    local ok, url = pcall(function()
        return Players:GetUserThumbnailAsync(PLR.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
    end)
    if ok then avatar.Image = url end
end)

local nameLbl = Instance.new("TextLabel")
nameLbl.Size = UDim2.new(1, -66, 0, 22)
nameLbl.Position = UDim2.new(0, 60, 0, 8)
nameLbl.BackgroundTransparency = 1
nameLbl.Text = PLR.DisplayName .. " (@" .. PLR.Name .. ")"
nameLbl.TextColor3 = Color3.new(1, 1, 1)
nameLbl.Font = Enum.Font.GothamBold
nameLbl.TextSize = 12
nameLbl.TextXAlignment = Enum.TextXAlignment.Left
nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
nameLbl.Parent = prof

local idLbl = Instance.new("TextLabel")
idLbl.Size = UDim2.new(1, -66, 0, 18)
idLbl.Position = UDim2.new(0, 60, 0, 32)
idLbl.BackgroundTransparency = 1
idLbl.Text = "UserId: " .. PLR.UserId
idLbl.TextColor3 = Color3.fromRGB(150, 220, 160)
idLbl.Font = Enum.Font.Gotham
idLbl.TextSize = 11
idLbl.TextXAlignment = Enum.TextXAlignment.Left
idLbl.Parent = prof

-- ===== เวลาปัจจุบัน =====
local timeLbl = Instance.new("TextLabel")
timeLbl.Size = UDim2.new(1, -16, 0, 24)
timeLbl.Position = UDim2.new(0, 8, 0, 108)
timeLbl.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
timeLbl.BorderSizePixel = 0
timeLbl.TextColor3 = Color3.fromRGB(255, 235, 90)
timeLbl.Font = Enum.Font.GothamBold
timeLbl.TextSize = 13
timeLbl.Text = "เวลาปัจจุบัน: --:--:--"
timeLbl.Parent = frame
Instance.new("UICorner", timeLbl).CornerRadius = UDim.new(0, 6)
blackBorder(timeLbl, 2)

task.spawn(function()
    while task.wait(1) do
        local d = DateTime.now():ToLocalTime()
        timeLbl.Text = string.format("เวลาปัจจุบัน: %02d:%02d:%02d", d.Hour, d.Minute, d.Second)
    end
end)

-- ===== ปุ่ม =====
local y = 138
local function mkBtn(txt, col, fn)
    y = y + 38
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0.92, 0, 0, 32)
    b.Position = UDim2.new(0.04, 0, 0, y)
    b.BackgroundColor3 = col
    b.Text = txt
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 13
    b.BorderSizePixel = 0
    b.Parent = frame
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    blackBorder(b, 2)
    b.MouseButton1Click:Connect(fn)
    return b
end

mkBtn("ปักหมุดฐาน", Color3.fromRGB(185, 120, 15), function()
    refresh()
    if hrp then
        CFG.pin = hrp.CFrame
        flash("ปักแล้ว @ " .. math.floor(hrp.Position.X) .. "," .. math.floor(hrp.Position.Y) .. "," .. math.floor(hrp.Position.Z))
        print(" | pin base:", hrp.Position)
    else flash("ไม่เจอตัวละคร") end
end)

local warpTotal = CFG.liftTime + CFG.flyTime + CFG.dropTime
mkBtn("วาร์ปกลับฐาน ARC (" .. warpTotal .. "s)", Color3.fromRGB(20, 110, 185), function()
    if not CFG.pin then flash("ยังไม่ได้ปักหมุด!") return end
    flash("ดึงขึ้น → ข้าม → ลงฐาน")
    task.spawn(returnBase)
end)

local godBtn = mkBtn("โดนตีไม่สะท้าน: ON", Color3.fromRGB(30, 160, 70), function()
    CFG.god = not CFG.god
    CFG.antiStun = CFG.god
    godBtn.Text = CFG.god and "โดนตีไม่สะท้าน: ON" or "โดนตีไม่สะท้าน: OFF"
    godBtn.BackgroundColor3 = CFG.god and Color3.fromRGB(30, 160, 70) or Color3.fromRGB(55, 55, 65)
end)

local lockBtn = mkBtn("ล็อกตำแหน่งเมนู: ON", Color3.fromRGB(30, 160, 70), function()
    CFG.lockDrag = not CFG.lockDrag
    lockBtn.Text = CFG.lockDrag and "ล็อกตำแหน่งเมนู: ON" or "ล็อกตำแหน่งเมนู: OFF (ลากได้)"
    lockBtn.BackgroundColor3 = CFG.lockDrag and Color3.fromRGB(30, 160, 70) or Color3.fromRGB(185, 120, 15)
end)

-- ===== ช่องพิมพ์ความเร็ว 1-10000 =====
y = y + 38
local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(0.92, 0, 0, 18)
speedLabel.Position = UDim2.new(0.04, 0, 0, y)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "ความเร็ววิ่ง (พิมพ์ 1-10000):"
speedLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
speedLabel.Font = Enum.Font.Gotham
speedLabel.TextSize = 12
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Parent = frame

y = y + 20
local speedBox = Instance.new("TextBox")
speedBox.Size = UDim2.new(0.92, 0, 0, 32)
speedBox.Position = UDim2.new(0.04, 0, 0, y)
speedBox.BackgroundColor3 = Color3.fromRGB(34, 34, 44)
speedBox.Text = "16"
speedBox.PlaceholderText = "พิมพ์ 1-10000 แล้วกด Enter"
speedBox.TextColor3 = Color3.fromRGB(255, 235, 90)
speedBox.Font = Enum.Font.GothamBold
speedBox.TextSize = 15
speedBox.ClearTextOnFocus = false
speedBox.BorderSizePixel = 0
speedBox.Parent = frame
Instance.new("UICorner", speedBox).CornerRadius = UDim.new(0, 6)
blackBorder(speedBox, 2)

y = y + 36
local speedBtn = Instance.new("TextButton")
speedBtn.Size = UDim2.new(0.92, 0, 0, 32)
speedBtn.Position = UDim2.new(0.04, 0, 0, y)
speedBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
speedBtn.Text = "เปิดความเร็ว (OFF)"
speedBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
speedBtn.Font = Enum.Font.GothamBold
speedBtn.TextSize = 13
speedBtn.BorderSizePixel = 0
speedBtn.Parent = frame
Instance.new("UICorner", speedBtn).CornerRadius = UDim.new(0, 6)
blackBorder(speedBtn, 2)

local function applyTypedSpeed()
    local n = tonumber(speedBox.Text)
    if not n then flash("ใส่ตัวเลขเท่านั้น!") speedBox.Text = tostring(CFG.speed_val) return end
    n = math.floor(n)
    if n < CFG.speed_min or n > CFG.speed_max then
        flash("ต้องอยู่ในช่วง 1-10000!") speedBox.Text = tostring(CFG.speed_val) return
    end
    CFG.speed_val = n
    CFG.speed_on = true
    speedBtn.Text = "เปิดความเร็ว: " .. n
    speedBtn.BackgroundColor3 = Color3.fromRGB(30, 160, 70)
    speedBtn.TextColor3 = Color3.new(1, 1, 1)
    if hum and hum.Parent then hum.WalkSpeed = n end
    flash("ความเร็วตั้งเป็น " .. n)
    speedBox.Text = tostring(n)
end
speedBox.FocusLost:Connect(function(enter) if enter then applyTypedSpeed() end end)

speedBtn.MouseButton1Click:Connect(function()
    CFG.speed_on = not CFG.speed_on
    if CFG.speed_on then
        applyTypedSpeed()
    else
        speedBtn.Text = "เปิดความเร็ว (OFF)"
        speedBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
        speedBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
        if hum and hum.Parent then hum.WalkSpeed = 16 end
        flash("ปิดความเร็ว")
    end
end)

y = y + 40
local foot = Instance.new("TextLabel")
foot.Size = UDim2.new(0.92, 0, 0, 20)
foot.Position = UDim2.new(0.04, 0, 0, y)
foot.BackgroundTransparency = 1
foot.Text = "สร้างโดย BankZa Mdz"
foot.TextColor3 = Color3.fromRGB(130, 130, 150)
foot.Font = Enum.Font.Gotham
foot.TextSize = 11
foot.Parent = frame
frame.Size = UDim2.new(0, 250, 0, y + 30)

-- ===== ลากได้เฉพาะตอนปลดล็อก กันเลื่อนมั่วตอนวิ่ง =====
local function makeDraggable(handle, target)
    local dragging, dragStart, startPos = false, nil, nil
    handle.InputBegan:Connect(function(i)
        if i.UserInputType ~= Enum.UserInputType.Touch and i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        if CFG.lockDrag and target == frame then flash("เมนูล็อกอยู่! กดปลดล็อกก่อน") return end
        dragging = true
        dragStart = i.Position
        startPos = target.Position
    end)
    UIS.InputChanged:Connect(function(i)
        if not dragging then return end
        if i.UserInputType ~= Enum.UserInputType.Touch and i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        local d = i.Position - dragStart
        target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end
makeDraggable(top, frame)
makeDraggable(openBtn, openBtn)

print("======================================")
print(" loaded | " .. MAKER)
print(" เมนูชิดขวา + ขอบดำ | ล็อกตำแหน่ง: ON")
print("======================================")

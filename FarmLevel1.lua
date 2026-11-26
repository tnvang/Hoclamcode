--[[
  FarmLevel.lua  -  tách riêng từ Hehe.lua (HiruMain)
  Chỉ gồm: 1 nút Auto Farm Level + 1 ô chọn số quái đánh cùng lúc.
  Luồng: nhận quest -> bay mượt tới đảo -> gom N con về dưới chân -> đánh nhanh.
]]

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local commF = RS:WaitForChild("Remotes"):WaitForChild("CommF_")
local Net = RS:WaitForChild("Modules"):WaitForChild("Net")
local TeleportService = game:GetService("TeleportService")

local placeId = game.PlaceId
local World1 = placeId == 2753915549 or placeId == 85211729168715
local World2 = placeId == 4442272183 or placeId == 79091703265657
local World3 = placeId == 7449423635 or placeId == 100117331123089
local SEA = World1 and 1 or World2 and 2 or World3 and 3 or 0

local setStatus = function() end -- được gán lại ở phần UI
local STATE_FILE = "FarmLevel_enabled.txt"

----------------------------------------------------------------
-- CẤU HÌNH
----------------------------------------------------------------
local cfg = {
    Enabled = false,
    MobCount = 5,        -- số quái đánh cùng lúc (1-6), chỉnh bằng nút +/- trên UI
    MaxMobs = 6,
    FlySpeed = 300,      -- tốc độ bay (studs/giây)
    HoverY = 12,         -- đứng cao hơn đám quái bao nhiêu
    BringRadius = 350,   -- gom quái trong bán kính này quanh điểm spawn
    AttackRange = 60,
    AttackMode = 2,      -- 1 = Nhanh, 2 = Siêu nhanh, 3 = Cực nhanh
    MinSpeed = 100,
    MaxSpeed = 500,
    SpeedStep = 50,
}

-- mức đánh: delay giữa các lượt + số lần gửi đòn mỗi lượt
local ATTACK_MODES = {
    { name = "Nhanh",      delay = 0.10, burst = 1 },
    { name = "Siêu nhanh", delay = 0.05, burst = 1 },
    { name = "Cực nhanh",  delay = 0.02, burst = 2 },
}

----------------------------------------------------------------
-- TIỆN ÍCH
----------------------------------------------------------------
local function getRoot()
    local c = player.Character
    return c and c:FindFirstChild("HumanoidRootPart"), c and c:FindFirstChildOfClass("Humanoid")
end

local function alive(m)
    local h = m and m:FindFirstChildOfClass("Humanoid")
    return h ~= nil and h.Health > 0
end

local function enemiesFolder()
    return workspace:FindFirstChild("Enemies")
end

local function ownsPart(p)
    if isnetworkowner then
        local ok, r = pcall(isnetworkowner, p)
        if ok then return r end
    end
    return true
end

----------------------------------------------------------------
-- DI CHUYỂN MƯỢT (bay theo vận tốc, không giật, tự dừng khi tới)
----------------------------------------------------------------
local flyTarget = nil
local hold = nil

local function setHold(on)
    local root = getRoot()
    if on and root then
        if not hold or hold.Parent ~= root then
            if hold then hold:Destroy() end
            hold = Instance.new("BodyVelocity")
            hold.Name = "FarmHold"
            hold.MaxForce = Vector3.new(1e9, 1e9, 1e9)
            hold.Velocity = Vector3.zero
            hold.Parent = root
        end
    elseif hold then
        hold:Destroy()
        hold = nil
    end
end

RunService.Heartbeat:Connect(function(dt)
    if not cfg.Enabled then
        setHold(false)
        return
    end
    local root, hum = getRoot()
    if not root or not hum or hum.Health <= 0 then return end
    setHold(true)

    -- noclip khi farm để không kẹt
    for _, p in ipairs(player.Character:GetDescendants()) do
        if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
    end

    if flyTarget then
        local delta = flyTarget.Position - root.Position
        local dist = delta.Magnitude
        local step = cfg.FlySpeed * dt
        if dist <= step or dist < 2 then
            root.CFrame = CFrame.new(flyTarget.Position) * (root.CFrame - root.CFrame.Position)
        else
            root.CFrame = root.CFrame + delta.Unit * step
        end
        root.AssemblyLinearVelocity = Vector3.zero
    end
end)

local function flyTo(pos)
    flyTarget = CFrame.new(pos)
end

local function distTo(pos)
    local root = getRoot()
    return root and (root.Position - pos).Magnitude or math.huge
end

----------------------------------------------------------------
-- QUEST THEO LEVEL
----------------------------------------------------------------
local okQ, Quests = pcall(function() return require(RS:WaitForChild("Quests", 15)) end)
if not okQ or type(Quests) ~= "table" then Quests = {} end

local okG, Guide = pcall(function() return require(RS:WaitForChild("GuideModule", 15)) end)
local npcList = (okG and type(Guide) == "table" and Guide.Data and Guide.Data.NPCList) or {}

local skipQuests = { BartiloQuest = true, CitizenQuest = true, ImpelQuest = true }

local function getLevel()
    local ok, v = pcall(function() return player.Data.Level.Value end)
    return ok and tonumber(v) or 1
end

local function posOf(i)
    if i:IsA("BasePart") then return i.Position end
    if i:IsA("Model") then return i:GetPivot().Position end
end

local function spawnPos(mobName)
    local o = workspace:FindFirstChild("_WorldOrigin")
    local sp = o and o:FindFirstChild("EnemySpawns")
    if sp then
        for _, s in ipairs(sp:GetChildren()) do
            if s.Name:find(mobName, 1, true) then
                local p = posOf(s)
                if p then return p end
            end
        end
    end
    local ef = enemiesFolder()
    if ef then
        for _, e in ipairs(ef:GetChildren()) do
            if e.Name == mobName and e:FindFirstChild("HumanoidRootPart") then
                return e.HumanoidRootPart.Position
            end
        end
    end
end

local function getQuest()
    local level = getLevel()
    local team = (player.Team and player.Team.Name) or "Pirates"
    local prefer = false
    if level < 10 then prefer = (team == "Marines") and "trainee" or "bandit" end

    local bestId, bestData, bestReq = nil, nil, -1
    for id, data in pairs(Quests) do
        local first = type(data) == "table" and data[1]
        if not skipQuests[id] and first and first.LevelReq and first.LevelReq <= level then
            local ok = true
            if prefer then
                ok = false
                for k in pairs(first.Task or {}) do
                    if tostring(k):lower():find(prefer, 1, true) then ok = true break end
                end
            end
            if ok and first.LevelReq > bestReq then
                bestReq, bestId, bestData = first.LevelReq, id, data
            end
        end
    end
    if not bestData then return nil end

    local sub = 1
    for i, e in ipairs(bestData) do
        if e.LevelReq and e.LevelReq <= level then sub = i end
    end
    local entry = bestData[sub] or bestData[#bestData]
    local mobName
    for k in pairs(entry.Task or {}) do mobName = k end

    local ref = spawnPos(mobName) or (getRoot() and getRoot().Position) or Vector3.zero
    local npc, best = nil, math.huge
    for inst, info in pairs(npcList) do
        if info and info.Levels and table.find(info.Levels, entry.LevelReq) and typeof(inst) == "Instance" then
            local p = posOf(inst)
            if p and (p - ref).Magnitude < best then
                best, npc = (p - ref).Magnitude, p
            end
        end
    end
    return { Id = bestId, Sub = sub, Mob = mobName, Npc = npc }
end

local function hasQuest()
    local pg = player:FindFirstChild("PlayerGui")
    if not pg then return false end
    local t = pg:FindFirstChild("TrackedQuestFrame")
    if t and t.Enabled and t:FindFirstChild("Frame") and t.Frame.Visible then return true end
    local m = pg:FindFirstChild("Main")
    local q = m and m:FindFirstChild("Quest")
    if q and q.Visible then
        local title = q:FindFirstChild("Container") and q.Container:FindFirstChild("QuestTitle")
        title = title and title:FindFirstChild("Title")
        if title and title.Text ~= "" and title.Text ~= "QUEST" then return true end
    end
    return false
end

----------------------------------------------------------------
-- GOM QUÁI DƯỚI CHÂN
----------------------------------------------------------------
local pack, packName, anchor = {}, nil, nil
local lastSim = 0

-- điểm spawn gần người chơi nhất của loại quái này
local function nearestSpawn(mobName)
    local root = getRoot()
    local o = workspace:FindFirstChild("_WorldOrigin")
    local sp = o and o:FindFirstChild("EnemySpawns")
    local best, bd = nil, math.huge
    if sp and root then
        for _, s in ipairs(sp:GetChildren()) do
            if s.Name:find(mobName, 1, true) then
                local p = posOf(s)
                if p then
                    local d = (p - root.Position).Magnitude
                    if d < bd then best, bd = p, d end
                end
            end
        end
    end
    return best or spawnPos(mobName)
end

-- con quái còn sống gần người chơi nhất
local function nearestMob(mobName)
    local ef, root = enemiesFolder(), getRoot()
    if not ef or not root then return nil end
    local best, bd = nil, math.huge
    for _, e in ipairs(ef:GetChildren()) do
        local r = e:FindFirstChild("HumanoidRootPart")
        if e.Name == mobName and r and alive(e) then
            local d = (r.Position - root.Position).Magnitude
            if d < bd then best, bd = e, d end
        end
    end
    return best
end

local function refreshPack(mobName)
    local ef = enemiesFolder()
    if not ef then return end

    if packName ~= mobName then pack, packName, anchor = {}, mobName, nil end

    -- bỏ quái đã chết / biến mất
    local keep = {}
    for _, e in ipairs(pack) do
        if e.Parent == ef and alive(e) then table.insert(keep, e) end
    end
    pack = keep

    -- nhóm mới: lấy điểm gom = vị trí con quái gần nhất đang có mặt
    if #pack == 0 then
        local m = nearestMob(mobName)
        if not m then
            anchor = nil
            return
        end
        anchor = m.HumanoidRootPart.Position
    end

    -- bù thêm quái cho đủ số lượng
    if #pack < cfg.MobCount then
        local inPack = {}
        for _, e in ipairs(pack) do inPack[e] = true end
        local cand = {}
        for _, e in ipairs(ef:GetChildren()) do
            local r = e:FindFirstChild("HumanoidRootPart")
            if e.Name == mobName and not inPack[e] and alive(e) and r then
                local d = (r.Position - anchor).Magnitude
                if d <= cfg.BringRadius then table.insert(cand, { e, d }) end
            end
        end
        table.sort(cand, function(a, b) return a[2] < b[2] end)
        for _, c in ipairs(cand) do
            if #pack >= cfg.MobCount then break end
            table.insert(pack, c[1])
        end
    end
    while #pack > cfg.MobCount do table.remove(pack) end
end

-- kéo quái tụ thành vòng nhỏ ngay dưới chân người chơi
task.spawn(function()
    while true do
        task.wait(0.03)
        if cfg.Enabled and anchor and #pack > 0 then
            pcall(function()
                local n = #pack
                for i, e in ipairs(pack) do
                    local r = e:FindFirstChild("HumanoidRootPart")
                    if r and alive(e) then
                        local a = (i / n) * math.pi * 2
                        r.CFrame = CFrame.new(anchor + Vector3.new(math.cos(a) * 3, 0, math.sin(a) * 3))
                        r.CanCollide = false
                        r.AssemblyLinearVelocity = Vector3.zero
                        r.AssemblyAngularVelocity = Vector3.zero
                    end
                end
            end)
        end
    end
end)

----------------------------------------------------------------
-- ĐÁNH NHANH (đánh tất cả quái trong tầm cùng lúc)
----------------------------------------------------------------
local function autoHaki()
    local c = player.Character
    if c and not c:FindFirstChild("HasBuso") then pcall(commF.InvokeServer, commF, "Buso") end
end

local function equipMelee()
    local c = player.Character
    local hum = c and c:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if c:FindFirstChildOfClass("Tool") then return end
    for _, t in ipairs(player.Backpack:GetChildren()) do
        if t:IsA("Tool") and t.ToolTip == "Melee" then hum:EquipTool(t) return end
    end
end

task.spawn(function()
    while true do
        local mode = ATTACK_MODES[cfg.AttackMode]
        task.wait(mode.delay)
        if cfg.Enabled then
            pcall(function()
                local root = getRoot()
                local ef = enemiesFolder()
                local tool = player.Character and player.Character:FindFirstChildOfClass("Tool")
                if not root or not ef or not tool then return end

                local targets = {}
                for _, e in ipairs(ef:GetChildren()) do
                    local r = e:FindFirstChild("HumanoidRootPart")
                    if r and alive(e) and (r.Position - root.Position).Magnitude <= cfg.AttackRange then
                        table.insert(targets, { e, r })
                    end
                end
                if #targets == 0 then return end

                local head = targets[1][1]:FindFirstChild("Head") or targets[1][2]
                for _ = 1, mode.burst do
                    Net["RE/RegisterAttack"]:FireServer(mode.delay)
                    Net["RE/RegisterHit"]:FireServer(head, targets)
                end
            end)
        end
    end
end)

----------------------------------------------------------------
-- CHUYỂN SEA TỰ ĐỘNG (Sea 1 -> 2 ở level 700, Sea 2 -> 3 ở level 1500)
----------------------------------------------------------------
local travelling = false

local function travelIfNeeded(level)
    if travelling then return true end
    local cmd, dest
    if World1 and level >= 700 then
        cmd = "TravelDressrosa"
        dest = (placeId == 2753915549) and 4442272183 or 79091703265657
    elseif World2 and level >= 1500 then
        cmd = "TravelZou"
        dest = (placeId == 4442272183) and 7449423635 or 100117331123089
    end
    if not cmd then return false end

    travelling = true
    setStatus("Đang qua Sea " .. (SEA + 1) .. "...")
    pcall(commF.InvokeServer, commF, cmd)
    task.wait(3)
    pcall(function() TeleportService:Teleport(dest, player) end)
    task.wait(15)
    travelling = false
    return true
end

----------------------------------------------------------------
-- VÒNG LẶP FARM CHÍNH
----------------------------------------------------------------
task.spawn(function()
    while true do
        task.wait(0.1)
        if cfg.Enabled then
            pcall(function()
                local root, hum = getRoot()
                if not root or not hum or hum.Health <= 0 then return end

                local level = getLevel()
                if travelIfNeeded(level) then return end

                local quest = getQuest()
                if not quest or not quest.Mob then
                    setStatus("Sea " .. SEA .. " | Lv " .. level .. " | chưa có quest")
                    return
                end

                -- 1) chưa có quest -> bay tới NPC nhận quest
                if not hasQuest() then
                    pack, anchor = {}, nil
                    if not quest.Npc then return end
                    setStatus("Sea " .. SEA .. " | Lv " .. level .. " | nhận quest")
                    flyTo(quest.Npc + Vector3.new(0, 4, 3))
                    if distTo(quest.Npc) <= 18 then
                        task.wait(0.4)
                        commF:InvokeServer("StartQuest", quest.Id, quest.Sub)
                        task.wait(0.8)
                    end
                    return
                end

                -- 2) có quest -> chuẩn bị đánh
                autoHaki()
                equipMelee()
                if os.clock() - lastSim > 1 then
                    lastSim = os.clock()
                    pcall(function()
                        if sethiddenproperty then sethiddenproperty(player, "SimulationRadius", math.huge) end
                    end)
                end

                refreshPack(quest.Mob)

                if anchor then
                    -- có quái: bay lên trên đám quái đã gom
                    setStatus(("Sea %d | Lv %d | %s (%d con)"):format(SEA, level, quest.Mob, #pack))
                    flyTo(anchor + Vector3.new(0, cfg.HoverY, 0))
                else
                    -- chưa thấy quái nào: bay tới điểm spawn gần nhất để quái load ra
                    local sp = nearestSpawn(quest.Mob)
                    setStatus("Sea " .. SEA .. " | Lv " .. level .. " | tìm " .. quest.Mob)
                    if sp then flyTo(sp + Vector3.new(0, cfg.HoverY + 10, 0)) end
                end
            end)
        end
    end
end)

----------------------------------------------------------------
-- NHẬP TẤT CẢ CODE (danh sách lấy từ Hehe.lua)
----------------------------------------------------------------
local CODES = {
    "LIGHTNINGABUSE", "1LOSTADMIN", "ADMINFIGHT", "GIFTING_HOURS", "NOMOREHACK",
    "BANEXPLOIT", "WildDares", "BossBuild", "GetPranked", "EARN_FRUITS",
    "ADMINHACKED", "SEATROLLING", "24NOADMIN", "ADMIN_TROLL", "NEWTROLL",
    "SECRET_ADMIN", "staffbattle", "NOEXPLOIT", "NOOB2ADMIN", "CODESLIDE",
    "fruitconcepts", "krazydares", "ADMINGIVEAWAY", "ADMIN_STRENGTH", "NOOB_ADMIN",
    "Bignews", "CHANDLER", "Fudd10", "fudd10_v2", "FUDD10_V3",
    "Sub2UncleKizaru", "kittgaming", "KITT_RESET", "KITT_EXP", "Sub2CaptainMaui",
    "Sub2Fer999", "Enyu_is_Pro", "Magicbus", "MAGICBUS_V2", "JCWK",
    "JCWK_V2", "Starcodeheo", "STARCODEHEO_V2", "Bluxxy", "BLUXXY_V2",
    "Sub2NoobMaster123", "SUB2NOOBMASTER", "Sub2Daigrock", "SUB2DAIGROCK", "Axiore",
    "AXIORE_V2", "TantaiGaming", "TANTAIGAMING_V2", "StrawHatMaine", "STRAWHATMAINE_V2",
    "Sub2OfficialNoobie", "SUB2OFFICIALNOOBIE_V2", "TheGreatAce", "THEGREATACE_V2", "GAMERROBOT_YT",
    "ZIOLES", "1MLIKES_RESET", "2BILLION", "3BVISITS", "1MVISITS",
    "EXP_5B", "RESET_5B", "GAMER_ROBOT_1M", "1BILLION", "15B_BESTBROTHERS",
    "100M", "100k", "500M", "TY_FOR_WATCHING", "SUB2GAMERROBOT_RESET1",
    "SUB2GAMERROBOT_EXP1", "SUB2GAMERROBOT_RESET", "SUB2GAMERROBOT_EXP", "JULYUPDATE_RESET", "DRAGONABUSE",
    "TRIPLEABUSE", "FIGHT4FRUIT", "UPD16", "UPD15", "UPD14",
    "UPDATE17", "UPDATE16", "UPDATE15", "UPDATE14", "UPDATE13",
    "UPDATE12", "UPDATE11", "UPDATE10", "UPDATE9", "UPDATE8",
    "UPDATE7", "UPDATE6", "UPDATE5", "UPDATE4", "UPDATE3",
    "UPDATE2", "UPDATE1", "UPD1", "UPD2", "UPD3",
    "CONTROL", "POINTSRESET", "THIRDSEA", "NOOB_REFUND", "ShutDownFix2",
    "REWARDS", "NOOB2PRO", "CODES", "24NOOB", "ALONEV2",
    "DEVSCOOKING", "SECRETCODE", "XMASEXP", "NEWYEAR24", "MERRYXMAS",
    "CINCODEMAYO_BOOST", "XMASRESET", "WINTERCODE_2024", "FALL_WIND", "VALENTINES_2023",
    "HALLOWEEN_2023", "THANKSGIVING", "NEWYEAR2023", "NEWYEAR2022", "CHRISTMAS2022",
    "CHRISTMAS2021", "HALLOWEEN2022", "HALLOWEEN2021", "VALENTINES2022", "VALENTINES2021",
}

local redeeming = false
local function redeemAll(onProgress)
    if redeeming then return end
    local redeem = RS:WaitForChild("Remotes"):FindFirstChild("Redeem")
    if not redeem then
        onProgress("Không thấy Redeem")
        return
    end
    redeeming = true
    task.spawn(function()
        for i, code in ipairs(CODES) do
            pcall(function()
                if redeem:IsA("RemoteFunction") then
                    redeem:InvokeServer(code)
                else
                    redeem:FireServer(code)
                end
            end)
            onProgress(("Nhập code %d/%d"):format(i, #CODES))
            task.wait(0.05)
        end
        onProgress("Đã nhập xong code")
        redeeming = false
    end)
end

----------------------------------------------------------------
-- UI
----------------------------------------------------------------
local host = gethui and gethui() or player:WaitForChild("PlayerGui")
local old = host:FindFirstChild("FarmLevelUI")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "FarmLevelUI"
gui.ResetOnSpawn = false
gui.Parent = host

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(220, 226)
frame.Position = UDim2.new(0, 20, 0.5, -113)
frame.BackgroundColor3 = Color3.fromRGB(24, 12, 52)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

local function button(text, x, y, w, h, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.fromOffset(w, h)
    b.Position = UDim2.fromOffset(x, y)
    b.BackgroundColor3 = color or Color3.fromRGB(150, 96, 255)
    b.Text = text
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 13
    b.Parent = frame
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 9)
    return b
end

local function label(x, y, w, h)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.fromOffset(w, h)
    l.Position = UDim2.fromOffset(x, y)
    l.BackgroundTransparency = 1
    l.TextColor3 = Color3.new(1, 1, 1)
    l.Font = Enum.Font.GothamBold
    l.TextSize = 13
    l.Parent = frame
    return l
end

local toggle = button("", 10, 10, 200, 38, Color3.fromRGB(104, 62, 224))
local mobMinus = button("-", 10, 56, 36, 28)
local mobLbl = label(51, 56, 118, 28)
local mobPlus = button("+", 174, 56, 36, 28)
local spdMinus = button("-", 10, 90, 36, 28)
local spdLbl = label(51, 90, 118, 28)
local spdPlus = button("+", 174, 90, 36, 28)
local modeBtn = button("", 10, 124, 200, 32, Color3.fromRGB(214, 120, 60))
local codeBtn = button("Nhập tất cả Code", 10, 162, 200, 32, Color3.fromRGB(60, 140, 200))
local status = label(10, 198, 200, 20)
status.TextSize = 11
status.TextColor3 = Color3.fromRGB(196, 182, 232)
status.Text = ""
setStatus = function(text) status.Text = text end

local function refreshUI()
    toggle.Text = "Auto Farm Level: " .. (cfg.Enabled and "BẬT" or "TẮT")
    toggle.BackgroundColor3 = cfg.Enabled and Color3.fromRGB(70, 190, 120) or Color3.fromRGB(104, 62, 224)
    mobLbl.Text = "Đánh " .. cfg.MobCount .. " con"
    spdLbl.Text = "Tốc độ bay: " .. cfg.FlySpeed
    modeBtn.Text = "Mức đánh: " .. ATTACK_MODES[cfg.AttackMode].name
end

toggle.MouseButton1Click:Connect(function()
    cfg.Enabled = not cfg.Enabled
    if not cfg.Enabled then
        flyTarget, pack, anchor = nil, {}, nil
        setStatus("")
    end
    if writefile then pcall(writefile, STATE_FILE, cfg.Enabled and "1" or "0") end
    refreshUI()
end)
mobMinus.MouseButton1Click:Connect(function()
    cfg.MobCount = math.max(1, cfg.MobCount - 1)
    refreshUI()
end)
mobPlus.MouseButton1Click:Connect(function()
    cfg.MobCount = math.min(cfg.MaxMobs, cfg.MobCount + 1)
    refreshUI()
end)
spdMinus.MouseButton1Click:Connect(function()
    cfg.FlySpeed = math.max(cfg.MinSpeed, cfg.FlySpeed - cfg.SpeedStep)
    refreshUI()
end)
spdPlus.MouseButton1Click:Connect(function()
    cfg.FlySpeed = math.min(cfg.MaxSpeed, cfg.FlySpeed + cfg.SpeedStep)
    refreshUI()
end)
modeBtn.MouseButton1Click:Connect(function()
    cfg.AttackMode = cfg.AttackMode % #ATTACK_MODES + 1
    refreshUI()
end)
codeBtn.MouseButton1Click:Connect(function()
    redeemAll(function(text) status.Text = text end)
end)

refreshUI()

-- tự bật lại sau khi qua sea (script cần nằm trong thư mục autoexec để chạy lại ở sea mới)
pcall(function()
    if isfile and readfile and isfile(STATE_FILE) and readfile(STATE_FILE) == "1" then
        task.delay(4, function()
            cfg.Enabled = true
            refreshUI()
        end)
    end
end)

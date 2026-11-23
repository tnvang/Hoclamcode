if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local Env = (getgenv and getgenv()) or _G

if Env.KhiHayHoiCleanup then
    pcall(Env.KhiHayHoiCleanup)
    Env.KhiHayHoiCleanup = nil
end

local OldGui = PlayerGui:FindFirstChild("KhiHayHoiHub")
if OldGui then
    OldGui:Destroy()
end

local Settings = {
    Interval = 0.4,
    Distance = 3,
    LavaPadding = 12,
    MinY = -100,
    MaxY = 10000,
    MapBoundsName = "MapBounds",
    RequireMapBounds = false,
    BoundsHeightPadding = 500,
    ZoneRefreshInterval = 3,
    GroundCheckDistance = 14,
    FlySpeed = 60
}

local Enabled = false
local Destroyed = false
local CurrentTarget = nil
local LastTargetUserId = nil
local LavaParts = {}
local SafeParts = {}
local MapParts = {}
local LastZoneRefresh = 0

local Flying = false
local FlyButtonDir = 0
local FlyKeyDir = 0
local FlyVelocity = nil
local FlyConnection = nil
local OnFlyChanged = nil

local StatusText
local StatusDot
local Gui

local Connections = {}

local function Track(connection)
    table.insert(Connections, connection)
    return connection
end

local function getCharacter(player)
    if not player or not player.Parent then
        return nil
    end

    local character = player.Character

    if not character or not character.Parent then
        return nil
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")

    if not humanoid or humanoid.Health <= 0 then
        return nil
    end

    if not root or not root:IsDescendantOf(Workspace) then
        return nil
    end

    return character, humanoid, root
end

local function isCharacterPart(object)
    local model = object:FindFirstAncestorOfClass("Model")

    while model do
        if Players:GetPlayerFromCharacter(model) then
            return true
        end

        local parent = model.Parent
        model = parent and parent:FindFirstAncestorOfClass("Model") or nil
    end

    return false
end

local function getBox(object)
    if object:IsA("BasePart") then
        return object.CFrame, object.Size
    end

    if object:IsA("Model") then
        return object:GetBoundingBox()
    end

    return nil
end

local function isInside(object, position, padding)
    if not object or not object.Parent then
        return false
    end

    local cframe, size = getBox(object)

    if not cframe then
        return false
    end

    local localPosition = cframe:PointToObjectSpace(position)
    local half = size / 2 + padding

    return math.abs(localPosition.X) <= half.X
        and math.abs(localPosition.Y) <= half.Y
        and math.abs(localPosition.Z) <= half.Z
end

local function isLavaPart(part)
    if part:GetAttribute("IsLava") == true then
        return true
    end

    if part.Material == Enum.Material.CrackedLava then
        return true
    end

    if string.find(string.lower(part.Name), "lava", 1, true) then
        return true
    end

    if part.Parent and string.find(string.lower(part.Parent.Name), "lava", 1, true) then
        return true
    end

    return false
end

local function refreshZones(force)
    local now = os.clock()

    if not force and now - LastZoneRefresh < Settings.ZoneRefreshInterval then
        return
    end

    LastZoneRefresh = now
    table.clear(LavaParts)
    table.clear(SafeParts)
    table.clear(MapParts)

    for _, object in ipairs(Workspace:GetDescendants()) do
        if object.Name == Settings.MapBoundsName
            and (object:IsA("BasePart") or object:IsA("Model")) then
            table.insert(MapParts, object)
        elseif object:IsA("BasePart") and not isCharacterPart(object) then
            local name = string.lower(object.Name)

            if object:GetAttribute("IsLava") == true
                or object.Material == Enum.Material.CrackedLava
                or string.find(name, "lava", 1, true) then
                table.insert(LavaParts, object)
            end

            if object:GetAttribute("IsSafeZone") == true
                or string.find(name, "safezone", 1, true) then
                table.insert(SafeParts, object)
            end
        end
    end
end

local function isInsideMap(position)
    refreshZones()

    if #MapParts == 0 then
        return not Settings.RequireMapBounds
    end

    local padding = Vector3.new(0, Settings.BoundsHeightPadding, 0)

    for _, part in ipairs(MapParts) do
        if isInside(part, position, padding) then
            return true
        end
    end

    return false
end

local function isDangerous(position)
    refreshZones()

    local padding = Vector3.new(
        Settings.LavaPadding,
        Settings.LavaPadding,
        Settings.LavaPadding
    )

    for _, part in ipairs(LavaParts) do
        if isInside(part, position, padding) then
            return true
        end
    end

    return false
end

local function isSafeZone(position)
    refreshZones()

    for _, part in ipairs(SafeParts) do
        if isInside(part, position, Vector3.zero) then
            return true
        end
    end

    return false
end

local function getIgnoreList()
    local list = {}

    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
            table.insert(list, player.Character)
        end
    end

    return list
end

local function hasSafeGround(position)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = getIgnoreList()
    params.IgnoreWater = true
    params.RespectCanCollide = true

    local origin = position + Vector3.new(0, 2, 0)
    local result = Workspace:Raycast(
        origin,
        Vector3.new(0, -Settings.GroundCheckDistance, 0),
        params
    )

    if not result then
        return false, nil
    end

    if isLavaPart(result.Instance) then
        return false, result
    end

    return true, result
end

local function getTargetReason(target)
    if not target or target == Player then
        return false, "INVALID TARGET"
    end

    if not target.Parent then
        return false, "PLAYER LEFT"
    end

    if Player.Team and target.Team and Player.Team == target.Team then
        return false, "SAME TEAM"
    end

    local character, humanoid, root = getCharacter(target)

    if not character or not humanoid or not root then
        return false, "TARGET DEAD / NO CHARACTER"
    end

    local position = root.Position

    if position.Y < Settings.MinY or position.Y > Settings.MaxY then
        return false, "TARGET OUT OF HEIGHT"
    end

    if humanoid.FloorMaterial == Enum.Material.Air then
        return false, "TARGET IN AIR"
    end

    refreshZones()

    if #MapParts == 0 and Settings.RequireMapBounds then
        return false, "MAP BOUNDS NOT FOUND"
    end

    if not isInsideMap(position) then
        return false, "TARGET OUTSIDE MAP"
    end

    if isDangerous(position) then
        return false, "TARGET NEAR LAVA"
    end

    if isSafeZone(position) then
        return false, "TARGET IN SAFE ZONE"
    end

    if not hasSafeGround(position) then
        return false, "TARGET NO SAFE GROUND"
    end

    return true, "TARGET VALID"
end

local function isValidTarget(target)
    local valid = getTargetReason(target)
    return valid
end

local function getNextTarget()
    local list = Players:GetPlayers()
    local count = #list

    if count <= 1 then
        return nil, "NO OTHER PLAYERS"
    end

    local startIndex = 1

    if LastTargetUserId then
        for index, target in ipairs(list) do
            if target.UserId == LastTargetUserId then
                startIndex = (index % count) + 1
                break
            end
        end
    end

    local lastReason = "NO VALID TARGET"

    for offset = 0, count - 1 do
        local index = ((startIndex + offset - 1) % count) + 1
        local target = list[index]
        local valid, reason = getTargetReason(target)

        if valid then
            LastTargetUserId = target.UserId
            return target, "TARGET FOUND"
        end

        if target ~= Player then
            lastReason = reason
        end
    end

    return nil, lastReason
end

local function findDestination(targetRoot)
    local targetOk, targetHit = hasSafeGround(targetRoot.Position)

    if not targetOk or not targetHit then
        return nil, "TARGET NO SAFE GROUND"
    end

    local rootHeight = targetRoot.Position.Y - targetHit.Position.Y
    local distance = Settings.Distance

    local offsets = {
        Vector3.new(0, 0, distance),
        Vector3.new(0, 0, -distance),
        Vector3.new(distance, 0, 0),
        Vector3.new(-distance, 0, 0)
    }

    local reason = "NO SAFE SPOT"

    for _, offset in ipairs(offsets) do
        local position = (targetRoot.CFrame * CFrame.new(offset)).Position

        if not isInsideMap(position) then
            reason = "DESTINATION OUTSIDE MAP"
        elseif isDangerous(position) then
            reason = "DESTINATION NEAR LAVA"
        elseif isSafeZone(position) then
            reason = "DESTINATION IN SAFE ZONE"
        else
            local ok, hit = hasSafeGround(position)

            if ok and hit then
                local height = hit.Position.Y + rootHeight + 0.5
                local finalPosition = Vector3.new(position.X, height, position.Z)
                local lookPosition = Vector3.new(
                    targetRoot.Position.X,
                    height,
                    targetRoot.Position.Z
                )

                return CFrame.lookAt(finalPosition, lookPosition), "OK"
            end

            reason = "DESTINATION NO GROUND"
        end
    end

    return nil, reason
end

local function teleportToTarget(target)
    local valid, reason = getTargetReason(target)

    if not valid then
        return false, reason
    end

    local myCharacter, _, myRoot = getCharacter(Player)
    local targetCharacter, _, targetRoot = getCharacter(target)

    if not myCharacter or not myRoot then
        return false, "YOUR CHARACTER NOT READY"
    end

    if not targetCharacter or not targetRoot then
        return false, "TARGET CHARACTER NOT READY"
    end

    local destination, failReason = findDestination(targetRoot)

    if not destination then
        return false, failReason
    end

    myCharacter:PivotTo(destination)
    myRoot.AssemblyLinearVelocity = Vector3.zero
    myRoot.AssemblyAngularVelocity = Vector3.zero

    return true, "TELEPORT REQUESTED"
end

local function teleportNext()
    local target, reason = getNextTarget()

    if not target then
        return false, reason
    end

    local success, failReason = teleportToTarget(target)

    if success then
        return true, "TELEPORT: " .. target.Name
    end

    return false, failReason
end
local function stopFly()
    Flying = false
    FlyButtonDir = 0
    FlyKeyDir = 0

    if FlyConnection then
        FlyConnection:Disconnect()
        FlyConnection = nil
    end

    if FlyVelocity then
        FlyVelocity:Destroy()
        FlyVelocity = nil
    end

    local _, humanoid = getCharacter(Player)

    if humanoid then
        humanoid.PlatformStand = false
    end

    if OnFlyChanged then
        OnFlyChanged(false)
    end
end

local function startFly()
    local _, humanoid, root = getCharacter(Player)

    if not humanoid or not root then
        return false
    end

    if FlyConnection then
        FlyConnection:Disconnect()
        FlyConnection = nil
    end

    if FlyVelocity then
        FlyVelocity:Destroy()
        FlyVelocity = nil
    end

    Flying = true
    FlyButtonDir = 0
    FlyKeyDir = 0

    FlyVelocity = Instance.new("BodyVelocity")
    FlyVelocity.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    FlyVelocity.Velocity = Vector3.zero
    FlyVelocity.Parent = root

    humanoid.PlatformStand = true

    FlyConnection = RunService.RenderStepped:Connect(function()
        local _, currentHumanoid, currentRoot = getCharacter(Player)

        if not currentHumanoid
            or not currentRoot
            or not FlyVelocity
            or FlyVelocity.Parent ~= currentRoot then
            stopFly()
            return
        end

        local vertical = FlyButtonDir ~= 0 and FlyButtonDir or FlyKeyDir
        local horizontal = currentHumanoid.MoveDirection * Settings.FlySpeed
        local lift = Vector3.new(0, vertical * Settings.FlySpeed * 0.75, 0)

        FlyVelocity.Velocity = horizontal + lift
    end)

    if OnFlyChanged then
        OnFlyChanged(true)
    end

    return true
end

local function setFly(value)
    if value then
        startFly()
    else
        stopFly()
    end

    return Flying
end

local function stopTeleport()
    Enabled = false
    CurrentTarget = nil
end

local function startTeleport()
    if Enabled then
        return
    end

    Enabled = true
    CurrentTarget = nil
    refreshZones(true)
end

local function setTeleport(value)
    if value then
        startTeleport()
    else
        stopTeleport()
    end

    return Enabled
end

local function setStatus(message, active)
    if StatusText and StatusText.Parent then
        StatusText.Text = message
        StatusText.TextColor3 = active
            and Color3.fromRGB(70, 214, 140)
            or Color3.fromRGB(235, 120, 110)
    end

    if StatusDot and StatusDot.Parent then
        StatusDot.BackgroundColor3 = active
            and Color3.fromRGB(70, 214, 140)
            or Color3.fromRGB(235, 90, 100)
    end
end

local DrawingSupported = false

if Drawing and Drawing.new then
    local ok, object = pcall(Drawing.new, "Line")

    if ok and object then
        DrawingSupported = true
        pcall(function()
            object:Remove()
        end)
    end
end

local ESPEnabled = false
local ESPObjects = {}

local ESPOptions = {
    Box = true,
    Skeleton = false,
    Tracer = false,
    Name = true,
    Health = true,
    Distance = true
}

local R15Bones = {
    {"Head", "UpperTorso"},
    {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"},
    {"LeftUpperArm", "LeftLowerArm"},
    {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"},
    {"RightUpperArm", "RightLowerArm"},
    {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"},
    {"LeftUpperLeg", "LeftLowerLeg"},
    {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"},
    {"RightUpperLeg", "RightLowerLeg"},
    {"RightLowerLeg", "RightFoot"}
}

local R6Bones = {
    {"Head", "Torso"},
    {"Torso", "Left Arm"},
    {"Torso", "Right Arm"},
    {"Torso", "Left Leg"},
    {"Torso", "Right Leg"}
}

local function newDrawing(class, properties)
    local object = Drawing.new(class)

    for key, value in pairs(properties) do
        pcall(function()
            object[key] = value
        end)
    end

    return object
end

local function createESP()
    local objects = {
        Box = newDrawing("Square", {
            Thickness = 1.5,
            Filled = false,
            Color = Color3.fromRGB(255, 198, 76),
            Visible = false
        }),
        Tracer = newDrawing("Line", {
            Thickness = 1,
            Color = Color3.fromRGB(255, 255, 255),
            Visible = false
        }),
        Name = newDrawing("Text", {
            Size = 12,
            Center = true,
            Outline = true,
            Color = Color3.fromRGB(255, 255, 255),
            Font = 2,
            Visible = false
        }),
        HealthBack = newDrawing("Line", {
            Thickness = 4,
            Color = Color3.fromRGB(0, 0, 0),
            Visible = false
        }),
        HealthBar = newDrawing("Line", {
            Thickness = 2,
            Color = Color3.fromRGB(70, 214, 140),
            Visible = false
        }),
        Bones = {}
    }

    for index = 1, 14 do
        objects.Bones[index] = newDrawing("Line", {
            Thickness = 1,
            Color = Color3.fromRGB(70, 214, 140),
            Visible = false
        })
    end

    return objects
end

local function hideESP(objects)
    objects.Box.Visible = false
    objects.Tracer.Visible = false
    objects.Name.Visible = false
    objects.HealthBack.Visible = false
    objects.HealthBar.Visible = false

    for _, line in ipairs(objects.Bones) do
        line.Visible = false
    end
end

local function removeESPObjects(objects)
    local function remove(object)
        pcall(function()
            object:Remove()
        end)
    end

    remove(objects.Box)
    remove(objects.Tracer)
    remove(objects.Name)
    remove(objects.HealthBack)
    remove(objects.HealthBar)

    for _, line in ipairs(objects.Bones) do
        remove(line)
    end
end

local function removeESP(player)
    local objects = ESPObjects[player]

    if objects then
        removeESPObjects(objects)
        ESPObjects[player] = nil
    end
end

local function clearESP()
    for player in pairs(ESPObjects) do
        removeESP(player)
    end
end

local function updatePlayerESP(player, camera, origin, myRoot)
    local objects = ESPObjects[player]
    local character, humanoid, root = getCharacter(player)
    local head = character and character:FindFirstChild("Head")

    if not character or not head then
        if objects then
            hideESP(objects)
        end

        return
    end

    local rootPos, onScreen = camera:WorldToViewportPoint(root.Position)

    if not onScreen then
        if objects then
            hideESP(objects)
        end

        return
    end

    if not objects then
        objects = createESP()
        ESPObjects[player] = objects
    end

    local top = camera:WorldToViewportPoint(head.Position + Vector3.new(0, 1, 0))
    local bottom = camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3.2, 0))

    local height = math.max(math.abs(bottom.Y - top.Y), 4)
    local width = height * 0.55
    local left = rootPos.X - width / 2
    local topY = math.min(top.Y, bottom.Y)
    local bottomY = topY + height

    objects.Box.Size = Vector2.new(width, height)
    objects.Box.Position = Vector2.new(left, topY)
    objects.Box.Visible = ESPOptions.Box

    objects.Tracer.From = origin
    objects.Tracer.To = Vector2.new(rootPos.X, bottomY)
    objects.Tracer.Visible = ESPOptions.Tracer

    local label = player.DisplayName ~= "" and player.DisplayName or player.Name

    if ESPOptions.Distance and myRoot then
        local distance = math.floor((root.Position - myRoot.Position).Magnitude)
        label = label .. " [" .. distance .. "m]"
    end

    objects.Name.Text = label
    objects.Name.Position = Vector2.new(rootPos.X, topY - 15)
    objects.Name.Visible = ESPOptions.Name or ESPOptions.Distance

    local ratio = 1

    if humanoid.MaxHealth > 0 then
        ratio = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
    end

    local barX = left - 5

    objects.HealthBack.From = Vector2.new(barX, bottomY + 1)
    objects.HealthBack.To = Vector2.new(barX, topY - 1)
    objects.HealthBack.Visible = ESPOptions.Health

    objects.HealthBar.From = Vector2.new(barX, bottomY)
    objects.HealthBar.To = Vector2.new(barX, bottomY - height * ratio)
    objects.HealthBar.Color = Color3.fromHSV(ratio * 0.33, 1, 1)
    objects.HealthBar.Visible = ESPOptions.Health

    local bones = character:FindFirstChild("UpperTorso") and R15Bones or R6Bones

    for index, line in ipairs(objects.Bones) do
        local pair = bones[index]
        local shown = false

        if ESPOptions.Skeleton and pair then
            local partA = character:FindFirstChild(pair[1])
            local partB = character:FindFirstChild(pair[2])

            if partA and partB then
                local pointA, visibleA = camera:WorldToViewportPoint(partA.Position)
                local pointB, visibleB = camera:WorldToViewportPoint(partB.Position)

                if visibleA and visibleB then
                    line.From = Vector2.new(pointA.X, pointA.Y)
                    line.To = Vector2.new(pointB.X, pointB.Y)
                    shown = true
                end
            end
        end

        line.Visible = shown
    end
end

local function setESP(value)
    if value and not DrawingSupported then
        return false
    end

    ESPEnabled = value

    if not value then
        clearESP()
    end

    return ESPEnabled
end

Track(RunService.RenderStepped:Connect(function()
    if Destroyed or not ESPEnabled then
        return
    end

    local camera = Workspace.CurrentCamera

    if not camera then
        return
    end

    local viewport = camera.ViewportSize
    local origin = Vector2.new(viewport.X / 2, viewport.Y)
    local _, _, myRoot = getCharacter(Player)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Player then
            local ok = pcall(updatePlayerESP, player, camera, origin, myRoot)

            if not ok then
                removeESP(player)
            end
        end
    end
end))

Track(Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
end))

Track(Player.CharacterAdded:Connect(function()
    if Flying then
        stopFly()
    end
end))

Track(UserInputService.InputBegan:Connect(function(input, processed)
    if processed or not Flying then
        return
    end

    if input.KeyCode == Enum.KeyCode.E then
        FlyKeyDir = 1
    elseif input.KeyCode == Enum.KeyCode.Q then
        FlyKeyDir = -1
    end
end))

Track(UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.E and FlyKeyDir == 1 then
        FlyKeyDir = 0
    elseif input.KeyCode == Enum.KeyCode.Q and FlyKeyDir == -1 then
        FlyKeyDir = 0
    end
end))
local C = {
    Glass = Color3.fromRGB(16, 18, 28),
    Panel = Color3.fromRGB(38, 42, 60),
    PanelOn = Color3.fromRGB(26, 66, 52),
    White = Color3.fromRGB(255, 255, 255),
    Text = Color3.fromRGB(238, 240, 250),
    Muted = Color3.fromRGB(140, 146, 166),
    Accent = Color3.fromRGB(255, 198, 76),
    Green = Color3.fromRGB(70, 214, 140),
    Red = Color3.fromRGB(235, 90, 100)
}

local WIDTH = 240
local HEIGHT = 196
local HEADER = 30
local Minimized = false
local OrderCounter = 0

local function nextOrder()
    OrderCounter = OrderCounter + 1
    return OrderCounter
end

local function New(class, properties, parent)
    local object = Instance.new(class)

    for key, value in pairs(properties) do
        object[key] = value
    end

    object.Parent = parent
    return object
end

local function Corner(parent, radius)
    return New("UICorner", {CornerRadius = UDim.new(0, radius)}, parent)
end

local function Stroke(parent, color, transparency)
    return New("UIStroke", {
        Color = color,
        Thickness = 1,
        Transparency = transparency,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    }, parent)
end

local function tween(object, properties)
    TweenService:Create(object, TweenInfo.new(0.12), properties):Play()
end

Gui = Instance.new("ScreenGui")
Gui.Name = "KhiHayHoiHub"
Gui.ResetOnSpawn = false
Gui.DisplayOrder = 999
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local parented = false

if gethui then
    parented = pcall(function()
        Gui.Parent = gethui()
    end)
end

if not parented or not Gui.Parent then
    parented = pcall(function()
        Gui.Parent = game:GetService("CoreGui")
    end)
end

if not parented or not Gui.Parent then
    Gui.Parent = PlayerGui
end

local Main = New("Frame", {
    Name = "Main",
    Size = UDim2.fromOffset(WIDTH, HEIGHT),
    Position = UDim2.new(0.5, -WIDTH / 2, 0.5, -HEIGHT / 2),
    BackgroundColor3 = C.Glass,
    BackgroundTransparency = 0.2,
    BorderSizePixel = 0,
    ClipsDescendants = true
}, Gui)

Corner(Main, 12)
Stroke(Main, C.White, 0.8)

New("UIGradient", {
    Color = ColorSequence.new(
        Color3.fromRGB(48, 52, 76),
        Color3.fromRGB(14, 16, 24)
    ),
    Rotation = 90
}, Main)

local Header = New("Frame", {
    Name = "Header",
    Size = UDim2.new(1, 0, 0, HEADER),
    BackgroundTransparency = 1,
    BorderSizePixel = 0
}, Main)

New("Frame", {
    Size = UDim2.new(1, -16, 0, 1),
    Position = UDim2.new(0, 8, 1, 0),
    BackgroundColor3 = C.White,
    BackgroundTransparency = 0.88,
    BorderSizePixel = 0
}, Header)

New("TextLabel", {
    Size = UDim2.fromOffset(120, 14),
    Position = UDim2.fromOffset(10, 4),
    BackgroundTransparency = 1,
    Text = "KHỈ HAY HỎI",
    TextColor3 = C.Text,
    TextSize = 11,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left
}, Header)

New("TextLabel", {
    Size = UDim2.fromOffset(120, 10),
    Position = UDim2.fromOffset(10, 18),
    BackgroundTransparency = 1,
    Text = "GLASS  •  v2.0",
    TextColor3 = C.Accent,
    TextSize = 8,
    Font = Enum.Font.GothamMedium,
    TextXAlignment = Enum.TextXAlignment.Left
}, Header)

local function HeaderButton(text, x, color)
    local button = New("TextButton", {
        Size = UDim2.fromOffset(18, 18),
        Position = UDim2.new(1, x, 0, 6),
        BackgroundColor3 = color,
        BackgroundTransparency = 0.45,
        AutoButtonColor = false,
        Text = text,
        TextColor3 = C.Text,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        BorderSizePixel = 0
    }, Header)

    Corner(button, 9)

    button.MouseEnter:Connect(function()
        tween(button, {BackgroundTransparency = 0.15})
    end)

    button.MouseLeave:Connect(function()
        tween(button, {BackgroundTransparency = 0.45})
    end)

    return button
end

local MinimizeButton = HeaderButton("–", -66, Color3.fromRGB(90, 96, 120))
local HideButton = HeaderButton("×", -44, Color3.fromRGB(90, 96, 120))
local DeleteButton = HeaderButton("⌫", -22, Color3.fromRGB(170, 60, 70))

local Body = New("Frame", {
    Name = "Body",
    Size = UDim2.new(1, -16, 1, -(HEADER + 13)),
    Position = UDim2.fromOffset(8, HEADER + 6),
    BackgroundTransparency = 1
}, Main)

local TabBar = New("Frame", {
    Size = UDim2.new(1, 0, 0, 22),
    BackgroundTransparency = 1
}, Body)

New("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 4),
    SortOrder = Enum.SortOrder.LayoutOrder
}, TabBar)

local PageHolder = New("Frame", {
    Size = UDim2.new(1, 0, 1, -28),
    Position = UDim2.fromOffset(0, 28),
    BackgroundTransparency = 1
}, Body)

local function Button(parent, text, size)
    local button = New("TextButton", {
        Size = size,
        BackgroundColor3 = C.Panel,
        BackgroundTransparency = 0.45,
        AutoButtonColor = false,
        Text = text,
        TextColor3 = C.Text,
        TextSize = 10,
        Font = Enum.Font.GothamMedium,
        BorderSizePixel = 0,
        LayoutOrder = nextOrder()
    }, parent)

    button:SetAttribute("Base", 0.45)
    Corner(button, 7)
    Stroke(button, C.White, 0.88)

    button.MouseEnter:Connect(function()
        tween(button, {BackgroundTransparency = math.max(button:GetAttribute("Base") - 0.15, 0)})
    end)

    button.MouseLeave:Connect(function()
        tween(button, {BackgroundTransparency = button:GetAttribute("Base")})
    end)

    return button
end

local function Chip(parent, label, initial, callback, size)
    local button = Button(parent, label, size or UDim2.new(1, 0, 0, 26))
    button.TextXAlignment = Enum.TextXAlignment.Left

    New("UIPadding", {PaddingLeft = UDim.new(0, 20)}, button)

    local dot = New("Frame", {
        Size = UDim2.fromOffset(6, 6),
        Position = UDim2.new(0, -12, 0.5, -3),
        BackgroundColor3 = C.Muted,
        BorderSizePixel = 0
    }, button)

    Corner(dot, 3)

    local stroke = button:FindFirstChildOfClass("UIStroke")
    local state = initial and true or false
    local text = label

    local function render()
        button.Text = text
        button.TextColor3 = state and C.Green or C.Text
        button.BackgroundColor3 = state and C.PanelOn or C.Panel
        dot.BackgroundColor3 = state and C.Green or C.Muted
        stroke.Color = state and C.Green or C.White
        stroke.Transparency = state and 0.5 or 0.88
    end

    button.Activated:Connect(function()
        local requested = not state
        local actual = callback(requested)

        if actual ~= nil then
            state = actual
        else
            state = requested
        end

        render()
    end)

    render()

    return {
        Button = button,
        Set = function(value)
            state = value and true or false
            render()
        end,
        SetLabel = function(value)
            text = value
            render()
        end,
        Get = function()
            return state
        end
    }
end

local function Stepper(parent, label, value, minValue, maxValue, step, decimals, onChange)
    local frame = New("Frame", {
        Size = UDim2.new(1, 0, 0, 26),
        BackgroundColor3 = C.Panel,
        BackgroundTransparency = 0.45,
        BorderSizePixel = 0,
        LayoutOrder = nextOrder()
    }, parent)

    Corner(frame, 7)
    Stroke(frame, C.White, 0.88)

    New("TextLabel", {
        Size = UDim2.new(1, -90, 1, 0),
        Position = UDim2.fromOffset(10, 0),
        BackgroundTransparency = 1,
        Text = label,
        TextColor3 = C.Muted,
        TextSize = 10,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left
    }, frame)

    local valueLabel = New("TextLabel", {
        Size = UDim2.fromOffset(40, 18),
        Position = UDim2.new(1, -62, 0.5, -9),
        BackgroundTransparency = 1,
        TextColor3 = C.Accent,
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        Text = ""
    }, frame)

    local function format(number)
        return string.format("%." .. decimals .. "f", number)
    end

    local function change(delta)
        value = math.clamp(math.floor((value + delta) / step + 0.5) * step, minValue, maxValue)
        valueLabel.Text = format(value)
        onChange(value)
    end

    local function small(text, x, delta)
        local button = New("TextButton", {
            Size = UDim2.fromOffset(18, 18),
            Position = UDim2.new(1, x, 0.5, -9),
            BackgroundColor3 = C.Panel,
            BackgroundTransparency = 0.2,
            AutoButtonColor = false,
            Text = text,
            TextColor3 = C.Text,
            TextSize = 11,
            Font = Enum.Font.GothamBold,
            BorderSizePixel = 0
        }, frame)

        Corner(button, 5)

        button.Activated:Connect(function()
            change(delta)
        end)
    end

    small("−", -84, -step)
    small("+", -22, step)

    valueLabel.Text = format(value)
    onChange(value)
end

local function Page()
    local page = New("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Visible = false
    }, PageHolder)

    New("UIListLayout", {
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, page)

    return page
end

local TabNames = {"TELEPORT", "FLY", "ESP"}
local Pages = {}
local TabButtons = {}

local function SelectTab(index)
    for i, page in ipairs(Pages) do
        local active = i == index
        local button = TabButtons[i]
        local stroke = button:FindFirstChildOfClass("UIStroke")

        page.Visible = active
        button.TextColor3 = active and C.Accent or C.Muted
        stroke.Color = active and C.Accent or C.White
        stroke.Transparency = active and 0.45 or 0.88
        button:SetAttribute("Base", active and 0.25 or 0.55)
        button.BackgroundTransparency = active and 0.25 or 0.55
    end
end

for index, name in ipairs(TabNames) do
    Pages[index] = Page()

    local tab = Button(TabBar, name, UDim2.new(1 / 3, -3, 1, 0))
    tab.TextSize = 9
    TabButtons[index] = tab

    tab.Activated:Connect(function()
        SelectTab(index)
    end)
end

local TeleportPage = Pages[1]
local FlyPage = Pages[2]
local ESPPage = Pages[3]

local StatusFrame = New("Frame", {
    Size = UDim2.new(1, 0, 0, 26),
    BackgroundColor3 = C.Panel,
    BackgroundTransparency = 0.55,
    BorderSizePixel = 0,
    LayoutOrder = nextOrder()
}, TeleportPage)

Corner(StatusFrame, 7)

StatusDot = New("Frame", {
    Size = UDim2.fromOffset(6, 6),
    Position = UDim2.new(0, 9, 0.5, -3),
    BackgroundColor3 = C.Red,
    BorderSizePixel = 0
}, StatusFrame)

Corner(StatusDot, 3)

StatusText = New("TextLabel", {
    Size = UDim2.new(1, -28, 1, 0),
    Position = UDim2.fromOffset(22, 0),
    BackgroundTransparency = 1,
    Text = "TELEPORT OFF",
    TextColor3 = C.Muted,
    TextSize = 9,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd
}, StatusFrame)

local TeleportChip = Chip(TeleportPage, "AUTO TELEPORT", false, function(value)
    local result = setTeleport(value)

    if result then
        setStatus("SEARCHING FOR TARGET...", true)
    else
        StatusText.Text = "TELEPORT OFF"
        StatusText.TextColor3 = C.Muted
        StatusDot.BackgroundColor3 = C.Red
    end

    return result
end)

local NextButton = Button(TeleportPage, "TP NEXT", UDim2.new(1, 0, 0, 26))
NextButton.TextColor3 = C.Accent

NextButton.Activated:Connect(function()
    if Enabled then
        setStatus("TURN OFF AUTO FIRST", false)
        return
    end

    local success, message = teleportNext()
    setStatus(message or "TELEPORT FAILED", success)
end)

Stepper(TeleportPage, "DELAY (s)", Settings.Interval, 0.1, 2, 0.1, 1, function(value)
    Settings.Interval = value
end)

local FlyChip

FlyChip = Chip(FlyPage, "FLY", false, function(value)
    return setFly(value)
end)

OnFlyChanged = function(state)
    if FlyChip and FlyChip.Button.Parent then
        FlyChip.Set(state)
    end
end

local DirRow = New("Frame", {
    Size = UDim2.new(1, 0, 0, 26),
    BackgroundTransparency = 1,
    LayoutOrder = nextOrder()
}, FlyPage)

New("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 4),
    SortOrder = Enum.SortOrder.LayoutOrder
}, DirRow)

local function HoldButton(text, value)
    local button = Button(DirRow, text, UDim2.new(0.5, -2, 1, 0))

    button.InputBegan:Connect(function(input)
        if not Flying then
            return
        end

        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            FlyButtonDir = value
        end
    end)

    button.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            if FlyButtonDir == value then
                FlyButtonDir = 0
            end
        end
    end)
end

HoldButton("▲ UP  (E)", 1)
HoldButton("▼ DOWN  (Q)", -1)

Stepper(FlyPage, "SPEED", Settings.FlySpeed, 20, 200, 10, 0, function(value)
    Settings.FlySpeed = value
end)

local ESPMaster = Chip(ESPPage, "ESP", false, function(value)
    local result = setESP(value)

    if value and not result then
        return false
    end

    return result
end)

if not DrawingSupported then
    ESPMaster.SetLabel("ESP (NO DRAWING API)")
end

local ESPGrid = New("Frame", {
    Size = UDim2.new(1, 0, 0, 86),
    BackgroundTransparency = 1,
    LayoutOrder = nextOrder()
}, ESPPage)

New("UIGridLayout", {
    CellSize = UDim2.new(0.5, -2, 0, 26),
    CellPadding = UDim2.fromOffset(4, 4),
    SortOrder = Enum.SortOrder.LayoutOrder
}, ESPGrid)

local function OptionChip(label, key)
    Chip(ESPGrid, label, ESPOptions[key], function(value)
        ESPOptions[key] = value
        return value
    end)
end

OptionChip("BOX", "Box")
OptionChip("SKELETON", "Skeleton")
OptionChip("TRACER", "Tracer")
OptionChip("NAME", "Name")
OptionChip("HEALTH", "Health")
OptionChip("DISTANCE", "Distance")

SelectTab(1)

local OpenButton = New("TextButton", {
    Name = "ReopenButton",
    Size = UDim2.fromOffset(30, 30),
    Position = UDim2.new(0, 12, 0.5, -15),
    BackgroundColor3 = C.Glass,
    BackgroundTransparency = 0.2,
    AutoButtonColor = false,
    Text = "KH",
    TextColor3 = C.Accent,
    TextSize = 10,
    Font = Enum.Font.GothamBlack,
    Visible = false,
    BorderSizePixel = 0
}, Gui)

Corner(OpenButton, 15)
Stroke(OpenButton, C.Accent, 0.5)

MinimizeButton.Activated:Connect(function()
    Minimized = not Minimized
    Body.Visible = not Minimized
    Main.Size = Minimized
        and UDim2.fromOffset(WIDTH, HEADER)
        or UDim2.fromOffset(WIDTH, HEIGHT)
    MinimizeButton.Text = Minimized and "+" or "–"
end)

HideButton.Activated:Connect(function()
    Main.Visible = false
    OpenButton.Visible = true
end)

OpenButton.Activated:Connect(function()
    Main.Visible = true
    OpenButton.Visible = false
end)

local function Cleanup()
    if Destroyed then
        return
    end

    Destroyed = true
    Enabled = false
    CurrentTarget = nil
    ESPEnabled = false

    pcall(stopFly)
    pcall(clearESP)

    for _, connection in ipairs(Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    table.clear(Connections)

    if Gui then
        Gui:Destroy()
    end

    if Env.KhiHayHoiCleanup == Cleanup then
        Env.KhiHayHoiCleanup = nil
    end
end

Env.KhiHayHoiCleanup = Cleanup

DeleteButton.Activated:Connect(Cleanup)

Gui.Destroying:Connect(Cleanup)

local Dragging = false
local DragStart
local StartPosition
local DragTouch

Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        Dragging = true
        DragStart = input.Position
        StartPosition = Main.Position
        DragTouch = input.UserInputType == Enum.UserInputType.Touch and input or nil

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                Dragging = false
                DragTouch = nil
            end
        end)
    end
end)

Track(UserInputService.InputChanged:Connect(function(input)
    if not Dragging then
        return
    end

    if input.UserInputType == Enum.UserInputType.MouseMovement
        or (DragTouch and input == DragTouch) then
        local delta = input.Position - DragStart

        Main.Position = UDim2.new(
            StartPosition.X.Scale,
            StartPosition.X.Offset + delta.X,
            StartPosition.Y.Scale,
            StartPosition.Y.Offset + delta.Y
        )
    end
end))

local function teleportStep()
    if CurrentTarget and not isValidTarget(CurrentTarget) then
        CurrentTarget = nil
    end

    if not CurrentTarget then
        local target, reason = getNextTarget()

        if target then
            CurrentTarget = target
        else
            setStatus(reason or "NO VALID TARGET", false)
            task.wait(0.5)
            return
        end
    end

    local target = CurrentTarget
    local success, reason = teleportToTarget(target)

    if success then
        setStatus("TELEPORT: " .. target.Name, true)
        task.wait(Settings.Interval)
    elseif reason == "YOUR CHARACTER NOT READY" then
        setStatus("WAITING RESPAWN", false)
        task.wait(0.4)
    else
        setStatus((reason or "TELEPORT FAILED") .. " - SWITCHING", false)
        CurrentTarget = nil
        task.wait(0.1)
    end
end

task.spawn(function()
    while not Destroyed do
        if Enabled then
            local ok = pcall(teleportStep)

            if not ok then
                task.wait(0.5)
            end
        else
            task.wait(0.2)
        end
    end
end)

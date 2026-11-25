local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local T = {
  Accent = Color3.fromRGB(150, 96, 255),
  Accent2 = Color3.fromRGB(214, 176, 255),
  Accent3 = Color3.fromRGB(104, 62, 224),
  Deep = Color3.fromRGB(24, 12, 52),
  Text = Color3.fromRGB(250, 246, 255),
  Sub = Color3.fromRGB(196, 182, 232),
  Danger = Color3.fromRGB(255, 96, 140),
  White = Color3.new(1, 1, 1),
  Logo = "rbxassetid://115603165979013",
  Bg = "rbxassetid://96997720823594",
}

local kp = ColorSequenceKeypoint.new
local nk = NumberSequenceKeypoint.new

local Shin = {}
local Window = {}
Window.__index = Window
local Tab = {}
Tab.__index = Tab

local function tween(o, t, p)
  local tw = TweenService:Create(o, TweenInfo.new(t, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), p)
  tw:Play()
  return tw
end

local function make(class, props, kids)
  local o = Instance.new(class)
  for k, v in pairs(props or {}) do
    o[k] = v
  end
  for _, c in ipairs(kids or {}) do
    c.Parent = o
  end
  return o
end

local function corner(o, r)
  return make("UICorner", {CornerRadius = UDim.new(0, r), Parent = o})
end

local function stroke(o, c, th, tr)
  return make("UIStroke", {
    Color = c,
    Thickness = th,
    Transparency = tr,
    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    Parent = o,
  })
end

local function grad(o, c, tr, rot)
  local g = Instance.new("UIGradient")
  if c then
    g.Color = c
  end
  if tr then
    g.Transparency = tr
  end
  g.Rotation = rot or 0
  g.Parent = o
  return g
end

local function loop(o, prop, from, to, time)
  o[prop] = from
  local tw = TweenService:Create(o, TweenInfo.new(time, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), {[prop] = to})
  tw:Play()
  return tw
end

local function gbutton(parent, text, c1, c2, size, pos)
  local f = make("Frame", {
    Size = size,
    Position = pos or UDim2.new(),
    BackgroundColor3 = T.White,
    BackgroundTransparency = 0.12,
    BorderSizePixel = 0,
    Parent = parent,
  })
  corner(f, 11)
  grad(f, ColorSequence.new(c1, c2), nil, 0)
  local st = stroke(f, T.White, 1, 0.5)
  grad(st, nil, NumberSequence.new(0.2, 0.8), 90)
  local shine = make("Frame", {
    Size = UDim2.fromScale(1, 0.5),
    BackgroundColor3 = T.White,
    BorderSizePixel = 0,
    Parent = f,
  })
  corner(shine, 11)
  grad(shine, nil, NumberSequence.new(0.78, 1), 90)
  local lbl = make("TextLabel", {
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Text = text,
    Font = Enum.Font.GothamBold,
    TextSize = 13,
    TextColor3 = T.White,
    Parent = f,
  })
  local hit = make("TextButton", {
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Text = "",
    Parent = f,
  })
  hit.MouseEnter:Connect(function()
    tween(f, 0.15, {BackgroundTransparency = 0})
  end)
  hit.MouseLeave:Connect(function()
    tween(f, 0.15, {BackgroundTransparency = 0.12})
  end)
  return f, hit, lbl
end

Shin.Theme = T
Shin.Tab = Tab
Shin.Util = {Tween = tween, Make = make, Corner = corner, Stroke = stroke, Grad = grad, Loop = loop, GButton = gbutton}

local function getParent()
  if gethui then
    local ok, r = pcall(gethui)
    if ok and r then
      return r
    end
  end
  local ok = pcall(function()
    local f = Instance.new("Folder")
    f.Parent = game:GetService("CoreGui")
    f:Destroy()
  end)
  if ok then
    return game:GetService("CoreGui")
  end
  return Players.LocalPlayer:WaitForChild("PlayerGui")
end

local function viewport()
  local cam = workspace.CurrentCamera
  return cam and cam.ViewportSize or Vector2.new(1280, 720)
end

local function clampPos(size, x, y)
  local vp = viewport()
  return math.clamp(x, 0, math.max(0, vp.X - size.X)), math.clamp(y, 0, math.max(0, vp.Y - size.Y))
end

local function setTopLeft(o, x, y)
  o.Position = UDim2.fromOffset(x + o.AnchorPoint.X * o.Size.X.Offset, y + o.AnchorPoint.Y * o.Size.Y.Offset)
end

local function makeDraggable(handle, target, conns, onClick)
  local dragging, moved, origin, start, active = false, false, nil, nil, nil
  handle.InputBegan:Connect(function(input)
    local t = input.UserInputType
    if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
      dragging = true
      moved = false
      active = input
      origin = input.Position
      start = target.AbsolutePosition
      input.Changed:Connect(function()
        if input.UserInputState == Enum.UserInputState.End then
          if dragging and not moved and onClick then
            onClick()
          end
          dragging = false
        end
      end)
    end
  end)
  table.insert(conns, UIS.InputChanged:Connect(function(input)
    if not dragging then
      return
    end
    local t = input.UserInputType
    if t == Enum.UserInputType.Touch and input ~= active then
      return
    end
    if t == Enum.UserInputType.MouseMovement or t == Enum.UserInputType.Touch then
      local d = input.Position - origin
      if not moved and d.Magnitude > 5 then
        moved = true
      end
      if moved then
        local sz = Vector2.new(target.Size.X.Offset, target.Size.Y.Offset)
        local x, y = clampPos(sz, start.X + d.X, start.Y + d.Y)
        setTopLeft(target, x, y)
      end
    end
  end))
end

function Shin.new(opts)
  opts = opts or {}
  local self = setmetatable({}, Window)
  self.Conns = {}
  self.Cleanups = {}
  self.Tabs = {}
  self.Minimized = false
  self.Collapsed = false
  self.Hidden = false
  self.LogoPlaced = false
  self.UseBlur = true
  self.Token = 0
  self.Key = opts.Key or Enum.KeyCode.RightControl

  local parent = getParent()
  local old = parent:FindFirstChild("ShinRoblox")
  if old then
    old:Destroy()
  end
  local oldBlur = Lighting:FindFirstChild("ShinBlur")
  if oldBlur then
    oldBlur:Destroy()
  end

  local gui = make("ScreenGui", {
    Name = "ShinRoblox",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 9999,
  })
  gui.Parent = parent
  self.Gui = gui

  local okBlur, blur = pcall(function()
    local b = Instance.new("BlurEffect")
    b.Name = "ShinBlur"
    b.Size = 0
    b.Parent = Lighting
    return b
  end)
  if okBlur then
    self.Blur = blur
  end

  local vp = viewport()
  local w = math.clamp(math.floor(vp.X * 0.62), 340, 540)
  local h = math.clamp(math.floor(vp.Y * 0.8), 250, 350)
  local sw = w >= 460 and 144 or 106
  self.Size = Vector2.new(w, h)

  local root = make("Frame", {
    Name = "Main",
    Size = UDim2.fromOffset(w, h),
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundTransparency = 1,
    Parent = gui,
  })
  self.Main = root
  self:Center()
  self.Scale = make("UIScale", {Scale = 1, Parent = root})

  local g1 = make("Frame", {
    Size = UDim2.new(1, 32, 1, 32),
    Position = UDim2.fromOffset(-16, -16),
    BackgroundColor3 = T.Accent,
    BackgroundTransparency = 0.95,
    BorderSizePixel = 0,
    ZIndex = 1,
    Parent = root,
  })
  corner(g1, 32)
  local g2 = make("Frame", {
    Size = UDim2.new(1, 16, 1, 16),
    Position = UDim2.fromOffset(-8, -8),
    BackgroundColor3 = T.Accent,
    BackgroundTransparency = 0.9,
    BorderSizePixel = 0,
    ZIndex = 1,
    Parent = root,
  })
  corner(g2, 26)

  local bezel = make("Frame", {
    Size = UDim2.new(1, 8, 1, 8),
    Position = UDim2.fromOffset(-4, -4),
    BackgroundColor3 = T.White,
    BackgroundTransparency = 0.94,
    BorderSizePixel = 0,
    ZIndex = 1,
    Parent = root,
  })
  corner(bezel, 22)
  local bezelStroke = stroke(bezel, T.White, 1, 0)
  grad(bezelStroke, ColorSequence.new(T.White, T.Accent2), NumberSequence.new({nk(0, 0.45), nk(0.5, 0.9), nk(1, 0.55)}), 40)

  local panel = make("Frame", {
    Name = "Panel",
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = T.Deep,
    BackgroundTransparency = 0.42,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    ZIndex = 2,
    Parent = root,
  })
  corner(panel, 18)
  local rim = stroke(panel, T.White, 1.8, 0)
  local rimGrad = grad(rim, ColorSequence.new({
    kp(0, T.Accent2),
    kp(0.35, T.Accent),
    kp(0.7, T.Accent3),
    kp(1, T.Accent2),
  }), NumberSequence.new({nk(0, 0.05), nk(0.5, 0.65), nk(1, 0.05)}), 0)
  loop(rimGrad, "Rotation", 0, 360, 7)

  local bg = make("ImageLabel", {
    Name = "Bg",
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Image = T.Bg,
    ScaleType = Enum.ScaleType.Crop,
    ImageTransparency = 0.78,
    ZIndex = 1,
    Parent = panel,
  })
  corner(bg, 18)
  self.Bg = bg

  local tint = make("Frame", {
    Name = "Tint",
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = T.White,
    BackgroundTransparency = 0.62,
    BorderSizePixel = 0,
    ZIndex = 2,
    Parent = panel,
  })
  corner(tint, 18)
  grad(tint, ColorSequence.new(Color3.fromRGB(160, 110, 255), Color3.fromRGB(44, 22, 98)), nil, 55)
  self.Tint = tint

  local sheen = make("Frame", {
    Size = UDim2.fromScale(1, 0.55),
    BackgroundColor3 = T.White,
    BorderSizePixel = 0,
    ZIndex = 3,
    Parent = panel,
  })
  corner(sheen, 18)
  grad(sheen, nil, NumberSequence.new(0.78, 1), 90)

  local floor = make("Frame", {
    Size = UDim2.fromScale(1, 0.35),
    Position = UDim2.fromScale(0, 0.65),
    BackgroundColor3 = T.Accent2,
    BorderSizePixel = 0,
    ZIndex = 3,
    Parent = panel,
  })
  corner(floor, 18)
  grad(floor, nil, NumberSequence.new(1, 0.86), 90)

  local streak1 = make("Frame", {
    Size = UDim2.new(0, 90, 1.7, 0),
    Position = UDim2.new(0.5, 0, -0.35, 0),
    Rotation = 18,
    BackgroundColor3 = T.White,
    BackgroundTransparency = 0,
    BorderSizePixel = 0,
    ZIndex = 3,
    Parent = panel,
  })
  grad(streak1, nil, NumberSequence.new({nk(0, 1), nk(0.5, 0.9), nk(1, 1)}), 0)
  local streak2 = make("Frame", {
    Size = UDim2.new(0, 28, 1.7, 0),
    Position = UDim2.new(0.68, 0, -0.35, 0),
    Rotation = 18,
    BackgroundColor3 = T.White,
    BackgroundTransparency = 0,
    BorderSizePixel = 0,
    ZIndex = 3,
    Parent = panel,
  })
  grad(streak2, nil, NumberSequence.new({nk(0, 1), nk(0.5, 0.94), nk(1, 1)}), 0)

  local inner = make("Frame", {
    Size = UDim2.new(1, -12, 1, -12),
    Position = UDim2.fromOffset(6, 6),
    BackgroundTransparency = 1,
    ZIndex = 3,
    Parent = panel,
  })
  corner(inner, 13)
  local innerStroke = stroke(inner, T.White, 2.4, 0.05)
  local innerGrad = grad(innerStroke, ColorSequence.new({
    kp(0, T.White),
    kp(0.25, T.Accent2),
    kp(0.5, T.Accent),
    kp(0.75, T.Accent2),
    kp(1, T.White),
  }), NumberSequence.new({
    nk(0, 0.1),
    nk(0.3, 0.5),
    nk(0.5, 0.78),
    nk(0.7, 0.5),
    nk(1, 0.1),
  }), 0)
  loop(innerGrad, "Rotation", 360, 0, 12)
  TweenService:Create(
    innerStroke,
    TweenInfo.new(2.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
    {Transparency = 0.3}
  ):Play()

  local inner2 = make("Frame", {
    Size = UDim2.new(1, -20, 1, -20),
    Position = UDim2.fromOffset(10, 10),
    BackgroundTransparency = 1,
    ZIndex = 3,
    Parent = panel,
  })
  corner(inner2, 10)
  local inner2Stroke = stroke(inner2, T.White, 1, 0.78)
  grad(inner2Stroke, ColorSequence.new(T.Accent2, T.White), NumberSequence.new({nk(0, 0.5), nk(0.5, 0.9), nk(1, 0.5)}), 135)

  local top = make("Frame", {
    Name = "Top",
    Size = UDim2.new(1, 0, 0, 50),
    BackgroundTransparency = 1,
    ZIndex = 4,
    Parent = panel,
  })
  local mark = make("ImageLabel", {
    Size = UDim2.fromOffset(32, 32),
    Position = UDim2.fromOffset(16, 9),
    BackgroundColor3 = Color3.fromRGB(40, 20, 90),
    Image = T.Logo,
    ScaleType = Enum.ScaleType.Crop,
    Parent = top,
  })
  corner(mark, 10)
  local markStroke = stroke(mark, T.White, 1.5, 0)
  grad(markStroke, ColorSequence.new(T.Accent2, T.Accent3), nil, 45)

  local titleBox = make("Frame", {
    Size = UDim2.fromOffset(math.max(140, w - 54 - 134), 38),
    Position = UDim2.fromOffset(56, 6),
    BackgroundTransparency = 1,
    Parent = top,
  })
  make("UIListLayout", {
    FillDirection = Enum.FillDirection.Vertical,
    Padding = UDim.new(0, 1),
    SortOrder = Enum.SortOrder.LayoutOrder,
    Parent = titleBox,
  })
  local row = make("Frame", {
    Size = UDim2.new(1, 0, 0, 24),
    BackgroundTransparency = 1,
    LayoutOrder = 1,
    Parent = titleBox,
  })
  make("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    VerticalAlignment = Enum.VerticalAlignment.Center,
    Padding = UDim.new(0, 6),
    SortOrder = Enum.SortOrder.LayoutOrder,
    Parent = row,
  })
  local t1 = make("TextLabel", {
    Size = UDim2.fromOffset(0, 24),
    AutomaticSize = Enum.AutomaticSize.X,
    BackgroundTransparency = 1,
    Text = "Shin",
    Font = Enum.Font.GothamBlack,
    TextSize = 20,
    TextColor3 = T.White,
    LayoutOrder = 1,
    Parent = row,
  })
  local t1g = grad(t1, ColorSequence.new({kp(0, T.White), kp(0.5, T.Accent2), kp(1, T.White)}), nil, 0)
  loop(t1g, "Offset", Vector2.new(-1, 0), Vector2.new(1, 0), 2.6)
  local t2 = make("TextLabel", {
    Size = UDim2.fromOffset(0, 24),
    AutomaticSize = Enum.AutomaticSize.X,
    BackgroundTransparency = 1,
    Text = "Roblox",
    Font = Enum.Font.GothamBold,
    TextSize = 20,
    TextColor3 = T.White,
    LayoutOrder = 2,
    Parent = row,
  })
  local t2g = grad(t2, ColorSequence.new({kp(0, T.Accent2), kp(0.5, T.Accent), kp(1, T.Accent2)}), nil, 0)
  loop(t2g, "Offset", Vector2.new(-1, 0), Vector2.new(1, 0), 3.2)
  local badge = make("Frame", {
    Size = UDim2.fromOffset(58, 16),
    BackgroundColor3 = T.White,
    BackgroundTransparency = 0.05,
    BorderSizePixel = 0,
    LayoutOrder = 3,
    Visible = w >= 430,
    Parent = row,
  })
  corner(badge, 8)
  grad(badge, ColorSequence.new(T.Accent, T.Accent3), nil, 0)
  stroke(badge, T.Accent2, 1, 0.45)
  make("TextLabel", {
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Text = "PREMIUM",
    Font = Enum.Font.GothamBlack,
    TextSize = 9,
    TextColor3 = T.White,
    Parent = badge,
  })
  make("TextLabel", {
    Size = UDim2.new(1, 0, 0, 12),
    BackgroundTransparency = 1,
    Text = "AURORA GLASS · V2.0",
    Font = Enum.Font.GothamMedium,
    TextSize = 9,
    TextColor3 = T.Sub,
    TextXAlignment = Enum.TextXAlignment.Left,
    LayoutOrder = 2,
    Parent = titleBox,
  })

  local function iconBtn(text, offset, hover)
    local b = make("TextButton", {
      Size = UDim2.fromOffset(32, 32),
      AnchorPoint = Vector2.new(1, 0.5),
      Position = UDim2.new(1, offset, 0.5, 0),
      BackgroundColor3 = T.White,
      BackgroundTransparency = 0.88,
      Text = text or "",
      Font = Enum.Font.GothamBold,
      TextSize = 18,
      TextColor3 = T.Text,
      AutoButtonColor = false,
      Parent = top,
    })
    corner(b, 16)
    local s = stroke(b, T.White, 1, 0.75)
    b.MouseEnter:Connect(function()
      tween(b, 0.18, {BackgroundColor3 = hover, BackgroundTransparency = 0.25})
      tween(s, 0.18, {Transparency = 0.3})
    end)
    b.MouseLeave:Connect(function()
      tween(b, 0.18, {BackgroundColor3 = T.White, BackgroundTransparency = 0.88})
      tween(s, 0.18, {Transparency = 0.75})
    end)
    return b
  end
  local closeBtn = iconBtn("×", -16, T.Danger)
  local minBtn = iconBtn("–", -54, T.Accent)
  local collapseBtn = iconBtn(nil, -92, T.Accent3)

  local chev = make("Frame", {
    Size = UDim2.fromOffset(14, 14),
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    BackgroundTransparency = 1,
    Rotation = 180,
    Parent = collapseBtn,
  })
  for _, d in ipairs({{4.3, 40}, {9.7, -40}}) do
    local bar = make("Frame", {
      Size = UDim2.fromOffset(8, 2),
      AnchorPoint = Vector2.new(0.5, 0.5),
      Position = UDim2.fromOffset(d[1], 7),
      Rotation = d[2],
      BackgroundColor3 = T.Text,
      BorderSizePixel = 0,
      Parent = chev,
    })
    corner(bar, 1)
  end
  self.Chevron = chev

  local divider = make("Frame", {
    Size = UDim2.new(1, -32, 0, 1),
    Position = UDim2.new(0, 16, 0, 50),
    BackgroundColor3 = T.White,
    BorderSizePixel = 0,
    ZIndex = 4,
    Parent = panel,
  })
  grad(divider, nil, NumberSequence.new({nk(0, 1), nk(0.5, 0.7), nk(1, 1)}), 0)

  local side = make("Frame", {
    Size = UDim2.fromOffset(sw, h - 74),
    Position = UDim2.fromOffset(16, 58),
    BackgroundColor3 = T.White,
    BackgroundTransparency = 0.92,
    BorderSizePixel = 0,
    ZIndex = 4,
    Parent = panel,
  })
  corner(side, 14)
  local sideStroke = stroke(side, T.White, 1, 0)
  grad(sideStroke, nil, NumberSequence.new(0.5, 0.94), 60)
  local sideSheen = make("Frame", {
    Size = UDim2.fromScale(1, 0.4),
    BackgroundColor3 = T.White,
    BorderSizePixel = 0,
    Parent = side,
  })
  corner(sideSheen, 14)
  grad(sideSheen, nil, NumberSequence.new(0.9, 1), 90)

  make("TextLabel", {
    Size = UDim2.new(1, -24, 0, 14),
    Position = UDim2.fromOffset(14, 10),
    BackgroundTransparency = 1,
    Text = "MENU",
    Font = Enum.Font.GothamBold,
    TextSize = 9,
    TextColor3 = T.Sub,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = side,
  })

  local tabList = make("ScrollingFrame", {
    Size = UDim2.new(1, 0, 1, -82),
    Position = UDim2.fromOffset(0, 26),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 0,
    CanvasSize = UDim2.new(),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollingDirection = Enum.ScrollingDirection.Y,
    Parent = side,
  })
  make("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = tabList})
  make("UIPadding", {
    PaddingLeft = UDim.new(0, 8),
    PaddingRight = UDim.new(0, 8),
    Parent = tabList,
  })
  self.TabList = tabList

  local chip = make("Frame", {
    Size = UDim2.new(1, -16, 0, 40),
    Position = UDim2.new(0, 8, 1, -48),
    BackgroundColor3 = T.White,
    BackgroundTransparency = 0.9,
    BorderSizePixel = 0,
    Parent = side,
  })
  corner(chip, 10)
  stroke(chip, T.White, 1, 0.82)
  local avatar = make("ImageLabel", {
    Size = UDim2.fromOffset(26, 26),
    Position = UDim2.fromOffset(7, 7),
    BackgroundColor3 = T.Accent3,
    BackgroundTransparency = 0.3,
    Image = "",
    ScaleType = Enum.ScaleType.Crop,
    Parent = chip,
  })
  corner(avatar, 13)
  local lp = Players.LocalPlayer
  make("TextLabel", {
    Size = UDim2.new(1, -44, 0, 16),
    Position = UDim2.fromOffset(38, 5),
    BackgroundTransparency = 1,
    Text = lp and lp.DisplayName or "Player",
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    TextColor3 = T.Text,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd,
    Parent = chip,
  })
  make("TextLabel", {
    Size = UDim2.new(1, -44, 0, 14),
    Position = UDim2.fromOffset(38, 21),
    BackgroundTransparency = 1,
    Text = self.Key.Name .. " · ẩn/hiện",
    Font = Enum.Font.Gotham,
    TextSize = 9,
    TextColor3 = T.Sub,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd,
    Parent = chip,
  })
  if lp then
    task.spawn(function()
      local ok, img = pcall(function()
        return Players:GetUserThumbnailAsync(lp.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
      end)
      if ok and avatar.Parent then
        avatar.Image = img
      end
    end)
  end

  self.Content = make("Frame", {
    Size = UDim2.fromOffset(w - sw - 48, h - 74),
    Position = UDim2.fromOffset(sw + 28, 58),
    BackgroundTransparency = 1,
    ZIndex = 4,
    Parent = panel,
  })

  local overlay = make("TextButton", {
    Name = "Confirm",
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = Color3.new(0, 0, 0),
    BackgroundTransparency = 1,
    Text = "",
    AutoButtonColor = false,
    Visible = false,
    ZIndex = 20,
    Parent = panel,
  })
  corner(overlay, 18)
  local dlg = make("Frame", {
    Size = UDim2.fromOffset(280, 148),
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    BackgroundColor3 = T.Deep,
    BackgroundTransparency = 0.1,
    BorderSizePixel = 0,
    Parent = overlay,
  })
  corner(dlg, 16)
  local dlgStroke = stroke(dlg, T.White, 1.5, 0)
  local dlgGrad = grad(dlgStroke, ColorSequence.new(T.Accent2, T.Accent3), NumberSequence.new(0.1, 0.6), 45)
  loop(dlgGrad, "Rotation", 0, 360, 6)
  local dsheen = make("Frame", {
    Size = UDim2.fromScale(1, 0.5),
    BackgroundColor3 = T.White,
    BorderSizePixel = 0,
    Parent = dlg,
  })
  corner(dsheen, 16)
  grad(dsheen, nil, NumberSequence.new(0.88, 1), 90)
  local dinner = make("Frame", {
    Size = UDim2.new(1, -10, 1, -10),
    Position = UDim2.fromOffset(5, 5),
    BackgroundTransparency = 1,
    Parent = dlg,
  })
  corner(dinner, 12)
  local dinnerStroke = stroke(dinner, T.White, 1, 0)
  grad(dinnerStroke, nil, NumberSequence.new({nk(0, 0.5), nk(0.5, 0.92), nk(1, 0.55)}), 35)
  self.CardScale = make("UIScale", {Scale = 0.85, Parent = dlg})
  make("TextLabel", {
    Size = UDim2.new(1, -32, 0, 24),
    Position = UDim2.fromOffset(16, 16),
    BackgroundTransparency = 1,
    Text = "Xoá giao diện?",
    Font = Enum.Font.GothamBlack,
    TextSize = 17,
    TextColor3 = T.Text,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = dlg,
  })
  make("TextLabel", {
    Size = UDim2.new(1, -32, 0, 40),
    Position = UDim2.fromOffset(16, 44),
    BackgroundTransparency = 1,
    Text = "Bạn có muốn xoá giao diện Shin Roblox không? Hành động này không thể hoàn tác.",
    Font = Enum.Font.Gotham,
    TextSize = 12,
    TextWrapped = true,
    TextColor3 = T.Sub,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    Parent = dlg,
  })
  local _, cancelBtn = gbutton(dlg, "Huỷ", Color3.fromRGB(128, 108, 184), Color3.fromRGB(76, 60, 120), UDim2.new(0.5, -24, 0, 34), UDim2.new(0, 16, 1, -50))
  local _, deleteBtn = gbutton(dlg, "Xoá", Color3.fromRGB(255, 116, 156), Color3.fromRGB(204, 54, 114), UDim2.new(0.5, -24, 0, 34), UDim2.new(0.5, 8, 1, -50))
  self.Overlay = overlay

  local logo = make("Frame", {
    Name = "Logo",
    Size = UDim2.fromOffset(46, 46),
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromOffset(60, 160),
    BackgroundTransparency = 1,
    Visible = false,
    ZIndex = 50,
    Parent = gui,
  })
  self.Logo = logo
  self.LogoScale = make("UIScale", {Scale = 1, Parent = logo})
  local halo2 = make("Frame", {
    Size = UDim2.new(1, 20, 1, 20),
    Position = UDim2.fromOffset(-10, -10),
    BackgroundColor3 = T.Accent,
    BackgroundTransparency = 0.92,
    BorderSizePixel = 0,
    Parent = logo,
  })
  corner(halo2, 33)
  local halo1 = make("Frame", {
    Size = UDim2.new(1, 9, 1, 9),
    Position = UDim2.fromOffset(-4, -4),
    BackgroundColor3 = T.Accent2,
    BackgroundTransparency = 0.84,
    BorderSizePixel = 0,
    Parent = logo,
  })
  corner(halo1, 27)
  local logoBtn = make("ImageButton", {
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = Color3.fromRGB(40, 20, 90),
    BackgroundTransparency = 0,
    AutoButtonColor = false,
    Image = T.Logo,
    ImageTransparency = 0,
    ScaleType = Enum.ScaleType.Crop,
    BorderSizePixel = 0,
    Parent = logo,
  })
  corner(logoBtn, 23)
  local ring = stroke(logoBtn, T.White, 2, 0)
  local ringGrad = grad(ring, ColorSequence.new({kp(0, T.Accent2), kp(0.5, T.Accent3), kp(1, T.Accent2)}), nil, 0)
  loop(ringGrad, "Rotation", 0, 360, 3)
  local logoInner = make("Frame", {
    Size = UDim2.new(1, -6, 1, -6),
    Position = UDim2.fromOffset(3, 3),
    BackgroundTransparency = 1,
    Parent = logoBtn,
  })
  corner(logoInner, 20)
  local logoInnerStroke = stroke(logoInner, T.White, 1, 0.5)
  grad(logoInnerStroke, nil, NumberSequence.new(0.2, 0.85), 45)

  local holder = make("Frame", {
    Size = UDim2.fromOffset(260, 300),
    AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.new(1, -16, 1, -16),
    BackgroundTransparency = 1,
    ZIndex = 60,
    Parent = gui,
  })
  make("UIListLayout", {
    Padding = UDim.new(0, 8),
    VerticalAlignment = Enum.VerticalAlignment.Bottom,
    HorizontalAlignment = Enum.HorizontalAlignment.Right,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Parent = holder,
  })
  self.Holder = holder

  makeDraggable(top, root, self.Conns)
  makeDraggable(logoBtn, logo, self.Conns, function()
    self:Restore()
  end)

  collapseBtn.MouseButton1Click:Connect(function()
    self:SetCollapsed(not self.Collapsed)
  end)
  minBtn.MouseButton1Click:Connect(function()
    self:Minimize()
  end)
  closeBtn.MouseButton1Click:Connect(function()
    self:Confirm(true)
  end)
  cancelBtn.MouseButton1Click:Connect(function()
    self:Confirm(false)
  end)
  deleteBtn.MouseButton1Click:Connect(function()
    tween(self.Scale, 0.2, {Scale = 0})
    if self.Blur then
      tween(self.Blur, 0.2, {Size = 0})
    end
    task.delay(0.22, function()
      self:Destroy()
    end)
  end)

  table.insert(self.Conns, UIS.InputBegan:Connect(function(input, gp)
    if gp then
      return
    end
    if input.KeyCode == self.Key then
      self:Toggle()
    end
  end))

  self:Refresh()
  self.Scale.Scale = 0.9
  tween(self.Scale, 0.3, {Scale = 1})

  return self
end

function Window:Center()
  local vp = viewport()
  self.Main.Position = UDim2.fromOffset(math.floor(vp.X / 2), math.floor(vp.Y / 2))
end

function Window:UpdateBlur()
  if not self.Blur then
    return
  end
  local on = self.Main.Visible and self.UseBlur
  tween(self.Blur, 0.3, {Size = on and 16 or 0})
end

function Window:SetBlur(v)
  self.UseBlur = v and true or false
  self:UpdateBlur()
end

function Window:Refresh()
  self.Main.Visible = not self.Hidden and not self.Minimized
  self.Logo.Visible = not self.Hidden and self.Minimized
  self:UpdateBlur()
end

function Window:SetCollapsed(v)
  v = v and true or false
  if self.Collapsed == v then
    return
  end
  self.Collapsed = v
  local full = self.Size.Y
  local cy = self.Main.Position.Y.Offset
  local newCenter
  if v then
    local topY = cy - full / 2
    newCenter = topY + 25
  else
    local topY = cy - 25
    topY = math.clamp(topY, 0, math.max(0, viewport().Y - full))
    newCenter = topY + full / 2
  end
  tween(self.Main, 0.3, {
    Size = UDim2.fromOffset(self.Size.X, v and 50 or full),
    Position = UDim2.fromOffset(self.Main.Position.X.Offset, newCenter),
  })
  tween(self.Chevron, 0.3, {Rotation = v and 0 or 180})
end

function Window:Toggle()
  self.Hidden = not self.Hidden
  if not self.Hidden and not self.Minimized then
    self:Center()
    self.Scale.Scale = 0.9
    self:Refresh()
    tween(self.Scale, 0.25, {Scale = 1})
  else
    self:Refresh()
  end
end

function Window:Minimize()
  if self.Minimized then
    return
  end
  self.Minimized = true
  self.Token += 1
  local token = self.Token
  if not self.LogoPlaced then
    self.LogoPlaced = true
    local p = self.Main.AbsolutePosition
    local x, y = clampPos(Vector2.new(46, 46), p.X + 14, p.Y + 14)
    setTopLeft(self.Logo, x, y)
  end
  tween(self.Scale, 0.2, {Scale = 0})
  task.delay(0.2, function()
    if token ~= self.Token or not self.Gui.Parent then
      return
    end
    self.LogoScale.Scale = 0
    self:Refresh()
    tween(self.LogoScale, 0.3, {Scale = 1})
  end)
end

function Window:Restore()
  if not self.Minimized then
    return
  end
  self.Minimized = false
  self.Token += 1
  self:Center()
  self.Scale.Scale = 0.85
  self:Refresh()
  tween(self.Scale, 0.3, {Scale = 1})
end

function Window:Confirm(show)
  if show then
    if self.Collapsed then
      self:SetCollapsed(false)
    end
    self.Overlay.Visible = true
    self.CardScale.Scale = 0.85
    tween(self.Overlay, 0.2, {BackgroundTransparency = 0.4})
    tween(self.CardScale, 0.25, {Scale = 1})
  else
    tween(self.Overlay, 0.15, {BackgroundTransparency = 1})
    tween(self.CardScale, 0.15, {Scale = 0.85})
    task.delay(0.15, function()
      self.Overlay.Visible = false
    end)
  end
end

function Window:OnDestroy(fn)
  table.insert(self.Cleanups, fn)
end

function Window:Destroy()
  for _, fn in ipairs(self.Cleanups) do
    pcall(fn)
  end
  self.Cleanups = {}
  for _, c in ipairs(self.Conns) do
    pcall(function()
      c:Disconnect()
    end)
  end
  self.Conns = {}
  if self.Blur then
    self.Blur:Destroy()
  end
  if self.Gui then
    self.Gui:Destroy()
  end
end

function Window:Notify(title, text, dur)
  local n = make("CanvasGroup", {
    Size = UDim2.fromOffset(250, 58),
    BackgroundColor3 = T.Deep,
    BackgroundTransparency = 0.12,
    GroupTransparency = 1,
    BorderSizePixel = 0,
    Parent = self.Holder,
  })
  corner(n, 14)
  local ns = stroke(n, T.White, 1.2, 0)
  grad(ns, ColorSequence.new(T.Accent2, T.Accent3), NumberSequence.new(0.1, 0.6), 45)
  local nsheen = make("Frame", {
    Size = UDim2.fromScale(1, 0.5),
    BackgroundColor3 = T.White,
    BorderSizePixel = 0,
    Parent = n,
  })
  grad(nsheen, nil, NumberSequence.new(0.88, 1), 90)
  local bar = make("Frame", {
    Size = UDim2.new(0, 3, 1, -20),
    Position = UDim2.fromOffset(10, 10),
    BackgroundColor3 = T.Accent2,
    BorderSizePixel = 0,
    Parent = n,
  })
  corner(bar, 2)
  make("TextLabel", {
    Size = UDim2.new(1, -34, 0, 20),
    Position = UDim2.fromOffset(22, 8),
    BackgroundTransparency = 1,
    Text = title,
    Font = Enum.Font.GothamBold,
    TextSize = 13,
    TextColor3 = T.Accent2,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = n,
  })
  make("TextLabel", {
    Size = UDim2.new(1, -34, 0, 22),
    Position = UDim2.fromOffset(22, 28),
    BackgroundTransparency = 1,
    Text = text,
    Font = Enum.Font.Gotham,
    TextSize = 12,
    TextColor3 = T.Text,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd,
    Parent = n,
  })
  tween(n, 0.25, {GroupTransparency = 0})
  task.delay(dur or 3, function()
    if n.Parent then
      tween(n, 0.25, {GroupTransparency = 1})
      task.delay(0.3, function()
        n:Destroy()
      end)
    end
  end)
end

function Tab:Select()
  for _, t in ipairs(self.Window.Tabs) do
    local on = t == self
    t.Page.Visible = on
    tween(t.Btn, 0.22, {BackgroundTransparency = on and 0.12 or 0.93})
    tween(t.Stroke, 0.22, {Transparency = on and 0.2 or 0.86})
    tween(t.Bar, 0.22, {BackgroundTransparency = on and 0 or 1})
    tween(t.Lbl, 0.22, {TextColor3 = on and T.White or T.Sub})
  end
end

function Window:AddTab(name)
  local tab = setmetatable({Window = self, Name = name, Order = 0}, Tab)
  local btn = make("TextButton", {
    Size = UDim2.new(1, 0, 0, 36),
    BackgroundColor3 = T.White,
    BackgroundTransparency = 0.93,
    Text = "",
    AutoButtonColor = false,
    LayoutOrder = #self.Tabs + 1,
    Parent = self.TabList,
  })
  corner(btn, 11)
  grad(btn, ColorSequence.new(Color3.fromRGB(180, 132, 255), Color3.fromRGB(112, 66, 232)), nil, 20)
  local st = stroke(btn, T.White, 1, 0.86)
  local bar = make("Frame", {
    Size = UDim2.fromOffset(3, 16),
    Position = UDim2.new(0, 7, 0.5, -8),
    BackgroundColor3 = T.White,
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Parent = btn,
  })
  corner(bar, 2)
  local lbl = make("TextLabel", {
    Size = UDim2.new(1, -26, 1, 0),
    Position = UDim2.fromOffset(20, 0),
    BackgroundTransparency = 1,
    Text = name,
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    TextColor3 = T.Sub,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = btn,
  })
  local page = make("ScrollingFrame", {
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = T.Accent2,
    CanvasSize = UDim2.new(),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    Visible = false,
    Parent = self.Content,
  })
  make("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = page})
  make("UIPadding", {PaddingRight = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6), Parent = page})
  tab.Btn, tab.Stroke, tab.Bar, tab.Lbl, tab.Page = btn, st, bar, lbl, page
  btn.MouseButton1Click:Connect(function()
    tab:Select()
  end)
  table.insert(self.Tabs, tab)
  if #self.Tabs == 1 then
    tab:Select()
  end
  return tab
end

local function card(tab, h)
  tab.Order += 1
  local f = make("Frame", {
    Size = UDim2.new(1, 0, 0, h),
    BackgroundColor3 = Color3.fromRGB(238, 228, 255),
    BackgroundTransparency = 0.87,
    BorderSizePixel = 0,
    LayoutOrder = tab.Order,
    ClipsDescendants = true,
    Parent = tab.Page,
  })
  corner(f, 12)
  local st = stroke(f, T.White, 1, 0)
  grad(st, nil, NumberSequence.new(0.45, 0.92), 45)
  local sheen = make("Frame", {
    Size = UDim2.fromScale(1, 0.55),
    BackgroundColor3 = T.White,
    BorderSizePixel = 0,
    Parent = f,
  })
  grad(sheen, nil, NumberSequence.new(0.88, 1), 90)
  return f
end

function Tab:AddSection(text)
  self.Order += 1
  local s = make("Frame", {
    Size = UDim2.new(1, 0, 0, 24),
    BackgroundTransparency = 1,
    LayoutOrder = self.Order,
    Parent = self.Page,
  })
  local l = make("TextLabel", {
    Size = UDim2.new(1, 0, 0, 20),
    BackgroundTransparency = 1,
    Text = string.upper(text),
    Font = Enum.Font.GothamBlack,
    TextSize = 11,
    TextColor3 = T.White,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = s,
  })
  grad(l, ColorSequence.new(T.Accent2, T.Accent), nil, 0)
  local line = make("Frame", {
    Size = UDim2.new(1, 0, 0, 1),
    Position = UDim2.new(0, 0, 1, -2),
    BackgroundColor3 = T.White,
    BorderSizePixel = 0,
    Parent = s,
  })
  grad(line, nil, NumberSequence.new(0.5, 1), 0)
  return s
end

function Tab:AddLabel(text)
  local c = card(self, 36)
  local l = make("TextLabel", {
    Size = UDim2.new(1, -28, 1, 0),
    Position = UDim2.fromOffset(14, 0),
    BackgroundTransparency = 1,
    Text = text,
    Font = Enum.Font.GothamMedium,
    TextSize = 12,
    TextColor3 = T.Text,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = c,
  })
  return {
    Set = function(_, v)
      l.Text = v
    end,
  }
end

function Tab:AddButton(text, callback)
  local c = card(self, 44)
  local f, hit = gbutton(
    c,
    text,
    Color3.fromRGB(176, 128, 255),
    Color3.fromRGB(104, 62, 226),
    UDim2.new(1, -10, 1, -10),
    UDim2.fromOffset(5, 5)
  )
  hit.MouseButton1Click:Connect(function()
    f.BackgroundTransparency = 0.4
    tween(f, 0.3, {BackgroundTransparency = 0.12})
    if callback then
      task.spawn(callback)
    end
  end)
end

function Tab:AddToggle(text, default, callback)
  local c = card(self, 42)
  make("TextLabel", {
    Size = UDim2.new(1, -80, 1, 0),
    Position = UDim2.fromOffset(14, 0),
    BackgroundTransparency = 1,
    Text = text,
    Font = Enum.Font.GothamMedium,
    TextSize = 13,
    TextColor3 = T.Text,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = c,
  })
  local sw = make("Frame", {
    Size = UDim2.fromOffset(44, 24),
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -14, 0.5, 0),
    BackgroundColor3 = Color3.fromRGB(30, 20, 56),
    BackgroundTransparency = 0.2,
    BorderSizePixel = 0,
    Parent = c,
  })
  corner(sw, 12)
  local swStroke = stroke(sw, T.White, 1, 0.8)
  local fill = make("Frame", {
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = T.White,
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Parent = sw,
  })
  corner(fill, 12)
  grad(fill, ColorSequence.new(T.Accent2, T.Accent3), nil, 0)
  local knob = make("Frame", {
    Size = UDim2.fromOffset(18, 18),
    AnchorPoint = Vector2.new(0, 0.5),
    Position = UDim2.new(0, 3, 0.5, 0),
    BackgroundColor3 = T.White,
    BorderSizePixel = 0,
    Parent = sw,
  })
  corner(knob, 9)
  local hit = make("TextButton", {
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Text = "",
    Parent = c,
  })
  local obj = {Value = default and true or false}
  local function render(fire)
    tween(fill, 0.22, {BackgroundTransparency = obj.Value and 0.05 or 1})
    tween(swStroke, 0.22, {Transparency = obj.Value and 0.3 or 0.8, Color = obj.Value and T.Accent2 or T.White})
    tween(knob, 0.22, {Position = obj.Value and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)})
    if fire and callback then
      task.spawn(callback, obj.Value)
    end
  end
  function obj:Set(v)
    obj.Value = v and true or false
    render(true)
  end
  hit.MouseButton1Click:Connect(function()
    obj.Value = not obj.Value
    render(true)
  end)
  render(false)
  return obj
end

function Tab:AddSlider(text, min, max, default, callback)
  local c = card(self, 58)
  make("TextLabel", {
    Size = UDim2.new(1, -90, 0, 24),
    Position = UDim2.fromOffset(14, 5),
    BackgroundTransparency = 1,
    Text = text,
    Font = Enum.Font.GothamMedium,
    TextSize = 13,
    TextColor3 = T.Text,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = c,
  })
  local chip = make("Frame", {
    Size = UDim2.fromOffset(46, 20),
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -12, 0, 7),
    BackgroundColor3 = T.Accent,
    BackgroundTransparency = 0.55,
    BorderSizePixel = 0,
    Parent = c,
  })
  corner(chip, 10)
  stroke(chip, T.Accent2, 1, 0.6)
  local val = make("TextLabel", {
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Text = "",
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    TextColor3 = T.White,
    Parent = chip,
  })
  local hit = make("TextButton", {
    Size = UDim2.new(1, -28, 0, 24),
    Position = UDim2.fromOffset(14, 30),
    BackgroundTransparency = 1,
    Text = "",
    Parent = c,
  })
  local track = make("Frame", {
    Size = UDim2.new(1, 0, 0, 6),
    AnchorPoint = Vector2.new(0, 0.5),
    Position = UDim2.fromScale(0, 0.5),
    BackgroundColor3 = T.White,
    BackgroundTransparency = 0.85,
    BorderSizePixel = 0,
    Parent = hit,
  })
  corner(track, 3)
  local fill = make("Frame", {
    Size = UDim2.fromScale(0, 1),
    BackgroundColor3 = T.White,
    BorderSizePixel = 0,
    Parent = track,
  })
  corner(fill, 3)
  grad(fill, ColorSequence.new(T.Accent3, T.Accent2), nil, 0)
  local knob = make("Frame", {
    Size = UDim2.fromOffset(16, 16),
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0, 0.5),
    BackgroundColor3 = T.White,
    BorderSizePixel = 0,
    Parent = track,
  })
  corner(knob, 8)
  stroke(knob, T.Accent, 2, 0.2)

  local obj = {Value = math.clamp(default or min, min, max)}
  local function set(v, fire)
    v = math.clamp(math.floor(v + 0.5), min, max)
    obj.Value = v
    local a = (v - min) / (max - min)
    fill.Size = UDim2.fromScale(a, 1)
    knob.Position = UDim2.fromScale(a, 0.5)
    val.Text = tostring(v)
    if fire and callback then
      task.spawn(callback, v)
    end
  end
  function obj:Set(v)
    set(v, true)
  end
  local function fromX(x)
    local a = math.clamp((x - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X), 0, 1)
    set(min + (max - min) * a, true)
  end

  local dragging = false
  hit.InputBegan:Connect(function(input)
    local t = input.UserInputType
    if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
      dragging = true
      self.Page.ScrollingEnabled = false
      tween(knob, 0.15, {Size = UDim2.fromOffset(20, 20)})
      fromX(input.Position.X)
    end
  end)
  table.insert(self.Window.Conns, UIS.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
      fromX(input.Position.X)
    end
  end))
  table.insert(self.Window.Conns, UIS.InputEnded:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
      dragging = false
      self.Page.ScrollingEnabled = true
      tween(knob, 0.15, {Size = UDim2.fromOffset(16, 16)})
    end
  end))
  set(obj.Value, false)
  return obj
end

local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local hasDrawing = Drawing ~= nil and Drawing.new ~= nil

local Flags = {
  Enabled = false,
  Box = true,
  Tracer = true,
  Skeleton = true,
  Head = true,
  Counter = true,
  Hitbox = true,
  HitboxSize = 9,
  MaxDist = 2500,
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
  {"RightLowerLeg", "RightFoot"},
}

local R6Bones = {
  {"Head", "Torso"},
  {"Torso", "Left Arm"},
  {"Torso", "Right Arm"},
  {"Torso", "Left Leg"},
  {"Torso", "Right Leg"},
}

local Drawings = {}
local Modified = {}
local CounterText

if hasDrawing then
  CounterText = Drawing.new("Text")
  CounterText.Visible = false
  CounterText.Color = Color3.fromRGB(255, 0, 0)
  CounterText.Size = 36
  CounterText.Center = true
  CounterText.Outline = true
  CounterText.OutlineColor = Color3.fromRGB(0, 0, 0)
  if Drawing.Fonts then
    CounterText.Font = Drawing.Fonts.UI
  end
end

local function removeObj(o)
  pcall(function()
    o:Remove()
  end)
end

local function clearDrawings(player)
  local d = Drawings[player]
  if not d then
    return
  end
  removeObj(d.Box)
  removeObj(d.Tracer)
  removeObj(d.Head)
  for _, l in ipairs(d.Lines) do
    removeObj(l)
  end
  Drawings[player] = nil
end

local function createDrawings(player)
  local box = Drawing.new("Square")
  box.Color = Color3.fromRGB(255, 0, 0)
  box.Thickness = 1.5
  box.Filled = false
  box.Visible = false

  local tracer = Drawing.new("Line")
  tracer.Color = Color3.fromRGB(255, 255, 255)
  tracer.Thickness = 1
  tracer.Visible = false

  local head = Drawing.new("Circle")
  head.Color = Color3.fromRGB(0, 255, 0)
  head.Thickness = 1.5
  head.Filled = false
  head.Visible = false

  local lines = {}
  for i = 1, 14 do
    local l = Drawing.new("Line")
    l.Color = Color3.fromRGB(0, 255, 0)
    l.Thickness = 1.5
    l.Visible = false
    lines[i] = l
  end

  local d = {Box = box, Tracer = tracer, Head = head, Lines = lines}
  Drawings[player] = d
  return d
end

local function hideDrawings(d)
  d.Box.Visible = false
  d.Tracer.Visible = false
  d.Head.Visible = false
  for _, l in ipairs(d.Lines) do
    l.Visible = false
  end
end

local function restoreOne(hrp)
  local o = Modified[hrp]
  if not o then
    return
  end
  if hrp.Parent then
    hrp.Size = o.Size
    hrp.Transparency = o.Transparency
    hrp.CanCollide = o.CanCollide
  end
  Modified[hrp] = nil
end

local function restoreAll()
  for hrp in pairs(Modified) do
    restoreOne(hrp)
  end
end

local function applyHitbox(hrp)
  if not Modified[hrp] then
    Modified[hrp] = {Size = hrp.Size, Transparency = hrp.Transparency, CanCollide = hrp.CanCollide}
  end
  local s = Vector3.new(Flags.HitboxSize, Flags.HitboxSize, Flags.HitboxSize)
  if hrp.Size ~= s then
    hrp.Size = s
  end
  hrp.Transparency = 0.7
  hrp.CanCollide = false
end

local function boneScreen(cam, char, name)
  local part = char:FindFirstChild(name)
  if not part then
    return nil, false
  end
  local p, on = cam:WorldToViewportPoint(part.Position)
  return Vector2.new(p.X, p.Y), on
end

local function cleanupAll()
  restoreAll()
  for player in pairs(Drawings) do
    clearDrawings(player)
  end
  if CounterText then
    CounterText.Visible = false
  end
end

local espConn = RunService.RenderStepped:Connect(function()
  local cam = workspace.CurrentCamera
  if not cam then
    return
  end

  for hrp in pairs(Modified) do
    if not hrp.Parent then
      Modified[hrp] = nil
    end
  end

  if not (Flags.Enabled and Flags.Hitbox) then
    restoreAll()
  end

  if not Flags.Enabled then
    return
  end

  local count = 0
  local vp = cam.ViewportSize
  local origin = Vector2.new(vp.X / 2, 0)
  local myChar = LocalPlayer.Character
  local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")

  for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
      local char = player.Character
      local hum = char and char:FindFirstChildOfClass("Humanoid")
      local hrp = char and char:FindFirstChild("HumanoidRootPart")
      local head = char and char:FindFirstChild("Head")
      local valid = hum ~= nil and hrp ~= nil and head ~= nil and hum.Health > 0

      if valid and myHrp then
        local diff = hrp.Position - myHrp.Position
        if diff.Magnitude > Flags.MaxDist or math.abs(diff.Y) > 600 then
          valid = false
        end
      end

      if valid then
        if Flags.Hitbox then
          applyHitbox(hrp)
        else
          restoreOne(hrp)
        end

        if hasDrawing then
          local d = Drawings[player] or createDrawings(player)
          local hp, onScreen = cam:WorldToViewportPoint(hrp.Position)
          if onScreen then
            count += 1
            local headTop = cam:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
            local foot = cam:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
            local height = math.abs(headTop.Y - foot.Y)
            local width = height * 0.65

            if Flags.Box then
              d.Box.Size = Vector2.new(width, height)
              d.Box.Position = Vector2.new(hp.X - width / 2, hp.Y - height / 2)
            end
            d.Box.Visible = Flags.Box

            if Flags.Tracer then
              d.Tracer.From = origin
              d.Tracer.To = Vector2.new(hp.X, hp.Y)
            end
            d.Tracer.Visible = Flags.Tracer

            local hpos, hvis = cam:WorldToViewportPoint(head.Position)
            if Flags.Head and hvis then
              d.Head.Position = Vector2.new(hpos.X, hpos.Y)
              d.Head.Radius = math.clamp(height / 7, 3, 20)
              d.Head.Visible = true
            else
              d.Head.Visible = false
            end

            local bones = char:FindFirstChild("UpperTorso") and R15Bones or R6Bones
            for i, line in ipairs(d.Lines) do
              local b = bones[i]
              if Flags.Skeleton and b then
                local p1, v1 = boneScreen(cam, char, b[1])
                local p2, v2 = boneScreen(cam, char, b[2])
                if p1 and p2 and v1 and v2 then
                  line.From = p1
                  line.To = p2
                  line.Visible = true
                else
                  line.Visible = false
                end
              else
                line.Visible = false
              end
            end
          else
            hideDrawings(d)
          end
        end
      else
        if hrp then
          restoreOne(hrp)
        end
        clearDrawings(player)
      end
    end
  end

  if CounterText then
    if Flags.Counter and count > 0 then
      CounterText.Text = tostring(count)
      CounterText.Position = origin + Vector2.new(0, 10)
      CounterText.Visible = true
    else
      CounterText.Visible = false
    end
  end
end)

local removingConn = Players.PlayerRemoving:Connect(function(player)
  clearDrawings(player)
end)

local MIN_SPEED = 16
local MAX_SPEED = 200
local Speed = {Enabled = false, Value = 30}

local speedConn = RunService.RenderStepped:Connect(function(dt)
  if not Speed.Enabled then
    return
  end
  local char = LocalPlayer.Character
  if not char then
    return
  end
  local hum = char:FindFirstChildOfClass("Humanoid")
  local root = char:FindFirstChild("HumanoidRootPart")
  if hum and root and hum.MoveDirection.Magnitude > 0 then
    local extra = Speed.Value - hum.WalkSpeed
    if extra > 0 then
      root.CFrame = root.CFrame + hum.MoveDirection * (extra * dt)
    end
  end
end)

local function addStepButtons(tab, slider, step)
  local c = card(tab, 44)
  local _, minus = gbutton(
    c,
    "− " .. step,
    Color3.fromRGB(128, 108, 184),
    Color3.fromRGB(76, 60, 120),
    UDim2.new(0.5, -8, 1, -10),
    UDim2.fromOffset(5, 5)
  )
  local _, plus = gbutton(
    c,
    "+ " .. step,
    Color3.fromRGB(176, 128, 255),
    Color3.fromRGB(104, 62, 226),
    UDim2.new(0.5, -8, 1, -10),
    UDim2.new(0.5, 3, 0, 5)
  )
  minus.MouseButton1Click:Connect(function()
    slider:Set(slider.Value - step)
  end)
  plus.MouseButton1Click:Connect(function()
    slider:Set(slider.Value + step)
  end)
end

local Win = Shin.new({Key = Enum.KeyCode.RightControl})

local Jump = {Enabled = false, Value = 50, Infinite = false}
local JumpOrig = {}

local function restoreJump()
  for hum, o in pairs(JumpOrig) do
    if hum.Parent then
      pcall(function()
        hum.UseJumpPower = o.Use
        hum.JumpPower = o.Power
      end)
    end
    JumpOrig[hum] = nil
  end
end

local jumpConn = RunService.Heartbeat:Connect(function()
  local char = LocalPlayer.Character
  local hum = char and char:FindFirstChildOfClass("Humanoid")
  for h in pairs(JumpOrig) do
    if not h.Parent then
      JumpOrig[h] = nil
    end
  end
  if not Jump.Enabled then
    restoreJump()
    return
  end
  if not hum then
    return
  end
  if not JumpOrig[hum] then
    JumpOrig[hum] = {Use = hum.UseJumpPower, Power = hum.JumpPower}
  end
  if not hum.UseJumpPower then
    hum.UseJumpPower = true
  end
  if hum.JumpPower ~= Jump.Value then
    hum.JumpPower = Jump.Value
  end
end)

local infConn = UIS.JumpRequest:Connect(function()
  if not Jump.Infinite then
    return
  end
  local char = LocalPlayer.Character
  local hum = char and char:FindFirstChildOfClass("Humanoid")
  if hum then
    hum:ChangeState(Enum.HumanoidStateType.Jumping)
  end
end)

local Boost = {Enabled = false, Token = 0}
local Saved = setmetatable({}, {__mode = "k"})
local BoostConns
local BoostGlobal = {}

local function desired(inst)
  if inst:IsA("Terrain") then
    return nil
  end
  if inst:IsA("BasePart") then
    return {Material = Enum.Material.SmoothPlastic, Reflectance = 0, CastShadow = false}
  elseif inst:IsA("Decal") then
    return {Transparency = 1}
  elseif inst:IsA("ParticleEmitter") or inst:IsA("Trail") or inst:IsA("Beam") or inst:IsA("Smoke") or inst:IsA("Fire") or inst:IsA("Sparkles") or inst:IsA("Clouds") then
    return {Enabled = false}
  elseif inst:IsA("PostEffect") then
    if inst.Name == "ShinBlur" then
      return nil
    end
    return {Enabled = false}
  elseif inst:IsA("Atmosphere") then
    return {Density = 0, Haze = 0}
  end
  return nil
end

local function applyInst(inst)
  if Saved[inst] then
    return
  end
  local d = desired(inst)
  if not d then
    return
  end
  local s = {}
  local ok = pcall(function()
    for k in pairs(d) do
      s[k] = inst[k]
    end
    for k, v in pairs(d) do
      inst[k] = v
    end
  end)
  if ok then
    Saved[inst] = s
  end
end

local function applyGlobals()
  BoostGlobal = {}
  pcall(function()
    BoostGlobal.Shadows = Lighting.GlobalShadows
    Lighting.GlobalShadows = false
  end)
  pcall(function()
    BoostGlobal.Quality = settings().Rendering.QualityLevel
    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
  end)
  local terrain = workspace:FindFirstChildOfClass("Terrain")
  if terrain then
    BoostGlobal.Terrain = {}
    for _, k in ipairs({"WaterWaveSize", "WaterWaveSpeed", "WaterReflectance"}) do
      pcall(function()
        BoostGlobal.Terrain[k] = terrain[k]
        terrain[k] = 0
      end)
    end
    pcall(function()
      BoostGlobal.Decoration = terrain.Decoration
      terrain.Decoration = false
    end)
  end
  if sethiddenproperty and gethiddenproperty then
    pcall(function()
      BoostGlobal.Tech = gethiddenproperty(Lighting, "Technology")
      sethiddenproperty(Lighting, "Technology", Enum.Technology.Compatibility)
    end)
  end
end

local function restoreGlobals()
  local g = BoostGlobal
  BoostGlobal = {}
  if g.Shadows ~= nil then
    pcall(function()
      Lighting.GlobalShadows = g.Shadows
    end)
  end
  if g.Quality then
    pcall(function()
      settings().Rendering.QualityLevel = g.Quality
    end)
  end
  local terrain = workspace:FindFirstChildOfClass("Terrain")
  if terrain and g.Terrain then
    for k, v in pairs(g.Terrain) do
      pcall(function()
        terrain[k] = v
      end)
    end
    if g.Decoration ~= nil then
      pcall(function()
        terrain.Decoration = g.Decoration
      end)
    end
  end
  if g.Tech and sethiddenproperty then
    pcall(function()
      sethiddenproperty(Lighting, "Technology", g.Tech)
    end)
  end
end

local function enableBoost()
  Boost.Token += 1
  local token = Boost.Token
  applyGlobals()
  BoostConns = {
    workspace.DescendantAdded:Connect(applyInst),
    Lighting.DescendantAdded:Connect(applyInst),
  }
  task.spawn(function()
    local n = 0
    local function run(list)
      for _, inst in ipairs(list) do
        if token ~= Boost.Token then
          return false
        end
        applyInst(inst)
        n += 1
        if n % 300 == 0 then
          task.wait()
        end
      end
      return true
    end
    if run(Lighting:GetDescendants()) and run(workspace:GetDescendants()) then
      Win:Notify("FPS Boost", "Đã tối ưu " .. n .. " đối tượng", 3)
    end
  end)
end

local function disableBoost()
  Boost.Token += 1
  local token = Boost.Token
  if BoostConns then
    for _, c in ipairs(BoostConns) do
      c:Disconnect()
    end
    BoostConns = nil
  end
  restoreGlobals()
  task.spawn(function()
    local n = 0
    for inst, s in pairs(Saved) do
      if token ~= Boost.Token then
        return
      end
      if inst.Parent then
        pcall(function()
          for k, v in pairs(s) do
            inst[k] = v
          end
        end)
      end
      Saved[inst] = nil
      n += 1
      if n % 300 == 0 then
        task.wait()
      end
    end
  end)
end

local function getRoot(char)
  if not char then
    return nil
  end
  return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
end

local function getHum(char)
  return char and char:FindFirstChildOfClass("Humanoid")
end

local Spin = {Enabled = false, Speed = 40, Angle = 0}

local spinConn = RunService.RenderStepped:Connect(function(dt)
  if not Spin.Enabled then
    return
  end
  local char = LocalPlayer.Character
  local root = char and char:FindFirstChild("HumanoidRootPart")
  local hum = getHum(char)
  if root and hum and hum.Health > 0 then
    Spin.Angle = (Spin.Angle + Spin.Speed * dt * 60) % 360
    root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, math.rad(Spin.Angle), 0)
  end
end)

local Invis = {Enabled = false}
local InvisSaved = setmetatable({}, {__mode = "k"})
local invisInfo

local function restoreInvis()
  for inst, v in pairs(InvisSaved) do
    if inst.Parent then
      pcall(function()
        inst.Transparency = v
      end)
    end
    InvisSaved[inst] = nil
  end
  if invisInfo then
    local info = invisInfo
    invisInfo = nil
    if info.hum.Parent then
      pcall(function()
        info.hum.DisplayDistanceType = info.kind
      end)
    end
  end
end

local invisConn = RunService.Heartbeat:Connect(function()
  if not Invis.Enabled then
    if next(InvisSaved) or invisInfo then
      restoreInvis()
    end
    return
  end
  local char = LocalPlayer.Character
  if not char then
    return
  end
  for _, inst in ipairs(char:GetDescendants()) do
    if (inst:IsA("BasePart") or inst:IsA("Decal")) and inst.Name ~= "HumanoidRootPart" then
      if InvisSaved[inst] == nil then
        InvisSaved[inst] = inst.Transparency
      end
      if inst.Transparency ~= 1 then
        inst.Transparency = 1
      end
    end
  end
  local hum = getHum(char)
  if hum and (not invisInfo or invisInfo.hum ~= hum) then
    invisInfo = {hum = hum, kind = hum.DisplayDistanceType}
    hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
  end
end)

local Target
local targetInfo
local targetDetail
local Follow = {Enabled = false, Speed = 50, Mode = "Behind", Distance = 3, Hum = nil}
local FollowModes = {{"Behind", "Sau lưng"}, {"Below", "Dưới"}, {"Center", "Trung tâm"}}
local NoclipSaved = setmetatable({}, {__mode = "k"})

local function setNoclip(char, on)
  if not char then
    return
  end
  for _, part in ipairs(char:GetDescendants()) do
    if part:IsA("BasePart") then
      if on then
        if not NoclipSaved[part] then
          NoclipSaved[part] = {part.CanCollide, part.CanTouch}
        end
        part.CanCollide = false
        part.CanTouch = false
      elseif NoclipSaved[part] then
        part.CanCollide = NoclipSaved[part][1]
        part.CanTouch = NoclipSaved[part][2]
        NoclipSaved[part] = nil
      end
    end
  end
end

local function setProtect(hum, on)
  pcall(function()
    hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, not on)
    hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, not on)
    hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, not on)
  end)
end

local function followOffset()
  if Follow.Mode == "Below" then
    return CFrame.new(0, -Follow.Distance, 0)
  elseif Follow.Mode == "Center" then
    return CFrame.new()
  end
  return CFrame.new(0, 0, Follow.Distance)
end

local function stopFollow()
  Follow.Enabled = false
  local char = LocalPlayer.Character
  local root = getRoot(char)
  local hum = getHum(char)
  if root then
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
  end
  if hum then
    hum.PlatformStand = false
    setProtect(hum, false)
  end
  Follow.Hum = nil
  setNoclip(char, false)
end

local followConn = RunService.Heartbeat:Connect(function(dt)
  if not Follow.Enabled then
    return
  end
  local char = LocalPlayer.Character
  local root = getRoot(char)
  local hum = getHum(char)
  if not (root and hum and hum.Health > 0) then
    return
  end
  local tgt = Target
  if not (tgt and tgt.Parent) then
    root.AssemblyLinearVelocity = Vector3.zero
    return
  end
  local tChar = tgt.Character
  local tRoot = getRoot(tChar)
  local tHum = getHum(tChar)
  if not (tRoot and tHum and tHum.Health > 0) then
    root.AssemblyLinearVelocity = Vector3.zero
    return
  end
  if Follow.Hum ~= hum then
    Follow.Hum = hum
    setProtect(hum, true)
  end
  setNoclip(char, true)
  hum.PlatformStand = true
  local goal = tRoot.CFrame * followOffset()
  local diff = goal.Position - root.Position
  local dist = diff.Magnitude
  root.AssemblyLinearVelocity = Vector3.zero
  root.AssemblyAngularVelocity = Vector3.zero
  local rot = Spin.Enabled and (root.CFrame - root.Position) or (goal - goal.Position)
  if dist > 0.05 then
    local step = math.min(dist, Follow.Speed * math.max(dt, 1 / 240))
    root.CFrame = CFrame.new(root.Position + diff.Unit * step) * rot
  else
    root.CFrame = CFrame.new(goal.Position) * rot
  end
end)

local function teleToTarget()
  if not Target then
    Win:Notify("Người chơi", "Chưa chọn mục tiêu", 2)
    return
  end
  local root = getRoot(LocalPlayer.Character)
  local tRoot = getRoot(Target.Character)
  if not (root and tRoot) then
    Win:Notify("Người chơi", "Nhân vật chưa sẵn sàng", 2)
    return
  end
  root.AssemblyLinearVelocity = Vector3.zero
  root.AssemblyAngularVelocity = Vector3.zero
  root.CFrame = tRoot.CFrame * followOffset()
  Win:Notify("Người chơi", "Đã tới " .. Target.DisplayName, 2)
end

local infoTimer = 0
local infoConn = RunService.Heartbeat:Connect(function(dt)
  infoTimer += dt
  if infoTimer < 0.2 then
    return
  end
  infoTimer = 0
  if not (targetInfo and targetDetail) then
    return
  end
  if not (Target and Target.Parent) then
    targetInfo:Set("Mục tiêu: chưa chọn")
    targetDetail:Set("Máu: N/A | Cao: N/A")
    return
  end
  local char = Target.Character
  local tRoot = getRoot(char)
  local tHum = getHum(char)
  local myRoot = getRoot(LocalPlayer.Character)
  if tRoot and myRoot then
    local d = math.floor((myRoot.Position - tRoot.Position).Magnitude * 10) / 10
    targetInfo:Set(Target.DisplayName .. " [" .. d .. "m]")
  else
    targetInfo:Set(Target.DisplayName .. " [N/A]")
  end
  if char and tHum then
    local hp = math.max(0, math.floor(tHum.Health))
    local maxHp = math.max(0, math.floor(tHum.MaxHealth))
    local height = math.floor(char:GetExtentsSize().Y * 10) / 10
    targetDetail:Set("Máu: " .. hp .. "/" .. maxHp .. " | Cao: " .. height .. "m")
  else
    targetDetail:Set("Máu: N/A | Cao: N/A")
  end
end)

function Tab:AddPlayerList(onSelect)
  local c = card(self, 150)
  local list = make("ScrollingFrame", {
    Size = UDim2.new(1, -16, 1, -16),
    Position = UDim2.fromOffset(8, 8),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = T.Accent2,
    CanvasSize = UDim2.new(),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    Parent = c,
  })
  make("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list})
  local rows = {}
  local selected
  local counter = 0

  local function paint()
    for p, r in pairs(rows) do
      local on = p == selected
      tween(r.Frame, 0.18, {BackgroundTransparency = on and 0.15 or 0.9})
      tween(r.Label, 0.18, {TextColor3 = on and T.White or T.Sub})
    end
  end

  local function add(p)
    if p == LocalPlayer or rows[p] then
      return
    end
    counter += 1
    local f = make("TextButton", {
      Size = UDim2.new(1, 0, 0, 30),
      BackgroundColor3 = T.White,
      BackgroundTransparency = 0.9,
      Text = "",
      AutoButtonColor = false,
      LayoutOrder = counter,
      Parent = list,
    })
    corner(f, 8)
    grad(f, ColorSequence.new(Color3.fromRGB(180, 132, 255), Color3.fromRGB(112, 66, 232)), nil, 20)
    local l = make("TextLabel", {
      Size = UDim2.new(1, -16, 1, 0),
      Position = UDim2.fromOffset(10, 0),
      BackgroundTransparency = 1,
      Text = p.DisplayName .. "  @" .. p.Name,
      Font = Enum.Font.GothamMedium,
      TextSize = 12,
      TextColor3 = T.Sub,
      TextXAlignment = Enum.TextXAlignment.Left,
      TextTruncate = Enum.TextTruncate.AtEnd,
      Parent = f,
    })
    rows[p] = {Frame = f, Label = l}
    f.MouseButton1Click:Connect(function()
      selected = p
      paint()
      if onSelect then
        onSelect(p)
      end
    end)
  end

  for _, p in ipairs(Players:GetPlayers()) do
    add(p)
  end
  table.insert(self.Window.Conns, Players.PlayerAdded:Connect(add))
  table.insert(self.Window.Conns, Players.PlayerRemoving:Connect(function(p)
    if rows[p] then
      rows[p].Frame:Destroy()
      rows[p] = nil
    end
    if selected == p then
      selected = nil
      if onSelect then
        onSelect(nil)
      end
    end
  end))
end

Win:OnDestroy(function()
  espConn:Disconnect()
  removingConn:Disconnect()
  speedConn:Disconnect()
  Speed.Enabled = false
  jumpConn:Disconnect()
  infConn:Disconnect()
  Jump.Enabled = false
  Jump.Infinite = false
  restoreJump()
  disableBoost()
  spinConn:Disconnect()
  followConn:Disconnect()
  infoConn:Disconnect()
  invisConn:Disconnect()
  Spin.Enabled = false
  Invis.Enabled = false
  stopFollow()
  restoreInvis()
  cleanupAll()
  if CounterText then
    removeObj(CounterText)
  end
end)

local function installShin(Win, Plr)
  local RunService = game:GetService("RunService")
  local HttpService = game:GetService("HttpService")
  local SoundService = game:GetService("SoundService")
  local TeleportService = game:GetService("TeleportService")
  local ProximityPromptService = game:GetService("ProximityPromptService")
  local MarketplaceService = game:GetService("MarketplaceService")
  local ContentProvider = game:GetService("ContentProvider")
  local CoreGui = game:GetService("CoreGui")
  local Player = Players.LocalPlayer
  local Mouse = Player:GetMouse()
  local alive = true
  local S = {
    NoFog = false,
    Fullbright = false,
    InfJump = false,
    AntiKick = true,
    SkyMode = "Normal",
    SkyStatic = nil,
    SkyToken = 0,
    Sky666 = false,
    Disco = false,
    DiscoThread = nil,
    PlayerEsp = false,
    NpcEsp = false,
  }

  local OriginalLighting = {
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    ColorShift_Top = Lighting.ColorShift_Top,
    ColorShift_Bottom = Lighting.ColorShift_Bottom,
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    FogStart = Lighting.FogStart,
    FogColor = Lighting.FogColor,
    GlobalShadows = Lighting.GlobalShadows,
  }

  local function note(text)
    Win:Notify("Shin Roblox", text, 2)
  end

  local function playSound(id, vol)
    pcall(function()
      local s = Instance.new("Sound")
      s.SoundId = "rbxassetid://" .. tostring(id)
      s.Volume = vol or 0.5
      s.Parent = SoundService
      s:Play()
      s.Ended:Connect(function()
        s:Destroy()
      end)
      task.delay(3, function()
        if s and s.Parent then
          s:Destroy()
        end
      end)
    end)
  end

  local function P(id)
    return "https://pastefy.app/" .. id .. "/raw"
  end

  local RawFn, RawBusy = {}, {}

  local function getRawFn(url)
    if RawFn[url] then
      return RawFn[url]
    end
    if RawBusy[url] then
      local t0 = os.clock()
      while RawBusy[url] and os.clock() - t0 < 15 do
        task.wait()
      end
      return RawFn[url]
    end
    RawBusy[url] = true
    local ok, res = pcall(function()
      return game:HttpGet(url, true)
    end)
    RawBusy[url] = nil
    if ok and type(res) == "string" and #res > 0 then
      local fn = loadstring(res)
      if fn then
        RawFn[url] = fn
      end
      return fn
    end
  end

  local function runRaw(url)
    task.spawn(function()
      local f = getRawFn(url)
      if f then
        local ok = pcall(f)
        if not ok then
          note("Script báo lỗi khi chạy")
        end
      else
        note("Không tải được script, thử lại!")
      end
    end)
  end

  local function runFresh(url)
    task.spawn(function()
      local ok, res = pcall(function()
        return game:HttpGet(url .. "?&v=1&t=" .. tick(), true)
      end)
      if ok and type(res) == "string" and #res > 0 then
        local fn = loadstring(res)
        if fn then
          pcall(fn)
          return
        end
      end
      note("Không tải được script, thử lại!")
    end)
  end

  local function loaderButton(tab, text, url, fresh)
    tab:AddButton(text, function()
      if fresh then
        runFresh(url)
      else
        runRaw(url)
      end
    end)
  end

  pcall(function()
    local vu = game:GetService("VirtualUser")
    table.insert(Win.Conns, Player.Idled:Connect(function()
      vu:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
      task.wait(1)
      vu:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    end))
  end)

  pcall(function()
    local mt = getrawmetatable(game)
    setreadonly(mt, false)
    local old = mt.__namecall
    mt.__namecall = newcclosure(function(self, ...)
      local method = getnamecallmethod()
      if alive and S.AntiKick and (method == "Kick" or method == "kick") and self == Player then
        return nil
      end
      return old(self, ...)
    end)
    setreadonly(mt, true)
  end)

  local FastPrompt = {Enabled = false, Original = setmetatable({}, {__mode = "k"}), AddConn = nil, ShownConn = nil}

  local function makePromptInstant(prompt)
    if not prompt:IsA("ProximityPrompt") then
      return
    end
    if FastPrompt.Original[prompt] == nil then
      FastPrompt.Original[prompt] = prompt.HoldDuration
    end
    if prompt.HoldDuration ~= 0 then
      prompt.HoldDuration = 0
    end
  end

  local function setFastPrompt(state)
    FastPrompt.Enabled = state and true or false
    if FastPrompt.AddConn then
      FastPrompt.AddConn:Disconnect()
      FastPrompt.AddConn = nil
    end
    if FastPrompt.ShownConn then
      FastPrompt.ShownConn:Disconnect()
      FastPrompt.ShownConn = nil
    end
    if FastPrompt.Enabled then
      FastPrompt.AddConn = workspace.DescendantAdded:Connect(function(d)
        if FastPrompt.Enabled and d:IsA("ProximityPrompt") then
          pcall(makePromptInstant, d)
        end
      end)
      FastPrompt.ShownConn = ProximityPromptService.PromptShown:Connect(function(prompt)
        pcall(makePromptInstant, prompt)
      end)
      task.spawn(function()
        local n = 0
        for _, d in ipairs(workspace:GetDescendants()) do
          if not FastPrompt.Enabled then
            return
          end
          if d:IsA("ProximityPrompt") then
            pcall(makePromptInstant, d)
          end
          n += 1
          if n % 2000 == 0 then
            task.wait()
          end
        end
      end)
    else
      for prompt, dur in pairs(FastPrompt.Original) do
        if prompt.Parent then
          pcall(function()
            prompt.HoldDuration = dur
          end)
        end
        FastPrompt.Original[prompt] = nil
      end
    end
  end

  local Noclip = {Enabled = false, Parts = setmetatable({}, {__mode = "k"}), StepConn = nil, CharConn = nil, AddConn = nil}

  local function noclipRegister(part)
    if part:IsA("BasePart") and Noclip.Parts[part] == nil then
      Noclip.Parts[part] = part.CanCollide
    end
  end

  local function noclipBind(char)
    if Noclip.AddConn then
      Noclip.AddConn:Disconnect()
      Noclip.AddConn = nil
    end
    if not char then
      return
    end
    for _, d in ipairs(char:GetDescendants()) do
      noclipRegister(d)
    end
    Noclip.AddConn = char.DescendantAdded:Connect(function(d)
      if Noclip.Enabled then
        noclipRegister(d)
      end
    end)
  end

  local function setNoclipState(state)
    Noclip.Enabled = state and true or false
    if Noclip.Enabled then
      noclipBind(Player.Character)
      for part in pairs(Noclip.Parts) do
        if part.Parent and part.CanCollide then
          part.CanCollide = false
        end
      end
      if not Noclip.StepConn then
        Noclip.StepConn = RunService.Stepped:Connect(function()
          for part in pairs(Noclip.Parts) do
            if part.Parent and part.CanCollide then
              part.CanCollide = false
            end
          end
        end)
      end
      if not Noclip.CharConn then
        Noclip.CharConn = Player.CharacterAdded:Connect(function(char)
          table.clear(Noclip.Parts)
          noclipBind(char)
        end)
      end
    else
      if Noclip.StepConn then
        Noclip.StepConn:Disconnect()
        Noclip.StepConn = nil
      end
      if Noclip.CharConn then
        Noclip.CharConn:Disconnect()
        Noclip.CharConn = nil
      end
      if Noclip.AddConn then
        Noclip.AddConn:Disconnect()
        Noclip.AddConn = nil
      end
      for part, orig in pairs(Noclip.Parts) do
        if part.Parent then
          pcall(function()
            part.CanCollide = orig
          end)
        end
        Noclip.Parts[part] = nil
      end
    end
  end

  local FLING_POWER = 25000
  local Fling = {Sources = {}, Running = false, HbConn = nil, RsConn = nil, SavedVel = Vector3.zero, Applied = false, Hum = nil}

  local function flingSetStates(hum, enabled)
    if not hum then
      return
    end
    pcall(function()
      hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, enabled)
      hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, enabled)
    end)
  end

  local function flingStop()
    if not Fling.Running then
      return
    end
    Fling.Running = false
    if Fling.HbConn then
      Fling.HbConn:Disconnect()
      Fling.HbConn = nil
    end
    if Fling.RsConn then
      Fling.RsConn:Disconnect()
      Fling.RsConn = nil
    end
    local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
      pcall(function()
        local v = Fling.Applied and Fling.SavedVel or hrp.AssemblyLinearVelocity
        if v.Magnitude > 500 then
          v = Vector3.zero
        end
        hrp.AssemblyLinearVelocity = v
        hrp.AssemblyAngularVelocity = Vector3.zero
      end)
    end
    Fling.Applied = false
    flingSetStates(Fling.Hum, true)
    Fling.Hum = nil
  end

  local function flingStart()
    if Fling.Running then
      return
    end
    Fling.Running = true
    local angle = 0
    Fling.HbConn = RunService.Heartbeat:Connect(function()
      local char = Player.Character
      local hrp = char and char:FindFirstChild("HumanoidRootPart")
      local hum = char and char:FindFirstChildOfClass("Humanoid")
      if not (hrp and hum) or hum.Health <= 0 then
        return
      end
      if Fling.Hum ~= hum then
        flingSetStates(Fling.Hum, true)
        Fling.Hum = hum
        flingSetStates(hum, false)
      end
      if not Fling.Applied then
        Fling.SavedVel = hrp.AssemblyLinearVelocity
      end
      angle = (angle + 1.7) % (math.pi * 2)
      hrp.AssemblyLinearVelocity = Vector3.new(math.cos(angle), 0.35, math.sin(angle)) * FLING_POWER
      hrp.AssemblyAngularVelocity = Vector3.zero
      Fling.Applied = true
    end)
    Fling.RsConn = RunService.RenderStepped:Connect(function()
      if not Fling.Applied then
        return
      end
      Fling.Applied = false
      local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
      if hrp then
        hrp.AssemblyLinearVelocity = Fling.SavedVel
        hrp.AssemblyAngularVelocity = Vector3.zero
      end
    end)
  end

  local function setFling(source, state)
    Fling.Sources[source] = state and true or nil
    if next(Fling.Sources) ~= nil then
      flingStart()
    else
      flingStop()
    end
  end

  local function applyLightingToggles()
    pcall(function()
      if S.NoFog then
        Lighting.FogStart = 9e9
        Lighting.FogEnd = 9e9
      end
      if S.Fullbright then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 786303
        Lighting.GlobalShadows = false
        if S.SkyMode == "Normal" and not S.Disco then
          Lighting.Ambient = Color3.fromRGB(178, 178, 178)
        end
      end
    end)
  end

  task.spawn(function()
    while alive do
      task.wait(0.2)
      if S.NoFog or S.Fullbright then
        applyLightingToggles()
      end
    end
  end)

  table.insert(Win.Conns, UIS.JumpRequest:Connect(function()
    if S.InfJump and Player.Character and Player.Character:FindFirstChildOfClass("Humanoid") then
      Player.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
    end
  end))

  local CAM_MIN_ZOOM = 0.5
  local CAM_MAX_ZOOM = 100000
  local CAM_START_ZOOM = 15
  local CamUnlock = {Enabled = false, Orig = nil, Min = CAM_MIN_ZOOM, Token = 0}

  local function camUnlockApply()
    pcall(function()
      if Player.CameraMode ~= Enum.CameraMode.Classic then
        Player.CameraMode = Enum.CameraMode.Classic
      end
      if Player.CameraMaxZoomDistance ~= CAM_MAX_ZOOM then
        Player.CameraMaxZoomDistance = CAM_MAX_ZOOM
      end
      if Player.CameraMinZoomDistance ~= CamUnlock.Min then
        Player.CameraMinZoomDistance = CamUnlock.Min
      end
    end)
  end

  local function setCamUnlock(state)
    CamUnlock.Enabled = state and true or false
    CamUnlock.Token += 1
    pcall(function()
      RunService:UnbindFromRenderStep("Shin_CamUnlock")
    end)
    if CamUnlock.Enabled then
      CamUnlock.Orig = {
        Mode = Player.CameraMode,
        Min = Player.CameraMinZoomDistance,
        Max = Player.CameraMaxZoomDistance,
      }
      CamUnlock.Min = CAM_START_ZOOM
      camUnlockApply()
      RunService:BindToRenderStep("Shin_CamUnlock", Enum.RenderPriority.Camera.Value - 1, camUnlockApply)
      local token = CamUnlock.Token
      task.delay(0.8, function()
        if CamUnlock.Enabled and CamUnlock.Token == token then
          CamUnlock.Min = CAM_MIN_ZOOM
        end
      end)
    else
      local o = CamUnlock.Orig
      if o then
        pcall(function()
          Player.CameraMode = o.Mode
          Player.CameraMinZoomDistance = o.Min
          Player.CameraMaxZoomDistance = o.Max
        end)
      end
      CamUnlock.Orig = nil
      CamUnlock.Min = CAM_MIN_ZOOM
    end
  end

  local TacosSound = SoundService:FindFirstChild("Shin_TacosMusic")
  if not TacosSound then
    TacosSound = Instance.new("Sound")
    TacosSound.Name = "Shin_TacosMusic"
    TacosSound.SoundId = "rbxassetid://142376088"
    TacosSound.Volume = 1
    TacosSound.Looped = true
    TacosSound.Parent = SoundService
  end
  task.spawn(function()
    pcall(function()
      ContentProvider:PreloadAsync({TacosSound})
    end)
  end)

  local function restoreLightingColors()
    Lighting.Ambient = OriginalLighting.Ambient
    Lighting.OutdoorAmbient = OriginalLighting.OutdoorAmbient
    Lighting.ColorShift_Top = OriginalLighting.ColorShift_Top
    Lighting.ColorShift_Bottom = OriginalLighting.ColorShift_Bottom
    Lighting.FogColor = OriginalLighting.FogColor
  end

  local function setDisco(state)
    S.Disco = state and true or false
    if S.DiscoThread then
      pcall(task.cancel, S.DiscoThread)
      S.DiscoThread = nil
    end
    if S.Disco then
      if not TacosSound.IsPlaying then
        TacosSound:Play()
      end
      S.DiscoThread = task.spawn(function()
        local hue = 0
        while S.Disco and alive do
          hue = (hue + 0.04) % 1
          local c = Color3.fromHSV(hue, 1, 1)
          Lighting.Ambient = c
          Lighting.OutdoorAmbient = c
          Lighting.FogColor = c
          Lighting.ColorShift_Top = c
          Lighting.ColorShift_Bottom = c
          task.wait(0.02)
        end
      end)
    else
      if TacosSound.IsPlaying then
        TacosSound:Stop()
      end
      restoreLightingColors()
      if S.SkyMode == "Static" and S.SkyStatic then
        Lighting.OutdoorAmbient = S.SkyStatic
        Lighting.Ambient = S.SkyStatic
        Lighting.FogColor = S.SkyStatic
      end
    end
  end

  local RainbowModes = {
    Rainbow = {0.005, function(h) return Color3.fromHSV(h, 0.9, 1) end},
    RainbowFast = {0.025, function(h) return Color3.fromHSV(h, 1, 1) end},
    RainbowFlash = {0.1, function(h) return Color3.fromHSV(h, 1, 1) end},
    RainbowPastel = {0.004, function(h) return Color3.fromHSV(h, 0.45, 1) end},
    RainbowNeon = {0.008, function(h) return Color3.fromHSV(h, 1, 1) end},
    RainbowDark = {0.005, function(h) return Color3.fromHSV(h, 0.9, 0.4) end},
    RainbowIce = {0.006, function(h) return Color3.fromHSV(0.45 + (h * 0.3), 0.85, 1) end},
    RainbowFire = {0.006, function(h) return Color3.fromHSV(h * 0.16, 1, 1) end},
  }

  local skyHue = 0
  table.insert(Win.Conns, RunService.Heartbeat:Connect(function(dt)
    local cfg = RainbowModes[S.SkyMode]
    if cfg and not S.Disco then
      skyHue = (skyHue + cfg[1] * dt * 60) % 1
      local c = cfg[2](skyHue)
      Lighting.OutdoorAmbient = c
      Lighting.Ambient = c
      Lighting.FogColor = c
    end
  end))

  local HiddenSky = {}

  local function hideGameSky()
    for _, v in ipairs(Lighting:GetChildren()) do
      if (v:IsA("Sky") or v:IsA("Atmosphere")) and not string.find(v.Name, "Shin_") then
        table.insert(HiddenSky, v)
        v.Parent = nil
      end
    end
  end

  local function restoreGameSky()
    for _, v in ipairs(HiddenSky) do
      pcall(function()
        v.Parent = Lighting
      end)
    end
    table.clear(HiddenSky)
  end

  local function resetSky()
    local was666 = S.Sky666
    S.SkyToken += 1
    S.Sky666 = false
    S.SkyMode = "Normal"
    S.SkyStatic = nil
    for _, v in ipairs(Lighting:GetChildren()) do
      if v:IsA("Sky") and string.find(v.Name, "Shin_") then
        v:Destroy()
      end
    end
    restoreGameSky()
    Lighting.ClockTime = OriginalLighting.ClockTime
    if not S.Disco then
      Lighting.OutdoorAmbient = OriginalLighting.OutdoorAmbient
      Lighting.Ambient = OriginalLighting.Ambient
      Lighting.FogColor = OriginalLighting.FogColor
    end
    if was666 then
      task.spawn(function()
        local n = 0
        for _, v in pairs(workspace:GetDescendants()) do
          if v:IsA("Texture") and v.Name == "Avatar666Texture" then
            v:Destroy()
          end
          n += 1
          if n % 1500 == 0 then
            task.wait()
          end
        end
      end)
    end
  end

  local function makeEmptySky(name)
    local sky = Instance.new("Sky")
    sky.Name = name
    sky.SkyboxBk = ""
    sky.SkyboxDn = ""
    sky.SkyboxFt = ""
    sky.SkyboxLf = ""
    sky.SkyboxRt = ""
    sky.SkyboxUp = ""
    sky.Parent = Lighting
  end

  local function applySkyColor(color, mode)
    resetSky()
    hideGameSky()
    S.SkyMode = mode or "Static"
    S.SkyStatic = color
    makeEmptySky("Shin_CustomSky")
    if S.SkyMode == "Static" and color and not S.Disco then
      Lighting.OutdoorAmbient = color
      Lighting.Ambient = color
      Lighting.FogColor = color
    end
  end

  local AvatarAsset = ""
  task.spawn(function()
    pcall(function()
      AvatarAsset = Players:GetUserThumbnailAsync(Player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
    end)
  end)

  local function enable666Sky()
    resetSky()
    hideGameSky()
    S.Sky666 = true
    S.SkyMode = "Static"
    S.SkyStatic = Color3.fromRGB(0, 0, 0)
    Lighting.ClockTime = 0
    Lighting.OutdoorAmbient = Color3.fromRGB(0, 0, 0)
    Lighting.Ambient = Color3.fromRGB(0, 0, 0)
    makeEmptySky("Shin_Sky666")
    local token = S.SkyToken
    task.spawn(function()
      if AvatarAsset == "" then
        return
      end
      local n = 0
      for _, obj in pairs(workspace:GetDescendants()) do
        if S.SkyToken ~= token then
          return
        end
        if obj:IsA("BasePart") and not obj:IsDescendantOf(workspace.Terrain) then
          local model = obj:FindFirstAncestorOfClass("Model")
          if not (model and model:FindFirstChildOfClass("Humanoid")) then
            pcall(function()
              for _, face in pairs(Enum.NormalId:GetEnumItems()) do
                local tex = Instance.new("Texture")
                tex.Name = "Avatar666Texture"
                tex.Texture = AvatarAsset
                tex.Face = face
                tex.Parent = obj
              end
            end)
          end
        end
        n += 1
        if n % 400 == 0 then
          task.wait()
        end
      end
    end)
  end

  local function updatePlayerEsp()
    pcall(function()
      if S.PlayerEsp then
        for _, p in pairs(Players:GetPlayers()) do
          if p ~= Player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            if not p.Character:FindFirstChild("Shin_PlayerESP") then
              local hl = Instance.new("Highlight")
              hl.Name = "Shin_PlayerESP"
              hl.FillColor = Color3.fromRGB(255, 0, 0)
              hl.OutlineColor = Color3.fromRGB(255, 255, 255)
              hl.Parent = p.Character
            end
          end
        end
      else
        for _, p in pairs(Players:GetPlayers()) do
          if p.Character and p.Character:FindFirstChild("Shin_PlayerESP") then
            p.Character.Shin_PlayerESP:Destroy()
          end
        end
      end
    end)
  end

  task.spawn(function()
    while alive do
      task.wait(0.4)
      if S.PlayerEsp then
        updatePlayerEsp()
      end
    end
  end)

  local NpcHighlights = {}

  local function updateNpcEsp()
    pcall(function()
      if S.NpcEsp then
        local n = 0
        for _, v in pairs(workspace:GetDescendants()) do
          if v:IsA("Model") and v:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(v) then
            if not v:FindFirstChild("Shin_NpcESP") then
              local hl = Instance.new("Highlight")
              hl.Name = "Shin_NpcESP"
              hl.FillColor = Color3.fromRGB(0, 255, 100)
              hl.OutlineColor = Color3.fromRGB(255, 255, 255)
              hl.Parent = v
              table.insert(NpcHighlights, hl)
            end
          end
          n += 1
          if n % 2000 == 0 then
            task.wait()
          end
        end
      else
        for _, hl in ipairs(NpcHighlights) do
          if hl and hl.Parent then
            hl:Destroy()
          end
        end
        table.clear(NpcHighlights)
      end
    end)
  end

  task.spawn(function()
    while alive do
      task.wait(1)
      if S.NpcEsp then
        updateNpcEsp()
      end
    end
  end)

  local function getRequest()
    return request or http_request or (syn and syn.request) or (fluxus and fluxus.request)
  end

  local function hopServer(sortOrder, pick, notFoundMsg)
    pcall(function()
      local req = getRequest()
      if not req then
        note("Executor không hỗ trợ request")
        return
      end
      local url = "https://games.roproxy.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=" .. sortOrder .. "&limit=100"
      local res = req({Url = url, Method = "GET"})
      local body = HttpService:JSONDecode(res.Body)
      if body and body.data then
        local target = pick(body.data)
        if target then
          TeleportService:TeleportToPlaceInstance(game.PlaceId, target, Player)
        elseif notFoundMsg then
          note(notFoundMsg)
        end
      end
    end)
  end

  local function myRoot()
    return Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
  end

  local SkyColors = {
    {"Xanh lá", 0, 180, 0}, {"Xanh lá v2", 0, 255, 100}, {"Xanh lá v3", 50, 205, 50}, {"Xanh Mint", 152, 255, 152}, {"Xanh lá chuối", 191, 255, 0}, {"Xanh ngọc bảo", 80, 200, 120},
    {"Đỏ tươi", 255, 30, 40}, {"Đỏ v2", 220, 0, 0}, {"Đỏ v3", 255, 60, 60}, {"Đỏ thẫm", 139, 0, 0}, {"Đỏ huyết dụ", 220, 20, 60},
    {"Xanh dương", 0, 100, 255}, {"Xanh dương v2", 0, 230, 255}, {"Xanh ngọc (Cyan)", 0, 255, 255}, {"Xanh băng", 175, 238, 238}, {"Xanh bầu trời", 135, 206, 235}, {"Xanh hải quân", 0, 0, 128},
    {"Tím", 140, 0, 200}, {"Tím v2", 190, 60, 255}, {"Tím hồng (Magenta)", 255, 0, 255}, {"Tím hoa oải hương", 230, 230, 250}, {"Tím đậm", 138, 43, 226},
    {"Vàng", 255, 255, 0}, {"Vàng chanh", 255, 247, 0}, {"Cam", 255, 130, 0}, {"Cam cháy", 255, 69, 0}, {"Vàng hoàng gia", 255, 215, 0},
    {"Hồng", 255, 120, 180}, {"Hồng đậm", 255, 20, 147}, {"Hồng hoa hồng", 255, 102, 102},
    {"Nâu gỗ", 139, 69, 19}, {"Xám kim loại", 128, 128, 128}, {"Trắng tinh", 255, 255, 255}, {"Đen tuyền", 30, 30, 30},
  }

  local SkyRainbows = {
    {"Cầu vồng mượt", "Rainbow"}, {"Cầu vồng siêu tốc", "RainbowFast"}, {"Cầu vồng nhấp nháy", "RainbowFlash"}, {"Cầu vồng Pastel", "RainbowPastel"},
    {"Cầu vồng Neon sáng", "RainbowNeon"}, {"Cầu vồng huyền bí", "RainbowDark"}, {"Cầu vồng Băng lạnh", "RainbowIce"}, {"Cầu vồng Lửa ấm", "RainbowFire"},
  }

  local Home = Win:AddTab("Trang chủ")
  local Sky = Win:AddTab("Bầu trời")
  local Fx = Win:AddTab("Hiệu ứng")
  local Npc = Win:AddTab("NPC")
  local Srv = Win:AddTab("Hop Sever")
  local Tools = Win:AddTab("Vật phẩm")
  local World = Win:AddTab("Thế giới")
  local Other = Win:AddTab("Khác")
  local Custom = Win:AddTab("Tạo Script lỏ")
  local Prof = Win:AddTab("Hồ sơ")

  Home:AddSection("Bảo vệ")
  Home:AddToggle("Chống kick", true, function(v)
    S.AntiKick = v
  end)
  loaderButton(Home, "Chế độ thần thánh", P("plXEGzy8"))
  loaderButton(Home, "Chống fling", P("LqqBeQtl"))
  Home:AddSection("Tàng hình")
  Home:AddButton("Vô hình", function()
    runRaw(P("N7OhsEzA"))
    Win:Toggle()
  end)
  loaderButton(Home, "Tàng Hình V2", P("FzwFpahi"))
  Home:AddSection("Ánh sáng")
  Home:AddToggle("Xóa sương mù (Client)", false, function(v)
    S.NoFog = v
    if v then
      applyLightingToggles()
    else
      Lighting.FogStart = OriginalLighting.FogStart
      Lighting.FogEnd = OriginalLighting.FogEnd
    end
  end)
  Home:AddToggle("Nhìn trong bóng tối (Client)", false, function(v)
    S.Fullbright = v
    if v then
      applyLightingToggles()
    else
      Lighting.Brightness = OriginalLighting.Brightness
      Lighting.ClockTime = OriginalLighting.ClockTime
      Lighting.GlobalShadows = OriginalLighting.GlobalShadows
      Lighting.FogEnd = OriginalLighting.FogEnd
      if S.SkyMode == "Normal" and not S.Disco then
        Lighting.Ambient = OriginalLighting.Ambient
      end
    end
  end)
  Home:AddSection("Di chuyển")
  Home:AddToggle("Xuyên tường", false, function(v)
    setNoclipState(v)
  end)
  loaderButton(Home, "Bay", P("YQTPy1Fm"))
  loaderButton(Home, "Tốc độ", P("lzKknJTZ"))
  Home:AddToggle("Nhảy vô hạn", false, function(v)
    S.InfJump = v
  end)
  Home:AddSlider("Lực nhảy", 1, 500, 50, function(v)
    local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
    if hum then
      hum.UseJumpPower = true
      hum.JumpPower = v
    end
  end)
  loaderButton(Home, "Đứng trên không", P("YaGjnt4Y"))
  Home:AddToggle("Bẻ khóa camera", false, function(v)
    setCamUnlock(v)
  end)
  loaderButton(Home, "Trạng thái Humanoid", P("cFRMspqN"))
  loaderButton(Home, "The Flash", P("yXPvznQE"))
  loaderButton(Home, "Bay V2", "https://pastefy.app/dKEu5Lm7/raw", true)
  loaderButton(Home, "Tốc Độ V2", "https://pastefy.app/J12Q67va/raw", true)

  local skyToggles = {}
  local skySyncing = false

  local function addSkyToggle(label, key, apply)
    local obj = Sky:AddToggle(label .. " (Client)", false, function(v)
      if skySyncing then
        return
      end
      if v then
        skySyncing = true
        for k, o in pairs(skyToggles) do
          if k ~= key and o.Value then
            o:Set(false)
          end
        end
        skySyncing = false
        apply()
      else
        resetSky()
      end
    end)
    skyToggles[key] = obj
  end

  Sky:AddSection("Đặc biệt")
  addSkyToggle("666", "666", enable666Sky)
  Sky:AddSection("Cầu vồng")
  for _, e in ipairs(SkyRainbows) do
    addSkyToggle(e[1], e[2], function()
      applySkyColor(nil, e[2])
    end)
  end
  Sky:AddSection("Màu tĩnh")
  for _, e in ipairs(SkyColors) do
    local color = Color3.fromRGB(e[2], e[3], e[4])
    addSkyToggle(e[1], "C_" .. e[1], function()
      applySkyColor(color, "Static")
    end)
  end

  Fx:AddSection("Hiệu ứng FE")
  loaderButton(Fx, "Animation siêu tốc", P("lbVyHe4J"))
  Fx:AddToggle("Đá bay", false, function(v)
    setFling("fx", v)
  end)
  Fx:AddSection("Giải trí")
  loaderButton(Fx, "Animation siêu tốc (Giải trí)", P("lbVyHe4J"))
  Fx:AddToggle("Đá bay (Giải trí)", false, function(v)
    setFling("ent", v)
  end)
  loaderButton(Fx, "Trễ giả", P("NBHt0P6E"))

  Plr:AddSection("Công cụ người chơi")
  loaderButton(Plr, "Hitbox người chơi", P("cc6VQvdi"))
  loaderButton(Plr, "Vô hạn (Infinite Yield)", "https://raw.githubusercontent.com/Edgeiy/InfiniteYield/master/source")
  loaderButton(Plr, "Dịch chuyển đến người", P("Sjc6pLeE"))
  loaderButton(Plr, "Theo dõi người chơi", P("tz5XTGmf"))
  loaderButton(Plr, "Aim slient Player", P("8pU8gBVs"))
  loaderButton(Plr, "Tiêu diệt người chơi (Đá Bay)", P("VKHasvm5"))
  Plr:AddButton("Gom người chơi (Client)", function()
    local pRoot = myRoot()
    if pRoot then
      for _, p in pairs(Players:GetPlayers()) do
        if p ~= Player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
          p.Character.HumanoidRootPart.CFrame = pRoot.CFrame * CFrame.new(0, 0, -4)
        end
      end
      note("Đã gom người chơi!")
    end
  end)
  Plr:AddToggle("Định vị người chơi (Client)", false, function(v)
    S.PlayerEsp = v
    updatePlayerEsp()
  end)

  Npc:AddSection("NPC")
  Npc:AddToggle("Định vị NPC (Client)", false, function(v)
    S.NpcEsp = v
    task.spawn(updateNpcEsp)
  end)
  loaderButton(Npc, "Tạo npc", P("hVpEyswQ"))
  loaderButton(Npc, "Aim slient npc", P("EOh2fTig"))
  loaderButton(Npc, "Tiêu diệt NPC", P("wVxzJVn8"))
  Npc:AddButton("Gom tất cả NPC (Client)", function()
    local pRoot = myRoot()
    if pRoot then
      for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(v) then
          local npcRoot = v:FindFirstChild("HumanoidRootPart")
          if npcRoot then
            npcRoot.CFrame = pRoot.CFrame * CFrame.new(0, 0, -5)
          end
        end
      end
      note("Đã gom tất cả NPC!")
    end
  end)
  Npc:AddSection("Tương tác")
  Npc:AddToggle("Tương tác nhanh", false, function(v)
    setFastPrompt(v)
  end)

  Srv:AddSection("Máy chủ")
  Srv:AddButton("Tham gia lại máy chủ", function()
    note("Đang kết nối lại...")
    pcall(function()
      if #Players:GetPlayers() <= 1 then
        TeleportService:Teleport(game.PlaceId, Player)
      else
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Player)
      end
    end)
  end)
  Srv:AddButton("Chuyển máy chủ", function()
    note("Đang tìm máy chủ mới...")
    hopServer("Desc", function(list)
      for _, s in ipairs(list) do
        if s.playing < s.maxPlayers and s.id ~= game.JobId then
          return s.id
        end
      end
    end)
  end)
  Srv:AddButton("Tìm máy chủ ít người", function()
    note("Đang tìm máy chủ ít người...")
    hopServer("Asc", function(list)
      for _, s in ipairs(list) do
        if s.playing > 0 and s.id ~= game.JobId then
          return s.id
        end
      end
    end)
  end)
  Srv:AddButton("Máy chủ VIP (1 người)", function()
    note("Đang tìm máy chủ VIP...")
    hopServer("Asc", function(list)
      for _, s in ipairs(list) do
        if s.playing == 1 and s.id ~= game.JobId then
          return s.id
        end
      end
      for _, s in ipairs(list) do
        if s.playing < 3 and s.id ~= game.JobId then
          return s.id
        end
      end
    end, "Không tìm thấy server 1 người!")
  end)

  Tools:AddSection("Dụng cụ")
  Tools:AddButton("Dụng cụ TP", function()
    local t = Instance.new("Tool")
    t.Name = "TP"
    t.RequiresHandle = false
    t.Parent = Player.Backpack
    t.Activated:Connect(function()
      local hit = Mouse.Hit
      local root = myRoot()
      if hit and root then
        root.CFrame = CFrame.new(hit.Position + Vector3.new(0, 3, 0))
        playSound(6026987522, 0.4)
      end
    end)
    note("Đã lấy dụng cụ TP!")
  end)
  Tools:AddButton("Nhân đôi dụng cụ (Client)", function()
    local character = Player.Character
    if character then
      local currentTool = character:FindFirstChildOfClass("Tool")
      if currentTool then
        currentTool:Clone().Parent = Player.Backpack
        note("Đã nhân đôi dụng cụ!")
      end
    end
  end)
  loaderButton(Tools, "Thả dụng cụ", P("bA6kORwX"))

  World:AddSection("Thế giới")
  loaderButton(World, "Xray (Client)", P("dZBZckua"))
  World:AddToggle("Disco + Tacos Music (Client)", false, function(v)
    setDisco(v)
  end)
  loaderButton(World, "Hồi sinh tại chỗ chết", P("tE5mPYcB"))
  loaderButton(World, "Quan sát thế giới", P("wtwhO5vE"))

  Other:AddSection("Script tổng hợp")
  loaderButton(Other, "Skid 2dev1", "https://raw.githubusercontent.com/Bom2devs/Script/refs/heads/main/Script-Obf-Weren-v0.4-4105025462.txt")
  loaderButton(Other, "Skid 2dev2", "https://raw.githubusercontent.com/Bom2devs/Script/refs/heads/main/Bom2dev-Hub-Old-0852245577.txt")
  loaderButton(Other, "longKiKi hub", "https://raw.githubusercontent.com/longhihilonghihi-hub/ScriptTongHop-/refs/heads/main/MainTongHop.lua")
  loaderButton(Other, "MADE BY ELAINA SKID", P("K2RDuzrf"))
  loaderButton(Other, "Okay script (skid)", "https://okay-scripts-hub-nd9p.onrender.com/raw/okay-hub")
  loaderButton(Other, "Oie Hub", P("CdWSUT1H"))
  loaderButton(Other, "Hoang.tt Gay", "https://voidedx.vercel.app/api/raw?id=vx_2aajo7ct")
  Other:AddSection("Chat")
  Other:AddButton("Gửi lời chào Shin Roblox vào chat", function()
    local msg = "Shin Roblox"
    task.spawn(function()
      pcall(function()
        local ev = game:GetService("ReplicatedStorage"):WaitForChild("DefaultChatSystemChatEvents", 3)
        if ev and ev:FindFirstChild("SayMessageRequest") then
          ev.SayMessageRequest:FireServer(msg, "All")
        end
      end)
    end)
    task.spawn(function()
      pcall(function()
        local tcs = game:GetService("TextChatService")
        if tcs.ChatVersion == Enum.ChatVersion.TextChatService then
          local ch = tcs.TextChannels:WaitForChild("RBXGeneral", 3)
          if ch then
            ch:SendAsync(msg)
          end
        end
      end)
    end)
  end)

  local ScriptFile = "ShinRobloxScript.json"
  local scriptData = {scripts = {}}
  pcall(function()
    if readfile and isfile and isfile(ScriptFile) then
      local ok, dec = pcall(function()
        return HttpService:JSONDecode(readfile(ScriptFile))
      end)
      if ok and type(dec) == "table" then
        scriptData = dec
        if type(scriptData.scripts) ~= "table" then
          scriptData.scripts = {}
        end
      end
    end
  end)

  local function saveScripts()
    pcall(function()
      if writefile then
        writefile(ScriptFile, HttpService:JSONEncode(scriptData))
      end
    end)
  end

  local function runScriptEntry(entry)
    if type(entry) == "function" then
      pcall(entry)
      return
    end
    if type(entry) ~= "string" or not loadstring then
      return
    end
    local chunk = loadstring(entry)
    if chunk then
      local ok, ret = pcall(chunk)
      if ok and type(ret) == "function" then
        pcall(ret)
      end
      return
    end
    local wrapper = loadstring("return function()\n" .. entry .. "\nend")
    if wrapper then
      local ok2, f = pcall(wrapper)
      if ok2 and type(f) == "function" then
        pcall(f)
      end
    end
  end

  local function textInput(tab, placeholder, h, multi)
    local c = card(tab, h)
    return make("TextBox", {
      Size = UDim2.new(1, -20, 1, -12),
      Position = UDim2.fromOffset(10, 6),
      BackgroundTransparency = 1,
      Text = "",
      PlaceholderText = placeholder,
      PlaceholderColor3 = T.Sub,
      TextColor3 = T.Text,
      Font = Enum.Font.Gotham,
      TextSize = 12,
      TextXAlignment = Enum.TextXAlignment.Left,
      TextYAlignment = multi and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
      ClearTextOnFocus = false,
      MultiLine = multi and true or false,
      TextWrapped = multi and true or false,
      ClipsDescendants = true,
      Parent = c,
    })
  end

  Custom:AddSection("Tạo script mới")
  local nameBox = textInput(Custom, "Tên script", 40, false)
  local codeBox = textInput(Custom, "Viết script ở đây", 130, true)
  local listRows = {}
  local rebuildList

  Custom:AddButton("Lưu script", function()
    local code = codeBox.Text
    if code == "" then
      note("Chưa có nội dung script")
      return
    end
    local name = nameBox.Text
    if name == "" then
      name = "Script " .. (#scriptData.scripts + 1)
    end
    table.insert(scriptData.scripts, {Text = {vn = name, en = name}, Script = code})
    saveScripts()
    nameBox.Text = ""
    codeBox.Text = ""
    note("Đã lưu: " .. name)
    rebuildList()
  end)
  Custom:AddSection("Script đã lưu")

  rebuildList = function()
    for _, r in ipairs(listRows) do
      r:Destroy()
    end
    table.clear(listRows)
    for i, v in ipairs(scriptData.scripts) do
      local name = (type(v.Text) == "table") and (v.Text.vn or v.Text.en) or tostring(v.Text or "")
      local c = card(Custom, 44)
      table.insert(listRows, c)
      local _, runHit = gbutton(c, name, Color3.fromRGB(176, 128, 255), Color3.fromRGB(104, 62, 226), UDim2.new(1, -92, 1, -10), UDim2.fromOffset(5, 5))
      local _, delHit = gbutton(c, "Xoá", Color3.fromRGB(255, 96, 140), Color3.fromRGB(176, 40, 90), UDim2.new(0, 70, 1, -10), UDim2.new(1, -77, 0, 5))
      runHit.MouseButton1Click:Connect(function()
        task.spawn(runScriptEntry, v.Script)
      end)
      delHit.MouseButton1Click:Connect(function()
        table.remove(scriptData.scripts, i)
        saveScripts()
        rebuildList()
      end)
    end
  end
  rebuildList()

  local function fmtTime(dt)
    return dt:FormatLocalTime("DD/MM/YYYY HH:mm:ss", "vi-vn")
  end

  local function readRobux()
    local found
    pcall(function()
      for _, d in ipairs(CoreGui:GetDescendants()) do
        if d:IsA("TextLabel") then
          local path = (d.Name .. (d.Parent and d.Parent.Name or "")):lower()
          if path:find("robux") or path:find("currency") then
            local digits = d.Text:gsub("[,%.%s]", "")
            if digits:match("^%d+$") then
              found = d.Text
              return
            end
          end
        end
      end
    end)
    return found
  end

  local function infoRow(label, value)
    local c = card(Prof, 36)
    local cur = value
    local b = make("TextButton", {
      Size = UDim2.new(1, -28, 1, 0),
      Position = UDim2.fromOffset(14, 0),
      BackgroundTransparency = 1,
      AutoButtonColor = false,
      Text = label .. ": " .. tostring(value),
      Font = Enum.Font.GothamMedium,
      TextSize = 12,
      TextColor3 = T.Text,
      TextXAlignment = Enum.TextXAlignment.Left,
      TextTruncate = Enum.TextTruncate.AtEnd,
      Parent = c,
    })
    b.MouseButton1Click:Connect(function()
      local ok = pcall(function()
        local fn = setclipboard or toclipboard or (syn and syn.write_clipboard) or (Clipboard and Clipboard.set)
        assert(fn, "no clipboard")
        fn(tostring(cur))
      end)
      note(ok and ("Đã sao chép: " .. tostring(cur)) or "Không sao chép được")
    end)
    return function(v)
      cur = v
      if b.Parent then
        b.Text = label .. ": " .. tostring(v)
      end
    end
  end

  Prof:AddSection("Thông tin (bấm để sao chép)")
  infoRow("Tên hiển thị", Player.DisplayName)
  infoRow("Tên tài khoản", Player.Name)
  infoRow("ID Roblox", Player.UserId)
  infoRow("ID game", game.PlaceId)
  local setMap = infoRow("Bản đồ", "Đang tải...")
  infoRow("Đăng nhập lúc", fmtTime(DateTime.now()))
  local setCreated = infoRow("Ngày tạo tài khoản", "Đang tải...")
  local setRobux = infoRow("Số Robux", readRobux() or "Không đọc được")

  task.spawn(function()
    local ok, info = pcall(function()
      return MarketplaceService:GetProductInfo(game.PlaceId)
    end)
    setMap((ok and info and info.Name) or (game.Name ~= "" and game.Name or "N/A"))
  end)

  task.spawn(function()
    local ok, dt = pcall(function()
      return DateTime.fromUnixTimestamp(os.time() - Player.AccountAge * 86400)
    end)
    if ok then
      setCreated(fmtTime(dt):sub(1, 10) .. " (~)")
    end
    pcall(function()
      local req = getRequest()
      if not req then
        return
      end
      local res = req({Url = "https://users.roproxy.com/v1/users/" .. Player.UserId, Method = "GET"})
      local body = HttpService:JSONDecode(res.Body)
      if body and body.created then
        setCreated(fmtTime(DateTime.fromIsoDate(body.created)))
      end
    end)
    setRobux(readRobux() or "Không đọc được")
  end)

  Win:OnDestroy(function()
    alive = false
    S.InfJump = false
    S.NoFog = false
    S.Fullbright = false
    S.PlayerEsp = false
    S.NpcEsp = false
    setNoclipState(false)
    Fling.Sources = {}
    flingStop()
    setFastPrompt(false)
    setCamUnlock(false)
    setDisco(false)
    resetSky()
    updatePlayerEsp()
    updateNpcEsp()
    Lighting.FogStart = OriginalLighting.FogStart
    Lighting.FogEnd = OriginalLighting.FogEnd
    Lighting.Brightness = OriginalLighting.Brightness
    Lighting.GlobalShadows = OriginalLighting.GlobalShadows
  end)
end

local Esp = Win:AddTab("ESP")
local Move = Win:AddTab("Di chuyển")
local Plr = Win:AddTab("Người chơi")
local Perf = Win:AddTab("Hiệu năng")
local Style = Win:AddTab("Tuỳ chỉnh")

Esp:AddSection("Nhìn xuyên")
Esp:AddToggle("Bật ESP", false, function(v)
  Flags.Enabled = v
  if v then
    if not hasDrawing then
      Win:Notify("ESP", "Executor không hỗ trợ Drawing", 4)
    else
      Win:Notify("ESP", "Đã bật", 2)
    end
  else
    cleanupAll()
    Win:Notify("ESP", "Đã tắt", 2)
  end
end)

Esp:AddSection("Hiển thị")
Esp:AddToggle("Hộp (Box)", true, function(v)
  Flags.Box = v
end)
Esp:AddToggle("Đường kẻ (Tracer)", true, function(v)
  Flags.Tracer = v
end)
Esp:AddToggle("Khung xương", true, function(v)
  Flags.Skeleton = v
end)
Esp:AddToggle("Vòng đầu", true, function(v)
  Flags.Head = v
end)
Esp:AddToggle("Đếm số người", true, function(v)
  Flags.Counter = v
end)

Esp:AddSection("Hitbox")
Esp:AddToggle("Mở rộng hitbox", true, function(v)
  Flags.Hitbox = v
end)
Esp:AddSlider("Kích thước hitbox", 2, 20, 9, function(v)
  Flags.HitboxSize = v
end)

Esp:AddSection("Phạm vi")
Esp:AddSlider("Khoảng cách tối đa", 100, 2500, 2500, function(v)
  Flags.MaxDist = v
end)

Move:AddSection("Tăng tốc chạy")
Move:AddToggle("Bật tăng tốc", false, function(v)
  Speed.Enabled = v
  Win:Notify("Di chuyển", v and ("Đã bật · tốc độ " .. Speed.Value) or "Đã tắt", 2)
end)
local speedSlider = Move:AddSlider("Tốc độ", MIN_SPEED, MAX_SPEED, Speed.Value, function(v)
  Speed.Value = v
end)
addStepButtons(Move, speedSlider, 1)

Move:AddSection("Tăng nhảy")
Move:AddToggle("Bật tăng nhảy", false, function(v)
  Jump.Enabled = v
  Win:Notify("Di chuyển", v and ("Sức nhảy " .. Jump.Value) or "Đã tắt tăng nhảy", 2)
end)
local jumpSlider = Move:AddSlider("Sức nhảy", 1, 200, Jump.Value, function(v)
  Jump.Value = v
end)
addStepButtons(Move, jumpSlider, 1)
Move:AddToggle("Nhảy vô hạn", false, function(v)
  Jump.Infinite = v
  Win:Notify("Di chuyển", v and "Nhảy vô hạn: bật" or "Nhảy vô hạn: tắt", 2)
end)

Move:AddSection("Xoay trực thăng")
Move:AddToggle("Bật xoay", false, function(v)
  Spin.Enabled = v
end)
local spinSlider = Move:AddSlider("Tốc độ xoay", 1, 100, Spin.Speed, function(v)
  Spin.Speed = v
end)
addStepButtons(Move, spinSlider, 1)

Move:AddSection("Tàng hình")
Move:AddToggle("Tàng hình (chỉ phía bạn)", false, function(v)
  Invis.Enabled = v
  Win:Notify("Tàng hình", v and "Đã bật" or "Đã tắt", 2)
end)
Move:AddLabel("Người khác vẫn thấy nhân vật bạn")

Plr:AddSection("Chọn người chơi")
Plr:AddPlayerList(function(p)
  Target = p
end)
targetInfo = Plr:AddLabel("Mục tiêu: chưa chọn")
targetDetail = Plr:AddLabel("Máu: N/A | Cao: N/A")

Plr:AddSection("Đi tới mục tiêu")
Plr:AddButton("TELE tới mục tiêu", teleToTarget)
Plr:AddToggle("Bay bám theo mục tiêu", false, function(v)
  if v then
    Follow.Enabled = true
    if not Target then
      Win:Notify("Người chơi", "Chưa chọn mục tiêu", 2)
    end
  else
    stopFollow()
  end
end)

local modeCard = card(Plr, 44)
local _, modeHit, modeLbl = gbutton(
  modeCard,
  "Vị trí: Sau lưng",
  Color3.fromRGB(128, 108, 184),
  Color3.fromRGB(76, 60, 120),
  UDim2.new(1, -10, 1, -10),
  UDim2.fromOffset(5, 5)
)
modeHit.MouseButton1Click:Connect(function()
  local i = 1
  for k, m in ipairs(FollowModes) do
    if m[1] == Follow.Mode then
      i = k
    end
  end
  local nxt = FollowModes[i % #FollowModes + 1]
  Follow.Mode = nxt[1]
  modeLbl.Text = "Vị trí: " .. nxt[2]
end)
Plr:AddSlider("Khoảng cách", 0, 50, Follow.Distance, function(v)
  Follow.Distance = v
end)
Plr:AddSlider("Tốc độ bay", 1, 500, Follow.Speed, function(v)
  Follow.Speed = v
end)

Perf:AddSection("Giảm lag")
Perf:AddToggle("FPS Boost (giảm lag mạnh)", false, function(v)
  Boost.Enabled = v
  if v then
    enableBoost()
  else
    disableBoost()
    Win:Notify("FPS Boost", "Đã khôi phục đồ hoạ", 2)
  end
end)
Perf:AddLabel("Tắt bóng, hiệu ứng, hạt, texture, nước, vật liệu")
local fps2 = Perf:AddLabel("FPS: ...")

Style:AddSection("Hiệu ứng kính")
Style:AddSlider("Độ rõ ảnh nền", 0, 100, 22, function(v)
  Win.Bg.ImageTransparency = 1 - v / 100
end)
Style:AddSlider("Độ đậm kính", 0, 100, 38, function(v)
  Win.Tint.BackgroundTransparency = 1 - v / 100
end)
Style:AddToggle("Làm mờ phía sau", true, function(v)
  Win:SetBlur(v)
end)
Style:AddToggle("Hiện ảnh nền", true, function(v)
  Win.Bg.Visible = v
end)
Style:AddSection("Thu gọn")
Style:AddButton("Thu gọn thanh tiêu đề", function()
  Win:SetCollapsed(true)
end)
Style:AddButton("Thu nhỏ thành logo", function()
  Win:Minimize()
end)

installShin(Win, Plr)
local Info = Win:AddTab("Thông tin")

Info:AddSection("Về Shin Roblox")
Info:AddLabel("Shin Roblox · Aurora Glass UI")
Info:AddLabel("RightControl: ẩn / hiện giao diện")
local fps = Info:AddLabel("FPS: ...")

local frames, last = 0, os.clock()
table.insert(Win.Conns, RunService.RenderStepped:Connect(function()
  frames += 1
  local now = os.clock()
  if now - last >= 1 then
    fps:Set("FPS: " .. frames)
    fps2:Set("FPS: " .. frames)
    frames, last = 0, now
  end
end))

Win:Notify("Shin Roblox", "Đã tải giao diện thành công", 3)

--// ============================================================
--//  NEXUS HUB v10  |  RELWX UI + Typer Town Systems (ALL-IN-ONE)
--//  - UI/ธีม/ตั้งค่า/ปุ่มลอย/Stats มาจาก RELWX style
--//  - ระบบฟาร์ม/วาป/ป้องกัน/ตกปลา/Anti-kick จาก Typer Town
--//  - ไม่มี Fluent — ใช้ Toast + Section + Toggle + Slider + Button
--// ============================================================

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")
local StatsService = game:GetService("Stats")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TeleportService = game:GetService("TeleportService")

local UI_FONT = "Montserrat"
local function E(name)
    local ok, v = pcall(function() return Enum.Font[name] end)
    return ok and v or Enum.Font.Gotham
end
local FontFamilies = {
    Montserrat = { R = E("Montserrat"), M = E("MontserratMedium"), B = E("MontserratBold") },
    BuilderSans = { R = E("BuilderSans"), M = E("BuilderSansMedium"), B = E("BuilderSansBold") },
    Gotham = { R = Enum.Font.Gotham, M = Enum.Font.GothamMedium, B = Enum.Font.GothamBold },
}
local FNT = FontFamilies[UI_FONT] or FontFamilies.Gotham

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local SOUND_ON = "rbxasset://sounds/switch.wav"
local SOUND_OFF = "rbxasset://sounds/button.wav"
local SOUND_FALLBACK = "rbxasset://sounds/electronicpingshort.wav"

--==================================================
-- CONFIG
--==================================================
local CONFIG_FILE = "NEXUS_TYPER_Config.json"
local Defaults = {
    UIAccentColor = "#C9CBD3", UIBackgroundColor = "#0A0A0C", UIButtonColor = "#232328",
    FloatingButtonColor = "#101012", FloatingBorderColor = "#E4E4EA", FloatingGlowColor = "#8E8E98",
    -- Farm toggles
    AutoSandwich = false, AutoMangoRice = false, AutoBananaPack = false, AutoKangSom = false,
    AutoIndividual = false, IndividualCrop = "Bread",
    AutoFishing = false, AutoEatDrink = true,
    AutoHopPlayer = true, HopDistance = 60,
    VehicleSpeed = 200, AntiKick = true, AntiAFK = true,
    -- System
    SoundEnabled = true, StatsVisible = true, UIScalePercent = 110,
    LastTab = "Home", WindowVisible = true, Maximized = false,
    CollapsedSections = "", WindowX = 0.5, WindowY = 0.5,
    FloatX = 0.04, FloatY = 0.25, StatsX = 0.5, StatsY = 0.045,
}
local Config = {}
for k, v in pairs(Defaults) do Config[k] = v end
local LoadedFromFile = false

local function LoadConfig()
    if not (isfile and readfile) then return end
    local ok, exists = pcall(isfile, CONFIG_FILE)
    if not (ok and exists) then return end
    pcall(function()
        local data = HttpService:JSONDecode(readfile(CONFIG_FILE))
        if type(data) == "table" then
            for k, v in pairs(Defaults) do
                if type(data[k]) == type(v) then Config[k] = data[k] end
            end
            LoadedFromFile = true
        end
    end)
end
LoadConfig()
for _, k in ipairs({ "WindowX", "WindowY" }) do Config[k] = math.clamp(Config[k], 0.05, 0.95) end
for _, k in ipairs({ "FloatX", "FloatY", "StatsX", "StatsY" }) do Config[k] = math.clamp(Config[k], 0.02, 0.98) end
Config.UIScalePercent = math.clamp(Config.UIScalePercent, 60, 150)

local SaveHooks = {}
local SaveToken = 0
local function Fire(state) for _, h in ipairs(SaveHooks) do pcall(h, state) end end
local function WriteNow()
    if not writefile then return "unsupported" end
    local ok = pcall(function() writefile(CONFIG_FILE, HttpService:JSONEncode(Config)) end)
    return ok and "saved" or "failed"
end
local function SaveConfig(instant)
    SaveToken = SaveToken + 1
    local token = SaveToken
    Fire("saving")
    local function commit()
        if token ~= SaveToken then return end
        local r = WriteNow()
        Fire(r)
        if r == "saved" then
            task.delay(1.8, function() if token == SaveToken then Fire("idle") end end)
        end
    end
    if instant then commit() else task.delay(0.3, commit) end
end
local function SetConfig(key, value)
    if Config[key] == value then return end
    Config[key] = value
    SaveConfig()
end

--==================================================
-- THEME
--==================================================
local function RGB(r, g, b) return Color3.fromRGB(r, g, b) end
local function Lum(c) return 0.299 * c.R + 0.587 * c.G + 0.114 * c.B end
local function Hex(key, fallback)
    local ok, c = pcall(Color3.fromHex, Config[key])
    return ok and c or fallback
end
local Theme = {}
local function ComputeTheme()
    local bg = Hex("UIBackgroundColor", RGB(8, 8, 8))
    local dark = Lum(bg) < 0.5
    local to = dark and Color3.new(1, 1, 1) or Color3.new(0, 0, 0)
    Theme.Bg = bg
    Theme.Surface = bg:Lerp(to, 0.05)
    Theme.Surface2 = bg:Lerp(to, 0.095)
    Theme.Stroke = bg:Lerp(to, 0.17)
    Theme.Text = dark and RGB(244, 244, 244) or RGB(20, 20, 20)
    Theme.Sub = Theme.Text:Lerp(bg, 0.32)
    Theme.Muted = Theme.Text:Lerp(bg, 0.58)
    Theme.Accent = Hex("UIAccentColor", RGB(190, 190, 190))
    Theme.OnAccent = Lum(Theme.Accent) > 0.55 and RGB(15, 15, 15) or RGB(255, 255, 255)
    Theme.Button = Hex("UIButtonColor", RGB(36, 36, 36))
    local h, s, v = Theme.Accent:ToHSV()
    if s < 0.12 then Theme.Accent2 = Theme.Accent:Lerp(Color3.fromRGB(96, 104, 128), 0.6)
    else Theme.Accent2 = Color3.fromHSV((h + 0.12) % 1, s, math.max(v, 0.6)) end
end
ComputeTheme()
local ThemeHooks = {}
local function OnTheme(fn) ThemeHooks[#ThemeHooks + 1] = fn; pcall(fn) end
local function Bind(obj, prop, key) OnTheme(function() obj[prop] = Theme[key] end) end
local function ApplyTheme()
    ComputeTheme()
    for _, fn in ipairs(ThemeHooks) do pcall(fn) end
end

--==================================================
-- HELPERS
--==================================================
local Orders = setmetatable({}, { __mode = "k" })
local function Next(parent) Orders[parent] = (Orders[parent] or 0) + 1; return Orders[parent] end
local function New(cls, props, parent)
    local o = Instance.new(cls)
    for k, v in pairs(props or {}) do o[k] = v end
    o.Parent = parent
    return o
end
local function Corner(p, r) return New("UICorner", { CornerRadius = UDim.new(0, r) }, p) end
local function Stroke(p, c, t, tr)
    return New("UIStroke", { Color = c, Thickness = t or 1, Transparency = tr or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, p)
end
local function Pad(p, l, r, t, b)
    return New("UIPadding", { PaddingLeft = UDim.new(0, l or 0), PaddingRight = UDim.new(0, r or 0),
        PaddingTop = UDim.new(0, t or 0), PaddingBottom = UDim.new(0, b or 0) }, p)
end
local function List(p, pad)
    return New("UIListLayout", { Padding = UDim.new(0, pad or 0), SortOrder = Enum.SortOrder.LayoutOrder }, p)
end
local function Text(p, txt, size, font, color, align)
    local l = New("TextLabel", { BackgroundTransparency = 1, BorderSizePixel = 0, Text = txt or "",
        TextSize = size or 13, Font = font or FNT.R, TextXAlignment = align or Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd }, p)
    if type(color) == "string" then Bind(l, "TextColor3", color)
    elseif color then l.TextColor3 = color end
    return l
end
local function Tween(o, t, props, style, dir)
    local tw = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
    tw:Play()
    return tw
end
local function Apply(o, anim, props)
    if anim then Tween(o, 0.16, props) else for k, v in pairs(props) do o[k] = v end end
end
local function Panel(parent, size, cls)
    local f = New(cls or "Frame", { BorderSizePixel = 0, LayoutOrder = Next(parent) }, parent)
    if cls == "TextButton" then f.Text = ""; f.AutoButtonColor = false end
    if size then f.Size = size end
    Bind(f, "BackgroundColor3", "Surface")
    Corner(f, 12)
    Bind(Stroke(f, Theme.Stroke, 1, 0.4), "Color", "Stroke")
    New("UIGradient", { Color = ColorSequence.new(Color3.new(1,1,1), Color3.new(0.76,0.76,0.76)), Rotation = 90 }, f)
    local hi = New("Frame", { Size = UDim2.new(1, -28, 0, 1), Position = UDim2.fromOffset(14, 0),
        BackgroundColor3 = Color3.new(1,1,1), BackgroundTransparency = 0.9, BorderSizePixel = 0 }, f)
    New("UIGradient", { Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1) }) }, hi)
    return f
end
local function HoverRow(btn)
    local st = btn:FindFirstChildOfClass("UIStroke")
    btn.MouseEnter:Connect(function()
        Tween(btn, 0.12, { BackgroundColor3 = Theme.Surface2 })
        if st then Tween(st, 0.12, { Transparency = 0.05 }) end
    end)
    local sc
    if btn:IsA("GuiButton") then
        sc = New("UIScale", { Scale = 1 }, btn)
        btn.MouseButton1Down:Connect(function() Tween(sc, 0.08, { Scale = 0.982 }) end)
        btn.MouseButton1Up:Connect(function() Tween(sc, 0.18, { Scale = 1 }, Enum.EasingStyle.Back) end)
    end
    btn.MouseLeave:Connect(function()
        Tween(btn, 0.12, { BackgroundColor3 = Theme.Surface })
        if st then Tween(st, 0.12, { Transparency = 0.4 }) end
        if sc then Tween(sc, 0.12, { Scale = 1 }) end
    end)
end
local function AccentGrad(parent, rot)
    local g = New("UIGradient", { Rotation = rot or 0 }, parent)
    OnTheme(function() g.Color = ColorSequence.new(Theme.Accent, Theme.Accent2) end)
    return g
end
local function Tint(parent)
    local t = New("Frame", { Size = UDim2.fromScale(1, 1), BorderSizePixel = 0, BackgroundColor3 = Color3.new(1,1,1) }, parent)
    Corner(t, 12)
    local g = AccentGrad(t, 25)
    g.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 1) })
    return t
end
local function IsPointer(i) return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch end
local function IsMove(i) return i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch end
local function Icon(parent, kind, x, y)
    local box = New("Frame", { Size = UDim2.fromOffset(18, 18), Position = UDim2.fromOffset(x, y), BackgroundTransparency = 1 }, parent)
    local parts = {}
    local function rect(px, py, w, h, r, rot)
        local f = New("Frame", { Size = UDim2.fromOffset(w, h), Position = UDim2.fromOffset(px, py),
            BorderSizePixel = 0, Rotation = rot or 0 }, box)
        Corner(f, r or 1)
        parts[#parts + 1] = { f = f }
        return f
    end
    if kind == "grid" then
        rect(1,1,7,7,2); rect(10,1,7,7,2); rect(1,10,7,7,2); rect(10,10,7,7,2)
    elseif kind == "sliders" then
        rect(1,2,16,2,1); rect(1,8,11,2,1); rect(1,14,14,2,1)
    elseif kind == "close" then
        rect(1,8,16,2,1,45); rect(1,8,16,2,1,-45)
    elseif kind == "max" then
        local r = New("Frame", { Size = UDim2.fromOffset(12,12), Position = UDim2.fromOffset(3,3), BackgroundTransparency = 1, BorderSizePixel = 0 }, box)
        Corner(r, 3)
        parts[#parts + 1] = { stroke = Stroke(r, Color3.new(1,1,1), 2, 0) }
    else
        local r = New("Frame", { Size = UDim2.fromOffset(16,16), Position = UDim2.fromOffset(1,1), BackgroundTransparency = 1, BorderSizePixel = 0 }, box)
        Corner(r, 8)
        parts[#parts + 1] = { stroke = Stroke(r, Color3.new(1,1,1), 2, 0) }
        rect(7, 7, 4, 4, 2)
    end
    return function(c)
        for _, p in ipairs(parts) do
            if p.stroke then p.stroke.Color = c else p.f.BackgroundColor3 = c end
        end
    end
end
--==================================================
-- ROOT GUI
--==================================================
pcall(function()
    for _, v in ipairs(PlayerGui:GetChildren()) do
        if v.Name:match("^NEXUS_") or v.Name:match("^RELWX_") then v:Destroy() end
    end
end)
local Screen = New("ScreenGui", { Name = "NEXUS_UI", ResetOnSpawn = false, IgnoreGuiInset = true,
    DisplayOrder = 999998, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, PlayerGui)
local Conns = {}
local function Track(c) Conns[#Conns + 1] = c; return c end
Screen.Destroying:Connect(function() for _, c in ipairs(Conns) do pcall(function() c:Disconnect() end) end end)

local BW, BH = 900, 660
local SW = 172
local function ViewSize()
    local s = Screen.AbsoluteSize
    if s.X > 0 and s.Y > 0 then return s end
    return workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
end
local function TargetScale()
    local v = ViewSize()
    local fit = math.min(v.X * 0.97 / BW, v.Y * 0.95 / BH)
    local base = math.min(fit * (Config.Maximized and 1 or 0.96), Config.Maximized and 1.5 or 1.25)
    return math.clamp(base * (Config.UIScalePercent / 100), 0.3, math.max(0.3, fit))
end

local Main = New("CanvasGroup", { Name = "Main", Size = UDim2.fromOffset(BW, BH),
    AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(Config.WindowX, Config.WindowY),
    BorderSizePixel = 0, BackgroundTransparency = 0.04, GroupTransparency = 1,
    Active = true, Visible = false }, Screen)
Bind(Main, "BackgroundColor3", "Bg")
Corner(Main, 18)

local function Aurora(key, rot)
    local f = New("Frame", { Size = UDim2.fromScale(1, 1), BorderSizePixel = 0 }, Main)
    Bind(f, "BackgroundColor3", key)
    Corner(f, 18)
    New("UIGradient", { Rotation = rot, Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.82), NumberSequenceKeypoint.new(0.55, 1), NumberSequenceKeypoint.new(1, 1) }) }, f)
end
Aurora("Accent", 35)
Aurora("Accent2", 215)

local Dust = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ClipsDescendants = true }, Main)
for i = 1, 16 do
    local sz = math.random(2, 4)
    local x = math.random()
    local p = New("Frame", { Size = UDim2.fromOffset(sz, sz), Position = UDim2.fromScale(x, 1.05),
        BorderSizePixel = 0, BackgroundTransparency = 0.55 + math.random() * 0.3 }, Dust)
    Corner(p, 2)
    Bind(p, "BackgroundColor3", (i % 2 == 0) and "Accent" or "Accent2")
    TweenService:Create(p, TweenInfo.new(9 + math.random() * 9, Enum.EasingStyle.Linear,
        Enum.EasingDirection.Out, -1, false, math.random() * 5), {
        Position = UDim2.fromScale(math.clamp(x + (math.random() - 0.5) * 0.15, 0, 1), -0.05) }):Play()
end

local MainStroke = Stroke(Main, Color3.new(1,1,1), 1.5, 0)
local MainGrad = New("UIGradient", { Rotation = 0 }, MainStroke)
OnTheme(function()
    MainGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.Stroke), ColorSequenceKeypoint.new(0.35, Theme.Accent),
        ColorSequenceKeypoint.new(0.65, Theme.Accent2), ColorSequenceKeypoint.new(1, Theme.Stroke) })
end)
TweenService:Create(MainGrad, TweenInfo.new(6, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), { Rotation = 360 }):Play()
local MainScale = New("UIScale", { Scale = TargetScale() }, Main)

local Shadow = New("Frame", { Size = UDim2.fromOffset(BW, BH), AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundTransparency = 1, ZIndex = 0, Visible = false }, Screen)
local ShadowScale = New("UIScale", { Scale = 1 }, Shadow)
local ShadowLayers = {}
for i, g in ipairs({ 8, 20, 36, 56 }) do
    local l = New("Frame", { Size = UDim2.new(1, g*2, 1, g*2), Position = UDim2.fromOffset(-g, -g+10),
        BorderSizePixel = 0, BackgroundColor3 = Color3.new(0,0,0) }, Shadow)
    Corner(l, 18 + g)
    ShadowLayers[i] = { f = l, base = 0.82 + i * 0.03 }
end
local ShadowGlow = New("Frame", { Size = UDim2.new(1, 40, 1, 40), Position = UDim2.fromOffset(-20, -20), BorderSizePixel = 0 }, Shadow)
Corner(ShadowGlow, 38)
Bind(ShadowGlow, "BackgroundColor3", "Accent")
ShadowLayers[#ShadowLayers + 1] = { f = ShadowGlow, base = 0.95 }
Track(RunService.RenderStepped:Connect(function()
    local vis = Main.Visible
    Shadow.Visible = vis
    if not vis then return end
    Shadow.Position = Main.Position
    Shadow.Size = Main.Size
    ShadowScale.Scale = MainScale.Scale
    local a = Main.GroupTransparency
    for _, l in ipairs(ShadowLayers) do l.f.BackgroundTransparency = 1 - (1 - l.base) * (1 - a) end
end))

local TopGlow = New("Frame", { Size = UDim2.new(0.8, 0, 0, 1), Position = UDim2.fromScale(0.1, 0), BorderSizePixel = 0 }, Main)
Bind(TopGlow, "BackgroundColor3", "Accent")
New("UIGradient", { Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.15), NumberSequenceKeypoint.new(1, 1) }) }, TopGlow)

local Opening = false
local function ApplyScale(anim)
    if Opening then return end
    if anim and Main.Visible then Tween(MainScale, 0.25, { Scale = TargetScale() }, Enum.EasingStyle.Quint)
    else MainScale.Scale = TargetScale() end
end
Track(Screen:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() ApplyScale(false) end))

local function PlayToggleSound(on, big)
    if not Config.SoundEnabled then return end
    pcall(function()
        local function play(id, vol, sp)
            local s = Instance.new("Sound")
            s.SoundId = id; s.Volume = vol; s.PlaybackSpeed = sp
            s.Parent = SoundService
            s:Play()
            Debris:AddItem(s, 2.5)
            return s
        end
        local speed = (on and 1.18 or 0.86) * (big and 0.85 or 1)
        local s = play(on and SOUND_ON or SOUND_OFF, big and 0.7 or 0.6, speed)
        task.delay(0.35, function()
            if s.Parent and s.TimeLength == 0 then play(SOUND_FALLBACK, 0.55, on and 1.35 or 0.85) end
        end)
    end)
end

local function FloatCenter()
    local s = Screen.AbsoluteSize
    return s.X * Config.FloatX, s.Y * Config.FloatY
end
local function FxRing(cx, cy, size, thick, dur, color)
    local r = New("Frame", { Size = UDim2.fromOffset(6, 6), AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromOffset(cx, cy), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 60 }, Screen)
    Corner(r, 9999)
    local st = Stroke(r, color or Theme.Accent, thick, 0.05)
    Tween(r, dur, { Size = UDim2.fromOffset(size, size) }, Enum.EasingStyle.Quint)
    Tween(st, dur, { Transparency = 1, Thickness = 0.5 }, Enum.EasingStyle.Quad)
    Debris:AddItem(r, dur + 0.15)
end
local function FxSparks(cx, cy, spread, count, dist)
    for i = 1, count do
        local ang = math.random() * math.pi * 2
        local d = dist * (0.45 + math.random() * 0.8)
        local sz = math.random(3, 6)
        local px = cx + (math.random() - 0.5) * spread
        local col = (i % 3 == 0) and Color3.new(1,1,1) or ((i % 2 == 0) and Theme.Accent or Theme.Accent2)
        local p = New("Frame", { Size = UDim2.fromOffset(sz, sz), AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromOffset(px, cy), BorderSizePixel = 0, BackgroundColor3 = col, ZIndex = 61 }, Screen)
        Corner(p, 3)
        local dur = 0.45 + math.random() * 0.45
        Tween(p, dur, { Position = UDim2.fromOffset(px + math.cos(ang) * d, cy + math.sin(ang) * d * 0.85),
            BackgroundTransparency = 1, Size = UDim2.fromOffset(1, 1) }, Enum.EasingStyle.Quint)
        Debris:AddItem(p, dur + 0.15)
    end
end
local function FxBeam(cx, cy, w)
    local b = New("Frame", { Size = UDim2.fromOffset(w, 4), AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromOffset(cx, cy), BorderSizePixel = 0, BackgroundColor3 = Color3.new(1,1,1), ZIndex = 62 }, Screen)
    New("UICorner", { CornerRadius = UDim.new(0.5, 0) }, b)
    New("UIGradient", { Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.Accent2), ColorSequenceKeypoint.new(0.5, Color3.new(1,1,1)),
        ColorSequenceKeypoint.new(1, Theme.Accent) }) }, b)
    Stroke(b, Theme.Accent, 5, 0.65)
    Debris:AddItem(b, 2)
    return b
end
local AnimToken = 0
local function PlayOpen()
    AnimToken = AnimToken + 1
    local token = AnimToken
    Opening = true
    local t = TargetScale()
    local fx, fy = FloatCenter()
    MainStroke.Thickness = 1.5
    Main.Size = UDim2.fromOffset(BW, BH)
    Main.Position = UDim2.fromOffset(fx, fy)
    Main.GroupTransparency = 1
    MainScale.Scale = t * 0.12
    Main.Visible = true
    PlayToggleSound(true, true)
    FxRing(fx, fy, 120, 3, 0.55)
    FxSparks(fx, fy, 6, 12, 60)
    Tween(Main, 0.3, { GroupTransparency = 0 })
    Tween(Main, 0.6, { Position = UDim2.fromScale(Config.WindowX, Config.WindowY) }, Enum.EasingStyle.Quint)
    Tween(MainScale, 0.65, { Scale = t }, Enum.EasingStyle.Back)
    task.delay(0.68, function() if token == AnimToken then Opening = false end end)
end
local function PlayClose()
    AnimToken = AnimToken + 1
    local token = AnimToken
    Opening = true
    PlayToggleSound(false, true)
    local s0 = MainScale.Scale
    local function alive() return token == AnimToken end
    Tween(MainScale, 0.14, { Scale = s0 * 1.03 }, Enum.EasingStyle.Sine)
    Tween(MainStroke, 0.3, { Thickness = 3.5 }, Enum.EasingStyle.Sine)
    task.delay(0.14, function()
        if not alive() then return end
        Tween(Main, 0.36, { Size = UDim2.fromOffset(BW, 5) }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        Tween(MainScale, 0.36, { Scale = s0 * 0.97 }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
    end)
    task.delay(0.5, function()
        if not alive() then return end
        local ap, asz = Main.AbsolutePosition, Main.AbsoluteSize
        local cx, cy = ap.X + asz.X / 2, ap.Y + asz.Y / 2
        local w = math.max(asz.X, 40)
        Main.Visible = false
        Main.Size = UDim2.fromOffset(BW, BH)
        Main.Position = UDim2.fromScale(Config.WindowX, Config.WindowY)
        MainScale.Scale = s0
        MainStroke.Thickness = 1.5
        local beam = FxBeam(cx, cy, w)
        FxRing(cx, cy, w * 0.75, 3, 0.6)
        FxSparks(cx, cy, w, 28, 150 * math.max(s0, 0.6))
        Tween(beam, 0.26, { Size = UDim2.fromOffset(18, 18) }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        task.delay(0.28, function()
            local fx, fy = FloatCenter()
            Tween(beam, 0.36, { Position = UDim2.fromOffset(fx, fy), Size = UDim2.fromOffset(8, 8) }, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut)
            task.delay(0.36, function()
                beam:Destroy()
                FxRing(fx, fy, 100, 3, 0.55)
                FxSparks(fx, fy, 6, 12, 50)
                if alive() then Opening = false end
            end)
        end)
    end)
end
local function SetWindow(visible)
    SetConfig("WindowVisible", visible)
    if visible then PlayOpen() else PlayClose() end
end

local function SavePosition(target, kx, ky)
    local s = Screen.AbsoluteSize
    if s.X <= 0 or s.Y <= 0 then return end
    local c = target.AbsolutePosition + target.AbsoluteSize / 2
    local fx = math.clamp(c.X / s.X, 0.02, 0.98)
    local fy = math.clamp(c.Y / s.Y, 0.02, 0.98)
    target.Position = UDim2.fromScale(fx, fy)
    SetConfig(kx, math.floor(fx * 10000) / 10000)
    SetConfig(ky, math.floor(fy * 10000) / 10000)
end
local function MakeDraggable(handle, target, kx, ky, onClick)
    local dragging, dragInput, startPos, startCenter, moved = false, nil, nil, nil, false
    handle.InputBegan:Connect(function(input)
        if IsPointer(input) then
            dragging = true; moved = false; dragInput = input
            startPos = input.Position
            startCenter = target.AbsolutePosition + target.AbsoluteSize / 2
        end
    end)
    Track(UIS.InputChanged:Connect(function(input)
        if not dragging or not IsMove(input) then return end
        if input.UserInputType == Enum.UserInputType.Touch and input ~= dragInput then return end
        local d = input.Position - startPos
        if d.Magnitude > 8 then moved = true end
        if moved then
            local s = Screen.AbsoluteSize
            target.Position = UDim2.fromOffset(math.clamp(startCenter.X + d.X, 0, s.X), math.clamp(startCenter.Y + d.Y, 0, s.Y))
        end
    end))
    Track(UIS.InputEnded:Connect(function(input)
        if dragging and IsPointer(input) then
            if input.UserInputType == Enum.UserInputType.Touch and input ~= dragInput then return end
            dragging = false
            if moved then SavePosition(target, kx, ky) elseif onClick then onClick() end
        end
    end))
end

local ActiveToast
function Toast(text, on)
    if ActiveToast then ActiveToast:Destroy(); ActiveToast = nil end
    local t = New("TextLabel", { Size = UDim2.fromOffset(0, 38), AutomaticSize = Enum.AutomaticSize.X,
        AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 48),
        BorderSizePixel = 0, Text = text, TextSize = 12, Font = FNT.M,
        BackgroundColor3 = Theme.Surface2, TextColor3 = Theme.Text, ZIndex = 300 }, Screen)
    Corner(t, 19)
    Stroke(t, Theme.Accent, 1, 0.55)
    Pad(t, 38, 18, 0, 0)
    local dot = New("Frame", { Size = UDim2.fromOffset(8, 8), Position = UDim2.new(0, -24, 0.5, -4),
        BorderSizePixel = 0, BackgroundColor3 = (on == true) and RGB(70, 200, 120) or (on == false and Theme.Muted or Theme.Accent) }, t)
    Corner(dot, 4)
    ActiveToast = t
    Tween(t, 0.35, { Position = UDim2.new(0.5, 0, 1, -26) }, Enum.EasingStyle.Back)
    task.delay(1.7, function()
        if ActiveToast == t then
            Tween(t, 0.25, { Position = UDim2.new(0.5, 0, 1, 48) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            task.delay(0.3, function() t:Destroy(); if ActiveToast == t then ActiveToast = nil end end)
        end
    end)
end

-- Save pill
local SaveStates = {
    idle = { "Auto Save", nil },
    saving = { "กำลังบันทึก...", RGB(240, 190, 60) },
    saved = { "บันทึกแล้ว", RGB(70, 200, 120) },
    failed = { "บันทึกไม่ได้", RGB(235, 75, 90) },
    unsupported = { "ไม่รองรับไฟล์", RGB(235, 75, 90) },
}
local function StatusPill(parent, width)
    local pill = New("Frame", { Size = UDim2.fromOffset(width or 108, 26), BorderSizePixel = 0 }, parent)
    Bind(pill, "BackgroundColor3", "Surface2")
    Corner(pill, 13)
    Bind(Stroke(pill, Theme.Stroke, 1, 0.3), "Color", "Stroke")
    local dot = New("Frame", { Size = UDim2.fromOffset(8, 8), Position = UDim2.new(0, 11, 0.5, -4), BorderSizePixel = 0 }, pill)
    Corner(dot, 4)
    local label = Text(pill, "", 10, FNT.M, "Sub")
    label.Position = UDim2.fromOffset(26, 0)
    label.Size = UDim2.new(1, -30, 1, 0)
    local current = "idle"
    local function render()
        local s = SaveStates[current]
        label.Text = s[1]
        dot.BackgroundColor3 = s[2] or Theme.Accent
    end
    OnTheme(render)
    SaveHooks[#SaveHooks + 1] = function(state) current = state; render() end
    return pill
end

-- Stats widget
local StatsGui = New("ScreenGui", { Name = "NEXUS_Stats", ResetOnSpawn = false, DisplayOrder = 999999,
    IgnoreGuiInset = true, Enabled = Config.StatsVisible }, PlayerGui)
local StatsBox = New("Frame", { Size = UDim2.fromOffset(152, 30), AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(Config.StatsX, Config.StatsY), BorderSizePixel = 0,
    BackgroundTransparency = 0.1, Active = true }, StatsGui)
Bind(StatsBox, "BackgroundColor3", "Surface")
Corner(StatsBox, 15)
Bind(Stroke(StatsBox, Theme.Stroke, 1, 0.2), "Color", "Stroke")
local FpsLabel = Text(StatsBox, "", 11, FNT.M, "Sub", Enum.TextXAlignment.Center)
FpsLabel.RichText = true
FpsLabel.Size = UDim2.new(0.5, -1, 1, 0)
local MsLabel = Text(StatsBox, "", 11, FNT.M, "Sub", Enum.TextXAlignment.Center)
MsLabel.RichText = true
MsLabel.Position = UDim2.new(0.5, 1, 0, 0)
MsLabel.Size = UDim2.new(0.5, -1, 1, 0)
local StatsDivider = New("Frame", { Size = UDim2.fromOffset(1, 14), Position = UDim2.new(0.5, 0, 0.5, -7), BorderSizePixel = 0 }, StatsBox)
Bind(StatsDivider, "BackgroundColor3", "Stroke")
MakeDraggable(StatsBox, StatsBox, "StatsX", "StatsY")

local Metrics = { fps = 60, ping = 0 }
do
    local frames, acc = 0, 0
    Track(RunService.RenderStepped:Connect(function(dt)
        frames = frames + 1
        acc = acc + dt
        if acc >= 0.5 then Metrics.fps = math.floor(frames / acc + 0.5); frames, acc = 0, 0 end
    end))
end
local function GetPing()
    local ok, v = pcall(function() return StatsService.Network.ServerStatsItem["Data Ping"]:GetValue() end)
    return (ok and type(v) == "number") and math.floor(v + 0.5) or 0
end
local function Level(value, good, mid, higher)
    local g, m, b = RGB(70,200,120), RGB(240,190,60), RGB(235,75,90)
    if higher then return value >= good and g or (value >= mid and m or b) end
    return value <= good and g or (value <= mid and m or b)
end
local function RefreshStats()
    Metrics.ping = GetPing()
    local fc = Level(Metrics.fps, 50, 30, true)
    local mc = Level(Metrics.ping, 80, 160, false)
    local muted = "#" .. Theme.Muted:ToHex()
    FpsLabel.Text = string.format('<font color="#%s"><b>%d</b></font> <font color="%s">FPS</font>', fc:ToHex(), Metrics.fps, muted)
    MsLabel.Text = string.format('<font color="#%s"><b>%d</b></font> <font color="%s">MS</font>', mc:ToHex(), Metrics.ping, muted)
end

-- Top bar
local Top = New("Frame", { Size = UDim2.new(1, 0, 0, 60), BackgroundTransparency = 1, BorderSizePixel = 0 }, Main)
local TopLine = New("Frame", { Size = UDim2.new(1, -24, 0, 1), Position = UDim2.new(0, 12, 1, -1),
    BorderSizePixel = 0, BackgroundColor3 = Color3.new(1,1,1) }, Top)
do
    local g = AccentGrad(TopLine, 0)
    g.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.95), NumberSequenceKeypoint.new(0.5, 0.15), NumberSequenceKeypoint.new(1, 0.95) })
end
Top.ClipsDescendants = true
local Shine = New("Frame", { Size = UDim2.new(0, 120, 1, 0), Position = UDim2.new(-0.3, 0, 0, 0),
    BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0 }, Top)
New("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.93), NumberSequenceKeypoint.new(1, 1) }) }, Shine)
TweenService:Create(Shine, TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, false, 4), { Position = UDim2.new(1.1, 0, 0, 0) }):Play()

local Badge = New("Frame", { Size = UDim2.fromOffset(34, 34), Position = UDim2.fromOffset(16, 13), BorderSizePixel = 0 }, Top)
Badge.BackgroundColor3 = Color3.new(1,1,1)
AccentGrad(Badge, 45)
Corner(Badge, 10)
Bind(Stroke(Badge, Theme.Accent, 1.5, 0.65), "Color", "Accent")
local BadgeText = Text(Badge, "NX", 13, FNT.B, nil, Enum.TextXAlignment.Center)
BadgeText.Size = UDim2.fromScale(1, 1)
Bind(BadgeText, "TextColor3", "OnAccent")

local Brand = Text(Top, "", 15, FNT.B, "Text")
Brand.RichText = true
OnTheme(function() Brand.Text = 'NEXUS <font color="#' .. Theme.Accent:ToHex() .. '">HUB</font>' end)
Brand.Position = UDim2.fromOffset(60, 10)
Brand.Size = UDim2.new(1, -270, 0, 22)
local BrandSub = Text(Top, tostring(game.Name or ""), 10, FNT.R, "Muted")
BrandSub.Position = UDim2.fromOffset(60, 31)
BrandSub.Size = UDim2.new(1, -270, 0, 16)

local function WindowButton(kind, xOff, danger)
    local b = New("TextButton", { Size = UDim2.fromOffset(32, 32), Position = UDim2.new(1, xOff, 0.5, -16),
        BorderSizePixel = 0, Text = "", AutoButtonColor = false }, Top)
    Corner(b, 10)
    Bind(b, "BackgroundColor3", "Surface2")
    local paint = Icon(b, kind, 7, 7)
    OnTheme(function() paint(Theme.Sub) end)
    b.MouseEnter:Connect(function()
        Tween(b, 0.12, { BackgroundColor3 = danger and RGB(200,70,80) or Theme.Button })
        paint(danger and RGB(255,255,255) or Theme.Text)
    end)
    b.MouseLeave:Connect(function()
        Tween(b, 0.12, { BackgroundColor3 = Theme.Surface2 })
        paint(Theme.Sub)
    end)
    return b
end
local MaxBtn = WindowButton("max", -86, false)
local CloseBtn = WindowButton("close", -48, true)
CloseBtn.MouseButton1Click:Connect(function() SetWindow(false) end)
MakeDraggable(Top, Main, "WindowX", "WindowY")
MaxBtn.MouseButton1Click:Connect(function()
    SetConfig("Maximized", not Config.Maximized)
    SetConfig("WindowX", 0.5)
    SetConfig("WindowY", 0.5)
    Tween(Main, 0.3, { Position = UDim2.fromScale(0.5, 0.5) }, Enum.EasingStyle.Quint)
    ApplyScale(true)
end)

-- Sidebar
local Rail = New("Frame", { Size = UDim2.new(0, SW, 1, -80), Position = UDim2.fromOffset(12, 68), BorderSizePixel = 0 }, Main)
Bind(Rail, "BackgroundColor3", "Surface")
Corner(Rail, 14)
Bind(Stroke(Rail, Theme.Stroke, 1, 0.4), "Color", "Stroke")
local CatList = New("ScrollingFrame", { Size = UDim2.new(1, -16, 1, -80), Position = UDim2.fromOffset(8, 10),
    BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2, ScrollBarImageTransparency = 0.3,
    CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollingDirection = Enum.ScrollingDirection.Y, ElasticBehavior = Enum.ElasticBehavior.Never }, Rail)
Bind(CatList, "ScrollBarImageColor3", "Accent")
List(CatList, 4)
Pad(CatList, 0, 4, 1, 1)

local UserBox = New("Frame", { Size = UDim2.new(1, -16, 0, 52), Position = UDim2.new(0, 8, 1, -60), BorderSizePixel = 0 }, Rail)
Bind(UserBox, "BackgroundColor3", "Surface2")
Corner(UserBox, 12)
local Avatar = New("ImageLabel", { Size = UDim2.fromOffset(34, 34), Position = UDim2.new(0, 9, 0.5, -17),
    BorderSizePixel = 0, Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=60&h=60" }, UserBox)
Corner(Avatar, 17)
Bind(Avatar, "BackgroundColor3", "Button")
Bind(Stroke(Avatar, Theme.Accent, 1.5, 0.2), "Color", "Accent")
Bind(Stroke(UserBox, Theme.Stroke, 1, 0.5), "Color", "Stroke")
local Online = New("Frame", { Size = UDim2.fromOffset(10, 10), Position = UDim2.new(0, 36, 0.5, 7),
    BorderSizePixel = 0, BackgroundColor3 = RGB(70,200,120), ZIndex = 3 }, UserBox)
Corner(Online, 5)
Bind(Stroke(Online, Theme.Surface2, 2, 0), "Color", "Surface2")
local UName = Text(UserBox, LocalPlayer.DisplayName, 12, FNT.B, "Text")
UName.Position = UDim2.fromOffset(52, 9)
UName.Size = UDim2.new(1, -58, 0, 18)
local UTag = Text(UserBox, "@" .. LocalPlayer.Name, 10, FNT.R, "Muted")
UTag.Position = UDim2.fromOffset(52, 27)
UTag.Size = UDim2.new(1, -58, 0, 14)

local Pages, TabList = {}, {}
local function CatGroup(name)
    local l = Text(CatList, name, 10, FNT.B, "Muted")
    l.Size = UDim2.new(1, 0, 0, 26)
    l.LayoutOrder = Next(CatList)
    Pad(l, 10, 0, 6, 0)
    return l
end
local CurrentTab = nil
local function SelectTab(id)
    if not Pages[id] then id = "Home" end
    SetConfig("LastTab", id)
    local changed = id ~= CurrentTab
    CurrentTab = id
    for pid, page in pairs(Pages) do page.Visible = (pid == id) end
    if changed then
        local p = Pages[id]
        p.Position = UDim2.fromOffset(0, 16)
        Tween(p, 0.32, { Position = UDim2.fromOffset(0, 0) }, Enum.EasingStyle.Quint)
    end
    for _, t in ipairs(TabList) do t.active = (t.id == id); t.paint() end
end
local function Category(name, id, iconKind)
    local b = New("TextButton", { Size = UDim2.new(1, 0, 0, 42), BackgroundTransparency = 1,
        BorderSizePixel = 0, Text = "", AutoButtonColor = false, LayoutOrder = Next(CatList) }, CatList)
    Corner(b, 11)
    local bst = Stroke(b, Theme.Accent, 1, 1)
    local ind = New("Frame", { Size = UDim2.fromOffset(3, 8), AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 4, 0.5, 0), BackgroundTransparency = 1, BorderSizePixel = 0 }, b)
    Corner(ind, 2)
    local setIcon = Icon(b, iconKind, 16, 12)
    local lbl = Text(b, name, 13, FNT.M)
    lbl.Position = UDim2.fromOffset(44, 0)
    lbl.Size = UDim2.new(1, -48, 1, 0)
    lbl.TextColor3 = Theme.Sub
    local tab = { id = id, active = false, hover = false }
    function tab.paint()
        Tween(b, 0.15, { BackgroundColor3 = tab.active and Theme.Accent or Theme.Button,
            BackgroundTransparency = tab.active and 0.84 or (tab.hover and 0.5 or 1) })
        Tween(bst, 0.15, { Color = Theme.Accent, Transparency = tab.active and 0.55 or 1 })
        Tween(lbl, 0.15, { TextColor3 = tab.active and Theme.Text or Theme.Sub })
        Tween(ind, 0.15, { BackgroundColor3 = Theme.Accent, BackgroundTransparency = tab.active and 0 or 1,
            Size = tab.active and UDim2.fromOffset(3, 22) or UDim2.fromOffset(3, 8) })
        setIcon(tab.active and Theme.Accent or Theme.Sub)
    end
    TabList[#TabList + 1] = tab
    OnTheme(tab.paint)
    b.MouseEnter:Connect(function() tab.hover = true; tab.paint() end)
    b.MouseLeave:Connect(function() tab.hover = false; tab.paint() end)
    b.MouseButton1Click:Connect(function() SelectTab(id) end)
    return b
end

-- Pages
local Body = New("Frame", { Size = UDim2.new(1, -(SW + 36), 1, -80), Position = UDim2.fromOffset(SW + 24, 68),
    BackgroundTransparency = 1 }, Main)
local function MakePage(id, title, subtitle)
    local page = New("ScrollingFrame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
        BorderSizePixel = 0, ScrollBarThickness = 3, CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y, Visible = false }, Body)
    Bind(page, "ScrollBarImageColor3", "Stroke")
    List(page, 8)
    Pad(page, 0, 8, 0, 14)
    local head = New("Frame", { Size = UDim2.new(1, 0, 0, 60), BackgroundTransparency = 1, LayoutOrder = Next(page) }, page)
    local t = Text(head, title, 22, FNT.B, "Text")
    t.Size = UDim2.new(1, 0, 0, 28)
    local s = Text(head, subtitle or "", 11, FNT.R, "Muted")
    s.Position = UDim2.fromOffset(0, 29)
    s.Size = UDim2.new(1, 0, 0, 18)
    local hb = New("Frame", { Size = UDim2.fromOffset(36, 3), Position = UDim2.fromOffset(0, 53),
        BorderSizePixel = 0, BackgroundColor3 = Color3.new(1,1,1) }, head)
    Corner(hb, 2)
    AccentGrad(hb, 0)
    Pages[id] = page
    return page
end

local Collapsed = {}
for id in string.gmatch(Config.CollapsedSections, "[^|]+") do Collapsed[id] = true end
local function SaveCollapsed()
    local t = {}
    for id, v in pairs(Collapsed) do if v then t[#t + 1] = id end end
    table.sort(t)
    SetConfig("CollapsedSections", table.concat(t, "|"))
end
local SectionsByPage = {}
local CurrentSection = nil
local function Section(page, title)
    local hdr = New("TextButton", { Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1,
        Text = "", AutoButtonColor = false, LayoutOrder = Next(page) }, page)
    local bar = New("Frame", { Size = UDim2.fromOffset(3, 14), Position = UDim2.new(0, 2, 0.5, -7), BorderSizePixel = 0 }, hdr)
    Corner(bar, 2)
    bar.BackgroundColor3 = Color3.new(1,1,1)
    AccentGrad(bar, 90)
    local hl = New("Frame", { Size = UDim2.new(1, -4, 0, 1), Position = UDim2.new(0, 2, 1, -1), BorderSizePixel = 0 }, hdr)
    Bind(hl, "BackgroundColor3", "Stroke")
    New("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) }) }, hl)
    local label = Text(hdr, title, 13, FNT.B, "Text")
    label.Position = UDim2.fromOffset(14, 0)
    label.Size = UDim2.new(1, -44, 1, 0)
    local chev = New("Frame", { Size = UDim2.fromOffset(14, 14), AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(1, -18, 0.5, 0), BackgroundTransparency = 1 }, hdr)
    local c1 = New("Frame", { Size = UDim2.fromOffset(8, 2), Position = UDim2.fromOffset(1, 6), Rotation = 45, BorderSizePixel = 0 }, chev)
    local c2 = New("Frame", { Size = UDim2.fromOffset(8, 2), Position = UDim2.fromOffset(6, 6), Rotation = -45, BorderSizePixel = 0 }, chev)
    Corner(c1, 1); Corner(c2, 1)
    OnTheme(function() c1.BackgroundColor3 = Theme.Muted; c2.BackgroundColor3 = Theme.Muted end)
    local sec = { label = hdr, items = {}, collapsed = Collapsed[title] == true }
    function sec.refresh(anim)
        for _, it in ipairs(sec.items) do it.frame.Visible = it.matched and not sec.collapsed end
        local rot = sec.collapsed and -90 or 0
        if anim then Tween(chev, 0.18, { Rotation = rot }) else chev.Rotation = rot end
    end
    sec.refresh(false)
    hdr.MouseButton1Click:Connect(function()
        sec.collapsed = not sec.collapsed
        Collapsed[title] = sec.collapsed
        SaveCollapsed()
        sec.refresh(true)
    end)
    CurrentSection = sec
    SectionsByPage[page] = SectionsByPage[page] or {}
    table.insert(SectionsByPage[page], sec)
    return sec
end
local function Register(row, search)
    local sec = CurrentSection
    if sec then
        table.insert(sec.items, { frame = row, search = string.lower(search or ""), matched = true })
        sec.refresh(false)
    end
end
local Refreshers = {}
local FuncToggles = {}
local UpdateSummary = function() end

-- Toggle
local function Toggle(page, opts)
    local row = Panel(page, UDim2.new(1, 0, 0, 64), "TextButton")
    HoverRow(row)
    Register(row, opts.title .. " " .. (opts.desc or ""))
    local rowStroke = row:FindFirstChildOfClass("UIStroke")
    local title = Text(row, opts.title, 13, FNT.M, "Text")
    title.Position = UDim2.fromOffset(18, 11)
    title.Size = UDim2.new(1, -96, 0, 20)
    local desc = Text(row, opts.desc or "", 11, FNT.R, "Muted")
    desc.Position = UDim2.fromOffset(18, 33)
    desc.Size = UDim2.new(1, -96, 0, 18)
    local strip = New("Frame", { Size = UDim2.fromOffset(3, 26), Position = UDim2.new(0, 4, 0.5, -13),
        BorderSizePixel = 0, BackgroundColor3 = Color3.new(1,1,1), BackgroundTransparency = 1 }, row)
    Corner(strip, 2); AccentGrad(strip, 90)
    local glow = New("Frame", { Size = UDim2.fromOffset(62, 40), Position = UDim2.new(1, -71, 0.5, -20),
        BorderSizePixel = 0, BackgroundColor3 = Color3.new(1,1,1), BackgroundTransparency = 1 }, row)
    Corner(glow, 20); AccentGrad(glow, 0)
    local track = New("Frame", { Size = UDim2.fromOffset(48, 26), Position = UDim2.new(1, -64, 0.5, -13), BorderSizePixel = 0 }, row)
    Corner(track, 13)
    local tStroke = Stroke(track, Theme.Stroke, 1, 0.2)
    Bind(tStroke, "Color", "Stroke")
    local fill = New("Frame", { Size = UDim2.fromScale(1, 1), BorderSizePixel = 0,
        BackgroundColor3 = Color3.new(1,1,1), BackgroundTransparency = 1 }, track)
    Corner(fill, 13); AccentGrad(fill, 0)
    local knob = New("Frame", { Size = UDim2.fromOffset(20, 20), Position = UDim2.fromOffset(3, 3), BorderSizePixel = 0 }, track)
    Corner(knob, 10)
    local state = Config[opts.key] == true
    if page ~= Pages["Settings"] and page ~= Pages["Home"] then
        FuncToggles[#FuncToggles + 1] = function() return state end
    end
    local function render(anim)
        Apply(track, anim, { BackgroundColor3 = Theme.Button })
        Apply(fill, anim, { BackgroundTransparency = state and 0 or 1 })
        Apply(glow, anim, { BackgroundTransparency = state and 0.82 or 1 })
        Apply(knob, anim, { Position = state and UDim2.fromOffset(25, 3) or UDim2.fromOffset(3, 3),
            BackgroundColor3 = state and Theme.OnAccent or Theme.Sub })
        Apply(strip, anim, { BackgroundTransparency = state and 0 or 1 })
        Apply(tStroke, anim, { Color = state and Theme.Accent or Theme.Stroke })
        if rowStroke then Apply(rowStroke, anim, { Color = state and Theme.Accent or Theme.Stroke, Transparency = state and 0.55 or 0.4 }) end
        UpdateSummary()
    end
    OnTheme(function() render(false) end)
    local function set(v, fire)
        state = v
        SetConfig(opts.key, v)
        render(true)
        if fire then
            PlayToggleSound(v)
            if opts.callback then task.spawn(opts.callback, v) end
        end
    end
    row.MouseButton1Click:Connect(function() set(not state, true) end)
    Refreshers[#Refreshers + 1] = function()
        state = Config[opts.key] == true
        render(false)
        if opts.callback then task.spawn(opts.callback, state) end
    end
    if opts.callback then task.defer(opts.callback, state) end
    return { Get = function() return state end, Set = function(v) set(v, true) end }
end

-- Slider
local function Slider(page, opts)
    local min, max, step = opts.min, opts.max, opts.step or 1
    local row = Panel(page, UDim2.new(1, 0, 0, 78))
    Register(row, opts.title .. " " .. (opts.desc or ""))
    local title = Text(row, opts.title, 13, FNT.M, "Text")
    title.Position = UDim2.fromOffset(16, 10)
    title.Size = UDim2.new(1, -110, 0, 20)
    local desc = Text(row, opts.desc or "", 11, FNT.R, "Muted")
    desc.Position = UDim2.fromOffset(16, 31)
    desc.Size = UDim2.new(1, -110, 0, 16)
    local pill = New("Frame", { Size = UDim2.fromOffset(82, 22), Position = UDim2.new(1, -98, 0, 9), BorderSizePixel = 0 }, row)
    Corner(pill, 11)
    Bind(pill, "BackgroundColor3", "Surface2")
    Bind(Stroke(pill, Theme.Accent, 1, 0.6), "Color", "Accent")
    local val = Text(row, "", 12, FNT.B, "Accent", Enum.TextXAlignment.Center)
    val.Position = UDim2.new(1, -98, 0, 9)
    val.Size = UDim2.fromOffset(82, 22)
    local bar = New("Frame", { Size = UDim2.new(1, -32, 0, 6), Position = UDim2.fromOffset(16, 60), BorderSizePixel = 0 }, row)
    Corner(bar, 3)
    Bind(bar, "BackgroundColor3", "Button")
    local fill = New("Frame", { Size = UDim2.fromScale(0, 1), BorderSizePixel = 0, BackgroundColor3 = Color3.new(1,1,1) }, bar)
    Corner(fill, 3); AccentGrad(fill, 0)
    local knob = New("Frame", { Size = UDim2.fromOffset(16, 16), AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0, 0.5), BorderSizePixel = 0 }, bar)
    Corner(knob, 8)
    Bind(knob, "BackgroundColor3", "Text")
    Bind(Stroke(knob, Theme.Accent, 3, 0), "Color", "Accent")
    local hit = New("TextButton", { Size = UDim2.new(1, -32, 0, 30), Position = UDim2.fromOffset(16, 48),
        BackgroundTransparency = 1, Text = "", AutoButtonColor = false }, row)
    local value = Config[opts.key]
    local function show()
        local a = (value - min) / (max - min)
        fill.Size = UDim2.fromScale(a, 1)
        knob.Position = UDim2.fromScale(a, 0.5)
        val.Text = string.format("%g", value) .. (opts.suffix or "")
    end
    local function setValue(v, fire)
        v = math.clamp(math.floor((v - min) / step + 0.5) * step + min, min, max)
        if v == value and fire then return end
        value = v
        show()
        if fire then
            SetConfig(opts.key, v)
            if opts.callback then task.spawn(opts.callback, v) end
        end
    end
    local dragging = false
    local function fromX(x)
        local a = math.clamp((x - bar.AbsolutePosition.X) / math.max(1, bar.AbsoluteSize.X), 0, 1)
        setValue(min + (max - min) * a, true)
    end
    hit.InputBegan:Connect(function(input)
        if IsPointer(input) then
            dragging = true
            page.ScrollingEnabled = false
            Tween(knob, 0.12, { Size = UDim2.fromOffset(21, 21) })
            fromX(input.Position.X)
        end
    end)
    Track(UIS.InputChanged:Connect(function(input) if dragging and IsMove(input) then fromX(input.Position.X) end end))
    Track(UIS.InputEnded:Connect(function(input)
        if dragging and IsPointer(input) then
            dragging = false
            page.ScrollingEnabled = true
            Tween(knob, 0.12, { Size = UDim2.fromOffset(16, 16) })
        end
    end))
    value = math.clamp(value, min, max)
    show()
    Refreshers[#Refreshers + 1] = function()
        value = math.clamp(Config[opts.key], min, max)
        show()
        if opts.callback then task.spawn(opts.callback, value) end
    end
    if opts.callback then task.defer(opts.callback, value) end
end

-- Button
local function Button(page, opts)
    local row = Panel(page, UDim2.new(1, 0, 0, 60), "TextButton")
    HoverRow(row)
    Register(row, opts.title .. " " .. (opts.desc or ""))
    local t = Text(row, opts.title, 13, FNT.M, "Text")
    t.Position = UDim2.fromOffset(18, 10)
    t.Size = UDim2.new(1, -130, 0, 20)
    local d = Text(row, opts.desc or "", 11, FNT.R, "Muted")
    d.Position = UDim2.fromOffset(18, 32)
    d.Size = UDim2.new(1, -130, 0, 18)
    local pill = New("Frame", { Size = UDim2.fromOffset(78, 30), Position = UDim2.new(1, -94, 0.5, -15),
        BorderSizePixel = 0, BackgroundColor3 = Color3.new(1,1,1) }, row)
    Corner(pill, 15); AccentGrad(pill, 0)
    local pt = Text(pill, opts.text or "RUN", 11, FNT.B, "OnAccent", Enum.TextXAlignment.Center)
    pt.Size = UDim2.fromScale(1, 1)
    row.MouseButton1Click:Connect(function()
        pt.Text = "DONE"
        task.delay(0.8, function() pt.Text = opts.text or "RUN" end)
        if opts.callback then task.spawn(opts.callback) end
    end)
end
--==================================================
-- COLOR PICKER
--==================================================
local PaletteColors = {
    "FFFFFF", "BEBEBE", "6B6B76", "2A2A33", "0E0E14", "000000", "8B5CF6", "6366F1",
    "3B82F6", "22D3EE", "10B981", "84CC16", "FACC15", "FB923C", "EF4444", "EC4899",
}
local ActiveOverlay, ActivePopup
local PaletteConns = {}
local function ClosePalette()
    for _, c in ipairs(PaletteConns) do pcall(function() c:Disconnect() end) end
    PaletteConns = {}
    if ActiveOverlay then ActiveOverlay:Destroy(); ActiveOverlay = nil end
    if ActivePopup then ActivePopup:Destroy(); ActivePopup = nil end
end
local themePending = false
local function QueueTheme()
    if themePending then return end
    themePending = true
    task.defer(function() themePending = false; ApplyTheme() end)
end
local function OpenPalette(title, key, onPick)
    ClosePalette()
    ActiveOverlay = New("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0,0,0),
        BackgroundTransparency = 1, BorderSizePixel = 0, Text = "", AutoButtonColor = false, ZIndex = 150 }, Screen)
    Tween(ActiveOverlay, 0.2, { BackgroundTransparency = 0.45 })
    ActiveOverlay.MouseButton1Click:Connect(ClosePalette)
    local PW, PH = 240, 304
    local pop = New("CanvasGroup", { Size = UDim2.fromOffset(PW, PH), AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = Theme.Surface, BorderSizePixel = 0,
        GroupTransparency = 1, ZIndex = 160, Active = true }, Screen)
    Corner(pop, 16)
    Stroke(pop, Theme.Accent, 1.5, 0.35)
    local vs = ViewSize()
    New("UIScale", { Scale = math.clamp((vs.Y - 24) / PH, 0.5, 1) }, pop)
    ActivePopup = pop
    Tween(pop, 0.2, { GroupTransparency = 0 })
    local okc, c0 = pcall(Color3.fromHex, Config[key])
    if not okc then c0 = Color3.new(1,1,1) end
    local H, S, V = c0:ToHSV()
    local ttl = Text(pop, title or "เลือกสี", 13, FNT.B, Theme.Text)
    ttl.Position = UDim2.fromOffset(14, 10)
    ttl.Size = UDim2.new(1, -130, 0, 20)
    local prev = New("Frame", { Size = UDim2.fromOffset(36, 18), Position = UDim2.fromOffset(PW - 82, 11), BorderSizePixel = 0 }, pop)
    Corner(prev, 6)
    Stroke(prev, Color3.new(1,1,1), 1, 0.75)
    local closeB = New("TextButton", { Size = UDim2.fromOffset(24, 24), Position = UDim2.fromOffset(PW - 38, 8),
        BackgroundColor3 = Theme.Surface2, BorderSizePixel = 0, Text = "×", TextSize = 18,
        Font = FNT.B, TextColor3 = Theme.Sub, AutoButtonColor = false }, pop)
    Corner(closeB, 8)
    closeB.MouseButton1Click:Connect(ClosePalette)
    local sv = New("Frame", { Size = UDim2.fromOffset(PW - 28, 124), Position = UDim2.fromOffset(14, 40),
        BorderSizePixel = 0, BackgroundColor3 = Color3.fromHSV(H, 1, 1) }, pop)
    Corner(sv, 10)
    local wf = New("Frame", { Size = UDim2.fromScale(1, 1), BorderSizePixel = 0, BackgroundColor3 = Color3.new(1,1,1) }, sv)
    Corner(wf, 10)
    New("UIGradient", { Transparency = NumberSequence.new(0, 1) }, wf)
    local bf = New("Frame", { Size = UDim2.fromScale(1, 1), BorderSizePixel = 0, BackgroundColor3 = Color3.new(0,0,0) }, sv)
    Corner(bf, 10)
    New("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0) }, bf)
    local svCur = New("Frame", { Size = UDim2.fromOffset(16, 16), AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1, BorderSizePixel = 0 }, sv)
    Corner(svCur, 8)
    Stroke(svCur, Color3.new(1,1,1), 2.5, 0)
    local svHit = New("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false }, sv)
    local hue = New("Frame", { Size = UDim2.fromOffset(PW - 28, 14), Position = UDim2.fromOffset(14, 176),
        BorderSizePixel = 0, BackgroundColor3 = Color3.new(1,1,1) }, pop)
    Corner(hue, 7)
    New("UIGradient", { Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255,0,0)),
        ColorSequenceKeypoint.new(1/6, Color3.fromRGB(255,255,0)),
        ColorSequenceKeypoint.new(2/6, Color3.fromRGB(0,255,0)),
        ColorSequenceKeypoint.new(3/6, Color3.fromRGB(0,255,255)),
        ColorSequenceKeypoint.new(4/6, Color3.fromRGB(0,0,255)),
        ColorSequenceKeypoint.new(5/6, Color3.fromRGB(255,0,255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255,0,0)) }) }, hue)
    local hueCur = New("Frame", { Size = UDim2.fromOffset(18, 18), AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0 }, hue)
    Corner(hueCur, 9)
    Stroke(hueCur, Color3.new(1,1,1), 2.5, 0)
    local hueHit = New("TextButton", { Size = UDim2.new(1, 0, 1, 12), Position = UDim2.fromOffset(0, -6),
        BackgroundTransparency = 1, Text = "", AutoButtonColor = false }, hue)
    local box = New("TextBox", { Size = UDim2.fromOffset(PW - 28, 30), Position = UDim2.fromOffset(14, 202),
        BackgroundColor3 = Theme.Surface2, BorderSizePixel = 0, Text = "", PlaceholderText = "#RRGGBB",
        ClearTextOnFocus = false, TextSize = 12, Font = FNT.M, TextColor3 = Theme.Text, PlaceholderColor3 = Theme.Muted }, pop)
    Corner(box, 9)
    Stroke(box, Theme.Stroke, 1, 0.3)
    local function render(fromBox)
        local c = Color3.fromHSV(H, S, V)
        sv.BackgroundColor3 = Color3.fromHSV(H, 1, 1)
        svCur.Position = UDim2.fromScale(S, 1 - V)
        hueCur.Position = UDim2.fromScale(H, 0.5)
        hueCur.BackgroundColor3 = Color3.fromHSV(H, 1, 1)
        prev.BackgroundColor3 = c
        if not fromBox then box.Text = "#" .. string.upper(c:ToHex()) end
        return c
    end
    local function commit(fromBox) onPick(render(fromBox)) end
    render(false)
    local function bindDrag(hit, onMove)
        local dragging, dInput = false, nil
        local off = Vector2.zero
        hit.InputBegan:Connect(function(input)
            if not IsPointer(input) then return end
            local p = Vector2.new(input.Position.X, input.Position.Y)
            local a, sz = hit.AbsolutePosition, hit.AbsoluteSize
            local inset = GuiService:GetGuiInset()
            local q = p + inset
            local inside = q.X >= a.X and q.X <= a.X + sz.X and q.Y >= a.Y and q.Y <= a.Y + sz.Y
            off = inside and inset or Vector2.zero
            dragging = true; dInput = input
            onMove(p + off)
        end)
        PaletteConns[#PaletteConns + 1] = UIS.InputChanged:Connect(function(input)
            if dragging and IsMove(input) then
                if input.UserInputType == Enum.UserInputType.Touch and input ~= dInput then return end
                onMove(Vector2.new(input.Position.X, input.Position.Y) + off)
            end
        end)
        PaletteConns[#PaletteConns + 1] = UIS.InputEnded:Connect(function(input)
            if dragging and IsPointer(input) then
                if input.UserInputType == Enum.UserInputType.Touch and input ~= dInput then return end
                dragging = false
            end
        end)
    end
    bindDrag(svHit, function(pos)
        S = math.clamp((pos.X - sv.AbsolutePosition.X) / math.max(1, sv.AbsoluteSize.X), 0, 1)
        V = 1 - math.clamp((pos.Y - sv.AbsolutePosition.Y) / math.max(1, sv.AbsoluteSize.Y), 0, 1)
        commit(false)
    end)
    bindDrag(hueHit, function(pos)
        H = math.clamp((pos.X - hue.AbsolutePosition.X) / math.max(1, hue.AbsoluteSize.X), 0, 1)
        commit(false)
    end)
    box.FocusLost:Connect(function()
        local h = string.match(box.Text, "^%s*#?(%x%x%x%x%x%x)%s*$")
        if h then H, S, V = Color3.fromHex(h):ToHSV(); commit(false)
        else
            box.TextColor3 = RGB(235,75,90)
            task.delay(0.8, function()
                if box.Parent then box.TextColor3 = Theme.Text; render(false) end
            end)
        end
    end)
    for i, hexv in ipairs(PaletteColors) do
        local c = Color3.fromHex(hexv)
        local sw = New("TextButton", { Size = UDim2.fromOffset(22, 22),
            Position = UDim2.fromOffset(14 + ((i-1) % 8) * 27, 244 + math.floor((i-1)/8) * 28),
            BackgroundColor3 = c, BorderSizePixel = 0, Text = "", AutoButtonColor = false }, pop)
        Corner(sw, 11)
        Stroke(sw, Color3.new(1,1,1), 1, 0.8)
        sw.MouseButton1Click:Connect(function() H, S, V = c:ToHSV(); commit(false) end)
    end
end
local ColorRefreshers = {}
local function ColorRow(page, title, key)
    local row = Panel(page, UDim2.new(1, 0, 0, 50), "TextButton")
    HoverRow(row)
    Register(row, title)
    local t = Text(row, title, 12, FNT.M, "Text")
    t.Position = UDim2.fromOffset(18, 0)
    t.Size = UDim2.new(1, -176, 1, 0)
    local hexLabel = Text(row, "", 10, FNT.M, "Muted", Enum.TextXAlignment.Right)
    hexLabel.Position = UDim2.new(1, -152, 0, 0)
    hexLabel.Size = UDim2.fromOffset(84, 50)
    local swatch = New("Frame", { Size = UDim2.fromOffset(44, 24), Position = UDim2.new(1, -60, 0.5, -12), BorderSizePixel = 0 }, row)
    Corner(swatch, 8)
    Stroke(swatch, Color3.new(1,1,1), 1, 0.7)
    local function refresh()
        swatch.BackgroundColor3 = Hex(key, RGB(100,100,100))
        hexLabel.Text = string.upper(tostring(Config[key]))
    end
    refresh()
    Refreshers[#Refreshers + 1] = refresh
    ColorRefreshers[#ColorRefreshers + 1] = refresh
    row.MouseButton1Click:Connect(function()
        OpenPalette(title, key, function(c)
            SetConfig(key, "#" .. string.upper(c:ToHex()))
            refresh()
            QueueTheme()
        end)
    end)
end
local ThemePresets = {
    { "Graphite", "#C9CBD3", "#0A0A0C", "#232328" },
    { "Violet", "#8B5CF6", "#09090D", "#1C1C26" },
    { "Crimson", "#F43F5E", "#0B0708", "#26151A" },
    { "Cyber", "#22D3EE", "#06090C", "#122029" },
    { "Toxic", "#4ADE80", "#060A07", "#13211A" },
    { "Sunset", "#FB923C", "#0C0805", "#271A10" },
}
local function ThemeGrid(page)
    local holder = New("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1, LayoutOrder = Next(page) }, page)
    New("UIGridLayout", { CellSize = UDim2.new(1/3, -7, 0, 56), CellPadding = UDim2.fromOffset(10, 10),
        SortOrder = Enum.SortOrder.LayoutOrder }, holder)
    Register(holder, "ธีม theme preset")
    for _, p in ipairs(ThemePresets) do
        local card = Panel(holder, nil, "TextButton")
        HoverRow(card)
        local function dot(hex, x)
            local d = New("Frame", { Size = UDim2.fromOffset(22, 22), AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, x, 0.5, 0), BorderSizePixel = 0, BackgroundColor3 = Color3.fromHex(hex) }, card)
            Corner(d, 11)
            Stroke(d, Color3.new(1,1,1), 1, 0.8)
        end
        dot(p[3], 12); dot(p[4], 24); dot(p[2], 36)
        local n = Text(card, p[1], 12, FNT.M, "Text")
        n.Position = UDim2.fromOffset(68, 0)
        n.Size = UDim2.new(1, -74, 1, 0)
        card.MouseButton1Click:Connect(function()
            SetConfig("UIAccentColor", p[2]); SetConfig("UIBackgroundColor", p[3]); SetConfig("UIButtonColor", p[4])
            SetConfig("FloatingButtonColor", p[3]); SetConfig("FloatingBorderColor", p[2]); SetConfig("FloatingGlowColor", p[2])
            for _, fn in ipairs(ColorRefreshers) do pcall(fn) end
            QueueTheme()
            Toast("ใช้ธีม " .. p[1])
        end)
    end
end

--==================================================
-- HOME PAGE
--==================================================
local Home = MakePage("Home", "หน้าหลัก", "ภาพรวม • ข้อมูลเซิร์ฟเวอร์ • สถานะ")
local Hero = Panel(Home, UDim2.new(1, 0, 0, 84))
Tint(Hero)
local HeroSub = Text(Hero, "", 11, FNT.M, "Muted")
HeroSub.Position = UDim2.fromOffset(20, 14)
HeroSub.Size = UDim2.new(0.6, 0, 0, 16)
local HeroName = Text(Hero, LocalPlayer.DisplayName, 24, FNT.B, Color3.new(1,1,1))
HeroName.Position = UDim2.fromOffset(20, 32)
HeroName.Size = UDim2.new(0.6, 0, 0, 38)
AccentGrad(HeroName, 0)
local HeroClock = Text(Hero, "", 26, FNT.B, "Text", Enum.TextXAlignment.Right)
HeroClock.Position = UDim2.new(0.5, 0, 0, 16)
HeroClock.Size = UDim2.new(0.5, -20, 0, 34)
local HeroDate = Text(Hero, "", 10, FNT.M, "Muted", Enum.TextXAlignment.Right)
HeroDate.Position = UDim2.new(0.5, 0, 0, 52)
HeroDate.Size = UDim2.new(0.5, -20, 0, 16)
local MapImage = "rbxthumb://type=GameIcon&id=" .. tostring(game.GameId) .. "&w=150&h=150"
local MapCard = Panel(Home, UDim2.new(1, 0, 0, 116))
MapCard.ClipsDescendants = true
local MapBG = New("ImageLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = MapImage,
    ScaleType = Enum.ScaleType.Crop, ImageTransparency = 0.86 }, MapCard)
Corner(MapBG, 12)
local MapFade = New("Frame", { Size = UDim2.fromScale(1, 1), BorderSizePixel = 0 }, MapCard)
Bind(MapFade, "BackgroundColor3", "Surface")
New("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 0.7) }) }, MapFade)
Corner(MapFade, 12)
Tint(MapCard)
local MapIcon = New("ImageLabel", { Size = UDim2.fromOffset(84, 84), Position = UDim2.fromOffset(16, 16),
    BorderSizePixel = 0, Image = MapImage, ScaleType = Enum.ScaleType.Crop }, MapCard)
Corner(MapIcon, 16)
Bind(MapIcon, "BackgroundColor3", "Button")
Bind(Stroke(MapIcon, Theme.Stroke, 1.5, 0.1), "Color", "Stroke")
local MapName = Text(MapCard, tostring(game.Name or "Unknown"), 17, FNT.B, "Text")
MapName.Position = UDim2.fromOffset(112, 16)
MapName.Size = UDim2.new(1, -128, 0, 26)
local MapBy = Text(MapCard, "กำลังโหลด...", 11, FNT.R, "Muted")
MapBy.Position = UDim2.fromOffset(112, 43)
MapBy.Size = UDim2.new(1, -128, 0, 16)
local Chips = New("Frame", { Size = UDim2.new(1, -128, 0, 24), Position = UDim2.fromOffset(112, 72), BackgroundTransparency = 1 }, MapCard)
New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, Chips)
local function Chip(text)
    local c = New("TextLabel", { Size = UDim2.fromOffset(0, 24), AutomaticSize = Enum.AutomaticSize.X,
        BorderSizePixel = 0, Text = text, TextSize = 10, Font = FNT.M, LayoutOrder = Next(Chips) }, Chips)
    Bind(c, "BackgroundColor3", "Surface2")
    Bind(c, "TextColor3", "Sub")
    Corner(c, 12)
    Pad(c, 10, 10, 0, 0)
    return c
end
local ChipPlace = Chip("ID " .. tostring(game.PlaceId))
local ChipPlayers = Chip("ผู้เล่น -/-")
task.spawn(function()
    pcall(function()
        local info = MarketplaceService:GetProductInfo(game.PlaceId)
        if info then
            if info.Name and info.Name ~= "" then MapName.Text = tostring(info.Name); BrandSub.Text = tostring(info.Name) end
            if info.Creator and info.Creator.Name then MapBy.Text = "โดย " .. tostring(info.Creator.Name) else MapBy.Text = "" end
        end
    end)
end)
local function Stat(parent, label, size)
    local c = Panel(parent, size)
    local bar = New("Frame", { Size = UDim2.fromOffset(3, 18), Position = UDim2.fromOffset(0, 12),
        BorderSizePixel = 0, BackgroundColor3 = Color3.new(1,1,1) }, c)
    Corner(bar, 2); AccentGrad(bar, 90)
    local l = Text(c, label, 10, FNT.M, "Muted")
    l.Position = UDim2.fromOffset(16, 11); l.Size = UDim2.new(1, -30, 0, 14)
    local v = Text(c, "-", 14, FNT.B, "Text")
    v.Position = UDim2.fromOffset(16, 30); v.Size = UDim2.new(1, -30, 0, 22)
    return v
end
local Grid = New("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1, LayoutOrder = Next(Home) }, Home)
New("UIGridLayout", { CellSize = UDim2.new(0.5, -5, 0, 64), CellPadding = UDim2.fromOffset(10, 10),
    SortOrder = Enum.SortOrder.LayoutOrder }, Grid)
local StatPlayer = Stat(Grid, "ผู้เล่น")
local StatTime = Stat(Grid, "เวลาในเซิร์ฟ")
local StatFps = Stat(Grid, "FPS")
local StatPing = Stat(Grid, "Ping")
local PerfCard = Panel(Home, UDim2.new(1, 0, 0, 120))
Tint(PerfCard)
local PerfTitle = Text(PerfCard, "ประสิทธิภาพ (FPS)", 12, FNT.B, "Text")
PerfTitle.Position = UDim2.fromOffset(18, 12); PerfTitle.Size = UDim2.new(0.5, 0, 0, 18)
local PerfAvg = Text(PerfCard, "", 11, FNT.M, "Sub", Enum.TextXAlignment.Right)
PerfAvg.Position = UDim2.new(0.5, 0, 0, 12); PerfAvg.Size = UDim2.new(0.5, -18, 0, 18)
local PerfBars = New("Frame", { Size = UDim2.new(1, -36, 0, 68), Position = UDim2.fromOffset(18, 40), BackgroundTransparency = 1 }, PerfCard)
local PERF_N = 36
local PerfBar, PerfHist = {}, {}
for i = 1, PERF_N do
    local b = New("Frame", { Size = UDim2.new(1/PERF_N, -2, 0, 2), AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new((i-1)/PERF_N, 1, 1, 0), BorderSizePixel = 0, BackgroundTransparency = 1 }, PerfBars)
    Corner(b, 2)
    PerfBar[i] = b; PerfHist[i] = 0
end
local function PerfUpdate()
    table.remove(PerfHist, 1)
    PerfHist[#PerfHist + 1] = Metrics.fps
    local peak, sum, cnt = 60, 0, 0
    for _, v in ipairs(PerfHist) do
        if v > peak then peak = v end
        if v > 0 then sum = sum + v; cnt = cnt + 1 end
    end
    for i, v in ipairs(PerfHist) do
        local b = PerfBar[i]
        b.Size = UDim2.new(1/PERF_N, -2, math.clamp(v / peak, 0.04, 1), 0)
        b.BackgroundColor3 = Level(v, 50, 30, true)
        b.BackgroundTransparency = v == 0 and 1 or 0.08
    end
    PerfAvg.Text = "เฉลี่ย " .. tostring(cnt > 0 and math.floor(sum / cnt + 0.5) or 0) .. " FPS"
end
local sessionStart = os.time()
local function RefreshHome()
    local hr = tonumber(os.date("%H")) or 12
    HeroSub.Text = (hr >= 5 and hr < 12 and "อรุณสวัสดิ์") or (hr >= 12 and hr < 17 and "สวัสดีตอนบ่าย")
        or (hr >= 17 and hr < 21 and "สวัสดีตอนเย็น") or "ราตรีสวัสดิ์"
    HeroClock.Text = os.date("%H:%M")
    HeroDate.Text = os.date("%d / %m / %Y")
    local sec = math.max(0, os.time() - sessionStart)
    StatPlayer.Text = LocalPlayer.DisplayName
    StatTime.Text = string.format("%02d:%02d:%02d", math.floor(sec/3600), math.floor((sec%3600)/60), sec%60)
    StatFps.Text = tostring(Metrics.fps)
    StatFps.TextColor3 = Level(Metrics.fps, 50, 30, true)
    StatPing.Text = tostring(Metrics.ping) .. " ms"
    StatPing.TextColor3 = Level(Metrics.ping, 80, 160, false)
    ChipPlayers.Text = string.format("ผู้เล่น %d/%d", #Players:GetPlayers(), Players.MaxPlayers)
    PerfUpdate()
end
task.spawn(function()
    while Screen.Parent do
        RefreshStats(); RefreshHome(); task.wait(0.5)
    end
end)

--==================================================
-- SYSTEMS (จาก Typer Town) — ฝังในไฟล์เดียว
--==================================================
local Sys = {}
Sys.TOWN_CAR_SPAWN = Vector3.new(-311.83, 17.5, 5490.39)
Sys.LOCATIONS = {
    Bread = { Booth = Vector3.new(872.19, 15.90, 4682.54), Farm = Vector3.new(828.31, 11.21, 4817.85) },
    Catchup = { Booth = Vector3.new(1763.23, 14.23, 4206.70), Farm = Vector3.new(1803.05, 12.65, 4236.79) },
    Pig = { Booth = Vector3.new(306.01, 30.77, -1558.06), Farm = Vector3.new(268.61, 28.74, -1513.65) },
    Mango = { Booth = Vector3.new(-1855.59, 20.06, 586.40), Farm = Vector3.new(-1862.26, 17.33, 535.43) },
    Rice = { Booth = Vector3.new(-92.11, 11.46, 89.48), Farm = Vector3.new(-128.87, 11.02, 78.51) },
    Tomato = { Booth = Vector3.new(-2294.10, 31.28, -1273.91), Farm = Vector3.new(-2319.61, 27.21, -1229.19) },
    Banana = { Booth = Vector3.new(-1528.59, 30.34, -1253.46), Farm = Vector3.new(-1545.12, 28.80, -1126.87) },
    Crab = { Booth = Vector3.new(1442.30, 30.56, 613.34), Farm = Vector3.new(1400.27, 28.69, 648.22) },
    Coconut = { Booth = Vector3.new(-1296.67, 10.37, 4216.59), Farm = Vector3.new(-1333.68, 10.87, 4376.67) },
    Food = { Crafting = Vector3.new(3442.48, 56.40, 3925.24), BananaProcess = Vector3.new(3429.20, 56.80, 3911.80) },
    Economy = { Market = Vector3.new(-462.0, 18.0, 5324.7) },
}
Sys.FISHING_PARKING = Vector3.new(-902.46, 3.41, 2964.32)
Sys.FISHING_SPOT = Vector3.new(-972.12, -0.87, 2926.62)
Sys.FISHING_LOOK = Vector3.new(-0.25, 0, -0.97)
Sys.BAIT_SHOP = Vector3.new(-949.31, 16.57, 4861.12)

local MY_CAR = nil
local isConsuming, isHopping, isAutoFishing = false, false, false
local fishingPlatform = nil

-- Anti-Kick
pcall(function()
    local lp = Players.LocalPlayer
    if hookmetamethod then
        local oldNm
        oldNm = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local m = getnamecallmethod()
            if (m == "Kick" or m == "kick") and (self == lp or self == Players) then return nil end
            return oldNm(self, ...)
        end))
    end
    if hookfunction and lp and lp.Kick then
        hookfunction(lp.Kick, newcclosure(function() return nil end))
    end
    local function Neutralize(char)
        if not char then return end
        for _, d in ipairs(char:GetDescendants()) do
            if d:IsA("Script") or d:IsA("LocalScript") then
                local n = d.Name:lower()
                if n:find("antifall") or n:find("fall") or n:find("ragdoll") or n:find("anti") then
                    pcall(function() d.Disabled = true; d:Destroy() end)
                end
            end
        end
    end
    if lp.Character then Neutralize(lp.Character) end
    lp.CharacterAdded:Connect(Neutralize)
end)

local function GetRoot() local c = LocalPlayer.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function GetHum() local c = LocalPlayer.Character; return c and c:FindFirstChildOfClass("Humanoid") end

function Sys.GrantGrace(sec)
    sec = sec or 25
    pcall(function()
        local char = LocalPlayer.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then
            root:SetAttribute("TeleportGrace", os.clock() + sec)
            root:SetAttribute("AntiFallGrace", os.clock() + sec)
            root:SetAttribute("VehicleGrace", os.clock() + sec)
            root:SetAttribute("IgnoreAntiCheat", true)
        end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        end
    end)
end

function Sys.GetGroundLevel(x, z, fallbackY)
    fallbackY = fallbackY or 20
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.IgnoreWater = false
    local filter = {}
    if LocalPlayer.Character then table.insert(filter, LocalPlayer.Character) end
    local veh = (workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Vehicles")) or workspace:FindFirstChild("Vehicles")
    if veh then table.insert(filter, veh) end
    if fishingPlatform then table.insert(filter, fishingPlatform) end
    params.FilterDescendantsInstances = filter
    local r = workspace:Raycast(Vector3.new(x, fallbackY + 150, z), Vector3.new(0, -350, 0), params)
    return r and r.Position.Y or fallbackY
end

function Sys.GetCount(item)
    local pd = LocalPlayer:FindFirstChild("PlayerData")
    if pd then
        local c = pd:GetAttribute(item)
        if typeof(c) == "number" then return c end
    end
    return 0
end

function Sys.GetHunger()
    local hud = PlayerGui:FindFirstChild("HUD")
    local hf = hud and hud:FindFirstChild("Health") and hud.Health:FindFirstChild("Hunger")
    if hf then
        local tl = hf:FindFirstChildWhichIsA("TextLabel", true)
        if tl then
            local v = tonumber(string.match(tl.Text, "%d+"))
            if v then return v end
        end
    end
    local pd = LocalPlayer:FindFirstChild("PlayerData")
    if pd then
        local hv = pd:GetAttribute("Hunger") or pd:GetAttribute("Food")
        if typeof(hv) == "number" then return hv end
    end
    return 100
end

function Sys.GetEnergy()
    local hud = PlayerGui:FindFirstChild("HUD")
    if hud and hud:FindFirstChild("Health") then
        for _, n in ipairs({ "Energy", "Stamina", "Thirst", "Coffee", "Brain" }) do
            local f = hud.Health:FindFirstChild(n)
            if f then
                local tl = f:FindFirstChildWhichIsA("TextLabel", true)
                if tl then
                    local v = tonumber(string.match(tl.Text, "%d+"))
                    if v then return v end
                end
            end
        end
    end
    local pd = LocalPlayer:FindFirstChild("PlayerData")
    if pd then
        local ev = pd:GetAttribute("Energy") or pd:GetAttribute("Stamina") or pd:GetAttribute("Thirst")
        if typeof(ev) == "number" then return ev end
    end
    return 100
end

local function FindFood()
    local pd = LocalPlayer:FindFirstChild("PlayerData")
    for _, f in ipairs({ "Sushi", "RiceKapaoMoo", "MangoRice", "Rice", "Sandwish", "Burger", "Bread", "Onigiri" }) do
        if pd then local c = pd:GetAttribute(f); if typeof(c) == "number" and c > 0 then return f end end
    end
    return nil
end

local function FindDrink()
    local pd = LocalPlayer:FindFirstChild("PlayerData")
    for _, d in ipairs({ "HotCocoa", "Coffee", "HotCoffee", "IcedCoffee", "Cocoa", "Water" }) do
        if pd then local c = pd:GetAttribute(d); if typeof(c) == "number" and c > 0 then return d end end
    end
    return nil
end

function Sys.UseItem(name)
    pcall(function()
        local remCore = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes")
        if remCore then local R = require(remCore); R.Fire("_inventory", "Use", name) end
    end)
end

function Sys.ConsumeItem(name, waitSec)
    if isConsuming or not name then return end
    isConsuming = true
    pcall(function()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        Sys.UseItem(name)
        local tool, t0 = nil, os.clock()
        while os.clock() - t0 < 2.5 do
            char = LocalPlayer.Character
            tool = char and char:FindFirstChild(name)
            if not tool and LocalPlayer:FindFirstChild("Backpack") then
                tool = LocalPlayer.Backpack:FindFirstChild(name)
                if tool and hum then hum:EquipTool(tool) end
            end
            if tool and tool.Parent == char then break end
            task.wait(0.1)
        end
        if tool and char then
            hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                if tool.Parent ~= char then hum:EquipTool(tool); task.wait(0.25) end
                task.wait(0.4)
                tool:Activate()
                local ws = os.clock()
                while os.clock() - ws < (waitSec or 6) do task.wait(0.15) end
                task.wait(0.3)
                pcall(function() hum:UnequipTools() end)
            end
        else task.wait(1.5) end
    end)
    isConsuming = false
end

function Sys.AutoEatDrink(target)
    target = target or 95
    if isConsuming then return end
    for _ = 1, 8 do
        local h, e = Sys.GetHunger(), Sys.GetEnergy()
        if h >= target and e >= target then break end
        local f, d = FindFood(), FindDrink()
        if f and h < target then Toast("🍣 กิน " .. f, true); Sys.ConsumeItem(f, 6); task.wait(0.4) end
        if d and e < target then Toast("☕ ดื่ม " .. d, true); Sys.ConsumeItem(d, 6); task.wait(0.4) end
        task.wait(0.3)
    end
end

function Sys.CheckAutoEat()
    if not Config.AutoEatDrink or isConsuming then return end
    if Sys.GetHunger() <= 75 or Sys.GetEnergy() <= 75 then Sys.AutoEatDrink(95) end
end

function Sys.SmoothWalk(target, timeout, check, stopDist)
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return false end
    timeout = timeout or 50
    stopDist = stopDist or 2.5
    local t0, last, stuck = os.clock(), root.Position, 0
    while (root.Position - target).Magnitude > stopDist and (os.clock() - t0 < timeout) do
        if check and not check() then return false end
        Sys.GrantGrace(5)
        hum:MoveTo(target)
        if (root.Position - last).Magnitude < 0.4 then
            stuck = stuck + 1; if stuck >= 3 then hum.Jump = true; stuck = 0 end
        else stuck = 0 end
        last = root.Position
        task.wait(0.2)
    end
    return (root.Position - target).Magnitude <= 8
end

function Sys.GetNearestBooth(from)
    from = from or (GetRoot() and GetRoot().Position) or Sys.TOWN_CAR_SPAWN
    local best, bd = nil, math.huge
    for _, d in pairs(Sys.LOCATIONS) do
        if d.Booth then
            local dist = (d.Booth - from).Magnitude
            if dist < bd then bd = dist; best = d.Booth end
        end
    end
    local td = (Sys.TOWN_CAR_SPAWN - from).Magnitude
    if td < bd then best = Sys.TOWN_CAR_SPAWN end
    return best or Sys.TOWN_CAR_SPAWN
end

local function IsMyVehicle(v)
    if not v or not v:IsA("Model") or not v.Parent then return false end
    if MY_CAR and v == MY_CAR then return true end
    local hum = GetHum()
    if hum and hum.SeatPart and hum.SeatPart:IsDescendantOf(v) then MY_CAR = v; return true end
    local owner = v:GetAttribute("Owner") or v:GetAttribute("OwnerName")
    if owner and tostring(owner) == LocalPlayer.Name then MY_CAR = v; return true end
    return false
end

function Sys.GetMyCar()
    local hum = GetHum()
    if hum and hum.SeatPart and hum.SeatPart:IsA("VehicleSeat") then
        local v = hum.SeatPart:FindFirstAncestorOfClass("Model")
        if v and IsMyVehicle(v) then return v end
    end
    if MY_CAR and MY_CAR.Parent and IsMyVehicle(MY_CAR) then return MY_CAR end
    return nil
end

function Sys.PressFEnter(car)
    if not car or not IsMyVehicle(car) then return false end
    local hum, root = GetHum(), GetRoot()
    if not hum or not root then return false end
    local seat = car:FindFirstChildWhichIsA("VehicleSeat", true) or car:FindFirstChildWhichIsA("Seat", true)
    if not seat then return false end
    if hum.Sit and hum.SeatPart == seat then MY_CAR = car; return true end
    if hum.Sit then hum.Sit = false; task.wait(0.2) end
    Sys.GrantGrace(20)
    local doorCF = seat.CFrame * CFrame.new(-2.6, 0.2, 0)
    root.CFrame = CFrame.lookAt(doorCF.Position, seat.Position)
    root.AssemblyLinearVelocity = Vector3.zero
    task.wait(0.15)
    local t0 = os.clock()
    while os.clock() - t0 < 3 do
        if hum.Sit then break end
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
            task.wait(0.06)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
        end)
        task.wait(0.2)
    end
    if not hum.Sit then
        pcall(function() root.CFrame = seat.CFrame + Vector3.new(0, 0.5, 0); seat:Sit(hum) end)
        task.wait(0.2)
    end
    if hum.Sit then MY_CAR = car end
    return hum.Sit ~= nil
end

function Sys.ExitCar(car)
    local hum, root = GetHum(), GetRoot()
    if not hum or not root then return end
    if hum.Sit then hum.Sit = false; task.wait(0.12) end
    if car and car.PrimaryPart then
        local right = car.PrimaryPart.CFrame.RightVector
        local exit = car.PrimaryPart.Position - right * 4.2
        local gy = Sys.GetGroundLevel(exit.X, exit.Z, car.PrimaryPart.Position.Y)
        root.CFrame = CFrame.new(exit.X, gy + 1.8, exit.Z)
        root.AssemblyLinearVelocity = Vector3.zero
    end
    task.wait(0.15)
end

function Sys.EnsureCar(pos)
    local car = Sys.GetMyCar()
    if car then return car end
    local root = GetRoot()
    if root and pos then root.CFrame = CFrame.new(pos + Vector3.new(0, 4, 0)); task.wait(0.4) end
    task.wait(0.3)
    car = Sys.GetMyCar()
    if car then MY_CAR = car end
    return car
end

function Sys.DriveCarTo(dest, check)
    local car = Sys.GetMyCar() or Sys.EnsureCar()
    if not car then return false end
    local hum = GetHum()
    if not hum.Sit then Sys.PressFEnter(car) end
    local root = GetRoot()
    if not root then return false end
    local seat = hum.SeatPart
    if not seat or not seat:IsA("VehicleSeat") then return false end
    local t0 = os.clock()
    while (root.Position - dest).Magnitude > 8 and os.clock() - t0 < 60 do
        if check and not check() then
            pcall(function() seat.ThrottleFloat = 0; seat.SteerFloat = 0 end)
            return false
        end
        Sys.GrantGrace(5)
        local dir = (dest - root.Position).Unit
        root.CFrame = CFrame.lookAt(root.Position, root.Position + Vector3.new(dir.X, 0, dir.Z))
        pcall(function() seat.ThrottleFloat = 1; seat.SteerFloat = 0 end)
        task.wait(0.1)
    end
    pcall(function() seat.ThrottleFloat = 0; seat.SteerFloat = 0 end)
    return true
end

local function FindPromptNear(center, maxDist, kw)
    maxDist = maxDist or 25
    local best, bd = nil, maxDist
    local sys = workspace:FindFirstChild("Systems")
    local containers = sys and { sys } or { workspace }
    for _, c in ipairs(containers) do
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("ProximityPrompt") and p.Enabled then
                local pp = p.Parent
                local pos = pp and ((pp:IsA("BasePart") and pp.Position) or (pp:IsA("Attachment") and pp.WorldPosition))
                if pos then
                    local d = (pos - center).Magnitude
                    if d <= bd then
                        if not kw or (p.ActionText and p.ActionText:lower():find(kw:lower())) then
                            best, bd = p, d
                        end
                    end
                end
            end
        end
    end
    return best
end

function Sys.TriggerPrompt(p)
    if not p or not p.Enabled then return end
    pcall(function()
        if fireproximityprompt then fireproximityprompt(p) end
        p:InputHoldBegin()
        task.wait((p.HoldDuration or 0) + 0.1)
        p:InputHoldEnd()
    end)
end

function Sys.HarvestCrop(crop, target, check)
    local loc = Sys.LOCATIONS[crop]
    if not loc then return end
    local root = GetRoot()
    if not root then return end
    if Sys.GetCount(crop) >= target then return end
    Toast("🌾 ฟาร์ม " .. crop, true)
    local car = Sys.GetMyCar() or Sys.EnsureCar(Sys.GetNearestBooth(root.Position))
    if car then
        Sys.PressFEnter(car)
        local px, pz = loc.Farm.X + 4.5, loc.Farm.Z + 4.5
        local gy = Sys.GetGroundLevel(px, pz, loc.Farm.Y)
        Sys.DriveCarTo(Vector3.new(px, gy, pz), check)
        task.wait(0.3)
        Sys.ExitCar(car)
    else Sys.SmoothWalk(loc.Farm, 40, check, 3) end
    task.wait(0.5)
    local gy = Sys.GetGroundLevel(loc.Farm.X, loc.Farm.Z, loc.Farm.Y)
    root.CFrame = CFrame.lookAt(Vector3.new(loc.Farm.X, gy + 2, loc.Farm.Z), Vector3.new(loc.Farm.X - 1, gy + 2, loc.Farm.Z))
    task.wait(0.3)
    local p = FindPromptNear(root.Position, 20)
    if p then Sys.TriggerPrompt(p) end
    task.wait(1.5)
    local t0, cur = os.clock(), Sys.GetCount(crop)
    while cur < target and os.clock() - t0 < 180 do
        if check and not check() then break end
        Sys.GrantGrace(15)
        if Sys.GetHunger() <= 75 or Sys.GetEnergy() <= 75 then Sys.CheckAutoEat() end
        task.wait(0.5)
        local n = Sys.GetCount(crop)
        if n > cur then cur = n; t0 = os.clock() end
        if os.clock() - t0 > 15 and n == cur then
            local pp = FindPromptNear(root.Position, 20)
            if pp then Sys.TriggerPrompt(pp) end
            t0 = os.clock()
        end
    end
    Toast("✅ " .. crop .. " " .. Sys.GetCount(crop) .. "/" .. target, true)
    local booth = Sys.GetNearestBooth(root.Position)
    Sys.SmoothWalk(booth, 45, check, 2.5)
    local c2 = Sys.EnsureCar(booth)
    if c2 then Sys.PressFEnter(c2) end
end

function Sys.SellAll(check)
    local root = GetRoot()
    if not root then return end
    local m = Sys.LOCATIONS.Economy.Market
    local car = Sys.GetMyCar() or Sys.EnsureCar()
    if car then
        Sys.PressFEnter(car)
        Sys.DriveCarTo(m, check)
        task.wait(0.3)
        Sys.ExitCar(car)
    else Sys.SmoothWalk(m, 40, check, 3) end
    local gy = Sys.GetGroundLevel(m.X, m.Z, m.Y)
    root.CFrame = CFrame.lookAt(Vector3.new(m.X + 2.5, gy + 2, m.Z), m)
    task.wait(0.2)
    local p = FindPromptNear(root.Position, 25, "econ") or FindPromptNear(root.Position, 25)
    if p then Sys.TriggerPrompt(p) end
    task.wait(0.4)
    pcall(function()
        local remCore = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes")
        if remCore then local R = require(remCore); R.Invoke("_economy", "SellAll"); R.Fire("_economy", "SellAll") end
    end)
    task.wait(1.0)
    Toast("💰 ขายของทั้งหมดแล้ว", true)
    if Config.AutoEatDrink then Sys.CheckAutoEat() end
    local c = Sys.GetMyCar() or Sys.EnsureCar(Sys.TOWN_CAR_SPAWN)
    if c then Sys.PressFEnter(c) end
end

function Sys.CraftFood(recipe, check)
    local food = Sys.LOCATIONS.Food
    local root = GetRoot()
    if not root then return end
    local car = Sys.GetMyCar() or Sys.EnsureCar()
    if car then
        Sys.PressFEnter(car)
        Sys.DriveCarTo(food.Crafting + Vector3.new(0, 0, 5), check)
        task.wait(0.3)
        Sys.ExitCar(car)
    end
    local gy = Sys.GetGroundLevel(food.Crafting.X, food.Crafting.Z, food.Crafting.Y)
    root.CFrame = CFrame.lookAt(Vector3.new(food.Crafting.X, gy + 3, food.Crafting.Z + 2.5), food.Crafting)
    task.wait(0.2)
    local prompt = nil
    local cs = workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Crafting")
    local c3 = cs and cs:FindFirstChild("Craft_3")
    if c3 then prompt = c3:FindFirstChildWhichIsA("ProximityPrompt", true) end
    if prompt then Sys.TriggerPrompt(prompt) end
    task.wait(1.0)
    local function maxCraft()
        local b, c, p, m, r = Sys.GetCount("Bread"), Sys.GetCount("Catchup"), Sys.GetCount("Pig"), Sys.GetCount("Mango"), Sys.GetCount("Rice")
        if recipe == "Sandwish" then return math.min(math.floor(b/3), math.floor(c/2), math.floor(p/2)) end
        if recipe == "MangoRice" then return math.min(math.floor(m/2), math.floor(r/3)) end
        if recipe == "KangSom" then return math.min(math.floor(Sys.GetCount("Tomato")/2), math.floor(Sys.GetCount("Crab")/2)) end
        return 1
    end
    local n = maxCraft()
    if n <= 0 then Toast("ของไม่พอคราฟ", false); return end
    pcall(function()
        local remCore = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes")
        if remCore then local R = require(remCore); R.Fire("_crafting", "Request", "Craft_3", recipe, n, false) end
    end)
    Toast("🍳 คราฟ " .. recipe .. " x" .. n, true)
    local t0 = os.clock()
    while os.clock() - t0 < 10.5 do
        if check and not check() then break end
        task.wait(0.5)
    end
    pcall(function()
        local remCore = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes")
        if remCore then local R = require(remCore); R.Fire("_crafting", "Complete", "Craft_3", recipe, n, false) end
    end)
    task.wait(0.3)
    local c2 = Sys.GetMyCar() or Sys.EnsureCar()
    if c2 then Sys.PressFEnter(c2) end
end

function Sys.ProcessBanana(check)
    local food = Sys.LOCATIONS.Food
    local root = GetRoot()
    if not root then return end
    local car = Sys.GetMyCar() or Sys.EnsureCar()
    if car then
        Sys.PressFEnter(car)
        Sys.DriveCarTo(food.BananaProcess + Vector3.new(0, 0, 5), check)
        task.wait(0.3)
        Sys.ExitCar(car)
    end
    local gy = Sys.GetGroundLevel(food.BananaProcess.X, food.BananaProcess.Z, food.BananaProcess.Y)
    root.CFrame = CFrame.lookAt(Vector3.new(food.BananaProcess.X, gy + 3, food.BananaProcess.Z + 2.5), food.BananaProcess)
    task.wait(0.3)
    local pb = workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Process") and workspace.Systems.Process:FindFirstChild("Banana")
    local prompt = pb and pb:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt then Sys.TriggerPrompt(prompt) end
    Toast("🍌 แปรรูปกล้วย", true)
    local t0 = os.clock()
    while Sys.GetCount("Banana") >= 2 and os.clock() - t0 < 120 do
        if check and not check() then break end
        task.wait(3.2)
    end
    local c = Sys.GetMyCar() or Sys.EnsureCar()
    if c then Sys.PressFEnter(c) end
end

function Sys.WarpToTown()
    local root = GetRoot()
    if not root then return nil end
    root.CFrame = CFrame.new(Sys.TOWN_CAR_SPAWN + Vector3.new(0, 5, 0))
    Sys.GrantGrace(20)
    task.wait(0.5)
    return Sys.EnsureCar(Sys.TOWN_CAR_SPAWN)
end

function Sys.HopServer(reason)
    if isHopping then return end
    isHopping = true
    Toast("🔄 ย้ายเซิร์ฟเวอร์: " .. tostring(reason), true)
    pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
end

-- Fishing
local function GetRod()
    local char = LocalPlayer.Character
    local bp = LocalPlayer:FindFirstChild("Backpack")
    for _, n in ipairs({ "FishingRodV3", "FishingRodV2", "FishingRod" }) do
        local t = char and char:FindFirstChild(n)
        if t and t:IsA("Tool") then return t end
        t = bp and bp:FindFirstChild(n)
        if t and t:IsA("Tool") then return t end
    end
end

local function EquipRod()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if not char or not hum then return nil end
    local rod = GetRod()
    if rod and rod.Parent == char then return rod end
    if rod and rod.Parent == bp then hum:EquipTool(rod); task.wait(0.3); return rod end
    pcall(function()
        local remCore = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes")
        if remCore then local R = require(remCore); R.Fire("_inventory", "Use", "FishingRod") end
    end)
    task.wait(0.4)
    rod = GetRod()
    if rod and rod.Parent == bp then hum:EquipTool(rod); task.wait(0.2) end
    return rod
end

local function SolveMinigame()
    local pgui = LocalPlayer:FindFirstChild("PlayerGui")
    local fg = pgui and pgui:FindFirstChild("FishingGame")
    if not fg then return false end
    local mg = fg:FindFirstChild("Minigame")
    if not mg then return false end
    local holding = false
    local t0 = os.clock()
    local conn
    conn = RunService.RenderStepped:Connect(function()
        if not isAutoFishing or not fg.Parent then
            if holding then pcall(function() VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game) end) end
            if conn then conn:Disconnect() conn = nil end
            return
        end
        local fish = mg:FindFirstChild("Fish")
        local gameF = mg:FindFirstChild("Game")
        local point = gameF and gameF:FindFirstChild("Point")
        if fish and point then
            local fc = fish.AbsolutePosition.Y + fish.AbsoluteSize.Y * 0.5
            local pc = point.AbsolutePosition.Y + point.AbsoluteSize.Y * 0.5
            if fc < pc - 4 then
                if not holding then holding = true; pcall(function() VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game) end) end
            elseif fc > pc + 4 then
                if holding then holding = false; pcall(function() VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game) end) end
            end
        end
    end)
    while fg.Parent and isAutoFishing and os.clock() - t0 < 30 do
        task.wait(0.05)
        fg = pgui:FindFirstChild("FishingGame")
    end
    if conn then conn:Disconnect() end
    if holding then pcall(function() VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game) end) end
    task.wait(2.0)
    return true
end

function Sys.StartFishing()
    isAutoFishing = true
    task.spawn(function()
        Toast("🎣 เริ่มตกปลา", true)
        while isAutoFishing do
            local root = GetRoot()
            local hum = GetHum()
            if root and hum and hum.Health > 0 then
                local pd = LocalPlayer:FindFirstChild("PlayerData")
                local bait = (pd and (pd:GetAttribute("FishingBait") or pd:GetAttribute("Bait"))) or 0
                local fishCount = ((pd and pd:GetAttribute("Bettafish")) or 0) + ((pd and pd:GetAttribute("Anglerfish")) or 0)
                if bait <= 0 or fishCount >= 25 then
                    local car = Sys.GetMyCar() or Sys.EnsureCar()
                    if car then
                        Sys.PressFEnter(car)
                        Sys.DriveCarTo(Sys.BAIT_SHOP, function() return isAutoFishing end)
                        Sys.ExitCar(car)
                    end
                    Sys.SellAll(function() return isAutoFishing end)
                    pcall(function()
                        local remCore = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes")
                        if remCore then local R = require(remCore); R.Fire("_shop", "Buy", { FishingBait = 100 }, "Money") end
                    end)
                    local c2 = Sys.GetMyCar() or Sys.EnsureCar()
                    if c2 then
                        Sys.PressFEnter(c2)
                        Sys.DriveCarTo(Sys.FISHING_PARKING, function() return isAutoFishing end)
                        Sys.ExitCar(c2)
                    end
                end
                Sys.SmoothWalk(Sys.FISHING_SPOT, 25, function() return isAutoFishing end, 2)
                if hum.Sit then hum.Sit = false end
                local rod = EquipRod()
                if rod and rod.Parent == LocalPlayer.Character then
                    root.CFrame = CFrame.lookAt(Sys.FISHING_SPOT, Sys.FISHING_SPOT + Sys.FISHING_LOOK * 20)
                    task.wait(0.3)
                    pcall(function() rod:Activate() end)
                    task.wait(1.0)
                    local pgui = LocalPlayer:FindFirstChild("PlayerGui")
                    if pgui and pgui:FindFirstChild("FishingGame") then SolveMinigame() end
                end
                task.wait(0.2)
            else task.wait(1) end
        end
        Toast("🛑 หยุดตกปลา", false)
    end)
end

function Sys.StopFishing()
    isAutoFishing = false
end

-- Auto Hop loop
task.spawn(function()
    while true do
        task.wait(0.5)
        if Config.AutoHopPlayer and not isHopping then
            local root = GetRoot()
            if root then
                local dist = Config.HopDistance
                for _, pl in ipairs(Players:GetPlayers()) do
                    if pl ~= LocalPlayer and pl.Character then
                        local oR = pl.Character:FindFirstChild("HumanoidRootPart")
                        local oH = pl.Character:FindFirstChildOfClass("Humanoid")
                        if oR and oH and oH.Health > 0 and (oR.Position - root.Position).Magnitude <= dist then
                            Sys.HopServer("ผู้เล่น @" .. pl.Name)
                            break
                        end
                    end
                end
            end
        end
    end
end)

-- Auto Eat loop
task.spawn(function()
    while true do
        task.wait(3.0)
        if Config.AutoEatDrink and not isConsuming then
            local hum = GetHum()
            if hum and not hum.Sit then Sys.CheckAutoEat() end
        end
    end
end)

--==================================================
-- PAGES ใหม่ (AllIn / Farm / Fishing / Settings)
--==================================================
local AllIn = MakePage("AllIn", "ไก่ตัน ALL-IN-ONE", "เปิดปุ่มเดียว ฟาร์มครบวงจร")
local FarmPage = MakePage("Farm", "ฟาร์มเดี่ยว", "เลือกพืช • ครบ 60 ชิ้น • ขายที่ตลาด")
local Fishing = MakePage("Fishing", "ตกปลาอัตโนมัติ", "เบิกรถ • ซื้อเหยื่อ • ตกปลา • ขายปลา")
local Settings = MakePage("Settings", "ตั้งค่า", "ปรับแต่ง UI • ระบบ • เซฟอัตโนมัติ")

local function StopAllFarms()
    for _, k in ipairs({ "AutoSandwich", "AutoMangoRice", "AutoBananaPack", "AutoKangSom", "AutoIndividual" }) do
        Config[k] = false
    end
    for _, fn in ipairs(Refreshers) do pcall(fn) end
end

local function RequestFarmSession(key)
    for _, k in ipairs({ "AutoSandwich", "AutoMangoRice", "AutoBananaPack", "AutoKangSom", "AutoIndividual" }) do
        if k ~= key then Config[k] = false end
    end
end

local function FarmLoop(key, crops, craftFn)
    while Config[key] do
        for _, crop in ipairs(crops) do
            if not Config[key] then return end
            Sys.HarvestCrop(crop, 60, function() return Config[key] end)
        end
        if not Config[key] then return end
        craftFn(function() return Config[key] end)
        if not Config[key] then return end
        Sys.SellAll(function() return Config[key] end)
    end
end

Section(AllIn, "ลูปครบวงจร")

local function FarmToggle(key, title, desc, crops, craftFn)
    Toggle(AllIn, {
        key = key,
        title = title,
        desc = desc,
        callback = function(v)
            if v then
                RequestFarmSession(key)
                task.spawn(function()
                    Sys.WarpToTown()
                    FarmLoop(key, crops, craftFn)
                end)
            end
        end,
    })
end

FarmToggle("AutoSandwich", "ลูปแซนวิช", "ขนมปัง + ซอส + หมู → แซนวิช → ขาย",
    { "Bread", "Catchup", "Pig" }, function(c) Sys.CraftFood("Sandwish", c) end)
FarmToggle("AutoMangoRice", "ลูปข้าวมันมะม่วง", "มะม่วง + ข้าว → ข้าวมันมะม่วง → ขาย",
    { "Mango", "Rice" }, function(c) Sys.CraftFood("MangoRice", c) end)
FarmToggle("AutoBananaPack", "ลูปกล้วยแพ็ค", "กล้วย → กล้วยแพ็ค → ขาย",
    { "Banana" }, function(c) Sys.ProcessBanana(c) end)
FarmToggle("AutoKangSom", "ลูปแกงส้ม", "มะเขือเทศ + ปู → แกงส้ม → ขาย",
    { "Tomato", "Crab" }, function(c) Sys.CraftFood("KangSom", c) end)

Button(AllIn, {
    title = "PANIC ปิดทุกอย่าง", desc = "หยุดฟาร์ม/ซื้อ/ขาย ทั้งหมดทันที", text = "STOP",
    callback = function()
        StopAllFarms()
        Config.AutoFishing = false
        Sys.StopFishing()
        Toast("หยุดทุกอย่างแล้ว", false)
    end,
})
Toggle(AllIn, {
    key = "AutoEatDrink",
    title = "ออโต้กินข้าว + กาแฟ",
    desc = "เมื่อหลอดอาหาร/พลังงาน ≤ 75%",
})

-- Farm page
Section(FarmPage, "ฟาร์มเดี่ยว (เลือกพืช)")
local cropOptions = { "Bread", "Catchup", "Pig", "Mango", "Rice", "Tomato", "Banana", "Crab", "Coconut" }
local cropRow = Panel(FarmPage, UDim2.new(1, 0, 0, 56), "TextButton")
HoverRow(cropRow)
Register(cropRow, "เลือกพืช")
local cropLabel = Text(cropRow, "พืช: " .. tostring(Config.IndividualCrop), 13, FNT.M, "Text")
cropLabel.Position = UDim2.fromOffset(18, 0)
cropLabel.Size = UDim2.new(1, -80, 1, 0)
local cropPill = New("Frame", { Size = UDim2.fromOffset(90, 28), Position = UDim2.new(1, -108, 0.5, -14), BorderSizePixel = 0 }, cropRow)
Corner(cropPill, 14)
Bind(cropPill, "BackgroundColor3", "Surface2")
local cropPillT = Text(cropPill, "เปลี่ยน", 11, FNT.M, "Accent", Enum.TextXAlignment.Center)
cropPillT.Size = UDim2.fromScale(1, 1)
local cropIdx = 1
for i, v in ipairs(cropOptions) do if v == Config.IndividualCrop then cropIdx = i break end end
cropRow.MouseButton1Click:Connect(function()
    cropIdx = cropIdx % #cropOptions + 1
    Config.IndividualCrop = cropOptions[cropIdx]
    cropLabel.Text = "พืช: " .. tostring(Config.IndividualCrop)
    SetConfig("IndividualCrop", Config.IndividualCrop)
end)

Toggle(FarmPage, {
    key = "AutoIndividual",
    title = "เริ่มออโต้ฟาร์มเดี่ยว",
    desc = "พืชที่เลือก → 60 ชิ้น → ขายที่ตลาด",
    callback = function(v)
        if v then
            RequestFarmSession("AutoIndividual")
            task.spawn(function()
                Sys.WarpToTown()
                while Config.AutoIndividual do
                    local crop = Config.IndividualCrop
                    Sys.HarvestCrop(crop, 60, function() return Config.AutoIndividual end)
                    Sys.SellAll(function() return Config.AutoIndividual end)
                end
            end)
        end
    end,
})

-- Fishing page
Section(Fishing, "ตกปลา")
Toggle(Fishing, {
    key = "AutoFishing",
    title = "เริ่มออโต้ตกปลา",
    desc = "เบิกรถ → ซื้อเหยื่อ → ตกปลา → ขายปลา",
    callback = function(v) if v then Sys.StartFishing() else Sys.StopFishing() end end,
})

-- Settings
Section(Settings, "ระบบ")
Toggle(Settings, { key = "SoundEnabled", title = "เสียงเปิด/ปิด", desc = "เล่นเสียงเมื่อกดสวิตช์" })
Toggle(Settings, { key = "StatsVisible", title = "แสดง FPS / MS", desc = "กล่องลากได้", callback = function(v) StatsGui.Enabled = v end })
Slider(Settings, { key = "UIScalePercent", title = "ขนาดหน้าต่าง", desc = "ปรับขนาด UI", min = 60, max = 150, step = 5, suffix = "%", callback = function() ApplyScale(true) end })
Slider(Settings, { key = "VehicleSpeed", title = "ความเร็วรถ", desc = "studs/วินาที", min = 10, max = 200, step = 10, suffix = "" })

Section(Settings, "ความปลอดภัย")
Toggle(Settings, { key = "AutoHopPlayer", title = "Auto Hop เมื่อมีคนใกล้", desc = "ย้ายเซิร์ฟอัตโนมัติ", callback = function(v) Config.AutoHopPlayer = v end })
Slider(Settings, { key = "HopDistance", title = "ระยะตรวจจับ", desc = "studs", min = 20, max = 250, step = 5, suffix = " studs" })
Toggle(Settings, { key = "AntiAFK", title = "Anti-AFK", desc = "กันโดนเตะเพราะไม่ขยับ" })

Section(Settings, "ธีมสำเร็จรูป")
ThemeGrid(Settings)
Section(Settings, "ธีม UI")
ColorRow(Settings, "สีหลัก UI", "UIAccentColor")
ColorRow(Settings, "สีพื้นหลัง UI", "UIBackgroundColor")
ColorRow(Settings, "สีปุ่ม UI", "UIButtonColor")
Section(Settings, "ปุ่มลอย")
ColorRow(Settings, "สีปุ่มลอย", "FloatingButtonColor")
ColorRow(Settings, "สีขอบ", "FloatingBorderColor")
ColorRow(Settings, "สี Glow", "FloatingGlowColor")

Section(Settings, "Config")
local CfgCard = Panel(Settings, UDim2.new(1, 0, 0, 64))
local CfgTitle = Text(CfgCard, "บันทึกอัตโนมัติ", 13, FNT.M, "Text")
CfgTitle.Position = UDim2.fromOffset(16, 11)
CfgTitle.Size = UDim2.new(1, -140, 0, 20)
local CfgDesc = Text(CfgCard, writefile and CONFIG_FILE or "ไม่รองรับการเขียนไฟล์", 10, FNT.R, "Muted")
CfgDesc.Position = UDim2.fromOffset(16, 33)
CfgDesc.Size = UDim2.new(1, -140, 0, 18)
local CfgPill = StatusPill(CfgCard, 108)
CfgPill.AnchorPoint = Vector2.new(1, 0.5)
CfgPill.Position = UDim2.new(1, -14, 0.5, 0)

local ResetRow = Panel(Settings, UDim2.new(1, 0, 0, 50), "TextButton")
HoverRow(ResetRow)
local ResetLabel = Text(ResetRow, "รีเซ็ตการตั้งค่าทั้งหมด", 12, FNT.M, RGB(235, 90, 100))
ResetLabel.Position = UDim2.fromOffset(16, 0)
ResetLabel.Size = UDim2.new(1, -32, 1, 0)
local resetArmed = false
ResetRow.MouseButton1Click:Connect(function()
    if not resetArmed then
        resetArmed = true
        ResetLabel.Text = "กดอีกครั้งเพื่อยืนยัน"
        task.delay(3, function() resetArmed = false; ResetLabel.Text = "รีเซ็ตการตั้งค่าทั้งหมด" end)
        return
    end
    resetArmed = false
    ResetLabel.Text = "รีเซ็ตการตั้งค่าทั้งหมด"
    for k, v in pairs(Defaults) do Config[k] = v end
    Collapsed = {}
    for _, secs in pairs(SectionsByPage) do
        for _, sec in ipairs(secs) do sec.collapsed = false; sec.refresh(true) end
    end
    ApplyTheme()
    for _, fn in ipairs(Refreshers) do pcall(fn) end
    Tween(Main, 0.3, { Position = UDim2.fromScale(Config.WindowX, Config.WindowY) }, Enum.EasingStyle.Quint)
    ApplyScale(true)
    StatsBox.Position = UDim2.fromScale(Config.StatsX, Config.StatsY)
    StatsGui.Enabled = Config.StatsVisible
    SelectTab(Config.LastTab)
    SaveConfig(true)
    Toast("รีเซ็ตแล้ว", true)
end)

-- Sidebar
CatGroup("เมนูหลัก")
Category("หน้าหลัก", "Home", "grid")
Category("ไก่ตัน ALL-IN-ONE", "AllIn", "ring")
Category("ฟาร์มเดี่ยว", "Farm", "sliders")
Category("ตกปลา", "Fishing", "ring")
CatGroup("ตั้งค่า")
Category("ตั้งค่า", "Settings", "ring")

-- Floating
local ToggleGui = New("ScreenGui", { Name = "NEXUS_Floating", ResetOnSpawn = false, DisplayOrder = 999999, IgnoreGuiInset = true }, PlayerGui)
local Float = New("Frame", { Size = UDim2.fromOffset(48, 48), AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(Config.FloatX, Config.FloatY), BackgroundTransparency = 1, Active = true }, ToggleGui)
local Glow = New("Frame", { Size = UDim2.new(1, 8, 1, 8), Position = UDim2.fromScale(0.5, 0.5),
    AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1 }, Float)
Corner(Glow, 15)
local GlowStroke = Stroke(Glow, RGB(145, 145, 145), 3, 0.2)
local RX = New("TextButton", { Size = UDim2.fromScale(1, 1), Text = "NX", TextSize = 15,
    Font = FNT.B, BorderSizePixel = 0, AutoButtonColor = false, Active = true }, Float)
Corner(RX, 13)
local RXStroke = Stroke(RX, RGB(255, 255, 255), 2, 0.05)
local RXGrad = New("UIGradient", { Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.85), NumberSequenceKeypoint.new(1, 0) }) }, RXStroke)
TweenService:Create(RXGrad, TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), { Rotation = 360 }):Play()
OnTheme(function()
    local bg = Hex("FloatingButtonColor", RGB(18, 18, 18))
    RX.BackgroundColor3 = bg
    RX.TextColor3 = Lum(bg) > 0.55 and RGB(15, 15, 15) or RGB(255, 255, 255)
    RXStroke.Color = Hex("FloatingBorderColor", RGB(255, 255, 255))
    GlowStroke.Color = Hex("FloatingGlowColor", RGB(145, 145, 145))
end)
TweenService:Create(GlowStroke, TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Transparency = 0.65 }):Play()
MakeDraggable(RX, Float, "FloatX", "FloatY", function() SetWindow(not Config.WindowVisible) end)

--==================================================
-- START
--==================================================
SelectTab(Config.LastTab)
RefreshStats()
RefreshHome()
if Config.WindowVisible then PlayOpen() end
if not LoadedFromFile then SaveConfig(true) end
print("[NEXUS] v10 ALL-IN-ONE Loaded" .. (LoadedFromFile and " (Config loaded)" or " (new Config)"))

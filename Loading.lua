-- ==========================================
-- MarvenRiz Hub Loading Screen
-- Module: Loading.lua
-- Minimum Loading Time: 3 Seconds
-- ==========================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local ContentProvider = game:GetService("ContentProvider")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local started = false
local finished = false

local startTime = os.clock()
local MIN_TIME = 3

local Gui, Blur, Card, ProgressFill, Status, PercentLabel

-- Animation
local function tween(obj, duration, props)
    local info = TweenInfo.new(
        duration,
        Enum.EasingStyle.Quart,
        Enum.EasingDirection.Out
    )

    local t = TweenService:Create(obj, info, props)
    t:Play()
    return t
end

-- Start Loading
local function StartLoading()
    if started then return end

    started = true
    finished = false
    startTime = os.clock()

    local oldGui = PlayerGui:FindFirstChild("MarvenRizLoading")
    if oldGui then oldGui:Destroy() end

    local oldBlur = Lighting:FindFirstChild("MarvenRizBlur")
    if oldBlur then oldBlur:Destroy() end

    -- Blur Effect
    Blur = Instance.new("BlurEffect")
    Blur.Name = "MarvenRizBlur"
    Blur.Size = 0
    Blur.Parent = Lighting

    tween(Blur, 0.45, {Size = 18})

    -- Main GUI
    Gui = Instance.new("ScreenGui")
    Gui.Name = "MarvenRizLoading"
    Gui.IgnoreGuiInset = true
    Gui.ResetOnSpawn = false
    Gui.DisplayOrder = 999
    Gui.Parent = PlayerGui

    local Background = Instance.new("Frame")
    Background.Size = UDim2.fromScale(1, 1)
    Background.BackgroundTransparency = 1
    Background.Parent = Gui

    -- Card
    Card = Instance.new("Frame")
    Card.AnchorPoint = Vector2.new(0.5, 0.5)
    Card.Position = UDim2.fromScale(0.5, 0.5)
    Card.Size = UDim2.new(0, 300, 0, 76)
    Card.BackgroundColor3 = Color3.fromRGB(28, 30, 36)
    Card.BackgroundTransparency = 0.12
    Card.BorderSizePixel = 0
    Card.Parent = Background

    Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 14)

    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Color3.fromRGB(95, 105, 125)
    Stroke.Transparency = 0.65
    Stroke.Thickness = 1
    Stroke.Parent = Card

    -- Logo
    local Logo = Instance.new("ImageLabel")
    Logo.BackgroundTransparency = 1
    Logo.Size = UDim2.fromOffset(46, 46)
    Logo.Position = UDim2.new(0, 12, 0.5, -26)
    Logo.Image = "rbxassetid://124905448303407"
    Logo.Parent = Card

    -- Title
    local Title = Instance.new("TextLabel")
    Title.BackgroundTransparency = 1
    Title.Position = UDim2.new(0, 68, 0, 13)
    Title.Size = UDim2.new(1, -120, 0, 20)
    Title.Font = Enum.Font.GothamBold
    Title.Text = "MarvenRiz Hub"
    Title.TextColor3 = Color3.fromRGB(245, 247, 255)
    Title.TextSize = 15
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Card

    -- Status
    Status = Instance.new("TextLabel")
    Status.BackgroundTransparency = 1
    Status.Position = UDim2.new(0, 68, 0, 35)
    Status.Size = UDim2.new(1, -82, 0, 16)
    Status.Font = Enum.Font.Gotham
    Status.Text = "กำลังเริ่มต้น..."
    Status.TextColor3 = Color3.fromRGB(170, 178, 195)
    Status.TextSize = 11
    Status.TextXAlignment = Enum.TextXAlignment.Left
    Status.Parent = Card

    -- Percentage
    PercentLabel = Instance.new("TextLabel")
    PercentLabel.BackgroundTransparency = 1
    PercentLabel.AnchorPoint = Vector2.new(1, 0)
    PercentLabel.Position = UDim2.new(1, -14, 0, 14)
    PercentLabel.Size = UDim2.fromOffset(40, 16)
    PercentLabel.Font = Enum.Font.GothamMedium
    PercentLabel.Text = "0%"
    PercentLabel.TextColor3 = Color3.fromRGB(200, 210, 230)
    PercentLabel.TextSize = 11
    PercentLabel.TextXAlignment = Enum.TextXAlignment.Right
    PercentLabel.Parent = Card

    -- Progress Bar Background
    local BarBG = Instance.new("Frame")
    BarBG.Position = UDim2.new(0, 14, 1, -13)
    BarBG.Size = UDim2.new(1, -28, 0, 3)
    BarBG.BackgroundColor3 = Color3.fromRGB(65, 70, 82)
    BarBG.BorderSizePixel = 0
    BarBG.Parent = Card

    Instance.new("UICorner", BarBG).CornerRadius = UDim.new(1, 0)

    -- Progress Fill
    ProgressFill = Instance.new("Frame")
    ProgressFill.Size = UDim2.fromScale(0, 1)
    ProgressFill.BackgroundColor3 = Color3.fromRGB(65, 145, 255)
    ProgressFill.BorderSizePixel = 0
    ProgressFill.Parent = BarBG

    Instance.new("UICorner", ProgressFill).CornerRadius = UDim.new(1, 0)

    -- Card Animation
    Card.BackgroundTransparency = 1
    tween(Card, 0.35, {BackgroundTransparency = 0.12})
end

-- Update Progress
local function SetProgress(percent, message)
    if not started or finished or not ProgressFill then
        return
    end

    percent = math.clamp(tonumber(percent) or 0, 0, 100)

    tween(ProgressFill, 0.25, {
        Size = UDim2.fromScale(percent / 100, 1)
    })

    PercentLabel.Text = math.floor(percent) .. "%"

    if message then
        Status.Text = tostring(message)
    end
end

-- Finish Loading
local function FinishLoading()
    if not started or finished then
        return
    end

    finished = true

    -- Minimum Loading Time: 3 Seconds
    local elapsed = os.clock() - startTime

    if elapsed < MIN_TIME then
        task.wait(MIN_TIME - elapsed)
    end

    if PercentLabel then
        PercentLabel.Text = "100%"
    end

    if Status then
        Status.Text = "โหลดเสร็จแล้ว"
    end

    if ProgressFill then
        tween(ProgressFill, 0.25, {
            Size = UDim2.fromScale(1, 1)
        })
    end

    task.wait(0.5)

    -- Fade Out
    if Card then
        tween(Card, 0.35, {
            BackgroundTransparency = 1
        })

        for _, obj in ipairs(Card:GetDescendants()) do
            if obj:IsA("TextLabel") then
                tween(obj, 0.3, {TextTransparency = 1})

            elseif obj:IsA("ImageLabel") then
                tween(obj, 0.3, {ImageTransparency = 1})

            elseif obj:IsA("Frame") then
                tween(obj, 0.3, {BackgroundTransparency = 1})

            elseif obj:IsA("UIStroke") then
                tween(obj, 0.3, {Transparency = 1})
            end
        end
    end

    if Blur then
        tween(Blur, 0.4, {Size = 0})
    end

    task.wait(0.45)

    if Gui then
        Gui:Destroy()
    end

    if Blur then
        Blur:Destroy()
    end

    started = false
end

-- Export Module
return {
    Start = StartLoading,
    SetProgress = SetProgress,
    Finish = FinishLoading,
}

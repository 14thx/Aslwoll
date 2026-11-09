-- =====================================
-- MARVENRIZ HUB : MAIN
-- =====================================

-- Loading Screen
local Loading = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/14thx/Aslwoll/main/Loading.lua"
))()

Loading.Start()
Loading.SetProgress(5, "กำลังเริ่มต้นระบบ...")

-- Load RayVinz UI
Loading.SetProgress(15, "กำลังโหลด UI Library...")

local UI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/14thx/Aslwoll/main/RayVinzUI.lua"
))()

UI:LoadLucide()

Loading.SetProgress(25, "กำลังเตรียมหน้าต่าง...")

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local MarketplaceService = game:GetService("MarketplaceService")

local Player = Players.LocalPlayer

-- =====================================
-- WINDOW
-- =====================================

local Window = UI:CreateWindow({
    Title = "MarvenRiz Hub",
    Author = "by. zems.xz",
    Version = "Version : Premium",
    Logo = "rbxassetid://124905448303407",
    Folder = "MarvenRizHub",
    ConfigAutoSave = true,
    ToggleKey = Enum.KeyCode.RightShift,
    Width = 620,
    Height = 430,
})

UI:SetAccent(
    Color3.fromRGB(0, 110, 255),
    Color3.fromRGB(0, 65, 200)
)

Loading.SetProgress(35, "กำลังสร้างหน้าต่างหลัก...")

-- =====================================
-- TAB 1 : STATUS
-- =====================================

local Status = Window:Tab({
    Title = "สถานะ",
    Icon = "chart-no-axes-combined"
})

local Welcome = Status:Section({
    Title = "WELCOME INFO"
})

Welcome:Banner({
    Title = "MarvenRiz Hub",
    SubTitle = "ยินดีต้อนรับเข้าสู่ MarvenRiz Hub",
    Logo = "rbxassetid://124905448303407",
    Height = 105,
    Color = Color3.fromRGB(0, 35, 140),
    Color2 = Color3.fromRGB(0, 10, 65),
})

local System = Status:Section({
    Title = "SYSTEM INFO"
})

local StatsGrid = System:StatGrid({
    { Label = "FPS",      Value = "0",       Icon = "gauge" },
    { Label = "Ping",     Value = "0 ms",    Icon = "wifi" },
    { Label = "Executor", Value = "Unknown", Icon = "terminal" },
    { Label = "Players",  Value = "0",       Icon = "users" },
    { Label = "Game",     Value = game.Name, Icon = "gamepad-2" },
    { Label = "Time",     Value = "00:00:00", Icon = "clock" },
})

-- FPS / Ping updater
local Frames = 0
local LastUpdate = os.clock()

RunService.RenderStepped:Connect(function()
    Frames = Frames + 1

    local Now = os.clock()

    if Now - LastUpdate >= 1 then
        local FPS = Frames
        Frames = 0
        LastUpdate = Now

        local Ping = 0

        pcall(function()
            Ping = math.floor(
                Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
            )
        end)

        local Executor = "Unknown"

        if identifyexecutor then
            pcall(function()
                Executor = identifyexecutor()
            end)
        end

        -- ใช้ "." ไม่ใช่ ":" (Set ไม่ใช่เมธอด)
        StatsGrid.Set("FPS", FPS)
        StatsGrid.Set("Ping", Ping .. " ms")
        StatsGrid.Set("Executor", Executor)
        StatsGrid.Set("Players", #Players:GetPlayers())
        StatsGrid.Set("Game", game.Name)
        StatsGrid.Set("Time", os.date("%H:%M:%S"))
    end
end)

Loading.SetProgress(50, "กำลังสร้างแท็บสถานะ...")

-- =====================================
-- TAB 2 : SETTINGS
-- =====================================

local Settings = Window:Tab({
    Title = "ตั้งค่า",
    Icon = "settings"
})

local SettingsSection = Settings:Section({
    Title = "ตั้งค่าทั่วไป"
})

SettingsSection:Toggle({
    Title = "ออโต้ ขายไอเท็ม",
    Description = "ขายของอัตโนมัติเมื่อฟาร์มแล้วไอเท็มเต็ม",
    Default = true,
    Flag = "AutoSell",
    Callback = function(Value)
        print("Auto Sell:", Value)
    end
})

SettingsSection:Toggle({
    Title = "ออโต้ ค้นอาหาร",
    Description = "ค้นหาอาหารอัตโนมัติ หากค่าต่ำกว่า 20",
    Default = true,
    Flag = "AutoFindFood",
    Callback = function(Value)
        print("Auto Find Food:", Value)
    end
})

Loading.SetProgress(60, "กำลังสร้างแท็บตั้งค่า...")

-- =====================================
-- TAB 3 : FARM
-- =====================================

local Farm = Window:Tab({
    Title = "ฟาร์ม",
    Icon = "sprout"
})

local NormalFarm = Farm:Section({
    Title = "ฟาร์มอัตโนมัติ"
})

NormalFarm:Dropdown({
    Title = "เลือกฟาร์ม",
    Options = { "None", "Farm 1", "Farm 2", "Farm 3" },
    Default = "None",
    Flag = "NormalFarmType",
    Callback = function(Value)
        print("Farm:", Value)
    end
})

NormalFarm:Toggle({
    Title = "ออโต้ ฟาร์มไอเท็ม (ที่เลือก)",
    Default = false,
    Flag = "AutoFarmItem",
    Callback = function(Value)
        print("Auto Farm Item:", Value)
    end
})

local PlayerFarm = Farm:Section({
    Title = "ฟาร์มอัตโนมัติ (ผู้เล่น)"
})

PlayerFarm:Dropdown({
    Title = "เลือกฟาร์ม",
    Options = { "None", "Player 1", "Player 2", "Player 3" },
    Default = "None",
    Flag = "PlayerFarmType",
    Callback = function(Value)
        print("Player Farm:", Value)
    end
})

PlayerFarm:Toggle({
    Title = "ออโต้ ฟาร์มผู้ขาย",
    Default = false,
    Flag = "AutoPlayerFarm",
    Callback = function(Value)
        print("Auto Player Farm:", Value)
    end
})

local SpecialFarm = Farm:Section({
    Title = "ฟาร์มอัตโนมัติ (เหมือง)"
})

SpecialFarm:Dropdown({
    Title = "เลือกฟาร์มเหมือง",
    Options = { "None", "Mine 1", "Mine 2", "Mine 3" },
    Default = "None",
    Flag = "MineFarmType",
    Callback = function(Value)
        print("Mine Farm:", Value)
    end
})

SpecialFarm:Toggle({
    Title = "ออโต้ ฟาร์มเหมือง",
    Default = false,
    Flag = "AutoMineFarm",
    Callback = function(Value)
        print("Auto Mine Farm:", Value)
    end
})

Loading.SetProgress(75, "กำลังสร้างแท็บฟาร์ม...")

-- =====================================
-- TAB 4 : OTHER
-- =====================================

local Other = Window:Tab({
    Title = "อื่นๆ",
    Icon = "ellipsis"
})

local OtherSection = Other:Section({
    Title = "ตัวละครผู้เล่น"
})

OtherSection:Toggle({
    Title = "พลังงานไม่จำกัด",
    Description = "เปิดใช้งานพลังงานไม่จำกัด",
    Default = false,
    Flag = "InfiniteEnergy",
    Callback = function(Value)
        print("Infinite Energy:", Value)
    end
})

Loading.SetProgress(85, "กำลังสร้างแท็บอื่นๆ...")

-- =====================================
-- TAB 5 : CONFIG
-- =====================================

local Config = Window:Tab({
    Title = "Config",
    Icon = "folder-cog"
})

local ConfigSection = Config:Section({
    Title = "CONFIG"
})

ConfigSection:ConfigManager()

Loading.SetProgress(95, "กำลังเตรียม Config...")

-- =====================================
-- COMPLETE
-- =====================================

UI:Notify({
    Title = "MarvenRiz Hub",
    Content = "Hub loaded successfully!",
    Type = "Success",
    Duration = 4
})

Loading.SetProgress(100, "โหลดเสร็จแล้ว")

task.wait(0.4)
Loading.Finish()

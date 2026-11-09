-- =====================================
-- MARVENRIZ HUB : MAIN
-- โหลด 100% -> ซ่อน Loading -> สร้าง UI หลัก
-- =====================================

-- 1. โหลด Module Loading จาก GitHub (ใช้ลิงก์เดิมของคุณ)
local Loading = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/14thx/Aslwoll/main/Loading.lua"
))()

-- 2. เริ่มโหลด (วิ่งไปจนถึง 100%)
Loading.Start()
task.wait(0.5)

Loading.SetProgress(10, "กำลังเริ่มต้นระบบ...")
task.wait(0.5)

Loading.SetProgress(30, "กำลังเตรียมความพร้อม...")
task.wait(0.5)

Loading.SetProgress(50, "กำลังตรวจสอบแพ็กเกจ...")
task.wait(0.5)

Loading.SetProgress(70, "กำลังโหลดโมดูล...")
task.wait(0.5)

Loading.SetProgress(90, "กำลังเตรียมหน้าต่างหลัก...")
task.wait(0.5)

-- 🔴 วิ่งไป 100% ก่อน
Loading.SetProgress(100, "โหลดเสร็จสมบูรณ์!")
task.wait(0.6) -- โชว์ 100% ค้างไว้ให้เห็นชัดๆ

-- 3. 🔴 สั่งซ่อน Loading ทันที
Loading.Hide()

-- =====================================
-- 4. สร้าง UI หลัก (หลังจาก Loading หายไปแล้ว)
-- =====================================

-- โหลด UI Library
local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/14thx/Aslwoll/main/RayVinzUI.lua"))()
UI:LoadLucide()
task.wait(0.2)

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local Player = Players.LocalPlayer

-- สร้าง Window หลัก
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

UI:SetAccent(Color3.fromRGB(0, 110, 255), Color3.fromRGB(0, 65, 200))
task.wait(0.3)

-- =====================================
-- TAB 1 : STATUS
-- =====================================
local Status = Window:Tab({ Title = "สถานะ", Icon = "chart-no-axes-combined" })
local Welcome = Status:Section({ Title = "WELCOME INFO" })
Welcome:Banner({
    Title = "MarvenRiz Hub",
    SubTitle = "ยินดีต้อนรับเข้าสู่ MarvenRiz Hub",
    Logo = "rbxassetid://124905448303407",
    Height = 105,
    Color = Color3.fromRGB(0, 35, 140),
    Color2 = Color3.fromRGB(0, 10, 65),
})
task.wait(0.1)

local System = Status:Section({ Title = "SYSTEM INFO" })
local StatsGrid = System:StatGrid({
    { Label = "FPS", Value = "0", Icon = "gauge" },
    { Label = "Ping", Value = "0 ms", Icon = "wifi" },
    { Label = "Executor", Value = "Unknown", Icon = "terminal" },
    { Label = "Players", Value = "0", Icon = "users" },
    { Label = "Game", Value = game.Name, Icon = "gamepad-2" },
    { Label = "Time", Value = "00:00:00", Icon = "clock" }
})
task.wait(0.1)

local Frames, LastUpdate, FPS = 0, os.clock(), 0
RunService.RenderStepped:Connect(function()
    Frames = Frames + 1
    local Now = os.clock()
    if Now - LastUpdate >= 1 then
        FPS = Frames
        Frames = 0
        LastUpdate = Now
        local Ping = 0
        pcall(function() Ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
        local Executor = "Unknown"
        if identifyexecutor then pcall(function() Executor = identifyexecutor() end) end
        StatsGrid.Set("FPS", FPS)
        StatsGrid.Set("Ping", Ping .. " ms")
        StatsGrid.Set("Executor", Executor)
        StatsGrid.Set("Players", #Players:GetPlayers())
        StatsGrid.Set("Game", game.Name)
        StatsGrid.Set("Time", os.date("%H:%M:%S"))
    end
end)
task.wait(0.2)

-- =====================================
-- TAB 2 : SETTINGS
-- =====================================
local Settings = Window:Tab({ Title = "ตั้งค่า", Icon = "settings" })
local SettingsSection = Settings:Section({ Title = "ตั้งค่าทั่วไป" })
SettingsSection:Toggle({ Title = "ออโต้ ขายไอเท็ม", Description = "ขายของอัตโนมัติเมื่อฟาร์มแล้วไอเท็มเต็ม", Default = true, Flag = "AutoSell", Callback = function(v) print("Auto Sell:", v) end })
task.wait(0.1)
SettingsSection:Toggle({ Title = "ออโต้ ค้นอาหาร", Description = "ค้นหาอาหารอัตโนมัติ หากค่าต่ำกว่า 20", Default = true, Flag = "AutoFindFood", Callback = function(v) print("Auto Find Food:", v) end })
task.wait(0.2)

-- =====================================
-- TAB 3 : FARM
-- =====================================
local Farm = Window:Tab({ Title = "ฟาร์ม", Icon = "sprout" })
local NormalFarm = Farm:Section({ Title = "ฟาร์มอัตโนมัติ" })
NormalFarm:Dropdown({ Title = "เลือกฟาร์ม", Options = {"None", "Farm 1", "Farm 2", "Farm 3"}, Default = "None", Flag = "NormalFarmType", Callback = function(v) print("Farm:", v) end })
task.wait(0.1)
NormalFarm:Toggle({ Title = "ออโต้ ฟาร์มไอเท็ม (ที่เลือก)", Default = false, Flag = "AutoFarmItem", Callback = function(v) print("Auto Farm Item:", v) end })
task.wait(0.1)

local PlayerFarm = Farm:Section({ Title = "ฟาร์มอัตโนมัติ (ผู้เล่น)" })
PlayerFarm:Dropdown({ Title = "เลือกฟาร์ม", Options = {"None", "Player 1", "Player 2", "Player 3"}, Default = "None", Flag = "PlayerFarmType", Callback = function(v) print("Player Farm:", v) end })
task.wait(0.1)
PlayerFarm:Toggle({ Title = "ออโต้ ฟาร์มผู้ขาย", Default = false, Flag = "AutoPlayerFarm", Callback = function(v) print("Auto Player Farm:", v) end })
task.wait(0.1)

local SpecialFarm = Farm:Section({ Title = "ฟาร์มอัตโนมัติ (เหมือง)" })
SpecialFarm:Dropdown({ Title = "เลือกฟาร์มเหมือง", Options = {"None", "Mine 1", "Mine 2", "Mine 3"}, Default = "None", Flag = "MineFarmType", Callback = function(v) print("Mine Farm:", v) end })
task.wait(0.1)
SpecialFarm:Toggle({ Title = "ออโต้ ฟาร์มเหมือง", Default = false, Flag = "AutoMineFarm", Callback = function(v) print("Auto Mine Farm:", v) end })
task.wait(0.2)

-- =====================================
-- TAB 4 : OTHER
-- =====================================
local Other = Window:Tab({ Title = "อื่นๆ", Icon = "ellipsis" })
local OtherSection = Other:Section({ Title = "ตัวละครผู้เล่น" })
OtherSection:Toggle({ Title = "พลังงานไม่จำกัด", Description = "เปิดใช้งานพลังงานไม่จำกัด", Default = false, Flag = "InfiniteEnergy", Callback = function(v) print("Infinite Energy:", v) end })
task.wait(0.2)

-- =====================================
-- TAB 5 : CONFIG
-- =====================================
local Config = Window:Tab({ Title = "Config", Icon = "folder-cog" })
local ConfigSection = Config:Section({ Title = "CONFIG" })
ConfigSection:ConfigManager()
task.wait(0.3)

-- =====================================
-- 5. แจ้งเตือนเมื่อโหลดเสร็จ
-- =====================================
UI:Notify({ 
    Title = "MarvenRiz Hub", 
    Content = "Hub loaded successfully!", 
    Type = "Success", 
    Duration = 4 
})

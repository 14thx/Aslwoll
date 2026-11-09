-- =====================================
-- MARVENRIZ HUB : MAIN (แยกไฟล์)
-- =====================================

-- 1. โหลด Loading Module
local Loading = loadstring(game:HttpGet("https://raw.githubusercontent.com/14thx/Aslwoll/main/Loading.lua"))()
-- หรือถ้าคุณวางไฟล์ Loading ไว้ใน Executor แล้ว ก็ใช้: local Loading = require(script.Parent.Loading)

-- 2. เริ่มแสดงหน้าโหลด (UI จะขึ้นมาที่ 0%)
Loading.Start()
task.wait(0.5) 

Loading.SetProgress(5, "กำลังเริ่มต้นระบบ...")
task.wait(0.5)

-- 3. โหลด UI Library
Loading.SetProgress(15, "กำลังโหลด UI Library...")
local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/14thx/Aslwoll/main/RayVinzUI.lua"))()
UI:LoadLucide()

Loading.SetProgress(25, "กำลังเตรียมหน้าต่าง...")
task.wait(0.3)

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local Player = Players.LocalPlayer

-- =====================================
-- 4. สร้าง UI หลัก (แต่ยังไม่โชว์จนกว่าจะเสร็จ)
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

UI:SetAccent(Color3.fromRGB(0, 110, 255), Color3.fromRGB(0, 65, 200))

Loading.SetProgress(35, "กำลังสร้างหน้าต่างหลัก...")
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

local System = Status:Section({ Title = "SYSTEM INFO" })
local StatsGrid = System:StatGrid({
    { Label = "FPS", Value = "0", Icon = "gauge" },
    { Label = "Ping", Value = "0 ms", Icon = "wifi" },
    { Label = "Executor", Value = "Unknown", Icon = "terminal" },
    { Label = "Players", Value = "0", Icon = "users" },
    { Label = "Game", Value = game.Name, Icon = "gamepad-2" },
    { Label = "Time", Value = "00:00:00", Icon = "clock" }
})

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
        StatsGrid:Set("FPS", FPS)
        StatsGrid:Set("Ping", Ping .. " ms")
        StatsGrid:Set("Executor", Executor)
        StatsGrid:Set("Players", #Players:GetPlayers())
        StatsGrid:Set("Game", game.Name)
        StatsGrid:Set("Time", os.date("%H:%M:%S"))
    end
end)

Loading.SetProgress(50, "กำลังสร้างแท็บสถานะ...")
task.wait(0.3)

-- =====================================
-- TAB 2 : SETTINGS
-- =====================================
local Settings = Window:Tab({ Title = "ตั้งค่า", Icon = "settings" })
local SettingsSection = Settings:Section({ Title = "ตั้งค่าทั่วไป" })
SettingsSection:Toggle({ Title = "ออโต้ ขายไอเท็ม", Description = "ขายของอัตโนมัติเมื่อฟาร์มแล้วไอเท็มเต็ม", Default = true, Flag = "AutoSell", Callback = function(v) print("Auto Sell:", v) end })
SettingsSection:Toggle({ Title = "ออโต้ ค้นอาหาร", Description = "ค้นหาอาหารอัตโนมัติ หากค่าต่ำกว่า 20", Default = true, Flag = "AutoFindFood", Callback = function(v) print("Auto Find Food:", v) end })

Loading.SetProgress(60, "กำลังสร้างแท็บตั้งค่า...")
task.wait(0.3)

-- =====================================
-- TAB 3 : FARM
-- =====================================
local Farm = Window:Tab({ Title = "ฟาร์ม", Icon = "sprout" })
local NormalFarm = Farm:Section({ Title = "ฟาร์มอัตโนมัติ" })
NormalFarm:Dropdown({ Title = "เลือกฟาร์ม", Options = {"None", "Farm 1", "Farm 2", "Farm 3"}, Default = "None", Flag = "NormalFarmType", Callback = function(v) print("Farm:", v) end })
NormalFarm:Toggle({ Title = "ออโต้ ฟาร์มไอเท็ม (ที่เลือก)", Default = false, Flag = "AutoFarmItem", Callback = function(v) print("Auto Farm Item:", v) end })

local PlayerFarm = Farm:Section({ Title = "ฟาร์มอัตโนมัติ (ผู้เล่น)" })
PlayerFarm:Dropdown({ Title = "เลือกฟาร์ม", Options = {"None", "Player 1", "Player 2", "Player 3"}, Default = "None", Flag = "PlayerFarmType", Callback = function(v) print("Player Farm:", v) end })
PlayerFarm:Toggle({ Title = "ออโต้ ฟาร์มผู้ขาย", Default = false, Flag = "AutoPlayerFarm", Callback = function(v) print("Auto Player Farm:", v) end })

local SpecialFarm = Farm:Section({ Title = "ฟาร์มอัตโนมัติ (เหมือง)" })
SpecialFarm:Dropdown({ Title = "เลือกฟาร์มเหมือง", Options = {"None", "Mine 1", "Mine 2", "Mine 3"}, Default = "None", Flag = "MineFarmType", Callback = function(v) print("Mine Farm:", v) end })
SpecialFarm:Toggle({ Title = "ออโต้ ฟาร์มเหมือง", Default = false, Flag = "AutoMineFarm", Callback = function(v) print("Auto Mine Farm:", v) end })

Loading.SetProgress(75, "กำลังสร้างแท็บฟาร์ม...")
task.wait(0.3)

-- =====================================
-- TAB 4 : OTHER
-- =====================================
local Other = Window:Tab({ Title = "อื่นๆ", Icon = "ellipsis" })
local OtherSection = Other:Section({ Title = "ตัวละครผู้เล่น" })
OtherSection:Toggle({ Title = "พลังงานไม่จำกัด", Description = "เปิดใช้งานพลังงานไม่จำกัด", Default = false, Flag = "InfiniteEnergy", Callback = function(v) print("Infinite Energy:", v) end })

Loading.SetProgress(85, "กำลังสร้างแท็บอื่นๆ...")
task.wait(0.3)

-- =====================================
-- TAB 5 : CONFIG
-- =====================================
local Config = Window:Tab({ Title = "Config", Icon = "folder-cog" })
local ConfigSection = Config:Section({ Title = "CONFIG" })
ConfigSection:ConfigManager()

Loading.SetProgress(95, "กำลังเตรียม Config...")
task.wait(0.3)

-- =====================================
-- 5. โหลดเสร็จสิ้น (โชว์ UI หลัก)
-- =====================================
UI:Notify({ Title = "MarvenRiz Hub", Content = "Hub loaded successfully!", Type = "Success", Duration = 4 })

Loading.SetProgress(100, "โหลดเสร็จแล้ว")
task.wait(0.5)
Loading.Finish()

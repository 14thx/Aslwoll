-- =====================================
-- MARVENRIZ HUB + NEXUS ENGINE (FULL v2.5)
-- ไฟล์รวมสมบูรณ์ 100% (Part 1/2)
-- =====================================

-- 1. โหลดหน้า UI
local Loading = loadstring(game:HttpGet("https://raw.githubusercontent.com/14thx/Aslwoll/main/Loading.lua"))()
Loading.Start()
task.wait(0.3)
Loading.SetProgress(20, "Initializing system...")
task.wait(0.3)
Loading.SetProgress(60, "Loading modules...")
task.wait(0.3)
Loading.SetProgress(100, "Ready!")
task.wait(0.4) 

-- 2. โหลด UI Library
local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/14thx/Aslwoll/main/RayVinzUI.lua"))()
UI:LoadLucide()
task.wait(0.2)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Stats = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- 3. ตัวแปรหลัก
TOWN_CAR_SPAWN = Vector3.new(-311.83, 17.5, 5490.39)
VAULT_COORDS = Vector3.new(-1.98, 26.54, 8632.61)
VehicleDriveSpeed = 150
MY_SPAWNED_CAR = nil
isAutoEatAndDrinkEnabled = true
isVehicleNoclipEnabled = true
isVehiclePlatformEnabled = true
isAutoHopOnPlayerNearbyEnabled = true
autoHopDistance = 90
isConsumingItem = false

TYPER_LOCATIONS = {
    Bread    = {Booth=Vector3.new(872.19,15.90,4682.54),   Farm=Vector3.new(828.31,11.21,4817.85)},
    Catchup  = {Booth=Vector3.new(1763.23,14.23,4206.70),  Farm=Vector3.new(1803.05,12.65,4236.79)},
    Pig      = {Booth=Vector3.new(306.01,30.77,-1558.06),  Farm=Vector3.new(268.61,28.74,-1513.65)},
    Mango    = {Booth=Vector3.new(-1855.59,20.06,586.40),  Farm=Vector3.new(-1862.26,17.33,535.43)},
    Rice     = {Booth=Vector3.new(-92.11,11.46,89.48),     Farm=Vector3.new(-128.87,11.02,78.51)},
    Tomato   = {Booth=Vector3.new(-2294.10,31.28,-1273.91),Farm=Vector3.new(-2319.61,27.21,-1229.19)},
    Banana   = {Booth=Vector3.new(-1528.59,30.34,-1253.46),Farm=Vector3.new(-1545.12,28.80,-1126.87)},
    Crab     = {Booth=Vector3.new(1442.30,30.56,613.34),   Farm=Vector3.new(1400.27,28.69,648.22)},
    Rock     = {Booth=Vector3.new(-4101.27,35.75,-1097.15),Farm=Vector3.new(-4138.03,29.88,-1286.63),Process=Vector3.new(-935.29,6.93,6786.66)},
    Svibranium={Booth=Vector3.new(2785.16,30.11,-262.38),  Farm=Vector3.new(2723.67,28.51,-236.17),Process=Vector3.new(-930.91,6.93,6760.56)},
    Food     = {Crafting=Vector3.new(3442.48,56.40,3925.24),BananaProcess=Vector3.new(3429.20,56.80,3911.80)},
    Economy  = {Market=Vector3.new(-462.0,18.0,5324.7)}
}

-- 4. ฟังก์ชันพื้นฐาน
local function GetGroundLevel(x, z, fallbackY)
    fallbackY = fallbackY or 20
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.IgnoreWater = false
    local result = workspace:Raycast(Vector3.new(x, fallbackY + 14, z), Vector3.new(0, -70, 0), params)
    if result and result.Position then
        if result.Material == Enum.Material.Water then return math.max(result.Position.Y, 4.0) end
        return result.Position.Y
    end
    return fallbackY
end

GetPlayerInventoryCount = function(name)
    local pd = LocalPlayer:FindFirstChild("PlayerData")
    if pd then local c = pd:GetAttribute(name) if typeof(c) == "number" then return c end end
    return 0
end

local function GetPlayerHunger()
    local s = LocalPlayer:FindFirstChild("Stats")
    if s then local v = s:GetAttribute("Hunger") if typeof(v) == "number" then return v end end
    return 100
end

local function GetPlayerEnergy()
    local s = LocalPlayer:FindFirstChild("Stats")
    if s then local v = s:GetAttribute("Brain") if typeof(v) == "number" then return v end end
    return 100
end

local function UseItem(name)
    pcall(function()
        local rc = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes")
        if rc then require(rc).Fire("_inventory", "Use", name) end
    end)
end

local function FindAvailableFood()
    local pd = LocalPlayer:FindFirstChild("PlayerData")
    if pd then
        for _, food in ipairs({"Sushi","RiceKapaoMoo","MangoRice","Rice","Sandwish","Burger","Bread"}) do
            local n = pd:GetAttribute(food)
            if typeof(n) == "number" and n > 0 then return food end
        end
    end
end

local function FindAvailableCoffee()
    local pd = LocalPlayer:FindFirstChild("PlayerData")
    if pd then
        for _, d in ipairs({"Water","HotCocoa","Coffee"}) do
            local n = pd:GetAttribute(d)
            if typeof(n) == "number" and n > 0 then return d end
        end
    end
end

local function ConsumeItemSafely(itemName, isFood, customWait)
    if isConsumingItem or not itemName then return end
    isConsumingItem = true
    pcall(function()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        UseItem(itemName)
        local tool = nil
        local t0 = os.clock()
        while os.clock() - t0 < 2.5 do
            char = LocalPlayer.Character
            tool = char and char:FindFirstChild(itemName)
            if not tool and LocalPlayer:FindFirstChild("Backpack") then
                tool = LocalPlayer.Backpack:FindFirstChild(itemName)
                if tool and hum then hum:EquipTool(tool) end
            end
            if tool and tool.Parent == char then break end
            task.wait(0.1)
        end
        if tool and char then
            hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                if tool.Parent ~= char then hum:EquipTool(tool) task.wait(0.25) end
                task.wait(0.3)
                pcall(function() tool:Activate() end)
                local ws = os.clock()
                while os.clock() - ws < (customWait or 5.5) do task.wait(0.2) end
                task.wait(0.3)
                pcall(function() hum:UnequipTools() end)
            end
        end
    end)
    isConsumingItem = false
end

AutoEatThenDrink = function(target)
    target = target or 95
    if isConsumingItem then return end
    local i = 0
    while i < 8 do
        local h, e = GetPlayerHunger(), GetPlayerEnergy()
        if h >= target and e >= target then break end
        local f, d = FindAvailableFood(), FindAvailableCoffee()
        if f and h < target then ConsumeItemSafely(f, true, 5.5) task.wait(0.4) end
        if d and e < target then ConsumeItemSafely(d, false, 5.5) task.wait(0.4) end
        i += 1
        task.wait(0.3)
    end
end

CheckAndAutoEat = function()
    if not isAutoEatAndDrinkEnabled or isConsumingItem then return end
    local h, e = GetPlayerHunger(), GetPlayerEnergy()
    if (e and e <= 50) or (h and h <= 80) then AutoEatThenDrink(95) end
end

CheckAndAutoDrinkCoffee = function() CheckAndAutoEat() end

task.spawn(function()
    while true do
        task.wait(3.0)
        if isAutoEatAndDrinkEnabled and not isConsumingItem then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum and not hum.Sit then CheckAndAutoEat() task.wait(0.5) CheckAndAutoDrinkCoffee() end
        end
    end
end)

CancelGameFarm = function()
    pcall(function()
        local af = PlayerGui:FindFirstChild("Auto Farm") or PlayerGui:FindFirstChild("AutoFarm")
        if af then af.Enabled = false end
    end)
    pcall(function()
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:UnequipTools() end
    end)
    task.wait(0.3)
end

local function ClickGuiButton(btn)
    if not btn then return end
    pcall(function()
        if firesignal then
            pcall(function() firesignal(btn.MouseButton1Click) end)
            pcall(function() firesignal(btn.Activated) end)
        end
    end)
end

local function SafeClickGuiButton(btn)
    if not btn or not btn:IsA("GuiButton") then return end
    pcall(function()
        if firesignal then firesignal(btn.MouseButton1Click) firesignal(btn.Activated) end
    end)
end

local function TriggerPrompt(prompt)
    if not prompt or not prompt.Enabled then return end
    pcall(function()
        if fireproximityprompt then pcall(function() fireproximityprompt(prompt) end) end
        pcall(function()
            prompt:InputHoldBegin()
            task.wait(prompt.HoldDuration > 0 and (prompt.HoldDuration + 0.05) or 0.1)
            prompt:InputHoldEnd()
        end)
    end)
end

local function FindPromptNear(centerPos, maxDist, matchKeyword)
    maxDist = maxDist or 25
    local closest, closestDist = nil, maxDist
    local systems = workspace:FindFirstChild("Systems")
    local containers = systems and {systems} or {workspace}
    for _, container in ipairs(containers) do
        for _, prompt in ipairs(container:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") and prompt.Enabled then
                local pPart = prompt.Parent
                local pPos = pPart and (pPart:IsA("BasePart") and pPart.Position or (pPart:IsA("Attachment") and pPart.WorldPosition))
                if pPos then
                    local d = (pPos - centerPos).Magnitude
                    if d <= closestDist then
                        if not matchKeyword or string.find(string.lower(prompt.ActionText or ""), string.lower(matchKeyword)) then
                            closest = prompt
                            closestDist = d
                        end
                    end
                end
            end
        end
    end
    return closest
end

pcall(function()
    local lp = Players.LocalPlayer
    if hookmetamethod then
        local oldNm
        oldNm = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if (method == "Kick" or method == "kick") and (self == lp or self == Players) then return nil end
            return oldNm(self, ...)
        end))
    end
end)

GrantAntiXGrace = function(seconds)
    seconds = seconds or 25
    pcall(function()
        local char = LocalPlayer.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then
            root:SetAttribute("TeleportGrace", os.clock() + seconds)
            root:SetAttribute("AntiFallGrace", os.clock() + seconds)
            root:SetAttribute("IgnoreAntiCheat", true)
        end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        end
    end)
end

-- 5. ฟังก์ชันยานพาหนะ
local function IsMyVehicle(v)
    if not v or not v:IsA("Model") or not v.Parent then return false end
    if MY_SPAWNED_CAR and v == MY_SPAWNED_CAR then return true end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum and hum.SeatPart and hum.SeatPart:IsDescendantOf(v) then MY_SPAWNED_CAR = v return true end
    local owner = v:GetAttribute("Owner") or v:GetAttribute("Player")
    if owner ~= nil and tostring(owner) ~= "" then
        if tostring(owner) == LocalPlayer.Name or tostring(owner) == tostring(LocalPlayer.UserId) then MY_SPAWNED_CAR = v return true end
        return false
    end
    return false
end

GetPlayerVehicle = function()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum and hum.SeatPart then
        local v = hum.SeatPart:FindFirstAncestorOfClass("Model")
        if v and IsMyVehicle(v) then return v end
    end
    if MY_SPAWNED_CAR and MY_SPAWNED_CAR.Parent and MY_SPAWNED_CAR.PrimaryPart and IsMyVehicle(MY_SPAWNED_CAR) then return MY_SPAWNED_CAR end
    local vf = (workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Vehicles")) or workspace:FindFirstChild("Vehicles")
    if vf then
        for _, v in ipairs(vf:GetChildren()) do
            if v:IsA("Model") and IsMyVehicle(v) and v.PrimaryPart then MY_SPAWNED_CAR = v return v end
        end
    end
end

GetNearbyPlayerVehicle = function(dist)
    dist = dist or 80
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local vf = (workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Vehicles")) or workspace:FindFirstChild("Vehicles")
    local best, bd = nil, math.huge
    if vf then
        for _, v in ipairs(vf:GetChildren()) do
            if v:IsA("Model") and IsMyVehicle(v) and v.PrimaryPart then
                local d = (v.PrimaryPart.Position - root.Position).Magnitude
                if d < bd then bd, best = d, v end
            end
        end
    end
    if best and bd <= dist then MY_SPAWNED_CAR = best return best end
end

PressFToEnterCar = function(car)
    if not car or not car.Parent or not IsMyVehicle(car) then return false end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return false end
    local seat = car:FindFirstChild("DriveSeat", true) or car:FindFirstChildWhichIsA("VehicleSeat", true)
    if not seat then return false end
    if hum.Sit and hum.SeatPart == seat then MY_SPAWNED_CAR = car return true end
    if hum.Sit then hum.Sit = false task.wait(0.2) end
    root.CFrame = CFrame.lookAt(seat.CFrame.Position + Vector3.new(0, 0, -2.6), seat.Position)
    task.wait(0.15)
    pcall(function() seat:Sit(hum) end)
    return hum.Sit and hum.SeatPart ~= nil
end

EnsurePlayerSeatedInCar = function(car)
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum and hum.Sit and hum.SeatPart and car and hum.SeatPart:IsDescendantOf(car) then return true end
    return PressFToEnterCar(car)
end

ExitCarNaturally = function(car)
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return end
    if hum.Sit then hum.Sit = false task.wait(0.12) end
    pcall(function() game:GetService("ProximityPromptService").Enabled = true end)
    if car and car.PrimaryPart then
        local right = car.PrimaryPart.CFrame.RightVector
        local ep = car.PrimaryPart.Position - (right * 4.2)
        local gy = GetGroundLevel(ep.X, ep.Z, car.PrimaryPart.Position.Y)
        root.CFrame = CFrame.new(ep.X, gy + 1.8, ep.Z)
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end
    task.wait(0.15)
end

SmoothWalkTo = function(targetPos, maxTimeout, shouldContinueCheck, stopDist)
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return false end
    maxTimeout = maxTimeout or 50
    stopDist = stopDist or 2.5
    local st = os.clock()
    while (root.Position - targetPos).Magnitude > stopDist and (os.clock() - st < maxTimeout) do
        if shouldContinueCheck and not shouldContinueCheck() then return false end
        GrantAntiXGrace(5)
        hum:MoveTo(targetPos)
        task.wait(0.15)
    end
    return (root.Position - targetPos).Magnitude <= 10
end

GetNearestCarBooth = function(fromPos)
    fromPos = fromPos or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.Position) or TOWN_CAR_SPAWN
    local best, bd = nil, math.huge
    for _, d in pairs(TYPER_LOCATIONS) do
        if d.Booth then
            local dist = (d.Booth - fromPos).Magnitude
            if dist < bd then bd, best = dist, d.Booth end
        end
    end
    return best or TOWN_CAR_SPAWN
end

FindBoothPromptNear = function(fromPos, maxDist)
    fromPos = fromPos or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.Position)
    if not fromPos then return nil end
    maxDist = maxDist or 30
    local farmSys = workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Farm")
    if farmSys then
        for _, cf in ipairs(farmSys:GetChildren()) do
            local sf = cf:FindFirstChild("Prompt") and cf.Prompt:FindFirstChild("Spawn")
            if sf then
                local pr = sf:FindFirstChildWhichIsA("ProximityPrompt", true)
                if pr then
                    local p = pr.Parent
                    local pos = (p:IsA("Attachment") and p.WorldPosition) or (p:IsA("BasePart") and p.Position)
                    if pos and (pos - fromPos).Magnitude <= maxDist then return pr end
                end
            end
        end
    end
end

local function GetSpawnPointForBooth(boothPos)
    local best, bd = nil, math.huge
    local farmSys = workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Farm")
    if farmSys then
        for _, farm in ipairs(farmSys:GetChildren()) do
            local sp = farm:FindFirstChild("Prompt") and farm.Prompt:FindFirstChild("Spawn")
            local ptF = sp and sp:FindFirstChild("Point")
            if ptF then
                for _, pt in ipairs(ptF:GetChildren()) do
                    if pt:IsA("BasePart") then
                        local d = (pt.Position - boothPos).Magnitude
                        if d < bd then bd, best = d, pt end
                    end
                end
            end
        end
    end
    return best
end

local function CloseCarSpawnGui()
    pcall(function()
        local cs = PlayerGui:FindFirstChild("Car_Spawn")
        if cs and cs:FindFirstChild("Group") then cs.Group.Visible = false end
    end)
end

local function FindPoundButton(group)
    if not group then return nil end
    local sf = group:FindFirstChild("Main") and group.Main:FindFirstChild("Carlist") and group.Main.Carlist:FindFirstChild("ScrollingFrame")
    if sf then
        for _, card in ipairs(sf:GetChildren()) do
            if card:IsA("GuiObject") then
                local pb = card:FindFirstChild("Pound")
                if pb and pb.Visible then return pb end
            end
        end
    end
end

local function FindBlueSpawnButton(group)
    if not group then return nil end
    local sf = group:FindFirstChild("Main") and group.Main:FindFirstChild("Carlist") and group.Main.Carlist:FindFirstChild("ScrollingFrame")
    if sf then
        for _, card in ipairs(sf:GetChildren()) do
            if card:IsA("GuiObject") then
                local sb = card:FindFirstChild("Spawn")
                if sb and sb.Visible then return sb end
            end
        end
    end
end

StoreCarAtBooth = function(boothPos)
    GrantAntiXGrace(35)
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local myCar = GetPlayerVehicle()
    if not myCar then return end
    local cName = myCar.Name or "R32"
    local spPt = GetSpawnPointForBooth(boothPos)
    if myCar.PrimaryPart then
        if spPt and spPt:IsA("BasePart") then myCar:PivotTo(spPt.CFrame + Vector3.new(0, 1.2, 0))
        else local gy = GetGroundLevel(boothPos.X, boothPos.Z, boothPos.Y) myCar:PivotTo(CFrame.new(boothPos.X, gy + 1.2, boothPos.Z)) end
    end
    task.wait(2.0)
    ExitCarNaturally(myCar)
    if root and (root.Position - boothPos).Magnitude > 8 then SmoothWalkTo(boothPos, 3, nil, 5.0) end
    local boothPrompt = nil
    local farmSys = workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Farm")
    if farmSys then
        for _, f in ipairs(farmSys:GetChildren()) do
            local sp = f:FindFirstChild("Prompt") and f.Prompt:FindFirstChild("Spawn")
            local p = sp and sp:FindFirstChildWhichIsA("ProximityPrompt", true)
            if p then
                local pos = (p.Parent:IsA("Attachment") and p.Parent.WorldPosition) or (p.Parent:IsA("BasePart") and p.Parent.Position)
                if pos and (pos - boothPos).Magnitude <= 40 then boothPrompt = p p.Enabled = true break end
            end
        end
    end
    if boothPrompt then TriggerPrompt(boothPrompt) end
    local cs = PlayerGui:WaitForChild("Car_Spawn", 1.5)
    local t0 = os.clock()
    while (not cs or not cs:FindFirstChild("Group") or not cs.Group.Visible) and (os.clock() - t0 < 1.2) do
        if boothPrompt then TriggerPrompt(boothPrompt) end
        task.wait(0.15)
    end
    if cs and cs:FindFirstChild("Group") and cs.Group.Visible then
        local btn = FindPoundButton(cs.Group)
        if btn then ClickGuiButton(btn) task.wait(0.4) end
    end
    pcall(function()
        local rc = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes")
        if rc then
            local R = require(rc)
            R.Fire("_carspawn", "Despawn", cName)
            R.Fire("_carspawn", "Despawn")
            MY_SPAWNED_CAR = nil
        end
    end)
    CloseCarSpawnGui()
    task.wait(0.2)
end

SpawnCarAtBooth = function(boothPos)
    GrantAntiXGrace(40)
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return nil end
    pcall(function() game:GetService("ProximityPromptService").Enabled = true end)
    if boothPos then
        local dist = (root.Position - boothPos).Magnitude
        if dist > 15 then
            local gy = GetGroundLevel(boothPos.X, boothPos.Z, boothPos.Y)
            root.CFrame = CFrame.new(boothPos.X, gy + 1.2, boothPos.Z)
            task.wait(0.2)
        else
            root.CFrame = CFrame.lookAt(root.Position, Vector3.new(boothPos.X, root.Position.Y, boothPos.Z))
        end
    end
    local cs = PlayerGui:FindFirstChild("Car_Spawn")
    local group = cs and cs:FindFirstChild("Group")
    local tOpen = os.clock()
    while os.clock() - tOpen < 3.0 do
        if group and group.Visible then break end
        local bp = FindBoothPromptNear(root.Position, 30) or (boothPos and FindBoothPromptNear(boothPos, 30))
        if not bp then bp = FindPromptNear(root.Position, 25, nil) end
        if bp then
            bp.Enabled = true
            pcall(function() bp.HoldDuration = 0 end)
            if fireproximityprompt then pcall(function() fireproximityprompt(bp) end) end
            task.wait(0.08)
            cs = PlayerGui:FindFirstChild("Car_Spawn")
            group = cs and cs:FindFirstChild("Group")
            if group and group.Visible then break end
        end
        task.wait(0.1)
        cs = PlayerGui:FindFirstChild("Car_Spawn")
        group = cs and cs:FindFirstChild("Group")
    end
    if group and group.Visible then
        local pBtn = FindPoundButton(group)
        local sBtn = FindBlueSpawnButton(group)
        if pBtn and pBtn.Visible then ClickGuiButton(pBtn) task.wait(4.0) end
        if sBtn and sBtn.Visible then ClickGuiButton(sBtn) task.wait(1.0) end
    end
    local finalCar = nil
    local tc = os.clock()
    while os.clock() - tc < 6.0 do
        finalCar = GetNearbyPlayerVehicle(80) or GetPlayerVehicle()
        if finalCar and finalCar.PrimaryPart then break end
        task.wait(0.2)
    end
    if finalCar then
        MY_SPAWNED_CAR = finalCar
        for cd = 2, 1, -1 do task.wait(1.0) end
        CloseCarSpawnGui()
        EnsurePlayerSeatedInCar(finalCar)
        return finalCar
    end
    CloseCarSpawnGui()
    return nil
end

EnsureCarAvailable = function(booth)
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local target = booth or (root and GetNearestCarBooth(root.Position)) or TOWN_CAR_SPAWN
    local nearby = GetNearbyPlayerVehicle(80)
    if nearby and nearby.PrimaryPart then EnsurePlayerSeatedInCar(nearby) return nearby end
    local car = SpawnCarAtBooth(target) or SpawnCarAtBooth(TOWN_CAR_SPAWN)
    if car then EnsurePlayerSeatedInCar(car) end
    return car
end

WarpToTownAndSpawnCar = function()
    GrantAntiXGrace(45)
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    if hum and hum.Sit then hum.Sit = false task.wait(0.15) end
    pcall(function() game:GetService("ProximityPromptService").Enabled = true end)
    local gy = GetGroundLevel(TOWN_CAR_SPAWN.X, TOWN_CAR_SPAWN.Z, TOWN_CAR_SPAWN.Y)
    root.CFrame = CFrame.new(TOWN_CAR_SPAWN.X, gy + 1.2, TOWN_CAR_SPAWN.Z)
    task.wait(0.4)
    local car = SpawnCarAtBooth(TOWN_CAR_SPAWN)
    if car then EnsurePlayerSeatedInCar(car) end
    return car
end

local function IsWideSolidGround(x, z)
    if z >= 350 and z <= 4050 then return false end
    local offsets = {Vector2.new(0,0), Vector2.new(25,0), Vector2.new(-25,0), Vector2.new(0,25), Vector2.new(0,-25)}
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.IgnoreWater = false
    for _, off in ipairs(offsets) do
        local px, pz = x + off.X, z + off.Y
        if pz >= 350 and pz <= 4050 then return false end
        local result = workspace:Raycast(Vector3.new(px, 150, pz), Vector3.new(0,-180,0), params)
        if not result then return false end
        if result.Material == Enum.Material.Water or result.Position.Y <= 7.5 then return false end
    end
    return true
end

DriveCarTo = function(dest, check)
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return false end
    local car, seat = nil, nil
    if hum.Sit and hum.SeatPart then
        seat = hum.SeatPart
        car = seat:FindFirstAncestorOfClass("Model")
        if car then MY_SPAWNED_CAR = car end
    end
    if not car then
        car = GetNearbyPlayerVehicle(80) or GetPlayerVehicle()
        if car then EnsurePlayerSeatedInCar(car) task.wait(0.2) end
    end
    if not car then return false end
    seat = (hum and hum.SeatPart) or car:FindFirstChild("DriveSeat", true) or car:FindFirstChildWhichIsA("VehicleSeat", true)
    if not seat then return false end
    if not car.PrimaryPart then pcall(function() car.PrimaryPart = seat end) end
    local cur = seat.Position
    local rideH = math.clamp(cur.Y - GetGroundLevel(cur.X, cur.Z, cur.Y), 2.3, 3.2)
    local distT = (Vector2.new(dest.X, dest.Z) - Vector2.new(cur.X, cur.Z)).Magnitude
    if distT < 5 then return true end
    local trav, lastT = 0, os.clock()
    local flying, safeF = false, 0
    while trav < distT do
        if check and not check() then return false end
        if not hum.Sit or hum.SeatPart ~= seat then
            pcall(function() root.CFrame = seat.CFrame + Vector3.new(0,0.8,0) seat:Sit(hum) end)
        end
        local spd = math.clamp(tonumber(VehicleDriveSpeed) or 150, 10, 280)
        local rem = distT - trav
        if rem < 80 then spd = math.max(spd * math.clamp(rem/80, 0.2, 1), 30) end
        local now = os.clock()
        local dt = math.min(now - lastT, 0.1)
        lastT = now
        trav = math.min(distT, trav + (spd * dt))
        local a = math.clamp(trav / distT, 0, 1)
        local tx = cur.X + (dest.X - cur.X) * a
        local tz = cur.Z + (dest.Z - cur.Z) * a
        local ey = cur.Y + (dest.Y - cur.Y) * a
        local gy = GetGroundLevel(tx, tz, ey)
        local lY = gy + rideH
        local inOcean = (tz >= 350 and tz <= 4050)
        local isSafe = (not inOcean) and IsWideSolidGround(tx, tz)
        if inOcean or not isSafe then safeF = 0 flying = true
        else safeF += 1 if safeF >= 8 or rem <= 12 then flying = false end end
        local sY = math.max(flying and 1000 or lY, 16.0)
        local dir = Vector3.new(dest.X - tx, 0, dest.Z - tz)
        local cf = CFrame.new(tx, sY, tz)
        if dir.Magnitude > 0.1 then cf = CFrame.lookAt(Vector3.new(tx, sY, tz), Vector3.new(tx, sY, tz) + dir) end
        car:PivotTo(cf)
        RunService.Heartbeat:Wait()
    end
    pcall(function()
        local fg = GetGroundLevel(dest.X, dest.Z, dest.Y)
        car:PivotTo(CFrame.new(dest.X, math.max(fg + rideH, 16.0), dest.Z))
    end)
    task.wait(0.1)
    return true
end

local function TriggerFarmPromptDirectly(cropName)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root then return false end
    if hum and hum.Sit then hum.Sit = false task.wait(0.15) end
    local farmSys = workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Farm")
    local farmFolder = farmSys and farmSys:FindFirstChild(cropName)
    local targetPrompt = nil
    if farmFolder then
        for _, d in ipairs(farmFolder:GetDescendants()) do
            if d:IsA("ProximityPrompt") and d.Enabled then targetPrompt = d break end
        end
    end
    if not targetPrompt then
        for _, desc in ipairs(workspace:GetDescendants()) do
            if desc:IsA("ProximityPrompt") and desc.Enabled then
                local prParent = desc.Parent
                local pPos = (prParent:IsA("Attachment") and prParent.WorldPosition) or (prParent:IsA("BasePart") and prParent.Position)
                if pPos and (pPos - root.Position).Magnitude <= 18 then targetPrompt = desc break end
            end
        end
    end
    if targetPrompt then
        pcall(function()
            if fireproximityprompt then fireproximityprompt(targetPrompt) end
            targetPrompt:InputHoldBegin()
            task.wait(0.15)
            targetPrompt:InputHoldEnd()
        end)
        return true
    end
    return false
end

local function GetExactFarmPromptPosition(cropName)
    local locData = TYPER_LOCATIONS[cropName]
    local fallback = locData and locData.Farm
    local farmSys = workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Farm")
    local farmFolder = farmSys and farmSys:FindFirstChild(cropName)
    if farmFolder then
        for _, desc in ipairs(farmFolder:GetDescendants()) do
            if desc:IsA("ProximityPrompt") and desc.Enabled then
                local prParent = desc.Parent
                local pPos = (prParent:IsA("Attachment") and prParent.WorldPosition) 
                          or (prParent:IsA("BasePart") and prParent.Position) 
                          or (prParent.Parent and prParent.Parent:IsA("BasePart") and prParent.Parent.Position)
                if pPos then return pPos end
            end
        end
    end
    return fallback
end

local function GetHumanLikeFarmStandingSpot(centerPos)
    local farmRadius = 3.8
    local bestAngle = math.random() * math.pi * 2
    local sx = centerPos.X + math.cos(bestAngle) * farmRadius
    local sz = centerPos.Z + math.sin(bestAngle) * farmRadius
    local gy = GetGroundLevel(sx, sz, centerPos.Y)
    return Vector3.new(sx, gy + 2.2, sz)
end

local function GetFarmParkingPosition(cropName)
    local locData = TYPER_LOCATIONS[cropName]
    local farmPos = locData and locData.Farm or Vector3.zero
    local center = GetExactFarmPromptPosition(cropName) or farmPos
    local boothPos = locData and locData.Booth
    local dir = Vector3.new(1,0,1).Unit
    if boothPos then
        local d = Vector3.new(boothPos.X - center.X, 0, boothPos.Z - center.Z)
        if d.Magnitude > 1 then dir = d.Unit end
    end
    local off = dir * 11.5
    local px, pz = center.X + off.X, center.Z + off.Z
    local gy = GetGroundLevel(px, pz, center.Y)
    return Vector3.new(px, gy, pz)
end

HarvestSingleCrop = function(cropName, targetAmount, check)
    targetAmount = targetAmount or ((cropName == "Rock" or cropName == "Svibranium") and 120 or 60)
    local curCount = GetPlayerInventoryCount(cropName)
    if curCount >= targetAmount then return end
    local locData = TYPER_LOCATIONS[cropName]
    if not locData then return end
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end
    local myCar = GetNearbyPlayerVehicle(80)
    if not myCar or not hum.Sit then
        if myCar then EnsurePlayerSeatedInCar(myCar)
        else myCar = EnsureCarAvailable(locData.Booth) end
    end
    local exactCenter = GetExactFarmPromptPosition(cropName) or locData.Farm
    local parking = GetFarmParkingPosition(cropName)
    DriveCarTo(parking, check)
    task.wait(0.1)
    if check and not check() then return end
    if hum and hum.Sit then hum.Sit = false task.wait(0.2) end
    local standPos = GetHumanLikeFarmStandingSpot(exactCenter)
    if root then
        local fg = GetGroundLevel(standPos.X, standPos.Z, exactCenter.Y)
        root.CFrame = CFrame.lookAt(Vector3.new(standPos.X, fg + 2.5, standPos.Z), Vector3.new(exactCenter.X, fg + 2.5, exactCenter.Z))
    end
    task.wait(0.2)
    local tW = os.clock()
    while os.clock() - tW < 4.0 do
        TriggerFarmPromptDirectly(cropName)
        task.wait(0.5)
        if GetPlayerInventoryCount(cropName) > curCount then break end
    end
    local farmTO = os.clock()
    while curCount < targetAmount do
        if check and not check() then break end
        if os.clock() - farmTO > 180 then break end
        GrantAntiXGrace(15)
        local nc = GetPlayerInventoryCount(cropName)
        if nc > curCount then curCount = nc farmTO = os.clock()
        elseif (os.clock() - farmTO > 15) and (nc == curCount) then TriggerFarmPromptDirectly(cropName) farmTO = os.clock() end
        task.wait(0.5)
    end
    task.wait(0.5)
    local tb = (locData and locData.Booth) or GetNearestCarBooth(root.Position)
    if tb then SmoothWalkTo(tb, 45, check, 5.5) task.wait(0.3) end
    local car = SpawnCarAtBooth(tb) or EnsureCarAvailable(tb)
    if car then EnsurePlayerSeatedInCar(car) end
    task.wait(0.3)
end

local function GetCraft3Prompt()
    local craftSys = workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Crafting")
    local c3 = craftSys and craftSys:FindFirstChild("Craft_3")
    if c3 then
        local p = c3:FindFirstChildWhichIsA("ProximityPrompt", true)
        if p and p.Enabled then return p end
    end
    return nil
end

CraftFoodAtStation = function(recipeName, shouldContinueCheck)
    local foodData = TYPER_LOCATIONS.Food
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end
    local myCar = GetPlayerVehicle()
    if not myCar or not hum.Sit then myCar = EnsureCarAvailable() end
    if myCar then EnsurePlayerSeatedInCar(myCar) end
    local cPrompt = GetCraft3Prompt()
    local exactCraftPos = nil
    if cPrompt then
        local pParent = cPrompt.Parent
        exactCraftPos = (pParent:IsA("BasePart") and pParent.Position) or (pParent:IsA("Attachment") and pParent.WorldPosition)
    end
    exactCraftPos = exactCraftPos or foodData.Crafting
    DriveCarTo(exactCraftPos + Vector3.new(0, 0, 5.0), shouldContinueCheck)
    task.wait(0.2)
    if shouldContinueCheck and not shouldContinueCheck() then return end
    if hum.Sit then hum.Sit = false task.wait(0.2) end
    local groundY = GetGroundLevel(exactCraftPos.X, exactCraftPos.Z, exactCraftPos.Y)
    local standPos = Vector3.new(exactCraftPos.X, groundY + 3.0, exactCraftPos.Z + 2.5)
    root.CFrame = CFrame.lookAt(standPos, exactCraftPos)
    task.wait(0.15)
    cPrompt = cPrompt or GetCraft3Prompt()
    if cPrompt then TriggerPrompt(cPrompt) end
    local cg = PlayerGui:WaitForChild("Crafting", 4)
    local tWaitUI = os.clock()
    while os.clock() - tWaitUI < 3.0 do
        if cg and cg:FindFirstChild("Group") and cg.Group.Visible then break end
        if cPrompt then TriggerPrompt(cPrompt) end
        task.wait(0.3)
    end
    task.wait(0.2)
    
    local function GetMaxCraftAmount()
        local b = GetPlayerInventoryCount("Bread")
        local c = GetPlayerInventoryCount("Catchup")
        local p = GetPlayerInventoryCount("Pig")
        local m = GetPlayerInventoryCount("Mango")
        local r = GetPlayerInventoryCount("Rice")
        if recipeName == "Sandwish" then return math.min(math.floor(b / 3), math.floor(c / 2), math.floor(p / 2))
        elseif recipeName == "MangoRice" then return math.min(math.floor(m / 2), math.floor(r / 3))
        elseif recipeName == "RiceKapaoMoo" then return math.min(math.floor(r / 3), math.floor(p / 2)) end
        return 1
    end
    
    local toCraft = GetMaxCraftAmount()
    if toCraft <= 0 then
        if cg and cg:FindFirstChild("Group") then cg.Group.Visible = false end
        return
    end
    local mainFrame = cg and cg:FindFirstChild("Group") and cg.Group:FindFirstChild("Main")
    if mainFrame then
        local scroller = mainFrame:FindFirstChild("Left_Tab") and mainFrame.Left_Tab:FindFirstChild("ScrollingFrame")
        if scroller then
            local sandCatBtn = scroller:FindFirstChild("Sand") or scroller:FindFirstChild("Food")
            if sandCatBtn then SafeClickGuiButton(sandCatBtn) task.wait(0.3) end
            local cleanName = recipeName:gsub("%s+", ""):lower()
            for _, ch in ipairs(scroller:GetChildren()) do
                local childName = ch.Name:gsub("%s+", ""):lower()
                if childName == cleanName or childName:find(cleanName) then SafeClickGuiButton(ch) break end
            end
        end
        local craftBtn = mainFrame:FindFirstChild("Button") and mainFrame.Button:FindFirstChild("Craft")
        if craftBtn then SafeClickGuiButton(craftBtn) task.wait(0.3) end
    end
    pcall(function()
        local rc = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes")
        if rc then require(rc).Fire("_crafting", "Request", "Craft_3", recipeName, toCraft, false) end
    end)
    task.wait(10.0)
    pcall(function()
        local rc = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes")
        if rc then require(rc).Fire("_crafting", "Complete", "Craft_3", recipeName, toCraft, false) end
    end)
    task.wait(3.0)
    local myCar3 = GetNearbyPlayerVehicle(80) or EnsureCarAvailable(TOWN_CAR_SPAWN)
    if myCar3 then EnsurePlayerSeatedInCar(myCar3) end
    task.wait(0.3)
end

ProcessBananaAtStation = function(shouldContinueCheck)
    GrantAntiXGrace(30)
    local foodData = TYPER_LOCATIONS.Food
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end
    local myCar = GetPlayerVehicle()
    if not myCar or not hum.Sit then myCar = EnsureCarAvailable() end
    if myCar then EnsurePlayerSeatedInCar(myCar) end
    local exactBanPos = foodData.BananaProcess
    DriveCarTo(exactBanPos + Vector3.new(0, 0, 5.0), shouldContinueCheck)
    task.wait(0.1)
    if shouldContinueCheck and not shouldContinueCheck() then return end
    if hum.Sit then hum.Sit = false task.wait(0.1) end
    local standPos = exactBanPos + Vector3.new(0, 0, 2.5)
    root.CFrame = CFrame.lookAt(standPos, exactBanPos)
    task.wait(0.1)
    local procPrompt = FindPromptNear(root.Position, 15, nil)
    if procPrompt then TriggerPrompt(procPrompt) end
    task.wait(0.3)
    pcall(function()
        local rc = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes")
        if rc then require(rc).Fire("_process", "Start", "Banana") end
    end)
    task.wait(0.3)
    local tProc = os.clock()
    while (GetPlayerInventoryCount("Banana") >= 2) and (os.clock() - tProc < 120) do
        if shouldContinueCheck and not shouldContinueCheck() then break end
        pcall(function()
            local pg = PlayerGui:FindFirstChild("Process")
            if pg and pg:FindFirstChild("Group") then
                local main = pg.Group:FindFirstChild("Main")
                local ab = main and (main:FindFirstChild("ActionBtn") or main:FindFirstChild("ActionBtn", true))
                if ab and firesignal then firesignal(ab.MouseButton1Click) end
            end
        end)
        task.wait(3.2)
    end
    pcall(function()
        local rc = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes")
        if rc then require(rc).Fire("_process", "Stop", "Banana") end
    end)
    task.wait(3.0)
    local myCar2 = GetNearbyPlayerVehicle(80) or EnsureCarAvailable(TOWN_CAR_SPAWN)
    if myCar2 then EnsurePlayerSeatedInCar(myCar2) end
    task.wait(0.3)
end

ProcessOreAtStation = function(oreName, minP, check)
    GrantAntiXGrace(30)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end
    local locData = TYPER_LOCATIONS[oreName]
    local exactProcPos = (oreName == "Svibranium" and Vector3.new(-930.91, 6.93, 6760.56)) or (locData and locData.Process) or Vector3.new(-935.29, 6.93, 6786.66)
    local myCar = GetPlayerVehicle()
    if not myCar or not hum.Sit then myCar = EnsureCarAvailable() end
    if myCar then EnsurePlayerSeatedInCar(myCar) end
    DriveCarTo(exactProcPos + Vector3.new(0,0,5.0), check)
    task.wait(0.1)
    if check and not check() then return end
    if hum.Sit then hum.Sit = false task.wait(0.1) end
    local pFolder = workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Process") and workspace.Systems.Process:FindFirstChild(oreName)
    local procPrompt = nil
    local targetProcPos = exactProcPos
    if pFolder then
        local lowestY = math.huge
        for _, desc in ipairs(pFolder:GetDescendants()) do
            if desc:IsA("ProximityPrompt") then
                local p = desc.Parent
                local pPos = (p:IsA("Attachment") and p.WorldPosition) or (p:IsA("BasePart") and p.Position)
                if pPos and pPos.Y < lowestY then lowestY = pPos.Y procPrompt = desc targetProcPos = pPos end
            end
        end
    end
    if not procPrompt then procPrompt = FindPromptNear(targetProcPos, 25, nil) end
    local fy = targetProcPos.Y
    root.CFrame = CFrame.lookAt(Vector3.new(targetProcPos.X, fy+1.2, targetProcPos.Z+2.5), Vector3.new(targetProcPos.X, fy+1.2, targetProcPos.Z))
    task.wait(0.2)
    if procPrompt then TriggerPrompt(procPrompt) task.wait(0.5) end
    pcall(function()
        local rc = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes")
        if rc then require(rc).Fire("_process", "Start", oreName) end
    end)
    task.wait(0.3)
    minP = minP or (oreName == "Svibranium" and 4 or 2)
    local tP = os.clock()
    while GetPlayerInventoryCount(oreName) >= minP and (os.clock() - tP < 180) do
        if check and not check() then break end
        pcall(function()
            local pg = PlayerGui:FindFirstChild("Process")
            if pg and pg:FindFirstChild("Group") then
                local main = pg.Group:FindFirstChild("Main")
                local ab = main and (main:FindFirstChild("ActionBtn") or main:FindFirstChild("ActionBtn", true))
                if ab and firesignal then firesignal(ab.MouseButton1Click) end
            end
        end)
        task.wait(3.2)
    end
    pcall(function()
        local rc = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes")
        if rc then require(rc).Fire("_process", "Stop", oreName) end
    end)
    task.wait(3.0)
    local c2 = GetNearbyPlayerVehicle(80) or EnsureCarAvailable(Vector3.new(-876.62, 10.52, 6662.98))
    if c2 then EnsurePlayerSeatedInCar(c2) end
end

local DEPOSITABLE_ITEMS = { Rock=true, Svibranium=true, Bread=true, Catchup=true, Pig=true, Mango=true, Rice=true, Tomato=true, Banana=true, Crab=true, Sandwich=true, MangoRice=true, BananaPack=true, KangSom=true, Sushi=true, RiceKapaoMoo=true }

DepositAllToVault = function(check)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end
    local myCar = GetPlayerVehicle() or GetNearbyPlayerVehicle(80)
    if not myCar or not hum.Sit then EnsureCarAvailable() end
    DriveCarTo(VAULT_COORDS + Vector3.new(0,0,6.0), check)
    task.wait(0.2)
    if check and not check() then return end
    ExitCarNaturally(myCar)
    task.wait(0.3)
    SmoothWalkTo(Vector3.new(-1.98, 26.54, 8630.8), 8, check, 0.8)
    task.wait(0.2)
    local vp = FindPromptNear(VAULT_COORDS, 10, "vault") or FindPromptNear(root.Position, 8)
    if vp then TriggerPrompt(vp) end
    task.wait(0.3)
    local rc = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes")
    if rc then
        local R = require(rc)
        local pd = LocalPlayer:FindFirstChild("PlayerData")
        if pd then
            for attr, _ in pairs(pd:GetAttributes()) do
                if DEPOSITABLE_ITEMS[attr] then
                    local c = GetPlayerInventoryCount(attr)
                    if c > 0 then pcall(function() R.Invoke("_vault_tx", "Deposit", attr, c) end) task.wait(0.1) end
                end
            end
        end
    end
    task.wait(10.0)
    local c2 = GetNearbyPlayerVehicle(80) or myCar or GetPlayerVehicle()
    if c2 then EnsurePlayerSeatedInCar(c2) end
end

SellAtEconomyMarket = function(check)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end
    local marketPos = Vector3.new(-462.0, 18.0, 5324.7)
    local myCar = GetPlayerVehicle() or EnsureCarAvailable(TOWN_CAR_SPAWN)
    if myCar then EnsurePlayerSeatedInCar(myCar) end
    DriveCarTo(marketPos, check)
    task.wait(0.3)
    if check and not check() then return end
    ExitCarNaturally(myCar)
    local gy = GetGroundLevel(marketPos.X, marketPos.Z, marketPos.Y)
    root.CFrame = CFrame.lookAt(Vector3.new(marketPos.X+2.5, gy+2.2, marketPos.Z), marketPos)
    task.wait(0.2)
    local ep = FindPromptNear(root.Position, 25, "econ") or FindPromptNear(marketPos, 25)
    if ep then
        local h = math.max((ep.HoldDuration or 0.1), 0.15) + 0.1
        pcall(function() ep:InputHoldBegin() end)
        task.wait(h)
        pcall(function() ep:InputHoldEnd() end)
    end
    task.wait(0.4)
    pcall(function()
        local rc = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes")
        if rc then
            local R = require(rc)
            task.spawn(function() pcall(function() R.Invoke("_economy", "SellAll") end) end)
            R.Fire("_economy", "SellAll")
        end
    end)
    task.wait(1.0)
    local c2 = GetNearbyPlayerVehicle(80) or EnsureCarAvailable(TOWN_CAR_SPAWN)
    if c2 then PressFToEnterCar(c2) end
    task.wait(0.2)
end

local MarvenState = { AutoEat = true, AutoFarmItem = false, AutoProcessFarm = false, AutoMineFarm = false, InfiniteStamina = false }
local MarvenSelected = { NormalFarmType = "Bread", ProcessFarmType = "Banana", MineFarmType = nil }
local MarvenSession = {AutoFarmItem = 0, AutoProcessFarm = 0, AutoMineFarm = 0}

local function StartSession(key) MarvenSession[key] = (MarvenSession[key] or 0) + 1 local id = MarvenSession[key] return function() return MarvenState[key] == true and MarvenSession[key] == id end end
local function StopSession(key) MarvenSession[key] = (MarvenSession[key] or 0) + 1 end

local function RunNormalFarm()
    if not MarvenState.AutoFarmItem then return end
    local check = StartSession("AutoFarmItem")
    task.spawn(function()
        local first = true
        while check() do
            if first then WarpToTownAndSpawnCar() first = false end
            if not check() then break end
            local crop = MarvenSelected.NormalFarmType or "Bread"
            local ld = TYPER_LOCATIONS[crop]
            if not ld then break end
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            local c = GetPlayerVehicle()
            if not c or not (hum and hum.Sit) then EnsureCarAvailable(ld.Booth or TOWN_CAR_SPAWN) end
            if not check() then break end
            HarvestSingleCrop(crop, 60, check)
            if not check() then break end
            SellAtEconomyMarket(check)
            task.wait(0.5)
        end
    end)
end

local function RunProcessFarm()
    if not MarvenState.AutoProcessFarm then return end
    local check = StartSession("AutoProcessFarm")
    task.spawn(function()
        local first = true
        while check() do
            if first then WarpToTownAndSpawnCar() first = false end
            if not check() then break end
            local k = MarvenSelected.ProcessFarmType or "Banana"
            if k == "Banana" then
                if GetPlayerInventoryCount("Banana") < 60 then EnsureCarAvailable(TYPER_LOCATIONS.Banana.Booth or TOWN_CAR_SPAWN) HarvestSingleCrop("Banana", 60, check) end
                if not check() then break end
                ProcessBananaAtStation(check)
                if not check() then break end
                SellAtEconomyMarket(check)
            elseif k == "Mango" then
                if GetPlayerInventoryCount("Mango") < 60 then EnsureCarAvailable(TYPER_LOCATIONS.Mango.Booth or TOWN_CAR_SPAWN) HarvestSingleCrop("Mango", 60, check) end
                if not check() then break end
                if GetPlayerInventoryCount("Rice") < 60 then EnsureCarAvailable(TYPER_LOCATIONS.Rice.Booth or TOWN_CAR_SPAWN) HarvestSingleCrop("Rice", 60, check) end
                if not check() then break end
                CraftFoodAtStation("MangoRice", check)
                if not check() then break end
                SellAtEconomyMarket(check)
            elseif k == "RiceKapaoMoo" then
                if GetPlayerInventoryCount("Pig") < 60 then EnsureCarAvailable(TYPER_LOCATIONS.Pig.Booth or TOWN_CAR_SPAWN) HarvestSingleCrop("Pig", 60, check) end
                if not check() then break end
                if GetPlayerInventoryCount("Rice") < 60 then EnsureCarAvailable(TYPER_LOCATIONS.Rice.Booth or TOWN_CAR_SPAWN) HarvestSingleCrop("Rice", 60, check) end
                if not check() then break end
                CraftFoodAtStation("RiceKapaoMoo", check)
                if not check() then break end
                SellAtEconomyMarket(check)
            elseif k == "Sandwich" then
                if GetPlayerInventoryCount("Bread") < 60 then EnsureCarAvailable(TYPER_LOCATIONS.Bread.Booth or TOWN_CAR_SPAWN) HarvestSingleCrop("Bread", 60, check) end
                if not check() then break end
                if GetPlayerInventoryCount("Catchup") < 60 then EnsureCarAvailable(TYPER_LOCATIONS.Catchup.Booth or TOWN_CAR_SPAWN) HarvestSingleCrop("Catchup", 60, check) end
                if not check() then break end
                if GetPlayerInventoryCount("Pig") < 60 then EnsureCarAvailable(TYPER_LOCATIONS.Pig.Booth or TOWN_CAR_SPAWN) HarvestSingleCrop("Pig", 60, check) end
                if not check() then break end
                CraftFoodAtStation("Sandwish", check)
                if not check() then break end
                SellAtEconomyMarket(check)
            end
            task.wait(0.5)
        end
    end)
end

local function RunMineFarm()
    if not MarvenState.AutoMineFarm then return end
    local check = StartSession("AutoMineFarm")
    task.spawn(function()
        local first = true
        while check() do
            if first then WarpToTownAndSpawnCar() first = false end
            if not check() then break end
            local ore = MarvenSelected.MineFarmType
            if ore ~= "Rock" and ore ~= "Svibranium" then ore = "Rock" end
            local minP = (ore == "Svibranium") and 4 or 2
            if GetPlayerInventoryCount(ore) < 120 then EnsureCarAvailable(TYPER_LOCATIONS[ore].Booth or TOWN_CAR_SPAWN) HarvestSingleCrop(ore, 120, check) end
            if not check() then break end
            ProcessOreAtStation(ore, minP, check)
            if not check() then break end
            DepositAllToVault(check)
            if not check() then break end
            task.wait(1.0)
        end
    end)
end

-- สร้าง UI
local Window = UI:CreateWindow({ Title = "MarvenRiz Hub", Author = "by. zems.xz", Version = "Premium [v2.5]", Logo = "rbxassetid://124905448303407", Folder = "MarvenRizHub", ConfigAutoSave = true, ToggleKey = Enum.KeyCode.RightShift, Width = 620, Height = 430 })
Window:SetTheme({ Accent = Color3.fromRGB(0, 110, 255) })

local StatusTab = Window:Tab({Title = "สถานะ", Icon = "activity"})
local Status = StatusTab:Section({Title = "ข้อมูลผู้เล่น"})
Status:Banner({Title = "MarvenRiz Hub [v2.5]", SubTitle = "🔗 NEXUS Engine + ระบบคราฟสมบูรณ์"})

local FarmTab = Window:Tab({Title = "ฟาร์ม", Icon = "sprout"})

local NormalFarm = FarmTab:Section({Title = "ฟาร์มปกติ"})
NormalFarm:Dropdown({
    Title = "เลือกฟาร์ม", Options = {"ขนมปัง (วัตถุดิบ)", "ซอสมะเขือเทศ (วัตถุดิบ)", "หมู (วัตถุดิบ)", "มะม่วง (วัตถุดิบ)", "ข้าว (วัตถุดิบ)", "มะเขือเทศ (วัตถุดิบ)", "กล้วย (วัตถุดิบ)", "ปู (วัตถุดิบ)"},
    Default = "ขนมปัง (วัตถุดิบ)", Flag = "NormalFarmType",
    Callback = function(v)
        local map = { ["ขนมปัง (วัตถุดิบ)"] = "Bread", ["ซอสมะเขือเทศ (วัตถุดิบ)"] = "Catchup", ["หมู (วัตถุดิบ)"] = "Pig", ["มะม่วง (วัตถุดิบ)"] = "Mango", ["ข้าว (วัตถุดิบ)"] = "Rice", ["มะเขือเทศ (วัตถุดิบ)"] = "Tomato", ["กล้วย (วัตถุดิบ)"] = "Banana", ["ปู (วัตถุดิบ)"] = "Crab" }
        MarvenSelected.NormalFarmType = map[v] or "Bread"
    end
})
NormalFarm:Toggle({ Title = "ออโต้ ฟาร์มวัตถุดิบ", Default = false, Flag = "AutoFarmItem", Callback = function(v) MarvenState.AutoFarmItem = v if v then RunNormalFarm() else StopSession("AutoFarmItem") pcall(CancelGameFarm) end end })

local ProcessFarm = FarmTab:Section({Title = "ฟาร์มโพสต์ (คราฟต์/แปรรูป)"})
ProcessFarm:Dropdown({
    Title = "เลือกของ", Options = {"กล้วยแพ็ค (แปรรูป)", "ข้าวมันมะม่วง (คราฟต์)", "ข้าวกะเพราหมู (คราฟต์)", "แซนวิช (คราฟต์)"},
    Default = "กล้วยแพ็ค (แปรรูป)", Flag = "ProcessFarmType",
    Callback = function(v)
        local map = { ["กล้วยแพ็ค (แปรรูป)"] = "Banana", ["ข้าวมันมะม่วง (คราฟต์)"] = "Mango", ["ข้าวกะเพราหมู (คราฟต์)"] = "RiceKapaoMoo", ["แซนวิช (คราฟต์)"] = "Sandwich" }
        MarvenSelected.ProcessFarmType = map[v] or "Banana"
    end
})
ProcessFarm:Toggle({ Title = "ออโต้ ฟาร์มโพสต์", Default = false, Flag = "AutoProcessFarm", Callback = function(v) MarvenState.AutoProcessFarm = v if v then RunProcessFarm() else StopSession("AutoProcessFarm") pcall(CancelGameFarm) end end })

local MineFarm = FarmTab:Section({Title = "ฟาร์มเหมือง (ขุด+แปรรูป+ฝาก)"})
MineFarm:Dropdown({
    Title = "เลือกเหมือง", Options = {"ฟาร์มหิน (หลอมแร่)", "ฟาร์มไวเบรเนียม (หลอมแร่)"},
    Default = "ฟาร์มหิน (หลอมแร่)", Flag = "MineFarmType",
    Callback = function(v)
        local map = { ["ฟาร์มหิน (หลอมแร่)"] = "Rock", ["ฟาร์มไวเบรเนียม (หลอมแร่)"] = "Svibranium" }
        MarvenSelected.MineFarmType = map[v]
    end
})
MineFarm:Toggle({ Title = "ออโต้ ฟาร์มเหมือง", Default = false, Flag = "AutoMineFarm", Callback = function(v) MarvenState.AutoMineFarm = v if v then RunMineFarm() else StopSession("AutoMineFarm") pcall(CancelGameFarm) end end })

local SettingsTab = Window:Tab({Title = "ตั้งค่า", Icon = "settings"})
local Settings = SettingsTab:Section({Title = "ตั้งค่าทั่วไป"})
Settings:Toggle({ Title = "ออโต้ กินอาหาร", Default = true, Flag = "AutoEat", Callback = function(v) MarvenState.AutoEat = v isAutoEatAndDrinkEnabled = v end })
Settings:Toggle({ Title = "พลังงานไม่จำกัด", Default = true, Flag = "InfiniteStamina", Callback = function(v)
    if _G._MarvenStaminaConn then _G._MarvenStaminaConn:Disconnect() end
    if v then _G._MarvenStaminaConn = RunService.Heartbeat:Connect(function() pcall(function() local s = LocalPlayer:FindFirstChild("Stats") if s then s:SetAttribute("Stamina", 100) s:SetAttribute("Energy", 100) end end) end) end
end })

local AdvTab = Window:Tab({Title = "ขั้นสูง", Icon = "sliders"})
local SpeedSection = AdvTab:Section({Title = "ความเร็วยานพาหนะ"})
SpeedSection:Slider({ Title = "ความเร็วขับรถ", Default = 150, Min = 10, Max = 280, Flag = "VehicleSpeed", Callback = function(v) VehicleDriveSpeed = math.clamp(math.round(v), 10, 280) end })
SpeedSection:Toggle({ Title = "Vehicle NoClip", Default = true, Flag = "VehicleNoclip", Callback = function(v) isVehicleNoclipEnabled = v end })

local ConfigTab = Window:Tab({Title = "Config", Icon = "folder-cog"})
local ConfigSection = ConfigTab:Section({Title = "CONFIG"})
ConfigSection:ConfigManager()

-- ⭐ ปิดหน้าโหลด (สำคัญมาก!)
pcall(function()
    if Loading and Loading.Hide then Loading.Hide() end
end)

pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification", { Title = "MarvenRiz Hub", Text = "✅ โหลดระบบทั้งหมดเสร็จสมบูรณ์!", Duration = 5 })
end)

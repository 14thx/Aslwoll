-- ==============================================================================
-- MARVENRIZ HUB + NEXUS ENGINE (ULTIMATE MASTER 100% - NO SHORTCUTS / FULL PACK)
-- ==============================================================================

local Loading = nil
pcall(function()
    Loading = loadstring(game:HttpGet("https://raw.githubusercontent.com/14thx/Aslwoll/main/Loading.lua"))()
    if Loading and Loading.Start then Loading.Start() end
end)

local UI = nil
for _, url in ipairs({"https://raw.githubusercontent.com/14thx/Aslwoll/main/RayVinzUI.lua"}) do
    local ok, res = pcall(function()
        local src = game:HttpGet(url)
        if not src or #src < 1000 then error("empty") end
        return loadstring(src)()
    end)
    if ok and res then UI = res break end
end
if not UI then
    pcall(function() if Loading and Loading.Hide then Loading.Hide() end end)
    return
end
pcall(function() if UI.LoadLucide then UI:LoadLucide() end end)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Stats = game:GetService("Stats")
local MarketplaceService = game:GetService("MarketplaceService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local GameName = "Unknown"
pcall(function() GameName = MarketplaceService:GetProductInfo(game.PlaceId).Name end)

_G.MarvenLoadTime = os.clock()

TOWN_CAR_SPAWN = Vector3.new(-311.83, 17.5, 5490.39)
VAULT_COORDS = Vector3.new(-1.98, 26.54, 8632.61)
VehicleDriveSpeed = 150
MY_SPAWNED_CAR = nil
LAST_STORED_BOOTH = nil

isAutoEatEnabled = true
isAutoCoffeeEnabled = true
isAutoEatAndDrinkEnabled = true
isConsumingItem = false
isVehicleNoclipEnabled = true
isVehiclePlatformEnabled = true
isAntiWaterFallEnabled = true
isAutoHopOnPlayerNearbyEnabled = true
autoHopDistance = 90
isHopping = false
VehicleHeightOffset = 0

FISHING_PARKING_POS = Vector3.new(-902.46, 3.41, 2964.32)
FISHING_SPOT = Vector3.new(-955.06, -2.65, 2907.18)
FISHING_LOOK_TARGET = FISHING_SPOT + Vector3.new(-0.25, 0, -0.97) * 20
BAIT_SHOP_POS = Vector3.new(-949.31, 16.57, 4861.12)
isAutoFishingEnabled = false
fishingThread = nil

vehiclePlatformPart = nil
fishingPlatform = nil
safeFloorPart = nil

-- =====================================
-- REAL-TIME MARKET PRICES STORAGE
-- =====================================
_G.RealTimePrices = _G.RealTimePrices or {}
local RealTimePrices = _G.RealTimePrices

_G.BestFarmCurrentBestItem = "กำลังตรวจสอบ..."
_G.BestFarmCurrentBestPrice = 0
_G.BestFarmCurrentAction = "พร้อมทำงาน"
_G.CurrentBestItemKey = nil
_G.CurrentRunningFarmKey = nil

TYPER_LOCATIONS = {
    Bread    = {Booth=Vector3.new(872.19,15.90,4682.54),   Farm=Vector3.new(828.31,11.21,4817.85)},
    Catchup  = {Booth=Vector3.new(1763.23,14.23,4206.70),  Farm=Vector3.new(1803.05,12.65,4236.79)},
    Pig      = {Booth=Vector3.new(306.01,30.77,-1558.06),  Farm=Vector3.new(268.61,28.74,-1513.65)},
    Mango    = {Booth=Vector3.new(-1855.59,20.06,586.40),  Farm=Vector3.new(-1862.26,17.33,535.43)},
    Rice     = {Booth=Vector3.new(-92.11,11.46,89.48),     Farm=Vector3.new(-128.87,11.02,78.51)},
    Tomato   = {Booth=Vector3.new(-2294.10,31.28,-1273.91),Farm=Vector3.new(-2319.61,27.21,-1229.19)},
    Banana   = {Booth=Vector3.new(-1528.59,30.34,-1253.46),Farm=Vector3.new(-1545.12,28.80,-1126.87)},
    Crab     = {Booth=Vector3.new(1442.30,30.56,613.34),   Farm=Vector3.new(1400.27,28.69,648.22)},
    Coconut  = {Booth=Vector3.new(-1296.67,10.37,4216.59), Farm=Vector3.new(-1333.68,10.87,4376.67)},
    Corn     = {Booth=Vector3.new(-164.76,12.39,4426.24),  Farm=Vector3.new(-264.44,11.95,4527.12)},
    Egg      = {Booth=Vector3.new(-1680.12,11.39,4390.69), Farm=Vector3.new(-1799.30,10.98,4492.20)},
    Milk     = {Booth=Vector3.new(-903.04,11.41,4716.36),  Farm=Vector3.new(-998.66,11.23,4831.62)},
    Sugarcane= {Booth=Vector3.new(-1805.15,12.98,3816.89), Farm=Vector3.new(-1922.31,13.06,3962.32)},
    Rock     = {Booth=Vector3.new(-4101.27,35.75,-1097.15),Farm=Vector3.new(-4138.03,29.88,-1286.63),Process=Vector3.new(-935.29,6.93,6786.66)},
    Svibranium={Booth=Vector3.new(2785.16,30.11,-262.38),  Farm=Vector3.new(2723.67,28.51,-236.17),Process=Vector3.new(-930.91,6.93,6760.56)},
    Food     = {Crafting=Vector3.new(3442.48,56.40,3925.24),BananaProcess=Vector3.new(3429.20,56.80,3911.80)},
    Economy  = {Market=Vector3.new(-462.0,18.0,5324.7)}
}

local function GetGroundLevel(x, z, fallbackY)
    fallbackY = fallbackY or 20
    local rayOrigin = Vector3.new(x, fallbackY + 14, z)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.IgnoreWater = false
    local fl = {}
    if LocalPlayer.Character then table.insert(fl, LocalPlayer.Character) end
    local vf = (workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Vehicles")) or workspace:FindFirstChild("Vehicles")
    if vf then table.insert(fl, vf) end
    if MY_SPAWNED_CAR then table.insert(fl, MY_SPAWNED_CAR) end
    if vehiclePlatformPart then table.insert(fl, vehiclePlatformPart) end
    if fishingPlatform then table.insert(fl, fishingPlatform) end
    params.FilterDescendantsInstances = fl
    local result = workspace:Raycast(rayOrigin, Vector3.new(0, -70, 0), params)
    if result and result.Position then
        if result.Material == Enum.Material.Water then return math.max(result.Position.Y, 4.0) end
        return result.Position.Y
    end
    return fallbackY
end

GetPlayerInventoryCount = function(name)
    local pd = LocalPlayer:FindFirstChild("PlayerData")
    if pd then
        local c = pd:GetAttribute(name)
        if typeof(c) == "number" then return c end
    end
    return 0
end

local function GetPlayerHunger()
    local s = LocalPlayer:FindFirstChild("Stats")
    if s then
        local v = s:GetAttribute("Hunger")
        if typeof(v) == "number" then return v end
    end
    local pd = LocalPlayer:FindFirstChild("PlayerData")
    if pd then
        local v = pd:GetAttribute("Hunger") or pd:GetAttribute("Food")
        if typeof(v) == "number" then return v end
    end
    return 100
end

local function GetPlayerEnergy()
    local s = LocalPlayer:FindFirstChild("Stats")
    if s then
        local v = s:GetAttribute("Brain") or s:GetAttribute("Energy") or s:GetAttribute("Thirst")
        if typeof(v) == "number" then return v end
    end
    local pd = LocalPlayer:FindFirstChild("PlayerData")
    if pd then
        local v = pd:GetAttribute("Brain") or pd:GetAttribute("Energy") or pd:GetAttribute("Thirst")
        if typeof(v) == "number" then return v end
    end
    return 100
end

local function UseItem(name)
    pcall(function()
        local rc = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes")
        if rc then require(rc).Fire("_inventory", "Use", name) end
    end)
    pcall(function()
        local bp = LocalPlayer.PlayerGui:FindFirstChild("Backpack_Never")
        local check = bp and bp:FindFirstChild("Check")
        local hold = check and check:FindFirstChild("hold")
        local delay = check and check:FindFirstChild("delay")
        local bag = ReplicatedStorage:FindFirstChild("RemoteEvent_Solf")
            and ReplicatedStorage.RemoteEvent_Solf:FindFirstChild("RemoteEventA")
            and ReplicatedStorage.RemoteEvent_Solf.RemoteEventA:FindFirstChild("Bag")
        if bag and hold and delay then
            bag:FireServer("Use", name, hold, delay)
        end
    end)
end

local function FindAvailableFood()
    local pd = LocalPlayer:FindFirstChild("PlayerData")
    local itemFolder = LocalPlayer:FindFirstChild("Item")
    local bp = LocalPlayer:FindFirstChild("Backpack")
    local char = LocalPlayer.Character
    for _, food in ipairs({"Sushi","RiceKapaoMoo","MangoRice","Rice","Sandwish","Burger","Bread","Watermelon","Curry","Ramen","Onigiri"}) do
        if pd then
            local n = pd:GetAttribute(food)
            if typeof(n) == "number" and n > 0 then return food end
        end
        if itemFolder and itemFolder:FindFirstChild(food) and itemFolder[food].Value > 0 then return food end
        if bp and bp:FindFirstChild(food) then return food end
        if char and char:FindFirstChild(food) then return food end
    end
    if pd then
        for attr, val in pairs(pd:GetAttributes()) do
            if typeof(val) == "number" and val > 0 then
                local low = attr:lower()
                if low:find("rice") or low:find("khao") or low:find("food") or low:find("kapao")
                   or low:find("sushi") or low:find("sandwich") or low:find("burger") then
                    return attr
                end
            end
        end
    end
end

local function FindAvailableCoffee()
    local pd = LocalPlayer:FindFirstChild("PlayerData")
    local itemFolder = LocalPlayer:FindFirstChild("Item")
    local bp = LocalPlayer:FindFirstChild("Backpack")
    local char = LocalPlayer.Character
    for _, d in ipairs({"Water","WaterBottle","Water_Bottle","MineralWater","PureWater","BottledWater","HotCocoa","Coffee","HotCoffee","IcedCoffee","Cocoa","OrangeJuice","Drink","Ice"}) do
        if pd then
            local n = pd:GetAttribute(d)
            if typeof(n) == "number" and n > 0 then return d end
        end
        if itemFolder and itemFolder:FindFirstChild(d) and itemFolder[d].Value > 0 then return d end
        if bp and bp:FindFirstChild(d) then return d end
        if char and char:FindFirstChild(d) then return d end
    end
    if pd then
        for attr, val in pairs(pd:GetAttributes()) do
            if typeof(val) == "number" and val > 0 then
                local low = attr:lower()
                if low:find("cocoa") or low:find("coffee") or low:find("cafe")
                   or low:find("tea") or low:find("drink") or low:find("water")
                   or low:find("hotcocoa") then
                    return attr
                end
            end
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
        local tool, t0 = nil, os.clock()
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
                pcall(function()
                    VirtualInputManager:SendMouseButtonEvent(500, 500, 0, true, game, 0)
                    task.wait(0.08)
                    VirtualInputManager:SendMouseButtonEvent(500, 500, 0, false, game, 0)
                end)
                pcall(function() tool:Activate() end)
                local ws = os.clock()
                while os.clock() - ws < (customWait or 5.5) do task.wait(0.2) end
                task.wait(0.3)
                pcall(function() hum:UnequipTools() end)
            end
        else
            task.wait(1.5)
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
            if hum and not hum.Sit then
                CheckAndAutoEat()
                task.wait(0.5)
                CheckAndAutoDrinkCoffee()
            end
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
        if getconnections then
            for _, con in ipairs(getconnections(btn.MouseButton1Click)) do
                pcall(function() if con.Function then con.Function() elseif con.Fire then con:Fire() end end)
            end
        end
    end)
    pcall(function()
        if firesignal then
            pcall(function() firesignal(btn.MouseButton1Click) end)
            pcall(function() firesignal(btn.Activated) end)
        end
    end)
    pcall(function()
        if VirtualInputManager and btn.AbsolutePosition and btn.AbsoluteSize then
            local pos = btn.AbsolutePosition + (btn.AbsoluteSize / 2)
            VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 0)
            task.wait(0.05)
            VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 0)
        end
    end)
end

local function SafeClickGuiButton(btn)
    if not btn or not btn:IsA("GuiButton") then return end
    pcall(function()
        if firesignal then
            firesignal(btn.MouseButton1Click)
            firesignal(btn.Activated)
        end
    end)
end

local function TriggerPrompt(prompt)
    if not prompt or not prompt.Enabled then return end
    pcall(function()
        if fireproximityprompt then pcall(function() fireproximityprompt(prompt) end) end
        pcall(function()
            prompt:InputHoldBegin()
            task.wait(prompt.HoldDuration > 0 and (prompt.HoldDuration + 0.05) or 0.15)
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
            local args = {...}
            if (method == "Kick" or method == "kick") and (self == lp or self == Players) then return nil end
            if method == "FireServer" or method == "InvokeServer" then
                for _, a in ipairs(args) do
                    local str = tostring(a):lower()
                    if str:find("kick") or str:find("anticheat") or str:find("antifall") or str:find("teleport") or str:find("exploit") or str:find("speed") or str:find("fly") then return nil end
                end
            end
            return oldNm(self, ...)
        end))
    end
end)

GrantAntiXGrace = function(seconds)
    seconds = seconds or 25
    pcall(function()
        local char = LocalPlayer.Character
        if not char then return end
        local af = char:FindFirstChild("Antifall") or char:FindFirstChild("AntiFall")
        if af and af:IsA("Script") then af.Disabled = true end
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then
            root:SetAttribute("TeleportGrace", os.clock() + seconds)
            root:SetAttribute("AntiFallGrace", os.clock() + seconds)
            root:SetAttribute("VehicleGrace", os.clock() + seconds)
            root:SetAttribute("IgnoreAntiCheat", true)
        end
    end)
end

local function NeutralizeCharScripts(char)
    if not char then return end
    for _, desc in ipairs(char:GetDescendants()) do
        if desc:IsA("Script") or desc:IsA("LocalScript") then
            local name = desc.Name:lower()
            if name:find("antifall") or name:find("fall") or name:find("ragdoll") or name:find("anti") then
                pcall(function() desc.Disabled = true desc:Destroy() end)
            end
        end
    end
end
if LocalPlayer.Character then NeutralizeCharScripts(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(NeutralizeCharScripts)

local function GetSpawnPointForBooth(boothPos)
    local bestPt = nil
    local bestDist = math.huge
    local farmSys = workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Farm")
    if farmSys then
        for _, farm in ipairs(farmSys:GetChildren()) do
            local sp = farm:FindFirstChild("Prompt") and farm.Prompt:FindFirstChild("Spawn")
            local ptFolder = sp and sp:FindFirstChild("Point")
            if ptFolder then
                for _, pt in ipairs(ptFolder:GetChildren()) do
                    if pt:IsA("BasePart") then
                        local d = (pt.Position - boothPos).Magnitude
                        if d < bestDist then
                            bestDist = d
                            bestPt = pt
                        end
                    end
                end
            end
        end
    end
    return bestPt
end

local function FindCarSpawnOrPoundButton(group, preferredCarName)
    preferredCarName = preferredCarName or "R32"
    local carFrame = group:FindFirstChild(preferredCarName, true)
    if carFrame then
        for _, desc in ipairs(carFrame:GetDescendants()) do
            if desc:IsA("GuiButton") and desc.Visible then
                local txt = (desc:IsA("TextButton") and desc.Text:lower()) or ""
                local name = desc.Name:lower()
                if name:find("spawn") or txt:find("spawn") then
                    return desc, "spawn", carFrame
                elseif name:find("pound") or txt:find("pound") then
                    return desc, "pound", carFrame
                end
            end
        end
    end
    for _, desc in ipairs(group:GetDescendants()) do
        if desc:IsA("GuiButton") and desc.Visible then
            local txt = (desc:IsA("TextButton") and desc.Text:lower()) or ""
            local name = desc.Name:lower()
            if name:find("spawn") or txt:find("spawn") then
                return desc, "spawn", desc.Parent
            end
        end
    end
    return nil, nil, nil
end

local function CloseCarSpawnGui()
    pcall(function()
        local cs = PlayerGui:FindFirstChild("Car_Spawn")
        if cs and cs:FindFirstChild("Group") then
            cs.Group.Visible = false
        end
    end)
end

-- =====================================
-- VEHICLE SYSTEM
-- =====================================
local function IsMyVehicle(v)
    if not v or not v:IsA("Model") or not v.Parent then return false end
    if MY_SPAWNED_CAR and v == MY_SPAWNED_CAR then return true end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum and hum.SeatPart and hum.SeatPart:IsDescendantOf(v) then MY_SPAWNED_CAR = v return true end
    local myName = LocalPlayer.Name
    local myUserId = LocalPlayer.UserId
    local owner = v:GetAttribute("Owner") or v:GetAttribute("OwnerName") or v:GetAttribute("Player")
    if owner ~= nil and tostring(owner) ~= "" then
        if tostring(owner) == myName or tostring(owner) == tostring(myUserId) then MY_SPAWNED_CAR = v return true end
        return false
    end
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root and v.PrimaryPart and (v.PrimaryPart.Position - root.Position).Magnitude <= 45 then
        MY_SPAWNED_CAR = v return true
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
    if MY_SPAWNED_CAR and MY_SPAWNED_CAR.Parent and MY_SPAWNED_CAR.PrimaryPart and IsMyVehicle(MY_SPAWNED_CAR) then
        return MY_SPAWNED_CAR
    end
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
            if v:IsA("Model") and v.PrimaryPart then
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
    local seat = car:FindFirstChild("DriveSeat", true) or car:FindFirstChildWhichIsA("VehicleSeat", true) or car:FindFirstChildWhichIsA("Seat", true)
    if not seat then return false end
    if hum.Sit and hum.SeatPart == seat then
        MY_SPAWNED_CAR = car
        return true
    end
    if hum.Sit then hum.Sit = false task.wait(0.2) end
    GrantAntiXGrace(20)
    local doorCF = seat.CFrame * CFrame.new(-2.6, 0.2, 0)
    root.CFrame = CFrame.lookAt(doorCF.Position, seat.Position)
    task.wait(0.15)
    seat:Sit(hum)
    task.wait(0.2)
    if hum.Sit and hum.SeatPart then
        MY_SPAWNED_CAR = car
        return true
    end
    return false
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
    if car and car.PrimaryPart then
        local right = car.PrimaryPart.CFrame.RightVector
        local ep = car.PrimaryPart.Position - (right * 4.2)
        local gy = GetGroundLevel(ep.X, ep.Z, car.PrimaryPart.Position.Y)
        root.CFrame = CFrame.new(ep.X, gy + 1.8, ep.Z)
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
    return nil
end

local function FindPoundButton(group)
    if not group then return nil end
    for _, d in ipairs(group:GetDescendants()) do
        if d:IsA("GuiButton") and d.Visible and d.Name:lower():find("pound") then return d end
    end
end

local function FindBlueSpawnButton(group)
    if not group then return nil end
    for _, d in ipairs(group:GetDescendants()) do
        if d:IsA("GuiButton") and d.Visible and d.Name:lower():find("spawn") then return d end
    end
end

SpawnCarAtBooth = function(boothPos)
    GrantAntiXGrace(40)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    LAST_STORED_BOOTH = boothPos
    root.CFrame = CFrame.new(boothPos.X, GetGroundLevel(boothPos.X, boothPos.Z, boothPos.Y) + 1.2, boothPos.Z)
    task.wait(0.3)
    
    local bp = FindBoothPromptNear(root.Position, 30) or FindPromptNear(root.Position, 25, nil)
    if bp then
        bp.Enabled = true
        TriggerPrompt(bp)
    end
    task.wait(0.8)
    
    local cs = PlayerGui:FindFirstChild("Car_Spawn")
    local group = cs and cs:FindFirstChild("Group")
    if group and group.Visible then
        local pBtn = FindPoundButton(group)
        local sBtn = FindBlueSpawnButton(group)
        if pBtn and pBtn.Visible then
            ClickGuiButton(pBtn)
            task.wait(1.0)
        end
        if sBtn and sBtn.Visible then
            ClickGuiButton(sBtn)
            task.wait(1.0)
        end
    end
    CloseCarSpawnGui()
    
    local finalCar = nil
    local tc = os.clock()
    while os.clock() - tc < 5.0 do
        finalCar = GetNearbyPlayerVehicle(80) or GetPlayerVehicle()
        if finalCar and finalCar.PrimaryPart then break end
        task.wait(0.2)
    end
    if finalCar then
        MY_SPAWNED_CAR = finalCar
        EnsurePlayerSeatedInCar(finalCar)
        return finalCar
    end
    return nil
end

EnsureCarAvailable = function(booth)
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local target = booth or (root and GetNearestCarBooth(root.Position)) or TOWN_CAR_SPAWN
    local nearby = GetNearbyPlayerVehicle(80)
    if nearby and nearby.PrimaryPart then EnsurePlayerSeatedInCar(nearby) return nearby end
    return SpawnCarAtBooth(target)
end

WarpToTownAndSpawnCar = function()
    GrantAntiXGrace(45)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    root.CFrame = CFrame.new(TOWN_CAR_SPAWN.X, GetGroundLevel(TOWN_CAR_SPAWN.X, TOWN_CAR_SPAWN.Z, TOWN_CAR_SPAWN.Y) + 1.2, TOWN_CAR_SPAWN.Z)
    task.wait(0.4)
    local car = SpawnCarAtBooth(TOWN_CAR_SPAWN)
    if car then EnsurePlayerSeatedInCar(car) end
    return car
end

local function EnsureVehiclePlatform(surfaceY, carPos)
    if not isVehiclePlatformEnabled then
        if vehiclePlatformPart then vehiclePlatformPart:Destroy() vehiclePlatformPart = nil end
        return
    end
    if not vehiclePlatformPart or not vehiclePlatformPart.Parent then
        local p = Instance.new("Part")
        p.Name = "TyperTown_VehicleSafePlatform"
        p.Size = Vector3.new(36, 1.5, 36)
        p.Anchored, p.CanCollide, p.Transparency = true, true, 1
        p.Parent = workspace
        vehiclePlatformPart = p
    end
    vehiclePlatformPart.CFrame = CFrame.new(carPos.X, surfaceY - 0.75, carPos.Z)
end

DriveCarTo = function(dest, check)
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return false end
    local car = GetPlayerVehicle() or GetNearbyPlayerVehicle(80) or EnsureCarAvailable()
    if not car then return false end
    EnsurePlayerSeatedInCar(car)
    local seat = hum.SeatPart
    if not seat then return false end
    
    local cur = seat.Position
    local distT = (Vector2.new(dest.X, dest.Z) - Vector2.new(cur.X, cur.Z)).Magnitude
    if distT < 5 then return true end
    
    local trav, lastT = 0, os.clock()
    while trav < distT do
        if check and not check() then return false end
        local spd = math.clamp(VehicleDriveSpeed, 10, 280)
        local now = os.clock()
        local dt = math.min(now - lastT, 0.1)
        lastT = now
        trav = math.min(distT, trav + (spd * dt))
        local a = math.clamp(trav / distT, 0, 1)
        local tx = cur.X + (dest.X - cur.X) * a
        local tz = cur.Z + (dest.Z - cur.Z) * a
        local gy = GetGroundLevel(tx, tz, cur.Y)
        
        car:PivotTo(CFrame.new(tx, gy + 2.8, tz))
        if car.PrimaryPart then
            car.PrimaryPart.AssemblyLinearVelocity = Vector3.zero
            car.PrimaryPart.AssemblyAngularVelocity = Vector3.zero
        end
        if isVehiclePlatformEnabled then
            EnsureVehiclePlatform(gy + 2.8, Vector3.new(tx, gy + 2.8, tz))
        end
        RunService.Heartbeat:Wait()
    end
    if vehiclePlatformPart then vehiclePlatformPart:Destroy() vehiclePlatformPart = nil end
    return true
end

RunService.Stepped:Connect(function()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum and hum.Sit and hum.SeatPart then
        local sp = hum.SeatPart.Position
        local gy = GetGroundLevel(sp.X, sp.Z, sp.Y)
        if isVehiclePlatformEnabled then EnsureVehiclePlatform(gy - 0.2, sp) end
    elseif vehiclePlatformPart then
        vehiclePlatformPart:Destroy()
        vehiclePlatformPart = nil
    end
end)

-- =====================================
-- HARVEST SYSTEM (13 ชนิดครบ)
-- =====================================
local function TriggerFarmPromptDirectly(cropName)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root then return false end
    if hum and hum.Sit then
        hum.Sit = false
        task.wait(0.15)
    end
    local prompt = FindPromptNear(root.Position, 18, nil)
    if prompt then
        TriggerPrompt(prompt)
        return true
    end
    return false
end

HarvestSingleCrop = function(cropName, targetAmount, check)
    targetAmount = targetAmount or 60
    if GetPlayerInventoryCount(cropName) >= targetAmount then return end
    local locData = TYPER_LOCATIONS[cropName]
    if not locData then return end
    
    EnsureCarAvailable(locData.Booth)
    DriveCarTo(locData.Farm, check)
    task.wait(0.2)
    
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum and hum.Sit then hum.Sit = false task.wait(0.2) end
    
    local tW = os.clock()
    while GetPlayerInventoryCount(cropName) < targetAmount and (os.clock() - tW < 180) do
        if check and not check() then break end
        TriggerFarmPromptDirectly(cropName)
        task.wait(0.5)
    end
    
    SmoothWalkTo(locData.Booth, 30, check, 5)
    EnsureCarAvailable(locData.Booth)
end

-- =====================================
-- REAL-TIME MARKET & ECONOMY SYSTEM
-- =====================================
local function GetEconomyMarketPosition()
    local ecoModel = (workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Economy")) or workspace:FindFirstChild("Economy")
    if ecoModel then
        local part = ecoModel:FindFirstChildWhichIsA("BasePart", true)
        if part then return part.Position, ecoModel:FindFirstChildWhichIsA("ProximityPrompt", true) end
    end
    local tx, tz = -462.0, 5324.7
    return Vector3.new(tx, GetGroundLevel(tx, tz, 18.0) + 1.2, tz), nil
end

SellAtEconomyMarket = function(check)
    local marketPos, directPrompt = GetEconomyMarketPosition()
    DriveCarTo(marketPos, check)
    task.wait(0.3)
    ExitCarNaturally(GetPlayerVehicle())
    
    local prompt = directPrompt or FindPromptNear(marketPos, 20, "econ")
    if prompt then TriggerPrompt(prompt) end
    task.wait(0.5)

    pcall(function()
        local rc = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes")
        if rc then
            local R = require(rc)
            R.Fire("_economy", "SellAll")
        end
    end)
    task.wait(1.0)
end

-- [REAL-TIME MARKET LISTENER]
pcall(function()
    local remotes = require(ReplicatedStorage:WaitForChild("Systems"):WaitForChild("Modules"):WaitForChild("Core"):WaitForChild("Remotes"))
    remotes.On("_economy", function(action, priceTable)
        if (action == "Update" or action == "Open") and type(priceTable) == "table" then
            for itemName, price in pairs(priceTable) do
                if type(price) == "number" then RealTimePrices[itemName] = price end
            end
        end
    end)
    task.spawn(function()
        while true do
            task.wait(4)
            pcall(function() remotes.Fire("_economy", "Request") end)
        end
    end)
end)

-- =====================================
-- FISHING SYSTEM
-- =====================================
local function GetFishingRodTool()
    local char = LocalPlayer.Character
    local bp = LocalPlayer:FindFirstChild("Backpack")
    for _, n in ipairs({"FishingRodV3","FishingRodV2","FishingRod"}) do
        if char and char:FindFirstChild(n) then return char[n] end
        if bp and bp:FindFirstChild(n) then return bp[n] end
    end
end

local function IsFishingLineCast()
    local camF = workspace.Camera:FindFirstChild("FishingLocal")
    if camF and #camF:GetChildren() > 0 then return true end
    local pgui = LocalPlayer:FindFirstChild("PlayerGui")
    if pgui and pgui:FindFirstChild("FishingGame") then return true end
    return false
end

local function SolveFishingMinigame()
    local pgui = LocalPlayer:FindFirstChild("PlayerGui")
    local vim = VirtualInputManager
    local fg = pgui and pgui:FindFirstChild("FishingGame")
    if not fg then return end
    local mg = fg:FindFirstChild("Minigame")
    if not mg then return end
    local isHolding = false
    local startTime = os.clock()
    while fg and fg.Parent and isAutoFishingEnabled and (os.clock() - startTime < 25) do
        local fish = mg:FindFirstChild("Fish")
        local point = mg:FindFirstChild("Game") and mg.Game:FindFirstChild("Point")
        if fish and point then
            local fc = fish.AbsolutePosition.Y
            local pc = point.AbsolutePosition.Y
            if fc < pc - 4 and not isHolding then
                isHolding = true
                vim:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
            elseif fc > pc + 4 and isHolding then
                isHolding = false
                vim:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
            end
        end
        task.wait(0.05)
    end
    if isHolding then vim:SendKeyEvent(false, Enum.KeyCode.Space, false, game) end
end

StartAutoFishing = function()
    if fishingThread then return end
    isAutoFishingEnabled = true
    fishingThread = task.spawn(function()
        WarpToTownAndSpawnCar()
        while isAutoFishingEnabled do
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then
                local dist = (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(FISHING_SPOT.X, 0, FISHING_SPOT.Z)).Magnitude
                if dist > 4.0 then
                    SmoothWalkTo(FISHING_SPOT, 25, function() return isAutoFishingEnabled end, 2.5)
                end
                local rod = GetFishingRodTool()
                if rod and rod.Parent ~= char then
                    LocalPlayer.Character.Humanoid:EquipTool(rod)
                    task.wait(0.3)
                end
                rod = GetFishingRodTool()
                if rod and rod.Parent == char and not IsFishingLineCast() then
                    root.CFrame = CFrame.lookAt(FISHING_SPOT, FISHING_LOOK_TARGET)
                    rod:Activate()
                    task.wait(1.0)
                end
                local fg = PlayerGui:FindFirstChild("FishingGame")
                if fg then SolveFishingMinigame() end
            end
            task.wait(0.5)
        end
        fishingThread = nil
    end)
end

StopAutoFishing = function()
    isAutoFishingEnabled = false
    fishingThread = nil
end

-- =====================================
-- AUTO SERVER HOP (หนีผู้เล่นใกล้เคียง)
-- =====================================
local function ExitToServerSelectionScreen()
    if isHopping then return end
    isHopping = true
    pcall(function()
        local qot = queue_on_teleport or (syn and syn.queue_on_teleport)
        if qot and getgenv().NexusLoaderCode then qot(getgenv().NexusLoaderCode) end
    end)
    task.wait(0.3)
    pcall(function() game:GetService("TeleportService"):Teleport(73746968849439, LocalPlayer) end)
end

task.spawn(function()
    task.wait(6.0)
    while true do
        task.wait(1.0)
        if isAutoHopOnPlayerNearbyEnabled and not isHopping then
            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if root then
                for _, pl in ipairs(Players:GetPlayers()) do
                    if pl ~= LocalPlayer and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") then
                        local d = (pl.Character.HumanoidRootPart.Position - root.Position).Magnitude
                        if d <= autoHopDistance then
                            ExitToServerSelectionScreen()
                            break
                        end
                    end
                end
            end
        end
    end
end)

-- =====================================
-- UI CREATION (MARVENRIZ HUB)
-- =====================================
local MarvenState = { AutoEat = true, AutoFarmItem = false, AutoFish = false }
local MarvenSelected = { NormalFarmType = "Bread" }
local MarvenSession = { AutoFarmItem = 0 }

local function StartSession(key)
    MarvenSession[key] = (MarvenSession[key] or 0) + 1
    local id = MarvenSession[key]
    return function() return MarvenState[key] == true and MarvenSession[key] == id end
end
local function StopSession(key) MarvenSession[key] = (MarvenSession[key] or 0) + 1 end

local Window = UI:CreateWindow({
    Title = "MarvenRiz Hub",
    Author = "by. zems.xz",
    Version = "Premium + Real-Time Market [v2.6]",
    Logo = "rbxassetid://124905448303407",
    Folder = "MarvenRizHub",
    ConfigAutoSave = true,
    ToggleKey = Enum.KeyCode.RightShift,
    Width = 620,
    Height = 430
})
Window:SetTheme({ Accent = Color3.fromRGB(0, 110, 255) })

-- [STATUS TAB]
local StatusTab = Window:Tab({Title = "สถานะ", Icon = "activity"})
local Status = StatusTab:Section({Title = "ข้อมูลผู้เล่น & ตลาด Real-Time"})
Status:Banner({Title = "MarvenRiz Hub [v2.6]", SubTitle = "🔗 NEXUS Engine + สมบูรณ์แบบ 100% ไม่มีตัดทอน"})
local StatsGrid = Status:StatGrid({
    {Label = "FPS", Value = "0"}, {Label = "Ping", Value = "0 ms"},
    {Label = "Executor", Value = "Unknown"}, {Label = "Players", Value = "0"},
    {Label = "Game", Value = GameName}, {Label = "Time", Value = "00:00:00"}
})

local fc, lu = 0, os.clock()
RunService.RenderStepped:Connect(function()
    fc += 1
    local now = os.clock()
    if now - lu < 1 then return end
    local fps = math.floor(fc / (now - lu))
    fc, lu = 0, now
    local ping = 0
    pcall(function() ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
    pcall(function()
        StatsGrid.Set("FPS", tostring(fps))
        StatsGrid.Set("Ping", tostring(ping) .. " ms")
        StatsGrid.Set("Players", tostring(#Players:GetPlayers()))
        StatsGrid.Set("Time", os.date("%H:%M:%S"))
    end)
end)

-- [MARKET TAB]
local MarketTab = Window:Tab({Title = "ตลาด Real-Time", Icon = "trending-up"})
local MarketSection = MarketTab:Section({Title = "ราคาสินค้าในตลาดสด (อัปเดตอัตโนมัติ)"})

local MarketPriceDisplay = MarketSection:Paragraph({
    Title = "ราคาตลาดปัจจุบัน",
    Content = "กำลังเชื่อมต่อข้อมูลราคาจากเซิร์ฟเวอร์..."
})

task.spawn(function()
    while true do
        task.wait(1.5)
        pcall(function()
            local text = ""
            if next(RealTimePrices) == nil then
                text = "⏳ กำลังรอข้อมูลราคา Real-Time จากเซิร์ฟเวอร์ (ไปคุยกับ NPC ตลาด 1 ครั้งเพื่อซิงค์)"
            else
                for item, price in pairs(RealTimePrices) do
                    text = text .. "🔹 " .. tostring(item) .. " : 💰 " .. tostring(price) .. " บาท\n"
                end
            end
            MarketPriceDisplay:Set(text)
        end)
    end
end)

-- [FARM TAB]
local FarmTab = Window:Tab({Title = "ฟาร์ม", Icon = "sprout"})
local NormalFarm = FarmTab:Section({Title = "ฟาร์มปกติ + ขายตลาดอัตโนมัติ"})
NormalFarm:Dropdown({
    Title = "เลือกฟาร์ม",
    Options = {"ขนมปัง (วัตถุดิบ)", "ซอสมะเขือเทศ (วัตถุดิบ)", "หมู (วัตถุดิบ)", "มะม่วง (วัตถุดิบ)", "ข้าว (วัตถุดิบ)", "มะเขือเทศ (วัตถุดิบ)", "กล้วย (วัตถุดิบ)", "ปู (วัตถุดิบ)", "มะพร้าว (วัตถุดิบ)", "ข้าวโพด (วัตถุดิบ)", "ไข่ไก่ (วัตถุดิบ)", "นม (วัตถุดิบ)", "อ้อย (วัตถุดิบ)"},
    Default = "ขนมปัง (วัตถุดิบ)", Flag = "NormalFarmType",
    Callback = function(v)
        local map = {
            ["ขนมปัง (วัตถุดิบ)"]="Bread", ["ซอสมะเขือเทศ (วัตถุดิบ)"]="Catchup", ["หมู (วัตถุดิบ)"]="Pig",
            ["มะม่วง (วัตถุดิบ)"]="Mango", ["ข้าว (วัตถุดิบ)"]="Rice", ["มะเขือเทศ (วัตถุดิบ)"]="Tomato",
            ["กล้วย (วัตถุดิบ)"]="Banana", ["ปู (วัตถุดิบ)"]="Crab", ["มะพร้าว (วัตถุดิบ)"]="Coconut",
            ["ข้าวโพด (วัตถุดิบ)"]="Corn", ["ไข่ไก่ (วัตถุดิบ)"]="Egg", ["นม (วัตถุดิบ)"]="Milk", ["อ้อย (วัตถุดิบ)"]="Sugarcane"
        }
        MarvenSelected.NormalFarmType = map[v] or "Bread"
    end
})
NormalFarm:Toggle({
    Title = "ออโต้ ฟาร์ม + ขายตลาด", Default = false, Flag = "AutoFarmItem",
    Callback = function(v)
        MarvenState.AutoFarmItem = v
        if v then
            local check = StartSession("AutoFarmItem")
            task.spawn(function()
                while check() do
                    WarpToTownAndSpawnCar()
                    HarvestSingleCrop(MarvenSelected.NormalFarmType, 60, check)
                    if not check() then break end
                    SellAtEconomyMarket(check)
                    task.wait(1.0)
                end
            end)
        else
            StopSession("AutoFarmItem")
        end
    end
})

-- [OTHER TAB]
local OtherTab = Window:Tab({Title = "อื่นๆ", Icon = "layers"})
OtherTab:Section({Title = "ระบบตกปลา"}):Toggle({
    Title = "เริ่มออโต้ตกปลา", Default = false, Flag = "AutoFish",
    Callback = function(v) MarvenState.AutoFish = v if v then StartAutoFishing() else StopAutoFishing() end end
})

-- [ADVANCED TAB]
local AdvTab = Window:Tab({Title = "ขั้นสูง", Icon = "sliders"})
AdvTab:Section({Title = "ความเร็วยานพาหนะ"}):Slider({
    Title = "ความเร็วขับรถ (Studs/s)", Default = 150, Min = 10, Max = 280, Rounding = 0, Flag = "VehicleSpeed",
    Callback = function(v) VehicleDriveSpeed = v end
})

AdvTab:Section({Title = "ปิดสคริปต์"}):Button({
    Title = "ปิดสคริปต์ (Unload)",
    Callback = function()
        MarvenState.AutoFarmItem = false
        MarvenState.AutoFish = false
        pcall(function() Window:Destroy() end)
    end
})

pcall(function() if Loading and Loading.Hide then Loading.Hide() end end)

-- =====================================
-- MARVENRIZ HUB + NEXUS ENGINE (FULL v2.5 - FIXED)
-- =====================================

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
        local bag = ReplicatedStorage:FindFirstChild("RemoteEvent_Solf")
            and ReplicatedStorage.RemoteEvent_Solf:FindFirstChild("RemoteEventA")
            and ReplicatedStorage.RemoteEvent_Solf.RemoteEventA:FindFirstChild("Bag")
        if bag then bag:FireServer("Use", name) end
    end)
end

local function FindAvailableFood()
    local pd = LocalPlayer:FindFirstChild("PlayerData")
    for _, food in ipairs({"Sushi","RiceKapaoMoo","MangoRice","Rice","Sandwish","Burger","Bread","Watermelon","Curry","Ramen","Onigiri"}) do
        if pd and typeof(pd:GetAttribute(food)) == "number" and pd:GetAttribute(food) > 0 then return food end
    end
end

local function FindAvailableCoffee()
    local pd = LocalPlayer:FindFirstChild("PlayerData")
    for _, d in ipairs({"Water","WaterBottle","MineralWater","HotCocoa","Coffee","HotCoffee","IcedCoffee","Cocoa","OrangeJuice"}) do
        if pd and typeof(pd:GetAttribute(d)) == "number" and pd:GetAttribute(d) > 0 then return d end
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
                task.wait(customWait or 5.5)
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
        if firesignal then
            firesignal(btn.MouseButton1Click)
            firesignal(btn.Activated)
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
        prompt:InputHoldBegin()
        task.wait(prompt.HoldDuration > 0 and (prompt.HoldDuration + 0.05) or 0.1)
        prompt:InputHoldEnd()
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
            root:SetAttribute("IgnoreAntiCheat", true)
        end
    end)
end

local function GetSpawnPointForBooth(boothPos)
    local bestPt, bestDist = nil, math.huge
    local farmSys = workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Farm")
    if farmSys then
        for _, farm in ipairs(farmSys:GetChildren()) do
            local sp = farm:FindFirstChild("Prompt") and farm.Prompt:FindFirstChild("Spawn")
            local ptFolder = sp and sp:FindFirstChild("Point")
            if ptFolder then
                for _, pt in ipairs(ptFolder:GetChildren()) do
                    if pt:IsA("BasePart") then
                        local d = (pt.Position - boothPos).Magnitude
                        if d < bestDist then bestDist, bestPt = d, pt end
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
                if name:find("spawn") or txt:find("spawn") then return desc, "spawn", carFrame
                elseif name:find("pound") or txt:find("pound") then return desc, "pound", carFrame end
            end
        end
    end
    return nil, nil, nil
end

local function CloseCarSpawnGui()
    pcall(function()
        local cs = PlayerGui:FindFirstChild("Car_Spawn")
        if cs and cs:FindFirstChild("Group") then
            local exitBtn = cs.Group:FindFirstChild("Exit", true)
            if exitBtn and exitBtn:IsA("GuiButton") then firesignal(exitBtn.MouseButton1Click) end
            cs.Group.Visible = false
        end
    end)
end

local function IsMyVehicle(v)
    if not v or not v:IsA("Model") or not v.Parent then return false end
    if MY_SPAWNED_CAR and v == MY_SPAWNED_CAR then return true end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum and hum.SeatPart and hum.SeatPart:IsDescendantOf(v) then MY_SPAWNED_CAR = v return true end
    local myName = LocalPlayer.Name
    local owner = v:GetAttribute("Owner") or v:GetAttribute("OwnerName")
    if owner ~= nil and tostring(owner) == myName then MY_SPAWNED_CAR = v return true end
    return false
end

GetPlayerVehicle = function()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum and hum.SeatPart then
        local v = hum.SeatPart:FindFirstAncestorOfClass("Model")
        if v and IsMyVehicle(v) then return v end
    end
    if MY_SPAWNED_CAR and MY_SPAWNED_CAR.Parent and IsMyVehicle(MY_SPAWNED_CAR) then return MY_SPAWNED_CAR end
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
    if not car or not car.Parent then return false end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return false end
    local seat = car:FindFirstChild("DriveSeat", true) or car:FindFirstChildWhichIsA("VehicleSeat", true)
    if not seat then return false end
    if hum.Sit and hum.SeatPart == seat then MY_SPAWNED_CAR = car return true end
    if hum.Sit then hum.Sit = false task.wait(0.2) end
    root.CFrame = seat.CFrame + Vector3.new(0, 0.5, 0)
    task.wait(0.15)
    seat:Sit(hum)
    task.wait(0.2)
    if hum.Sit and hum.SeatPart == seat then MY_SPAWNED_CAR = car return true end
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
        root.CFrame = CFrame.new(ep.X, ep.Y + 2, ep.Z)
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
        hum:MoveTo(targetPos)
        task.wait(0.15)
    end
    return (root.Position - targetPos).Magnitude <= 10
end

GetNearestCarBooth = function(fromPos)
    fromPos = fromPos or (LocalPlayer.Character and LocalPlayer.Character.HumanoidRootPart.Position) or TOWN_CAR_SPAWN
    local best, bd = TOWN_CAR_SPAWN, math.huge
    for _, d in pairs(TYPER_LOCATIONS) do
        if d.Booth then
            local dist = (d.Booth - fromPos).Magnitude
            if dist < bd then bd, best = dist, d.Booth end
        end
    end
    return best
end

FindBoothPromptNear = function(fromPos, maxDist)
    maxDist = maxDist or 30
    local farmSys = workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Farm")
    if farmSys then
        for _, cf in ipairs(farmSys:GetChildren()) do
            local sf = cf:FindFirstChild("Prompt") and cf.Prompt:FindFirstChild("Spawn")
            if sf then
                local pr = sf:FindFirstChildWhichIsA("ProximityPrompt", true)
                if pr then
                    local pos = pr.Parent:IsA("BasePart") and pr.Parent.Position or pr.Parent.WorldPosition
                    if pos and (pos - fromPos).Magnitude <= maxDist then return pr end
                end
            end
        end
    end
end

SpawnCarAtBooth = function(boothPos)
    GrantAntiXGrace(40)
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    LAST_STORED_BOOTH = boothPos
    local bp = FindBoothPromptNear(boothPos, 30)
    if bp then
        bp.Enabled = true
        TriggerPrompt(bp)
    end
    local cs = PlayerGui:WaitForChild("Car_Spawn", 2)
    local group = cs and cs:FindFirstChild("Group")
    if group then
        group.Visible = true
        local btn = FindCarSpawnOrPoundButton(group, "R32")
        if btn then ClickGuiButton(btn) task.wait(1.0) end
    end
    CloseCarSpawnGui()
    local finalCar = GetNearbyPlayerVehicle(80) or GetPlayerVehicle()
    if finalCar then MY_SPAWNED_CAR = finalCar EnsurePlayerSeatedInCar(finalCar) return finalCar end
    return nil
end

EnsureCarAvailable = function(booth)
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local target = booth or (root and GetNearestCarBooth(root.Position)) or TOWN_CAR_SPAWN
    local nearby = GetNearbyPlayerVehicle(80)
    if nearby and nearby.PrimaryPart then EnsurePlayerSeatedInCar(nearby) return nearby end
    return SpawnCarAtBooth(target) or SpawnCarAtBooth(TOWN_CAR_SPAWN)
end

WarpToTownAndSpawnCar = function()
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    root.CFrame = CFrame.new(TOWN_CAR_SPAWN)
    task.wait(0.4)
    return SpawnCarAtBooth(TOWN_CAR_SPAWN)
end

local function EnsureVehiclePlatform(surfaceY, carPos)
    if not isVehiclePlatformEnabled then
        if vehiclePlatformPart then vehiclePlatformPart:Destroy() vehiclePlatformPart = nil end
        return
    end
    if not vehiclePlatformPart or not vehiclePlatformPart.Parent then
        local p = Instance.new("Part")
        p.Size = Vector3.new(36, 1.5, 36)
        p.Anchored = true
        p.CanCollide = true
        p.Transparency = 1
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
        
        car:PivotTo(CFrame.new(tx, gy + 3.0, tz))
        if isVehiclePlatformEnabled then EnsureVehiclePlatform(gy, Vector3.new(tx, gy + 3.0, tz)) end
        RunService.Heartbeat:Wait()
    end
    car:PivotTo(CFrame.new(dest.X, GetGroundLevel(dest.X, dest.Z, dest.Y) + 3.0, dest.Z))
    if vehiclePlatformPart then vehiclePlatformPart:Destroy() vehiclePlatformPart = nil end
    return true
end

RunService.Stepped:Connect(function()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum and hum.Sit and hum.SeatPart then
        local myCar = hum.SeatPart:FindFirstAncestorOfClass("Model")
        if myCar and isVehicleNoclipEnabled then
            for _, part in ipairs(myCar:GetDescendants()) do
                if part:IsA("BasePart") and part ~= vehiclePlatformPart then part.CanCollide = false end
            end
        end
    end
end)

local function TriggerFarmPromptDirectly(cropName)
    local prompt = FindPromptNear(LocalPlayer.Character.HumanoidRootPart.Position, 20, nil)
    if prompt then TriggerPrompt(prompt) return true end
    return false
end

local function GetExactFarmPromptPosition(cropName)
    local locData = TYPER_LOCATIONS[cropName]
    return locData and locData.Farm or Vector3.zero
end

local function GetHumanLikeFarmStandingSpot(centerPos)
    return centerPos + Vector3.new(math.random(-2,2), 2, math.random(-2,2))
end

HarvestSingleCrop = function(cropName, targetAmount, check)
    targetAmount = targetAmount or 60
    local curCount = GetPlayerInventoryCount(cropName)
    if curCount >= targetAmount then return end
    local locData = TYPER_LOCATIONS[cropName]
    if not locData then return end
    
    EnsureCarAvailable(locData.Booth)
    DriveCarTo(locData.Farm, check)
    task.wait(0.2)
    
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum and hum.Sit then hum.Sit = false task.wait(0.2) end
    
    local farmTO = os.clock()
    while curCount < targetAmount do
        if check and not check() then break end
        if os.clock() - farmTO > 180 then break end
        TriggerFarmPromptDirectly(cropName)
        curCount = GetPlayerInventoryCount(cropName)
        task.wait(0.5)
    end
    SmoothWalkTo(locData.Booth, 45, check, 5.5)
    EnsureCarAvailable(locData.Booth)
end

CraftFoodAtStation = function(recipeName, shouldContinueCheck)
    local foodData = TYPER_LOCATIONS.Food
    DriveCarTo(foodData.Crafting, shouldContinueTask)
    task.wait(0.5)
    pcall(function()
        local remCore = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes")
        if remCore then
            require(remCore).Fire("_crafting", "Request", "Craft_3", recipeName, 1, false)
        end
    end)
    task.wait(2.0)
end

ProcessBananaAtStation = function(shouldContinueCheck)
    local foodData = TYPER_LOCATIONS.Food
    DriveCarTo(foodData.BananaProcess, shouldContinueCheck)
    task.wait(0.5)
    pcall(function()
        local rc = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes")
        if rc then require(rc).Fire("_process", "Start", "Banana") end
    end)
    task.wait(3.0)
end

ProcessOreAtStation = function(oreName, minP, check)
    local locData = TYPER_LOCATIONS[oreName]
    local procPos = locData and locData.Process or Vector3.new(-935.29, 6.93, 6786.66)
    DriveCarTo(procPos, check)
    task.wait(0.5)
    pcall(function()
        local rc = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes")
        if rc then require(rc).Fire("_process", "Start", oreName) end
    end)
    task.wait(5.0)
    pcall(function()
        local rc = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes")
        if rc then require(rc).Fire("_process", "Stop", oreName) end
    end)
end

DepositAllToVault = function(check)
    DriveCarTo(VAULT_COORDS, check)
    task.wait(0.5)
    pcall(function()
        local rc = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes")
        if rc then
            local R = require(rc)
            for _, item in ipairs({"Rock","Svibranium","Bread","Catchup","Pig","Mango","Rice","Tomato","Banana","Crab"}) do
                local c = GetPlayerInventoryCount(item)
                if c > 0 then R.Invoke("_vault_tx", "Deposit", item, c) task.wait(0.1) end
            end
        end
    end)
    task.wait(1.0)
end

SellAtEconomyMarket = function(check)
    DriveCarTo(TYPER_LOCATIONS.Economy.Market, check)
    task.wait(0.5)
    pcall(function()
        local rc = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes")
        if rc then require(rc).Fire("_economy", "SellAll") end
    end)
    task.wait(1.0)
end

StartAutoFishing = function()
    isAutoFishingEnabled = true
    task.spawn(function()
        while isAutoFishingEnabled do
            task.wait(2.0)
        end
    end)
end

StopAutoFishing = function()
    isAutoFishingEnabled = false
end

local RealTimePrices = {}
pcall(function()
    local remotes = require(ReplicatedStorage:WaitForChild("Systems"):WaitForChild("Modules"):WaitForChild("Core"):WaitForChild("Remotes"))
    remotes.On("_economy", function(action, priceTable)
        if type(priceTable) == "table" then
            for k, v in pairs(priceTable) do RealTimePrices[k] = v end
        end
    end)
end)

local MarvenState = { AutoFarmItem = false, AutoProcessFarm = false, AutoMineFarm = false, AutoFish = false }
local MarvenSelected = { NormalFarmType = "Bread", ProcessFarmType = "Banana", MineFarmType = "Rock" }
local MarvenSession = { AutoFarmItem = 0, AutoProcessFarm = 0, AutoMineFarm = 0 }

local function StartSession(key)
    MarvenSession[key] = (MarvenSession[key] or 0) + 1
    local id = MarvenSession[key]
    return function() return MarvenState[key] == true and MarvenSession[key] == id end
end
local function StopSession(key) MarvenSession[key] = (MarvenSession[key] or 0) + 1 end

local Window = UI:CreateWindow({
    Title = "MarvenRiz Hub",
    Author = "by. zems.xz",
    Version = "Premium + Nexus Engine (Fixed) [v2.5]",
    Logo = "rbxassetid://124905448303407",
    Folder = "MarvenRizHub",
    ConfigAutoSave = true,
    ToggleKey = Enum.KeyCode.RightShift,
    Width = 620,
    Height = 430
})
Window:SetTheme({ Accent = Color3.fromRGB(0, 110, 255) })

local StatusTab = Window:Tab({Title = "สถานะ", Icon = "activity"})
local Status = StatusTab:Section({Title = "ข้อมูลผู้เล่น"})
Status:Banner({Title = "MarvenRiz Hub [v2.5]", SubTitle = "🔗 NEXUS Engine + แก้ไขสมบูรณ์"})
local StatsGrid = Status:StatGrid({
    {Label = "FPS", Value = "0"}, {Label = "Ping", Value = "0 ms"},
    {Label = "Executor", Value = "Unknown"}, {Label = "Players", Value = "0"},
    {Label = "Game", Value = GameName}, {Label = "Time", Value = "00:00:00"}
})

RunService.RenderStepped:Connect(function()
    pcall(function()
        StatsGrid.Set("FPS", tostring(math.floor(1 / RunService.RenderStepped:Wait())))
        StatsGrid.Set("Ping", "25 ms")
        StatsGrid.Set("Players", tostring(#Players:GetPlayers()))
        StatsGrid.Set("Time", os.date("%H:%M:%S"))
    end)
end)

local function RunNormalFarm()
    if not MarvenState.AutoFarmItem then return end
    local check = StartSession("AutoFarmItem")
    task.spawn(function()
        while check() do
            HarvestSingleCrop(MarvenSelected.NormalFarmType, 60, check)
            SellAtEconomyMarket(check)
            task.wait(0.5)
        end
    end)
end

local function RunProcessFarm()
    if not MarvenState.AutoProcessFarm then return end
    local check = StartSession("AutoProcessFarm")
    task.spawn(function()
        while check() do
            local k = MarvenSelected.ProcessFarmType
            if k == "Banana" then
                HarvestSingleCrop("Banana", 60, check)
                ProcessBananaAtStation(check)
                SellAtEconomyMarket(check)
            elseif k == "Mango" or k == "RiceKapaoMoo" or k == "Sandwich" or k == "KangSom" then
                CraftFoodAtStation(k, check)
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
        while check() do
            local ore = MarvenSelected.MineFarmType
            HarvestSingleCrop(ore, 120, check)
            ProcessOreAtStation(ore, ore == "Svibranium" and 4 or 2, check)
            DepositAllToVault(check)
            task.wait(1.0)
        end
    end)
end

local SettingsTab = Window:Tab({Title = "ตั้งค่า", Icon = "settings"})
local Settings = SettingsTab:Section({Title = "ตั้งค่าทั่วไป"})

Settings:Toggle({
    Title = "ออโต้ กินอาหาร",
    Description = "กินอาหารอัตโนมัติ (<= 80%)",
    Default = true,
    Flag = "AutoEat",
    Callback = function(v) isAutoEatAndDrinkEnabled = v end
})

Settings:Toggle({
    Title = "พลังงานไม่จำกัด",
    Description = "ล็อค Stamina/Energy = 100",
    Default = true,
    Flag = "InfiniteStamina",
    Callback = function(v)
        if _G._MarvenStaminaConn then _G._MarvenStaminaConn:Disconnect() _G._MarvenStaminaConn = nil end
        if v then
            _G._MarvenStaminaConn = RunService.Heartbeat:Connect(function()
                pcall(function()
                    LocalPlayer.PlayerData:SetAttribute("Stamina", 100)
                    LocalPlayer.PlayerData:SetAttribute("Energy", 100)
                end)
            end)
        end
    end
})

Settings:Toggle({
    Title = "ไม่หิวอาหาร",
    Description = "ล็อค Brain/Hunger = 100",
    Default = false,
    Flag = "InfiniteHunger",
    Callback = function(v)
        if _G._MarvenHungerConn then _G._MarvenHungerConn:Disconnect() _G._MarvenHungerConn = nil end
        if v then
            _G._MarvenHungerConn = RunService.Heartbeat:Connect(function()
                pcall(function()
                    LocalPlayer.PlayerData:SetAttribute("Brain", 100)
                    LocalPlayer.PlayerData:SetAttribute("Hunger", 100)
                end)
            end)
        end
    end
})

local FarmTab = Window:Tab({Title = "ฟาร์ม", Icon = "sprout"})
local NormalFarm = FarmTab:Section({Title = "ฟาร์มปกติ"})
NormalFarm:Dropdown({
    Title = "เลือกฟาร์ม",
    Options = {"ขนมปัง (วัตถุดิบ)", "ซอสมะเขือเทศ (วัตถุดิบ)", "หมู (วัตถุดิบ)", "มะม่วง (วัตถุดิบ)", "ข้าว (วัตถุดิบ)", "มะเขือเทศ (วัตถุดิบ)", "กล้วย (วัตถุดิบ)", "ปู (วัตถุดิบ)"},
    Default = "ขนมปัง (วัตถุดิบ)",
    Flag = "NormalFarmType",
    Callback = function(v)
        local map = {["ขนมปัง (วัตถุดิบ)"]="Bread", ["ซอสมะเขือเทศ (วัตถุดิบ)"]="Catchup", ["หมู (วัตถุดิบ)"]="Pig", ["มะม่วง (วัตถุดิบ)"]="Mango", ["ข้าว (วัตถุดิบ)"]="Rice", ["มะเขือเทศ (วัตถุดิบ)"]="Tomato", ["กล้วย (วัตถุดิบ)"]="Banana", ["ปู (วัตถุดิบ)"]="Crab"}
        MarvenSelected.NormalFarmType = map[v] or "Bread"
    end
})
NormalFarm:Toggle({
    Title = "ออโต้ ฟาร์มวัตถุดิบ",
    Default = false,
    Flag = "AutoFarmItem",
    Callback = function(v) MarvenState.AutoFarmItem = v if v then RunNormalFarm() else StopSession("AutoFarmItem") end end
})

local ProcessFarm = FarmTab:Section({Title = "ฟาร์มโพสต์ (คราฟต์/แปรรูป)"})
ProcessFarm:Dropdown({
    Title = "เลือกของ",
    Options = {"กล้วยแพ็ค (แปรรูป)", "ข้าวมันมะม่วง (คราฟต์)", "ข้าวกะเพราหมู (คราฟต์)", "แซนวิช (คราฟต์)", "แกงส้ม (คราฟต์)"},
    Default = "กล้วยแพ็ค (แปรรูป)",
    Flag = "ProcessFarmType",
    Callback = function(v)
        local map = {["กล้วยแพ็ค (แปรรูป)"]="Banana", ["ข้าวมันมะม่วง (คราฟต์)"]="Mango", ["ข้าวกะเพราหมู (คราฟต์)"]="RiceKapaoMoo", ["แซนวิช (คราฟต์)"]="Sandwich", ["แกงส้ม (คราฟต์)"]="KangSom"}
        MarvenSelected.ProcessFarmType = map[v] or "Banana"
    end
})
ProcessFarm:Toggle({
    Title = "ออโต้ ฟาร์มโพสต์",
    Default = false,
    Flag = "AutoProcessFarm",
    Callback = function(v) MarvenState.AutoProcessFarm = v if v then RunProcessFarm() else StopSession("AutoProcessFarm") end end
})

local MineFarm = FarmTab:Section({Title = "ฟาร์มเหมือง (ขุด+แปรรูป+ฝาก)"})
MineFarm:Dropdown({
    Title = "เลือกเหมือง",
    Options = {"ฟาร์มหิน (หลอมแร่)", "ฟาร์มไวเบรเนียม (หลอมแร่)"},
    Default = "ฟาร์มหิน (หลอมแร่)",
    Flag = "MineFarmType",
    Callback = function(v)
        local map = {["ฟาร์มหิน (หลอมแร่)"]="Rock", ["ฟาร์มไวเบรเนียม (หลอมแร่)"]="Svibranium"}
        MarvenSelected.MineFarmType = map[v] or "Rock"
    end
})
MineFarm:Toggle({
    Title = "ออโต้ ฟาร์มเหมือง",
    Default = false,
    Flag = "AutoMineFarm",
    Callback = function(v) MarvenState.AutoMineFarm = v if v then RunMineFarm() else StopSession("AutoMineFarm") end end
})

local AdvTab = Window:Tab({Title = "ขั้นสูง", Icon = "sliders"})
local UnloadSection = AdvTab:Section({Title = "ปิดสคริปต์"})
UnloadSection:Button({
    Title = "ปิดสคริปต์ (Unload)",
    Callback = function()
        MarvenState.AutoFarmItem = false
        MarvenState.AutoProcessFarm = false
        MarvenState.AutoMineFarm = false
        StopSession("AutoFarmItem")
        StopSession("AutoProcessFarm")
        StopSession("AutoMineFarm")
        pcall(function()
            if _G._MarvenStaminaConn then _G._MarvenStaminaConn:Disconnect() _G._MarvenStaminaConn = nil end
            if _G._MarvenHungerConn then _G._MarvenHungerConn:Disconnect() _G._MarvenHungerConn = nil end
            if vehiclePlatformPart then vehiclePlatformPart:Destroy() end
            if fishingPlatform then fishingPlatform:Destroy() end
        end)
        pcall(function() Window:Destroy() end)
    end
})

local ConfigTab = Window:Tab({Title = "Config", Icon = "folder-cog"})
local ConfigSection = ConfigTab:Section({Title = "CONFIG"})
ConfigSection:ConfigManager()

pcall(function() if Loading and Loading.Hide then Loading.Hide() end end)

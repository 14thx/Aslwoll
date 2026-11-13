-- =====================================
-- MARVENRIZ HUB + NEXUS ENGINE (FULL v2.6 FINAL FIXED)
-- PART 1/2: Core + Vehicle + Harvest + Craft + Process + Vault + Sell
-- =====================================

local Loading = nil
pcall(function()
    Loading = loadstring(game:HttpGet("https://raw.githubusercontent.com/14thx/Aslwoll/main/Loading.lua"))()
    if Loading and Loading.Start then Loading.Start() end
end)

task.wait(0.5)   -- ⭐ FIX #8: รอ Loading UI พร้อมก่อน

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
end

local function FindAvailableFood()
    local pd, bp = LocalPlayer:FindFirstChild("PlayerData"), LocalPlayer:FindFirstChild("Backpack")
    for _, food in ipairs({"Sushi","RiceKapaoMoo","MangoRice","Rice","Sandwish","Burger","Bread","Watermelon","Curry","Ramen","Onigiri"}) do
        if pd and typeof(pd:GetAttribute(food)) == "number" and pd:GetAttribute(food) > 0 then return food end
        if bp and bp:FindFirstChild(food) then return food end
    end
end

local function FindAvailableCoffee()
    local pd, bp = LocalPlayer:FindFirstChild("PlayerData"), LocalPlayer:FindFirstChild("Backpack")
    for _, d in ipairs({"Water","WaterBottle","Water_Bottle","MineralWater","PureWater","BottledWater","HotCocoa","Coffee","HotCoffee","IcedCoffee","Cocoa","OrangeJuice","Drink","Ice"}) do
        if pd and typeof(pd:GetAttribute(d)) == "number" and pd:GetAttribute(d) > 0 then return d end
        if bp and bp:FindFirstChild(d) then return d end
    end
end

local function ConsumeItemSafely(itemName, isFood, customWait)
    if isConsumingItem or not itemName then return end
    isConsumingItem = true
    pcall(function()
        local char, hum = LocalPlayer.Character, LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        UseItem(itemName)
        local tool, t0 = nil, os.clock()
        while os.clock() - t0 < 2.5 do
            tool = char and char:FindFirstChild(itemName) or (LocalPlayer.Backpack and LocalPlayer.Backpack:FindFirstChild(itemName))
            if tool and tool.Parent ~= char then hum:EquipTool(tool) end
            if tool and tool.Parent == char then break end
            task.wait(0.1)
        end
        if tool then
            task.wait(0.3)
            pcall(function() tool:Activate() end)
            task.wait(customWait or 5.5)
            pcall(function() hum:UnequipTools() end)
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
        if h < target then ConsumeItemSafely(FindAvailableFood(), true, 5.5) task.wait(0.4) end
        if e < target then ConsumeItemSafely(FindAvailableCoffee(), false, 5.5) task.wait(0.4) end
        i += 1
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
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum and not hum.Sit then
                CheckAndAutoEat()
                task.wait(0.5)
                CheckAndAutoDrinkCoffee()
            end
        end
    end
end)

CancelGameFarm = function()
    pcall(function() local af = PlayerGui:FindFirstChild("Auto Farm") or PlayerGui:FindFirstChild("AutoFarm") if af then af.Enabled = false end end)
    pcall(function() local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") if hum then hum:UnequipTools() end end)
end

local function ClickGuiButton(btn)
    if not btn then return end
    pcall(function() if getconnections then for _, con in ipairs(getconnections(btn.MouseButton1Click)) do pcall(function() if con.Function then con.Function() elseif con.Fire then con:Fire() end end) end end end)
    pcall(function() if firesignal then pcall(function() firesignal(btn.MouseButton1Click) end) pcall(function() firesignal(btn.Activated) end) end end)
    pcall(function() if VirtualInputManager and btn.AbsolutePosition then local p = btn.AbsolutePosition + (btn.AbsoluteSize / 2) VirtualInputManager:SendMouseButtonEvent(p.X, p.Y, 0, true, game, 0) task.wait(0.05) VirtualInputManager:SendMouseButtonEvent(p.X, p.Y, 0, false, game, 0) end end)
end

local function SafeClickGuiButton(btn)
    if not btn or not btn:IsA("GuiButton") then return end
    pcall(function() if firesignal then firesignal(btn.MouseButton1Click) firesignal(btn.Activated) end end)
end

local function TriggerPrompt(prompt)
    if not prompt or not prompt.Enabled then return end
    pcall(function()
        if fireproximityprompt then pcall(function() fireproximityprompt(prompt) end) end
        pcall(function() prompt:InputHoldBegin() task.wait(prompt.HoldDuration > 0 and (prompt.HoldDuration + 0.05) or 0.15) prompt:InputHoldEnd() end)
    end)
end

local function FindPromptNear(centerPos, maxDist, matchKeyword)
    maxDist = maxDist or 25
    local closest, closestDist = nil, maxDist
    local systems = workspace:FindFirstChild("Systems")
    for _, container in ipairs(systems and {systems} or {workspace}) do
        for _, prompt in ipairs(container:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") and prompt.Enabled then
                local pPos = prompt.Parent and (prompt.Parent:IsA("BasePart") and prompt.Parent.Position or (prompt.Parent:IsA("Attachment") and prompt.Parent.WorldPosition))
                if pPos then
                    local d = (pPos - centerPos).Magnitude
                    if d <= closestDist then
                        if not matchKeyword or string.find(string.lower(prompt.ActionText or ""), string.lower(matchKeyword)) then closest = prompt closestDist = d end
                    end
                end
            end
        end
    end
    return closest
end

pcall(function()
    local lp = Players.LocalPlayer
    if not hookmetamethod or not newcclosure then return end
    local oldNm = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if (method == "Kick" or method == "kick") and (self == lp or self == Players) then return nil end
        return oldNm(self, ...)
    end))
end)

GrantAntiXGrace = function(seconds)
    seconds = seconds or 25
    pcall(function()
        local char = LocalPlayer.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then root:SetAttribute("TeleportGrace", os.clock() + seconds) root:SetAttribute("AntiFallGrace", os.clock() + seconds) root:SetAttribute("VehicleGrace", os.clock() + seconds) root:SetAttribute("IgnoreAntiCheat", true) end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false) hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false) end
    end)
end

-- =====================================
-- VEHICLE SYSTEM
-- =====================================
local function IsMyVehicle(v)
    if not v or not v:IsA("Model") or not v.Parent then return false end
    if MY_SPAWNED_CAR and v == MY_SPAWNED_CAR then return true end
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum and hum.SeatPart and hum.SeatPart:IsDescendantOf(v) then MY_SPAWNED_CAR = v return true end
    local owner = v:GetAttribute("Owner") or v:GetAttribute("OwnerName")
    if owner then return tostring(owner) == LocalPlayer.Name or tostring(owner) == tostring(LocalPlayer.UserId) end
    return false
end

GetPlayerVehicle = function()
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum and hum.SeatPart then local v = hum.SeatPart:FindFirstAncestorOfClass("Model") if v and IsMyVehicle(v) then return v end end
    if MY_SPAWNED_CAR and MY_SPAWNED_CAR.Parent and IsMyVehicle(MY_SPAWNED_CAR) then return MY_SPAWNED_CAR end
    local vf = (workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Vehicles")) or workspace:FindFirstChild("Vehicles")
    if vf then for _, v in ipairs(vf:GetChildren()) do if v:IsA("Model") and IsMyVehicle(v) and v.PrimaryPart then MY_SPAWNED_CAR = v return v end end end
end

GetNearbyPlayerVehicle = function(dist)
    dist = dist or 80
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    if hum and hum.Sit and hum.SeatPart then local v = hum.SeatPart:FindFirstAncestorOfClass("Model") if v and IsMyVehicle(v) then return v end end
    local vf = (workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Vehicles")) or workspace:FindFirstChild("Vehicles")
    local best, bd = nil, math.huge
    if vf then for _, v in ipairs(vf:GetChildren()) do if v:IsA("Model") and IsMyVehicle(v) and v.PrimaryPart then local d = (v.PrimaryPart.Position - root.Position).Magnitude if d < bd then bd, best = d, v end end end end
    if best and bd <= dist then MY_SPAWNED_CAR = best return best end
end

PressFToEnterCar = function(car)
    if not car or not car.Parent or not IsMyVehicle(car) then return false end
    local char, hum, root = LocalPlayer.Character, LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid"), LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return false end
    local seat = car:FindFirstChild("DriveSeat", true) or car:FindFirstChildWhichIsA("VehicleSeat", true) or car:FindFirstChildWhichIsA("Seat", true)
    if not seat then return false end
    if hum.Sit and hum.SeatPart == seat then MY_SPAWNED_CAR = car return true end
    if hum.Sit and hum.SeatPart ~= seat then hum.Sit = false task.wait(0.2) end
    GrantAntiXGrace(20)
    local drivePrompt = nil
    for _, d in ipairs(car:GetDescendants()) do
        if d:IsA("ProximityPrompt") and (d.ActionText:lower():find("drive") or d.Name:lower():find("drive")) then drivePrompt = d break end
    end
    root.CFrame = CFrame.lookAt(seat.CFrame.Position - seat.CFrame.LookVector * 2.6, seat.Position)
    root.AssemblyLinearVelocity = Vector3.zero
    task.wait(0.15)
    local t0 = os.clock()
    while os.clock() - t0 < 3.0 do
        if hum.Sit and hum.SeatPart then break end
        if drivePrompt then pcall(function() fireproximityprompt(drivePrompt) end) end
        pcall(function() VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game) task.wait(0.06) VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game) end)
        task.wait(0.2)
    end
    if not (hum.Sit and hum.SeatPart) then pcall(function() root.CFrame = seat.CFrame + Vector3.new(0, 0.5, 0) seat:Sit(hum) end) task.wait(0.2) end
    if hum.Sit and hum.SeatPart then MY_SPAWNED_CAR = car return true end
    return false
end

EnsurePlayerSeatedInCar = function(car)
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum and hum.Sit and hum.SeatPart and car and hum.SeatPart:IsDescendantOf(car) then return true end
    return PressFToEnterCar(car)
end

ExitCarNaturally = function(car)
    local char, hum, root = LocalPlayer.Character, LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid"), LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return end
    if hum.Sit then hum.Sit = false task.wait(0.12) end
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

local FindBoothPromptNear
SmoothWalkTo = function(targetPos, maxTimeout, shouldContinueCheck, stopDist)
    local char, hum, root = LocalPlayer.Character, LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid"), LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return false end
    maxTimeout = maxTimeout or 50
    stopDist = stopDist or 2.5
    local st, last, stuck = os.clock(), root.Position, 0
    while (root.Position - targetPos).Magnitude > stopDist and (os.clock() - st < maxTimeout) do
        if shouldContinueCheck and not shouldContinueCheck() then return false end
        GrantAntiXGrace(5)
        local curDist = (root.Position - targetPos).Magnitude
        if curDist <= 12.0 then
            local boothPrompt = FindBoothPromptNear(targetPos, 20) or FindBoothPromptNear(root.Position, 20)
            if boothPrompt then
                local cs = PlayerGui:FindFirstChild("Car_Spawn")
                local group = cs and cs:FindFirstChild("Group")
                if group and not group.Visible then boothPrompt.Enabled = true pcall(function() boothPrompt.HoldDuration = 0 end) if fireproximityprompt then pcall(function() fireproximityprompt(boothPrompt) end) end end
                if curDist <= 6.0 then break end
            end
        end
        hum:MoveTo(targetPos)
        if (root.Position - last).Magnitude < 0.4 then stuck += 1 if stuck >= 3 then hum.Jump = true stuck = 0 end else stuck = 0 end
        last = root.Position
        task.wait(0.15)
    end
    return (root.Position - targetPos).Magnitude <= 10
end

GetNearestCarBooth = function(fromPos)
    fromPos = fromPos or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.Position) or TOWN_CAR_SPAWN
    local best, bd = nil, math.huge
    for _, d in pairs(TYPER_LOCATIONS) do if d.Booth then local dist = (d.Booth - fromPos).Magnitude if dist < bd then bd, best = dist, d.Booth end end end
    if TOWN_CAR_SPAWN then local dist = (TOWN_CAR_SPAWN - fromPos).Magnitude if dist < bd then bd, best = dist, TOWN_CAR_SPAWN end end
    return best or TOWN_CAR_SPAWN
end

FindBoothPromptNear = function(fromPos, maxDist)
    fromPos = fromPos or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.Position)
    if not fromPos then return nil end
    maxDist = maxDist or 30
    local farmSys = workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Farm")
    if farmSys then for _, cf in ipairs(farmSys:GetChildren()) do local sf = cf:FindFirstChild("Prompt") and cf.Prompt:FindFirstChild("Spawn") if sf then local pr = sf:FindFirstChildWhichIsA("ProximityPrompt", true) if pr then local p = pr.Parent local pos = (p:IsA("Attachment") and p.WorldPosition) or (p:IsA("BasePart") and p.Position) if pos and (pos - fromPos).Magnitude <= maxDist then return pr end end end end end
end

local function FindPoundButton(group)
    if not group then return nil end
    for _, d in ipairs(group:GetDescendants()) do if d:IsA("GuiButton") and d.Visible and d.Name:lower():find("pound") then return d end end
end

local function FindBlueSpawnButton(group)
    if not group then return nil end
    for _, d in ipairs(group:GetDescendants()) do if d:IsA("GuiButton") and d.Visible and d.Name:lower():find("spawn") then return d end end
end

local function FindCarSpawnOrPoundButton(group, preferred)
    preferred = preferred or "R32"
    local card = group:FindFirstChild(preferred, true)
    if card then
        for _, d in ipairs(card:GetDescendants()) do
            if d:IsA("GuiButton") and d.Visible then
                local nm = d.Name:lower()
                local txt = (d:IsA("TextButton") and d.Text:lower()) or ""
                if nm:find("spawn") or txt:find("spawn") then return d, "spawn", card end
                if nm:find("pound") or txt:find("pound") then return d, "pound", card end
            end
        end
    end
    return FindBlueSpawnButton(group), "spawn", group
end

local function CloseCarSpawnGui()
    pcall(function() local cs = PlayerGui:FindFirstChild("Car_Spawn") if cs and cs:FindFirstChild("Group") then cs.Group.Visible = false end end)
end

SpawnCarAtBooth = function(boothPos)
    GrantAntiXGrace(40)
    local char, hum, root = LocalPlayer.Character, LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid"), LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return nil end
    LAST_STORED_BOOTH = boothPos
    pcall(function() game:GetService("ProximityPromptService").Enabled = true end)
    if boothPos then
        local dist = (root.Position - boothPos).Magnitude
        if dist > 15 then
            local gy = GetGroundLevel(boothPos.X, boothPos.Z, boothPos.Y)
            root.CFrame = CFrame.new(boothPos.X, gy + 1.2, boothPos.Z)
            task.wait(0.2)
        end
    end
    local cs = PlayerGui:FindFirstChild("Car_Spawn")
    local group = cs and cs:FindFirstChild("Group")
    local tOpen = os.clock()
    while os.clock() - tOpen < 3.0 do
        if group and group.Visible then break end
        local bp = FindBoothPromptNear(root.Position, 30) or (boothPos and FindBoothPromptNear(boothPos, 30))
        if bp then
            bp.Enabled = true
            if fireproximityprompt then pcall(function() fireproximityprompt(bp) end) end
            task.wait(0.08)
            cs = PlayerGui:FindFirstChild("Car_Spawn")
            group = cs and cs:FindFirstChild("Group")
            if group and group.Visible then break end
            pcall(function() VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game) task.wait(0.04) VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game) end)
        end
        task.wait(0.1)
        cs = PlayerGui:FindFirstChild("Car_Spawn")
        group = cs and cs:FindFirstChild("Group")
    end
    if group and group.Visible then
        local sf = group:FindFirstChild("Main") and group.Main:FindFirstChild("Carlist") and group.Main.Carlist:FindFirstChild("ScrollingFrame")
        local card = sf and (sf:FindFirstChild("R32") or sf:GetChildren()[1])
        local pBtn = (card and card:FindFirstChild("Pound")) or FindPoundButton(group)
        local sBtn = (card and card:FindFirstChild("Spawn")) or FindBlueSpawnButton(group)
        local cName = (card and card.Name) or "R32"
        if pBtn and pBtn.Visible then
            ClickGuiButton(pBtn)
            local tw = os.clock()
            while os.clock() - tw < 4.5 do task.wait(0.2) if (sBtn and sBtn.Visible) then break end end
            if card and card:FindFirstChild("Spawn") then sBtn = card.Spawn end
        end
        if sBtn and sBtn.Visible then
            ClickGuiButton(sBtn)
            task.wait(1.0)
        end
    end
    local finalCar = nil
    local tc = os.clock()
    while os.clock() - tc < 6.0 do finalCar = GetNearbyPlayerVehicle(80) or GetPlayerVehicle() if finalCar and finalCar.PrimaryPart then break end task.wait(0.2) end
    if finalCar then
        MY_SPAWNED_CAR = finalCar
        for cd = 2, 1, -1 do task.wait(1.0) end
        CloseCarSpawnGui()
        EnsurePlayerSeatedInCar(finalCar)
        return finalCar
    end
    CloseCarSpawnGui()
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
    local char, hum, root = LocalPlayer.Character, LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid"), LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
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

local function EnsureVehiclePlatform(surfaceY, carPos)
    if not isVehiclePlatformEnabled then if vehiclePlatformPart then vehiclePlatformPart:Destroy() vehiclePlatformPart = nil end return end
    if not vehiclePlatformPart or not vehiclePlatformPart.Parent then
        local p = Instance.new("Part") p.Name = "TyperTown_VehicleSafePlatform" p.Size = Vector3.new(36, 1.5, 36) p.Anchored = true p.CanCollide = true p.Transparency = 1 p.Parent = workspace vehiclePlatformPart = p
    else vehiclePlatformPart.CanCollide = false end
    vehiclePlatformPart.CFrame = CFrame.new(carPos.X, surfaceY - 0.75, carPos.Z)
end

local function IsWideSolidGround(x, z)
    if z >= 350 and z <= 4050 then return false end
    local params = RaycastParams.new() params.FilterType = Enum.RaycastFilterType.Exclude
    local fl = {} if LocalPlayer.Character then table.insert(fl, LocalPlayer.Character) end if MY_SPAWNED_CAR then table.insert(fl, MY_SPAWNED_CAR) end
    params.FilterDescendantsInstances = fl
    for _, off in ipairs({Vector2.new(0,0), Vector2.new(25,0), Vector2.new(-25,0), Vector2.new(0,25), Vector2.new(0,-25)}) do
        local px, pz = x + off.X, z + off.Y
        if pz >= 350 and pz <= 4050 then return false end
        local result = workspace:Raycast(Vector3.new(px, 150, pz), Vector3.new(0,-180,0), params)
        if not result or result.Material == Enum.Material.Water or result.Position.Y <= 7.5 then return false end
    end
    return true
end

DriveCarTo = function(dest, check)
    local char, hum, root = LocalPlayer.Character, LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid"), LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return false end
    local car, seat = nil, nil
    if hum.Sit and hum.SeatPart then seat = hum.SeatPart car = seat:FindFirstAncestorOfClass("Model") if car then MY_SPAWNED_CAR = car end end
    if not car then car = GetNearbyPlayerVehicle(80) or GetPlayerVehicle() if car then EnsurePlayerSeatedInCar(car) task.wait(0.2) end end
    if not car then return false end
    seat = (hum and hum.SeatPart) or car:FindFirstChild("DriveSeat", true) or car:FindFirstChildWhichIsA("VehicleSeat", true)
    if not seat then return false end
    if not car.PrimaryPart then pcall(function() car.PrimaryPart = seat end) end
    local cur = seat.Position
    local rideH = math.clamp(cur.Y - GetGroundLevel(cur.X, cur.Z, cur.Y), 2.3, 3.2)
    local distT = (Vector2.new(dest.X, dest.Z) - Vector2.new(cur.X, cur.Z)).Magnitude
    if distT < 5 then return true end
    local trav, lastT, flying, safeF = 0, os.clock(), false, 0
    local driveStartTime = os.clock()
    while trav < distT do
        if os.clock() - driveStartTime > 120 or (check and not check()) then if vehiclePlatformPart then vehiclePlatformPart:Destroy() vehiclePlatformPart = nil end return false end
        if not hum.Sit or hum.SeatPart ~= seat then pcall(function() root.CFrame = seat.CFrame + Vector3.new(0,0.8,0) seat:Sit(hum) end) end
        local spd = math.clamp(tonumber(VehicleDriveSpeed) or 150, 10, 280)
        local rem = distT - trav
        if rem < 80 then spd = math.max(spd * math.clamp(rem/80, 0.2, 1), 30) end
        local now = os.clock() local dt = math.min(now - lastT, 0.1) lastT = now
        trav = math.min(distT, trav + (spd * dt))
        local a = math.clamp(trav / distT, 0, 1)
        local tx = cur.X + (dest.X - cur.X) * a
        local tz = cur.Z + (dest.Z - cur.Z) * a
        local gy = GetGroundLevel(tx, tz, cur.Y)
        local inOcean = (tz >= 350 and tz <= 4050)
        local isSafe = (not inOcean) and IsWideSolidGround(tx, tz)
        if inOcean or not isSafe then safeF = 0 flying = true else safeF += 1 if safeF >= 8 or rem <= 12 then flying = false end end
        local sY = math.max(flying and 1000 or gy + rideH, 16.0)
        local dir = Vector3.new(dest.X - tx, 0, dest.Z - tz)
        local cf = CFrame.new(tx, sY, tz)
        if dir.Magnitude > 0.1 then cf = CFrame.lookAt(Vector3.new(tx, sY, tz), Vector3.new(tx, sY, tz) + dir) end
        car:PivotTo(cf)
        pcall(function() if car.PrimaryPart then car.PrimaryPart.AssemblyLinearVelocity = Vector3.zero car.PrimaryPart.AssemblyAngularVelocity = Vector3.zero end end)
        if isVehiclePlatformEnabled and not flying then EnsureVehiclePlatform(sY - rideH, Vector3.new(tx, sY, tz)) end
        RunService.Heartbeat:Wait()
    end
    pcall(function() local fg = GetGroundLevel(dest.X, dest.Z, dest.Y) car:PivotTo(CFrame.new(dest.X, math.max(fg + rideH, 16.0), dest.Z)) end)
    if vehiclePlatformPart then vehiclePlatformPart:Destroy() vehiclePlatformPart = nil end
    task.wait(0.1)
    return true
end

-- =====================================
-- HARVEST SYSTEM
-- =====================================
local function TriggerFarmPromptDirectly(cropName)
    local char, hum, root = LocalPlayer.Character, LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid"), LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    if hum and hum.Sit then hum.Sit = false task.wait(0.15) end
    local farmSys = workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Farm")
    local farmFolder = farmSys and farmSys:FindFirstChild(cropName)
    local targetPrompt = nil
    if farmFolder then for _, d in ipairs(farmFolder:GetDescendants()) do if d:IsA("ProximityPrompt") and d.Enabled then targetPrompt = d break end end end
    if targetPrompt then pcall(function() if fireproximityprompt then pcall(function() fireproximityprompt(targetPrompt) end) end end) return true end
    return false
end

local function GetExactFarmPromptPosition(cropName)
    local locData = TYPER_LOCATIONS[cropName]
    local farmFolder = workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Farm") and workspace.Systems.Farm:FindFirstChild(cropName)
    if farmFolder then for _, desc in ipairs(farmFolder:GetDescendants()) do if desc:IsA("ProximityPrompt") and desc.Enabled then local pPos = desc.Parent:IsA("Attachment") and desc.Parent.WorldPosition or desc.Parent:IsA("BasePart") and desc.Parent.Position if pPos then return pPos end end end end
    return locData and locData.Farm
end

local function GetFarmParkingPosition(cropName)
    local locData = TYPER_LOCATIONS[cropName]
    local center = GetExactFarmPromptPosition(cropName) or (locData and locData.Farm) or Vector3.zero
    local dir = Vector3.new(1,0,1).Unit
    if locData and locData.Booth then local d = Vector3.new(locData.Booth.X - center.X, 0, locData.Booth.Z - center.Z) if d.Magnitude > 1 then dir = d.Unit end end
    local px, pz = center.X + (dir * 11.5).X, center.Z + (dir * 11.5).Z
    return Vector3.new(px, GetGroundLevel(px, pz, center.Y), pz)
end

HarvestSingleCrop = function(cropName, targetAmount, check)
    targetAmount = targetAmount or ((cropName == "Rock" or cropName == "Svibranium") and 120 or 60)
    local curCount = GetPlayerInventoryCount(cropName)
    if curCount >= targetAmount then return end
    local locData = TYPER_LOCATIONS[cropName]
    if not locData then return end
    -- ⭐ FIX #6: เช็ค hum.Sit ก่อน DriveCarTo
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    local myCar = GetNearbyPlayerVehicle(80)
    if not myCar or not (hum and hum.Sit) then
        if myCar then EnsurePlayerSeatedInCar(myCar)
        else EnsureCarAvailable(locData.Booth) end
    end
    DriveCarTo(GetFarmParkingPosition(cropName), check)
    if check and not check() then return end
    hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum and hum.Sit then hum.Sit = false task.wait(0.2) end
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local exactCenter = GetExactFarmPromptPosition(cropName) or locData.Farm
    if root then
        -- ⭐ FIX: หันหน้าเข้าหาศูนย์กลางจริงๆ (ไม่ใช่ตำแหน่งตัวเอง)
        root.CFrame = CFrame.lookAt(
            Vector3.new(exactCenter.X + 3, exactCenter.Y + 3, exactCenter.Z + 3),
            exactCenter
        )
    end
    task.wait(0.2)
    local tW = os.clock()
    while os.clock() - tW < 4.0 do TriggerFarmPromptDirectly(cropName) task.wait(0.5) if GetPlayerInventoryCount(cropName) > curCount then break end end
    local farmTO = os.clock()
    while curCount < targetAmount do
        if check and not check() then break end
        if os.clock() - farmTO > 180 then break end
        GrantAntiXGrace(15)
        local nc = GetPlayerInventoryCount(cropName)
        if nc > curCount then curCount = nc farmTO = os.clock()
        elseif (os.clock() - farmTO > 15) then TriggerFarmPromptDirectly(cropName) farmTO = os.clock() end
        task.wait(0.5)
    end
    local tb = (locData and locData.Booth) or TOWN_CAR_SPAWN
    SmoothWalkTo(tb, 45, check, 5.5)
    local car = SpawnCarAtBooth(tb) or EnsureCarAvailable(tb)
    if car then EnsurePlayerSeatedInCar(car) end
end

-- =====================================
-- CRAFT SYSTEM
-- =====================================
local function GetCraft3Prompt()
    local craftSys = workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Crafting")
    local c3 = craftSys and craftSys:FindFirstChild("Craft_3")
    if c3 then local p = c3:FindFirstChildWhichIsA("ProximityPrompt", true) if p and p.Enabled then return p end end
    return nil
end

CraftFoodAtStation = function(recipeName, shouldContinueCheck)
    local foodData = TYPER_LOCATIONS.Food
    local char, hum, root = LocalPlayer.Character, LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid"), LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root or not hum then return end
    local myCar = GetPlayerVehicle()
    if not myCar or not hum.Sit then myCar = EnsureCarAvailable() end
    if myCar then EnsurePlayerSeatedInCar(myCar) end
    pcall(function() local procGui = PlayerGui:FindFirstChild("Process") if procGui and procGui:FindFirstChild("Group") then procGui.Group.Visible = false end end)
    local cPrompt = GetCraft3Prompt()
    local exactCraftPos = nil
    if cPrompt then local pParent = cPrompt.Parent exactCraftPos = pParent:IsA("BasePart") and pParent.Position or pParent:IsA("Attachment") and pParent.WorldPosition or pParent.Parent:IsA("BasePart") and pParent.Parent.Position end
    if not exactCraftPos then local anyPart = workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Crafting") and workspace.Systems.Crafting:FindFirstChild("Craft_3") and workspace.Systems.Crafting.Craft_3:FindFirstChildWhichIsA("BasePart", true) if anyPart then exactCraftPos = anyPart.Position end end
    exactCraftPos = exactCraftPos or foodData.Crafting
    DriveCarTo(exactCraftPos + Vector3.new(0, 0, 5.0), shouldContinueCheck)
    task.wait(0.2)
    if shouldContinueCheck and not shouldContinueCheck() then return end
    if hum.Sit then hum.Sit = false task.wait(0.2) end
    local standPos = Vector3.new(exactCraftPos.X, GetGroundLevel(exactCraftPos.X, exactCraftPos.Z, exactCraftPos.Y) + 3.0, exactCraftPos.Z + 2.5)
    root.CFrame = CFrame.lookAt(standPos, exactCraftPos)
    task.wait(0.15)
    cPrompt = cPrompt or GetCraft3Prompt()
    if cPrompt then TriggerPrompt(cPrompt) end
    local cg = PlayerGui:WaitForChild("Crafting", 4)
    local tWaitUI = os.clock()
    while os.clock() - tWaitUI < 3.0 do if cg and cg:FindFirstChild("Group") and cg.Group.Visible then break end if cPrompt then TriggerPrompt(cPrompt) end task.wait(0.3) end
    if not cg or not cg:FindFirstChild("Group") or not cg.Group.Visible then pcall(function() if cg and cg:FindFirstChild("Group") then cg.Group.Visible = true cg.Group.GroupTransparency = 0 end end) end
    task.wait(0.2)
    local toCraft = 1
    if recipeName == "Sandwish" or recipeName == "Sandwich" then toCraft = math.min(math.floor(GetPlayerInventoryCount("Bread")/3), math.floor(GetPlayerInventoryCount("Catchup")/2), math.floor(GetPlayerInventoryCount("Pig")/2))
    elseif recipeName == "MangoRice" or recipeName == "Mango" then toCraft = math.min(math.floor(GetPlayerInventoryCount("Mango")/2), math.floor(GetPlayerInventoryCount("Rice")/3))
    elseif recipeName == "RiceKapaoMoo" then toCraft = math.min(math.floor(GetPlayerInventoryCount("Rice")/3), math.floor(GetPlayerInventoryCount("Pig")/2))
    elseif recipeName == "KangSom" then toCraft = math.min(math.floor(GetPlayerInventoryCount("Tomato")/2), math.floor(GetPlayerInventoryCount("Crab")/2)) end
    if toCraft <= 0 then if cg and cg:FindFirstChild("Group") then cg.Group.Visible = false end return end
    local mainFrame = cg and cg:FindFirstChild("Group") and cg.Group:FindFirstChild("Main")
    if mainFrame then
        local scroller = mainFrame:FindFirstChild("Left_Tab") and mainFrame.Left_Tab:FindFirstChild("ScrollingFrame")
        if scroller then
            local sandCatBtn = scroller:FindFirstChild("Sand") or scroller:FindFirstChild("Food") or scroller:FindFirstChild("อาหาร") if sandCatBtn then SafeClickGuiButton(sandCatBtn) task.wait(0.3) end
            local cleanName = recipeName:gsub("%s+", ""):lower()
            local recipeBtn = nil
            for _, ch in ipairs(scroller:GetChildren()) do local childName = ch.Name:gsub("%s+", ""):lower() if childName == cleanName or childName:find(cleanName) then recipeBtn = ch break end end
            if recipeBtn then local clickTarget = recipeBtn:IsA("GuiButton") and recipeBtn or recipeBtn:FindFirstChildWhichIsA("GuiButton", true) if clickTarget then SafeClickGuiButton(clickTarget) end task.wait(0.3) end
        end
        local amtBox = mainFrame:FindFirstChild("Function") and mainFrame.Function:FindFirstChild("Amount") and mainFrame.Function.Amount:FindFirstChild("Amount") if amtBox and amtBox:IsA("TextBox") then amtBox.Text = tostring(toCraft) task.wait(0.1) end
        local craftBtn = mainFrame:FindFirstChild("Button") and mainFrame.Button:FindFirstChild("Craft") if not craftBtn then for _, b in ipairs(mainFrame:GetDescendants()) do if b:IsA("GuiButton") and (b.Name:lower():find("craft") or b:IsA("TextButton") and b.Text:lower():find("craft")) then craftBtn = b break end end end
        if craftBtn then SafeClickGuiButton(craftBtn) task.wait(0.3) end
    end
    local actualRecipe = (recipeName == "Sandwich" and "Sandwish") or recipeName
    pcall(function()
        local remCore = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes")
        if remCore then require(remCore).Fire("_crafting", "Request", "Craft_3", actualRecipe, toCraft, false) end
    end)
    local tStart = os.clock()
    while os.clock() - tStart < 10.0 do if shouldContinueCheck and not shouldContinueCheck() then break end task.wait(0.5) end
    pcall(function() local remCore = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes") if remCore then require(remCore).Fire("_crafting", "Complete", "Craft_3", actualRecipe, toCraft, false) end end)
    pcall(function() if mainFrame and mainFrame:FindFirstChild("Exit") and firesignal then firesignal(mainFrame.Exit.MouseButton1Click) end if cg and cg:FindFirstChild("Group") then cg.Group.Visible = false end end)
    task.wait(3.0)
    local myCar3 = GetNearbyPlayerVehicle(80) or EnsureCarAvailable(TOWN_CAR_SPAWN) if myCar3 then EnsurePlayerSeatedInCar(myCar3) end
end

-- =====================================
-- PROCESS ORE (FIXED: เพิ่ม _process Start remote)
-- =====================================
ProcessOreAtStation = function(oreName, minP, check)
    GrantAntiXGrace(30)
    local char, hum, root = LocalPlayer.Character, LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid"), LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root or not hum then return end
    local exactProcPos = (oreName == "Svibranium" and Vector3.new(-930.91, 6.93, 6760.56)) or (TYPER_LOCATIONS[oreName] and TYPER_LOCATIONS[oreName].Process) or Vector3.new(-935.29, 6.93, 6786.66)
    if not GetPlayerVehicle() or not hum.Sit then EnsureCarAvailable() end
    DriveCarTo(exactProcPos + Vector3.new(0,0,5.0), check)
    if check and not check() then return end
    if hum.Sit then hum.Sit = false task.wait(0.1) end
    local procPrompt = FindPromptNear(exactProcPos, 25, nil)
    root.CFrame = CFrame.lookAt(Vector3.new(exactProcPos.X, exactProcPos.Y+1.2, exactProcPos.Z+2.5), exactProcPos)
    task.wait(0.2)
    if procPrompt then TriggerPrompt(procPrompt) task.wait(0.5) end
    minP = minP or (oreName == "Svibranium" and 4 or 2)
    local tP = os.clock()
    while GetPlayerInventoryCount(oreName) >= minP and (os.clock() - tP < 180) do
        if check and not check() then break end
        -- ⭐ FIX #2: ยิง _process Start ก่อน + กด ActionBtn สำรอง
        pcall(function()
            local rc = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes")
            if rc then require(rc).Fire("_process", "Start", oreName) end
        end)
        local ab = PlayerGui:FindFirstChild("Process") and PlayerGui.Process:FindFirstChild("Group") and PlayerGui.Process.Group:FindFirstChild("Main") and PlayerGui.Process.Group.Main:FindFirstChild("ActionBtn")
        if ab and firesignal then firesignal(ab.MouseButton1Click) end
        task.wait(3.2)
    end
    pcall(function() local rc = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes") if rc then require(rc).Fire("_process", "Stop", oreName) end end)
    pcall(function()
        local pg = PlayerGui:FindFirstChild("Process")
        if pg and pg:FindFirstChild("Group") then
            local main = pg.Group:FindFirstChild("Main")
            if main and main:FindFirstChild("Exit") and firesignal then firesignal(main.Exit.MouseButton1Click) end
            pg.Group.Visible = false
        end
    end)
    task.wait(1.0)
    local c2 = GetNearbyPlayerVehicle(80) or EnsureCarAvailable(Vector3.new(-876.62, 10.52, 6662.98)) if c2 then EnsurePlayerSeatedInCar(c2) end
end

-- =====================================
-- ⭐ FIX #1: PROCESS BANANA (ฟังก์ชันที่ขาดหาย!)
-- =====================================
ProcessBananaAtStation = function(check)
    GrantAntiXGrace(30)
    local char, hum, root = LocalPlayer.Character, LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid"), LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root or not hum then return end
    
    local foodData = TYPER_LOCATIONS.Food
    local exactBanPos = foodData.BananaProcess
    local pBan = workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Process") and workspace.Systems.Process:FindFirstChild("Banana")
    if pBan then
        local anyPart = pBan:FindFirstChildWhichIsA("BasePart", true)
        if anyPart then exactBanPos = anyPart.Position end
    end
    
    if not GetPlayerVehicle() or not hum.Sit then EnsureCarAvailable() end
    DriveCarTo(exactBanPos + Vector3.new(0, 0, 5.0), check)
    if check and not check() then return end
    if hum.Sit then hum.Sit = false task.wait(0.1) end
    
    root.CFrame = CFrame.lookAt(
        Vector3.new(exactBanPos.X, exactBanPos.Y + 1.2, exactBanPos.Z + 2.5),
        exactBanPos
    )
    task.wait(0.2)
    
    local procPrompt = pBan and pBan:FindFirstChildWhichIsA("ProximityPrompt", true)
    if not procPrompt then procPrompt = FindPromptNear(root.Position, 15, nil) end
    if procPrompt then TriggerPrompt(procPrompt) task.wait(0.5) end
    
    -- ยิง Start remote
    pcall(function()
        local rc = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes")
        if rc then require(rc).Fire("_process", "Start", "Banana") end
    end)
    
    local tProc = os.clock()
    while GetPlayerInventoryCount("Banana") >= 2 and (os.clock() - tProc < 120) do
        if check and not check() then break end
        GrantAntiXGrace(15)
        local ab = PlayerGui:FindFirstChild("Process") 
            and PlayerGui.Process:FindFirstChild("Group") 
            and PlayerGui.Process.Group:FindFirstChild("Main") 
            and PlayerGui.Process.Group.Main:FindFirstChild("ActionBtn")
        if ab and firesignal then firesignal(ab.MouseButton1Click) end
        task.wait(3.2)
    end
    
    pcall(function()
        local rc = ReplicatedStorage:FindFirstChild("Systems") 
            and ReplicatedStorage.Systems:FindFirstChild("Modules") 
            and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") 
            and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes")
        if rc then require(rc).Fire("_process", "Stop", "Banana") end
    end)
    
    pcall(function()
        local pg = PlayerGui:FindFirstChild("Process")
        if pg and pg:FindFirstChild("Group") then
            local main = pg.Group:FindFirstChild("Main")
            if main and main:FindFirstChild("Exit") and firesignal then
                firesignal(main.Exit.MouseButton1Click)
            end
            pg.Group.Visible = false
        end
    end)
    
    task.wait(1.0)
    local c2 = GetNearbyPlayerVehicle(80) or EnsureCarAvailable(TOWN_CAR_SPAWN)
    if c2 then EnsurePlayerSeatedInCar(c2) end
end

-- =====================================
-- VAULT (เติม Iron, Gold แล้ว)
-- =====================================
local DEPOSITABLE_ITEMS = { Rock=true, Svibranium=true, Iron=true, Gold=true, Bread=true, Catchup=true, Pig=true, Mango=true, Rice=true, Tomato=true, Banana=true, Crab=true, Coconut=true, Corn=true, Egg=true, Milk=true, Sugarcane=true, Sandwich=true, MangoRice=true, BananaPack=true, KangSom=true, Water=true, Coffee=true }
DepositAllToVault = function(check)
    local char, hum, root = LocalPlayer.Character, LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid"), LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root or not hum then return end
    local myCar = GetPlayerVehicle() or GetNearbyPlayerVehicle(80) if not myCar or not hum.Sit then EnsureCarAvailable() end
    DriveCarTo(VAULT_COORDS + Vector3.new(0,0,6.0), check)
    if check and not check() then return end
    ExitCarNaturally(myCar) task.wait(0.3)
    SmoothWalkTo(Vector3.new(-1.98, 26.54, 8630.8), 8, check, 0.8)
    local vp = FindPromptNear(VAULT_COORDS, 10, "vault") or FindPromptNear(root.Position, 8) if vp then TriggerPrompt(vp) end task.wait(0.3)
    local rc = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes")
    if rc then
        local R = require(rc) local pd = LocalPlayer:FindFirstChild("PlayerData")
        if pd then for attr in pairs(pd:GetAttributes()) do if DEPOSITABLE_ITEMS[attr] then local c = GetPlayerInventoryCount(attr) if c > 0 then pcall(function() R.Invoke("_vault_tx", "Deposit", attr, c) end) end end end end
    end
    task.wait(5.0)
    local c2 = GetNearbyPlayerVehicle(80) or myCar or GetPlayerVehicle() if c2 then EnsurePlayerSeatedInCar(c2) end
end

-- =====================================
-- SELL (FIXED: UI fallback + keyword กว้างขึ้น)
-- =====================================
SellAtEconomyMarket = function(check)
    local char, hum, root = LocalPlayer.Character, LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid"), LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root or not hum then return end
    local marketPos = TYPER_LOCATIONS.Economy.Market
    if not GetPlayerVehicle() or not hum.Sit then EnsureCarAvailable(TOWN_CAR_SPAWN) end
    DriveCarTo(marketPos, check)
    if check and not check() then return end
    ExitCarNaturally(GetPlayerVehicle())
    if root then root.CFrame = CFrame.lookAt(Vector3.new(marketPos.X+2.5, marketPos.Y+2.2, marketPos.Z), marketPos) end
    -- ⭐ FIX #7: keyword กว้างขึ้น
    local ep = FindPromptNear(root.Position, 25, "econ") 
            or FindPromptNear(root.Position, 25, "market") 
            or FindPromptNear(root.Position, 25, "sell") 
            or FindPromptNear(marketPos, 25)
    if ep then pcall(function() ep:InputHoldBegin() end) task.wait(0.3) pcall(function() ep:InputHoldEnd() end) end
    task.wait(0.4)
    -- ยิง Remote
    pcall(function() 
        local rc = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes") 
        if rc then require(rc).Fire("_economy", "SellAll") end 
    end)
    -- ⭐ FIX #4: UI fallback
    pcall(function()
        local eg = PlayerGui:FindFirstChild("Economy") or PlayerGui:FindFirstChild("Ecconomy")
        if eg and eg:FindFirstChild("Group") then
            local main = eg.Group:FindFirstChild("Main") or eg.Group
            local sellBtn = main:FindFirstChild("Sell_All", true) or main:FindFirstChild("SellAll", true) or main:FindFirstChild("Sell", true)
            if not sellBtn then
                for _, b in ipairs(main:GetDescendants()) do
                    if b:IsA("GuiButton") and (b.Name:lower():find("sell") or (b:IsA("TextButton") and b.Text:lower():find("sell"))) then sellBtn = b break end
                end
            end
            if sellBtn and sellBtn:IsA("GuiButton") then SafeClickGuiButton(sellBtn) end
            local closeBtn = main:FindFirstChild("Exit") or main:FindFirstChild("Close") or main:FindFirstChild("Closed")
            if closeBtn and closeBtn:IsA("GuiButton") then SafeClickGuiButton(closeBtn) end
            eg.Group.Visible = false
        end
    end)
    task.wait(1.0)
    local c2 = GetNearbyPlayerVehicle(80) or EnsureCarAvailable(TOWN_CAR_SPAWN) if c2 then PressFToEnterCar(c2) end
end

-- =====================================
-- FISHING SYSTEM
-- =====================================
local function GetFishingRodTool()
    local char, bp = LocalPlayer.Character, LocalPlayer:FindFirstChild("Backpack")
    local names = {"FishingRodV3","FishingRodV2","FishingRod"}
    if char then for _, n in ipairs(names) do local t = char:FindFirstChild(n) if t and t:IsA("Tool") then return t end end end
    if bp then for _, n in ipairs(names) do local t = bp:FindFirstChild(n) if t and t:IsA("Tool") then return t end end end
end

local function EquipFishingRod()
    local char, hum, bp = LocalPlayer.Character, LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid"), LocalPlayer:FindFirstChild("Backpack")
    if not char or not hum then return nil end
    local rod = GetFishingRodTool()
    if rod and rod.Parent == char then return rod end
    if rod and rod.Parent == bp then hum:EquipTool(rod) task.wait(0.3) return rod end
    pcall(function() local rc = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes") if rc then require(rc).Fire("_inventory", "Use", "FishingRod") end end)
    task.wait(0.4) rod = GetFishingRodTool() if rod and rod.Parent == bp then hum:EquipTool(rod) task.wait(0.2) end
    return rod
end

local function IsFishingLineCast()
    local camF = workspace.Camera:FindFirstChild("FishingLocal") if camF and #camF:GetChildren() > 0 then return true end
    local pgui = LocalPlayer:FindFirstChild("PlayerGui") if pgui and pgui:FindFirstChild("FishingGame") then return true end
    return false
end

local function EnsureFishingPlatform(pos)
    if not fishingPlatform or not fishingPlatform.Parent then
        local p = Instance.new("Part") p.Name = "TyperTown_FishingSafePlatform" p.Size = Vector3.new(20, 2, 20) p.CFrame = CFrame.new(pos.X, pos.Y - 2.8, pos.Z) p.Anchored = true p.CanCollide = true p.Transparency = 1 p.Parent = workspace fishingPlatform = p
    else fishingPlatform.CFrame = CFrame.new(pos.X, pos.Y - 2.8, pos.Z) end
end

-- ⭐ FIX #3: BuyBaitMaxAtShop ส่งทั้ง FishingBait + Bait + UI fallback
local function BuyBaitMaxAtShop(shopPos)
    local char, hum, root = LocalPlayer.Character, LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid"), LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root or not hum then return end
    if hum.Sit then hum.Sit = false task.wait(0.2) end
    local safeStandPos = shopPos + Vector3.new(0, 2.5, 4) 
    root.CFrame = CFrame.lookAt(safeStandPos, shopPos) root.AssemblyLinearVelocity = Vector3.zero task.wait(0.5)
    local prompt = FindPromptNear(shopPos, 20, "shop") or FindPromptNear(root.Position, 20, nil)
    if prompt then prompt.Enabled = true pcall(function() prompt:InputHoldBegin() end) task.wait(0.2) pcall(function() prompt:InputHoldEnd() end) end
    local shopGui = nil local tWait = os.clock()
    while os.clock() - tWait < 3.0 do shopGui = PlayerGui:FindFirstChild("Shop") if shopGui and shopGui:FindFirstChild("Group") and shopGui.Group.Visible then break end task.wait(0.2) end
    local toBuy = math.clamp(math.floor(((LocalPlayer:FindFirstChild("PlayerData") and LocalPlayer.PlayerData:GetAttribute("Money")) or 1000) / 10), 10, 100) 
    pcall(function() 
        local remCore = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes") 
        if remCore then 
            local R = require(remCore)
            R.Fire("_shop", "Buy", { FishingBait = toBuy }, "Money")
            R.Fire("_shop", "Buy", { Bait = toBuy }, "Money")
        end 
    end)
    -- UI fallback
    pcall(function()
        if shopGui and shopGui:FindFirstChild("Group") and shopGui.Group:FindFirstChild("Main") then
            local main = shopGui.Group.Main
            local sf = main:FindFirstChild("ScrollingFrame")
            local baitBtn = sf and (sf:FindFirstChild("FishingBait") or sf:FindFirstChild("Bait"))
            if not baitBtn and sf then
                for _, b in ipairs(sf:GetDescendants()) do
                    if b:IsA("GuiButton") and (b.Name:lower():find("bait") or b.Name:lower():find("worm")) then baitBtn = b break end
                end
            end
            local payBtn = main:FindFirstChild("Pay") and main.Pay:FindFirstChild("Money")
            if baitBtn and payBtn then SafeClickGuiButton(baitBtn) task.wait(0.2) SafeClickGuiButton(payBtn) task.wait(0.3) end
            local closeBtn = main:FindFirstChild("Closed") or main:FindFirstChild("Close")
            if closeBtn then SafeClickGuiButton(closeBtn) end
            shopGui.Group.Visible = false
        end
    end)
end

-- ⭐ FIX #4: SellAllFishAtShop UI fallback
local function SellAllFishAtShop(shopPos)
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") if not root then return end
    local prompt = FindPromptNear(shopPos, 20, "sell") or FindPromptNear(shopPos, 20, "economy") or FindPromptNear(root.Position, 20, nil)
    if prompt then pcall(function() prompt:InputHoldBegin() end) task.wait(0.2) pcall(function() prompt:InputHoldEnd() end) end
    task.wait(0.3)
    pcall(function() local rc = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes") if rc then require(rc).Fire("_economy", "SellAll") end end)
    pcall(function()
        local econ = PlayerGui:FindFirstChild("Economy") or PlayerGui:FindFirstChild("Ecconomy")
        if econ and econ:FindFirstChild("Group") and econ.Group:FindFirstChild("Main") then
            local main = econ.Group.Main
            local sellBtn = main:FindFirstChild("Sell_All", true) or main:FindFirstChild("SellAll", true)
            if sellBtn then SafeClickGuiButton(sellBtn) task.wait(0.2) end
            local closeBtn = main:FindFirstChild("Closed") or main:FindFirstChild("Close")
            if closeBtn then SafeClickGuiButton(closeBtn) end
            econ.Group.Visible = false
        end
    end)
end

local function SolveFishingMinigame()
    local vim = VirtualInputManager local fg = PlayerGui:FindFirstChild("FishingGame") local mg = fg and fg:FindFirstChild("Minigame") if not mg then return end
    local isHolding = false local startTime = os.clock() local conn = nil
    conn = RunService.RenderStepped:Connect(function()
        if not isAutoFishingEnabled or not fg or not fg.Parent then if isHolding then pcall(function() vim:SendKeyEvent(false, Enum.KeyCode.Space, false, game) end) isHolding = false end if conn then conn:Disconnect() conn = nil end return end
        local fish, point = mg:FindFirstChild("Fish"), mg:FindFirstChild("Game") and mg.Game:FindFirstChild("Point")
        if fish and point then
            if fish.AbsolutePosition.Y + (fish.AbsoluteSize.Y * 0.5) < point.AbsolutePosition.Y + (point.AbsoluteSize.Y * 0.5) - 4 then
                if not isHolding then isHolding = true pcall(function() vim:SendKeyEvent(true, Enum.KeyCode.Space, false, game) end) end
            elseif fish.AbsolutePosition.Y + (fish.AbsoluteSize.Y * 0.5) > point.AbsolutePosition.Y + (point.AbsoluteSize.Y * 0.5) + 4 then
                if isHolding then isHolding = false pcall(function() vim:SendKeyEvent(false, Enum.KeyCode.Space, false, game) end) end
            end
        end
    end)
    while fg and fg.Parent and isAutoFishingEnabled and (os.clock() - startTime < 30) do task.wait(0.05) fg = PlayerGui:FindFirstChild("FishingGame") end
    if conn then conn:Disconnect() conn = nil end if isHolding then pcall(function() vim:SendKeyEvent(false, Enum.KeyCode.Space, false, game) end) end
    task.wait(3.0)
end

pcall(function() local pgui = PlayerGui if pgui then pgui.ChildAdded:Connect(function(child) if child.Name == "FishingGame" and isAutoFishingEnabled then task.spawn(SolveFishingMinigame) end end) end end)

StartAutoFishing = function()
    if fishingThread then return end
    isAutoFishingEnabled = true
    fishingThread = task.spawn(function()
        local isFirstRun = true
        while isAutoFishingEnabled do
            if isFirstRun then WarpToTownAndSpawnCar() isFirstRun = false end
            if not isAutoFishingEnabled then break end
            local char, root, hum = LocalPlayer.Character, LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"), LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            local pData = LocalPlayer:FindFirstChild("PlayerData")
            if root and hum and hum.Health > 0 then
                local bait = (pData and (pData:GetAttribute("FishingBait") or pData:GetAttribute("Bait"))) or 0
                local fishCount = ((pData and pData:GetAttribute("Bettafish")) or 0) + ((pData and pData:GetAttribute("Anglerfish")) or 0)
                if bait <= 0 or fishCount >= 25 then
                    if IsFishingLineCast() then pcall(function() local r = char:FindFirstChild("FishingRod") if r then r:Activate() end end) task.wait(0.4) end
                    if (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(FISHING_PARKING_POS.X, 0, FISHING_PARKING_POS.Z)).Magnitude > 8 then SmoothWalkTo(FISHING_PARKING_POS, 25, function() return isAutoFishingEnabled end, 4.0) end
                    local myCar = GetNearbyPlayerVehicle(80) or EnsureCarAvailable(TOWN_CAR_SPAWN)
                    if myCar then EnsurePlayerSeatedInCar(myCar) DriveCarTo(BAIT_SHOP_POS, function() return isAutoFishingEnabled end) ExitCarNaturally(myCar) SellAllFishAtShop(BAIT_SHOP_POS) BuyBaitMaxAtShop(BAIT_SHOP_POS) EnsurePlayerSeatedInCar(myCar) DriveCarTo(FISHING_PARKING_POS, function() return isAutoFishingEnabled end) ExitCarNaturally(myCar) end
                end
                if not isAutoFishingEnabled then break end
                char, root = LocalPlayer.Character, LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if root and (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(FISHING_SPOT.X, 0, FISHING_SPOT.Z)).Magnitude > 3.0 then SmoothWalkTo(FISHING_SPOT, 25, function() return isAutoFishingEnabled end, 2.5) end
                EnsureFishingPlatform(FISHING_SPOT) GrantAntiXGrace(20)
                local rod = char:FindFirstChild("FishingRod") or EquipFishingRod()
                if rod and rod.Parent == char then
                    if not IsFishingLineCast() then root.CFrame = CFrame.lookAt(FISHING_SPOT, FISHING_LOOK_TARGET) task.wait(0.2) pcall(function() rod:Activate() end) task.wait(1.0) end
                    if PlayerGui:FindFirstChild("FishingGame") then SolveFishingMinigame() task.wait(3.0) end
                end
            end
            task.wait(0.2)
        end
        if fishingPlatform and fishingPlatform.Parent then fishingPlatform:Destroy() end
        fishingThread = nil
    end)
end

StopAutoFishing = function() isAutoFishingEnabled = false if fishingPlatform and fishingPlatform.Parent then fishingPlatform:Destroy() fishingPlatform = nil end fishingThread = nil end

-- =====================================
-- AUTO BEST PRICE
-- =====================================
local RealTimePrices = {}
pcall(function()
    local remotes = require(ReplicatedStorage:WaitForChild("Systems"):WaitForChild("Modules"):WaitForChild("Core"):WaitForChild("Remotes"))
    remotes.On("_economy", function(action, priceTable) if (action == "Update" or action == "Open") and type(priceTable) == "table" then for k, v in pairs(priceTable) do if type(v) == "number" then RealTimePrices[k] = v end end end end)
    task.spawn(function() while true do pcall(function() remotes.Fire("_economy", "Request") end) task.wait(5) end end)
end)

local function GetBestFoodPack()
    local foodItems = { Sandwich = {"Sandwich", "Sandwish"}, MangoRice = {"MangoRice"}, BananaPack = {"BananaPack"}, KangSom = {"KangSom"} }
    local displayNames = { Sandwich = "แซนวิช", MangoRice = "ข้าวมันมะม่วง", BananaPack = "กล้วยแพ็ค", KangSom = "แกงส้ม" }
    local bestKey, bestName, bestPrice = nil, "รอข้อมูลตลาด...", 0
    for key, aliases in pairs(foodItems) do
        local price = 0
        for _, alias in ipairs(aliases) do if RealTimePrices[alias] then price = RealTimePrices[alias] break end end
        if price > bestPrice then bestPrice = price bestKey = key bestName = displayNames[key] end
    end
    if bestPrice == 0 then return nil, "รอข้อมูลจากตลาด (กรุณาเดินไปที่ตลาด)", 0 end
    return bestKey, bestName, bestPrice
end

-- =====================================
-- SERVER HOP
-- =====================================
local isHopping = false
local function IsInMainGame() return tostring(game.PlaceId) == "119554426329370" end

-- ⭐ FIX #5: qot ใช้ URL สคริปต์เต็ม
local function ExitToServerSelectionScreen(reason)
    if isHopping then return end isHopping = true
    pcall(function() 
        local qot = queue_on_teleport or (syn and syn.queue_on_teleport) 
        if qot then 
            -- ⭐ ใช้ URL สคริปต์เต็ม (replace ด้วย URL จริงของคุณ)
            qot([[loadstring(game:HttpGet("https://raw.githubusercontent.com/14thx/Aslwoll/main/main.lua"))()]])
        end 
    end)
    pcall(function() game:GetService("TeleportService"):Teleport(73746968849439, LocalPlayer) end)
    task.delay(6.0, function() isHopping = false end)
end

task.spawn(function()
    task.wait(6.0)
    while true do
        task.wait(0.5)
        if IsInMainGame() and isAutoHopOnPlayerNearbyEnabled and not isHopping then
            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if root then for _, pl in ipairs(Players:GetPlayers()) do if pl ~= LocalPlayer and pl.Character then local orr = pl.Character:FindFirstChild("HumanoidRootPart") if orr and (orr.Position - root.Position).Magnitude <= autoHopDistance then ExitToServerSelectionScreen("เจอคนใกล้") break end end end end
        end
    end
end)

-- =====================================
-- MAIN UI CREATION
-- =====================================
local MarvenState = { AutoEat = true, AutoFarmItem = false, AutoProcessFarm = false, AutoMineFarm = false, AutoFish = false, ServerHop = true }
local MarvenSelected = { NormalFarmType = "Bread", ProcessFarmType = "Banana", MineFarmType = "Rock" }
local MarvenSession = { AutoFarmItem = 0, AutoProcessFarm = 0, AutoMineFarm = 0 }
local function StartSession(key) MarvenSession[key] = (MarvenSession[key] or 0) + 1 local id = MarvenSession[key] return function() return MarvenState[key] == true and MarvenSession[key] == id end end
local function StopSession(key) MarvenSession[key] = (MarvenSession[key] or 0) + 1 end

local Window = UI:CreateWindow({ Title = "MarvenRiz Hub", Author = "by. zems.xz", Version = "Premium v2.6 FINAL", Logo = "rbxassetid://124905448303407", Folder = "MarvenRizHub", ConfigAutoSave = true, ToggleKey = Enum.KeyCode.RightShift, Width = 620, Height = 430 })
Window:SetTheme({ Accent = Color3.fromRGB(0, 110, 255) })

local StatusTab = Window:Tab({Title = "สถานะ", Icon = "activity"})
StatusTab:Section({Title = "ข้อมูล"}):Banner({Title = "MarvenRiz Hub", SubTitle = "CRAFT FIXED + FULL FARM + BANANA FIX"})

-- BEST PRICE
local FarmTab = Window:Tab({Title = "ฟาร์ม", Icon = "sprout"})
local BestPriceSection = FarmTab:Section({Title = "🌟 ข้อมูลราคาตลาด (Real-Time)"})
local BestPriceInfo = BestPriceSection:Paragraph({ Title = "📊 ราคาอาหารที่ดีที่สุด", Content = "กำลังดึงข้อมูล..." })
task.spawn(function() while true do task.wait(1.5) pcall(function() local k, name, price = GetBestFoodPack() if BestPriceInfo and BestPriceInfo.SetDesc then BestPriceInfo:SetDesc(string.format("⭐ ราคาดีที่สุด: %s\n💰 ราคา: %d฿", tostring(name), tonumber(price))) end end) end end)

-- FARM RUNNERS
local function RunNormalFarm()
    if not MarvenState.AutoFarmItem then return end local check = StartSession("AutoFarmItem") task.spawn(function() local first = true while check() do if first then WarpToTownAndSpawnCar() first = false end if not check() then break end local crop = MarvenSelected.NormalFarmType if GetPlayerInventoryCount(crop) < 60 then HarvestSingleCrop(crop, 60, check) end SellAtEconomyMarket(check) task.wait(0.5) end end)
end

local function RunProcessFarm()
    if not MarvenState.AutoProcessFarm then return end local check = StartSession("AutoProcessFarm") task.spawn(function() local first = true while check() do if first then WarpToTownAndSpawnCar() first = false end local k = MarvenSelected.ProcessFarmType 
        if k == "Banana" then 
            if GetPlayerInventoryCount("Banana") < 60 then HarvestSingleCrop("Banana", 60, check) end 
            ProcessBananaAtStation(check)   -- ⭐ FIX #1
        elseif k == "Mango" then 
            if GetPlayerInventoryCount("Mango") < 60 then HarvestSingleCrop("Mango", 60, check) end 
            if GetPlayerInventoryCount("Rice") < 60 then HarvestSingleCrop("Rice", 60, check) end 
            CraftFoodAtStation("MangoRice", check) 
        elseif k == "RiceKapaoMoo" then 
            if GetPlayerInventoryCount("Pig") < 60 then HarvestSingleCrop("Pig", 60, check) end 
            if GetPlayerInventoryCount("Rice") < 60 then HarvestSingleCrop("Rice", 60, check) end 
            CraftFoodAtStation("RiceKapaoMoo", check) 
        elseif k == "Sandwich" then 
            if GetPlayerInventoryCount("Bread") < 60 then HarvestSingleCrop("Bread", 60, check) end 
            if GetPlayerInventoryCount("Catchup") < 60 then HarvestSingleCrop("Catchup", 60, check) end 
            if GetPlayerInventoryCount("Pig") < 60 then HarvestSingleCrop("Pig", 60, check) end 
            CraftFoodAtStation("Sandwich", check) 
        elseif k == "KangSom" then 
            if GetPlayerInventoryCount("Tomato") < 60 then HarvestSingleCrop("Tomato", 60, check) end 
            if GetPlayerInventoryCount("Crab") < 60 then HarvestSingleCrop("Crab", 60, check) end 
            CraftFoodAtStation("KangSom", check) 
        end 
        SellAtEconomyMarket(check) task.wait(0.5) end end)
end

local function RunMineFarm()
    if not MarvenState.AutoMineFarm then return end local check = StartSession("AutoMineFarm") task.spawn(function() local first = true while check() do if first then WarpToTownAndSpawnCar() first = false end local ore = MarvenSelected.MineFarmType if GetPlayerInventoryCount(ore) < 120 then HarvestSingleCrop(ore, 120, check) end ProcessOreAtStation(ore, (ore == "Svibranium" and 4 or 2), check) DepositAllToVault(check) task.wait(1.0) end end)
end

-- TABS
local NormalFarm = FarmTab:Section({Title = "ฟาร์มปกติ"})
NormalFarm:Dropdown({ Title = "เลือกฟาร์ม", Options = {"ขนมปัง", "ซอสมะเขือเทศ", "หมู", "มะม่วง", "ข้าว", "มะเขือเทศ", "กล้วย", "ปู", "มะพร้าว", "ข้าวโพด", "ไข่ไก่", "นม", "อ้อย"}, Default = "ขนมปัง", Callback = function(v) local map = {["ขนมปัง"]="Bread", ["ซอสมะเขือเทศ"]="Catchup", ["หมู"]="Pig", ["มะม่วง"]="Mango", ["ข้าว"]="Rice", ["มะเขือเทศ"]="Tomato", ["กล้วย"]="Banana", ["ปู"]="Crab", ["มะพร้าว"]="Coconut", ["ข้าวโพด"]="Corn", ["ไข่ไก่"]="Egg", ["นม"]="Milk", ["อ้อย"]="Sugarcane"} MarvenSelected.NormalFarmType = map[v] or "Bread" end })
NormalFarm:Toggle({ Title = "ออโต้ ฟาร์มวัตถุดิบ", Default = false, Callback = function(v) MarvenState.AutoFarmItem = v if v then RunNormalFarm() else StopSession("AutoFarmItem") pcall(CancelGameFarm) end end })

local ProcessFarm = FarmTab:Section({Title = "ฟาร์มโพสต์ (คราฟต์/แปรรูป)"})
ProcessFarm:Dropdown({ Title = "เลือกของ", Options = {"กล้วยแพ็ค", "ข้าวมันมะม่วง", "ข้าวกะเพราหมู", "แซนวิช", "แกงส้ม"}, Default = "กล้วยแพ็ค", Callback = function(v) local map = {["กล้วยแพ็ค"]="Banana", ["ข้าวมันมะม่วง"]="Mango", ["ข้าวกะเพราหมู"]="RiceKapaoMoo", ["แซนวิช"]="Sandwich", ["แกงส้ม"]="KangSom"} MarvenSelected.ProcessFarmType = map[v] or "Banana" end })
ProcessFarm:Toggle({ Title = "ออโต้ ฟาร์มโพสต์", Default = false, Callback = function(v) MarvenState.AutoProcessFarm = v if v then RunProcessFarm() else StopSession("AutoProcessFarm") pcall(CancelGameFarm) end end })

local MineFarm = FarmTab:Section({Title = "ฟาร์มเหมือง (ขุด+แปรรูป+ฝาก)"})
MineFarm:Dropdown({ Title = "เลือกเหมือง", Options = {"ฟาร์มหิน (หลอมแร่)", "ฟาร์มไวเบรเนียม (หลอมแร่)"}, Default = "ฟาร์มหิน (หลอมแร่)", Callback = function(v) local map = {["ฟาร์มหิน (หลอมแร่)"]="Rock", ["ฟาร์มไวเบรเนียม (หลอมแร่)"]="Svibranium"} MarvenSelected.MineFarmType = map[v] or "Rock" end })
MineFarm:Toggle({ Title = "ออโต้ ฟาร์มเหมือง", Default = false, Callback = function(v) MarvenState.AutoMineFarm = v if v then RunMineFarm() else StopSession("AutoMineFarm") pcall(CancelGameFarm) end end })

local OtherTab = Window:Tab({Title = "อื่นๆ", Icon = "layers"})
OtherTab:Section({Title = "ระบบตกปลา"}):Toggle({ Title = "เริ่มออโต้ตกปลา", Default = false, Callback = function(v) MarvenState.AutoFish = v if v then pcall(StartAutoFishing) else pcall(StopAutoFishing) end end })

local AdvTab = Window:Tab({Title = "ขั้นสูง", Icon = "sliders"})
local SpeedSection = AdvTab:Section({Title = "ความเร็วยานพาหนะ"})
SpeedSection:Slider({ Title = "ความเร็วขับรถ (Studs/s)", Default = 150, Min = 10, Max = 280, Rounding = 0, Callback = function(v) VehicleDriveSpeed = math.clamp(math.round(v), 10, 280) end })
SpeedSection:Toggle({ Title = "รถทะลุสิ่งกีดขวาง (Vehicle NoClip)", Default = true, Callback = function(v) isVehicleNoclipEnabled = v end })

local UnloadSection = AdvTab:Section({Title = "ปิดสคริปต์"})
UnloadSection:Button({ Title = "ปิดสคริปต์ (Unload)", Callback = function() MarvenState.AutoFarmItem = false MarvenState.AutoProcessFarm = false MarvenState.AutoMineFarm = false MarvenState.AutoFish = false StopSession("AutoFarmItem") StopSession("AutoProcessFarm") StopSession("AutoMineFarm") pcall(StopAutoFishing) pcall(function() if vehiclePlatformPart then vehiclePlatformPart:Destroy() end if fishingPlatform then fishingPlatform:Destroy() end if Window and Window.Destroy then Window:Destroy() end end) end })

pcall(function() if Loading and Loading.Hide then Loading.Hide() end end)

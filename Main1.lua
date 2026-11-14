-- ==============================================================================
-- MARVENRIZ HUB + NEXUS ENGINE (ULTIMATE MASTER 100% - REAL-TIME ECONOMY SYNCED)
-- (รวมฟังก์ชัน WarpToTownAndSpawnCar และ ProcessBananaAtStation จากต้นฉบับ 100%)
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

_G.RealTimePrices = _G.RealTimePrices or {}
local RealTimePrices = _G.RealTimePrices

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
    if hookfunction and lp and lp.Kick then
        hookfunction(lp.Kick, newcclosure(function() return nil end))
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
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
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
    for _, desc in ipairs(group:GetDescendants()) do
        if desc:IsA("GuiButton") and desc.Visible then
            local txt = (desc:IsA("TextButton") and desc.Text:lower()) or ""
            local name = desc.Name:lower()
            if name:find("pound") or txt:find("pound") then
                return desc, "pound", desc.Parent
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
            if exitBtn and exitBtn:IsA("GuiButton") then
                if firesignal then firesignal(exitBtn.MouseButton1Click) end
            end
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
    local ownerId = v:GetAttribute("OwnerId") or v:GetAttribute("UserId") or v:GetAttribute("PlayerId")
    if owner ~= nil and tostring(owner) ~= "" then
        if tostring(owner) == myName or tostring(owner) == tostring(myUserId) then MY_SPAWNED_CAR = v return true end
        return false
    end
    if ownerId ~= nil and tonumber(ownerId) then
        if tonumber(ownerId) == myUserId then MY_SPAWNED_CAR = v return true else return false end
    end
    local ownerVal = v:FindFirstChild("Owner") or v:FindFirstChild("Player")
    if ownerVal and (ownerVal:IsA("StringValue") or ownerVal:IsA("ObjectValue")) then
        if ownerVal.Value == myName or ownerVal.Value == LocalPlayer then MY_SPAWNED_CAR = v return true
        else return false end
    end
    local seat = v:FindFirstChildWhichIsA("VehicleSeat", true)
    if seat and seat.Occupant and seat.Occupant ~= hum then return false end
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
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    if hum and hum.Sit and hum.SeatPart then
        local v = hum.SeatPart:FindFirstAncestorOfClass("Model")
        if v and IsMyVehicle(v) then return v end
    end
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
    local seat = car:FindFirstChild("DriveSeat", true) or car:FindFirstChildWhichIsA("VehicleSeat", true) or car:FindFirstChildWhichIsA("Seat", true)
    if not seat then return false end
    if hum.Sit and hum.SeatPart == seat then
        MY_SPAWNED_CAR = car
        pcall(function() game:GetService("ProximityPromptService").Enabled = false end)
        return true
    end
    if hum.Sit and hum.SeatPart ~= seat then hum.Sit = false task.wait(0.2) end
    GrantAntiXGrace(20)
    local drivePrompt = nil
    local pFolder = seat:FindFirstChild("Prompt")
    if pFolder and pFolder:FindFirstChild("Prompt") and pFolder.Prompt:IsA("ProximityPrompt") then
        drivePrompt = pFolder.Prompt
    else
        for _, d in ipairs(seat:GetDescendants()) do
            if d:IsA("ProximityPrompt") and d.ActionText:lower():find("drive") and not d.ActionText:lower():find("passenger") then
                drivePrompt = d break
            end
        end
    end
    if not drivePrompt then
        for _, d in ipairs(car:GetDescendants()) do
            if d:IsA("ProximityPrompt") then
                local act = (d.ActionText or ""):lower()
                local nm = (d.Name or ""):lower()
                if (act:find("drive") or nm:find("drive") or d.KeyboardKeyCode == Enum.KeyCode.F) and not act:find("passenger") and not nm:find("passenger") then
                    drivePrompt = d break
                end
            end
        end
    end
    for _, d in ipairs(car:GetDescendants()) do
        if d:IsA("ProximityPrompt") and (d.ActionText:lower():find("passenger") or d.Name:lower():find("passenger")) then
            d.Enabled = false
        end
    end
    local vf = (workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Vehicles")) or workspace:FindFirstChild("Vehicles")
    if vf then
        for _, ov in ipairs(vf:GetChildren()) do
            if ov ~= car then
                for _, op in ipairs(ov:GetDescendants()) do
                    if op:IsA("ProximityPrompt") then op.Enabled = false end
                end
            end
        end
    end
    local doorCF = seat.CFrame * CFrame.new(-2.6, 0.2, 0)
    root.CFrame = CFrame.lookAt(doorCF.Position, seat.Position)
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    task.wait(0.15)
    pcall(function()
        game:GetService("ProximityPromptService").Enabled = true
        if drivePrompt then drivePrompt.Enabled = true end
    end)
    local t0 = os.clock()
    while os.clock() - t0 < 3.0 do
        if hum.Sit and hum.SeatPart then break end
        if drivePrompt then
            pcall(function() drivePrompt.HoldDuration = 0 end)
            pcall(function() fireproximityprompt(drivePrompt) end)
            pcall(function() drivePrompt:InputHoldBegin() end)
            task.wait(0.08)
            pcall(function() drivePrompt:InputHoldEnd() end)
        end
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
            task.wait(0.06)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
        end)
        task.wait(0.2)
    end
    if not (hum.Sit and hum.SeatPart) then
        pcall(function()
            root.CFrame = seat.CFrame + Vector3.new(0, 0.5, 0)
            seat:Sit(hum)
        end)
        task.wait(0.2)
    end
    if hum.Sit and hum.SeatPart then
        MY_SPAWNED_CAR = car
        pcall(function() game:GetService("ProximityPromptService").Enabled = false end)
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
    local last = root.Position
    local stuck = 0
    while (root.Position - targetPos).Magnitude > stopDist and (os.clock() - st < maxTimeout) do
        if shouldContinueCheck and not shouldContinueCheck() then return false end
        GrantAntiXGrace(5)
        local curDist = (root.Position - targetPos).Magnitude
        if curDist <= 12.0 then
            local boothPrompt = FindBoothPromptNear(targetPos, 20) or FindBoothPromptNear(root.Position, 20)
            if boothPrompt then
                local cs = PlayerGui:FindFirstChild("Car_Spawn")
                local group = cs and cs:FindFirstChild("Group")
                if group and not group.Visible then
                    boothPrompt.Enabled = true
                    pcall(function() boothPrompt.HoldDuration = 0 end)
                    if fireproximityprompt then pcall(function() fireproximityprompt(boothPrompt) end) end
                end
                if curDist <= 6.0 then break end
            end
        end
        hum:MoveTo(targetPos)
        if (root.Position - last).Magnitude < 0.4 then
            stuck += 1
            if stuck >= 3 then hum.Jump = true stuck = 0 end
        else stuck = 0 end
        last = root.Position
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
    if TOWN_CAR_SPAWN then
        local dist = (TOWN_CAR_SPAWN - fromPos).Magnitude
        if dist < bd then bd, best = dist, TOWN_CAR_SPAWN end
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
    local cs = workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Car_Spawn")
    if cs then
        for _, desc in ipairs(cs:GetDescendants()) do
            if desc:IsA("ProximityPrompt") then
                local p = desc.Parent
                local pos = (p:IsA("Attachment") and p.WorldPosition) or (p:IsA("BasePart") and p.Position)
                if pos and (pos - fromPos).Magnitude <= maxDist then return desc end
            end
        end
    end
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
    for _, d in ipairs(group:GetDescendants()) do
        if d:IsA("GuiButton") and d.Visible and d.Name:lower():find("pound") then return d end
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
    for _, d in ipairs(group:GetDescendants()) do
        if d:IsA("GuiButton") and d.Visible and d.Name:lower():find("spawn") then return d end
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
        if spPt and spPt:IsA("BasePart") then
            myCar:PivotTo(spPt.CFrame + Vector3.new(0, 1.2, 0))
        else
            local gy = GetGroundLevel(boothPos.X, boothPos.Z, boothPos.Y)
            myCar:PivotTo(CFrame.new(boothPos.X, gy + 1.2, boothPos.Z))
        end
        myCar.PrimaryPart.AssemblyLinearVelocity = Vector3.zero
        myCar.PrimaryPart.AssemblyAngularVelocity = Vector3.zero
    end
    task.wait(2.0)
    ExitCarNaturally(myCar)
    if root and (root.Position - boothPos).Magnitude > 8 then
        SmoothWalkTo(boothPos, 3, nil, 5.0)
    end
    pcall(function()
        local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if not h or not h.Sit then game:GetService("ProximityPromptService").Enabled = true end
    end)
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
    if boothPrompt then
        boothPrompt.Enabled = true
        TriggerPrompt(boothPrompt)
    end
    local cs = PlayerGui:WaitForChild("Car_Spawn", 1.5)
    local t0 = os.clock()
    while (not cs or not cs:FindFirstChild("Group") or not cs.Group.Visible) and (os.clock() - t0 < 1.2) do
        if boothPrompt then TriggerPrompt(boothPrompt) end
        task.wait(0.15)
    end
    if cs and cs:FindFirstChild("Group") and cs.Group.Visible then
        local btn, btnType = FindCarSpawnOrPoundButton(cs.Group, cName)
        if btn and btnType == "pound" then ClickGuiButton(btn) task.wait(0.4) end
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
    LAST_STORED_BOOTH = boothPos
    pcall(function() game:GetService("ProximityPromptService").Enabled = true end)
    if boothPos then
        local dist = (root.Position - boothPos).Magnitude
        if dist > 15 then
            local gy = GetGroundLevel(boothPos.X, boothPos.Z, boothPos.Y)
            root.CFrame = CFrame.new(boothPos.X, gy + 1.2, boothPos.Z)
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
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
            pcall(function()
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                task.wait(0.04)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
            end)
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
            pcall(function()
                local rc = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes")
                if rc then require(rc).Fire("_carspawn", "Despawn", cName) end
            end)
            local tw = os.clock()
            while os.clock() - tw < 4.5 do
                task.wait(0.2)
                if (sBtn and sBtn.Visible) or (card and card:FindFirstChild("Spawn") and card.Spawn.Visible) then break end
            end
            if card and card:FindFirstChild("Spawn") then sBtn = card.Spawn end
        end
        if sBtn and sBtn.Visible then
            ClickGuiButton(sBtn)
            task.wait(1.0)
            local check = GetNearbyPlayerVehicle(80) or GetPlayerVehicle()
            if not check or not check.PrimaryPart then
                for i = 1, 2 do
                    ClickGuiButton(sBtn)
                    task.wait(1.0)
                    check = GetNearbyPlayerVehicle(80) or GetPlayerVehicle()
                    if check and check.PrimaryPart then break end
                end
            end
        end
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

-- =====================================
-- WarpToTownAndSpawnCar (เหมือนต้นฉบับ 100% + เปลี่ยน Fluent -> UI)
-- =====================================
WarpToTownAndSpawnCar = function()
    GrantAntiXGrace(45)
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    -- ลุกออกจากเก้าอี้เสมอ เพื่อเบิกรถคันใหม่
    if hum and hum.Sit then
        hum.Sit = false
        task.wait(0.15)
    end

    pcall(function()
        UI:Notify({
            Title = "NEXUS HUB",
            Content = "🚀 วาปไปจุดเบิกรถในเมืองเพื่อเบิกรถใหม่...",
            Duration = 2.0
        })
    end)

    pcall(function()
        game:GetService("ProximityPromptService").Enabled = true
    end)

    pcall(function()
        LocalPlayer:RequestStreamAroundAsync(TOWN_CAR_SPAWN, 45)
    end)

    -- วาปไปที่หน้าตู้เบิกรถในเมืองเท่านั้น
    local groundY = GetGroundLevel(TOWN_CAR_SPAWN.X, TOWN_CAR_SPAWN.Z, TOWN_CAR_SPAWN.Y)
    local townPos = Vector3.new(TOWN_CAR_SPAWN.X, groundY + 1.2, TOWN_CAR_SPAWN.Z)
    root.CFrame = CFrame.new(townPos)
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    task.wait(0.4)

    -- สั่งเบิกรถผ่านตู้ในเมืองตามสเต็ป POUND -> SPAWN
    local car = SpawnCarAtBooth(TOWN_CAR_SPAWN)
    if not car then
        car = GetNearbyPlayerVehicle(80)
    end
    if car then
        EnsurePlayerSeatedInCar(car)
        CloseCarSpawnGui()
    end
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
        p.Anchored = true
        p.CanCollide = true
        p.Transparency = 1
        p.Material = Enum.Material.SmoothPlastic
        p.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.8, 0, 1, 1)
        p.Parent = workspace
        vehiclePlatformPart = p
    else
        vehiclePlatformPart.CanCollide = false
    end
    vehiclePlatformPart.CFrame = CFrame.new(carPos.X, surfaceY - 0.75, carPos.Z)
end

local function IsWideSolidGround(x, z)
    if z >= 350 and z <= 4050 then return false end
    local offsets = {Vector2.new(0,0), Vector2.new(25,0), Vector2.new(-25,0), Vector2.new(0,25), Vector2.new(0,-25)}
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.IgnoreWater = false
    local fl = {}
    if LocalPlayer.Character then table.insert(fl, LocalPlayer.Character) end
    local vf = (workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Vehicles")) or workspace:FindFirstChild("Vehicles")
    if vf then table.insert(fl, vf) end
    if MY_SPAWNED_CAR then table.insert(fl, MY_SPAWNED_CAR) end
    if vehiclePlatformPart then table.insert(fl, vehiclePlatformPart) end
    params.FilterDescendantsInstances = fl
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
    local DRIVE_TIMEOUT = 120
    local driveStartTime = os.clock()

    while trav < distT do
        if os.clock() - driveStartTime > DRIVE_TIMEOUT then
            if vehiclePlatformPart then vehiclePlatformPart:Destroy() vehiclePlatformPart = nil end
            return false
        end
        if check and not check() then
            if vehiclePlatformPart then vehiclePlatformPart:Destroy() vehiclePlatformPart = nil end
            return false
        end
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
        pcall(function()
            if hum then
                hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
                hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
            end
        end)
        local dir = Vector3.new(dest.X - tx, 0, dest.Z - tz)
        local cf = CFrame.new(tx, sY, tz)
        if dir.Magnitude > 0.1 then cf = CFrame.lookAt(Vector3.new(tx, sY, tz), Vector3.new(tx, sY, tz) + dir) end
        car:PivotTo(cf)
        pcall(function()
            if car.PrimaryPart then
                car.PrimaryPart.AssemblyLinearVelocity = Vector3.zero
                car.PrimaryPart.AssemblyAngularVelocity = Vector3.zero
            end
            if seat and seat:IsA("BasePart") then
                seat.AssemblyLinearVelocity = Vector3.zero
                seat.AssemblyAngularVelocity = Vector3.zero
            end
        end)
        if isVehiclePlatformEnabled then
            if flying then
                if vehiclePlatformPart then vehiclePlatformPart.CanCollide = false end
            else
                EnsureVehiclePlatform(sY - rideH, Vector3.new(tx, sY, tz))
            end
        end
        RunService.Heartbeat:Wait()
    end
    pcall(function()
        local fg = GetGroundLevel(dest.X, dest.Z, dest.Y)
        car:PivotTo(CFrame.new(dest.X, math.max(fg + rideH, 16.0), dest.Z))
        if car.PrimaryPart then
            car.PrimaryPart.AssemblyLinearVelocity = Vector3.zero
            car.PrimaryPart.AssemblyAngularVelocity = Vector3.zero
        end
    end)
    if vehiclePlatformPart then vehiclePlatformPart:Destroy() vehiclePlatformPart = nil end
    task.wait(0.1)
    return true
end

RunService.Stepped:Connect(function()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum and hum.Sit and hum.SeatPart then
        local myCar = hum.SeatPart:FindFirstAncestorOfClass("Model")
        if myCar then
            local sp = hum.SeatPart.Position
            local gy = GetGroundLevel(sp.X, sp.Z, sp.Y)
            if isVehiclePlatformEnabled then
                EnsureVehiclePlatform(gy - 0.2, sp)
            elseif vehiclePlatformPart then
                vehiclePlatformPart:Destroy()
                vehiclePlatformPart = nil
            end
            if isVehicleNoclipEnabled then
                for _, part in ipairs(myCar:GetDescendants()) do
                    if part:IsA("BasePart") and part ~= vehiclePlatformPart then
                        local pn = part.Name:lower()
                        if pn:find("groundguard") or pn:find("bumpstop") then
                            part.CanCollide = true
                        else
                            part.CanCollide = false
                        end
                    end
                end
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end
    else
        if vehiclePlatformPart then vehiclePlatformPart:Destroy() vehiclePlatformPart = nil end
        if isVehicleNoclipEnabled and char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
    end
end)

-- =====================================
-- HARVEST SYSTEM
-- =====================================
local function TriggerFarmPromptDirectly(cropName)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root then return false end
    if hum and hum.Sit then
        hum.Sit = false
        pcall(function()
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            if hum.SeatPart then hum.SeatPart = nil end
        end)
        task.wait(0.15)
    end
    local farmSys = workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Farm")
    local farmFolder = farmSys and farmSys:FindFirstChild(cropName)
    local targetPrompt = nil
    if farmFolder then
        for _, d in ipairs(farmFolder:GetDescendants()) do
            if d:IsA("ProximityPrompt") and d.Enabled then
                local n = (d.Parent and d.Parent.Name or ""):lower()
                local a = (d.ActionText or ""):lower()
                local o = (d.ObjectText or ""):lower()
                if not n:find("spawn") and not a:find("spawn") and not a:find("car") and not o:find("car") then
                    targetPrompt = d break
                end
            end
        end
    end
    if not targetPrompt then
        for _, desc in ipairs(workspace:GetDescendants()) do
            if desc:IsA("ProximityPrompt") and desc.Enabled then
                local prParent = desc.Parent
                local pPos = (prParent:IsA("Attachment") and prParent.WorldPosition) or (prParent:IsA("BasePart") and prParent.Position)
                if pPos and (pPos - root.Position).Magnitude <= 18 then
                    local action = (desc.ActionText or ""):lower()
                    local obj = (desc.ObjectText or ""):lower()
                    if not action:find("spawn") and not action:find("car") and not obj:find("car") then
                        targetPrompt = desc
                        break
                    end
                end
            end
        end
    end
    if targetPrompt then
        pcall(function()
            if fireproximityprompt then pcall(function() fireproximityprompt(targetPrompt) end) end
            pcall(function()
                targetPrompt:InputHoldBegin()
                task.wait(targetPrompt.HoldDuration > 0 and (targetPrompt.HoldDuration + 0.05) or 0.15)
                targetPrompt:InputHoldEnd()
            end)
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
                local n = (desc.Parent and desc.Parent.Name or ""):lower()
                local a = (desc.ActionText or ""):lower()
                local o = (desc.ObjectText or ""):lower()
                if not n:find("spawn") and not a:find("spawn") and not a:find("car") and not o:find("car") then
                    local prParent = desc.Parent
                    local pPos = (prParent:IsA("Attachment") and prParent.WorldPosition) 
                              or (prParent:IsA("BasePart") and prParent.Position) 
                              or (prParent.Parent and prParent.Parent:IsA("BasePart") and prParent.Parent.Position)
                    if pPos then return pPos end
                end
            end
        end
    end
    return fallback
end

local function GetHumanLikeFarmStandingSpot(centerPos)
    local farmRadius = 3.8
    local occupiedAngles = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = plr.Character.HumanoidRootPart
            local d = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(centerPos.X, 0, centerPos.Z)).Magnitude
            if d <= 10 then
                local angle = math.atan2(hrp.Position.Z - centerPos.Z, hrp.Position.X - centerPos.X)
                table.insert(occupiedAngles, angle)
            end
        end
    end
    local bestAngle, maxMinDist = nil, -1
    for i = 0, 15 do
        local testAngle = (i / 16) * math.pi * 2
        local minDiff = math.pi
        for _, occAngle in ipairs(occupiedAngles) do
            local diff = math.abs(testAngle - occAngle)
            if diff > math.pi then diff = (math.pi * 2) - diff end
            if diff < minDiff then minDiff = diff end
        end
        if minDiff > maxMinDist then maxMinDist = minDiff bestAngle = testAngle end
    end
    if not bestAngle then bestAngle = math.random() * math.pi * 2 end
    local sx = centerPos.X + math.cos(bestAngle) * farmRadius
    local sz = centerPos.Z + math.sin(bestAngle) * farmRadius
    local gy = GetGroundLevel(sx, sz, centerPos.Y)
    return Vector3.new(sx, gy + 2.2, sz), bestAngle
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
    if hum and hum.Sit then
        hum.Sit = false
        pcall(function()
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            if hum.SeatPart then hum.SeatPart = nil end
        end)
        task.wait(0.2)
    end
    local standPos = GetHumanLikeFarmStandingSpot(exactCenter)
    if root then
        local fg = GetGroundLevel(standPos.X, standPos.Z, exactCenter.Y)
        root.CFrame = CFrame.lookAt(
            Vector3.new(standPos.X, fg + 2.5, standPos.Z),
            Vector3.new(exactCenter.X, fg + 2.5, exactCenter.Z)
        )
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end
    task.wait(0.2)
    local tW = os.clock()
    while os.clock() - tW < 4.0 do
        TriggerFarmPromptDirectly(cropName)
        task.wait(0.5)
        local af = PlayerGui:FindFirstChild("Auto Farm") or PlayerGui:FindFirstChild("AutoFarm")
        if af and af.Enabled then break end
        if GetPlayerInventoryCount(cropName) > curCount then break end
    end
    local farmTO = os.clock()
    while curCount < targetAmount do
        if isAutoEatAndDrinkEnabled and not isConsumingItem then
            local h = GetPlayerHunger()
            local e = GetPlayerEnergy()
            if (h and h <= 75) or (e and e <= 75) then
                CancelGameFarm()
                task.wait(0.3)
                if h and h <= 75 then CheckAndAutoEat() end
                if e and e <= 75 then CheckAndAutoDrinkCoffee() end
                task.wait(0.3)
                TriggerFarmPromptDirectly(cropName)
                task.wait(1.2)
                farmTO = os.clock()
            end
        end
        if check and not check() then break end
        if os.clock() - farmTO > 180 then break end
        GrantAntiXGrace(15)
        local nc = GetPlayerInventoryCount(cropName)
        if nc > curCount then
            curCount = nc
            farmTO = os.clock()
        elseif (os.clock() - farmTO > 15) and (nc == curCount) then
            TriggerFarmPromptDirectly(cropName)
            farmTO = os.clock()
        end
        task.wait(0.5)
    end
    task.wait(0.5)
    local tb = (locData and locData.Booth) or GetNearestCarBooth(root.Position)
    if tb then
        SmoothWalkTo(tb, 45, check, 5.5)
        task.wait(0.3)
    end
    local car = SpawnCarAtBooth(tb) or EnsureCarAvailable(tb)
    if car then EnsurePlayerSeatedInCar(car) end
    task.wait(0.3)
end

-- =====================================
-- CRAFT SYSTEM
-- =====================================
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
    pcall(function()
        local procGui = PlayerGui:FindFirstChild("Process")
        if procGui and procGui:FindFirstChild("Group") then procGui.Group.Visible = false end
        local ecoGui = PlayerGui:FindFirstChild("Economy")
        if ecoGui and ecoGui:FindFirstChild("Group") then ecoGui.Group.Visible = false end
    end)
    local cPrompt = GetCraft3Prompt()
    local exactCraftPos = nil
    if cPrompt then
        local pParent = cPrompt.Parent
        exactCraftPos = (pParent:IsA("BasePart") and pParent.Position)
                     or (pParent:IsA("Attachment") and pParent.WorldPosition)
                     or (pParent.Parent and pParent.Parent:IsA("BasePart") and pParent.Parent.Position)
    end
    if not exactCraftPos then
        local craftSys = workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Crafting")
        local c3 = craftSys and craftSys:FindFirstChild("Craft_3")
        if c3 then
            local anyPart = c3:FindFirstChildWhichIsA("BasePart", true)
            if anyPart then exactCraftPos = anyPart.Position end
        end
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
    if not cg or not cg:FindFirstChild("Group") or not cg.Group.Visible then
        pcall(function()
            if cg and cg:FindFirstChild("Group") then
                cg.Group.Visible = true
                cg.Group.GroupTransparency = 0
            end
        end)
    end
    task.wait(0.2)
    
    local function GetMaxCraftAmount()
        local b = GetPlayerInventoryCount("Bread")
        local c = GetPlayerInventoryCount("Catchup")
        local p = GetPlayerInventoryCount("Pig")
        local m = GetPlayerInventoryCount("Mango")
        local r = GetPlayerInventoryCount("Rice")
        
        if recipeName == "Sandwish" then
            return math.min(math.floor(b / 3), math.floor(c / 2), math.floor(p / 2))
        elseif recipeName == "MangoRice" then
            return math.min(math.floor(m / 2), math.floor(r / 3))
        elseif recipeName == "RiceKapaoMoo" then
            return math.min(math.floor(r / 3), math.floor(p / 2))
        elseif recipeName == "KangSom" then
            local t = GetPlayerInventoryCount("Tomato")
            local cr = GetPlayerInventoryCount("Crab")
            return math.min(math.floor(t / 2), math.floor(cr / 2))
        end
        return 1
    end
    
    local toCraft = GetMaxCraftAmount()
    if toCraft <= 0 then
        pcall(function()
            if cg and cg:FindFirstChild("Group") then cg.Group.Visible = false end
        end)
        local myCar2 = GetNearbyPlayerVehicle(80) or EnsureCarAvailable(TOWN_CAR_SPAWN)
        if myCar2 then EnsurePlayerSeatedInCar(myCar2) end
        return
    end
    local mainFrame = cg and cg:FindFirstChild("Group") and cg.Group:FindFirstChild("Main")
    
    if mainFrame then
        local scroller = mainFrame:FindFirstChild("Left_Tab") and mainFrame.Left_Tab:FindFirstChild("ScrollingFrame")
        if scroller then
            local sandCatBtn = scroller:FindFirstChild("Sand") or scroller:FindFirstChild("Food") or scroller:FindFirstChild("อาหาร")
            if sandCatBtn then
                SafeClickGuiButton(sandCatBtn)
                task.wait(0.3)
            end
            
            local cleanName = recipeName:gsub("%s+", ""):lower()
            local recipeBtn = nil
            
            for _, ch in ipairs(scroller:GetChildren()) do
                local childName = ch.Name:gsub("%s+", ""):lower()
                if childName == cleanName or childName:find(cleanName) then
                    recipeBtn = ch
                    break
                end
            end
            
            if recipeBtn then
                local clickTarget = (recipeBtn:IsA("GuiButton") and recipeBtn) or recipeBtn:FindFirstChildWhichIsA("GuiButton", true) or recipeBtn
                if clickTarget and clickTarget:IsA("GuiButton") then SafeClickGuiButton(clickTarget) end
                task.wait(0.3)
            end
        end
        
        local amtBox = mainFrame:FindFirstChild("Function") and mainFrame.Function:FindFirstChild("Amount") and mainFrame.Function.Amount:FindFirstChild("Amount")
        if amtBox and amtBox:IsA("TextBox") then
            amtBox.Text = tostring(toCraft)
            task.wait(0.1)
        end
        
        local craftBtn = mainFrame:FindFirstChild("Button") and mainFrame.Button:FindFirstChild("Craft")
        if not craftBtn then
            for _, b in ipairs(mainFrame:GetDescendants()) do
                if b:IsA("GuiButton") and (b.Name:lower():find("craft") or (b:IsA("TextButton") and b.Text:lower():find("craft"))) then
                    craftBtn = b
                    break
                end
            end
        end
        if craftBtn and craftBtn:IsA("GuiButton") then
            SafeClickGuiButton(craftBtn)
            task.wait(0.3)
        end
    end
    
    pcall(function()
        local remCore = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes")
        if remCore then
            local Remotes_m = require(remCore)
            Remotes_m.Fire("_crafting", "Request", "Craft_3", recipeName, toCraft, false)
        else
            local rem = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Remotes")
            if rem and rem:FindFirstChild("_crafting") then
                rem._crafting:FireServer("Request", "Craft_3", recipeName, toCraft, false)
            end
        end
    end)
    
    local tStart = os.clock()
    while (os.clock() - tStart < 10.0) do
        if shouldContinueCheck and not shouldContinueCheck() then break end
        GrantAntiXGrace(15)
        task.wait(0.5)
    end
    task.wait(0.2)
    
    pcall(function()
        local remCore = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes")
        if remCore then
            local Remotes_m = require(remCore)
            Remotes_m.Fire("_crafting", "Complete", "Craft_3", recipeName, toCraft, false)
        else
            local rem = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Remotes")
            if rem and rem:FindFirstChild("_crafting") then
                rem._crafting:FireServer("Complete", "Craft_3", recipeName, toCraft, false)
            end
        end
    end)
    task.wait(0.3)
    pcall(function()
        if mainFrame and mainFrame:FindFirstChild("Exit") then
            if firesignal then firesignal(mainFrame.Exit.MouseButton1Click) end
        end
        if cg and cg:FindFirstChild("Group") then cg.Group.Visible = false end
    end)
    task.wait(0.2)
    task.wait(3.0)
    local myCar3 = GetNearbyPlayerVehicle(80) or EnsureCarAvailable(TOWN_CAR_SPAWN)
    if myCar3 then EnsurePlayerSeatedInCar(myCar3) end
    task.wait(0.3)
end

-- =====================================
-- PROCESS BANANA (เหมือนต้นฉบับ 100% + เปลี่ยน Fluent -> UI)
-- =====================================
ProcessBananaAtStation = function(shouldContinueCheck)
    local foodData = TYPER_LOCATIONS.Food
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end

    -- ตรวจสอบและขึ้นรถเสมอเพื่อขับไปที่แปรรูปกล้วย
    local myCar = GetPlayerVehicle()
    if not myCar or not hum.Sit then
        myCar = EnsureCarAvailable()
    end
    if myCar then
        EnsurePlayerSeatedInCar(myCar)
    end

    local pBan = workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Process") and workspace.Systems.Process:FindFirstChild("Banana")
    local pPrompt = pBan and pBan:FindFirstChild("Prompt")
    local bPos = nil
    if pPrompt then
        bPos = (pPrompt:IsA("Attachment") and pPrompt.WorldPosition) or (pPrompt:IsA("BasePart") and pPrompt.Position) or (pPrompt:FindFirstChildWhichIsA("BasePart") and pPrompt:FindFirstChildWhichIsA("BasePart").Position)
    end
    if not bPos and pBan then
        local anyPart = pBan:FindFirstChildWhichIsA("BasePart", true)
        if anyPart then bPos = anyPart.Position end
    end
    local exactBanPos = bPos or foodData.BananaProcess

    DriveCarTo(exactBanPos + Vector3.new(0, 0, 5.0), shouldContinueCheck)
    task.wait(0.1)
    if shouldContinueCheck and not shouldContinueCheck() then return end

    if hum.Sit then
        hum.Sit = false
        task.wait(0.1)
    end

    local standPos = exactBanPos + Vector3.new(0, 0, 2.5)
    local groundY = GetGroundLevel(standPos.X, standPos.Z, standPos.Y)
    root.CFrame = CFrame.lookAt(Vector3.new(standPos.X, groundY + 3.0, standPos.Z), exactBanPos)
    task.wait(0.1)

    local procPrompt = pBan and pBan:FindFirstChildWhichIsA("ProximityPrompt", true)
    if not procPrompt then
        procPrompt = FindPromptNear(root.Position, 15, nil)
    end
    if procPrompt then
        TriggerPrompt(procPrompt)
    end
    task.wait(0.3)

    pcall(function()
        UI:Notify({
            Title = "NEXUS HUB",
            Content = "🍌 กำลังแปรรูปกล้วยเป็น BananaPack อัตโนมัติ...",
            Duration = 3.0
        })
    end)

    local tProc = os.clock()
    while (GetPlayerInventoryCount("Banana") >= 2) and (os.clock() - tProc < 120) do
        if shouldContinueCheck and not shouldContinueCheck() then break end
        GrantAntiXGrace(15)
        task.wait(3.2)
    end

    pcall(function()
        local procGui = PlayerGui:FindFirstChild("Process")
        if procGui and procGui:FindFirstChild("Group") then
            local mainFrame = procGui.Group:FindFirstChild("Main")
            if mainFrame and mainFrame:FindFirstChild("Exit") and firesignal then
                firesignal(mainFrame.Exit.MouseButton1Click)
            end
            procGui.Group.Visible = false
        end
    end)
    task.wait(0.2)

    pcall(function()
        UI:Notify({
            Title = "NEXUS HUB",
            Content = "✅ แปรรูปเสร็จเรียบร้อย! รอ 3 วินาทีก่อนขึ้นรถไปขาย...",
            Duration = 3.0
        })
    end)
    task.wait(3.0)

    local myCar = GetNearbyPlayerVehicle(80) or EnsureCarAvailable(TOWN_CAR_SPAWN)
    if myCar then
        EnsurePlayerSeatedInCar(myCar)
    end
    task.wait(0.3)
end

-- =====================================
-- PROCESS ORE SYSTEM
-- =====================================
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
                if pPos then
                    if pPos.Y < lowestY then
                        lowestY = pPos.Y
                        procPrompt = desc
                        targetProcPos = pPos
                    end
                else
                    procPrompt = procPrompt or desc
                end
            end
        end
    end

    if not procPrompt then 
        procPrompt = FindPromptNear(targetProcPos, 25, nil) or FindPromptNear(root.Position, 25, nil) 
    end

    local fy = targetProcPos.Y
    root.CFrame = CFrame.lookAt(Vector3.new(targetProcPos.X, fy+1.2, targetProcPos.Z+2.5), Vector3.new(targetProcPos.X, fy+1.2, targetProcPos.Z))
    root.AssemblyLinearVelocity = Vector3.zero
    task.wait(0.2)

    if procPrompt then 
        TriggerPrompt(procPrompt) 
        task.wait(0.5)
    end

    pcall(function()
        local rc = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes")
        if rc then require(rc).Fire("_process", "Start", oreName) end
    end)

    pcall(function()
        local pg = PlayerGui:FindFirstChild("Process")
        if pg and pg:FindFirstChild("Group") then
            pg.Group.Visible = true
            pg.Group.GroupTransparency = 0
        end
    end)
    task.wait(0.3)

    minP = minP or (oreName == "Svibranium" and 4 or 2)
    local tP = os.clock()
    
    while GetPlayerInventoryCount(oreName) >= minP and (os.clock() - tP < 180) do
        if check and not check() then break end
        GrantAntiXGrace(15)
        
        pcall(function()
            local pg = PlayerGui:FindFirstChild("Process")
            if pg and pg:FindFirstChild("Group") then
                local main = pg.Group:FindFirstChild("Main")
                local ab = main and (main:FindFirstChild("ActionBtn") or main:FindFirstChild("ActionBtn", true))
                if ab and firesignal then 
                    firesignal(ab.MouseButton1Click) 
                end
            end
        end)
        task.wait(3.2)
    end

    pcall(function()
        local rc = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes")
        if rc then require(rc).Fire("_process", "Stop", oreName) end
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
    
    task.wait(3.0)

    local c2 = GetNearbyPlayerVehicle(80) or EnsureCarAvailable(Vector3.new(-876.62, 10.52, 6662.98))
    if c2 then EnsurePlayerSeatedInCar(c2) end
end

-- =====================================
-- VAULT SYSTEM
-- =====================================
local DEPOSITABLE_ITEMS = {
    Rock=true, Svibranium=true, Bread=true, Catchup=true, Pig=true,
    Mango=true, Rice=true, Tomato=true, Banana=true, Crab=true,
    Coconut=true, Corn=true, Egg=true, Milk=true, Sugarcane=true,
    Sandwich=true, MangoRice=true, BananaPack=true, KangSom=true,
    Sushi=true, RiceKapaoMoo=true, Burger=true, Ramen=true, Onigiri=true,
    Watermelon=true, Curry=true, Water=true, HotCocoa=true, Coffee=true,
    Bettafish=true, Anglerfish=true, FishingBait=true, Bait=true,
    FishingRod=true, FishingRodV2=true, FishingRodV3=true,
}

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
                    if c > 0 then
                        pcall(function() R.Invoke("_vault_tx", "Deposit", attr, c) end)
                        task.wait(0.1)
                    end
                end
            end
        end
    end
    for s = 10, 1, -1 do
        if check and not check() then break end
        task.wait(1.0)
    end
    pcall(function()
        local vg = PlayerGui:FindFirstChild("Safe Vault") or PlayerGui:FindFirstChild("SafeVault") or PlayerGui:FindFirstChild("Vault")
        if vg and vg:FindFirstChild("Group") then
            local main = vg.Group:FindFirstChild("Main")
            local cb = main and (main:FindFirstChild("Exit") or main:FindFirstChild("Close"))
            if cb then SafeClickGuiButton(cb) end
            vg.Group.Visible = false
        end
    end)
    task.wait(0.3)
    local c2 = GetNearbyPlayerVehicle(80) or myCar or GetPlayerVehicle()
    if c2 then EnsurePlayerSeatedInCar(c2) end
end

-- =====================================
-- MARKET SELL SYSTEM (ซิงค์ตามเกมแท้ 100%)
-- =====================================
local function GetEconomyMarketPosition()
    local systems = workspace:FindFirstChild("Systems")
    local containers = systems and {systems, workspace} or {workspace}
    for _, container in ipairs(containers) do
        for _, p in ipairs(container:GetDescendants()) do
            if p:IsA("ProximityPrompt") and p.Enabled then
                local act = (p.ActionText or ""):lower()
                local obj = (p.ObjectText or ""):lower()
                local pn = p.Name:lower()
                local parn = p.Parent and p.Parent.Name:lower() or ""
                if act:find("econ") or obj:find("econ") or pn:find("econ") or parn:find("econ") then
                    local par = p.Parent
                    local pp = (par:IsA("Attachment") and par.WorldPosition) or (par:IsA("BasePart") and par.Position) or (par.Parent and par.Parent:IsA("BasePart") and par.Parent.Position)
                    if pp then return pp, p end
                end
            end
        end
    end
    local ecoModel = (workspace:FindFirstChild("Systems") and (workspace.Systems:FindFirstChild("Economy") or workspace.Systems:FindFirstChild("Ecconomy"))) or workspace:FindFirstChild("Economy") or workspace:FindFirstChild("Ecconomy")
    if ecoModel then
        local p = ecoModel:FindFirstChildWhichIsA("ProximityPrompt", true)
        if p then
            local par = p.Parent
            local pp = (par:IsA("Attachment") and par.WorldPosition) or (par:IsA("BasePart") and par.Position)
            if pp then return pp, p end
        end
        local part = ecoModel:FindFirstChildWhichIsA("BasePart", true)
        if part then return part.Position, nil end
    end
    local tx, tz = -462.0, 5324.7
    local ty = GetGroundLevel(tx, tz, 17.5)
    return Vector3.new(tx, ty+1.2, tz), nil
end

SellAtEconomyMarket = function(check)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end
    local marketPos, directPrompt = GetEconomyMarketPosition()
    marketPos = marketPos or TYPER_LOCATIONS.Economy.Market
    local myCar = GetPlayerVehicle()
    if not myCar or not (hum and hum.Sit) then
        if not myCar then myCar = EnsureCarAvailable(TOWN_CAR_SPAWN) end
        if myCar then EnsurePlayerSeatedInCar(myCar) end
    end
    if not myCar then myCar = EnsureCarAvailable(TOWN_CAR_SPAWN) end
    if myCar then EnsurePlayerSeatedInCar(myCar) end
    DriveCarTo(marketPos, check)
    task.wait(0.3)
    if check and not check() then return end
    ExitCarNaturally(myCar)
    local fp, pFound = GetEconomyMarketPosition()
    local tp = fp or marketPos
    if root then
        local gy = GetGroundLevel(tp.X, tp.Z, tp.Y)
        root.CFrame = CFrame.lookAt(Vector3.new(tp.X+2.5, gy+2.2, tp.Z), tp)
        root.AssemblyLinearVelocity = Vector3.zero
    end
    task.wait(0.2)
    local ep = pFound or directPrompt or FindPromptNear(root.Position, 25, "econ") or FindPromptNear(tp, 25)
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
    pcall(function()
        local eg = PlayerGui:FindFirstChild("Economy") or PlayerGui:FindFirstChild("Ecconomy")
        if eg and eg:FindFirstChild("Group") then
            local main = eg.Group:FindFirstChild("Main") or eg.Group
            local sellBtn = main:FindFirstChild("Sell_All", true) 
                         or main:FindFirstChild("SellAll", true) 
                         or main:FindFirstChild("Sell", true)
            if not sellBtn then
                for _, b in ipairs(main:GetDescendants()) do
                    if b:IsA("GuiButton") and (b.Name:lower():find("sell") or (b:IsA("TextButton") and b.Text:lower():find("sell"))) then
                        sellBtn = b
                        break
                    end
                end
            end
            if sellBtn and sellBtn:IsA("GuiButton") then SafeClickGuiButton(sellBtn) end
        end
    end)
    task.wait(1.0)
    pcall(function()
        local eg = PlayerGui:FindFirstChild("Economy") or PlayerGui:FindFirstChild("Ecconomy")
        if eg and eg:FindFirstChild("Group") then
            local main = eg.Group:FindFirstChild("Main")
            local eb = main and (main:FindFirstChild("Exit", true) or main:FindFirstChild("Close", true))
            if eb and eb:IsA("GuiButton") then SafeClickGuiButton(eb) end
            eg.Group.Visible = false
        end
    end)
    if isAutoEatAndDrinkEnabled then
        local h = GetPlayerHunger()
        local e = GetPlayerEnergy()
        if (h and h <= 75) or (e and e <= 75) then AutoEatThenDrink(95) end
    end
    local c2 = GetNearbyPlayerVehicle(80) or EnsureCarAvailable(TOWN_CAR_SPAWN)
    if c2 then PressFToEnterCar(c2) end
    task.wait(0.2)
end

-- =====================================
-- FISHING SYSTEM
-- =====================================
local function GetFishingRodTool()
    local char = LocalPlayer.Character
    local bp = LocalPlayer:FindFirstChild("Backpack")
    local names = {"FishingRodV3","FishingRodV2","FishingRod"}
    if char then
        for _, n in ipairs(names) do
            local t = char:FindFirstChild(n)
            if t and t:IsA("Tool") then return t end
        end
    end
    if bp then
        for _, n in ipairs(names) do
            local t = bp:FindFirstChild(n)
            if t and t:IsA("Tool") then return t end
        end
    end
end

local function EquipFishingRod()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if not char or not hum then return nil end
    local rod = GetFishingRodTool()
    if rod and rod.Parent == char then return rod end
    if rod and rod.Parent == bp then
        hum:EquipTool(rod)
        task.wait(0.3)
        return rod
    end
    pcall(function()
        local rc = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes")
        if rc then require(rc).Fire("_inventory", "Use", "FishingRod") end
    end)
    task.wait(0.4)
    rod = GetFishingRodTool()
    if rod and rod.Parent == bp then
        hum:EquipTool(rod)
        task.wait(0.2)
    end
    return rod
end

local function IsFishingLineCast()
    local camF = workspace.Camera:FindFirstChild("FishingLocal")
    if camF and #camF:GetChildren() > 0 then return true end
    local pgui = LocalPlayer:FindFirstChild("PlayerGui")
    if pgui and pgui:FindFirstChild("FishingGame") then return true end
    return false
end

local function EnsureFishingPlatform(pos)
    if not fishingPlatform or not fishingPlatform.Parent then
        local p = Instance.new("Part")
        p.Name = "TyperTown_FishingSafePlatform"
        p.Size = Vector3.new(20, 2, 20)
        p.CFrame = CFrame.new(pos.X, pos.Y - 2.8, pos.Z)
        p.Anchored = true
        p.CanCollide = true
        p.Transparency = 1
        p.Parent = workspace
        fishingPlatform = p
    else
        fishingPlatform.CFrame = CFrame.new(pos.X, pos.Y - 2.8, pos.Z)
    end
end

local function BuyBaitMaxAtShop(shopPos)
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root or not hum then return end

    if hum.Sit then
        hum.Sit = false
        task.wait(0.2)
    end
    
    local safeStandPos = shopPos + Vector3.new(0, 2.5, 4) 
    root.CFrame = CFrame.lookAt(safeStandPos, shopPos)
    root.AssemblyLinearVelocity = Vector3.zero
    task.wait(0.5)

    local prompt = FindPromptNear(shopPos, 20, "shop") or FindPromptNear(root.Position, 20, nil)
    if prompt then
        prompt.Enabled = true
        pcall(function() prompt:InputHoldBegin() end)
        task.wait(0.2)
        pcall(function() prompt:InputHoldEnd() end)
    end

    local pgui = LocalPlayer:FindFirstChild("PlayerGui")
    local shopGui = nil
    local tWait = os.clock()
    while os.clock() - tWait < 3.0 do
        shopGui = pgui:FindFirstChild("Shop")
        if shopGui and shopGui:FindFirstChild("Group") and shopGui.Group.Visible then
            break
        end
        if prompt then
            pcall(function() fireproximityprompt(prompt) end)
        end
        task.wait(0.2)
    end

    local pData = LocalPlayer:FindFirstChild("PlayerData")
    local money = (pData and pData:GetAttribute("Money")) or 1000
    local toBuy = math.clamp(math.floor(money / 10), 10, 100) 

    pcall(function()
        local remCore = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes")
        if remCore then
            local Remotes_m = require(remCore)
            Remotes_m.Fire("_shop", "Buy", { FishingBait = toBuy }, "Money")
            Remotes_m.Fire("_shop", "Buy", { Bait = toBuy }, "Money")
        end
    end)
    task.wait(0.5)

    pcall(function()
        if shopGui and shopGui:FindFirstChild("Group") and shopGui.Group:FindFirstChild("Main") then
            local main = shopGui.Group.Main
            local sf = main:FindFirstChild("ScrollingFrame")
            
            local baitBtn = sf and (sf:FindFirstChild("FishingBait") or sf:FindFirstChild("Bait"))
            if not baitBtn and sf then
                for _, b in ipairs(sf:GetDescendants()) do
                    if b:IsA("GuiButton") and (b.Name:lower():find("bait") or b.Name:lower():find("worm")) then
                        baitBtn = b
                        break
                    end
                end
            end
            
            local payBtn = main:FindFirstChild("Pay") and main.Pay:FindFirstChild("Money")
            
            if baitBtn and payBtn then
                SafeClickGuiButton(baitBtn)
                task.wait(0.2)
                SafeClickGuiButton(payBtn)
                task.wait(0.3)
            end
            
            local closeBtn = main:FindFirstChild("Closed") or main:FindFirstChild("Close")
            if closeBtn then SafeClickGuiButton(closeBtn) end
            shopGui.Group.Visible = false
        end
    end)
    task.wait(0.4)
end

local function SellAllFishAtShop(shopPos)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local prompt = FindPromptNear(shopPos, 20, "sell") or FindPromptNear(shopPos, 20, "economy") or FindPromptNear(root.Position, 20, nil)
    if prompt then
        prompt.Enabled = true
        pcall(function() prompt:InputHoldBegin() end)
        task.wait(0.2)
        pcall(function() prompt:InputHoldEnd() end)
        task.wait(0.3)
    end
    pcall(function()
        local rc = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes")
        if rc then
            local R = require(rc)
            R.Fire("_economy", "SellAll")
            R.Fire("_economy", "Sell", "Anglerfish", 999)
            R.Fire("_economy", "Sell", "Bettafish", 999)
        end
    end)
    task.wait(0.4)
    pcall(function()
        local pgui = LocalPlayer:FindFirstChild("PlayerGui")
        local econ = pgui and pgui:FindFirstChild("Economy")
        if econ and econ:FindFirstChild("Group") and econ.Group:FindFirstChild("Main") then
            local sellAllBtn = econ.Group.Main:FindFirstChild("Sell_All")
            if sellAllBtn then
                SafeClickGuiButton(sellAllBtn)
                task.wait(0.2)
            end
            local closeBtn = econ.Group.Main:FindFirstChild("Closed") or econ.Group.Main:FindFirstChild("Close")
            if closeBtn then SafeClickGuiButton(closeBtn) end
            econ.Group.Visible = false
        end
    end)
    task.wait(0.3)
end

local function SolveFishingMinigame()
    local pgui = LocalPlayer:FindFirstChild("PlayerGui")
    local vim = VirtualInputManager
    local fg = pgui and pgui:FindFirstChild("FishingGame")
    if not fg or not fg.Parent then return false end
    local mg = fg:FindFirstChild("Minigame")
    if not mg then return false end
    local isHolding = false
    local startTime = os.clock()
    local conn = nil
    conn = RunService.RenderStepped:Connect(function()
        if not isAutoFishingEnabled or not fg or not fg.Parent then
            if isHolding then
                pcall(function() vim:SendKeyEvent(false, Enum.KeyCode.Space, false, game) end)
                isHolding = false
            end
            if conn then conn:Disconnect() conn = nil end
            return
        end
        local fish = mg:FindFirstChild("Fish")
        local gameF = mg:FindFirstChild("Game")
        local point = gameF and gameF:FindFirstChild("Point")
        if fish and point then
            local fishCenter = fish.AbsolutePosition.Y + (fish.AbsoluteSize.Y * 0.5)
            local pointCenter = point.AbsolutePosition.Y + (point.AbsoluteSize.Y * 0.5)
            if fishCenter < pointCenter - 4 then
                if not isHolding then
                    isHolding = true
                    pcall(function() vim:SendKeyEvent(true, Enum.KeyCode.Space, false, game) end)
                end
            elseif fishCenter > pointCenter + 4 then
                if isHolding then
                    isHolding = false
                    pcall(function() vim:SendKeyEvent(false, Enum.KeyCode.Space, false, game) end)
                end
            end
        end
    end)
    while fg and fg.Parent and isAutoFishingEnabled and (os.clock() - startTime < 30) do
        task.wait(0.05)
        fg = pgui:FindFirstChild("FishingGame")
    end
    if conn then conn:Disconnect() conn = nil end
    if isHolding then
        pcall(function() vim:SendKeyEvent(false, Enum.KeyCode.Space, false, game) end)
        isHolding = false
    end
    task.wait(3.0)
    return true
end

pcall(function()
    local pgui = LocalPlayer:FindFirstChild("PlayerGui")
    if pgui then
        pgui.ChildAdded:Connect(function(child)
            if child.Name == "FishingGame" and isAutoFishingEnabled then
                task.spawn(SolveFishingMinigame)
            end
        end)
    end
end)

StartAutoFishing = function()
    if fishingThread then return end
    isAutoFishingEnabled = true
    fishingThread = task.spawn(function()
        local isFirstRun = true
        while isAutoFishingEnabled do
            if isFirstRun then
                WarpToTownAndSpawnCar()
                isFirstRun = false
            end
            if not isAutoFishingEnabled then break end
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local pData = LocalPlayer:FindFirstChild("PlayerData")
            if root and hum and hum.Health > 0 then
                local bait = (pData and (pData:GetAttribute("FishingBait") or pData:GetAttribute("Bait"))) or 0
                local betta = (pData and pData:GetAttribute("Bettafish")) or 0
                local angler = (pData and pData:GetAttribute("Anglerfish")) or 0
                local fishCount = betta + angler
                if bait <= 0 or fishCount >= 25 then
                    if IsFishingLineCast() then
                        pcall(function()
                            local r = char:FindFirstChild("FishingRod")
                            if r then r:Activate() end
                        end)
                        task.wait(0.4)
                    end
                    local distToParking = (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(FISHING_PARKING_POS.X, 0, FISHING_PARKING_POS.Z)).Magnitude
                    if distToParking > 8.0 and distToParking < 150.0 then
                        SmoothWalkTo(FISHING_PARKING_POS, 25, function() return isAutoFishingEnabled end, 4.0)
                        task.wait(0.2)
                    end
                    local myCar = GetNearbyPlayerVehicle(80) or EnsureCarAvailable(TOWN_CAR_SPAWN)
                    if myCar then
                        EnsurePlayerSeatedInCar(myCar)
                        DriveCarTo(BAIT_SHOP_POS, function() return isAutoFishingEnabled end)
                        ExitCarNaturally(myCar)
                        task.wait(0.3)
                    end
                    SellAllFishAtShop(BAIT_SHOP_POS)
                    task.wait(0.5)
                    BuyBaitMaxAtShop(BAIT_SHOP_POS)
                    task.wait(0.5)
                    myCar = GetNearbyPlayerVehicle(80) or EnsureCarAvailable(TOWN_CAR_SPAWN)
                    if myCar then
                        EnsurePlayerSeatedInCar(myCar)
                        DriveCarTo(FISHING_PARKING_POS, function() return isAutoFishingEnabled end)
                        ExitCarNaturally(myCar)
                        task.wait(0.4)
                    end
                end
                if not isAutoFishingEnabled then break end
                local distToParking = (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(FISHING_PARKING_POS.X, 0, FISHING_PARKING_POS.Z)).Magnitude
                local distToFish = (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(FISHING_SPOT.X, 0, FISHING_SPOT.Z)).Magnitude
                if distToParking > 15.0 and distToFish > 15.0 then
                    local myCar = GetNearbyPlayerVehicle(80) or EnsureCarAvailable(TOWN_CAR_SPAWN)
                    if myCar then
                        EnsurePlayerSeatedInCar(myCar)
                        DriveCarTo(FISHING_PARKING_POS, function() return isAutoFishingEnabled end)
                        ExitCarNaturally(myCar)
                        task.wait(0.4)
                    end
                end
                if not isAutoFishingEnabled then break end
                char = LocalPlayer.Character
                root = char and char:FindFirstChild("HumanoidRootPart")
                distToFish = root and (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(FISHING_SPOT.X, 0, FISHING_SPOT.Z)).Magnitude or 9999
                if distToFish > 3.0 then
                    SmoothWalkTo(FISHING_SPOT, 25, function() return isAutoFishingEnabled end, 2.5)
                    task.wait(0.2)
                end
                if not isAutoFishingEnabled then break end
                EnsureFishingPlatform(FISHING_SPOT)
                GrantAntiXGrace(20)
                if not IsFishingLineCast() and isAutoEatAndDrinkEnabled then
                    local h = GetPlayerHunger()
                    local e = GetPlayerEnergy()
                    if (h and h <= 75) or (e and e <= 75) then
                        AutoEatThenDrink(95)
                    end
                end
                local rod = char:FindFirstChild("FishingRod")
                if not rod then
                    rod = EquipFishingRod()
                    if not rod then
                        pcall(function()
                            local rc = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes")
                            if rc then require(rc).Fire("_shop", "Buy", { FishingRod = 1 }, "Money") end
                        end)
                        task.wait(0.8)
                        rod = EquipFishingRod()
                    end
                end
                if rod and rod.Parent == char then
                    if not IsFishingLineCast() then
                        root.CFrame = CFrame.lookAt(FISHING_SPOT, FISHING_LOOK_TARGET)
                        root.AssemblyLinearVelocity = Vector3.zero
                        root.AssemblyAngularVelocity = Vector3.zero
                        task.wait(0.2)
                        pcall(function() rod:Activate() end)
                        task.wait(1.0)
                    end
                    local pgui = LocalPlayer:FindFirstChild("PlayerGui")
                    local fg = pgui and pgui:FindFirstChild("FishingGame")
                    if fg and fg:FindFirstChild("Minigame") then
                        SolveFishingMinigame()
                        task.wait(3.0)
                    else
                        task.wait(0.2)
                    end
                else
                    task.wait(0.5)
                end
            end
            task.wait(0.2)
        end
        if fishingPlatform and fishingPlatform.Parent then
            fishingPlatform:Destroy()
            fishingPlatform = nil
        end
        fishingThread = nil
    end)
end

StopAutoFishing = function()
    isAutoFishingEnabled = false
    if fishingPlatform and fishingPlatform.Parent then
        fishingPlatform:Destroy()
        fishingPlatform = nil
    end
    fishingThread = nil
    pcall(function()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum:UnequipTools() end
    end)
end

-- =====================================
-- REAL-TIME ECONOMY SYNC (อัปเดตตาม Decompiled Script แท้)
-- =====================================
pcall(function()
    local modules = ReplicatedStorage:WaitForChild("Systems"):WaitForChild("Modules")
    local remotes = require(modules:WaitForChild("Core"):WaitForChild("Remotes"))
    
    remotes.On("_economy", function(p1, p2, p3, p4)
        if p3 then
            _G.EconomyTimer = p3
        end
        if (p1 == "Update" or p1 == "Open") and type(p2) == "table" then
            for itemName, price in pairs(p2) do
                if type(price) == "number" then 
                    RealTimePrices[itemName] = price 
                end
            end
        end
    end)
    
    task.spawn(function()
        while true do
            task.wait(3)
            pcall(function() remotes.Fire("_economy", "Request") end)
        end
    end)
end)

getgenv().VisitedTyperServers = getgenv().VisitedTyperServers or {}
pcall(function()
    local now = os.clock()
    for sid, t in pairs(getgenv().VisitedTyperServers) do
        if type(t) == "number" and (now - t > 1800) then getgenv().VisitedTyperServers[sid] = nil end
    end
end)

local function IsInMainGame()
    if tostring(game.PlaceId) == "119554426329370" then
        local pgui = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
        if pgui then
            if pgui:FindFirstChild("serverlistUI") or pgui:FindFirstChild("ServerList") or pgui:FindFirstChild("Server_List") or pgui:FindFirstChild("ServerSelect") then return false end
        end
        return true
    end
    return false
end

local function IsServerSelectionScreen() return not IsInMainGame() end

local function ExitToServerSelectionScreen(reason)
    if isHopping then return end
    isHopping = true
    pcall(function()
        local qot = queue_on_teleport or (syn and syn.queue_on_teleport)
        if qot and getgenv().NexusLoaderCode then qot(getgenv().NexusLoaderCode) end
    end)
    task.wait(0.3)
    pcall(function() game:GetService("TeleportService"):Teleport(73746968849439, LocalPlayer) end)
    task.delay(6.0, function() isHopping = false end)
end

task.spawn(function()
    task.wait(6.0)
    while true do
        task.wait(0.5)
        if IsInMainGame() and isAutoHopOnPlayerNearbyEnabled and not isHopping then
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then
                local myPos = root.Position
                for _, pl in ipairs(Players:GetPlayers()) do
                    if pl ~= LocalPlayer and pl.Character then
                        local orr = pl.Character:FindFirstChild("HumanoidRootPart")
                        local oh = pl.Character:FindFirstChildOfClass("Humanoid")
                        if orr and oh and oh.Health > 0 then
                            local d = (orr.Position - myPos).Magnitude
                            if d <= autoHopDistance then
                                ExitToServerSelectionScreen("ตรวจพบผู้เล่นใกล้เคียง")
                                break
                            end
                        end
                    end
                end
            end
        end
    end
end)

local MarvenState = {
    AutoEat = true, AutoFarmItem = false, AutoProcessFarm = false, AutoMineFarm = false, AutoFish = false, InfiniteStamina = false, InfiniteHunger = false
}
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
    Version = "Premium + Nexus Engine (Ultimate Master 100%) [v2.5]",
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
Status:Banner({Title = "MarvenRiz Hub [v2.5]", SubTitle = "🔗 NEXUS Engine + สมบูรณ์แบบ 100% ไม่มีตัดทอน"})
local StatsGrid = Status:StatGrid({
    {Label = "FPS", Value = "0"}, {Label = "Ping", Value = "0 ms"},
    {Label = "Executor", Value = "Unknown"}, {Label = "Players", Value = "0"},
    {Label = "Game", Value = GameName}, {Label = "Time", Value = "00:00:00"}
})

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
                text = "⏳ กำลังรอข้อมูลราคา Real-Time จากเซิร์ฟเวอร์..."
            else
                for item, price in pairs(RealTimePrices) do
                    text = text .. "🔹 " .. tostring(item) .. " : 💰 " .. tostring(price) .. " บาท\n"
                end
            end
            MarketPriceDisplay:Set(text)
        end)
    end
end)

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
                if GetPlayerInventoryCount("Banana") < 60 then HarvestSingleCrop("Banana", 60, check) end
                if not check() then break end
                ProcessBananaAtStation(check)
                if not check() then break end
                SellAtEconomyMarket(check)
            elseif k == "Mango" or k == "RiceKapaoMoo" or k == "Sandwich" or k == "KangSom" then
                CraftFoodAtStation(k, check)
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
            local ore = MarvenSelected.MineFarmType or "Rock"
            local minP = (ore == "Svibranium") and 4 or 2
            if GetPlayerInventoryCount(ore) < 120 then HarvestSingleCrop(ore, 120, check) end
            if not check() then break end
            ProcessOreAtStation(ore, minP, check)
            if not check() then break end
            DepositAllToVault(check)
            task.wait(1.0)
        end
    end)
end

local SettingsTab = Window:Tab({Title = "ตั้งค่า", Icon = "settings"})
local Settings = SettingsTab:Section({Title = "ตั้งค่าทั่วไป"})
Settings:Toggle({
    Title = "ออโต้ กินอาหาร", Default = true, Flag = "AutoEat",
    Callback = function(v) isAutoEatAndDrinkEnabled = v end
})
Settings:Toggle({
    Title = "พลังงานไม่จำกัด", Default = true, Flag = "InfiniteStamina",
    Callback = function(v)
        if _G._MarvenStaminaConn then _G._MarvenStaminaConn:Disconnect() _G._MarvenStaminaConn = nil end
        if v then
            _G._MarvenStaminaConn = RunService.Heartbeat:Connect(function()
                pcall(function() LocalPlayer.PlayerData:SetAttribute("Stamina", 100) end)
            end)
        end
    end
})
Settings:Toggle({
    Title = "ไม่หิวอาหาร", Default = false, Flag = "InfiniteHunger",
    Callback = function(v)
        if _G._MarvenHungerConn then _G._MarvenHungerConn:Disconnect() _G._MarvenHungerConn = nil end
        if v then
            _G._MarvenHungerConn = RunService.Heartbeat:Connect(function()
                pcall(function() LocalPlayer.PlayerData:SetAttribute("Hunger", 100) end)
            end)
        end
    end
})

local FarmTab = Window:Tab({Title = "ฟาร์ม", Icon = "sprout"})
local NormalFarm = FarmTab:Section({Title = "ฟาร์มปกติ"})
NormalFarm:Dropdown({
    Title = "เลือกฟาร์ม",
    Options = {"ขนมปัง (วัตถุดิบ)", "ซอสมะเขือเทศ (วัตถุดิบ)", "หมู (วัตถุดิบ)", "มะม่วง (วัตถุดิบ)", "ข้าว (วัตถุดิบ)", "มะเขือเทศ (วัตถุดิบ)", "กล้วย (วัตถุดิบ)", "ปู (วัตถุดิบ)", "มะพร้าว (วัตถุดิบ)", "ข้าวโพด (วัตถุดิบ)", "ไข่ไก่ (วัตถุดิบ)", "นม (วัตถุดิบ)", "อ้อย (วัตถุดิบ)"},
    Default = "ขนมปัง (วัตถุดิบ)", Flag = "NormalFarmType",
    Callback = function(v)
        local map = {["ขนมปัง (วัตถุดิบ)"]="Bread", ["ซอสมะเขือเทศ (วัตถุดิบ)"]="Catchup", ["หมู (วัตถุดิบ)"]="Pig", ["มะม่วง (วัตถุดิบ)"]="Mango", ["ข้าว (วัตถุดิบ)"]="Rice", ["มะเขือเทศ (วัตถุดิบ)"]="Tomato", ["กล้วย (วัตถุดิบ)"]="Banana", ["ปู (วัตถุดิบ)"]="Crab", ["มะพร้าว (วัตถุดิบ)"]="Coconut", ["ข้าวโพด (วัตถุดิบ)"]="Corn", ["ไข่ไก่ (วัตถุดิบ)"]="Egg", ["นม (วัตถุดิบ)"]="Milk", ["อ้อย (วัตถุดิบ)"]="Sugarcane"}
        MarvenSelected.NormalFarmType = map[v] or "Bread"
    end
})
NormalFarm:Toggle({
    Title = "ออโต้ ฟาร์มวัตถุดิบ", Default = false, Flag = "AutoFarmItem",
    Callback = function(v) MarvenState.AutoFarmItem = v if v then RunNormalFarm() else StopSession("AutoFarmItem") end end
})

local ProcessFarm = FarmTab:Section({Title = "ฟาร์มโพสต์ (คราฟต์/แปรรูป)"})
ProcessFarm:Dropdown({
    Title = "เลือกของ",
    Options = {"กล้วยแพ็ค (แปรรูป)", "ข้าวมันมะม่วง (คราฟต์)", "ข้าวกะเพราหมู (คราฟต์)", "แซนวิช (คราฟต์)", "แกงส้ม (คราฟต์)"},
    Default = "กล้วยแพ็ค (แปรรูป)", Flag = "ProcessFarmType",
    Callback = function(v)
        local map = {["กล้วยแพ็ค (แปรรูป)"]="Banana", ["ข้าวมันมะม่วง (คราฟต์)"]="Mango", ["ข้าวกะเพราหมู (คราฟต์)"]="RiceKapaoMoo", ["แซนวิช (คราฟต์)"]="Sandwich", ["แกงส้ม (คราฟต์)"]="KangSom"}
        MarvenSelected.ProcessFarmType = map[v] or "Banana"
    end
})
ProcessFarm:Toggle({
    Title = "ออโต้ ฟาร์มโพสต์", Default = false, Flag = "AutoProcessFarm",
    Callback = function(v) MarvenState.AutoProcessFarm = v if v then RunProcessFarm() else StopSession("AutoProcessFarm") end end
})

local MineFarm = FarmTab:Section({Title = "ฟาร์มเหมือง (ขุด+แปรรูป+ฝาก)"})
MineFarm:Dropdown({
    Title = "เลือกเหมือง",
    Options = {"ฟาร์มหิน (หลอมแร่)", "ฟาร์มไวเบรเนียม (หลอมแร่)"},
    Default = "ฟาร์มหิน (หลอมแร่)", Flag = "MineFarmType",
    Callback = function(v)
        local map = {["ฟาร์มหิน (หลอมแร่)"]="Rock", ["ฟาร์มไวเบรเนียม (หลอมแร่)"]="Svibranium"}
        MarvenSelected.MineFarmType = map[v] or "Rock"
    end
})
MineFarm:Toggle({
    Title = "ออโต้ ฟาร์มเหมือง", Default = false, Flag = "AutoMineFarm",
    Callback = function(v) MarvenState.AutoMineFarm = v if v then RunMineFarm() else StopSession("AutoMineFarm") end end
})

local OtherTab = Window:Tab({Title = "อื่นๆ", Icon = "layers"})
local FishSection = OtherTab:Section({Title = "ระบบตกปลา"})
FishSection:Toggle({
    Title = "เริ่มออโต้ตกปลา", Default = false, Flag = "AutoFish",
    Callback = function(v) MarvenState.AutoFish = v if v then pcall(StartAutoFishing) else pcall(StopAutoFishing) end end
})

local AdvTab = Window:Tab({Title = "ขั้นสูง", Icon = "sliders"})
local SpeedSection = AdvTab:Section({Title = "ความเร็วยานพาหนะ"})
SpeedSection:Slider({
    Title = "ความเร็วขับรถ (Studs/s)", Default = 150, Min = 10, Max = 280, Rounding = 0, Flag = "VehicleSpeed",
    Callback = function(v) VehicleDriveSpeed = math.clamp(math.round(v), 10, 280) end
})
SpeedSection:Toggle({
    Title = "รถทะลุสิ่งกีดขวาง (Vehicle NoClip)", Default = true, Flag = "VehicleNoclip",
    Callback = function(v) isVehicleNoclipEnabled = v end
})

local UnloadSection = AdvTab:Section({Title = "ปิดสคริปต์"})
UnloadSection:Button({
    Title = "ปิดสคริปต์ (Unload)",
    Callback = function()
        MarvenState.AutoFarmItem = false
        MarvenState.AutoProcessFarm = false
        MarvenState.AutoMineFarm = false
        MarvenState.AutoFish = false
        StopSession("AutoFarmItem")
        StopSession("AutoProcessFarm")
        StopSession("AutoMineFarm")
        pcall(StopAutoFishing)
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

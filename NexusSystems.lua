--// NEXUS HUB - Typer Town Systems (Full)
--// ระบบฟาร์ม/รถ/คราฟ/ขาย/ตกปลา/Anti-kick ครบจาก 1.txt
--// ใช้งาน: local Systems = loadstring(...)() แล้วเรียก Systems.XXX()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Systems = {}
local NotifyFn = function() end
local ConfigRef = {}

function Systems.SetNotify(fn) NotifyFn = fn end
function Systems.SetConfig(cfg) ConfigRef = cfg end
local function Notify(msg, ok) pcall(NotifyFn, msg, ok) end

--==================================================
-- Anti-Kick Shield
--==================================================
pcall(function()
    local lp = Players.LocalPlayer
    if hookmetamethod then
        local oldNm
        oldNm = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if (method == "Kick" or method == "kick") and (self == lp or self == Players) then
                warn("[NEXUS] Blocked Kick:", tostring((...)))
                return nil
            end
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

--==================================================
-- Constants
--==================================================
Systems.TOWN_CAR_SPAWN = Vector3.new(-311.83, 17.5, 5490.39)
Systems.VAULT_COORDS = Vector3.new(-1.98, 26.54, 8632.61)
Systems.FISHING_PARKING = Vector3.new(-902.46, 3.41, 2964.32)
Systems.FISHING_SPOT = Vector3.new(-972.12, -0.87, 2926.62)
Systems.FISHING_LOOK = Vector3.new(-0.25, 0, -0.97)
Systems.BAIT_SHOP = Vector3.new(-949.31, 16.57, 4861.12)

Systems.LOCATIONS = {
    Bread = { Booth = Vector3.new(872.19, 15.90, 4682.54), Farm = Vector3.new(828.31, 11.21, 4817.85) },
    Catchup = { Booth = Vector3.new(1763.23, 14.23, 4206.70), Farm = Vector3.new(1803.05, 12.65, 4236.79) },
    Pig = { Booth = Vector3.new(306.01, 30.77, -1558.06), Farm = Vector3.new(268.61, 28.74, -1513.65) },
    Mango = { Booth = Vector3.new(-1855.59, 20.06, 586.40), Farm = Vector3.new(-1862.26, 17.33, 535.43) },
    Rice = { Booth = Vector3.new(-92.11, 11.46, 89.48), Farm = Vector3.new(-128.87, 11.02, 78.51) },
    Tomato = { Booth = Vector3.new(-2294.10, 31.28, -1273.91), Farm = Vector3.new(-2319.61, 27.21, -1229.19) },
    Banana = { Booth = Vector3.new(-1528.59, 30.34, -1253.46), Farm = Vector3.new(-1545.12, 28.80, -1126.87) },
    Crab = { Booth = Vector3.new(1442.30, 30.56, 613.34), Farm = Vector3.new(1400.27, 28.69, 648.22) },
    Coconut = { Booth = Vector3.new(-1296.67, 10.37, 4216.59), Farm = Vector3.new(-1333.68, 10.87, 4376.67) },
    Corn = { Booth = Vector3.new(-164.76, 12.39, 4426.24), Farm = Vector3.new(-264.44, 11.95, 4527.12) },
    Egg = { Booth = Vector3.new(-1680.12, 11.39, 4390.69), Farm = Vector3.new(-1799.30, 10.98, 4492.20) },
    Milk = { Booth = Vector3.new(-903.04, 11.41, 4716.36), Farm = Vector3.new(-998.66, 11.23, 4831.62) },
    Sugarcane = { Booth = Vector3.new(-1805.15, 12.98, 3816.89), Farm = Vector3.new(-1922.31, 13.06, 3962.32) },
    Food = { Crafting = Vector3.new(3442.48, 56.40, 3925.24), BananaProcess = Vector3.new(3429.20, 56.80, 3911.80) },
    Economy = { Market = Vector3.new(-462.0, 18.0, 5324.7) },
}

--==================================================
-- State
--==================================================
local MY_CAR = nil
local isConsuming = false
local isHopping = false
local fishingPlatform = nil
local safeWaterFloor = nil
local vehiclePlatform = nil
local isAutoFishing = false
local lastEatT, lastCoffeeT = 0, 0

local function CFG(key, def)
    return (ConfigRef and ConfigRef[key]) ~= nil and ConfigRef[key] or def
end

--==================================================
-- Helpers
--==================================================
local function GetRoot()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function GetHum()
    local c = LocalPlayer.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end

function Systems.GrantGrace(sec)
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

function Systems.GetGroundLevel(x, z, fallbackY)
    fallbackY = fallbackY or 20
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.IgnoreWater = false
    local filter = {}
    if LocalPlayer.Character then table.insert(filter, LocalPlayer.Character) end
    local veh = (workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Vehicles")) or workspace:FindFirstChild("Vehicles")
    if veh then table.insert(filter, veh) end
    if vehiclePlatform then table.insert(filter, vehiclePlatform) end
    if fishingPlatform then table.insert(filter, fishingPlatform) end
    params.FilterDescendantsInstances = filter
    local r = workspace:Raycast(Vector3.new(x, fallbackY + 150, z), Vector3.new(0, -350, 0), params)
    return r and r.Position.Y or fallbackY
end

function Systems.GetCount(item)
    local pd = LocalPlayer:FindFirstChild("PlayerData")
    if pd then
        local c = pd:GetAttribute(item)
        if typeof(c) == "number" then return c end
    end
    return 0
end

local function GetHunger()
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

local function GetEnergy()
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
Systems.GetHunger = GetHunger
Systems.GetEnergy = GetEnergy

local function FindFood()
    local pd = LocalPlayer:FindFirstChild("PlayerData")
    local itemFolder = LocalPlayer:FindFirstChild("Item")
    local bp = LocalPlayer:FindFirstChild("Backpack")
    local char = LocalPlayer.Character
    local list = { "Sushi", "RiceKapaoMoo", "MangoRice", "Rice", "Sandwish", "Burger", "Bread", "Watermelon", "Curry", "Ramen", "Onigiri" }
    for _, f in ipairs(list) do
        if pd then
            local c = pd:GetAttribute(f)
            if typeof(c) == "number" and c > 0 then return f end
        end
        if itemFolder and itemFolder:FindFirstChild(f) and itemFolder[f].Value > 0 then return f end
        if bp and bp:FindFirstChild(f) then return f end
        if char and char:FindFirstChild(f) then return f end
    end
    if pd then
        for attr, val in pairs(pd:GetAttributes()) do
            if typeof(val) == "number" and val > 0 then
                local lo = attr:lower()
                if lo:find("rice") or lo:find("food") or lo:find("sushi") or lo:find("sandwich") or lo:find("burger") then
                    return attr
                end
            end
        end
    end
    return nil
end

local function FindDrink()
    local pd = LocalPlayer:FindFirstChild("PlayerData")
    local itemFolder = LocalPlayer:FindFirstChild("Item")
    local bp = LocalPlayer:FindFirstChild("Backpack")
    local char = LocalPlayer.Character
    local list = { "HotCocoa", "Coffee", "HotCoffee", "IcedCoffee", "Cocoa", "OrangeJuice", "Water", "Ice", "Drink" }
    for _, d in ipairs(list) do
        if pd then
            local c = pd:GetAttribute(d)
            if typeof(c) == "number" and c > 0 then return d end
        end
        if itemFolder and itemFolder:FindFirstChild(d) and itemFolder[d].Value > 0 then return d end
        if bp and bp:FindFirstChild(d) then return d end
        if char and char:FindFirstChild(d) then return d end
    end
    if pd then
        for attr, val in pairs(pd:GetAttributes()) do
            if typeof(val) == "number" and val > 0 then
                local lo = attr:lower()
                if lo:find("coffee") or lo:find("cocoa") or lo:find("tea") or lo:find("drink") or lo:find("water") then
                    return attr
                end
            end
        end
    end
    return nil
end

local function UseItem(name)
    pcall(function()
        local remCore = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes")
        if remCore then
            local R = require(remCore)
            R.Fire("_inventory", "Use", name)
        else
            local rem = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Remotes")
            if rem and rem:FindFirstChild("_inventory") then rem._inventory:FireServer("Use", name) end
        end
    end)
end
Systems.UseItem = UseItem

local function ConsumeItem(name, waitSec)
    if isConsuming or not name then return end
    isConsuming = true
    pcall(function()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        UseItem(name)
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
Systems.ConsumeItem = ConsumeItem

function Systems.AutoEatDrink(target)
    target = target or 95
    if isConsuming then return end
    for _ = 1, 8 do
        local h, e = GetHunger(), GetEnergy()
        if h >= target and e >= target then break end
        local f, d = FindFood(), FindDrink()
        if f and h < target then
            Notify("🍣 กิน " .. f, true)
            ConsumeItem(f, 6)
            task.wait(0.4)
        end
        if d and e < target then
            Notify("☕ ดื่ม " .. d, true)
            ConsumeItem(d, 6)
            task.wait(0.4)
        end
        task.wait(0.3)
    end
end

function Systems.CheckAutoEat()
    if not CFG("AutoEatDrink", true) or isConsuming then return end
    if GetHunger() <= 75 or GetEnergy() <= 75 then
        Systems.AutoEatDrink(95)
    end
end

--==================================================
-- Walking / Car
--==================================================
function Systems.SmoothWalk(target, timeout, check, stopDist)
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return false end
    timeout = timeout or 50
    stopDist = stopDist or 2.5
    local t0 = os.clock()
    local last, stuck = root.Position, 0
    while (root.Position - target).Magnitude > stopDist and (os.clock() - t0 < timeout) do
        if check and not check() then return false end
        Systems.GrantGrace(5)
        hum:MoveTo(target)
        if (root.Position - last).Magnitude < 0.4 then
            stuck = stuck + 1
            if stuck >= 3 then hum.Jump = true; stuck = 0 end
        else stuck = 0 end
        last = root.Position
        task.wait(0.2)
    end
    return (root.Position - target).Magnitude <= 8
end

function Systems.GetNearestBooth(from)
    from = from or (GetRoot() and GetRoot().Position) or Systems.TOWN_CAR_SPAWN
    local best, bd = nil, math.huge
    for _, d in pairs(Systems.LOCATIONS) do
        if d.Booth then
            local dist = (d.Booth - from).Magnitude
            if dist < bd then bd = dist; best = d.Booth end
        end
    end
    local td = (Systems.TOWN_CAR_SPAWN - from).Magnitude
    if td < bd then best = Systems.TOWN_CAR_SPAWN end
    return best or Systems.TOWN_CAR_SPAWN
end

local function IsMyVehicle(v)
    if not v or not v:IsA("Model") or not v.Parent then return false end
    if MY_CAR and v == MY_CAR then return true end
    local hum = GetHum()
    if hum and hum.SeatPart and hum.SeatPart:IsDescendantOf(v) then MY_CAR = v; return true end
    local owner = v:GetAttribute("Owner") or v:GetAttribute("OwnerName") or v:GetAttribute("Player")
    local ownerId = v:GetAttribute("OwnerId") or v:GetAttribute("UserId")
    if owner and tostring(owner) ~= "" then
        if tostring(owner) == LocalPlayer.Name or tostring(owner) == tostring(LocalPlayer.UserId) then
            MY_CAR = v; return true
        else return false end
    end
    if ownerId and tonumber(ownerId) == LocalPlayer.UserId then MY_CAR = v; return true end
    for _, s in ipairs(v:GetDescendants()) do
        if s:IsA("VehicleSeat") or s:IsA("Seat") then
            if s.Occupant and s.Occupant ~= hum then return false end
        end
    end
    return true
end
Systems.IsMyVehicle = IsMyVehicle

function Systems.GetMyCar()
    local hum = GetHum()
    if hum and hum.SeatPart and hum.SeatPart:IsA("VehicleSeat") then
        local v = hum.SeatPart:FindFirstAncestorOfClass("Model")
        if v and IsMyVehicle(v) then return v end
    end
    if MY_CAR and MY_CAR.Parent and IsMyVehicle(MY_CAR) then return MY_CAR end
    local veh = (workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Vehicles")) or workspace:FindFirstChild("Vehicles")
    if veh then
        for _, v in ipairs(veh:GetChildren()) do
            if v:IsA("Model") and IsMyVehicle(v) and v.PrimaryPart then
                MY_CAR = v; return v
            end
        end
    end
    return nil
end

function Systems.PressFEnter(car)
    if not car or not IsMyVehicle(car) then return false end
    local hum = GetHum()
    local root = GetRoot()
    if not hum or not root then return false end
    local seat = car:FindFirstChildWhichIsA("VehicleSeat", true) or car:FindFirstChildWhichIsA("Seat", true)
    if not seat then return false end
    if hum.Sit and hum.SeatPart == seat then MY_CAR = car; return true end
    if hum.Sit then hum.Sit = false; task.wait(0.2) end
    Systems.GrantGrace(20)
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
        pcall(function()
            root.CFrame = seat.CFrame + Vector3.new(0, 0.5, 0)
            seat:Sit(hum)
        end)
        task.wait(0.2)
    end
    if hum.Sit then MY_CAR = car end
    return hum.Sit ~= nil
end

function Systems.ExitCar(car)
    local hum = GetHum()
    local root = GetRoot()
    if not hum or not root then return end
    if hum.Sit then hum.Sit = false; task.wait(0.12) end
    if car and car.PrimaryPart then
        local right = car.PrimaryPart.CFrame.RightVector
        local exit = car.PrimaryPart.Position - right * 4.2
        local gy = Systems.GetGroundLevel(exit.X, exit.Z, car.PrimaryPart.Position.Y)
        root.CFrame = CFrame.new(exit.X, gy + 1.8, exit.Z)
        root.AssemblyLinearVelocity = Vector3.zero
    end
    task.wait(0.15)
end

function Systems.EnsureCar(pos)
    local car = Systems.GetMyCar()
    if car then return car end
    local root = GetRoot()
    if root and pos then root.CFrame = CFrame.new(pos + Vector3.new(0, 4, 0)); task.wait(0.4) end
    task.wait(0.3)
    car = Systems.GetMyCar()
    if car then MY_CAR = car end
    return car
end

function Systems.DriveCarTo(dest, check)
    local car = Systems.GetMyCar() or Systems.EnsureCar()
    if not car then return false end
    local hum = GetHum()
    if not hum.Sit then Systems.PressFEnter(car) end
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
        Systems.GrantGrace(5)
        local dir = (dest - root.Position).Unit
        local look = CFrame.lookAt(root.Position, root.Position + Vector3.new(dir.X, 0, dir.Z))
        root.CFrame = look
        pcall(function()
            seat.ThrottleFloat = 1
            seat.SteerFloat = 0
        end)
        task.wait(0.1)
    end
    pcall(function() seat.ThrottleFloat = 0; seat.SteerFloat = 0 end)
    return true
end

--==================================================
-- Prompt
--==================================================
local function FindPromptNear(center, maxDist, kw)
    maxDist = maxDist or 25
    local best, bd = nil, maxDist
    local sys = workspace:FindFirstChild("Systems")
    local containers = sys and { sys } or { workspace }
    for _, c in ipairs(containers) do
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("ProximityPrompt") and p.Enabled then
                local pp = p.Parent
                local pos = pp and ((pp:IsA("BasePart") and pp.Position) or (pp:IsA("Attachment") and pp.WorldPosition) or (pp:FindFirstChildWhichIsA("BasePart") and pp:FindFirstChildWhichIsA("BasePart").Position))
                if pos then
                    local d = (pos - center).Magnitude
                    if d <= bd then
                        if not kw or (p.ActionText and p.ActionText:lower():find(kw:lower())) or (p.ObjectText and p.ObjectText:lower():find(kw:lower())) then
                            best, bd = p, d
                        end
                    end
                end
            end
        end
    end
    return best
end
Systems.FindPromptNear = FindPromptNear

function Systems.TriggerPrompt(p)
    if not p or not p.Enabled then return end
    pcall(function()
        if fireproximityprompt then fireproximityprompt(p) end
        p:InputHoldBegin()
        task.wait((p.HoldDuration or 0) + 0.1)
        p:InputHoldEnd()
    end)
end

--==================================================
-- Harvest
--==================================================
function Systems.HarvestCrop(crop, target, check)
    local loc = Systems.LOCATIONS[crop]
    if not loc then Notify("ไม่พบตำแหน่ง: " .. crop, false); return end
    local root = GetRoot()
    if not root then return end
    local start = Systems.GetCount(crop)
    if start >= target then return end
    Notify("🌾 ขับรถไปฟาร์ม " .. crop, true)
    local car = Systems.GetMyCar() or Systems.EnsureCar(Systems.GetNearestBooth(root.Position))
    if car then
        Systems.PressFEnter(car)
        local parkX, parkZ = loc.Farm.X + 4.5, loc.Farm.Z + 4.5
        local gy = Systems.GetGroundLevel(parkX, parkZ, loc.Farm.Y)
        Systems.DriveCarTo(Vector3.new(parkX, gy, parkZ), check)
        task.wait(0.3)
        Systems.ExitCar(car)
    else
        Systems.SmoothWalk(loc.Farm, 40, check, 3)
    end
    task.wait(0.5)
    local gp = Systems.GetGroundLevel(loc.Farm.X, loc.Farm.Z, loc.Farm.Y)
    root.CFrame = CFrame.lookAt(Vector3.new(loc.Farm.X, gp + 2, loc.Farm.Z), Vector3.new(loc.Farm.X - 1, gp + 2, loc.Farm.Z))
    task.wait(0.3)
    local prompt = FindPromptNear(root.Position, 20)
    if prompt then Systems.TriggerPrompt(prompt) end
    task.wait(1.5)
    local t0 = os.clock()
    local cur = Systems.GetCount(crop)
    while cur < target and os.clock() - t0 < 180 do
        if check and not check() then break end
        Systems.GrantGrace(15)
        if GetHunger() <= 75 or GetEnergy() <= 75 then
            Systems.CheckAutoEat()
        end
        task.wait(0.5)
        local n = Systems.GetCount(crop)
        if n > cur then cur = n; t0 = os.clock() end
        if os.clock() - t0 > 15 and n == cur then
            local p = FindPromptNear(root.Position, 20)
            if p then Systems.TriggerPrompt(p) end
            t0 = os.clock()
        end
    end
    Notify("✅ ฟาร์ม " .. crop .. " " .. Systems.GetCount(crop) .. "/" .. target, true)
    -- เบิกรถที่ตู้ใกล้สุด
    local booth = Systems.GetNearestBooth(root.Position)
    Systems.SmoothWalk(booth, 45, check, 2.5)
    local c2 = Systems.EnsureCar(booth)
    if c2 then Systems.PressFEnter(c2) end
end

--==================================================
-- Sell
--==================================================
function Systems.SellAll(check)
    local root = GetRoot()
    if not root then return end
    local market = Systems.LOCATIONS.Economy.Market
    local car = Systems.GetMyCar() or Systems.EnsureCar()
    if car then
        Systems.PressFEnter(car)
        Systems.DriveCarTo(market, check)
        task.wait(0.3)
        Systems.ExitCar(car)
    else
        Systems.SmoothWalk(market, 40, check, 3)
    end
    local gy = Systems.GetGroundLevel(market.X, market.Z, market.Y)
    root.CFrame = CFrame.lookAt(Vector3.new(market.X + 2.5, gy + 2, market.Z), market)
    task.wait(0.2)
    local p = FindPromptNear(root.Position, 25, "econ") or FindPromptNear(root.Position, 25)
    if p then Systems.TriggerPrompt(p) end
    task.wait(0.4)
    pcall(function()
        local remCore = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes")
        if remCore then
            local R = require(remCore)
            R.Invoke("_economy", "SellAll")
            R.Fire("_economy", "SellAll")
        else
            local rem = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Remotes")
            if rem and rem:FindFirstChild("_economy") then rem._economy:FireServer("SellAll") end
        end
    end)
    task.wait(1.0)
    Notify("💰 ขายของทั้งหมดแล้ว", true)
    if CFG("AutoEatDrink", true) then Systems.CheckAutoEat() end
    local c = Systems.GetMyCar() or Systems.EnsureCar(Systems.TOWN_CAR_SPAWN)
    if c then Systems.PressFEnter(c) end
end

--==================================================
-- Craft
--==================================================
function Systems.CraftFood(recipe, check)
    local food = Systems.LOCATIONS.Food
    local root = GetRoot()
    if not root then return end
    local car = Systems.GetMyCar() or Systems.EnsureCar()
    if car then
        Systems.PressFEnter(car)
        Systems.DriveCarTo(food.Crafting + Vector3.new(0, 0, 5), check)
        task.wait(0.3)
        Systems.ExitCar(car)
    end
    local gy = Systems.GetGroundLevel(food.Crafting.X, food.Crafting.Z, food.Crafting.Y)
    root.CFrame = CFrame.lookAt(Vector3.new(food.Crafting.X, gy + 3, food.Crafting.Z + 2.5), food.Crafting)
    task.wait(0.2)
    -- หา prompt Craft_3
    local prompt = nil
    local craftSys = workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Crafting")
    local c3 = craftSys and craftSys:FindFirstChild("Craft_3")
    if c3 then prompt = c3:FindFirstChildWhichIsA("ProximityPrompt", true) end
    if prompt then Systems.TriggerPrompt(prompt) end
    task.wait(1.0)
    -- คำนวณจำนวนที่คราฟได้
    local function maxCraft()
        local b, c, p, m, r = Systems.GetCount("Bread"), Systems.GetCount("Catchup"), Systems.GetCount("Pig"), Systems.GetCount("Mango"), Systems.GetCount("Rice")
        if recipe == "Sandwish" then return math.min(math.floor(b / 3), math.floor(c / 2), math.floor(p / 2)) end
        if recipe == "MangoRice" then return math.min(math.floor(m / 2), math.floor(r / 3)) end
        if recipe == "RiceKapaoMoo" then return math.min(math.floor(p / 2), math.floor(r / 3)) end
        if recipe == "KangSom" then
            local tom, cr = Systems.GetCount("Tomato"), Systems.GetCount("Crab")
            return math.min(math.floor(tom / 2), math.floor(cr / 2))
        end
        return 1
    end
    local n = maxCraft()
    if n <= 0 then Notify("ของไม่พอคราฟ " .. recipe, false); return end
    pcall(function()
        local remCore = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes")
        if remCore then
            local R = require(remCore)
            R.Fire("_crafting", "Request", "Craft_3", recipe, n, false)
        end
    end)
    Notify("🍳 คราฟ " .. recipe .. " x" .. n, true)
    local t0 = os.clock()
    while os.clock() - t0 < 10.5 do
        if check and not check() then break end
        task.wait(0.5)
    end
    pcall(function()
        local remCore = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes")
        if remCore then
            local R = require(remCore)
            R.Fire("_crafting", "Complete", "Craft_3", recipe, n, false)
        end
    end)
    task.wait(0.3)
    local c2 = Systems.GetMyCar() or Systems.EnsureCar()
    if c2 then Systems.PressFEnter(c2) end
end

function Systems.ProcessBanana(check)
    local food = Systems.LOCATIONS.Food
    local root = GetRoot()
    if not root then return end
    local car = Systems.GetMyCar() or Systems.EnsureCar()
    if car then
        Systems.PressFEnter(car)
        Systems.DriveCarTo(food.BananaProcess + Vector3.new(0, 0, 5), check)
        task.wait(0.3)
        Systems.ExitCar(car)
    end
    local gy = Systems.GetGroundLevel(food.BananaProcess.X, food.BananaProcess.Z, food.BananaProcess.Y)
    root.CFrame = CFrame.lookAt(Vector3.new(food.BananaProcess.X, gy + 3, food.BananaProcess.Z + 2.5), food.BananaProcess)
    task.wait(0.3)
    local pBan = workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Process") and workspace.Systems.Process:FindFirstChild("Banana")
    local prompt = pBan and pBan:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt then Systems.TriggerPrompt(prompt) end
    Notify("🍌 แปรรูปกล้วย", true)
    local t0 = os.clock()
    while Systems.GetCount("Banana") >= 2 and os.clock() - t0 < 120 do
        if check and not check() then break end
        task.wait(3.2)
    end
    local c = Systems.GetMyCar() or Systems.EnsureCar()
    if c then Systems.PressFEnter(c) end
end

--==================================================
-- Warp
--==================================================
function Systems.WarpToTown()
    local root = GetRoot()
    if not root then return nil end
    root.CFrame = CFrame.new(Systems.TOWN_CAR_SPAWN + Vector3.new(0, 5, 0))
    Systems.GrantGrace(20)
    task.wait(0.5)
    return Systems.EnsureCar(Systems.TOWN_CAR_SPAWN)
end

--==================================================
-- Server Hop
--==================================================
function Systems.HopServer(reason)
    if isHopping then return end
    isHopping = true
    Notify("🔄 ย้ายเซิร์ฟเวอร์: " .. tostring(reason), true)
    pcall(function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end)
end

--==================================================
-- Fishing (Full with Minigame Solver)
--==================================================
local function GetRod()
    local char = LocalPlayer.Character
    local bp = LocalPlayer:FindFirstChild("Backpack")
    for _, n in ipairs({ "FishingRodV3", "FishingRodV2", "FishingRod" }) do
        local t = char and char:FindFirstChild(n)
        if t and t:IsA("Tool") then return t end
        t = bp and bp:FindFirstChild(n)
        if t and t:IsA("Tool") then return t end
    end
    return nil
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
        if remCore then
            local R = require(remCore)
            R.Fire("_inventory", "Use", "FishingRod")
        end
    end)
    task.wait(0.4)
    rod = GetRod()
    if rod and rod.Parent == bp then hum:EquipTool(rod); task.wait(0.2) end
    return rod
end

local function SolveMinigame()
    local pgui = LocalPlayer:FindFirstChild("PlayerGui")
    local vim = VirtualInputManager
    local fg = pgui and pgui:FindFirstChild("FishingGame")
    if not fg then return false end
    local mg = fg:FindFirstChild("Minigame")
    if not mg then return false end
    local holding = false
    local t0 = os.clock()
    local conn
    conn = RunService.RenderStepped:Connect(function()
        if not isAutoFishing or not fg.Parent then
            if holding then pcall(function() vim:SendKeyEvent(false, Enum.KeyCode.Space, false, game) end) end
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
                if not holding then
                    holding = true
                    pcall(function() vim:SendKeyEvent(true, Enum.KeyCode.Space, false, game) end)
                end
            elseif fc > pc + 4 then
                if holding then
                    holding = false
                    pcall(function() vim:SendKeyEvent(false, Enum.KeyCode.Space, false, game) end)
                end
            end
        end
    end)
    while fg.Parent and isAutoFishing and os.clock() - t0 < 30 do
        task.wait(0.05)
        fg = pgui:FindFirstChild("FishingGame")
    end
    if conn then conn:Disconnect() end
    if holding then pcall(function() vim:SendKeyEvent(false, Enum.KeyCode.Space, false, game) end) end
    task.wait(2.0)
    return true
end

function Systems.StartFishing(onChange)
    isAutoFishing = true
    onChange = onChange or function() end
    task.spawn(function()
        Notify("🎣 เริ่มตกปลาออโต้", true)
        while isAutoFishing do
            local root = GetRoot()
            local hum = GetHum()
            if root and hum and hum.Health > 0 then
                local pd = LocalPlayer:FindFirstChild("PlayerData")
                local bait = (pd and (pd:GetAttribute("FishingBait") or pd:GetAttribute("Bait"))) or 0
                local betta = (pd and pd:GetAttribute("Bettafish")) or 0
                local angler = (pd and pd:GetAttribute("Anglerfish")) or 0
                local fishCount = betta + angler

                if bait <= 0 or fishCount >= 25 then
                    local car = Systems.GetMyCar() or Systems.EnsureCar()
                    if car then
                        Systems.PressFEnter(car)
                        Systems.DriveCarTo(Systems.BAIT_SHOP, function() return isAutoFishing end)
                        Systems.ExitCar(car)
                    end
                    Systems.SellAll(function() return isAutoFishing end)
                    -- ซื้อเหยื่อ (ยิง remote)
                    pcall(function()
                        local remCore = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes")
                        if remCore then
                            local R = require(remCore)
                            R.Fire("_shop", "Buy", { FishingBait = 100 }, "Money")
                        end
                    end)
                    local c2 = Systems.GetMyCar() or Systems.EnsureCar()
                    if c2 then
                        Systems.PressFEnter(c2)
                        Systems.DriveCarTo(Systems.FISHING_PARKING, function() return isAutoFishing end)
                        Systems.ExitCar(c2)
                    end
                end
                Systems.SmoothWalk(Systems.FISHING_SPOT, 25, function() return isAutoFishing end, 2)
                if hum.Sit then hum.Sit = false end
                local rod = EquipRod()
                if rod and rod.Parent == LocalPlayer.Character then
                    local look = Systems.FISHING_SPOT + Systems.FISHING_LOOK * 20
                    root.CFrame = CFrame.lookAt(Systems.FISHING_SPOT, look)
                    task.wait(0.3)
                    pcall(function() rod:Activate() end)
                    task.wait(1.0)
                    local pgui = LocalPlayer:FindFirstChild("PlayerGui")
                    local fg = pgui and pgui:FindFirstChild("FishingGame")
                    if fg then SolveMinigame() end
                end
                task.wait(0.2)
            else
                task.wait(1)
            end
        end
        Notify("🛑 หยุดตกปลา", false)
    end)
end

function Systems.StopFishing()
    isAutoFishing = false
    if fishingPlatform and fishingPlatform.Parent then fishingPlatform:Destroy(); fishingPlatform = nil end
end

--==================================================
-- Auto Hop loop
--==================================================
task.spawn(function()
    while true do
        task.wait(0.5)
        if CFG("AutoHopPlayer", true) and not isHopping then
            local root = GetRoot()
            if root then
                local dist = CFG("HopDistance", 60)
                for _, pl in ipairs(Players:GetPlayers()) do
                    if pl ~= LocalPlayer and pl.Character then
                        local oR = pl.Character:FindFirstChild("HumanoidRootPart")
                        local oH = pl.Character:FindFirstChildOfClass("Humanoid")
                        if oR and oH and oH.Health > 0 then
                            if (oR.Position - root.Position).Magnitude <= dist then
                                Systems.HopServer("ผู้เล่น @" .. pl.Name)
                                break
                            end
                        end
                    end
                end
            end
        end
    end
end)

--==================================================
-- Auto Eat loop
--==================================================
task.spawn(function()
    while true do
        task.wait(3.0)
        if CFG("AutoEatDrink", true) and not isConsuming then
            local hum = GetHum()
            if hum and not hum.Sit then Systems.CheckAutoEat() end
        end
    end
end)

return Systems

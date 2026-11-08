-- ==============================================================================
-- [[ NEXUS HUB v4.4 — TYPER TOWN COMPACT EDITION ]]
-- ไฟล์เดียวจบ: UI (WindUI) + Farm + Fishing + Auto Hop + Anti-Kick
-- ==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local okVIM, VirtualInputManager = pcall(function() return game:GetService("VirtualInputManager") end)
if not okVIM then VirtualInputManager = nil end
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Notify = function(_) end

-- ==== ANTI-KICK ====
pcall(function()
    local lp = Players.LocalPlayer
    if hookmetamethod then
        local oldNm
        oldNm = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local m = getnamecallmethod()
            local args = {...}
            if (m == "Kick" or m == "kick") and (self == lp or self == Players) then
                warn("[ANTI-KICK] Blocked: " .. tostring(args[1] or "?"))
                return nil
            end
            if m == "FireServer" or m == "InvokeServer" then
                for _, a in ipairs(args) do
                    local s = tostring(a):lower()
                    if s:find("kick") or s:find("anticheat") or s:find("antifall") or s:find("exploit") then return nil end
                end
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

-- ==== CONFIG ====
local TOWN_CAR_SPAWN = Vector3.new(-311.83, 17.5, 5490.39)
local isAutoEatAndDrinkEnabled = true
local VehicleDriveSpeed = 200
local isAutoHopOnPlayerNearbyEnabled = true
local autoHopDistance = 60
local isHopping = false
local MY_SPAWNED_CAR = nil
local isConsumingItem = false

-- ==== GRACE / GROUND ====
local function GrantAntiXGrace(sec)
    sec = sec or 25
    pcall(function()
        local char = LocalPlayer.Character
        if not char then return end
        local antiFall = char:FindFirstChild("Antifall") or char:FindFirstChild("AntiFall")
        if antiFall and antiFall:IsA("Script") then antiFall.Disabled = true end
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

local function GetGroundLevel(x, z, fallbackY)
    fallbackY = fallbackY or 20
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.IgnoreWater = false
    local filter = {}
    if LocalPlayer.Character then table.insert(filter, LocalPlayer.Character) end
    local veh = (workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Vehicles")) or workspace:FindFirstChild("Vehicles")
    if veh then table.insert(filter, veh) end
    params.FilterDescendantsInstances = filter
    local r = workspace:Raycast(Vector3.new(x, fallbackY + 150, z), Vector3.new(0, -350, 0), params)
    return r and r.Position.Y or fallbackY
end

-- ==== INVENTORY ====
local function GetPlayerInventoryCount(item)
    local pd = LocalPlayer:FindFirstChild("PlayerData")
    if pd then
        local c = pd:GetAttribute(item)
        if typeof(c) == "number" then return c end
    end
    return 0
end

-- ==== HUNGER / ENERGY ====
local function GetPlayerHunger()
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

local function GetPlayerEnergy()
    local hud = PlayerGui:FindFirstChild("HUD")
    if hud and hud:FindFirstChild("Health") then
        for _, n in ipairs({"Energy","Stamina","Thirst","Coffee","Brain"}) do
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

local function FindAvailableFood()
    local pd = LocalPlayer:FindFirstChild("PlayerData")
    local bp = LocalPlayer:FindFirstChild("Backpack")
    for _, f in ipairs({"RiceKapaoMoo","MangoRice","Rice","Sushi","Sandwish","Burger","Bread","Onigiri"}) do
        if pd then
            local c = pd:GetAttribute(f)
            if typeof(c) == "number" and c > 0 then return f end
        end
        if bp and bp:FindFirstChild(f) then return f end
    end
    return nil
end

local function FindAvailableCoffee()
    local pd = LocalPlayer:FindFirstChild("PlayerData")
    local bp = LocalPlayer:FindFirstChild("Backpack")
    for _, d in ipairs({"Coffee","HotCoffee","HotCocoa","Cocoa","Water","Drink"}) do
        if pd then
            local c = pd:GetAttribute(d)
            if typeof(c) == "number" and c > 0 then return d end
        end
        if bp and bp:FindFirstChild(d) then return d end
    end
    return nil
end

local function UseItem(item)
    pcall(function()
        local rem = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes")
        if rem then
            local R = require(rem)
            R.Fire("_inventory", "Use", item)
        end
    end)
end

local function ConsumeItemSafely(item, isFood)
    if isConsumingItem or not item then return end
    isConsumingItem = true
    pcall(function()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        UseItem(item)
        local tool, t0 = nil, os.clock()
        while os.clock() - t0 < 2.5 do
            char = LocalPlayer.Character
            tool = char and char:FindFirstChild(item)
            if not tool and LocalPlayer:FindFirstChild("Backpack") then
                tool = LocalPlayer.Backpack:FindFirstChild(item)
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
                local barGui = PlayerGui:FindFirstChild("Bar")
                local barMain = barGui and barGui:FindFirstChild("Main")
                local maxWait = (item:lower():find("sushi") and 5.6) or (isFood and 5.4 or 3.8)
                local ws = os.clock()
                while os.clock() - ws < maxWait do task.wait(0.15) end
                task.wait(0.3)
                pcall(function() hum:UnequipTools() end)
            end
        else task.wait(1.5) end
    end)
    isConsumingItem = false
end

local function AutoEatThenDrink(target)
    target = target or 95
    if isConsumingItem then return end
    local hunger = GetPlayerHunger()
    if hunger and hunger < target then
        for _ = 1, 8 do
            if not hunger or hunger >= target then break end
            local food = FindAvailableFood()
            if not food then break end
            pcall(function() Notify({ Title="NEXUS HUB", Content="🍣 กิน "..food, Duration=2 }) end)
            ConsumeItemSafely(food, true)
            task.wait(0.5)
            hunger = GetPlayerHunger()
        end
    end
    task.wait(0.4)
    local energy = GetPlayerEnergy()
    if energy and energy < target then
        for _ = 1, 8 do
            if not energy or energy >= target then break end
            local drink = FindAvailableCoffee()
            if not drink then break end
            pcall(function() Notify({ Title="NEXUS HUB", Content="☕ ดื่ม "..drink, Duration=2 }) end)
            ConsumeItemSafely(drink, false)
            task.wait(0.5)
            energy = GetPlayerEnergy()
        end
    end
end

local function CheckAndAutoEat()
    if not isAutoEatAndDrinkEnabled or isConsumingItem then return end
    if GetPlayerHunger() <= 75 or GetPlayerEnergy() <= 75 then AutoEatThenDrink(95) end
end

local function CancelGameFarm()
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

-- ==== LOCATIONS ====
local TYPER_LOCATIONS = {
    Bread = { Booth = Vector3.new(872.19, 15.90, 4682.54), Farm = Vector3.new(828.31, 11.21, 4817.85) },
    Catchup = { Booth = Vector3.new(1763.23, 14.23, 4206.70), Farm = Vector3.new(1803.05, 12.65, 4236.79) },
    Pig = { Booth = Vector3.new(306.01, 30.77, -1558.06), Farm = Vector3.new(268.61, 28.74, -1513.65) },
    Mango = { Booth = Vector3.new(-1855.59, 20.06, 586.40), Farm = Vector3.new(-1862.26, 17.33, 535.43) },
    Rice = { Booth = Vector3.new(-92.11, 11.46, 89.48), Farm = Vector3.new(-128.87, 11.02, 78.51) },
    Tomato = { Booth = Vector3.new(-2294.10, 31.28, -1273.91), Farm = Vector3.new(-2319.61, 27.21, -1229.19) },
    Banana = { Booth = Vector3.new(-1528.59, 30.34, -1253.46), Farm = Vector3.new(-1545.12, 28.80, -1126.87) },
    Crab = { Booth = Vector3.new(1442.30, 30.56, 613.34), Farm = Vector3.new(1400.27, 28.69, 648.22) },
    Coconut = { Booth = Vector3.new(-1296.67, 10.37, 4216.59), Farm = Vector3.new(-1333.68, 10.87, 4376.67) },
    Food = { Crafting = Vector3.new(3442.48, 56.40, 3925.24), BananaProcess = Vector3.new(3429.20, 56.80, 3911.80) },
    Economy = { Market = Vector3.new(-462.0, 18.0, 5324.7) },
}

-- ==== VEHICLE ====
local function IsMyVehicle(v)
    if not v or not v:IsA("Model") or not v.Parent then return false end
    local myName = LocalPlayer.Name
    local myId = LocalPlayer.UserId
    local owner = v:GetAttribute("Owner") or v:GetAttribute("OwnerName") or v:GetAttribute("Player")
    local ownerId = v:GetAttribute("OwnerId") or v:GetAttribute("UserId")
    if owner and tostring(owner) ~= "" then
        return tostring(owner) == myName or tostring(owner) == tostring(myId)
    end
    if ownerId and tonumber(ownerId) then return tonumber(ownerId) == myId end
    return false
end

local function GetPlayerVehicle()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum and hum.SeatPart and hum.SeatPart:IsA("VehicleSeat") then
        local veh = hum.SeatPart:FindFirstAncestorOfClass("Model")
        if veh and IsMyVehicle(veh) then return veh end
    end
    if MY_SPAWNED_CAR and MY_SPAWNED_CAR.Parent and MY_SPAWNED_CAR.PrimaryPart and IsMyVehicle(MY_SPAWNED_CAR) then
        return MY_SPAWNED_CAR
    end
    local vehFolder = (workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Vehicles")) or workspace:FindFirstChild("Vehicles")
    if vehFolder then
        for _, v in ipairs(vehFolder:GetChildren()) do
            if v:IsA("Model") and IsMyVehicle(v) and v.PrimaryPart then MY_SPAWNED_CAR = v; return v end
        end
    end
    return nil
end

local function GetNearbyPlayerVehicle(maxDist)
    maxDist = maxDist or 80
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return nil, math.huge end
    if hum and hum.Sit and hum.SeatPart and hum.SeatPart:IsA("VehicleSeat") then
        local veh = hum.SeatPart:FindFirstAncestorOfClass("Model")
        if veh and IsMyVehicle(veh) then return veh, 0 end
    end
    local vehFolder = (workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Vehicles")) or workspace:FindFirstChild("Vehicles")
    local nearest, minDist = nil, math.huge
    if vehFolder then
        for _, v in ipairs(vehFolder:GetChildren()) do
            if v:IsA("Model") and IsMyVehicle(v) and v.PrimaryPart then
                local d = (v.PrimaryPart.Position - root.Position).Magnitude
                if d < minDist then minDist = d; nearest = v end
            end
        end
    end
    if nearest and minDist <= maxDist then MY_SPAWNED_CAR = nearest; return nearest, minDist end
    return nil, minDist
end

local function PressFToEnterCar(car)
    if not car or not car.Parent or not IsMyVehicle(car) then return false end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return false end
    local seat = car:FindFirstChild("DriveSeat", true) or car:FindFirstChildWhichIsA("VehicleSeat", true)
    if not seat then return false end
    if hum.Sit and hum.SeatPart == seat then return true end
    if hum.Sit then hum.Sit = false; task.wait(0.2) end
    GrantAntiXGrace(15)
    local drivePrompt = nil
    local pFolder = seat:FindFirstChild("Prompt")
    if pFolder and pFolder:FindFirstChild("Prompt") and pFolder.Prompt:IsA("ProximityPrompt") then
        drivePrompt = pFolder.Prompt
    else
        for _, d in ipairs(seat:GetDescendants()) do
            if d:IsA("ProximityPrompt") and d.ActionText:lower():find("drive") and not d.ActionText:lower():find("passenger") then
                drivePrompt = d; break
            end
        end
    end
    for _, d in ipairs(car:GetDescendants()) do
        if d:IsA("ProximityPrompt") and (d.ActionText:lower():find("passenger") or d.Name:lower():find("passenger")) then
            d.Enabled = false
        end
    end
    local doorCF = seat.CFrame * CFrame.new(-2.6, 0.2, 0)
    root.CFrame = CFrame.lookAt(doorCF.Position, seat.Position)
    root.AssemblyLinearVelocity = Vector3.zero
    task.wait(0.15)
    if drivePrompt then
        pcall(function() fireproximityprompt(drivePrompt) end)
        pcall(function() drivePrompt:InputHoldBegin() end)
        task.wait(0.06)
        pcall(function() drivePrompt:InputHoldEnd() end)
    end
    if VirtualInputManager then
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
            task.wait(0.08)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
        end)
    end
    local t0 = os.clock()
    while os.clock() - t0 < 1.5 do
        if hum.Sit and hum.SeatPart == seat then break end
        task.wait(0.1)
    end
    if not (hum.Sit and hum.SeatPart == seat) then
        pcall(function() root.CFrame = seat.CFrame + Vector3.new(0, 0.5, 0); seat:Sit(hum) end)
        task.wait(0.2)
    end
    local seated = hum.Sit and hum.SeatPart == seat
    if seated then MY_SPAWNED_CAR = car end
    return seated
end

local function ExitCarNaturally(car)
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return end
    if hum.Sit then hum.Sit = false; task.wait(0.12) end
    if car and car.PrimaryPart then
        local right = car.PrimaryPart.CFrame.RightVector
        local exit = car.PrimaryPart.Position - right * 4.2
        local gy = GetGroundLevel(exit.X, exit.Z, car.PrimaryPart.Position.Y)
        root.CFrame = CFrame.new(exit.X, gy + 1.8, exit.Z)
        root.AssemblyLinearVelocity = Vector3.zero
    end
    task.wait(0.15)
end

-- ==== UTIL ====
local function FindPromptNear(center, maxDist, kw)
    maxDist = maxDist or 25
    local best, bd = nil, maxDist
    local sys = workspace:FindFirstChild("Systems")
    local containers = sys and {sys} or {workspace}
    for _, c in ipairs(containers) do
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("ProximityPrompt") and p.Enabled then
                local pp = p.Parent
                local pos = pp and ((pp:IsA("BasePart") and pp.Position) or (pp:IsA("Attachment") and pp.WorldPosition))
                if pos then
                    local d = (pos - center).Magnitude
                    if d <= bd then
                        if not kw or (p.ActionText and p.ActionText:lower():find(kw:lower())) then
                            best, bd = p, d
                        end
                    end
                end
            end
        end
    end
    return best
end

local function ClickGuiButton(btn)
    if not btn then return end
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

local function TriggerPrompt(p)
    if not p or not p.Enabled then return end
    pcall(function()
        if fireproximityprompt then fireproximityprompt(p) end
        p:InputHoldBegin()
        task.wait((p.HoldDuration or 0) + 0.1)
        p:InputHoldEnd()
    end)
end

-- ==== BOOTH ====
local function GetNearestCarBooth(from)
    from = from or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.Position) or TOWN_CAR_SPAWN
    local best, bd = nil, math.huge
    for _, data in pairs(TYPER_LOCATIONS) do
        if data.Booth then
            local d = (data.Booth - from).Magnitude
            if d < bd then bd = d; best = data.Booth end
        end
    end
    local d = (TOWN_CAR_SPAWN - from).Magnitude
    if d < bd then best = TOWN_CAR_SPAWN end
    return best or TOWN_CAR_SPAWN
end

local function SmoothWalkTo(target, timeout, check, stopDist)
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return false end
    timeout = timeout or 50
    stopDist = stopDist or 2.5
    local t0, last, stuck = os.clock(), root.Position, 0
    while (root.Position - target).Magnitude > stopDist and (os.clock() - t0 < timeout) do
        if check and not check() then return false end
        GrantAntiXGrace(5)
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

local function DriveCarTo(dest, check)
    local myCar = GetNearbyPlayerVehicle(80) or GetPlayerVehicle()
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myCar or not hum or not root then return false end
    local seat = myCar:FindFirstChildWhichIsA("VehicleSeat", true)
    if not seat then return false end
    if not hum.Sit then PressFToEnterCar(myCar) end
    task.wait(0.1)
    local startPos = seat.Position
    local startY = startPos.Y
    local initialGround = GetGroundLevel(startPos.X, startPos.Z, startY)
    local rideHeight = math.clamp(startY - initialGround, 2.3, 3.2)
    local distTotal = (Vector2.new(dest.X, dest.Z) - Vector2.new(startPos.X, startPos.Z)).Magnitude
    if distTotal < 5 then return true end
    local traveled = 0
    local lastTick = os.clock()
    while traveled < distTotal do
        if check and not check() then return false end
        local now = os.clock()
        GrantAntiXGrace(5)
        if not hum.Sit or hum.SeatPart ~= seat then
            pcall(function() root.CFrame = seat.CFrame + Vector3.new(0, 0.8, 0); seat:Sit(hum) end)
        end
        local spd = math.clamp(tonumber(VehicleDriveSpeed) or 200, 10, 500)
        local dt = math.min(now - lastTick, 0.1)
        lastTick = now
        traveled = math.min(distTotal, traveled + spd * dt)
        local a = math.clamp(traveled / distTotal, 0, 1)
        local tx = startPos.X + (dest.X - startPos.X) * a
        local tz = startPos.Z + (dest.Z - startPos.Z) * a
        local gy = GetGroundLevel(tx, tz, startY)
        local sy = math.max(gy + rideHeight, 6.0)
        local dir = Vector3.new(dest.X - tx, 0, dest.Z - tz)
        local cf = CFrame.new(tx, sy, tz)
        if dir.Magnitude > 0.1 then cf = CFrame.lookAt(Vector3.new(tx, sy, tz), Vector3.new(tx, sy, tz) + dir) end
        myCar:PivotTo(cf)
        task.wait(0.03)
    end
    local endGround = GetGroundLevel(dest.X, dest.Z, dest.Y)
    myCar:PivotTo(CFrame.new(dest.X, math.max(endGround + rideHeight, 6.0), dest.Z))
    task.wait(0.1)
    return true
end

-- ==== CAR SPAWN UI ====
local function GetSpawnPointForBooth(pos)
    local bestPt, bd = nil, math.huge
    local fs = workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Farm")
    if fs then
        for _, f in ipairs(fs:GetChildren()) do
            local sp = f:FindFirstChild("Prompt") and f.Prompt:FindFirstChild("Spawn")
            local ptFolder = sp and sp:FindFirstChild("Point")
            if ptFolder then
                for _, pt in ipairs(ptFolder:GetChildren()) do
                    if pt:IsA("BasePart") then
                        local d = (pt.Position - pos).Magnitude
                        if d < bd then bd = d; bestPt = pt end
                    end
                end
            end
        end
    end
    return bestPt
end

local function CloseCarSpawnGui()
    pcall(function()
        local cs = PlayerGui:FindFirstChild("Car_Spawn")
        if cs and cs:FindFirstChild("Group") then
            local exitBtn = cs.Group:FindFirstChild("Exit", true)
            if exitBtn then ClickGuiButton(exitBtn) end
            cs.Group.Visible = false
        end
    end)
end

local function FindButtonByType(group, kind)
    local sf = group:FindFirstChild("Main") and group.Main:FindFirstChild("Carlist") and group.Main.Carlist:FindFirstChild("ScrollingFrame")
    if sf then
        for _, ch in ipairs(sf:GetChildren()) do
            if ch:IsA("GuiObject") then
                local b = ch:FindFirstChild(kind == "spawn" and "Spawn" or "Pound")
                if b and b:IsA("GuiButton") and b.Visible then return b end
            end
        end
    end
    for _, d in ipairs(group:GetDescendants()) do
        if d:IsA("GuiButton") and d.Visible then
            local n = d.Name:lower()
            local t = d:IsA("TextButton") and d.Text:lower() or ""
            if kind == "spawn" and (n:find("spawn") or t:find("spawn")) then return d end
            if kind == "pound" and (n:find("pound") or t:find("pound")) then return d end
        end
    end
end

local function SpawnCarAtBooth(boothPos)
    GrantAntiXGrace(40)
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return nil end
    if boothPos then
        local gy = GetGroundLevel(boothPos.X, boothPos.Z, boothPos.Y)
        root.CFrame = CFrame.new(boothPos.X, gy + 1.2, boothPos.Z)
        task.wait(0.4)
    end
    local bp = FindPromptNear(root.Position, 30, nil)
    if bp then
        bp.Enabled = true
        pcall(function() bp:InputHoldBegin() end)
        task.wait(0.3)
        pcall(function() bp:InputHoldEnd() end)
    end
    task.wait(0.6)
    local cs = PlayerGui:FindFirstChild("Car_Spawn")
    local group = cs and cs:FindFirstChild("Group")
    if group and group.Visible then
        local targetCard = nil
        local sf = group:FindFirstChild("Main") and group.Main:FindFirstChild("Carlist") and group.Main.Carlist:FindFirstChild("ScrollingFrame")
        if sf then targetCard = sf:FindFirstChild("Buggy") end
        local poundBtn = (targetCard and targetCard:FindFirstChild("Pound")) or FindButtonByType(group, "pound")
        local spawnBtn = (targetCard and targetCard:FindFirstChild("Spawn")) or FindButtonByType(group, "spawn")
        if poundBtn and poundBtn.Visible then
            ClickGuiButton(poundBtn)
            pcall(function()
                local rem = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes")
                if rem then local R = require(rem); R.Fire("_carspawn", "Despawn") end
            end)
            local tw = os.clock()
            while os.clock() - tw < 4.5 do
                task.wait(0.2)
                if spawnBtn and spawnBtn.Visible then break end
            end
            if targetCard and targetCard:FindFirstChild("Spawn") then spawnBtn = targetCard.Spawn end
        end
        if spawnBtn and spawnBtn.Visible then
            ClickGuiButton(spawnBtn)
            task.wait(1.0)
            for _ = 1, 2 do
                local chk = GetNearbyPlayerVehicle(80) or GetPlayerVehicle()
                if chk and chk.PrimaryPart then break end
                ClickGuiButton(spawnBtn)
                task.wait(1.0)
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
        task.wait(2.0)
        CloseCarSpawnGui()
        PressFToEnterCar(finalCar)
        return finalCar
    end
    CloseCarSpawnGui()
    return nil
end

local function WarpToTownAndSpawnCar()
    GrantAntiXGrace(45)
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    if hum and hum.Sit then hum.Sit = false; task.wait(0.15) end
    pcall(function() LocalPlayer:RequestStreamAroundAsync(TOWN_CAR_SPAWN, 45) end)
    local gy = GetGroundLevel(TOWN_CAR_SPAWN.X, TOWN_CAR_SPAWN.Z, TOWN_CAR_SPAWN.Y)
    root.CFrame = CFrame.new(TOWN_CAR_SPAWN.X, gy + 1.2, TOWN_CAR_SPAWN.Z)
    task.wait(0.4)
    local car = SpawnCarAtBooth(TOWN_CAR_SPAWN)
    if not car then car = GetNearbyPlayerVehicle(80) end
    if car then PressFToEnterCar(car); CloseCarSpawnGui() end
    return car
end

local function EnsureCarAvailable(boothPos)
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local target = boothPos or (root and GetNearestCarBooth(root.Position)) or TOWN_CAR_SPAWN
    local nearby = GetNearbyPlayerVehicle(80)
    if nearby and nearby.PrimaryPart and IsMyVehicle(nearby) then
        PressFToEnterCar(nearby); return nearby
    end
    local car = SpawnCarAtBooth(target)
    if not car or not IsMyVehicle(car) then car = SpawnCarAtBooth(TOWN_CAR_SPAWN) end
    if car and IsMyVehicle(car) then PressFToEnterCar(car) end
    return car
end

-- ==== HOPSERVER ====
local function HopServer(reason)
    if isHopping then return end
    isHopping = true
    pcall(function() Notify({ Title="SERVER HOP", Content="⚠️ "..(reason or "ย้ายเซิร์ฟ..."), Duration=6 }) end)
    task.wait(0.5)
    local TS = game:GetService("TeleportService")
    local HS = game:GetService("HttpService")
    local reqFn = (syn and syn.request) or (http and http.request) or http_request or request
    local hopped = false
    if reqFn then
        pcall(function()
            local url = string.format("https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Asc&limit=25", tostring(game.PlaceId))
            local resp = reqFn({ Url = url, Method = "GET" })
            if resp and resp.StatusCode == 200 and resp.Body then
                local data = HS:JSONDecode(resp.Body)
                if data and data.data then
                    local servers = {}
                    for _, s in ipairs(data.data) do
                        if s.id ~= game.JobId and s.playing and s.maxPlayers and s.playing < s.maxPlayers then
                            table.insert(servers, s.id)
                        end
                    end
                    if #servers > 0 then
                        TS:TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)], LocalPlayer)
                        hopped = true
                    end
                end
            end
        end)
    end
    if not hopped then pcall(function() TS:Teleport(game.PlaceId, LocalPlayer) end) end
end

pcall(function()
    local TS = game:GetService("TeleportService")
    TS.TeleportInitFailed:Connect(function(pl, r, e)
        if pl == LocalPlayer then
            isHopping = false
            task.wait(1.5)
            HopServer("เชื่อมต่อล้มเหลว")
        end
    end)
end)

task.spawn(function()
    while true do
        task.wait(0.5)
        if isAutoHopOnPlayerNearbyEnabled and not isHopping then
            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if root then
                for _, pl in ipairs(Players:GetPlayers()) do
                    if pl ~= LocalPlayer and pl.Character then
                        local oR = pl.Character:FindFirstChild("HumanoidRootPart")
                        local oH = pl.Character:FindFirstChildOfClass("Humanoid")
                        if oR and oH and oH.Health > 0 and (oR.Position - root.Position).Magnitude <= autoHopDistance then
                            HopServer("ผู้เล่น @"..pl.Name)
                            break
                        end
                    end
                end
            end
        end
    end
end)

-- ==== HARVEST ====
local function GetExactFarmPromptPosition(crop)
    local loc = TYPER_LOCATIONS[crop]
    local fallback = loc and loc.Farm
    local fs = workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Farm")
    local folder = fs and fs:FindFirstChild(crop)
    if folder then
        for _, d in ipairs(folder:GetDescendants()) do
            if d:IsA("ProximityPrompt") and d.Enabled then
                local pn = d.Parent and d.Parent.Name:lower() or ""
                local ac = (d.ActionText or ""):lower()
                local ob = (d.ObjectText or ""):lower()
                if not pn:find("spawn") and not ac:find("spawn") and not ac:find("car") and not ob:find("car") then
                    local pp = d.Parent
                    local pos = (pp:IsA("Attachment") and pp.WorldPosition) or (pp:IsA("BasePart") and pp.Position) or (pp.Parent and pp.Parent:IsA("BasePart") and pp.Parent.Position)
                    if pos then return pos end
                end
            end
        end
    end
    return fallback
end

local function GetFarmStandingSpot(center)
    local r = 3.8
    local bestAngle = math.random() * math.pi * 2
    local sx = center.X + math.cos(bestAngle) * r
    local sz = center.Z + math.sin(bestAngle) * r
    local gy = GetGroundLevel(sx, sz, center.Y)
    return Vector3.new(sx, gy + 2.2, sz), bestAngle
end

local function TriggerFarmPromptDirectly(crop)
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    local fs = workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Farm")
    local folder = fs and fs:FindFirstChild(crop)
    local tp = nil
    if folder then
        for _, d in ipairs(folder:GetDescendants()) do
            if d:IsA("ProximityPrompt") and d.Enabled then
                local pn = d.Parent and d.Parent.Name:lower() or ""
                local ac = (d.ActionText or ""):lower()
                if not pn:find("spawn") and not ac:find("spawn") and not ac:find("car") then tp = d; break end
            end
        end
    end
    if not tp and fs then
        for _, p in ipairs(fs:GetDescendants()) do
            if p:IsA("ProximityPrompt") and p.Enabled then
                local pp = p.Parent
                local pos = (pp:IsA("Attachment") and pp.WorldPosition) or (pp:IsA("BasePart") and pp.Position)
                if pos and (pos - root.Position).Magnitude <= 20 then
                    local ac = (p.ActionText or ""):lower()
                    if not ac:find("spawn") and not ac:find("car") then tp = p; break end
                end
            end
        end
    end
    if tp then
        local hold = math.max((tp.HoldDuration or 0.1), 0.15) + 0.12
        pcall(function() tp:InputHoldBegin() end)
        task.wait(hold)
        pcall(function() tp:InputHoldEnd() end)
        return true
    end
    return false
end

local function HarvestSingleCrop(crop, target, check)
    target = 60
    local cur = GetPlayerInventoryCount(crop)
    if cur >= target then return end
    local loc = TYPER_LOCATIONS[crop]
    if not loc then return end
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end
    local myCar = GetNearbyPlayerVehicle(80)
    if not myCar or not hum.Sit then
        if myCar then PressFToEnterCar(myCar) else EnsureCarAvailable(loc.Booth) end
    end
    local center = GetExactFarmPromptPosition(crop) or loc.Farm
    local park = Vector3.new(center.X + 4.5, GetGroundLevel(center.X + 4.5, center.Z + 4.5, center.Y), center.Z + 4.5)
    DriveCarTo(park, check)
    task.wait(2.0)
    ExitCarNaturally(myCar)
    task.wait(0.3)
    local standPos = GetFarmStandingSpot(center)
    SmoothWalkTo(standPos, 6, check, 1.2)
    task.wait(0.2)
    if root then
        local gy = GetGroundLevel(standPos.X, standPos.Z, center.Y)
        root.CFrame = CFrame.lookAt(Vector3.new(standPos.X, gy + 2.2, standPos.Z), Vector3.new(center.X, gy + 2.2, center.Z))
        root.AssemblyLinearVelocity = Vector3.zero
    end
    task.wait(1.5)
    TriggerFarmPromptDirectly(crop)
    task.wait(1.5)
    local farmT = os.clock()
    while cur < target do
        if isAutoEatAndDrinkEnabled and not isConsumingItem then
            if GetPlayerHunger() <= 75 or GetPlayerEnergy() <= 75 then
                CancelGameFarm(); task.wait(0.3)
                CheckAndAutoEat(); task.wait(0.3)
                TriggerFarmPromptDirectly(crop); task.wait(1.2)
                farmT = os.clock()
            end
        end
        if check and not check() then break end
        if os.clock() - farmT > 180 then break end
        GrantAntiXGrace(15)
        local n = GetPlayerInventoryCount(crop)
        if n > cur then cur = n; farmT = os.clock()
        elseif (os.clock() - farmT > 15) and n == cur then
            TriggerFarmPromptDirectly(crop); farmT = os.clock()
        end
        task.wait(0.5)
    end
    local booth = (loc and loc.Booth) or GetNearestCarBooth(root.Position)
    local car = SpawnCarAtBooth(booth) or EnsureCarAvailable(booth)
    if car then PressFToEnterCar(car) end
end

-- ==== CRAFT ====
local function GetCraft3Prompt()
    local cs = workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Crafting")
    local c3 = cs and cs:FindFirstChild("Craft_3")
    if c3 then return c3:FindFirstChildWhichIsA("ProximityPrompt", true) end
    return nil
end

local function CraftFoodAtStation(recipe, check)
    local food = TYPER_LOCATIONS.Food
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end
    if not GetPlayerVehicle() or not hum.Sit then EnsureCarAvailable() end
    local prompt = GetCraft3Prompt()
    local pos = prompt and prompt.Parent and prompt.Parent.Position or food.Crafting
    DriveCarTo(pos + Vector3.new(0, 0, 5), check)
    task.wait(0.2)
    if hum.Sit then hum.Sit = false; task.wait(0.2) end
    root.CFrame = CFrame.lookAt(Vector3.new(pos.X, pos.Y + 3, pos.Z + 2.5), pos)
    task.wait(0.15)
    prompt = prompt or GetCraft3Prompt()
    if prompt then TriggerPrompt(prompt) end
    local cg = PlayerGui:WaitForChild("Crafting", 4)
    local tw = os.clock()
    while os.clock() - tw < 3.0 do
        if cg and cg:FindFirstChild("Group") and cg.Group.Visible then break end
        if prompt then TriggerPrompt(prompt) end
        task.wait(0.3)
    end
    local function maxCraft()
        local b = GetPlayerInventoryCount("Bread")
        local c = GetPlayerInventoryCount("Catchup")
        local p = GetPlayerInventoryCount("Pig")
        local m = GetPlayerInventoryCount("Mango")
        local r = GetPlayerInventoryCount("Rice")
        if recipe == "Sandwish" then return math.min(math.floor(b/3), math.floor(c/2), math.floor(p/2)) end
        if recipe == "MangoRice" then return math.min(math.floor(m/2), math.floor(r/3)) end
        if recipe == "KangSom" then return math.min(math.floor(GetPlayerInventoryCount("Tomato")/2), math.floor(GetPlayerInventoryCount("Crab")/2)) end
        return 1
    end
    local n = maxCraft()
    if n <= 0 then
        if cg and cg:FindFirstChild("Group") then cg.Group.Visible = false end
        return
    end
    pcall(function()
        local rem = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes")
        if rem then local R = require(rem); R.Fire("_crafting", "Request", "Craft_3", recipe, n, false) end
    end)
    task.wait(10.5)
    pcall(function()
        local rem = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes")
        if rem then local R = require(rem); R.Fire("_crafting", "Complete", "Craft_3", recipe, n, false) end
    end)
    task.wait(0.3)
    if cg and cg:FindFirstChild("Group") then cg.Group.Visible = false end
    local car = GetNearbyPlayerVehicle(80) or EnsureCarAvailable(TOWN_CAR_SPAWN)
    if car then PressFToEnterCar(car) end
end

-- ==== BANANA ====
local function ProcessBananaAtStation(check)
    local food = TYPER_LOCATIONS.Food
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end
    if not GetPlayerVehicle() or not hum.Sit then EnsureCarAvailable() end
    local pBan = workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Process") and workspace.Systems.Process:FindFirstChild("Banana")
    local pos = pBan and pBan:FindFirstChildWhichIsA("BasePart", true) and pBan:FindFirstChildWhichIsA("BasePart", true).Position or food.BananaProcess
    DriveCarTo(pos + Vector3.new(0, 0, 5), check)
    task.wait(0.1)
    if hum.Sit then hum.Sit = false; task.wait(0.1) end
    root.CFrame = CFrame.lookAt(Vector3.new(pos.X, pos.Y + 3, pos.Z + 2.5), pos)
    task.wait(0.1)
    local prompt = pBan and pBan:FindFirstChildWhichIsA("ProximityPrompt", true) or FindPromptNear(root.Position, 15, nil)
    if prompt then TriggerPrompt(prompt) end
    local t = os.clock()
    while GetPlayerInventoryCount("Banana") >= 2 and os.clock() - t < 120 do
        if check and not check() then break end
        task.wait(3.2)
    end
    local car = GetNearbyPlayerVehicle(80) or EnsureCarAvailable(TOWN_CAR_SPAWN)
    if car then PressFToEnterCar(car) end
end

-- ==== SELL ====
local function GetEconomyMarketPosition()
    local sys = workspace:FindFirstChild("Systems")
    local containers = sys and {sys, workspace} or {workspace}
    for _, c in ipairs(containers) do
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("ProximityPrompt") and p.Enabled then
                local a = (p.ActionText or ""):lower()
                local o = (p.ObjectText or ""):lower()
                if a:find("econ") or o:find("econ") or p.Name:lower():find("econ") then
                    local par = p.Parent
                    local pos = (par:IsA("Attachment") and par.WorldPosition) or (par:IsA("BasePart") and par.Position)
                    if pos then return pos, p end
                end
            end
        end
    end
    local x, z = -462.0, 5324.7
    local y = GetGroundLevel(x, z, 17.5)
    return Vector3.new(x, y + 1.2, z), nil
end

local function SellAtEconomyMarket(check)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end
    local marketPos, direct = GetEconomyMarketPosition()
    marketPos = marketPos or TYPER_LOCATIONS.Economy.Market
    local myCar = GetPlayerVehicle()
    if not myCar or not hum.Sit then myCar = EnsureCarAvailable(TOWN_CAR_SPAWN) end
    if myCar then PressFToEnterCar(myCar) end
    DriveCarTo(marketPos, check)
    task.wait(0.3)
    ExitCarNaturally(myCar)
    local finalPos = marketPos
    local gy = GetGroundLevel(finalPos.X, finalPos.Z, finalPos.Y)
    root.CFrame = CFrame.lookAt(Vector3.new(finalPos.X + 2.5, gy + 2.2, finalPos.Z), finalPos)
    task.wait(0.2)
    local prompt = direct or FindPromptNear(root.Position, 25, nil)
    if prompt then TriggerPrompt(prompt) end
    task.wait(0.4)
    pcall(function()
        local rem = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes")
        if rem then local R = require(rem); R.Invoke("_economy", "SellAll"); R.Fire("_economy", "SellAll") end
    end)
    task.wait(1.0)
    if isAutoEatAndDrinkEnabled then
        if GetPlayerHunger() <= 75 or GetPlayerEnergy() <= 75 then AutoEatThenDrink(95) end
    end
    local car = GetNearbyPlayerVehicle(80) or EnsureCarAvailable(TOWN_CAR_SPAWN)
    if car then PressFToEnterCar(car) end
end

-- ==== FISHING ====
local FISHING_PARKING = Vector3.new(-902.46, 3.41, 2964.32)
local FISHING_SPOT = Vector3.new(-972.12, -0.87, 2926.62)
local FISHING_LOOK = FISHING_SPOT + Vector3.new(-0.25, 0, -0.97) * 20
local BAIT_SHOP = Vector3.new(-949.31, 16.57, 4861.12)
local isAutoFishingEnabled = false
local fishingThread = nil
local fishingPlatform = nil

local function EnsureFishingPlatform(pos)
    if not fishingPlatform or not fishingPlatform.Parent then
        local p = Instance.new("Part")
        p.Name = "NEXUS_FishingPlatform"
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

local function GetFishingRod()
    local char = LocalPlayer.Character
    local bp = LocalPlayer:FindFirstChild("Backpack")
    for _, n in ipairs({"FishingRodV3","FishingRodV2","FishingRod"}) do
        local t = char and char:FindFirstChild(n)
        if t and t:IsA("Tool") then return t end
        t = bp and bp:FindFirstChild(n)
        if t and t:IsA("Tool") then return t end
    end
    return nil
end

local function EquipFishingRod()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if not char or not hum then return nil end
    local rod = GetFishingRod()
    if rod and rod.Parent == char then return rod end
    if rod and rod.Parent == bp then hum:EquipTool(rod); task.wait(0.3); return rod end
    pcall(function() UseItem("FishingRod") end)
    task.wait(0.4)
    rod = GetFishingRod()
    if rod and rod.Parent == bp then hum:EquipTool(rod); task.wait(0.2) end
    return rod
end

local function SolveFishingMinigame()
    local pgui = LocalPlayer:FindFirstChild("PlayerGui")
    local fg = pgui and pgui:FindFirstChild("FishingGame")
    if not fg or not fg.Parent then return false end
    local mg = fg:FindFirstChild("Minigame")
    if not mg then return false end
    local holding = false
    local t0 = os.clock()
    local conn
    conn = RunService.RenderStepped:Connect(function()
        if not isAutoFishingEnabled or not fg or not fg.Parent then
            if holding and VirtualInputManager then pcall(function() VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game) end) end
            if conn then conn:Disconnect() end
            return
        end
        local fish = mg:FindFirstChild("Fish")
        local gameF = mg:FindFirstChild("Game")
        local point = gameF and gameF:FindFirstChild("Point")
        if fish and point and VirtualInputManager then
            local fc = fish.AbsolutePosition.Y + fish.AbsoluteSize.Y * 0.5
            local pc = point.AbsolutePosition.Y + point.AbsoluteSize.Y * 0.5
            if fc < pc - 4 then
                if not holding then holding = true; pcall(function() VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game) end) end
            elseif fc > pc + 4 then
                if holding then holding = false; pcall(function() VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game) end) end
            end
        end
    end)
    while fg and fg.Parent and isAutoFishingEnabled and os.clock() - t0 < 30 do
        task.wait(0.05)
        fg = pgui:FindFirstChild("FishingGame")
    end
    if conn then conn:Disconnect() end
    if holding and VirtualInputManager then pcall(function() VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game) end) end
    task.wait(2.0)
end

pcall(function()
    local pgui = LocalPlayer:FindFirstChild("PlayerGui")
    if pgui then
        pgui.ChildAdded:Connect(function(child)
            if child.Name == "FishingGame" and isAutoFishingEnabled then task.spawn(SolveFishingMinigame) end
        end)
    end
end)

local function StartAutoFishing()
    if fishingThread then return end
    isAutoFishingEnabled = true
    fishingThread = task.spawn(function()
        while isAutoFishingEnabled do
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local pd = LocalPlayer:FindFirstChild("PlayerData")
            if root and hum then
                local bait = (pd and (pd:GetAttribute("FishingBait") or pd:GetAttribute("Bait"))) or 0
                local fishCount = ((pd and pd:GetAttribute("Bettafish")) or 0) + ((pd and pd:GetAttribute("Anglerfish")) or 0)
                if bait <= 0 or fishCount >= 25 then
                    local car = GetNearbyPlayerVehicle(80) or EnsureCarAvailable(TOWN_CAR_SPAWN)
                    if car then PressFToEnterCar(car); DriveCarTo(BAIT_SHOP, function() return isAutoFishingEnabled end); ExitCarNaturally(car) end
                    SellAtEconomyMarket(function() return isAutoFishingEnabled end)
                    pcall(function()
                        local rem = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes")
                        if rem then local R = require(rem); R.Fire("_shop", "Buy", { FishingBait = 100 }, "Money") end
                    end)
                    car = GetNearbyPlayerVehicle(80) or EnsureCarAvailable(TOWN_CAR_SPAWN)
                    if car then PressFToEnterCar(car); DriveCarTo(FISHING_PARKING, function() return isAutoFishingEnabled end); ExitCarNaturally(car) end
                end
                if not isAutoFishingEnabled then break end
                if not root or (Vector3.new(root.Position.X,0,root.Position.Z) - Vector3.new(FISHING_SPOT.X,0,FISHING_SPOT.Z)).Magnitude > 3 then
                    SmoothWalkTo(FISHING_SPOT, 25, function() return isAutoFishingEnabled end, 2.5)
                end
                EnsureFishingPlatform(FISHING_SPOT)
                GrantAntiXGrace(20)
                local rod = char:FindFirstChild("FishingRod")
                if not rod then rod = EquipFishingRod() end
                if rod and rod.Parent == char then
                    root.CFrame = CFrame.lookAt(FISHING_SPOT, FISHING_LOOK)
                    root.AssemblyLinearVelocity = Vector3.zero
                    task.wait(0.2)
                    pcall(function() rod:Activate() end)
                    task.wait(1.0)
                    local pgui = LocalPlayer:FindFirstChild("PlayerGui")
                    local fg = pgui and pgui:FindFirstChild("FishingGame")
                    if fg then SolveFishingMinigame() end
                end
            end
            task.wait(0.2)
        end
        if fishingPlatform and fishingPlatform.Parent then fishingPlatform:Destroy(); fishingPlatform = nil end
        fishingThread = nil
    end)
end

local function StopAutoFishing()
    isAutoFishingEnabled = false
    if fishingPlatform and fishingPlatform.Parent then fishingPlatform:Destroy(); fishingPlatform = nil end
    fishingThread = nil
end

-- ==== WINDUI ====
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/refs/heads/main/dist/main.lua"))()
local Window = WindUI:CreateWindow({
    Title = "NEXUS HUB | TYPER TOWN",
    Icon = "rbxassetid://124905448303407",
    Author = "NEXUS",
    Folder = "NexusHub",
    ToggleKey = Enum.KeyCode.RightShift,
    HideSearchBar = true,
    NewElements = true,
    OpenButton = {
        Title = "NEXUS", Icon = "rbxassetid://124905448303407",
        Enabled = true, OnlyIcon = true, Draggable = false, OnlyMobile = false,
        Position = UDim2.new(0, 92, 1, -82), Scale = 0.9, CornerRadius = UDim.new(0, 16),
        StrokeThickness = 1, Color = ColorSequence.new(Color3.fromHex("#363941"), Color3.fromHex("#111318")),
    },
    Topbar = { Height = 44, ButtonsType = "Mac" },
    User = { Enabled = true, Anonymous = false,
        Callback = function()
            WindUI:Notify({ Title = "โปรไฟล์", Content = "@" .. LocalPlayer.Name, Icon = "user", Duration = 4 })
        end },
})

local ScreenBlur = Lighting:FindFirstChild("WindUIScreenBlur")
local BlurEnabled = true
if not ScreenBlur then
    ScreenBlur = Instance.new("BlurEffect")
    ScreenBlur.Name = "WindUIScreenBlur"
    ScreenBlur.Size = 0
    ScreenBlur.Parent = Lighting
end
local function SetBlur(on)
    BlurEnabled = on
    if ScreenBlur and ScreenBlur.Parent then
        TweenService:Create(ScreenBlur, TweenInfo.new(0.35, Enum.EasingStyle.Quint), { Size = on and 18 or 0 }):Play()
    end
end
SetBlur(true)
Window:OnClose(function() SetBlur(false) end)
Window:OnOpen(function() SetBlur(BlurEnabled) end)

Notify = function(data)
    data = data or {}
    WindUI:Notify({
        Title = data.Title or "NEXUS HUB",
        Content = data.Content or data.Text or "",
        Duration = data.Duration or 3,
        Icon = data.Icon,
    })
end

local Colors = { Green = Color3.fromHex("#35E878"), Blue = Color3.fromHex("#67E8F9"), Yellow = Color3.fromHex("#F5C46B") }

local Tabs = {
    Main = Window:Tab({ Title = "ฟาร์มหลัก", Icon = "solar:repeat-bold-duotone", IconColor = Colors.Green, IconShape = "Square", Border = true }),
    Individual = Window:Tab({ Title = "ฟาร์มเดี่ยว", Icon = "solar:leaf-bold-duotone", IconColor = Colors.Green, IconShape = "Square", Border = true }),
    Fishing = Window:Tab({ Title = "ตกปลา", Icon = "solar:fish-bold-duotone", IconColor = Colors.Blue, IconShape = "Square", Border = true }),
    Vehicle = Window:Tab({ Title = "รถ", Icon = "solar:wheel-bold", IconColor = Colors.Yellow, IconShape = "Square", Border = true }),
    Settings = Window:Tab({ Title = "ตั้งค่า", Icon = "solar:settings-bold-duotone", IconColor = Colors.Yellow, IconShape = "Square", Border = true }),
}

local MainSec = Tabs.Main:Section({ Title = "กิน/ดื่มอัตโนมัติ", Box = true, BoxBorder = true, Opened = true })
local LoopSec = Tabs.Main:Section({ Title = "ลูปทำอาหารและขาย", Box = true, BoxBorder = true, Opened = true })
local IndiSec = Tabs.Individual:Section({ Title = "เลือกพืช", Box = true, BoxBorder = true, Opened = true })
local IndiRunSec = Tabs.Individual:Section({ Title = "ควบคุม", Box = true, BoxBorder = true, Opened = true })
local FishSec = Tabs.Fishing:Section({ Title = "🎣 ตกปลา", Box = true, BoxBorder = true, Opened = true })
local HopSec = Tabs.Settings:Section({ Title = "🚨 Auto Hop", Box = true, BoxBorder = true, Opened = true })
local SetSec = Tabs.Settings:Section({ Title = "การแสดงผล", Box = true, BoxBorder = true, Opened = true })

-- Manage session
local CurrentSession = 0
local CurrentKey = nil
local isUnloaded = false
local FarmControls = {}

local function RequestSession(key)
    CurrentSession = CurrentSession + 1
    local thisSession = CurrentSession
    CurrentKey = key
    task.spawn(function()
        for k, ctrl in pairs(FarmControls) do
            if k ~= key and ctrl and ctrl.SetValue then
                pcall(function() ctrl:SetValue(false) end)
            end
        end
    end)
    return function() return CurrentSession == thisSession and CurrentKey == key end
end

local function StopSession(key)
    if CurrentKey == key then
        CurrentSession = CurrentSession + 1
        CurrentKey = nil
    end
end

local function AddFarmToggle(section, opts)
    local h = { Value = opts.Value == true, Element = nil }
    local cnt = 0
    h.Element = section:Toggle({
        Title = opts.Title, Desc = opts.Desc, Value = h.Value,
        Callback = function(v)
            cnt = cnt + 1
            h.Value = v == true
            if opts.Callback then opts.Callback(h.Value) end
        end,
    })
    function h:SetValue(v)
        v = v == true
        if self.Value == v then return end
        local before = cnt
        if self.Element and self.Element.Set then pcall(function() self.Element:Set(v) end) end
        if cnt == before then
            self.Value = v
            if opts.Callback then opts.Callback(v) end
        end
    end
    return h
end

-- ===== Main =====
MainSec:Toggle({
    Title = "ออโต้กินข้าวและกาแฟ",
    Desc = "กิน/ดื่มเมื่อ Hunger/Energy ≤ 75%",
    Value = true,
    Callback = function(v) isAutoEatAndDrinkEnabled = v end,
})

-- Farm Loops
local function MakeFarmLoop(key, title, desc, crops, craftFn)
    FarmControls[key] = AddFarmToggle(LoopSec, {
        Title = title, Desc = desc, Value = false,
        Callback = function(v)
            if v then
                local check = RequestSession(key)
                task.spawn(function()
                    local firstRun = true
                    while check() do
                        local needFarm = false
                        for _, c in ipairs(crops) do
                            if GetPlayerInventoryCount(c) < 60 then needFarm = true; break end
                        end
                        if needFarm then
                            if firstRun then WarpToTownAndSpawnCar(); firstRun = false
                            else
                                local car = GetPlayerVehicle()
                                if not car then
                                    local r = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                                    if r then EnsureCarAvailable(GetNearestCarBooth(r.Position)) end
                                else PressFToEnterCar(car) end
                            end
                            if not check() then break end
                            for _, c in ipairs(crops) do
                                if GetPlayerInventoryCount(c) < 60 then
                                    HarvestSingleCrop(c, 60, check)
                                    if not check() then break end
                                end
                            end
                            if not check() then break end
                        end
                        craftFn(check)
                        if not check() then break end
                        SellAtEconomyMarket(check)
                        if not check() then break end
                        local returnCar = GetPlayerVehicle() or EnsureCarAvailable(TOWN_CAR_SPAWN)
                        if returnCar then PressFToEnterCar(returnCar); DriveCarTo(TYPER_LOCATIONS[crops[1]].Farm, check) end
                        task.wait(1.0)
                    end
                end)
            else StopSession(key) end
        end,
    })
end

MakeFarmLoop("Sandwich", "ลูปแซนวิช", "Bread + Catchup + Pig → ขาย", {"Bread","Catchup","Pig"},
    function(c) CraftFoodAtStation("Sandwish", c) end)
MakeFarmLoop("MangoRice", "ลูปข้าวมันมะม่วง", "Mango + Rice → ขาย", {"Mango","Rice"},
    function(c) CraftFoodAtStation("MangoRice", c) end)
MakeFarmLoop("BananaPack", "ลูปกล้วยแพ็ค", "Banana → Process → ขาย", {"Banana"},
    function(c) ProcessBananaAtStation(c) end)
MakeFarmLoop("KangSom", "ลูปแกงส้ม", "Tomato + Crab → ขาย", {"Tomato","Crab"},
    function(c) CraftFoodAtStation("KangSom", c) end)

-- ===== Individual =====
local cropsList = {"Bread","Catchup","Pig","Mango","Rice","Tomato","Banana","Crab","Coconut"}
local cropDisplay = {
    Bread="Bread (ขนมปัง)", Catchup="Catchup (ซอส)", Pig="Pig (หมู)",
    Mango="Mango (มะม่วง)", Rice="Rice (ข้าว)", Tomato="Tomato (มะเขือเทศ)",
    Banana="Banana (กล้วย)", Crab="Crab (ปู)", Coconut="Coconut (มะพร้าว)",
}
local cropDropdown = {}
for _, c in ipairs(cropsList) do table.insert(cropDropdown, cropDisplay[c]) end
local selectedCrop = "Bread"

IndiSec:Dropdown({
    Title = "🌾 เลือกพืช",
    Values = cropDropdown,
    Value = "Bread (ขนมปัง)",
    Callback = function(v)
        local k = string.match(v, "^(%a+)")
        if k and TYPER_LOCATIONS[k] then selectedCrop = k end
    end,
})

FarmControls["Individual"] = AddFarmToggle(IndiRunSec, {
    Title = "🚀 เริ่มฟาร์มเดี่ยว", Value = false,
    Callback = function(v)
        if v then
            local crop = selectedCrop
            local check = RequestSession("Individual")
            task.spawn(function()
                local firstRun = true
                while check() do
                    local loc = TYPER_LOCATIONS[crop]
                    if not loc then break end
                    if firstRun then
                        local c = WarpToTownAndSpawnCar()
                        if not c then c = EnsureCarAvailable(TOWN_CAR_SPAWN) end
                        if c then PressFToEnterCar(c) end
                        firstRun = false
                    else
                        local c = GetPlayerVehicle() or EnsureCarAvailable(TOWN_CAR_SPAWN)
                        if c then PressFToEnterCar(c) end
                    end
                    if not check() then break end
                    HarvestSingleCrop(crop, 60, check)
                    if not check() then break end
                    SellAtEconomyMarket(check)
                    if not check() then break end
                    task.wait(1.0)
                end
            end)
        else StopSession("Individual") end
    end,
})

-- ===== Fishing =====
FishSec:Toggle({
    Title = "เริ่มออโต้ตกปลา",
    Desc = "เบิกรถ → ซื้อเหยื่อ → ตกปลา → ขาย",
    Value = false,
    Callback = function(v) if v then StartAutoFishing() else StopAutoFishing() end end,
})

-- ===== Hop =====
HopSec:Toggle({
    Title = "ย้ายเซิร์ฟหนีเมื่อมีคนใกล้",
    Desc = "Auto Server Hop",
    Value = true,
    Callback = function(v) isAutoHopOnPlayerNearbyEnabled = v end,
})
HopSec:Slider({
    Title = "ระยะตรวจจับ (studs)",
    Step = 5,
    Value = { Min = 20, Max = 250, Default = 60 },
    Callback = function(v) autoHopDistance = math.clamp(math.round(v), 20, 250) end,
})
HopSec:Button({
    Title = "🚨 ย้ายเซิร์ฟเวอร์ทันที",
    Callback = function() HopServer("กดด้วยตนเอง") end,
})

-- ===== Vehicle =====
Tabs.Vehicle:Slider({
    Title = "🚗 ความเร็วรถ",
    Desc = "10-500 studs/s",
    Step = 1,
    Value = { Min = 10, Max = 500, Default = 200 },
    Callback = function(v) VehicleDriveSpeed = math.clamp(math.round(v), 10, 500) end,
})

-- ===== Settings =====
SetSec:Toggle({
    Title = "เบลอพื้นหลัง",
    Value = true,
    Callback = function(v) SetBlur(v) end,
})
SetSec:Button({ Title = "จัดกลางจอ", Callback = function() Window:SetToTheCenter() end })

Tabs.Settings:Section({ Title = "ปิดสคริปต์", Box = true, BoxBorder = true, Opened = false }):Button({
    Title = "🔴 ปิดสคริปต์และลบ UI",
    Callback = function()
        isUnloaded = true
        StopAutoFishing()
        if Window and Window.Destroy then Window:Destroy() end
    end,
})

-- Auto Eat Loop
task.spawn(function()
    while not isUnloaded do
        task.wait(3.0)
        if isAutoEatAndDrinkEnabled and not isConsumingItem then
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum and not hum.Sit then CheckAndAutoEat() end
        end
    end
end)

Tabs.Main:Select()
Window:Open()
Notify({ Title = "NEXUS HUB v4.4 พร้อมใช้งาน", Content = "ฟาร์ม + ตกปลา + Auto Hop", Duration = 5 })

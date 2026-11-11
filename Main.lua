-- =====================================
-- MARVENRIZ HUB : MAIN (FULL SYSTEM)
-- =====================================

local Loading = loadstring(game:HttpGet("https://raw.githubusercontent.com/14thx/Aslwoll/main/Loading.lua"))()
Loading.Start()
Loading.SetProgress(100, "โหลดเสร็จสมบูรณ์!")
task.wait(0.6)
Loading.Hide()

local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/14thx/Aslwoll/main/RayVinzUI.lua"))()
UI:LoadLucide()

-- ⭐ 1. ผูกระบบ AntiSpy (สแกนหา Remote Spy)
pcall(function()
    if UI.AntiSpy then
        UI:AntiSpy({
            Interval = 2,                 
            RemoveGui = true,             
            Kick = false,                 
            DetectHooks = false,          
            Callback = function(reasons)
                UI:Notify({ Title = "⚠️ Security Alert", Content = "ตรวจพบ Spy: " .. table.concat(reasons, ", "), Type = "Warning" })
            end
        })
    end
end)

-- ⭐ 2. ผูกระบบ Anti-AFK (กันเตะ 20 นาที)
pcall(function()
    if UI.AntiAFK then
        UI:AntiAFK(true) 
    end
end)

-- ⭐ 3. ผูกระบบ ReExecute (วาร์ปแล้วรันสคริปต์ใหม่)
pcall(function()
    if UI.ReExecuteOnTeleport then
        local myScriptUrl = "https://raw.githubusercontent.com/14thx/Aslwoll/main/Main.lua" 
        UI:ReExecuteOnTeleport('loadstring(game:HttpGet("' .. myScriptUrl .. '"))()')
    end
end)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ANTI-KICK
pcall(function()
    if hookmetamethod then
        local oldNm
        oldNm = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if (method == "Kick" or method == "kick") and (self == LocalPlayer or self == Players) then
                return nil
            end
            return oldNm(self, ...)
        end))
    end
end)

-- DATA
local TYPER_LOCATIONS = {
    Bread = { Farm = Vector3.new(828.31, 11.21, 4817.85) },
    Catchup = { Farm = Vector3.new(1803.05, 12.65, 4236.79) },
    Pig = { Farm = Vector3.new(268.61, 28.74, -1513.65) },
    Mango = { Farm = Vector3.new(-1862.26, 17.33, 535.43) },
    Rice = { Farm = Vector3.new(-128.87, 11.02, 78.51) },
    Tomato = { Farm = Vector3.new(-2319.61, 27.21, -1229.19) },
    Banana = { Farm = Vector3.new(-1545.12, 28.80, -1126.87) },
    Crab = { Farm = Vector3.new(1400.27, 28.69, 648.22) },
    Coconut = { Farm = Vector3.new(-1333.68, 10.87, 4376.67) },
    Corn = { Farm = Vector3.new(-264.44, 11.95, 4527.12) },
    Egg = { Farm = Vector3.new(-1799.30, 10.98, 4492.20) },
    Milk = { Farm = Vector3.new(-998.66, 11.23, 4831.62) },
    Sugarcane = { Farm = Vector3.new(-1922.31, 13.06, 3962.32) },
    Rock = { Farm = Vector3.new(-4138.03, 29.88, -1286.63), Process = Vector3.new(-935.29, 6.93, 6786.66) },
    Svibranium = { Farm = Vector3.new(2723.67, 28.51, -236.17), Process = Vector3.new(-927.35, 6.93, 6763.02) },
    Food = { Crafting = Vector3.new(3442.48, 56.40, 3925.24), BananaProcess = Vector3.new(3429.20, 56.80, 3911.80) },
    Economy = { Market = Vector3.new(-462.0, 18.0, 5324.7) },
    Vault = Vector3.new(-1.98, 26.54, 8632.61),
    Fishing = { Spot = Vector3.new(-955.06, -2.65, 2907.18) }
}

local CurrentFarmSessionId = 0
local CurrentActiveFarmKey = nil
local FarmToggleControls = {}
local isAutoSellEnabled = true
local isAutoFishingEnabled = false
local fishingThread = nil
local isSelling = false           
local lastSellTime = 0            
local SELL_COOLDOWN = 20          

-- CORE
local function Notify(Title, Content, Type)
    pcall(function() UI:Notify({ Title = Title, Content = Content, Type = Type or "Info", Duration = 3.0 }) end)
end

local function RequestFarmSession(farmKey)
    CurrentFarmSessionId = CurrentFarmSessionId + 1
    local thisSession = CurrentFarmSessionId
    CurrentActiveFarmKey = farmKey
    task.spawn(function()
        for key, toggleObj in pairs(FarmToggleControls) do
            if key ~= farmKey and toggleObj and toggleObj.SetValue and toggleObj.Value then
                pcall(function() toggleObj:SetValue(false) end)
            end
        end
    end)
    return function() return CurrentFarmSessionId == thisSession and CurrentActiveFarmKey == farmKey end
end

local function StopFarmSession(farmKey)
    if CurrentActiveFarmKey == farmKey then
        CurrentFarmSessionId = CurrentFarmSessionId + 1
        CurrentActiveFarmKey = nil
    end
end

local function GetPlayerInventoryCount(itemName)
    local pd = LocalPlayer:FindFirstChild("PlayerData")
    if pd then
        local c = pd:GetAttribute(itemName)
        if typeof(c) == "number" then return c end
    end
    return 0
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

local function FindPromptNear(centerPos, maxDist, keyword)
    maxDist = maxDist or 30
    local closest, closestDist = nil, maxDist
    for _, p in ipairs(workspace:GetDescendants()) do
        if p:IsA("ProximityPrompt") and p.Enabled then
            local part = p.Parent
            if part and part:IsA("BasePart") then
                local d = (part.Position - centerPos).Magnitude
                if d <= closestDist then
                    if not keyword or (p.ActionText:lower():find(keyword) or p.ObjectText:lower():find(keyword)) then
                        closest = p
                        closestDist = d
                    end
                end
            end
        end
    end
    return closest
end

-- 🛸 GHOST TELEPORT (NoClip + Anchored + Tween นิ่งๆ)
local function GhostTeleport(targetPos, shouldContinueCheck)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return false end
    if shouldContinueCheck and not shouldContinueCheck() then return false end

    -- ⭐ 1. เปิด NoClip (ทะลุทุกอย่าง)
    local noclipParts = {}
    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("BasePart") then
            v.CanCollide = false
            table.insert(noclipParts, v)
        end
        if v:IsA("Decal") or v:IsA("Texture") then 
            v.LocalTransparencyModifier = 1 
        end
    end
    
    -- ⭐ 2. ล็อคฟิสิกส์ (ไม่ร่วงพื้น + ไม่ขึ้นลง)
    hrp.Anchored = true
    hum.WalkSpeed = 0
    hum.JumpPower = 0
    
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {char}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    local rayResult = workspace:Raycast(targetPos + Vector3.new(0, 50, 0), Vector3.new(0, -100, 0), rayParams)
    local groundY = rayResult and rayResult.Position.Y or targetPos.Y
    
    local finalPos = CFrame.new(targetPos.X, groundY + 3, targetPos.Z)
    
    -- ⭐ 3. Tween ตำแหน่ง (นิ่งสนิท)
    local dist = (hrp.Position - finalPos.Position).Magnitude
    local travelTime = math.clamp(dist / 20, 2.0, 10.0) 
    
    local tw = TweenService:Create(hrp, TweenInfo.new(travelTime, Enum.EasingStyle.Linear), { CFrame = finalPos })
    tw:Play()
    tw.Completed:Wait()
    
    hrp.CFrame = finalPos
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
    
    -- ⭐ 4. ปลดล็อค + คืนค่า CanCollide
    hrp.Anchored = false
    hum.WalkSpeed = 16
    hum.JumpPower = 50
    
    for _, v in ipairs(noclipParts) do
        if v and v.Parent then
            pcall(function() v.CanCollide = true end)
        end
    end
    
    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("Decal") or v:IsA("Texture") then 
            v.LocalTransparencyModifier = 0 
        end
    end
    
    task.wait(0.5)
    return true
end

-- 🌾 HARVEST
local function HarvestSingleCrop(cropName, targetAmount, shouldContinueCheck)
    local curCount = GetPlayerInventoryCount(cropName)
    if curCount >= targetAmount then return end
    local locData = TYPER_LOCATIONS[cropName]
    if not locData then return end
    
    local farmPos = locData.Farm
    local approachPos = Vector3.new(farmPos.X + 10, farmPos.Y, farmPos.Z + 10)
    
    GhostTeleport(approachPos, shouldContinueCheck)
    if shouldContinueCheck and not shouldContinueCheck() then return end
    
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    
    -- ⭐ ยืนนิ่ง 15 วิ หลังลอยถึง
    if hum then
        local oldSpeed = hum.WalkSpeed
        hum.WalkSpeed = 0 
        task.wait(15.0)  
        hum.WalkSpeed = oldSpeed 
    end
    if shouldContinueCheck and not shouldContinueCheck() then return end
    
    local farmTimeout = os.clock()
    while curCount < targetAmount do
        if shouldContinueCheck and not shouldContinueCheck() then break end
        if os.clock() - farmTimeout > 180 then break end
        
        char = LocalPlayer.Character
        hum = char and char:FindFirstChildOfClass("Humanoid")
        hrp = char and char:FindFirstChild("HumanoidRootPart")
        
        local targetPrompt = nil
        local targetPos = nil
        local farmSys = workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Farm")
        
        if farmSys then
            local cropFolder = farmSys:FindFirstChild(cropName)
            if cropFolder then
                for _, desc in ipairs(cropFolder:GetDescendants()) do
                    if desc:IsA("ProximityPrompt") and desc.Enabled then
                        local prParent = desc.Parent
                        local pPos = (prParent:IsA("Attachment") and prParent.WorldPosition)
                                  or (prParent:IsA("BasePart") and prParent.Position)
                                  or (prParent.Parent and prParent.Parent:IsA("BasePart") and prParent.Parent.Position)
                        local action = (desc.ActionText or ""):lower()
                        if pPos and not action:find("spawn") and not action:find("car") then
                            targetPrompt = desc
                            targetPos = pPos
                            break
                        end
                    end
                end
            end
        end

        if not targetPrompt then
            targetPrompt = FindPromptNear(locData.Farm, 50)
            if targetPrompt then targetPos = targetPrompt.Parent.Position end
        end
        
        if targetPrompt and targetPos and hum and hrp then
            hum.WalkSpeed = 8 -- เดินช้า
            
            hum:MoveTo(targetPos)
            local walkTime = 0
            while (hrp.Position - targetPos).Magnitude > 6 and walkTime < 8 do
                task.wait(0.1)
                walkTime = walkTime + 0.1
                if walkTime % 1 == 0 then hum.Jump = true end
            end
            
            -- ⭐ ยืนนิ่ง 4 วิ ก่อนกด
            hum:MoveTo(hrp.Position)
            local oldSpeed = hum.WalkSpeed
            hum.WalkSpeed = 0 
            task.wait(4.0)  
            hum.WalkSpeed = oldSpeed 
            
            TriggerPrompt(targetPrompt)
        else
            warn("❌ [Farm] หาปุ่มฟาร์มไม่เจอ!")
        end
        
        task.wait(6.0) -- รอหลังกด
        
        local newCount = GetPlayerInventoryCount(cropName)
        if newCount > curCount then
            curCount = newCount
            farmTimeout = os.clock()
        elseif (os.clock() - farmTimeout > 15) then
            if targetPrompt then TriggerPrompt(targetPrompt) end
            farmTimeout = os.clock()
        end
    end
end

-- 💰 SELL
local function SellAtEconomyMarket(shouldContinueCheck)
    if isSelling then return end
    local now = os.clock()
    if now - lastSellTime < SELL_COOLDOWN then return end
    
    isSelling = true
    lastSellTime = now
    
    local success, err = pcall(function()
        local marketPos = TYPER_LOCATIONS.Economy.Market
        GhostTeleport(marketPos, shouldContinueCheck)
        if shouldContinueCheck and not shouldContinueCheck() then return end
        
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        
        -- ⭐ ยืนนิ่ง 15 วิ
        if hum then
            local oldSpeed = hum.WalkSpeed
            hum.WalkSpeed = 0
            task.wait(15.0)
            hum.WalkSpeed = oldSpeed
        end
        if shouldContinueCheck and not shouldContinueCheck() then return end
        
        local prompt = FindPromptNear(marketPos, 50, "econ") or FindPromptNear(marketPos, 50, "sell") or FindPromptNear(marketPos, 50)
        if prompt then
            char = LocalPlayer.Character
            hum = char and char:FindFirstChildOfClass("Humanoid")
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hum and hrp then
                hum:MoveTo(prompt.Parent.Position)
                local walkTime = 0
                while (hrp.Position - prompt.Parent.Position).Magnitude > 4 and walkTime < 5 do
                    task.wait(0.1) 
                    walkTime = walkTime + 0.1
                end
                
                -- ⭐ ยืนนิ่ง 4 วิ ก่อนกด
                hum:MoveTo(hrp.Position)
                local oldSpeed = hum.WalkSpeed
                hum.WalkSpeed = 0
                task.wait(4.0) 
                hum.WalkSpeed = oldSpeed
            end
            TriggerPrompt(prompt)
        end
        
        task.wait(1.5)
        
        pcall(function()
            local remCore = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes")
            if remCore then
                local Remotes_m = require(remCore)
                Remotes_m.Invoke("_economy", "SellAll")
                task.wait(0.5)
                Remotes_m.Fire("_economy", "SellAll")
            end
        end)
        
        task.wait(2.0)
        
        pcall(function()
            local eg = PlayerGui:FindFirstChild("Economy") or PlayerGui:FindFirstChild("Ecconomy")
            if eg and eg:FindFirstChild("Group") then
                local main = eg.Group:FindFirstChild("Main") or eg.Group
                local sellBtn = main:FindFirstChild("Sell_All", true) or main:FindFirstChild("SellAll", true)
                if not sellBtn then
                    for _, b in ipairs(main:GetDescendants()) do
                        if b:IsA("GuiButton") and (b.Name:lower():find("sell") or (b:IsA("TextButton") and b.Text:lower():find("sell"))) then sellBtn = b break end
                    end
                end
                if sellBtn and sellBtn:IsA("GuiButton") then if firesignal then firesignal(sellBtn.MouseButton1Click) else sellBtn:Activate() end end
                task.wait(1.5)
                local exitBtn = main:FindFirstChild("Exit", true) or main:FindFirstChild("Close", true)
                if exitBtn then if firesignal then firesignal(exitBtn.MouseButton1Click) else exitBtn:Activate() end end
                eg.Group.Visible = false
            end
        end)
        task.wait(2)
    end)

    isSelling = false
end

-- 🍳 CRAFT
local function CraftFoodAtStation(recipeName, shouldContinueCheck)
    local exactCraftPos = TYPER_LOCATIONS.Food.Crafting
    GhostTeleport(exactCraftPos, shouldContinueCheck)
    if shouldContinueCheck and not shouldContinueCheck() then return end
    
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    
    if hum then
        local oldSpeed = hum.WalkSpeed
        hum.WalkSpeed = 0
        task.wait(15.0)
        hum.WalkSpeed = oldSpeed
    end
    
    local prompt = FindPromptNear(exactCraftPos, 30)
    if prompt then
        char = LocalPlayer.Character
        hum = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hum and hrp then
            hum:MoveTo(prompt.Parent.Position)
            local walkTime = 0
            while (hrp.Position - prompt.Parent.Position).Magnitude > 6 and walkTime < 5 do
                task.wait(0.1) walkTime = walkTime + 0.1
            end
            
            hum:MoveTo(hrp.Position)
            local oldSpeed = hum.WalkSpeed
            hum.WalkSpeed = 0
            task.wait(4.0)
            hum.WalkSpeed = oldSpeed
        end
        TriggerPrompt(prompt)
    end
    task.wait(5)
    
    local cg = PlayerGui:FindFirstChild("Crafting")
    if cg and cg:FindFirstChild("Group") then
        pcall(function() cg.Group.Visible = true end)
        local mainFrame = cg.Group:FindFirstChild("Main")
        if mainFrame then
            local amtBox = mainFrame:FindFirstChild("Function") and mainFrame.Function:FindFirstChild("Amount") and mainFrame.Function.Amount:FindFirstChild("Amount")
            if amtBox and amtBox:IsA("TextBox") then amtBox.Text = "60" task.wait(0.1) end
            local craftBtn = mainFrame:FindFirstChild("Button") and mainFrame.Button:FindFirstChild("Craft")
            if craftBtn then if firesignal then firesignal(craftBtn.MouseButton1Click) else craftBtn:Activate() end end
        end
    end
    task.wait(10)
end

-- 🍌 PROCESS BANANA
local function ProcessBananaAtStation(shouldContinueCheck)
    local exactBanPos = TYPER_LOCATIONS.Food.BananaProcess
    GhostTeleport(exactBanPos, shouldContinueCheck)
    if shouldContinueCheck and not shouldContinueCheck() then return end
    
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    
    if hum then
        local oldSpeed = hum.WalkSpeed
        hum.WalkSpeed = 0
        task.wait(15.0)
        hum.WalkSpeed = oldSpeed
    end
    
    local prompt = FindPromptNear(exactBanPos, 30)
    if prompt then
        char = LocalPlayer.Character
        hum = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hum and hrp then
            hum:MoveTo(prompt.Parent.Position)
            local walkTime = 0
            while (hrp.Position - prompt.Parent.Position).Magnitude > 6 and walkTime < 5 do
                task.wait(0.1) walkTime = walkTime + 0.1
            end
            
            hum:MoveTo(hrp.Position)
            local oldSpeed = hum.WalkSpeed
            hum.WalkSpeed = 0
            task.wait(4.0)
            hum.WalkSpeed = oldSpeed
        end
        TriggerPrompt(prompt)
    end
    task.wait(5)
end

-- 🪨 PROCESS ORE
local function ProcessOreAtStation(oreName, requiredMin, shouldContinueCheck)
    local locData = TYPER_LOCATIONS[oreName]
    if not locData or not locData.Process then return end
    local exactProcPos = locData.Process
    
    GhostTeleport(exactProcPos, shouldContinueCheck)
    if shouldContinueCheck and not shouldContinueCheck() then return end
    
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    
    if hum then
        local oldSpeed = hum.WalkSpeed
        hum.WalkSpeed = 0
        task.wait(15.0)
        hum.WalkSpeed = oldSpeed
    end
    
    local prompt = FindPromptNear(exactProcPos, 30)
    if prompt then
        char = LocalPlayer.Character
        hum = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hum and hrp then
            hum:MoveTo(prompt.Parent.Position)
            local walkTime = 0
            while (hrp.Position - prompt.Parent.Position).Magnitude > 6 and walkTime < 5 do
                task.wait(0.1) walkTime = walkTime + 0.1
            end
            
            hum:MoveTo(hrp.Position)
            local oldSpeed = hum.WalkSpeed
            hum.WalkSpeed = 0
            task.wait(4.0)
            hum.WalkSpeed = oldSpeed
        end
        TriggerPrompt(prompt)
    end
    task.wait(5)
    
    local pFolder = workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Process") and workspace.Systems:FindFirstChild(oreName)
    if pFolder then
        local procPrompt = pFolder:FindFirstChildWhichIsA("ProximityPrompt", true)
        if procPrompt then 
            task.wait(15.0)
            TriggerPrompt(procPrompt) 
        end
    end
    task.wait(5)
end

-- 🏦 VAULT
local function DepositAllToVault(shouldContinueCheck)
    GhostTeleport(TYPER_LOCATIONS.Vault, shouldContinueCheck)
    if shouldContinueCheck and not shouldContinueCheck() then return end
    
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    
    if hum then
        local oldSpeed = hum.WalkSpeed
        hum.WalkSpeed = 0
        task.wait(15.0)
        hum.WalkSpeed = oldSpeed
    end
    
    local prompt = FindPromptNear(TYPER_LOCATIONS.Vault, 40)
    if prompt then
        char = LocalPlayer.Character
        hum = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hum and hrp then
            hum:MoveTo(prompt.Parent.Position)
            local walkTime = 0
            while (hrp.Position - prompt.Parent.Position).Magnitude > 6 and walkTime < 5 do
                task.wait(0.1) walkTime = walkTime + 0.1
            end
            
            hum:MoveTo(hrp.Position)
            local oldSpeed = hum.WalkSpeed
            hum.WalkSpeed = 0
            task.wait(4.0)
            hum.WalkSpeed = oldSpeed
        end
        TriggerPrompt(prompt)
    end
    
    task.wait(1.5)
    
    pcall(function()
        local remCore = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes")
        if remCore then
            local Remotes_m = require(remCore)
            local pData = LocalPlayer:FindFirstChild("PlayerData")
            if pData then
                for attrName, _ in pairs(pData:GetAttributes()) do
                    local count = GetPlayerInventoryCount(attrName)
                    if count > 0 then pcall(function() Remotes_m.Invoke("_vault_tx", "Deposit", attrName, count) end) task.wait(0.15) end
                end
            end
        end
    end)
    task.wait(2)
end

-- 🐟 FISHING (คงเดิม)
local function SolveFishingMinigame()
    local pgui = LocalPlayer:FindFirstChild("PlayerGui")
    local vim = game:GetService("VirtualInputManager")
    local fg = pgui and pgui:FindFirstChild("FishingGame")
    if not fg or not fg.Parent then return false end
    local mg = fg:FindFirstChild("Minigame")
    if not mg then return false end
    local isHolding = false
    local startTime = os.clock()
    local conn = RunService.RenderStepped:Connect(function()
        if not isAutoFishingEnabled or not fg or not fg.Parent then
            if isHolding then pcall(function() vim:SendKeyEvent(false, Enum.KeyCode.Space, false, game) end) isHolding = false end
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
                if not isHolding then isHolding = true pcall(function() vim:SendKeyEvent(true, Enum.KeyCode.Space, false, game) end) end
            elseif fishCenter > pointCenter + 4 then
                if isHolding then isHolding = false pcall(function() vim:SendKeyEvent(false, Enum.KeyCode.Space, false, game) end) end
            end
        end
    end)
    while fg and fg.Parent and isAutoFishingEnabled and (os.clock() - startTime < 30) do
        task.wait(0.05)
        fg = pgui:FindFirstChild("FishingGame")
    end
    if conn then conn:Disconnect() conn = nil end
    if isHolding then pcall(function() vim:SendKeyEvent(false, Enum.KeyCode.Space, false, game) end) isHolding = false end
    task.wait(3.0)
end

local function StartAutoFishing()
    if fishingThread then return end
    isAutoFishingEnabled = true
    fishingThread = task.spawn(function()
        Notify("NEXUS HUB", "🎣 เริ่มระบบตกปลา...", "Success")
        while isAutoFishingEnabled do
            GhostTeleport(TYPER_LOCATIONS.Fishing.Spot, function() return isAutoFishingEnabled end)
            if not isAutoFishingEnabled then break end
            
            local prompt = FindPromptNear(TYPER_LOCATIONS.Fishing.Spot, 30)
            if prompt then
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hum and hrp then
                    hum:MoveTo(prompt.Parent.Position)
                    local walkTime = 0
                    while (hrp.Position - prompt.Parent.Position).Magnitude > 6 and walkTime < 5 do
                        task.wait(0.1) walkTime = walkTime + 0.1
                    end
                    
                    hum:MoveTo(hrp.Position)
                    local oldSpeed = hum.WalkSpeed
                    hum.WalkSpeed = 0
                    task.wait(3.0) 
                    hum.WalkSpeed = oldSpeed
                end
                TriggerPrompt(prompt)
            end
            
            task.wait(3.0)
            
            local pgui = LocalPlayer:FindFirstChild("PlayerGui")
            local fg = pgui and pgui:FindFirstChild("FishingGame")
            if fg then SolveFishingMinigame() end
            task.wait(5)
        end
        fishingThread = nil
    end)
end

local function StopAutoFishing()
    isAutoFishingEnabled = false
    fishingThread = nil
    Notify("NEXUS HUB", "🛑 หยุดระบบตกปลา", "Warning")
end

-- UI
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
        pcall(function() Ping = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()) end)
        local Executor = "Unknown"
        if identifyexecutor then pcall(function() Executor = identifyexecutor() end) end
        StatsGrid.Set("FPS", FPS)
        StatsGrid.Set("Ping", Ping .. " ms")
        StatsGrid.Set("Executor", Executor)
        StatsGrid.Set("Players", #Players:GetPlayers())
        StatsGrid.Set("Time", os.date("%H:%M:%S"))
    end
end)

local Settings = Window:Tab({ Title = "ตั้งค่า", Icon = "settings" })
local SettingsSection = Settings:Section({ Title = "ตั้งค่าทั่วไป" })
SettingsSection:Toggle({
    Title = "ออโต้ กินอาหาร", Description = "กินอาหารอัตโนมัติ หากค่าต่ำกว่า 20",
    Default = true, Flag = "AutoEat",
    Callback = function(v) end
})
SettingsSection:Toggle({
    Title = "ออโต้ ขายไอเท็ม", Description = "ขายของอัตโนมัติเมื่อฟาร์มแล้วไอเท็มเต็ม",
    Default = true, Flag = "AutoSell",
    Callback = function(v) isAutoSellEnabled = v end
})

local Farm = Window:Tab({ Title = "ฟาร์ม", Icon = "sprout" })
local NormalFarm = Farm:Section({ Title = "ฟาร์มปกติ" })

NormalFarm:Dropdown({
    Title = "เลือกฟาร์ม",
    Options = {"Bread", "Catchup", "Pig", "Mango", "Rice", "Tomato", "Banana", "Crab", "Coconut", "Corn", "Egg", "Milk", "Sugarcane"},
    Default = "Bread", Flag = "NormalFarmType",
    Callback = function(v) _G.SelectedFarmItem = v end
})

local toggleAutoFarm = NormalFarm:Toggle({
    Title = "ออโต้ ฟาร์มไอเท็ม", Default = false, Flag = "AutoFarmItem",
    Callback = function(v)
        if v then
            local check = RequestFarmSession("FarmItemMaster")
            task.spawn(function()
                local crop = _G.SelectedFarmItem or "Bread"
                while check() do
                    isSelling = false
                    
                    local currentCount = GetPlayerInventoryCount(crop)
                    
                    if currentCount >= 60 then
                        if isAutoSellEnabled then SellAtEconomyMarket(check) end
                        task.wait(5.0) 
                    else
                        HarvestSingleCrop(crop, 60, check)
                        if not check() then break end
                        local afterFarmCount = GetPlayerInventoryCount(crop)
                        if afterFarmCount >= 60 then
                            if isAutoSellEnabled then SellAtEconomyMarket(check) end
                            task.wait(5.0)
                        end
                    end
                    
                    if not check() then break end
                    task.wait(1.0)
                end
            end)
        else
            StopFarmSession("FarmItemMaster")
        end
    end
})
FarmToggleControls["FarmItemMaster"] = toggleAutoFarm

local ProcessFarm = Farm:Section({ Title = "ฟาร์มโพสต์ (คราฟต์/แปรรูป)" })
ProcessFarm:Dropdown({
    Title = "เลือกของ",
    Options = {"Banana", "Mango", "Rice"},
    Default = "Banana", Flag = "ProcessFarmType",
    Callback = function(v) _G.SelectedProcessItem = v end
})

local toggleAutoProcess = ProcessFarm:Toggle({
    Title = "ออโต้ ฟาร์มโพสต์", Default = false, Flag = "AutoProcessFarm",
    Callback = function(v)
        if v then
            local check = RequestFarmSession("ProcessMaster")
            task.spawn(function()
                local crop = _G.SelectedProcessItem or "Banana"
                while check() do
                    if GetPlayerInventoryCount(crop) < 60 then HarvestSingleCrop(crop, 60, check) end
                    if not check() then break end
                    if crop == "Banana" then ProcessBananaAtStation(check)
                    elseif crop == "Mango" then CraftFoodAtStation("MangoRice", check)
                    elseif crop == "Rice" then CraftFoodAtStation("RiceKapaoMoo", check) end
                    if not check() then break end
                    if isAutoSellEnabled then SellAtEconomyMarket(check) end
                    task.wait(5.0)
                end
            end)
        else
            StopFarmSession("ProcessMaster")
        end
    end
})
FarmToggleControls["ProcessMaster"] = toggleAutoProcess

local MineFarm = Farm:Section({ Title = "ฟาร์มเหมือง (ขุด+แปรรูป+ฝาก)" })
MineFarm:Dropdown({
    Title = "เลือกเหมือง",
    Options = {"Rock", "Svibranium"},
    Default = "Rock", Flag = "MineFarmType",
    Callback = function(v) _G.SelectedMineItem = v end
})

local toggleAutoMine = MineFarm:Toggle({
    Title = "ออโต้ ฟาร์มเหมือง", Default = false, Flag = "AutoMineFarm",
    Callback = function(v)
        if v then
            local check = RequestFarmSession("MineMaster")
            task.spawn(function()
                local ore = _G.SelectedMineItem or "Rock"
                while check() do
                    HarvestSingleCrop(ore, 60, check)
                    if not check() then break end
                    ProcessOreAtStation(ore, ore == "Svibranium" and 4 or 2, check)
                    if not check() then break end
                    DepositAllToVault(check)
                    task.wait(5.0)
                end
            end)
        else
            StopFarmSession("MineMaster")
        end
    end
})
FarmToggleControls["MineMaster"] = toggleAutoMine

local Other = Window:Tab({ Title = "อื่นๆ", Icon = "ellipsis" })
local OtherSection = Other:Section({ Title = "ระบบตกปลา", Icon = "fish" })
OtherSection:Toggle({
    Title = "เริ่มออโต้ตกปลา (ลอย)", Default = false, Flag = "AutoFish",
    Callback = function(v)
        if v then StartAutoFishing() else StopAutoFishing() end
    end
})

local OtherSection2 = Other:Section({ Title = "ตัวละครผู้เล่น" })
OtherSection2:Toggle({ Title = "พลังงานไม่จำกัด", Default = false, Flag = "InfiniteEnergy", Callback = function(v) print("Infinite Energy:", v) end })

local Config = Window:Tab({ Title = "Config", Icon = "folder-cog" })
local ConfigSection = Config:Section({ Title = "CONFIG" })
ConfigSection:ConfigManager()

UI:Notify({ Title = "MarvenRiz Hub", Content = "ติดตั้งระบบ AntiSpy / Anti-AFK / Tween NoClip เรียบร้อย!", Type = "Success", Duration = 4 })

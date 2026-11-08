--// NEXUS HUB - UI (RELWX style) — วางต่อจาก NexusSystems.lua
--// ผูก Toggle/Slider/Button กับ Systems จาก NexusSystems

-- [วางโค้ด UI ของ RELWX จากข้อความก่อนหน้าที่นี่]
-- แทนที่ส่วน "ระบบหลักจาก 1.txt" ด้วย:

local Systems = loadstring(game:HttpGet("https://raw.githubusercontent.com/14thx/Aslwoll/main/NexusSystems.lua"))()
Systems.SetNotify(function(msg, ok) Toast(msg, ok) end)
Systems.SetConfig(Config)

-- ตัวอย่าง All-in-one
Toggle(AllIn, {
    key = "AutoSandwich",
    title = "ลูปแซนวิช",
    desc = "ขนมปัง + ซอส + หมู → แซนวิช → ขาย (วนลูป)",
    callback = function(v)
        if v then
            task.spawn(function()
                Systems.WarpToTown()
                while Config.AutoSandwich do
                    Systems.HarvestCrop("Bread", 60, function() return Config.AutoSandwich end)
                    Systems.HarvestCrop("Catchup", 60, function() return Config.AutoSandwich end)
                    Systems.HarvestCrop("Pig", 60, function() return Config.AutoSandwich end)
                    Systems.CraftFood("Sandwish", function() return Config.AutoSandwich end)
                    Systems.SellAll(function() return Config.AutoSandwich end)
                end
            end)
        end
    end,
})

Toggle(AllIn, {
    key = "AutoMangoRice",
    title = "ลูปข้าวมันมะม่วง",
    desc = "มะม่วง + ข้าว → ข้าวมันมะม่วง → ขาย",
    callback = function(v)
        if v then
            task.spawn(function()
                Systems.WarpToTown()
                while Config.AutoMangoRice do
                    Systems.HarvestCrop("Mango", 60, function() return Config.AutoMangoRice end)
                    Systems.HarvestCrop("Rice", 60, function() return Config.AutoMangoRice end)
                    Systems.CraftFood("MangoRice", function() return Config.AutoMangoRice end)
                    Systems.SellAll(function() return Config.AutoMangoRice end)
                end
            end)
        end
    end,
})

Toggle(AllIn, {
    key = "AutoBananaPack",
    title = "ลูปกล้วยแพ็ค",
    desc = "กล้วย → กล้วยแพ็ค → ขาย",
    callback = function(v)
        if v then
            task.spawn(function()
                Systems.WarpToTown()
                while Config.AutoBananaPack do
                    Systems.HarvestCrop("Banana", 60, function() return Config.AutoBananaPack end)
                    Systems.ProcessBanana(function() return Config.AutoBananaPack end)
                    Systems.SellAll(function() return Config.AutoBananaPack end)
                end
            end)
        end
    end,
})

Toggle(AllIn, {
    key = "AutoKangSom",
    title = "ลูปแกงส้ม",
    desc = "มะเขือเทศ + ปู → แกงส้ม → ขาย",
    callback = function(v)
        if v then
            task.spawn(function()
                Systems.WarpToTown()
                while Config.AutoKangSom do
                    Systems.HarvestCrop("Tomato", 60, function() return Config.AutoKangSom end)
                    Systems.HarvestCrop("Crab", 60, function() return Config.AutoKangSom end)
                    Systems.CraftFood("KangSom", function() return Config.AutoKangSom end)
                    Systems.SellAll(function() return Config.AutoKangSom end)
                end
            end)
        end
    end,
})

-- Farm เดี่ยว
Toggle(FarmPage, {
    key = "AutoIndividual",
    title = "เริ่มออโต้ฟาร์มเดี่ยว",
    desc = "พืชที่เลือก → 60 ชิ้น → ขาย",
    callback = function(v)
        if v then
            task.spawn(function()
                Systems.WarpToTown()
                while Config.AutoIndividual do
                    Systems.HarvestCrop(Config.IndividualCrop, 60, function() return Config.AutoIndividual end)
                    Systems.SellAll(function() return Config.AutoIndividual end)
                end
            end)
        end
    end,
})

-- Fishing
Toggle(Fishing, {
    key = "AutoFishing",
    title = "เริ่มออโต้ตกปลา",
    desc = "เบิกรถ → ซื้อเหยื่อ → ตกปลา → ขายปลา",
    callback = function(v)
        if v then Systems.StartFishing() else Systems.StopFishing() end
    end,
})

-- Settings
Toggle(Settings, { key = "AntiKick", title = "Anti-Kick", desc = "บล็อกคำสั่ง Kick" })
Toggle(Settings, { key = "AutoHopPlayer", title = "Auto Hop เมื่อมีคนใกล้", desc = "ย้ายเซิร์ฟอัตโนมัติ" })
Slider(Settings, { key = "HopDistance", title = "ระยะตรวจจับ", min = 20, max = 250, step = 5, suffix = " studs" })

-- IM THE MAN SCRIPT v5.1 - Safe Boot Edition

local Success, Rayfield = pcall(function()

    return loadstring(game:HttpGet('https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua'))()

end)



if not Success or not Rayfield then

    warn("[IM THE MAN] Rayfield Load Failure! Falling back to mirror...")

    Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

end



local Players = game:GetService("Players")

local HttpService = game:GetService("HttpService")

local RunService = game:GetService("RunService")

local VirtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer



local env = getgenv and getgenv() or _G



-- =========================================================================

-- 1. SINGLETON KILL SWITCH

-- =========================================================================

if env.ImTheMan_script_running then

    env.ImTheMan_kill_switch = true

    task.wait(0.3) 

end

env.ImTheMan_script_running = true

env.ImTheMan_kill_switch = false

local scriptRunning = true



-- =========================================================================

-- 2. VARIABLES & ROUTES CONFIGURATION

-- =========================================================================

env.ImTheManConfig = env.ImTheManConfig or {}

env.ImTheManConfig.AntiAFK = false

env.ImTheManConfig.MiningTarget = "Voidsteel + Celestium + Aetherite Loop"

env.ImTheManConfig.WebhookURL = ""

env.ImTheManConfig.WebhookEnabled = false



local Settings = {

    CustomWalkSpeed = 165,       

    WaitTimeOnOre = 0.50,      

    UseNoclip = false,

}



local looping = false

local totalMined, minedInLast10Mins, display10MinMined, estPerHour = 0, 0, 0, 0

local celestiumMined, voidsteelMined, aetheriteMined = 0, 0, 0

local rubyMined, infinityMined, palladiumMined, cobaltMined, uraniumMined, titaniumMined, platinumMined, goldMined, silverMined, ironMined, copperMined = 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

local runTime, history10min = 0, {}



local master_routes = {

    ["Voidsteel + Celestium + Aetherite Loop"] = {

        {name = "Voidsteel_1", pos = Vector3.new(699.21, 7.74, 2827.68)}, {name = "Voidsteel_2", pos = Vector3.new(683.25, 7.74, 2858.61)}, {name = "Voidsteel_3", pos = Vector3.new(705.66, 7.74, 2852.43)}, {name = "Voidsteel_4", pos = Vector3.new(723.42, 7.74, 2874.51)}, {name = "Voidsteel_5", pos = Vector3.new(727.90, 7.74, 2836.23)},

        {name = "Celestium_4", pos = Vector3.new(725.19, 7.87, 2804.33)}, {name = "Celestium_5", pos = Vector3.new(730.71, 7.87, 2780.08)}, {name = "Celestium_3", pos = Vector3.new(713.99, 7.87, 2764.92)}, {name = "Celestium_2", pos = Vector3.new(687.15, 7.87, 2772.15)}, {name = "Celestium_1", pos = Vector3.new(692.65, 7.87, 2799.67)},

        {name = "Aetherite_5", pos = Vector3.new(659.25, 7.34, 2783.24)}, {name = "Aetherite_4", pos = Vector3.new(645.36, 7.34, 2760.03)}, {name = "Aetherite_3", pos = Vector3.new(611.97, 7.34, 2769.11)}, {name = "Aetherite_2", pos = Vector3.new(593.95, 7.34, 2790.59)}, {name = "Aetherite_1", pos = Vector3.new(628.22, 7.34, 2793.83)}

    },

    ["Voidsteel + Celestium Loop"] = {

        {name = "Celestium_4", pos = Vector3.new(725.19, 7.87, 2804.33)}, {name = "Celestium_5", pos = Vector3.new(730.71, 7.87, 2780.08)}, {name = "Celestium_3", pos = Vector3.new(713.99, 7.87, 2764.92)}, {name = "Celestium_2", pos = Vector3.new(687.15, 7.87, 2772.15)}, {name = "Celestium_1", pos = Vector3.new(692.65, 7.87, 2799.67)},

        {name = "Voidsteel_1", pos = Vector3.new(699.21, 7.74, 2827.68)}, {name = "Voidsteel_2", pos = Vector3.new(683.25, 7.74, 2858.61)}, {name = "Voidsteel_4", pos = Vector3.new(723.42, 7.74, 2874.51)}, {name = "Voidsteel_3", pos = Vector3.new(705.66, 7.74, 2852.43)}, {name = "Voidsteel_5", pos = Vector3.new(727.90, 7.74, 2836.23)}

    },

    ["Ruby + Infinity Loop"] = {

        {name = "Ruby_1", pos = Vector3.new(651.74, 8.78, 2844.68)}, {name = "Ruby_2", pos = Vector3.new(639.78, 8.78, 2871.09)}, {name = "Ruby_3", pos = Vector3.new(615.62, 8.78, 2871.16)}, {name = "Ruby_4", pos = Vector3.new(596.52, 8.78, 2857.79)}, {name = "Ruby_5", pos = Vector3.new(621.73, 8.78, 2842.55)},

        {name = "Infinity_1", pos = Vector3.new(663.17, 8.78, 2816.40)}

    },

    ["Palladium Loop"] = {

        {name = "Palladium_1", pos = Vector3.new(525.00, 8.78, 2803.74)}, {name = "Palladium_2", pos = Vector3.new(522.01, 8.78, 2773.20)}, {name = "Palladium_3", pos = Vector3.new(494.60, 8.78, 2772.18)}, {name = "Palladium_4", pos = Vector3.new(496.76, 8.78, 2800.46)}, {name = "Palladium_5", pos = Vector3.new(472.91, 8.78, 2798.02)}

    },

    ["Cobalt Loop"] = {

        {name = "Cobalt_1", pos = Vector3.new(433.48, 8.78, 2768.60)}, {name = "Cobalt_2", pos = Vector3.new(396.16, 8.78, 2778.85)}, {name = "Cobalt_3", pos = Vector3.new(393.05, 8.78, 2807.30)}, {name = "Cobalt_4", pos = Vector3.new(422.19, 8.78, 2825.19)}, {name = "Cobalt_5", pos = Vector3.new(442.35, 8.78, 2802.93)}

    },

    ["Uranium Loop"] = {

        {name = "Uranium_1", pos = Vector3.new(514.41, 8.78, 2856.15)}, {name = "Uranium_2", pos = Vector3.new(489.87, 8.78, 2846.91)}, {name = "Uranium_3", pos = Vector3.new(470.85, 8.78, 2874.21)}, {name = "Uranium_4", pos = Vector3.new(483.24, 8.78, 2897.50)}, {name = "Uranium_5", pos = Vector3.new(505.20, 8.78, 2888.03)}

    },

    ["Titanium Loop"] = {

        {name = "Titanium_1", pos = Vector3.new(399.60, 8.78, 2919.29)}, {name = "Titanium_2", pos = Vector3.new(411.18, 8.78, 2941.41)}, {name = "Titanium_3", pos = Vector3.new(388.71, 8.78, 2958.50)}, {name = "Titanium_4", pos = Vector3.new(361.83, 8.78, 2955.87)}

    },

    ["Platinum Loop"] = {

        {name = "Platinum_1", pos = Vector3.new(447.21, 8.78, 2966.91)}, {name = "Platinum_2", pos = Vector3.new(479.44, 8.78, 2967.49)}, {name = "Platinum_3", pos = Vector3.new(457.66, 8.78, 3000.88)}, {name = "Platinum_4", pos = Vector3.new(441.88, 8.78, 3031.86)}, {name = "Platinum_5", pos = Vector3.new(479.13, 8.78, 3022.63)}

    },

    ["Gold Loop"] = {

        {name = "Gold_1", pos = Vector3.new(382.85, 8.78, 3031.27)}, {name = "Gold_2", pos = Vector3.new(365.46, 8.78, 3046.73)}, {name = "Gold_3", pos = Vector3.new(343.85, 8.78, 3027.68)}, {name = "Gold_4", pos = Vector3.new(352.53, 8.78, 2993.79)}, {name = "Gold_5", pos = Vector3.new(370.19, 8.78, 3006.34)}

    },

    ["Silver Loop"] = {

        {name = "Silver_1", pos = Vector3.new(424.68, 8.78, 3131.01)}, {name = "Silver_2", pos = Vector3.new(453.46, 8.78, 3130.71)}, {name = "Silver_3", pos = Vector3.new(463.66, 8.78, 3155.80)}, {name = "Silver_4", pos = Vector3.new(441.15, 8.78, 3177.76)}, {name = "Silver_5", pos = Vector3.new(425.91, 8.78, 3158.28)}

    },

    ["Iron Loop"] = {

        {name = "Iron_1", pos = Vector3.new(383.37, 8.78, 3145.71)}, {name = "Iron_2", pos = Vector3.new(381.09, 8.78, 3173.59)}, {name = "Iron_3", pos = Vector3.new(352.32, 8.78, 3165.98)}, {name = "Iron_4", pos = Vector3.new(356.29, 8.78, 3191.83)}, {name = "Iron_5", pos = Vector3.new(380.75, 8.78, 3202.53)}

    },

    ["Copper Loop"] = {

        {name = "Copper_1", pos = Vector3.new(397.91, 8.78, 3241.41)}, {name = "Copper_2", pos = Vector3.new(415.63, 8.78, 3263.55)}, {name = "Copper_3", pos = Vector3.new(420.53, 8.78, 3225.27)}, {name = "Copper_4", pos = Vector3.new(442.87, 8.78, 3255.16)}, {name = "Copper_5", pos = Vector3.new(443.08, 8.78, 3227.66)}

    }

}



local dropdown_options = {

    "Voidsteel + Celestium + Aetherite Loop", "Voidsteel + Celestium Loop", "Ruby + Infinity Loop", 

    "Palladium Loop", "Cobalt Loop", "Uranium Loop", "Titanium Loop", "Platinum Loop", 

    "Gold Loop", "Silver Loop", "Iron Loop", "Copper Loop"

}



-- =========================================================================

-- 3. WEBHOOK HANDLING ENGINE

-- =========================================================================

local function sendDiscordWebhook(isTest)

    local url = env.ImTheManConfig.WebhookURL

    if not url or url == "" or not string.match(url, "^https://") then return end



    local titleStr = isTest and "🧪 Script Webhook Test Connection" or "📊 10-Minute Progress Report"

    local colorVal = isTest and 16776960 or 3066993

    

    local data = {

        ["embeds"] = {{

            ["title"] = titleStr,

            ["color"] = colorVal,

            ["description"] = string.format("Tracking update for player: **%s**", player.Name),

            ["fields"] = {

                {["name"] = "Status", ["value"] = looping and "🟢 Active" or "🔴 Paused", ["inline"] = true},

                {["name"] = "Runtime", ["value"] = string.format("%d min", math.floor(runTime/60)), ["inline"] = true},

                {["name"] = "Est. Speed", ["value"] = string.format("%d /hr", estPerHour), ["inline"] = true},

                {["name"] = "Total Mined Balance", ["value"] = string.format("**%d Ores**", totalMined), ["inline"] = false},

                {["name"] = "High-Tier Breakdown", ["value"] = string.format("Voidsteel: %d\nCelestium: %d\nAetherite: %d", voidsteelMined, celestiumMined, aetheriteMined), ["inline"] = true},

                {["name"] = "Mid-Tier Breakdown", ["value"] = string.format("Ruby: %d\nInfinity: %d\nPalladium: %d\nCobalt: %d", rubyMined, infinityMined, palladiumMined, cobaltMined), ["inline"] = true},

                {["name"] = "Base Ores Breakdown", ["value"] = string.format("Uranium: %d\nTitanium: %d\nPlatinum: %d\nGold: %d\nSilver: %d\nIron: %d\nCopper: %d", uraniumMined, titaniumMined, platinumMined, goldMined, silverMined, ironMined, copperMined), ["inline"] = false}

            },

            ["timestamp"] = DateTime.now():ToIsoDate()

        }}

    }



    local jsonData = HttpService:JSONEncode(data)

    

    task.spawn(function()

        pcall(function()

            local request = syn and syn.request or http and http.request or http_request or request

            if request then

                request({Url = url, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = jsonData})

            end

        end)

    end)

end



local function getTrendData()

    local currentHourMined = totalMined - (history10min[#history10min - 6] or history10min[1] or 0)

    local prevHourMined = (history10min[#history10min - 6] or 0) - (history10min[#history10min - 12] or 0)

    local trendText = "0%"

    if prevHourMined > 0 then

        local diff = currentHourMined - prevHourMined

        local pct = (diff / prevHourMined) * 100

        trendText = string.format("%.1f%%", pct)

        if diff > 0 then trendText = "+" .. trendText end

    elseif currentHourMined > 0 and prevHourMined == 0 then trendText = "+100% 📈" end

    return trendText

end



-- =========================================================================

-- GHOST MODE & ANTI-AFK

-- =========================================================================

local NoclipConnection, AxisLockConnection, fixedY

local function noclip()

    Settings.UseNoclip = true

    local character = player.Character or player.CharacterAdded:Wait()

    local hrp = character:WaitForChild("HumanoidRootPart")

    local humanoid = character:WaitForChild("Humanoid")

    fixedY = hrp.Position.Y

    humanoid.JumpPower = 0

    humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)

    

    if not NoclipConnection then

        NoclipConnection = RunService.Stepped:Connect(function()

            if Settings.UseNoclip and player.Character ~= nil then

                for _, v in pairs(player.Character:GetDescendants()) do 

                    if v:IsA('BasePart') and v.CanCollide then v.CanCollide = false end 

                end

            end

        end)

    end

    if not AxisLockConnection then

        AxisLockConnection = RunService.Heartbeat:Connect(function()

            if Settings.UseNoclip and character and hrp and humanoid then

                humanoid.Jump = false

                if math.abs(hrp.Position.Y - fixedY) > 0.5 then 

                    hrp.CFrame = CFrame.new(Vector3.new(hrp.Position.X, fixedY, hrp.Position.Z)) * hrp.CFrame.Rotation 

                end

                hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, 0, hrp.AssemblyLinearVelocity.Z)

            end

        end)

    end

end



local function clip()

    Settings.UseNoclip = false

    if NoclipConnection then NoclipConnection:Disconnect(); NoclipConnection = nil end

    if AxisLockConnection then AxisLockConnection:Disconnect(); AxisLockConnection = nil end

    local character = player.Character

    if character and character:FindFirstChildOfClass("Humanoid") then

        character:FindFirstChildOfClass("Humanoid").JumpPower = 50

        character:FindFirstChildOfClass("Humanoid"):SetStateEnabled(Enum.HumanoidStateType.Jumping, true)

    end

end



local antiIdleConnection = nil

local function setAntiIdle(enabled)

    env.ImTheManConfig.AntiAFK = enabled

    if antiIdleConnection then antiIdleConnection:Disconnect(); antiIdleConnection = nil end

    if not enabled then return end

    antiIdleConnection = player.Idled:Connect(function() 

        if scriptRunning and not env.ImTheMan_kill_switch then 

            pcall(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end) 

        end 

    end)

end



-- =========================================================================

-- MOVEMENT METHOD

-- =========================================================================

local function moveToPoint(targetPos, hrp)

    local speed = Settings.CustomWalkSpeed

    local character = hrp.Parent

    local humanoid = character:FindFirstChildOfClass("Humanoid")

    if humanoid then humanoid.AutoRotate = false end



    while scriptRunning and not env.ImTheMan_kill_switch and looping do

        if not hrp or not hrp.Parent or (humanoid and humanoid.Health <= 0) then break end



        local currentPos = hrp.Position

        local diff = Vector3.new(targetPos.X - currentPos.X, 0, targetPos.Z - currentPos.Z)

        local distance = diff.Magnitude

        local deltaTime = RunService.Heartbeat:Wait()

        local step = speed * deltaTime

        

        if distance <= step or distance <= 1.5 then

            character:PivotTo(CFrame.new(targetPos))

            break

        end

        

        local newPos = currentPos + (diff.Unit * step)

        character:PivotTo(CFrame.lookAt(newPos, Vector3.new(targetPos.X, currentPos.Y, targetPos.Z)))

    end

    if humanoid then humanoid.AutoRotate = true end

end



-- =========================================================================

-- 4. RAYFIELD UI INITIALIZATION

-- =========================================================================

local Window = Rayfield:CreateWindow({

    Name = "IM THE MAN SCRIPT v2.5",

    LoadingTitle = "IM THE MAN",

    LoadingSubtitle = "by Juicepoppers",

    Theme = "DarkTheme",

    ConfigurationSaving = {

        Enabled = false -- Turn off auto config loading to prevent data mismatch crashes

    },

    Discord = { Enabled = false },

    KeySystem = false

})



-- TABS

local MiningTab = Window:CreateTab("Auto Mining", 4483362458)

local SettingsTab = Window:CreateTab("Settings", 4483362458)

local WebhookTab = Window:CreateTab("Webhook", 4483362458)

local StatsTab = Window:CreateTab("Statistics", 4483362458)



-- ======================== MINING TAB ========================

MiningTab:CreateSection("Mining Controls")



MiningTab:CreateToggle({

    Name = "Enable Auto-Mining",

    CurrentValue = false,

    Flag = "Toggle_Mining",

    Callback = function(Value)

        looping = Value

    end,

})



MiningTab:CreateDropdown({

    Name = "Select Mining Route",

    Options = dropdown_options,

    CurrentOption = "Voidsteel + Celestium + Aetherite Loop",

    Flag = "Dropdown_Route", 

    Callback = function(Option)

        local choice = type(Option) == "table" and Option[1] or Option

        if choice then

            env.ImTheManConfig.MiningTarget = choice

        end

    end,

})



-- ======================== SETTINGS TAB ========================

SettingsTab:CreateSection("Character Settings")



SettingsTab:CreateSlider({

    Name = "WalkSpeed",

    Range = {16, 300},

    Increment = 1,

    Suffix = "Speed",

    CurrentValue = 165,

    Flag = "Slider_WalkSpeed",

    Callback = function(Value)

        Settings.CustomWalkSpeed = Value

        local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")

        if h then h.WalkSpeed = Value end

    end,

})



SettingsTab:CreateInput({

    Name = "Ore Break Time (Seconds)",

    PlaceholderText = "Default: 0.50",

    RemoveTextAfterFocusLost = false,

    Callback = function(Text)

        local num = tonumber(Text)

        if num then Settings.WaitTimeOnOre = num end

    end,

})



SettingsTab:CreateSection("Utilities")



SettingsTab:CreateToggle({

    Name = "Ghost Mode (Noclip)",

    CurrentValue = false,

    Flag = "Toggle_Noclip",

    Callback = function(Value)

        if Value then noclip() else clip() end

    end

})



SettingsTab:CreateToggle({

    Name = "Anti-AFK",

    CurrentValue = false,

    Flag = "Toggle_AntiAFK",

    Callback = function(Value)

        setAntiIdle(Value)

    end,

})



SettingsTab:CreateButton({

    Name = "Kill Script & Destroy UI",

    Callback = function()

        scriptRunning = false

        looping = false

        clip()

        setAntiIdle(false)

        env.ImTheMan_kill_switch = true

        Rayfield:Destroy()

    end,

})



-- ======================== WEBHOOK TAB ========================

WebhookTab:CreateSection("Discord Integration")



WebhookTab:CreateInput({

    Name = "Webhook URL",

    PlaceholderText = "Paste Discord webhooks link here...",

    RemoveTextAfterFocusLost = false,

    Callback = function(Text)

        env.ImTheManConfig.WebhookURL = Text

    end,

})



WebhookTab:CreateToggle({

    Name = "Enable Webhook Reports (10m interval)",

    CurrentValue = false,

    Flag = "Toggle_WebhookReports",

    Callback = function(Value)

        env.ImTheManConfig.WebhookEnabled = Value

    end,

})



WebhookTab:CreateButton({

    Name = "Send Test Webhook",

    Callback = function()

        sendDiscordWebhook(true)

    end,

})



-- ======================== STATS TAB ========================

local StatsParagraph = StatsTab:CreateParagraph({

    Title = "Live Tracking", 

    Content = "Starting up..."

})



-- =========================================================================

-- 5. SYSTEM CLOCK LOOP

-- =========================================================================

local runTimer = 0

task.spawn(function()

    while scriptRunning and not env.ImTheMan_kill_switch do

        task.wait(1)

        if looping then

            runTime = runTime + 1

            runTimer = runTimer + 1

            if runTimer >= 600 then 

                display10MinMined = minedInLast10Mins

                minedInLast10Mins = 0 

                table.insert(history10min, totalMined) 

                if #history10min > 25 then table.remove(history10min, 1) end 

                if env.ImTheManConfig.WebhookEnabled then sendDiscordWebhook(false) end

                runTimer = 0

            end

        end

        if runTime > 0 then estPerHour = math.floor((totalMined / runTime) * 3600) end 

        

        local status = looping and "🟢 ACTIVE" or "🔴 PAUSED"

        local statsString = string.format(

            "Status: %s\n\nTotal Mined: %d\nEst. Speed: %d /hr\n\nCelestium: %d | Voidsteel: %d\nAetherite: %d\nRuby: %d | Infinity: %d\nPalladium: %d | Cobalt: %d\nUranium: %d | Titanium: %d\nPlatinum: %d | Gold: %d\nSilver: %d | Iron: %d\nCopper Mined: %d\n\nPerformance Trend: %s",

            status, totalMined, estPerHour, celestiumMined, voidsteelMined, aetheriteMined, rubyMined, infinityMined, palladiumMined, cobaltMined, uraniumMined, titaniumMined, platinumMined, goldMined, silverMined, ironMined, copperMined, getTrendData()

        )

        

        pcall(function()

            StatsParagraph:Set({Title = "Live Tracking", Content = statsString})

        end)

    end

end)



-- =========================================================================

-- 6. MAIN MINING LOOP

-- =========================================================================

task.spawn(function()

    while scriptRunning and not env.ImTheMan_kill_switch do

        if looping then

            local activeRouteName = env.ImTheManConfig.MiningTarget

            local activeRoute = master_routes[activeRouteName]

            

            if activeRoute then

                for idx, target in ipairs(activeRoute) do

                    if not looping or not scriptRunning or env.ImTheMan_kill_switch then break end

                    

                    local char = player.Character

                    local hrp = char and char:FindFirstChild("HumanoidRootPart")

                    local humanoid = char and char:FindFirstChild("Humanoid")



                    if hrp and humanoid and humanoid.Health > 0 then

                        moveToPoint(target.pos, hrp)

                        task.wait(0.08) -- Stop remote queue error

                        

                        if not looping or not scriptRunning or env.ImTheMan_kill_switch then break end

                        totalMined = totalMined + 1

                        minedInLast10Mins = minedInLast10Mins + 1

                        

                        if string.find(target.name, "Celestium") then celestiumMined = celestiumMined + 1

                        elseif string.find(target.name, "Voidsteel") then voidsteelMined = voidsteelMined + 1 

                        elseif string.find(target.name, "Aetherite") then aetheriteMined = aetheriteMined + 1 

                        elseif string.find(target.name, "Ruby") then rubyMined = rubyMined + 1

                        elseif string.find(target.name, "Infinity") then infinityMined = infinityMined + 1

                        elseif string.find(target.name, "Palladium") then palladiumMined = palladiumMined + 1

                        elseif string.find(target.name, "Cobalt") then cobaltMined = cobaltMined + 1

                        elseif string.find(target.name, "Uranium") then uraniumMined = uraniumMined + 1

                        elseif string.find(target.name, "Titanium") then titaniumMined = titaniumMined + 1

                        elseif string.find(target.name, "Platinum") then platinumMined = platinumMined + 1

                        elseif string.find(target.name, "Gold") then goldMined = goldMined + 1

                        elseif string.find(target.name, "Silver") then silverMined = silverMined + 1

                        elseif string.find(target.name, "Iron") then ironMined = ironMined + 1

                        elseif string.find(target.name, "Copper") then copperMined = copperMined + 1 end

                        

                        task.wait(Settings.WaitTimeOnOre)

                    end

                end

            else

                task.wait(1)

            end

        else 

            task.wait(0.2) 

        end

    end

end) 


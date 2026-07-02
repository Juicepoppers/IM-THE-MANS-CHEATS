-- IM THE MAN SCRIPT v2.4 - Surowe GUI + Wybór Trasy + Toggle Key
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

local env = getgenv and getgenv() or _G

-- =========================================================================
-- 1. SINGLETON KILL SWITCH
-- =========================================================================
if env.ImTheMan_script_running then
    env.ImTheMan_kill_switch = true
    task.wait(0.5) 
end
env.ImTheMan_script_running = true
env.ImTheMan_kill_switch = false
local scriptRunning = true

-- =========================================================================
-- 2. VARIABLES & CONFIGURATION
-- =========================================================================
env.ImTheManConfig = env.ImTheManConfig or {}

env.ImTheManConfig.WebhookEnabled = env.ImTheManConfig.WebhookEnabled or false
env.ImTheManConfig.WebhookURL = env.ImTheManConfig.WebhookURL or ""
env.ImTheManConfig.AntiAFK = env.ImTheManConfig.AntiAFK or false
env.ImTheManConfig.MiningTarget = env.ImTheManConfig.MiningTarget or "Voidsteel + Celestium + Aetherite Loop"

local Settings = {
    CustomWalkSpeed = 165,       
    WaitTimeOnOre = 0.50,      
    UseNoclip = false,
    ToggleKey = Enum.KeyCode.LeftControl -- Key to minimize/maximize the menu
}

local looping = false
local totalMined, minedInLast10Mins, display10MinMined, estPerHour = 0, 0, 0, 0
local celestiumMined, voidsteelMined, aetheriteMined = 0, 0, 0
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
    }
}

local routeNames = {
    "Voidsteel + Celestium + Aetherite Loop",
    "Voidsteel + Celestium Loop"
}

local saveFileName = "ImTheMan_Storage.json"

local function loadSettings()
    pcall(function()
        if readfile and isfile and isfile(saveFileName) then
            local raw = readfile(saveFileName)
            local data = HttpService:JSONDecode(raw)
            if data then
                if data.ImTheManConfig then for k, v in pairs(data.ImTheManConfig) do env.ImTheManConfig[k] = v end end
                if data.Settings then for k, v in pairs(data.Settings) do Settings[k] = v end end
            end
        end
    end)
end

loadSettings()

local function saveSettings()
    local safeConfig = {}
    for k, v in pairs(env.ImTheManConfig) do
        if type(v) == "boolean" or type(v) == "number" or type(v) == "string" or type(v) == "table" then safeConfig[k] = v end
    end
    local data = { ImTheManConfig = safeConfig, Settings = Settings }
    pcall(function() if writefile then writefile(saveFileName, HttpService:JSONEncode(data)) end end)
end

-- =========================================================================
-- 3. INTERNAL LOGIC & WEBHOOK
-- =========================================================================
local request = request or http_request or (syn and syn.request)

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

local function dispatchStatsWebhook()
    if not request or not looping or not env.ImTheManConfig.WebhookEnabled or env.ImTheManConfig.WebhookURL == "" then return end 
    local hours = math.floor(runTime / 3600); local minutes = math.floor((runTime % 3600) / 60)
    local payload = {
        embeds = {{
            title = "⚡ IM THE MAN SCRIPT - Raport Kopania", color = 5763719, 
            fields = {
                {name = "⏳ Czas", value = string.format("`%dh %dm`", hours, minutes), inline = true},
                {name = "🔋 Wykopane", value = string.format("`%d`", totalMined), inline = true},
                {name = "📈 Prędkość", value = string.format("`%d /h`", estPerHour), inline = true},
                {name = "⏱️ Ostatnie 10m", value = string.format("`%d`", display10MinMined), inline = true},
                {name = "📊 Trend", value = string.format("`%s`", getTrendData()), inline = true},
                {name = "💎 Celestium", value = string.format("`%d`", celestiumMined), inline = true},
                {name = "💜 Voidsteel", value = string.format("`%d`", voidsteelMined), inline = true},
                {name = "💙 Aetherite", value = string.format("`%d`", aetheriteMined), inline = true}
            }, footer = { text = "IM THE MAN SCRIPT v2.4 - Surowe GUI" }, timestamp = DateTime.now():ToIsoDate()
        }}
    }
    pcall(function() request({Url = env.ImTheManConfig.WebhookURL, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = HttpService:JSONEncode(payload)}) end)
end

-- =========================================================================
-- GHOST MODE (NOCLIP + Y-AXIS LOCK)
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
-- MOVEMENT METHOD (LEVITATING ONLY)
-- =========================================================================
local function moveToPoint(targetPos, hrp)
    local speed = Settings.CustomWalkSpeed
    local humanoid = hrp.Parent:FindFirstChildOfClass("Humanoid")
    if humanoid then humanoid.AutoRotate = false end

    while scriptRunning and not env.ImTheMan_kill_switch and looping do
        if not hrp or not hrp.Parent or (humanoid and humanoid.Health <= 0) then break end

        local currentPos = hrp.Position
        local diff = Vector3.new(targetPos.X - currentPos.X, 0, targetPos.Z - currentPos.Z)
        local distance = diff.Magnitude
        local deltaTime = RunService.Heartbeat:Wait()
        local step = speed * deltaTime
        
        hrp.AssemblyLinearVelocity = Vector3.zero
        
        if distance <= step or distance <= 0.7 then
            hrp.CFrame = CFrame.lookAt(currentPos, Vector3.new(targetPos.X, currentPos.Y, targetPos.Z))
            if humanoid then humanoid:Move(Vector3.zero) end 
            break
        end
        
        local newPos = currentPos + (diff.Unit * step)
        hrp.CFrame = CFrame.lookAt(newPos, Vector3.new(targetPos.X, currentPos.Y, targetPos.Z))
    end
    if humanoid then humanoid.AutoRotate = true end
end

-- =========================================================================
-- 4. SUROWE GUI (Roblox Native)
-- =========================================================================
local ImTheManGUI = Instance.new("ScreenGui")
ImTheManGUI.Name = "ImTheManBiedaUI"
ImTheManGUI.ResetOnSpawn = false

local successGui, _ = pcall(function() ImTheManGUI.Parent = CoreGui end)
if not successGui then ImTheManGUI.Parent = player:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 300, 0, 480)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -240)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(100, 100, 100)
MainFrame.Parent = ImTheManGUI
MainFrame.Active = true
MainFrame.Draggable = true 

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Text = "IM THE MAN SCRIPT v2.4"
Title.Font = Enum.Font.Code
Title.TextSize = 18
Title.Parent = MainFrame

local Container = Instance.new("ScrollingFrame")
Container.Size = UDim2.new(1, -10, 1, -40)
Container.Position = UDim2.new(0, 5, 0, 35)
Container.BackgroundTransparency = 1
Container.ScrollBarThickness = 4
Container.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 5)
UIListLayout.Parent = Container

-- =========================================================================
-- INPUT HANDLING (MINIMIZE / TOGGLE SYSTEM)
-- =========================================================================
local uiConnection
uiConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not scriptRunning or env.ImTheMan_kill_switch then
        uiConnection:Disconnect()
        return
    end
    if not gameProcessed and input.KeyCode == Settings.ToggleKey then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

local function createButton(text, onClick)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 30)
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Text = text
    btn.Font = Enum.Font.Code
    btn.TextSize = 12
    btn.TextWrapped = true
    btn.Parent = Container
    btn.MouseButton1Click:Connect(onClick)
    return btn
end

local function createInput(placeholder, text, onFocusLost)
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -10, 0, 30)
    box.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    box.TextColor3 = Color3.fromRGB(200, 200, 200)
    box.PlaceholderText = placeholder
    box.Text = text
    box.Font = Enum.Font.Code
    box.TextSize = 14
    box.ClearTextOnFocus = false
    box.Parent = Container
    box.FocusLost:Connect(function() onFocusLost(box.Text) end)
    return box
end

local function createLabel(text)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -10, 0, 20)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Color3.fromRGB(180, 180, 180)
    lbl.Text = text
    lbl.Font = Enum.Font.Code
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = Container
    return lbl
end

-- Informacyjny label o klawiszu ukrywania
createLabel("[L-CTRL] Ukrywa / Pokazuje GUI")
createLabel("-------------------------")

-- Toggle Kopania
local btnStart = createButton("Start Mining: OFF", function() end)
btnStart.MouseButton1Click:Connect(function()
    looping = not looping
    if looping then
        btnStart.Text = "Start Mining: ON"
        btnStart.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
    else
        btnStart.Text = "Start Mining: OFF"
        btnStart.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    end
end)

-- Przełącznik trasy
local currentRouteIdx = 1
for i, name in ipairs(routeNames) do
    if name == env.ImTheManConfig.MiningTarget then currentRouteIdx = i end
end

local function getRouteDisplayName(name)
    if name == "Voidsteel + Celestium + Aetherite Loop" then return "Trasa: 3 Rudy (V+C+A)" end
    if name == "Voidsteel + Celestium Loop" then return "Trasa: 2 Rudy (V+C)" end
    return "Trasa: " .. name
end

local btnRoute = createButton(getRouteDisplayName(routeNames[currentRouteIdx]), function() end)
btnRoute.BackgroundColor3 = Color3.fromRGB(70, 70, 100)
btnRoute.MouseButton1Click:Connect(function()
    currentRouteIdx = currentRouteIdx + 1
    if currentRouteIdx > #routeNames then currentRouteIdx = 1 end
    
    env.ImTheManConfig.MiningTarget = routeNames[currentRouteIdx]
    btnRoute.Text = getRouteDisplayName(routeNames[currentRouteIdx])
    saveSettings()
end)

createLabel("Movement Speed:")
createInput("WalkSpeed", tostring(Settings.CustomWalkSpeed), function(val)
    local num = tonumber(val)
    if num then 
        Settings.CustomWalkSpeed = num 
        local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if h then h.WalkSpeed = num end
        saveSettings()
    end
end)

createLabel("Ore Break Time (s):")
createInput("Wait Time", tostring(Settings.WaitTimeOnOre), function(val)
    local num = tonumber(val)
    if num then 
        Settings.WaitTimeOnOre = num 
        saveSettings()
    end
end)

-- Webhook
createLabel("Discord Webhook URL:")
createInput("https://discord.com/api/webhooks/...", env.ImTheManConfig.WebhookURL, function(val)
    env.ImTheManConfig.WebhookURL = val
    saveSettings()
end)

local btnWeb = createButton("Webhook: OFF", function() end)
if env.ImTheManConfig.WebhookEnabled then btnWeb.Text = "Webhook: ON" btnWeb.BackgroundColor3 = Color3.fromRGB(50, 150, 50) end
btnWeb.MouseButton1Click:Connect(function()
    env.ImTheManConfig.WebhookEnabled = not env.ImTheManConfig.WebhookEnabled
    if env.ImTheManConfig.WebhookEnabled then
        btnWeb.Text = "Webhook: ON"
        btnWeb.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
    else
        btnWeb.Text = "Webhook: OFF"
        btnWeb.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    end
    saveSettings()
end)

createButton("Test Webhook", function()
    if env.ImTheManConfig.WebhookURL ~= "" then
        local payload = { embeds = {{ title = "✅ Test Webhook", description = "Działa pomyślnie!", color = 5763719 }} }
        pcall(function() request({Url = env.ImTheManConfig.WebhookURL, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = HttpService:JSONEncode(payload)}) end)
    end
end)

-- Settings
local btnGhost = createButton("Ghost Mode (Noclip): OFF", function() end)
if Settings.UseNoclip then btnGhost.Text = "Ghost Mode (Noclip): ON" btnGhost.BackgroundColor3 = Color3.fromRGB(50, 150, 50) end
btnGhost.MouseButton1Click:Connect(function()
    Settings.UseNoclip = not Settings.UseNoclip
    if Settings.UseNoclip then
        noclip()
        btnGhost.Text = "Ghost Mode (Noclip): ON"
        btnGhost.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
    else
        clip()
        btnGhost.Text = "Ghost Mode (Noclip): OFF"
        btnGhost.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    end
    saveSettings()
end)

local btnAfk = createButton("Anti-AFK: OFF", function() end)
if env.ImTheManConfig.AntiAFK then btnAfk.Text = "Anti-AFK: ON" btnAfk.BackgroundColor3 = Color3.fromRGB(50, 150, 50) end
btnAfk.MouseButton1Click:Connect(function()
    env.ImTheManConfig.AntiAFK = not env.ImTheManConfig.AntiAFK
    setAntiIdle(env.ImTheManConfig.AntiAFK)
    if env.ImTheManConfig.AntiAFK then
        btnAfk.Text = "Anti-AFK: ON"
        btnAfk.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
    else
        btnAfk.Text = "Anti-AFK: OFF"
        btnAfk.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    end
    saveSettings()
end)

createLabel("-------------------------")

local StatsLabel = Instance.new("TextLabel")
StatsLabel.Size = UDim2.new(1, -10, 0, 60)
StatsLabel.BackgroundTransparency = 1
StatsLabel.TextColor3 = Color3.fromRGB(200, 255, 200)
StatsLabel.Text = "Mined: 0 | Speed: 0/h\nCel: 0 | Void: 0 | Aet: 0"
StatsLabel.Font = Enum.Font.Code
StatsLabel.TextSize = 13
StatsLabel.TextYAlignment = Enum.TextYAlignment.Top
StatsLabel.Parent = Container

createLabel("-------------------------")

local killBtn = createButton("KILL SCRIPT", function()
    scriptRunning = false; looping = false; clip(); setAntiIdle(false); env.ImTheMan_kill_switch = true
    if uiConnection then uiConnection:Disconnect() end
    ImTheManGUI:Destroy()
end)
killBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)

Container.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 10)
UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    Container.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 10)
end)

if Settings.UseNoclip then task.spawn(noclip) end
setAntiIdle(env.ImTheManConfig.AntiAFK)

-- =========================================================================
-- 5. SYSTEM LOOP & WEBHOOK
-- =========================================================================
local runTimer = 0
task.spawn(function()
    while scriptRunning and not env.ImTheMan_kill_switch do
        task.wait(1)
        if looping then
            runTime = runTime + 1; runTimer = runTimer + 1
            if runTimer >= 600 then 
                display10MinMined = minedInLast10Mins; minedInLast10Mins = 0 
                table.insert(history10min, totalMined) 
                if #history10min > 25 then table.remove(history10min, 1) end 
                dispatchStatsWebhook()
                runTimer = 0
            end
        end
        if runTime > 0 then estPerHour = math.floor((totalMined / runTime) * 3600) end 
        
        local status = looping and "ACTIVE" or "PAUSED"
        StatsLabel.Text = string.format("Status: %s\nMined: %d | Speed: %d/h\nCel: %d | Void: %d | Aet: %d", 
            status, totalMined, estPerHour, celestiumMined, voidsteelMined, aetheriteMined)
    end
end)

-- MAIN MINING LOOP
task.spawn(function()
    while scriptRunning and not env.ImTheMan_kill_switch do
        if looping then
            local activeRoute = master_routes[env.ImTheManConfig.MiningTarget]
            if activeRoute then
                for _, target in ipairs(activeRoute) do
                    if not looping or not scriptRunning or env.ImTheMan_kill_switch then break end
                    
                    local char = player.Character or player.CharacterAdded:Wait()
                    local hrp = char:WaitForChild("HumanoidRootPart", 5)
                    local humanoid = char:WaitForChild("Humanoid", 5)

                    if hrp and humanoid and humanoid.Health > 0 then
                        moveToPoint(target.pos, hrp)
                        
                        if not scriptRunning or env.ImTheMan_kill_switch then break end
                        totalMined = totalMined + 1
                        minedInLast10Mins = minedInLast10Mins + 1
                        if string.find(target.name, "Celestium") then celestiumMined = celestiumMined + 1
                        elseif string.find(target.name, "Voidsteel") then voidsteelMined = voidsteelMined + 1 
                        elseif string.find(target.name, "Aetherite") then aetheriteMined = aetheriteMined + 1 end
                        
                        task.wait(Settings.WaitTimeOnOre)
                    end
                end
            else
                task.wait(0.5)
            end
        else task.wait(0.1) end
    end
end)

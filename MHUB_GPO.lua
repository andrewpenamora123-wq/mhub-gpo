-- =============================================
--           M HUB — Grand Piece Online
--              Executor: Volt
--           [ SAFE MODE ENABLED ]
-- =============================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local lp = Players.LocalPlayer
local char = lp.Character or lp.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")
local hum = char:WaitForChild("Humanoid")

-- =============================================
-- CONFIG
-- =============================================
local TARGET_LEVEL  = 425
local FARM_RADIUS   = 45
local TWEEN_SPEED   = 35
local ATK_DELAY_MIN = 0.35
local ATK_DELAY_MAX = 0.85
local PAUSE_EVERY   = math.random(12, 20)
local PAUSE_MIN     = 2
local PAUSE_MAX     = 6

local ISLANDS = {
    ["Starter Island"]   = CFrame.new(3980, 7, 1270),
    ["Shell's Town"]     = CFrame.new(-3700, 7, -400),
    ["Gecko Island"]     = CFrame.new(-2400, 7, 2700),
    ["Baratie"]          = CFrame.new(-5800, 7, 3000),
    ["Arlong Park"]      = CFrame.new(-6700, 7, 700),
    ["Skypiea"]          = CFrame.new(-300, 1507, -3000),
    ["Alabasta"]         = CFrame.new(8900, 7, -1600),
    ["Thriller Bark"]    = CFrame.new(-9800, 7, -2300),
    ["Marineford"]       = CFrame.new(100, 7, -11000),
    ["Fishman Island"]   = CFrame.new(-340, -2500, -14900),
}

local SHRINE_CF = CFrame.new(140, 12, -11200)

local FISHMAN_MOBS = {
    "fishman", "arlong", "merfolk", "sea warrior", "fisher tiger"
}

-- =============================================
-- STATE
-- =============================================
local autoFarmEnabled   = false
local autoScrollEnabled = false
local attackCount       = 0
local farmConn          = nil

-- =============================================
-- UTILITY
-- =============================================
local function notify(title, text)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title, Text = text, Duration = 4,
        })
    end)
end

local function randWait(min, max)
    task.wait(min + math.random() * (max - min))
end

local function getLevel()
    for _, v in pairs(lp:GetDescendants()) do
        if (v.Name == "Level" or v.Name == "Lvl") and (v:IsA("IntValue") or v:IsA("NumberValue")) then
            return v.Value
        end
    end
    local ls = lp:FindFirstChild("leaderstats") or lp:FindFirstChild("Stats") or lp:FindFirstChild("Data")
    if ls then
        for _, v in pairs(ls:GetChildren()) do
            if v.Name:lower():find("lvl") or v.Name:lower():find("level") then
                return v.Value
            end
        end
    end
    return 0
end

lp.CharacterAdded:Connect(function(c)
    char = c
    hrp  = c:WaitForChild("HumanoidRootPart")
    hum  = c:WaitForChild("Humanoid")
end)

-- =============================================
-- TWEEN
-- =============================================
local function tweenTo(cf, label)
    if not hrp then return end
    notify("M HUB", "Moving to " .. label .. "...")

    local startPos = hrp.Position
    local endPos   = cf.Position
    local dist     = (startPos - endPos).Magnitude
    local segments = 3

    for i = 1, segments do
        if not hrp then break end
        local t      = i / segments
        local midPos = startPos:Lerp(endPos, t)
        local midCF  = CFrame.new(midPos) * (cf - cf.Position)
        local segDur = math.clamp((dist / segments) / TWEEN_SPEED, 0.5, 30)

        local bp = Instance.new("BodyPosition")
        bp.MaxForce = Vector3.new(1e9, 1e9, 1e9)
        bp.Position = hrp.Position
        bp.Parent   = hrp

        local tween = TweenService:Create(hrp,
            TweenInfo.new(segDur, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
            { CFrame = midCF }
        )
        tween:Play()
        tween.Completed:Wait()
        bp:Destroy()

        if i < segments then randWait(0.3, 1.0) end
    end

    notify("M HUB", "Arrived at " .. label .. "!")
    randWait(1, 2)
end

-- =============================================
-- FARMING
-- =============================================
local function isFishman(model)
    local name = model.Name:lower()
    for _, keyword in ipairs(FISHMAN_MOBS) do
        if name:find(keyword) then return true end
    end
    return false
end

local function getNearestMob()
    local closest, closestDist = nil, FARM_RADIUS
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v ~= char then
            local mobHum = v:FindFirstChildWhichIsA("Humanoid")
            local mobHRP = v:FindFirstChild("HumanoidRootPart")
            if mobHum and mobHRP and mobHum.Health > 0 and isFishman(v) then
                local d = (hrp.Position - mobHRP.Position).Magnitude
                if d < closestDist then
                    closest, closestDist = v, d
                end
            end
        end
    end
    return closest
end

local function attackMob(mob)
    local mobHRP = mob:FindFirstChild("HumanoidRootPart")
    if not mobHRP then return end

    local offsetX = (math.random() - 0.5) * 2
    local offsetZ = 3 + math.random() * 1.5
    hrp.CFrame = mobHRP.CFrame * CFrame.new(offsetX, 0, offsetZ)

    randWait(ATK_DELAY_MIN, ATK_DELAY_MAX)

    local click = mob:FindFirstChildOfClass("ClickDetector")
    if click then pcall(function() fireclickdetector(click) end) end

    attackCount = attackCount + 1
    if attackCount >= PAUSE_EVERY then
        attackCount = 0
        PAUSE_EVERY = math.random(12, 22)
        task.wait(math.random(PAUSE_MIN, PAUSE_MAX))
    end
end

local function startFarm()
    if farmConn then return end
    autoFarmEnabled = true
    task.spawn(function()
        while autoFarmEnabled do
            task.wait(0.15)
            if not char or not hrp or not hum then continue end
            if hum.Health <= 0 then task.wait(5) continue end

            if autoScrollEnabled and getLevel() >= TARGET_LEVEL then
                autoFarmEnabled = false
                notify("M HUB", "Lv.425 reached! Going to Marineford Shrine...")
                task.spawn(function()
                    tweenTo(CFrame.new(100, 7, -11000), "Marineford")
                    randWait(1, 2)
                    tweenTo(SHRINE_CF, "Shrine NPC")
                    task.wait(1)
                    for _, v in pairs(workspace:GetDescendants()) do
                        local n = v.Name:lower()
                        if n:find("shrine") or n:find("altar") or n:find("oracle") then
                            local click = v:FindFirstChildOfClass("ClickDetector")
                                or (v:IsA("Model") and v:FindFirstChildWhichIsA("ClickDetector"))
                            if click then
                                randWait(0.5, 1.5)
                                pcall(function() fireclickdetector(click) end)
                            end
                        end
                    end
                    notify("M HUB", "✅ Done! Check inventory for World Scroll.")
                end)
                break
            end

            local mob = getNearestMob()
            if mob then
                attackMob(mob)
            else
                local FISHMAN_CF = ISLANDS["Fishman Island"]
                hrp.CFrame = FISHMAN_CF * CFrame.new(math.random(-30, 30), 0, math.random(-30, 30))
                randWait(1.5, 3)
            end
        end
    end)
end

local function stopFarm()
    autoFarmEnabled = false
end

-- =============================================
-- GUI
-- =============================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "MHUB"
ScreenGui.ResetOnSpawn   = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent         = (gethui and gethui()) or lp.PlayerGui

-- MAIN WINDOW
local Main = Instance.new("Frame")
Main.Name             = "Main"
Main.Size             = UDim2.new(0, 520, 0, 340)
Main.Position         = UDim2.new(0.5, -260, 0.5, -170)
Main.BackgroundColor3 = Color3.fromRGB(13, 13, 22)
Main.BorderSizePixel  = 0
Main.Active           = true
Main.Draggable        = true
Main.ClipsDescendants = true
Main.Parent           = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)

-- TITLE BAR
local TitleBar = Instance.new("Frame")
TitleBar.Size             = UDim2.new(1, 0, 0, 38)
TitleBar.BackgroundColor3 = Color3.fromRGB(0, 110, 210)
TitleBar.BorderSizePixel  = 0
TitleBar.Parent           = Main
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 12)

local TitleFix = Instance.new("Frame")
TitleFix.Size             = UDim2.new(1, 0, 0, 12)
TitleFix.Position         = UDim2.new(0, 0, 1, -12)
TitleFix.BackgroundColor3 = Color3.fromRGB(0, 110, 210)
TitleFix.BorderSizePixel  = 0
TitleFix.Parent           = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Text               = "M HUB"
TitleLabel.Size               = UDim2.new(1, -10, 1, 0)
TitleLabel.Position           = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Font               = Enum.Font.GothamBold
TitleLabel.TextSize           = 18
TitleLabel.TextColor3         = Color3.new(1, 1, 1)
TitleLabel.TextXAlignment     = Enum.TextXAlignment.Left
TitleLabel.Parent             = TitleBar

local SafeTag = Instance.new("TextLabel")
SafeTag.Text               = "🛡️ SAFE MODE"
SafeTag.Size               = UDim2.new(0, 100, 1, 0)
SafeTag.Position           = UDim2.new(1, -110, 0, 0)
SafeTag.BackgroundTransparency = 1
SafeTag.Font               = Enum.Font.GothamBold
SafeTag.TextSize           = 10
SafeTag.TextColor3         = Color3.fromRGB(80, 255, 140)
SafeTag.Parent             = TitleBar

-- SIDEBAR
local Sidebar = Instance.new("Frame")
Sidebar.Size             = UDim2.new(0, 130, 1, -38)
Sidebar.Position         = UDim2.new(0, 0, 0, 38)
Sidebar.BackgroundColor3 = Color3.fromRGB(8, 8, 16)
Sidebar.BorderSizePixel  = 0
Sidebar.Parent           = Main

-- CONTENT AREA
local Content = Instance.new("Frame")
Content.Size             = UDim2.new(1, -130, 1, -38)
Content.Position         = UDim2.new(0, 130, 0, 38)
Content.BackgroundColor3 = Color3.fromRGB(13, 13, 22)
Content.BorderSizePixel  = 0
Content.Parent           = Main

-- Divider between sidebar and content
local SideDiv = Instance.new("Frame")
SideDiv.Size             = UDim2.new(0, 1, 1, -38)
SideDiv.Position         = UDim2.new(0, 130, 0, 38)
SideDiv.BackgroundColor3 = Color3.fromRGB(0, 110, 210)
SideDiv.BackgroundTransparency = 0.6
SideDiv.BorderSizePixel  = 0
SideDiv.Parent           = Main

-- =============================================
-- TAB SYSTEM
-- =============================================
local tabs = {}
local tabPages = {}
local activeTab = nil
local activeIndicator = nil

local function switchTab(name)
    for n, page in pairs(tabPages) do
        page.Visible = (n == name)
    end
    for n, btn in pairs(tabs) do
        if n == name then
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.BackgroundColor3 = Color3.fromRGB(0, 110, 210)
            btn.BackgroundTransparency = 0.6
        else
            btn.TextColor3 = Color3.fromRGB(160, 160, 180)
            btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            btn.BackgroundTransparency = 1
        end
    end
    activeTab = name
end

local tabNames = {"Main", "Farm", "Traveling", "Settings"}
local tabY = 10

for _, name in ipairs(tabNames) do
    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.new(1, -8, 0, 34)
    btn.Position         = UDim2.new(0, 4, 0, tabY)
    btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    btn.BackgroundTransparency = 1
    btn.BorderSizePixel  = 0
    btn.Font             = Enum.Font.GothamSemibold
    btn.TextSize         = 13
    btn.TextColor3       = Color3.fromRGB(160, 160, 180)
    btn.Text             = name
    btn.TextXAlignment   = Enum.TextXAlignment.Left
    btn.Parent           = Sidebar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    -- Left accent bar
    local accent = Instance.new("Frame")
    accent.Size             = UDim2.new(0, 3, 0.6, 0)
    accent.Position         = UDim2.new(0, 0, 0.2, 0)
    accent.BackgroundColor3 = Color3.fromRGB(0, 140, 255)
    accent.BorderSizePixel  = 0
    accent.Visible          = false
    accent.Parent           = btn
    Instance.new("UICorner", accent).CornerRadius = UDim.new(0, 2)

    -- Page
    local page = Instance.new("Frame")
    page.Size             = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel  = 0
    page.Visible          = false
    page.Parent           = Content

    tabs[name]     = btn
    tabPages[name] = page

    btn.MouseButton1Click:Connect(function()
        switchTab(name)
        for n, b in pairs(tabs) do
            local acc = b:FindFirstChildOfClass("Frame")
            if acc then acc.Visible = (n == name) end
        end
    end)

    tabY = tabY + 38
end

-- =============================================
-- HELPERS FOR PAGE CONTENT
-- =============================================
local function makeLabel(parent, text, y, size, color)
    local lbl = Instance.new("TextLabel")
    lbl.Size               = UDim2.new(1, -20, 0, size or 20)
    lbl.Position           = UDim2.new(0, 10, 0, y)
    lbl.BackgroundTransparency = 1
    lbl.Font               = Enum.Font.GothamBold
    lbl.TextSize           = size or 13
    lbl.TextColor3         = color or Color3.fromRGB(0, 160, 255)
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    lbl.Text               = text
    lbl.Parent             = parent
    return lbl
end

local function makeToggle(parent, label, y, onEnable, onDisable)
    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.new(1, -20, 0, 34)
    btn.Position         = UDim2.new(0, 10, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
    btn.BorderSizePixel  = 0
    btn.Font             = Enum.Font.GothamSemibold
    btn.TextSize         = 13
    btn.TextColor3       = Color3.fromRGB(180, 180, 200)
    btn.Text             = "[ OFF ]  " .. label
    btn.TextXAlignment   = Enum.TextXAlignment.Left
    btn.Parent           = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)

    -- indent text
    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 10)
    pad.Parent = btn

    local state = false
    btn.MouseButton1Click:Connect(function()
        state = not state
        if state then
            btn.Text             = "[ ON ]   " .. label
            btn.BackgroundColor3 = Color3.fromRGB(0, 130, 70)
            btn.TextColor3       = Color3.fromRGB(255, 255, 255)
            if onEnable then onEnable() end
        else
            btn.Text             = "[ OFF ]  " .. label
            btn.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
            btn.TextColor3       = Color3.fromRGB(180, 180, 200)
            if onDisable then onDisable() end
        end
    end)
    return btn
end

local function makeButton(parent, label, y, callback)
    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.new(1, -20, 0, 34)
    btn.Position         = UDim2.new(0, 10, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(0, 110, 210)
    btn.BorderSizePixel  = 0
    btn.Font             = Enum.Font.GothamSemibold
    btn.TextSize         = 13
    btn.TextColor3       = Color3.new(1, 1, 1)
    btn.Text             = label
    btn.Parent           = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
    btn.MouseButton1Click:Connect(function()
        if callback then callback() end
    end)
    return btn
end

-- =============================================
-- MAIN TAB
-- =============================================
local mainPage = tabPages["Main"]

makeLabel(mainPage, "Welcome to M HUB", 15, 15, Color3.fromRGB(255, 255, 255))
makeLabel(mainPage, "Grand Piece Online — Safe Mode", 36, 11, Color3.fromRGB(80, 255, 140))

local lvlDisplay = makeLabel(mainPage, "Level: loading...", 65, 13, Color3.fromRGB(0, 180, 255))
local statusDisplay = makeLabel(mainPage, "Status: Idle", 85, 12, Color3.fromRGB(160, 160, 180))

makeLabel(mainPage, "────────────────────────", 108, 11, Color3.fromRGB(40, 40, 60))
makeLabel(mainPage, "• Go to Farm tab to start auto farming", 122, 11, Color3.fromRGB(140, 140, 160))
makeLabel(mainPage, "• Go to Traveling tab to tween to islands", 138, 11, Color3.fromRGB(140, 140, 160))
makeLabel(mainPage, "• All actions use Safe Mode delays", 154, 11, Color3.fromRGB(140, 140, 160))

-- =============================================
-- FARM TAB
-- =============================================
local farmPage = tabPages["Farm"]

makeLabel(farmPage, "Auto Farm", 12, 14, Color3.fromRGB(0, 180, 255))
makeLabel(farmPage, "Farms Fishman Island mobs", 30, 11, Color3.fromRGB(120, 120, 140))

makeToggle(farmPage, "Auto Farm Fishman", 52, function()
    task.spawn(function()
        tweenTo(ISLANDS["Fishman Island"], "Fishman Island")
        startFarm()
    end)
    statusDisplay.Text = "Status: ⚔️ Farming Fishman..."
end, function()
    stopFarm()
    statusDisplay.Text = "Status: Idle"
end)

makeLabel(farmPage, "Auto World Scroll", 100, 14, Color3.fromRGB(0, 180, 255))
makeLabel(farmPage, "Goes to shrine after reaching Lv.425", 118, 11, Color3.fromRGB(120, 120, 140))

makeToggle(farmPage, "Auto Get World Scroll", 140, function()
    autoScrollEnabled = true
end, function()
    autoScrollEnabled = false
end)

makeButton(farmPage, "Go to Shrine Now", 188, function()
    task.spawn(function()
        tweenTo(CFrame.new(100, 7, -11000), "Marineford")
        randWait(1, 2)
        tweenTo(SHRINE_CF, "Shrine NPC")
        task.wait(1)
        for _, v in pairs(workspace:GetDescendants()) do
            local n = v.Name:lower()
            if n:find("shrine") or n:find("altar") then
                local click = v:FindFirstChildOfClass("ClickDetector")
                    or (v:IsA("Model") and v:FindFirstChildWhichIsA("ClickDetector"))
                if click then
                    randWait(0.5, 1.2)
                    pcall(function() fireclickdetector(click) end)
                end
            end
        end
        notify("M HUB", "✅ Shrine interacted! Check inventory.")
    end)
end)

-- =============================================
-- TRAVELING TAB
-- =============================================
local travelPage = tabPages["Traveling"]

makeLabel(travelPage, "Tween to Island", 12, 14, Color3.fromRGB(0, 180, 255))
makeLabel(travelPage, "Click an island to travel there", 30, 11, Color3.fromRGB(120, 120, 140))

local islandList = {
    "Starter Island", "Shell's Town", "Gecko Island",
    "Baratie", "Arlong Park", "Skypiea",
    "Alabasta", "Thriller Bark", "Marineford", "Fishman Island"
}

-- Scrolling frame for islands
local scroll = Instance.new("ScrollingFrame")
scroll.Size             = UDim2.new(1, -10, 1, -55)
scroll.Position         = UDim2.new(0, 5, 0, 50)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel  = 0
scroll.ScrollBarThickness = 3
scroll.ScrollBarImageColor3 = Color3.fromRGB(0, 110, 210)
scroll.CanvasSize       = UDim2.new(0, 0, 0, #islandList * 40 + 10)
scroll.Parent           = travelPage

local sy = 5
for _, islandName in ipairs(islandList) do
    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.new(1, -10, 0, 32)
    btn.Position         = UDim2.new(0, 5, 0, sy)
    btn.BackgroundColor3 = Color3.fromRGB(18, 18, 32)
    btn.BorderSizePixel  = 0
    btn.Font             = Enum.Font.Gotham
    btn.TextSize         = 12
    btn.TextColor3       = Color3.fromRGB(180, 210, 255)
    btn.Text             = "➤  " .. islandName
    btn.TextXAlignment   = Enum.TextXAlignment.Left
    btn.Parent           = scroll
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 10)
    pad.Parent = btn

    btn.MouseButton1Click:Connect(function()
        local cf = ISLANDS[islandName]
        if cf then
            btn.BackgroundColor3 = Color3.fromRGB(0, 110, 210)
            task.spawn(function()
                tweenTo(cf, islandName)
                task.wait(1)
                btn.BackgroundColor3 = Color3.fromRGB(18, 18, 32)
            end)
        end
    end)

    sy = sy + 38
end

-- =============================================
-- SETTINGS TAB
-- =============================================
local settingsPage = tabPages["Settings"]

makeLabel(settingsPage, "Settings", 12, 14, Color3.fromRGB(0, 180, 255))

makeButton(settingsPage, "Close Hub", 45, function()
    ScreenGui:Destroy()
end)

makeButton(settingsPage, "Stop All Scripts", 88, function()
    autoFarmEnabled = false
    autoScrollEnabled = false
    notify("M HUB", "All scripts stopped.")
end)

makeLabel(settingsPage, "🛡️ Safe Mode is always ON", 135, 11, Color3.fromRGB(80, 255, 140))
makeLabel(settingsPage, "Tween Speed: 35 studs/sec", 152, 11, Color3.fromRGB(120, 120, 140))
makeLabel(settingsPage, "Attack Delay: 0.35–0.85s random", 168, 11, Color3.fromRGB(120, 120, 140))
makeLabel(settingsPage, "Random breaks every 12–22 attacks", 184, 11, Color3.fromRGB(120, 120, 140))

-- =============================================
-- LIVE STATUS UPDATE
-- =============================================
RunService.Heartbeat:Connect(function()
    local lvl = getLevel()
    lvlDisplay.Text    = "Level: " .. lvl .. " / " .. TARGET_LEVEL .. "  (" .. math.floor(math.clamp(lvl/TARGET_LEVEL,0,1)*100) .. "%)"
    if autoFarmEnabled then
        statusDisplay.Text = "Status: ⚔️ Farming..."
    elseif not autoFarmEnabled then
        -- keep whatever was last set
    end
end)

-- Start on Main tab
switchTab("Main")
tabs["Main"]:FindFirstChildOfClass("Frame").Visible = true

notify("M HUB", "Loaded! Use the sidebar to navigate.")
print("[M HUB] Loaded successfully.")

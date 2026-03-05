-- =============================================
--         M HUB — Grand Piece Online
--           FNR Hub Style Recreation
--              Executor: Volt
-- =============================================

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UIS          = game:GetService("UserInputService")

local lp   = Players.LocalPlayer
local char = lp.Character or lp.CharacterAdded:Wait()
local hrp  = char:WaitForChild("HumanoidRootPart")
local hum  = char:WaitForChild("Humanoid")

-- =============================================
-- CONFIG
-- =============================================
local TARGET_LEVEL  = 425
local FARM_RADIUS   = 50
local ATK_DELAY_MIN = 0.3
local ATK_DELAY_MAX = 0.8
local PAUSE_EVERY   = math.random(10, 18)
local PAUSE_MIN     = 2
local PAUSE_MAX     = 5

local ISLANDS = {
    ["Starter Island"]  = CFrame.new(3980,  7,   1270),
    ["Shell's Town"]    = CFrame.new(-3700, 7,   -400),
    ["Gecko Island"]    = CFrame.new(-2400, 7,   2700),
    ["Baratie"]         = CFrame.new(-5800, 7,   3000),
    ["Arlong Park"]     = CFrame.new(-6700, 7,    700),
    ["Skypiea"]         = CFrame.new(-300,  1507,-3000),
    ["Alabasta"]        = CFrame.new(8900,  7,  -1600),
    ["Thriller Bark"]   = CFrame.new(-9800, 7,  -2300),
    ["Marineford"]      = CFrame.new(100,   7, -11000),
    ["Fishman Island"]  = CFrame.new(-340, -2500,-14900),
}

local SHRINE_CF = CFrame.new(140, 12, -11200)

local FISHMAN_MOBS = {"fishman","arlong","merfolk","sea warrior","fisher tiger"}

-- =============================================
-- STATE
-- =============================================
local autoFarm    = false
local autoScroll  = false
local atkCount    = 0
local currentPage = "Main"

-- =============================================
-- UTILITY
-- =============================================
local function notify(t, m)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification",{Title=t,Text=m,Duration=4})
    end)
end

local function randWait(a, b) task.wait(a + math.random()*(b-a)) end

local function getLevel()
    for _, v in pairs(lp:GetDescendants()) do
        if (v.Name=="Level" or v.Name=="Lvl") and (v:IsA("IntValue") or v:IsA("NumberValue")) then
            return v.Value
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
-- SAFE TRAVEL (step-based, no physics kick)
-- =============================================
local function tweenTo(cf, label)
    if not hrp then return end
    notify("M HUB", "Traveling to "..label.."...")
    local s = hrp.Position
    local e = cf.Position
    local dist = (s - e).Magnitude
    local steps = math.clamp(math.floor(dist / 60), 10, 50)
    if hum then hum.PlatformStand = true end
    for i = 1, steps do
        if not hrp then break end
        local t    = i / steps
        local ease = t < 0.5 and (2*t*t) or (1-(-2*t+2)^2/2)
        hrp.CFrame = CFrame.new(s:Lerp(e, ease))
        task.wait(0.1)
    end
    hrp.CFrame = cf
    if hum then hum.PlatformStand = false end
    notify("M HUB", "Arrived at "..label.."!")
    randWait(0.5, 1.2)
end

-- =============================================
-- FARMING
-- =============================================
local function isFishman(m)
    local n = m.Name:lower()
    for _, k in ipairs(FISHMAN_MOBS) do if n:find(k) then return true end end
    return false
end

local function getNearestMob()
    local best, bd = nil, FARM_RADIUS
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v ~= char then
            local mh = v:FindFirstChildWhichIsA("Humanoid")
            local mr = v:FindFirstChild("HumanoidRootPart")
            if mh and mr and mh.Health > 0 and isFishman(v) then
                local d = (hrp.Position - mr.Position).Magnitude
                if d < bd then best, bd = v, d end
            end
        end
    end
    return best
end

local function attackMob(mob)
    local mr = mob:FindFirstChild("HumanoidRootPart")
    if not mr then return end
    hrp.CFrame = mr.CFrame * CFrame.new((math.random()-0.5)*2, 0, 3+math.random()*1.5)
    randWait(ATK_DELAY_MIN, ATK_DELAY_MAX)
    local click = mob:FindFirstChildOfClass("ClickDetector")
    if click then pcall(function() fireclickdetector(click) end) end
    atkCount = atkCount + 1
    if atkCount >= PAUSE_EVERY then
        atkCount = 0
        PAUSE_EVERY = math.random(10, 20)
        task.wait(math.random(PAUSE_MIN, PAUSE_MAX))
    end
end

local function startFarm()
    autoFarm = true
    task.spawn(function()
        tweenTo(ISLANDS["Fishman Island"], "Fishman Island")
        while autoFarm do
            task.wait(0.15)
            if not char or not hrp or not hum then continue end
            if hum.Health <= 0 then task.wait(5) continue end
            if autoScroll and getLevel() >= TARGET_LEVEL then
                autoFarm = false
                notify("M HUB", "Lv.425! Going to Shrine...")
                task.spawn(function()
                    tweenTo(ISLANDS["Marineford"], "Marineford")
                    tweenTo(SHRINE_CF, "Shrine NPC")
                    task.wait(1)
                    for _, v in pairs(workspace:GetDescendants()) do
                        local n = v.Name:lower()
                        if n:find("shrine") or n:find("altar") then
                            local c = v:FindFirstChildOfClass("ClickDetector")
                                or (v:IsA("Model") and v:FindFirstChildWhichIsA("ClickDetector"))
                            if c then randWait(0.5,1.2) pcall(function() fireclickdetector(c) end) end
                        end
                    end
                    notify("M HUB", "✅ Done! Check inventory.")
                end)
                break
            end
            local mob = getNearestMob()
            if mob then
                attackMob(mob)
            else
                hrp.CFrame = ISLANDS["Fishman Island"] * CFrame.new(math.random(-25,25),0,math.random(-25,25))
                randWait(1.5, 2.5)
            end
        end
    end)
end

-- =============================================
-- COLORS (FNR-style dark red theme → M HUB blue)
-- =============================================
local C = {
    BG        = Color3.fromRGB(12,  12,  18),   -- main bg
    Sidebar   = Color3.fromRGB(8,   8,   14),   -- sidebar bg
    Accent    = Color3.fromRGB(0,   110, 220),  -- blue accent
    AccentDim = Color3.fromRGB(0,   70,  150),  -- dimmed accent
    Active    = Color3.fromRGB(0,   110, 220),  -- active tab
    TabHover  = Color3.fromRGB(18,  18,  30),
    Text      = Color3.fromRGB(230, 230, 240),
    SubText   = Color3.fromRGB(140, 140, 160),
    Section   = Color3.fromRGB(200, 80,  80),   -- section header red like FNR
    RowBG     = Color3.fromRGB(18,  18,  28),
    ToggleOff = Color3.fromRGB(50,  50,  65),
    ToggleOn  = Color3.fromRGB(0,   130, 70),
    White     = Color3.new(1,1,1),
}

-- =============================================
-- GUI ROOT
-- =============================================
local gui = Instance.new("ScreenGui")
gui.Name          = "MHUB"
gui.ResetOnSpawn  = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent        = (gethui and gethui()) or lp.PlayerGui

-- =============================================
-- MAIN WINDOW
-- =============================================
local Win = Instance.new("Frame")
Win.Name             = "Window"
Win.Size             = UDim2.new(0, 580, 0, 370)
Win.Position         = UDim2.new(0.5,-290, 0.5,-185)
Win.BackgroundColor3 = C.BG
Win.BorderSizePixel  = 0
Win.Active           = true
Win.Draggable        = true
Win.ClipsDescendants = true
Win.Parent           = gui
Instance.new("UICorner", Win).CornerRadius = UDim.new(0, 10)

-- Drop shadow
local Sh = Instance.new("ImageLabel")
Sh.Size               = UDim2.new(1, 30, 1, 30)
Sh.Position           = UDim2.new(0,-15, 0,-15)
Sh.BackgroundTransparency = 1
Sh.Image              = "rbxassetid://5028857084"
Sh.ImageColor3        = Color3.fromRGB(0, 80, 180)
Sh.ImageTransparency  = 0.6
Sh.ScaleType          = Enum.ScaleType.Slice
Sh.SliceCenter        = Rect.new(24,24,276,276)
Sh.ZIndex             = 0
Sh.Parent             = Win

-- =============================================
-- TITLE BAR
-- =============================================
local TBar = Instance.new("Frame")
TBar.Size             = UDim2.new(1, 0, 0, 36)
TBar.BackgroundColor3 = C.AccentDim
TBar.BorderSizePixel  = 0
TBar.ZIndex           = 3
TBar.Parent           = Win

local TBarFix = Instance.new("Frame")
TBarFix.Size             = UDim2.new(1, 0, 0, 10)
TBarFix.Position         = UDim2.new(0, 0, 1, -10)
TBarFix.BackgroundColor3 = C.AccentDim
TBarFix.BorderSizePixel  = 0
TBarFix.ZIndex           = 3
TBarFix.Parent           = TBar

-- Hub icon dot
local Dot = Instance.new("Frame")
Dot.Size             = UDim2.new(0, 10, 0, 10)
Dot.Position         = UDim2.new(0, 12, 0.5, -5)
Dot.BackgroundColor3 = C.Accent
Dot.BorderSizePixel  = 0
Dot.ZIndex           = 4
Dot.Parent           = TBar
Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)

local TTitle = Instance.new("TextLabel")
TTitle.Text               = "M HUB"
TTitle.Size               = UDim2.new(0, 120, 1, 0)
TTitle.Position           = UDim2.new(0, 28, 0, 0)
TTitle.BackgroundTransparency = 1
TTitle.Font               = Enum.Font.GothamBold
TTitle.TextSize           = 15
TTitle.TextColor3         = C.White
TTitle.TextXAlignment     = Enum.TextXAlignment.Left
TTitle.ZIndex             = 4
TTitle.Parent             = TBar

local TSubtitle = Instance.new("TextLabel")
TSubtitle.Text               = "GPO — First Sea"
TSubtitle.Size               = UDim2.new(0, 180, 1, 0)
TSubtitle.Position           = UDim2.new(0, 100, 0, 0)
TSubtitle.BackgroundTransparency = 1
TSubtitle.Font               = Enum.Font.Gotham
TSubtitle.TextSize           = 12
TSubtitle.TextColor3         = C.SubText
TSubtitle.TextXAlignment     = Enum.TextXAlignment.Left
TSubtitle.ZIndex             = 4
TSubtitle.Parent             = TBar

-- Close button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size             = UDim2.new(0, 28, 0, 28)
CloseBtn.Position         = UDim2.new(1, -34, 0.5, -14)
CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
CloseBtn.BorderSizePixel  = 0
CloseBtn.Text             = "✕"
CloseBtn.Font             = Enum.Font.GothamBold
CloseBtn.TextSize         = 13
CloseBtn.TextColor3       = C.White
CloseBtn.ZIndex           = 5
CloseBtn.Parent           = TBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 5)
CloseBtn.MouseButton1Click:Connect(function() gui:Destroy() end)

-- Minimize button
local MinBtn = Instance.new("TextButton")
MinBtn.Size             = UDim2.new(0, 28, 0, 28)
MinBtn.Position         = UDim2.new(1, -68, 0.5, -14)
MinBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
MinBtn.BorderSizePixel  = 0
MinBtn.Text             = "—"
MinBtn.Font             = Enum.Font.GothamBold
MinBtn.TextSize         = 13
MinBtn.TextColor3       = C.White
MinBtn.ZIndex           = 5
MinBtn.Parent           = TBar
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 5)

local minimized = false
local ContentArea -- forward declare
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        Win.Size = UDim2.new(0, 580, 0, 36)
    else
        Win.Size = UDim2.new(0, 580, 0, 370)
    end
end)

-- =============================================
-- SIDEBAR
-- =============================================
local Sidebar = Instance.new("Frame")
Sidebar.Name             = "Sidebar"
Sidebar.Size             = UDim2.new(0, 140, 1, -36)
Sidebar.Position         = UDim2.new(0, 0, 0, 36)
Sidebar.BackgroundColor3 = C.Sidebar
Sidebar.BorderSizePixel  = 0
Sidebar.ZIndex           = 2
Sidebar.Parent           = Win

-- Sidebar divider
local SDiv = Instance.new("Frame")
SDiv.Size             = UDim2.new(0, 1, 1, 0)
SDiv.Position         = UDim2.new(1, 0, 0, 0)
SDiv.BackgroundColor3 = C.Accent
SDiv.BackgroundTransparency = 0.7
SDiv.BorderSizePixel  = 0
SDiv.Parent           = Sidebar

-- Hub name in sidebar
local SHubName = Instance.new("TextLabel")
SHubName.Text               = "M HUB"
SHubName.Size               = UDim2.new(1, -10, 0, 36)
SHubName.Position           = UDim2.new(0, 10, 0, 8)
SHubName.BackgroundTransparency = 1
SHubName.Font               = Enum.Font.GothamBold
SHubName.TextSize           = 14
SHubName.TextColor3         = C.Accent
SHubName.TextXAlignment     = Enum.TextXAlignment.Left
SHubName.Parent             = Sidebar

-- Sidebar divider line
local SLine = Instance.new("Frame")
SLine.Size             = UDim2.new(0.85, 0, 0, 1)
SLine.Position         = UDim2.new(0.075, 0, 0, 46)
SLine.BackgroundColor3 = C.Accent
SLine.BackgroundTransparency = 0.7
SLine.BorderSizePixel  = 0
SLine.Parent           = Sidebar

-- =============================================
-- CONTENT AREA
-- =============================================
ContentArea = Instance.new("Frame")
ContentArea.Name             = "Content"
ContentArea.Size             = UDim2.new(1, -141, 1, -36)
ContentArea.Position         = UDim2.new(0, 141, 0, 36)
ContentArea.BackgroundColor3 = C.BG
ContentArea.BorderSizePixel  = 0
ContentArea.ClipsDescendants = true
ContentArea.Parent           = Win

-- =============================================
-- TAB SYSTEM
-- =============================================
local tabBtns  = {}
local tabPages = {}
local activeTabName = nil

local tabDefs = {
    "Main", "Farm", "Fishing", "Merchant",
    "Auto Stats", "Traveling", "Private Server", "Misc", "Settings"
}

local function setTab(name)
    activeTabName = name
    for n, page in pairs(tabPages) do
        page.Visible = (n == name)
    end
    for n, btn in pairs(tabBtns) do
        if n == name then
            btn.TextColor3       = C.White
            btn.BackgroundColor3 = C.Active
            btn.BackgroundTransparency = 0.75
        else
            btn.TextColor3       = C.SubText
            btn.BackgroundColor3 = C.BG
            btn.BackgroundTransparency = 1
        end
    end
end

local tabY = 54
for _, name in ipairs(tabDefs) do
    -- Active indicator bar
    local indicator = Instance.new("Frame")
    indicator.Size             = UDim2.new(0, 3, 0.55, 0)
    indicator.Position         = UDim2.new(0, 0, 0.225, 0)
    indicator.BackgroundColor3 = C.Accent
    indicator.BorderSizePixel  = 0
    indicator.Visible          = false

    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.new(1, -4, 0, 30)
    btn.Position         = UDim2.new(0, 2, 0, tabY)
    btn.BackgroundColor3 = C.BG
    btn.BackgroundTransparency = 1
    btn.BorderSizePixel  = 0
    btn.Font             = Enum.Font.GothamSemibold
    btn.TextSize         = 13
    btn.TextColor3       = C.SubText
    btn.Text             = name
    btn.TextXAlignment   = Enum.TextXAlignment.Left
    btn.ZIndex           = 3
    btn.Parent           = Sidebar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 14)
    pad.Parent = btn

    indicator.Parent = btn

    local page = Instance.new("ScrollingFrame")
    page.Name                = name
    page.Size                = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel     = 0
    page.ScrollBarThickness  = 3
    page.ScrollBarImageColor3 = C.Accent
    page.CanvasSize          = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Visible             = false
    page.Parent              = ContentArea

    tabBtns[name]  = btn
    tabPages[name] = page

    btn.MouseButton1Click:Connect(function()
        setTab(name)
        for n, b in pairs(tabBtns) do
            local ind = b:FindFirstChildOfClass("Frame")
            if ind then ind.Visible = (n == name) end
        end
    end)

    tabY = tabY + 32
end

-- =============================================
-- PAGE BUILDER HELPERS
-- =============================================
local function addSection(page, title)
    local lbl = Instance.new("TextLabel")
    lbl.Size               = UDim2.new(1, -20, 0, 28)
    lbl.BackgroundTransparency = 1
    lbl.Font               = Enum.Font.GothamBold
    lbl.TextSize           = 12
    lbl.TextColor3         = C.Section
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    lbl.Text               = title
    lbl.LayoutOrder        = 1
    lbl.Parent             = page
    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0,12)
    pad.Parent = lbl
    return lbl
end

local function addRow(page, title, subtitle, rightWidget)
    local row = Instance.new("Frame")
    row.Size             = UDim2.new(1, -10, 0, subtitle ~= "" and 52 or 38)
    row.BackgroundColor3 = C.RowBG
    row.BorderSizePixel  = 0
    row.LayoutOrder      = 2
    row.Parent           = page
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 12)
    pad.Parent = row

    local tl = Instance.new("TextLabel")
    tl.Size               = UDim2.new(0.7, 0, 0, 22)
    tl.Position           = subtitle ~= "" and UDim2.new(0,0,0,8) or UDim2.new(0,0,0.5,-10)
    tl.BackgroundTransparency = 1
    tl.Font               = Enum.Font.GothamSemibold
    tl.TextSize           = 13
    tl.TextColor3         = C.Text
    tl.TextXAlignment     = Enum.TextXAlignment.Left
    tl.Text               = title
    tl.Parent             = row

    if subtitle ~= "" then
        local sl = Instance.new("TextLabel")
        sl.Size               = UDim2.new(0.75, 0, 0, 18)
        sl.Position           = UDim2.new(0, 0, 0, 28)
        sl.BackgroundTransparency = 1
        sl.Font               = Enum.Font.Gotham
        sl.TextSize           = 11
        sl.TextColor3         = C.SubText
        sl.TextXAlignment     = Enum.TextXAlignment.Left
        sl.Text               = subtitle
        sl.TextWrapped        = true
        sl.Parent             = row
    end

    if rightWidget then rightWidget(row) end
    return row
end

-- Toggle checkbox (like FNR red square → M HUB blue)
local function addToggle(page, title, subtitle, onEnable, onDisable)
    local state = false
    addRow(page, title, subtitle, function(row)
        local box = Instance.new("TextButton")
        box.Size             = UDim2.new(0, 22, 0, 22)
        box.Position         = UDim2.new(1, -34, 0.5, -11)
        box.BackgroundColor3 = C.ToggleOff
        box.BorderSizePixel  = 0
        box.Text             = ""
        box.ZIndex           = 3
        box.Parent           = row
        Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)

        local check = Instance.new("TextLabel")
        check.Size               = UDim2.new(1,0,1,0)
        check.BackgroundTransparency = 1
        check.Font               = Enum.Font.GothamBold
        check.TextSize           = 14
        check.TextColor3         = C.White
        check.Text               = ""
        check.Parent             = box

        box.MouseButton1Click:Connect(function()
            state = not state
            if state then
                box.BackgroundColor3 = C.Accent
                check.Text           = "✓"
                if onEnable then onEnable() end
            else
                box.BackgroundColor3 = C.ToggleOff
                check.Text           = ""
                if onDisable then onDisable() end
            end
        end)
    end)
end

-- Arrow button row (dropdown style like FNR)
local function addArrow(page, label, sublabel, onClick)
    addRow(page, label, sublabel, function(row)
        local arr = Instance.new("TextButton")
        arr.Size             = UDim2.new(0, 28, 0, 28)
        arr.Position         = UDim2.new(1, -36, 0.5, -14)
        arr.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
        arr.BorderSizePixel  = 0
        arr.Text             = "›"
        arr.Font             = Enum.Font.GothamBold
        arr.TextSize         = 18
        arr.TextColor3       = C.SubText
        arr.ZIndex           = 3
        arr.Parent           = row
        Instance.new("UICorner", arr).CornerRadius = UDim.new(0, 5)
        if onClick then
            row.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then onClick() end
            end)
            arr.MouseButton1Click:Connect(onClick)
        end
    end)
end

-- Spacer
local function addSpacer(page, h)
    local s = Instance.new("Frame")
    s.Size               = UDim2.new(1, 0, 0, h or 6)
    s.BackgroundTransparency = 1
    s.LayoutOrder        = 0
    s.Parent             = page
end

-- List layout for all pages
local function addLayout(page)
    local layout = Instance.new("UIListLayout")
    layout.SortOrder      = Enum.SortOrder.LayoutOrder
    layout.Padding        = UDim.new(0, 5)
    layout.Parent         = page
    local pad = Instance.new("UIPadding")
    pad.PaddingLeft   = UDim.new(0, 5)
    pad.PaddingTop    = UDim.new(0, 8)
    pad.PaddingRight  = UDim.new(0, 5)
    pad.PaddingBottom = UDim.new(0, 8)
    pad.Parent        = page
end

-- =============================================
-- PAGE: MAIN
-- =============================================
local mainPage = tabPages["Main"]
addLayout(mainPage)
addSpacer(mainPage, 4)

local lvlRow = addRow(mainPage, "Level", "", nil)
local lvlVal = Instance.new("TextLabel")
lvlVal.Size               = UDim2.new(0, 80, 1, 0)
lvlVal.Position           = UDim2.new(1, -90, 0, 0)
lvlVal.BackgroundTransparency = 1
lvlVal.Font               = Enum.Font.GothamBold
lvlVal.TextSize           = 13
lvlVal.TextColor3         = C.Accent
lvlVal.Text               = "..."
lvlVal.TextXAlignment     = Enum.TextXAlignment.Right
lvlVal.Parent             = lvlRow

addRow(mainPage, "Hub", "M HUB — Grand Piece Online", nil)
addRow(mainPage, "Safe Mode", "Human-like delays & step travel active", nil)
addSpacer(mainPage, 4)
addSection(mainPage, "Quick Info")
addRow(mainPage, "Farm Tab", "Auto farm Fishman Island mobs", nil)
addRow(mainPage, "Traveling Tab", "Tween to any island", nil)
addRow(mainPage, "Merchant Tab", "Auto merchant features", nil)

-- =============================================
-- PAGE: FARM
-- =============================================
local farmPage = tabPages["Farm"]
addLayout(farmPage)
addSection(farmPage, "Farm")

addToggle(farmPage, "Auto Farm Fishman Island", "Farms mobs until Lv.425 with safe delays",
    function()
        startFarm()
    end,
    function()
        autoFarm = false
        notify("M HUB", "Auto Farm stopped.")
    end
)

addToggle(farmPage, "Auto World Scroll", "Goes to Marineford shrine after Lv.425",
    function() autoScroll = true end,
    function() autoScroll = false end
)

addSpacer(farmPage)
addSection(farmPage, "Manual")

addArrow(farmPage, "Go to Shrine Now", "Teleport to Marineford shrine NPC", function()
    task.spawn(function()
        tweenTo(ISLANDS["Marineford"], "Marineford")
        tweenTo(SHRINE_CF, "Shrine NPC")
        task.wait(1)
        for _, v in pairs(workspace:GetDescendants()) do
            local n = v.Name:lower()
            if n:find("shrine") or n:find("altar") then
                local c = v:FindFirstChildOfClass("ClickDetector")
                    or (v:IsA("Model") and v:FindFirstChildWhichIsA("ClickDetector"))
                if c then randWait(0.5,1.2) pcall(function() fireclickdetector(c) end) end
            end
        end
        notify("M HUB", "✅ Check inventory for World Scroll!")
    end)
end)

addArrow(farmPage, "Stop All Farming", "Stops auto farm immediately", function()
    autoFarm   = false
    autoScroll = false
    notify("M HUB", "Farming stopped.")
end)

-- =============================================
-- PAGE: FISHING
-- =============================================
local fishingPage = tabPages["Fishing"]
addLayout(fishingPage)
addSection(fishingPage, "Fishing")
addToggle(fishingPage, "Auto Fish", "Automatically casts and reels in fishing rod", nil, nil)
addToggle(fishingPage, "Auto Sell Fish", "Sells fish automatically after catching", nil, nil)
addSpacer(fishingPage)
addSection(fishingPage, "Settings")
addArrow(fishingPage, "Fish Location", "Current island", nil)

-- =============================================
-- PAGE: MERCHANT
-- =============================================
local merchantPage = tabPages["Merchant"]
addLayout(merchantPage)
addSection(merchantPage, "Merchant")
addToggle(merchantPage, "Auto Merchant", "Automatically find merchants and purchase the requested items.",
    function() notify("M HUB", "Auto Merchant ON") end,
    function() notify("M HUB", "Auto Merchant OFF") end
)
addArrow(merchantPage, "Method Find Merchant: Until Max Peli", "", nil)
addSpacer(merchantPage)
addSection(merchantPage, "Items To Buy")
addArrow(merchantPage, "Items: Mythical Fruit Chest", "", nil)

-- =============================================
-- PAGE: AUTO STATS
-- =============================================
local statsPage = tabPages["Auto Stats"]
addLayout(statsPage)
addSection(statsPage, "Auto Stats")
addToggle(statsPage, "Auto Assign Stats", "Automatically assigns stat points on level up",
    function() notify("M HUB", "Auto Stats ON") end,
    function() notify("M HUB", "Auto Stats OFF") end
)
addSpacer(statsPage)
addSection(statsPage, "Stat Build")
addArrow(statsPage, "Build: Melee", "Focus all points into Melee stat", nil)
addArrow(statsPage, "Build: Sword", "Focus all points into Sword stat", nil)
addArrow(statsPage, "Build: Devil Fruit", "Focus all points into DF stat", nil)

-- =============================================
-- PAGE: TRAVELING
-- =============================================
local travelPage = tabPages["Traveling"]
addLayout(travelPage)
addSection(travelPage, "Traveling")

for islandName, cf in pairs(ISLANDS) do
    local captured = cf
    local capturedName = islandName
    addArrow(travelPage, islandName, "Tween to "..islandName, function()
        task.spawn(function()
            tweenTo(captured, capturedName)
        end)
    end)
end

-- =============================================
-- PAGE: PRIVATE SERVER
-- =============================================
local psPage = tabPages["Private Server"]
addLayout(psPage)
addSection(psPage, "Private Server")
addToggle(psPage, "Auto Rejoin Private Server", "Automatically rejoins your private server on disconnect",
    nil, nil
)
addArrow(psPage, "Private Server Link", "Set your private server URL", nil)

-- =============================================
-- PAGE: MISC
-- =============================================
local miscPage = tabPages["Misc"]
addLayout(miscPage)
addSection(miscPage, "Misc")
addToggle(miscPage, "No Clip", "Walk through walls",
    function()
        RunService.Stepped:Connect(function()
            if char then
                for _, p in pairs(char:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end
            end
        end)
    end,
    nil
)
addToggle(miscPage, "Infinite Jump", "Jump in mid-air",
    function()
        UIS.JumpRequest:Connect(function()
            if char and hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
        notify("M HUB", "Infinite Jump ON")
    end,
    nil
)
addToggle(miscPage, "Speed Boost", "Increases walk speed to 32",
    function() if hum then hum.WalkSpeed = 32 end end,
    function() if hum then hum.WalkSpeed = 16 end end
)
addArrow(miscPage, "Reset Character", "Kills your character", function()
    if hum then hum.Health = 0 end
end)

-- =============================================
-- PAGE: SETTINGS
-- =============================================
local settPage = tabPages["Settings"]
addLayout(settPage)
addSection(settPage, "Settings")
addRow(settPage, "Safe Mode", "Always ON — human-like delays active", nil)
addRow(settPage, "Tween Speed", "Step-based, ~60 studs per step", nil)
addRow(settPage, "Attack Delay", "0.3–0.8s randomized per hit", nil)
addSpacer(settPage)
addSection(settPage, "Hub")
addArrow(settPage, "Close M HUB", "Destroys the hub GUI", function()
    gui:Destroy()
end)
addArrow(settPage, "Stop All Scripts", "Stops farming and all loops", function()
    autoFarm   = false
    autoScroll = false
    notify("M HUB", "All scripts stopped.")
end)

-- =============================================
-- LIVE UPDATE
-- =============================================
RunService.Heartbeat:Connect(function()
    local lvl = getLevel()
    lvlVal.Text = tostring(lvl) .. " / " .. TARGET_LEVEL
end)

-- Start on Main tab
setTab("Main")
for n, b in pairs(tabBtns) do
    local ind = b:FindFirstChildOfClass("Frame")
    if ind then ind.Visible = (n == "Main") end
end

notify("M HUB", "Loaded! Welcome to M HUB.")
print("[M HUB] Loaded successfully.")

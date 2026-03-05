-- =============================================
--           M HUB — Grand Piece Online
--         Fishman Farm → World Scroll
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
-- SAFE CONFIG
-- =============================================
local TARGET_LEVEL  = 425
local FARM_RADIUS   = 45

-- Slow human-like tween speed (was 120, now 35)
local TWEEN_SPEED   = 35

-- Random attack delay range (seconds) — mimics real player reaction time
local ATK_DELAY_MIN = 0.35
local ATK_DELAY_MAX = 0.85

-- Random break every N attacks
local PAUSE_EVERY   = math.random(12, 20)
local PAUSE_MIN     = 2
local PAUSE_MAX     = 6

local FISHMAN_CF    = CFrame.new(-340, -2500, -14900)
local MARINEFORD_CF = CFrame.new(100, 7, -11000)
local SHRINE_CF     = CFrame.new(140, 12, -11200)

local FISHMAN_MOBS  = {
    "fishman", "arlong", "merfolk", "sea warrior", "fisher tiger"
}

-- =============================================
-- STATE
-- =============================================
local State = {
    phase   = "idle",
    status  = "Waiting...",
    farming = false,
}

local attackCount = 0

-- =============================================
-- UTILITY
-- =============================================
local function notify(title, text)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title, Text = text, Duration = 5,
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
    task.wait(4)
    if State.farming and getLevel() < TARGET_LEVEL then
        State.status = "⚔️ Respawned — resuming..."
    end
end)

-- =============================================
-- SAFE TWEEN — splits trip into 3 segments
-- with small pauses between, looks like sailing
-- =============================================
local function tweenTo(cf, label)
    if not hrp then return end
    State.status = "✈️ Moving to " .. label .. "..."

    local startPos = hrp.Position
    local endPos   = cf.Position
    local dist     = (startPos - endPos).Magnitude
    local segments = 3

    for i = 1, segments do
        if not hrp then break end
        local t     = i / segments
        local midPos = startPos:Lerp(endPos, t)
        local midCF  = CFrame.new(midPos) * (cf - cf.Position)

        local segDist = dist / segments
        local segDur  = math.clamp(segDist / TWEEN_SPEED, 0.5, 30)

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

        if i < segments then
            randWait(0.3, 1.2) -- brief pause between segments
        end
    end

    State.status = "📍 Arrived at " .. label
    notify("M HUB", "Arrived at " .. label .. "!")
    randWait(1, 2.5)
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

    -- Slight random offset so position isn't always identical
    local offsetX = (math.random() - 0.5) * 2
    local offsetZ = 3 + math.random() * 1.5
    hrp.CFrame = mobHRP.CFrame * CFrame.new(offsetX, 0, offsetZ)

    -- Human-like reaction delay before swinging
    randWait(ATK_DELAY_MIN, ATK_DELAY_MAX)

    local tool = char:FindFirstChildOfClass("Tool")
    if tool then
        for _, v in pairs(tool:GetDescendants()) do
            if v:IsA("RemoteEvent") then
                pcall(function() v:FireServer() end)
            end
        end
    end

    local click = mob:FindFirstChildOfClass("ClickDetector")
    if click then pcall(function() fireclickdetector(click) end) end

    -- Take random breaks to simulate a real player
    attackCount = attackCount + 1
    if attackCount >= PAUSE_EVERY then
        attackCount = 0
        PAUSE_EVERY = math.random(12, 22)
        local pauseTime = math.random(PAUSE_MIN, PAUSE_MAX)
        State.status = "💤 Short break (" .. pauseTime .. "s)..."
        task.wait(pauseTime)
    end
end

-- =============================================
-- WORLD SCROLL
-- =============================================
local function getWorldScroll()
    State.phase  = "toShrine"
    State.status = "✈️ Heading to Marineford Shrine..."
    notify("M HUB", "Lv.425 reached! Going to Marineford Shrine...")

    randWait(2, 4) -- pause before leaving like checking map

    tweenTo(MARINEFORD_CF, "Marineford")
    randWait(1, 3)
    tweenTo(SHRINE_CF, "Shrine NPC")
    randWait(1, 2)

    State.status = "🛕 Interacting with Shrine..."

    local interacted = false
    for _, v in pairs(workspace:GetDescendants()) do
        local name = v.Name:lower()
        if name:find("shrine") or name:find("scroll") or name:find("altar") or name:find("oracle") then
            local click = v:FindFirstChildOfClass("ClickDetector")
                or (v:IsA("Model") and v:FindFirstChildWhichIsA("ClickDetector"))
            if click then
                randWait(0.5, 1.5)
                pcall(function() fireclickdetector(click) end)
                interacted = true
                randWait(0.8, 1.5)
            end
        end
    end

    for _, remote in pairs(game:GetDescendants()) do
        if remote:IsA("RemoteEvent") then
            local name = remote.Name:lower()
            if name:find("shrine") or name:find("scroll") or name:find("world") or name:find("altar") then
                pcall(function() remote:FireServer() end)
                interacted = true
                randWait(0.4, 0.9)
            end
        end
    end

    randWait(1, 2)
    State.phase  = "scrollDone"

    if interacted then
        State.status = "✅ World Scroll obtained!"
        notify("M HUB", "✅ World Scroll obtained! All done.")
    else
        State.status = "⚠️ Shrine clicked — check inventory!"
        notify("M HUB", "⚠️ Clicked Shrine — check your inventory.")
    end
end

-- =============================================
-- MAIN SEQUENCE
-- =============================================
task.spawn(function()
    task.wait(3)

    if getLevel() >= TARGET_LEVEL then
        notify("M HUB", "Already Lv.425! Heading to Shrine...")
        getWorldScroll()
        return
    end

    State.phase = "tweening"
    randWait(1, 2)
    tweenTo(FISHMAN_CF, "Fishman Island")

    State.phase   = "farming"
    State.farming = true
    State.status  = "⚔️ Farming Fishman mobs..."
    notify("M HUB", "Farming Fishman Island → Target Lv." .. TARGET_LEVEL)

    while State.farming do
        task.wait(0.15)
        if not char or not hrp or not hum then continue end
        if hum.Health <= 0 then
            task.wait(5)
            continue
        end

        if getLevel() >= TARGET_LEVEL then
            State.farming = false
            break
        end

        local mob = getNearestMob()
        if mob then
            attackMob(mob)
            State.status = "⚔️ Farming: " .. mob.Name
        else
            local rx = math.random(-30, 30)
            local rz = math.random(-30, 30)
            hrp.CFrame = FISHMAN_CF * CFrame.new(rx, 0, rz)
            State.status = "🔍 Looking for mobs..."
            randWait(1.5, 3)
        end
    end

    getWorldScroll()
end)

-- =============================================
-- GUI — M HUB
-- =============================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "MHUB"
ScreenGui.ResetOnSpawn   = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent         = (gethui and gethui()) or lp.PlayerGui

local Main = Instance.new("Frame")
Main.Name             = "Main"
Main.Size             = UDim2.new(0, 280, 0, 165)
Main.Position         = UDim2.new(0, 20, 0, 20)
Main.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
Main.BorderSizePixel  = 0
Main.Active           = true
Main.Draggable        = true
Main.ClipsDescendants = true
Main.Parent           = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)

local Shadow = Instance.new("Frame")
Shadow.Size                   = UDim2.new(1, 8, 1, 8)
Shadow.Position               = UDim2.new(0, -4, 0, -4)
Shadow.BackgroundColor3       = Color3.fromRGB(0, 100, 200)
Shadow.BackgroundTransparency = 0.85
Shadow.BorderSizePixel        = 0
Shadow.ZIndex                 = 0
Shadow.Parent                 = Main
Instance.new("UICorner", Shadow).CornerRadius = UDim.new(0, 14)

local TopBar = Instance.new("Frame")
TopBar.Size             = UDim2.new(1, 0, 0, 44)
TopBar.BackgroundColor3 = Color3.fromRGB(0, 120, 220)
TopBar.BorderSizePixel  = 0
TopBar.ZIndex           = 2
TopBar.Parent           = Main
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 12)

local TopBarFix = Instance.new("Frame")
TopBarFix.Size             = UDim2.new(1, 0, 0, 12)
TopBarFix.Position         = UDim2.new(0, 0, 1, -12)
TopBarFix.BackgroundColor3 = Color3.fromRGB(0, 120, 220)
TopBarFix.BorderSizePixel  = 0
TopBarFix.ZIndex           = 2
TopBarFix.Parent           = TopBar

local HubName = Instance.new("TextLabel")
HubName.Text               = "M HUB"
HubName.Size               = UDim2.new(1, 0, 1, 0)
HubName.BackgroundTransparency = 1
HubName.Font               = Enum.Font.GothamBold
HubName.TextSize           = 20
HubName.TextColor3         = Color3.new(1, 1, 1)
HubName.ZIndex             = 3
HubName.Parent             = TopBar

local SafeBadge = Instance.new("TextLabel")
SafeBadge.Text               = "🛡️ SAFE MODE"
SafeBadge.Size               = UDim2.new(0.9, 0, 0, 16)
SafeBadge.Position           = UDim2.new(0.05, 0, 0, 46)
SafeBadge.BackgroundTransparency = 1
SafeBadge.Font               = Enum.Font.GothamBold
SafeBadge.TextSize           = 10
SafeBadge.TextColor3         = Color3.fromRGB(80, 255, 140)
SafeBadge.TextXAlignment     = Enum.TextXAlignment.Left
SafeBadge.Parent             = Main

local Divider = Instance.new("Frame")
Divider.Size             = UDim2.new(0.9, 0, 0, 1)
Divider.Position         = UDim2.new(0.05, 0, 0, 65)
Divider.BackgroundColor3 = Color3.fromRGB(0, 120, 220)
Divider.BackgroundTransparency = 0.5
Divider.BorderSizePixel  = 0
Divider.Parent           = Main

local PhaseLabel = Instance.new("TextLabel")
PhaseLabel.Size           = UDim2.new(0.9, 0, 0, 20)
PhaseLabel.Position       = UDim2.new(0.05, 0, 0, 70)
PhaseLabel.BackgroundTransparency = 1
PhaseLabel.Font           = Enum.Font.GothamBold
PhaseLabel.TextSize       = 12
PhaseLabel.TextColor3     = Color3.fromRGB(0, 180, 255)
PhaseLabel.TextXAlignment = Enum.TextXAlignment.Left
PhaseLabel.Text           = "PHASE: Initializing"
PhaseLabel.Parent         = Main

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size           = UDim2.new(0.9, 0, 0, 34)
StatusLabel.Position       = UDim2.new(0.05, 0, 0, 90)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Font           = Enum.Font.Gotham
StatusLabel.TextSize       = 12
StatusLabel.TextColor3     = Color3.fromRGB(200, 225, 255)
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.TextWrapped    = true
StatusLabel.Text           = "Starting up..."
StatusLabel.Parent         = Main

local LvlBarBG = Instance.new("Frame")
LvlBarBG.Size             = UDim2.new(0.9, 0, 0, 12)
LvlBarBG.Position         = UDim2.new(0.05, 0, 0, 132)
LvlBarBG.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
LvlBarBG.BorderSizePixel  = 0
LvlBarBG.Parent           = Main
Instance.new("UICorner", LvlBarBG).CornerRadius = UDim.new(0, 6)

local LvlBarFill = Instance.new("Frame")
LvlBarFill.Size             = UDim2.new(0, 0, 1, 0)
LvlBarFill.BackgroundColor3 = Color3.fromRGB(0, 160, 255)
LvlBarFill.BorderSizePixel  = 0
LvlBarFill.Parent           = LvlBarBG
Instance.new("UICorner", LvlBarFill).CornerRadius = UDim.new(0, 6)

local LvlText = Instance.new("TextLabel")
LvlText.Size              = UDim2.new(0.9, 0, 0, 16)
LvlText.Position          = UDim2.new(0.05, 0, 0, 146)
LvlText.BackgroundTransparency = 1
LvlText.Font              = Enum.Font.GothamSemibold
LvlText.TextSize          = 11
LvlText.TextColor3        = Color3.fromRGB(100, 200, 255)
LvlText.TextXAlignment    = Enum.TextXAlignment.Left
LvlText.Text              = "Level: ... / 425"
LvlText.Parent            = Main

local phaseColors = {
    idle       = Color3.fromRGB(120, 120, 120),
    tweening   = Color3.fromRGB(0, 180, 255),
    farming    = Color3.fromRGB(255, 160, 0),
    toShrine   = Color3.fromRGB(180, 80, 255),
    scrollDone = Color3.fromRGB(50, 220, 100),
}

local phaseNames = {
    idle       = "IDLE",
    tweening   = "TWEENING",
    farming    = "FARMING",
    toShrine   = "TO SHRINE",
    scrollDone = "COMPLETE",
}

RunService.Heartbeat:Connect(function()
    local lvl   = getLevel()
    local pct   = math.clamp(lvl / TARGET_LEVEL, 0, 1)
    local phase = State.phase
    local color = phaseColors[phase] or Color3.fromRGB(0, 120, 220)
    local pname = phaseNames[phase] or phase:upper()

    LvlBarFill.Size             = UDim2.new(pct, 0, 1, 0)
    LvlBarFill.BackgroundColor3 = color
    LvlText.Text                = "Level: " .. lvl .. " / " .. TARGET_LEVEL .. "  (" .. math.floor(pct * 100) .. "%)"
    PhaseLabel.Text             = "PHASE: " .. pname
    PhaseLabel.TextColor3       = color
    StatusLabel.Text            = State.status
    TopBar.BackgroundColor3     = color
    TopBarFix.BackgroundColor3  = color
end)

notify("M HUB", "🛡️ Safe Mode ON — Starting Fishman Farm...")
print("[M HUB] Loaded in Safe Mode.")

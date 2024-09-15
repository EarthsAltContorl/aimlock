-- Improved Aimlock by earthdhc (bezzer included~!)
-- Modified to use a large red circle for targeting

getgenv().Config = {
    Prediction = 0.13,
    AimPart = "HumanoidRootPart",
    Key = "C",
    DisableKey = "X",
    FOV = true,
    ShowFOV = false,
    FOVSize = 55,
    AutoPrediction = true,
    CircleSize = 20, -- Size of the red circle
    CircleColor = Color3.fromRGB(255, 0, 0) -- Red color for the circle
}

-- Services
local Players = game:GetService("Players")
local RS = game:GetService("RunService")
local WS = game:GetService("Workspace")
local GS = game:GetService("GuiService")
local SG = game:GetService("StarterGui")

-- Locals
local LP = Players.LocalPlayer
local Mouse = LP:GetMouse()
local Camera = WS.CurrentCamera
local GetGuiInset = GS.GetGuiInset

-- Aimlock variables
local AimlockState = true
local Locked = false
local Victim

-- FOV Circle
local fov = Drawing.new("Circle")
fov.Filled = false
fov.Transparency = 1
fov.Thickness = 1
fov.Color = Color3.fromRGB(255, 255, 0)
fov.NumSides = 100

-- Target Circle
local targetCircle = Drawing.new("Circle")
targetCircle.Filled = false
targetCircle.Transparency = 1
targetCircle.Thickness = 2
targetCircle.Color = getgenv().Config.CircleColor
targetCircle.NumSides = 100

-- Functions
local function Notify(text)
    SG:SetCore("SendNotification", {
        Title = "Improved Aimlock",
        Text = text,
        Duration = 3
    })
end

local function UpdateFOV()
    if getgenv().Config.FOV then
        fov.Radius = getgenv().Config.FOVSize * 2
        fov.Visible = getgenv().Config.ShowFOV
        fov.Position = Vector2.new(Mouse.X, Mouse.Y + GetGuiInset(GS).Y)
    else
        fov.Visible = false
    end
end

local function GetClosestPlayer()
    local closestPlayer, shortestDistance = nil, math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP and player.Character and player.Character:FindFirstChild("Humanoid")
           and player.Character.Humanoid.Health > 0 and player.Character:FindFirstChild(getgenv().Config.AimPart) then
            local character = player.Character
            local humanoid = character.Humanoid
            local bodyEffects = character:FindFirstChild("BodyEffects")

            if bodyEffects and bodyEffects:FindFirstChild("K.O") and bodyEffects["K.O"].Value ~= true
               and not character:FindFirstChild("GRABBING_COINSTRAINT") then
                local pos = Camera:WorldToViewportPoint(character.PrimaryPart.Position)
                local magnitude = (Vector2.new(pos.X, pos.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude

                if (not getgenv().Config.FOV or fov.Radius > magnitude) and magnitude < shortestDistance then
                    closestPlayer = player
                    shortestDistance = magnitude
                end
            end
        end
    end

    return closestPlayer
end

local function UpdatePrediction()
    if getgenv().Config.AutoPrediction then
        local ping = tonumber(string.split(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValueString(), "(")[1])
        
        getgenv().Config.Prediction = ping < 20 and 0.157
            or ping < 30 and 0.155
            or ping < 40 and 0.145
            or ping < 50 and 0.15038
            or ping < 60 and 0.15038
            or ping < 70 and 0.136
            or ping < 80 and 0.133
            or ping < 90 and 0.130
            or ping < 105 and 0.127
            or ping < 110 and 0.124
            or ping < 120 and 0.120
            or ping < 130 and 0.116
            or ping < 140 and 0.113
            or ping < 150 and 0.110
            or ping < 160 and 0.18
            or ping < 170 and 0.15
            or ping < 180 and 0.12
            or ping < 190 and 0.10
            or ping < 205 and 1.0
            or ping < 215 and 1.2
            or 1.4
    end
end

-- Main aimlock logic
local function AimlockTarget()
    if AimlockState and Locked and Victim and Victim.Character and Victim.Character:FindFirstChild(getgenv().Config.AimPart) then
        local targetPart = Victim.Character[getgenv().Config.AimPart]
        local targetPos = targetPart.Position + targetPart.Velocity * getgenv().Config.Prediction
        local screenPos, onScreen = Camera:WorldToViewportPoint(targetPos)

        if onScreen then
            Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, targetPos)
            targetCircle.Visible = true
            targetCircle.Position = Vector2.new(screenPos.X, screenPos.Y)
            targetCircle.Radius = getgenv().Config.CircleSize
        else
            targetCircle.Visible = false
        end
    else
        targetCircle.Visible = false
    end
end

-- Event connections
Mouse.KeyDown:Connect(function(key)
    key = key:lower()
    if key == getgenv().Config.Key:lower() then
        if AimlockState then
            Locked = not Locked
            if Locked then
                Victim = GetClosestPlayer()
                if Victim then
                    Notify("Locked onto: " .. tostring(Victim.Character.Humanoid.DisplayName))
                else
                    Notify("No target found")
                    Locked = false
                end
            else
                if Victim then
                    Victim = nil
                    Notify("Unlocked!")
                end
            end
        else
            Notify("Aimlock is disabled")
        end
    elseif key == getgenv().Config.DisableKey:lower() then
        AimlockState = not AimlockState
        Notify(AimlockState and "Aimlock enabled" or "Aimlock disabled")
    end
end)

RS.RenderStepped:Connect(function()
    UpdateFOV()
    AimlockTarget()
end)

-- Auto-prediction update
spawn(function()
    while wait(0.1) do
        UpdatePrediction()
    end
end)

-- Initial setup
if getgenv().Loaded then
    Notify("Aimlock is already loaded!")
    return
end

getgenv().Loaded = true
Notify("Improved Aimlock loaded successfully!")

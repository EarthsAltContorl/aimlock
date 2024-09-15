-- Improved Aimlock by earthdhc (bezzer included~!)
-- Modified for better locking and performance

getgenv().Config = {
    Prediction = 0.13,
    AimPart = "HumanoidRootPart",
    Key = "C",
    DisableKey = "X",
    FOV = true,
    ShowFOV = false,
    FOVSize = 55,
    AutoPrediction = true,
    CircleSize = 20,
    CircleColor = Color3.fromRGB(255, 0, 0),
    Smoothness = 0.5 -- Adjust this for smoother or snappier aiming (lower = smoother)
}

-- Services
local Players = game:GetService("Players")
local RS = game:GetService("RunService")
local WS = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")
local SG = game:GetService("StarterGui")

-- Locals
local LP = Players.LocalPlayer
local Mouse = LP:GetMouse()
local Camera = WS.CurrentCamera

-- Aimlock variables
local AimlockState = true
local Locked = false
local Victim

-- Target Circle
local targetCircle = Drawing.new("Circle")
targetCircle.Filled = false
targetCircle.Transparency = 1
targetCircle.Thickness = 2
targetCircle.Color = Config.CircleColor
targetCircle.NumSides = 100

-- Functions
local function Notify(text)
    SG:SetCore("SendNotification", {Title = "Improved Aimlock", Text = text, Duration = 3})
end

local function GetClosestPlayer()
    local closestPlayer, shortestDistance = nil, math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP and player.Character and player.Character:FindFirstChild("Humanoid") and
           player.Character.Humanoid.Health > 0 and player.Character:FindFirstChild(Config.AimPart) then
            local pos = Camera:WorldToViewportPoint(player.Character[Config.AimPart].Position)
            local magnitude = (Vector2.new(pos.X, pos.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude
            if magnitude < shortestDistance and (not Config.FOV or magnitude <= Config.FOVSize) then
                closestPlayer = player
                shortestDistance = magnitude
            end
        end
    end
    return closestPlayer
end

local function UpdatePrediction()
    if Config.AutoPrediction then
        local ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
        Config.Prediction = ping / 1000 + 0.1 -- Simple prediction based on ping
    end
end

-- Main aimlock logic
local function AimlockTarget()
    if AimlockState and Locked and Victim and Victim.Character and Victim.Character:FindFirstChild(Config.AimPart) then
        UpdatePrediction()
        local targetPart = Victim.Character[Config.AimPart]
        local targetPos = targetPart.Position + targetPart.Velocity * Config.Prediction
        local screenPos, onScreen = Camera:WorldToViewportPoint(targetPos)
        
        if onScreen then
            local mousePos = Vector2.new(Mouse.X, Mouse.Y)
            local targetPos2D = Vector2.new(screenPos.X, screenPos.Y)
            local movementX = (targetPos2D.X - mousePos.X) * Config.Smoothness
            local movementY = (targetPos2D.Y - mousePos.Y) * Config.Smoothness
            mousemoverel(movementX, movementY)
            
            targetCircle.Visible = true
            targetCircle.Position = targetPos2D
            targetCircle.Radius = Config.CircleSize
        else
            targetCircle.Visible = false
        end
    else
        targetCircle.Visible = false
    end
end

-- Input handling
UIS.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed then
        if input.KeyCode == Enum.KeyCode[Config.Key:upper()] then
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
                Victim = nil
                Notify("Unlocked!")
            end
        elseif input.KeyCode == Enum.KeyCode[Config.DisableKey:upper()] then
            AimlockState = not AimlockState
            Notify(AimlockState and "Aimlock enabled" or "Aimlock disabled")
        end
    end
end)

-- Main loop
RS.RenderStepped:Connect(AimlockTarget)

-- Initial setup
if getgenv().Loaded then
    Notify("Aimlock is already loaded!")
    return
end

getgenv().Loaded = true
Notify("Improved Aimlock loaded successfully!")

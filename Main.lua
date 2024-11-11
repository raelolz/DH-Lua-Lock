-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

-- Local Player
local LocalPlayer = Players.LocalPlayer

-- Settings
getgenv().dhlock = {
    enabled = false,
    fov = 50, -- Radius of the FOV circle
    keybind = Enum.UserInputType.MouseButton2, -- Activation key
    showfov = false, -- Show FOV circle
    teamcheck = false, -- Enable/disable team check
    wallcheck = false, -- doesnt work well / doesnt work at all at times
    lockpart = "Head", -- Part to lock onto, "HumanoidRootPart", "UpperTorso", "LowerTorso", "Torso" and most other parts
    smoothness = 1, -- Smoothness factor (higher = slower)
    fovcolorlocked = Color3.new(1, 0, 0), -- Color when locked
    fovcolorunlocked = Color3.new(0, 0, 0), -- Color when unlocked
    toggle = false, -- Toggle mode
    blacklist = {}, -- Blacklisted players
}

-- Variables
local isAiming = false
local fovCircle
local lockedPlayer = nil

-- Create FOV circle
local function CreateFOVCircle()
    if not fovCircle then
        fovCircle = Drawing.new("Circle")
        fovCircle.Thickness = 2
        fovCircle.NumSides = 64
        fovCircle.Filled = false
        fovCircle.Transparency = 1
    end
end

-- Update FOV circle
local function UpdateFOVCircle()
    CreateFOVCircle()

    fovCircle.Visible = dhlock.showfov
    fovCircle.Position = UserInputService:GetMouseLocation()
    fovCircle.Radius = dhlock.fov

    if lockedPlayer then
        fovCircle.Color = dhlock.fovcolorlocked
    else
        fovCircle.Color = dhlock.fovcolorunlocked
    end
end

-- Check if a player is in FOV
local function IsPlayerInFOV(player)
    local part = player.Character and player.Character:FindFirstChild(dhlock.lockpart)
    if not part then return false end

    local screenPoint = Workspace.CurrentCamera:WorldToViewportPoint(part.Position)
    local mousePosition = UserInputService:GetMouseLocation()
    local distance = (Vector2.new(screenPoint.X, screenPoint.Y) - mousePosition).Magnitude

    return distance <= dhlock.fov
end

-- Get closest player
local function GetClosestPlayer()
    local closestPlayer = nil
    local shortestDistance = math.huge

    for _, player in pairs(Players:GetPlayers()) do
        local part = player.Character and player.Character:FindFirstChild(dhlock.lockpart)
        if player ~= LocalPlayer and part and IsPlayerInFOV(player) and not table.find(dhlock.blacklist, player.Name) then
            if not dhlock.teamcheck or player.Team ~= LocalPlayer.Team then
                local distance = (part.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    closestPlayer = player
                end
            end
        end
    end

    return closestPlayer
end

-- Smooth aiming
local function SmoothAimAtPlayer(player)
    local targetPart = player.Character and player.Character:FindFirstChild(dhlock.lockpart)
    if not targetPart then return end

    local camera = Workspace.CurrentCamera
    local targetPosition = targetPart.Position
    local currentCFrame = camera.CFrame
    local targetCFrame = CFrame.lookAt(currentCFrame.Position, targetPosition)

    camera.CFrame = currentCFrame:Lerp(targetCFrame, 1 / dhlock.smoothness)
end

-- Handle aiming
local function HandleAim()
    if not isAiming or not dhlock.enabled then return end

    local closestPlayer = GetClosestPlayer()
    if closestPlayer then
        lockedPlayer = closestPlayer
        SmoothAimAtPlayer(closestPlayer)
    else
        lockedPlayer = nil
    end
end

-- Input handling
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == dhlock.keybind then
        isAiming = dhlock.toggle and not isAiming or true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == dhlock.keybind and not dhlock.toggle then
        isAiming = false
        lockedPlayer = nil
    end
end)

-- Update loop
RunService.RenderStepped:Connect(function()
    UpdateFOVCircle()
    HandleAim()
end)

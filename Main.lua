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
    showfov = false, -- Show FOV circle
    fov = 50, -- Radius of the FOV circle
    keybind = Enum.UserInputType.MouseButton2, -- Activation key
    teamcheck = false, -- Enable/disable team check
    wallcheck = false, -- Checks for walls
    alivecheck = false, -- Enable/disable alive check
    lockpart = "Head", -- Part to lock onto when on the ground
    lockpartair = "HumanoidRootPart", -- Part to lock onto when in the air
    smoothness = 1, -- Smoothness factor (higher = slower)
    predictionX = 0, -- Prediction multiplier for X-axis (horizontal)
    predictionY = 0, -- Prediction multiplier for Y-axis (vertical)
    fovcolorlocked = Color3.new(1, 0, 0), -- Color when locked
    fovcolorunlocked = Color3.new(0, 0, 0), -- Color when unlocked
    toggle = false, -- Toggle mode (set true for toggle, false for hold)
    blacklist = {} -- Blacklisted players
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

-- Determine the current lock part
local function GetCurrentLockPart()
    local character = LocalPlayer.Character
    if not character then return dhlock.lockpart end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.FloorMaterial == Enum.Material.Air then
        return dhlock.lockpartair
    else
        return dhlock.lockpart
    end
end

-- Check if a player is in FOV
local function IsPlayerInFOV(player)
    local lockPart = GetCurrentLockPart()
    local part = player.Character and player.Character:FindFirstChild(lockPart)
    if not part then return false end

    local screenPoint, onScreen = Workspace.CurrentCamera:WorldToViewportPoint(part.Position)
    if not onScreen then return false end

    local mousePosition = UserInputService:GetMouseLocation()
    local distance = (Vector2.new(screenPoint.X, screenPoint.Y) - mousePosition).Magnitude

    return distance <= dhlock.fov -- Only true if within the FOV circle
end

-- Check if the player is alive
local function IsPlayerAlive(player)
    local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health > 0
end

-- Get the predicted position of a target
local function GetPredictedPosition(player)
    local lockPart = GetCurrentLockPart()
    local targetPart = player.Character and player.Character:FindFirstChild(lockPart)
    if not targetPart then return nil end

    local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return targetPart.Position end

    local velocity = humanoidRootPart.Velocity
    local scaleFactor = 0.394 -- Adjust based on the desired scale (0.165 -> 0.065)

    local predictedX = targetPart.Position + Vector3.new(velocity.X * dhlock.predictionX * scaleFactor, 0, velocity.Z * dhlock.predictionX * scaleFactor)
    local predictedY = Vector3.new(0, velocity.Y * dhlock.predictionY * scaleFactor, 0)

    return predictedX + predictedY
end

-- Revalidate the current locked player
local function IsLockedPlayerValid()
    if not lockedPlayer then return false end
    if not lockedPlayer.Character then return false end

    local lockPart = GetCurrentLockPart()
    local targetPart = lockedPlayer.Character:FindFirstChild(lockPart)
    if not targetPart then return false end

    local valid = IsPlayerAlive(lockedPlayer) and
                  (not dhlock.teamcheck or lockedPlayer.Team ~= LocalPlayer.Team)

    if not dhlock.toggle then
        valid = valid and IsPlayerInFOV(lockedPlayer)
    end

    return valid
end

-- Get closest player
local function GetClosestPlayer()
    local closestPlayer = nil
    local shortestDistance = math.huge
    local mousePosition = UserInputService:GetMouseLocation()

    for _, player in pairs(Players:GetPlayers()) do
        local lockPart = GetCurrentLockPart()
        local part = player.Character and player.Character:FindFirstChild(lockPart)
        if player ~= LocalPlayer and part and not table.find(dhlock.blacklist, player.Name) then
            if IsPlayerInFOV(player) and
                (not dhlock.teamcheck or player.Team ~= LocalPlayer.Team) and
                (not dhlock.alivecheck or IsPlayerAlive(player)) then

                local worldDistance = (part.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                if worldDistance < shortestDistance then
                    shortestDistance = worldDistance
                    closestPlayer = player
                end
            end
        end
    end

    return closestPlayer
end

-- Smooth aiming
local function SmoothAimAtPlayer(player)
    local predictedPosition = GetPredictedPosition(player)
    if not predictedPosition then return end

    local camera = Workspace.CurrentCamera
    local currentCFrame = camera.CFrame
    local targetCFrame = CFrame.lookAt(currentCFrame.Position, predictedPosition)

    camera.CFrame = currentCFrame:Lerp(targetCFrame, 1 / dhlock.smoothness)
end

-- Handle aiming
local function HandleAim()
    if not isAiming or not dhlock.enabled then return end

    if lockedPlayer and IsLockedPlayerValid() then
        SmoothAimAtPlayer(lockedPlayer)
        return
    end

    if not dhlock.toggle or not lockedPlayer then
        local closestPlayer = GetClosestPlayer()
        if closestPlayer then
            lockedPlayer = closestPlayer
        else
            lockedPlayer = nil
        end
    end

    if lockedPlayer then
        SmoothAimAtPlayer(lockedPlayer)
    end
end

-- Input handling
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.UserInputType == dhlock.keybind or input.KeyCode == dhlock.keybind then
        if dhlock.toggle then
            isAiming = not isAiming
            if not isAiming then
                lockedPlayer = nil
            end
        else
            isAiming = true
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == dhlock.keybind or input.KeyCode == dhlock.keybind then
        if not dhlock.toggle then
            isAiming = false
            lockedPlayer = nil
        end
    end
end)

-- Update loop
RunService.RenderStepped:Connect(function()
    UpdateFOVCircle()
    HandleAim()
end)

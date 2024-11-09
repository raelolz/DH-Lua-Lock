-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")

-- Local Player
local LocalPlayer = Players.LocalPlayer

-- Settings
local dhlock = {
    fov = 50, -- Radius of the FOV circle
    keybind = Enum.UserInputType.MouseButton2, -- Activation key
    enabled = false, -- Toggle aiming
    showfov = false, -- Show FOV circle
    teamcheck = false, -- Enable/disable team check
    fovcolorlocked = Color3.new(0, 1, 0), -- Color when a player is locked
    fovcolorunlocked = Color3.new(1, 0, 0), -- Color when no player is locked 
    predicionX = 0, -- Amount of prediction in X direction (in studs)
    predictionY = 0, -- Amount of prediction in Y direction (in studs)
}

-- Variables
local isAiming = false
local fovCircle
local lockedPlayer = nil
local lockedPlayerBeforeDeath = nil  -- Variable to store locked player before death
local originalCFrameMethod

-- Function to create and update the FOV circle
local function UpdateFOVCircle()
    if not fovCircle then
        fovCircle = Drawing.new("Circle")
        fovCircle.Thickness = 2
        fovCircle.NumSides = 64
        fovCircle.Filled = false
        fovCircle.Transparency = 1
    end

    -- Set the FOV circle's color based on whether a player is locked
    if lockedPlayer then
        fovCircle.Color = SETTINGS.FOV_COLOR_LOCKED
    else
        fovCircle.Color = SETTINGS.FOV_COLOR_UNLOCKED
    end

    if SETTINGS.SHOW_FOV then
        fovCircle.Visible = true
        fovCircle.Radius = SETTINGS.FOV_RADIUS

        local fovPosition = UserInputService:GetMouseLocation()

        -- Apply prediction offset when locked onto a player
        if lockedPlayer then
            local camera = Workspace.CurrentCamera
            local predictedPosition = lockedPlayer.Character.HumanoidRootPart.Position

            -- Add fixed amounts to X and Y for prediction
            predictedPosition = predictedPosition + Vector3.new(SETTINGS.PREDICTION_X, SETTINGS.PREDICTION_Y, 0)

            -- Convert predicted position to screen space
            local screenPos = camera:WorldToViewportPoint(predictedPosition)
            fovPosition = Vector2.new(screenPos.X, screenPos.Y)
        end

        fovCircle.Position = fovPosition
    else
        fovCircle.Visible = false
    end
end

-- Function to check if a player is within the FOV
local function IsPlayerInFOV(player)
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        return false
    end

    local characterPosition = Workspace.CurrentCamera:WorldToViewportPoint(player.Character.HumanoidRootPart.Position)
    local mousePosition = UserInputService:GetMouseLocation()
    local fovDistance = (Vector2.new(characterPosition.X, characterPosition.Y) - mousePosition).Magnitude

    return fovDistance <= SETTINGS.FOV_RADIUS
end

-- Function to get the closest player within the FOV
local function GetClosestPlayer()
    local closestPlayer = nil
    local closestDistance = math.huge

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and 
           (not SETTINGS.CHECK_TEAM or player.Team ~= LocalPlayer.Team) and 
           IsPlayerInFOV(player) then

            local playerPos = player.Character.HumanoidRootPart.Position
            local localPlayerPos = LocalPlayer.Character.HumanoidRootPart.Position
            local distance = (playerPos - localPlayerPos).Magnitude

            if distance < closestDistance then
                closestDistance = distance
                closestPlayer = player
            end
        end
    end

    return closestPlayer
end

-- Hook the CFrame method to apply prediction when getting the HumanoidRootPart's CFrame
local function HookPredictionCFrame()
    originalCFrameMethod = hookmetamethod(game, "__index", function(self, key)
        if key == "CFrame" and self:IsA("BasePart") and self.Name == "HumanoidRootPart" then
            -- Apply prediction offset to the CFrame position when locked on
            if lockedPlayer and self.Parent == lockedPlayer.Character then
                local predictedPosition = self.Position + Vector3.new(SETTINGS.PREDICTION_X, SETTINGS.PREDICTION_Y, 0)
                return CFrame.new(predictedPosition)
            end
        end

        return originalCFrameMethod(self, key)
    end)
end

-- Function to lock on and aim at a player using CFrame (with fixed prediction)
local function AimAtPlayerUsingCFrame(player)
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        return
    end

    local camera = Workspace.CurrentCamera

    -- Get the predicted position by adding fixed X and Y prediction amounts
    local predictedPosition = player.Character.HumanoidRootPart.Position
    predictedPosition = predictedPosition + Vector3.new(SETTINGS.PREDICTION_X, SETTINGS.PREDICTION_Y, 0)

    -- Lock the character's aim with CFrame
    local cframeLookAt = CFrame.lookAt(camera.CFrame.Position, predictedPosition)
    camera.CFrame = cframeLookAt
end

-- Function to update aiming logic
local function UpdateAim()
    if not isAiming or not SETTINGS.AIM_ENABLED then
        return
    end

    local closestPlayer = GetClosestPlayer()
    if closestPlayer then
        lockedPlayer = closestPlayer
        AimAtPlayerUsingCFrame(lockedPlayer) -- Lock on to the closest player using CFrame
    else
        lockedPlayer = nil
    end
end

-- Input handling
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == SETTINGS.ACTIVATE_KEY then
        isAiming = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == SETTINGS.ACTIVATE_KEY then
        isAiming = false
        lockedPlayer = nil -- Reset locked player when MouseButton2 is released
    end
end)

-- Handle team changes or character spawns
LocalPlayer:GetPropertyChangedSignal("Team"):Connect(function()
    isAiming = false -- Reset aiming when switching teams
    lockedPlayer = nil -- Reset locked player
end)

LocalPlayer.CharacterAdded:Connect(function()
    isAiming = false -- Reset aiming on respawn
    -- Re-lock to previous locked player if they are still valid
    if lockedPlayerBeforeDeath and lockedPlayerBeforeDeath.Parent then
        lockedPlayer = lockedPlayerBeforeDeath
    else
        lockedPlayer = nil
    end
end)

-- Handle player death
LocalPlayer.CharacterRemoving:Connect(function()
    -- Store the locked player before death to restore after respawn
    lockedPlayerBeforeDeath = lockedPlayer
    lockedPlayer = nil -- Reset locked player on death
end)

-- Render loop
RunService.RenderStepped:Connect(function()
    UpdateAim()
    UpdateFOVCircle()
end)

-- Initialize the hook
HookPredictionCFrame()

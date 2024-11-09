-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

-- Local Player
local LocalPlayer = Players.LocalPlayer

-- Settings
local dhlock = {
    fov = 50, -- Radius of the FOV circle
    keybind = Enum.UserInputType.MouseButton2, -- Activation key
    enabled = false, -- Toggle aiming
    showfov = false, -- Show FOV circle
    teamcheck = false, -- Enable/disable team check
    fovcolorlocked = Color3.new(0, 1, 0), -- Color when a player is locked (Green)
    fovcolorunlocked = Color3.new(1, 0, 0), -- Color when no player is locked (Red)
    lockpart = "HumanoidRootPart", -- Part to lock onto ("HumanoidRootPart", "UpperTorso", "LowerTorso", "Head")
    smoothness = 1, -- Smoothness factor (higher = slower)
}

-- Variables
local isAiming = false
local fovCircle
local lockedPlayer = nil
local missingParts = {} -- Tracks missing parts to avoid repeated messages

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
        fovCircle.Color = dhlock.fovcolorlocked
    else
        fovCircle.Color = dhlock.fovcolorunlocked
    end

    if dhlock.showfov then
        fovCircle.Visible = true
        fovCircle.Radius = dhlock.fov
        fovCircle.Position = UserInputService:GetMouseLocation()
    else
        fovCircle.Visible = false
    end
end

-- Function to check if a player is within the FOV
local function IsPlayerInFOV(player)
    local part = player.Character and player.Character:FindFirstChild(dhlock.lockpart)
    if not part then
        if not missingParts[dhlock.lockpart] then
            print("Warning: Lock part '" .. dhlock.lockpart .. "' not found on " .. player.Name)
            missingParts[dhlock.lockpart] = true
        end
        return false
    end

    local characterPosition = Workspace.CurrentCamera:WorldToViewportPoint(part.Position)
    local mousePosition = UserInputService:GetMouseLocation()
    local fovDistance = (Vector2.new(characterPosition.X, characterPosition.Y) - mousePosition).Magnitude

    return fovDistance <= dhlock.fov
end

-- Function to get the closest player within the FOV
local function GetClosestPlayer()
    local closestPlayer = nil
    local closestDistance = math.huge

    for _, player in pairs(Players:GetPlayers()) do
        local part = player.Character and player.Character:FindFirstChild(dhlock.lockpart)
        if player ~= LocalPlayer and 
           (not dhlock.teamcheck or player.Team ~= LocalPlayer.Team) and 
           part and IsPlayerInFOV(player) then

            local playerPos = part.Position
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

-- Function to lock on and aim at a player with smoothness
local function AimAtPlayerSmoothly(player)
    local part = player.Character and player.Character:FindFirstChild(dhlock.lockpart)
    if not part then
        return
    end

    local camera = Workspace.CurrentCamera
    local targetPosition = part.Position

    -- Calculate direction to target
    local currentCFrame = camera.CFrame
    local targetCFrame = CFrame.lookAt(currentCFrame.Position, targetPosition)
    local smoothFactor = 1 / dhlock.smoothness

    -- Interpolate rotation toward the target
    camera.CFrame = currentCFrame:Lerp(targetCFrame, smoothFactor)
end

-- Function to update aiming logic
local function UpdateAim()
    if not isAiming or not dhlock.enabled then
        return
    end

    local closestPlayer = GetClosestPlayer()
    if closestPlayer then
        lockedPlayer = closestPlayer
        AimAtPlayerSmoothly(lockedPlayer) -- Lock on to the closest player with smoothness
    else
        lockedPlayer = nil
    end
end

-- Input handling
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == dhlock.keybind then
        isAiming = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == dhlock.keybind then
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
    lockedPlayer = nil -- Reset locked player
end)

-- Render loop
RunService.RenderStepped:Connect(function()
    UpdateAim()
    UpdateFOVCircle()
end)

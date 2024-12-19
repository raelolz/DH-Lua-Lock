
getgenv().dhlock = {
    enabled = false,
    showfov = false, 
    fov = 50,
    keybind = Enum.UserInputType.MouseButton2, 
    teamcheck = false,
    wallcheck = false,
    alivecheck = false, 
    lockpart = "Head", 
    lockpartair = "HumanoidRootPart", 
    smoothness = 1,
    predictionX = 0, 
    predictionY = 0, 
    fovcolorlocked = Color3.new(1, 0, 0),
    fovcolorunlocked = Color3.new(0, 0, 0),
    fovtransparency = 0.6, 
    toggle = false, 
    blacklist = {} 
}


local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer


local isAiming = false
local fovCircle
local lockedPlayer = nil

local function IsValidKeybind(input)
    return typeof(input) == "EnumItem" and (input.EnumType == Enum.KeyCode or input.EnumType == Enum.UserInputType)
end

local function UpdateKeybind(newKeybind)
    if IsValidKeybind(newKeybind) then
        dhlock.keybind = newKeybind
    end
end

local function CreateFOVCircle()
    if not fovCircle then
        fovCircle = Drawing.new("Circle")
        fovCircle.Thickness = 2
        fovCircle.NumSides = 64
        fovCircle.Filled = false
    end
end

local function UpdateFOVCircle()
    CreateFOVCircle()

    fovCircle.Visible = dhlock.showfov
    fovCircle.Position = UserInputService:GetMouseLocation()
    fovCircle.Radius = dhlock.fov
    fovCircle.Transparency = dhlock.fovtransparency 

    if lockedPlayer then
        fovCircle.Color = dhlock.fovcolorlocked
    else
        fovCircle.Color = dhlock.fovcolorunlocked
    end
end

local function UpdateFovTransparency(newTransparency)
    if type(newTransparency) == "number" and newTransparency >= 0 and newTransparency <= 1 then
        dhlock.fovtransparency = newTransparency
        UpdateFOVCircle()
    end
end

local function GetCurrentLockPart()
    local character = LocalPlayer.Character
    if not character then return dhlock.lockpart end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local lockPartName = dhlock.lockpart
    if humanoid and humanoid.FloorMaterial == Enum.Material.Air then
        lockPartName = dhlock.lockpartair
    end

    if character:FindFirstChild(lockPartName) then
        return lockPartName
    else
        return "Head"
    end
end

local function IsPlayerInFOV(player)
    local lockPartName = GetCurrentLockPart()
    local part = player.Character and player.Character:FindFirstChild(lockPartName)
    if not part then return false end

    local screenPoint, onScreen = Workspace.CurrentCamera:WorldToViewportPoint(part.Position)
    if not onScreen then return false end

    local mousePosition = UserInputService:GetMouseLocation()
    local distance = (Vector2.new(screenPoint.X, screenPoint.Y) - mousePosition).Magnitude

    return distance <= dhlock.fov 
end

local function IsPlayerAlive(player)
    local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health > 0
end

local function GetPredictedPosition(player)
    local lockPartName = GetCurrentLockPart()
    local targetPart = player.Character and player.Character:FindFirstChild(lockPartName)
    if not targetPart then return nil end

    local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return targetPart.Position end

    local velocity = humanoidRootPart.Velocity
    local scaleFactor = 0.394 

    local predictedX = targetPart.Position + Vector3.new(velocity.X * dhlock.predictionX * scaleFactor, 0, velocity.Z * dhlock.predictionX * scaleFactor)
    local predictedY = Vector3.new(0, velocity.Y * dhlock.predictionY * scaleFactor, 0)

    return predictedX + predictedY
end

local function IsLockedPlayerValid()
    if not lockedPlayer then return false end
    if not lockedPlayer.Character then return false end

    local lockPartName = GetCurrentLockPart()
    local targetPart = lockedPlayer.Character:FindFirstChild(lockPartName)
    if not targetPart then return false end

    local valid = IsPlayerAlive(lockedPlayer) and
                  (not dhlock.teamcheck or lockedPlayer.Team ~= LocalPlayer.Team)

    if not dhlock.toggle then
        valid = valid and IsPlayerInFOV(lockedPlayer)
    end

    return valid
end

local function GetClosestPlayer()
    local closestPlayer = nil
    local shortestDistance = math.huge
    local mousePosition = UserInputService:GetMouseLocation()

    for _, player in pairs(Players:GetPlayers()) do
        local lockPartName = GetCurrentLockPart()
        local part = player.Character and player.Character:FindFirstChild(lockPartName)
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

local function SmoothAimAtPlayer(player)
    local predictedPosition = GetPredictedPosition(player)
    if not predictedPosition then return end

    local camera = Workspace.CurrentCamera
    local currentCFrame = camera.CFrame
    local targetCFrame = CFrame.lookAt(currentCFrame.Position, predictedPosition)

    camera.CFrame = currentCFrame:Lerp(targetCFrame, 1 / dhlock.smoothness)
end

local function HandleAim()
    if not isAiming or not dhlock.enabled then return end

    if lockedPlayer and not IsLockedPlayerValid() then
        lockedPlayer = nil
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

local function ResetState()
    lockedPlayer = nil
    isAiming = false
end

local function UpdateLockPartAir(newLockPartAir)
    dhlock.lockpartair = newLockPartAir
    ResetState()
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if (input.UserInputType == dhlock.keybind or input.KeyCode == dhlock.keybind) and IsValidKeybind(dhlock.keybind) then
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
    if (input.UserInputType == dhlock.keybind or input.KeyCode == dhlock.keybind) and not dhlock.toggle and IsValidKeybind(dhlock.keybind) then
        isAiming = false
        lockedPlayer = nil
    end
end)

RunService.RenderStepped:Connect(function()
    UpdateFOVCircle()
    HandleAim()
end)

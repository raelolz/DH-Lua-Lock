local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")


local LocalPlayer = Players.LocalPlayer


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
    fovtransparency = 0.8, -- Transparency of the FOV circle (0 = fully transparent, 1 = fully opaque)
    toggle = false, -- Toggle mode (set true for toggle, false for hold)
    blacklist = {} -- Blacklisted players
}


local isAiming = false
local fovCircle
local lockedPlayer = nil


local function IsValidKeybind(input)
    return typeof(input) == "EnumItem" and (input.EnumType == Enum.KeyCode or input.EnumType == Enum.UserInputType)
end


local function UpdateKeybind(newKeybind)
    if IsValidKeybind(newKeybind) then
        dhlock.keybind = newKeybind
    else
        warn("Invalid keybind specified!")
    end
end


local function RecreateFOVCircle()
    if fovCircle then
        fovCircle:Remove()
    end
    fovCircle = Drawing.new("Circle")
    fovCircle.Thickness = 2
    fovCircle.NumSides = 64
    fovCircle.Filled = false
    fovCircle.Transparency = dhlock.fovtransparency
end


local function CreateFOVCircle()
    if not fovCircle then
        RecreateFOVCircle()
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


task.spawn(function()
    local lastTransparency = dhlock.fovtransparency
    while true do
        if dhlock.fovtransparency ~= lastTransparency then
            lastTransparency = dhlock.fovtransparency
            RecreateFOVCircle() 
        end
        task.wait(0.2) 
    end
end)




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

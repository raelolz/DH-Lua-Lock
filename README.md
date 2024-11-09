# DH-Lua-Lock
roblox lua lock (aimbot) designed for da hood, also works on games like hood customs.
feel free to skid and use in your script.
## Load the Lock
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Stratxgy/DH-Lua-Lock/refs/heads/main/Main.lua"))()
```
## Customizable Settings
```lua
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
```
> [!IMPORTANT]
> Disabled by default. Make sure to enable everything. Here's an example usage:
> ## Example Usage
> ```lua
>loadstring(game:HttpGet("https://raw.githubusercontent.com/Stratxgy/DH-Lua-Lock/refs/heads/main/Main.lua"))()
> dhlock.fov = 80
> dhlock.keybind = Enum.Keycode.E
>  dhlock.enabled = true
>  dhlock.showfov = true
>  dhlock.fovcolorlocked = Color3.new(1, 0, 0)
>  dhlock.predictionX = 10
>  dhlock.predictionY = 10
> ```

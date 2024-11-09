# DH-Lua-Lock | Make sure to drop a ⭐ if you liked the script
roblox lua lock (aimbot) designed for da hood, also works on games like hood customs.
feel free to skid and use in your script.
## Load the Lock
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Stratxgy/DH-Lua-Lock/refs/heads/main/Main.lua"))()
```
## Customizable Settings
```lua
local dhlock = {
    enabled = false,
    fov = 50, -- Radius of the FOV circle
    keybind = Enum.UserInputType.MouseButton2, -- Activation key
    showfov = false, -- Show FOV circle
    teamcheck = false, -- Enable/disable team check
    wallcheck = false, -- doesnt work well / doesnt work at all at times
    lockpart = "Head", -- Part to lock onto, "HumanoidRootPart", "UpperTorso", "LowerTorso", "Torso" and most other parts
    smoothness = 1, -- Smoothness factor (higher = slower)
    fovcolorlocked = Color3.new(0, 1, 0), -- Color when locked
    fovcolorunlocked = Color3.new(1, 0, 0), -- Color when unlocked
    toggle = false, -- Toggle mode
    blacklist = {}, -- Blacklisted players
}
```
> [!IMPORTANT]
> Disabled by default. Make sure to enable everything. Here's an example usage:
> ## Example Usage
> ```lua
>loadstring(game:HttpGet("https://raw.githubusercontent.com/Stratxgy/DH-Lua-Lock/refs/heads/main/Main.lua"))()
>  dhlock.fov = 80
>  dhlock.keybind = Enum.Keycode.E
>  dhlock.enabled = true
>  dhlock.showfov = true
>  dhlock.fovcolorlocked = Color3.new(1, 0, 0)
>  dhlock.fovcolorunlocked = Color3.new(1, 0, 0)
>  dhlock.lockpart = "Head"
>  dhlock.smoothness = 2
> ```

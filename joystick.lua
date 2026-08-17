-- [[ CUSTOM JOYSTICK - ANTI-RESET WASD EMULATOR ]] --
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer

-- 1. สร้าง ScreenGui และ Touch Zone (ซ้ายล่าง 50%)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CustomJoystickGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

local touchZone = Instance.new("Frame")
touchZone.Name = "TouchZone"
touchZone.Parent = screenGui
touchZone.Size = UDim2.new(0.5, 0, 0.5, 0)      -- กว้าง 50% สูง 50%
touchZone.Position = UDim2.new(0, 0, 0.5, 0)    -- ตำแหน่งซ้ายล่าง
touchZone.BackgroundTransparency = 1 
touchZone.Active = true

-- 2. UI Joystick (Base & Thumb)
local joystickRadius = 60

local joystickBase = Instance.new("Frame")
joystickBase.Name = "JoystickBase"
joystickBase.Parent = screenGui
joystickBase.Size = UDim2.new(0, joystickRadius * 2, 0, joystickRadius * 2)
joystickBase.AnchorPoint = Vector2.new(0.5, 0.5)
joystickBase.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
joystickBase.BackgroundTransparency = 0.5
joystickBase.Visible = false

local baseCorner = Instance.new("UICorner")
baseCorner.CornerRadius = UDim.new(1, 0)
baseCorner.Parent = joystickBase

local joystickThumb = Instance.new("Frame")
joystickThumb.Name = "JoystickThumb"
joystickThumb.Parent = joystickBase
joystickThumb.Size = UDim2.new(0, 50, 0, 50)
joystickThumb.AnchorPoint = Vector2.new(0.5, 0.5)
joystickThumb.Position = UDim2.new(0.5, 0, 0.5, 0)
joystickThumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
joystickThumb.BackgroundTransparency = 0.2

local thumbCorner = Instance.new("UICorner")
thumbCorner.CornerRadius = UDim.new(1, 0)
thumbCorner.Parent = joystickThumb

-- 3. ระบบจัดการปุ่ม WASD
local activeKeys = {
    W = false,
    A = false,
    S = false,
    D = false
}

local function updateWASDState(normX, normZ)
    local deadzone = 0.25

    local shouldW = normZ < -deadzone
    local shouldS = normZ > deadzone
    local shouldA = normX < -deadzone
    local shouldD = normX > deadzone

    -- ปล่อยปุ่มที่ไม่ได้กดแล้ว
    if not shouldW and activeKeys.W then VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.W, false, game) end
    if not shouldS and activeKeys.S then VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.S, false, game) end
    if not shouldA and activeKeys.A then VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.A, false, game) end
    if not shouldD and activeKeys.D then VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.D, false, game) end

    -- อัปเดตสถานะปุ่ม
    activeKeys.W = shouldW
    activeKeys.S = shouldS
    activeKeys.A = shouldA
    activeKeys.D = shouldD
end

local function releaseAllKeys()
    for keyName, isPressed in pairs(activeKeys) do
        if isPressed then
            activeKeys[keyName] = false
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[keyName], false, game)
        end
    end
end

-- 4. ระบบรับ Touch Input
local currentTouchInput = nil
local startPos = Vector2.new(0, 0)

touchZone.InputBegan:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1) and not currentTouchInput then
        currentTouchInput = input
        startPos = Vector2.new(input.Position.X, input.Position.Y)

        joystickBase.Position = UDim2.new(0, startPos.X, 0, startPos.Y)
        joystickThumb.Position = UDim2.new(0.5, 0, 0.5, 0)
        joystickBase.Visible = true
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == currentTouchInput then
        local currentPos = Vector2.new(input.Position.X, input.Position.Y)
        local delta = currentPos - startPos
        local distance = delta.Magnitude

        local clampedDistance = math.min(distance, joystickRadius)
        local direction = distance > 0 and delta.Unit or Vector2.new(0, 0)

        local thumbOffset = direction * clampedDistance
        joystickThumb.Position = UDim2.new(0.5, thumbOffset.X, 0.5, thumbOffset.Y)

        local normX = thumbOffset.X / joystickRadius
        local normZ = thumbOffset.Y / joystickRadius

        updateWASDState(normX, normZ)
    end
end)

local function stopJoystick(input)
    if input == currentTouchInput then
        currentTouchInput = nil
        joystickBase.Visible = false
        releaseAllKeys()
    end
end

UserInputService.InputEnded:Connect(stopJoystick)

-- 5. ส่งสัญญาณย้ำคีย์บอร์ดทุกเฟรม (ป้องกัน Roblox Auto-Reset เมื่อสลับโหมด Touch)
RunService.RenderStepped:Connect(function()
    if currentTouchInput then
        for keyName, isPressed in pairs(activeKeys) do
            if isPressed then
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[keyName], false, game)
            end
        end
    end
end)

print("✅ [Custom Joystick] Continuous Hold Fix Loaded!")

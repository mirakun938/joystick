-- [[ CUSTOM JOYSTICK - WASD KEYBOARD EMULATOR ]] --
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local localPlayer = Players.LocalPlayer

-- 1. สร้าง ScreenGui และ Touch Zone (ซ้ายล่าง 50% ตามที่คุณกำหนด)
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

-- 2. สร้าง UI Joystick (Base & Thumb)
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

-- 3. ระบบจำลองการกดคีย์บอร์ด (WASD Keyboard System)
local activeKeys = {
    W = false,
    A = false,
    S = false,
    D = false
}

local function updateWASDKeys(normX, normZ)
    local deadzone = 0.25 -- ระยะเริ่มต้นของจอยสติ๊กก่อนเริ่มส่งสัญญาณกด

    local shouldW = normZ < -deadzone -- ดันขึ้น = กด W
    local shouldS = normZ > deadzone  -- ดึงลง = กด S
    local shouldA = normX < -deadzone -- ลากซ้าย = กด A
    local shouldD = normX > deadzone  -- ลากขวา = กด D

    -- ส่งสัญญาณกด/ปล่อย ปุ่ม W
    if shouldW ~= activeKeys.W then
        activeKeys.W = shouldW
        VirtualInputManager:SendKeyEvent(shouldW, Enum.KeyCode.W, false, game)
    end
    -- ส่งสัญญาณกด/ปล่อย ปุ่ม S
    if shouldS ~= activeKeys.S then
        activeKeys.S = shouldS
        VirtualInputManager:SendKeyEvent(shouldS, Enum.KeyCode.S, false, game)
    end
    -- ส่งสัญญาณกด/ปล่อย ปุ่ม A
    if shouldA ~= activeKeys.A then
        activeKeys.A = shouldA
        VirtualInputManager:SendKeyEvent(shouldA, Enum.KeyCode.A, false, game)
    end
    -- ส่งสัญญาณกด/ปล่อย ปุ่ม D
    if shouldD ~= activeKeys.D then
        activeKeys.D = shouldD
        VirtualInputManager:SendKeyEvent(shouldD, Enum.KeyCode.D, false, game)
    end
end

local function releaseAllKeys()
    for keyName, isPressed in pairs(activeKeys) do
        if isPressed then
            activeKeys[keyName] = false
            local keyCode = Enum.KeyCode[keyName]
            VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
        end
    end
end

-- 4. ระบบรับค่า Touch/Mouse Input
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

        -- แปลงระยะจอยสติ๊กเป็นคำสั่งกด WASD
        updateWASDKeys(normX, normZ)
    end
end)

local function stopJoystick(input)
    if input == currentTouchInput then
        currentTouchInput = nil
        joystickBase.Visible = false
        releaseAllKeys() -- ปล่อยปุ่มเดินทั้งหมดเมื่อยกนิ้วออก
    end
end

UserInputService.InputEnded:Connect(stopJoystick)

print("✅ [Custom Joystick] WASD Emulator Ready! (Fixed Movement & Animation)")

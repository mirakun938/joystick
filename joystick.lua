-- [[ CUSTOM JOYSTICK - CONTINUOUS WASD EMULATOR ]] --
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

-- 3. ตัวแปรสำหรับรับค่า
local currentTouchInput = nil
local startPos = Vector2.new(0, 0)
local currentNormX = 0
local currentNormZ = 0

local activeKeys = {
    W = false,
    A = false,
    S = false,
    D = false
}

-- ฟังก์ชันปล่อยปุ่มทั้งหมด
local function releaseAllKeys()
    for keyName, isPressed in pairs(activeKeys) do
        if isPressed then
            activeKeys[keyName] = false
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[keyName], false, game)
        end
    end
end

-- 4. ระบบรับค่า Touch/Mouse Input
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

        -- อัปเดตค่าพิกัดการลากเก็บไว้ในตัวแปร
        currentNormX = thumbOffset.X / joystickRadius
        currentNormZ = thumbOffset.Y / joystickRadius
    end
end)

local function stopJoystick(input)
    if input == currentTouchInput then
        currentTouchInput = nil
        joystickBase.Visible = false
        currentNormX = 0
        currentNormZ = 0
        releaseAllKeys()
    end
end

UserInputService.InputEnded:Connect(stopJoystick)

-- 5. ลูปทำงานต่อเนื่องทุกเฟรม (RenderStepped) เพื่อป้องกันปุ่มหลุด/หยุดเดินกลางทาง
RunService.RenderStepped:Connect(function()
    if not currentTouchInput then return end

    local deadzone = 0.2
    local shouldW = currentNormZ < -deadzone
    local shouldS = currentNormZ > deadzone
    local shouldA = currentNormX < -deadzone
    local shouldD = currentNormX > deadzone

    -- อัปเดตและย้ำสัญญาณกดปุ่ม W, A, S, D
    local keysToUpdate = {
        {Key = "W", ShouldPress = shouldW, Code = Enum.KeyCode.W},
        {Key = "S", ShouldPress = shouldS, Code = Enum.KeyCode.S},
        {Key = "A", ShouldPress = shouldA, Code = Enum.KeyCode.A},
        {Key = "D", ShouldPress = shouldD, Code = Enum.KeyCode.D},
    }

    for _, data in ipairs(keysToUpdate) do
        if data.ShouldPress then
            -- ย้ำสัญญาณกดค้างตลอดเวลา
            VirtualInputManager:SendKeyEvent(true, data.Code, false, game)
            activeKeys[data.Key] = true
        elseif activeKeys[data.Key] then
            -- ปล่อยปุ่มเมื่อไม่อยู่ในทิศทางนั้น
            VirtualInputManager:SendKeyEvent(false, data.Code, false, game)
            activeKeys[data.Key] = false
        end
    end
end)

print("✅ [Custom Joystick] Fixed Drag Hold Issue!")

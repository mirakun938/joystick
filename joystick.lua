-- [[ HYBRID JOYSTICK - RESPAWN FIX & CAMERA TRACKING ]] --
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

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
touchZone.Position = UDim2.new(0, 0, 0.5, 0)    -- มุมซ้ายล่าง
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

-- 3. ตัวแปรเก็บสถานะการควบคุม
local currentTouchInput = nil
local startPos = Vector2.new(0, 0)
local moveVector = Vector3.new(0, 0, 0)

local activeKeys = { W = false, A = false, S = false, D = false }

-- ฟังก์ชันอัปเดตสถานะปุ่ม WASD
local function updateWASDState(normX, normZ)
    local deadzone = 0.2

    local shouldW = normZ < -deadzone
    local shouldS = normZ > deadzone
    local shouldA = normX < -deadzone
    local shouldD = normX > deadzone

    if not shouldW and activeKeys.W then VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.W, false, game) end
    if not shouldS and activeKeys.S then VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.S, false, game) end
    if not shouldA and activeKeys.A then VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.A, false, game) end
    if not shouldD and activeKeys.D then VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.D, false, game) end

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

        -- คำนวณ Move Vector สำหรับทิศทาง 360 องศา
        moveVector = Vector3.new(normX, 0, -normZ)
    end
end)

local function stopJoystick(input)
    if input == currentTouchInput then
        currentTouchInput = nil
        joystickBase.Visible = false
        moveVector = Vector3.new(0, 0, 0)
        releaseAllKeys()
    end
end

UserInputService.InputEnded:Connect(stopJoystick)

-- 5. ระบบคำนวณทิศทาง (ดึงกล้องปัจจุบันแบบ Dynamic ตลอดเวลา)
RunService.RenderStepped:Connect(function()
    if currentTouchInput then
        -- [ระบบ A] ส่งสัญญาณ WASD ต่อเนื่อง
        for keyName, isPressed in pairs(activeKeys) do
            if isPressed then
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[keyName], false, game)
            end
        end

        -- [ระบบ B] คำนวณการเดิน 360 องศา
        local character = localPlayer.Character
        if character and moveVector.Magnitude > 0 then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            
            -- ดึง CurrentCamera ณ ปัจจุบันเสมอ เพื่อป้องกันปัญหากล้องสลับทิศหลัง Respawn
            local currentCamera = Workspace.CurrentCamera
            
            if humanoid and currentCamera then
                local camCFrame = currentCamera.CFrame
                local cameraForward = Vector3.new(camCFrame.LookVector.X, 0, camCFrame.LookVector.Z).Unit
                local cameraRight = Vector3.new(camCFrame.RightVector.X, 0, camCFrame.RightVector.Z).Unit

                local worldDirection = (cameraRight * moveVector.X) + (cameraForward * moveVector.Z)
                humanoid:Move(worldDirection, false)
            end
        end
    end
end)

print("✅ [Hybrid Joystick] Dynamic Camera Tracking Active - Respawn Bug Fixed!")

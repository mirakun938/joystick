-- [[ CUSTOM JOYSTICK - BOTTOM-LEFT 50% WITH FORCE ANIMATION STATE ]] --
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local localPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- 1. สร้าง ScreenGui และ Touch Zone (ซ้ายล่าง 50%)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CustomJoystickGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

local touchZone = Instance.new("Frame")
touchZone.Name = "TouchZone"
touchZone.Parent = screenGui
touchZone.Size = UDim2.new(0.5, 0, 0.5, 0)      -- กว้าง 50% สูง 50%
touchZone.Position = UDim2.new(0, 0, 0.5, 0)    -- โซนซ้ายล่าง
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

-- 3. ระบบคำนวณการแตะและการเคลื่อนที่
local currentTouchInput = nil
local startPos = Vector2.new(0, 0)
local moveVector = Vector3.new(0, 0, 0)

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
        local normForward = -thumbOffset.Y / joystickRadius

        moveVector = Vector3.new(normX, 0, normForward)
    end
end)

local function stopJoystick(input)
    if input == currentTouchInput then
        currentTouchInput = nil
        joystickBase.Visible = false
        moveVector = Vector3.new(0, 0, 0)
    end
end

UserInputService.InputEnded:Connect(stopJoystick)

-- 4. สั่งการเคลื่อนที่ + กระตุ้น State ของ Animation
RunService.RenderStepped:Connect(function()
    local character = localPlayer.Character
    if not character then return end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    if moveVector.Magnitude > 0 then
        -- คำนวณทิศทางตามกล้อง
        local camCFrame = camera.CFrame
        local cameraForward = Vector3.new(camCFrame.LookVector.X, 0, camCFrame.LookVector.Z).Unit
        local cameraRight = Vector3.new(camCFrame.RightVector.X, 0, camCFrame.RightVector.Z).Unit
        local worldDirection = (cameraRight * moveVector.X) + (cameraForward * moveVector.Z)

        -- 1. สั่งเคลื่อนที่ตัวละคร
        humanoid:Move(worldDirection, false)

        -- 2. บังคับเปลี่ยน State เป็น Running เพื่อปลุกให้ Animation Controller ของเกมทำงาน
        if humanoid:GetState() ~= Enum.HumanoidStateType.Running and humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
            humanoid:ChangeState(Enum.HumanoidStateType.Running)
        end
    else
        -- เมื่อหยุดลากจอย ให้สั่งหยุดย้ายตำแหน่ง
        humanoid:Move(Vector3.new(0, 0, 0), false)
    end
end)

print("✅ [Custom Joystick] Force State Animation Fix Loaded!")

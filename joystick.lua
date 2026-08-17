-- [[ CUSTOM JOYSTICK - PLAYERMODULE CONTROL INJECTION ]] --
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local playerScripts = localPlayer:WaitForChild("PlayerScripts")

-- 1. ดึง ControlModule ของ Roblox เพื่อเตรียมฉีดค่าการเคลื่อนที่
local controls = nil
pcall(function()
    local playerModule = require(playerScripts:WaitForChild("PlayerModule", 5))
    controls = playerModule:GetControls()
end)

-- 2. สร้าง UI และ Touch Zone (โซนซ้ายล่าง 50% ตามภาพ)
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

-- 3. UI Joystick (Base & Thumb)
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
thumbCorner.Parent = thumbCorner and joystickThumb

-- 4. ระบบคำนวณการแตะและลาก
local currentTouchInput = nil
local startPos = Vector2.new(0, 0)
local rawMoveVector = Vector3.new(0, 0, 0)

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

        -- ค่าสำหรับ Roblox ControlModule: X = ซ้าย/ขวา, Z = หน้า(-)/หลัง(+)
        rawMoveVector = Vector3.new(normX, 0, normZ)
    end
end)

local function stopJoystick(input)
    if input == currentTouchInput then
        currentTouchInput = nil
        joystickBase.Visible = false
        rawMoveVector = Vector3.new(0, 0, 0)
    end
end

UserInputService.InputEnded:Connect(stopJoystick)

-- 5. Hook คำสั่งเดินเข้าสู่อินพุตหลักของเกมโดยตรง (ส่งผลให้ Animate ทำงานสมบูรณ์)
if controls then
    local oldGetMoveVector = controls.GetMoveVector
    controls.GetMoveVector = function(self)
        if rawMoveVector.Magnitude > 0 then
            return rawMoveVector
        end
        return oldGetMoveVector(self)
    end
    print("✅ [Joystick] Successfully Injected into PlayerModule Controls!")
else
    -- สำรองกรณีเกมลบ PlayerModule ออก
    RunService.RenderStepped:Connect(function()
        local character = localPlayer.Character
        if character and rawMoveVector.Magnitude > 0 then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid:Move(rawMoveVector, true)
            end
        end
    end)
end

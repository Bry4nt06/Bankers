local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local CONFIG_FOLDER_NAME = "TheTakeMenuCameraConfig"
local READY_ATTRIBUTE = "TheTakeCameraReady"
local STARTED_ATTRIBUTE = "TheTakeGameplayStarted"
local BIND_NAME = "TheTakeCameraAuthority"

local INTRO_DURATION = 7.0
local START_FOV = 58
local END_FOV = 44
local PARALLAX_X_STUDS = 0.78
local PARALLAX_Y_STUDS = 0.38
local PARALLAX_YAW_DEGREES = 1.35
local PARALLAX_PITCH_DEGREES = 0.68
local POINTER_RESPONSE = 8.5

player:SetAttribute(READY_ATTRIBUTE, false)

local camera = workspace.CurrentCamera
if not camera then
	workspace:GetPropertyChangedSignal("CurrentCamera"):Wait()
	camera = workspace.CurrentCamera
end
if not camera then
	warn("[TheTakeCamera] CurrentCamera unavailable")
	return
end

local config = ReplicatedStorage:WaitForChild(CONFIG_FOLDER_NAME, 15)
if not config then
	warn("[TheTakeCamera] cinematic config missing")
	return
end

local deadline = os.clock() + 15
while config:GetAttribute("Ready") ~= true and os.clock() < deadline do
	task.wait(0.05)
end
if config:GetAttribute("Ready") ~= true then
	warn("[TheTakeCamera] cinematic config never became ready")
	return
end

local startValue = config:WaitForChild("Start", 5)
local endValue = config:WaitForChild("End", 5)
if not startValue or not startValue:IsA("CFrameValue") or not endValue or not endValue:IsA("CFrameValue") then
	warn("[TheTakeCamera] Start/End camera values missing")
	return
end

local cameraStart = startValue.Value
local cameraEnd = endValue.Value
local released = false
local authoritativeCFrame = cameraStart
local authoritativeFov = START_FOV
local neutralMousePosition = UserInputService:GetMouseLocation()
local smoothedPointerX = 0
local smoothedPointerY = 0
local introComplete = false

local function requestStream(position: Vector3)
	if not workspace.StreamingEnabled then
		return
	end
	pcall(function()
		player:RequestStreamAroundAsync(position, 5)
	end)
end

requestStream(cameraStart.Position)
requestStream(cameraStart:Lerp(cameraEnd, 0.5).Position)
requestStream(cameraEnd.Position)

local function writeCamera(cframe: CFrame, fov: number)
	if released then
		return
	end
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = cframe
	camera.FieldOfView = fov
end

local function restoreCharacterCamera(character: Model?)
	if released == false then
		return
	end
	camera.CameraType = Enum.CameraType.Custom
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			camera.CameraSubject = humanoid
		end
	end
end

local function releaseCamera()
	if released then
		return
	end
	released = true
	RunService:UnbindFromRenderStep(BIND_NAME)
	camera.FieldOfView = 70
	restoreCharacterCamera(player.Character)
	if not player.Character then
		local connection
		connection = player.CharacterAdded:Connect(function(character)
			if connection then
				connection:Disconnect()
			end
			task.defer(restoreCharacterCamera, character)
		end)
	end
	print("[TheTakeCamera] cinematic authority released to donor gameplay")
end

player:GetAttributeChangedSignal(STARTED_ATTRIBUTE):Connect(function()
	if player:GetAttribute(STARTED_ATTRIBUTE) == true then
		releaseCamera()
	end
end)

if player:GetAttribute(STARTED_ATTRIBUTE) == true then
	releaseCamera()
	return
end

UserInputService.MouseBehavior = Enum.MouseBehavior.Default
UserInputService.MouseIconEnabled = true
writeCamera(cameraStart, START_FOV)
RunService.RenderStepped:Wait()
writeCamera(cameraStart, START_FOV)
player:SetAttribute(READY_ATTRIBUTE, true)
print("[TheTakeCamera] cinematic camera ready")

local startedAt = os.clock()
RunService:UnbindFromRenderStep(BIND_NAME)
RunService:BindToRenderStep(BIND_NAME, Enum.RenderPriority.Last.Value, function(dt)
	if released then
		return
	end

	if UserInputService.MouseBehavior ~= Enum.MouseBehavior.Default then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end

	local elapsed = os.clock() - startedAt
	local alpha = math.clamp(elapsed / INTRO_DURATION, 0, 1)
	local eased = TweenService:GetValue(alpha, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut)

	if alpha < 1 then
		neutralMousePosition = UserInputService:GetMouseLocation()
		smoothedPointerX = 0
		smoothedPointerY = 0
		authoritativeCFrame = cameraStart:Lerp(cameraEnd, eased)
		authoritativeFov = START_FOV + (END_FOV - START_FOV) * eased
	else
		if not introComplete then
			introComplete = true
			neutralMousePosition = UserInputService:GetMouseLocation()
			print("[TheTakeCamera] reached final cinematic framing")
		end

		local viewport = camera.ViewportSize
		local mouse = UserInputService:GetMouseLocation()
		local targetX = 0
		local targetY = 0
		if viewport.X > 0 and viewport.Y > 0 then
			targetX = math.clamp((mouse.X - neutralMousePosition.X) / math.max(viewport.X * 0.5, 1), -1, 1)
			targetY = math.clamp((mouse.Y - neutralMousePosition.Y) / math.max(viewport.Y * 0.5, 1), -1, 1)
		end

		local response = 1 - math.exp(-POINTER_RESPONSE * math.max(dt, 0))
		smoothedPointerX += (targetX - smoothedPointerX) * response
		smoothedPointerY += (targetY - smoothedPointerY) * response

		authoritativeCFrame = cameraEnd
			* CFrame.new(smoothedPointerX * PARALLAX_X_STUDS, -smoothedPointerY * PARALLAX_Y_STUDS, 0)
			* CFrame.Angles(
				math.rad(-smoothedPointerY * PARALLAX_PITCH_DEGREES),
				math.rad(-smoothedPointerX * PARALLAX_YAW_DEGREES),
				0
			)
		authoritativeFov = END_FOV
	end

	writeCamera(authoritativeCFrame, authoritativeFov)
end)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local CONFIG_FOLDER_NAME = "BankersMenuCameraConfig"
local INTRO_DURATION = 7.0
local INTRO_HOLD_DURATION = 0.35
local START_FOV = 58
local END_FOV = 44
local BIND_NAME = "BankersCameraAuthority"
local POSITION_EPSILON = 0.001
local LOOK_EPSILON = 0.0001

-- Menu micro-parallax: the final hero shot stays still until the mouse moves.
-- These offsets are intentionally small so the menu feels responsive rather
-- than behaving like a free-look gameplay camera.
local PARALLAX_X_STUDS = 0.32
local PARALLAX_Y_STUDS = 0.16
local PARALLAX_YAW_DEGREES = 0.85
local PARALLAX_PITCH_DEGREES = 0.42
local POINTER_DEADZONE = 0.025
local POINTER_RESPONSE = 7.0

local function getCamera(): Camera?
	local camera = workspace.CurrentCamera
	if camera then
		return camera
	end
	workspace:GetPropertyChangedSignal("CurrentCamera"):Wait()
	return workspace.CurrentCamera
end

local camera = getCamera()
if not camera then
	warn("[BankersCamera] CurrentCamera unavailable")
	return
end

local config = ReplicatedStorage:WaitForChild(CONFIG_FOLDER_NAME, 10)
if not config then
	warn("[BankersCamera] replicated camera config missing")
	return
end

local deadline = os.clock() + 10
while config:GetAttribute("Ready") ~= true and os.clock() < deadline do
	config:GetAttributeChangedSignal("Ready"):Wait()
end

if config:GetAttribute("Ready") ~= true then
	warn("[BankersCamera] camera config never became ready")
	return
end

local startValue = config:WaitForChild("Start", 5)
local endValue = config:WaitForChild("End", 5)
if not startValue or not startValue:IsA("CFrameValue") or not endValue or not endValue:IsA("CFrameValue") then
	warn("[BankersCamera] camera CFrame values missing")
	return
end

local cameraStart = startValue.Value
local cameraEnd = endValue.Value

print(string.format(
	"[BankersCamera] using Start %.2f, %.2f, %.2f -> End %.2f, %.2f, %.2f",
	cameraStart.Position.X,
	cameraStart.Position.Y,
	cameraStart.Position.Z,
	cameraEnd.Position.X,
	cameraEnd.Position.Y,
	cameraEnd.Position.Z
))

local authoritativeCFrame = cameraStart
local authoritativeFov = START_FOV
local writingCamera = false
local overrideCorrections = 0
local smoothedPointerX = 0
local smoothedPointerY = 0
local idleLogged = false

local function writeCamera(cframe: CFrame, fov: number)
	writingCamera = true
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = cframe
	camera.FieldOfView = fov
	writingCamera = false
end

local function applyDeadzone(value: number): number
	local magnitude = math.abs(value)
	if magnitude <= POINTER_DEADZONE then
		return 0
	end

	local remapped = (magnitude - POINTER_DEADZONE) / (1 - POINTER_DEADZONE)
	return math.sign(value) * math.clamp(remapped, 0, 1)
end

local function getNormalizedPointer(): (number, number)
	local viewport = camera.ViewportSize
	if viewport.X <= 0 or viewport.Y <= 0 then
		return 0, 0
	end

	local mouse = UserInputService:GetMouseLocation()
	local x = math.clamp(((mouse.X / viewport.X) - 0.5) * 2, -1, 1)
	local y = math.clamp(((mouse.Y / viewport.Y) - 0.5) * 2, -1, 1)
	return applyDeadzone(x), applyDeadzone(y)
end

local function buildMouseParallaxCamera(dt: number): CFrame
	local targetX, targetY = getNormalizedPointer()
	local response = 1 - math.exp(-POINTER_RESPONSE * math.max(dt, 0))
	smoothedPointerX += (targetX - smoothedPointerX) * response
	smoothedPointerY += (targetY - smoothedPointerY) * response

	local localX = smoothedPointerX * PARALLAX_X_STUDS
	local localY = -smoothedPointerY * PARALLAX_Y_STUDS
	local pitch = math.rad(-smoothedPointerY * PARALLAX_PITCH_DEGREES)
	local yaw = math.rad(-smoothedPointerX * PARALLAX_YAW_DEGREES)

	return cameraEnd
		* CFrame.new(localX, localY, 0)
		* CFrame.Angles(pitch, yaw, 0)
end

-- If another LocalScript writes CurrentCamera after Bankers does, immediately
-- restore the Bankers-authored frame. This keeps the menu camera deterministic.
camera:GetPropertyChangedSignal("CFrame"):Connect(function()
	if writingCamera then
		return
	end

	local positionError = (camera.CFrame.Position - authoritativeCFrame.Position).Magnitude
	local lookError = (camera.CFrame.LookVector - authoritativeCFrame.LookVector).Magnitude
	if positionError <= POSITION_EPSILON and lookError <= LOOK_EPSILON then
		return
	end

	overrideCorrections += 1
	writeCamera(authoritativeCFrame, authoritativeFov)

	if overrideCorrections == 1 then
		warn("[BankersCamera] another client camera writer was detected and overridden")
	end
end)

writeCamera(cameraStart, START_FOV)

local startedAt = os.clock()
local finishedLogged = false

RunService:UnbindFromRenderStep(BIND_NAME)
RunService:BindToRenderStep(BIND_NAME, Enum.RenderPriority.Last.Value, function(dt)
	local elapsed = os.clock() - startedAt
	local alpha = math.clamp(elapsed / INTRO_DURATION, 0, 1)
	local eased = TweenService:GetValue(alpha, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut)

	if alpha < 1 then
		authoritativeCFrame = cameraStart:Lerp(cameraEnd, eased)
		authoritativeFov = START_FOV + (END_FOV - START_FOV) * eased
	elseif elapsed < INTRO_DURATION + INTRO_HOLD_DURATION then
		authoritativeCFrame = cameraEnd
		authoritativeFov = END_FOV
	else
		authoritativeCFrame = buildMouseParallaxCamera(dt)
		authoritativeFov = END_FOV
		if not idleLogged then
			idleLogged = true
			print("[BankersCamera] mouse micro-parallax active")
		end
	end

	writeCamera(authoritativeCFrame, authoritativeFov)

	if alpha >= 1 and not finishedLogged then
		finishedLogged = true

		local positionError = (camera.CFrame.Position - cameraEnd.Position).Magnitude
		local lookError = (camera.CFrame.LookVector - cameraEnd.LookVector).Magnitude

		print("[BankersCamera] reached exact MenuCameraEnd framing")
		print(string.format(
			"[BankersCamera][CLIENT CHECK] live %.3f, %.3f, %.3f | expected %.3f, %.3f, %.3f | position error %.6f | look error %.6f | override corrections %d",
			camera.CFrame.Position.X,
			camera.CFrame.Position.Y,
			camera.CFrame.Position.Z,
			cameraEnd.Position.X,
			cameraEnd.Position.Y,
			cameraEnd.Position.Z,
			positionError,
			lookError,
			overrideCorrections
		))
	end
end)

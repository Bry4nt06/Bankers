local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local CONFIG_FOLDER_NAME = "BankersMenuCameraConfig"
local INTRO_DURATION = 7.0
local START_FOV = 58
local END_FOV = 44
local BIND_NAME = "BankersCameraAuthority"
local POSITION_EPSILON = 0.001
local LOOK_EPSILON = 0.0001

-- Final-shot mouse micro-parallax. The mouse position on the exact final frame
-- becomes the neutral point, eliminating the old post-intro snap/hitch.
local PARALLAX_X_STUDS = 0.78
local PARALLAX_Y_STUDS = 0.38
local PARALLAX_YAW_DEGREES = 1.35
local PARALLAX_PITCH_DEGREES = 0.68
local POINTER_RESPONSE = 8.5

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
local neutralMousePosition = UserInputService:GetMouseLocation()
local introComplete = false
local idleLogged = false
local pointerMotionLogged = false

local function writeCamera(cframe: CFrame, fov: number)
	writingCamera = true
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = cframe
	camera.FieldOfView = fov
	writingCamera = false
end

local function refreshNeutralMousePosition()
	neutralMousePosition = UserInputService:GetMouseLocation()
end

local function getPointerDeltaFromNeutral(): (number, number)
	local viewport = camera.ViewportSize
	if viewport.X <= 0 or viewport.Y <= 0 then
		return 0, 0
	end

	local mouse = UserInputService:GetMouseLocation()
	local halfWidth = math.max(viewport.X * 0.5, 1)
	local halfHeight = math.max(viewport.Y * 0.5, 1)

	local x = math.clamp((mouse.X - neutralMousePosition.X) / halfWidth, -1, 1)
	local y = math.clamp((mouse.Y - neutralMousePosition.Y) / halfHeight, -1, 1)
	return x, y
end

local function buildMouseParallaxCamera(dt: number): CFrame
	local targetX, targetY = getPointerDeltaFromNeutral()
	local response = 1 - math.exp(-POINTER_RESPONSE * math.max(dt, 0))
	smoothedPointerX += (targetX - smoothedPointerX) * response
	smoothedPointerY += (targetY - smoothedPointerY) * response

	if not pointerMotionLogged and (math.abs(smoothedPointerX) > 0.08 or math.abs(smoothedPointerY) > 0.08) then
		pointerMotionLogged = true
		print(string.format(
			"[BankersCamera] mouse movement detected x=%.2f y=%.2f; parallax is driving",
			smoothedPointerX,
			smoothedPointerY
		))
	end

	local localX = smoothedPointerX * PARALLAX_X_STUDS
	local localY = -smoothedPointerY * PARALLAX_Y_STUDS
	local pitch = math.rad(-smoothedPointerY * PARALLAX_PITCH_DEGREES)
	local yaw = math.rad(-smoothedPointerX * PARALLAX_YAW_DEGREES)

	return cameraEnd
		* CFrame.new(localX, localY, 0)
		* CFrame.Angles(pitch, yaw, 0)
end

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

-- PlayerModule can leave the cursor locked after controls are disabled. Keep the
-- menu cursor free so GetMouseLocation actually changes while the menu is open.
UserInputService.MouseBehavior = Enum.MouseBehavior.Default
UserInputService.MouseIconEnabled = true

writeCamera(cameraStart, START_FOV)

local startedAt = os.clock()

RunService:UnbindFromRenderStep(BIND_NAME)
RunService:BindToRenderStep(BIND_NAME, Enum.RenderPriority.Last.Value, function(dt)
	if UserInputService.MouseBehavior ~= Enum.MouseBehavior.Default then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end

	local elapsed = os.clock() - startedAt
	local alpha = math.clamp(elapsed / INTRO_DURATION, 0, 1)
	local eased = TweenService:GetValue(alpha, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut)

	if alpha < 1 then
		-- Track the cursor during the cinematic so its final location becomes the
		-- neutral point. This prevents any delayed snap after reaching the hero shot.
		refreshNeutralMousePosition()
		smoothedPointerX = 0
		smoothedPointerY = 0
		authoritativeCFrame = cameraStart:Lerp(cameraEnd, eased)
		authoritativeFov = START_FOV + (END_FOV - START_FOV) * eased
	else
		if not introComplete then
			introComplete = true
			refreshNeutralMousePosition()
			smoothedPointerX = 0
			smoothedPointerY = 0
			authoritativeCFrame = cameraEnd
			authoritativeFov = END_FOV

			print("[BankersCamera] reached exact MenuCameraEnd framing")
			print(string.format(
				"[BankersCamera][CLIENT CHECK] final position error %.6f | look error %.6f | override corrections %d",
				(camera.CFrame.Position - cameraEnd.Position).Magnitude,
				(camera.CFrame.LookVector - cameraEnd.LookVector).Magnitude,
				overrideCorrections
			))
		elseif not idleLogged then
			idleLogged = true
			print("[BankersCamera] mouse micro-parallax active; move the cursor to shift the final shot")
		end

		authoritativeCFrame = buildMouseParallaxCamera(dt)
		authoritativeFov = END_FOV
	end

	writeCamera(authoritativeCFrame, authoritativeFov)
end)

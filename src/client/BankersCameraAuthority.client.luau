local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local CONFIG_FOLDER_NAME = "BankersMenuCameraConfig"
local INTRO_DURATION = 7.0
local START_FOV = 58
local END_FOV = 44
local BIND_NAME = "BankersCameraAuthority"
local POSITION_EPSILON = 0.001
local LOOK_EPSILON = 0.0001

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

local function writeCamera(cframe: CFrame, fov: number)
	writingCamera = true
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = cframe
	camera.FieldOfView = fov
	writingCamera = false
end

-- If another LocalScript writes CurrentCamera after Bankers does, immediately
-- restore the Bankers-authored frame. This makes the menu camera deterministic.
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
RunService:BindToRenderStep(BIND_NAME, Enum.RenderPriority.Last.Value, function()
	local alpha = math.clamp((os.clock() - startedAt) / INTRO_DURATION, 0, 1)
	local eased = TweenService:GetValue(alpha, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut)

	if alpha < 1 then
		authoritativeCFrame = cameraStart:Lerp(cameraEnd, eased)
		authoritativeFov = START_FOV + (END_FOV - START_FOV) * eased
	else
		authoritativeCFrame = cameraEnd
		authoritativeFov = END_FOV
	end

	-- Run at RenderPriority.Last so this is the final normal camera write before render.
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
		print("[BankersCamera][CLIENT CHECK] live CFrame:", camera.CFrame)
		print("[BankersCamera][CLIENT CHECK] expected End CFrame:", cameraEnd)
	end
end)

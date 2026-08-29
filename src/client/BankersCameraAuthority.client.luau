local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local CONFIG_FOLDER_NAME = "BankersMenuCameraConfig"
local INTRO_DURATION = 7.0
local START_FOV = 58
local END_FOV = 44
local BIND_NAME = "BankersCameraAuthority"

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

camera.CameraType = Enum.CameraType.Scriptable
camera.CFrame = cameraStart
camera.FieldOfView = START_FOV

local startedAt = os.clock()
local finishedLogged = false

RunService:UnbindFromRenderStep(BIND_NAME)
RunService:BindToRenderStep(BIND_NAME, Enum.RenderPriority.Camera.Value + 20, function()
	local alpha = math.clamp((os.clock() - startedAt) / INTRO_DURATION, 0, 1)
	local eased = TweenService:GetValue(alpha, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut)

	camera.CameraType = Enum.CameraType.Scriptable

	if alpha < 1 then
		camera.CFrame = cameraStart:Lerp(cameraEnd, eased)
		camera.FieldOfView = START_FOV + (END_FOV - START_FOV) * eased
	else
		-- Exact final framing. No drift, parallax, look-at recalculation, or offset.
		camera.CFrame = cameraEnd
		camera.FieldOfView = END_FOV
		if not finishedLogged then
			finishedLogged = true
			print("[BankersCamera] reached exact MenuCameraEnd framing")
		end
	end
end)

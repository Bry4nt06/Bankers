local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local BIND_NAME = "BankersGetawayDriverCamera"
local TRUCK_NAME = "GetawayArmoredTruck"
local DRIVER_SEAT_NAME = "DriverSeat"

local activeTruck: Model? = nil
local activeChassis: BasePart? = nil
local activeHumanoid: Humanoid? = nil
local cameraCf: CFrame? = nil

local function restoreCamera()
	RunService:UnbindFromRenderStep(BIND_NAME)
	activeTruck = nil
	activeChassis = nil
	cameraCf = nil
	camera.CameraType = Enum.CameraType.Custom
	camera.FieldOfView = 70
	if activeHumanoid and activeHumanoid.Parent then
		camera.CameraSubject = activeHumanoid
	end
end

local function startDriverCamera(seat: BasePart, humanoid: Humanoid)
	local truck = seat:FindFirstAncestor(TRUCK_NAME)
	if not truck or not truck:IsA("Model") then
		return
	end
	local chassis = truck:FindFirstChild("Chassis")
	if not chassis or not chassis:IsA("BasePart") then
		return
	end

	activeTruck = truck
	activeChassis = chassis
	activeHumanoid = humanoid
	camera.CameraType = Enum.CameraType.Scriptable
	cameraCf = nil

	RunService:UnbindFromRenderStep(BIND_NAME)
	RunService:BindToRenderStep(BIND_NAME, Enum.RenderPriority.Camera.Value + 5, function(dt)
		if not activeTruck or not activeChassis or not activeHumanoid or activeHumanoid.SeatPart ~= seat then
			restoreCamera()
			return
		end

		local chassisCf = activeChassis.CFrame
		local lookPoint = activeChassis.Position + chassisCf.LookVector * 9 + Vector3.new(0, 3.8, 0)
		local desiredPosition = chassisCf:PointToWorldSpace(Vector3.new(0, 9.5, 24))

		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = {activeTruck, player.Character}
		params.IgnoreWater = true
		local direction = desiredPosition - lookPoint
		local hit = workspace:Raycast(lookPoint, direction, params)
		if hit then
			desiredPosition = hit.Position + hit.Normal * 1.5
		end

		local desired = CFrame.lookAt(desiredPosition, lookPoint)
		local response = 1 - math.exp(-7.5 * math.max(dt, 0))
		cameraCf = cameraCf and cameraCf:Lerp(desired, response) or desired
		camera.CFrame = cameraCf

		local speed = activeTruck:GetAttribute("Speed")
		local speedAlpha = type(speed) == "number" and math.clamp(speed / 82, 0, 1) or 0
		camera.FieldOfView = 70 + speedAlpha * 8
	end)

	print("[BankersTruckCamera] driver chase camera active")
end

local function bindCharacter(character: Model)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid or not humanoid:IsA("Humanoid") then
		return
	end
	activeHumanoid = humanoid

	humanoid.Seated:Connect(function(active, seat)
		if active and seat and seat.Name == DRIVER_SEAT_NAME and seat:FindFirstAncestor(TRUCK_NAME) then
			startDriverCamera(seat, humanoid)
		else
			restoreCamera()
		end
	end)
end

if player.Character then
	task.defer(bindCharacter, player.Character)
end
player.CharacterAdded:Connect(bindCharacter)

print("[BankersTruckCamera] getaway vehicle camera ready")

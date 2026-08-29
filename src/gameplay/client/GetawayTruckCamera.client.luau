local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local BIND_NAME = "BankersGetawayDriverCamera"
local TRUCK_NAME = "GetawayArmoredTruck"
local DRIVER_SEAT_NAME = "DriverSeat"

-- Higher/farther than the first pass so the driver can read the road ahead.
local CAMERA_HEIGHT = 15.5
local CAMERA_DISTANCE = 27
local LOOK_AHEAD = 34
local LOOK_HEIGHT = 5.0
local CAMERA_RESPONSE = 8.5
local BASE_FOV = 68
local SPEED_FOV_BONUS = 7

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

local function buildCameraFilter(truck: Model): {Instance}
	local filter: {Instance} = {truck}
	if player.Character then
		table.insert(filter, player.Character)
	end

	-- Route checkpoints/extraction zones are transparent gameplay triggers, not
	-- camera obstacles. Excluding them prevents a checkpoint crossing from
	-- snapping the chase camera toward the truck.
	local graybox = workspace:FindFirstChild("GetawayGraybox")
	if graybox then
		local checkpoints = graybox:FindFirstChild("RouteCheckpoints", true)
		if checkpoints then
			table.insert(filter, checkpoints)
		end
		local extraction = graybox:FindFirstChild("ExtractionZone", true)
		if extraction then
			table.insert(filter, extraction)
		end
		local truckStart = graybox:FindFirstChild("ArmoredTruckStart", true)
		if truckStart then
			table.insert(filter, truckStart)
		end
	end
	return filter
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
		local lookPoint = activeChassis.Position + chassisCf.LookVector * LOOK_AHEAD + Vector3.new(0, LOOK_HEIGHT, 0)
		local desiredPosition = chassisCf:PointToWorldSpace(Vector3.new(0, CAMERA_HEIGHT, CAMERA_DISTANCE))

		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = buildCameraFilter(activeTruck)
		params.IgnoreWater = true
		local direction = desiredPosition - lookPoint
		local hit = workspace:Raycast(lookPoint, direction, params)
		if hit then
			desiredPosition = hit.Position + hit.Normal * 1.75
		end

		local desired = CFrame.lookAt(desiredPosition, lookPoint)
		local response = 1 - math.exp(-CAMERA_RESPONSE * math.max(dt, 0))
		cameraCf = cameraCf and cameraCf:Lerp(desired, response) or desired
		camera.CFrame = cameraCf

		local speed = activeTruck:GetAttribute("Speed")
		local speedAlpha = type(speed) == "number" and math.clamp(speed / 82, 0, 1) or 0
		camera.FieldOfView = BASE_FOV + speedAlpha * SPEED_FOV_BONUS
	end)

	print("[BankersTruckCamera] high chase camera active; route triggers excluded from camera collision")
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

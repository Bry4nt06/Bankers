local InsertService = game:GetService("InsertService")

local BuildGetawayTruck = {}

local TRUCK_MODEL_NAME = "GetawayArmoredTruck"
local GRAYBOX_MODEL_NAME = "GetawayGraybox"
local START_MARKER_NAME = "ArmoredTruckStart"
local DONOR_ASSET_ID = 5144461510

local BODY_COLOR = Color3.fromRGB(47, 50, 54)
local DARK_COLOR = Color3.fromRGB(24, 25, 28)
local GLASS_COLOR = Color3.fromRGB(35, 48, 60)

local function weld(root: BasePart, part: BasePart)
	local constraint = Instance.new("WeldConstraint")
	constraint.Part0 = root
	constraint.Part1 = part
	constraint.Parent = root
end

local function makePart(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material, collide: boolean?): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cf
	part.Color = color
	part.Material = material
	part.Anchored = false
	part.CanCollide = collide ~= false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function makeSeat(parent: Instance, name: string, size: Vector3, cf: CFrame, isDriver: boolean)
	local seat
	if isDriver then
		seat = Instance.new("VehicleSeat")
		seat.MaxSpeed = 0
		seat.Torque = 0
		seat.TurnSpeed = 0
	else
		seat = Instance.new("Seat")
	end
	seat.Name = name
	seat.Size = size
	seat.CFrame = cf
	seat.Color = DARK_COLOR
	seat.Material = Enum.Material.Metal
	seat.Anchored = false
	seat.CanCollide = false
	seat.Parent = parent
	return seat
end

local function makeWheel(parent: Instance, root: BasePart, name: string, offset: Vector3)
	local wheel = makePart(parent, name, Vector3.new(2.6, 6.2, 6.2), root.CFrame * CFrame.new(offset), DARK_COLOR, Enum.Material.Rubber, false)
	wheel.Shape = Enum.PartType.Cylinder
	wheel.CFrame = wheel.CFrame * CFrame.Angles(0, 0, math.rad(90))
	wheel.Massless = true
	weld(root, wheel)
	return wheel
end

local function removeUnsafeDonorInstances(root: Instance)
	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("Script")
			or descendant:IsA("LocalScript")
			or descendant:IsA("ModuleScript")
			or descendant:IsA("Seat")
			or descendant:IsA("VehicleSeat")
			or descendant:IsA("BodyMover")
			or descendant:IsA("LinearVelocity")
			or descendant:IsA("AngularVelocity")
			or descendant:IsA("VectorForce")
			or descendant:IsA("AlignPosition")
			or descendant:IsA("AlignOrientation") then
			descendant:Destroy()
		end
	end
end

local function weldVisualToChassis(visual: Model, chassis: BasePart)
	for _, descendant in ipairs(visual:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = false
			descendant.Massless = true
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
			weld(chassis, descendant)
		end
	end
end

local function placeDonorByBoundingBox(visual: Model, chassis: BasePart)
	local _, originalSize = visual:GetBoundingBox()
	if originalSize.Magnitude <= 0 then
		error("donor vehicle has no measurable geometry")
	end

	-- Fit the visual into our known armored-truck collision envelope without
	-- changing the driving physics dimensions.
	local targetSize = Vector3.new(11.2, 9.2, 22.0)
	local scale = math.min(
		targetSize.X / math.max(originalSize.X, 0.01),
		targetSize.Y / math.max(originalSize.Y, 0.01),
		targetSize.Z / math.max(originalSize.Z, 0.01)
	)
	visual:ScaleTo(scale)

	local bboxCf, bboxSize = visual:GetBoundingBox()
	local rotate = bboxSize.X > bboxSize.Z and CFrame.Angles(0, math.rad(90), 0) or CFrame.identity
	local desiredBbox = chassis.CFrame * CFrame.new(0, 4.2, 0.4) * rotate
	local transform = desiredBbox * bboxCf:Inverse()

	for _, descendant in ipairs(visual:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.CFrame = transform * descendant.CFrame
		end
	end
end

local function addDonorVisual(model: Model, chassis: BasePart): boolean
	local ok, loadedOrError = pcall(function()
		return InsertService:LoadAsset(DONOR_ASSET_ID)
	end)
	if not ok then
		warn(string.format("[BankersTruckBake] could not load donor asset %d: %s", DONOR_ASSET_ID, tostring(loadedOrError)))
		return false
	end

	local loaded = loadedOrError
	if not loaded or not loaded:IsA("Model") then
		warn(string.format("[BankersTruckBake] donor asset %d did not return a Model", DONOR_ASSET_ID))
		return false
	end

	loaded.Name = "DonorVisual_5144461510"
	removeUnsafeDonorInstances(loaded)
	loaded.Parent = model

	local geometryCount = 0
	for _, descendant in ipairs(loaded:GetDescendants()) do
		if descendant:IsA("BasePart") then
			geometryCount += 1
		end
	end
	if geometryCount == 0 then
		loaded:Destroy()
		warn("[BankersTruckBake] donor asset contained no usable BaseParts")
		return false
	end

	local positioned, positionError = pcall(placeDonorByBoundingBox, loaded, chassis)
	if not positioned then
		loaded:Destroy()
		warn("[BankersTruckBake] donor visual alignment failed: " .. tostring(positionError))
		return false
	end

	weldVisualToChassis(loaded, chassis)
	model:SetAttribute("VisualDonorAssetId", DONOR_ASSET_ID)
	print(string.format("[BankersTruckBake] using Creator Store vehicle donor %d (%d visual parts)", DONOR_ASSET_ID, geometryCount))
	return true
end

local function addFallbackVisual(model: Model, chassis: BasePart)
	local lowerBody = makePart(model, "LowerBody", Vector3.new(11, 4.5, 19.5), chassis.CFrame * CFrame.new(0, 3.1, 0.5), BODY_COLOR, Enum.Material.Metal, false)
	lowerBody.Massless = true
	weld(chassis, lowerBody)

	local upperBody = makePart(model, "UpperBody", Vector3.new(10.4, 4.2, 14.5), chassis.CFrame * CFrame.new(0, 6.9, 1.8), BODY_COLOR, Enum.Material.Metal, false)
	upperBody.Massless = true
	weld(chassis, upperBody)

	local hood = makePart(model, "Hood", Vector3.new(10.2, 2.4, 5.5), chassis.CFrame * CFrame.new(0, 4.6, -8.3), BODY_COLOR, Enum.Material.Metal, false)
	hood.Massless = true
	weld(chassis, hood)

	local windshield = makePart(model, "Windshield", Vector3.new(9.4, 2.5, 0.35), chassis.CFrame * CFrame.new(0, 6.9, -5.55) * CFrame.Angles(math.rad(-10), 0, 0), GLASS_COLOR, Enum.Material.Glass, false)
	windshield.Transparency = 0.28
	windshield.Massless = true
	weld(chassis, windshield)

	local rearDoor = makePart(model, "RearDoor", Vector3.new(8.2, 5.4, 0.45), chassis.CFrame * CFrame.new(0, 5.3, 10.15), DARK_COLOR, Enum.Material.Metal, false)
	rearDoor.Massless = true
	weld(chassis, rearDoor)

	for _, offset in ipairs({
		Vector3.new(-6.0, -0.15, -6.8),
		Vector3.new(6.0, -0.15, -6.8),
		Vector3.new(-6.0, -0.15, 6.7),
		Vector3.new(6.0, -0.15, 6.7),
	}) do
		makeWheel(model, chassis, "Wheel", offset)
	end
end

function BuildGetawayTruck.Run()
	local graybox = workspace:FindFirstChild(GRAYBOX_MODEL_NAME)
	if not graybox then
		error("[BankersTruckBake] GetawayGraybox not found. Bake the getaway graybox first.")
	end

	local marker = graybox:FindFirstChild(START_MARKER_NAME, true)
	if not marker or not marker:IsA("BasePart") then
		error("[BankersTruckBake] ArmoredTruckStart marker not found in GetawayGraybox.")
	end

	local old = workspace:FindFirstChild(TRUCK_MODEL_NAME)
	if old then
		old:Destroy()
	end

	local model = Instance.new("Model")
	model.Name = TRUCK_MODEL_NAME
	model:SetAttribute("BankersGetawayTruck", true)
	model:SetAttribute("MaxHealth", 1000)
	model:SetAttribute("Health", 1000)
	model:SetAttribute("Destroyed", false)
	model.Parent = workspace

	local spawnCf = marker.CFrame * CFrame.new(0, 4.2, 0)
	local chassis = makePart(model, "Chassis", Vector3.new(11.5, 2.2, 22), spawnCf, DARK_COLOR, Enum.Material.Metal, true)
	chassis.CustomPhysicalProperties = PhysicalProperties.new(5, 0.65, 0.15, 1, 1)
	model.PrimaryPart = chassis

	local donorLoaded = addDonorVisual(model, chassis)
	if donorLoaded then
		chassis.Transparency = 1
	else
		warn("[BankersTruckBake] falling back to the simple internal truck visual")
		addFallbackVisual(model, chassis)
	end

	local driver = makeSeat(model, "DriverSeat", Vector3.new(2.2, 1, 2.2), chassis.CFrame * CFrame.new(-2.25, 3.3, -4.4), true)
	driver:SetAttribute("CrewRole", "Driver")
	driver.Massless = true
	weld(chassis, driver)

	local leftGunner = makeSeat(model, "LeftGunnerSeat", Vector3.new(2.2, 1, 2.2), chassis.CFrame * CFrame.new(-3.6, 3.3, 2.0) * CFrame.Angles(0, math.rad(90), 0), false)
	leftGunner:SetAttribute("CrewRole", "LeftGunner")
	leftGunner.Massless = true
	weld(chassis, leftGunner)

	local rightGunner = makeSeat(model, "RightGunnerSeat", Vector3.new(2.2, 1, 2.2), chassis.CFrame * CFrame.new(3.6, 3.3, 2.0) * CFrame.Angles(0, math.rad(-90), 0), false)
	rightGunner:SetAttribute("CrewRole", "RightGunner")
	rightGunner.Massless = true
	weld(chassis, rightGunner)

	local rearGunner = makeSeat(model, "RearGunnerSeat", Vector3.new(2.2, 1, 2.2), chassis.CFrame * CFrame.new(0, 3.3, 6.8) * CFrame.Angles(0, math.rad(180), 0), false)
	rearGunner:SetAttribute("CrewRole", "RearGunner")
	rearGunner.Massless = true
	weld(chassis, rearGunner)

	local cameraTarget = makePart(model, "CameraTarget", Vector3.new(1, 1, 1), chassis.CFrame * CFrame.new(0, 5.5, 1.5), BODY_COLOR, Enum.Material.SmoothPlastic, false)
	cameraTarget.Transparency = 1
	cameraTarget.CanTouch = false
	cameraTarget.CanQuery = false
	cameraTarget.Massless = true
	weld(chassis, cameraTarget)

	local leftMount = makePart(model, "LeftGunMount", Vector3.new(0.6, 0.6, 0.6), chassis.CFrame * CFrame.new(-5.35, 5.0, 1.6), DARK_COLOR, Enum.Material.Metal, false)
	leftMount.Transparency = 1
	leftMount.Massless = true
	weld(chassis, leftMount)

	local rightMount = makePart(model, "RightGunMount", Vector3.new(0.6, 0.6, 0.6), chassis.CFrame * CFrame.new(5.35, 5.0, 1.6), DARK_COLOR, Enum.Material.Metal, false)
	rightMount.Transparency = 1
	rightMount.Massless = true
	weld(chassis, rightMount)

	local rearMount = makePart(model, "RearGunMount", Vector3.new(0.6, 0.6, 0.6), chassis.CFrame * CFrame.new(0, 5.0, 10.0), DARK_COLOR, Enum.Material.Metal, false)
	rearMount.Transparency = 1
	rearMount.Massless = true
	weld(chassis, rearMount)

	chassis.AssemblyLinearVelocity = Vector3.zero
	chassis.AssemblyAngularVelocity = Vector3.zero

	print("[BankersTruckBake] COMPLETE: getaway truck created with sanitized Creator Store donor when available. Press Ctrl+S to save it into BankersGameplay.rbxl.")
	return model
end

return BuildGetawayTruck

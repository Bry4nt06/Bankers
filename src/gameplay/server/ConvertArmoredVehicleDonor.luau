local ConvertArmoredVehicleDonor = {}

local DONOR_NAMES = {
	"Armored Vehicle",
	"ArmoredVehicle",
}
local TRUCK_NAME = "GetawayArmoredTruck"

local PLACEHOLDER_NAMES = {
	LowerBody = true,
	UpperBody = true,
	Hood = true,
	Windshield = true,
	RearDoor = true,
	Wheel = true,
}

local function findDonor(): Model?
	for _, name in ipairs(DONOR_NAMES) do
		local candidate = workspace:FindFirstChild(name)
		if candidate and candidate:IsA("Model") then
			return candidate
		end
	end
	return nil
end

local function removeUnsafeContent(root: Instance): number
	local removed = 0
	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("Script")
			or descendant:IsA("LocalScript")
			or descendant:IsA("ModuleScript")
			or descendant:IsA("Seat")
			or descendant:IsA("VehicleSeat")
			or descendant:IsA("Sound")
			or descendant:IsA("BodyMover")
			or descendant:IsA("LinearVelocity")
			or descendant:IsA("AngularVelocity")
			or descendant:IsA("VectorForce")
			or descendant:IsA("AlignPosition")
			or descendant:IsA("AlignOrientation")
			or descendant:IsA("Constraint")
			or descendant:IsA("JointInstance") then
			descendant:Destroy()
			removed += 1
		end
	end
	return removed
end

local function clearPlaceholderVisual(truck: Model)
	for _, child in ipairs(truck:GetChildren()) do
		if PLACEHOLDER_NAMES[child.Name] then
			child:Destroy()
		end
	end

	local oldVisual = truck:FindFirstChild("ConvertedDonorVisual")
	if oldVisual then
		oldVisual:Destroy()
	end
end

local function weld(root: BasePart, part: BasePart)
	local constraint = Instance.new("WeldConstraint")
	constraint.Part0 = root
	constraint.Part1 = part
	constraint.Parent = root
end

local function fitVisualToTruck(visual: Model, chassis: BasePart)
	local _, originalSize = visual:GetBoundingBox()
	if originalSize.Magnitude <= 0 then
		error("donor visual has no measurable geometry")
	end

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
			descendant.Anchored = false
			descendant.Massless = true
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
			weld(chassis, descendant)
		end
	end
end

function ConvertArmoredVehicleDonor.Run()
	local donor = findDonor()
	if not donor then
		error("[BankersVehicleConvert] Workspace donor 'Armored Vehicle' not found")
	end

	local truck = workspace:FindFirstChild(TRUCK_NAME)
	if not truck or not truck:IsA("Model") then
		error("[BankersVehicleConvert] GetawayArmoredTruck not found. Bake the Bankers truck first.")
	end

	local chassis = truck:FindFirstChild("Chassis")
	if not chassis or not chassis:IsA("BasePart") then
		error("[BankersVehicleConvert] GetawayArmoredTruck is missing Chassis")
	end

	local visual = donor:Clone()
	visual.Name = "ConvertedDonorVisual"
	local removed = removeUnsafeContent(visual)

	local partCount = 0
	for _, descendant in ipairs(visual:GetDescendants()) do
		if descendant:IsA("BasePart") then
			partCount += 1
		end
	end
	if partCount == 0 then
		visual:Destroy()
		error("[BankersVehicleConvert] donor contained no usable BaseParts after sanitizing")
	end

	clearPlaceholderVisual(truck)
	visual.Parent = truck
	fitVisualToTruck(visual, chassis)
	chassis.Transparency = 1

	truck:SetAttribute("VisualSource", "Workspace Armored Vehicle")
	truck:SetAttribute("ConvertedDonorParts", partCount)
	truck:SetAttribute("ConvertedDonorObjectsRemoved", removed)

	donor:Destroy()

	print(string.format(
		"[BankersVehicleConvert] COMPLETE: Armored Vehicle converted into GetawayArmoredTruck | %d visual parts | %d scripts/sounds/physics objects stripped | original donor removed",
		partCount,
		removed
	))
	print("[BankersVehicleConvert] Press Ctrl+S, then Play to test E-exit and the updated chase camera.")
	return truck
end

return ConvertArmoredVehicleDonor

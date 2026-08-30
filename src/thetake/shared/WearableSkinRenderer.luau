local Renderer = {}

local OVERLAY_NAME = "TheTakeWearableSkin"

local COLORS = {
	navy = Color3.fromRGB(20, 35, 82),
	wine = Color3.fromRGB(108, 24, 60),
	bronze = Color3.fromRGB(193, 119, 51),
	cyan = Color3.fromRGB(45, 174, 190),
}

local function clear(rig: Model)
	local existing = rig:FindFirstChild(OVERLAY_NAME)
	if existing then
		existing:Destroy()
	end
end

local function weldPanel(folder: Folder, target: BasePart, name: string, size: Vector3, offset: CFrame, color: Color3, material: Enum.Material)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = material
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
	part.CastShadow = true
	part.CFrame = target.CFrame * offset
	part.Parent = folder

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = target
	weld.Part1 = part
	weld.Parent = part

	return part
end

function Renderer.Clear(rig: Model)
	clear(rig)
end

function Renderer.ApplyDefaultCrew(rig: Model)
	clear(rig)

	local torso = rig:FindFirstChild("UpperTorso") or rig:FindFirstChild("Torso")
	if not torso or not torso:IsA("BasePart") then
		return false
	end

	local folder = Instance.new("Folder")
	folder.Name = OVERLAY_NAME
	folder.Parent = rig

	local chestWidth = torso.Size.X + 0.16
	local chestHeight = math.max(torso.Size.Y * 0.72, 1.15)
	local chestDepth = 0.18

	weldPanel(
		folder,
		torso,
		"FrontCarrier",
		Vector3.new(chestWidth, chestHeight, chestDepth),
		CFrame.new(0, -torso.Size.Y * 0.03, -(torso.Size.Z / 2 + chestDepth / 2 + 0.02)),
		COLORS.navy,
		Enum.Material.Fabric
	)

	weldPanel(
		folder,
		torso,
		"BackCarrier",
		Vector3.new(chestWidth, chestHeight * 0.9, chestDepth),
		CFrame.new(0, -torso.Size.Y * 0.01, torso.Size.Z / 2 + chestDepth / 2 + 0.02),
		COLORS.wine,
		Enum.Material.Fabric
	)

	local strapWidth = math.max(torso.Size.X * 0.15, 0.24)
	for _, x in ipairs({-torso.Size.X * 0.28, torso.Size.X * 0.28}) do
		weldPanel(
			folder,
			torso,
			"ShoulderStrap",
			Vector3.new(strapWidth, torso.Size.Y * 0.82, 0.11),
			CFrame.new(x, 0, -(torso.Size.Z / 2 + 0.13)),
			COLORS.bronze,
			Enum.Material.Fabric
		)
	end

	local belt = weldPanel(
		folder,
		torso,
		"CrewBelt",
		Vector3.new(torso.Size.X + 0.24, 0.22, torso.Size.Z + 0.20),
		CFrame.new(0, -torso.Size.Y * 0.44, 0),
		COLORS.bronze,
		Enum.Material.Metal
	)
	belt.CastShadow = false

	local centerAccent = weldPanel(
		folder,
		torso,
		"CrewAccent",
		Vector3.new(math.max(torso.Size.X * 0.28, 0.5), 0.12, 0.08),
		CFrame.new(0, torso.Size.Y * 0.18, -(torso.Size.Z / 2 + 0.16)),
		COLORS.cyan,
		Enum.Material.Neon
	)
	centerAccent.CastShadow = false

	for _, limbName in ipairs({"LeftUpperArm", "RightUpperArm", "Left Arm", "Right Arm"}) do
		local limb = rig:FindFirstChild(limbName)
		if limb and limb:IsA("BasePart") then
			weldPanel(
				folder,
				limb,
				"CrewArmBand",
				Vector3.new(limb.Size.X + 0.08, math.max(limb.Size.Y * 0.18, 0.22), limb.Size.Z + 0.08),
				CFrame.new(0, limb.Size.Y * 0.20, 0),
				COLORS.wine,
				Enum.Material.Fabric
			)
		end
	end

	return true
end

return Renderer

local BuildGetawayGraybox = {}

local MODEL_NAME = "GetawayGraybox"
local ROAD_WIDTH = 64
local ROAD_THICKNESS = 1

local routePoints = {
	Vector3.new(0, 0, 0),
	Vector3.new(0, 0, -260),
	Vector3.new(180, 0, -440),
	Vector3.new(500, 0, -440),
	Vector3.new(740, 0, -620),
	Vector3.new(740, 0, -1000),
	Vector3.new(980, 0, -1220),
	Vector3.new(1300, 0, -1220),
	Vector3.new(1550, 0, -1450),
}

local sectionNames = {
	"Bank Exit",
	"Downtown Grid",
	"Commercial Streets",
	"Downtown Arterial",
	"Industrial Entry",
	"Industrial District",
	"Highway Approach",
	"Tunnel Run",
}

local function newPart(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Anchored = true
	part.CanCollide = true
	part.Color = color
	part.Material = material
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function segmentCFrame(a: Vector3, b: Vector3): (CFrame, number)
	local midpoint = (a + b) * 0.5
	local length = (b - a).Magnitude
	return CFrame.lookAt(midpoint, b), length
end

local function addRoadSegment(parent: Instance, index: number, a: Vector3, b: Vector3)
	local cf, length = segmentCFrame(a, b)
	local road = newPart(
		parent,
		string.format("Road_%02d_%s", index, sectionNames[index] or "Route"),
		Vector3.new(ROAD_WIDTH, ROAD_THICKNESS, length),
		cf * CFrame.new(0, -0.5, 0),
		Color3.fromRGB(42, 42, 45),
		Enum.Material.Asphalt
	)
	road:SetAttribute("Section", sectionNames[index] or "Route")

	local stripeSpacing = 34
	local stripeCount = math.max(1, math.floor(length / stripeSpacing))
	for stripeIndex = 1, stripeCount do
		local z = -length * 0.5 + (stripeIndex - 0.5) * (length / stripeCount)
		local stripe = newPart(
			parent,
			string.format("LaneStripe_%02d_%02d", index, stripeIndex),
			Vector3.new(0.45, 0.04, 12),
			cf * CFrame.new(0, 0.04, z),
			Color3.fromRGB(228, 210, 120),
			Enum.Material.SmoothPlastic
		)
		stripe.CanCollide = false
		stripe.CanTouch = false
	end

	local right = cf.RightVector
	for blockIndex = 1, 3 do
		local t = blockIndex / 4
		local center = a:Lerp(b, t)
		local height = 36 + ((index * 17 + blockIndex * 13) % 52)
		local depth = 38 + ((index * 11 + blockIndex * 7) % 26)
		for _, side in ipairs({-1, 1}) do
			local offset = right * side * (ROAD_WIDTH * 0.5 + depth * 0.5 + 10)
			local building = newPart(
				parent,
				string.format("Block_%02d_%02d_%s", index, blockIndex, side < 0 and "L" or "R"),
				Vector3.new(depth, height, depth),
				CFrame.new(center + offset + Vector3.new(0, height * 0.5, 0)),
				index >= 5 and Color3.fromRGB(88, 83, 77) or Color3.fromRGB(104, 108, 116),
				index >= 5 and Enum.Material.Concrete or Enum.Material.Brick
			)
			building:SetAttribute("GrayboxBuilding", true)
		end
	end
end

local function addCheckpoint(parent: Instance, sequence: number, point: Vector3, lookAtPoint: Vector3)
	local checkpoint = newPart(
		parent,
		string.format("CP%02d", sequence),
		Vector3.new(ROAD_WIDTH - 4, 10, 6),
		CFrame.lookAt(point + Vector3.new(0, 5, 0), lookAtPoint + Vector3.new(0, 5, 0)),
		Color3.fromRGB(255, 170, 0),
		Enum.Material.Neon
	)
	checkpoint.Transparency = 0.72
	checkpoint.CanCollide = false
	checkpoint.CanTouch = true
	checkpoint:SetAttribute("Sequence", sequence)
	return checkpoint
end

local function addPoliceSpawn(parent: Instance, index: number, point: Vector3, directionPoint: Vector3, side: number)
	local roadCf = CFrame.lookAt(point, directionPoint)
	local spawnPoint = newPart(
		parent,
		string.format("PoliceSpawn_%02d", index),
		Vector3.new(10, 1, 18),
		roadCf * CFrame.new(side * 46, 0.5, 0),
		Color3.fromRGB(40, 90, 180),
		Enum.Material.Neon
	)
	spawnPoint.Transparency = 0.45
	spawnPoint.CanCollide = false
	spawnPoint.CanTouch = false
	spawnPoint:SetAttribute("WaveIndex", index)
end

local function addTunnel(parent: Instance, startPoint: Vector3, endPoint: Vector3)
	local cf, length = segmentCFrame(startPoint, endPoint)
	local tunnel = Instance.new("Folder")
	tunnel.Name = "EscapeTunnel"
	tunnel.Parent = parent

	newPart(tunnel, "TunnelRoof", Vector3.new(ROAD_WIDTH + 18, 4, length), cf * CFrame.new(0, 25, 0), Color3.fromRGB(58, 58, 61), Enum.Material.Concrete)
	newPart(tunnel, "TunnelWallL", Vector3.new(4, 27, length), cf * CFrame.new(-(ROAD_WIDTH * 0.5 + 7), 12, 0), Color3.fromRGB(66, 66, 69), Enum.Material.Concrete)
	newPart(tunnel, "TunnelWallR", Vector3.new(4, 27, length), cf * CFrame.new(ROAD_WIDTH * 0.5 + 7, 12, 0), Color3.fromRGB(66, 66, 69), Enum.Material.Concrete)
end

function BuildGetawayGraybox.Run()
	local old = workspace:FindFirstChild(MODEL_NAME)
	if old then
		old:Destroy()
	end

	local model = Instance.new("Model")
	model.Name = MODEL_NAME
	model.Parent = workspace

	local roads = Instance.new("Folder")
	roads.Name = "Roads"
	roads.Parent = model

	for index = 1, #routePoints - 1 do
		addRoadSegment(roads, index, routePoints[index], routePoints[index + 1])
	end

	local checkpoints = Instance.new("Folder")
	checkpoints.Name = "RouteCheckpoints"
	checkpoints.Parent = model
	for sequence = 1, 8 do
		local pointIndex = sequence + 1
		local point = routePoints[pointIndex]
		local previous = routePoints[math.max(1, pointIndex - 1)]
		addCheckpoint(checkpoints, sequence, point, point + (point - previous))
	end

	local policeSpawns = Instance.new("Folder")
	policeSpawns.Name = "PoliceSpawnPoints"
	policeSpawns.Parent = model
	local spawnRouteIndices = {2, 3, 4, 5, 6, 7, 8}
	for index, routeIndex in ipairs(spawnRouteIndices) do
		local point = routePoints[routeIndex]
		local nextPoint = routePoints[math.min(#routePoints, routeIndex + 1)]
		addPoliceSpawn(policeSpawns, index, point, nextPoint, index % 2 == 0 and 1 or -1)
	end

	local truckStart = newPart(
		model,
		"ArmoredTruckStart",
		Vector3.new(18, 1, 30),
		CFrame.lookAt(routePoints[1] + Vector3.new(0, 0.5, -22), routePoints[2]),
		Color3.fromRGB(225, 125, 35),
		Enum.Material.Neon
	)
	truckStart.Transparency = 0.35
	truckStart.CanCollide = false

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "CrewSpawn"
	spawn.Size = Vector3.new(14, 1, 14)
	spawn.CFrame = CFrame.new(routePoints[1] + Vector3.new(-18, 2.5, 16))
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Transparency = 0.25
	spawn.Parent = model

	local extractionPoint = routePoints[#routePoints]
	local extraction = newPart(
		model,
		"ExtractionZone",
		Vector3.new(ROAD_WIDTH - 8, 2, 44),
		CFrame.lookAt(extractionPoint + Vector3.new(0, 1, 0), extractionPoint + (extractionPoint - routePoints[#routePoints - 1])),
		Color3.fromRGB(80, 220, 120),
		Enum.Material.Neon
	)
	extraction.Transparency = 0.45
	extraction.CanCollide = false
	extraction.CanTouch = true

	addTunnel(model, routePoints[#routePoints - 1], routePoints[#routePoints])

	model:SetAttribute("BankersGetawayGraybox", true)
	model:SetAttribute("RouteLengthStuds", math.floor((routePoints[#routePoints] - routePoints[1]).Magnitude))

	print("[BankersGetawayBake] COMPLETE: getaway graybox created. Press Ctrl+S to save it into the gameplay place.")
	return model
end

return BuildGetawayGraybox

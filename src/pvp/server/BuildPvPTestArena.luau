local BuildPvPTestArena = {}

local MODEL_NAME = "PvPTestArena"

local function part(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Anchored = true
	p.CanCollide = true
	p.Color = color
	p.Material = material
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function spawn(parent: Instance, name: string, position: Vector3)
	local s = Instance.new("SpawnLocation")
	s.Name = name
	s.Size = Vector3.new(12, 1, 12)
	s.CFrame = CFrame.new(position)
	s.Anchored = true
	s.Neutral = true
	s.Transparency = 0.35
	s.Parent = parent
	return s
end

function BuildPvPTestArena.Run()
	local old = workspace:FindFirstChild(MODEL_NAME)
	if old then
		old:Destroy()
	end

	local model = Instance.new("Model")
	model.Name = MODEL_NAME
	model:SetAttribute("TemporaryMechanicsTestMap", true)
	model.Parent = workspace

	part(model, "Floor", Vector3.new(260, 2, 260), CFrame.new(0, -1, 0), Color3.fromRGB(62, 64, 68), Enum.Material.Concrete)
	part(model, "WallNorth", Vector3.new(260, 24, 4), CFrame.new(0, 12, -130), Color3.fromRGB(45, 47, 51), Enum.Material.Concrete)
	part(model, "WallSouth", Vector3.new(260, 24, 4), CFrame.new(0, 12, 130), Color3.fromRGB(45, 47, 51), Enum.Material.Concrete)
	part(model, "WallWest", Vector3.new(4, 24, 260), CFrame.new(-130, 12, 0), Color3.fromRGB(45, 47, 51), Enum.Material.Concrete)
	part(model, "WallEast", Vector3.new(4, 24, 260), CFrame.new(130, 12, 0), Color3.fromRGB(45, 47, 51), Enum.Material.Concrete)

	local coverData = {
		{Vector3.new(-60, 6, -55), Vector3.new(28, 12, 8)},
		{Vector3.new(55, 6, -60), Vector3.new(8, 12, 32)},
		{Vector3.new(-52, 6, 58), Vector3.new(8, 12, 30)},
		{Vector3.new(58, 6, 54), Vector3.new(30, 12, 8)},
		{Vector3.new(0, 5, 0), Vector3.new(34, 10, 12)},
		{Vector3.new(-88, 4, 0), Vector3.new(16, 8, 16)},
		{Vector3.new(88, 4, 0), Vector3.new(16, 8, 16)},
		{Vector3.new(0, 4, -88), Vector3.new(16, 8, 16)},
		{Vector3.new(0, 4, 88), Vector3.new(16, 8, 16)},
	}
	for index, data in ipairs(coverData) do
		part(model, string.format("Cover_%02d", index), data[2], CFrame.new(data[1]), Color3.fromRGB(86, 88, 92), Enum.Material.Metal)
	end

	part(model, "CenterDeck", Vector3.new(56, 2, 42), CFrame.new(0, 11, 0), Color3.fromRGB(74, 76, 80), Enum.Material.Metal)
	part(model, "RampWest", Vector3.new(42, 2, 14), CFrame.new(-38, 5, 0) * CFrame.Angles(0, 0, math.rad(-15)), Color3.fromRGB(72, 74, 78), Enum.Material.Metal)
	part(model, "RampEast", Vector3.new(42, 2, 14), CFrame.new(38, 5, 0) * CFrame.Angles(0, 0, math.rad(15)), Color3.fromRGB(72, 74, 78), Enum.Material.Metal)

	spawn(model, "Spawn_NW", Vector3.new(-104, 1.5, -104))
	spawn(model, "Spawn_NE", Vector3.new(104, 1.5, -104))
	spawn(model, "Spawn_SW", Vector3.new(-104, 1.5, 104))
	spawn(model, "Spawn_SE", Vector3.new(104, 1.5, 104))
	spawn(model, "Spawn_W", Vector3.new(-112, 1.5, 0))
	spawn(model, "Spawn_E", Vector3.new(112, 1.5, 0))

	print("[BankersPvPArenaBake] COMPLETE: temporary mechanics test arena created. Ctrl+S to save BankersPvP.rbxl.")
	return model
end

return BuildPvPTestArena

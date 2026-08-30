local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local ROOT_NAME = "TheTakeVaultScene"
local CONFIG_NAME = "TheTakeVaultCameraConfig"
local FOCUS_REMOTE_NAME = "TheTakeVaultStreamingFocus"
local ORIGIN = Vector3.new(5000, 260, 5000)

local ROOM_WIDTH = 112
local ROOM_DEPTH = 50
local ROOM_HEIGHT = 30

local COLORS = {
	floor = Color3.fromRGB(17, 28, 66),
	wall = Color3.fromRGB(57, 18, 57),
	wallAlt = Color3.fromRGB(24, 54, 82),
	bronze = Color3.fromRGB(171, 101, 44),
	gold = Color3.fromRGB(222, 164, 71),
	cyan = Color3.fromRGB(34, 180, 193),
	wine = Color3.fromRGB(122, 27, 62),
	panel = Color3.fromRGB(27, 38, 80),
}

for _, name in ipairs({ROOT_NAME, CONFIG_NAME, FOCUS_REMOTE_NAME}) do
	local parent = name == ROOT_NAME and Workspace or ReplicatedStorage
	local existing = parent:FindFirstChild(name)
	if existing then
		existing:Destroy()
	end
end

local scene = Instance.new("Model")
scene.Name = ROOT_NAME
scene:SetAttribute("DisplayOnly", true)
scene.Parent = Workspace

local architecture = Instance.new("Folder")
architecture.Name = "Architecture"
architecture.Parent = scene

local displayProps = Instance.new("Folder")
displayProps.Name = "DisplayProps"
displayProps.Parent = scene

for _, folderName in ipairs({"WeaponDisplays", "GearDisplays", "CashDisplays", "TechDisplays"}) do
	local folder = Instance.new("Folder")
	folder.Name = folderName
	folder.Parent = displayProps
end

local markers = Instance.new("Folder")
markers.Name = "Markers"
markers.Parent = scene

local function createPart(name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material, parent: Instance): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material
	part.Anchored = true
	part.CanCollide = true
	part.CanTouch = false
	part.CanQuery = true
	part.CastShadow = true
	part.Parent = parent
	return part
end

local function createMarker(name: string, cframe: CFrame): Part
	local marker = createPart(name, Vector3.new(1, 1, 1), cframe, COLORS.cyan, Enum.Material.SmoothPlastic, markers)
	marker.Transparency = 1
	marker.CanCollide = false
	marker.CanQuery = false
	marker.CastShadow = false
	return marker
end

local function sanitizeDisplay(instance: Instance)
	local all = {instance}
	for _, descendant in ipairs(instance:GetDescendants()) do
		table.insert(all, descendant)
	end
	for _, descendant in ipairs(all) do
		if descendant:IsA("Script") or descendant:IsA("LocalScript") then
			descendant.Enabled = false
		elseif descendant:IsA("Sound") then
			descendant.SoundId = ""
			descendant.Volume = 0
		elseif descendant:IsA("ProximityPrompt") then
			descendant.Enabled = false
		elseif descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
		end
	end
end

local function cloneVisual(source: Instance?, name: string, parent: Instance, target: CFrame, targetSize: number, rotation: CFrame?): Model?
	if not source then
		return nil
	end
	local wrapper = Instance.new("Model")
	wrapper.Name = name
	local clone = source:Clone()
	sanitizeDisplay(clone)
	clone.Parent = wrapper
	wrapper.Parent = parent

	local ok, _, size = pcall(function()
		return wrapper:GetBoundingBox()
	end)
	if not ok or not size then
		wrapper:Destroy()
		return nil
	end
	local maxDim = math.max(size.X, size.Y, size.Z)
	if maxDim > 0.01 then
		pcall(function()
			wrapper:ScaleTo(math.min(1, targetSize / maxDim))
		end)
	end
	wrapper:PivotTo(target * (rotation or CFrame.new()))
	return wrapper
end

local function findByName(root: Instance?, names: {string}): Instance?
	if not root then
		return nil
	end
	for _, name in ipairs(names) do
		local direct = root:FindFirstChild(name)
		if direct then
			return direct
		end
	end
	for _, descendant in ipairs(root:GetDescendants()) do
		for _, name in ipairs(names) do
			if descendant.Name == name then
				return descendant
			end
		end
	end
	return nil
end

local function findContaining(root: Instance?, token: string): Instance?
	if not root then
		return nil
	end
	local lowered = token:lower()
	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant.Name:lower():find(lowered, 1, true) then
			return descendant
		end
	end
	return nil
end

-- Full-color room shell.
createPart("Floor", Vector3.new(ROOM_WIDTH, 1, ROOM_DEPTH), CFrame.new(ORIGIN + Vector3.new(0, -0.5, 0)), COLORS.floor, Enum.Material.Slate, architecture)
createPart("BackWall", Vector3.new(ROOM_WIDTH, ROOM_HEIGHT, 1), CFrame.new(ORIGIN + Vector3.new(0, ROOM_HEIGHT / 2, ROOM_DEPTH / 2)), COLORS.wall, Enum.Material.Concrete, architecture)
createPart("LeftWall", Vector3.new(1, ROOM_HEIGHT, ROOM_DEPTH), CFrame.new(ORIGIN + Vector3.new(-ROOM_WIDTH / 2, ROOM_HEIGHT / 2, 0)), COLORS.wallAlt, Enum.Material.Metal, architecture)
createPart("RightWall", Vector3.new(1, ROOM_HEIGHT, ROOM_DEPTH), CFrame.new(ORIGIN + Vector3.new(ROOM_WIDTH / 2, ROOM_HEIGHT / 2, 0)), COLORS.wallAlt, Enum.Material.Metal, architecture)

local lightChannel = createPart("CyanLightChannel", Vector3.new(ROOM_WIDTH - 8, 0.2, 0.35), CFrame.new(ORIGIN + Vector3.new(0, ROOM_HEIGHT - 3, ROOM_DEPTH / 2 - 1)), COLORS.cyan, Enum.Material.Neon, architecture)
lightChannel.CanCollide = false
local floorChannel = createPart("GoldFloorChannel", Vector3.new(ROOM_WIDTH - 14, 0.12, 0.28), CFrame.new(ORIGIN + Vector3.new(0, 0.08, 13)), COLORS.gold, Enum.Material.Neon, architecture)
floorChannel.CanCollide = false

-- Player pedestal.
local pedestal = createPart("AvatarPedestal", Vector3.new(11, 0.8, 9), CFrame.new(ORIGIN + Vector3.new(0, 0.4, 0)), COLORS.wine, Enum.Material.DiamondPlate, architecture)
pedestal.CanCollide = false
createMarker("AvatarStand", CFrame.new(ORIGIN + Vector3.new(0, 1.1, 0)) * CFrame.Angles(0, math.rad(180), 0))

local heroMount = createPart("HeroLightMount", Vector3.new(1, 0.25, 1), CFrame.new(ORIGIN + Vector3.new(0, ROOM_HEIGHT - 2.2, 0)), COLORS.gold, Enum.Material.Neon, architecture)
heroMount.CanCollide = false
local spot = Instance.new("SpotLight")
spot.Angle = 58
spot.Brightness = 4.5
spot.Range = 38
spot.Face = Enum.NormalId.Bottom
spot.Color = Color3.fromRGB(255, 196, 110)
spot.Shadows = true
spot.Parent = heroMount

-- Compact weapon shelf: background dressing only, never store interaction.
local weaponFolder = displayProps.WeaponDisplays
local shelfCenter = ORIGIN + Vector3.new(28, 7.5, 21.7)
createPart("WeaponBackdrop", Vector3.new(39, 15, 0.5), CFrame.new(shelfCenter), COLORS.panel, Enum.Material.Metal, weaponFolder)
for y = -5, 5, 5 do
	local shelf = createPart("WeaponShelf", Vector3.new(36, 0.25, 2.2), CFrame.new(shelfCenter + Vector3.new(0, y, -1.2)), COLORS.bronze, Enum.Material.DiamondPlate, weaponFolder)
	shelf.CanCollide = false
end

local allWeapons = ServerStorage:FindFirstChild("AllWeapons")
local heroWeapons = {
	{"M4A1", Vector3.new(-12, 4.0, -1.8), 5.2},
	{"AK-47", Vector3.new(-4, 4.0, -1.8), 5.2},
	{"SPAS-12", Vector3.new(5, -1.0, -1.8), 5.5},
	{"Honey Badger", Vector3.new(13, -1.0, -1.8), 5.2},
}
for _, entry in ipairs(heroWeapons) do
	local source = allWeapons and allWeapons:FindFirstChild(entry[1])
	cloneVisual(source, "Display_" .. entry[1], weaponFolder, CFrame.new(shelfCenter + entry[2]), entry[3], CFrame.Angles(0, math.rad(90), math.rad(-4)))
end

-- Secondary weapon shelf.
local secondaryBase = ORIGIN + Vector3.new(28, 2.7, 21.0)
for index, name in ipairs({"Glock-17", "M9A3"}) do
	local source = allWeapons and allWeapons:FindFirstChild(name)
	cloneVisual(source, "Secondary_" .. name, weaponFolder, CFrame.new(secondaryBase + Vector3.new((index - 1.5) * 8, 0, 0)), 3.3, CFrame.Angles(0, math.rad(90), 0))
end

-- Tactical gear on stands.
local gearFolder = displayProps.GearDisplays
local allArmor = ServerStorage:FindFirstChild("AllArmor")
for index, lookup in ipairs({{"Vest"}, {"Bag"}, {"Hat"}}) do
	local x = -35 + (index - 1) * 9
	local stand = createPart("GearStand", Vector3.new(6.5, 0.5, 5), CFrame.new(ORIGIN + Vector3.new(x, 0.25, 16)), COLORS.bronze, Enum.Material.DiamondPlate, gearFolder)
	stand.CanCollide = false
	local source = findByName(allArmor, lookup)
	cloneVisual(source, "Gear_" .. lookup[1], gearFolder, CFrame.new(ORIGIN + Vector3.new(x, 4.5, 16)), 5.4, CFrame.Angles(0, math.rad(180), 0))
end

-- Donor cash/briefcase props.
local cashFolder = displayProps.CashDisplays
local syntySpy = ServerStorage:FindFirstChild("SyntySpy")
local cashTable = createPart("CashTable", Vector3.new(17, 2.4, 6), CFrame.new(ORIGIN + Vector3.new(-35, 1.2, -5)), COLORS.wine, Enum.Material.Metal, cashFolder)
local cashTop = createPart("CashTableTop", Vector3.new(17.4, 0.2, 6.4), CFrame.new(ORIGIN + Vector3.new(-35, 2.5, -5)), COLORS.bronze, Enum.Material.DiamondPlate, cashFolder)
cashTable.CanCollide = false
cashTop.CanCollide = false
cloneVisual(findContaining(syntySpy, "briefcase_cash"), "CashBriefcase", cashFolder, CFrame.new(ORIGIN + Vector3.new(-39, 4.0, -5)), 4.8, CFrame.Angles(0, math.rad(25), 0))
cloneVisual(findContaining(syntySpy, "prop_cash"), "CashStacks", cashFolder, CFrame.new(ORIGIN + Vector3.new(-31, 3.0, -5)), 3.7, CFrame.Angles(0, math.rad(-20), 0))

-- Donor monitor hardware built into two colored laptop stations.
local techFolder = displayProps.TechDisplays
local syntyScifi = ServerStorage:FindFirstChild("SyntyScifi")
local donorMonitor = findContaining(syntyScifi, "monitor_01") or findContaining(syntyScifi, "security_monitor")
for index = 1, 2 do
	local x = 27 + (index - 1) * 13
	local deskPos = ORIGIN + Vector3.new(x, 1.4, -7)
	local desk = createPart("LaptopDesk", Vector3.new(10, 2.8, 5), CFrame.new(deskPos), COLORS.panel, Enum.Material.Metal, techFolder)
	local base = createPart("LaptopBase", Vector3.new(6.5, 0.35, 4.3), CFrame.new(deskPos + Vector3.new(0, 1.6, 0)), index == 1 and COLORS.wine or COLORS.wallAlt, Enum.Material.Metal, techFolder)
	local keyboard = createPart("KeyboardGlow", Vector3.new(5.4, 0.08, 2.4), CFrame.new(deskPos + Vector3.new(0, 1.82, -0.45)), COLORS.cyan, Enum.Material.Neon, techFolder)
	desk.CanCollide = false
	base.CanCollide = false
	keyboard.CanCollide = false
	cloneVisual(donorMonitor, "DonorLaptopMonitor" .. index, techFolder, CFrame.new(deskPos + Vector3.new(0, 4.0, 1.1)) * CFrame.Angles(0, math.rad(180), 0), 4.5)
end

-- Vault door accent.
local door = createPart("VaultDoor", Vector3.new(0.8, 17, 17), CFrame.new(ORIGIN + Vector3.new(-ROOM_WIDTH / 2 + 0.7, 9.5, 7)), COLORS.wine, Enum.Material.Metal, architecture)
for angle = 0, 300, 60 do
	local spoke = createPart("VaultDoorSpoke", Vector3.new(0.45, 5.0, 0.45), CFrame.new(ORIGIN + Vector3.new(-ROOM_WIDTH / 2 + 1.1, 9.5, 7)) * CFrame.Angles(math.rad(angle), 0, 0), COLORS.gold, Enum.Material.Metal, architecture)
	spoke.CanCollide = false
end

local cameraStart = createMarker("VaultCameraStart", CFrame.lookAt(ORIGIN + Vector3.new(-5, 9.8, -21), ORIGIN + Vector3.new(7, 6.7, 7)))
local cameraEnd = createMarker("VaultCameraEnd", CFrame.lookAt(ORIGIN + Vector3.new(-8, 8.8, -16), ORIGIN + Vector3.new(7, 6.4, 7)))
local streamingFocus = createMarker("StreamingFocus", CFrame.new(ORIGIN + Vector3.new(0, 8, 8)))

local config = Instance.new("Folder")
config.Name = CONFIG_NAME
config:SetAttribute("Ready", false)
config.Parent = ReplicatedStorage

for name, value in pairs({Start = cameraStart.CFrame, End = cameraEnd.CFrame, AvatarStand = markers.AvatarStand.CFrame}) do
	local cframeValue = Instance.new("CFrameValue")
	cframeValue.Name = name
	cframeValue.Value = value
	cframeValue.Parent = config
end

local focusRemote = Instance.new("RemoteEvent")
focusRemote.Name = FOCUS_REMOTE_NAME
focusRemote.Parent = ReplicatedStorage
focusRemote.OnServerEvent:Connect(function(player: Player, enabled)
	if enabled == true then
		player.ReplicationFocus = streamingFocus
		print("[TheVault] streaming focus pinned for " .. player.Name)
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	player.ReplicationFocus = root and root:IsA("BasePart") and root or nil
	print("[TheVault] streaming focus released for " .. player.Name)
end)

Players.PlayerRemoving:Connect(function(player)
	if player.ReplicationFocus == streamingFocus then
		player.ReplicationFocus = nil
	end
end)

config:SetAttribute("Ready", true)
print("[TheVault] curated showroom ready | 4 primary weapons | 2 sidearms | tactical gear | cash | tech")

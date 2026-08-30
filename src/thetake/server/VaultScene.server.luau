local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local ROOT_NAME = "TheTakeVaultScene"
local CONFIG_NAME = "TheTakeVaultCameraConfig"
local ORIGIN = Vector3.new(5000, 260, 5000)

local ROOM_WIDTH = 132
local ROOM_DEPTH = 54
local ROOM_HEIGHT = 34
local DISPLAY_COLUMNS = 18
local DISPLAY_SPACING_X = 6.5
local DISPLAY_SPACING_Y = 5.0
local DISPLAY_TARGET_SIZE = 4.25

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

local oldScene = Workspace:FindFirstChild(ROOT_NAME)
if oldScene then
	oldScene:Destroy()
end

local oldConfig = ReplicatedStorage:FindFirstChild(CONFIG_NAME)
if oldConfig then
	oldConfig:Destroy()
end

local scene = Instance.new("Model")
scene.Name = ROOT_NAME
scene.Parent = Workspace
scene:SetAttribute("DisplayOnly", true)

local architecture = Instance.new("Folder")
architecture.Name = "Architecture"
architecture.Parent = scene

local displays = Instance.new("Folder")
displays.Name = "DonorEquipmentDisplays"
displays.Parent = scene

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

local function createSurfaceLabel(part: BasePart, text: string, face: Enum.NormalId, textColor: Color3)
	local surface = Instance.new("SurfaceGui")
	surface.Name = "Label"
	surface.Face = face
	surface.AlwaysOnTop = false
	surface.LightInfluence = 0.15
	surface.PixelsPerStud = 52
	surface.Parent = part

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.Text = text
	label.TextColor3 = textColor
	label.TextScaled = true
	label.TextWrapped = true
	label.Parent = surface
end

-- Room shell: deliberately colored, not grayscale.
createPart("Floor", Vector3.new(ROOM_WIDTH, 1, ROOM_DEPTH), CFrame.new(ORIGIN + Vector3.new(0, -0.5, 0)), COLORS.floor, Enum.Material.Slate, architecture)
createPart("BackWall", Vector3.new(ROOM_WIDTH, ROOM_HEIGHT, 1), CFrame.new(ORIGIN + Vector3.new(0, ROOM_HEIGHT / 2, ROOM_DEPTH / 2)), COLORS.wall, Enum.Material.Concrete, architecture)
createPart("LeftWall", Vector3.new(1, ROOM_HEIGHT, ROOM_DEPTH), CFrame.new(ORIGIN + Vector3.new(-ROOM_WIDTH / 2, ROOM_HEIGHT / 2, 0)), COLORS.wallAlt, Enum.Material.Metal, architecture)
createPart("RightWall", Vector3.new(1, ROOM_HEIGHT, ROOM_DEPTH), CFrame.new(ORIGIN + Vector3.new(ROOM_WIDTH / 2, ROOM_HEIGHT / 2, 0)), COLORS.wallAlt, Enum.Material.Metal, architecture)
createPart("CeilingBand", Vector3.new(ROOM_WIDTH, 1, 7), CFrame.new(ORIGIN + Vector3.new(0, ROOM_HEIGHT - 0.5, 18)), COLORS.wine, Enum.Material.Metal, architecture)

for x = -60, 60, 15 do
	createPart("BronzeRib", Vector3.new(0.55, ROOM_HEIGHT - 3, 0.7), CFrame.new(ORIGIN + Vector3.new(x, (ROOM_HEIGHT - 3) / 2, ROOM_DEPTH / 2 - 0.9)), COLORS.bronze, Enum.Material.Metal, architecture)
end

local cyanChannel = createPart("CyanLightChannel", Vector3.new(ROOM_WIDTH - 6, 0.22, 0.35), CFrame.new(ORIGIN + Vector3.new(0, ROOM_HEIGHT - 3.2, ROOM_DEPTH / 2 - 1.25)), COLORS.cyan, Enum.Material.Neon, architecture)
cyanChannel.CanCollide = false

local goldChannel = createPart("GoldFloorChannel", Vector3.new(ROOM_WIDTH - 12, 0.12, 0.3), CFrame.new(ORIGIN + Vector3.new(0, 0.08, 14)), COLORS.gold, Enum.Material.Neon, architecture)
goldChannel.CanCollide = false

local pedestalBase = createPart("AvatarPedestalBase", Vector3.new(12, 0.8, 10), CFrame.new(ORIGIN + Vector3.new(0, 0.4, 1)), COLORS.wine, Enum.Material.Metal, architecture)
local pedestalTop = createPart("AvatarPedestalTop", Vector3.new(9.5, 0.35, 8), CFrame.new(ORIGIN + Vector3.new(0, 0.98, 1)), COLORS.bronze, Enum.Material.DiamondPlate, architecture)
pedestalBase.CanCollide = false
pedestalTop.CanCollide = false
createMarker("AvatarStand", CFrame.new(ORIGIN + Vector3.new(0, 1.25, 1)) * CFrame.Angles(0, math.rad(180), 0))

local heroLightPart = createPart("HeroLightMount", Vector3.new(1, 0.25, 1), CFrame.new(ORIGIN + Vector3.new(0, ROOM_HEIGHT - 2.5, 1)), COLORS.gold, Enum.Material.Neon, architecture)
heroLightPart.CanCollide = false
local heroLight = Instance.new("SpotLight")
heroLight.Name = "HeroSpot"
heroLight.Angle = 58
heroLight.Brightness = 5
heroLight.Color = Color3.fromRGB(255, 196, 110)
heroLight.Range = 42
heroLight.Face = Enum.NormalId.Bottom
heroLight.Shadows = true
heroLight.Parent = heroLightPart

for _, side in ipairs({-1, 1}) do
	local x = side * 48
	createPart("PrepConsole", Vector3.new(18, 3.4, 5), CFrame.new(ORIGIN + Vector3.new(x, 1.7, -6)), side < 0 and COLORS.wine or COLORS.panel, Enum.Material.Metal, architecture)
	local top = createPart("PrepConsoleTop", Vector3.new(18.4, 0.25, 5.4), CFrame.new(ORIGIN + Vector3.new(x, 3.5, -6)), COLORS.bronze, Enum.Material.DiamondPlate, architecture)
	top.CanCollide = false
end

local door = createPart("VaultDoor", Vector3.new(0.8, 18, 18), CFrame.new(ORIGIN + Vector3.new(-ROOM_WIDTH / 2 + 0.7, 10, 9)), COLORS.wine, Enum.Material.Metal, architecture)
createSurfaceLabel(door, "THE VAULT", Enum.NormalId.Right, COLORS.gold)
for angle = 0, 300, 60 do
	local spoke = createPart("VaultDoorSpoke", Vector3.new(0.45, 5.5, 0.45), CFrame.new(ORIGIN + Vector3.new(-ROOM_WIDTH / 2 + 1.15, 10, 9)) * CFrame.Angles(math.rad(angle), 0, 0), COLORS.gold, Enum.Material.Metal, architecture)
	spoke.CanCollide = false
end

local cameraStart = createMarker("VaultCameraStart", CFrame.lookAt(ORIGIN + Vector3.new(0, 10.5, -23), ORIGIN + Vector3.new(0, 7.5, 5)))
local cameraEnd = createMarker("VaultCameraEnd", CFrame.lookAt(ORIGIN + Vector3.new(-8, 9.2, -17), ORIGIN + Vector3.new(3, 7.2, 5)))

local config = Instance.new("Folder")
config.Name = CONFIG_NAME
config:SetAttribute("Ready", false)
config.Parent = ReplicatedStorage

local startValue = Instance.new("CFrameValue")
startValue.Name = "Start"
startValue.Value = cameraStart.CFrame
startValue.Parent = config

local endValue = Instance.new("CFrameValue")
endValue.Name = "End"
endValue.Value = cameraEnd.CFrame
endValue.Parent = config

local standValue = Instance.new("CFrameValue")
standValue.Name = "AvatarStand"
standValue.Value = markers.AvatarStand.CFrame
standValue.Parent = config

local function hasVisual(instance: Instance): boolean
	return instance:IsA("BasePart") or instance:FindFirstChildWhichIsA("BasePart", true) ~= nil
end

local function sanitizeDisplayClone(instance: Instance)
	for _, descendant in ipairs(instance:GetDescendants()) do
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
	if instance:IsA("BasePart") then
		instance.Anchored = true
		instance.CanCollide = false
		instance.CanTouch = false
		instance.CanQuery = false
	end
end

local function collectTopLevel(folder: Instance?, category: string, destination: {any})
	if not folder then
		return
	end
	local children = folder:GetChildren()
	table.sort(children, function(a, b)
		return a.Name:lower() < b.Name:lower()
	end)
	for _, child in ipairs(children) do
		if hasVisual(child) then
			table.insert(destination, {
				source = child,
				category = category,
				name = child.Name,
			})
		end
	end
end

local equipment = {}
collectTopLevel(ServerStorage:FindFirstChild("AllWeapons"), "WEAPON", equipment)
collectTopLevel(ServerStorage:FindFirstChild("AllArmor"), "ARMOR", equipment)
collectTopLevel(ReplicatedStorage:FindFirstChild("Items"), "ITEM", equipment)

local function createDisplaySlot(index: number, record)
	local row = math.floor((index - 1) / DISPLAY_COLUMNS)
	local column = (index - 1) % DISPLAY_COLUMNS
	local x = (column - (DISPLAY_COLUMNS - 1) / 2) * DISPLAY_SPACING_X
	local y = 4.2 + row * DISPLAY_SPACING_Y
	local z = ROOM_DEPTH / 2 - 1.45

	local backColor = record.category == "WEAPON" and COLORS.panel or (record.category == "ARMOR" and COLORS.wine or COLORS.wallAlt)
	local back = createPart("DisplayBack", Vector3.new(5.8, 4.45, 0.32), CFrame.new(ORIGIN + Vector3.new(x, y, z)), backColor, Enum.Material.Metal, displays)
	back.CanCollide = false

	local shelf = createPart("DisplayShelf", Vector3.new(5.9, 0.18, 2.0), CFrame.new(ORIGIN + Vector3.new(x, y - 1.8, z - 0.85)), COLORS.bronze, Enum.Material.DiamondPlate, displays)
	shelf.CanCollide = false

	local labelBar = createPart("DisplayLabel", Vector3.new(5.7, 0.52, 0.16), CFrame.new(ORIGIN + Vector3.new(x, y - 1.45, z - 0.26)), COLORS.wine, Enum.Material.SmoothPlastic, displays)
	labelBar.CanCollide = false
	createSurfaceLabel(labelBar, record.name, Enum.NormalId.Front, COLORS.gold)

	local wrapper = Instance.new("Model")
	wrapper.Name = string.format("%03d_%s_%s", index, record.category, record.name)

	local clone = record.source:Clone()
	sanitizeDisplayClone(clone)
	clone.Parent = wrapper

	if not hasVisual(wrapper) then
		wrapper:Destroy()
		return false
	end

	local okBounds, _, size = pcall(function()
		return wrapper:GetBoundingBox()
	end)
	if not okBounds or not size then
		wrapper:Destroy()
		return false
	end

	local maxDim = math.max(size.X, size.Y, size.Z)
	if maxDim > 0.01 then
		pcall(function()
			wrapper:ScaleTo(math.min(1, DISPLAY_TARGET_SIZE / maxDim))
		end)
	end

	wrapper.Parent = displays
	wrapper:PivotTo(CFrame.new(ORIGIN + Vector3.new(x, y - 0.1, z - 1.1)) * CFrame.Angles(0, math.rad(90), math.rad(-5)))
	return true
end

local displayed = 0
for index, record in ipairs(equipment) do
	if createDisplaySlot(index, record) then
		displayed += 1
	end
end

local rows = math.max(1, math.ceil(#equipment / DISPLAY_COLUMNS))
local requiredHeight = 7 + rows * DISPLAY_SPACING_Y
if requiredHeight > ROOM_HEIGHT then
	warn(string.format("[TheVault] donor collection uses %d display rows; some upper racks may sit above the initial wall shell", rows))
end

config:SetAttribute("Ready", true)
scene:SetAttribute("EquipmentCount", #equipment)
scene:SetAttribute("DisplayedCount", displayed)

print(string.format(
	"[TheVault] full-color showroom ready | donor equipment=%d | displayed=%d | weapons=%s | armor=%s | items=%s",
	#equipment,
	displayed,
	tostring(ServerStorage:FindFirstChild("AllWeapons") ~= nil),
	tostring(ServerStorage:FindFirstChild("AllArmor") ~= nil),
	tostring(ReplicatedStorage:FindFirstChild("Items") ~= nil)
))

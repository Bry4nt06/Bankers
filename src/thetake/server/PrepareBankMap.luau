local PrepareBankMap = {}

local DEFAULT_MAP_NAME = "TheTakeBankMap"

local STRUCTURE = {
	"Environment",
	"Bank",
	"Streets",
	"Props",
	"GameplayMarkers",
}

local BANK_STRUCTURE = {
	"Exterior",
	"Lobby",
	"TellerArea",
	"Offices",
	"SecurityRoom",
	"VaultApproach",
	"Vault",
	"LootRoom",
}

local MARKER_NAMES = {
	"CrewSpawn",
	"FrontEntry",
	"SideEntry",
	"RearEntry",
	"VaultBreach",
	"LootZone",
	"EscapeRoute",
	"Extraction",
}

local function resolveModel(modelOrName: any?): Model
	if typeof(modelOrName) == "Instance" then
		if modelOrName:IsA("Model") then
			return modelOrName
		end
		error("[TheTakeBankPrep] supplied Instance must be a Model")
	end

	local name = type(modelOrName) == "string" and modelOrName or DEFAULT_MAP_NAME
	local candidate = workspace:FindFirstChild(name)
	if candidate and candidate:IsA("Model") then
		return candidate
	end

	error(string.format(
		"[TheTakeBankPrep] Workspace.%s was not found. Clone the donor city into Workspace first.",
		name
	))
end

local function shouldStrip(instance: Instance): boolean
	return instance:IsA("Script")
		or instance:IsA("LocalScript")
		or instance:IsA("ModuleScript")
		or instance:IsA("RemoteEvent")
		or instance:IsA("RemoteFunction")
		or instance:IsA("BindableEvent")
		or instance:IsA("BindableFunction")
		or instance:IsA("Seat")
		or instance:IsA("VehicleSeat")
		or instance:IsA("Sound")
		or instance:IsA("BodyMover")
		or instance:IsA("Constraint")
		or instance:IsA("JointInstance")
		or instance:IsA("ClickDetector")
		or instance:IsA("ProximityPrompt")
		or instance:IsA("Humanoid")
		or instance:IsA("Animator")
		or instance:IsA("Tool")
		or instance:IsA("Camera")
		or instance:IsA("SpawnLocation")
end

local function sanitize(root: Model): (number, number)
	local removed = 0
	local anchoredParts = 0

	-- Snapshot first because Destroy() mutates the descendant list.
	local descendants = root:GetDescendants()
	for index = #descendants, 1, -1 do
		local descendant = descendants[index]
		if descendant.Parent == nil then
			continue
		end

		if shouldStrip(descendant) then
			descendant:Destroy()
			removed += 1
		elseif descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.AssemblyLinearVelocity = Vector3.zero
			descendant.AssemblyAngularVelocity = Vector3.zero
			anchoredParts += 1
		end
	end

	return removed, anchoredParts
end

local function ensureFolder(parent: Instance, name: string): Folder
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA("Folder") then
		return existing
	end
	if existing then
		existing:Destroy()
	end

	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

local function createStructure(root: Model)
	local environment = ensureFolder(root, "Environment")
	local bank = ensureFolder(root, "Bank")
	local streets = ensureFolder(root, "Streets")
	local props = ensureFolder(root, "Props")
	local markers = ensureFolder(root, "GameplayMarkers")

	for _, name in ipairs(BANK_STRUCTURE) do
		ensureFolder(bank, name)
	end

	for _, name in ipairs(MARKER_NAMES) do
		local marker = markers:FindFirstChild(name)
		if not marker then
			marker = Instance.new("Folder")
			marker.Name = name
			marker:SetAttribute("NeedsPlacement", true)
			marker.Parent = markers
		end
	end

	-- On the first preparation pass, move the untouched donor hierarchy under
	-- Environment so THE TAKE-authored bank/gameplay folders stay separate.
	for _, child in ipairs(root:GetChildren()) do
		if child ~= environment
			and child ~= bank
			and child ~= streets
			and child ~= props
			and child ~= markers then
			child.Parent = environment
		end
	end
end

function PrepareBankMap.Run(modelOrName: any?)
	local map = resolveModel(modelOrName)

	if map:GetAttribute("TheTakeBankMapPrepared") == true then
		createStructure(map)
		print("[TheTakeBankPrep] map already prepared; hierarchy verified")
		return map
	end

	local removed, parts = sanitize(map)
	if parts == 0 then
		error("[TheTakeBankPrep] selected map contains no usable BaseParts")
	end

	createStructure(map)

	map.Name = DEFAULT_MAP_NAME
	map:SetAttribute("TheTakeBankMapPrepared", true)
	map:SetAttribute("Sanitized", true)
	map:SetAttribute("RemovedDonorObjects", removed)
	map:SetAttribute("EnvironmentPartCount", parts)
	map:SetAttribute("HeistMapVersion", 1)

	local _, size = map:GetBoundingBox()
	print(string.format(
		"[TheTakeBankPrep] COMPLETE | %d static parts | %d donor gameplay/audio/physics objects stripped | footprint %.0f x %.0f studs",
		parts,
		removed,
		size.X,
		size.Z
	))
	print("[TheTakeBankPrep] Next: Ctrl+S, then send a top-down screenshot so the bank building and heist route can be selected.")

	return map
end

return PrepareBankMap

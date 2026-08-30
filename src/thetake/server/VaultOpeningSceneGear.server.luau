local ServerStorage = game:GetService("ServerStorage")

local catalogRoot = ServerStorage:WaitForChild("TheTakeVaultCatalog")
local gearFolder = catalogRoot:WaitForChild("Gear")

-- THE TAKE already has a stronger visual language in its opening-menu characters
-- than several of the generic Creator Store free-model fallbacks. These records
-- expose the exact menu accessories in THE VAULT so store gear and menu art match.
local OPENING_SCENE_GEAR = {
	{
		sourceName = "Accessory (Black Balaclava Goggles)",
		itemId = "gear-opening-balaclava-goggles",
		displayName = "Black Balaclava Goggles",
		gearSlot = "FaceMask",
		price = 950,
	},
	{
		sourceName = "balaclavaClassicBody",
		itemId = "gear-opening-classic-balaclava",
		displayName = "Classic Black Balaclava",
		gearSlot = "FaceMask",
		price = 800,
	},
	{
		sourceName = "B_SkiMask_1H",
		itemId = "gear-opening-ski-mask",
		displayName = "Black Ski Mask",
		gearSlot = "FaceMask",
		price = 850,
	},
	{
		sourceName = "HexagonalPlateCarrier",
		itemId = "gear-opening-hex-carrier",
		displayName = "Hexagonal Plate Carrier",
		gearSlot = "Vest",
		price = 1750,
	},
	{
		sourceName = "Vest 2",
		itemId = "gear-opening-tactical-vest",
		displayName = "Black Tactical Vest",
		gearSlot = "Vest",
		price = 1450,
	},
	{
		sourceName = "Black Vest",
		itemId = "gear-opening-black-vest",
		displayName = "Black Armor Vest",
		gearSlot = "Vest",
		price = 1350,
	},
	{
		sourceName = "Black Military Duffel Bag",
		itemId = "gear-opening-military-duffel",
		displayName = "Black Military Duffel",
		gearSlot = "Back",
		price = 1200,
	},
}

local RETIRED_ITEM_IDS = {
	["gear-ir-helmet"] = true,
	["gear-helmet-model"] = true,
	["gear-backpack"] = true,
}

local function lower(value): string
	return string.lower(tostring(value or ""))
end

local function removeRetiredGear(): number
	local removed = 0
	for _, item in ipairs(gearFolder:GetChildren()) do
		local itemId = tostring(item:GetAttribute("VaultItemId") or "")
		local displayName = lower(item:GetAttribute("VaultDisplayName") or item.Name)
		local sourceName = lower(item:GetAttribute("CreatorStoreSourceName") or "")
		local oldBackpack = displayName:find("tactical backpack", 1, true) ~= nil
			or sourceName:find("tactical backpack", 1, true) ~= nil
		if RETIRED_ITEM_IDS[itemId] or oldBackpack then
			item:Destroy()
			removed += 1
		end
	end
	return removed
end

local function ancestorHasHumanoid(instance: Instance, stopAt: Instance): boolean
	local current = instance.Parent
	while current and current ~= stopAt do
		if current:IsA("Model") and current:FindFirstChildOfClass("Humanoid") then
			return true
		end
		current = current.Parent
	end
	return false
end

local function findOpeningAccessory(scene: Instance, sourceName: string): Accessory?
	local fallback = nil
	for _, descendant in ipairs(scene:GetDescendants()) do
		if descendant:IsA("Accessory") and descendant.Name == sourceName then
			if ancestorHasHumanoid(descendant, scene) then
				return descendant
			end
			fallback = fallback or descendant
		end
	end
	return fallback
end

local function sanitizeAccessory(accessory: Accessory)
	for _, descendant in ipairs(accessory:GetDescendants()) do
		if descendant:IsA("Script") or descendant:IsA("LocalScript") or descendant:IsA("ModuleScript") then
			descendant:Destroy()
		elseif descendant:IsA("RemoteEvent") or descendant:IsA("RemoteFunction")
			or descendant:IsA("BindableEvent") or descendant:IsA("BindableFunction")
			or descendant:IsA("Sound") or descendant:IsA("ClickDetector")
			or descendant:IsA("ProximityPrompt") then
			descendant:Destroy()
		elseif descendant:IsA("BasePart") then
			descendant.Anchored = false
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
			descendant.Massless = true
		end
	end
end

local function findByItemId(itemId: string): Instance?
	for _, item in ipairs(gearFolder:GetChildren()) do
		if item:GetAttribute("VaultItemId") == itemId then
			return item
		end
	end
	return nil
end

local function seedRecord(scene: Instance, record): boolean
	local source = findOpeningAccessory(scene, record.sourceName)
	if not source then
		warn(string.format("[VaultOpeningGear] opening accessory not found: %s", record.sourceName))
		return false
	end

	local existing = findByItemId(record.itemId)
	if existing then
		existing:Destroy()
	end

	local clone = source:Clone()
	clone.Name = record.displayName
	sanitizeAccessory(clone)
	clone:SetAttribute("VaultItemId", record.itemId)
	clone:SetAttribute("VaultDisplayName", record.displayName)
	clone:SetAttribute("VaultPrice", record.price)
	clone:SetAttribute("VaultCurrency", "Cash")
	clone:SetAttribute("VaultEnabled", true)
	clone:SetAttribute("VaultWearable", true)
	clone:SetAttribute("GearType", "OpeningSceneAccessory")
	clone:SetAttribute("GearSlot", record.gearSlot)
	clone:SetAttribute("FitStatus", "Native")
	clone:SetAttribute("OpeningSceneImported", true)
	clone:SetAttribute("OpeningSceneSourceName", record.sourceName)
	clone.Parent = gearFolder
	return true
end

local removed = removeRetiredGear()

local scene = workspace:FindFirstChild("TheTakeMenuScene")
local deadline = os.clock() + 20
while not scene and os.clock() < deadline do
	task.wait(0.1)
	scene = workspace:FindFirstChild("TheTakeMenuScene")
end

if not scene then
	warn(string.format("[VaultOpeningGear] menu scene unavailable; retired=%d, seeded=0", removed))
	return
end

local seeded = 0
local missing = 0
for _, record in ipairs(OPENING_SCENE_GEAR) do
	if seedRecord(scene, record) then
		seeded += 1
	else
		missing += 1
	end
end

print(string.format(
	"[VaultOpeningGear] curated opening gear ready | retired=%d | seeded=%d | missing=%d",
	removed,
	seeded,
	missing
))

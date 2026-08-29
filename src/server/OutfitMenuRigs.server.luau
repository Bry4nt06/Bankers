local InsertService = game:GetService("InsertService")

local LoadoutConfig = require(script.Parent:WaitForChild("RobberLoadouts"))

local ATTRIBUTE_NAME = LoadoutConfig.AttributeName or "BankersLoadout"
local LOADOUTS = LoadoutConfig.Loadouts or {}

local DESCRIPTION_FIELDS = {
	"Shirt",
	"Pants",
	"GraphicTShirt",
	"HatAccessory",
	"HairAccessory",
	"FaceAccessory",
	"NeckAccessory",
	"FrontAccessory",
	"BackAccessory",
	"WaistAccessory",
	"ShouldersAccessory",
	"JacketAccessory",
	"SweaterAccessory",
	"ShirtAccessory",
	"PantsAccessory",
	"ShortsAccessory",
	"LeftShoeAccessory",
	"RightShoeAccessory",
	"DressSkirtAccessory",
}

local ACCESSORY_SLOT_ORDER = {
	"Mask",
	"Headgear",
	"PlateCarrier",
	"Gloves",
	"Radio",
	"KneePads",
	"Bag",
}

local function isMeaningfulValue(value)
	if type(value) == "number" then
		return value > 0
	end
	if type(value) == "string" then
		return value ~= "" and value ~= "0"
	end
	return false
end

local function getRigPosition(rig: Model): Vector3
	local ok, pivot = pcall(function()
		return rig:GetPivot()
	end)
	if ok then
		return pivot.Position
	end

	local root = rig:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root.Position
	end

	return Vector3.zero
end

local function getSortedMenuRigs(): {Model}
	local rigs = {}
	for _, child in workspace:GetChildren() do
		if child:IsA("Model") and child.Name == "Rig" and child:FindFirstChildOfClass("Humanoid") then
			table.insert(rigs, child)
		end
	end

	table.sort(rigs, function(a, b)
		local ap = getRigPosition(a)
		local bp = getRigPosition(b)
		if math.abs(ap.X - bp.X) > 0.01 then
			return ap.X < bp.X
		end
		if math.abs(ap.Z - bp.Z) > 0.01 then
			return ap.Z < bp.Z
		end
		return ap.Y < bp.Y
	end)

	return rigs
end

local function findLoadoutByName(name: string)
	local lowerName = string.lower(name)
	for _, loadout in LOADOUTS do
		if string.lower(loadout.Name or "") == lowerName then
			return loadout
		end
	end
	return nil
end

local function resolveLoadout(rig: Model, slotIndex: number)
	local override = rig:GetAttribute(ATTRIBUTE_NAME)
	if type(override) == "string" and override ~= "" then
		local byName = findLoadoutByName(override)
		if byName then
			return byName
		end
		warn(string.format("[BankersOutfits] unknown %s '%s' on %s; using slot %d", ATTRIBUTE_NAME, override, rig:GetFullName(), slotIndex))
	elseif type(override) == "number" and LOADOUTS[override] then
		return LOADOUTS[override]
	end

	if #LOADOUTS == 0 then
		return nil
	end
	return LOADOUTS[((slotIndex - 1) % #LOADOUTS) + 1]
end

local function removeRuntimeGear(rig: Model)
	for _, descendant in rig:GetDescendants() do
		if descendant:IsA("Accessory") and descendant:GetAttribute("BankersRuntimeGear") == true then
			descendant:Destroy()
		end
	end
end

local function applyDescription(humanoid: Humanoid, loadout)
	local ok, description = pcall(function()
		return humanoid:GetAppliedDescription()
	end)
	if not ok or not description then
		warn("[BankersOutfits] could not read applied HumanoidDescription; skipping description gear")
		return
	end

	local configured = loadout.Description or {}
	for _, propertyName in DESCRIPTION_FIELDS do
		local value = configured[propertyName]
		if isMeaningfulValue(value) then
			local setOk, setErr = pcall(function()
				description[propertyName] = value
			end)
			if not setOk then
				warn(string.format("[BankersOutfits] unable to set HumanoidDescription.%s: %s", propertyName, tostring(setErr)))
			end
		end
	end

	local applyOk, applyErr = pcall(function()
		humanoid:ApplyDescription(description)
	end)
	if not applyOk then
		warn(string.format("[BankersOutfits] ApplyDescription failed: %s", tostring(applyErr)))
	end
end

local function addAccessoryAsset(humanoid: Humanoid, rig: Model, slotName: string, assetId: number)
	if type(assetId) ~= "number" or assetId <= 0 then
		return 0
	end

	local ok, containerOrError = pcall(function()
		return InsertService:LoadAsset(assetId)
	end)
	if not ok then
		warn(string.format("[BankersOutfits] %s asset %d failed to load: %s", slotName, assetId, tostring(containerOrError)))
		return 0
	end

	local container = containerOrError
	local accessories = {}
	if container:IsA("Accessory") then
		table.insert(accessories, container)
	else
		for _, descendant in container:GetDescendants() do
			if descendant:IsA("Accessory") then
				table.insert(accessories, descendant)
			end
		end
	end

	if #accessories == 0 then
		warn(string.format("[BankersOutfits] %s asset %d did not contain an Accessory", slotName, assetId))
		container:Destroy()
		return 0
	end

	local added = 0
	for _, accessory in accessories do
		accessory:SetAttribute("BankersRuntimeGear", true)
		accessory:SetAttribute("BankersGearSlot", slotName)
		accessory:SetAttribute("BankersGearAssetId", assetId)
		accessory.Parent = rig
		local addOk, addErr = pcall(function()
			humanoid:AddAccessory(accessory)
		end)
		if addOk then
			added += 1
		else
			warn(string.format("[BankersOutfits] could not attach %s asset %d: %s", slotName, assetId, tostring(addErr)))
			accessory:Destroy()
		end
	end

	if container.Parent then
		container:Destroy()
	end

	return added
end

local function freezeRig(rig: Model)
	local humanoid = rig:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.AutoRotate = false
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end

	for _, descendant in rig:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.AssemblyLinearVelocity = Vector3.zero
			descendant.AssemblyAngularVelocity = Vector3.zero
		end
	end
end

local function applyLoadout(rig: Model, slotIndex: number)
	local humanoid = rig:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local loadout = resolveLoadout(rig, slotIndex)
	if not loadout then
		warn("[BankersOutfits] no loadouts configured")
		return
	end

	rig:SetAttribute("BankersAppliedLoadout", loadout.Name or tostring(slotIndex))

	if humanoid.RigType ~= Enum.HumanoidRigType.R15 then
		warn(string.format("[BankersOutfits] %s is %s; high-detail layered tactical gear works best on R15", rig:GetFullName(), humanoid.RigType.Name))
	end

	removeRuntimeGear(rig)
	applyDescription(humanoid, loadout)

	local accessoryCount = 0
	local gear = loadout.AccessoryAssets or {}
	for _, slotName in ACCESSORY_SLOT_ORDER do
		local assetId = gear[slotName]
		if type(assetId) == "number" and assetId > 0 then
			accessoryCount += addAccessoryAsset(humanoid, rig, slotName, assetId)
		end
	end

	freezeRig(rig)
	print(string.format(
		"[BankersOutfits] slot %d -> %s (%s), %d runtime accessories",
		slotIndex,
		rig:GetFullName(),
		loadout.DisplayName or loadout.Name or "Unnamed",
		accessoryCount
	))
end

local function outfitAllMenuRigs()
	local rigs = getSortedMenuRigs()
	if #rigs == 0 then
		warn("[BankersOutfits] no Workspace Rig models with Humanoids found")
		return
	end

	for index, rig in rigs do
		applyLoadout(rig, index)
	end

	print(string.format("[BankersOutfits] tactical menu loadout system ready for %d rigs", #rigs))
end

-- Give Studio-authored rigs a moment to settle before applying descriptions.
task.wait(0.35)
outfitAllMenuRigs()

-- Re-run once after startup in case a character description or accessory was late to replicate.
task.delay(2, outfitAllMenuRigs)

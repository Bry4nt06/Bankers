local AvatarEditorService = game:GetService("AvatarEditorService")
local InsertService = game:GetService("InsertService")
local MarketplaceService = game:GetService("MarketplaceService")

local LoadoutConfig = require(script.Parent:WaitForChild("RobberLoadouts"))

local ATTRIBUTE_NAME = LoadoutConfig.AttributeName or "BankersLoadout"
local LOADOUTS = LoadoutConfig.Loadouts or {}
local DEFAULT_BASE_COLOR = LoadoutConfig.DefaultBaseColor or Color3.fromRGB(31, 32, 35)

local DESCRIPTION_FIELDS = {
	"Shirt",
	"Pants",
	"GraphicTShirt",
}

local avatarAssetTypeByValue = {}
for _, item in Enum.AvatarAssetType:GetEnumItems() do
	avatarAssetTypeByValue[item.Value] = item
end

local catalogResolutionCache = {}

local function getRigPosition(rig: Model): Vector3
	local ok, pivot = pcall(function()
		return rig:GetPivot()
	end)
	if ok then
		return pivot.Position
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
	elseif type(override) == "number" and LOADOUTS[override] then
		return LOADOUTS[override]
	end

	if #LOADOUTS == 0 then
		return nil
	end
	return LOADOUTS[((slotIndex - 1) % #LOADOUTS) + 1]
end

local function resolveCatalogAccessory(assetId: number)
	local cached = catalogResolutionCache[assetId]
	if cached ~= nil then
		return cached ~= false and cached or nil
	end

	local ok, infoOrError = pcall(function()
		return MarketplaceService:GetProductInfo(assetId, Enum.InfoType.Asset)
	end)
	if not ok then
		warn(string.format("[BankersOutfits] catalog asset %d metadata lookup failed: %s", assetId, tostring(infoOrError)))
		catalogResolutionCache[assetId] = false
		return nil
	end

	local info = infoOrError
	local avatarAssetType = avatarAssetTypeByValue[info.AssetTypeId]
	if not avatarAssetType then
		warn(string.format("[BankersOutfits] catalog asset %d (%s) has unsupported AssetTypeId %s", assetId, tostring(info.Name), tostring(info.AssetTypeId)))
		catalogResolutionCache[assetId] = false
		return nil
	end

	local accessoryType = AvatarEditorService:GetAccessoryType(avatarAssetType)
	if accessoryType == Enum.AccessoryType.Unknown then
		warn(string.format("[BankersOutfits] catalog asset %d (%s) is %s, not an avatar accessory", assetId, tostring(info.Name), avatarAssetType.Name))
		catalogResolutionCache[assetId] = false
		return nil
	end

	local resolved = {
		AssetId = assetId,
		AccessoryType = accessoryType,
		Name = info.Name or tostring(assetId),
		AvatarAssetType = avatarAssetType,
	}
	catalogResolutionCache[assetId] = resolved
	return resolved
end

local function buildCatalogAccessorySpecs(loadout)
	local specs = {}
	local resolvedCount = 0
	for order, assetId in loadout.CatalogAccessories or {} do
		if type(assetId) == "number" and assetId > 0 then
			local resolved = resolveCatalogAccessory(assetId)
			if resolved then
				table.insert(specs, {
					Order = order,
					AssetId = assetId,
					AccessoryType = resolved.AccessoryType,
				})
				resolvedCount += 1
				print(string.format(
					"[BankersOutfits] catalog %d -> %s (%s / %s)",
					assetId,
					resolved.Name,
					resolved.AvatarAssetType.Name,
					resolved.AccessoryType.Name
				))
			end
		end
	end
	return specs, resolvedCount
end

local function applyBaseColor(description: HumanoidDescription)
	description.HeadColor = DEFAULT_BASE_COLOR
	description.LeftArmColor = DEFAULT_BASE_COLOR
	description.RightArmColor = DEFAULT_BASE_COLOR
	description.LeftLegColor = DEFAULT_BASE_COLOR
	description.RightLegColor = DEFAULT_BASE_COLOR
	description.TorsoColor = DEFAULT_BASE_COLOR
end

local function applyDescription(humanoid: Humanoid, loadout)
	local ok, description = pcall(function()
		return humanoid:GetAppliedDescription()
	end)
	if not ok or not description then
		warn("[BankersOutfits] could not read applied HumanoidDescription")
		return false, 0
	end

	applyBaseColor(description)

	for _, propertyName in DESCRIPTION_FIELDS do
		local value = (loadout.Description or {})[propertyName]
		if type(value) == "number" and value > 0 then
			description[propertyName] = value
		end
	end

	local accessorySpecs, resolvedCount = buildCatalogAccessorySpecs(loadout)
	local setOk, setErr = pcall(function()
		description:SetAccessories(accessorySpecs, true)
	end)
	if not setOk then
		warn(string.format("[BankersOutfits] SetAccessories failed: %s", tostring(setErr)))
		return false, 0
	end

	local applyOk, applyErr = pcall(function()
		humanoid:ApplyDescription(description)
	end)
	if not applyOk then
		warn(string.format("[BankersOutfits] ApplyDescription failed: %s", tostring(applyErr)))
		return false, 0
	end

	return true, resolvedCount
end

local function addGameOwnedAccessory(humanoid: Humanoid, rig: Model, assetId: number)
	local ok, containerOrError = pcall(function()
		return InsertService:LoadAsset(assetId)
	end)
	if not ok then
		warn(string.format("[BankersOutfits] custom accessory %d failed to load: %s", assetId, tostring(containerOrError)))
		return 0
	end

	local container = containerOrError
	local accessory = container:IsA("Accessory") and container or container:FindFirstChildWhichIsA("Accessory", true)
	if not accessory then
		container:Destroy()
		return 0
	end

	accessory:SetAttribute("BankersRuntimeGear", true)
	accessory.Parent = rig
	local addOk = pcall(function()
		humanoid:AddAccessory(accessory)
	end)

	if container ~= accessory then
		container:Destroy()
	end
	return addOk and 1 or 0
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
	print(string.format("[BankersOutfits] %s rig type: %s", rig:GetFullName(), humanoid.RigType.Name))

	local descriptionApplied, catalogCount = applyDescription(humanoid, loadout)
	local customCount = 0
	for _, assetId in loadout.AccessoryAssets or {} do
		if type(assetId) == "number" and assetId > 0 then
			customCount += addGameOwnedAccessory(humanoid, rig, assetId)
		end
	end

	freezeRig(rig)
	print(string.format(
		"[BankersOutfits] slot %d -> %s (%s), description=%s, catalog accessories=%d, custom accessories=%d",
		slotIndex,
		rig:GetFullName(),
		loadout.DisplayName or loadout.Name or "Unnamed",
		tostring(descriptionApplied),
		catalogCount,
		customCount
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

task.wait(0.35)
outfitAllMenuRigs()

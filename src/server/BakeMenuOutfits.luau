local AvatarEditorService = game:GetService("AvatarEditorService")
local MarketplaceService = game:GetService("MarketplaceService")

local LoadoutConfig = require(script.Parent:WaitForChild("RobberLoadouts"))

local BakeMenuOutfits = {}

local ATTRIBUTE_NAME = LoadoutConfig.AttributeName or "BankersLoadout"
local LOADOUTS = LoadoutConfig.Loadouts or {}
local DEFAULT_BASE_COLOR = LoadoutConfig.DefaultBaseColor or Color3.fromRGB(31, 32, 35)

local avatarAssetTypeByValue = {}
for _, item in Enum.AvatarAssetType:GetEnumItems() do
	avatarAssetTypeByValue[item.Value] = item
end

local catalogResolutionCache = {}

local function getRigPosition(rig: Model): Vector3
	local ok, pivot = pcall(function()
		return rig:GetPivot()
	end)
	return ok and pivot.Position or Vector3.zero
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
		warn(string.format("[BankersBake] catalog asset %d metadata lookup failed: %s", assetId, tostring(infoOrError)))
		catalogResolutionCache[assetId] = false
		return nil
	end

	local info = infoOrError
	local avatarAssetType = avatarAssetTypeByValue[info.AssetTypeId]
	if not avatarAssetType then
		warn(string.format("[BankersBake] catalog asset %d (%s) has unsupported AssetTypeId %s", assetId, tostring(info.Name), tostring(info.AssetTypeId)))
		catalogResolutionCache[assetId] = false
		return nil
	end

	local okType, accessoryTypeOrError = pcall(function()
		return AvatarEditorService:GetAccessoryType(avatarAssetType)
	end)
	if not okType or accessoryTypeOrError == Enum.AccessoryType.Unknown then
		warn(string.format("[BankersBake] catalog asset %d (%s) is not a supported wearable accessory", assetId, tostring(info.Name)))
		catalogResolutionCache[assetId] = false
		return nil
	end

	local resolved = {
		AssetId = assetId,
		AccessoryType = accessoryTypeOrError,
		Name = info.Name or tostring(assetId),
		AvatarAssetType = avatarAssetType,
	}
	catalogResolutionCache[assetId] = resolved
	return resolved
end

local function buildAccessorySpecs(loadout)
	local specs = {}
	local count = 0
	for order, assetId in loadout.CatalogAccessories or {} do
		if type(assetId) == "number" and assetId > 0 then
			local resolved = resolveCatalogAccessory(assetId)
			if resolved then
				table.insert(specs, {
					Order = order,
					AssetId = assetId,
					AccessoryType = resolved.AccessoryType,
				})
				count += 1
				print(string.format("[BankersBake] %d -> %s (%s)", assetId, resolved.Name, resolved.AccessoryType.Name))
			end
		end
	end
	return specs, count
end

local function applyLoadout(rig: Model, slotIndex: number): boolean
	local humanoid = rig:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return false
	end

	local loadout = resolveLoadout(rig, slotIndex)
	if not loadout then
		warn("[BankersBake] no loadout configured for " .. rig:GetFullName())
		return false
	end

	print(string.format("[BankersBake] baking slot %d (%s) onto %s [%s]", slotIndex, loadout.DisplayName or loadout.Name or "Unnamed", rig:GetFullName(), humanoid.RigType.Name))

	local ok, descriptionOrError = pcall(function()
		return humanoid:GetAppliedDescription()
	end)
	if not ok then
		warn("[BankersBake] GetAppliedDescription failed: " .. tostring(descriptionOrError))
		return false
	end

	local description = descriptionOrError
	description.HeadColor = DEFAULT_BASE_COLOR
	description.LeftArmColor = DEFAULT_BASE_COLOR
	description.RightArmColor = DEFAULT_BASE_COLOR
	description.LeftLegColor = DEFAULT_BASE_COLOR
	description.RightLegColor = DEFAULT_BASE_COLOR
	description.TorsoColor = DEFAULT_BASE_COLOR

	local configured = loadout.Description or {}
	for _, propertyName in ipairs({"Shirt", "Pants", "GraphicTShirt"}) do
		local value = configured[propertyName]
		if type(value) == "number" and value > 0 then
			description[propertyName] = value
		end
	end

	local specs, accessoryCount = buildAccessorySpecs(loadout)
	local setOk, setErr = pcall(function()
		description:SetAccessories(specs, true)
	end)
	if not setOk then
		warn("[BankersBake] SetAccessories failed: " .. tostring(setErr))
		return false
	end

	local applyOk, applyErr = pcall(function()
		humanoid:ApplyDescription(description)
	end)
	if not applyOk then
		warn("[BankersBake] ApplyDescription failed: " .. tostring(applyErr))
		return false
	end

	rig:SetAttribute("BankersAppliedLoadout", loadout.Name or tostring(slotIndex))
	rig:SetAttribute("BankersOutfitBaked", true)
	rig:SetAttribute("BankersBakedAccessoryCount", accessoryCount)

	print(string.format("[BankersBake] baked %s with %d catalog accessories", loadout.DisplayName or loadout.Name or "Unnamed", accessoryCount))
	return true
end

function BakeMenuOutfits.Run()
	local rigs = getSortedMenuRigs()
	if #rigs == 0 then
		warn("[BankersBake] no Workspace Rig models with Humanoids found")
		return false
	end

	local successCount = 0
	for index, rig in ipairs(rigs) do
		if applyLoadout(rig, index) then
			successCount += 1
		end
	end

	print(string.format("[BankersBake] COMPLETE: %d/%d rigs baked. Press Ctrl+S to save them into Bankers.rbxl.", successCount, #rigs))
	return successCount == #rigs
end

function BakeMenuOutfits.ClearBakedFlags()
	for _, rig in ipairs(getSortedMenuRigs()) do
		rig:SetAttribute("BankersOutfitBaked", nil)
		rig:SetAttribute("BankersBakedAccessoryCount", nil)
	end
	print("[BankersBake] baked flags cleared")
end

return BakeMenuOutfits

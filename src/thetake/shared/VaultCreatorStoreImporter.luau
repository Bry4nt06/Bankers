local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local shared = ReplicatedStorage:WaitForChild("TheTake"):WaitForChild("Shared")
local Manifest = require(shared:WaitForChild("VaultCreatorStoreManifest"))
local GearRules = require(shared:WaitForChild("VaultGearRules"))

local Importer = {}

local BLOCKED_MESH_IDS = {
	[8357187898] = true,
	[8357195670] = true,
	[8211433480] = true,
	[8357164518] = true,
	[8357191738] = true,
}

local function contentIdNumber(value: string): number?
	local number = value:match("(%d+)")
	return number and tonumber(number) or nil
end

local function sanitize(instance: Instance)
	local all = {instance}
	for _, descendant in ipairs(instance:GetDescendants()) do
		table.insert(all, descendant)
	end
	for index = #all, 1, -1 do
		local descendant = all[index]
		if descendant:IsA("Script") or descendant:IsA("LocalScript") or descendant:IsA("ModuleScript") then
			descendant:Destroy()
		elseif descendant:IsA("RemoteEvent") or descendant:IsA("RemoteFunction") or descendant:IsA("BindableEvent") or descendant:IsA("BindableFunction") then
			descendant:Destroy()
		elseif descendant:IsA("Sound") or descendant:IsA("ProximityPrompt") or descendant:IsA("ClickDetector") then
			descendant:Destroy()
		elseif descendant:IsA("MeshPart") then
			local id = contentIdNumber(descendant.MeshId)
			if id and BLOCKED_MESH_IDS[id] then
				descendant:Destroy()
			else
				descendant.Anchored = true
				descendant.CanCollide = false
				descendant.CanTouch = false
				descendant.CanQuery = false
			end
		elseif descendant:IsA("SpecialMesh") then
			local id = contentIdNumber(descendant.MeshId)
			if id and BLOCKED_MESH_IDS[id] then
				descendant:Destroy()
			end
		elseif descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
		end
	end
end

local function findByItemId(folder: Instance, itemId: string): Instance?
	for _, child in ipairs(folder:GetChildren()) do
		if child:GetAttribute("VaultItemId") == itemId then
			return child
		end
	end
	return nil
end

local function migrateLegacySkins(root: Folder)
	local legacy = root:FindFirstChild("Skins")
	local gear = root:FindFirstChild("Gear")
	if not legacy or not legacy:IsA("Folder") or not gear or not gear:IsA("Folder") then
		return
	end

	local moved = 0
	for _, child in ipairs(legacy:GetChildren()) do
		local itemId = child:GetAttribute("VaultItemId")
		local duplicate = type(itemId) == "string" and itemId ~= "" and findByItemId(gear, itemId) or nil
		if not duplicate then
			child.Parent = gear
			moved += 1
		end
	end
	legacy:Destroy()
	print(string.format("[VaultImporter] migrated legacy Skins -> Gear | moved=%d", moved))
end

local function clearLegacyLoadoutPresets(root: Folder)
	local folder = root:FindFirstChild("Loadouts")
	if not folder or not folder:IsA("Folder") then
		return
	end
	local removed = 0
	for _, child in ipairs(folder:GetChildren()) do
		if child:GetAttribute("SeededBaseline") == true then
			child:Destroy()
			removed += 1
		end
	end
	if removed > 0 then
		print(string.format("[VaultImporter] removed %d legacy purchasable loadout presets; LOADOUTS is now the Gear wardrobe", removed))
	end
end

local function targetFolder(root: Folder, category: string, record): Folder?
	local folder = root:FindFirstChild(category)
	if not folder or not folder:IsA("Folder") then
		return nil
	end
	if category == "Guns" then
		local subcategory = folder:FindFirstChild(record.subcategory)
		return subcategory and subcategory:IsA("Folder") and subcategory or nil
	end
	return folder
end

local function setCommonAttributes(item: Instance, category: string, record)
	item:SetAttribute("VaultItemId", record.itemId)
	item:SetAttribute("VaultDisplayName", record.displayName)
	item:SetAttribute("VaultPrice", record.price or 0)
	item:SetAttribute("VaultCurrency", "Cash")
	item:SetAttribute("VaultEnabled", true)
	item:SetAttribute("CreatorStoreImported", true)
	item:SetAttribute("CreatorStoreAssetId", record.assetId or 0)
	item:SetAttribute("CreatorStoreCreator", record.creator or "")
	item:SetAttribute("CreatorStoreSourceName", record.displayName)

	if category == "Gear" then
		item:SetAttribute("VaultWearable", true)
		item:SetAttribute("FitStatus", "AutoFit")
		item:SetAttribute("GearType", "CreatorStoreModel")
		item:SetAttribute("GearSlot", GearRules.InferSlot(item))
	elseif category == "Emotes" then
		item:SetAttribute("EmoteType", "CreatorStoreAnimationAsset")
	elseif category == "SafehouseFurniture" then
		item:SetAttribute("FurnitureType", "CreatorStoreModel")
	end
end

local function importAsset(root: Folder, category: string, record, replaceExisting: boolean)
	local destination = targetFolder(root, category, record)
	if not destination then
		return false, "TARGET_FOLDER_MISSING"
	end

	local existing = findByItemId(destination, record.itemId)
	if existing then
		if not replaceExisting then
			return true, "SKIPPED_EXISTING"
		end
		existing:Destroy()
	end

	local ok, loaded = pcall(function()
		return AssetService:LoadAssetAsync(record.assetId)
	end)
	if not ok or not loaded then
		return false, tostring(loaded)
	end

	loaded.Name = record.displayName
	sanitize(loaded)
	setCommonAttributes(loaded, category, record)
	loaded.Parent = destination
	return true, "IMPORTED"
end

function Importer.Run(options)
	options = type(options) == "table" and options or {}
	local replaceExisting = options.replaceExisting == true

	local root = ServerStorage:FindFirstChild("TheTakeVaultCatalog")
	if not root or not root:IsA("Folder") then
		error("[VaultImporter] ServerStorage.TheTakeVaultCatalog is missing. Connect Rojo with thetake.project.json first.")
	end

	migrateLegacySkins(root)
	clearLegacyLoadoutPresets(root)

	local permissionReadable, allowThirdParty = pcall(function()
		return AssetService.AllowInsertFreeAssets
	end)
	if permissionReadable and allowThirdParty ~= true then
		warn("[VaultImporter] Enable Game Settings > Security > Allow Loading Third Party Assets, then run the importer again.")
	end

	local imported = 0
	local skipped = 0
	local failed = 0

	for _, category in ipairs({"Guns", "Gear", "Emotes", "SafehouseFurniture"}) do
		for _, record in ipairs(Manifest[category]) do
			local ok, status = importAsset(root, category, record, replaceExisting)
			if ok and status == "IMPORTED" then
				imported += 1
				print(string.format("[VaultImporter] imported %s / %s", category, record.displayName))
			elseif ok then
				skipped += 1
			else
				failed += 1
				warn(string.format("[VaultImporter] FAILED %s / %s (%s): %s", category, record.displayName, tostring(record.assetId), status))
			end
		end
	end

	print(string.format(
		"[VaultImporter] complete | imported=%d | skipped=%d | failed=%d | LOADOUTS is wardrobe-only",
		imported,
		skipped,
		failed
	))

	return {
		imported = imported,
		skipped = skipped,
		failed = failed,
	}
end

return Importer

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local sourceRoot = ServerStorage:WaitForChild("TheTakeVaultCatalog")
local theTakeRoot = ReplicatedStorage:WaitForChild("TheTake")
local shared = theTakeRoot:WaitForChild("Shared")
local Config = require(shared:WaitForChild("VaultEconomyConfig"))

local skinsFolder = sourceRoot:WaitForChild("Skins")
local defaultSkin = nil
for _, child in ipairs(skinsFolder:GetChildren()) do
	if child:GetAttribute("VaultItemId") == Config.DefaultSkinId then
		defaultSkin = child
		break
	end
end
if not defaultSkin then
	warn("[TheVaultCatalog] physical Crew Standard skin is missing from ServerStorage.TheTakeVaultCatalog.Skins")
end

local runtimeIndex = theTakeRoot:FindFirstChild("VaultStoreIndex")
if runtimeIndex then
	runtimeIndex:Destroy()
end
runtimeIndex = Instance.new("Folder")
runtimeIndex.Name = "VaultStoreIndex"
runtimeIndex.Parent = theTakeRoot

local previewRoot = theTakeRoot:FindFirstChild("VaultPreviewModels")
if previewRoot then
	previewRoot:Destroy()
end
previewRoot = Instance.new("Folder")
previewRoot.Name = "VaultPreviewModels"
previewRoot.Parent = theTakeRoot

local VALID_TOP_LEVEL = {
	Guns = true,
	Skins = true,
	Emotes = true,
	SafehouseFurniture = true,
	Loadouts = true,
}

local rebuildQueued = false

local function slug(value: string): string
	local result = value:lower():gsub("[^%w]+", "-"):gsub("^-+", ""):gsub("-+$", "")
	return result ~= "" and result or "item"
end

local function getCategoryParts(item: Instance)
	local parts = {}
	local cursor = item.Parent
	while cursor and cursor ~= sourceRoot do
		table.insert(parts, 1, cursor.Name)
		cursor = cursor.Parent
	end
	return parts
end

local function isCatalogItem(instance: Instance): boolean
	if instance:IsA("Folder") then
		return false
	end

	local parent = instance.Parent
	if not parent or not parent:IsA("Folder") then
		return false
	end

	if parent.Parent == sourceRoot then
		return VALID_TOP_LEVEL[parent.Name] == true and parent.Name ~= "Guns"
	end

	local grandparent = parent.Parent
	if grandparent and grandparent:IsA("Folder") and grandparent.Name == "Guns" and grandparent.Parent == sourceRoot then
		return true
	end

	return false
end

local function stripPreviewBehavior(instance: Instance)
	local all = {instance}
	for _, descendant in ipairs(instance:GetDescendants()) do
		table.insert(all, descendant)
	end
	for _, descendant in ipairs(all) do
		if descendant:IsA("Script") or descendant:IsA("LocalScript") or descendant:IsA("ModuleScript") then
			descendant:Destroy()
		elseif descendant:IsA("Sound") then
			descendant:Destroy()
		elseif descendant:IsA("ProximityPrompt") then
			descendant:Destroy()
		elseif descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
		end
	end
end

local function hasVisual(instance: Instance): boolean
	return instance:IsA("BasePart") or instance:FindFirstChildWhichIsA("BasePart", true) ~= nil
end

local function buildPreview(item: Instance, itemId: string)
	if not hasVisual(item) then
		return false
	end
	local clone = item:Clone()
	clone.Name = itemId
	stripPreviewBehavior(clone)
	clone.Parent = previewRoot
	return true
end

local function rebuild()
	rebuildQueued = false
	for _, child in ipairs(runtimeIndex:GetChildren()) do
		child:Destroy()
	end
	for _, child in ipairs(previewRoot:GetChildren()) do
		child:Destroy()
	end

	local count = 0
	local previewCount = 0
	for _, item in ipairs(sourceRoot:GetDescendants()) do
		if isCatalogItem(item) then
			local categoryParts = getCategoryParts(item)
			local category = categoryParts[1] or "Unknown"
			local subcategory = categoryParts[2] or ""
			local wearable = category == "Skins" and item:GetAttribute("VaultWearable") == true
			local enabled = item:GetAttribute("VaultEnabled") ~= false
			if category == "Skins" and not wearable then
				enabled = false
			end

			local itemId = item:GetAttribute("VaultItemId")
			if type(itemId) ~= "string" or itemId == "" then
				itemId = slug(table.concat(categoryParts, "-") .. "-" .. item.Name)
			end

			local previewAvailable = buildPreview(item, itemId)
			if previewAvailable then
				previewCount += 1
			end

			local entry = Instance.new("Folder")
			entry.Name = itemId
			entry:SetAttribute("ItemId", itemId)
			entry:SetAttribute("DisplayName", item:GetAttribute("VaultDisplayName") or item.Name)
			entry:SetAttribute("Category", category)
			entry:SetAttribute("Subcategory", subcategory)
			entry:SetAttribute("Price", item:GetAttribute("VaultPrice") or 0)
			entry:SetAttribute("Currency", item:GetAttribute("VaultCurrency") or "Cash")
			entry:SetAttribute("Enabled", enabled)
			entry:SetAttribute("SourceClass", item.ClassName)
			entry:SetAttribute("PreviewAvailable", previewAvailable)
			entry:SetAttribute("Wearable", wearable)
			entry:SetAttribute("DefaultOwned", item:GetAttribute("VaultDefaultOwned") == true)
			entry:SetAttribute("SkinType", item:GetAttribute("SkinType") or "")
			entry.Parent = runtimeIndex
			count += 1
		end
	end

	runtimeIndex:SetAttribute("ItemCount", count)
	runtimeIndex:SetAttribute("PreviewCount", previewCount)
	runtimeIndex:SetAttribute("Ready", true)
	print(string.format("[TheVaultCatalog] indexed %d store items (%d automatic previews)", count, previewCount))
end

local function queueRebuild()
	if rebuildQueued then
		return
	end
	rebuildQueued = true
	task.defer(rebuild)
end

sourceRoot.DescendantAdded:Connect(queueRebuild)
sourceRoot.DescendantRemoving:Connect(queueRebuild)

for _, descendant in ipairs(sourceRoot:GetDescendants()) do
	descendant.AttributeChanged:Connect(queueRebuild)
end
sourceRoot.DescendantAdded:Connect(function(descendant)
	descendant.AttributeChanged:Connect(queueRebuild)
end)

rebuild()

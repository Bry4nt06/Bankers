local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local sourceRoot = ServerStorage:WaitForChild("TheTakeVaultCatalog")
local theTakeRoot = ReplicatedStorage:WaitForChild("TheTake")

local runtimeIndex = theTakeRoot:FindFirstChild("VaultStoreIndex")
if runtimeIndex then
	runtimeIndex:Destroy()
end
runtimeIndex = Instance.new("Folder")
runtimeIndex.Name = "VaultStoreIndex"
runtimeIndex.Parent = theTakeRoot

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
	local cursor = instance.Parent
	while cursor and cursor ~= sourceRoot do
		if cursor.Parent == sourceRoot and not VALID_TOP_LEVEL[cursor.Name] then
			return false
		end
		cursor = cursor.Parent
	end
	return cursor == sourceRoot
end

local function rebuild()
	rebuildQueued = false
	for _, child in ipairs(runtimeIndex:GetChildren()) do
		child:Destroy()
	end

	local count = 0
	for _, item in ipairs(sourceRoot:GetDescendants()) do
		if isCatalogItem(item) then
			local categoryParts = getCategoryParts(item)
			local category = categoryParts[1] or "Unknown"
			local subcategory = categoryParts[2] or ""
			local itemId = item:GetAttribute("VaultItemId")
			if type(itemId) ~= "string" or itemId == "" then
				itemId = slug(table.concat(categoryParts, "-") .. "-" .. item.Name)
			end

			local entry = Instance.new("Folder")
			entry.Name = itemId
			entry:SetAttribute("ItemId", itemId)
			entry:SetAttribute("DisplayName", item:GetAttribute("VaultDisplayName") or item.Name)
			entry:SetAttribute("Category", category)
			entry:SetAttribute("Subcategory", subcategory)
			entry:SetAttribute("Price", item:GetAttribute("VaultPrice") or 0)
			entry:SetAttribute("Currency", item:GetAttribute("VaultCurrency") or "Cash")
			entry:SetAttribute("Enabled", item:GetAttribute("VaultEnabled") ~= false)
			entry:SetAttribute("SourceClass", item.ClassName)
			entry.Parent = runtimeIndex
			count += 1
		end
	end

	runtimeIndex:SetAttribute("ItemCount", count)
	runtimeIndex:SetAttribute("Ready", true)
	print(string.format("[TheVaultCatalog] indexed %d store items", count))
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

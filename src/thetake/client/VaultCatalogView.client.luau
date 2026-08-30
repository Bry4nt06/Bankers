local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local theTake = ReplicatedStorage:WaitForChild("TheTake")
local shared = theTake:WaitForChild("Shared")
local GearRules = require(shared:WaitForChild("VaultGearRules"))
local Config = require(shared:WaitForChild("VaultEconomyConfig"))
local index = theTake:WaitForChild("VaultStoreIndex")
local previewRoot = theTake:WaitForChild("VaultPreviewModels")
local remotes = theTake:WaitForChild("VaultRemotes")
local getProfile = remotes:WaitForChild("GetProfile")
local purchaseItem = remotes:WaitForChild("PurchaseItem")
local equipItem = remotes:WaitForChild("EquipItem")
local profileChanged = remotes:WaitForChild("ProfileChanged")

local CATEGORY_MAP = {
	guns = "Guns",
	gear = "Gear",
	emotes = "Emotes",
	safehouse_furniture = "SafehouseFurniture",
	loadouts = "Wardrobe",
}

local currentCategory = "Guns"
local listFrame: ScrollingFrame? = nil
local emptyState: TextLabel? = nil
local cashLabel: TextLabel? = nil

local function emptyGearSlots()
	local slots = {}
	for _, slot in ipairs(GearRules.SlotOrder) do
		slots[slot] = ""
	end
	return slots
end

local profile = {
	Cash = 0,
	Owned = {},
	Equipped = {
		GearSlots = emptyGearSlots(),
		Primary = "",
		Secondary = "",
	},
}

local function findVaultPanel()
	local gui = playerGui:FindFirstChild("TheTakeMenuGui")
	if not gui then
		return nil
	end
	return gui:FindFirstChild("TheVaultPanel", true)
end

local function findEmptyState(panel: Instance): TextLabel?
	for _, descendant in ipairs(panel:GetDescendants()) do
		if descendant:IsA("TextLabel") and descendant.Text:find("CATALOG FOUNDATION READY", 1, true) then
			return descendant
		end
	end
	return nil
end

local function migrateClientSlots(incoming)
	local slots = emptyGearSlots()
	if type(incoming) ~= "table" then
		return slots
	end

	local function apply(rawSlot: string)
		local value = incoming[rawSlot]
		if type(value) ~= "string" or value == "" then
			return
		end
		local normalized = GearRules.NormalizeSlot(rawSlot, value)
		if value == Config.DefaultGearId and slots[normalized] ~= "" then
			return
		end
		slots[normalized] = value
	end

	for _, slot in ipairs({"Base", "Head", "Face", "Torso", "Back"}) do
		apply(slot)
	end
	for _, slot in ipairs(GearRules.SlotOrder) do
		apply(slot)
	end
	return slots
end

local function normalizeProfile(result)
	if type(result) ~= "table" then
		return
	end
	profile = result
	profile.Owned = type(profile.Owned) == "table" and profile.Owned or {}
	profile.Equipped = type(profile.Equipped) == "table" and profile.Equipped or {}
	if type(profile.Equipped.GearSlots) == "table" then
		profile.Equipped.GearSlots = migrateClientSlots(profile.Equipped.GearSlots)
	else
		local slots = emptyGearSlots()
		local legacy = type(profile.Equipped.Gear) == "string" and profile.Equipped.Gear or ""
		if legacy ~= "" then
			slots[GearRules.NormalizeSlot("Base", legacy)] = legacy
		end
		profile.Equipped.GearSlots = slots
	end
	profile.Equipped.Primary = type(profile.Equipped.Primary) == "string" and profile.Equipped.Primary or ""
	profile.Equipped.Secondary = type(profile.Equipped.Secondary) == "string" and profile.Equipped.Secondary or ""
end

local function updateCash()
	if cashLabel then
		cashLabel.Text = string.format("CASH  $%s", tostring(math.floor(tonumber(profile.Cash) or 0)))
	end
end

local function clearRows()
	if not listFrame then
		return
	end
	for _, child in ipairs(listFrame:GetChildren()) do
		if not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end
end

local function loadProfile()
	local ok, success, _, result = pcall(function()
		return getProfile:InvokeServer()
	end)
	if ok and success == true then
		normalizeProfile(result)
	end
	updateCash()
end

local function addThumbnail(viewport: ViewportFrame, entry: Folder): boolean
	local assetId = tonumber(entry:GetAttribute("CreatorStoreAssetId")) or 0
	if assetId <= 0 then
		return false
	end
	local image = Instance.new("ImageLabel")
	image.Size = UDim2.fromScale(1, 1)
	image.BackgroundTransparency = 1
	image.Image = string.format("rbxthumb://type=Asset&id=%d&w=420&h=420", assetId)
	image.ScaleType = Enum.ScaleType.Fit
	image.Parent = viewport
	return true
end

local function buildViewport(viewport: ViewportFrame, entry: Folder)
	viewport.BackgroundColor3 = Color3.fromRGB(13, 20, 48)
	viewport.BackgroundTransparency = 0.05
	viewport.BorderSizePixel = 0
	viewport.Ambient = Color3.fromRGB(150, 158, 180)
	viewport.LightColor = Color3.fromRGB(255, 213, 154)
	viewport.LightDirection = Vector3.new(-1, -1, -1)

	-- Creator Store imports intentionally use Roblox thumbnails. Their raw child meshes
	-- can reference content that is not authorized for this experience.
	if tonumber(entry:GetAttribute("CreatorStoreAssetId")) and tonumber(entry:GetAttribute("CreatorStoreAssetId")) > 0 then
		if addThumbnail(viewport, entry) then
			return
		end
	end

	local itemId = tostring(entry:GetAttribute("ItemId") or entry.Name)
	local source = previewRoot:FindFirstChild(itemId)
	if not source then
		local fallback = Instance.new("TextLabel")
		fallback.Size = UDim2.fromScale(1, 1)
		fallback.BackgroundTransparency = 1
		fallback.Font = Enum.Font.GothamBold
		fallback.Text = entry:GetAttribute("Category") == "Gear" and "GEAR\nPREVIEW" or "NO\nPREVIEW"
		fallback.TextColor3 = Color3.fromRGB(118, 170, 191)
		fallback.TextSize = 12
		fallback.TextWrapped = true
		fallback.Parent = viewport
		return
	end

	local world = Instance.new("WorldModel")
	world.Parent = viewport
	local wrapper = Instance.new("Model")
	wrapper.Name = "Preview"
	wrapper.Parent = world
	local clone = source:Clone()
	clone.Parent = wrapper

	for _, descendant in ipairs(wrapper:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
		end
	end

	local okBounds, _, size = pcall(function()
		return wrapper:GetBoundingBox()
	end)
	if not okBounds or not size then
		world:Destroy()
		return
	end

	wrapper:PivotTo(CFrame.new())
	local maxDim = math.max(size.X, size.Y, size.Z)
	if maxDim < 0.1 then
		maxDim = 1
	end

	local previewCamera = Instance.new("Camera")
	previewCamera.FieldOfView = 35
	previewCamera.CFrame = CFrame.lookAt(
		Vector3.new(maxDim * 1.45, maxDim * 0.55, maxDim * 1.75),
		Vector3.new(0, 0, 0)
	)
	previewCamera.Parent = viewport
	viewport.CurrentCamera = previewCamera
end

local function entrySlot(entry: Folder, itemId: string): string
	return GearRules.NormalizeSlot(tostring(entry:GetAttribute("GearSlot") or "Vest"), itemId)
end

local function isGearEquipped(entry: Folder, itemId: string): boolean
	local slot = entrySlot(entry, itemId)
	return profile.Equipped.GearSlots[slot] == itemId
end

local function isGunEquipped(entry: Folder, itemId: string): boolean
	local subcategory = tostring(entry:GetAttribute("Subcategory") or "")
	if subcategory == "Pistols" then
		return profile.Equipped.Secondary == itemId
	end
	return profile.Equipped.Primary == itemId
end

local function collectEntries()
	local entries = {}
	for _, entry in ipairs(index:GetChildren()) do
		if entry:IsA("Folder") and entry:GetAttribute("Enabled") ~= false then
			local itemId = tostring(entry:GetAttribute("ItemId") or entry.Name)
			if currentCategory == "Wardrobe" then
				if entry:GetAttribute("Category") == "Gear" and profile.Owned[itemId] == true then
					table.insert(entries, entry)
				end
			elseif entry:GetAttribute("Category") == currentCategory then
				table.insert(entries, entry)
			end
		end
	end
	table.sort(entries, function(a, b)
		if currentCategory == "Wardrobe" then
			local itemA = tostring(a:GetAttribute("ItemId") or a.Name)
			local itemB = tostring(b:GetAttribute("ItemId") or b.Name)
			local slotA = entrySlot(a, itemA)
			local slotB = entrySlot(b, itemB)
			local rankA = GearRules.SlotRank(slotA)
			local rankB = GearRules.SlotRank(slotB)
			if rankA ~= rankB then
				return rankA < rankB
			end
		end
		return tostring(a:GetAttribute("DisplayName")):lower() < tostring(b:GetAttribute("DisplayName")):lower()
	end)
	return entries
end

local function callEquip(itemId: string)
	local callOk, success, message, result = pcall(function()
		return equipItem:InvokeServer(itemId)
	end)
	if callOk and type(result) == "table" then
		normalizeProfile(result)
	end
	return callOk and success == true, message
end

local function addWardrobeHeader(slot: string, layoutOrder: number)
	if not listFrame then
		return
	end
	local header = Instance.new("Frame")
	header.Name = "Category_" .. slot
	header.Size = UDim2.new(1, -8, 0, 34)
	header.BackgroundTransparency = 1
	header.LayoutOrder = layoutOrder
	header.Parent = listFrame

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -8, 1, 0)
	label.Position = UDim2.fromOffset(4, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.Text = GearRules.SlotLabel(slot)
	label.TextColor3 = Color3.fromRGB(236, 179, 78)
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = header

	local line = Instance.new("Frame")
	line.AnchorPoint = Vector2.new(0, 1)
	line.Position = UDim2.new(0, 4, 1, -2)
	line.Size = UDim2.new(1, -8, 0, 1)
	line.BorderSizePixel = 0
	line.BackgroundColor3 = Color3.fromRGB(77, 210, 218)
	line.BackgroundTransparency = 0.62
	line.Parent = header
end

local refresh
refresh = function()
	if not listFrame or not emptyState then
		return
	end
	clearRows()
	updateCash()

	local entries = collectEntries()
	if #entries == 0 then
		emptyState.Visible = true
		if currentCategory == "Wardrobe" then
			emptyState.Text = "NO OWNED GEAR YET\nBuy Gear first, then dress your avatar here."
		elseif currentCategory == "Gear" then
			emptyState.Text = "NO GEAR REGISTERED"
		else
			emptyState.Text = "NO ITEMS REGISTERED\nAdd approved assets to ServerStorage.TheTakeVaultCatalog."
		end
		listFrame.Visible = false
		return
	end

	emptyState.Visible = false
	listFrame.Visible = true

	local layoutOrder = 0
	local lastWardrobeSlot = ""
	for _, entry in ipairs(entries) do
		local itemId = tostring(entry:GetAttribute("ItemId") or entry.Name)
		local category = tostring(entry:GetAttribute("Category") or "")
		local wearable = entry:GetAttribute("Wearable") == true
		local gearSlot = category == "Gear" and entrySlot(entry, itemId) or ""
		local fitStatus = tostring(entry:GetAttribute("FitStatus") or "")

		if currentCategory == "Wardrobe" and gearSlot ~= lastWardrobeSlot then
			layoutOrder += 1
			addWardrobeHeader(gearSlot, layoutOrder)
			lastWardrobeSlot = gearSlot
		end

		layoutOrder += 1
		local row = Instance.new("Frame")
		row.Name = itemId
		row.Size = UDim2.new(1, -8, 0, 106)
		row.BackgroundColor3 = Color3.fromRGB(24, 54, 82)
		row.BackgroundTransparency = 0.10
		row.BorderSizePixel = 0
		row.LayoutOrder = layoutOrder
		row.Parent = listFrame

		local viewport = Instance.new("ViewportFrame")
		viewport.Position = UDim2.fromOffset(8, 8)
		viewport.Size = UDim2.fromOffset(90, 90)
		viewport.Parent = row
		buildViewport(viewport, entry)

		local name = Instance.new("TextLabel")
		name.Position = UDim2.fromOffset(110, 10)
		name.Size = UDim2.new(1, -230, 0, 24)
		name.BackgroundTransparency = 1
		name.Font = Enum.Font.GothamBold
		name.Text = tostring(entry:GetAttribute("DisplayName") or entry.Name)
		name.TextColor3 = Color3.fromRGB(245, 245, 245)
		name.TextSize = 14
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.Parent = row

		local detail = Instance.new("TextLabel")
		detail.Position = UDim2.fromOffset(110, 37)
		detail.Size = UDim2.new(1, -230, 0, 20)
		detail.BackgroundTransparency = 1
		detail.Font = Enum.Font.Gotham
		if currentCategory == "Wardrobe" then
			detail.Text = GearRules.SlotLabel(gearSlot) .. " • " .. (fitStatus ~= "" and string.upper(fitStatus) or "READY")
		elseif category == "Gear" then
			detail.Text = GearRules.SlotLabel(gearSlot) .. " • " .. (wearable and (fitStatus == "AutoFit" and "AUTO FIT" or "WEARABLE") or "FIT PENDING")
		else
			local subcategory = tostring(entry:GetAttribute("Subcategory") or "")
			detail.Text = subcategory ~= "" and subcategory or "VAULT ITEM"
		end
		detail.TextColor3 = Color3.fromRGB(157, 178, 194)
		detail.TextSize = 11
		detail.TextXAlignment = Enum.TextXAlignment.Left
		detail.Parent = row

		local price = math.max(0, math.floor(tonumber(entry:GetAttribute("Price")) or 0))
		local currency = tostring(entry:GetAttribute("Currency") or "Cash")
		local priceLabel = Instance.new("TextLabel")
		priceLabel.Position = UDim2.fromOffset(110, 61)
		priceLabel.Size = UDim2.new(1, -230, 0, 20)
		priceLabel.BackgroundTransparency = 1
		priceLabel.Font = Enum.Font.GothamMedium
		if currentCategory == "Wardrobe" then
			priceLabel.Text = "OWNED"
		else
			priceLabel.Text = price > 0 and string.format("%d %s", price, currency) or "INCLUDED"
		end
		priceLabel.TextColor3 = Color3.fromRGB(236, 179, 78)
		priceLabel.TextSize = 12
		priceLabel.TextXAlignment = Enum.TextXAlignment.Left
		priceLabel.Parent = row

		local action = Instance.new("TextButton")
		action.AnchorPoint = Vector2.new(1, 0.5)
		action.Position = UDim2.new(1, -12, 0.5, 0)
		action.Size = UDim2.fromOffset(104, 38)
		action.BackgroundColor3 = Color3.fromRGB(108, 24, 60)
		action.BackgroundTransparency = 0.04
		action.BorderSizePixel = 0
		action.AutoButtonColor = true
		action.Font = Enum.Font.GothamBold
		action.TextColor3 = Color3.fromRGB(245, 245, 245)
		action.TextSize = 12
		action.Parent = row

		local owned = profile.Owned[itemId] == true
		local activeAction = false

		if currentCategory == "Wardrobe" then
			if not wearable then
				action.Text = "FIT PENDING"
				action.Active = false
			elseif isGearEquipped(entry, itemId) then
				if itemId == Config.DefaultGearId then
					action.Text = "DEFAULT WORN"
					action.Active = false
				else
					action.Text = "REMOVE"
					activeAction = true
				end
			else
				action.Text = "WEAR"
				activeAction = true
			end
		elseif category == "Gear" then
			if owned then
				action.Text = "OWNED"
				action.Active = false
			else
				action.Text = price > 0 and "BUY" or "CLAIM"
				activeAction = true
			end
		elseif category == "Guns" then
			if owned and isGunEquipped(entry, itemId) then
				action.Text = "EQUIPPED"
				action.BackgroundColor3 = Color3.fromRGB(28, 116, 126)
				action.Active = false
			elseif owned then
				action.Text = "EQUIP"
				activeAction = true
			else
				action.Text = price > 0 and "BUY" or "CLAIM"
				activeAction = true
			end
		else
			if owned then
				action.Text = "OWNED"
				action.Active = false
			else
				action.Text = price > 0 and "BUY" or "CLAIM"
				activeAction = true
			end
		end

		if activeAction then
			action.Active = true
			action.Activated:Connect(function()
				action.Active = false
				action.Text = "..."

				if currentCategory == "Wardrobe" then
					callEquip(itemId)
				elseif profile.Owned[itemId] == true then
					callEquip(itemId)
				else
					local callOk, success, message, result = pcall(function()
						return purchaseItem:InvokeServer(itemId)
					end)
					if callOk and type(result) == "table" then
						normalizeProfile(result)
					end
					-- Guns preserve the quick buy-and-equip flow. Gear is dressed only in LOADOUTS.
					if callOk and success == true and message == "PURCHASED" and category == "Guns" then
						callEquip(itemId)
					end
				end
				refresh()
			end)
		end
	end
end

local function attach(panel: Frame)
	emptyState = findEmptyState(panel)
	if not emptyState or not emptyState.Parent or not emptyState.Parent:IsA("Frame") then
		return
	end
	local contentFrame = emptyState.Parent

	cashLabel = Instance.new("TextLabel")
	cashLabel.AnchorPoint = Vector2.new(1, 0)
	cashLabel.Position = UDim2.new(1, -24, 0, 24)
	cashLabel.Size = UDim2.fromOffset(150, 30)
	cashLabel.BackgroundTransparency = 1
	cashLabel.Font = Enum.Font.GothamBold
	cashLabel.TextColor3 = Color3.fromRGB(236, 179, 78)
	cashLabel.TextSize = 14
	cashLabel.TextXAlignment = Enum.TextXAlignment.Right
	cashLabel.ZIndex = 34
	cashLabel.Parent = contentFrame

	listFrame = Instance.new("ScrollingFrame")
	listFrame.Name = "VaultCatalogItems"
	listFrame.Position = UDim2.fromOffset(24, 140)
	listFrame.Size = UDim2.new(1, -48, 1, -164)
	listFrame.BackgroundTransparency = 1
	listFrame.BorderSizePixel = 0
	listFrame.ScrollBarThickness = 4
	listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	listFrame.CanvasSize = UDim2.new()
	listFrame.ZIndex = 33
	listFrame.Parent = contentFrame

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = listFrame

	for buttonId, serverCategory in pairs(CATEGORY_MAP) do
		local button = panel:FindFirstChild(buttonId, true)
		if button and button:IsA("TextButton") then
			button.Activated:Connect(function()
				currentCategory = serverCategory
				refresh()
			end)
		end
	end

	loadProfile()
	refresh()
end

local function tryAttach()
	local panel = findVaultPanel()
	if panel and panel:IsA("Frame") then
		attach(panel)
		return true
	end
	return false
end

if not tryAttach() then
	playerGui.ChildAdded:Connect(function(child)
		if child.Name == "TheTakeMenuGui" then
			task.defer(tryAttach)
		end
	end)
end

index.ChildAdded:Connect(refresh)
index.ChildRemoved:Connect(refresh)
index.AttributeChanged:Connect(refresh)
previewRoot.ChildAdded:Connect(refresh)
previewRoot.ChildRemoved:Connect(refresh)
profileChanged.OnClientEvent:Connect(function(newProfile)
	if type(newProfile) == "table" then
		normalizeProfile(newProfile)
		refresh()
	end
end)

print("[TheVaultCatalog] store + categorized LOADOUT wardrobe UI ready")

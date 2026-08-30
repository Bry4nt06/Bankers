local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local theTake = ReplicatedStorage:WaitForChild("TheTake")
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
	loadouts = "Loadouts",
}

local currentCategory = "Guns"
local listFrame: ScrollingFrame? = nil
local emptyState: TextLabel? = nil
local cashLabel: TextLabel? = nil
local profile = {
	Cash = 0,
	Owned = {},
	Equipped = {Gear = "", Primary = "", Secondary = ""},
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

local function normalizeProfile(result)
	if type(result) ~= "table" then
		return
	end
	profile = result
	profile.Owned = type(profile.Owned) == "table" and profile.Owned or {}
	profile.Equipped = type(profile.Equipped) == "table" and profile.Equipped or {}
	if type(profile.Equipped.Gear) ~= "string" then
		profile.Equipped.Gear = type(profile.Equipped.Skin) == "string" and profile.Equipped.Skin or ""
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

local function addThumbnailFallback(viewport: ViewportFrame, entry: Folder): boolean
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

	local itemId = tostring(entry:GetAttribute("ItemId") or entry.Name)
	local source = previewRoot:FindFirstChild(itemId)
	if not source then
		if addThumbnailFallback(viewport, entry) then
			return
		end
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
		addThumbnailFallback(viewport, entry)
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

local function isEquipped(entry: Folder, itemId: string)
	local category = tostring(entry:GetAttribute("Category") or "")
	if category == "Gear" then
		return profile.Equipped.Gear == itemId
	end
	if category == "Guns" then
		local subcategory = tostring(entry:GetAttribute("Subcategory") or "")
		if subcategory == "Pistols" then
			return profile.Equipped.Secondary == itemId
		end
		return profile.Equipped.Primary == itemId
	end
	return false
end

local function refresh()
	if not listFrame or not emptyState then
		return
	end
	clearRows()
	updateCash()

	local entries = {}
	for _, entry in ipairs(index:GetChildren()) do
		if entry:IsA("Folder") and entry:GetAttribute("Enabled") ~= false and entry:GetAttribute("Category") == currentCategory then
			table.insert(entries, entry)
		end
	end
	table.sort(entries, function(a, b)
		return tostring(a:GetAttribute("DisplayName")):lower() < tostring(b:GetAttribute("DisplayName")):lower()
	end)

	if #entries == 0 then
		emptyState.Visible = true
		emptyState.Text = currentCategory == "Gear"
			and "NO GEAR REGISTERED"
			or "NO ITEMS REGISTERED\nAdd approved assets to ServerStorage.TheTakeVaultCatalog."
		listFrame.Visible = false
		return
	end

	emptyState.Visible = false
	listFrame.Visible = true

	for _, entry in ipairs(entries) do
		local itemId = tostring(entry:GetAttribute("ItemId") or entry.Name)
		local category = tostring(entry:GetAttribute("Category") or "")
		local wearable = entry:GetAttribute("Wearable") == true

		local row = Instance.new("Frame")
		row.Name = itemId
		row.Size = UDim2.new(1, -8, 0, 106)
		row.BackgroundColor3 = Color3.fromRGB(24, 54, 82)
		row.BackgroundTransparency = 0.10
		row.BorderSizePixel = 0
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

		local subcategory = tostring(entry:GetAttribute("Subcategory") or "")
		local detail = Instance.new("TextLabel")
		detail.Position = UDim2.fromOffset(110, 37)
		detail.Size = UDim2.new(1, -230, 0, 20)
		detail.BackgroundTransparency = 1
		detail.Font = Enum.Font.Gotham
		if category == "Gear" then
			detail.Text = wearable and "WEARABLE GEAR" or "GEAR • FIT PENDING"
		else
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
		priceLabel.Text = price > 0 and string.format("%d %s", price, currency) or "INCLUDED"
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
		local equipped = owned and isEquipped(entry, itemId)
		local equippable = category == "Guns" or (category == "Gear" and wearable)

		if equipped then
			action.Text = "EQUIPPED"
			action.BackgroundColor3 = Color3.fromRGB(28, 116, 126)
			action.Active = false
		elseif owned and equippable then
			action.Text = "EQUIP"
		elseif owned then
			action.Text = "OWNED"
			action.Active = false
		else
			action.Text = price > 0 and "BUY" or "CLAIM"
		end

		if action.Active then
			action.Activated:Connect(function()
				action.Active = false
				action.Text = "..."
				local callOk, success, message, result
				if profile.Owned[itemId] == true then
					callOk, success, message, result = pcall(function()
						return equipItem:InvokeServer(itemId)
					end)
				else
					callOk, success, message, result = pcall(function()
						return purchaseItem:InvokeServer(itemId)
					end)
				end

				if callOk and type(result) == "table" then
					normalizeProfile(result)
				end
				if callOk and success == true and message == "PURCHASED" and equippable then
					local equipOk, _, _, equipResult = pcall(function()
						return equipItem:InvokeServer(itemId)
					end)
					if equipOk and type(equipResult) == "table" then
						normalizeProfile(equipResult)
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

print("[TheVaultCatalog] automatic preview + purchase UI ready")

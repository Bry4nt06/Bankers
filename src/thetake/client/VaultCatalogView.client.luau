local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local theTake = ReplicatedStorage:WaitForChild("TheTake")
local index = theTake:WaitForChild("VaultStoreIndex")

local CATEGORY_MAP = {
	guns = "Guns",
	skins = "Skins",
	emotes = "Emotes",
	safehouse_furniture = "SafehouseFurniture",
	loadouts = "Loadouts",
}

local currentCategory = "Guns"
local listFrame: ScrollingFrame? = nil
local emptyState: TextLabel? = nil

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

local function refresh()
	if not listFrame or not emptyState then
		return
	end
	clearRows()

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
		emptyState.Text = "NO ITEMS REGISTERED\nDrop donor assets into ServerStorage.TheTakeVaultCatalog to add them."
		listFrame.Visible = false
		return
	end

	emptyState.Visible = false
	listFrame.Visible = true

	for _, entry in ipairs(entries) do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -8, 0, 54)
		row.BackgroundColor3 = Color3.fromRGB(24, 54, 82)
		row.BackgroundTransparency = 0.16
		row.BorderSizePixel = 0
		row.Parent = listFrame

		local name = Instance.new("TextLabel")
		name.Position = UDim2.fromOffset(14, 7)
		name.Size = UDim2.new(0.66, -18, 0, 22)
		name.BackgroundTransparency = 1
		name.Font = Enum.Font.GothamBold
		name.Text = tostring(entry:GetAttribute("DisplayName") or entry.Name)
		name.TextColor3 = Color3.fromRGB(245, 245, 245)
		name.TextSize = 14
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.Parent = row

		local subcategory = tostring(entry:GetAttribute("Subcategory") or "")
		local detail = Instance.new("TextLabel")
		detail.Position = UDim2.fromOffset(14, 29)
		detail.Size = UDim2.new(0.66, -18, 0, 18)
		detail.BackgroundTransparency = 1
		detail.Font = Enum.Font.Gotham
		detail.Text = subcategory ~= "" and subcategory or "VAULT ITEM"
		detail.TextColor3 = Color3.fromRGB(157, 178, 194)
		detail.TextSize = 11
		detail.TextXAlignment = Enum.TextXAlignment.Left
		detail.Parent = row

		local price = tonumber(entry:GetAttribute("Price")) or 0
		local currency = tostring(entry:GetAttribute("Currency") or "Cash")
		local priceLabel = Instance.new("TextLabel")
		priceLabel.AnchorPoint = Vector2.new(1, 0.5)
		priceLabel.Position = UDim2.new(1, -14, 0.5, 0)
		priceLabel.Size = UDim2.new(0.32, 0, 0, 24)
		priceLabel.BackgroundTransparency = 1
		priceLabel.Font = Enum.Font.GothamMedium
		priceLabel.Text = price > 0 and string.format("%d %s", price, currency) or "PRICE TBD"
		priceLabel.TextColor3 = price > 0 and Color3.fromRGB(236, 179, 78) or Color3.fromRGB(112, 116, 124)
		priceLabel.TextSize = 12
		priceLabel.TextXAlignment = Enum.TextXAlignment.Right
		priceLabel.Parent = row
	end
end

local function attach(panel: Frame)
	emptyState = findEmptyState(panel)
	if not emptyState or not emptyState.Parent or not emptyState.Parent:IsA("Frame") then
		return
	end
	local contentFrame = emptyState.Parent

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
	layout.Padding = UDim.new(0, 7)
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

print("[TheVaultCatalog] client catalog view ready")

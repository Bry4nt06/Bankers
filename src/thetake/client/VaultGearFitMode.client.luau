local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

if not RunService:IsStudio() then
	return
end

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local theTake = ReplicatedStorage:WaitForChild("TheTake")
local shared = theTake:WaitForChild("Shared")
local GearRules = require(shared:WaitForChild("VaultGearRules"))
local index = theTake:WaitForChild("VaultStoreIndex")
local remotes = theTake:WaitForChild("VaultFitRemotes", 20)
if not remotes then
	warn("[TheVaultFit] Studio fit remotes were not created")
	return
end

local beginFit = remotes:WaitForChild("BeginFit")
local updateFit = remotes:WaitForChild("UpdateFit")
local endFit = remotes:WaitForChild("EndFit")

local MENU_MODE_ATTRIBUTE = "TheTakeMenuMode"

local COLORS = {
	panel = Color3.fromRGB(19, 25, 68),
	content = Color3.fromRGB(74, 23, 67),
	row = Color3.fromRGB(24, 54, 82),
	wine = Color3.fromRGB(108, 24, 60),
	gold = Color3.fromRGB(236, 179, 78),
	cyan = Color3.fromRGB(77, 210, 218),
	text = Color3.fromRGB(245, 245, 245),
	muted = Color3.fromRGB(157, 178, 194),
	dark = Color3.fromRGB(12, 18, 42),
}

local existing = playerGui:FindFirstChild("TheTakeVaultFitGui")
if existing then
	existing:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "TheTakeVaultFitGui"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 220
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local launcher = Instance.new("TextButton")
launcher.Name = "FitGearLauncher"
launcher.AnchorPoint = Vector2.new(1, 0)
launcher.Position = UDim2.new(1, -22, 0, 90)
launcher.Size = UDim2.fromOffset(168, 34)
launcher.BackgroundColor3 = COLORS.wine
launcher.BorderSizePixel = 0
launcher.Font = Enum.Font.GothamBold
launcher.Text = "STUDIO  •  FIT GEAR"
launcher.TextColor3 = COLORS.text
launcher.TextSize = 11
launcher.Visible = false
launcher.ZIndex = 220
launcher.Parent = gui

local panel = Instance.new("Frame")
panel.Name = "GearFitPanel"
panel.AnchorPoint = Vector2.new(1, 0.5)
panel.Position = UDim2.new(1, -22, 0.5, 0)
panel.Size = UDim2.fromOffset(350, 640)
panel.BackgroundColor3 = COLORS.panel
panel.BackgroundTransparency = 0.03
panel.BorderSizePixel = 0
panel.Visible = false
panel.ZIndex = 221
panel.Parent = gui

local stroke = Instance.new("UIStroke")
stroke.Color = COLORS.gold
stroke.Transparency = 0.18
stroke.Thickness = 1
stroke.Parent = panel

local title = Instance.new("TextLabel")
title.Position = UDim2.fromOffset(18, 14)
title.Size = UDim2.new(1, -72, 0, 28)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.Text = "GEAR FIT MODE"
title.TextColor3 = COLORS.gold
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 222
title.Parent = panel

local studioTag = Instance.new("TextLabel")
studioTag.Position = UDim2.fromOffset(19, 41)
studioTag.Size = UDim2.new(1, -80, 0, 18)
studioTag.BackgroundTransparency = 1
studioTag.Font = Enum.Font.Gotham
studioTag.Text = "STUDIO ONLY • LIVE MANNEQUIN PREVIEW"
studioTag.TextColor3 = COLORS.cyan
studioTag.TextSize = 9
studioTag.TextXAlignment = Enum.TextXAlignment.Left
studioTag.ZIndex = 222
studioTag.Parent = panel

local closeButton = Instance.new("TextButton")
closeButton.AnchorPoint = Vector2.new(1, 0)
closeButton.Position = UDim2.new(1, -14, 0, 14)
closeButton.Size = UDim2.fromOffset(34, 28)
closeButton.BackgroundColor3 = COLORS.row
closeButton.BorderSizePixel = 0
closeButton.Font = Enum.Font.GothamBold
closeButton.Text = "X"
closeButton.TextColor3 = COLORS.text
closeButton.TextSize = 12
closeButton.ZIndex = 223
closeButton.Parent = panel

local selectedLabel = Instance.new("TextLabel")
selectedLabel.Position = UDim2.fromOffset(18, 68)
selectedLabel.Size = UDim2.new(1, -36, 0, 36)
selectedLabel.BackgroundTransparency = 1
selectedLabel.Font = Enum.Font.GothamBold
selectedLabel.Text = "SELECT GEAR TO FIT"
selectedLabel.TextColor3 = COLORS.text
selectedLabel.TextSize = 13
selectedLabel.TextWrapped = true
selectedLabel.TextXAlignment = Enum.TextXAlignment.Left
selectedLabel.TextYAlignment = Enum.TextYAlignment.Top
selectedLabel.ZIndex = 222
selectedLabel.Parent = panel

local itemList = Instance.new("ScrollingFrame")
itemList.Name = "FitItemList"
itemList.Position = UDim2.fromOffset(18, 106)
itemList.Size = UDim2.new(1, -36, 0, 120)
itemList.BackgroundColor3 = COLORS.dark
itemList.BackgroundTransparency = 0.12
itemList.BorderSizePixel = 0
itemList.ScrollBarThickness = 4
itemList.AutomaticCanvasSize = Enum.AutomaticSize.Y
itemList.CanvasSize = UDim2.new()
itemList.ZIndex = 222
itemList.Parent = panel

local itemLayout = Instance.new("UIListLayout")
itemLayout.Padding = UDim.new(0, 4)
itemLayout.SortOrder = Enum.SortOrder.LayoutOrder
itemLayout.Parent = itemList

local modeButton = Instance.new("TextButton")
modeButton.Position = UDim2.fromOffset(18, 236)
modeButton.Size = UDim2.new(1, -36, 0, 32)
modeButton.BackgroundColor3 = COLORS.row
modeButton.BorderSizePixel = 0
modeButton.Font = Enum.Font.GothamBold
modeButton.Text = "ATTACHMENT MODE"
modeButton.TextColor3 = COLORS.text
modeButton.TextSize = 11
modeButton.Active = false
modeButton.ZIndex = 222
modeButton.Parent = panel

local controlsFrame = Instance.new("Frame")
controlsFrame.Position = UDim2.fromOffset(18, 278)
controlsFrame.Size = UDim2.new(1, -36, 0, 238)
controlsFrame.BackgroundTransparency = 1
controlsFrame.ZIndex = 222
controlsFrame.Parent = panel

local controlLayout = Instance.new("UIListLayout")
controlLayout.Padding = UDim.new(0, 4)
controlLayout.SortOrder = Enum.SortOrder.LayoutOrder
controlLayout.Parent = controlsFrame

local codeBox = Instance.new("TextBox")
codeBox.Position = UDim2.fromOffset(18, 526)
codeBox.Size = UDim2.new(1, -36, 0, 58)
codeBox.BackgroundColor3 = COLORS.dark
codeBox.BackgroundTransparency = 0.04
codeBox.BorderSizePixel = 0
codeBox.ClearTextOnFocus = false
codeBox.Font = Enum.Font.Code
codeBox.MultiLine = true
codeBox.Text = "Select an item to generate VaultGearFitConfig values."
codeBox.TextColor3 = COLORS.muted
codeBox.TextEditable = false
codeBox.TextSize = 9
codeBox.TextWrapped = false
codeBox.TextXAlignment = Enum.TextXAlignment.Left
codeBox.TextYAlignment = Enum.TextYAlignment.Top
codeBox.ZIndex = 222
codeBox.Parent = panel

local resetButton = Instance.new("TextButton")
resetButton.Position = UDim2.fromOffset(18, 594)
resetButton.Size = UDim2.fromOffset(88, 30)
resetButton.BackgroundColor3 = COLORS.row
resetButton.BorderSizePixel = 0
resetButton.Font = Enum.Font.GothamBold
resetButton.Text = "RESET"
resetButton.TextColor3 = COLORS.text
resetButton.TextSize = 10
resetButton.Active = false
resetButton.ZIndex = 222
resetButton.Parent = panel

local printButton = Instance.new("TextButton")
printButton.Position = UDim2.fromOffset(114, 594)
printButton.Size = UDim2.fromOffset(108, 30)
printButton.BackgroundColor3 = COLORS.row
printButton.BorderSizePixel = 0
printButton.Font = Enum.Font.GothamBold
printButton.Text = "PRINT CONFIG"
printButton.TextColor3 = COLORS.text
printButton.TextSize = 10
printButton.Active = false
printButton.ZIndex = 222
printButton.Parent = panel

local doneButton = Instance.new("TextButton")
doneButton.AnchorPoint = Vector2.new(1, 0)
doneButton.Position = UDim2.new(1, -18, 0, 594)
doneButton.Size = UDim2.fromOffset(102, 30)
doneButton.BackgroundColor3 = COLORS.wine
doneButton.BorderSizePixel = 0
doneButton.Font = Enum.Font.GothamBold
doneButton.Text = "DONE"
doneButton.TextColor3 = COLORS.text
doneButton.TextSize = 10
doneButton.Active = false
doneButton.ZIndex = 222
doneButton.Parent = panel

local statusLabel = Instance.new("TextLabel")
statusLabel.AnchorPoint = Vector2.new(0, 1)
statusLabel.Position = UDim2.new(0, 18, 1, -4)
statusLabel.Size = UDim2.new(1, -36, 0, 14)
statusLabel.BackgroundTransparency = 1
statusLabel.Font = Enum.Font.Gotham
statusLabel.Text = ""
statusLabel.TextColor3 = COLORS.cyan
statusLabel.TextSize = 9
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.ZIndex = 222
statusLabel.Parent = panel

local session = nil
local draft = nil
local baseline = nil
local busy = false
local valueLabels = {}
local parameterButtons = {}

local PARAMETERS = {
	{key = "Scale", label = "SCALE", step = 0.02, format = function(value) return string.format("%.2f", value) end},
	{key = "OffsetX", label = "LEFT / RIGHT", step = 0.02, format = function(value) return string.format("%+.2f", value) end},
	{key = "OffsetY", label = "UP / DOWN", step = 0.02, format = function(value) return string.format("%+.2f", value) end},
	{key = "OffsetZ", label = "IN / OUT", step = 0.02, format = function(value) return string.format("%+.2f", value) end},
	{key = "RotationX", label = "PITCH", step = 2, format = function(value) return string.format("%+.0f°", value) end},
	{key = "RotationY", label = "YAW", step = 2, format = function(value) return string.format("%+.0f°", value) end},
	{key = "RotationZ", label = "ROLL", step = 2, format = function(value) return string.format("%+.0f°", value) end},
}

local function setControlsEnabled(enabled: boolean)
	modeButton.Active = enabled
	resetButton.Active = enabled
	printButton.Active = enabled
	doneButton.Active = enabled
	for _, button in ipairs(parameterButtons) do
		button.Active = enabled
		button.AutoButtonColor = enabled
	end
end

local function refreshValues()
	for _, parameter in ipairs(PARAMETERS) do
		local label = valueLabels[parameter.key]
		if label then
			local value = draft and draft[parameter.key] or 0
			label.Text = parameter.format(value)
		end
	end

	if session and draft then
		modeButton.Text = draft.UseAutoFit and "FITTER: MANUAL  •  SCALE/OFFSET ENABLED" or "ATTACHMENT: NATIVE / DEFAULT"
		modeButton.BackgroundColor3 = draft.UseAutoFit and COLORS.wine or COLORS.row
		codeBox.Text = tostring(session.Snippet or "")
		if session.NativeAccessory and not draft.UseAutoFit then
			statusLabel.Text = "Native accessory detected. Switch to MANUAL to resize/reposition it."
		else
			statusLabel.Text = "Changes update the Vault mannequin live."
		end
	else
		modeButton.Text = "ATTACHMENT MODE"
		modeButton.BackgroundColor3 = COLORS.row
		codeBox.Text = "Select an item to generate VaultGearFitConfig values."
		statusLabel.Text = ""
	end
end

local function invokeUpdate()
	if busy or not session or not draft then
		return
	end
	busy = true
	statusLabel.Text = "Updating preview..."
	local ok, success, message, result = pcall(function()
		return updateFit:InvokeServer(draft)
	end)
	busy = false
	if ok and success == true and type(result) == "table" then
		session = result
		draft = result.Draft
		refreshValues()
	else
		statusLabel.Text = "Fit update failed: " .. tostring(message or result)
	end
end

for order, parameter in ipairs(PARAMETERS) do
	local row = Instance.new("Frame")
	row.LayoutOrder = order
	row.Size = UDim2.new(1, 0, 0, 30)
	row.BackgroundColor3 = COLORS.row
	row.BackgroundTransparency = 0.12
	row.BorderSizePixel = 0
	row.ZIndex = 223
	row.Parent = controlsFrame

	local label = Instance.new("TextLabel")
	label.Position = UDim2.fromOffset(9, 0)
	label.Size = UDim2.new(1, -144, 1, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamMedium
	label.Text = parameter.label
	label.TextColor3 = COLORS.muted
	label.TextSize = 9
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.ZIndex = 224
	label.Parent = row

	local minus = Instance.new("TextButton")
	minus.AnchorPoint = Vector2.new(1, 0.5)
	minus.Position = UDim2.new(1, -92, 0.5, 0)
	minus.Size = UDim2.fromOffset(28, 24)
	minus.BackgroundColor3 = COLORS.wine
	minus.BorderSizePixel = 0
	minus.Font = Enum.Font.GothamBold
	minus.Text = "−"
	minus.TextColor3 = COLORS.text
	minus.TextSize = 14
	minus.ZIndex = 224
	minus.Parent = row

	local value = Instance.new("TextLabel")
	value.AnchorPoint = Vector2.new(1, 0.5)
	value.Position = UDim2.new(1, -36, 0.5, 0)
	value.Size = UDim2.fromOffset(52, 24)
	value.BackgroundColor3 = COLORS.dark
	value.BorderSizePixel = 0
	value.Font = Enum.Font.Code
	value.Text = parameter.format(0)
	value.TextColor3 = COLORS.gold
	value.TextSize = 10
	value.ZIndex = 224
	value.Parent = row
	valueLabels[parameter.key] = value

	local plus = Instance.new("TextButton")
	plus.AnchorPoint = Vector2.new(1, 0.5)
	plus.Position = UDim2.new(1, -4, 0.5, 0)
	plus.Size = UDim2.fromOffset(28, 24)
	plus.BackgroundColor3 = COLORS.wine
	plus.BorderSizePixel = 0
	plus.Font = Enum.Font.GothamBold
	plus.Text = "+"
	plus.TextColor3 = COLORS.text
	plus.TextSize = 13
	plus.ZIndex = 224
	plus.Parent = row

	table.insert(parameterButtons, minus)
	table.insert(parameterButtons, plus)

	minus.Activated:Connect(function()
		if not draft then
			return
		end
		draft[parameter.key] -= parameter.step
		invokeUpdate()
	end)
	plus.Activated:Connect(function()
		if not draft then
			return
		end
		draft[parameter.key] += parameter.step
		invokeUpdate()
	end)
end

setControlsEnabled(false)
refreshValues()

local function clearItemButtons()
	for _, child in ipairs(itemList:GetChildren()) do
		if not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end
end

local function beginItem(itemId: string)
	if busy then
		return
	end
	busy = true
	statusLabel.Text = "Loading item..."
	local ok, success, message, result = pcall(function()
		return beginFit:InvokeServer(itemId)
	end)
	busy = false
	if not ok or success ~= true or type(result) ~= "table" then
		statusLabel.Text = "Unable to fit item: " .. tostring(message or result)
		return
	end

	session = result
	draft = result.Draft
	baseline = result.Baseline
	selectedLabel.Text = string.upper(tostring(result.DisplayName or itemId)) .. "\n" .. GearRules.SlotLabel(tostring(result.Slot or "Vest"))
	setControlsEnabled(true)
	refreshValues()
end

local function refreshItemList()
	clearItemButtons()
	local entries = {}
	for _, entry in ipairs(index:GetChildren()) do
		if entry:IsA("Folder") and entry:GetAttribute("Category") == "Gear" and entry:GetAttribute("Enabled") ~= false then
			table.insert(entries, entry)
		end
	end
	table.sort(entries, function(a, b)
		local itemA = tostring(a:GetAttribute("ItemId") or a.Name)
		local itemB = tostring(b:GetAttribute("ItemId") or b.Name)
		local slotA = GearRules.NormalizeSlot(tostring(a:GetAttribute("GearSlot") or "Vest"), itemA)
		local slotB = GearRules.NormalizeSlot(tostring(b:GetAttribute("GearSlot") or "Vest"), itemB)
		local rankA = GearRules.SlotRank(slotA)
		local rankB = GearRules.SlotRank(slotB)
		if rankA ~= rankB then
			return rankA < rankB
		end
		return tostring(a:GetAttribute("DisplayName") or a.Name):lower() < tostring(b:GetAttribute("DisplayName") or b.Name):lower()
	end)

	for order, entry in ipairs(entries) do
		local itemId = tostring(entry:GetAttribute("ItemId") or entry.Name)
		local displayName = tostring(entry:GetAttribute("DisplayName") or entry.Name)
		local slot = GearRules.NormalizeSlot(tostring(entry:GetAttribute("GearSlot") or "Vest"), itemId)
		local button = Instance.new("TextButton")
		button.Name = "FitItem_" .. itemId
		button.LayoutOrder = order
		button.Size = UDim2.new(1, -6, 0, 30)
		button.BackgroundColor3 = COLORS.row
		button.BackgroundTransparency = 0.06
		button.BorderSizePixel = 0
		button.Font = Enum.Font.GothamMedium
		button.Text = "  " .. displayName .. "   •   " .. GearRules.SlotLabel(slot)
		button.TextColor3 = COLORS.text
		button.TextSize = 9
		button.TextXAlignment = Enum.TextXAlignment.Left
		button.ZIndex = 223
		button.Parent = itemList
		button.Activated:Connect(function()
			beginItem(itemId)
		end)
	end
end

local function closeFitPanel(printFinal: boolean)
	if busy then
		return
	end
	if session then
		busy = true
		local ok, success, _, result = pcall(function()
			return endFit:InvokeServer()
		end)
		busy = false
		if printFinal and ok and success == true and type(result) == "table" then
			print("[TheVaultFit] FINAL CONFIG for " .. tostring(result.DisplayName) .. "\n" .. tostring(result.Snippet))
		end
	end
	session = nil
	draft = nil
	baseline = nil
	selectedLabel.Text = "SELECT GEAR TO FIT"
	setControlsEnabled(false)
	refreshValues()
	panel.Visible = false
	launcher.Visible = player:GetAttribute(MENU_MODE_ATTRIBUTE) == "Vault"
end

modeButton.Activated:Connect(function()
	if not draft then
		return
	end
	draft.UseAutoFit = not draft.UseAutoFit
	invokeUpdate()
end)

resetButton.Activated:Connect(function()
	if not baseline then
		return
	end
	draft = {
		Scale = baseline.Scale,
		OffsetX = baseline.OffsetX,
		OffsetY = baseline.OffsetY,
		OffsetZ = baseline.OffsetZ,
		RotationX = baseline.RotationX,
		RotationY = baseline.RotationY,
		RotationZ = baseline.RotationZ,
		UseAutoFit = baseline.UseAutoFit == true,
	}
	invokeUpdate()
end)

printButton.Activated:Connect(function()
	if not session then
		return
	end
	print("[TheVaultFit] CONFIG for " .. tostring(session.DisplayName) .. "\n" .. tostring(session.Snippet))
	statusLabel.Text = "Config printed to Studio Output."
end)

doneButton.Activated:Connect(function()
	closeFitPanel(true)
end)

closeButton.Activated:Connect(function()
	closeFitPanel(false)
end)

launcher.Activated:Connect(function()
	refreshItemList()
	launcher.Visible = false
	panel.Visible = true
end)

local function updateVisibility()
	local inVault = player:GetAttribute(MENU_MODE_ATTRIBUTE) == "Vault"
	if not inVault and panel.Visible then
		closeFitPanel(false)
	else
		launcher.Visible = inVault and not panel.Visible
	end
end

player:GetAttributeChangedSignal(MENU_MODE_ATTRIBUTE):Connect(updateVisibility)
index.ChildAdded:Connect(refreshItemList)
index.ChildRemoved:Connect(refreshItemList)

refreshItemList()
updateVisibility()
print("[TheVaultFit] live Studio fitting UI ready")

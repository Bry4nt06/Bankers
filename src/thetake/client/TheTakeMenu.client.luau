local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local theTakeRoot = ReplicatedStorage:WaitForChild("TheTake")
local sharedFolder = theTakeRoot:WaitForChild("Shared")
local VaultCatalog = require(sharedFolder:WaitForChild("VaultCatalog"))

local CONFIG_FOLDER_NAME = "TheTakeMenuCameraConfig"
local CAMERA_READY_ATTRIBUTE = "TheTakeCameraReady"
local STARTED_ATTRIBUTE = "TheTakeGameplayStarted"
local MENU_REVEAL_DELAY = 4.75
local CINEMATIC_READY_TIMEOUT = 12

print("[TheTakeMenu] client boot started")
player:SetAttribute(STARTED_ATTRIBUTE, false)

local function setCoreGuiEnabled(enabled: boolean)
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, enabled)
	end)
end

local function setControlsEnabled(enabled: boolean)
	-- Broken deliberately delays character spawning until PLAY. Calling the
	-- default controls module before a character exists causes Player:Move
	-- warnings in Studio and is unnecessary.
	if not player.Character then
		return
	end

	local playerScripts = player:FindFirstChild("PlayerScripts")
	if not playerScripts then
		return
	end
	local playerModule = playerScripts:FindFirstChild("PlayerModule")
	if not playerModule or not playerModule:IsA("ModuleScript") then
		return
	end
	local ok, module = pcall(require, playerModule)
	if not ok or type(module) ~= "table" or type(module.GetControls) ~= "function" then
		return
	end
	local controls = module:GetControls()
	if enabled then
		controls:Enable()
	else
		controls:Disable()
	end
end

local function setCharacterLocallyHidden(character: Model?, hidden: boolean)
	if not character then
		return
	end
	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.LocalTransparencyModifier = hidden and 1 or 0
		end
	end
end

local function destroyBrokenPresentationGui()
	for _, name in ipairs({"CutsceneUI", "LoadingScreenGui"}) do
		local gui = playerGui:FindFirstChild(name)
		if gui then
			gui:Destroy()
			print("[TheTakeMenu] removed donor PlayerGui." .. name)
		end
	end
end

destroyBrokenPresentationGui()
playerGui.ChildAdded:Connect(function(child)
	if child.Name == "CutsceneUI" or child.Name == "LoadingScreenGui" then
		task.defer(function()
			if child.Parent then
				child:Destroy()
			end
		end)
	end
end)

local function startDonorGameplay()
	local spawnRemote = ReplicatedStorage:FindFirstChild("SpawnPlayer")
	if spawnRemote and spawnRemote:IsA("RemoteEvent") then
		spawnRemote:FireServer()
		print("[TheTakeMenu] fired donor SpawnPlayer RemoteEvent")
		return true
	elseif spawnRemote and spawnRemote:IsA("RemoteFunction") then
		local ok, err = pcall(function()
			spawnRemote:InvokeServer()
		end)
		if ok then
			print("[TheTakeMenu] invoked donor SpawnPlayer RemoteFunction")
			return true
		end
		warn("[TheTakeMenu] donor SpawnPlayer RemoteFunction failed: " .. tostring(err))
		return false
	end
	warn("[TheTakeMenu] donor SpawnPlayer remote missing")
	return false
end

setCoreGuiEnabled(false)
setControlsEnabled(false)
setCharacterLocallyHidden(player.Character, true)
player.CharacterAdded:Connect(function(character)
	if player:GetAttribute(STARTED_ATTRIBUTE) ~= true then
		task.defer(setCharacterLocallyHidden, character, true)
	end
end)

UserInputService.MouseBehavior = Enum.MouseBehavior.Default
UserInputService.MouseIconEnabled = true

for _, name in ipairs({"TheTakeBootGui", "TheTakeMenuGui"}) do
	local existing = playerGui:FindFirstChild(name)
	if existing then
		existing:Destroy()
	end
end

local bootGui = Instance.new("ScreenGui")
bootGui.Name = "TheTakeBootGui"
bootGui.IgnoreGuiInset = true
bootGui.ResetOnSpawn = false
bootGui.DisplayOrder = 10000
bootGui.Parent = playerGui

local bootBlackout = Instance.new("Frame")
bootBlackout.Size = UDim2.fromScale(1, 1)
bootBlackout.BackgroundColor3 = Color3.new(0, 0, 0)
bootBlackout.BorderSizePixel = 0
bootBlackout.Parent = bootGui

local function failOpen(reason: string)
	warn("[TheTakeMenu] cinematic startup failed open: " .. reason)
	player:SetAttribute(STARTED_ATTRIBUTE, true)
	setCoreGuiEnabled(true)
	setControlsEnabled(true)
	setCharacterLocallyHidden(player.Character, false)
	if bootGui.Parent then
		bootGui:Destroy()
	end
	UserInputService.MouseIconEnabled = false
	startDonorGameplay()
end

local config = ReplicatedStorage:WaitForChild(CONFIG_FOLDER_NAME, CINEMATIC_READY_TIMEOUT)
if not config then
	failOpen("camera config folder did not replicate within timeout")
	return
end

local configDeadline = os.clock() + CINEMATIC_READY_TIMEOUT
while config:GetAttribute("Ready") ~= true and os.clock() < configDeadline do
	task.wait(0.05)
end
if config:GetAttribute("Ready") ~= true then
	failOpen("camera config never became Ready")
	return
end
print("[TheTakeMenu] server camera config is ready")

local cameraDeadline = os.clock() + CINEMATIC_READY_TIMEOUT
while player:GetAttribute(CAMERA_READY_ATTRIBUTE) ~= true and os.clock() < cameraDeadline do
	task.wait(0.05)
end
if player:GetAttribute(CAMERA_READY_ATTRIBUTE) ~= true then
	failOpen("camera client never reported ready")
	return
end
print("[TheTakeMenu] camera client is ready; revealing cinematic")

local gui = Instance.new("ScreenGui")
gui.Name = "TheTakeMenuGui"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 1500
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local fade = Instance.new("Frame")
fade.Name = "Fade"
fade.Size = UDim2.fromScale(1, 1)
fade.BackgroundColor3 = Color3.new(0, 0, 0)
fade.BackgroundTransparency = 0
fade.BorderSizePixel = 0
fade.ZIndex = 100
fade.Parent = gui

local topBar = Instance.new("Frame")
topBar.Size = UDim2.fromScale(1, 0.055)
topBar.BackgroundColor3 = Color3.new(0, 0, 0)
topBar.BorderSizePixel = 0
topBar.ZIndex = 20
topBar.Parent = gui

local bottomBar = topBar:Clone()
bottomBar.Position = UDim2.fromScale(0, 0.945)
bottomBar.Parent = gui

local shade = Instance.new("Frame")
shade.Size = UDim2.fromScale(0.42, 1)
shade.BackgroundColor3 = Color3.new(0, 0, 0)
shade.BackgroundTransparency = 0.22
shade.BorderSizePixel = 0
shade.ZIndex = 2
shade.Parent = gui

local shadeGradient = Instance.new("UIGradient")
shadeGradient.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.05),
	NumberSequenceKeypoint.new(0.72, 0.6),
	NumberSequenceKeypoint.new(1, 1),
})
shadeGradient.Parent = shade

local menuFrame = Instance.new("Frame")
menuFrame.AnchorPoint = Vector2.new(0, 0.5)
menuFrame.Position = UDim2.fromScale(0.065, 0.67)
menuFrame.Size = UDim2.fromOffset(420, 245)
menuFrame.BackgroundTransparency = 1
menuFrame.ZIndex = 10
menuFrame.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 66)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBlack
title.Text = "THE TAKE"
title.TextColor3 = Color3.fromRGB(245, 245, 245)
title.TextSize = 46
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextTransparency = 1
title.ZIndex = 10
title.Parent = menuFrame

local rule = Instance.new("Frame")
rule.Position = UDim2.fromOffset(0, 72)
rule.Size = UDim2.fromOffset(0, 2)
rule.BackgroundColor3 = Color3.fromRGB(235, 235, 235)
rule.BackgroundTransparency = 0.18
rule.BorderSizePixel = 0
rule.ZIndex = 10
rule.Parent = menuFrame

local function createMenuButton(text: string, y: number)
	local button = Instance.new("TextButton")
	button.Position = UDim2.fromOffset(0, y)
	button.Size = UDim2.fromOffset(230, 42)
	button.BackgroundTransparency = 1
	button.AutoButtonColor = false
	button.Font = Enum.Font.GothamMedium
	button.Text = text
	button.TextColor3 = Color3.fromRGB(245, 245, 245)
	button.TextSize = 22
	button.TextXAlignment = Enum.TextXAlignment.Left
	button.TextTransparency = 1
	button.ZIndex = 10
	button.Parent = menuFrame

	local accent = Instance.new("Frame")
	accent.AnchorPoint = Vector2.new(0, 0.5)
	accent.Position = UDim2.new(0, -16, 0.5, 0)
	accent.Size = UDim2.fromOffset(3, 0)
	accent.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
	accent.BorderSizePixel = 0
	accent.ZIndex = 11
	accent.Parent = button

	button.MouseEnter:Connect(function()
		TweenService:Create(accent, TweenInfo.new(0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(3, 30),
		}):Play()
	end)

	button.MouseLeave:Connect(function()
		TweenService:Create(accent, TweenInfo.new(0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(3, 0),
		}):Play()
	end)

	return button
end

local playButton = createMenuButton("PLAY", 96)
local vaultButton = createMenuButton("THE VAULT", 144)

-- THE VAULT is a menu-state store. The physical Vault location will live under
-- ReplicatedStorage.TheTake.Locations.TheVault instead of Broken's round Maps.
local vaultPanel = Instance.new("Frame")
vaultPanel.Name = "TheVaultPanel"
vaultPanel.AnchorPoint = Vector2.new(1, 0.5)
vaultPanel.Position = UDim2.fromScale(0.955, 0.5)
vaultPanel.Size = UDim2.fromScale(0.58, 0.76)
vaultPanel.BackgroundColor3 = Color3.fromRGB(8, 9, 11)
vaultPanel.BackgroundTransparency = 0.04
vaultPanel.BorderSizePixel = 0
vaultPanel.Visible = false
vaultPanel.ZIndex = 30
vaultPanel.Parent = gui

local vaultStroke = Instance.new("UIStroke")
vaultStroke.Color = Color3.fromRGB(90, 94, 101)
vaultStroke.Transparency = 0.45
vaultStroke.Thickness = 1
vaultStroke.Parent = vaultPanel

local vaultTitle = Instance.new("TextLabel")
vaultTitle.Position = UDim2.fromOffset(34, 24)
vaultTitle.Size = UDim2.new(1, -160, 0, 48)
vaultTitle.BackgroundTransparency = 1
vaultTitle.Font = Enum.Font.GothamBlack
vaultTitle.Text = "THE VAULT"
vaultTitle.TextColor3 = Color3.fromRGB(245, 245, 245)
vaultTitle.TextSize = 36
vaultTitle.TextXAlignment = Enum.TextXAlignment.Left
vaultTitle.ZIndex = 31
vaultTitle.Parent = vaultPanel

local vaultSubtitle = Instance.new("TextLabel")
vaultSubtitle.Position = UDim2.fromOffset(36, 68)
vaultSubtitle.Size = UDim2.new(1, -180, 0, 28)
vaultSubtitle.BackgroundTransparency = 1
vaultSubtitle.Font = Enum.Font.Gotham
vaultSubtitle.Text = "ARMORY  /  STYLE  /  SAFEHOUSE"
vaultSubtitle.TextColor3 = Color3.fromRGB(150, 154, 162)
vaultSubtitle.TextSize = 13
vaultSubtitle.TextXAlignment = Enum.TextXAlignment.Left
vaultSubtitle.ZIndex = 31
vaultSubtitle.Parent = vaultPanel

local backButton = Instance.new("TextButton")
backButton.AnchorPoint = Vector2.new(1, 0)
backButton.Position = UDim2.new(1, -30, 0, 29)
backButton.Size = UDim2.fromOffset(92, 38)
backButton.BackgroundTransparency = 1
backButton.Font = Enum.Font.GothamMedium
backButton.Text = "BACK"
backButton.TextColor3 = Color3.fromRGB(220, 220, 220)
backButton.TextSize = 15
backButton.ZIndex = 32
backButton.Parent = vaultPanel

local divider = Instance.new("Frame")
divider.Position = UDim2.fromOffset(32, 108)
divider.Size = UDim2.new(1, -64, 0, 1)
divider.BackgroundColor3 = Color3.fromRGB(77, 80, 86)
divider.BackgroundTransparency = 0.45
divider.BorderSizePixel = 0
divider.ZIndex = 31
divider.Parent = vaultPanel

local categoryFrame = Instance.new("Frame")
categoryFrame.Position = UDim2.fromOffset(32, 128)
categoryFrame.Size = UDim2.new(0.32, -42, 1, -158)
categoryFrame.BackgroundTransparency = 1
categoryFrame.ZIndex = 31
categoryFrame.Parent = vaultPanel

local categoryLayout = Instance.new("UIListLayout")
categoryLayout.Padding = UDim.new(0, 8)
categoryLayout.FillDirection = Enum.FillDirection.Vertical
categoryLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
categoryLayout.SortOrder = Enum.SortOrder.LayoutOrder
categoryLayout.Parent = categoryFrame

local contentFrame = Instance.new("Frame")
contentFrame.Position = UDim2.new(0.34, 0, 0, 128)
contentFrame.Size = UDim2.new(0.66, -32, 1, -158)
contentFrame.BackgroundColor3 = Color3.fromRGB(16, 18, 21)
contentFrame.BackgroundTransparency = 0.08
contentFrame.BorderSizePixel = 0
contentFrame.ZIndex = 31
contentFrame.Parent = vaultPanel

local contentTitle = Instance.new("TextLabel")
contentTitle.Position = UDim2.fromOffset(28, 24)
contentTitle.Size = UDim2.new(1, -56, 0, 38)
contentTitle.BackgroundTransparency = 1
contentTitle.Font = Enum.Font.GothamBold
contentTitle.TextColor3 = Color3.fromRGB(245, 245, 245)
contentTitle.TextSize = 25
contentTitle.TextXAlignment = Enum.TextXAlignment.Left
contentTitle.ZIndex = 32
contentTitle.Parent = contentFrame

local contentDescription = Instance.new("TextLabel")
contentDescription.Position = UDim2.fromOffset(28, 70)
contentDescription.Size = UDim2.new(1, -56, 0, 62)
contentDescription.BackgroundTransparency = 1
contentDescription.Font = Enum.Font.Gotham
contentDescription.TextColor3 = Color3.fromRGB(174, 178, 185)
contentDescription.TextSize = 15
contentDescription.TextWrapped = true
contentDescription.TextXAlignment = Enum.TextXAlignment.Left
contentDescription.TextYAlignment = Enum.TextYAlignment.Top
contentDescription.ZIndex = 32
contentDescription.Parent = contentFrame

local emptyState = Instance.new("TextLabel")
emptyState.AnchorPoint = Vector2.new(0.5, 0.5)
emptyState.Position = UDim2.fromScale(0.5, 0.61)
emptyState.Size = UDim2.new(1, -70, 0, 80)
emptyState.BackgroundTransparency = 1
emptyState.Font = Enum.Font.GothamMedium
emptyState.Text = "CATALOG FOUNDATION READY\nItems and ownership will be connected next."
emptyState.TextColor3 = Color3.fromRGB(112, 116, 124)
emptyState.TextSize = 14
emptyState.TextWrapped = true
emptyState.TextXAlignment = Enum.TextXAlignment.Center
emptyState.TextYAlignment = Enum.TextYAlignment.Center
emptyState.ZIndex = 32
emptyState.Parent = contentFrame

local categoryButtons = {}
local selectedCategoryId = nil

local function selectVaultCategory(category)
	selectedCategoryId = category.id
	contentTitle.Text = category.name
	contentDescription.Text = category.description

	for id, button in pairs(categoryButtons) do
		if id == selectedCategoryId then
			button.TextColor3 = Color3.fromRGB(255, 255, 255)
			button.BackgroundTransparency = 0.82
		else
			button.TextColor3 = Color3.fromRGB(158, 162, 170)
			button.BackgroundTransparency = 1
		end
	end
end

for index, category in ipairs(VaultCatalog) do
	local button = Instance.new("TextButton")
	button.Name = category.id
	button.LayoutOrder = index
	button.Size = UDim2.new(1, 0, 0, 46)
	button.BackgroundColor3 = Color3.fromRGB(44, 47, 53)
	button.BackgroundTransparency = 1
	button.BorderSizePixel = 0
	button.AutoButtonColor = false
	button.Font = Enum.Font.GothamMedium
	button.Text = category.name
	button.TextColor3 = Color3.fromRGB(158, 162, 170)
	button.TextSize = category.id == "safehouse_furniture" and 13 or 15
	button.TextXAlignment = Enum.TextXAlignment.Left
	button.ZIndex = 32
	button.Parent = categoryFrame
	categoryButtons[category.id] = button

	button.Activated:Connect(function()
		selectVaultCategory(category)
	end)
end

if VaultCatalog[1] then
	selectVaultCategory(VaultCatalog[1])
end

local function setVaultOpen(open: boolean)
	vaultPanel.Visible = open
	menuFrame.Visible = not open
	if open then
		print("[TheVault] store opened from cinematic menu")
	else
		print("[TheVault] returned to main menu")
	end
end

vaultButton.Activated:Connect(function()
	setVaultOpen(true)
end)

backButton.Activated:Connect(function()
	setVaultOpen(false)
end)

bootGui:Destroy()
TweenService:Create(fade, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
	BackgroundTransparency = 1,
}):Play()

local function showMenu()
	TweenService:Create(title, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		TextTransparency = 0,
	}):Play()
	TweenService:Create(rule, TweenInfo.new(0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(132, 2),
	}):Play()
	TweenService:Create(playButton, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		TextTransparency = 0,
	}):Play()
	TweenService:Create(vaultButton, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		TextTransparency = 0,
	}):Play()
	print("[TheTakeMenu] THE TAKE menu revealed with THE VAULT")
end

task.delay(MENU_REVEAL_DELAY, showMenu)

local playSelected = false
playButton.Activated:Connect(function()
	if playSelected then
		return
	end
	playSelected = true
	playButton.Active = false
	vaultButton.Active = false
	vaultPanel.Visible = false

	TweenService:Create(fade, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		BackgroundTransparency = 0,
	}):Play()
	task.wait(0.6)

	player:SetAttribute(STARTED_ATTRIBUTE, true)
	setCoreGuiEnabled(true)
	setControlsEnabled(true)
	setCharacterLocallyHidden(player.Character, false)
	startDonorGameplay()

	task.wait(0.35)
	gui:Destroy()
	UserInputService.MouseIconEnabled = false
	print("[TheTakeMenu] cinematic frontend handed off to donor gameplay")
end)

print("[TheTakeMenu] integrated THE TAKE frontend ready")

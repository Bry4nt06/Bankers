local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

local CONFIG_FOLDER_NAME = "BankersMenuCameraConfig"
local MENU_REVEAL_DELAY = 4.75

local function hideCoreGui()
	for _, coreType in ipairs({
		Enum.CoreGuiType.Backpack,
		Enum.CoreGuiType.PlayerList,
		Enum.CoreGuiType.Health,
		Enum.CoreGuiType.EmotesMenu,
		Enum.CoreGuiType.Chat,
	}) do
		pcall(function()
			StarterGui:SetCoreGuiEnabled(coreType, false)
		end)
	end
end

local function hideLocalCharacter()
	local character = player.Character
	if not character then
		return
	end
	for _, descendant in character:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.LocalTransparencyModifier = 1
		elseif descendant:IsA("Decal") then
			descendant.Transparency = 1
		end
	end
end

local function setControlsEnabled(enabled: boolean)
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

local configFolder = ReplicatedStorage:WaitForChild(CONFIG_FOLDER_NAME, 10)
if not configFolder then
	warn("[BankersMenu] replicated camera config missing; UI skipped")
	return
end

if configFolder:GetAttribute("Ready") ~= true then
	local deadline = os.clock() + 10
	while configFolder:GetAttribute("Ready") ~= true and os.clock() < deadline do
		configFolder:GetAttributeChangedSignal("Ready"):Wait()
	end
end

if configFolder:GetAttribute("Ready") ~= true then
	warn("[BankersMenu] camera config never became ready; UI skipped")
	return
end

hideCoreGui()
hideLocalCharacter()
setControlsEnabled(false)

player.CharacterAdded:Connect(function()
	task.defer(hideLocalCharacter)
end)

UserInputService.MouseIconEnabled = true

local playerGui = player:WaitForChild("PlayerGui")
local oldGui = playerGui:FindFirstChild("BankersMenuGui")
if oldGui then
	oldGui:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "BankersMenuGui"
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
topBar.Name = "TopBar"
topBar.Size = UDim2.fromScale(1, 0.055)
topBar.BackgroundColor3 = Color3.new(0, 0, 0)
topBar.BorderSizePixel = 0
topBar.ZIndex = 20
topBar.Parent = gui

local bottomBar = topBar:Clone()
bottomBar.Name = "BottomBar"
bottomBar.Position = UDim2.fromScale(0, 0.945)
bottomBar.Parent = gui

local shade = Instance.new("Frame")
shade.Name = "LeftShade"
shade.Size = UDim2.fromScale(0.42, 1)
shade.BackgroundColor3 = Color3.new(0, 0, 0)
shade.BackgroundTransparency = 0.22
shade.BorderSizePixel = 0
shade.ZIndex = 2
shade.Parent = gui

local shadeGradient = Instance.new("UIGradient")
shadeGradient.Rotation = 0
shadeGradient.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.05),
	NumberSequenceKeypoint.new(0.72, 0.6),
	NumberSequenceKeypoint.new(1, 1),
})
shadeGradient.Parent = shade

local menuFrame = Instance.new("Frame")
menuFrame.Name = "Menu"
menuFrame.AnchorPoint = Vector2.new(0, 0.5)
menuFrame.Position = UDim2.fromScale(0.065, 0.68)
menuFrame.Size = UDim2.fromOffset(360, 190)
menuFrame.BackgroundTransparency = 1
menuFrame.ZIndex = 10
menuFrame.Parent = gui

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 66)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBlack
title.Text = "BANKERS"
title.TextColor3 = Color3.fromRGB(245, 245, 245)
title.TextSize = 46
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextTransparency = 1
title.ZIndex = 10
title.Parent = menuFrame

local rule = Instance.new("Frame")
rule.Name = "Rule"
rule.Position = UDim2.fromOffset(0, 72)
rule.Size = UDim2.fromOffset(0, 2)
rule.BackgroundColor3 = Color3.fromRGB(235, 235, 235)
rule.BackgroundTransparency = 0.18
rule.BorderSizePixel = 0
rule.ZIndex = 10
rule.Parent = menuFrame

local playButton = Instance.new("TextButton")
playButton.Name = "PlayButton"
playButton.Position = UDim2.fromOffset(0, 96)
playButton.Size = UDim2.fromOffset(180, 48)
playButton.BackgroundTransparency = 1
playButton.AutoButtonColor = false
playButton.Font = Enum.Font.GothamMedium
playButton.Text = "PLAY"
playButton.TextColor3 = Color3.fromRGB(245, 245, 245)
playButton.TextSize = 22
playButton.TextXAlignment = Enum.TextXAlignment.Left
playButton.TextTransparency = 1
playButton.ZIndex = 10
playButton.Parent = menuFrame

local accent = Instance.new("Frame")
accent.Name = "Accent"
accent.AnchorPoint = Vector2.new(0, 0.5)
accent.Position = UDim2.new(0, -16, 0.5, 0)
accent.Size = UDim2.fromOffset(3, 0)
accent.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
accent.BorderSizePixel = 0
accent.ZIndex = 10
accent.Parent = playButton

local menuShown = false
local playSelected = false

local function showMenu()
	if menuShown then
		return
	end
	menuShown = true
	TweenService:Create(title, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		TextTransparency = 0,
	}):Play()
	TweenService:Create(rule, TweenInfo.new(0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(132, 2),
	}):Play()
	TweenService:Create(playButton, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		TextTransparency = 0,
	}):Play()
end

TweenService:Create(fade, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
	BackgroundTransparency = 1,
}):Play()

task.delay(MENU_REVEAL_DELAY, showMenu)

playButton.MouseEnter:Connect(function()
	TweenService:Create(accent, TweenInfo.new(0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(3, 32),
	}):Play()
end)

playButton.MouseLeave:Connect(function()
	TweenService:Create(accent, TweenInfo.new(0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(3, 0),
	}):Play()
end)

playButton.Activated:Connect(function()
	if playSelected then
		return
	end
	playSelected = true
	playButton.Active = false
	TweenService:Create(fade, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		BackgroundTransparency = 0,
	}):Play()
	task.wait(0.6)
	print("[BankersMenu] PLAY selected; gameplay-place transition hook is ready")
end)

print("[BankersMenu] UI-only controller ready; BankersCameraAuthority owns CurrentCamera")

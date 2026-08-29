local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

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
menuFrame.Position = UDim2.fromScale(0.065, 0.68)
menuFrame.Size = UDim2.fromOffset(420, 190)
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

local playButton = Instance.new("TextButton")
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
accent.AnchorPoint = Vector2.new(0, 0.5)
accent.Position = UDim2.new(0, -16, 0.5, 0)
accent.Size = UDim2.fromOffset(3, 0)
accent.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
accent.BorderSizePixel = 0
accent.ZIndex = 11
accent.Parent = playButton

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
	print("[TheTakeMenu] THE TAKE PLAY menu revealed")
end

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

local playSelected = false
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

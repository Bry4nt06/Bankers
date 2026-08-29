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

player:SetAttribute(STARTED_ATTRIBUTE, false)

local function setCoreGuiEnabled(enabled: boolean)
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, enabled)
	end)
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

local function normalize(value: string): string
	return string.lower((value:gsub("%s+", "")))
end

local function findBrokenStarterScreenGui(): ScreenGui?
	local bestButton: GuiButton? = nil
	local bestScore = 0

	for _, descendant in ipairs(playerGui:GetDescendants()) do
		if descendant:IsA("GuiButton") then
			local screenGui = descendant:FindFirstAncestorOfClass("ScreenGui")
			if screenGui and screenGui.Name ~= "TheTakeMenuGui" and screenGui.Name ~= "TheTakeBootGui" then
				local score = 0
				local name = normalize(descendant.Name)
				if name == "play" or name == "playbutton" or name == "start" or name == "startbutton" then
					score += 10
			elseif string.find(name, "play", 1, true) or string.find(name, "start", 1, true) then
					score += 5
				end

				if descendant:IsA("TextButton") then
					local text = normalize(descendant.Text)
					if text == "play" or text == "start" then
						score += 12
					elseif string.find(text, "play", 1, true) or string.find(text, "start", 1, true) then
						score += 6
					end
				end

				if score > bestScore then
					bestScore = score
					bestButton = descendant
				end
			end
		end
	end

	if bestButton and bestScore >= 10 then
		return bestButton:FindFirstAncestorOfClass("ScreenGui")
	end
	return nil
end

local function suppressBrokenStarterMenu()
	local deadline = os.clock() + 20
	repeat
		local brokenMenu = findBrokenStarterScreenGui()
		if brokenMenu then
			brokenMenu.Enabled = false
			brokenMenu:SetAttribute("TheTakeSuppressed", true)
			print("[TheTakeMenu] suppressed Broken starter menu: " .. brokenMenu.Name)
			return
		end
		task.wait(0.1)
	until os.clock() >= deadline
	warn("[TheTakeMenu] Broken starter menu was not identified; donor HUD was otherwise left untouched")
end

task.spawn(suppressBrokenStarterMenu)

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

local oldBoot = playerGui:FindFirstChild("TheTakeBootGui")
if oldBoot then
	oldBoot:Destroy()
end
local oldMenu = playerGui:FindFirstChild("TheTakeMenuGui")
if oldMenu then
	oldMenu:Destroy()
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

local config = ReplicatedStorage:WaitForChild(CONFIG_FOLDER_NAME, 15)
if not config then
	warn("[TheTakeMenu] camera config missing; keeping startup blackout")
	return
end

local deadline = os.clock() + 20
while player:GetAttribute(CAMERA_READY_ATTRIBUTE) ~= true and os.clock() < deadline do
	task.wait(0.05)
end
if player:GetAttribute(CAMERA_READY_ATTRIBUTE) ~= true then
	warn("[TheTakeMenu] cinematic camera never became ready; keeping startup blackout")
	return
end

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
local function startBrokenGameplay()
	local spawnRemote = ReplicatedStorage:FindFirstChild("SpawnPlayer")
	if spawnRemote and spawnRemote:IsA("RemoteEvent") then
		spawnRemote:FireServer()
		print("[TheTakeMenu] fired donor SpawnPlayer RemoteEvent")
	elseif spawnRemote and spawnRemote:IsA("RemoteFunction") then
		local ok, err = pcall(function()
			spawnRemote:InvokeServer()
		end)
		if ok then
			print("[TheTakeMenu] invoked donor SpawnPlayer RemoteFunction")
		else
			warn("[TheTakeMenu] donor SpawnPlayer RemoteFunction failed: " .. tostring(err))
		end
	else
		warn("[TheTakeMenu] donor SpawnPlayer remote missing; gameplay handoff may require Broken start-path inspection")
	end
end

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
	startBrokenGameplay()

	task.wait(0.35)
	gui:Destroy()
	UserInputService.MouseIconEnabled = false
	print("[TheTakeMenu] cinematic frontend handed off to Broken donor gameplay")
end)

print("[TheTakeMenu] integrated THE TAKE frontend ready")

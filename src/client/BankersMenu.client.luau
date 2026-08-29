local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

local START_MARKER_NAME = "MenuCameraStart"
local END_MARKER_NAME = "MenuCameraEnd"
local INTRO_DURATION = 7.0
local START_FOV = 58
local END_FOV = 44
local CAMERA_BIND_NAME = "BankersMenuCamera"

local function getCamera(): Camera?
	local camera = workspace.CurrentCamera
	if camera then
		return camera
	end
	workspace:GetPropertyChangedSignal("CurrentCamera"):Wait()
	return workspace.CurrentCamera
end

local camera = getCamera()
if not camera then
	warn("[BankersMenu] CurrentCamera unavailable; menu camera skipped")
	return
end

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

local function findMarker(name: string): BasePart?
	local marker = workspace:FindFirstChild(name)
	if marker and marker:IsA("BasePart") then
		return marker
	end
	return nil
end

local function findRigCenter(): Vector3
	local positions = {}
	for _, descendant in workspace:GetDescendants() do
		if descendant:IsA("Model") and descendant.Name == "Rig" then
			local pivot = descendant:GetPivot()
			table.insert(positions, pivot.Position)
		end
	end
	if #positions == 0 then
		local bank = workspace:FindFirstChild("Bank")
		if bank and bank:IsA("Model") then
			return bank:GetPivot().Position
		end
		return Vector3.zero
	end
	local total = Vector3.zero
	for _, position in positions do
		total += position
	end
	return total / #positions
end

local function createRuntimeMarker(name: string, cframe: CFrame): BasePart
	local marker = Instance.new("Part")
	marker.Name = name
	marker.Size = Vector3.new(2, 2, 2)
	marker.Anchored = true
	marker.CanCollide = false
	marker.CanTouch = false
	marker.CanQuery = false
	marker.Transparency = 1
	marker.CFrame = cframe
	marker.Parent = workspace
	return marker
end

local center = findRigCenter()
local startMarker = findMarker(START_MARKER_NAME)
local endMarker = findMarker(END_MARKER_NAME)

if not startMarker then
	local fallback = CFrame.lookAt(center + Vector3.new(0, 34, 92), center + Vector3.new(0, 8, 0))
	startMarker = createRuntimeMarker(START_MARKER_NAME, fallback)
	warn("[BankersMenu] MenuCameraStart missing; using runtime fallback")
end

if not endMarker then
	local fallback = CFrame.lookAt(center + Vector3.new(0, 9, 34), center + Vector3.new(0, 4, 0))
	endMarker = createRuntimeMarker(END_MARKER_NAME, fallback)
	warn("[BankersMenu] MenuCameraEnd missing; using runtime fallback")
end

local function hideMarker(marker: BasePart)
	marker.LocalTransparencyModifier = 1
end

hideMarker(startMarker)
hideMarker(endMarker)

workspace.ChildAdded:Connect(function(child)
	if child:IsA("BasePart") and (child.Name == START_MARKER_NAME or child.Name == END_MARKER_NAME) then
		child.LocalTransparencyModifier = 1
	end
end)

hideCoreGui()
hideLocalCharacter()
setControlsEnabled(false)

player.CharacterAdded:Connect(function()
	task.defer(hideLocalCharacter)
end)

UserInputService.MouseIconEnabled = true

local gui = Instance.new("ScreenGui")
gui.Name = "BankersMenuGui"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 1500
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

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

local cameraStart = startMarker.CFrame
local cameraEnd = endMarker.CFrame
local introStartedAt = os.clock()
local introFinished = false
local menuShown = false
local playSelected = false
local parallax = Vector2.zero

camera.CameraType = Enum.CameraType.Scriptable
camera.CFrame = cameraStart
camera.FieldOfView = START_FOV

TweenService:Create(fade, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
	BackgroundTransparency = 1,
}):Play()

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

local function getMouseParallax(): Vector2
	local viewport = camera.ViewportSize
	if viewport.X <= 0 or viewport.Y <= 0 then
		return Vector2.zero
	end
	local mouse = UserInputService:GetMouseLocation()
	local normalized = Vector2.new(
		(mouse.X / viewport.X - 0.5) * 2,
		(mouse.Y / viewport.Y - 0.5) * 2
	)
	return Vector2.new(math.clamp(normalized.X, -1, 1), math.clamp(normalized.Y, -1, 1))
end

RunService:BindToRenderStep(CAMERA_BIND_NAME, Enum.RenderPriority.Camera.Value + 1, function(dt)
	if playSelected then
		return
	end

	local elapsed = os.clock() - introStartedAt
	local alpha = math.clamp(elapsed / INTRO_DURATION, 0, 1)
	local eased = TweenService:GetValue(alpha, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut)

	if not introFinished then
		camera.CFrame = cameraStart:Lerp(cameraEnd, eased)
		camera.FieldOfView = START_FOV + (END_FOV - START_FOV) * eased
		if alpha >= 0.68 then
			showMenu()
		end
		if alpha >= 1 then
			introFinished = true
		end
		return
	end

	local targetParallax = getMouseParallax()
	local smoothing = 1 - math.exp(-dt * 4.2)
	parallax = parallax:Lerp(targetParallax, smoothing)

	local now = os.clock()
	local swayX = math.sin(now * 0.38) * 0.11
	local swayY = math.sin(now * 0.29 + 0.8) * 0.07
	local translation = CFrame.new(
		parallax.X * 0.16 + swayX,
		-parallax.Y * 0.10 + swayY,
		0
	)
	local rotation = CFrame.Angles(
		math.rad(parallax.Y * 0.65),
		math.rad(-parallax.X * 1.0),
		0
	)
	camera.CFrame = cameraEnd * translation * rotation
	camera.FieldOfView = END_FOV
end)

playButton.MouseEnter:Connect(function()
	TweenService:Create(accent, TweenInfo.new(0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(3, 32),
	}):Play()
	TweenService:Create(playButton, TweenInfo.new(0.16), {
		TextColor3 = Color3.fromRGB(255, 255, 255),
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
	RunService:UnbindFromRenderStep(CAMERA_BIND_NAME)
	print("[BankersMenu] PLAY selected; gameplay-place transition hook is ready")
end)

print("[BankersMenu] cinematic menu controller ready")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

local CONFIG_NAME = "TheTakeVaultCameraConfig"
local MENU_MODE_ATTRIBUTE = "TheTakeMenuMode"
local STARTED_ATTRIBUTE = "TheTakeGameplayStarted"
local BIND_NAME = "TheTakeVaultCameraAuthority"
local CAMERA_PRIORITY = Enum.RenderPriority.Last.Value + 10

local ENTRY_DURATION = 0.75
local SETTLE_DURATION = 1.15
local VAULT_FOV_START = 53
local VAULT_FOV_END = 46
local POINTER_RESPONSE = 7.5
local PARALLAX_X = 0.55
local PARALLAX_Y = 0.30
local PARALLAX_YAW = 1.0
local PARALLAX_PITCH = 0.55

local config = ReplicatedStorage:WaitForChild(CONFIG_NAME, 20)
if not config then
	warn("[TheVault] camera config missing")
	return
end

local deadline = os.clock() + 20
while config:GetAttribute("Ready") ~= true and os.clock() < deadline do
	task.wait(0.05)
end
if config:GetAttribute("Ready") ~= true then
	warn("[TheVault] camera config never became ready")
	return
end

local startValue = config:WaitForChild("Start")
local endValue = config:WaitForChild("End")
local avatarStandValue = config:WaitForChild("AvatarStand")

if not startValue:IsA("CFrameValue") or not endValue:IsA("CFrameValue") or not avatarStandValue:IsA("CFrameValue") then
	warn("[TheVault] invalid camera/avatar markers")
	return
end

local vaultStart = startValue.Value
local vaultEnd = endValue.Value
local avatarStand = avatarStandValue.Value

local vaultOpen = false
local entryStartedAt = 0
local entryFromCFrame = camera.CFrame
local entryFromFov = camera.FieldOfView
local neutralMouse = UserInputService:GetMouseLocation()
local smoothedX = 0
local smoothedY = 0
local avatarRig: Model? = nil

local function requestVaultStream()
	if workspace.StreamingEnabled then
		pcall(function()
			player:RequestStreamAroundAsync(vaultEnd.Position, 5)
		end)
	end
end

local function disableRigBehavior(rig: Model)
	for _, descendant in ipairs(rig:GetDescendants()) do
		if descendant:IsA("Script") or descendant:IsA("LocalScript") then
			descendant.Enabled = false
		elseif descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
		elseif descendant:IsA("Sound") then
			descendant.SoundId = ""
			descendant.Volume = 0
		end
	end

	local humanoid = rig:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	end
end

local function createAvatarDisplay()
	if avatarRig and avatarRig.Parent then
		return
	end

	local okDescription, description = pcall(function()
		return Players:GetHumanoidDescriptionFromUserId(player.UserId)
	end)
	if not okDescription or not description then
		warn("[TheVault] could not load player avatar description")
		return
	end

	local okRig, rig = pcall(function()
		return Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)
	end)
	if not okRig or not rig then
		warn("[TheVault] could not create player avatar display rig")
		return
	end

	rig.Name = "TheTakeVaultAvatar_" .. player.UserId
	disableRigBehavior(rig)
	rig.Parent = workspace

	local _, bounds = rig:GetBoundingBox()
	rig:PivotTo(avatarStand * CFrame.new(0, math.max(bounds.Y * 0.5, 2.5), 0))
	avatarRig = rig
	print("[TheVault] player avatar display ready")
end

local function styleVaultPanel(panel: Frame)
	panel.AnchorPoint = Vector2.new(0, 0.5)
	panel.Position = UDim2.fromScale(0.035, 0.5)
	panel.Size = UDim2.fromScale(0.43, 0.76)
	panel.BackgroundColor3 = Color3.fromRGB(19, 25, 68)
	panel.BackgroundTransparency = 0.08

	for _, descendant in ipairs(panel:GetDescendants()) do
		if descendant:IsA("UIStroke") then
			descendant.Color = Color3.fromRGB(183, 113, 50)
			descendant.Transparency = 0.22
		elseif descendant:IsA("TextLabel") or descendant:IsA("TextButton") then
			local upper = string.upper(descendant.Text or "")
			if upper == "THE VAULT" then
				descendant.TextColor3 = Color3.fromRGB(236, 179, 78)
			elseif upper == "BACK" then
				descendant.TextColor3 = Color3.fromRGB(77, 210, 218)
			end
		elseif descendant:IsA("Frame") and descendant ~= panel and descendant.BackgroundTransparency < 0.5 then
			if descendant.AbsoluteSize.X > panel.AbsoluteSize.X * 0.45 then
				descendant.BackgroundColor3 = Color3.fromRGB(74, 23, 67)
			else
				descendant.BackgroundColor3 = Color3.fromRGB(24, 54, 82)
			end
		end
	end
end

local function setVaultOpen(open: boolean)
	if vaultOpen == open then
		return
	end
	vaultOpen = open
	player:SetAttribute(MENU_MODE_ATTRIBUTE, open and "Vault" or "Main")

	if open then
		requestVaultStream()
		createAvatarDisplay()
		entryStartedAt = os.clock()
		entryFromCFrame = camera.CFrame
		entryFromFov = camera.FieldOfView
		neutralMouse = UserInputService:GetMouseLocation()
		smoothedX = 0
		smoothedY = 0
		print("[TheVault] entering 3D showroom")
	else
		print("[TheVault] returning camera authority to main menu")
	end
end

player:SetAttribute(MENU_MODE_ATTRIBUTE, "Main")

RunService:UnbindFromRenderStep(BIND_NAME)
RunService:BindToRenderStep(BIND_NAME, CAMERA_PRIORITY, function(dt)
	if player:GetAttribute(STARTED_ATTRIBUTE) == true or not vaultOpen then
		return
	end

	camera.CameraType = Enum.CameraType.Scriptable
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	UserInputService.MouseIconEnabled = true

	local elapsed = os.clock() - entryStartedAt
	if elapsed < ENTRY_DURATION then
		local alpha = TweenService:GetValue(math.clamp(elapsed / ENTRY_DURATION, 0, 1), Enum.EasingStyle.Quint, Enum.EasingDirection.InOut)
		camera.CFrame = entryFromCFrame:Lerp(vaultStart, alpha)
		camera.FieldOfView = entryFromFov + (VAULT_FOV_START - entryFromFov) * alpha
		return
	end

	if elapsed < ENTRY_DURATION + SETTLE_DURATION then
		local settleElapsed = elapsed - ENTRY_DURATION
		local alpha = TweenService:GetValue(math.clamp(settleElapsed / SETTLE_DURATION, 0, 1), Enum.EasingStyle.Quint, Enum.EasingDirection.InOut)
		camera.CFrame = vaultStart:Lerp(vaultEnd, alpha)
		camera.FieldOfView = VAULT_FOV_START + (VAULT_FOV_END - VAULT_FOV_START) * alpha
		neutralMouse = UserInputService:GetMouseLocation()
		return
	end

	local viewport = camera.ViewportSize
	local mouse = UserInputService:GetMouseLocation()
	local targetX = 0
	local targetY = 0
	if viewport.X > 0 and viewport.Y > 0 then
		targetX = math.clamp((mouse.X - neutralMouse.X) / math.max(viewport.X * 0.5, 1), -1, 1)
		targetY = math.clamp((mouse.Y - neutralMouse.Y) / math.max(viewport.Y * 0.5, 1), -1, 1)
	end

	local response = 1 - math.exp(-POINTER_RESPONSE * math.max(dt, 0))
	smoothedX += (targetX - smoothedX) * response
	smoothedY += (targetY - smoothedY) * response

	camera.CFrame = vaultEnd
		* CFrame.new(smoothedX * PARALLAX_X, -smoothedY * PARALLAX_Y, 0)
		* CFrame.Angles(math.rad(-smoothedY * PARALLAX_PITCH), math.rad(-smoothedX * PARALLAX_YAW), 0)
	camera.FieldOfView = VAULT_FOV_END
end)

local function watchMenuGui(gui: ScreenGui)
	local panel = gui:FindFirstChild("TheVaultPanel", true)
	if not panel or not panel:IsA("Frame") then
		return
	end

	styleVaultPanel(panel)
	setVaultOpen(panel.Visible)
	panel:GetPropertyChangedSignal("Visible"):Connect(function()
		setVaultOpen(panel.Visible)
	end)
end

local existingMenu = playerGui:FindFirstChild("TheTakeMenuGui")
if existingMenu and existingMenu:IsA("ScreenGui") then
	task.defer(watchMenuGui, existingMenu)
end

playerGui.ChildAdded:Connect(function(child)
	if child.Name == "TheTakeMenuGui" and child:IsA("ScreenGui") then
		task.defer(watchMenuGui, child)
	end
end)

print("[TheVault] 3D showroom client ready")

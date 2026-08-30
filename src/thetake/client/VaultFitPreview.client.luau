local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

if not RunService:IsStudio() then
	return
end

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local theTake = ReplicatedStorage:WaitForChild("TheTake")
local shared = theTake:WaitForChild("Shared")
local Renderer = require(shared:WaitForChild("WearableSkinRenderer"))
local previewRoot = theTake:WaitForChild("VaultFitPreviewModels", 20)
if not previewRoot then
	warn("[TheVaultFitPreview] preview model root missing")
	return
end

local MENU_MODE_ATTRIBUTE = "TheTakeMenuMode"
local FIT_ACTIVE_ATTRIBUTE = "VaultFitActive"
local FIT_REVISION_ATTRIBUTE = "VaultFitRevision"
local FIT_SLOT_ATTRIBUTE = "VaultFitSlot"
local AVATAR_NAME = "TheTakeVaultAvatar_" .. player.UserId

local COLORS = {
	panel = Color3.fromRGB(19, 25, 68),
	row = Color3.fromRGB(24, 54, 82),
	wine = Color3.fromRGB(108, 24, 60),
	gold = Color3.fromRGB(236, 179, 78),
	text = Color3.fromRGB(245, 245, 245),
	muted = Color3.fromRGB(157, 178, 194),
}

local previewGeneration = 0
local currentRig: Model? = nil
local basePivot: CFrame? = nil
local avatarYaw = 0
local hadActiveFit = false

local function findAvatarRig(): Model?
	local rig = Workspace:FindFirstChild(AVATAR_NAME)
	if rig and rig:IsA("Model") then
		return rig
	end
	return nil
end

local function rememberBasePivot(rig: Model)
	if currentRig ~= rig then
		currentRig = rig
		basePivot = rig:GetPivot()
	end
end

local function applyAvatarYaw(rig: Model?)
	if not rig then
		return
	end
	rememberBasePivot(rig)
	if basePivot then
		rig:PivotTo(basePivot * CFrame.Angles(0, math.rad(avatarYaw), 0))
	end
end

local function previewTemplate(): Instance?
	local folder = previewRoot:FindFirstChild(tostring(player.UserId))
	if not folder or not folder:IsA("Folder") then
		return nil
	end
	return folder:FindFirstChild("Gear")
end

local function applyCurrentPreview(generation: number)
	if generation ~= previewGeneration or player:GetAttribute(FIT_ACTIVE_ATTRIBUTE) ~= true then
		return
	end

	local rig = findAvatarRig()
	local template = previewTemplate()
	if not rig or not template then
		-- The mannequin and replicated preview model can arrive a frame apart.
		task.delay(0.05, function()
			if generation == previewGeneration then
				applyCurrentPreview(generation)
			end
		end)
		return
	end

	rememberBasePivot(rig)
	Renderer.Clear(rig)
	local slot = tostring(player:GetAttribute(FIT_SLOT_ATTRIBUTE) or template:GetAttribute("GearSlot") or "Vest")
	local success = Renderer.ApplyGear(rig, template, slot)
	if not success then
		warn(string.format("[TheVaultFitPreview] could not render %s in slot %s", tostring(template:GetAttribute("VaultItemId") or template.Name), slot))
	end
	applyAvatarYaw(rig)
end

local function requestNormalShowroomRestore()
	local rig = findAvatarRig()
	if rig then
		Renderer.Clear(rig)
	end
	avatarYaw = 0
	currentRig = nil
	basePivot = nil

	-- VaultExperience already owns the canonical mannequin rebuild path. A local
	-- revision bump asks it to rebuild from the player's real equipped wardrobe
	-- without touching server profile state.
	player:SetAttribute("VaultGearRevision", (tonumber(player:GetAttribute("VaultGearRevision")) or 0) + 1)
end

local function refreshFitPreview()
	previewGeneration += 1
	local generation = previewGeneration
	local active = player:GetAttribute(FIT_ACTIVE_ATTRIBUTE) == true
	if active then
		hadActiveFit = true
		task.defer(applyCurrentPreview, generation)
	elseif hadActiveFit then
		hadActiveFit = false
		requestNormalShowroomRestore()
	end
end

player:GetAttributeChangedSignal(FIT_REVISION_ATTRIBUTE):Connect(refreshFitPreview)
player:GetAttributeChangedSignal(FIT_ACTIVE_ATTRIBUTE):Connect(refreshFitPreview)

Workspace.ChildAdded:Connect(function(child)
	if child.Name ~= AVATAR_NAME or not child:IsA("Model") then
		return
	end
	currentRig = child
	basePivot = child:GetPivot()
	if player:GetAttribute(FIT_ACTIVE_ATTRIBUTE) == true then
		previewGeneration += 1
		local generation = previewGeneration
		task.delay(0.05, function()
			applyCurrentPreview(generation)
		end)
	else
		applyAvatarYaw(child)
	end
end)

-- Add turn controls to the existing Studio fit UI without changing the main
-- Vault layout. They stay near the mannequin and only appear while Fit Mode is open.
local fitGui = playerGui:WaitForChild("TheTakeVaultFitGui", 20)
if fitGui and fitGui:IsA("ScreenGui") then
	local fitPanel = fitGui:WaitForChild("GearFitPanel", 20)
	if fitPanel and fitPanel:IsA("Frame") then
		local old = fitGui:FindFirstChild("VaultAvatarTurnBar")
		if old then
			old:Destroy()
		end

		local turnBar = Instance.new("Frame")
		turnBar.Name = "VaultAvatarTurnBar"
		turnBar.AnchorPoint = Vector2.new(0.5, 1)
		turnBar.Position = UDim2.new(0.62, 0, 1, -24)
		turnBar.Size = UDim2.fromOffset(292, 38)
		turnBar.BackgroundColor3 = COLORS.panel
		turnBar.BackgroundTransparency = 0.05
		turnBar.BorderSizePixel = 0
		turnBar.Visible = false
		turnBar.ZIndex = 230
		turnBar.Parent = fitGui

		local stroke = Instance.new("UIStroke")
		stroke.Color = COLORS.gold
		stroke.Transparency = 0.25
		stroke.Thickness = 1
		stroke.Parent = turnBar

		local function makeButton(name: string, text: string, x: number, width: number)
			local button = Instance.new("TextButton")
			button.Name = name
			button.Position = UDim2.fromOffset(x, 5)
			button.Size = UDim2.fromOffset(width, 28)
			button.BackgroundColor3 = COLORS.row
			button.BorderSizePixel = 0
			button.Font = Enum.Font.GothamBold
			button.Text = text
			button.TextColor3 = COLORS.text
			button.TextSize = 10
			button.ZIndex = 231
			button.Parent = turnBar
			return button
		end

		local left = makeButton("TurnLeft", "◀  TURN", 5, 88)
		local front = makeButton("TurnFront", "FRONT", 99, 88)
		local right = makeButton("TurnRight", "TURN  ▶", 193, 94)
		front.BackgroundColor3 = COLORS.wine

		local function rotateBy(delta: number)
			avatarYaw = (avatarYaw + delta) % 360
			applyAvatarYaw(findAvatarRig())
		end

		left.Activated:Connect(function()
			rotateBy(-15)
		end)
		front.Activated:Connect(function()
			avatarYaw = 0
			applyAvatarYaw(findAvatarRig())
		end)
		right.Activated:Connect(function()
			rotateBy(15)
		end)

		local function updateTurnBarVisibility()
			turnBar.Visible = fitPanel.Visible and player:GetAttribute(MENU_MODE_ATTRIBUTE) == "Vault"
		end
		fitPanel:GetPropertyChangedSignal("Visible"):Connect(updateTurnBarVisibility)
		player:GetAttributeChangedSignal(MENU_MODE_ATTRIBUTE):Connect(updateTurnBarVisibility)
		updateTurnBarVisibility()
	end
end

refreshFitPreview()
print("[TheVaultFitPreview] isolated mannequin preview + turn controls ready")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local shared = ReplicatedStorage:WaitForChild("BankersPvP")
local PvPConfig = require(shared:WaitForChild("PvPConfig"))
local movement = PvPConfig.Movement
local cameraConfig = PvPConfig.Camera

local character: Model? = nil
local humanoid: Humanoid? = nil
local root: BasePart? = nil
local sprintHeld = false
local crouched = false
local sliding = false
local slideStartedAt = 0
local slideCooldownUntil = 0
local slideDirection = Vector3.zero
local defaultCameraOffset = Vector3.zero

local function grounded(): boolean
	return humanoid ~= nil and humanoid.FloorMaterial ~= Enum.Material.Air
end

local function setCrouched(value: boolean)
	crouched = value and not sliding
	player:SetAttribute("PvPCrouched", crouched)
	if humanoid then
		humanoid.CameraOffset = crouched and cameraConfig.CrouchOffset or defaultCameraOffset
	end
end

local function beginSlide()
	if sliding or not humanoid or not root then
		return
	end
	local now = os.clock()
	if now < slideCooldownUntil or not grounded() then
		return
	end
	local moveDirection = humanoid.MoveDirection
	if moveDirection.Magnitude < 0.2 then
		return
	end

	sliding = true
	crouched = false
	player:SetAttribute("PvPSliding", true)
	player:SetAttribute("PvPCrouched", false)
	humanoid.CameraOffset = Vector3.new(0, -1.3, 0)
	slideStartedAt = now
	slideCooldownUntil = now + movement.SlideCooldown
	slideDirection = Vector3.new(moveDirection.X, 0, moveDirection.Z).Unit
end

local function endSlide()
	if not sliding then
		return
	end
	sliding = false
	player:SetAttribute("PvPSliding", false)
	if humanoid then
		humanoid.CameraOffset = defaultCameraOffset
	end
end

local function bindCharacter(newCharacter: Model)
	character = newCharacter
	humanoid = newCharacter:WaitForChild("Humanoid", 10) :: Humanoid?
	root = newCharacter:WaitForChild("HumanoidRootPart", 10) :: BasePart?
	if not humanoid or not root then
		return
	end
	defaultCameraOffset = humanoid.CameraOffset
	humanoid.UseJumpPower = true
	humanoid.JumpPower = movement.JumpPower
	sprintHeld = false
	crouched = false
	sliding = false
	player:SetAttribute("PvPSprinting", false)
	player:SetAttribute("PvPCrouched", false)
	player:SetAttribute("PvPSliding", false)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.LeftShift then
		sprintHeld = true
	elseif input.KeyCode == Enum.KeyCode.C or input.KeyCode == Enum.KeyCode.LeftControl then
		if sprintHeld and humanoid and humanoid.MoveDirection.Magnitude > 0.2 then
			beginSlide()
		else
			setCrouched(not crouched)
		end
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.LeftShift then
		sprintHeld = false
	end
end)

RunService.Heartbeat:Connect(function()
	if not humanoid or not root or humanoid.Health <= 0 then
		return
	end

	if sliding then
		local elapsed = os.clock() - slideStartedAt
		local alpha = math.clamp(elapsed / movement.SlideDuration, 0, 1)
		local speed = movement.SlideSpeed + (movement.SlideEndSpeed - movement.SlideSpeed) * alpha
		local velocity = root.AssemblyLinearVelocity
		root.AssemblyLinearVelocity = Vector3.new(slideDirection.X * speed, velocity.Y, slideDirection.Z * speed)
		humanoid.WalkSpeed = 0
		if alpha >= 1 or not grounded() then
			endSlide()
		end
		return
	end

	local ads = player:GetAttribute("PvPADS") == true
	local tryingToSprint = sprintHeld and not crouched and not ads and humanoid.MoveDirection.Magnitude > 0.1
	player:SetAttribute("PvPSprinting", tryingToSprint)

	local speed
	if crouched then
		speed = movement.CrouchSpeed
	elseif tryingToSprint then
		speed = movement.SprintSpeed
	else
		speed = movement.WalkSpeed
	end
	if ads then
		speed *= movement.ADSMoveMultiplier
	end
	humanoid.WalkSpeed = speed
end)

RunService:BindToRenderStep("BankersPvPFov", Enum.RenderPriority.Camera.Value + 2, function(dt)
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local targetFov = cameraConfig.BaseFov
	if player:GetAttribute("PvPADS") == true then
		targetFov = cameraConfig.ADSFov
	elseif player:GetAttribute("PvPSprinting") == true then
		targetFov = cameraConfig.SprintFov
	end
	local response = 1 - math.exp(-10 * math.max(dt, 0))
	camera.FieldOfView += (targetFov - camera.FieldOfView) * response
end)

if player.Character then
	task.defer(bindCharacter, player.Character)
end
player.CharacterAdded:Connect(bindCharacter)

print("[BankersPvP] movement ready: Shift sprint | C/Ctrl crouch-slide")

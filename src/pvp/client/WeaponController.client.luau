local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local shared = ReplicatedStorage:WaitForChild("BankersPvP")
local PvPConfig = require(shared:WaitForChild("PvPConfig"))
local WeaponConfig = require(shared:WaitForChild("WeaponConfig"))
local remotes = ReplicatedStorage:WaitForChild("BankersPvPRemotes")
local fireWeapon = remotes:WaitForChild("FireWeapon")
local reloadWeapon = remotes:WaitForChild("ReloadWeapon")
local shotFx = remotes:WaitForChild("ShotFX")

local activeTool: Tool? = nil
local activeConfig = nil
local fireHeld = false
local adsHeld = false
local lastLocalShot = 0
local recoil = Vector2.zero
local previousMinZoom = player.CameraMinZoomDistance
local previousMaxZoom = player.CameraMaxZoomDistance

local function currentHumanoid(): Humanoid?
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid") or nil
end

local function currentRoot(): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return root and root:IsA("BasePart") and root or nil
end

local function setADS(enabled: boolean)
	adsHeld = enabled and activeTool ~= nil and player:GetAttribute("PvPSliding") ~= true
	player:SetAttribute("PvPADS", adsHeld)
	if activeTool then
		local cameraConfig = PvPConfig.Camera
		if adsHeld then
			player.CameraMinZoomDistance = cameraConfig.ADSZoomMin
			player.CameraMaxZoomDistance = cameraConfig.ADSZoomMax
		else
			player.CameraMinZoomDistance = cameraConfig.HipZoomMin
			player.CameraMaxZoomDistance = cameraConfig.HipZoomMax
		end
	end
end

local function equipTool(tool: Tool)
	if tool:GetAttribute("BankersWeapon") ~= true then
		return
	end
	activeTool = tool
	local weaponId = tool:GetAttribute("WeaponId")
	activeConfig = type(weaponId) == "string" and WeaponConfig[weaponId] or nil
	if not activeConfig then
		activeTool = nil
		return
	end
	previousMinZoom = player.CameraMinZoomDistance
	previousMaxZoom = player.CameraMaxZoomDistance
	player.CameraMinZoomDistance = PvPConfig.Camera.HipZoomMin
	player.CameraMaxZoomDistance = PvPConfig.Camera.HipZoomMax
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	UserInputService.MouseIconEnabled = false
	local humanoid = currentHumanoid()
	if humanoid then
		humanoid.AutoRotate = false
	end
end

local function unequipTool(tool: Tool)
	if activeTool ~= tool then
		return
	end
	fireHeld = false
	setADS(false)
	activeTool = nil
	activeConfig = nil
	recoil = Vector2.zero
	player.CameraMinZoomDistance = previousMinZoom
	player.CameraMaxZoomDistance = previousMaxZoom
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	UserInputService.MouseIconEnabled = true
	local humanoid = currentHumanoid()
	if humanoid then
		humanoid.AutoRotate = true
		humanoid.CameraOffset = player:GetAttribute("PvPCrouched") == true and PvPConfig.Camera.CrouchOffset or Vector3.zero
	end
end

local registered = {}
local function registerTool(instance: Instance)
	if not instance:IsA("Tool") or instance:GetAttribute("BankersWeapon") ~= true or registered[instance] then
		return
	end
	registered[instance] = true
	instance.Equipped:Connect(function()
		equipTool(instance)
	end)
	instance.Unequipped:Connect(function()
		unequipTool(instance)
	end)
	instance.Destroying:Connect(function()
		registered[instance] = nil
		if activeTool == instance then
			unequipTool(instance)
		end
	end)
end

local function scanTools()
	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		for _, child in ipairs(backpack:GetChildren()) do
			registerTool(child)
		end
	end
	if player.Character then
		for _, child in ipairs(player.Character:GetChildren()) do
			registerTool(child)
		end
	end
end

local function fireOnce()
	if not activeTool or not activeConfig then
		return
	end
	if activeTool:GetAttribute("Reloading") == true then
		return
	end
	if player:GetAttribute("PvPSprinting") == true or player:GetAttribute("PvPSliding") == true then
		return
	end
	local ammo = activeTool:GetAttribute("Ammo")
	if type(ammo) ~= "number" or ammo <= 0 then
		return
	end

	local now = os.clock()
	local interval = 60 / activeConfig.RPM
	if now - lastLocalShot < interval then
		return
	end
	lastLocalShot = now

	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local viewport = camera.ViewportSize
	local ray = camera:ViewportPointToRay(viewport.X * 0.5, viewport.Y * 0.5)
	fireWeapon:FireServer(ray.Direction.Unit)

	local pitch = activeConfig.RecoilPitchDegrees
	local yaw = Random.new():NextNumber(-activeConfig.RecoilYawDegrees, activeConfig.RecoilYawDegrees)
	recoil += Vector2.new(pitch, yaw)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed or not activeTool then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		fireHeld = true
		fireOnce()
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
		setADS(true)
	elseif input.KeyCode == Enum.KeyCode.R then
		reloadWeapon:FireServer()
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		fireHeld = false
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
		setADS(false)
	end
end)

RunService.Heartbeat:Connect(function()
	if fireHeld and activeConfig and activeConfig.Automatic then
		fireOnce()
	end
end)

RunService:BindToRenderStep("BankersPvPWeaponCamera", Enum.RenderPriority.Camera.Value + 4, function(dt)
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end

	if activeTool then
		local humanoid = currentHumanoid()
		local root = currentRoot()
		if humanoid and root and humanoid.Health > 0 then
			local yOffset = 0
			if player:GetAttribute("PvPSliding") == true then
				yOffset = -1.25
			elseif player:GetAttribute("PvPCrouched") == true then
				yOffset = PvPConfig.Camera.CrouchOffset.Y
			end
			humanoid.CameraOffset = PvPConfig.Camera.ShoulderOffset + Vector3.new(0, yOffset, 0)

			local look = camera.CFrame.LookVector
			local flat = Vector3.new(look.X, 0, look.Z)
			if flat.Magnitude > 0.001 then
				root.CFrame = CFrame.lookAt(root.Position, root.Position + flat.Unit)
			end
		end
	end

	if activeConfig then
		local recovery = 1 - math.exp(-activeConfig.RecoilRecovery * math.max(dt, 0))
		recoil = recoil:Lerp(Vector2.zero, recovery)
		camera.CFrame = camera.CFrame * CFrame.Angles(math.rad(recoil.X), math.rad(recoil.Y), 0)
	end
end)

local function drawTracer(origin, hitPosition)
	if typeof(origin) ~= "Vector3" or typeof(hitPosition) ~= "Vector3" then
		return
	end
	local distance = (hitPosition - origin).Magnitude
	if distance <= 0.05 then
		return
	end
	local tracer = Instance.new("Part")
	tracer.Name = "BankersTracer"
	tracer.Anchored = true
	tracer.CanCollide = false
	tracer.CanTouch = false
	tracer.CanQuery = false
	tracer.Material = Enum.Material.Neon
	tracer.Color = Color3.fromRGB(240, 220, 155)
	tracer.Transparency = 0.18
	tracer.Size = Vector3.new(0.05, 0.05, distance)
	tracer.CFrame = CFrame.lookAt((origin + hitPosition) * 0.5, hitPosition)
	tracer.Parent = workspace
	Debris:AddItem(tracer, 0.045)
end

shotFx.OnClientEvent:Connect(function(_, origin, hitPosition)
	drawTracer(origin, hitPosition)
end)

local backpack = player:WaitForChild("Backpack")
backpack.ChildAdded:Connect(registerTool)
if player.Character then
	player.Character.ChildAdded:Connect(registerTool)
end
player.CharacterAdded:Connect(function(character)
	activeTool = nil
	activeConfig = nil
	fireHeld = false
	setADS(false)
	character.ChildAdded:Connect(registerTool)
	task.defer(scanTools)
end)

task.defer(scanTools)
print("[BankersPvP] weapon controller ready: LMB fire | RMB ADS | R reload")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

Players.CharacterAutoLoads = false

local START_MARKER_NAME = "MenuCameraStart"
local END_MARKER_NAME = "MenuCameraEnd"
local CONFIG_FOLDER_NAME = "BankersMenuCameraConfig"

local function isDisplayVehicleModel(instance: Instance): boolean
	if not instance:IsA("Model") then
		return false
	end

	local lowerName = string.lower(instance.Name)
	return string.find(lowerName, "armored truck", 1, true) ~= nil
end

local function findDisplayVehicleAncestor(instance: Instance): Model?
	local current: Instance? = instance
	while current and current ~= workspace do
		if current:IsA("Model") and isDisplayVehicleModel(current) then
			return current
		end
		current = current.Parent
	end
	return nil
end

local function freezeModel(model: Model)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.AutoRotate = false
		humanoid.BreakJointsOnDeath = false
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end

	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.AssemblyLinearVelocity = Vector3.zero
			descendant.AssemblyAngularVelocity = Vector3.zero
		end
	end
end

local function freezeVehiclesFolder(folder: Instance)
	for _, descendant in folder:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.AssemblyLinearVelocity = Vector3.zero
			descendant.AssemblyAngularVelocity = Vector3.zero
		end
	end
end

local function stabilizeScene()
	for _, descendant in workspace:GetDescendants() do
		if descendant:IsA("Model") and descendant.Name == "Rig" then
			freezeModel(descendant)
		end
	end

	local vehiclesFolder = workspace:FindFirstChild("Vehicles")
	if vehiclesFolder then
		freezeVehiclesFolder(vehiclesFolder)
	end

	for _, child in workspace:GetChildren() do
		if isDisplayVehicleModel(child) then
			freezeModel(child)
		end
	end
end

local function keepPlayerOutOfScene(player: Player)
	if player.Character then
		player.Character:Destroy()
	end
	player.CharacterAdded:Connect(function(character)
		character:Destroy()
	end)
end

local function publishCameraConfig()
	local folder = ReplicatedStorage:FindFirstChild(CONFIG_FOLDER_NAME)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = CONFIG_FOLDER_NAME
		folder.Parent = ReplicatedStorage
	end

	local startValue = folder:FindFirstChild("Start")
	if not startValue then
		startValue = Instance.new("CFrameValue")
		startValue.Name = "Start"
		startValue.Parent = folder
	end

	local endValue = folder:FindFirstChild("End")
	if not endValue then
		endValue = Instance.new("CFrameValue")
		endValue.Name = "End"
		endValue.Parent = folder
	end

	local startMarker = workspace:FindFirstChild(START_MARKER_NAME)
	local endMarker = workspace:FindFirstChild(END_MARKER_NAME)
	local startReady = startMarker ~= nil and startMarker:IsA("BasePart")
	local endReady = endMarker ~= nil and endMarker:IsA("BasePart")

	if startReady then
		(startValue :: CFrameValue).Value = (startMarker :: BasePart).CFrame
	else
		warn("[BankersMenu] server could not find MenuCameraStart in Workspace")
	end

	if endReady then
		(endValue :: CFrameValue).Value = (endMarker :: BasePart).CFrame
	else
		warn("[BankersMenu] server could not find MenuCameraEnd in Workspace")
	end

	folder:SetAttribute("Ready", startReady and endReady)
	print("[BankersMenu] camera CFrames published to ReplicatedStorage")
end

for _, player in Players:GetPlayers() do
	keepPlayerOutOfScene(player)
end
Players.PlayerAdded:Connect(keepPlayerOutOfScene)

stabilizeScene()
publishCameraConfig()

task.delay(1, function()
	stabilizeScene()
	publishCameraConfig()
end)

task.delay(3, stabilizeScene)

workspace.DescendantAdded:Connect(function(descendant)
	if descendant:IsA("Model") and descendant.Name == "Rig" then
		task.defer(freezeModel, descendant)
		return
	end

	if descendant:IsA("BasePart") then
		if descendant.Name == START_MARKER_NAME or descendant.Name == END_MARKER_NAME then
			task.defer(publishCameraConfig)
			return
		end

		local vehicle = findDisplayVehicleAncestor(descendant)
		if vehicle then
			descendant.Anchored = true
			descendant.AssemblyLinearVelocity = Vector3.zero
			descendant.AssemblyAngularVelocity = Vector3.zero
		end
	end
end)

print("[BankersMenu] menu-only scene stabilized; rigs and display vehicles locked; player spawning disabled")

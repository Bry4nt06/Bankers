local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

Players.CharacterAutoLoads = false

local START_MARKER_NAME = "MenuCameraStart"
local END_MARKER_NAME = "MenuCameraEnd"
local CONFIG_FOLDER_NAME = "BankersMenuCameraConfig"

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

local function stabilizeScene()
	for _, descendant in workspace:GetDescendants() do
		if descendant:IsA("Model") and descendant.Name == "Rig" then
			freezeModel(descendant)
		end
	end

	local vehicles = workspace:FindFirstChild("Vehicles")
	if vehicles then
		for _, descendant in vehicles:GetDescendants() do
			if descendant:IsA("BasePart") then
				descendant.Anchored = true
				descendant.AssemblyLinearVelocity = Vector3.zero
				descendant.AssemblyAngularVelocity = Vector3.zero
			end
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

	if startMarker and startMarker:IsA("BasePart") then
		startValue.Value = startMarker.CFrame
	else
		warn("[BankersMenu] server could not find MenuCameraStart in Workspace")
	end

	if endMarker and endMarker:IsA("BasePart") then
		endValue.Value = endMarker.CFrame
	else
		warn("[BankersMenu] server could not find MenuCameraEnd in Workspace")
	end

	folder:SetAttribute("Ready", startMarker ~= nil and endMarker ~= nil)
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
	elseif descendant:IsA("BasePart") and (descendant.Name == START_MARKER_NAME or descendant.Name == END_MARKER_NAME) then
		task.defer(publishCameraConfig)
	end
end)

print("[BankersMenu] menu-only scene stabilized; player spawning disabled")

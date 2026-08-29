local Players = game:GetService("Players")

Players.CharacterAutoLoads = false

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

for _, player in Players:GetPlayers() do
	keepPlayerOutOfScene(player)
end
Players.PlayerAdded:Connect(keepPlayerOutOfScene)

stabilizeScene()
task.delay(1, stabilizeScene)
task.delay(3, stabilizeScene)

workspace.DescendantAdded:Connect(function(descendant)
	if descendant:IsA("Model") and descendant.Name == "Rig" then
		task.defer(freezeModel, descendant)
	end
end)

print("[BankersMenu] menu-only scene stabilized; player spawning disabled")

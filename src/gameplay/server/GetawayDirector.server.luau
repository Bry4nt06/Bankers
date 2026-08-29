local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("BankersGameplay")
local GetawayConfig = require(shared:WaitForChild("GetawayConfig"))

local runtime = ReplicatedStorage:FindFirstChild("BankersGetawayRuntime")
if not runtime then
	runtime = Instance.new("Folder")
	runtime.Name = "BankersGetawayRuntime"
	runtime.Parent = ReplicatedStorage
end

local currentPhaseIndex = 1
local countdownGeneration = 0
local resultsGeneration = 0
local connectedCheckpoints = {}
local extractionConnected = false

local function getPhaseName(index: number): string
	return GetawayConfig.PhaseOrder[index]
end

local function publishPhase(index: number, reason: string?)
	currentPhaseIndex = math.clamp(index, 1, #GetawayConfig.PhaseOrder)
	local phaseName = getPhaseName(currentPhaseIndex)
	local definition = GetawayConfig.Phases[phaseName] or {}

	runtime:SetAttribute("Phase", phaseName)
	runtime:SetAttribute("PhaseIndex", currentPhaseIndex)
	runtime:SetAttribute("PhaseDisplayName", definition.DisplayName or phaseName)
	runtime:SetAttribute("Objective", definition.Objective or "")
	runtime:SetAttribute("Reason", reason or "")
	runtime:SetAttribute("PhaseStartedAt", workspace:GetServerTimeNow())

	print(string.format("[BankersGetaway] phase -> %s | %s", phaseName, reason or ""))
end

local function setPhaseByName(phaseName: string, reason: string?)
	for index, candidate in ipairs(GetawayConfig.PhaseOrder) do
		if candidate == phaseName then
			publishPhase(index, reason)
			return
		end
	end
end

local function countCrewPlayers(): number
	local count = 0
	for _, player in Players:GetPlayers() do
		if not player.Team or player.Team.Name == GetawayConfig.Factions.Crew then
			count += 1
		end
	end
	return count
end

local function getCrewPlayerFromHit(hit: BasePart): Player?
	local character = hit:FindFirstAncestorOfClass("Model")
	if not character then
		return nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return nil
	end
	local player = Players:GetPlayerFromCharacter(character)
	if not player then
		return nil
	end
	if player.Team and player.Team.Name ~= GetawayConfig.Factions.Crew then
		return nil
	end
	return player
end

local function resetMission(reason: string?)
	countdownGeneration += 1
	resultsGeneration += 1
	runtime:SetAttribute("CurrentCheckpoint", 0)
	runtime:SetAttribute("LobbyCountdownEndsAt", 0)
	publishPhase(1, reason or "reset")
end

local function scheduleResultsReset()
	resultsGeneration += 1
	local generation = resultsGeneration
	task.delay(GetawayConfig.ResultsDurationSeconds, function()
		if generation ~= resultsGeneration then
			return
		end
		if runtime:GetAttribute("Phase") == "Results" then
			resetMission("results complete")
		end
	end)
end

local function completeMission(reason: string)
	if runtime:GetAttribute("Phase") == "Results" then
		return
	end
	setPhaseByName("Results", reason)
	scheduleResultsReset()
end

local function handleCheckpoint(sequence: number, player: Player)
	local current = runtime:GetAttribute("CurrentCheckpoint")
	if type(current) ~= "number" then
		current = 0
	end
	if sequence <= current then
		return
	end

	runtime:SetAttribute("CurrentCheckpoint", sequence)
	print(string.format("[BankersGetaway] %s cleared checkpoint %d", player.Name, sequence))

	local phase = runtime:GetAttribute("Phase")
	if phase == "Ready" then
		setPhaseByName("Chase", "crew entered chase route")
	end

	if sequence >= GetawayConfig.EscapeCheckpoint then
		if runtime:GetAttribute("Phase") ~= "Results" then
			setPhaseByName("Escape", "tunnel approach reached")
		end
	elseif sequence >= GetawayConfig.BreakContactCheckpoint then
		if runtime:GetAttribute("Phase") == "Chase" then
			setPhaseByName("BreakContact", "heavy police response triggered")
		end
	end
end

local function connectCheckpoint(part: BasePart)
	if connectedCheckpoints[part] then
		return
	end
	connectedCheckpoints[part] = true

	local sequence = part:GetAttribute("Sequence")
	if type(sequence) ~= "number" then
		return
	end

	part.Touched:Connect(function(hit)
		local player = getCrewPlayerFromHit(hit)
		if player then
			handleCheckpoint(sequence, player)
		end
	end)
end

local function connectExtraction(part: BasePart)
	if extractionConnected then
		return
	end
	extractionConnected = true

	part.Touched:Connect(function(hit)
		local player = getCrewPlayerFromHit(hit)
		if player and runtime:GetAttribute("Phase") == "Escape" then
			completeMission("crew reached extraction")
		end
	end)
end

local function discoverRouteTriggers()
	local graybox = workspace:FindFirstChild(GetawayConfig.GrayboxModelName)
	if not graybox then
		warn("[BankersGetaway] GetawayGraybox not found; bake the route before testing checkpoints")
		return
	end

	local checkpointFolder = graybox:FindFirstChild(GetawayConfig.CheckpointFolderName)
	if checkpointFolder then
		for _, descendant in checkpointFolder:GetDescendants() do
			if descendant:IsA("BasePart") then
				connectCheckpoint(descendant)
			end
		end
	end

	local extraction = graybox:FindFirstChild(GetawayConfig.ExtractionZoneName, true)
	if extraction and extraction:IsA("BasePart") then
		connectExtraction(extraction)
	end
end

local function tryStartCountdown()
	if runtime:GetAttribute("Phase") ~= "Ready" then
		return
	end
	if countCrewPlayers() < GetawayConfig.MinPlayers then
		runtime:SetAttribute("LobbyCountdownEndsAt", 0)
		return
	end

	countdownGeneration += 1
	local generation = countdownGeneration
	local endsAt = workspace:GetServerTimeNow() + GetawayConfig.LobbyCountdownSeconds
	runtime:SetAttribute("LobbyCountdownEndsAt", endsAt)
	print(string.format("[BankersGetaway] crew ready; getaway begins in %ds", GetawayConfig.LobbyCountdownSeconds))

	task.delay(GetawayConfig.LobbyCountdownSeconds, function()
		if generation ~= countdownGeneration then
			return
		end
		if runtime:GetAttribute("Phase") ~= "Ready" then
			return
		end
		if countCrewPlayers() < GetawayConfig.MinPlayers then
			runtime:SetAttribute("LobbyCountdownEndsAt", 0)
			return
		end
		runtime:SetAttribute("LobbyCountdownEndsAt", 0)
		setPhaseByName("Chase", "getaway launched")
	end)
end

Players.PlayerAdded:Connect(function()
	task.defer(tryStartCountdown)
end)

Players.PlayerRemoving:Connect(function()
	task.defer(function()
		if #Players:GetPlayers() == 0 then
			resetMission("server empty")
		else
			tryStartCountdown()
		end
	end)
end)

workspace.ChildAdded:Connect(function(child)
	if child.Name == GetawayConfig.GrayboxModelName then
		task.defer(discoverRouteTriggers)
	end
end)

runtime:SetAttribute("Mode", "CoopPvEGetaway")
runtime:SetAttribute("HybridReady", true)
runtime:SetAttribute("CurrentCheckpoint", 0)
runtime:SetAttribute("LobbyCountdownEndsAt", 0)
resetMission("server started")
discoverRouteTriggers()
task.defer(tryStartCountdown)

print("[BankersGetaway] co-op armored-truck getaway director ready")

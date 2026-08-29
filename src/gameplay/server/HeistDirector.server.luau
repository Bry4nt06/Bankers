local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local shared = ReplicatedStorage:WaitForChild("BankersGameplay")
local HeistConfig = require(shared:WaitForChild("HeistConfig"))

local runtime = ReplicatedStorage:FindFirstChild("BankersHeistRuntime")
if not runtime then
	runtime = Instance.new("Folder")
	runtime.Name = "BankersHeistRuntime"
	runtime.Parent = ReplicatedStorage
end

local serverEvents = ServerStorage:FindFirstChild("BankersGameplayEvents")
if not serverEvents then
	serverEvents = Instance.new("Folder")
	serverEvents.Name = "BankersGameplayEvents"
	serverEvents.Parent = ServerStorage
end

local advanceEvent = serverEvents:FindFirstChild("AdvanceHeistPhase")
if not advanceEvent then
	advanceEvent = Instance.new("BindableEvent")
	advanceEvent.Name = "AdvanceHeistPhase"
	advanceEvent.Parent = serverEvents
end

local currentPhaseIndex = 1
local lobbyGeneration = 0
local resultsGeneration = 0

local function phaseDefinition(phaseName: string)
	return HeistConfig.Phases[phaseName]
end

local function publishPhase(index: number, reason: string?)
	currentPhaseIndex = math.clamp(index, 1, #HeistConfig.PhaseOrder)
	local phaseName = HeistConfig.PhaseOrder[currentPhaseIndex]
	local definition = phaseDefinition(phaseName) or {}

	runtime:SetAttribute("Phase", phaseName)
	runtime:SetAttribute("PhaseIndex", currentPhaseIndex)
	runtime:SetAttribute("PhaseDisplayName", definition.DisplayName or phaseName)
	runtime:SetAttribute("Objective", definition.Objective or "")
	runtime:SetAttribute("PhaseStartedAt", workspace:GetServerTimeNow())
	runtime:SetAttribute("Reason", reason or "")

	print(string.format(
		"[BankersHeist] phase -> %s (%d/%d)%s",
		phaseName,
		currentPhaseIndex,
		#HeistConfig.PhaseOrder,
		reason and (" | " .. reason) or ""
	))
end

local function resetToLobby(reason: string?)
	lobbyGeneration += 1
	resultsGeneration += 1
	publishPhase(1, reason or "reset")
end

local function scheduleResultsReset()
	resultsGeneration += 1
	local generation = resultsGeneration
	task.delay(HeistConfig.ResultsDurationSeconds, function()
		if generation ~= resultsGeneration then
			return
		end
		if runtime:GetAttribute("Phase") ~= "Results" then
			return
		end
		resetToLobby("results complete")
	end)
end

local function advancePhase(reason: string?)
	local phaseName = HeistConfig.PhaseOrder[currentPhaseIndex]
	if phaseName == "Results" then
		return
	end

	local nextIndex = math.min(currentPhaseIndex + 1, #HeistConfig.PhaseOrder)
	publishPhase(nextIndex, reason or "objective complete")
	if HeistConfig.PhaseOrder[nextIndex] == "Results" then
		scheduleResultsReset()
	end
end

local function countCrewPlayers(): number
	local count = 0
	for _, player in Players:GetPlayers() do
		if not player.Team or player.Team.Name == HeistConfig.Factions.Crew then
			count += 1
		end
	end
	return count
end

local function tryStartLobbyCountdown()
	if runtime:GetAttribute("Phase") ~= "Lobby" then
		return
	end
	if countCrewPlayers() < HeistConfig.MinPlayers then
		runtime:SetAttribute("LobbyCountdownEndsAt", 0)
		return
	end

	lobbyGeneration += 1
	local generation = lobbyGeneration
	local endsAt = workspace:GetServerTimeNow() + HeistConfig.LobbyCountdownSeconds
	runtime:SetAttribute("LobbyCountdownEndsAt", endsAt)
	print(string.format("[BankersHeist] crew ready; infiltration begins in %ds", HeistConfig.LobbyCountdownSeconds))

	task.delay(HeistConfig.LobbyCountdownSeconds, function()
		if generation ~= lobbyGeneration then
			return
		end
		if runtime:GetAttribute("Phase") ~= "Lobby" then
			return
		end
		if countCrewPlayers() < HeistConfig.MinPlayers then
			runtime:SetAttribute("LobbyCountdownEndsAt", 0)
			return
		end
		runtime:SetAttribute("LobbyCountdownEndsAt", 0)
		advancePhase("crew deployed")
	end)
end

advanceEvent.Event:Connect(function(reason)
	advancePhase(type(reason) == "string" and reason or "server objective")
end)

Players.PlayerAdded:Connect(function()
	task.defer(tryStartLobbyCountdown)
end)

Players.PlayerRemoving:Connect(function()
	task.defer(function()
		if #Players:GetPlayers() == 0 then
			resetToLobby("server empty")
		else
			tryStartLobbyCountdown()
		end
	end)
end)

runtime:SetAttribute("Mode", "CoopPvE")
runtime:SetAttribute("HybridReady", true)
runtime:SetAttribute("LobbyCountdownEndsAt", 0)
resetToLobby("server started")
task.defer(tryStartLobbyCountdown)

print("[BankersHeist] co-op PvE director ready; future Law players can reuse the same faction/state model")

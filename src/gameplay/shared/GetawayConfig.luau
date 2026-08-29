local GetawayConfig = {}

GetawayConfig.MinPlayers = 1
GetawayConfig.LobbyCountdownSeconds = 6
GetawayConfig.ResultsDurationSeconds = 10

GetawayConfig.Factions = {
	Crew = "Crew",
	Law = "Law",
}

GetawayConfig.PhaseOrder = {
	"Ready",
	"Chase",
	"BreakContact",
	"Escape",
	"Results",
}

GetawayConfig.Phases = {
	Ready = {
		DisplayName = "GETAWAY READY",
		Objective = "Crew up at the armored truck",
	},
	Chase = {
		DisplayName = "POLICE PURSUIT",
		Objective = "Keep the armored truck moving and stop pursuing units",
	},
	BreakContact = {
		DisplayName = "BREAK CONTACT",
		Objective = "Survive the heavy response through the industrial district",
	},
	Escape = {
		DisplayName = "LOSE THE TAIL",
		Objective = "Reach the tunnel extraction with the crew and the truck",
	},
	Results = {
		DisplayName = "CREW ESCAPED",
		Objective = "Getaway complete",
	},
}

GetawayConfig.GrayboxModelName = "GetawayGraybox"
GetawayConfig.CheckpointFolderName = "RouteCheckpoints"
GetawayConfig.PoliceSpawnFolderName = "PoliceSpawnPoints"
GetawayConfig.ExtractionZoneName = "ExtractionZone"
GetawayConfig.TruckStartName = "ArmoredTruckStart"

-- Crossing these checkpoint sequence numbers changes the mission intensity.
GetawayConfig.BreakContactCheckpoint = 5
GetawayConfig.EscapeCheckpoint = 8

return GetawayConfig

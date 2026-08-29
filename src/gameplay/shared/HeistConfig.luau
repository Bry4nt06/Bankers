local HeistConfig = {}

HeistConfig.MinPlayers = 1
HeistConfig.LobbyCountdownSeconds = 8
HeistConfig.ResultsDurationSeconds = 12

-- Bankers starts as co-op PvE. These faction identifiers are intentionally
-- generic so player-controlled law enforcement can be added later without
-- rewriting combat, damage, or objective ownership systems.
HeistConfig.Factions = {
	Crew = "Crew",
	Law = "Law",
}

HeistConfig.PhaseOrder = {
	"Lobby",
	"Infiltration",
	"Vault",
	"Loot",
	"Escape",
	"Results",
}

HeistConfig.Phases = {
	Lobby = {
		DisplayName = "CREW ASSEMBLY",
		Objective = "Waiting for the crew",
	},
	Infiltration = {
		DisplayName = "INFILTRATION",
		Objective = "Enter the bank and reach the vault floor",
	},
	Vault = {
		DisplayName = "BREACH THE VAULT",
		Objective = "Open the vault while holding off security",
	},
	Loot = {
		DisplayName = "SECURE THE CASH",
		Objective = "Bag the target amount of cash",
	},
	Escape = {
		DisplayName = "ESCAPE",
		Objective = "Reach the extraction vehicle with the loot",
	},
	Results = {
		DisplayName = "HEIST COMPLETE",
		Objective = "Calculating crew results",
	},
}

return HeistConfig

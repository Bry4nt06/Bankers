local Players = game:GetService("Players")
local Teams = game:GetService("Teams")

Players.CharacterAutoLoads = true
Players.RespawnTime = 5

local function ensureTeam(name: string, teamColor: BrickColor, autoAssignable: boolean): Team
	local team = Teams:FindFirstChild(name)
	if not team then
		team = Instance.new("Team")
		team.Name = name
		team.Parent = Teams
	end
	team.TeamColor = teamColor
	team.AutoAssignable = autoAssignable
	return team
end

local crewTeam = ensureTeam("Crew", BrickColor.new("Really black"), true)
-- Reserved now for AI faction ownership and later player-controlled police.
ensureTeam("Law", BrickColor.new("Navy blue"), false)

local function assignCrew(player: Player)
	player.Team = crewTeam
	player.Neutral = false
end

for _, player in Players:GetPlayers() do
	assignCrew(player)
end
Players.PlayerAdded:Connect(assignCrew)

-- A blank gameplay place is still testable before the real heist map exists.
-- Studio-authored SpawnLocations take precedence once one is placed.
if not workspace:FindFirstChildWhichIsA("SpawnLocation", true) then
	local fallbackSpawn = Instance.new("SpawnLocation")
	fallbackSpawn.Name = "FallbackCrewSpawn"
	fallbackSpawn.Size = Vector3.new(12, 1, 12)
	fallbackSpawn.CFrame = CFrame.new(0, 3, 0)
	fallbackSpawn.Anchored = true
	fallbackSpawn.CanCollide = true
	fallbackSpawn.Transparency = 0.35
	fallbackSpawn.Neutral = false
	fallbackSpawn.TeamColor = crewTeam.TeamColor
	fallbackSpawn.Parent = workspace
	warn("[BankersGameplay] no SpawnLocation found; created temporary FallbackCrewSpawn")
end

print("[BankersGameplay] gameplay bootstrap ready; normal spawning enabled; Crew active; Law reserved for hybrid mode")

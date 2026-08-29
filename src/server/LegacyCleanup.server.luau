local Players = game:GetService("Players")
local StarterPlayer = game:GetService("StarterPlayer")

local LEGACY_SCRIPT_NAME = "CinematicIntro"
local LEGACY_CONFIG_NAME = "CinematicIntroConfig"

local function purge(container: Instance?)
	if not container then
		return
	end

	for _, descendant in container:GetDescendants() do
		if descendant.Name == LEGACY_SCRIPT_NAME or descendant.Name == LEGACY_CONFIG_NAME then
			if descendant:IsA("LocalScript") or descendant:IsA("Script") then
				descendant.Enabled = false
			end
			descendant:Destroy()
		end
	end
end

purge(StarterPlayer:FindFirstChild("StarterPlayerScripts"))

local function cleanPlayer(player: Player)
	local playerScripts = player:FindFirstChild("PlayerScripts") or player:WaitForChild("PlayerScripts", 10)
	purge(playerScripts)

	local playerGui = player:FindFirstChild("PlayerGui")
	if playerGui then
		local legacyGui = playerGui:FindFirstChild("CinematicIntroGui")
		if legacyGui then
			legacyGui:Destroy()
		end
	end
end

for _, player in Players:GetPlayers() do
	task.defer(cleanPlayer, player)
end
Players.PlayerAdded:Connect(function(player)
	task.defer(cleanPlayer, player)
end)

print("[BankersMenu] legacy cinematic scripts removed")

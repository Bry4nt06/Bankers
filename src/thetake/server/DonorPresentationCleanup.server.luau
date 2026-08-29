local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local StarterGui = game:GetService("StarterGui")

local REMOVALS = {
	{parent = workspace, name = "StarterScene"},
	{parent = workspace, name = "introcameras"},
	{parent = ServerStorage, name = "Intro"},
	{parent = StarterGui, name = "CutsceneUI"},
	{parent = StarterGui, name = "LoadingScreenGui"},
}

local function destroyNamed(parent: Instance, name: string)
	local target = parent:FindFirstChild(name)
	if target then
		print(string.format("[TheTakeCleanup] removing Broken presentation object %s.%s", parent.Name, name))
		target:Destroy()
	end
end

for _, entry in ipairs(REMOVALS) do
	destroyNamed(entry.parent, entry.name)
end

local function cleanPlayerGui(player: Player)
	local playerGui = player:FindFirstChildOfClass("PlayerGui")
	if not playerGui then
		return
	end
	destroyNamed(playerGui, "CutsceneUI")
	destroyNamed(playerGui, "LoadingScreenGui")
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		task.defer(cleanPlayerGui, player)
	end)
	task.defer(cleanPlayerGui, player)
end)

for _, player in ipairs(Players:GetPlayers()) do
	task.defer(cleanPlayerGui, player)
end

print("[TheTakeCleanup] Broken opening presentation cleanup complete")

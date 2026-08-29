local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")

local LEGACY_NAMES = {
	CinematicIntro = true,
	CinematicIntroConfig = true,
	DestroyHelperUI = true,
	MenuRigKeeper = true,
}

local INVALID_SOUND_IDS = {
	["rbxassetid://0"] = true,
	["rbxassetid://295227435"] = true,
	["rbxassetid://303735435"] = true,
}

local function isDisplayVehicle(instance: Instance): boolean
	local current: Instance? = instance
	while current and current ~= workspace do
		if current:IsA("Model") then
			local lowerName = string.lower(current.Name)
			if string.find(lowerName, "armored truck", 1, true) then
				return true
			end
		end
		current = current.Parent
	end
	return false
end

local function disableAndDestroy(instance: Instance)
	if instance:IsA("Script") or instance:IsA("LocalScript") then
		instance.Enabled = false
	end
	instance:Destroy()
end

local function purgeLegacyNamedInstances(container: Instance?)
	if not container then
		return
	end

	for _, descendant in container:GetDescendants() do
		if LEGACY_NAMES[descendant.Name] then
			disableAndDestroy(descendant)
		end
	end
end

local function sanitizeSound(sound: Sound)
	if isDisplayVehicle(sound) or INVALID_SOUND_IDS[sound.SoundId] then
		sound:Stop()
		sound.SoundId = ""
	end
end

local function sanitizeVehicleRuntime(container: Instance)
	for _, descendant in container:GetDescendants() do
		if isDisplayVehicle(descendant) then
			if descendant:IsA("Script") or descendant:IsA("LocalScript") then
				descendant.Enabled = false
				descendant:Destroy()
			elseif descendant:IsA("Sound") then
				sanitizeSound(descendant)
			end
		elseif descendant:IsA("Sound") then
			sanitizeSound(descendant)
		end
	end
end

local function cleanPlayer(player: Player)
	local playerScripts = player:FindFirstChild("PlayerScripts") or player:WaitForChild("PlayerScripts", 10)
	purgeLegacyNamedInstances(playerScripts)

	local playerGui = player:FindFirstChild("PlayerGui")
	if playerGui then
		local legacyGui = playerGui:FindFirstChild("CinematicIntroGui")
		if legacyGui then
			legacyGui:Destroy()
		end
	end
end

purgeLegacyNamedInstances(ServerScriptService)
purgeLegacyNamedInstances(StarterPlayer:FindFirstChild("StarterPlayerScripts"))
sanitizeVehicleRuntime(workspace)

for _, descendant in workspace:GetDescendants() do
	if descendant:IsA("Sound") then
		sanitizeSound(descendant)
	end
end

for _, player in Players:GetPlayers() do
	task.defer(cleanPlayer, player)
end

Players.PlayerAdded:Connect(function(player)
	task.defer(cleanPlayer, player)
end)

ServerScriptService.DescendantAdded:Connect(function(descendant)
	if LEGACY_NAMES[descendant.Name] then
		task.defer(function()
			if descendant.Parent then
				disableAndDestroy(descendant)
			end
		end)
	end
end)

workspace.DescendantAdded:Connect(function(descendant)
	if descendant:IsA("Script") or descendant:IsA("LocalScript") then
		if isDisplayVehicle(descendant) then
			descendant.Enabled = false
			task.defer(function()
				if descendant.Parent then
					descendant:Destroy()
				end
			end)
		end
	elseif descendant:IsA("Sound") then
		task.defer(function()
			if descendant.Parent then
				sanitizeSound(descendant)
			end
		end)
	end
end)

print("[BankersMenu] legacy runtime cleanup complete; display vehicles sanitized")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("BankersPvP")
local PvPConfig = require(shared:WaitForChild("PvPConfig"))
local WeaponConfig = require(shared:WaitForChild("WeaponConfig"))

Players.CharacterAutoLoads = true
Players.RespawnTime = PvPConfig.RespawnSeconds

local function ensureLeaderstats(player: Player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end

	if not leaderstats:FindFirstChild("KOs") then
		local kos = Instance.new("IntValue")
		kos.Name = "KOs"
		kos.Parent = leaderstats
	end

	if not leaderstats:FindFirstChild("WOs") then
		local wos = Instance.new("IntValue")
		wos.Name = "WOs"
		wos.Parent = leaderstats
	end
end

local function makeRifleTool(): Tool
	local config = WeaponConfig.Rifle
	local tool = Instance.new("Tool")
	tool.Name = config.DisplayName
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	tool:SetAttribute("BankersWeapon", true)
	tool:SetAttribute("WeaponId", config.Id)
	tool:SetAttribute("Ammo", config.MagazineSize)
	tool:SetAttribute("ReserveAmmo", config.ReserveAmmo)
	tool:SetAttribute("Reloading", false)

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.42, 0.55, 3.2)
	handle.Color = Color3.fromRGB(42, 44, 47)
	handle.Material = Enum.Material.Metal
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = tool

	local barrel = Instance.new("Part")
	barrel.Name = "Barrel"
	barrel.Size = Vector3.new(0.18, 0.18, 1.9)
	barrel.Color = Color3.fromRGB(20, 21, 23)
	barrel.Material = Enum.Material.Metal
	barrel.CanCollide = false
	barrel.Massless = true
	barrel.CFrame = handle.CFrame * CFrame.new(0, 0.08, -2.1)
	barrel.Parent = tool

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = handle
	weld.Part1 = barrel
	weld.Parent = handle

	return tool
end

local function giveLoadout(player: Player)
	local backpack = player:WaitForChild("Backpack")
	for _, container in ipairs({backpack, player.Character}) do
		if container then
			for _, child in ipairs(container:GetChildren()) do
				if child:IsA("Tool") and child:GetAttribute("BankersWeapon") == true then
					child:Destroy()
				end
			end
		end
	end

	makeRifleTool().Parent = backpack
end

local function setupCharacter(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if humanoid and humanoid:IsA("Humanoid") then
		humanoid.MaxHealth = PvPConfig.MaxHealth
		humanoid.Health = PvPConfig.MaxHealth
		humanoid.UseJumpPower = true
		humanoid.JumpPower = PvPConfig.Movement.JumpPower
	end

	player:SetAttribute("PvPADS", false)
	player:SetAttribute("PvPSprinting", false)
	player:SetAttribute("PvPCrouched", false)
	player:SetAttribute("PvPSliding", false)
	player:SetAttribute("SpawnProtectedUntil", workspace:GetServerTimeNow() + PvPConfig.SpawnProtectionSeconds)

	task.delay(0.15, function()
		if player.Parent then
			giveLoadout(player)
		end
	end)
end

local function setupPlayer(player: Player)
	ensureLeaderstats(player)
	player.CharacterAdded:Connect(function(character)
		setupCharacter(player, character)
	end)
	if player.Character then
		task.defer(setupCharacter, player, player.Character)
	end
end

for _, player in ipairs(Players:GetPlayers()) do
	setupPlayer(player)
end
Players.PlayerAdded:Connect(setupPlayer)

if not workspace:FindFirstChildWhichIsA("SpawnLocation", true) then
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "PvPFallbackSpawn"
	spawn.Size = Vector3.new(16, 1, 16)
	spawn.CFrame = CFrame.new(0, 3, 0)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Transparency = 0.3
	spawn.Parent = workspace
	warn("[BankersPvP] no arena spawn found; temporary fallback spawn created")
end

print("[BankersPvP] FFA bootstrap ready; rifle loadout + respawns enabled")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local shared = ReplicatedStorage:WaitForChild("BankersPvP")
local PvPConfig = require(shared:WaitForChild("PvPConfig"))
local WeaponConfig = require(shared:WaitForChild("WeaponConfig"))

local remotes = ReplicatedStorage:FindFirstChild("BankersPvPRemotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "BankersPvPRemotes"
	remotes.Parent = ReplicatedStorage
end

local function remote(name: string): RemoteEvent
	local existing = remotes:FindFirstChild(name)
	if existing and existing:IsA("RemoteEvent") then
		return existing
	end
	local event = Instance.new("RemoteEvent")
	event.Name = name
	event.Parent = remotes
	return event
end

local fireWeapon = remote("FireWeapon")
local reloadWeapon = remote("ReloadWeapon")
local shotFx = remote("ShotFX")
local hitConfirm = remote("HitConfirm")

local stateByPlayer = {}
local rng = Random.new()

local function getWeaponTool(player: Player): Tool?
	local character = player.Character
	if not character then
		return nil
	end
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Tool") and child:GetAttribute("BankersWeapon") == true then
			return child
		end
	end
	return nil
end

local function getConfig(tool: Tool)
	local id = tool:GetAttribute("WeaponId")
	if type(id) ~= "string" then
		return nil
	end
	return WeaponConfig[id]
end

local function applySpread(direction: Vector3, spreadDegrees: number): Vector3
	if spreadDegrees <= 0 then
		return direction.Unit
	end
	local basis = CFrame.lookAt(Vector3.zero, direction.Unit)
	local yaw = math.rad(rng:NextNumber(-spreadDegrees, spreadDegrees))
	local pitch = math.rad(rng:NextNumber(-spreadDegrees, spreadDegrees))
	return (basis * CFrame.Angles(pitch, yaw, 0)).LookVector.Unit
end

local function findHumanoidFromHit(instance: Instance?): Humanoid?
	local current = instance
	while current and current ~= workspace do
		if current:IsA("Model") then
			local humanoid = current:FindFirstChildOfClass("Humanoid")
			if humanoid then
				return humanoid
			end
		end
		current = current.Parent
	end
	return nil
end

local function playerFromHumanoid(humanoid: Humanoid): Player?
	local model = humanoid.Parent
	if model and model:IsA("Model") then
		return Players:GetPlayerFromCharacter(model)
	end
	return nil
end

local function canDamageTarget(shooter: Player, targetHumanoid: Humanoid): boolean
	if targetHumanoid.Health <= 0 then
		return false
	end
	local targetPlayer = playerFromHumanoid(targetHumanoid)
	if not targetPlayer or targetPlayer == shooter then
		return false
	end
	local protectedUntil = targetPlayer:GetAttribute("SpawnProtectedUntil")
	if type(protectedUntil) == "number" and protectedUntil > workspace:GetServerTimeNow() then
		return false
	end
	return true
end

local function recordDamage(shooter: Player, targetHumanoid: Humanoid)
	targetHumanoid:SetAttribute("LastDamagerUserId", shooter.UserId)
	targetHumanoid:SetAttribute("LastDamageAt", workspace:GetServerTimeNow())
end

local function processFire(player: Player, desiredDirection)
	if typeof(desiredDirection) ~= "Vector3" or desiredDirection.Magnitude < 0.9 then
		return
	end
	local character = player.Character
	if not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local head = character:FindFirstChild("Head")
	if not humanoid or humanoid.Health <= 0 or not head or not head:IsA("BasePart") then
		return
	end

	local tool = getWeaponTool(player)
	if not tool then
		return
	end
	local config = getConfig(tool)
	if not config then
		return
	end

	local state = stateByPlayer[player]
	if not state then
		state = {lastFire = 0}
		stateByPlayer[player] = state
	end
	local now = workspace:GetServerTimeNow()
	local minimumInterval = 60 / config.RPM
	if now - state.lastFire < minimumInterval * 0.92 then
		return
	end
	if tool:GetAttribute("Reloading") == true then
		return
	end

	local ammo = tool:GetAttribute("Ammo")
	if type(ammo) ~= "number" or ammo <= 0 then
		return
	end
	state.lastFire = now
	tool:SetAttribute("Ammo", ammo - 1)

	local ads = player:GetAttribute("PvPADS") == true
	local spread = ads and config.ADSSpreadDegrees or config.HipSpreadDegrees
	local direction = applySpread(desiredDirection, spread)
	local origin = head.Position + direction * 0.4

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {character}
	params.IgnoreWater = true

	local result = workspace:Raycast(origin, direction * config.Range, params)
	local hitPosition = origin + direction * config.Range
	local didHitCharacter = false
	local killed = false
	local damage = 0

	if result then
		hitPosition = result.Position
		local targetHumanoid = findHumanoidFromHit(result.Instance)
		if targetHumanoid and canDamageTarget(player, targetHumanoid) then
			damage = config.Damage
			if result.Instance.Name == "Head" then
				damage *= config.HeadshotMultiplier
			end
			damage = math.floor(damage + 0.5)
			recordDamage(player, targetHumanoid)
			local before = targetHumanoid.Health
			targetHumanoid:TakeDamage(damage)
			didHitCharacter = true
			killed = before > 0 and targetHumanoid.Health <= 0
		end
	end

	shotFx:FireAllClients(player.UserId, origin, hitPosition)
	if didHitCharacter then
		hitConfirm:FireClient(player, damage, killed)
	end
end

local function processReload(player: Player)
	local tool = getWeaponTool(player)
	if not tool then
		return
	end
	local config = getConfig(tool)
	if not config or tool:GetAttribute("Reloading") == true then
		return
	end
	local ammo = tool:GetAttribute("Ammo")
	local reserve = tool:GetAttribute("ReserveAmmo")
	if type(ammo) ~= "number" or type(reserve) ~= "number" or ammo >= config.MagazineSize or reserve <= 0 then
		return
	end

	tool:SetAttribute("Reloading", true)
	local token = tostring(os.clock()) .. ":" .. player.UserId
	tool:SetAttribute("ReloadToken", token)

	task.delay(config.ReloadSeconds, function()
		if not tool.Parent or tool:GetAttribute("ReloadToken") ~= token then
			return
		end
		local currentAmmo = tool:GetAttribute("Ammo")
		local currentReserve = tool:GetAttribute("ReserveAmmo")
		if type(currentAmmo) ~= "number" or type(currentReserve) ~= "number" then
			tool:SetAttribute("Reloading", false)
			return
		end
		local needed = math.max(0, config.MagazineSize - currentAmmo)
		local moved = math.min(needed, currentReserve)
		tool:SetAttribute("Ammo", currentAmmo + moved)
		tool:SetAttribute("ReserveAmmo", currentReserve - moved)
		tool:SetAttribute("Reloading", false)
	end)
end

local function connectCharacter(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid or not humanoid:IsA("Humanoid") then
		return
	end
	humanoid.Died:Connect(function()
		local stats = player:FindFirstChild("leaderstats")
		local wos = stats and stats:FindFirstChild("WOs")
		if wos and wos:IsA("IntValue") then
			wos.Value += 1
		end

		local lastDamager = humanoid:GetAttribute("LastDamagerUserId")
		local lastDamageAt = humanoid:GetAttribute("LastDamageAt")
		if type(lastDamager) == "number" and type(lastDamageAt) == "number" and workspace:GetServerTimeNow() - lastDamageAt <= 8 then
			local killer = Players:GetPlayerByUserId(lastDamager)
			if killer and killer ~= player then
				local killerStats = killer:FindFirstChild("leaderstats")
				local kos = killerStats and killerStats:FindFirstChild("KOs")
				if kos and kos:IsA("IntValue") then
					kos.Value += 1
				end
			end
		end
	end)
end

for _, player in ipairs(Players:GetPlayers()) do
	player.CharacterAdded:Connect(function(character)
		connectCharacter(player, character)
	end)
	if player.Character then
		task.defer(connectCharacter, player, player.Character)
	end
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		connectCharacter(player, character)
	end)
end)
Players.PlayerRemoving:Connect(function(player)
	stateByPlayer[player] = nil
end)

fireWeapon.OnServerEvent:Connect(processFire)
reloadWeapon.OnServerEvent:Connect(processReload)

print("[BankersPvP] server-authoritative hitscan combat ready")

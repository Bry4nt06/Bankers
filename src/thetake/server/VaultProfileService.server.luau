local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local theTake = ReplicatedStorage:WaitForChild("TheTake")
local shared = theTake:WaitForChild("Shared")
local Config = require(shared:WaitForChild("VaultEconomyConfig"))
local GearRenderer = require(shared:WaitForChild("WearableSkinRenderer"))
local GearRules = require(shared:WaitForChild("VaultGearRules"))
local storeIndex = theTake:WaitForChild("VaultStoreIndex")
local catalogRoot = ServerStorage:WaitForChild("TheTakeVaultCatalog")
local gearFolder = catalogRoot:WaitForChild("Gear")

local remotes = theTake:FindFirstChild("VaultRemotes")
if remotes then
	remotes:Destroy()
end
remotes = Instance.new("Folder")
remotes.Name = "VaultRemotes"
remotes.Parent = theTake

local getProfile = Instance.new("RemoteFunction")
getProfile.Name = "GetProfile"
getProfile.Parent = remotes

local purchaseItem = Instance.new("RemoteFunction")
purchaseItem.Name = "PurchaseItem"
purchaseItem.Parent = remotes

local equipItem = Instance.new("RemoteFunction")
equipItem.Name = "EquipItem"
equipItem.Parent = remotes

local profileChanged = Instance.new("RemoteEvent")
profileChanged.Name = "ProfileChanged"
profileChanged.Parent = remotes

local dataStore = nil
if not RunService:IsStudio() then
	dataStore = DataStoreService:GetDataStore(Config.ProfileStoreName)
end

local profiles = {}

local function defaultGearSlots()
	return {
		Base = Config.DefaultGearId,
		Head = "",
		Face = "",
		Torso = "",
		Back = "",
	}
end

local function newProfile()
	return {
		Cash = Config.StartingCash,
		Owned = {
			[Config.DefaultGearId] = true,
		},
		Equipped = {
			GearSlots = defaultGearSlots(),
			Primary = "",
			Secondary = "",
		},
	}
end

local function normalizeProfile(raw)
	local profile = newProfile()
	if type(raw) ~= "table" then
		return profile
	end

	if type(raw.Cash) == "number" then
		profile.Cash = math.max(0, math.floor(raw.Cash))
	end
	if type(raw.Owned) == "table" then
		for itemId, owned in pairs(raw.Owned) do
			if type(itemId) == "string" and owned == true then
				profile.Owned[itemId] = true
			end
		end
	end

	if type(raw.Equipped) == "table" then
		if type(raw.Equipped.GearSlots) == "table" then
			for _, slot in ipairs(GearRules.SlotOrder) do
				local value = raw.Equipped.GearSlots[slot]
				if type(value) == "string" then
					profile.Equipped.GearSlots[slot] = value
				end
			end
		else
			-- Migration from the original one-gear/skin profile format.
			local legacy = raw.Equipped.Gear
			if type(legacy) ~= "string" or legacy == "" then
				legacy = raw.Equipped.Skin
			end
			if type(legacy) == "string" and legacy ~= "" then
				profile.Equipped.GearSlots.Base = legacy
			end
		end

		for _, key in ipairs({"Primary", "Secondary"}) do
			local value = raw.Equipped[key]
			if type(value) == "string" then
				profile.Equipped[key] = value
			end
		end
	end

	profile.Owned[Config.DefaultGearId] = true
	if profile.Equipped.GearSlots.Base == "" or not profile.Owned[profile.Equipped.GearSlots.Base] then
		profile.Equipped.GearSlots.Base = Config.DefaultGearId
	end
	for _, slot in ipairs({"Head", "Face", "Torso", "Back"}) do
		local itemId = profile.Equipped.GearSlots[slot]
		if itemId ~= "" and not profile.Owned[itemId] then
			profile.Equipped.GearSlots[slot] = ""
		end
	end
	return profile
end

local function copyGearSlots(source)
	local result = defaultGearSlots()
	for _, slot in ipairs(GearRules.SlotOrder) do
		local value = source and source[slot]
		if type(value) == "string" then
			result[slot] = value
		end
	end
	return result
end

local function publicProfile(profile)
	local owned = {}
	for itemId, value in pairs(profile.Owned) do
		if value == true then
			owned[itemId] = true
		end
	end
	local slots = copyGearSlots(profile.Equipped.GearSlots)
	return {
		Cash = profile.Cash,
		Owned = owned,
		Equipped = {
			GearSlots = slots,
			Gear = slots.Base, -- compatibility alias
			Skin = slots.Base, -- legacy compatibility alias
			Primary = profile.Equipped.Primary,
			Secondary = profile.Equipped.Secondary,
		},
	}
end

local function applyPlayerAttributes(player: Player, profile)
	local slots = profile.Equipped.GearSlots
	player:SetAttribute("VaultCash", profile.Cash)
	player:SetAttribute("VaultEquippedGear", slots.Base)
	player:SetAttribute("VaultEquippedSkin", slots.Base)
	for _, slot in ipairs(GearRules.SlotOrder) do
		player:SetAttribute("VaultGear" .. slot, slots[slot] or "")
	end
	player:SetAttribute("VaultEquippedPrimary", profile.Equipped.Primary)
	player:SetAttribute("VaultEquippedSecondary", profile.Equipped.Secondary)
	player:SetAttribute("VaultGearRevision", (tonumber(player:GetAttribute("VaultGearRevision")) or 0) + 1)
end

local function findGearTemplate(itemId: string): Instance?
	if itemId == "" then
		return nil
	end
	for _, gear in ipairs(gearFolder:GetChildren()) do
		if gear:GetAttribute("VaultItemId") == itemId then
			return gear
		end
	end
	return nil
end

local function applyEquippedGear(player: Player, character: Model?)
	if not character then
		return
	end
	local profile = profiles[player.UserId]
	if not profile then
		return
	end

	GearRenderer.Clear(character)
	for _, slot in ipairs(GearRules.SlotOrder) do
		local itemId = profile.Equipped.GearSlots[slot] or ""
		if itemId ~= "" then
			local template = findGearTemplate(itemId)
			if template and GearRules.IsWearable(template) then
				if not GearRenderer.ApplyGear(character, template, slot) then
					warn(string.format("[TheVaultProfile] gear could not attach: %s [%s]", itemId, slot))
				end
			elseif not template then
				warn(string.format("[TheVaultProfile] equipped gear template missing: %s", itemId))
			end
		end
	end
end

local function loadProfile(player: Player)
	local raw = nil
	if dataStore then
		local ok, result = pcall(function()
			return dataStore:GetAsync("u_" .. player.UserId)
		end)
		if ok then
			raw = result
		else
			warn("[TheVaultProfile] load failed for " .. player.Name .. ": " .. tostring(result))
		end
	end

	local profile = normalizeProfile(raw)
	profiles[player.UserId] = profile
	applyPlayerAttributes(player, profile)

	player.CharacterAdded:Connect(function(character)
		task.defer(applyEquippedGear, player, character)
	end)
	if player.Character then
		task.defer(applyEquippedGear, player, player.Character)
	end

	print(string.format("[TheVaultProfile] ready for %s | Cash=%d | wardrobe slots ready", player.Name, profile.Cash))
end

local function saveProfile(player: Player)
	if not dataStore then
		return
	end
	local profile = profiles[player.UserId]
	if not profile then
		return
	end
	local snapshot = publicProfile(profile)
	local ok, err = pcall(function()
		dataStore:SetAsync("u_" .. player.UserId, snapshot)
	end)
	if not ok then
		warn("[TheVaultProfile] save failed for " .. player.Name .. ": " .. tostring(err))
	end
end

local function notify(player: Player)
	local profile = profiles[player.UserId]
	if not profile then
		return
	end
	applyPlayerAttributes(player, profile)
	profileChanged:FireClient(player, publicProfile(profile))
	if dataStore then
		task.defer(saveProfile, player)
	end
end

local function getEntry(itemId: string)
	local entry = storeIndex:FindFirstChild(itemId)
	if entry and entry:IsA("Folder") and entry:GetAttribute("Enabled") ~= false then
		return entry
	end
	return nil
end

getProfile.OnServerInvoke = function(player: Player)
	local profile = profiles[player.UserId]
	if not profile then
		return false, "PROFILE_NOT_READY", nil
	end
	return true, "OK", publicProfile(profile)
end

purchaseItem.OnServerInvoke = function(player: Player, itemId)
	if type(itemId) ~= "string" then
		return false, "INVALID_ITEM", nil
	end
	local profile = profiles[player.UserId]
	if not profile then
		return false, "PROFILE_NOT_READY", nil
	end
	local entry = getEntry(itemId)
	if not entry then
		return false, "ITEM_NOT_FOUND", publicProfile(profile)
	end
	if profile.Owned[itemId] then
		return true, "ALREADY_OWNED", publicProfile(profile)
	end

	local price = math.max(0, math.floor(tonumber(entry:GetAttribute("Price")) or 0))
	local currency = tostring(entry:GetAttribute("Currency") or "Cash")
	if currency ~= "Cash" then
		return false, "UNSUPPORTED_CURRENCY", publicProfile(profile)
	end
	if profile.Cash < price then
		return false, "NOT_ENOUGH_CASH", publicProfile(profile)
	end

	profile.Cash -= price
	profile.Owned[itemId] = true
	notify(player)
	print(string.format("[TheVaultProfile] %s purchased %s for %d Cash", player.Name, itemId, price))
	return true, "PURCHASED", publicProfile(profile)
end

equipItem.OnServerInvoke = function(player: Player, itemId)
	if type(itemId) ~= "string" then
		return false, "INVALID_ITEM", nil
	end
	local profile = profiles[player.UserId]
	if not profile then
		return false, "PROFILE_NOT_READY", nil
	end
	local entry = getEntry(itemId)
	if not entry then
		return false, "ITEM_NOT_FOUND", publicProfile(profile)
	end
	if not profile.Owned[itemId] then
		return false, "NOT_OWNED", publicProfile(profile)
	end

	local category = tostring(entry:GetAttribute("Category") or "")
	local message = "EQUIPPED"
	if category == "Gear" then
		if entry:GetAttribute("Wearable") ~= true then
			return false, "GEAR_FIT_PENDING", publicProfile(profile)
		end
		local slot = tostring(entry:GetAttribute("GearSlot") or "Torso")
		if profile.Equipped.GearSlots[slot] == itemId then
			if slot == "Base" then
				return true, "BASE_GEAR_REQUIRED", publicProfile(profile)
			end
			profile.Equipped.GearSlots[slot] = ""
			message = "UNEQUIPPED"
		else
			profile.Equipped.GearSlots[slot] = itemId
		end
		applyEquippedGear(player, player.Character)
	elseif category == "Guns" then
		local subcategory = tostring(entry:GetAttribute("Subcategory") or "")
		if subcategory == "Pistols" then
			profile.Equipped.Secondary = itemId
		else
			profile.Equipped.Primary = itemId
		end
	else
		return false, "CATEGORY_NOT_EQUIPPABLE_YET", publicProfile(profile)
	end

	notify(player)
	print(string.format("[TheVaultProfile] %s %s %s", player.Name, string.lower(message), itemId))
	return true, message, publicProfile(profile)
end

Players.PlayerAdded:Connect(loadProfile)
for _, player in ipairs(Players:GetPlayers()) do
	task.defer(loadProfile, player)
end

Players.PlayerRemoving:Connect(function(player)
	saveProfile(player)
	profiles[player.UserId] = nil
end)

game:BindToClose(function()
	if not dataStore then
		return
	end
	for _, player in ipairs(Players:GetPlayers()) do
		saveProfile(player)
	end
end)

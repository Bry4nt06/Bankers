local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local theTake = ReplicatedStorage:WaitForChild("TheTake")
local shared = theTake:WaitForChild("Shared")
local Config = require(shared:WaitForChild("VaultEconomyConfig"))
local SkinRenderer = require(shared:WaitForChild("WearableSkinRenderer"))
local storeIndex = theTake:WaitForChild("VaultStoreIndex")
local catalogRoot = ServerStorage:WaitForChild("TheTakeVaultCatalog")
local skinsFolder = catalogRoot:WaitForChild("Skins")

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

local function newProfile()
	return {
		Cash = Config.StartingCash,
		Owned = {
			[Config.DefaultSkinId] = true,
		},
		Equipped = {
			Skin = Config.DefaultSkinId,
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
		for _, key in ipairs({"Skin", "Primary", "Secondary"}) do
			local value = raw.Equipped[key]
			if type(value) == "string" then
				profile.Equipped[key] = value
			end
		end
	end
	profile.Owned[Config.DefaultSkinId] = true
	if profile.Equipped.Skin == "" or not profile.Owned[profile.Equipped.Skin] then
		profile.Equipped.Skin = Config.DefaultSkinId
	end
	return profile
end

local function publicProfile(profile)
	local owned = {}
	for itemId, value in pairs(profile.Owned) do
		if value == true then
			owned[itemId] = true
		end
	end
	return {
		Cash = profile.Cash,
		Owned = owned,
		Equipped = {
			Skin = profile.Equipped.Skin,
			Primary = profile.Equipped.Primary,
			Secondary = profile.Equipped.Secondary,
		},
	}
end

local function applyPlayerAttributes(player: Player, profile)
	player:SetAttribute("VaultCash", profile.Cash)
	player:SetAttribute("VaultEquippedSkin", profile.Equipped.Skin)
	player:SetAttribute("VaultEquippedPrimary", profile.Equipped.Primary)
	player:SetAttribute("VaultEquippedSecondary", profile.Equipped.Secondary)
end

local function findSkinTemplate(itemId: string): Instance?
	for _, skin in ipairs(skinsFolder:GetChildren()) do
		if skin:GetAttribute("VaultItemId") == itemId then
			return skin
		end
	end
	return nil
end

local function applyEquippedSkin(player: Player, character: Model?)
	if not character then
		return
	end
	local profile = profiles[player.UserId]
	if not profile then
		return
	end

	SkinRenderer.Clear(character)
	local template = findSkinTemplate(profile.Equipped.Skin)
	if not template then
		warn(string.format("[TheVaultProfile] equipped skin template missing: %s", profile.Equipped.Skin))
		return
	end

	if not SkinRenderer.ApplyTemplate(character, template) then
		warn(string.format("[TheVaultProfile] skin template could not attach: %s", profile.Equipped.Skin))
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
		task.defer(applyEquippedSkin, player, character)
	end)
	if player.Character then
		task.defer(applyEquippedSkin, player, player.Character)
	end

	print(string.format("[TheVaultProfile] ready for %s | Cash=%d | default skin owned", player.Name, profile.Cash))
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
	if category == "Skins" then
		if entry:GetAttribute("Wearable") ~= true then
			return false, "SKIN_NOT_WEARABLE", publicProfile(profile)
		end
		profile.Equipped.Skin = itemId
		applyEquippedSkin(player, player.Character)
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
	print(string.format("[TheVaultProfile] %s equipped %s", player.Name, itemId))
	return true, "EQUIPPED", publicProfile(profile)
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

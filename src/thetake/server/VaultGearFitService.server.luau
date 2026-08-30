local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

if not RunService:IsStudio() then
	return
end

local theTake = ReplicatedStorage:WaitForChild("TheTake")
local shared = theTake:WaitForChild("Shared")
local FitConfig = require(shared:WaitForChild("VaultGearFitConfig"))
local GearRules = require(shared:WaitForChild("VaultGearRules"))
local gearFolder = ServerStorage:WaitForChild("TheTakeVaultCatalog"):WaitForChild("Gear")

local existingRemotes = theTake:FindFirstChild("VaultFitRemotes")
if existingRemotes then
	existingRemotes:Destroy()
end

local existingPreviewRoot = theTake:FindFirstChild("VaultFitPreviewModels")
if existingPreviewRoot then
	existingPreviewRoot:Destroy()
end

local remotes = Instance.new("Folder")
remotes.Name = "VaultFitRemotes"
remotes.Parent = theTake

local previewRoot = Instance.new("Folder")
previewRoot.Name = "VaultFitPreviewModels"
previewRoot.Parent = theTake

local beginFit = Instance.new("RemoteFunction")
beginFit.Name = "BeginFit"
beginFit.Parent = remotes

local updateFit = Instance.new("RemoteFunction")
updateFit.Name = "UpdateFit"
updateFit.Parent = remotes

local endFit = Instance.new("RemoteFunction")
endFit.Name = "EndFit"
endFit.Parent = remotes

local sessions = {}

local function findGearTemplate(itemId: string): Instance?
	for _, item in ipairs(gearFolder:GetChildren()) do
		if item:GetAttribute("VaultItemId") == itemId then
			return item
		end
	end
	return nil
end

local function hasNativeAccessory(template: Instance): boolean
	if template:IsA("Accessory") then
		return true
	end
	return template:FindFirstChildWhichIsA("Accessory", true) ~= nil
end

local function clampNumber(value, fallback: number, minimum: number, maximum: number): number
	local numeric = tonumber(value)
	if numeric == nil then
		return fallback
	end
	return math.clamp(numeric, minimum, maximum)
end

local function normalizeDraft(raw, fallback)
	raw = type(raw) == "table" and raw or {}
	fallback = type(fallback) == "table" and fallback or {
		Scale = 1,
		OffsetX = 0,
		OffsetY = 0,
		OffsetZ = 0,
		RotationX = 0,
		RotationY = 0,
		RotationZ = 0,
		UseAutoFit = false,
	}

	return {
		Scale = clampNumber(raw.Scale, fallback.Scale, 0.25, 2),
		OffsetX = clampNumber(raw.OffsetX, fallback.OffsetX, -3, 3),
		OffsetY = clampNumber(raw.OffsetY, fallback.OffsetY, -3, 3),
		OffsetZ = clampNumber(raw.OffsetZ, fallback.OffsetZ, -3, 3),
		RotationX = clampNumber(raw.RotationX, fallback.RotationX, -180, 180),
		RotationY = clampNumber(raw.RotationY, fallback.RotationY, -180, 180),
		RotationZ = clampNumber(raw.RotationZ, fallback.RotationZ, -180, 180),
		UseAutoFit = type(raw.UseAutoFit) == "boolean" and raw.UseAutoFit or fallback.UseAutoFit == true,
	}
end

local function fitToDraft(template: Instance)
	local fit = FitConfig.Resolve(template)
	return {
		Scale = fit.Scale,
		OffsetX = fit.Offset.X,
		OffsetY = fit.Offset.Y,
		OffsetZ = fit.Offset.Z,
		RotationX = fit.Rotation.X,
		RotationY = fit.Rotation.Y,
		RotationZ = fit.Rotation.Z,
		UseAutoFit = fit.UseAutoFit == true,
	}
end

local function applyDraftAttributes(template: Instance, draft)
	template:SetAttribute("GearScale", draft.Scale)
	template:SetAttribute("GearOffsetX", draft.OffsetX)
	template:SetAttribute("GearOffsetY", draft.OffsetY)
	template:SetAttribute("GearOffsetZ", draft.OffsetZ)
	template:SetAttribute("GearRotationX", draft.RotationX)
	template:SetAttribute("GearRotationY", draft.RotationY)
	template:SetAttribute("GearRotationZ", draft.RotationZ)
	template:SetAttribute("GearUseAutoFit", draft.UseAutoFit == true)
end

local function bumpFitRevision(player: Player)
	player:SetAttribute("VaultFitRevision", (tonumber(player:GetAttribute("VaultFitRevision")) or 0) + 1)
end

local function previewFolderFor(player: Player): Folder
	local name = tostring(player.UserId)
	local folder = previewRoot:FindFirstChild(name)
	if folder and folder:IsA("Folder") then
		return folder
	end
	if folder then
		folder:Destroy()
	end
	folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = previewRoot
	return folder
end

local function clearPreview(player: Player)
	local folder = previewRoot:FindFirstChild(tostring(player.UserId))
	if folder then
		folder:Destroy()
	end
	player:SetAttribute("VaultFitActive", false)
	player:SetAttribute("VaultFitItemId", "")
	player:SetAttribute("VaultFitSlot", "")
	bumpFitRevision(player)
end

local function publishPreview(player: Player, session)
	local source = findGearTemplate(session.ItemId)
	if not source then
		return false
	end

	local folder = previewFolderFor(player)
	folder:ClearAllChildren()
	folder:SetAttribute("ItemId", session.ItemId)
	folder:SetAttribute("GearSlot", session.Slot)

	local preview = source:Clone()
	preview.Name = "Gear"
	applyDraftAttributes(preview, session.Draft)
	preview.Parent = folder

	player:SetAttribute("VaultFitActive", true)
	player:SetAttribute("VaultFitItemId", session.ItemId)
	player:SetAttribute("VaultFitSlot", session.Slot)
	bumpFitRevision(player)
	return true
end

local function snippetFor(session): string
	local draft = session.Draft
	local autoFitLine = draft.UseAutoFit and "\n\t\tUseAutoFit = true," or ""
	return string.format(
		"[\"%s\"] = {\n\t\tScale = %.3f,\n\t\tOffset = Vector3.new(%.3f, %.3f, %.3f),\n\t\tRotation = Vector3.new(%.1f, %.1f, %.1f),%s\n\t},",
		session.ItemId,
		draft.Scale,
		draft.OffsetX,
		draft.OffsetY,
		draft.OffsetZ,
		draft.RotationX,
		draft.RotationY,
		draft.RotationZ,
		autoFitLine
	)
end

local function publicSession(session)
	return {
		ItemId = session.ItemId,
		DisplayName = session.DisplayName,
		Slot = session.Slot,
		NativeAccessory = session.NativeAccessory,
		Draft = session.Draft,
		Baseline = session.Baseline,
		Snippet = snippetFor(session),
	}
end

beginFit.OnServerInvoke = function(player: Player, itemId)
	if type(itemId) ~= "string" or itemId == "" then
		return false, "INVALID_ITEM", nil
	end

	local template = findGearTemplate(itemId)
	if not template then
		return false, "ITEM_NOT_FOUND", nil
	end
	if not GearRules.IsWearable(template) then
		return false, "ITEM_NOT_WEARABLE", nil
	end

	local slot = GearRules.InferSlot(template)
	local baseline = fitToDraft(template)
	local session = {
		ItemId = itemId,
		DisplayName = tostring(template:GetAttribute("VaultDisplayName") or template.Name),
		Slot = slot,
		NativeAccessory = hasNativeAccessory(template),
		Baseline = baseline,
		Draft = normalizeDraft(baseline, baseline),
	}
	sessions[player.UserId] = session
	if not publishPreview(player, session) then
		sessions[player.UserId] = nil
		return false, "PREVIEW_PUBLISH_FAILED", nil
	end
	return true, "FIT_STARTED", publicSession(session)
end

updateFit.OnServerInvoke = function(player: Player, rawDraft)
	local session = sessions[player.UserId]
	if not session then
		return false, "FIT_NOT_ACTIVE", nil
	end

	session.Draft = normalizeDraft(rawDraft, session.Draft)
	if not publishPreview(player, session) then
		return false, "PREVIEW_PUBLISH_FAILED", nil
	end
	return true, "FIT_UPDATED", publicSession(session)
end

endFit.OnServerInvoke = function(player: Player)
	local session = sessions[player.UserId]
	if not session then
		clearPreview(player)
		return true, "FIT_ALREADY_CLOSED", nil
	end

	local final = publicSession(session)
	sessions[player.UserId] = nil
	clearPreview(player)
	return true, "FIT_CLOSED", final
end

local function initializePlayer(player: Player)
	player:SetAttribute("VaultFitActive", false)
	player:SetAttribute("VaultFitItemId", "")
	player:SetAttribute("VaultFitSlot", "")
	player:SetAttribute("VaultFitRevision", 0)
end

Players.PlayerAdded:Connect(initializePlayer)
for _, player in ipairs(Players:GetPlayers()) do
	initializePlayer(player)
end

Players.PlayerRemoving:Connect(function(player)
	sessions[player.UserId] = nil
	local folder = previewRoot:FindFirstChild(tostring(player.UserId))
	if folder then
		folder:Destroy()
	end
end)

print("[TheVaultFit] isolated Studio gear fitting service ready")

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
local Renderer = require(shared:WaitForChild("WearableSkinRenderer"))
local gearFolder = ServerStorage:WaitForChild("TheTakeVaultCatalog"):WaitForChild("Gear")

local existing = theTake:FindFirstChild("VaultFitRemotes")
if existing then
	existing:Destroy()
end

local remotes = Instance.new("Folder")
remotes.Name = "VaultFitRemotes"
remotes.Parent = theTake

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

local function equippedItemForSlot(player: Player, slot: string): string
	local value = player:GetAttribute("VaultGear" .. slot)
	return type(value) == "string" and value or ""
end

local function bumpPreviewRevision(player: Player)
	player:SetAttribute("VaultGearRevision", (tonumber(player:GetAttribute("VaultGearRevision")) or 0) + 1)
end

local function renderPlayerGear(player: Player, session)
	local character = player.Character
	if not character then
		return false
	end

	Renderer.Clear(character)
	for _, slot in ipairs(GearRules.SlotOrder) do
		local itemId = equippedItemForSlot(player, slot)
		local selected = session and session.Slot == slot
		if selected then
			itemId = session.ItemId
		end

		if itemId ~= "" then
			local template = findGearTemplate(itemId)
			if template then
				if selected then
					local previewTemplate = template:Clone()
					applyDraftAttributes(previewTemplate, session.Draft)
					Renderer.ApplyGear(character, previewTemplate, slot)
					previewTemplate:Destroy()
				else
					Renderer.ApplyGear(character, template, slot)
				end
			end
		end
	end

	bumpPreviewRevision(player)
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
	renderPlayerGear(player, session)
	return true, "FIT_STARTED", publicSession(session)
end

updateFit.OnServerInvoke = function(player: Player, rawDraft)
	local session = sessions[player.UserId]
	if not session then
		return false, "FIT_NOT_ACTIVE", nil
	end

	session.Draft = normalizeDraft(rawDraft, session.Draft)
	renderPlayerGear(player, session)
	return true, "FIT_UPDATED", publicSession(session)
end

endFit.OnServerInvoke = function(player: Player)
	local session = sessions[player.UserId]
	if not session then
		return true, "FIT_ALREADY_CLOSED", nil
	end

	local final = publicSession(session)
	sessions[player.UserId] = nil
	renderPlayerGear(player, nil)
	return true, "FIT_CLOSED", final
end

Players.PlayerRemoving:Connect(function(player)
	sessions[player.UserId] = nil
end)

for _, player in ipairs(Players:GetPlayers()) do
	player.CharacterAdded:Connect(function()
		task.delay(0.5, function()
			local session = sessions[player.UserId]
			if session then
				renderPlayerGear(player, session)
			end
		end)
	end)
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		task.delay(0.5, function()
			local session = sessions[player.UserId]
			if session then
				renderPlayerGear(player, session)
			end
		end)
	end)
end)

print("[TheVaultFit] Studio-only live gear fitting service ready")

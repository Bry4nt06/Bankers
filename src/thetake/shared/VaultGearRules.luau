local GearRules = {}

GearRules.SlotOrder = {"Base", "Head", "Face", "Torso", "Back"}

local function textFor(instance: Instance): string
	return string.lower(table.concat({
		tostring(instance:GetAttribute("VaultItemId") or ""),
		tostring(instance:GetAttribute("VaultDisplayName") or instance.Name),
		tostring(instance:GetAttribute("GearType") or ""),
	}, " "))
end

function GearRules.InferSlot(instance: Instance): string
	local explicit = instance:GetAttribute("GearSlot")
	if type(explicit) == "string" and explicit ~= "" then
		return explicit
	end

	local text = textFor(instance)
	if text:find("default%-crew") or text:find("crew standard", 1, true) then
		return "Base"
	elseif text:find("backpack", 1, true) or text:find("pack", 1, true) then
		return "Back"
	elseif text:find("mask", 1, true) or text:find("respirator", 1, true) then
		return "Face"
	elseif text:find("helmet", 1, true) or text:find("headgear", 1, true) then
		return "Head"
	elseif text:find("vest", 1, true) or text:find("carrier", 1, true) or text:find("iotv", 1, true) or text:find("armor", 1, true) then
		return "Torso"
	end
	return "Torso"
end

function GearRules.IsWearable(instance: Instance): boolean
	if instance:GetAttribute("VaultWearable") == true then
		return true
	end
	-- Curated Creator Store Gear gets a conservative automatic fitting pass.
	return instance:GetAttribute("CreatorStoreImported") == true
end

function GearRules.FitStatus(instance: Instance): string
	local explicit = instance:GetAttribute("FitStatus")
	if instance:GetAttribute("VaultWearable") == true and type(explicit) == "string" and explicit ~= "" then
		return explicit
	end
	if instance:GetAttribute("CreatorStoreImported") == true then
		return "AutoFit"
	end
	return type(explicit) == "string" and explicit or "NeedsFitting"
end

return GearRules

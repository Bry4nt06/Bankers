local GearRules = {}

GearRules.SlotOrder = {
	"Base",
	"Headwear",
	"Eyewear",
	"FaceMask",
	"Vest",
	"Back",
	"Waist",
	"Hands",
}

local SLOT_LABELS = {
	Base = "BASE OUTFIT",
	Headwear = "HATS / HELMETS",
	Eyewear = "GLASSES / GOGGLES",
	FaceMask = "FACE MASKS",
	Vest = "VESTS / CARRIERS",
	Back = "BACKPACKS",
	Waist = "BELTS / HOLSTERS",
	Hands = "GLOVES",
}

local LEGACY_SLOT_MAP = {
	Head = "Headwear",
	Face = "FaceMask",
	Torso = "Vest",
	Back = "Back",
	Base = "Base",
}

local VALID_SLOTS = {}
for _, slot in ipairs(GearRules.SlotOrder) do
	VALID_SLOTS[slot] = true
end

local function textFor(instance: Instance): string
	return string.lower(table.concat({
		tostring(instance:GetAttribute("VaultItemId") or ""),
		tostring(instance:GetAttribute("VaultDisplayName") or instance.Name),
		tostring(instance:GetAttribute("GearType") or ""),
	}, " "))
end

function GearRules.NormalizeSlot(slot: string?, itemId: string?): string
	local raw = type(slot) == "string" and slot or ""
	local id = type(itemId) == "string" and itemId or ""

	-- Crew Standard used to occupy Base. It is actually a tactical vest and must
	-- compete with IOTV/plate carriers instead of stacking underneath them.
	if id == "skins-default-crew" then
		return "Vest"
	end

	if VALID_SLOTS[raw] then
		return raw
	end
	return LEGACY_SLOT_MAP[raw] or "Vest"
end

function GearRules.SlotLabel(slot: string): string
	return SLOT_LABELS[GearRules.NormalizeSlot(slot)] or string.upper(slot)
end

function GearRules.SlotRank(slot: string): number
	local normalized = GearRules.NormalizeSlot(slot)
	for index, value in ipairs(GearRules.SlotOrder) do
		if value == normalized then
			return index
		end
	end
	return #GearRules.SlotOrder + 1
end

function GearRules.InferSlot(instance: Instance): string
	local explicit = instance:GetAttribute("GearSlot")
	local itemId = tostring(instance:GetAttribute("VaultItemId") or "")
	if type(explicit) == "string" and explicit ~= "" then
		return GearRules.NormalizeSlot(explicit, itemId)
	end

	local text = textFor(instance)
	if text:find("default%-crew") or text:find("crew standard", 1, true) then
		return "Vest"
	elseif text:find("glasses", 1, true)
		or text:find("sunglasses", 1, true)
		or text:find("eyewear", 1, true)
		or text:find("goggle", 1, true) then
		return "Eyewear"
	elseif text:find("mask", 1, true)
		or text:find("respirator", 1, true)
		or text:find("balaclava", 1, true) then
		return "FaceMask"
	elseif text:find("helmet", 1, true)
		or text:find("headgear", 1, true)
		or text:find("hat", 1, true)
		or text:find("cap", 1, true)
		or text:find("beanie", 1, true) then
		return "Headwear"
	elseif text:find("backpack", 1, true) or text:find("pack", 1, true) then
		return "Back"
	elseif text:find("belt", 1, true) or text:find("holster", 1, true) or text:find("waist", 1, true) then
		return "Waist"
	elseif text:find("glove", 1, true) then
		return "Hands"
	elseif text:find("vest", 1, true)
		or text:find("carrier", 1, true)
		or text:find("iotv", 1, true)
		or text:find("armor", 1, true)
		or text:find("plate", 1, true) then
		return "Vest"
	elseif text:find("outfit", 1, true)
		or text:find("uniform", 1, true)
		or text:find("jacket", 1, true)
		or text:find("shirt", 1, true) then
		return "Base"
	end
	return "Vest"
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

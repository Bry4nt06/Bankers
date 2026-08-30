local FitConfig = {}

-- Source-controlled fit overrides for THE VAULT. These apply even to gear that
-- was imported before the current manifest/attribute values existed. Runtime
-- attributes on a gear model still win, so Studio can be used for one-off tuning.
--
-- Fitting order: Scale first, then Offset (studs), then Rotation (degrees).
-- UseAutoFit forces our manual bounding-box fitter even when the source contains
-- a standard Roblox Accessory. Leave it false/nil when native attachments fit well.
-- Keeping the final values here means corrections survive Creator Store re-imports.
FitConfig.Items = {
	["gear-plate-carrier"] = {
		Scale = 0.88,
		Offset = Vector3.new(0, -0.02, 0),
		Rotation = Vector3.new(0, 0, 0),
	},
	["gear-tactical-helmet"] = {
		Scale = 0.91,
		Offset = Vector3.new(0, 0.04, 0),
		Rotation = Vector3.new(0, 0, 0),
	},
	["gear-mask"] = {
		Scale = 0.84,
		Offset = Vector3.new(0, -0.02, 0),
		Rotation = Vector3.new(0, 0, 0),
	},
	["gear-m50-mask"] = {
		Scale = 0.82,
		Offset = Vector3.new(0, -0.03, 0),
		Rotation = Vector3.new(0, 0, 0),
	},
	["gear-opening-balaclava-goggles"] = {
		Scale = 1.00,
		Offset = Vector3.new(0, 0, 0),
		Rotation = Vector3.new(0, 0, 0),
		UseAutoFit = true,
	},
	["gear-opening-classic-balaclava"] = {
		Scale = 1.00,
		Offset = Vector3.new(0, 0, 0),
		Rotation = Vector3.new(0, 0, 0),
		UseAutoFit = true,
	},
	["gear-opening-ski-mask"] = {
		Scale = 1.00,
		Offset = Vector3.new(0, 0, 0),
		Rotation = Vector3.new(0, 0, 0),
		UseAutoFit = true,
	},
	["gear-opening-hex-carrier"] = {
		Scale = 1.00,
		Offset = Vector3.new(0, 0, 0),
		Rotation = Vector3.new(0, 0, 0),
		UseAutoFit = true,
	},
	["gear-opening-tactical-vest"] = {
		Scale = 1.00,
		Offset = Vector3.new(0, 0, 0),
		Rotation = Vector3.new(0, 0, 0),
		UseAutoFit = true,
	},
	["gear-opening-black-vest"] = {
		Scale = 1.00,
		Offset = Vector3.new(0, 0, 0),
		Rotation = Vector3.new(0, 0, 0),
		UseAutoFit = true,
	},
	["gear-opening-military-duffel"] = {
		Scale = 1.00,
		Offset = Vector3.new(0, 0, 0),
		Rotation = Vector3.new(0, 0, 0),
		UseAutoFit = true,
	},
}

function FitConfig.Get(template: Instance)
	local itemId = tostring(template:GetAttribute("VaultItemId") or "")
	return FitConfig.Items[itemId]
end

function FitConfig.Resolve(template: Instance)
	local configured = FitConfig.Get(template)
	local configuredOffset = configured and configured.Offset or Vector3.zero
	local configuredRotation = configured and configured.Rotation or Vector3.zero

	local scale = tonumber(template:GetAttribute("GearScale"))
	if scale == nil then
		scale = configured and configured.Scale or 1
	end

	local x = tonumber(template:GetAttribute("GearOffsetX"))
	local y = tonumber(template:GetAttribute("GearOffsetY"))
	local z = tonumber(template:GetAttribute("GearOffsetZ"))
	local rx = tonumber(template:GetAttribute("GearRotationX"))
	local ry = tonumber(template:GetAttribute("GearRotationY"))
	local rz = tonumber(template:GetAttribute("GearRotationZ"))
	local useAutoFit = template:GetAttribute("GearUseAutoFit")
	if type(useAutoFit) ~= "boolean" then
		useAutoFit = configured and configured.UseAutoFit == true or false
	end

	return {
		Scale = math.clamp(scale, 0.25, 2),
		Offset = Vector3.new(
			x ~= nil and x or configuredOffset.X,
			y ~= nil and y or configuredOffset.Y,
			z ~= nil and z or configuredOffset.Z
		),
		Rotation = Vector3.new(
			rx ~= nil and rx or configuredRotation.X,
			ry ~= nil and ry or configuredRotation.Y,
			rz ~= nil and rz or configuredRotation.Z
		),
		UseAutoFit = useAutoFit == true,
	}
end

return FitConfig

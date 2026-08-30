local Renderer = {}

local OVERLAY_NAME = "TheTakeWearableGear"

-- These mesh ids were observed returning AssetFetchStatus failure in Studio.
-- They are removed before an imported Creator Store model is parented into a rendered container.
local BLOCKED_MESH_IDS = {
	[8357187898] = true,
	[8357195670] = true,
	[8211433480] = true,
	[8357164518] = true,
	[8357191738] = true,
}

local function contentIdNumber(value: string): number?
	local number = value:match("(%d+)")
	return number and tonumber(number) or nil
end

local function isBlockedContent(value: string): boolean
	local id = contentIdNumber(value)
	return id ~= nil and BLOCKED_MESH_IDS[id] == true
end

local function clear(rig: Model)
	local existing = rig:FindFirstChild(OVERLAY_NAME)
	if existing then
		existing:Destroy()
	end
	-- Remove the legacy overlay name during migration.
	local legacy = rig:FindFirstChild("TheTakeWearableSkin")
	if legacy then
		legacy:Destroy()
	end
end

local function ensureOverlay(rig: Model): Folder
	local existing = rig:FindFirstChild(OVERLAY_NAME)
	if existing and existing:IsA("Folder") then
		return existing
	end
	local folder = Instance.new("Folder")
	folder.Name = OVERLAY_NAME
	folder.Parent = rig
	return folder
end

local function findTarget(rig: Model, preferred: string?, fallback: string?): BasePart?
	if preferred and preferred ~= "" then
		local part = rig:FindFirstChild(preferred)
		if part and part:IsA("BasePart") then
			return part
		end
	end
	if fallback and fallback ~= "" then
		local part = rig:FindFirstChild(fallback)
		if part and part:IsA("BasePart") then
			return part
		end
	end
	return nil
end

local function sanitizeTree(instance: Instance)
	local all = {instance}
	for _, descendant in ipairs(instance:GetDescendants()) do
		table.insert(all, descendant)
	end

	for index = #all, 1, -1 do
		local descendant = all[index]
		if descendant:IsA("Script") or descendant:IsA("LocalScript") or descendant:IsA("ModuleScript") then
			descendant:Destroy()
		elseif descendant:IsA("RemoteEvent") or descendant:IsA("RemoteFunction") or descendant:IsA("BindableEvent") or descendant:IsA("BindableFunction") then
			descendant:Destroy()
		elseif descendant:IsA("Sound") or descendant:IsA("ProximityPrompt") or descendant:IsA("ClickDetector") then
			descendant:Destroy()
		elseif descendant:IsA("MeshPart") then
			if isBlockedContent(descendant.MeshId) then
				descendant:Destroy()
			else
				descendant.Anchored = false
				descendant.CanCollide = false
				descendant.CanTouch = false
				descendant.CanQuery = false
				descendant.Massless = true
			end
		elseif descendant:IsA("SpecialMesh") then
			if isBlockedContent(descendant.MeshId) then
				descendant:Destroy()
			end
		elseif descendant:IsA("BasePart") then
			descendant.Anchored = false
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
			descendant.Massless = true
		end
	end
end

local function scaledLocalCFrame(reference: BasePart, target: BasePart, source: BasePart): CFrame
	local localCFrame = reference.CFrame:ToObjectSpace(source.CFrame)
	local localPosition = localCFrame.Position
	local scale = Vector3.new(
		target.Size.X / math.max(reference.Size.X, 0.001),
		target.Size.Y / math.max(reference.Size.Y, 0.001),
		target.Size.Z / math.max(reference.Size.Z, 0.001)
	)
	local scaledPosition = Vector3.new(
		localPosition.X * scale.X,
		localPosition.Y * scale.Y,
		localPosition.Z * scale.Z
	)
	return CFrame.new(scaledPosition) * localCFrame.Rotation
end

local function scaledSize(reference: BasePart, target: BasePart, source: BasePart): Vector3
	local scale = Vector3.new(
		target.Size.X / math.max(reference.Size.X, 0.001),
		target.Size.Y / math.max(reference.Size.Y, 0.001),
		target.Size.Z / math.max(reference.Size.Z, 0.001)
	)
	return Vector3.new(
		source.Size.X * scale.X,
		source.Size.Y * scale.Y,
		source.Size.Z * scale.Z
	)
end

local function hasExplicitAttachmentTemplate(template: Instance): boolean
	for _, descendant in ipairs(template:GetDescendants()) do
		if descendant:IsA("BasePart") and type(descendant:GetAttribute("SkinAttachTo")) == "string" then
			return true
		end
	end
	return false
end

local function applyExplicitTemplate(rig: Model, template: Instance, group: Folder): boolean
	local applied = 0
	for _, source in ipairs(template:GetDescendants()) do
		if source:IsA("BasePart") and source:GetAttribute("SkinReferencePart") ~= true then
			local attachTo = source:GetAttribute("SkinAttachTo")
			local attachFallback = source:GetAttribute("SkinAttachFallback")
			local referenceName = source:GetAttribute("SkinReference")

			if type(attachTo) == "string" and type(referenceName) == "string" then
				local target = findTarget(rig, attachTo, type(attachFallback) == "string" and attachFallback or nil)
				local reference = template:FindFirstChild(referenceName, true)
				if target and reference and reference:IsA("BasePart") then
					local clone = source:Clone()
					sanitizeTree(clone)
					if clone.Parent == nil then
						clone.Size = scaledSize(reference, target, source)
						clone.CFrame = target.CFrame * scaledLocalCFrame(reference, target, source)
						clone.Parent = group

						local weld = Instance.new("WeldConstraint")
						weld.Name = "GearWeld"
						weld.Part0 = target
						weld.Part1 = clone
						weld.Parent = clone
						applied += 1
					end
				end
			end
		end
	end
	return applied > 0
end

local function targetForSlot(rig: Model, slot: string): BasePart?
	if slot == "Head" or slot == "Face" then
		return findTarget(rig, "Head", nil)
	end
	return findTarget(rig, "UpperTorso", "Torso")
end

local function desiredSizeForSlot(target: BasePart, slot: string): Vector3
	if slot == "Head" then
		return Vector3.new(target.Size.X * 1.65, target.Size.Y * 1.55, target.Size.Z * 1.65)
	elseif slot == "Face" then
		return Vector3.new(target.Size.X * 1.35, target.Size.Y * 1.25, target.Size.Z * 1.35)
	elseif slot == "Back" then
		return Vector3.new(target.Size.X * 1.35, target.Size.Y * 1.45, target.Size.Z * 1.8)
	end
	return Vector3.new(target.Size.X * 1.45, target.Size.Y * 1.4, target.Size.Z * 1.9)
end

local function autoFitCFrame(target: BasePart, slot: string, fittedSize: Vector3, template: Instance): CFrame
	local x = tonumber(template:GetAttribute("GearOffsetX")) or 0
	local y = tonumber(template:GetAttribute("GearOffsetY")) or 0
	local z = tonumber(template:GetAttribute("GearOffsetZ")) or 0
	local rx = tonumber(template:GetAttribute("GearRotationX")) or 0
	local ry = tonumber(template:GetAttribute("GearRotationY")) or 0
	local rz = tonumber(template:GetAttribute("GearRotationZ")) or 0

	if slot == "Head" then
		y += target.Size.Y * 0.18
	elseif slot == "Face" then
		z -= target.Size.Z * 0.34
	elseif slot == "Back" then
		z += target.Size.Z * 0.56 + fittedSize.Z * 0.12
	end

	return target.CFrame
		* CFrame.new(x, y, z)
		* CFrame.Angles(math.rad(rx), math.rad(ry), math.rad(rz))
end

local function applyAutoFit(rig: Model, template: Instance, slot: string, group: Folder): boolean
	local target = targetForSlot(rig, slot)
	if not target then
		return false
	end

	local wrapper = Instance.new("Model")
	wrapper.Name = "AutoFit"
	local clone = template:Clone()
	clone.Name = "Source"
	sanitizeTree(clone)
	clone.Parent = wrapper

	if not wrapper:FindFirstChildWhichIsA("BasePart", true) then
		wrapper:Destroy()
		return false
	end

	local okBounds, _, size = pcall(function()
		return wrapper:GetBoundingBox()
	end)
	if not okBounds or not size or size.Magnitude < 0.01 then
		wrapper:Destroy()
		return false
	end

	local desired = desiredSizeForSlot(target, slot)
	local scale = math.min(
		desired.X / math.max(size.X, 0.01),
		desired.Y / math.max(size.Y, 0.01),
		desired.Z / math.max(size.Z, 0.01),
		3
	)
	pcall(function()
		wrapper:ScaleTo(scale)
	end)

	local _, fittedSize = wrapper:GetBoundingBox()
	wrapper:PivotTo(autoFitCFrame(target, slot, fittedSize, template))
	wrapper.Parent = group

	local partCount = 0
	for _, descendant in ipairs(wrapper:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = false
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
			descendant.Massless = true
			local weld = Instance.new("WeldConstraint")
			weld.Name = "GearWeld"
			weld.Part0 = target
			weld.Part1 = descendant
			weld.Parent = descendant
			partCount += 1
		end
	end
	return partCount > 0
end

function Renderer.Clear(rig: Model)
	clear(rig)
end

function Renderer.ApplyGear(rig: Model, template: Instance, slot: string): boolean
	if not template then
		return false
	end

	local overlay = ensureOverlay(rig)
	local group = Instance.new("Folder")
	group.Name = tostring(template:GetAttribute("VaultItemId") or template.Name)
	group:SetAttribute("GearSlot", slot)
	group.Parent = overlay

	local success
	if hasExplicitAttachmentTemplate(template) then
		success = applyExplicitTemplate(rig, template, group)
	else
		success = applyAutoFit(rig, template, slot, group)
	end

	if not success then
		group:Destroy()
	end
	return success
end

function Renderer.ApplyTemplate(rig: Model, template: Instance): boolean
	-- Backward-compatible entry point for older callers.
	clear(rig)
	return Renderer.ApplyGear(rig, template, tostring(template:GetAttribute("GearSlot") or "Base"))
end

return Renderer

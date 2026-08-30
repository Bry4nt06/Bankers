local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("TheTake"):WaitForChild("Shared")
local FitConfig = require(shared:WaitForChild("VaultGearFitConfig"))

local Renderer = {}

local OVERLAY_NAME = "TheTakeWearableGear"
local MANAGED_ACCESSORY_ATTRIBUTE = "TheTakeManagedAccessory"

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
	for _, child in ipairs(rig:GetChildren()) do
		if child:IsA("Accessory") and child:GetAttribute(MANAGED_ACCESSORY_ATTRIBUTE) == true then
			child:Destroy()
		end
	end

	local existing = rig:FindFirstChild(OVERLAY_NAME)
	if existing then
		existing:Destroy()
	end
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

local function collectAccessories(template: Instance): {Accessory}
	local result = {}
	if template:IsA("Accessory") then
		table.insert(result, template)
	end
	for _, descendant in ipairs(template:GetDescendants()) do
		if descendant:IsA("Accessory") then
			table.insert(result, descendant)
		end
	end
	return result
end

local function applyNativeAccessories(rig: Model, template: Instance): boolean
	local humanoid = rig:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return false
	end

	local applied = 0
	for _, source in ipairs(collectAccessories(template)) do
		local accessory = source:Clone()
		sanitizeTree(accessory)
		local handle = accessory:FindFirstChild("Handle")
		if handle and handle:IsA("BasePart") then
			accessory:SetAttribute(MANAGED_ACCESSORY_ATTRIBUTE, true)
			local ok = pcall(function()
				humanoid:AddAccessory(accessory)
			end)
			if ok and accessory.Parent == rig then
				applied += 1
			else
				accessory:Destroy()
			end
		else
			accessory:Destroy()
		end
	end
	return applied > 0
end

local function targetForSlot(rig: Model, slot: string): BasePart?
	if slot == "Headwear" or slot == "Eyewear" or slot == "FaceMask" or slot == "Head" or slot == "Face" then
		return findTarget(rig, "Head", nil)
	elseif slot == "Waist" then
		return findTarget(rig, "LowerTorso", "Torso")
	elseif slot == "Hands" then
		return findTarget(rig, "RightHand", "Right Arm")
	end
	return findTarget(rig, "UpperTorso", "Torso")
end

local function desiredSizeForSlot(target: BasePart, slot: string): Vector3
	if slot == "Headwear" or slot == "Head" then
		return Vector3.new(target.Size.X * 1.24, target.Size.Y * 1.22, target.Size.Z * 1.24)
	elseif slot == "Eyewear" then
		return Vector3.new(target.Size.X * 1.12, target.Size.Y * 0.58, target.Size.Z * 0.68)
	elseif slot == "FaceMask" or slot == "Face" then
		return Vector3.new(target.Size.X * 1.12, target.Size.Y * 1.02, target.Size.Z * 0.86)
	elseif slot == "Back" then
		return Vector3.new(target.Size.X * 1.12, target.Size.Y * 1.16, target.Size.Z * 1.05)
	elseif slot == "Waist" then
		return Vector3.new(target.Size.X * 1.18, target.Size.Y * 0.72, target.Size.Z * 1.20)
	elseif slot == "Hands" then
		return Vector3.new(target.Size.X * 1.16, target.Size.Y * 1.16, target.Size.Z * 1.16)
	elseif slot == "Base" then
		return Vector3.new(target.Size.X * 1.16, target.Size.Y * 1.40, target.Size.Z * 1.28)
	end
	return Vector3.new(target.Size.X * 1.16, target.Size.Y * 1.08, target.Size.Z * 1.28)
end

local function stripInvisibleFitHelpers(root: Instance)
	local all = root:GetDescendants()
	for index = #all, 1, -1 do
		local descendant = all[index]
		if descendant:IsA("BasePart")
			and descendant.Transparency >= 0.98
			and not descendant:FindFirstAncestorOfClass("Accessory") then
			descendant:Destroy()
		end
	end
end

local function centerVisibleGeometry(wrapper: Model): Vector3?
	local okBounds, boundsCFrame, size = pcall(function()
		return wrapper:GetBoundingBox()
	end)
	if not okBounds or not size or size.Magnitude < 0.01 then
		return nil
	end

	-- Free models often have a pivot/helper part far away from the actual mesh.
	-- Center the visible cluster before ScaleTo so the helper pivot cannot throw
	-- the item several studs away from the avatar.
	local translation = CFrame.new(-boundsCFrame.Position)
	for _, descendant in ipairs(wrapper:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.CFrame = translation * descendant.CFrame
		end
	end
	pcall(function()
		wrapper.WorldPivot = CFrame.new()
	end)
	return size
end

local function autoFitCFrame(target: BasePart, slot: string, fittedSize: Vector3, template: Instance): CFrame
	local fit = FitConfig.Resolve(template)
	local offset = fit.Offset
	local rotation = fit.Rotation
	local x = offset.X
	local y = offset.Y
	local z = offset.Z

	if slot == "Headwear" or slot == "Head" then
		y += target.Size.Y * 0.30
	elseif slot == "Eyewear" then
		y += target.Size.Y * 0.03
		z -= target.Size.Z * 0.44
	elseif slot == "FaceMask" or slot == "Face" then
		y -= target.Size.Y * 0.04
		z -= target.Size.Z * 0.40
	elseif slot == "Back" then
		z += target.Size.Z * 0.52 + fittedSize.Z * 0.22
	elseif slot == "Waist" then
		y -= target.Size.Y * 0.08
	end

	return target.CFrame
		* CFrame.new(x, y, z)
		* CFrame.Angles(math.rad(rotation.X), math.rad(rotation.Y), math.rad(rotation.Z))
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
	stripInvisibleFitHelpers(wrapper)

	if not wrapper:FindFirstChildWhichIsA("BasePart", true) then
		wrapper:Destroy()
		return false
	end

	local size = centerVisibleGeometry(wrapper)
	if not size then
		wrapper:Destroy()
		return false
	end

	local desired = desiredSizeForSlot(target, slot)
	local fit = FitConfig.Resolve(template)
	local scale = math.min(
		desired.X / math.max(size.X, 0.01),
		desired.Y / math.max(size.Y, 0.01),
		desired.Z / math.max(size.Z, 0.01),
		3
	) * fit.Scale
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
	elseif applyNativeAccessories(rig, template) then
		success = true
	else
		success = applyAutoFit(rig, template, slot, group)
	end

	if not success then
		group:Destroy()
	end
	return success
end

function Renderer.ApplyTemplate(rig: Model, template: Instance): boolean
	clear(rig)
	return Renderer.ApplyGear(rig, template, tostring(template:GetAttribute("GearSlot") or "Vest"))
end

return Renderer

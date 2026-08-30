local Renderer = {}

local OVERLAY_NAME = "TheTakeWearableSkin"

local function clear(rig: Model)
	local existing = rig:FindFirstChild(OVERLAY_NAME)
	if existing then
		existing:Destroy()
	end
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

local function sanitizeClone(part: BasePart)
	part.Anchored = false
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true

	for _, descendant in ipairs(part:GetDescendants()) do
		if descendant:IsA("Script") or descendant:IsA("LocalScript") or descendant:IsA("ModuleScript") then
			descendant:Destroy()
		elseif descendant:IsA("Sound") or descendant:IsA("ProximityPrompt") then
			descendant:Destroy()
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

function Renderer.Clear(rig: Model)
	clear(rig)
end

function Renderer.ApplyTemplate(rig: Model, template: Instance): boolean
	clear(rig)
	if not template then
		return false
	end

	local overlay = Instance.new("Folder")
	overlay.Name = OVERLAY_NAME
	overlay.Parent = rig

	local applied = 0
	for _, source in ipairs(template:GetDescendants()) do
		if source:IsA("BasePart") and source:GetAttribute("SkinReferencePart") ~= true then
			local attachTo = source:GetAttribute("SkinAttachTo")
			local attachFallback = source:GetAttribute("SkinAttachFallback")
			local referenceName = source:GetAttribute("SkinReference")

			if type(attachTo) == "string" and type(referenceName) == "string" then
				local target = findTarget(
					rig,
					attachTo,
					type(attachFallback) == "string" and attachFallback or nil
				)
				local reference = template:FindFirstChild(referenceName, true)

				if target and reference and reference:IsA("BasePart") then
					local clone = source:Clone()
					sanitizeClone(clone)
					clone.Size = scaledSize(reference, target, source)
					clone.CFrame = target.CFrame * scaledLocalCFrame(reference, target, source)
					clone.Parent = overlay

					local weld = Instance.new("WeldConstraint")
					weld.Name = "SkinWeld"
					weld.Part0 = target
					weld.Part1 = clone
					weld.Parent = clone
					applied += 1
				end
			end
		end
	end

	if applied == 0 then
		overlay:Destroy()
		return false
	end
	return true
end

return Renderer

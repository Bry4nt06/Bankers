local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SCENE_NAME = "TheTakeMenuScene"
local START_MARKER_NAME = "MenuCameraStart"
local END_MARKER_NAME = "MenuCameraEnd"
local CONFIG_FOLDER_NAME = "TheTakeMenuCameraConfig"

print("[TheTakeMenu] server cinematic setup starting")

local scene = workspace:WaitForChild(SCENE_NAME, 15)
if not scene then
	warn("[TheTakeMenu] Workspace.TheTakeMenuScene is missing; cinematic server setup skipped")
	return
end

local function findMarker(name: string): BasePart?
	local marker = scene:FindFirstChild(name, true)
	if marker and marker:IsA("BasePart") then
		return marker
	end
	return nil
end

local function stabilizeScene()
	local startedAt = os.clock()
	local parts = 0
	local scripts = 0

	for _, descendant in ipairs(scene:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.AssemblyLinearVelocity = Vector3.zero
			descendant.AssemblyAngularVelocity = Vector3.zero
			parts += 1
		elseif descendant:IsA("Tool") then
			descendant.CanBeDropped = false
		elseif descendant:IsA("Script") or descendant:IsA("LocalScript") then
			-- Everything inside TheTakeMenuScene is display-only. Donor gameplay
			-- scripts live elsewhere and are intentionally untouched.
			descendant.Enabled = false
			scripts += 1
		end
	end

	print(string.format(
		"[TheTakeMenu] display scene stabilized asynchronously: %d parts, %d scripts, %.2fs",
		parts,
		scripts,
		os.clock() - startedAt
	))
end

local function hideMarker(marker: BasePart)
	marker.Anchored = true
	marker.Transparency = 1
	marker.CanCollide = false
	marker.CanTouch = false
	marker.CanQuery = false
	marker.CastShadow = false

	for _, descendant in ipairs(marker:GetDescendants()) do
		if descendant:IsA("Decal") or descendant:IsA("Texture") then
			descendant.Transparency = 1
		elseif descendant:IsA("ParticleEmitter") or descendant:IsA("Trail") or descendant:IsA("Beam") then
			descendant.Enabled = false
		elseif descendant:IsA("BillboardGui") or descendant:IsA("SurfaceGui") then
			descendant.Enabled = false
		elseif descendant:IsA("Highlight") then
			descendant.Enabled = false
		end
	end
end

local function publishCameraConfig(): boolean
	local startMarker = findMarker(START_MARKER_NAME)
	local endMarker = findMarker(END_MARKER_NAME)
	if not startMarker or not endMarker then
		warn("[TheTakeMenu] MenuCameraStart/MenuCameraEnd missing inside TheTakeMenuScene")
		return false
	end

	local folder = ReplicatedStorage:FindFirstChild(CONFIG_FOLDER_NAME)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = CONFIG_FOLDER_NAME
		folder.Parent = ReplicatedStorage
	end
	folder:SetAttribute("Ready", false)

	local startValue = folder:FindFirstChild("Start")
	if not startValue then
		startValue = Instance.new("CFrameValue")
		startValue.Name = "Start"
		startValue.Parent = folder
	end

	local endValue = folder:FindFirstChild("End")
	if not endValue then
		endValue = Instance.new("CFrameValue")
		endValue.Name = "End"
		endValue.Parent = folder
	end

	(startValue :: CFrameValue).Value = startMarker.CFrame
	(endValue :: CFrameValue).Value = endMarker.CFrame
	folder:SetAttribute("Ready", true)

	hideMarker(startMarker)
	hideMarker(endMarker)
	print("[TheTakeMenu] cinematic camera config published immediately")
	return true
end

-- Camera readiness is the startup critical path. Publish it BEFORE walking the
-- very large display scene so the client can begin the cinematic immediately.
publishCameraConfig()

task.spawn(stabilizeScene)

-- Catch late-loaded appearance/prop descendants inside the cinematic model only.
scene.DescendantAdded:Connect(function(descendant)
	if descendant:IsA("BasePart") then
		task.defer(function()
			if descendant.Parent then
				descendant.Anchored = true
				descendant.AssemblyLinearVelocity = Vector3.zero
				descendant.AssemblyAngularVelocity = Vector3.zero
			end
		end)
	elseif descendant:IsA("Script") or descendant:IsA("LocalScript") then
		descendant.Enabled = false
	elseif descendant:IsA("Tool") then
		descendant.CanBeDropped = false
	end
end)

print("[TheTakeMenu] server cinematic setup handed off to asynchronous stabilization")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

Players.CharacterAutoLoads = false

local START_MARKER_NAME = "MenuCameraStart"
local END_MARKER_NAME = "MenuCameraEnd"
local CONFIG_FOLDER_NAME = "BankersMenuCameraConfig"
local CAMERA_STREAM_SETTLE = 0.20

local function isDisplayVehicleModel(instance: Instance): boolean
	if not instance:IsA("Model") then
		return false
	end

	local lowerName = string.lower(instance.Name)
	return string.find(lowerName, "armored truck", 1, true) ~= nil
end

local function findDisplayVehicleAncestor(instance: Instance): Model?
	local current: Instance? = instance
	while current and current ~= workspace do
		if current:IsA("Model") and isDisplayVehicleModel(current) then
			return current
		end
		current = current.Parent
	end
	return nil
end

local function findDisplayRigAncestor(instance: Instance): Model?
	local current: Instance? = instance
	while current and current ~= workspace do
		if current:IsA("Model") and current.Name == "Rig" and current:FindFirstChildOfClass("Humanoid") then
			return current
		end
		current = current.Parent
	end
	return nil
end

local function freezePart(part: BasePart)
	part.Anchored = true
	part.AssemblyLinearVelocity = Vector3.zero
	part.AssemblyAngularVelocity = Vector3.zero
end

local function hideCameraMarker(marker: BasePart)
	-- Runtime-only changes. In Edit mode the Studio-authored marker stays available
	-- for framing; in Play it is invisible and non-interactive.
	marker.Anchored = true
	marker.Transparency = 1
	marker.CanCollide = false
	marker.CanTouch = false
	marker.CanQuery = false
	marker.CastShadow = false
	marker.AssemblyLinearVelocity = Vector3.zero
	marker.AssemblyAngularVelocity = Vector3.zero

	for _, descendant in marker:GetDescendants() do
		if descendant:IsA("Decal") or descendant:IsA("Texture") then
			descendant.Transparency = 1
		elseif descendant:IsA("ParticleEmitter") or descendant:IsA("Trail") or descendant:IsA("Beam") then
			descendant.Enabled = false
		elseif descendant:IsA("BillboardGui") or descendant:IsA("SurfaceGui") then
			descendant.Enabled = false
		elseif descendant:IsA("Highlight") then
			descendant.Enabled = false
		elseif descendant:IsA("SelectionBox") then
			descendant.Visible = false
		end
	end
end

local function hideCameraMarkers()
	for _, markerName in ipairs({START_MARKER_NAME, END_MARKER_NAME}) do
		local marker = workspace:FindFirstChild(markerName)
		if marker and marker:IsA("BasePart") then
			hideCameraMarker(marker)
		end
	end
end

local function freezeDisplayRig(model: Model)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.AutoRotate = false
		humanoid.BreakJointsOnDeath = false
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end

	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			freezePart(descendant)
		elseif descendant:IsA("Tool") then
			descendant.CanBeDropped = false
		elseif descendant:IsA("Script") or descendant:IsA("LocalScript") then
			-- Menu rigs are display-only. Embedded scripts in weapon/free-model props
			-- must not equip, animate, unanchor, or drop their parts.
			descendant.Enabled = false
		end
	end
end

local function freezeVehicleModel(model: Model)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			freezePart(descendant)
		end
	end
end

local function freezeVehiclesFolder(folder: Instance)
	for _, descendant in folder:GetDescendants() do
		if descendant:IsA("BasePart") then
			freezePart(descendant)
		end
	end
end

local function stabilizeScene()
	for _, descendant in workspace:GetDescendants() do
		if descendant:IsA("Model") and descendant.Name == "Rig" and descendant:FindFirstChildOfClass("Humanoid") then
			freezeDisplayRig(descendant)
		end
	end

	local vehiclesFolder = workspace:FindFirstChild("Vehicles")
	if vehiclesFolder then
		freezeVehiclesFolder(vehiclesFolder)
	end

	for _, child in workspace:GetChildren() do
		if isDisplayVehicleModel(child) then
			freezeVehicleModel(child)
		end
	end
end

local function getMenuReplicationFocus(): BasePart?
	local endMarker = workspace:FindFirstChild(END_MARKER_NAME)
	if endMarker and endMarker:IsA("BasePart") then
		return endMarker
	end

	local startMarker = workspace:FindFirstChild(START_MARKER_NAME)
	if startMarker and startMarker:IsA("BasePart") then
		return startMarker
	end

	return nil
end

local function pinReplicationFocus(player: Player)
	local focus = getMenuReplicationFocus()
	if not focus then
		warn(string.format("[BankersMenu] no menu replication focus available for %s", player.Name))
		return
	end

	-- Avoid reassigning the same focus. Repeated focus writes during the cinematic
	-- can force unnecessary streaming work and present as a brief visual hitch.
	if player.ReplicationFocus ~= focus then
		player.ReplicationFocus = focus
		print(string.format(
			"[BankersMenu] replication focus pinned to %s for %s",
			focus.Name,
			player.Name
		))
	end
end

local function refreshReplicationFocusForAllPlayers()
	for _, player in Players:GetPlayers() do
		pinReplicationFocus(player)
	end
end

local function keepPlayerOutOfScene(player: Player)
	if player.Character then
		player.Character:Destroy()
	end

	player.CharacterAdded:Connect(function(character)
		character:Destroy()
	end)

	local config = ReplicatedStorage:FindFirstChild(CONFIG_FOLDER_NAME)
	if config and config:GetAttribute("Ready") == true then
		task.defer(pinReplicationFocus, player)
	end
end

local publishingCameraConfig = false

local function publishCameraConfig()
	if publishingCameraConfig then
		return
	end
	publishingCameraConfig = true

	local folder = ReplicatedStorage:FindFirstChild(CONFIG_FOLDER_NAME)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = CONFIG_FOLDER_NAME
		folder.Parent = ReplicatedStorage
	end

	-- Once the authoritative camera config is live, never republish it during the
	-- same server session. MenuCameraStart/End are Studio framing markers, not a
	-- live runtime camera source.
	if folder:GetAttribute("Ready") == true then
		hideCameraMarkers()
		publishingCameraConfig = false
		return
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

	local startMarker = workspace:FindFirstChild(START_MARKER_NAME)
	local endMarker = workspace:FindFirstChild(END_MARKER_NAME)
	local startReady = startMarker ~= nil and startMarker:IsA("BasePart")
	local endReady = endMarker ~= nil and endMarker:IsA("BasePart")

	if startReady then
		(startValue :: CFrameValue).Value = (startMarker :: BasePart).CFrame
	else
		warn("[BankersMenu] server could not find MenuCameraStart in Workspace")
	end

	if endReady then
		(endValue :: CFrameValue).Value = (endMarker :: BasePart).CFrame
	else
		warn("[BankersMenu] server could not find MenuCameraEnd in Workspace")
	end

	if startReady and endReady then
		-- Establish the no-character streaming focus before exposing Ready to the
		-- client camera. Give that focus a brief head start so the cinematic begins
		-- from a stable streamed scene instead of changing focus after it has begun.
		refreshReplicationFocusForAllPlayers()
		hideCameraMarkers()
		task.wait(CAMERA_STREAM_SETTLE)
		folder:SetAttribute("Ready", true)
		print("[BankersMenu] camera CFrames published once; replication focus settled; runtime camera markers hidden")
	else
		folder:SetAttribute("Ready", false)
	end

	publishingCameraConfig = false
end

Players.PlayerAdded:Connect(keepPlayerOutOfScene)
for _, player in Players:GetPlayers() do
	keepPlayerOutOfScene(player)
end

stabilizeScene()
publishCameraConfig()

-- These repeats only stabilize late-created display geometry. They deliberately
-- do not touch camera config or replication focus after the cinematic has begun.
task.delay(0.25, stabilizeScene)
task.delay(1, stabilizeScene)
task.delay(3, stabilizeScene)

workspace.DescendantAdded:Connect(function(descendant)
	if descendant:IsA("Model") and descendant.Name == "Rig" and descendant:FindFirstChildOfClass("Humanoid") then
		task.defer(freezeDisplayRig, descendant)
		return
	end

	local rig = findDisplayRigAncestor(descendant)
	if rig then
		if descendant:IsA("BasePart") then
			task.defer(freezePart, descendant)
		elseif descendant:IsA("Tool") then
			descendant.CanBeDropped = false
		elseif descendant:IsA("Script") or descendant:IsA("LocalScript") then
			descendant.Enabled = false
		end
		return
	end

	if descendant:IsA("BasePart") then
		if descendant.Name == START_MARKER_NAME or descendant.Name == END_MARKER_NAME then
			task.defer(function()
				hideCameraMarker(descendant)
				local config = ReplicatedStorage:FindFirstChild(CONFIG_FOLDER_NAME)
				if not config or config:GetAttribute("Ready") ~= true then
					publishCameraConfig()
				end
			end)
			return
		end

		local vehicle = findDisplayVehicleAncestor(descendant)
		if vehicle then
			task.defer(freezePart, descendant)
		end
	end
end)

print("[BankersMenu] menu-only scene stabilized; rigs, hand props, display vehicles, and runtime camera markers locked; player spawning disabled")

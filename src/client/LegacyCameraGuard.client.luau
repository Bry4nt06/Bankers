local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local LEGACY_RENDER_STEP = "CinematicIntroCamera"
local LEGACY_SCRIPT_NAME = "CinematicIntro"
local LEGACY_GUI_NAME = "CinematicIntroGui"
local LEGACY_MARKERS = {
	IntroCamera = true,
	IntroCameraTarget = true,
}

local function disableAndDestroy(instance: Instance)
	if instance:IsA("LocalScript") or instance:IsA("Script") then
		instance.Enabled = false
	end
	instance:Destroy()
end

local function purgeLegacyCamera()
	pcall(function()
		RunService:UnbindFromRenderStep(LEGACY_RENDER_STEP)
	end)

	local playerScripts = player:FindFirstChild("PlayerScripts")
	if playerScripts then
		for _, descendant in playerScripts:GetDescendants() do
			if descendant.Name == LEGACY_SCRIPT_NAME then
				disableAndDestroy(descendant)
			end
		end
	end

	local playerGui = player:FindFirstChild("PlayerGui")
	if playerGui then
		local legacyGui = playerGui:FindFirstChild(LEGACY_GUI_NAME)
		if legacyGui then
			legacyGui:Destroy()
		end
	end

	for _, child in workspace:GetChildren() do
		if child:IsA("BasePart") and LEGACY_MARKERS[child.Name] then
			child.LocalTransparencyModifier = 1
		end
	end
end

local playerScripts = player:WaitForChild("PlayerScripts")
playerScripts.DescendantAdded:Connect(function(descendant)
	if descendant.Name == LEGACY_SCRIPT_NAME then
		task.defer(function()
			if descendant.Parent then
				disableAndDestroy(descendant)
			end
		end)
	end
end)

local playerGui = player:WaitForChild("PlayerGui")
playerGui.ChildAdded:Connect(function(child)
	if child.Name == LEGACY_GUI_NAME then
		task.defer(function()
			if child.Parent then
				child:Destroy()
			end
		end)
	end
end)

workspace.ChildAdded:Connect(function(child)
	if child:IsA("BasePart") and LEGACY_MARKERS[child.Name] then
		child.LocalTransparencyModifier = 1
	end
end)

purgeLegacyCamera()

task.spawn(function()
	local deadline = os.clock() + 12
	while os.clock() < deadline do
		purgeLegacyCamera()
		task.wait(0.25)
	end
end)

print("[BankersMenu] legacy CinematicIntro camera guard active")

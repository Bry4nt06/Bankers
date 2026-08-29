-- THE TAKE one-time donor sanitation pass.
-- Run this from Roblox Studio's Command Bar while NOT in Play mode, then save.

local ServerStorage = game:GetService("ServerStorage")
local StarterGui = game:GetService("StarterGui")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local removedSounds = 0
local disabledSceneScripts = 0
local removedPresentation = 0
local patchedShoulderCameras = 0

local presentationTargets = {
	{workspace, "StarterScene"},
	{workspace, "introcameras"},
	{ServerStorage, "Intro"},
	{StarterGui, "CutsceneUI"},
	{StarterGui, "LoadingScreenGui"},
}

for _, entry in ipairs(presentationTargets) do
	local object = entry[1]:FindFirstChild(entry[2])
	if object then
		object:Destroy()
		removedPresentation += 1
	end
end

local audioScript = workspace:FindFirstChild("AudioScript")
if audioScript then
	audioScript:Destroy()
end

-- The cinematic scene is display-only. Its copied vehicle/seat/animation scripts
-- must never execute during startup.
local scene = workspace:FindFirstChild("TheTakeMenuScene")
if scene then
	for _, descendant in ipairs(scene:GetDescendants()) do
		if descendant:IsA("Script") or descendant:IsA("LocalScript") then
			descendant.Enabled = false
			disabledSceneScripts += 1
		end
	end
end

-- Strip all donor audio for now. Owned THE TAKE audio can be added back later.
for _, descendant in ipairs(game:GetDescendants()) do
	if descendant:IsA("Sound") then
		descendant:Destroy()
		removedSounds += 1
	end
end

-- Persistence is intentionally paused until the final experience is published.
local main = ServerScriptService:FindFirstChild("Main")
if main then
	for _, name in ipairs({"Inventory", "TimePlayed"}) do
		local scriptObject = main:FindFirstChild(name)
		if scriptObject and scriptObject:IsA("Script") then
			scriptObject.Enabled = false
		end
	end
end

-- Broken's legacy shoulder camera writes Motor6D.C0 every render step. Current
-- Roblox exposes that target as read-only in this path. Remove only that obsolete
-- write and retain the remainder of the weapon camera/gun implementation.
local oldLine = "\t\tself.rootJoint.C0 = CFrame.new(self.rootJoint.C0.Position, self.rootJoint.C0.Position + rotationFix.LookVector.Unit)"
local replacementLine = "\t\t-- THE TAKE: obsolete rootJoint.C0 mutation disabled for current Roblox runtime"

local function patchShoulderCamera(root: Instance)
	local weaponsSystem = root:FindFirstChild("WeaponsSystem")
	local libraries = weaponsSystem and weaponsSystem:FindFirstChild("Libraries")
	local shoulderCamera = libraries and libraries:FindFirstChild("ShoulderCamera")
	if not shoulderCamera or not shoulderCamera:IsA("ModuleScript") then
		return
	end

	local source = shoulderCamera.Source
	local first, last = string.find(source, oldLine, 1, true)
	if first and last then
		shoulderCamera.Source = string.sub(source, 1, first - 1) .. replacementLine .. string.sub(source, last + 1)
		patchedShoulderCameras += 1
	end
end

patchShoulderCamera(ReplicatedStorage)
patchShoulderCamera(ServerScriptService)

print(string.format(
	"[THE TAKE SANITIZE] complete | presentation=%d | sceneScriptsDisabled=%d | soundsRemoved=%d | shoulderCameraPatched=%d",
	removedPresentation,
	disabledSceneScripts,
	removedSounds,
	patchedShoulderCameras
))

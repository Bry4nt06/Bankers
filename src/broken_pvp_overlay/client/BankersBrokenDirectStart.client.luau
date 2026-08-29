local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local SEARCH_TIMEOUT = 20
local SPAWN_REMOTE_NAME = "SpawnPlayer"

local function normalize(value: string): string
	return string.lower((value:gsub("%s+", "")))
end

local function buttonScore(button: GuiButton): number
	local score = 0
	local name = normalize(button.Name)

	if name == "play" or name == "playbutton" or name == "start" or name == "startbutton" then
		score += 10
	elseif string.find(name, "play", 1, true) or string.find(name, "start", 1, true) then
		score += 5
	end

	if button:IsA("TextButton") then
		local text = normalize(button.Text)
		if text == "play" or text == "start" then
			score += 12
		elseif string.find(text, "play", 1, true) or string.find(text, "start", 1, true) then
			score += 6
		end
	end

	return score
end

local function findBrokenPlayButton(): GuiButton?
	local bestButton: GuiButton? = nil
	local bestScore = 0

	for _, descendant in ipairs(playerGui:GetDescendants()) do
		if descendant:IsA("GuiButton") then
			local screenGui = descendant:FindFirstAncestorOfClass("ScreenGui")
			if screenGui then
				local score = buttonScore(descendant)
				if score > bestScore then
					bestScore = score
					bestButton = descendant
				end
			end
		end
	end

	if bestScore < 10 then
		return nil
	end

	return bestButton
end

local function findWithTimeout(): GuiButton?
	local deadline = os.clock() + SEARCH_TIMEOUT
	repeat
		local button = findBrokenPlayButton()
		if button then
			return button
		end
		task.wait(0.1)
	until os.clock() >= deadline

	return nil
end

local function hideStarterMenu(playButton: GuiButton)
	local screenGui = playButton:FindFirstAncestorOfClass("ScreenGui")
	if not screenGui then
		warn("[TheTakeBrokenDirectStart] identified PLAY button has no ScreenGui ancestor")
		return nil
	end

	-- Disable only the ScreenGui that owns Broken's starter PLAY button. Other
	-- gameplay ScreenGuis remain untouched so the round HUD, combat HUD, voting,
	-- inventory, shop, and weapon interfaces can continue to function.
	screenGui.Enabled = false
	print(string.format(
		"[TheTakeBrokenDirectStart] disabled Broken starter menu %s (PLAY: %s)",
		screenGui.Name,
		playButton:GetFullName()
	))
	return screenGui
end

local function restoreGameplayPresentation(character: Model?)
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
	end)

	UserInputService.MouseIconEnabled = true

	local camera = workspace.CurrentCamera
	if not camera then
		return
	end

	camera.CameraType = Enum.CameraType.Custom
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			camera.CameraSubject = humanoid
		end
	end
end

local function requestSpawn(): boolean
	local remote = ReplicatedStorage:FindFirstChild(SPAWN_REMOTE_NAME)
	if not remote then
		remote = ReplicatedStorage:WaitForChild(SPAWN_REMOTE_NAME, 10)
	end

	if not remote then
		warn("[TheTakeBrokenDirectStart] ReplicatedStorage.SpawnPlayer was not found; Broken menu is hidden but automatic spawn could not be requested")
		return false
	end

	if remote:IsA("RemoteEvent") then
		remote:FireServer()
		print("[TheTakeBrokenDirectStart] fired Broken SpawnPlayer RemoteEvent")
		return true
	elseif remote:IsA("RemoteFunction") then
		local ok, err = pcall(function()
			remote:InvokeServer()
		end)
		if not ok then
			warn("[TheTakeBrokenDirectStart] SpawnPlayer RemoteFunction failed: " .. tostring(err))
			return false
		end
		print("[TheTakeBrokenDirectStart] invoked Broken SpawnPlayer RemoteFunction")
		return true
	end

	warn(string.format(
		"[TheTakeBrokenDirectStart] %s exists but is %s, not a RemoteEvent/RemoteFunction",
		SPAWN_REMOTE_NAME,
		remote.ClassName
	))
	return false
end

local playButton = findWithTimeout()
if not playButton then
	warn("[TheTakeBrokenDirectStart] could not identify Broken's starter PLAY button; no donor UI was changed")
	return
end

hideStarterMenu(playButton)

-- Give Broken's own client bootstrap a moment to finish creating its remotes and
-- player state, then use the donor game's existing spawn entry point directly.
task.wait(0.25)
requestSpawn()

restoreGameplayPresentation(player.Character)
player.CharacterAdded:Connect(function(character)
	task.defer(function()
		restoreGameplayPresentation(character)
	end)
end)

-- Broken can recreate its starter menu during respawn/reinitialization. If the
-- same menu ScreenGui is cloned again, disable only that menu again.
playerGui.DescendantAdded:Connect(function(descendant)
	if descendant:IsA("GuiButton") then
		task.defer(function()
			if descendant.Parent and buttonScore(descendant) >= 10 then
				local screenGui = descendant:FindFirstAncestorOfClass("ScreenGui")
				if screenGui and screenGui.Enabled then
					screenGui.Enabled = false
					print("[TheTakeBrokenDirectStart] suppressed recreated Broken starter menu " .. screenGui.Name)
				end
			end
		end)
	end
end)

print("[TheTakeBrokenDirectStart] Broken starter menu bypass active; donor gameplay systems preserved")
